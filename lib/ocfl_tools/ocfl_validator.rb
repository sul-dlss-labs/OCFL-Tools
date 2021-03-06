# frozen_string_literal: true

module OcflTools
  # Class to perform validation actions on POSIX directories that potentially contain OCFL objects.
  class OcflValidator
    # @return [Pathname] the full local filesystem path to the OCFL object root directory.
    attr_reader :ocfl_object_root

    # @return [String] the discovered version format of the object, found by inspecting version directory names.
    attr_reader :version_format

    # @return [String] the version of OCFL that this validator object is targeting.
    attr_accessor :ocfl_version

    # @return {OcflTools::OcflInventory} an OcflInventory instance that represents an inventory.json file, if the directory contains a valid OCFL object.
    attr_reader :inventory

    # @return {OcflTools::OcflVerify} an OcflVerify instance that represents the results of requesting verification of an OcflInventory.
    attr_reader :verify

    # @param [Pathname] ocfl_object_root is a the full local filesystem path to the object directory.
    def initialize(ocfl_object_root)
      unless File.directory? ocfl_object_root
        raise "#{ocfl_object_root} is not a directory!"
      end

      @digest           = nil
      @version_format   = nil
      @ocfl_version     = nil
      @ocfl_object_root = ocfl_object_root
      @my_results       = OcflTools::OcflResults.new
      @inventory        = nil # some checks create an inventory object; have a way to get at that.
      @verify           = nil # some checks create a verify object; have a way to get at that.
    end

    # Get the current summation of results events for this instance, including a roll-up of any verify actions.
    # @return [OcflTools::OcflResults] current validation results.
    def results
      @my_results.add_results(@verify.results) unless @verify.nil?
      @my_results
    end

    # Perform an OCFL-spec validation of the given object directory.
    # If given the optional digest value, verify file content using checksums in inventory file will fail if digest is not found in manifest or a fixity block. This validates all versions and all files in the object_root. If you want to just check a specific version, call {verify_directory}.
    # @param [String] digest optional digest to use, if one wishes to use values in the fixity block instead of the official OCFL digest values.
    # @return {OcflTools::OcflResults} event results
    def validate_ocfl_object_root(digest: nil)
      # calls verify_structure, verify_inventory and verify_checksums.
      verify_structure
      verify_inventory # returns a diff. results object; merge it?
      verify_manifest
      if !digest.nil?
        verify_fixity(digest: digest)
      else
        verify_checksums
      end
      results # this copies verify.results into our main results object, if it exists.
    end

    # Performs checksum validation of files listed in the inventory's fixity block.
    # @param [Pathname] inventory_file fully-qualified path to a valid OCFL inventory.json.
    # @param [String] digest string value of the algorithm to use for this fixity check. This value must exist as a key in the object's fixity block.
    # @return {OcflTools::OcflResults} of event results
    def verify_fixity(inventory_file: "#{@ocfl_object_root}/inventory.json", digest: 'md5')
      # Gets the appropriate fixity block, calls compare_hash_checksums

      begin
        @inventory = load_inventory(inventory_file)
      rescue OcflTools::Errors::ValidationError
        @my_results.error('E210', 'verify_fixity', "Unable to process inventory file #{inventory_file}.")
        return @my_results
      end

      # Since fixity blocks are not required to be complete, we just validate what's there.
      # So get the fixity block, flip it, expand it, checksum it against the same files on disk.

      if @inventory.fixity.empty?
        @my_results.error('E111', "verify_fixity #{digest}", "No fixity block in #{inventory_file}!")
        return @my_results
      end

      unless @inventory.fixity.key?(digest)
        @my_results.error('E111', "verify_fixity #{digest}", "Requested algorithm #{digest} not found in fixity block.")
        return @my_results
      end

      fixity_checksums = OcflTools::Utils::Files.invert_and_expand_and_prepend(@inventory.fixity[digest], @ocfl_object_root)

      my_files_on_disk = fixity_checksums.keys

      # Warn if there are less files in requested fixity block than in manifest.
      if @inventory.manifest.keys.size > fixity_checksums.keys.size
        missing_files = @inventory.manifest.keys.size - fixity_checksums.keys.size
        @my_results.warn(
          'W111',
          "verify_fixity #{digest}",
          "#{missing_files} files in manifest are missing from fixity block."
        )
      end

      # check these files exist on disk before trying to make checksums!
      my_files_on_disk.each do |file|
        unless File.file? file
          @my_results.error('E111', "verify_fixity #{digest}", "File #{file} in fixity block not found on disk.")
          my_files_on_disk.delete(file)
        end
      end

      disk_checksums = OcflTools::Utils::Files.create_digests(my_files_on_disk, digest)

      # And now we can compare values!
      OcflTools::Utils.compare_hash_checksums(
        disk_checksums: disk_checksums,
        inventory_checksums: fixity_checksums,
        results: @my_results,
        context: "verify_fixity #{digest}"
      )
    end

    # Given an inventory file, do the files mentioned in the manifest exist on disk?
    # This is a basic file existence cross-check.
    # @param [Pathname] inventory_file fully-qualified path to a valid OCFL inventory.json.
    # @return {OcflTools::OcflResults} of event results
    def verify_manifest(inventory_file = "#{@ocfl_object_root}/inventory.json")
      @my_results ||= OcflTools::OcflResults.new
      unless File.exist?(inventory_file)
        @my_results.error('E215', 'verify_files', "Expected inventory file #{inventory_file} not found.")
        return @my_results
      end

      begin
        @inventory = load_inventory(inventory_file)
      rescue OcflTools::Errors::ValidationError
        @my_results.error('E210', 'verify_fixity', "Unable to process inventory file #{inventory_file}.")
        return @my_results
      end

      # These are arrays, not hashes, so they must be sorted for the comparison below to work.
      files_in_manifest  = OcflTools::Utils::Files.invert_and_expand_and_prepend(@inventory.manifest, @ocfl_object_root).keys.sort
      files_on_disk      = OcflTools::Utils::Files.get_versions_dir_files(@ocfl_object_root, @inventory.version_id_list.min, @inventory.version_id_list.max).sort

      # E012: Check that the contentDirectory value in inventory is present on disk.
      # 3.3.1 Content directory
      # Version directories MUST contain a designated content sub-directory if the version contains files to be preserved,
      # and SHOULD NOT contain this sub-directory otherwise.
      @inventory.versions.keys.each do | version |
        # Are there files mentioned in the manifest for this version?
        files_in_this_version = files_in_manifest.grep(/^#{@ocfl_object_root}\/#{version}/)
        if files_in_this_version.size > 0
          if Dir.exist?("#{@ocfl_object_root}/#{version}/#{@inventory.contentDirectory}")
            @my_results.info('I200', 'verify_manifest', "OCFL 3.3.1 Expected content directory #{version}/#{@inventory.contentDirectory} found.")
          else
            @my_results.error('E012', 'verify_manifest', "OCFL 3.3.1 Expected content directory #{version}/#{@inventory.contentDirectory} not found.")
            # IF WE GET THIS RESULT, then files_on_disk is likely not going to work (it expects contentDirectory to NOT LIE).
          end
        else
          if Dir.exist?("#{@ocfl_object_root}/#{version}/#{@inventory.contentDirectory}")
            @my_results.warn('W102', 'verify_manifest', "OCFL 3.3.1 version #{version} contentDirectory should not be empty.")
          else
            @my_results.info('I200', 'verify_manifest', "OCFL 3.3.1 version #{version} does not have (and should not have) a contentDirectory directory.")
          end
        end
      end

      # get_versions_dir_files relies on contentDirectory value being correct. Check!
      # If the prefix of files_in_manifest DOES NOT MATCH object_root/<ver>/contentDirectory, we have a problem.
      case
        when files_in_manifest.size > 0
          working_files = OcflTools::Utils::Files.invert_and_expand(@inventory.manifest).keys
          # gives me version/contentDir/<foo>
          # ....and I know that '/' is the delimiter, and element 0 is version. I want element 1, the content_dir value.
          manifest_content_dirs = []
          working_files.each do | file |
            manifest_content_dirs << file.split('/')[1]
            # Need this from manifest: /object_root/version/[contentDirectory]/file
          end
          manifest_content_dirs.uniq!
          manifest_content_dirs.each do | mcd |
          if "#{mcd}" != "#{@inventory.contentDirectory}"
            # Don't need this; version_structure test will pick up on this directory's presence.
            # @my_results.error('E111', 'verify_manifest', "content directory '#{mcd}' discovered in manifest DOES NOT match inventory contentDirectory value!")
            # We should check that path on disk to see if there's content there.
            @inventory.versions.keys.each do | version |
              my_files = OcflTools::Utils::Files.get_dir_files("#{@ocfl_object_root}/#{version}/#{mcd}")
              # And expand it to a full file path (returns an array, so flatten it out and append to files_on_disk.
              OcflTools::Utils::Files.expand_filepaths(my_files, "#{@ocfl_object_root}/#{version}/#{mcd}").each do | file |
                files_on_disk << file
              end
            end
            files_on_disk.uniq! # Just to make sure there's no funky business.
          end
        end
      end

      # we only need the files (keys), not the digests here.
      if files_on_disk == files_in_manifest
        @my_results.ok('O200', 'verify_manifest', "All files in inventory were found on disk.")
        @my_results.ok('O200', 'verify_manifest', "All discovered files on disk are referenced in inventory file.")
        # Now call verify_versions_across_inventories;  this will check to make sure all prior inventories match this one.
        verify_versions_across_inventories
        return @my_results
      end

      missing_from_disk = []
      files_in_manifest.each do | file |
        # Is there a match to a file in files_on_disk ?
        unless files_on_disk.include? file  # Unless this returns true, the file's not there.
          missing_from_disk << file
        end
      end

      missing_from_manifest = []
      files_on_disk.each do | file |
        unless files_in_manifest.include? file
          missing_from_manifest << file
        end
      end

      unless missing_from_manifest.empty?
        missing_from_manifest.each do |missing|
          @my_results.error('E111', 'verify_manifest', "Unexpected file #{missing} discovered on disk.")
        end
        if missing_from_disk.empty?
          if files_in_manifest.size < 1
            @my_results.warn('W111', 'verify_manifest', 'No files were found in manifest.')
          else
            @my_results.ok('O200', 'verify_manifest', "All files in inventory were found on disk.")
          end
        end
      end

      unless missing_from_disk.empty?
        missing_from_disk.each do |missing|
          @my_results.error('E111', 'verify_manifest', "Expected file #{missing} not found on disk.")
        end
        if missing_from_manifest.empty?
          # This is NOT TRUE if there were no files_on_disk in the first place!
          if files_on_disk.size < 1
            @my_results.warn('W111', 'verify_manifest', "No files discovered on disk.")
          else
            @my_results.ok('O200', 'verify_manifest', "All discovered files on disk are referenced in inventory file.")
          end
        end
      end
      # Now call verify_versions_across_inventories;  this will check to make sure all prior inventories match this one.
      verify_versions_across_inventories
      @my_results
    end

    # The default checksum test assumes you want to test all likely files on disk against
    # whatever version of the inventory.json (hopefully the latest!) is in the root directory.
    # Otherwise, if you give it a version 3 inventory, it'll check v1...v3 directories on disk
    # against the inventory's manifest, but won't check >v4.
    # {#verify_structure} will, however, let you know if your most recent inventory goes to v3,
    # but there's a v4 directory in your object root.
    # @param [Pathname] inventory_file fully-qualified path to a valid OCFL inventory.json.
    # @return {OcflTools::OcflResults} of event results
    def verify_checksums(inventory_file = "#{@ocfl_object_root}/inventory.json")
      # validate inventory.json checksum against inventory.json.<sha256|sha512>
      # validate files in manifest against physical copies on disk.
      # cross_check digestss.
      # Report out via @my_results.
      # Inventory file does not exist; create a results object, record this epic fail, and return.
      @my_results ||= OcflTools::OcflResults.new
      unless File.exist?(inventory_file)
        @my_results.error('E215', 'verify_checksums', "Expected inventory file #{inventory_file} not found.")
        return @my_results
      end

      begin
        @inventory = load_inventory(inventory_file)
      rescue OcflTools::Errors::ValidationError
        @my_results.error('E210', 'verify_checksums', "Unable to process inventory file #{inventory_file}.")
        return @my_results
      end

      # if @digest is set, use that as the digest for checksumming.
      # ( but check inventory.fixity to make sure it's there first )
      # Otherwise, use the value of inventory.digestAlgorithm
      # TODO: files_on_disk here LIES if contentDirectory value is wrong!
#      files_on_disk = OcflTools::Utils::Files.get_versions_dir_files(@ocfl_object_root, @inventory.version_id_list.min, @inventory.version_id_list.max)
      # WORK OUT what contentDirectory is by inspecting all paths in inventory.manifest.
      files_on_disk = []
      working_files = OcflTools::Utils::Files.invert_and_expand(@inventory.manifest).keys
      # gives me version/contentDir/<foo>
      # ....and I know that '/' is the delimiter, and element 0 is version. I want element 1, the content_dir value.
      manifest_content_dirs = []
      working_files.each do | file |
        manifest_content_dirs << file.split('/')[1]
      end
      manifest_content_dirs.uniq!
      manifest_content_dirs.each do | mcd |
        # We should check that path on disk to see if there's content there.
        @inventory.versions.keys.each do | version |
          my_files = OcflTools::Utils::Files.get_dir_files("#{@ocfl_object_root}/#{version}/#{mcd}")
          # And expand it to a full file path (returns an array, so flatten it out and append to files_on_disk.
          OcflTools::Utils::Files.expand_filepaths(my_files, "#{@ocfl_object_root}/#{version}/#{mcd}").each do | file |
            files_on_disk << file
          end
        end
        files_on_disk.uniq! # Just to make sure there's no funky business.
      end

      # Now generate checksums for the files we found on disk, and Hash them.
      disk_checksums = OcflTools::Utils::Files.create_digests(files_on_disk, @inventory.digestAlgorithm)
      # Get an equivalent hash by manipulating the inventory.manifest hash.
      manifest_checksums = OcflTools::Utils::Files.invert_and_expand_and_prepend(@inventory.manifest, @ocfl_object_root)
      # Returns OcflTools::OcflResults object; either new or the one passed in with new content.
      OcflTools::Utils.compare_hash_checksums(disk_checksums: disk_checksums, inventory_checksums: manifest_checksums, results: @my_results)
    end

    # Do all the files and directories in the object_dir conform to spec?
    # Are there inventory.json files in each version directory? (warn if not in version dirs)
    # Deduce version dir naming convention by finding the v1 directory; apply that format to other dirs.
    # @return {OcflTools::OcflResults} of event results
    def verify_structure
      error = nil
      @my_results ||= OcflTools::OcflResults.new
      # 1. use get_version_format to determine the format used for version directories.
      #    If we can't deduce it by inspection of the object_root, ERROR and try and process using site-wide defaults.
      if get_version_format == false
        @my_results.error('E111', 'verify_structure', 'OCFL unable to determine version format by inspection of directories.')
        @error = true
      end

      object_root_dirs  = []
      object_root_files = []

      Dir.chdir(@ocfl_object_root)
      Dir.glob('*').select do |file|
        object_root_dirs << file if File.directory? file
        object_root_files << file if File.file? file
      end

      # 1b. What happens if some this directory is just completely empty?
      if object_root_dirs.size == 0 && object_root_files.size == 0
        @my_results.error('E100', 'verify_sructure', "Object root directory #{@ocfl_object_root} is empty.")
        return @my_results
      end

      # 2. Check object root directory for required files.
      # We have to check the top of inventory.json to get the appropriate digest algo.
      # This is so we don't cause get_digestAlgorithm to throw up if inventory.json doesn't exist.
      file_checks = ['inventory.json']

      # 2a. What digest should the inventory.json sidecar be using? Ask inventory.json.
      # 2b. What's the highest version we should find here?
      # 2c. What should our contentDirectory value be?
      if File.exist? "#{@ocfl_object_root}/inventory.json"
        begin
          @inventory = load_inventory("#{@ocfl_object_root}/inventory.json")
          json_digest      = OcflTools::Utils::Inventory.get_digestAlgorithm("#{@ocfl_object_root}/inventory.json")
          contentDirectory = OcflTools::Utils::Inventory.get_contentDirectory("#{@ocfl_object_root}/inventory.json")
          expect_head      = OcflTools::Utils::Inventory.get_value("#{@ocfl_object_root}/inventory.json", 'head')
          file_checks << "inventory.json.#{json_digest}"
        rescue OcflTools::Errors::ValidationError
          # We couldn't load up the inventory; use site defaults.
          contentDirectory = OcflTools.config.content_directory
          json_digest      = OcflTools.config.digest_algorithm
          file_checks << "inventory.json.#{json_digest}"
        end
      else
        # If we can't get these values from a handy inventory.json, use the site defaults.
        contentDirectory = OcflTools.config.content_directory
        json_digest      = OcflTools.config.digest_algorithm
        file_checks << "inventory.json.#{json_digest}"
      end

      # Error if a required file is not found in the object root.
      # This is now just the check for inventory.json and sidecar file.
      file_checks.each do |file|
        unless object_root_files.include? file
          @my_results.error('E102', 'verify_structure', "Object root does not include required file #{file}")
          error = true
        end
        object_root_files.delete(file)
      end

      # NamAsTe file checks:
      # C1: There should be only 1 file in the root dir beginning with '0=ocfl_object_'
      # C2: That file should match the expected value of OCFL_version (e.g. '0=ocfl_object_1.0')
      # C3: The content of that file should match the filename, less the leading '0='
      root_namaste_files = []
      Dir.glob('0=ocfl_object_*').select do |file|
        root_namaste_files << file if File.file? file
      end

      # C1: We need EXACTLY ONE of these files.
      if root_namaste_files.size == 0
        @my_results.error('E103', 'verify_structure', 'Object root does not include required NamAsTe file.')
        error = true
      end

      if root_namaste_files.size > 1
        @my_results.error('E104', 'verify_structure', "Object root contains multiple NamAsTe files: #{root_namaste_files}")
        error = true
      end

      # C2 and C3 here.
      # If we're dealing with 1 or more ocfl_object_files, process them for correctness.
      unless root_namaste_files.size == 0 || root_namaste_files.size == nil

        # What OCFL version are we looking for? Pull the default value if not otherwise set.
        @ocfl_version ||= OcflTools.config.ocfl_version

        root_namaste_files.each do | file |

          # C2: Is this file the expected version?
          if file != "0=ocfl_object_#{@ocfl_version}"
            @my_results.error('E107', 'verify_structure', "Required NamAsTe file in object root is for unexpected OCFL version: #{file}")
            error = true
          end

          # C3: does the file content match the file name?
          # Cut the first 2 characters from the filename; what remains is the expected content.
          expected_content = file.slice(2..file.size)

          # We use &:gets here instead of &:readline so we don't throw an exception if the file doesn't have content.
          first_line = File.open("#{@ocfl_object_root}/#{file}", &:gets)

          # Handle 'the Namaste file is empty' case.
          if first_line == nil
            @my_results.error('E105', 'verify_structure', 'Required NamAsTe file in object root directory has no content!')
            error = true
            object_root_files.delete(file)
            next
          end

          # it'll have a \n on the end. Remove it, then verify for correct content.
          if first_line.chomp! != expected_content
            @my_results.error('E106', 'verify_structure', 'Required NamAsTe file in object root directory does not contain expected string.')
            error = true
          end
          object_root_files.delete(file)
        end
      end

      # 3. Error if there are extraneous files in object root.
      unless object_root_files.empty?
        @my_results.error('E101', 'verify_structure', "Object root contains noncompliant files: #{object_root_files}")
        error = true
      end

      # 4. Warn if the optional 'logs' directory is found in the object root.
      if object_root_dirs.include? 'logs'
        @my_results.warn('W111', 'verify_structure', 'OCFL 3.1 optional logs directory found in object root.')
        object_root_dirs.delete('logs')
      end

      # 5. Warn if the optional 'extensions' directory is found in object root.
      if object_root_dirs.include? 'extensions'
        @my_results.warn('W111', 'verify_structure', 'OCFL 3.1 optional extensions directory found in object root.')
        object_root_dirs.delete('extensions')
      end

      begin
        version_directories = OcflTools::Utils::Files.get_version_directories(@ocfl_object_root)
      rescue OcflTools::Errors::ValidationError => e
        e.details.each do | code, messages |
          messages.each do | msg |
            @my_results.error(code, 'verify_structure', msg)
          end
        end
        # If we actually throw a validation error, we can't proceed: no version directories found!
        return @my_results
      end

      remaining_dirs = object_root_dirs - version_directories

      # 6. Error if there are extraneous/unexpected directories in the object root.
      unless remaining_dirs.empty?
        @my_results.error('E100', 'verify_structure', "Object root contains noncompliant directories: #{remaining_dirs}")
        error = true
      end

      # 7. Version directories must be a continuous sequence, starting at v1.
      version_dir_count = version_directories.size
      count = 0

      until count == version_dir_count
        count += 1
        expected_directory = @version_format % count
        # just check to see if it's in the array version_directories.
        # We're not *SURE* that what we have is a continous sequence starting at 1;
        # just that they're valid version dir names, sorted in ascending order, and they exist.
        if version_directories.include? expected_directory
          # Could verbose log this here.
          # @my_results.info('I200', 'verify_sructure', "Expected version directory #{expected_directory} found.")
        else
          @my_results.error('E013', 'verify_structure', "Expected version directory #{expected_directory} missing from directory list #{version_directories} ")
          error = true
        end
      end

      # 8. Error if the head version in the inventory does not match the highest version directory discovered in the object root.
      unless expect_head.nil? # No point checking this is we've already failed the root inventory.json check.
        if version_directories[-1] != expect_head
          @my_results.error('E111', 'verify_structure', "Inventory file expects a highest version of #{expect_head} but directory list contains #{version_directories} ")
          error = true
        else
          # could log an 'expected head version found' here.
        end
      end

      # CHECK VERSION DIRECTORY CONTENTS
      # This is setup for the next round of checks.
      # For the version_directories we *do* have, are they cool?
      version_directories.each do |ver|
        version_dirs  = []
        version_files = []

        Dir.chdir("#{@ocfl_object_root}/#{ver}")
        Dir.glob('*').select do |file|
          version_dirs << file if File.directory? file
          version_files << file if File.file? file
        end

        # 9. Warn if inventory.json and sidecar are not present in version directory.
        file_checks = []
        if File.exist? "#{@ocfl_object_root}/#{ver}/inventory.json"
          begin
            @inventory = load_inventory("#{@ocfl_object_root}/#{ver}/inventory.json")
            json_digest      = OcflTools::Utils::Inventory.get_digestAlgorithm("#{@ocfl_object_root}/#{ver}/inventory.json")
            file_checks << 'inventory.json'
            file_checks << "inventory.json.#{json_digest}"
            versionContentDirectory = OcflTools::Utils::Inventory.get_contentDirectory("#{@ocfl_object_root}/#{ver}/inventory.json")
            if versionContentDirectory != contentDirectory
              @my_results.error('E111', 'verify_structure', "contentDirectory value #{versionContentDirectory} in version #{ver} does not match expected contentDirectory value #{contentDirectory}.")
              error = true
            end
          rescue OcflTools::Errors::ValidationError
            # We couldn't load up the inventory; use site defaults.
            # We should also record the error in @my_results?
            json_digest = OcflTools.config.digest_algorithm
            file_checks << 'inventory.json'
            file_checks << "inventory.json.#{json_digest}"
            error = true
          end
        else
          file_checks << 'inventory.json'         # We look for it, even though we know we won't find it, so we can log the omission.
          file_checks << 'inventory.json.sha512'  # We look for it, even though we know we won't find it, so we can log the omission.
        end

        file_checks.each do |file|
          if version_files.include? file
            # The inventory file in the highest version directory MUST match the inventory file in the object root.
            case file
              when 'inventory.json'
                case ver
                  # expect_head is nil if there's no inventory.json in the object root, so this test won't run against nothing.
                  when expect_head
                    # expand_filepaths(@ocfl_object_root)
                    my_files = ["#{@ocfl_object_root}/inventory.json", "#{@ocfl_object_root}/#{ver}/inventory.json"]
                    # create_digests
                    my_digests = OcflTools::Utils::Files.create_digests(my_files, 'sha512')
                    # We know there must be only 2 values here, and they should be equal.
                    if my_digests.values[0] != my_digests.values[1]
                      @my_results.error('E111', 'verify_structure', "Inventory.json in root and highest version #{ver} MUST match.")
                    end
                    # Only 1 case block, no 'else'
                  end
                # Only 1 case block, no 'else'
              end
            # Expected file exists; delete it from our check list and move on.
            version_files.delete(file)
          else
            @my_results.warn('W111', 'verify_structure', "OCFL 3.1 optional #{file} missing from #{ver} directory")
            version_files.delete(file)
          end
        end

        # 10. Error if files other than inventory & sidecar found in version directory.
        unless version_files.empty?
          @my_results.error('E011', 'verify_structure', "non-compliant files #{version_files} in #{ver} directory")
          error = true
        end

        ###### CHECK THIS; I think this is superseded by the verify_manifest content_dir check.
        # 11. WARN if a contentDirectory exists, but is empty.
        if version_dirs.include? contentDirectory
          version_dirs.delete(contentDirectory)
        end

        # 12. Warn if any directories other than the expected 'content' directory are found in the version directory.
        # This is the "Moab Excepion" to allow for legacy Moab object migration - a 'manifests' directory would be here.
        unless version_dirs.empty?
          @my_results.warn('W101', 'version_structure', "OCFL 3.3 version directory should not contain any directories other than the designated content sub-directory. Additional directories found: #{version_dirs}")
          error = true
        end
      end

      # If we get here without errors (warnings are OK), we passed!
      if error.nil?
        @my_results.ok('O111', 'verify_structure', 'OCFL 3.1 Object root passed file structure test.')
      end
      @my_results
    end

    # We may also want to only verify a specific directory, not the entire object.
    # For example, if we've just added a new version, we might want to just check those files
    # and not the rest of the object (esp. if it has some very large version directories).
    # @param [Integer] version directory to verify
    # @return {OcflTools::OcflResults} of verify events
    def verify_directory(version)
      # start by getting version format and directories.
      get_version_format # sets @version_format, one way or another.

      version_name = @version_format % version.to_i
      # Make sure this directory actually exists.
      unless File.directory?("#{@ocfl_object_root}/#{version_name}")
        raise "Requested version directory doesn't exist!"
      end

      # OK, now we need an inventory.json to tell use what the contentDirectory should be.
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
      manifest_checksums = OcflTools::Utils::Files.invert_and_expand_and_prepend(@inventory.manifest, @ocfl_object_root)

      # Now we need to trim manifest_checksums to the stuff that only matches
      # ocfl_object_root/version_string/content_dir
      filtered_checksums = {}
      manifest_checksums.each do |file, digest|
        if file =~ %r{^#{ocfl_object_root}/#{version_name}/#{my_content_dir}}
          filtered_checksums[file] = digest
        end
      end

      # Now generate checksums for the files we found on disk, and Hash them.
      disk_checksums = OcflTools::Utils::Files.create_digests(my_files_on_disk, @inventory.digestAlgorithm)

      # Finally! Pass them to checksum checker.
      OcflTools::Utils.compare_hash_checksums(disk_checksums: disk_checksums, inventory_checksums: filtered_checksums, results: @my_results, context: "verify_directory #{version_name}")
    end

    # Different from verify_directory.
    # Verify_version is *all* versions of the object, up to and including this one.
    # Verify_directory is *just* check the files and checksums inside that particular version directory.
    # Verify_version(@head) is the canonical way to check an entire object?
    # @param [Integer] version of object to verify
    # @return {OcflTools::OcflResults}
    def verify_version(version)
      # calls verify_directory for 1...n versions.
      count = 1 # start at the bottom
      until count > version # count to the top
        verify_directory(count)
        count += 1
      end
      @my_results
    end

    # Creates an {OcflInventory} for the given inventory.json,
    # then creates an {OcflVerify} instance of it and verifies it.
    # @param [Pathname] inventory_file fully-qualified path to a valid OCFL inventory.json.
    # @return {OcflTools::OcflResults} event results
    def verify_inventory(inventory_file = "#{@ocfl_object_root}/inventory.json")
      # Load up the object with ocfl_inventory, push it through ocfl_verify.
      @my_results ||= OcflTools::OcflResults.new
      # If inventory_file does not exist, load_inventory will throw and log an E215.
      begin
        @inventory = load_inventory(inventory_file)
        @inventory = OcflTools::OcflInventory.new.from_file(inventory_file)
        @verify    = OcflTools::OcflVerify.new(@inventory)
        @verify.check_all # creates & returns @results object from OcflVerify
      # This could be OcflTools::Errors::ValidationError now.
      rescue OcflTools::Errors::ValidationError
        # I don't think we need to throw this E210 any more.
        @my_results.error('E210', 'verify_inventory', "Unable to process inventory file #{inventory_file}.")
        return @my_results
      end
    end

  private
    # load up an inventory file and handle any errors.
    # Returns an inventory file is syntatically correct; false if otherwise.
    def load_inventory(inventory_file)
      @my_results ||= OcflTools::OcflResults.new
      OcflTools::OcflInventory.new.from_file(inventory_file)
      # The generic 'something went wrong but I don't know what'; not sure if we should keep this.
      rescue RuntimeError => e
        @my_results.error('E210', 'load_inventory', "#{e}")
        raise
      rescue OcflTools::Errors::ValidationError => e
        e.details.each do | code, messages |
          # code is a string, messages is an array.
          messages.each do | msg |
            @my_results.error(code, 'load_inventory', msg)
          end
        end
        raise # re-raise the error.
    end

    # Compares the state blocks for all versions across all inventories in the object,
    # and errors if the state block for a given version differs between inventory files.
    # NOTE: this is a private method that should only be called by #verify_manifest.
    # That way, we know that @inventory is valid and set by the time we get here.
    def verify_versions_across_inventories
      # OCFL 3.7: In the case that prior version directories include an inventory file
      # there will be multiple inventory files describing prior versions within the OCFL
      # Object. Each version block in each prior inventory file must represent the same
      # object state as the corresponding version block in the current inventory file.
      # Additionally, the values of the created, message and user keys in each version
      # block in each prior inventory file should have the same values as the
      # corresponding keys in the corresponding version block in the current inventory file.

      current_version = @inventory.version_id_list.max
      # Nothing to do if there's only 1 version. Other checks will catch if the inventory
      # in the v1 directory doesn't match the inventory in the object_root.
      return if current_version == 1

      prior_versions = @inventory.version_id_list.max - 1

      until current_version == 1
        compare_inventories(current_version)
        current_version -= 1
      end
    end

    # PRIVATE METHOD called by verify_versions_across_inventories
    # Tries to load up an inventory file from the given version directory,
    # and the inventory in the previous version directory.
    def compare_inventories(version)
      # @version_format is important here.
      if get_version_format == false
        @my_results.error('E111', 'compare_inventories', 'OCFL unable to determine version format by inspection of directories.')
        return
      end

      current_version = @version_format % version.to_i
      current_inventory = OcflTools::OcflInventory.new.from_file("#{@ocfl_object_root}/#{current_version}/inventory.json")

      previous_version_int = version - 1
      previous_version = @version_format % previous_version_int.to_i


      if !File.exist? "#{@ocfl_object_root}/#{previous_version}/inventory.json"
        @my_results.error('E111', 'compare_inventories', "OCFL unable to locate previous inventory file at #{@ocfl_object_root}/#{previous_version}/inventory.json.")
        return
      end

      previous_inventory = OcflTools::OcflInventory.new.from_file("#{@ocfl_object_root}/#{previous_version}/inventory.json")

      # Now we have two inventories, we can get their versions blocks.
      #puts current_inventory.versions
      compare_inventories_to_version(current_inventory, previous_inventory, previous_version_int)
    end

    # Given 2 inventories and a version, step down thru versions until you reach 1 and compare their states.
    def compare_inventories_to_version(current_inventory, previous_inventory, version)
      # increment thru versions, calling compare_inventories_version for each.
      until version == 0
        compare_inventories_version(current_inventory, previous_inventory, version)
        version -= 1
      end
    end

    # Get the version state from each inventory and compare.
    def compare_inventories_version(current_inventory, previous_inventory, version)
      current_version_string = @version_format % version.to_i
      current_version_block = current_inventory.versions[current_version_string]
      previous_version_block = previous_inventory.versions[current_version_string]

      # message, user, created are WARN if different. state is ERROR if different.
      if current_version_block['message'] != previous_version_block['message']
        @my_results.warn('W270', 'compare_inventories_version', "OCFL 3.7 version message mismatch between inventory files: version #{version} message block in #{current_inventory.head}/inventory.json differs from previous inventory.json.")
      end

      if current_version_block['user'] != previous_version_block['user']
        @my_results.warn('W272', 'compare_inventories_version', "OCFL 3.7 version user mismatch between inventory files: version #{version} user block in #{current_inventory.head}/inventory.json differs from previous inventory.json.")
      end

      if current_version_block['created'] != previous_version_block['created']
        @my_results.warn('W271', 'compare_inventories_version', "OCFL 3.7 version created mismatch between inventory files: version #{version} created block in #{current_inventory.head}/inventory.json differs from previous inventory.json.")
      end

      if current_version_block['state'] != previous_version_block['state']
        @my_results.error('E270', 'compare_inventories_version', "OCFL 3.7 version state mismatch between inventory files: version #{version} state block in #{current_inventory.head}/inventory.json differs from previous inventory.json.")
      end

    end

    def get_version_format
      begin
        @my_results ||= OcflTools::OcflResults.new
        @version_format ||= OcflTools::Utils::Files.get_version_format(@ocfl_object_root)
        @my_results.ok('O111', 'version_format', 'OCFL conforming first version directory found.')
        return @version_format
      rescue OcflTools::Errors::ValidationError => e
        # OcflTools::Utils::Files.get_version_format doesn't set errors, so capture them here.
        e.details.each do | code, messages |
          # code is a string, messages is an array.
          messages.each do | msg |
            @my_results.error(code, 'load_inventory', msg)
          end
        end
        # Add on another error explaining how we got here.
        @my_results.error('E111', 'version_format', 'OCFL unable to determine version format by inspection of directories.')
        @my_results.warn('W111', 'version_format', "Attempting to process using default value: #{OcflTools.config.version_format}")
        @version_format = OcflTools.config.version_format
        return false
      end
    end

  end
end
