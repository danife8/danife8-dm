# frozen_string_literal: true

module Validators
  class PercentageSumValidator < ActiveModel::Validator
    def validate(record)
      fields_to_validate = options[:fields].dup || []
      total_should_be = options[:should_be] || 100

      total = fields_to_validate.sum { |field| record.send(field) || 0 }
      return if total == total_should_be

      last_field = fields_to_validate.pop
      record.errors.add(:base, "The sum of #{fields_to_validate.join(", ")} and #{last_field} must equal #{total_should_be}%")
    end
  end
end
