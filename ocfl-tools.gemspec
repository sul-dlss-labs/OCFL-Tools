# frozen_string_literal: true

Gem::Specification.new do |gem|
  gem.authors       = ['Julian M. Morley']
  gem.email         = ['jmorley@stanford.edu']
  gem.description   = 'Tools to create, manipulate and write Oxford Common File Layout (OCFL) preservation objects.'
  gem.summary       = 'Tools to create, manipulate and write Oxford Common File Layout (OCFL) preservation objects.'
  gem.homepage      = 'https://github.com/sul-dlss-labs/OCFL-Tools'
  gem.licenses      = ['Apache-2.0']

  # Don't include fixtures in the gem.
  gem.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  gem.add_runtime_dependency 'anyway_config', '~> 1.0'
  gem.add_runtime_dependency 'fileutils', '~> 1.3'
  gem.add_runtime_dependency 'json', '~> 2.2', '>= 2.2.0'

  #  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  #  gem.test_files    = gem.files.grep(%r{^spec/})
  gem.name          = 'ocfl-tools'
  gem.require_paths = ['lib']
  gem.version       = File.read('VERSION').strip
  # gem.metadata["yard.run"] = "yri" # use "yard" to build full HTML docs.
  gem.add_development_dependency 'pry-byebug' unless ENV['CI']
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rubocop'
  gem.add_development_dependency 'rubocop-rspec'
end
