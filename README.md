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
OcflTools.config.version_format     = "v%04d"     # default value, yields 'v0001' etc.

# Set our digest algorithm
OcflTools.config.digest_algorithm   = 'sha256'    # default is sha512

# set our object's content directory name
OcflTools.config.content_directory  = 'data'     # default is 'content'

# Optionally, set allowed digest algorithms for the fixity block.
OcflTools.config.fixity_algorithms  = ['md5', 'sha1', 'sha256'] # default values

ocfl = OcflTools::OcflInventory.new

ocfl.id = 'bb123cd4567'

ocfl.get_version(1) # Creates initial version.

ocfl.set_version_message(1, 'My first version!')
ocfl.add_file('my_content/this_is_a_file.txt', 'checksum_aaaaaaaaaaaa', 1)

# Create a new version and add a 2nd file
ocfl.add_file('my_content/a_second_file.txt', 'checksum_bbbbbbbbbbbb', 2)

# Create a third version and add a 3rd file.
ocfl.add_file('my_content/a_third_file.txt', 'checksum_cccccccccccc', 3)

# Make a (deduplicated) copy of that 3rd file in version 3.
ocfl.copy_file('my_content/a_third_file.txt', 'my_content/a_copy_of_third_file.txt', 3)

# or if you don't want to deduplicate the file, this also works:
ocfl.add_file('my_content/a_copy_of_third_file.txt', 'checksum_cccccccccccc', 3)

# Delete a file from version 3.
ocfl.delete_file('my_content/this_is_a_file.txt', 3)

# Create a 4th version where the bitstream of an existing file is modified:
ocfl.update_file('my_content/a_second_file.txt', 'checksum_dddddddddddd', 4)

# Still in version 4, move a file to a new location (functionally an add-then-delete).
ocfl.move_file('my_content/a_copy_of_third_file.txt', 'another_dir/a_copy_of_third_file.txt', 4)

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

## Depositing and Updating Objects

This gem includes basic deposit and update functionality. It requires content for deposit
to be arranged in a specific syntax in a `deposit` directory. The `deposit` directory can
be any name, but MUST contain a 'head' directory, which MUST contain a directory with a name
that matches your site's `OcflTools::config.content_directory` setting (defaults to `content`).

### First Version

If this is to be the first version of a new OCFL object you MUST provide at least one file
in the `content` directory to add, and you MUST include the `head/add_files.json` file (described below).
The first version of an OCFL object MAY also contain fixity information; provide a `head/fixity_files.json` with details, but MUST NOT include any other action files (e.g `delete_files.json`, `copy_files.json`). Finally, the `deposit` directory must contain a NAMasTE file, in the format of `4={id value}`, describing the digital object identifier to use to uniquely identify this OCFL object at
this site. An example layout, where the id of the OCFL object being created is `123cd4567`, is below. In
this example the site is using the default value `content` for `content_directory`.

```
deposit_dir/
  4=123cd4567
  head/
    add_files.json
    fixity_files.json [optional]
    content/
      my_content/a_file_to_add.txt
```

### Subsequent versions of an existing object

To version an existing object, you must provide a `deposit` directory with the following layout:

```
deposit_dir/
  inventory.json
  inventory.json.{sha256|sha512}
  head/
    {action files}
    content/
      {files and directories to or update, if applicable}
```

`{action files}` are AT LEAST ONE of `add_files.json`, `delete_files.json`, `update_files.json`,
`move_files.json`,  `copy_files.json` and `fixity_files.json`.

The `inventory.json` and sidecar digest file must be the most recent versions of the inventory and
sidecar from the OCFL object that you are updating, copied from the object root that you intend
to update. New version creation will fail if the destination object directory does not contain
the expected OCFL object at the `head` value of this `inventory.json`.

The `head/content` directory MUST exist, but is not required to contain any bitstreams unless there
is a correctly-formatted `add_files.json` or `update_files.json`.

Note that it is possible to version an object merely by providing a `fixity_files.json`.

### Add files

