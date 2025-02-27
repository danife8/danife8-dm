# frozen_string_literal: true

# PreviousOptions for Media Brief ComboBox step 6
class MediaBriefPreviousData
  OPTIONS = [
    {position: 1, label: "Yes", value: "yes"}.freeze,
    {position: 2, label: "No", value: "no"}.freeze,
    {position: 3, label: "I Don't Know", value: "i_don_t_know"}.freeze
  ].freeze

  def self.all
    @all ||= OPTIONS.map { |media_brief_previous_data| new(**media_brief_previous_data) }
  end

  # @param value [String] resource to find
  # @return a resource
  def self.find(value)
    all.find { |sp| sp.value == value }
  end

  attr_reader :position, :label, :value

  # @param label [String] human friendly description
  # @param value [String] value for back-end usage
  def initialize(position:, label:, value:)
    @position = position
    @label = label
    @value = value
  end
end
