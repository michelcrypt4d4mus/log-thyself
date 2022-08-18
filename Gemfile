source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

# dotenv gem should come first
gem 'dotenv-rails', groups: [:development, :test]

gem 'fx'
gem 'jsonpath'
gem 'oj'
gem "pastel"  # Part of tty we actually use
gem 'pg'
gem 'plist'
gem 'scenic'
gem 'thor'
gem 'tty'
gem 'tty-table'  # Part of tty


# Rails
gem "bootsnap", require: false  # Reduces boot times through caching; required in config/boot.rb
gem "importmap-rails"
gem "jbuilder"  # Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "puma", "~> 5.0" # Use the Puma web server [https://github.com/puma/puma]
gem "rails", "~> 7.0"
gem "sprockets-rails"
gem "stimulus-rails"  # Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "turbo-rails"  # Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]  # Windows does not include zoneinfo files, so bundle the tzinfo-data gem


# Use Sass to process CSS
# gem "sassc-rails"

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  #gem 'profile'
  gem 'pry'
  gem 'rspec-rails', '~> 5.0.0'
end

group :development do
  gem "web-console"  # Use console on exceptions pages [https://github.com/rails/web-console]
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end
