Gem::Specification.new do |gem|
  gem.authors       = ['Julian M. Morley']
  gem.email         = ['jmorley@stanford.edu']
  gem.description   = 'Tools to migrate Stanford Moab objects into OCFL objects.'
  gem.summary       = 'Tools to migrate Stanford Moab objects into OCFL objects.'
  gem.homepage      = 'https://github.com/sul-dlss-labs/OCFL-Tools'
  gem.licenses      = ['Apache-2.0', 'Stanford University Libraries']

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)

  gem.add_runtime_dependency 'json', '~> 2.2', '>= 2.2.0'
  gem.add_runtime_dependency 'druid-tools',  '~> 2.1', '>= 2.1.0'
  gem.add_runtime_dependency 'nokogiri', '~> 1.10', '>= 1.10.0'
  gem.add_runtime_dependency 'moab-versioning', '~> 4.2', '>= 4.2.2'

#  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
#  gem.test_files    = gem.files.grep(%r{^spec/})
  gem.name          = 'ocfl-tools'
  gem.require_paths = ['lib']
  gem.version       = File.read('VERSION').strip
end
