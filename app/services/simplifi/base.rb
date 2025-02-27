# frozen_string_literal: true

module Simplifi
  class Base
    ENDPOINT = "https://app.simpli.fi/api/organizations/#{ENV.fetch("SIMPLIFI_ORGANIZATION_ID", "")}"

    def get(path, params = {})
      url = URI(ENDPOINT + "#{path}?#{URI.encode_www_form(params)}")
      res = Net::HTTP.get(url, headers)

      JSON.parse(res).deep_symbolize_keys
    rescue
      {}
    end

    protected

    def headers
      {
        "X-App-Key": ENV.fetch("SIMPLIFI_APP_KEY", ""),
        "X-User-Key": ENV.fetch("SIMPLIFI_USER_KEY", "")
      }
    end
  end
end
