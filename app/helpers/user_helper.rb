module UserHelper
  def user_role_options
    options = current_user.super_admin? ? UserRole.all : UserRole.not_reviewer
    options.map { |role| [role.label, role.id] }
  end

  def client_options_by_agency(agency_id = nil)
    return [] unless agency_id.present?
    policy_scope(Client).by_agency_id(agency_id).map { |c| [c.contact_full_name, c.id] }
  end

  def client_user_role_id
    @client_user_role_id ||= UserRole.client_user&.id
  end

  def client_container_class(user_role_id)
    return "d-none" if user_role_id.blank? || user_role_id != client_user_role_id

    ""
  end
end
