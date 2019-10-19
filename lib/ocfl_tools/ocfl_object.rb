module OcflTools
  class OcflObject
    attr_accessor :manifest, :versions, :fixity, :id, :digestAlgorithm, :head, :type, :contentDirectory

    def initialize
      # Parameters that must be serialized into JSON
      @id               = nil
      @head             = nil
      @type             = 'https://ocfl.io/1.0/spec/#inventory'
      @digestAlgorithm  = 'sha256' # sha512 is recommended, Stanford uses sha256.
      @contentDirectory = 'data' # default is 'content', Stanford uses 'data'
      @manifest         = Hash.new
      @versions         = Hash.new # A hash of Version hashes.
      @fixity           = Hash.new # Optional. Same format as Manifest.
    end

    def set_head_from_version(version)
      # @param [Integer] current version.
      # sets @head in current format.
      @head = OcflTools::Utils.version_int_to_string(version)
    end

    def set_version_message(version, message)
      @versions[OcflTools::Utils.version_int_to_string(version)]['message'] = message
    end

    def get_version_message(version)
      @versions[OcflTools::Utils.version_int_to_string(version)]['message']
    end

    def set_version_user(version, user)
      @versions[OcflTools::Utils.version_int_to_string(version)]['user'] = user
    end

    def get_version_user(version)
      @versions[OcflTools::Utils.version_int_to_string(version)]['user']
    end

    # TODO; get and set version stuff?
    def version_id_list
      # @return [Array] of [Integer] versions.
      my_versions = []
      @versions.keys.each do | key |
        my_versions << OcflTools::Utils.version_string_to_int(key)
      end
      my_versions
    end

    def get_state(version)
      # @param [Integer] version to get state block of.
      # @return [Hash] state block.
      version_name = OcflTools::Utils.version_int_to_string(version)
      raise "Version #{version_name} does not exist in OCFL object!" unless @versions.has_key?(version_name)
      @versions[version_name]['state']
    end

    def get_files(version)
      # @param [Integer] version from which to generate file list.
      # @return [Hash] of files, with logical file as key, physical location within object dir as value.
      my_state = self.get_state(version)
      my_files = Hash.new

      my_state.each do | digest, filepaths | # filepaths is [Array]
        filepaths.each do | logical_filepath |
          # look up this file via digest in @manifest.
          physical_filepath = @manifest[digest]
          # physical_filepath is an [Array] of files, but they're all the same so only need 1.
          my_files[logical_filepath] = physical_filepath[0]
        end
      end
      my_files
    end

    def get_current_files
      # @return [Hash] of files from most recent version, with logical file as key,
      # physical location within object dir as value.
      self.get_files(OcflTools::Utils.version_string_to_int(@head))
    end

    def add_file(file, digest, version)
      # new digest, new filename, update manifest.
    end

    def update_file(file, digest, version)
      # Same filename, different digest, update manifest.
      # EXPECT file to already exist, or fail.
    end

    def delete_file(file, digest, version)
      # remove filename, may remove digest if that was last instance.
      # EXPECT file to already exist, or fail.
    end

    def copy_file(source_file, destination_file, version)
      # add new filename to existing digest.
    end

    def move_file(old_file, new_file, version)
      # re-name; functionally a copy and delete.
      # get old_file digest.
      self.copy_file(old_file, new_file, version)
      self.delete_file(old_file, self.get_digest(old_file, version))
    end

    def get_digest(file, version)
      # could be moved to ocfl_object?
    end



  end
end
