require "date"
require "csv"

module CsvTransformer
  HEADER_MAPPING = {
    "ID" => "id",
    "Objective" => "campaign_objective",
    "Objective Type" => "campaign_initiative",
    "Target Strategy" => "target_strategy",
    "Target" => "target",
    "Priority" => "priority",
    "Channel" => "campaign_channel",
    "Platform" => "media_platform",
    "Format" => "ad_format",
    "CPM" => "cpm"
  }.freeze

  SPECIAL_CASES_MAPPING = {
    "Ad Groups/Keywords" => "ad_group_keywords", # Target Strategy
    "Activites & Topics" => "activities_topics", # Target
    "Streaming Audio" => "audio", # Campaign Channel,
    # Campaign Initiatives
    "Promo/Giveaway" => "promotion",
    "New Product Launch" => "product_launch",
    "Site Traffic" => "traffic",
    "App Downloads" => "app_download",
    "Appointments" => "appointment",
    "Coupon" => "coupon_download",
    "Ecom" => "ecommerce",
    "File Downloads" => "file_download",
    "In-Store Visits" => "instore_visit"
  }.freeze

  def self.remove_na_values(value)
    (value == "NA" || value == "N/A") ? nil : value
  end

  def self.parameterize_value(value)
    return nil if value.nil?

    SPECIAL_CASES_MAPPING[value] || value.gsub("*", " star").parameterize.underscore
  end

  def self.row_blank?(row)
    row.to_hash.values.all?(&:blank?)
  end

  def self.process_csv(input_file, output_file)
    CSV.open(output_file, "wb") do |csv|
      puts "-> CSV processing started"
      headers_written = false

      CSV.foreach(input_file, headers: true) do |row|
        next if row_blank?(row)  # Skip row where all values are empty or nil at the beginning

        row.delete_if { |field, value| field.nil? || field.strip.empty? }
        transformed_row = row.headers.map { |header| HEADER_MAPPING[header] }
        row = row.to_hash.transform_keys { |header| HEADER_MAPPING[header] }
        row.each { |key, value| row[key] = parameterize_value(remove_na_values(value)) }

        csv << transformed_row unless headers_written
        headers_written = true

        row_became_blank = row_blank?(row)
        csv << row.values unless row_became_blank
        puts "-> Final Row #{row_became_blank ? "Skipped" : "Transformed"}: '#{row.values}'\n"
      end
    end
    puts "-> CSV processing completed successfully. File saved as: '#{output_file}'"
  rescue Errno::ENOENT
    puts "ERROR: File '#{input_file}' not found."
  end
end
