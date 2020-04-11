# frozen_string_literal: true

module OcflTools
  module Utils
    module Files
      # Given a directory, return a list of all files (no dirs or special files) found beneath it.
      # @param [Pathname] directory full file path to directory to search.
      # @return [Array] of files found in all sub-directories of given path.
      def self.get_dir_files(directory)
        # Don't crash out if the requested dir doesn't exist, just state the obvious: there are no files in it.
        return [] unless Dir.exist?(directory) == true

        Dir.chdir(directory)
        directory_files = []
        Dir.glob('**/*').select do |file|
          directory_files << file if File.file? file
        end
        directory_files
      end

      # Given an object root and a version, return the files on disk in the appropriate content dir.
      # @return [Array] of fully-qualified filepaths for this version of the {OcflTools::Ocflinventory}
      def self.get_version_dir_files(object_root_dir, version)
        version_format = OcflTools::Utils::Files.get_version_format(object_root_dir)
        # Int to version format
        version_name = version_format % version.to_i
        # Get latest inventory file
        inventory = OcflTools::Utils::Files.get_latest_inventory(object_root_dir)
        # Get contentDirectory value from inventory (or use default value)
        contentDirectory = OcflTools::Utils::Inventory.get_contentDirectory(inventory)
        # Now bring it together and get the goods.
        my_files = OcflTools::Utils::Files.get_dir_files("#{object_root_dir}/#{version_name}/#{contentDirectory}")
        # And expand it to a full file path
        OcflTools::Utils::Files.expand_filepaths(my_files, "#{object_root_dir}/#{version_name}/#{contentDirectory}")
      end

      # Given an object root and two versions, get the files on disk for that range of versions (inclusive)
      def self.get_versions_dir_files(object_root_dir, version1, version2)
        top_ver = [version1, version2].max
        bot_ver = [version1, version2].min
        all_files = []
        count = bot_ver       # start at the bottom
        until count > top_ver # count to the top
          all_files << OcflTools::Utils::Files.get_version_dir_files(object_root_dir, count)
          count += 1
        end
        raise 'No files found in version directories!' if all_files.empty?

        all_files.flatten!
      end

      # Given an object root directory, deduce and return the version directories by inspecting disk.
      def self.get_version_directories(object_root_dir)
        unless Dir.exist?(object_root_dir) == true
          # This is a client error.
          raise OcflTools::Errors::RequestedDirectoryNotFound, "#{object_root_dir} does not exist!"
        end

        object_root_dirs = []
        version_directories = []
        Dir.chdir(object_root_dir)
        Dir.glob('*').select do |file|
          object_root_dirs << file if File.directory? file
        end
        if object_root_dirs.empty?
          # This is a validation error.
          raise OcflTools::Errors::ValidationError, details: { "E100" => ["#{object_root_dir} is empty!"] }
        end

        # Needs to call get version_format method here.
        object_root_dirs.each do |i|
          if i =~ /[^"{OcflTools::Utils.Files.get_version_format(object_root_dir)}"$]/
            version_directories << i
          end
        end
        # This is a validation error; we expect to find matching version directories.
        if version_directories.empty?
          raise OcflTools::Errors::ValidationError, details: { "E013" => ["#{object_root_dir} must contain at least one identifiable version directory."] }
        end
        version_directories.sort! # sort it, to be nice.
      end

      # Given an object_root_directory, deduce the format used to describe version directories.
      def self.get_version_format(object_root_dir)
        unless Dir.exist?(object_root_dir) == true
          # This is a client error.
          raise OcflTools::Errors::RequestedDirectoryNotFound, "#{object_root_dir} does not exist!"
        end

        # Get all directories starting with 'v', sort them.
        # Take the top of the sort. Count the number of 0s found.
        # Raises errors if it can't find an appropriate version 1 directory.
        version_dirs = []
        Dir.chdir(object_root_dir)
        Dir.glob('v*').select do |file|
          version_dirs << file if File.directory? file
        end

        # Raise E008 if there are no identifiable version directories.
        if version_dirs.empty?
          raise OcflTools::Errors::ValidationError, details: { "E008" => ["No version directories found in #{object_root_dir}."] }
        end

        version_dirs.sort!
        # if there's a verson_dirs that's just 'v', throw it out! It's hot garbage edge case we'll deal with later.
        version_dirs.delete('v') if version_dirs.include? 'v'

        first_version = version_dirs[0] # the first element should be the first version directory.
        first_version.slice!(0, 1) # cut the leading 'v' from the string.
        if first_version.length == 1 # A length of 1 for the first version implies 'v1'
          unless first_version.to_i == 1
            # This is a validation error; there must be a v1 directory.
            # E015 "OCFL 3.5.3 Expected version sequence not found. Expected version #{count}, found version #{my_versions[count]}."
            raise OcflTools::Errors::ValidationError, details: { "E015" => ["Expected version 1 not found. Found version #{first_version.to_i} instead."] }
          end

          version_format = 'v%d'
        else
          # Make sure this is Integer 1.
          unless first_version.to_i == 1
            raise OcflTools::Errors::ValidationError, details: { "E015" => ["Expected version 1 not found. Found version #{first_version.to_i} instead."] }
          end

          version_format = "v%0#{first_version.length}d"
        end
        version_format
      end

      # Given a [Hash] of digests and [ filepaths ], flip & expand to unique Filepath => digest.
      def self.invert_and_expand(digest_hash)
        raise 'This only works on Hashes, buck-o' unless digest_hash.is_a?(Hash)

        working_hash = OcflTools::Utils.deep_copy(digest_hash)
        return_hash = {}
        working_hash.each do |key, value|
          value.each do |v|
            return_hash[v] = key
          end
        end
        return_hash
      end

      # Given a hash of digest => [ Filepaths ], invert and expand, then prepend a string to all filepaths.
      def self.invert_and_expand_and_prepend(digest_hash, prepend_string)
        raise 'This only works on Hashes, buck-o' unless digest_hash.is_a?(Hash)

        return_hash = {}
        filepath_hash = OcflTools::Utils::Files.invert_and_expand(digest_hash)
        filepath_hash.each do |file, digest|
          filepaths = OcflTools::Utils::Files.expand_filepaths(file, prepend_string)
          return_hash[filepaths[0]] = digest
        end
        return_hash
      end

      # Given an array of files and a digestAlgorithm, create digests and return results in a [Hash]
      def self.create_digests(files, digestAlgorithm)
        my_digests = {}
        array = Array(files) # make sure it's an array, so we can handle single files as well.
        array.each do |file|
          my_digests[file] = OcflTools::Utils.generate_file_digest(file, digestAlgorithm)
        end
        my_digests
      end

      # Given an array of (relative to object root) filepaths, expand to fully-resovable filesystem paths.
      # If the object_root_dir is already at the front of the filepath, don't add it again.
      def self.expand_filepaths(files, object_root_dir)
        array = Array(files) # make sure whatever we have is an array, so we can handle single files too.
        my_full_filepaths = []
        array.each do |f|
          #  /^#{object_root_dir}/ matches on what we want.
          unless f =~ /^#{object_root_dir}/
            my_full_filepaths << "#{object_root_dir}/#{f}"
          end
        end
        my_full_filepaths
      end

      # Given an object root dir, get the most recent inventory file.
      def self.get_latest_inventory(object_root_dir)
        # Tries most recent version dir first, then object root, then other version dirs.
        # g_v_d returns a sorted array already. Reverse it, so we start with highest version.
        my_versions = OcflTools::Utils::Files.get_version_directories(object_root_dir).reverse
        case
        # Return the inventory file in the highest version dir, if it exists.
        when File.exist?("#{object_root_dir}/#{my_versions[0]}/inventory.json")
          return "#{object_root_dir}/#{my_versions[0]}/inventory.json"
        # Otherwise, return the inventory file in the root, if it exists.
        when File.exist?("#{object_root_dir}/inventory.json")
          return "#{object_root_dir}/inventory.json"
        else
          # We don't have a highest-version inventory, and we don't have a root inventory.
          # This is a problem! But there might be an inventory file in a non-highest-version dir.
          # Quit out here if there was only 1 version directory (We've already checked this)
          unless my_versions.size > 1
            # This is a validation error; no inventory files found.
            raise OcflTools::Errors::ValidationError, details: { "E215" => ["OCFL 3.1 Expected inventory file not found in #{object_root_dir} or discovered version directories."] }
          end

          my_versions.delete_at(0) # drop the first element (we've already checked it).
          my_versions.each do |v|
            # Return the highest version inventory file we find.
            # Note, this is technically a non-compliant object root, but we
            # want to return a result if we have one - we might be attempting object
            # recovery and something is better than nothing.
            if File.exist?("#{object_root_dir}/#{v}/inventory.json")
              return "#{object_root_dir}/#{v}/inventory.json"
            end
          end
          # If we get here, no inventory file found in any version dirs or the object root.
          # This is a validation error.
          raise OcflTools::Errors::ValidationError, details: { "E215" => ["OCFL 3.1 Expected inventory file not found in #{object_root_dir} or discovered version directories."] }
        end
      end
    end
  end
end
