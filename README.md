# OCFL-Tools
Ruby gem to create OCFL objects from existing Moabs.

## Usage

Require the gem and configure Moab to point at one or more storage roots.

```
require 'ocfl-tools'

Moab::Config.configure do
  storage_roots ['/Users/jmorley/Documents/source3']
  storage_trunk 'sdr2objects'
  deposit_trunk 'deposit'
  # path_method 'druid_tree'  # druid_tree is the default path_method
end

druid='bj102hs9687' # 3 vers
```

For an all-in-one creation of an OCFL inventory file and digest, do:
```
OcflTools::DruidExport.new(druid).make_inventory
```

To control where the inventory and digest files are created, do:
```
ocfl = OcflTools::DruidExport.new(druid)
ocfl.export_directory = '/some/path/for/inventory'
ocfl.make_inventory
```

More fine-grained control can be done like this:
```
# Find & create a Moab object from content on disk
path = Moab::StorageServices.object_path(druid)
moab = Moab::StorageObject.new(druid , path)

export = OcflTools::MoabExport.new(moab)

# We want to extract sha256 digests.
export.digest = 'sha256'

ocfl = OcflTools::OcflInventory.new(export.digital_object_id, export.current_version_id)

ocfl.versions = export.generate_ocfl_versions
ocfl.manifest = export.generate_ocfl_manifest
# We'd also like to extract the md5 digests for additional fixity.
export.digest = 'md5'
ocfl.fixity = export.generate_ocfl_fixity

ocfl.to_file(path)
```
