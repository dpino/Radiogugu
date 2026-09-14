source "https://rubygems.org"

ruby "3.2.3"

gem "rails", "~> 7.1.5"

# Classic asset pipeline (keeps the app's existing jQuery-based JS/CSS working
# without moving to Turbo/Stimulus/importmaps).
gem "sprockets-rails"

# jQuery + jquery-ujs (data-method / data-confirm support for plain links),
# replacing the vendored jquery-1.5.js / jquery-ujs that shipped with the app.
gem "jquery-rails"
gem "jquery-ui-rails"

# Use sqlite3 as the database for Active Record (all environments)
gem "sqlite3", ">= 1.4"

# Use the Puma web server
gem "puma", ">= 5.0"

# Authentication
gem "devise"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
end

group :development do
  gem "web-console"
end
