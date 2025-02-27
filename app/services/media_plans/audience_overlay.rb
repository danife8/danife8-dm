# frozen_string_literal: true

module MediaPlans
  # MediaPlans::AudienceOverlay
  class AudienceOverlay
    def initialize(media_plan)
      @media_plan = media_plan
      @media_brief = media_plan.media_brief
      @results_count = 0
      @results = []
    end

    def call
      demographics.each do |demographic|
        response = get_results(demographic).take(take).map { |r| r[:description].present? ? r[:description] : r[:name] }
        results << response
        @results_count += response.size
      end

      results.flatten.uniq
    end

    protected

    attr_accessor :media_plan, :media_brief, :results_count, :results

    def get_results(demographic)
      Simplifi::ThirdPartySegment.new.search(demographic).try(:[], :third_party_segments)
    end

    def take
      (limit - results_count) / (demographic_count - results.size)
    end

    def limit
      @limit ||= {
        3 => 21,
        4 => 24,
        5 => 25
      }[demographic_count] || 21
    end

    def demographic_count
      @demographic_count ||= demographics.count
    end

    def demographics
      (1..5).map do |i|
        prefix = media_brief.send(:"demographic_details#{i}_prefix")
        prefix_label = DemographicDetailsPrefix.find(prefix).try(:label) || ""
        details = media_brief.send(:"demographic_details#{i}")

        "#{prefix_label} #{details}".strip
      end.compact_blank
    end
  end
end
