module ClientHelper
  def agency_user_options
    policy_scope(User).agency_users.map { |u| [u.full_name, u.id] }
  end
end
