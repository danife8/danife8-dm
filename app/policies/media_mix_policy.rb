# app/policies/media_mix_policy.rb
class MediaMixPolicy < ApplicationPolicy
  def index?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager?
  end

  def show_details?
    user.super_admin? || user.admin?
  end

  def edit?
    return false if record.approved?

    user.super_admin? || user.admin?
  end

  def update?
    return false if record.approved?

    user.super_admin? || user.admin?
  end

  # @return [TrueClass,FalseClass]
  def create?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager?
  end

  def destroy?
    return false if record.approved?

    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager?
  end

  def restore_version?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager?
  end

  def download_ppt?
    return false unless record.has_media_output?

    user.super_admin? || user.admin?
  end

  # @return [Array<Symbol>]
  def permitted_params
    [:title, :client_id, :media_brief_id]
  end

  # Determine which resources are available to the user.
  class Scope < ApplicationPolicy::Scope
    # Scope clients to agency unless super admin.
    def resolve
      scope.all
    end
  end
end
