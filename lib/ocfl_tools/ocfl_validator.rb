module OcflTools
  # Class to perform checksum and structural validation of POSIX OCFL directories.
  class OcflValidator

    # @return [Pathname] ocfl_object_root the full local filesystem path to the OCFL object root directory.
    attr_reader :ocfl_object_root

    # @return [String] version_format the discovered version format of the object, found by inspecting version directory names.
    attr_reader :version_format

    # @return [OcflTools::OcflInventory] inventory an OcflInventory object, if created.
    attr_reader :inventory

    # @return [OcflTools::OcflVerify] verify an OcflVerify object, if created.
    attr_reader :verify

    # @param [Pathname] ocfl_storage_root is a the full local filesystem path to the object directory.
    def initialize(ocfl_object_root)
      @digest           = nil
      @version_format   = nil
      @ocfl_object_root = ocfl_object_root
      @my_results       = OcflTools::OcflResults.new
      @inventory        = nil # some checks create an inventory object; have a way to get at that.
      @verify           = nil # some checks create a verify object; have a way to get at that.
      # Should check that ocfl_object_root is a readable directory.
    end

    # @return [OcflTools::OcflResults] results of validation results.
    def results
      @my_results
    end

    # Perform an OCFL-spec validation of the given object directory.
    # If given the optional digest value, verify file content using checksums in inventory file.
    # Will fail if digest is not found in manifest or a fixity block.
    # This validates all versions and all files in the object_root.
    # If you want to just check a specific version, call {verify_directory}.
    def validate_ocfl_object_root(digest=@digest)
      # calls verify_structure, verify_inventory and verify_checksums.
      self.verify_structure
      self.verify_inventory # returns a diff. results object; merge it?
      self.verify_checksums
      results = [ @my_results, @verify.my_results ]
    end

    def verify_fixity(inventory_file, digest='md5')
      # Gets the appropriate fixity block, calls verify_directory?
    end

    def verify_manifest(inventory_file="default_value")
      # If inventory_file not set, verify as @head vs all files in all version directories.
      # If inventory is set, verify as verify_version for that inventory file (v1 thru N)
      # Gets the appropriate manifest from inventory, calls verify_directory?
    end

    # The default checksum test assumes you want to test all likely files on disk against
    # whatever version of the inventory.json (hopefully the latest!) is in the root directory.
    # Otherwise, if you give it a version 3 inventory, it'll check v1...v3 directories on disk
    # against the inventory's manifest, but won't check >v4.
    def verify_checksums(inventory_file="#{@ocfl_object_root}/inventory.json")
      # validate inventory.json checksum against inventory.json.<sha256|sha512>
      # validate files in manifest against physical copies on disk.
      # cross_check digestss.
      # Report out via @my_results.
      @inventory          = OcflTools::OcflInventory.new.from_file(inventory_file)

      # if @digest is set, use that as the digest for checksumming.
      # ( but check inventory.fixity to make sure it's there first )
      # Otherwise, use the value of inventory.digestAlgorithm

      files_on_disk      = OcflTools::Utils::Files.get_versions_dir_files(@ocfl_object_root, @inventory.version_id_list.min, @inventory.version_id_list.max)

      # Now generate checksums for the files we found on disk, and Hash them.
      disk_checksums     = OcflTools::Utils::Files.create_digests(files_on_disk, @inventory.digestAlgorithm)

      # Get an equivalent hash by manipulating the inventory.manifest hash.
      manifest_checksums = OcflTools::Utils::Files.invert_and_expand_and_prepend(@inventory.manifest, @ocfl_object_root)

      @my_results        = OcflTools::Utils.compare_hash_checksums(disk_checksums: disk_checksums, inventory_checksums: manifest_checksums, results: @my_results)

    end

    # Do all the files and directories in the object_dir conform to spec?
    # Are there inventory.json files in each version directory? (warn if not in version dirs)
    # Deduce version dir naming convention by finding the v1 directory; apply that format to other dirs.
    def verify_structure

      error = nil

      begin
        if @version_format == nil
          @version_format = OcflTools::Utils::Files.get_version_format(@ocfl_object_root)
          @my_results.ok('O111', 'version_format', "OCFL conforming first version directory found.")
        end
      rescue
        @my_results.error('E111', 'version_format', "OCFL unable to determine version format by inspection of directories.")
        error = true
        # raise "Can't determine appropriate version format"
        # The rest of the method simply won't work without @version_format.
        @version_format = OcflTools.config.version_format
        @my_results.warn('W111', 'version_format', "Attempting to process using default value: #{OcflTools.config.version_format}")
      end

      object_root_dirs  = []
      object_root_files = []

      Dir.chdir(@ocfl_object_root)
      Dir.glob('*').select do |file|
         if File.directory? file
           object_root_dirs << file
         end
         if File.file? file
           object_root_files << file
         end
      end

      # CHECK for required files.
      # We have to check the top of inventory.json to get the appropriate digest algo.
      # This is so we don't cause get_digestAlgorithm to throw up if inventory.json doesn't exist.
      file_checks = [ 'inventory.json', '0=ocfl_object_1.0']

      # What digest should the inventory.json sidecar be using? Ask inventory.json.
      if File.exist? "#{@ocfl_object_root}/inventory.json"
        json_digest = OcflTools::Utils::Inventory.get_digestAlgorithm("#{@ocfl_object_root}/inventory.json")
        file_checks << "inventory.json.#{json_digest}"
      end

      file_checks.each do | file |
        if object_root_files.include? file == false
          @my_results.error('E102', 'verify_structure', "Object root does not include required file #{file}")
          error = true
        end
        # we found it, delete it and go to next.
        object_root_files.delete(file)
      end

      # Array should be empty! If not, we have extraneous files in object root.
      if object_root_files.size != 0
        @my_results.error('E101', 'verify_structure', "Object root contains noncompliant files: #{object_root_files}")
        error = true
      end

      # CHECK DIRECTORIES
      # logs are optional.
      if object_root_dirs.include? 'logs'
        @my_results.warn('W111', 'verify_structure', "OCFL 3.1 optional logs directory found in object root.")
        object_root_dirs.delete('logs')
      end

      version_directories = OcflTools::Utils::Files.get_version_directories(@ocfl_object_root)

      remaining_dirs = object_root_dirs - version_directories

      # Any content left in object_root_dirs are not compliant. Log them!
      if remaining_dirs.size > 0
        @my_results.error('E100', 'verify_structure', "Object root contains noncompliant directories: #{remaining_dirs}")
        error = true
      end

      # Now process the version directories we *did* find.
      # Must be a continuous sequence, starting at v1.
      version_dir_count = version_directories.size
      count = 0

      until count == version_dir_count
        count += 1
        expected_directory = @version_format % count
        # just check to see if it's in the array version_directories.
        # We're not *SURE* that what we have is a continous sequence starting at 1;
        # just that they're valid version dir names and they exist.
        if version_directories.include? expected_directory
          # puts "I found expected directory #{expected_directory}"
        else
          @my_results.error('E013', 'verify_structure', "Expected version directory #{expected_directory} missing from directory list #{version_directories} ")
          error = true
        end
      end

      # For the version_directories we *do* have, are they cool?
      version_directories.each do | ver |
        # Do a file and dir glob.
        version_dirs  = []
        version_files = []

        Dir.chdir("#{@ocfl_object_root}/#{ver}")
        Dir.glob('*').select do |file|
           if File.directory? file
             version_dirs << file
           end
           if File.file? file
             version_files << file
           end
        end

        # only two files here, but only warn if they're not present.
        file_checks = []
        if File.exist? "#{@ocfl_object_root}/#{ver}/inventory.json"
          json_digest = OcflTools::Utils::Inventory.get_digestAlgorithm("#{@ocfl_object_root}/#{ver}/inventory.json")
          file_checks << "inventory.json"
          file_checks << "inventory.json.#{json_digest}"
        else
          file_checks << "inventory.json" # We look for it, even though we know we won't find it, so we can log the omission.
        end

        file_checks.each do | file |
          if version_files.include? file
            version_files.delete(file)
            else
            @my_results.warn('W111', 'verify_structure', "OCFL 3.1 optional #{file} missing from #{ver} directory")
            version_files.delete(file)
          end
        end

        if version_files.size > 0
          @my_results.error('E011', 'verify_structure', "non-compliant files #{version_files} in #{ver} directory")
          error = true
        end

        # TODO: Is there a better way to get the content_directory? We should be getting this from a local inventory file?
        if version_dirs.include? OcflTools.config.content_directory
          version_dirs.delete(OcflTools.config.content_directory)
          else
          @my_results.error('E012', 'verify_structure', "required content directory #{OcflTools.config.content_directory} not found in #{ver} directory")
          error = true
        end

        if version_dirs.size > 0
          @my_results.error('E010', 'version_structure', "noncompliant directories #{version_dirs} found in #{ver} directory")
          error = true
        end

      end

      # If we get here without errors (warnings are OK), we passed!
      if error == nil
        @my_results.ok('O111', 'verify_structure', "OCFL 3.1 Object root passed file structure test.")
      end
      return @my_results
    end

    # We may also want to only verify a specific directory, not the entire object.
    # For example, if we've just added a new version, we might want to just check those files
    # and not the rest of the object (esp. if it has some very large version directories).
    def verify_directory(version, digest=nil)

      # start by getting version format and directories.
      if @version_format == nil
        @version_format = OcflTools::Utils::Files.get_version_format(@ocfl_object_root)
      end

      # result = OcflTools.config.version_format % version.to_i
      version_name = @version_format % version.to_i
      # Make sure this directory actually exists.
      raise "Requested version directory doesn't exist!" unless Dir.exist?("#{@ocfl_object_root}/#{version_name}")

      #OK, now we need an inventory.json to tell use what teh contentDirectory should be.
      if File.exist?("#{ocfl_object_root}/#{version_name}/inventory.json")
        my_content_dir = OcflTools::Utils::Inventory.get_contentDirectory("#{ocfl_object_root}/#{version_name}/inventory.json")
        @inventory     = OcflTools::OcflInventory.new.from_file("#{ocfl_object_root}/#{version_name}/inventory.json")
      else
        my_content_dir = OcflTools::Utils::Inventory.get_contentDirectory("#{ocfl_object_root}/inventory.json")
        @inventory     = OcflTools::OcflInventory.new.from_file("#{ocfl_object_root}/inventory.json")
      end

      # Get a list of fully-resolvable files for this version directory from disk.
      my_files_on_disk = OcflTools::Utils::Files.get_version_dir_files(@ocfl_object_root, version)

      # Now process my_inventory.manifest
      # Flip and invert  it.
      manifest_checksums = OcflTools::Utils::Files.invert_and_expand_and_prepend(@inventory.manifest, @ocfl_object_root )

      # Now we need to trim manifest_checksums to the stuff that only matches
      # ocfl_object_root/version_string/content_dir
      filtered_checksums = {}
      manifest_checksums.each do | file, digest |
        if file =~ /^#{ocfl_object_root}\/#{version_name}\/#{my_content_dir}/
          filtered_checksums[file] = digest
        end
      end

      # Now generate checksums for the files we found on disk, and Hash them.
      disk_checksums = OcflTools::Utils::Files.create_digests(my_files_on_disk, @inventory.digestAlgorithm)

      #Finally! Pass them to checksum checker.
      @my_results = OcflTools::Utils.compare_hash_checksums(disk_checksums: disk_checksums, inventory_checksums: filtered_checksums, results: @my_results, context: "verify_directory #{version_name}")
    end

    # Different from verify_directory.
    # Verify_version is *all* versions of the object, up to and including this one.
    # Verify_directory is *just* check the files and checksums of inside that particular version directory.
    # Verify_version(@head) is the canonical way to check an entire object?
    def verify_version(version)
    end

    # Is the inventory file valid?
    # @return [OcflTools::OcflResults] of verification results.
    def verify_inventory(inventory_file="#{@ocfl_object_root}/inventory.json")
      # Load up the object with ocfl_inventory, push it through ocfl_verify.
      @inventory = OcflTools::OcflInventory.new.from_file(inventory_file)
      @verify    = OcflTools::OcflVerify.new(@inventory)
      @verify.check_all # creates & returns @results object from OcflVerify
    end

    # Do all the files mentioned in the inventory(s) exist on disk?
    # This is an existence check, not a checksum verification.
    def verify_files
      # Calls verify_directory for each version?
    end

  end
end
