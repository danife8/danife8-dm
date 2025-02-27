# frozen_string_literal: true

module MediaMixes
  module Reallocate
    # MediaMixes::Reallocate::PrimaryChannel
    class PrimaryChannel < Base
      attr_accessor :logger

      def call
        @logger = []

        progressive_reallocate if stair_step?

        while channel_has_one_meets_false
          channel_reallocate
        end

        reallocate_primary_channel_2

        logger.last
      end

      protected

      # If only one Primary Target Strategy has a Minimum Status of FALSE
      def channel_has_one_meets_false
        if valid_target_strategies(primary_channels.first).size == 1 && valid_target_strategies(primary_channels.last).size == 1
          return
        end

        primary_channel_1_meets_min.size.positive? || primary_channel_2_meets_min.size.positive?
      end

      def channel_reallocate
        primary_channels.each_with_index do |channel, channel_index|
          strategies = channel[:target_strategies]
          last_meets_index = strategies.rindex { |st| st[:meets_min] == false }

          # Pre cache variables
          primary_channel2_positions
          primary_channel1_positions

          next unless last_meets_index

          strategy = strategies.delete_at(last_meets_index)
          valid_strategies = strategies.select { |st| !st[:meets_min].nil? }
          invalid_strategies = valid_strategies.select { |st| st[:meets_min] == false }
          reallocate_strategies = invalid_strategies.size.positive? ? invalid_strategies : valid_strategies

          reallocate_percentage = (!reallocate_strategies.size.zero?) ?
            strategy[:budget].to_f / reallocate_strategies.size : 0

          if channel_index == 0
            tmp_percentages = primary_channel1_positions.map.with_index do |position, index|
              percentages.send(:"primary_channel1_target_strategy#{position}")
            end

            reset_percentage("primary_channel1_target_strategy#{primary_channel1_positions.size}") # Reset the last percentage
            tmp_percentages.delete_at(last_meets_index)
            primary_channel1_positions.pop

            # Move percentage positions
            tmp_percentages.each_with_index do |percentage, index|
              set_percentage("primary_channel1_target_strategy#{index + 1}", percentage)
            end

            # Increment all percentages
            primary_channel1_positions.each_with_index do |position, index|
              next if invalid_strategies.size.positive? && valid_strategies[index].try(:[], :meets_min) == true

              inc_percentage("primary_channel1_target_strategy#{position}", reallocate_percentage)
            end
          else
            tmp_percentages = primary_channel2_positions.map.with_index do |position, index|
              percentages.send(:"primary_channel2_target_strategy#{position}")
            end

            reset_percentage("primary_channel2_target_strategy#{primary_channel2_positions.size}") # Reset the last percentage
            tmp_percentages.delete_at(last_meets_index)
            primary_channel2_positions.pop

            # Move percentage positions
            tmp_percentages.each_with_index do |percentage, index|
              set_percentage("primary_channel2_target_strategy#{index + 1}", percentage)
            end

            # Increment all percentages
            primary_channel2_positions.each_with_index do |position, index|
              next if invalid_strategies.size.positive? && valid_strategies[index].try(:[], :meets_min) == true

              inc_percentage("primary_channel2_target_strategy#{position}", reallocate_percentage)
            end
          end
        end

        reallocate_primary_channels(engine)
        @logger << {title: "Reallocate Step 2: Condition one", engine: engine.deep_dup}
      end

      def primary_channel2_positions
        target_strategies = engine[:channel_strategies][:primary_channels][1].try(:[], :target_strategies)
        return [] if target_strategies.blank?

        @primary_channel2_positions ||= (1..target_strategies.size).to_a.select do |position|
          percentages.send(:"primary_channel2_target_strategy#{position}").to_f > 0
        end
      end

      def primary_channel1_positions
        @primary_channel1_positions ||= (1..engine[:channel_strategies][:primary_channels][0][:target_strategies].size).to_a.select do |position|
          percentages.send(:"primary_channel1_target_strategy#{position}").to_f > 0
        end
      end

      def progressive_reallocate
        return if primary_channels.size == 1

        percentage_step = 0.25
        reallocation_percentage = percentage_step

        channel = primary_channels.last
        strategies = channel[:target_strategies]
        last_meets_index = strategies.rindex { |st| st[:meets_min] == false }

        return unless last_meets_index

        strategy = strategies.delete_at(last_meets_index)
        valid_strategies = strategies.select { |st| !st[:meets_min].nil? }

        reallocate_percentage = (!valid_strategies.size.zero?) ?
          strategy[:budget].to_f / valid_strategies.size : 0

        primary_channel2_strategies.delete(last_meets_index + 1)
        reset_percentage("primary_channel2_target_strategy#{last_meets_index + 1}")
        primary_channel2_strategies.each do |position|
          inc_percentage("primary_channel2_target_strategy#{position}", reallocate_percentage)
        end

        total_budget = engine[:budget].to_f
        reallocation_amount = strategy[:amt] * percentage_step
        total_percentage = ((reallocation_amount.to_f * 100.00) / total_budget)

        while reallocation_percentage <= 1
          # Reallocate to primary channels and increase general budget
          inc_percentage("primary_channel1", total_percentage)
          inc_percentage("primary_channel2", total_percentage * -1)

          # Reallocate to false meets min and drop percentages in strategies with meets min in true without change the amount
          channel1 = primary_channels.first
          channel1_strategies = channel1[:target_strategies].select { |st| [true, false].include?(st[:meets_min]) }
          valid_ts = channel1_strategies.select { |ts| ts[:meets_min] }
          invalid_ts = channel1_strategies - valid_ts

          if channel1_strategies.any? { |st| !st[:meets_min] }
            platform_amount = channel1[:platform_amt] + reallocation_amount

            channel1_strategies.each_with_index do |ts, index|
              next unless ts[:meets_min]

              percentage = (ts[:amt].to_f * 100.00) / platform_amount.to_f
              ts[:budget] = percentage
              set_percentage("primary_channel1_target_strategy#{index + 1}", percentage)
            end

            channel1_strategies.each_with_index do |ts, index|
              next if ts[:meets_min]

              amount = ts[:amt].to_f + (reallocation_amount / invalid_ts.size.to_f)
              percentage_to_add = (amount * 100.00) / platform_amount.to_f

              set_percentage("primary_channel1_target_strategy#{index + 1}", percentage_to_add)
            end
          end

          reallocate_primary_channels(engine)

          @logger << {
            title: "Reallocate Step 2: Condition two - Get #{(reallocation_percentage * 100).to_i}% from #{strategy[:target_strategy][:label]}",
            engine: engine.deep_dup
          }

          break if primary_channel_1_meets_min.size.zero?
          break unless exists_false_meets_min?

          reallocation_percentage += percentage_step
        end
      end

      def primary_channels
        engine[:channel_strategies][:primary_channels]
      end

      def primary_channel_1_meets_min
        primary_channels.first[:target_strategies].select { |st| st[:meets_min] == false }
      end

      def primary_channel_2_meets_min
        primary_channels.last[:target_strategies].select { |st| st[:meets_min] == false }
      end

      def valid_target_strategies(channel)
        channel[:target_strategies].select { |st| [true, false].include?(st[:meets_min]) }
      end

      def primary_channel1_strategies
        @primary_channel1_strategies ||= [1, 2, 3, 4, 5].select do |position|
          percentages.send(:"primary_channel1_target_strategy#{position}") > 0
        end
      end

      def primary_channel2_strategies
        @primary_channel2_strategies ||= [1, 2, 3, 4, 5].select do |position|
          percentages.send(:"primary_channel2_target_strategy#{position}") > 0
        end
      end

      def exists_false_meets_min?
        !!primary_channels.select do |pc|
          pc[:target_strategies].any? { |st| st[:meets_min] == false }
        end
      end

      def stair_step?
        return unless primary_channels[1]

        (primary_channel_1_meets_min.size.positive? &&
          primary_channel_2_meets_min.size >= 1) ||
          (primary_channel_1_meets_min.size >= 1 &&
            primary_channel_2_meets_min.size.positive?)
      end

      def reallocate_primary_channel_2
        return unless primary_channels[1]
        return if primary_channel_2_meets_min.size != valid_target_strategies(primary_channels.last).size

        # Reallocate primary channel 2 to primary channel 1
        inc_percentage("primary_channel1", percentages.primary_channel2)
        reset_percentage("primary_channel2")
        primary_channels.delete_at(1)
        reallocate_primary_channels(engine)

        @logger << {
          title: "Reallocate Step 2: Condition three - Remove primary channel 2 and reallocate to primary channel",
          engine: engine.deep_dup
        }
      end
    end
  end
end
