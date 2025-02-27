# frozen_string_literal: true

require "google/ads/google_ads"
require "aws-sdk-s3"

module MediaPlans
  class KeywordGenerator
    GEO_TARGETS = ENV.fetch("GEO_TARGETS", "2840").split(",")

    def initialize(media_plan)
      @media_plan = media_plan
    end

    def call
      service = client.service.keyword_plan_idea

      url_seed = client.resource.url_seed do |seed|
        seed.url = media_plan.media_brief.destination_url
      end

      options = {url_seed:}

      include_adult_keywords = false

      geo_target_constants = GEO_TARGETS.map do |location_id|
        client.path.geo_target_constant(location_id)
      end

      service_call = service.generate_keyword_ideas(
        customer_id: ENV.fetch("GOOGLE_ADS_CUSTOMER_ID").tr("-", ""),
        language: client.path.language_constant(1000),
        geo_target_constants:,
        include_adult_keywords:,
        # To restrict to only Google Search, change the parameter below to
        # :GOOGLE_SEARCH
        keyword_plan_network: :GOOGLE_SEARCH_AND_PARTNERS,
        **options
      )

      service_call.response.results.take(20).map do |result|
        result.text
      end
    rescue Google::Ads::GoogleAds::Errors::GoogleAdsError, StandardError
      []
    end

    protected

    attr_accessor :media_plan

    def client
      @client ||= Google::Ads::GoogleAds::GoogleAdsClient.new do |c|
        c.treat_deprecation_warnings_as_errors = false
        c.warn_on_all_deprecations = false
        c.developer_token = ENV.fetch("GOOGLE_ADS_DEVELOPER_TOKEN")
        c.keyfile = keyfile
        c.impersonate = ENV.fetch("GOOGLE_ADS_IMPERSONATE")
        c.login_customer_id = ENV.fetch("GOOGLE_ADS_LOGIN_CUSTOMER_ID", "").tr("-", "")
        c.log_level = "WARN"
      end
    end

    def keyfile
      temp_file = Tempfile.new(["keyfile", ".json"])
      s3_client.get_object({bucket: ENV.fetch("AWS_BUCKET"), key: ENV.fetch("GOOGLE_KEYFILE")}, target: temp_file.path)
      temp_file.path
    end

    def s3_client
      @s3_client ||= Aws::S3::Client.new(
        region: ENV.fetch("AWS_REGION", "us-east-1"),
        access_key_id: ENV.fetch("AWS_ACCESS_KEY_ID", ""),
        secret_access_key: ENV.fetch("AWS_SECRET_ACCESS_KEY", "")
      )
    end
  end
end
