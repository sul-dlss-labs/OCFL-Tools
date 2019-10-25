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

    # We may also want to only verify the most recent directory, not the entire object.
    def verify_directory(version, digest=nil)
      # Try to load the inventory.json in the version directory *first*.
      # Only go for the root object directory if that fails.
      # Why? Because if it exists, the inventory in the version directory is the canonical inventory for that version.
      # ONLY checks that the files in this directory are present in the Manifest and (if digest is given)
      # that their checksums match. And that the files in the Manifest for this verion directory exist on disk.
    end

    # Different from verify_directory.
    # Verify_version is *all* versions of the object, up to and including this one.
    # Verify_directory is *just* check the files and checksums of inside that particular version directory.
    # Verify_version(@head) is the canonical way to check an entire object?
    def verify_version(version)
    end

    # Is the inventory file valid?
    def verify_inventory(inventory_file)
      # Load up the object with ocfl_inventory, push it through ocfl_verify.
    end

    # Do all the files mentioned in the inventory(s) exist on disk?
    # This is an existence check, not a checksum verification.
    def verify_files
      # Calls verify_directory for each version?
    end

    # find the first directory and deduce the version format. set @version_format appropriately.
    def get_version_format
      # Get all directories starting with 'v', sort them.
      # Take the top of the sort. Count the number of 0s found.
    end

  end
end
