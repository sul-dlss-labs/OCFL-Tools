module OcflTools
  # Class to take new content from a deposit directory and marshal it
  # into a new version directory of a new or existing OCFL object dir.
  # Expects deposit_dir to be:
  # <ocfl deposit directoy>/
  #     |-- inventory.json (from object_directory root, if adding to existing version)
  #     |-- head/
  #         |-- manifest.json (all proposed file actions)
  #         |-- <content_dir>/
  #             |-- <files to add or modify>
  #
  # Maybe manifest.json is too complex, and we should just do
  # add_files.txt, delete_files.txt, update_files.txt, copy_files.txt, move_files.txt
  # fixity_files.txt
  # in format of "digest", "filepath"
  class OcflDeposit < OcflTools::OcflInventory

    def initialize(deposit_directory:, object_directory:)
      @deposit_dir = deposit_directory
      @object_dir  = object_directory
      raise "#{@deposit_dir} is not a valid directory!" unless File.directory? deposit_directory
      raise "#{@object_dir} is not a valid directory!" unless File.directory? object_directory

      @my_results  = OcflTools::OcflResults.new
      san_check
    end

    private
    def san_check
      # If deposit directory contains inventory.json:
      #  - it's an update to an existing object. Do existing_object_san_check.
      # If deposit directory !contain inventory.json:
      #  - it's a new object. Do a new_object_san_check.

      if File.file? "#{@deposit_dir}/inventory.json"
        puts "I've found an inventory file!"
        existing_object_san_check
      else
        puts "No inventory found!"
        new_object_san_check
      end

    end

    def new_object_san_check
      # object_directory must be empty (no existing versions or inventory)
      # deposit dir can only contain 'head' directory and an id.namaste file.
      # 'head' directory can only contain 'add' and optionally 'fixity' files,
      # and the contentDirectory defined by site settings.
      puts "This is new_object_san_check"
    end

    def existing_object_san_check
      # must contain inventory.json and sidecar.
      # sidecar digest must match inventory.json
      # must contain 'head' directory
      # must not contain any other files at this level.
      # Inside 'head', must contain 'content' directory.
      # head must also contain at least one of the actions files.
      puts 'This is existing_object_san_check'
    end

    def stage_new_object
      # create new OcflInventory instance.
      # read id.namaste file, set @id.
      # read head/add_files.txt, process into OcflInventory.
      # - check their checksums as they are processed.
      # read head/fixity_files.txt, process into OcflInventory.
    end

    def stage_update_object
      # read existing inventory into OcflInventory instance.
      # Determine next version, stage files into it.
      # - check checksums when staging.

    end

    def deposit_new_version
      # verify that our object_directory head is still what we expect.
      # create the version and contentDirectory directories.
      # move or copy content over from deposit_directory
      # write the inventory.json & sidecar into version directory.
      # do a directory verify on the new directory.
      # write the new inventory.json to object root.
    end

  end
end
