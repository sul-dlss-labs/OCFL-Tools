# frozen_string_literal: true

module OcflTools
  # Class to take new content from a deposit directory and marshal it
  # into a new version directory of a new or existing OCFL object dir.
  # Expects deposit_dir to be:
  #
  #   <ocfl deposit directoy>/
  #     |-- inventory.json (from object_directory root, if adding to existing version)
  #     |-- inventory.json.sha512 (matching sidecar from object_directory root)
  #     |-- head/
  #         |-- head.json
  #         |   OR a combination of the following files:
  #         |-- add_files.json     (all proposed file add actions)
  #         |-- update_files.json  (all proposed file update actions)
  #         |-- copy_files.json    (all proposed file copy actions)
  #         |-- delete_files.json  (all proposed file delete actions)
  #         |-- move_files.json    (all proposed file move actions)
  #         |-- version.json       (optional version metadata)
  #         |-- fixity_files.json  (optional fixity information)
  #         |-- <content_dir>/
  #             |-- <files to add or update>
  #
  class OcflDeposit < OcflTools::OcflInventory
    # @param [Pathname] deposit_directory fully-qualified path to a well-formed deposit directory.
    # @param [Pathname] object_directory fully-qualified path to either an empty directory to create new OCFL object in, or the existing OCFL object to which the new version directory should be added.
    # @return {OcflTools::OcflDeposit}
    def initialize(deposit_directory:, object_directory:)
      @deposit_dir = deposit_directory
      @object_dir  = object_directory
      unless File.directory? deposit_directory
        raise "#{@deposit_dir} is not a valid directory!"
      end
      unless File.directory? object_directory
        raise "#{@object_dir} is not a valid directory!"
      end

      # Since we are overriding OcflObject's initialize block, we need to define these variables again.
      @id               = nil
      @head             = nil
      @type             = OcflTools.config.content_type
      @digestAlgorithm  = OcflTools.config.digest_algorithm # sha512 is recommended, Stanford uses sha256.
      @contentDirectory = OcflTools.config.content_directory # default is 'content', Stanford uses 'data'
      @manifest         = {}
      @versions         = {} # A hash of Version hashes.
      @fixity           = {} # Optional. Same format as Manifest.

      @my_results = OcflTools::OcflResults.new

      # san_check works out if the deposit_dir and object_dir represents a
      # new object with a first version, or an update to an existing object.
      # It then verifies and stages all files so that, if it doesn't raise an
      # exception, the calling app can simply invoke #deposit_new_version to proceed.
      san_check
    end

    # Returns a {OcflTools::OcflResults} object containing information about actions taken during the staging and creation of this new version.
    # @return {OcflTools::OcflResults}
    def results
      @my_results
    end

    # Creates a new version of an OCFL object in the destination object directory.
    # This method can only be called if the {OcflTools::OcflDeposit} object passed all
    # necessary sanity checks, which occur when the object is initialized.
    # @return {OcflTools::OcflDeposit} self
    def deposit_new_version
      # verify that our object_directory head is still what we expect.
      # create the version and contentDirectory directories.
      # move or copy content over from deposit_directory
      # write the inventory.json & sidecar into version directory.
      # do a directory verify on the new directory.
      # write the new inventory.json to object root.
      # Can only be called if there are no errors in @my_results; raise exception if otherwise?
      set_head_version

      # Am I put together correctly?
      @my_results.add_results(OcflTools::OcflVerify.new(self).check_all)
      # If @my_results.error_count > 0, abort!
      if @my_results.error_count > 0
        raise "Errors detected in OCFL object verification. Cannot process deposit: #{@my_results.get_errors}"
      end

      if OcflTools::Utils.version_string_to_int(@head) == 1 && !Dir.empty?(@object_dir)
        raise "#{@object_dir} is not empty! Unable to create new object."
      end

      process_new_version
      self
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
      # 1. Object directory must be empty.
      if Dir.empty?(@object_dir)
        @my_results.info('I111', 'new_object_san_check', "target dir #{@object_dir} is empty.")
      else
        @my_results.error('E111', 'new_object_san_check', "target dir #{@object_dir} is NOT empty!")
      end

      # 2. Deposit directory must contain 'head' directory.
      if File.directory?("#{@deposit_dir}/head")
        @my_results.info('I111', 'new_object_san_check', "Deposit dir #{@deposit_dir} contains a 'head' directory.")
      else
        @my_results.error('E111', 'new_object_san_check', "Deposit dir #{@deposit_dir} does NOT contain required 'head' directory.")
      end

      # 3. Deposit directory must contain ONE id namaste file. (4='id')
      deposit_root_files = []
      deposit_root_directories = []
      Dir.chdir(@deposit_dir)
      Dir.glob('*').select do |file|
        deposit_root_files << file if File.file? file
        deposit_root_directories << file if File.directory? file
      end

      namaste_file = nil
      deposit_root_files.each do |file|
        next unless file =~ /^4=/ # Looks like the start of a Namaste file.

        deposit_root_files.delete(file)
        if namaste_file.nil?
          namaste_file = file
          @my_results.info('I111', 'new_object_san_check', "Matching Namaste file #{file} found in #{@deposit_dir}.")
        else
          @my_results.error('E111', 'new_object_san_check', "More than one matching Namaste file found in #{@deposit_dir}!")
          raise "More than one matching Namaste file found in #{@deposit_dir}! #{namaste_file} & #{file}"
        end
      end

      # 3b. Verify namaste file is valid.
      object_id = namaste_file.split('=')[1]
      raise 'Object ID cannot be zero length!' if object_id.empty?

      File.readlines("#{@deposit_dir}/#{namaste_file}").each do |line|
        line.chomp!
        if object_id != line
          @my_results.error('E111', 'new_object_san_check', "Contents of Namaste ID file do not match filename! #{object_id} vs #{line}.")
          raise "Contents of Namaste ID file do not match filename! #{object_id} vs #{line}."
        end
      end
      # Really there should only be 1 line in namaste_file but so long as they all match, we're good.
      @namaste = object_id

      # 4. Deposit directory must NOT contain any other files.
      unless deposit_root_files.empty?
        @my_results.error('E111', 'new_object_san_check', "Deposit directory contains extraneous files: #{deposit_root_files}")
        raise "Deposit directory contains extraneous files: #{deposit_root_files}."
      end

      # 4b. Deposit directory MUST contain a 'head' directory.
      if deposit_root_directories.include? 'head'
        @my_results.info('I111', 'new_object_san_check', "#{@deposit_dir} contains expected 'head' directory.")
        deposit_root_directories.delete('head')
      else
        @my_results.error('E111', 'new_object_san_check', "#{@deposit_dir} must contain 'head' directory!")
        raise "Deposit directory must contain a 'head' directory."
      end

      # 4c. Deposit directory MUST NOT contain any other directories.
      unless deposit_root_directories.empty?
        @my_results.error('E111', 'new_object_san_check', "#{@deposit_dir} contains extraneous directories: #{deposit_root_directories}")
        raise "#{deposit_dir} contains extraneous directories: #{deposit_root_directories}"
      end

      # Intermission: prepare deposit/head for inspection
      deposit_head_files = []
      deposit_head_directories = []
      Dir.chdir("#{@deposit_dir}/head")
      Dir.glob('*').select do |file|
        deposit_head_files << file if File.file? file
        deposit_head_directories << file if File.directory? file
      end

      # 5. 'head' directory must contain a 'content' directory that matches sitewide setting.
      if deposit_head_directories.include? OcflTools.config.content_directory
        @my_results.info('I111', 'new_object_san_check', "#{@deposit_dir}/head contains expected #{OcflTools.config.content_directory} directory.")
        deposit_head_directories.delete(OcflTools.config.content_directory)
      else
        @my_results.error('E111', 'new_object_san_check', "#{@deposit_dir}/head does NOT contain expected #{OcflTools.config.content_directory} directory.")
        raise "#{@deposit_dir}/head does NOT contain expected #{OcflTools.config.content_directory} directory."
      end

      # 5b. 'head' directory MUST NOT contain any other directories.
      unless deposit_head_directories.empty?
        @my_results.error('E111', 'new_object_san_check', "#{@deposit_dir}/head contains extraneous directories: #{deposit_head_directories}")
        raise "#{deposit_dir}/head contains extraneous directories: #{deposit_head_directories}"
      end

      # 6. 'head' directory MUST contain either 'head.json' or 'add_files.json'
      found_me = nil
      require_one = ['head.json', 'add_files.json']
      require_one.each do |file|
        if deposit_head_files.include? file
          @my_results.info('I111', 'new_object_san_check', "#{@deposit_dir}/head contains required file #{file}")
          deposit_head_files.delete(file)
          found_me = true
        end
      end

      unless found_me
        @my_results.error('E111', 'new_object_san_check', "#{@deposit_dir}/head requires either head.json or add_files.json, but not found.")
        raise "#{@deposit_dir}/head requires either head.json or add_files.json, but not found."
      end

      # 7. 'head' directory MAY contain one or more of these action files.
      action_files = ['head.json', 'add_files.json', 'update_files.json', 'version.json', 'update_manifest.json', 'delete_files.json', 'move_files.json', 'fixity_files.json']
      action_files.each do |file|
        if deposit_head_files.include? file
          @my_results.info('I111', 'new_object_san_check', "#{@deposit_dir}/head contains optional #{file}")
          deposit_head_files.delete(file)
        end
      end

      # 8. 'head' directory MUST NOT contain any other files.
      unless deposit_head_files.empty?
        @my_results.error('E111', 'new_object_san_check', "#{@deposit_dir}/head contains extraneous files: #{deposit_head_files}")
        raise "#{@deposit_dir}/head contains extraneous files: #{deposit_head_files}"
      end
      # Only call this if we got here without errors.
      stage_new_object
    end

    def existing_object_san_check
      deposit_root_files = []
      deposit_root_directories = []
      Dir.chdir(@deposit_dir)
      Dir.glob('*').select do |file|
        deposit_root_files << file if File.file? file
        deposit_root_directories << file if File.directory? file
      end

      # 1. Deposit directory MUST contain an inventory.json
      if deposit_root_files.include? 'inventory.json'
        @my_results.info('I111', 'existing_object_san_check', "#{@deposit_dir}/inventory.json found")
        deposit_root_files.delete('inventory.json')
      else
        @my_results.error('E111', 'existing_object_san_check', "#{@deposit_dir}/inventory.json required, but not found.")
        raise "#{@deposit_dir}/inventory.json required, but not found."
      end

      # 2. Deposit directory MUST contain a matching inventory.json sidecar file.
      inventory_digest = OcflTools::Utils::Inventory.get_digestAlgorithm("#{@deposit_dir}/inventory.json")

      if deposit_root_files.include? "inventory.json.#{inventory_digest}"
        @my_results.info('I111', 'existing_object_san_check', "#{@deposit_dir}/inventory.json.#{inventory_digest} found")
        deposit_root_files.delete("inventory.json.#{inventory_digest}")
      else
        @my_results.error('E111', 'existing_object_san_check', "#{@deposit_dir}/inventory.json.#{inventory_digest} required, but not found")
        raise "#{@deposit_dir}/inventory.json.#{inventory_digest} required, but not found."
      end

      # 3. inventory.json MUST validate against sidecar digest value.
      generated_digest = OcflTools::Utils.generate_file_digest("#{@deposit_dir}/inventory.json", inventory_digest)
      sidecar_digest   = File.open("#{@deposit_dir}/inventory.json.#{inventory_digest}", &:readline).split(' ')[0]

      if generated_digest == sidecar_digest
        @my_results.info('I111', 'existing_object_san_check', "#{@deposit_dir}/inventory.json checksum matches generated value.")
      else
        @my_results.error('E111', 'existing_object_san_check', "#{@deposit_dir}/inventory.json checksum does not match generated value.")
        raise "#{@deposit_dir}/inventory.json checksum does not match generated value."
      end

      # 4. inventory.json MUST be a valid OCFL inventory (passes OcflVerify; copy results into our results instance).
      deposit_inventory = OcflTools::OcflInventory.new.from_file("#{@deposit_dir}/inventory.json")

      @my_results.add_results(OcflTools::OcflVerify.new(deposit_inventory).check_all)

      unless @my_results.error_count == 0
        raise 'Errors detected in deposit inventory verification!'
      end

      # 5. Deposit directory MUST NOT contain any other files.
      unless deposit_root_files.empty?
        @my_results.error('E111', 'existing_object_san_check', "Deposit directory contains extraneous files: #{deposit_root_files}")
        raise "Deposit directory contains extraneous files: #{deposit_root_files}."
      end

      # 6. Deposit directory MUST contain a 'head' directory.
      if deposit_root_directories.include? 'head'
        @my_results.info('I111', 'existing_object_san_check', "#{@deposit_dir} contains expected 'head' directory.")
        deposit_root_directories.delete('head')
      else
        @my_results.error('E111', 'existing_object_san_check', "#{@deposit_dir} must contain 'head' directory!")
        raise "Deposit directory must contain a 'head' directory."
      end

      # 7. Deposit directory MUST NOT contain any other directories.
      unless deposit_root_directories.empty?
        @my_results.error('E111', 'existing_object_san_check', "#{@deposit_dir} contains extraneous directories: #{deposit_root_directories}")
        raise "#{deposit_dir} contains extraneous directories: #{deposit_root_directories}"
      end

      # Intermission: into the head directory!

      deposit_head_files = []
      deposit_head_directories = []
      Dir.chdir("#{@deposit_dir}/head")
      Dir.glob('*').select do |file|
        deposit_head_files << file if File.file? file
        deposit_head_directories << file if File.directory? file
      end

      # 8. 'head' directory must contain a 'content' directory that
      #    matches value in inventory.json or OCFL default if not otherwise set.
      content_directory = OcflTools::Utils::Inventory.get_contentDirectory("#{@deposit_dir}/inventory.json")

      if deposit_head_directories.include? content_directory
        @my_results.info('I111', 'existing_object_san_check', "#{@deposit_dir}/head contains expected #{content_directory} directory.")
        deposit_head_directories.delete(content_directory)
      else
        @my_results.error('E111', 'existing_object_san_check', "#{@deposit_dir}/head does NOT contain expected #{content_directory} directory.")
        raise "#{@deposit_dir}/head does NOT contain expected #{content_directory} directory."
      end

      # 9. 'head' MUST contain at least one of the 'actions' json files (inc. fixity).
      # Any one of these is needed.
      action_files = ['add_files.json', 'head.json', 'update_manifest.json', 'update_files.json', 'delete_files.json', 'move_files.json', 'fixity_files.json']
      action_found = nil

      deposit_head_files.each do |file|
        if action_files.include? file # We found an action file!
          deposit_head_files.delete(file)
          action_found = true
        end
      end

      if action_found == true
        @my_results.info('I111', 'existing_object_san_check', "#{@deposit_dir}/head contains at least 1 action file.")
      else
        @my_results.error('E111', 'existing_object_san_check', "Unable to find any action files in #{@deposit_dir}/head")
        raise "Unable to find any action files in #{@deposit_dir}/head"
      end

      # 9b. 'head' directory MAY contain a 'version.json' file.
      if deposit_head_files.include? 'version.json'
        @my_results.info('I111', 'new_object_san_check', "#{@deposit_dir}/head contains optional version.json")
        deposit_head_files.delete('version.json')
      else
        @my_results.info('I111', 'new_object_san_check', "#{@deposit_dir}/head does not contain optional version.json")
      end

      # 10. Object root MUST contain an inventory.json
      if File.exist? "#{@object_dir}/inventory.json"
        @my_results.info('I111', 'existing_object_san_check', "#{@object_dir}/inventory.json exists.")
      else
        @my_results.error('E111', 'existing_object_san_check', "#{@object_dir}/inventory.json does not exist.")
        raise "#{@object_dir}/inventory.json does not exist."
      end

      # 11. Object directory OCFL MUST match Deposit directory OCFL object (sidecar check)
      # - doing a digest check is the fastest way to ensure it's the same inventory file & contents.
      object_root_digest = OcflTools::Utils.generate_file_digest("#{@object_dir}/inventory.json", inventory_digest)

      if object_root_digest == generated_digest
        @my_results.info('I111', 'existing_object_san_check', "#{@object_dir}/inventory.json matches #{@deposit_dir}/inventory.json")
      else
        @my_results.error('E111', 'existing_object_san_check', "#{@object_dir}/inventory.json does not match #{@deposit_dir}/inventory.json")
        raise "#{@object_dir}/inventory.json does not match #{@deposit_dir}/inventory.json"
      end

      # 12. Object directory OCFL must pass a structure test (don't do checksum verification)
      destination_ocfl = OcflTools::OcflValidator.new(@object_dir)
      @my_results.add_results(destination_ocfl.verify_structure)
      unless @my_results.error_count == 0
        raise 'Errors detected in destination object structure!'
      end

      # Only call this if we got here without errors.
      stage_existing_object
    end

    def stage_new_object
      # read id.namaste file, set @id.
      # set new version
      # process action files
      self.id = @namaste
      @new_version = 1
      get_version(@new_version) # It's a new OCFL object; we start at version 1.
      process_action_files
    end

    def process_update_manifest(update_manifest_block)
      # Process update_manifest, if present.
      update_manifest_block.each do |digest, filepaths|
        filepaths.each do |file|
          # Make sure it actually exists!
          unless File.exist? "#{@deposit_dir}/head/#{@contentDirectory}/#{file}"
            @my_results.error('E111', 'process_action_files', "File #{file} referenced in update_manifest.json not found in #{@deposit_dir}/head/#{@contentDirectory}")
            raise "File #{file} referenced in update_manifest.json not found in #{@deposit_dir}/head/#{@contentDirectory}"
          end
          # Here's where we'd compute checksum.
          if OcflTools::Utils.generate_file_digest("#{@deposit_dir}/head/#{@contentDirectory}/#{file}", @digestAlgorithm) == digest
            update_manifest(file, digest, @new_version)
            @my_results.info('I111', 'process_action_files', "#{@deposit_dir}/head/#{@contentDirectory}/#{file} added to manifest inventory.")
          else
            @my_results.error('E111', 'process_action_files', "#{@deposit_dir}/head/#{@contentDirectory}/#{file} computed checksum does not match provided digest.")
            raise "#{@deposit_dir}/head/#{@contentDirectory}/#{file} computed checksum does not match provided digest."
          end
        end
      end
    end

    def process_add_files(add_files_block)
      add_files_block.each do |digest, filepaths|
        filepaths.each do |file|
          unless manifest.key?(digest)
            # This digest does NOT exist in the manifest; check disk for ingest (because add_file's going to add it to manifest later).
            # It better be on disk, buck-o.
            unless File.exist? "#{@deposit_dir}/head/#{@contentDirectory}/#{file}"
              @my_results.error('E111', 'process_action_files', "File #{file} referenced in add_files block not found in #{@deposit_dir}/head/#{@contentDirectory}")
              raise "File #{file} referenced in add_files block not found in #{@deposit_dir}/head/#{@contentDirectory}"
            end

            if !OcflTools::Utils.generate_file_digest("#{@deposit_dir}/head/#{@contentDirectory}/#{file}", @digestAlgorithm) == digest
              # checksum failed, raise error.
              raise "#{@deposit_dir}/head/#{@contentDirectory}/#{file} computed checksum does not match provided digest in add_files block."
            end
          end
          # If we get to here, we're OK to add_file.
          add_file(file, digest, @new_version)
          @my_results.info('I111', 'process_action_files', "#{@deposit_dir}/head/#{@contentDirectory}/#{file} added to inventory.")
        end
      end
    end

    def process_update_files(update_files_block)
      update_files_block.each do |digest, filepaths|
        filepaths.each do |file|
          # Make sure it actually exists!
          unless File.exist? "#{@deposit_dir}/head/#{@contentDirectory}/#{file}"
            @my_results.error('E111', 'process_action_files', "File #{file} referenced in update_files.json not found in #{@deposit_dir}/head/#{@contentDirectory}")
            raise "File #{file} referenced in update_files.json not found in #{@deposit_dir}/head/#{@contentDirectory}"
          end
          # Here's where we'd compute checksum.
          if OcflTools::Utils.generate_file_digest("#{@deposit_dir}/head/#{@contentDirectory}/#{file}", @digestAlgorithm) == digest
            update_file(file, digest, @new_version)
            @my_results.info('I111', 'process_action_files', "#{@deposit_dir}/head/#{@contentDirectory}/#{file} added to inventory.")
          else
            @my_results.error('E111', 'process_action_files', "#{@deposit_dir}/head/#{@contentDirectory}/#{file} computed checksum does not match provided digest.")
            raise "#{@deposit_dir}/head/#{@contentDirectory}/#{file} computed checksum does not match provided digest."
          end
        end
      end
    end

    def process_move_files(move_files_block)
      move_files_block.each do |digest, filepaths|
        my_state = get_state(@new_version)
        unless my_state.key?(digest)
          @my_results.error('E111', 'process_action_files', "Unable to find digest #{digest} in state whilst processing a move request.")
          raise "Unable to find digest #{digest} in state whilst processing a move request."
        end
        previous_files = my_state[digest]
        # Disambiguation; we can only process a move if there is only 1 file here.
        if previous_files.size != 1
          @my_results.error('E111', 'process_action_files', "Disambiguation protection: unable to process move for digest #{digest}: more than 1 file uses this digest in prior version.")
          raise "Disambiguation protection: unable to process move for digest #{digest}: more than 1 file uses this digest in this version."
        end
        unless filepaths.include?(previous_files[0])
          @my_results.error('E111', 'process_action_files', "Unable to find source file #{previous_files[0]} digest #{digest} in state whilst processing a move request.")
          raise "Unable to find source file #{previous_files[0]} digest #{digest} in state whilst processing a move request."
        end
        source_file = previous_files[0]
        destination_file = filepaths[1]
        move_file(source_file, destination_file, @new_version)
      end
    end

    def process_copy_files(copy_files_block)
      my_state = get_state(@new_version)
      copy_files_block.each do |digest, filepaths|
        unless my_state.key?(digest)
          @my_results.error('E111', 'process_action_files', "Unable to find digest #{digest} in state whilst processing a copy request.")
          raise "Unable to find digest #{digest} in state whilst processing a copy request."
        end

        previous_files = my_state[digest]

        filepaths.each do |destination_file|
          copy_file(previous_files[0], destination_file, @new_version)
        end
      end
    end

    def process_delete_files(delete_files_block)
      delete_files_block.each do |_digest, filepaths|
        filepaths.each do |filepath|
          delete_file(filepath, @new_version)
        end
      end
    end

    def process_version(version_block)
      # Version block MUST contain keys 'created', 'message', 'user'
      %w[created message user].each do |req_key|
        unless version_block.key?(req_key)
          @my_results.error('E111', 'process_action_files', "#{@deposit_dir}/head/version.json does not contain expected key #{req_key}")
          raise "#{@deposit_dir}/head/version.json does not contain expected key #{req_key}"
        end
      end
      # user block MUST contain 'name', 'address'
      %w[name address].each do |req_key|
        unless version_block['user'].key?(req_key)
          @my_results.error('E111', 'process_action_files', "#{@deposit_dir}/head/version.json does not contain expected key #{req_key}")
          raise "#{@deposit_dir}/head/version.json does not contain expected key #{req_key}"
        end
      end
      # Now process!
      set_version_user(@new_version, version_block['user'])
      set_version_message(@new_version, version_block['message'])
      set_version_created(@new_version, version_block['created'])
    end

    def process_fixity(fixity_block)
      fixity_block.each do |algorithm, checksums|
        # check if algorithm is in list of acceptable fixity algos for this site.
        unless OcflTools.config.fixity_algorithms.include? algorithm
          @my_results.error('E111', 'process_action_files', "#{@deposit_dir}/head/fixity_files.json contains unsupported algorithm #{algorithm}")
          raise "#{@deposit_dir}/head/fixity_files.json contains unsupported algorithm #{algorithm}"
        end
        # Algo is permitted in the fixity block; add it.
        checksums.each do |manifest_checksum, fixity_checksum|
          update_fixity(manifest_checksum, algorithm, fixity_checksum)
        end
      end
      @my_results.info('I111', 'process_action_files', "#{@deposit_dir}/head/fixity_files.json successfully processed.")
    end

    def process_action_files
      # Moving towards just processing 1 big head.json file.

      if File.exist? "#{@deposit_dir}/head/head.json"
        head = read_json("#{@deposit_dir}/head/head.json")
        # Process keys here.
        process_update_manifest(head['update_manifest']) if head.key?('update_manifest')
        process_add_files(head['add']) if head.key?('add')
        process_update_files(head['update']) if head.key?('update')
        process_copy_files(head['copy']) if head.key?('copy')
        process_move_files(head['move']) if head.key?('move')
        process_move_files(head['delete']) if head.key?('delete')
        process_fixity(head['fixity']) if head.key?('fixity')
        process_version(head['version']) if head.key?('version')
        return # don't process any more.
      end

      # Process update_manifest, if present.
      if File.exist? "#{@deposit_dir}/head/update_manifest.json"
        updates = read_json("#{@deposit_dir}/head/update_manifest.json")
        process_update_manifest(updates)
      end

      # Process add_files, if present.
      # add_files requires { "digest_value": [ "filepaths" ]}
      if File.exist? "#{@deposit_dir}/head/add_files.json"
        add_files = read_json("#{@deposit_dir}/head/add_files.json")
        process_add_files(add_files)
      end

      # process update_files, if present.
      # update_files requires { "digest_value": [ "filepaths" ]}
      if File.exist? "#{@deposit_dir}/head/update_files.json"
        update_files = read_json("#{@deposit_dir}/head/update_files.json")
        process_update_files(update_files)
      end

      # Process move_files, if present.
      # move_file requires digest => [ filepaths ]
      if File.exist? "#{@deposit_dir}/head/move_files.json"
        move_files = read_json("#{@deposit_dir}/head/move_files.json")
        process_move_files(move_files)
      end

      # Process copy_files, if present.
      # copy_files requires digest => [ filepaths_of_copy_destinations ]
      if File.exist? "#{@deposit_dir}/head/copy_files.json"
        copy_files = read_json("#{@deposit_dir}/head/copy_files.json")
        process_copy_files(copy_files)
      end

      # Process delete_files, if present.
      # Do this last in case the same file is moved > 1.
      #  { digest => [ filepaths_to_delete ] }
      if File.exist? "#{@deposit_dir}/head/delete_files.json"
        delete_files = read_json("#{@deposit_dir}/head/delete_files.json")
        process_delete_files(delete_files)
      end

      # If there's a fixity block, add it too.
      if File.file?  "#{@deposit_dir}/head/fixity_files.json"
        fixity_files = read_json("#{@deposit_dir}/head/fixity_files.json")
        process_fixity(fixity_files)
      end

      # Process version.json, if present.
      if File.file? "#{@deposit_dir}/head/version.json"
        version_file = read_json("#{@deposit_dir}/head/version.json")
        process_version(version_file)
      end
    end

    def stage_existing_object
      # If we get here, we know that the local inventory.json is the same as the dest. inventory.json.
      from_file("#{@deposit_dir}/inventory.json")

      # Increment the version from the inventory.json by 1.
      @new_version = OcflTools::Utils.version_string_to_int(head) + 1

      get_version(@new_version) # Add this new version to our representation of this inventory in self.

      process_action_files # now process all our action files for this new version.
    end

    def process_new_version
      # We just passed OCflVerify to get here, so we're good to go.

      # Create version & content directory.
      target_content = "#{@object_dir}/#{@head}/#{@contentDirectory}"

      # Abort if target_content already exists!
      if Dir.exist? target_content
        @my_results.error('E111', 'process_new_version', "#{target_content} already exists! Unable to process new version.")
        raise "#{target_content} already exists! Unable to process new version."
      end

      unless FileUtils.mkdir_p target_content
        raise "Errror creating #{target_content}!"
      end

      source_content = "#{@deposit_dir}/head/#{@contentDirectory}"

      # Copy [or move? make this behavior configurable] content across.
      # Why move? Well, if you're on the same filesystem root, and you're moving large files,
      # move is *much, much faster* and doesn't run the risk of bitstream corruption as it's
      # just a filesystem metadata operation.
      FileUtils.cp_r "#{source_content}/.", target_content

      # Add inventory.json to version directory.
      to_file("#{@object_dir}/#{@head}")
      # Verify version directory.
      validation = OcflTools::OcflValidator.new(@object_dir)
      validation.verify_directory(@new_version)

      @my_results.add_results(validation.results)
      raise 'Errors detected in validation!' unless @my_results.error_count == 0

      # If this is version 1, there will not be a Namaste file in object root - add it.
      unless File.exist?("#{@object_dir}/0=ocfl_object_1.0")
        namaste = File.open("#{@object_dir}/0=ocfl_object_1.0", 'w')
        namaste.puts '0=ocfl_object_1.0'
        namaste.close
      end

      # Add new inventory.json to object root directory. This should always be the final step.
      to_file(@object_dir)

      @my_results.ok('0111', 'process_new_version', "object #{id} version #{@new_version} successfully processed.")
    end
  end
end
