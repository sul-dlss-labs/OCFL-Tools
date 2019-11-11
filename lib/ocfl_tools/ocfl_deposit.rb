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

      # Since we are overriding OcflObject's initialize, we need to define these variables again.
      @id               = nil
      @head             = nil
      @type             = OcflTools.config.content_type
      @digestAlgorithm  = OcflTools.config.digest_algorithm # sha512 is recommended, Stanford uses sha256.
      @contentDirectory = OcflTools.config.content_directory # default is 'content', Stanford uses 'data'
      @manifest         = Hash.new
      @versions         = Hash.new # A hash of Version hashes.
      @fixity           = Hash.new # Optional. Same format as Manifest.

      @my_results  = OcflTools::OcflResults.new
      san_check
    end

    def results
      @my_results
    end

    def deposit_new_version
      # verify that our object_directory head is still what we expect.
      # create the version and contentDirectory directories.
      # move or copy content over from deposit_directory
      # write the inventory.json & sidecar into version directory.
      # do a directory verify on the new directory.
      # write the new inventory.json to object root.
      # Can only be called if there are no errors in @my_results; raise exception if otherwise?
      puts "This is deposit_new_version"
      self.set_head_version

      # Am I put together correctly?
      @my_results.add_results(OcflTools::OcflVerify.new(self).check_all)
      # If @my_results.error_count > 0, abort!
      if @my_results.error_count > 0
        raise "Errors detected in OCFL object verification. Cannot process deposit: #{@my_results.get_errors}"
      end

      if OcflTools::Utils.version_string_to_int(@head) == 1
        new_object_new_version
      else
        existing_object_new_version
      end

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
        puts "The line from namaste is #{line}"
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

      # 6. 'head' directory MUST contain an 'add_files.txt' file.
      if deposit_head_files.include? 'add_files.json'
        @my_results.info('I111', 'new_object_san_check', "#{@deposit_dir}/head contains expected add_files.json")
        deposit_head_files.delete('add_files.json')
      else
        @my_results.error('E111', 'new_object_san_check', "#{@deposit_dir}/head/add_files.json required, but not found.")
        raise "#{@deposit_dir}/head/add_files.json required, but not found."
      end

      # 7. 'head' directory MAY contain a 'fixity_files.txt' file.
      if deposit_head_files.include? 'fixity_files.json'
        @my_results.info('I111', 'new_object_san_check', "#{@deposit_dir}/head contains optional fixity_files.json")
        deposit_head_files.delete('fixity_files.json')
      else
        @my_results.info('I111', 'new_object_san_check', "#{@deposit_dir}/head does not contain optional fixity_files.json")
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
      puts 'This is existing_object_san_check'
      # Deposit directory MUST contain an inventory.json
      # Deposit directory MUST contain a matching inventory.json sidecar file.
      # inventory.json MUST validate against sidecar digest value.
      # inventory.json MUST be a valid OCFL inventory (passes OcflVerify; copy results into our results instance).
      # Deposit directory MUST NOT contain any other files.
      # Deposit directory MUST contain a 'head' directory.
      # 'head' directory must contain a 'content' directory that
      #    matches value in inventory.json or site default if not otherwise set.
      # 'head' MUST contain at least one of the 'actions' txt files (inc. fixity).
      # Object directory OCFL MUST match Deposit directory OCFL object (sidecar check)
      # - doing a digest check is the fastest way to ensure it's the same inventory file & contents.
      # Object directory OCFL must pass a structure & verify test (don't do checksum verification)

      # Only call this if we got here without errors.
      stage_existing_object
    end

    def stage_new_object
      # read id.namaste file, set @id.
      # read head/add_files.txt, process into OcflInventory.
      # - check their checksums as they are processed.
      # read head/fixity_files.txt, process into OcflInventory.

      self.id = @namaste

      add_files = self.read_json("#{@deposit_dir}/head/add_files.json")

      self.get_version(1) # It's a new OCFL object; we start at version 1.

      add_files.each do | digest, filepaths |
        filepaths.each do | file |
          # Here's where we'd compute checksum.
          if OcflTools::Utils.generate_file_digest("#{@deposit_dir}/head/#{@contentDirectory}/#{file}", @digestAlgorithm) == digest
            self.add_file( file, digest, 1)
            @my_results.info('I111', 'stage_new_object', "#{@deposit_dir}/head/#{@contentDirectory}/#{file} added to inventory.")
          else
            @my_results.error('E111', 'stage_new_object', "#{@deposit_dir}/head/#{@contentDirectory}/#{file} computed checksum does not match provided digest.")
            raise "#{@deposit_dir}/head/#{@contentDirectory}/#{file} computed checksum does not match provided digest."
          end
        end
      end

      # If there's a fixity block, add it too.
      if File.file?  "#{@deposit_dir}/head/fixity_files.json"
        fixity_files = self.read_json("#{@deposit_dir}/head/fixity_files.json")
        fixity_files.each do | algorithm, checksums |
          # check if algorithm is in list of acceptable fixity algos for this site.
          if !OcflTools.config.fixity_algorithms.include? algorithm
            @my_results.error('E111', 'stage_new_object', "#{@deposit_dir}/head/fixity_files.json contains unsupported algorithm #{algorithm}")
            raise "#{@deposit_dir}/head/fixity_files.json contains unsupported algorithm #{algorithm}"
          end
          # Algo is permitted in the fixity block; add it.
          checksums.each do | manifest_checksum, fixity_checksum |
            self.update_fixity( manifest_checksum, algorithm, fixity_checksum )
          end
        end
        @my_results.info('I111', 'stage_new_object', "#{@deposit_dir}/head/fixity_files.json successfully processed.")
      end

    end

    def stage_existing_object
      # read existing inventory into OcflInventory instance.
      # Determine next version, stage files into it.
      # - check checksums when staging.
      puts "This is stage_update_object"

    end

    def new_object_new_version
      puts "This is new_object_new_version"
      # I've got a valid OCFL object tee'd up.
      # Is my destination directory still empty?
      if !Dir.empty?(@object_dir)
        raise "#{@object_dir} is not empty! Unable to create new object."
      end
      target_content = "#{@object_dir}/#{@head}/#{@contentDirectory}"
      # Create version & content directory.
      raise "Errror creating #{target_content}!" unless FileUtils.mkdir_p target_content

      source_content = "#{@deposit_dir}/head/#{@contentDirectory}"

      # Copy/move content across.
      FileUtils.cp_r "#{source_content}/.", target_content

      # Add inventory.json to version directory.
      self.to_file("#{@object_dir}/#{@head}")
      # Verify version directory.
      validation = OcflTools::OcflValidator.new(@object_dir)
      validation.verify_directory(1)

      @my_results.add_results(validation.results)
      raise "Errors detected in validation!" unless @my_results.error_count == 0
      # Add inventory.json to root directory.
      self.to_file(@object_dir)

    end

    def existing_object_new_version
      puts "This is existing_object_new_version"
    end

  end
end
