module ReportingDashboardHelper
  def client_options
    policy_scope(Client).map { |c| [c.name, c.id] }
  end

  def user_options
    policy_scope(User).map { |u| [u.full_name, u.id] }
  end
end
