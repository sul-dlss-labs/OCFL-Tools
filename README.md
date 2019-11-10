# OCFL-Tools
Ruby gem to manipulate Oxford Common File Layout preservation objects.
Classes provide APIs to create objects and versions, perform typical file operations, verify
compliance of the resulting object and serialize it to an inventory.json file.
Can also read in an existing inventory.json to verify, manipulate, and produce
an updated inventory file.

This is very much a work-in-progress PROTOTYPE and is not guaranteed to do anything more
than take up space on your storage device. Not all methods are implemented, and refactoring
is a fact of life.

## Basic Usage

```
require 'ocfl-tools'

# Set our version string format; 5 characters, 4 of which are 0-padded integers.
OcflTools.config.version_format     = "v%04d"     # default value

# Set our digest algorithm
OcflTools.config.digest_algorithm   = 'sha256'    # default is sha512

# set our object's content directory name
OcflTools.config.content_directory  = 'data'     # default is 'content'

ocfl = OcflTools::OcflInventory.new

ocfl.id = 'bb123cd4567'

ocfl.get_version(1) # Creates initial version.

ocfl.set_version_message(1, 'My first version!')
ocfl.add_file('my_content/this_is_a_file.txt', 'checksum_aaaaaaaaaaaa', 1)

# Create a new version and add a 2nd file
ocfl.add_file('my_content/a_second_file.txt', 'checksum_bbbbbbbbbbbb', 2)

# Create a third version and add a 3rd file.
ocfl.add_file('my_content/a_third_file.txt', 'checksum_cccccccccccc', 3)

# Add (optional) additional fixity checksums to an existing file:
ocfl.update_fixity('checksum_cccccccccccc', 'md5', 'an_md5_checksum_for_this_file')
ocfl.update_fixity('checksum_cccccccccccc', 'sha1', 'a_sha1_checksum_for_this_file')

# Remember we're using the digest of the file to positively identify it, which
# is why we use the digest, not the file path, to associate an additional checksum with that file.

# Output the complete inventory.json.
puts ocfl.serialize

# If you want the object output to an inventory.json file, call #to_file.
# This will also generate the appropriate digest sidecar file.
ocfl.to_file('/directory/to/put/inventory/in/')


# Check a directory for a valid OCFL object
validate = OcflTools::OcflValidator.new(object_root_dir)
puts validate.verify_structure.results  # checks the physical layout of the object root
puts validate.verify_inventory.results  # checks the syntax and internal consistency of the inventory.json
puts validate.verify_manifest.results   # cross-checks existence of files on disk against the manifest in the inventory.json
puts validate.verify_checksums.results  # checks digests in the inventory manifest against files discovered in the object root.

# Optionally, if you have additional fixity checksums in the inventory:
puts validate.verify_fixity.results                   # checks files using MD5 checksums (default).
puts validate.verify_fixity(digest: 'sha1').results   # checks files using sha1 checksums.

# If you just want to do a complete check of a suspected OCFL object root, do:
validate = OcflTools::OcflValidator.new(object_root_dir)
puts validate.validate_ocfl_object_root # Will do structure, inventory and manifest checksum checks.

# If you'd like to use values in the fixity block instead of the manifest checksums, do:
puts validate.validate_ocfl_object_root(digest: 'sha1').results


```

## Implementation notes

`OcflTools::OcflInventory` is a child class of `OcflTools::OcflObject`, designed
for reading and writing inventory.json files.

`OcflObject` will prevent you from doing the dumbest of things - once you've created
version 2 of an object, you can't edit the state of version 1 - but it won't prevent
you from the more subtle stupids. That's for implementing applications to work around
with their own business logic.

This version of OCFL-Tools implements file de-duplication. A later version will make
that a feature flag so you can disable it if you wish.

It's up to implementing applications to marshal bitstreams and write them to the appropriate directories.
OCFL-Tools just creates the inventory.json files and verifies that the content within them is correctly
formatted and, optionally, actually exists on disk. It's up to something else to put the bits on disk
where OCFL-Tools expects them to be.

`OcflTools::OcflValidator` will take a directory and tell you if it's an OCFL object or not. If it is a valid OCFL
object, `OcflValidator` will check the files on disk against the records in the inventory.json and let
you know if they are all there and have matching checksums.

`OcflTools::OcflVerify` will take an `OcflObject` and will let you know if it's syntactically correct
and internally consistent. `OcflVerify` doesn't care or know about files or directories on disk.
`OcflValidator` uses `OcflVerify` as part of its validation process, once it has identified a suitable
 inventory.json file.

`OcflTools::OcflResults` is a class to capture logging events for a specific OcflValidator or
OcflVerify instance. Any reported error (inspect `OcflResults#get_errors`) indicates the object
under consideration is not OCFL compliant.
