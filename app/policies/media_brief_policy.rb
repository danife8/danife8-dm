# MediaBrief resource access policy.
class MediaBriefPolicy < MediaBriefBuilderPolicy
  # @return [TrueClass,FalseClass]
  def index?
    !user.nil?
  end

  # @return [TrueClass,FalseClass]
  def show?
    !user.nil?
  end

  # @return [TrueClass,FalseClass]
  def create?
    user.super_admin? || user.admin?
  end

  # @return [TrueClass,FalseClass]
  def edit?
    return false if record.approved?

    user.super_admin? || user.admin?
  end

  # @return [TrueClass,FalseClass]
  def update?
    return false if record.approved?

    user.super_admin? || user.admin?
  end

  # @return [TrueClass,FalseClass]
  def destroy?
    return false if record.approved?

    user.super_admin? || user.admin?
  end

  def download_ppt?
    user.super_admin? || user.admin?
  end

  def restore_version?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager?
  end

  # Determine which resources are available to the user.
  class Scope < ApplicationPolicy::Scope
    # Scope clients to agency unless super admin.
    def resolve
      if user.super_admin?
        scope.all
      else
        scope.joins(client: :agency).where(client: {agency: user.agency})
      end
    end
  end
end
