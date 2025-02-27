# frozen_string_literal: true

module Simplifi
  class ThirdPartySegment < Base
    def search(str, page = 1)
      get("/third_party_segments/search", {page:, search_term: str})
    end
  end
end
