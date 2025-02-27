source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.6"

gem "dotenv-rails", groups: [:development, :test]

gem "aasm", "~> 5.5"
gem "acts_as_paranoid", "~> 0.10"
gem "aws-sdk-s3", require: false
gem "barnes"
gem "bootsnap", require: false
gem "browser"
gem "cssbundling-rails"
gem "csv", "~> 3.3"
gem "decent_exposure", "~> 3.0"
gem "devise", "~> 4.9"
gem "devise_invitable", "~> 2.0"
gem "dropbox-sign", "~> 1.8.0"
gem "faraday", "~> 2.12"
gem "google-ads-googleads"
gem "honeybadger"
gem "image_processing", "~> 1.2"
gem "jbuilder"
gem "jsbundling-rails"
gem "nokogiri"
gem "handlebars-engine"
gem "kaminari", "~> 1.2"
gem "paper_trail", "~> 16.0"
gem "pdf-reader"
gem "pg", "~> 1.5"
gem "prawn", "~> 2.5"
gem "prawn-table", "~> 0.2.2"
gem "puma", "~> 6.5"
gem "pundit", "~> 2.4"
gem "rails", "~> 7.1.5"
gem "redis", "~> 5.3"
gem "sidekiq", "~> 7.3"
gem "sidekiq-cron"
gem "sprockets-rails"
gem "stimulus-rails"
gem "turbo-rails", "~> 2.0"
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

group :development, :test do
  gem "factory_bot_rails"
  gem "faker"
  gem "pry-rails"
  gem "pry-byebug"
  gem "rspec-rails", "~> 7.1"
  gem "shoulda-matchers", "~> 6.4"
  gem "vcr"
  gem "webmock"
end

group :development do
  gem "brakeman"
  gem "foreman"
  gem "letter_opener"
  gem "simplecov", require: false
  gem "standard"
  gem "web-console"
  gem "yard"
end
