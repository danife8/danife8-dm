# app/policies/insertion_order_policy.rb
class InsertionOrderPolicy < ApplicationPolicy
  def index?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer?
  end

  def show?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer?
  end

  def serve_pdf?
    user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer?
  end

  # Determine which resources are available to the user.
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(client: :agency).where(client: {agency: user.agency})
    end
  end
end
