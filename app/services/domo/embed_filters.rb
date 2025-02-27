module Domo
  class EmbedFilters
    # @param user [User] the current user
    def initialize(user)
      @user = user
    end

    attr_reader :user

    # @return [Array<Hash>]
    def call
      return [] if skip_filters?

      filters = [common_agency_filter]
      filters.concat(role_specific_filters)
      filters
    end

    private

    # Determines if filters should be skipped for certain users
    # @return [TrueClass,FalseClass]
    def skip_filters?
      user.super_admin? || user.admin? || user.account_manager? || user.campaign_manager? || user.reviewer? || user.employee?
    end

    # Common DM Agency filter for "Agency Admin", "Agency User" and "Client User"
    # @return [Hash]
    def common_agency_filter
      {
        column: "DM Agency",
        operator: "EQUALS",
        values: [user.agency_name]
      }
    end

    # Role-specific filters
    # @return [Array<Hash>]
    def role_specific_filters
      if user.agency_user?
        agency_user_filters
      elsif user.client_user?
        client_user_filters
      else
        []
      end
    end

    # @return [Array<Hash>]
    def agency_user_filters
      return [] unless user.own_clients.any?

      [
        {
          column: "DM Client",
          operator: "IN",
          values: user.own_clients.pluck(:name)
        }
      ]
    end

    # @return [Array<Hash>]
    def client_user_filters
      filters = [
        {
          column: "DM Client",
          operator: "EQUALS",
          values: [user.client_name]
        }
      ]

      campaign_labels = user.client_document_request_campaigns.pluck(:label)
      if campaign_labels.any?
        filters << {
          column: "DM Campaign",
          operator: "IN",
          values: campaign_labels
        }
      end

      filters
    end
  end
end
