FactoryBot.define do
  factory(:user_role) do
    sequence(:name) { |n| "role_#{n}" }
    sequence(:label) { |n| "Role #{n}" }

    factory(:admin_role) do
      name { "admin" }
      label { "Admin" }
    end

    factory(:account_manager_role) do
      name { "account_manager" }
      label { "Internal Account Manager" }
    end

    factory(:campaign_manager_role) do
      name { "campaign_manager" }
      label { "Internal Campaign Manager" }
    end

    factory(:reviewer_role) do
      name { "reviewer" }
      label { "Review Expert" }
    end

    factory(:employee_role) do
      name { "employee" }
      label { "Employee" }
    end

    factory(:agency_admin_role) do
      name { "agency_admin" }
      label { "Agency Admin" }
    end

    factory(:agency_user_role) do
      name { "agency_user" }
      label { "Agency User" }
    end

    factory(:client_user_role) do
      name { "client_user" }
      label { "Client User" }
    end
  end
end
