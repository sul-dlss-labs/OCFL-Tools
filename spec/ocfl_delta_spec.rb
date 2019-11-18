require 'ocfl-tools'
require 'digest'

describe OcflTools::OcflDelta do
  # Run after ocf_deposit_spec, so we can use that deposit object example.
  basedir     = Dir.pwd
  # set site-specific settings.
  OcflTools.config.content_directory  = 'content'
  OcflTools.config.digest_algorithm   = 'sha256'
  OcflTools.config.version_format     =  "v%04d"

  object_dir  =  "#{basedir}/spec/fixtures/deposit/object_c"

  ocfl = OcflTools::OcflInventory.new.from_file("#{object_dir}/inventory.json")

  ocfl_delta = OcflTools::OcflDelta.new(ocfl)

  puts "delta 1:"
  ocfl_delta.previous(1)
  puts "delta 2:"
  ocfl_delta.previous(2)
  puts "delta 3:"
  ocfl_delta.previous(3)
  puts "delta 4:"
  ocfl_delta.previous(4)

  puts "   "
#  puts ocfl_delta.delta

puts JSON.pretty_generate(ocfl_delta.delta)

end
