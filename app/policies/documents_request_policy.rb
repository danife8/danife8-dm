# Documents Request resource access policy.

class DocumentsRequestPolicy < ApplicationPolicy
  # @return [TrueClass,FalseClass]
  def create?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer?
  end

  def show?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer? || user.client_user?
  end

  def upload_documents?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer? || user.client_user?
  end

  def send_reminder?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer? || user.client_user?
  end

  def update?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer? || user.client_user?
  end

  def request_documents?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer? || user.client_user?
  end

  def edit_documents_request?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer? || user.client_user?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(insertion_order: :client).where(clients: {agency: user.agency})
    end
  end
end
