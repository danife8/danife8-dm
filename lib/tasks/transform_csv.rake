require "csv_transformer"

namespace :csv do
  desc "Clean and Parameterize CSV files"
  task :transform, [:file] => :environment do |t, args|
    if args[:file].nil? || args[:file].empty?
      puts "ERROR: Please provide a file path as an argument."
      exit 1
    end

    formatted_date = Date.today.strftime("%Y%m%d") # YYYYMMDD
    input_file = args[:file]
    output_file = args[:file].gsub("raw", "parsed").gsub(".csv", "_#{formatted_date}.csv")

    CsvTransformer.process_csv(input_file, output_file)
  end
end
