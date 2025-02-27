# frozen_string_literal: true

require "faraday"

module Domo
  # Manages DOMO API requests.
  class ApiClient
    # @return [String]
    def access_token
      @access_token ||= begin
        request = Faraday.new(
          url: Domo.api_base_url,
          params: {
            grant_type: "client_credentials",
            scope: "dashboard"
          }
        ) do |conn|
          conn.request :authorization,
            "Basic",
            Domo.api_client_id,
            Domo.api_client_secret
          conn.request :json
          conn.response :json
        end
        response = request.get("/oauth/token")

        unless response.success?
          raise Error, "Could not get access token - #{response.status} : #{response.body}"
        end

        response.body.fetch("access_token")
      end
    end

    # @return [String]
    def embed_token(user, domo_embed_id)
      @embed_token ||= begin
        embed_token_path = if Domo.embed_type == "dashboard"
          "/v1/stories/embed/auth"
        else
          "/v1/cards/embed/auth"
        end
        response = api_conn.post(
          embed_token_path,
          _body = {
            sessionLength: 1440,
            authorizations: [
              {
                token: domo_embed_id,
                permissions: ["READ", "FILTER", "EXPORT"],
                filters: Domo.embed_filters(user),
                policies: []
              }
            ]
          }
        )

        unless response.success?
          raise Error, "Could not get embed token - #{response.status} : #{response.body}"
        end

        response.body.fetch("authentication")
      end
    end

    private

    # @return [Faraday::Connection]
    def api_conn
      @api_conn ||= Faraday.new(url: Domo.api_base_url) do |conn|
        conn.request :authorization, "Bearer", access_token
        conn.request :json
        conn.response :json
      end
    end
  end
end
