module OcflTools
  # Class to perform checksum and structural validation of POSIX OCFL directories.
  # Requires an OcflInventory object (it needs to read JSON).
  class OcflIntegrity < OcflTools::OcflVerify
    def initialize(ocfl_inventory, object_directory)
    end

    # Optionally, start by providing a checksum for sidecar file of the inventory.json
    def verify_checksums(sidecar_checksum: nil)
      # validate sidecar_checksum if present.
      # validate inventory.json checksum with sidecar_checksum.
      # validate files in manifest against physical copies on disk.
      # cross_check digestss.
      # Report out via @my_results. 
    end

    # Do all the files and directories in the object_dir conform to spec?
    # Are there inventory.json files in each version directory?
    def verify_structure
    end

    # Do all the files described in the most recent inventory.json
    # actually exist on disk?
    def verify_inventory
    end
  end
end
