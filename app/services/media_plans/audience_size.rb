# frozen_string_literal: true

module MediaPlans
  class AudienceSize
    MIN_SIZE = 1_000
    MAX_SIZE = 2_000_000

    def self.generate
      # Generate a random number between MIN_SIZE and MAX_SIZE and round it to the nearest thousand
      rand(MIN_SIZE..MAX_SIZE).round(-3)
    end
  end
end
