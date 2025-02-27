FactoryBot.define do
  factory(:user) do
    agency
    user_role
    email { Faker::Internet.email }
    password { Faker::Internet.password }
    confirmed_at { 5.seconds.ago }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    phone_number { rand(1000000000..9999999999).to_s }
  end
end
