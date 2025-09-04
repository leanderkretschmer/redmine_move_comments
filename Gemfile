# Gemfile for Redmine Move Comments Plugin

# This Gemfile is used for plugin development and testing
# In production, Redmine will handle all dependencies
# Note: Avoid gems that are already included in Redmine's main Gemfile

source 'https://rubygems.org'

# Test dependencies (only gems not in Redmine's Gemfile)
group :test do
  gem 'rspec', '~> 3.0'
  gem 'factory_bot_rails'
end

# Development and test dependencies
group :development, :test do
  gem 'pry'
end

# Note: Redmine core dependencies are managed by the main Redmine application
# This Gemfile only includes plugin-specific development and testing gems