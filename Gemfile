# Gemfile for Redmine Move Comments Plugin

# This Gemfile is used for plugin development and testing
# In production, Redmine will handle all dependencies

source 'https://rubygems.org'

# Development dependencies
group :development do
  gem 'rubocop', '~> 1.0', require: false
  gem 'rubocop-rails', require: false
end

# Test dependencies
group :test do
  gem 'rspec', '~> 3.0'
  gem 'rspec-rails'
  gem 'factory_bot_rails'
end

# Development and test
group :development, :test do
  gem 'pry'
  gem 'pry-rails'
end

# Note: Redmine core dependencies are managed by the main Redmine application
# This Gemfile only includes plugin-specific development and testing gems