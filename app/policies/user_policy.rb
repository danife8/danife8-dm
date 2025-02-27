# User resource access policy.
class UserPolicy < ApplicationPolicy
  # @return [Array<Symbol>]
  def assign_role?
    if record.user_role&.name == "reviewer" && !user.super_admin?
      return false
    end

    true
  end

  def permitted_user_params(current_params = {})
    permitted_params = %i[email first_name last_name phone_number user_role_id]

    # Add client_id for client users
    if current_params[:user_role_id].to_i == UserRole.client_user&.id
      permitted_params << :client_id
    end

    permitted_params += %i[agency_id super_admin] if user.super_admin?
    permitted_params
  end

  def permitted_create_params(current_params = {})
    permitted_user_params(current_params)
  end

  # @return [Array<Symbol>]
  def permitted_update_params(current_params = {})
    permitted_user_params(current_params) << :aasm_state
  end

  # Determine which resources are available to the user.
  class Scope < ApplicationPolicy::Scope
    # Scope users to agency unless super admin.
    def resolve
      if user.super_admin?
        scope.all
      else
        scope.where(agency: user.agency)
      end
    end
  end
end
