release: bundle exec rails db:migrate
web: bundle exec puma --config config/puma.rb
worker: RAILS_MAX_THREADS=${SIDEKIQ_CONCURRENCY:-5} bundle exec sidekiq --config config/sidekiq.yml
