# Document resource access policy.
class DocumentPolicy < ApplicationPolicy
  # @return [TrueClass,FalseClass]
  def upload_documents?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer? || user.client_user?
  end

  def create?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer? || user.client_user?
  end

  def destroy?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer? || user.client_user?
  end

  def upload?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer? || user.client_user?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(insertion_order: :client).merge(user.agency.clients)
    end
  end
end
