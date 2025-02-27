# Common media brief data validators for custom data types.
module StateFieldValidations
  extend ActiveSupport::Concern

  included do
    before_validation :cleanup_state_field

    validates :state,
      presence: true,
      inclusion: {in: UsState.abbreviations}
  end

  def cleanup_state_field
    return unless state.present?

    self.state = if state.strip.size == 2
      state.strip.upcase
    else
      UsState.name_to_abbr(state) || state
    end
  end
end
