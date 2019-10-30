module OcflTools
  module Utils
    module Files

      # Given a directory, return a list of all files (no dirs or special files) found beneath it.
      # @param [Pathname] directory full file path to directory to search.
      # @return [Array] of files found in all sub-directories of given path.
      def self.get_dir_files(directory)
        raise "Directory does not exist!" unless Dir.exist?(directory) == true
        Dir.chdir(directory)
        directory_files = []
        Dir.glob('**/*').select do |file|
           if File.file? file
             directory_files << file
           end
        end
        directory_files
      end

      # Given an object root and a version, return the files on disk in the appropriate content dir.
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
        top_ver = [ version1, version2 ].max
        bot_ver = [ version1, version2 ].min
        all_files = []
        count = bot_ver       # start at the bottom
        until count > top_ver # count to the top
          all_files << OcflTools::Utils::Files.get_version_dir_files(object_root_dir, count)
          count += 1
        end
        raise "No files found in version directories!" unless all_files.size > 0
        all_files.flatten!
      end

      # Given an object root directory, deduce and return the version directories by inspecting disk.
      def self.get_version_directories(object_root_dir)
        raise "Directory does not exist!" unless Dir.exist?(object_root_dir) == true
        object_root_dirs = []
        version_directories = []
        Dir.chdir(object_root_dir)
        Dir.glob('*').select do |file|
           if File.directory? file
             object_root_dirs << file
           end
        end
        raise "No directories found in #{object_root_dir}!" unless object_root_dirs.size > 0
        # Needs to call get version_format method here.
        object_root_dirs.each  do |i|
          if i =~ /[^"{OcflTools::Utils.Files.get_version_format(object_root_dir)}"$]/
            version_directories << i
          end
        end
        raise "No version directories found!" unless version_directories.size > 0
        version_directories.sort! # sort it, to be nice.
      end

      # Given an object_root_directory, deduce the format used to describe version directories.
      def self.get_version_format(object_root_dir)
        raise "Directory does not exist!" unless Dir.exist?(object_root_dir) == true
        # Get all directories starting with 'v', sort them.
        # Take the top of the sort. Count the number of 0s found.
        # Raises errors if it can't find an appropriate version 1 directory.
        version_dirs = []
        Dir.chdir(object_root_dir)
        Dir.glob('v*').select do |file|
           if File.directory? file
             version_dirs << file
           end
        end
        version_dirs.sort!
        # if there's a verson_dirs that's just 'v', throw it out! It's hot garbage edge case we'll deal with later.
        if version_dirs.include? 'v'
          version_dirs.delete('v')
        end

        first_version = version_dirs[0]   # the first element should be the first version directory.
        first_version.slice!(0,1)         # cut the leading 'v' from the string.
        case
        when first_version.length == 1    # A length of 1 for the first version implies 'v1'
            raise "#{object_root_dir}/#{first_version} is not the first version directory!" unless first_version.to_i == 1
            version_format = "v%d"
          else
            # Make sure this is Integer 1.
            raise "#{object_root_dir}/#{first_version} is not the first version directory!" unless first_version.to_i == 1
            version_format = "v%0#{first_version.length}d"
        end
        version_format
      end

      # Given a [Hash] of digests and [ filepaths ], flip & expand to unique Filepath => digest.
      def self.invert_and_expand(digest_hash)
        raise "This only works on Hashes, buck-o" unless digest_hash.is_a?(Hash)
        working_hash = OcflTools::Utils.deep_copy(digest_hash)
        return_hash = {}
        working_hash.each do | key, value |
          value.each do | v |
            return_hash[v] = key
          end
        end
        return_hash
      end

      # Given an array of files and a digestAlgorithm, create digests and return results in a [Hash]
      def self.create_digests(files, digestAlgorithm)
        my_digests = {}
        array = Array(files) # make sure it's an array, so we can handle single files as well.
        array.each do | file |
          my_digests[file] = OcflObject::Utils.generate_file_digest(file, digestAlgorithm)
        end
        my_digests
      end

      # Given an array of (relative to object root) filepaths, expand to fully-resovable filesystem paths.
      # If the object_root_dir is already at the front of the filepath, don't add it again.
      def self.expand_filepaths(files, object_root_dir)
        array = Array(files) # make sure whatever we have is an array, so we can handle single files too.
        my_full_filepaths = []
        array.each do | f |
        #  /^#{object_root_dir}/ matches on what we want.
          my_full_filepaths << "#{object_root_dir}/#{f}" unless f =~ /^#{object_root_dir}/
        end
        my_full_filepaths
      end

      # Given an object root dir, get the most recent inventory file.
      def self.get_latest_inventory(object_root_dir)
        # Tries most recent version dir first, then object root, then other version dirs.
        # g_v_d returns a sorted array already. Reverse it, so we start with highest version.
        my_versions = OcflTools::Utils::Files.get_version_directories(object_root_dir).reverse
        case
          when File.exist?("#{object_root_dir}/#{my_versions[0]}/inventory.json")
            return "#{object_root_dir}/#{my_versions[0]}/inventory.json"
          when File.exist?("#{object_root_dir}/inventory.json")
            return "#{object_root_dir}/inventory.json"
          else
            # Quit out here if there was only 1 version directory
            raise "No inventory file found in #{object_root_dir}!" unless my_versions.size > 1
            my_versions.delete_at(0) # drop the first element.
            my_versions.each do | v |
              if File.exist?("#{object_root_dir}/#{v}/inventory.json")
                return "#{object_root_dir}/#{v}/inventory.json"
              end
            end
            # If we get here, no inventory file found!
            raise "No inventory file found in #{object_root_dir}!"
        end
      end


    end
  end
end
