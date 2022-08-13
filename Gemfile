source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

# dotenv gem should come first
gem 'dotenv-rails', groups: [:development, :test]

gem 'fx'
gem 'gli'
gem 'jsonpath'
gem 'oj'
gem "pastel"  # Part of tty we actually use
gem 'pg'
gem 'piperator'
gem 'postgres-copy'
gem 'scenic'
gem 'thor'
gem 'tty'


# Rails
gem "importmap-rails"
gem "puma", "~> 5.0" # Use the Puma web server [https://github.com/puma/puma]
gem "rails", "~> 7.0"
gem "sprockets-rails"
gem "turbo-rails"  # Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "stimulus-rails"  # Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "jbuilder"  # Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]  # Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "bootsnap", require: false  # Reduces boot times through caching; required in config/boot.rb

# Use Sass to process CSS
# gem "sassc-rails"

group :development, :test do
  #gem 'byebug'
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
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
