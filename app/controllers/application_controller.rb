# Common behavior for inbound requests.
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :ensure_user_active!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_paper_trail_whodunnit

  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  # Verify that the current user account status is active.
  def ensure_user_active!
    return unless current_user.present? && !current_user.active?

    flash[:alert] = "You must have an active account."
    sign_out(current_user)
    redirect_to new_user_session_path
  end

  # Override to permit extra user profile params.
  # @return [configure_permitted_parameters]
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :first_name,
      :last_name,
      :phone_number
    ])
  end

  # @param resource_name [User]
  # @return [String] send invalid tokens to login
  def invalid_token_path_for(resource_name)
    new_user_session_path
  end

  # Notify user that they are unauthorized and redirect.
  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end
end
