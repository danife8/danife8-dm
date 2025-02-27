RSpec.describe Client, type: :model do
  subject { build(:client) }

  describe "soft deletion" do
    before { create_list(:campaign_channel, 5) }

    let!(:media_brief) { create(:media_brief, client: subject) }
    let!(:media_brief_builder) { media_brief.media_brief_builder }
    let(:media_mix) { create(:media_mix, client: subject, media_brief:) }

    it "does not fully destroy client records" do
      expect { subject.destroy! }.to change { subject.deleted_at }
      expect { described_class.with_deleted.find_by!(id: subject.id) }.to_not raise_error
    end

    it "does not fully destroy media brief records" do
      expect { subject.destroy! }.to change { media_brief.reload.deleted_at }
      expect { MediaBrief.with_deleted.find_by!(id: media_brief.reload.id) }.to_not raise_error
    end

    it "does not fully destroy media brief builder records" do
      expect { subject.destroy! }.to change { media_brief_builder.reload.deleted_at }
      expect { MediaBriefBuilder.with_deleted.find_by!(id: media_brief_builder.reload.id) }.to_not raise_error
    end

    it "does not fully destroy media mix records" do
      expect { subject.destroy! }.to change { media_mix.reload.deleted_at }
      expect { MediaMix.with_deleted.find_by!(id: media_mix.reload.id) }.to_not raise_error
    end
  end

  describe ".search_by_name" do
    context "when names start with query" do
      it "returns matching client records" do
        query = "needle"

        matching_clients = [
          FactoryBot.create(:client, name: "#{query}1"),
          FactoryBot.create(:client, name: "#{query}2"),
          FactoryBot.create(:client, name: "#{query}3")
        ]

        # Create some clients without the query.
        3.times do
          FactoryBot.create(:client)
        end

        expect(described_class.search_by_name(query).sort).to eq(matching_clients)
      end
    end

    context "when names end with query" do
      it "returns matching client records" do
        query = "needle"

        matching_clients = [
          FactoryBot.create(:client, name: "1#{query}"),
          FactoryBot.create(:client, name: "2#{query}"),
          FactoryBot.create(:client, name: "3#{query}")
        ]

        # Create some clients without the query.
        3.times do
          FactoryBot.create(:client)
        end

        expect(described_class.search_by_name(query).sort).to eq(matching_clients)
      end
    end

    context "when names contain query" do
      it "returns matching client records" do
        query = "needle"

        matching_clients = [
          FactoryBot.create(:client, name: "Client #{query} Name"),
          FactoryBot.create(:client, name: "Client-#{query}-Name"),
          FactoryBot.create(:client, name: "Hay#{query}Stack")
        ]

        # Create some clients without the query.
        3.times do
          FactoryBot.create(:client)
        end

        expect(described_class.search_by_name(query).sort).to eq(matching_clients)
      end
    end

    context "when name equals query" do
      it "returns matching client records" do
        query = "needle"

        matching_clients = [
          FactoryBot.create(:client, name: query),
          FactoryBot.create(:client, name: query)
        ]

        # Create some clients without the query.
        3.times do
          FactoryBot.create(:client)
        end

        expect(described_class.search_by_name(query).sort).to eq(matching_clients)
      end
    end

    context "when no names match query" do
      it "returns empty results" do
        query = "needle"

        # Create some clients without the query.
        6.times do
          FactoryBot.create(:user)
        end

        expect(described_class.search_by_name(query).sort).to be_empty
      end
    end

    context "when query is not present" do
      it "returns empty results" do
        query = [nil, ""].sample

        # Create some clients without the query.
        6.times do
          FactoryBot.create(:user)
        end

        expect(described_class.search_by_name(query).sort).to be_empty
      end
    end
  end

  describe ".ordered" do
    it "returns clients in ascending order by name" do
      create(:client, name: "Zeta Corp")
      create(:client, name: "Alpha Inc")
      create(:client, name: "Omega Ltd")

      ordered_client_names = Client.ordered.pluck(:name)

      expect(ordered_client_names).to eq(["Alpha Inc", "Omega Ltd", "Zeta Corp"])
    end
  end

  describe ".by_agency_id" do
    let!(:agency1) { create(:agency) }
    let!(:client) { create(:client, agency: agency1) }
    let!(:client2) { create(:client, agency: agency1) }

    let!(:agency2) { create(:agency) }
    let!(:client_agency_2) { create(:client, agency: agency2) }

    let!(:agency3) { create(:agency) }

    context "when clients exist for the given agency" do
      it "returns clients belonging to the specified agency" do
        result = Client.by_agency_id(agency1.id)
        expect(result).to match_array([client, client2])
      end

      it "does not return clients belonging to other agencies" do
        result = Client.by_agency_id(agency1.id)
        expect(result).not_to include(client_agency_2)
      end
    end

    context "when no clients exist for the given agency" do
      it "returns an empty collection" do
        result = Client.by_agency_id(agency3.id)
        expect(result).to be_empty
      end
    end

    context "when agency_id is nil" do
      it "returns an empty collection" do
        result = Client.by_agency_id(nil)
        expect(result).to be_empty
      end
    end
  end

  describe "associations" do
    context "agency" do
      it { should belong_to(:agency).inverse_of(:clients) }
    end

    context "users" do
      it { should have_many(:users).inverse_of(:client) }
    end

    context "media_plan" do
      it { should have_one(:media_plan) }
    end

    context "media_brief_builders" do
      it { should have_many(:media_brief_builders).inverse_of(:client).dependent(:destroy) }
    end

    context "media_briefs" do
      it { should have_many(:media_briefs).inverse_of(:client).dependent(:destroy) }
    end

    context "media_mixes" do
      it { should have_many(:media_mixes).dependent(:destroy) }
    end

    context "campaigns" do
      it { should have_many(:campaigns).inverse_of(:client) }
    end

    context "documents_requests" do
      it { should have_many(:documents_requests).through(:campaigns) }
    end

    context "documents_request_users" do
      it { should have_many(:documents_request_users).through(:documents_requests) }
    end
  end

  describe "validations" do
    let(:instance) { FactoryBot.build(:client) }

    context "agency" do
      it "must be present" do
        instance.agency = nil
        expect(instance).to be_invalid

        instance.agency = FactoryBot.build(:agency)
        expect(instance).to be_valid
      end
    end

    context "name" do
      it "must be present" do
        instance.name = nil
        expect(instance).to be_invalid

        instance.name = ""
        expect(instance).to be_invalid

        instance.name = Faker::Company.name
        expect(instance).to be_valid
      end

      it "must be unique scoped to agency" do
        name = Faker::Company.name
        agency = FactoryBot.create(:agency)

        instance.name = name
        instance.agency = agency
        expect(instance).to be_valid

        FactoryBot.create(:client, name: name, agency: agency)
        expect(instance).to be_invalid

        instance.name = Faker::Company.name
        expect(instance).to be_valid

        instance.name = name
        instance.agency = FactoryBot.create(:agency)
        expect(instance).to be_valid
      end
    end

    context "contact_first_name" do
      it "must be present" do
        instance.contact_first_name = nil
        expect(instance).to be_invalid

        instance.contact_first_name = ""
        expect(instance).to be_invalid

        instance.contact_first_name = Faker::Name.first_name
        expect(instance).to be_valid
      end
    end

    context "contact_last_name" do
      it "must be present" do
        instance.contact_last_name = nil
        expect(instance).to be_invalid

        instance.contact_last_name = ""
        expect(instance).to be_invalid

        instance.contact_last_name = Faker::Name.last_name
        expect(instance).to be_valid
      end
    end

    context "contact_email" do
      it "must be present" do
        instance.contact_email = ""
        expect(instance).to be_invalid

        instance.contact_email = nil
        expect(instance).to be_invalid

        instance.contact_email = Faker::Internet.email
        expect(instance).to be_valid
      end

      it "must be an email address" do
        instance.contact_email = "email address"
        expect(instance).to be_invalid

        instance.contact_email = "email@"
        expect(instance).to be_invalid

        instance.contact_email = "@domain.com"
        expect(instance).to be_invalid

        instance.contact_email = "email@domain.com"
        expect(instance).to be_valid
      end
    end

    context "contact_position" do
      it "does not have to be present" do
        instance.contact_position = nil
        expect(instance).to be_valid

        instance.contact_position = ""
        expect(instance).to be_valid

        instance.contact_position = Faker::Job.position
        expect(instance).to be_valid
      end
    end

    context "contact_phone_number" do
      it "does not have to be present" do
        instance.contact_phone_number = nil
        expect(instance).to be_valid

        instance.contact_phone_number = ""
        expect(instance).to be_valid
      end

      context "when present" do
        it "must be numeric" do
          instance.contact_phone_number = "ABCDEFGHIJ"
          expect(instance).to be_invalid

          instance.contact_phone_number = "866NOBLSHT"
          expect(instance).to be_invalid

          instance.contact_phone_number = "6155557890"
          expect(instance).to be_valid
        end

        it "must have length of 10" do
          instance.contact_phone_number = "123456789"
          expect(instance).to be_invalid

          instance.contact_phone_number = "12345678901"
          expect(instance).to be_invalid

          instance.contact_phone_number = "1234567890"
          expect(instance).to be_valid
        end
      end
    end

    context "website" do
      it "must be present" do
        instance.website = nil
        expect(instance).to be_invalid

        instance.website = ""
        expect(instance).to be_invalid

        instance.website = Faker::Internet.url
        expect(instance).to be_valid
      end

      it "must be a url" do
        instance.website = "website"
        expect(instance).to be_invalid

        instance.website = Faker::Internet.domain_name
        expect(instance).to be_invalid

        instance.website = Faker::Internet.domain_name(subdomain: true)
        expect(instance).to be_invalid

        instance.website = Faker::Internet.url
        expect(instance).to be_valid

        instance.website = Faker::Internet.url(scheme: "https")
        expect(instance).to be_valid
      end
    end
  end

  describe "before create" do
    let(:instance) { FactoryBot.build(:client) }

    context "name" do
      it "removes whitespace" do
        name = " #{Faker::Company.name} "
        instance.name = name

        expect {
          instance.save!
        }.to change {
          instance.name
        }.to(name.strip)
      end
    end

    context "contact_first_name" do
      it "removes whitespace" do
        contact_first_name = " #{Faker::Name.first_name} "
        instance.contact_first_name = contact_first_name

        expect {
          instance.save!
        }.to change {
          instance.contact_first_name
        }.to(contact_first_name.strip)
      end
    end

    context "contact_last_name" do
      it "removes whitespace" do
        contact_last_name = " #{Faker::Name.last_name} "
        instance.contact_last_name = contact_last_name

        expect {
          instance.save!
        }.to change {
          instance.contact_last_name
        }.to(contact_last_name.strip)
      end
    end

    context "contact_email" do
      it "removes whitespace" do
        contact_email = " #{Faker::Internet.email} "
        instance.contact_email = contact_email

        expect {
          instance.save!
        }.to change {
          instance.contact_email
        }.to(contact_email.strip)
      end

      it "downcases the value" do
        contact_email = Faker::Internet.email.upcase
        instance.contact_email = contact_email

        expect {
          instance.save!
        }.to change {
          instance.contact_email
        }.to(contact_email.downcase)
      end
    end

    context "contact_position" do
      context "when empty string" do
        it "converts to nil" do
          instance.contact_position = ""

          expect {
            instance.save!
          }.to change {
            instance.contact_position
          }.to(nil)
        end
      end

      context "when present" do
        it "removes whitespace" do
          contact_position = " #{Faker::Job.position} "
          instance.contact_position = contact_position

          expect {
            instance.save!
          }.to change {
            instance.contact_position
          }.to(contact_position.strip)
        end
      end
    end

    context "contact_phone_number" do
      context "when empty string" do
        it "converts to nil" do
          instance.contact_phone_number = ""

          expect {
            instance.save!
          }.to change {
            instance.contact_phone_number
          }.to(nil)
        end
      end

      context "when present" do
        it "removes whitespace" do
          contact_phone_number = " 1234567890 "
          instance.contact_phone_number = contact_phone_number

          expect {
            instance.save!
          }.to change {
            instance.contact_phone_number
          }.to(contact_phone_number.strip)
        end

        it "removes formatting characters" do
          contact_phone_number = [
            "123-456-7890",
            "(123) 456-7890",
            "123.456.7890",
            "123 456 7890",
            "+1234567890"
          ].sample
          instance.contact_phone_number = contact_phone_number

          expect {
            instance.save!
          }.to change {
            instance.contact_phone_number
          }.to("1234567890")
        end
      end
    end

    context "website" do
      it "removes whitespace" do
        website = " #{Faker::Internet.url} "
        instance.website = website

        expect {
          instance.save!
        }.to change {
          instance.website
        }.to(website.strip)
      end

      it "downcases the value" do
        website = Faker::Internet.url.upcase
        instance.website = website

        expect {
          instance.save!
        }.to change {
          instance.website
        }.to(website.downcase)
      end
    end
  end

  describe "before update" do
    let(:instance) { FactoryBot.create(:client) }

    context "name" do
      it "removes whitespace" do
        name = " #{Faker::Company.name} "
        instance.name = name

        expect {
          instance.save!
        }.to change {
          instance.name
        }.to(name.strip)
      end
    end

    context "contact_first_name" do
      it "removes whitespace" do
        contact_first_name = " #{Faker::Name.first_name} "
        instance.contact_first_name = contact_first_name

        expect {
          instance.save!
        }.to change {
          instance.contact_first_name
        }.to(contact_first_name.strip)
      end
    end

    context "contact_last_name" do
      it "removes whitespace" do
        contact_last_name = " #{Faker::Name.last_name} "
        instance.contact_last_name = contact_last_name

        expect {
          instance.save!
        }.to change {
          instance.contact_last_name
        }.to(contact_last_name.strip)
      end
    end

    context "contact_email" do
      it "removes whitespace" do
        contact_email = " #{Faker::Internet.email} "
        instance.contact_email = contact_email

        expect {
          instance.save!
        }.to change {
          instance.contact_email
        }.to(contact_email.strip)
      end

      it "downcases the value" do
        contact_email = Faker::Internet.email.upcase
        instance.contact_email = contact_email

        expect {
          instance.save!
        }.to change {
          instance.contact_email
        }.to(contact_email.downcase)
      end
    end

    context "contact_position" do
      context "when empty string" do
        it "converts to nil" do
          instance.contact_position = ""

          expect {
            instance.save!
          }.to change {
            instance.contact_position
          }.to(nil)
        end
      end

      context "when present" do
        it "removes whitespace" do
          contact_position = " #{Faker::Job.position} "
          instance.contact_position = contact_position

          expect {
            instance.save!
          }.to change {
            instance.contact_position
          }.to(contact_position.strip)
        end
      end
    end

    context "contact_phone_number" do
      context "when empty string" do
        it "converts to nil" do
          instance.contact_phone_number = ""

          expect {
            instance.save!
          }.to change {
            instance.contact_phone_number
          }.to(nil)
        end
      end

      context "when present" do
        it "removes whitespace" do
          contact_phone_number = " 1234567890 "
          instance.contact_phone_number = contact_phone_number

          expect {
            instance.save!
          }.to change {
            instance.contact_phone_number
          }.to(contact_phone_number.strip)
        end

        it "removes formatting characters" do
          contact_phone_number = [
            "123-456-7890",
            "(123) 456-7890",
            "123.456.7890",
            "123 456 7890",
            "+1234567890"
          ].sample
          instance.contact_phone_number = contact_phone_number

          expect {
            instance.save!
          }.to change {
            instance.contact_phone_number
          }.to("1234567890")
        end
      end
    end

    context "website" do
      it "removes whitespace" do
        website = " #{Faker::Internet.url} "
        instance.website = website

        expect {
          instance.save!
        }.to change {
          instance.website
        }.to(website.strip)
      end

      it "downcases the value" do
        website = Faker::Internet.url.upcase
        instance.website = website

        expect {
          instance.save!
        }.to change {
          instance.website
        }.to(website.downcase)
      end
    end
  end

  describe "#agency_name" do
    it "returns agency name" do
      expect(subject.agency_name).to eq(subject.agency.name)
    end
  end

  describe "#contact_full_name" do
    it "returns string with contact first and last name" do
      expected_result = subject.contact_first_name + " " + subject.contact_last_name
      expect(subject.contact_full_name).to eq(expected_result)
    end
  end
end
