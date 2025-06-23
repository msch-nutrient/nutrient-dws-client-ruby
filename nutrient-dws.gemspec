# frozen_string_literal: true

require_relative 'lib/nutrient_dws/version'

Gem::Specification.new do |spec|
  spec.name = 'nutrient-dws'
  spec.version = NutrientDWS::VERSION
  spec.authors = ['Nutrient']
  spec.email = ['support@nutrient.io']

  spec.summary = 'Ruby client library for Nutrient DWS Processor API'
  spec.description = 'A Ruby gem that provides a clean, idiomatic interface for interacting with the Nutrient DWS Processor API for document processing operations like conversion, OCR, watermarking, and PDF editing.'
  spec.homepage = 'https://github.com/nutrient-io/nutrient-dws-client-ruby'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # No runtime dependencies - uses only Ruby standard library

  # Development dependencies
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'dotenv', '~> 2.8'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.21'
  spec.add_development_dependency 'webmock', '~> 3.18'
end
