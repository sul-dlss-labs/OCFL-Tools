Gem::Specification.new do |gem|
  gem.authors       = ['Julian M. Morley']
  gem.email         = ['jmorley@stanford.edu']
  gem.description   = 'Tools to migrate Stanford Moab objects into OCFL objects.'
  gem.summary       = 'Tools to migrate Stanford Moab objects into OCFL objects.'
  gem.homepage      = 'https://github.com/sul-dlss-labs/OCFL-Tools'
  gem.licenses      = ['ALv2', 'Stanford University Libraries']
#
  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
#   gem.files         = [ "./lib/ocfl-tools.rb",
#                         "./lib/ocfl_tools.rb",
#                         "./lib/ocfl_tools/druid_export.rb",
#                         "./lib/ocfl_tools/moab_export.rb",
#                         "./lib/ocfl_tools/ocfl_inventory.rb"
#                       ]
#  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
#  gem.test_files    = gem.files.grep(%r{^spec/})
  gem.name          = 'ocfl-tools'
  gem.require_paths = ['lib']
  gem.version       = File.read('VERSION').strip
end
