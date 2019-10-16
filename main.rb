
require 'druid-tools'
require 'moab'
# Need moab/stanford for proper druid_tree parsing.
require 'moab/stanford'

Dir[File.join(__dir__, 'lib', '*.rb')].each { |file| require file }

Moab::Config.configure do
  storage_roots ['/Users/jmorley/Documents/source3']
  storage_trunk 'sdr2objects'
  deposit_trunk 'deposit'
  # path_method 'druid_tree'  # druid_tree is the default path_method
end

druid='bj102hs9687' # 3 vers
#druid='bz514sm9647' # 3 vers
#druid='jj925bx9565' # 2 vers

# Get the location of the storage object on disk
path = Moab::StorageServices.object_path( druid )
# Now make a Moab object using that path and druid
moab = Moab::StorageObject.new( druid , path )

export = OcflTools::MoabExport.new(moab)

# puts all changes from all versions in human-readable output.
export.print_deltas

export.digest = 'sha256'

puts "Show all changes in version 3"
puts export.get_deltas[3]

puts "Show files added in version 2"
puts export.get_deltas[2]['added']
