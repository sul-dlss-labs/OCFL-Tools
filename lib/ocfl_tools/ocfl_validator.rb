module OcflTools
  # Class to perform checksum and structural validation of POSIX OCFL directories.

  # I'm a doof - Validator does *not* inherit Ocfl::Verify. 
  class OcflValidator

    # @return [Pathname] ocfl_object_root the full local filesystem path to the OCFL object root directory.
    attr_reader :ocfl_object_root

    # @param [Pathname] ocfl_storage_root is a the full local filesystem path to the object directory.
    def initialize(ocfl_object_root)
      @digest           = nil
      @version_format   = nil
      @ocfl_object_root = ocfl_object_root
    end

    # Perform an OCFL-spec validation of the given object directory.
    # If given the optional digest value, verify file content using checksums in inventory file.
    # Will fail if digest is not found in manifest or a fixity block.
    # This validates all versions and all files in the object_root.
    # If you want to just check a specific version, call {verify_directory}.
    def validate_ocfl_object_root(digest=nil)
      @digest = digest
    end

    # Optionally, start by providing a checksum for sidecar file of the inventory.json
    def verify_checksums(inventory_file, sidecar_checksum: nil)
      # validate sidecar_checksum if present.
      # Sidecar checksum ignores @digest setting, and deduces digest to use from filename, per spec.
      # validate inventory.json checksum against inventory.json.<sha256|sha512>
      # validate files in manifest against physical copies on disk.
      # cross_check digestss.
      # Report out via @my_results.
    end

    # Do all the files and directories in the object_dir conform to spec?
    # Are there inventory.json files in each version directory? (warn if not in version dirs)
    # Deduce version dir naming convention by finding the v1 directory; apply that format to other dirs.
    def verify_structure
    end

    # because different version directories may use different digests, and may or may not
    # have fixity blocks in them, we need a way to verify directories using different rules
    # within the same object. v1 thru v3 might use sha256, v4 thru v7 might use sha512. etc.
    # We may also want to only verify the most recent directory, not the entire object.
    def verify_directory(version)
      # Try to load the inventory.json in the version directory *first*.
      # Only go for the root object directory if that fails.
      # Why? Because if it exists, the inventory in the version directory is the canonical inventory for that version.
    end

    # Is the inventory file valid?
    def verify_inventory(inventory_file)
      # Load up the object with ocfl_inventory, push it through ocfl_verify.
    end

    # Do all the files mentioned in the inventory(s) exist on disk?
    # This is an existence check, not a checksum verification.
    def verify_files
    end

    # find the first directory and deduce the version format. set @version_format appropriately.
    def get_version_format
      # Get all directories starting with 'v', sort them.
      # Take the top of the sort. Count the number of 0s found.
    end

  end
end
