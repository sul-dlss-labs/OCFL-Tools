# OCFL-Tools
Ruby gem to manipulate Oxford Common File Layout preservation objects.
Classes provide APIs to create objects and versions, perform typical file operations, verify
compliance of the resulting object and serialize it to an inventory.json file.
Can also read in an existing inventory.json to verify, manipulate, and produce
an updated inventory file.

## Basic Usage

```
require 'ocfl-tools'

# Set our version string format; 5 characters, 4 of which are 0-padded integers.
OcflTools::Utils::VERSION_FORMAT = "v%04d"

ocfl = OcflTools::OcflInventory.new

ocfl.id = 'bb123cd4567'

ocfl.get_version(1) # Creates initial version.

ocfl.set_version_message(1, 'My first version!')
ocfl.add_file('my_content/this_is_a_file.txt', 'checksum_aaaaaaaaaaaa', 1)

# Create a new version and add a 2nd file
ocfl.add_file('my_content/a_second_file.txt', 'checksum_bbbbbbbbbbbb', 2)

# Create a third version and add a 3rd file.
ocfl.add_file('my_content/a_third_file.txt', 'checksum_cccccccccccc', 3)

# Output the complete inventory.json.
puts ocfl.serialize

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
