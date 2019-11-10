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


    def deposit_new_version
      # verify that our object_directory head is still what we expect.
      # create the version and contentDirectory directories.
      # move or copy content over from deposit_directory
      # write the inventory.json & sidecar into version directory.
      # do a directory verify on the new directory.
      # write the new inventory.json to object root.
      # Can only be called if there are no errors in @my_results; raise exception if otherwise?
    end


    private
    def san_check
      # If deposit directory contains inventory.json:
      #  - it's an update to an existing object. Do existing_object_san_check.
      # If deposit directory !contain inventory.json:
      #  - it's a new object. Do a new_object_san_check.

      if File.file? "#{@deposit_dir}/inventory.json"
        @my_results.info('I111', 'san_check', "Existing inventory found at #{@deposit_dir}/inventory.json")
        existing_object_san_check
      else
        @my_results.info('I111', 'san_check', "No inventory.json found in #{@deposit_dir}; assuming new object workflow.")
        new_object_san_check
      end

    end

    def new_object_san_check
      puts "This is new_object_san_check"
      # 1. Object directory must be empty.
      # 2. Deposit directory must contain 'head' directory.
      # 3. Deposit directory must contain an id namaste file.
      # 4. Deposit directory must NOT contain any other files or directories.
      # 5. 'head' directory must contain a 'content' directory that matches site setting.
      # 6. 'head' directory must contain an 'add_files.txt' file.
      # 7. 'head' directory MAY contain a 'fixity_files.txt' file.
      # 8. 'head' directory must NOT contain any other files.

      # Only call this if we got here without errors.
      stage_new_object
    end

    def existing_object_san_check
      puts 'This is existing_object_san_check'
      # Deposit directory MUST contain an inventory.json
      # Deposit directory MUST contain a matching inventory.json sidecar file.
      # inventory.json MUST validate against sidecar digest value.
      # inventory.json MUST be a valid OCFL inventory (passes OcflVerify).
      # Deposit directory MUST NOT contain any other files.
      # Deposit directory MUST contain a 'head' directory.
      # 'head' directory must contain a 'content' directory that
      #    matches value in inventory.json or site default if not otherwise set.
      # 'head' MUST contain at least one of the 'actions' txt files (inc. fixity).
      # Object directory OCFL MUST match Deposit directory OCFL object (sidecar check)
      # - doing a digest check is the fastest way to ensure it's the same inventory file & contents.
      # Object directory OCFL must pass a structure & verify test (don't do checksum verification)

      # Only call this if we got here without errors.
      stage_update_object
    end

    def stage_new_object
      # create new OcflInventory instance.
      # read id.namaste file, set @id.
      # read head/add_files.txt, process into OcflInventory.
      # - check their checksums as they are processed.
      # read head/fixity_files.txt, process into OcflInventory.
      puts "This is stage_new_object"
    end

    def stage_update_object
      # read existing inventory into OcflInventory instance.
      # Determine next version, stage files into it.
      # - check checksums when staging.
      puts "This is stage_update_object"

    end


  end
end
