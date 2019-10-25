module OcflTools
  # Class to perform checksum and structural validation of POSIX OCFL directories.

  # I'm a doof - Validator does *not* inherit Ocfl::Verify.
  class OcflValidator

    # @return [Pathname] ocfl_object_root the full local filesystem path to the OCFL object root directory.
    attr_reader :ocfl_object_root

    # @return [String] version_format the discovered version format of the object, found by inspecting version directory names.
    attr_reader :version_format

    # @param [Pathname] ocfl_storage_root is a the full local filesystem path to the object directory.
    def initialize(ocfl_object_root)
      @digest           = nil
      @version_format   = nil
      @ocfl_object_root = ocfl_object_root
      @my_results       = Hash.new
      @my_results['errors'] = {}
      @my_results['warnings'] = {}
      @my_results['pass'] = {}

    end

    def results
      @my_results
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
      begin
        if @version_format == nil
          self.get_version_format
        end
      rescue
        error('version_format', "OCFL no appropriate version formats")
        raise "Can't determine appropriate version format"
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

      error = nil
      # CHECK for required files.
        [ "inventory.json", "inventory.json.sha512", "0=ocfl_object_1.0" ].each do | file |
        if object_root_files.include? file == false
          error('verify_structure', "OCFL 3.1 Object root does not include required file #{file}")
          error = true
        end
        # we found it, delete it and go to next.
        object_root_files.delete(file)
      end

      # Array should be empty! If not, we have extraneous files in object root.
      if object_root_files.size != 0
        error('verify_structure', "OCFL 3.1 Object root contains noncompliant files: #{object_root_files}")
        error = true
      end

      # CHECK DIRECTORIES
      # logs are optional.
      if object_root_dirs.include? 'logs'
        warning('verify_structure', "OCFL 3.1 optional logs directory found in object root.")
        object_root_dirs.delete('logs')
      end
      # we should be left with *only* version directories.
      count = 0
      dirs  = object_root_dirs.length # the number of expected versions.
      version_directories = [] # we need this for later.

      puts "I have #{object_root_dirs}  directories to check"
      until count == dirs # as we process dirs, object_root_dirs.length will change. So don't use it here.
        count += 1
        expected_directory = @version_format % count # get the version string in expected format.
        puts "processing dir #{count}, looking for #{expected_directory}"
        # As we find matching version directories, put them into version_directories []
        if object_root_dirs.include? expected_directory
          version_directories << expected_directory
          object_root_dirs.delete(expected_directory)
          puts "found version dir #{expected_directory}"
        end
      end

      # Any content left in object_root_dirs are not compliant. Log them!
      if object_root_dirs.size != 0
        error('verify_structure', "OCFL 3.1 Object root contains noncompliant directories: #{object_root_dirs}")
        error = true
      end

      # Now process the version directories we *did* find.
      # Must be a continuous sequence, starting at v1.
      version_directories.sort!
      version_dir_count = version_directories.length
      count = 0

      until count == version_dir_count
        count += 1
        expected_directory = @version_format % count
        # just check to see if it's in the array version_directories.
        # We're not *SURE* that what we have is a continous sequence starting at 1;
        # just that they're valid version dir names and they exist.

      end


      # If we get here without errors, we passed!
      if error == nil
        pass('verify_structure', "OCFL 3.1 Object root passed file structure test.")
      end
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
      # Raises errors if it can't find an appropriate version 1 directory.
      version_dirs = []
      Dir.chdir(@ocfl_object_root)
      Dir.glob('v*').select do |file|
         if File.directory? file
           version_dirs << file
         end
      end
      version_dirs.sort!
      # if there's a verson_dirs that's just 'v', throw it out! It's hot garbage.
      if version_dirs.include? 'v'
        version_dirs.delete('v')
      end

      first_version = version_dirs[0]   # the first element should be the first version directory.
      first_version.slice!(0,1)         # cut the leading 'v' from the string.
      case
      when first_version.length == 1    # A length of 1 for the first version implies 'v1'
          raise "#{@ocfl_object_root}/#{first_version} is not the first version directory!" unless first_version.to_i == 1
          @version_format = "v%d"
        else
          # Make sure this is Integer 1.
          raise "#{@ocfl_object_root}/#{first_version} is not the first version directory!" unless first_version.to_i == 1
          @version_format = "v%0#{first_version.length}d"
          pass('version_format', "OCFL conforming first version directory found.")
      end
    end

    private
    # Internal logging method.
    # @param [String] check
    # @param [String] message
    def error(check, message)
      if @my_results['errors'].key?(check) == false
        @my_results['errors'][check] = []  # add an initial empty array.
      end
      @my_results['errors'][check] = ( @my_results['errors'][check] << message )
    end

    # Internal logging method.
    # @param [String] check
    # @param [String] message
    def warning(check, message)
      if @my_results['warnings'].key?(check) == false
        @my_results['warnings'][check] = []  # add an initial empty array.
      end
      @my_results['warnings'][check] = ( @my_results['warnings'][check] << message )
    end

    # Internal logging method.
    # @param [String] check
    # @param [String] message
    def pass(check, message)
      if @my_results['pass'].key?(check) == false
        @my_results['pass'][check] = []  # add an initial empty array.
      end
      @my_results['pass'][check] = ( @my_results['pass'][check] << message )
    end
  end
end
