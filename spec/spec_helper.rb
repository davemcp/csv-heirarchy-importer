require 'simplecov'
SimpleCov.start 'rails'

$integration = true

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

Dir[File.expand_path("support/integration/*.rb", File.dirname(__FILE__))].each { |f| require f }
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.infer_base_class_for_anonymous_controllers = false

  config.raise_errors_for_deprecations!

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    Capybara.app_host = 'lvh.me'
  end

end
