# frozen_string_literal: true

module MediaMixes
  module Reallocate
    # MediaMixes::Reallocate::Base
    class Base
      def initialize(engine, percentages)
        @engine = engine
        @percentages = percentages
      end

      def call
        raise NotImplementedError
      end

      protected

      attr_accessor :engine, :percentages

      def inc_percentage(field, reallocate_percentage)
        new_percentage = percentages.send(field).to_f + reallocate_percentage
        percentages.send(:"#{field}=", new_percentage)
      end

      def reset_percentage(field)
        percentages.send(:"#{field}=", 0)
      end

      def set_percentage(field, percentage)
        percentages.send(:"#{field}=", percentage)
      end

      def reallocate_primary_channels(engine)
        SetPrimaryBudget.new(
          engine[:channel_strategies][:primary_channels],
          engine[:flight_days],
          engine[:budget],
          engine[:budget_size],
          percentages
        ).call
      end

      def reallocate_secondary_channels(engine)
        SetSecondaryBudget.new(
          engine[:channel_strategies][:secondary_channels],
          engine[:flight_days],
          engine[:budget],
          engine[:budget_size],
          percentages
        ).call
      end
    end
  end
end
