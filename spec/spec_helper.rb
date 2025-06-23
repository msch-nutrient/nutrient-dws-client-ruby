# frozen_string_literal: true

require 'dotenv/load'
require 'nutrient_dws'

# Load custom matchers
Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Skip tests that require API key if not provided
  config.filter_run_excluding :integration unless ENV['NUTRIENT_API_KEY']

  if ENV['NUTRIENT_API_KEY'].nil?
    config.before(:suite) do
      puts 'WARNING: No NUTRIENT_API_KEY found. Integration tests will be skipped.'
      puts 'Create a .env file with NUTRIENT_API_KEY=your_key_here to run integration tests.'
    end
  end
end
