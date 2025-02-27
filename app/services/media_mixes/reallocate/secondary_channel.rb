# frozen_string_literal: true

module MediaMixes
  module Reallocate
    # MediaMixes::Reallocate::SecondaryChannel
    class SecondaryChannel < Base
      def call
        return unless engine[:channel_strategies][:secondary_channels].any?

        secondary_channels = engine[:channel_strategies][:secondary_channels]
        query = ->(ch) { ch[:target_strategies].first[:meets_min] == false }

        while secondary_channels.any?(&query)
          tmp_percentages = secondary_positions.map.with_index do |position, index|
            percentages.send(:"secondary_channel#{position}")
          end

          last_meets_index = secondary_channels.rindex(&query)
          reset_percentage("secondary_channel#{secondary_channels.size}") # Reset the last percentage
          secondary_positions.pop
          channel = secondary_channels.delete_at(last_meets_index)
          tmp_percentages.delete_at(last_meets_index)

          # Move percentage positions
          tmp_percentages.each_with_index do |percentage, index|
            set_percentage("secondary_channel#{index + 1}", percentage)
          end

          reallocate_percentage = (!secondary_channels.size.zero?) ?
            channel[:platform_budget].to_f / secondary_channels.size :
            channel[:platform_budget].to_f / primary_positions.size

          # Increment all percentages
          secondary_positions.each do |position|
            inc_percentage("secondary_channel#{position}", reallocate_percentage)
          end

          # Reallocate to Primary channels
          unless secondary_channels.any?
            primary_positions.each do |position|
              inc_percentage("primary_channel#{position}", reallocate_percentage)
            end
            reallocate_primary_channels(engine)
          end

          reallocate_secondary_channels(engine)
          secondary_channels = engine[:channel_strategies][:secondary_channels]
        end

        engine
      end

      protected

      def secondary_positions
        @secondary_positions ||= (1..engine[:channel_strategies][:secondary_channels].size).to_a.select do |position|
          percentages.send(:"secondary_channel#{position}") > 0
        end
      end

      def primary_positions
        @primary_positions ||= [1, 2].select do |position|
          percentages.send(:"primary_channel#{position}") > 0
        end
      end
    end
  end
end
