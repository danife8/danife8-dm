# frozen_string_literal: true

# DOMO API namespace
module Domo
  # @return [String]
  def self.get_embed_token(user, domo_embed_id)
    ApiClient.new.embed_token(user, domo_embed_id)
  end

  #####
  # Config values
  #####

  # @return [String]
  def self.api_client_id
    ENV.fetch("DOMO_API_CLIENT_ID", "ABC123")
  end

  # @return [String]
  def self.api_client_secret
    ENV.fetch("DOMO_API_CLIENT_SECRET", "DEF456")
  end

  # @return [String]
  def self.api_base_url
    "https://api.domo.com"
  end

  # @return [String]
  def self.embed_url
    @embed_url ||= "https://public.domo.com" + (
      (embed_type == "dashboard") ? "/embed/pages/" : "/cards/"
    )
  end

  # @return [String]
  def self.embed_type
    ENV.fetch("DOMO_EMBED_TYPE", "dashboard")
  end

  # Programmatic filters
  # @return [Array]
  def self.embed_filters(user)
    EmbedFilters.new(user).call
  end
end
