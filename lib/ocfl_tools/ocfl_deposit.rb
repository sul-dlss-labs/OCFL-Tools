module OcflTools
  # Class to take new content from a deposit directory and marshal it
  # into a new version directory of a new or existing OCFL object dir.
  # Expects deposit_dir to be:
  #
  #   <ocfl deposit directoy>/
  #     |-- inventory.json (from object_directory root, if adding to existing version)
  #     |-- inventory.json.sha512 (matching sidecar from object_directory root)
  #     |-- head/
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
      raise "#{@deposit_dir} is not a valid directory!" unless File.directory? deposit_directory
      raise "#{@object_dir} is not a valid directory!" unless File.directory? object_directory

      # Since we are overriding OcflObject's initialize block, we need to define these variables again.
      @id               = nil
      @head             = nil
      @type             = OcflTools.config.content_type
      @digestAlgorithm  = OcflTools.config.digest_algorithm # sha512 is recommended, Stanford uses sha256.
      @contentDirectory = OcflTools.config.content_directory # default is 'content', Stanford uses 'data'
      @manifest         = Hash.new
      @versions         = Hash.new # A hash of Version hashes.
      @fixity           = Hash.new # Optional. Same format as Manifest.

      @my_results  = OcflTools::OcflResults.new

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
      self.set_head_version

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
      return self
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
         if File.file? file
           deposit_root_files << file
         end
         if File.directory? file
           deposit_root_directories << file
         end
      end

      namaste_file = nil
      deposit_root_files.each do | file |
        if file =~ /^4=/  # Looks like the start of a Namaste file.
          deposit_root_files.delete(file)
          if namaste_file == nil
            namaste_file = file
            @my_results.info('I111', 'new_object_san_check', "Matching Namaste file #{file} found in #{@deposit_dir}.")
          else
            @my_results.error('E111', 'new_object_san_check', "More than one matching Namaste file found in #{@deposit_dir}!")
            raise "More than one matching Namaste file found in #{@deposit_dir}! #{namaste_file} & #{file}"
          end
        end
      end

      # 3b. Verify namaste file is valid.
      object_id = namaste_file.split('=')[1]
      raise "Object ID cannot be zero length!" unless object_id.size > 0

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
      if deposit_root_files.size > 0
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
      if deposit_root_directories.size > 0
        @my_results.error('E111', 'new_object_san_check', "#{@deposit_dir} contains extraneous directories: #{deposit_root_directories}")
        raise "#{deposit_dir} contains extraneous directories: #{deposit_root_directories}"
      end

      # 5. 'head' directory must contain a 'content' directory that matches sitewide setting.
      deposit_head_files = []
      deposit_head_directories = []
      Dir.chdir("#{@deposit_dir}/head")
      Dir.glob('*').select do |file|
         if File.file? file
           deposit_head_files << file
         end
         if File.directory? file
           deposit_head_directories << file
         end
      end

      if deposit_head_directories.include? OcflTools.config.content_directory
        @my_results.info('I111', 'new_object_san_check', "#{@deposit_dir}/head contains expected #{OcflTools.config.content_directory} directory.")
        deposit_head_directories.delete(OcflTools.config.content_directory)
      else
        @my_results.error('E111', 'new_object_san_check', "#{@deposit_dir}/head does NOT contain expected #{OcflTools.config.content_directory} directory.")
        raise "#{@deposit_dir}/head does NOT contain expected #{OcflTools.config.content_directory} directory."
      end

      # 5b. 'head' directory MUST NOT contain any other directories.
      if deposit_head_directories.size > 0
        @my_results.error('E111', 'new_object_san_check', "#{@deposit_dir}/head contains extraneous directories: #{deposit_head_directories}")
        raise "#{deposit_dir}/head contains extraneous directories: #{deposit_head_directories}"
      end

      # 6. 'head' directory MUST contain an 'add_files.json' file.
      if deposit_head_files.include? 'add_files.json'
        @my_results.info('I111', 'new_object_san_check', "#{@deposit_dir}/head contains expected add_files.json")
        deposit_head_files.delete('add_files.json')
      else
        @my_results.error('E111', 'new_object_san_check', "#{@deposit_dir}/head/add_files.json required, but not found.")
        raise "#{@deposit_dir}/head/add_files.json required, but not found."
      end

      # 7. 'head' directory MAY contain a 'fixity_files.json' file.
      if deposit_head_files.include? 'fixity_files.json'
        @my_results.info('I111', 'new_object_san_check', "#{@deposit_dir}/head contains optional fixity_files.json")
        deposit_head_files.delete('fixity_files.json')
      else
        @my_results.info('I111', 'new_object_san_check', "#{@deposit_dir}/head does not contain optional fixity_files.json")
      end

      # 7b. 'head' directory MAY contain a 'version.json' file.
      if deposit_head_files.include? 'version.json'
        @my_results.info('I111', 'new_object_san_check', "#{@deposit_dir}/head contains optional version.json")
        deposit_head_files.delete('version.json')
      else
        @my_results.info('I111', 'new_object_san_check', "#{@deposit_dir}/head does not contain optional version.json")
      end


      # 8. 'head' directory MUST NOT contain any other files.
      if deposit_head_files.size > 0
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
         if File.file? file
           deposit_root_files << file
         end
         if File.directory? file
           deposit_root_directories << file
         end
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

      raise "Errors detected in deposit inventory verification!" unless @my_results.error_count == 0

      # 5. Deposit directory MUST NOT contain any other files.
      if deposit_root_files.size > 0
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
      if deposit_root_directories.size > 0
        @my_results.error('E111', 'existing_object_san_check', "#{@deposit_dir} contains extraneous directories: #{deposit_root_directories}")
        raise "#{deposit_dir} contains extraneous directories: #{deposit_root_directories}"
      end

      # Intermission: into the head directory!

      deposit_head_files = []
      deposit_head_directories = []
      Dir.chdir("#{@deposit_dir}/head")
      Dir.glob('*').select do |file|
         if File.file? file
           deposit_head_files << file
         end
         if File.directory? file
           deposit_head_directories << file
         end
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
      action_files = [ 'add_files.json', 'update_files.json', 'delete_files.json', 'move_files.json', 'fixity_files.json']
      action_found = nil

      deposit_head_files.each do | file |
        if action_files.include? file       # We found an action file!
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
      if File.exists? "#{@object_dir}/inventory.json"
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
      raise "Errors detected in destination object structure!" unless @my_results.error_count == 0

      # Only call this if we got here without errors.
      stage_existing_object
    end

    def stage_new_object
      # read id.namaste file, set @id.
      # set new version
      # process action files
      self.id = @namaste
      @new_version = 1
      self.get_version(@new_version) # It's a new OCFL object; we start at version 1.
      process_action_files
    end

    def process_action_files
      # Process add_files, if present.
      # add_files requires { "digest_value": [ "filepaths" ]}
      if File.exists? "#{@deposit_dir}/head/add_files.json"
        add_files = self.read_json("#{@deposit_dir}/head/add_files.json")
        add_files.each do | digest, filepaths |
          filepaths.each do | file |
            # Make sure it actually exists!
            if !File.exist? "#{@deposit_dir}/head/#{@contentDirectory}/#{file}"
              @my_results.error('E111', 'process_action_files', "File #{file} referenced in add_files.json not found in #{@deposit_dir}/head/#{@contentDirectory}")
              raise "File #{file} referenced in add_files.json not found in #{@deposit_dir}/head/#{@contentDirectory}"
            end
            # Here's where we'd compute checksum.
            if OcflTools::Utils.generate_file_digest("#{@deposit_dir}/head/#{@contentDirectory}/#{file}", @digestAlgorithm) == digest
              self.add_file( file, digest, @new_version)
              @my_results.info('I111', 'process_action_files', "#{@deposit_dir}/head/#{@contentDirectory}/#{file} added to inventory.")
            else
              @my_results.error('E111', 'process_action_files', "#{@deposit_dir}/head/#{@contentDirectory}/#{file} computed checksum does not match provided digest.")
              raise "#{@deposit_dir}/head/#{@contentDirectory}/#{file} computed checksum does not match provided digest."
            end
          end
        end
      end

      # process update_files, if present.
      # update_files requires { "digest_value": [ "filepaths" ]}
      if File.exists? "#{@deposit_dir}/head/update_files.json"
        update_files = self.read_json("#{@deposit_dir}/head/update_files.json")
        update_files.each do | digest, filepaths |
          filepaths.each do | file |
            # Make sure it actually exists!
            if !File.exist? "#{@deposit_dir}/head/#{@contentDirectory}/#{file}"
              @my_results.error('E111', 'process_action_files', "File #{file} referenced in update_files.json not found in #{@deposit_dir}/head/#{@contentDirectory}")
              raise "File #{file} referenced in update_files.json not found in #{@deposit_dir}/head/#{@contentDirectory}"
            end
            # Here's where we'd compute checksum.
            if OcflTools::Utils.generate_file_digest("#{@deposit_dir}/head/#{@contentDirectory}/#{file}", @digestAlgorithm) == digest
              self.update_file( file, digest, @new_version)
              @my_results.info('I111', 'process_action_files', "#{@deposit_dir}/head/#{@contentDirectory}/#{file} added to inventory.")
            else
              @my_results.error('E111', 'process_action_files', "#{@deposit_dir}/head/#{@contentDirectory}/#{file} computed checksum does not match provided digest.")
              raise "#{@deposit_dir}/head/#{@contentDirectory}/#{file} computed checksum does not match provided digest."
            end
          end
        end
      end

      # Process move_files, if present.
      # move_file requires { "source_file": "destination_file" }
      if File.exists? "#{@deposit_dir}/head/move_files.json"
        move_files = self.read_json("#{@deposit_dir}/head/move_files.json")
        move_files.each do | source_file, destination_file |
          self.move_file(source_file, destination_file, @new_version)
        end
      end

      # Process copy_files, if present.
      # copy_files requires { "source_file": ["destination_files"]}
      if File.exists? "#{@deposit_dir}/head/copy_files.json"
        copy_files = self.read_json("#{@deposit_dir}/head/copy_files.json")
        copy_files.each do | source_file, destination_files |
          destination_files.each do | destination_file |
            self.copy_file(source_file, destination_file, @new_version)
          end
        end
      end

      # Process delete_files, if present.
      # Do this last in case the same file is moved > 1.
      # { "delete": [ filepaths to delete ]}
      if File.exists? "#{@deposit_dir}/head/delete_files.json"
        delete_files = self.read_json("#{@deposit_dir}/head/delete_files.json")
        delete_files.each do | action, filepaths |
          filepaths.each do | filepath |
            self.delete_file(filepath, @new_version)
          end
        end
      end

      # If there's a fixity block, add it too.
      if File.file?  "#{@deposit_dir}/head/fixity_files.json"
        fixity_files = self.read_json("#{@deposit_dir}/head/fixity_files.json")
        fixity_files.each do | algorithm, checksums |
          # check if algorithm is in list of acceptable fixity algos for this site.
          if !OcflTools.config.fixity_algorithms.include? algorithm
            @my_results.error('E111', 'process_action_files', "#{@deposit_dir}/head/fixity_files.json contains unsupported algorithm #{algorithm}")
            raise "#{@deposit_dir}/head/fixity_files.json contains unsupported algorithm #{algorithm}"
          end
          # Algo is permitted in the fixity block; add it.
          checksums.each do | manifest_checksum, fixity_checksum |
            self.update_fixity( manifest_checksum, algorithm, fixity_checksum )
          end
        end
        @my_results.info('I111', 'process_action_files', "#{@deposit_dir}/head/fixity_files.json successfully processed.")
      end

      # Process version.json, if present.
      if File.file? "#{@deposit_dir}/head/version.json"
        version_file = self.read_json("#{@deposit_dir}/head/version.json")
        # Version block MUST contain keys 'created', 'message', 'user'
        [ 'created', 'message', 'user' ].each do | req_key |
          if !version_file.has_key?(req_key)
            @my_results.error('E111', 'process_action_files', "#{@deposit_dir}/head/version.json does not contain expected key #{req_key}")
            raise "#{@deposit_dir}/head/version.json does not contain expected key #{req_key}"
          end
        end
        # user block MUST contain 'name', 'address'
        [ 'name', 'address' ].each do | req_key |
          if !version_file['user'].has_key?(req_key)
            @my_results.error('E111', 'process_action_files', "#{@deposit_dir}/head/version.json does not contain expected key #{req_key}")
            raise "#{@deposit_dir}/head/version.json does not contain expected key #{req_key}"
          end
        end
        # Now process!
        self.set_version_user(@new_version, version_file['user'])
        self.set_version_message(@new_version, version_file['message'])
        self.set_version_created(@new_version, version_file['created'])
      end

    end

    def stage_existing_object

      # If we get here, we know that the local inventory.json is the same as the dest. inventory.json.
      self.from_file("#{@deposit_dir}/inventory.json")

      # Increment the version from the inventory.json by 1.
      @new_version = OcflTools::Utils.version_string_to_int(self.head) + 1

      self.get_version(@new_version) # Add this new version to our representation of this inventory in self.

      process_action_files # now process all our action files for this new version.

    end

    def process_new_version
      # We just passed OCflVerify to get here, so we're good to go.

      # Create version & content directory.
      target_content = "#{@object_dir}/#{@head}/#{@contentDirectory}"

      # Abort if target_content already exists!
      if Dir.exists? target_content
        @my_results.error('E111', 'process_new_version', "#{target_content} already exists! Unable to process new version.")
        raise "#{target_content} already exists! Unable to process new version."
      end

      raise "Errror creating #{target_content}!" unless FileUtils.mkdir_p target_content

      source_content = "#{@deposit_dir}/head/#{@contentDirectory}"

      # Copy [or move? make this behavior configurable] content across.
      # Why move? Well, if you're on the same filesystem root, and you're moving large files,
      # move is *much, much faster* and doesn't run the risk of bitstream corruption as it's
      # just a filesystem metadata operation.
      FileUtils.cp_r "#{source_content}/.", target_content

      # Add inventory.json to version directory.
      self.to_file("#{@object_dir}/#{@head}")
      # Verify version directory.
      validation = OcflTools::OcflValidator.new(@object_dir)
      validation.verify_directory(@new_version)

      @my_results.add_results(validation.results)
      raise "Errors detected in validation!" unless @my_results.error_count == 0
      # Add new inventory.json to object root directory. This should always be the final step.
      self.to_file(@object_dir)

      @my_results.ok('0111', 'process_new_version', "object #{self.id} version #{@new_version} successfully processed.")

    end


  end
end
