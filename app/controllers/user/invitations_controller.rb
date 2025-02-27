# Resources to manage user invitations.
# @see https://github.com/scambra/devise_invitable/blob/master/app/controllers/devise/invitations_controller.rb
class User::InvitationsController < Devise::InvitationsController
  protected

  # Override to change user state to active with successful invite acceptance.
  # @return [User]
  # @see https://github.com/scambra/devise_invitable/blob/master/app/controllers/devise/invitations_controller.rb#L83-L85
  def accept_resource
    super.tap do |u|
      u.enable! unless u.active?
    end
  end
end
