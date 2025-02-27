# Campaign resource access policy.
class CampaignPolicy < ApplicationPolicy
  # @return [TrueClass,FalseClass]
  def index?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer?
  end

  def show?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer? || user.client_user?
  end

  def request_documents?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer?
  end

  def upload_documents?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer? || user.client_user?
  end

  def add_client_user?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer?
  end

  def edit_documents_request?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer? || user.client_user?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(insertion_order: :client).merge(user.agency.clients)
    end
  end
end
