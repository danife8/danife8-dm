FactoryBot.define do
  factory(:client) do
    agency
    name { Faker::Company.name }
    contact_first_name { Faker::Name.first_name }
    contact_last_name { Faker::Name.last_name }
    contact_email { Faker::Internet.email }
    contact_position { [nil, Faker::Job.position].sample }
    contact_phone_number { [nil, rand(1000000000..9999999999).to_s].sample }
    website { Faker::Internet.url }
  end
end
