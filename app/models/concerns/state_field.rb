# ActiveRecord models including this module will have to define a constant named
# VALID_AASM_STATES with all valid states for the aasm_state field.
#
# Example:
#
#   VALID_AASM_STATES = %w[pending active inactive].freeze
#
module StateField
  extend ActiveSupport::Concern

  included do
    include ::AASM

    validates :aasm_state,
      presence: true,
      inclusion: {in: -> { valid_aasm_states }}
  end

  class_methods do
    # @return [Array<String>] supported state machine values
    # @raise [NotImplementedError] class implementing behavior must define
    def valid_aasm_states
      raise NotImplementedError, "#{name} must define .valid_aasm_states"
    end
  end
end
