# OCFL-Tools

[![Build Status](https://travis-ci.org/sul-dlss-labs/OCFL-Tools.svg?branch=master)](https://travis-ci.org/sul-dlss-labs/OCFL-Tools)

Ruby gem to manipulate Oxford Common File Layout preservation objects (https://ocfl.io).
Classes provide APIs to create objects and versions, perform typical file operations, verify
compliance of the resulting object and serialize it to an inventory.json file.
Can also read in an existing inventory.json to verify, manipulate, and produce
an updated inventory file.

This is beta software. No guarantee of fitness for purpose is made.

## Quickstart

### Install Ruby > 2.5.3

See: https://www.ruby-lang.org/en/documentation/installation/

### Install OCFL-Tools gem

Ruby gems is part of all modern distributions of Ruby.

```
gem install ocfl-tools
```

### Get the example scripts
```
wget https://raw.githubusercontent.com/sul-dlss-labs/OCFL-Tools/master/examples/list_files.rb
wget https://raw.githubusercontent.com/sul-dlss-labs/OCFL-Tools/master/examples/validate_object.rb
```

### Checkout a copy of the OCFL Sample Fixtures
```
git clone https://github.com/OCFL/fixtures.git
```

### Validate a fixture

From the directory you downloaded the example scripts to, do:
```
ruby ./validate_object.rb -d /[full path to fixture checkout dir]/fixtures/1.0/objects/of3
```

### List all files in latest version of a fixture

From the directory you downloaded the example scripts to, do:
```
ruby ./list_files.rb -d /[full path to fixture checkout dir]/fixtures/1.0/objects/of3
```

### List all files in version 1 of a fixture

From the directory you downloaded the example scripts to, do:
```
ruby ./list_files.rb -d /[full path to fixture checkout dir]/fixtures/1.0/objects/of3 -v 1
```



## Development setup (assuming bundler is installed)

```
git clone https://github.com/sul-dlss-labs/OCFL-Tools.git
cd OCFL-Tools
bundle # to install dependencies
rake # to run rspec/rubocop
```

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

# Create a 4th version where the bitstream of an existing file is modified.
# 1. add the file's bitstream to the object:
ocfl.update_manifest('my_content/a_second_file.txt', 'checksum_dddddddddddd', 4)

# 2. Update an existing logical filepath to point to the new bitstream.
ocfl.update_file('my_content/a_second_file.txt', 'checksum_dddddddddddd', 4)

# Still in version 4, move a file to a new location (functionally an add-then-delete).
ocfl.move_file('my_content/a_copy_of_third_file.txt', 'another_dir/a_copy_of_third_file.txt', 4)

# Add (optional) additional fixity checksums to an existing file:
ocfl.update_fixity('checksum_cccccccccccc', 'md5', 'an_md5_checksum_for_this_file')
ocfl.update_fixity('checksum_cccccccccccc', 'sha1', 'a_sha1_checksum_for_this_file')

# Remember we're using the digest of the file to positively identify it, which
# is why we use the digest, not the file path, to associate an additional checksum with that file.
# The actual fixity block in the inventory will include an array of all files
# for which the checksum applies.

# Output the complete inventory.json.
puts ocfl.serialize

# If you want the object output to an inventory.json file, call #to_file.
# This will also generate the appropriate digest sidecar file.
ocfl.to_file('/directory/to/put/inventory/in/')

```

## Validating OCFL objects

The prime use case of this gem is to inspect directories for well-formed OCFL objects
and perform verification actions on them: ensuring that they are syntactically correct and
that all files referenced in the OCFL object exist on disk and match their stored digest values.

There are four levels of verification available, each checking a different aspect of the OCFL object.

### Verify Structure

This check inspects a given directory on disk for "OCFL-ness". It attempts to deduce the version
directory naming convention, checks for the presence of required OCFL files (primarily the inventory.json, sidecar digest and NamAsTe identifier), and verifies that there is a complete
sequence of version directories present.

### Verify Inventory

This check takes an inventory file discovered by `#verify_structure` and checks it for format
and internal consistency. It also verifies that every file mentioned in every version state block
can be associated with its matching file in the manifest block. By default it acts on the
`inventory.json` in the object root, but it can also be directed at any of the inventories
in any version directory.

### Verify Manifest

This check verifies that all files mentioned in the manifest block exist on disk in the given
object directory, and that all files on disk for all versions of the given inventory file can
be associated with a matching record in the manifest. It does not perform checksum verification
of these files, and thus is appropriate for the quick initial identification and verification of
large volumes of suspected OCFL objects. Note that `#verify_manifest` confines itself to versions
discovered in the `inventory.json`, so if an object directory contains more version directories,
`#verify_manifest` will not inspect those directories. `#verify_structure` will, however, detect
this issue as an error condition.

### Verify Checksums

This is a potentially resource-intensive check that computes new digest values for each file discovered
on disk and compares them against values stored in the manifest block of the provided `inventory.json`.
 It reports problems if a given checksum does not match the stored value, or if a file is discovered
 on disk that does not have a record in the manifest block, or if a file in the manifest block cannot
 be found on disk.

For larger objects, or as part of a deposit workflow, it is possible to call `#verify_checksum` against
the contents of one version directory only. See `OcflValidator#verify_directory` for details. This method
is used by `OcflDeposit` to verify successful transfer of a new version directory without invoking a full
checksum validation of all existing version directories in the destination object.

### Verify Fixity (optional)

Additionally, if a given `inventory.json` contains an optional fixity block, it is possible to perform
a `#verify_checksums` check against the files on disk, except using values and digest types stored in
the fixity block instead of the OCFL digest algorithm. Since a fixity block is optional, and is not
required to hold values for every file in the manifest, this check should not be considered a primary
method for checksum validation.

```

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
puts validate.validate_ocfl_object_root.results # Will do structure, inventory and manifest checksum checks.

# If you'd like to use values in the fixity block instead of the manifest checksums, do:
puts validate.validate_ocfl_object_root(digest: 'sha1').results


```

## Depositing and Updating Objects

This gem includes basic deposit and update functionality. It requires content for deposit
to be arranged in a specific syntax in a `deposit` directory. The `deposit` directory can
be any name, but MUST contain a `head` directory, which MUST contain a directory with a name
that matches your site's `OcflTools::config.content_directory` setting (defaults to `content`).

### First Version

If this is to be the first version of a new OCFL object you MUST provide at least one file
in the `head/content/` directory to add, and you MUST include either a `head/head.json` OR a
`head/add_files.json` file (but not both - see below for format descriptions).

If the logical paths of the files being ingested DO NOT match the physical path of the files
as laid out in the `head/content/` directory, then you MUST include an `update_manifest` stanza
in `head/head.json` (if used) or a `head/update_manifest.json` file. If the logical paths
match the physical paths (that is, if the directory structure in `head/content` matches how you
  wish the object directory layout to appear after versioning) then you need not include an
  `update_manifest` stanza in `head.json` or use an `update_manifest.json` action file ;
  `OcflTools::OcflDeposit` will use the `add` stanza or contents of `add_files.json` to both
  create the logical path and update the manifest block with the appropriate physical path.

The first version of an OCFL object MAY contain fixity and version metadata; provide this information
either as part of the `head/head.json` file or, if you are not using `head.json`, provide this in
`head/fixity_files.json` and `head/version.json`.

The first version of an OCFL object MAY have MOVE and COPY actions performed against digests in it,
either as stanzas in the `head.json` file or as stand-alone `copy_files.json` and `move_files.json`
if a `head.json` is not used, but the `head.json` MUST NOT contain DELETE actions and you MUST NOT
use a `head/delete_files.json`.

Finally, the `deposit` directory must contain a NAMasTE file, in the format of `4={id value}`,
describing the digital object identifier to use to uniquely identify this OCFL object at
this site. An example layout, where the id of the OCFL object being created is `123cd4567`, is below. In
this example the site is using the default value `content` for `content_directory`.

Note that, within an object version, actions are processed in the following order: UPDATE_MANIFEST, ADD,
UPDATE, MOVE, COPY, DELETE. This is to support the ingest of bitstreams where the logical filepath
needs to differ from the physical (deposit directory `head/content`) layout.

```
deposit_dir/
  4=123cd4567
  head/
    head.json OR add_files.json
    update_manifest.json [optional, if add_files.json is used]
    move_files.json      [optional, if add_files.json is used]
    copy_files.json      [optional, if add_files.json is used]
    version.json         [optional, if add_files.json is used]
    fixity_files.json    [optional, if add_files.json is used]
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
    head.json OR [one or more action files]
    content/
      {files and directories to add or update, if applicable}
```

`{action files}` are AT LEAST ONE of `update_manifest`, `add_files.json`, `delete_files.json`,
`update_files.json`, `move_files.json`, `copy_files.json` and `fixity_files.json`.
You may also optionally include `version.json`, but this file does not count towards
the minimum required action files requirement.

The `inventory.json` and sidecar digest file must be the most recent versions of the inventory and
sidecar from the OCFL object that you are updating, copied from the object root that you intend
to update. New version creation will fail if the destination object directory does not contain
the expected OCFL object at the `head` value of this `inventory.json`.

The `head/content` directory MUST exist, but is not required to contain any bitstreams unless there
is a correctly-formatted `add_files.json` or `update_files.json`.

Note that it is possible to version an object merely by providing a `fixity_files.json`.

### Update Manifest

Create a file named `update_manifest.json` and place in `deposit/head`. Place the bitstream to be
added to the object in the content directory, and reference that bitstream in `update_manifest.json`
with the following syntax:

```

{
  "9b4566a0455e76a392c43ec4d8b8e7d636b21ff2cf83b87fe99b97d00a501de0": [
    "my_content/dunwich.txt"
  ]
}

```

Note that this example, and all others in this doc, use the sha256 algorithm for digest values, for
easier legibility. Also note that the file path is relative to the object's content directory. The file
path for the above example relative to the deposit root directory would be `head/content/my_content/dunwich.txt`.

### Add files

Create a file named `add_files.json` and place in `deposit/head`. Place the file to be added
to the object in `deposit/head/{content_directory}` in the desired directory structure. If multiple
filepaths are provided for any one digest value, and if only one matching bitstream is provided
in `head/content`, then the file is deduplicated and only 1 bitstream of that file will exist
in the final object version.

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
{ "digest of an existing file": [ filepaths of new copies ] }

e.g.

{
  "9b4566a0455e76a392c43ec4d8b8e7d636b21ff2cf83b87fe99b97d00a501de0": [
    "my_content/a_second_copy_of_dunwich.txt",
    "my_content/a_third_copy_of_dunwich.txt"
  ]
}

```

### Move files

`move` is functionally a rename operation, performed by creating a new filepath for the digest
and then deleting the old one.

Create a file named `move_files.json` and place in `deposit/head`. Note that `move_files.json`
requires exactly 2 filepaths per digest; a source and a destination. It also will fail if
the previous version has more than one filepath recorded for this digest; this is to prevent a
Disambiguation issue when reconstructing file actions from the inventory file.

If you wish to move a specific filepath instance where there are multiple source filepaths in
the prior version, perform a `copy` action and then `delete` the desired source file.


```
{ "digest of source filepath": [ "source_file", "destination_file" ] }

e.g.

{
  "9b4566a0455e76a392c43ec4d8b8e7d636b21ff2cf83b87fe99b97d00a501de0": [
    "my_content/a_third_copy_of_dunwich.txt",
    "my_content/moved_third_copy_of_dunwich_to_here.txt"
  ]
}


```

### Delete files

Create a file named `delete_files.json` and place in `deposit/head`.

```
{ "digest of file to delete": [ filepaths of files to delete ] }

e.g.

{ "9b4566a0455e76a392c43ec4d8b8e7d636b21ff2cf83b87fe99b97d00a501de0": [
  "my_content/a_third_copy_of_dunwich.txt",
  "my_content/moved_third_copy_of_dunwich_to_here.txt"
 ]
}

```

### Additional version info

If you wish to add additional information to the version, create a file named `version.json` and place in `deposit/head`.

```
{
  "created": "2019-11-12",
  "message": "Ia! Ia! cthulhu fhtagn!",
  "user": {
    "name": "Yog-Sothoth",
    "address": "all_seeing_spheres@miskatonic.edu"
  }
}
```

### Add additional fixity values to object

Create a file named `fixity_files.json` and place in `deposit/head`. The top level keys of this JSON
should be the string value of the digest algorithm to add. Each key contains a hash of key/value pairs,
where the key is the string value of the file digest as recorded in the manifest (i.e. either SHA256 or
SHA512), and the value is the additional file digest to associate with this file as an additional fixity value.
Note that you do not need to provide fixity values for all existing files in the object, and you
can mix-and-match digest algorithms so long as the algorithm is listed as a supported value in your site.
Set `OcflTools.config.fixity_algorithms` to specify acceptable algorithms.

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

### Using head.json instead of individual action files

Instead of providing multiple action files in `head/` to describe desired operations,
you may provide a single file, `head.json`, containing multiple actions. Each individual
action has the same format as their action file, but is nested beneath a key that describes
the action, e.g.:

```
{
    "update_manifest": {
      "cffe55838a878a29da82a0e10b2909b7e46b6f7167ed7f815782465573e98f27": [
        "ingest_temp/dracula.txt"
      ],
      "f512eb0a032f562225e848ce88449895f3ec19f3d4836a80df80c77c74557bab": [
        "ingest_temp/poe.txt"
      ]
    },
    "add": {
      "cffe55838a878a29da82a0e10b2909b7e46b6f7167ed7f815782465573e98f27": [
        "my_content/a_great_copy_of_dracula.txt",
        "my_content/another_directory/a_third_copy_of_dracula.txt"
      ],
      "f512eb0a032f562225e848ce88449895f3ec19f3d4836a80df80c77c74557bab": [
        "edgar/alan/poe.txt"
      ]
    }
}
```

In the above example we are adding two bitstreams to the object (via `update_manifest`),
in a directory called `ingest_temp`, but after this version is created the object
will appear to contain 3 files in total, thus:

```

  my_content/a_great_copy_of_dracula.txt
  my_content/another_directory/a_third_copy_of_dracula.txt
  edgar/alan/poe.txt
```

This is an example of both data duplication (the same bitstream refers to two different files)
and that the logical representation of the object need not match its physical layout. In this
case, the version directory on disk would contain these files:

```

  v0001/content/ingest_temp/dracula.txt
  v0001/content/ingest_temp/poe.txt
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

Note that for the first version of an object, the destination `object_directory` MUST be empty. For
subsequent versions of the object, the `object_directory` must contain the most recent version of
the OCFL object to be updated.

### Viewing Object History

Use `OcflTools::OcflDelta` to query an OCFL object to produce the list of actions performed on each
version of the object. This does not list when fixity information was added to the object, nor
does it reveal `version` information. `version` information can be queried separately; historical
fixity info requires access to prior versions of the inventory file.

```
ocfl       = OcflTools::OcflInventory.new.from_file("#{object_dir}/inventory.json")
ocfl_delta = OcflTools::OcflDelta.new(ocfl)

puts JSON.pretty_generate(ocfl_delta.all)

# Or if you just want a specific version (say, changes made to create version 3), do:
ocfl_delta.previous(3)
```

`JSON.pretty_generate(ocfl_delta.all)` yields output like this:

```
{
  "v0001": {
    "update_manifest": {
      "cffe55838a878a29da82a0e10b2909b7e46b6f7167ed7f815782465573e98f27": [
        "my_content/dracula.txt"
      ],
      "f512eb0a032f562225e848ce88449895f3ec19f3d4836a80df80c77c74557bab": [
        "my_content/poe.txt"
      ]
    },
    "add": {
      "cffe55838a878a29da82a0e10b2909b7e46b6f7167ed7f815782465573e98f27": [
        "my_content/dracula.txt"
      ],
      "f512eb0a032f562225e848ce88449895f3ec19f3d4836a80df80c77c74557bab": [
        "my_content/poe.txt"
      ]
    }
  },
  "v0002": {
    "copy": {
      "cffe55838a878a29da82a0e10b2909b7e46b6f7167ed7f815782465573e98f27": [
        "my_content/a_second_copy_of_dracula.txt",
        "my_content/another_directory/a_third_copy_of_dracula.txt"
      ]
    },
    "move": {
      "f512eb0a032f562225e848ce88449895f3ec19f3d4836a80df80c77c74557bab": [
        "my_content/poe.txt",
        "my_content/poe-nevermore.txt"
      ]
    }
  },
  "v0003": {
    "update_manifest": {
      "618ea77f3a74558493f2df1d82fee18073f6458573d58e6b65bade8bd65227fb": [
        "my_content/poe-nevermore.txt"
      ]
    },
    "update": {
      "618ea77f3a74558493f2df1d82fee18073f6458573d58e6b65bade8bd65227fb": [
        "my_content/poe-nevermore.txt"
      ]
    }
  },
  "v0004": {
    "update_manifest": {
      "9b4566a0455e76a392c43ec4d8b8e7d636b21ff2cf83b87fe99b97d00a501de0": [
        "my_content/dunwich.txt"
      ]
    },
    "add": {
      "9b4566a0455e76a392c43ec4d8b8e7d636b21ff2cf83b87fe99b97d00a501de0": [
        "my_content/dunwich.txt"
      ]
    }
  }
}
```

## Implementation notes

`OcflTools::OcflInventory` is a child class of `OcflTools::OcflObject`, designed
for reading and writing inventory.json files.

`OcflObject` will prevent you from doing the dumbest of things - once you've created
version 2 of an object, you can't edit the state of version 1 - but it won't prevent
you from the more subtle stupids. That's for implementing applications to work around
with their own business logic.

`OcflTools::OcflValidator` will take a directory and tell you if it's an OCFL object or not.
If it is a valid OCFL object, `OcflValidator` will check the files on disk against the records
in the inventory.json and let you know if they are all there and have matching checksums.

`OcflTools::OcflVerify` will take an `OcflObject` and will let you know if it's syntactically correct
and internally consistent. `OcflVerify` doesn't care or know about files or directories on disk.
`OcflValidator` uses `OcflVerify` as part of its validation process, once it has identified a suitable
 inventory.json file.

`OcflTools::OcflResults` is a class to capture logging events for a specific OcflValidator or
OcflVerify instance. Any reported error (inspect `OcflResults#get_errors`) indicates the object
under consideration is not OCFL compliant.

`OcflTools::OcflDeposit` is a reference implementation of a deposit workflow from an upstream repository.
When given a correctly-formatted `deposit` directory and a destination directory, `OcflDeposit` will
attempt to create a new OCFL object an empty destination directory, or add a new version to a
well-formed OCFL object in the destination directory.

OCFL supports file deduplication but it is up to the implementing application to decide
if this is desirable behavior. If one is using `OcflDeposit` then deduplication will occur when
the same bitstream is added to an object several times in the same version with different
filenames AND only one file is placed in `deposit/head/content` for versioning.

When adding an existing bitstream as a different filename in a new version, deduplication will
occur when a matching digest can be found in the manifest, but only if the new filename is versioned
via `copy_files.json` and if the bitstream is not added again to `deposit/head/content`.
