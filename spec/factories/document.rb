FactoryBot.define do
  factory :document do
    file { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.pdf"), "application/pdf") }
    title { File.basename(file.original_filename.to_s, ".*") }
    insertion_order { :insertion_order }
    files_for { nil }
  end
end