Create a file named `add_files.json` and place in `deposit/head`. Place the file to be added
to the object in `deposit/head/{content_directory}` in the desired directory structure. If multiple
filepaths are provided for any one digest value, and if only one matching bitstream is provided in `head/content`, then the file is deduplicated and only 1 bitstream of that file will exist in the final object version.

```
{ "digest of file to add": [ filepaths of file to add ] }

e.g.:

{
  "9b4566a0455e76a392c43ec4d8b8e7d636b21ff2cf83b87fe99b97d00a501de0": [
    "my_content/dunwich.txt",
    "my_content/a_deduplicated_copy_of_dunwich.txt"
  ]
}
```

### Update files

Create a file named `update_files.json` and place in `deposit/head`. Place the updated file
in `deposit/head/{content_directory}` in the desired directory structure.

```
{ "digest of file to update": [ existing filepaths of file to update ] }

e.g.: this updates the previously versioned file 'my_content/dunwich.txt' with a new bitstream:

{
  "334566a04a5e76a392c43ec4d8b8e7d666f1ff2cf83b87fe99b97d00a5443f43": [
    "my_content/dunwich.txt"
  ]
}
```

### Copy files

Create a file named `copy_files.json` and place in `deposit/head`. This makes a deduplicated
copy of a bitstream that already exists in the object. If you do NOT want to make a deduplicated
copy, use `add_files.json` instead, and provide the bitstream in `deposit/head/{content_directory}`.

```
{ "filepath of existing file": [ filepaths of new copies ] }

e.g.

{
  "my_content/dunwich.txt": [
    "my_content/a_second_copy_of_dunwich.txt",
    "my_content/a_third_copy_of_dunwich.txt"
  ]
}

```

### Move files

Create a file named `move_files.json` and place in `deposit/head`. Note that `move_files.json` does
not take an array of files as a value. It's a 1:1 mapping of source and destination filepaths.

```
{ "filepath of old file location": "filepath of new file location" }

e.g.

{
  "my_content/a_third_copy_of_dunwich.txt":
    "my_content/moved_third_copy_of_dunwich_to_here.txt"
}

```

### Delete files

Create a file named `delete_files.json` and place in `deposit/head`. Note that `delete_files.json`
only contains one key, `delete`, with an array of values.

```
{ "delete": [ filepaths of files to delete ] }

e.g.

{ "delete": [
  "my_content/a_third_copy_of_dunwich.txt",
  "my_content/moved_third_copy_of_dunwich_to_here.txt"
 ]
}

```

### Add additional fixity values to object

Create a file named `fixity_files.json` and place in `deposit/head`. The top level keys of this JSON
should be the string value of the digest algorithm to add. Each key contains a hash of key/value pairs,
where the key is the string value of the file digest as recorded in the manifest (i.e. either SHA256 or SHA512), and the value is the additional file digest to associate with this file as an additional fixity value. Note that you do not need to provide fixity values for all existing files in the object, and you
can mix-and-match digest algorithms so long as the algorithm is listed as a supported value in your site.

```
{
  "md5": {
  "cffe55838a878a29da82a0e10b2909b7e46b6f7167ed7f815782465573e98f27": "fccd3f96d461f495a3bef31dc1d28f01",
  "f512eb0a032f562225e848ce88449895f3ec19f3d4836a80df80c77c74557bab": "d2c79c8519af858fac2993c2373b5203"
  },
  "sha1": {
  "f512eb0a032f562225e848ce88449895f3ec19f3d4836a80df80c77c74557bab": "aa9e59cde167454f1f8b1f0eeeb0795e2d2f8c6f"
  }
}
```

### Accessioning a version

Once the content to be accessioned is marshaled correctly in the `deposit` directory,
simply do:

```
# Creating this object performs extensive sanity checks on both deposit layout and destination.
# Any error will cause it to raise an exception and perform no action on the destination object.

deposit = OcflTools::OcflDeposit.new(deposit_directory: deposit_dir, object_directory: object_dir)

# This creates the new version and verifies successful accessioning.
deposit.deposit_new_version

# This returns a results object with additional details.
deposit.results
```

Note that for the first version of an object, the destination `object_directory` MUST be empty.


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
