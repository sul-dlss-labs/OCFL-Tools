# frozen_string_literal: true

module OcflTools
  # Class that represents the data structures used by an OCFL inventory file.
  class OcflObject
    # @return [Hash] manifest block of the OCFL object.
    attr_accessor :manifest

    # @return [Hash] versions block of the OCFL object.
    attr_accessor :versions

    # @return [Hash] fixity block of the OCFL object.
    attr_accessor :fixity

    # @return [String] id the unique identifer of the OCFL object, as defined by the local repository system.
    attr_accessor :id

    # @return [String] algorithm used by the OCFL object to generate digests for file manifests and versions.
    attr_accessor :digestAlgorithm

    # @return [String] the most recent version of the OCFL object, expressed as a string that conforms to the format defined in version_format.
    attr_accessor :head

    # @return [String] the version of the OCFL spec to which this object conforms, expressed as a URL, as required by the OCFL specification.
    attr_accessor :type

    # @return [String] the name of the directory, inside each version directory, that the OCFL object should use as the base directory for files.
    attr_accessor :contentDirectory

    def initialize
      # Parameters that must be serialized into JSON
      @id               = nil
      @head             = nil
      @type             = nil # OcflTools.config.content_type
      @digestAlgorithm  = OcflTools.config.digest_algorithm # sha512 is recommended, Stanford uses sha256.
      @contentDirectory = OcflTools.config.content_directory # default is 'content', Stanford uses 'data'
      @manifest         = {}
      @versions         = {} # A hash of Version hashes.
      @fixity           = {} # Optional. Same format as Manifest.
    end

    # sets @head in current string format, when given integer.
    # @param [Integer] version to set head to.
    # @return {@head} value of most recent version.
    def set_head_from_version(version)
      @head = OcflTools::Utils.version_int_to_string(version)
    end

    # sets the message field for a given version.
    # @param [Integer] version of OCFL object to set message for.
    # @param [String] message to set for given version.
    # @note will raise an exception if you attempt to query a non-existent version.
    def set_version_message(version, message)
      unless @versions.key?(OcflTools::Utils.version_int_to_string(version))
        raise OcflTools::Errors::RequestedKeyNotFound, "Version #{version} does not yet exist!"
      end

      @versions[OcflTools::Utils.version_int_to_string(version)]['message'] = message
    end

    # returns the message field for a given version.
    # @param [Integer] version of OCFL object to get the message for.
    # @return [String] message set for the given version, if any.
    # @note will raise an exception if you attempt to query a non-existent version.
    def get_version_message(version)
      unless @versions.key?(OcflTools::Utils.version_int_to_string(version))
        raise OcflTools::Errors::RequestedKeyNotFound, "Version #{version} does not yet exist!"
      end

      @versions[OcflTools::Utils.version_int_to_string(version)]['message']
    end

    # sets the created field for a given version.
    # @param [Integer] version of OCFL object to set value for.
    # @param [String] created value to set for given version.
    # @note will raise an exception if you attempt to query a non-existent version.
    def set_version_created(version, created)
      unless @versions.key?(OcflTools::Utils.version_int_to_string(version))
        raise OcflTools::Errors::RequestedKeyNotFound, "Version #{version} does not yet exist!"
      end

      @versions[OcflTools::Utils.version_int_to_string(version)]['created'] = created
    end

    # returns the created field for a given version.
    # @param [Integer] version of OCFL object to get value for.
    # @return [String] created value set for the given version, if any.
    # @note will raise an exception if you attempt to query a non-existent version.
    def get_version_created(version)
      unless @versions.key?(OcflTools::Utils.version_int_to_string(version))
        raise OcflTools::Errors::RequestedKeyNotFound, "Version #{version} does not yet exist!"
      end

      @versions[OcflTools::Utils.version_int_to_string(version)]['created']
    end

    # Sets the user Hash for a given version. Expects a complete User hash (with sub-keys of name & address).
    # @param [Integer] version of OCFL object to set the user block for.
    # @param [Hash] user block to set for this version. Must be a hash with two keys 'name' and 'address'.
    # @note will raise an exception if you attempt to query a nonexistent version.
    def set_version_user(version, user)
      unless @versions.key?(OcflTools::Utils.version_int_to_string(version))
        raise OcflTools::Errors::RequestedKeyNotFound, "Version #{version} does not yet exist!"
      end

      @versions[OcflTools::Utils.version_int_to_string(version)]['user'] = user
    end

    # Gets the user Hash for a given version.
    # @ param [Integer] version of OCFL object to retrieve user block for.
    # @return [Hash] user block for this version, a hash consisting of two keys, 'name' and 'address'.
    # @note will raise an exception if you attempt to query a nonexistent version.
    def get_version_user(version)
      unless @versions.key?(OcflTools::Utils.version_int_to_string(version))
        raise OcflTools::Errors::RequestedKeyNotFound, "Version #{version} does not yet exist!"
      end

      @versions[OcflTools::Utils.version_int_to_string(version)]['user']
    end

    # Gets an array of integers comprising all versions of this OCFL object. It is not guaranteed to be in numeric order.
    # @return [Array{Integer}] versions that exist in the object.
    def version_id_list
      my_versions = []
      @versions.keys.each do |key|
        my_versions << OcflTools::Utils.version_string_to_int(key)
      end
      my_versions
    end

    # Gets the state block of a given version, comprising of digest keys and an array of filenames associated with those digests.
    # @param [Integer] version of OCFL object to retreive version state block of.
    # @return [Hash] of digests and array of pathnames associated with this version.
    # @note Creates new version and copies previous versions' state block over if requested version does not yet exist.
    def get_state(version)
      my_version = get_version(version)
      my_version['state']
    end

    # Sets the state block for a given version when provided with a hash of digest keys and an array of associated filenames.
    # @param [Integer] version of object to set state for.
    # @param [Hash] hash of digests (keys) and an array of pathnames (values) associated with those digests.
    # @note It is prefered to update version state via add/update/delete/copy/move file operations.
    def set_state(version, hash)
      # SAN Check needed here to make sure passed Hash has all expected keys.
      @versions[OcflTools::Utils.version_int_to_string(version)]['state'] = hash
    end

    # Gets a hash of all logical files and their associated physical filepaths with the given version.
    # @param [Integer] version from which to generate file list.
    # @return [Hash] of files, with logical file as key, physical location within object dir as value.
    def get_files(version)
      my_state = get_state(version)
      my_files = {}

      my_state.each do |digest, filepaths| # filepaths is [Array]
        filepaths.each do |logical_filepath|
          # look up this file via digest in @manifest.
          physical_filepath = @manifest[digest]
          # physical_filepath is an [Array] of files, but they're all the same so only need 1.
          my_files[logical_filepath] = physical_filepath[0]
        end
      end
      my_files
    end

    # Gets all files for the current (highest) version of the OCFL object. Represents the state of the object at 'head',
    # with the logical files that consist of the most recent version and their physical representations on disk, relative
    # to the object's root directory.
    # @return [Hash] of files from most recent version, with logical file as key, associated physical filepath as value.
    def get_current_files
      get_files(OcflTools::Utils.version_string_to_int(@head))
    end

    # Adds a file to a version.
    # @param [Pathname] file is the logical filename within the object.
    # @param [String] digest of filename, presumably computed with the {digestAlgorithm} for the object.
    # @param [Integer] version to add file to.
    # @return [Hash] state block reflecting the version after the changes.
    # @note will raise an error if an attempt is made to add a file to a prior (non-head) version. Will also raise an error if the requested file already exists in this version with a different digest: use {update_file} instead.
    def add_file(file, digest, version)
      # We use get_state here instead of asking @versions directly
      # because get_state will create version hash if it doesn't already exist.
      my_state = get_state(version)

      unless version == version_id_list.max
        raise OcflTools::Errors::CannotEditPreviousVersion, "Can't edit prior versions! Only version #{version_id_list.max} can be modified now."
      end

      # if the key is not in the manifest, assume that we meant to add it.
      update_manifest(file, digest, version) unless @manifest.key?(digest)

      if my_state.key?(digest)
        # file's already in this version. Add file to existing digest.
        my_files = my_state[digest]
        my_files << file
        unique_files = my_files.uniq # Just in case we're trying to add the same thing multiple times.
        # Need to actually add this to @versions!
        @versions[OcflTools::Utils.version_int_to_string(version)]['state'][digest] = unique_files
        # Prove we actually added to state
        return get_state(version)
      end

      # Check to make sure the file isn't already in this state with a different digest!
      # If so; fail. We don't do implicit / soft adds. You want that, be explict: do an update_file instead.
      existing_files = get_files(version)
      if existing_files.key?(file)
        raise OcflTools::Errors::FileDigestMismatch, "#{file} already exists with different digest in version #{version}. Consider update instead."
      end

      # if it's not in State already, just add it.
      @versions[OcflTools::Utils.version_int_to_string(version)]['state'][digest] = [file]

      get_state(version)
    end

    # Updates an existing file with a new bitstream and digest.
    # @param [String] file filepath to update.
    # @param [String] digest of updated file.
    # @param [Integer] version of object to update.
    # @note this method explicitly deletes the prior file if found, and re-creates it with a new digest via the {add_file} method.
    def update_file(file, digest, version)
      # Same filename, different digest, update manifest.
      # Do a Delete, then an Add.
      existing_files = get_files(version)

      delete_file(file, version) if existing_files.key?(file)
      add_file(file, digest, version)
    end

    # Add a file and digest to the manifest at the given version.
    # @param [Pathname] file filepath to add to the manifest.
    # @param [String] digest of file being added to the manifest.
    # @param [Integer] version version of the OCFL object that the file is being added to.
    # @note internal API.
    def update_manifest(file, digest, version)
      # We only ever add to the manifest.
      physical_filepath = "#{OcflTools::Utils.version_int_to_string(version)}/#{@contentDirectory}/#{file}"

      if @manifest.key?(digest)
        # This bitstream is already in the manifest.
        # We need to append the new filepath to the existing array.
        @manifest[digest] = (@manifest[digest] << physical_filepath)
        return @manifest[digest]
      end
      @manifest[digest] = [physical_filepath] # otherwise, add our first entry to the array.
      @manifest[digest]
    end

    # Given a digest, fixityAlgo and fixityDigest, add to fixity block.
    # @param [String] digest value from Manifest for the file we are adding fixity info for.
    # @param [String] fixityAlgorithm a valid fixity algorithm for this site (see Config.fixity_algorithms).
    # @param [String] fixityDigest the digest value of the file, using the provided fixityAlgorithm.
    # @return [Hash] fixity block for the object.
    def update_fixity(digest, fixityAlgorithm, fixityDigest)
      # Does Digest exist in @manifest? Fail if not.
      # Doe fixityAlgorithm exist as a key in @fixity? Add if not.
      unless @manifest.key?(digest) == true
        raise OcflTools::Errors::RequestedKeyNotFound, "Unable to find digest #{digest} in manifest!"
      end

      filepaths = @manifest[digest]

      # Construct the nested hash, if necessary.
      @fixity[fixityAlgorithm] = {} if @fixity.key?(fixityAlgorithm) != true

      if @fixity[fixityAlgorithm].key?(fixityDigest) != true
        @fixity[fixityAlgorithm][fixityDigest] = []
      end

      # Append the filepath to the appropriate fixityDigest, if it's not already there.
      filepaths.each do |filepath|
        if @fixity[fixityAlgorithm][fixityDigest].include?(filepath)
          next # don't add it if the filepath is already in the array.
        end

        @fixity[fixityAlgorithm][fixityDigest] = (@fixity[fixityAlgorithm][fixityDigest] << filepath)
      end
      @fixity
    end

    # Given a filepath, deletes that file from the given version. If multiple copies of the same file
    # (as identified by a common digest) exist in the version, only the requested filepath is removed.
    # @param [Pathname] file logical path of file to be deleted.
    # @param [Integer] version version of object to delete file from.
    # @return [Hash] state of version after delete has completed.
    def delete_file(file, version)
      # remove filename, may remove digest if that was last file associated with that digest.
      my_state = get_state(version) # Creates version & copies state from prior version if doesn't exist.

      unless version == version_id_list.max
        raise OcflTools::Errors::CannotEditPreviousVersion, "Can't edit prior versions! Only version #{version_id_list.max} can be modified now."
      end

      my_digest = get_digest(file, version)
      # we know it's here b/c self.get_digest would have crapped out if not.
      my_array = my_state[my_digest]  # Get [Array] of files that have this digest in this version.
      my_array.delete(file)           # Delete the array value that matches file.
      if !my_array.empty?
        # update the array with (fewer) items.
        my_state[my_digest] = my_array
      else
        # delete the key.
        my_state.delete(my_digest)
      end
      # put results back into State.
      set_state(version, my_state)
    end

    # Copies a file within the same version. If the destination file already exists with a different digest,
    # it is overwritten with the digest of the source file.
    # @param [Filepath] source_file filepath of source file.
    # @param [Filepath] destination_file filepath of destination file.
    # @param [Integer] version version of OCFL object.
    # @return [Hash] state block of version after file copy has completed.
    # @note Raises an error if source_file does not exist in this version.
    def copy_file(source_file, destination_file, version)
      # add new filename to existing digest in current state.
      # If destination file already exists, overwrite it.
      existing_files = get_files(version)

      if existing_files.key?(destination_file)
        delete_file(destination_file, version)
      end
      # should NOT call add_file, as add_file updates the manifest.
      # Should instead JUST update current state with new filepath.
      digest = get_digest(source_file, version) # errors out if source_file not found in current state

      my_state = get_state(version)
      my_files = my_state[digest]
      my_files << destination_file
      unique_files = my_files.uniq # Just in case we're trying to add the same thing multiple times.
      # Need to actually add this to @versions!
      @versions[OcflTools::Utils.version_int_to_string(version)]['state'][digest] = unique_files
      # Prove we actually added to state
      get_state(version)
      # self.add_file(destination_file, self.get_digest(source_file, version), version)
    end

    # Moves (renames) a file from one location to another within the same version.
    # @param [Pathname] old_file filepath to move.
    # @param [Pathname] new_file new filepath.
    # @return [Hash] state block of version after file copy has completed.
    # @note This is functionally a {copy_file} followed by a {delete_file}. Will raise an error if the source file does not exist in this version.
    def move_file(old_file, new_file, version)
      # re-name; functionally a copy and delete.
      copy_file(old_file, new_file, version)
      delete_file(old_file, version)
    end

    # When given a file path and version, return the associated digest from version state.
    # @param [Pathname] file filepath of file to return digest for.
    # @param [Integer] version version of OCFL object to search for the requested file.
    # @return [String] digest of requested file.
    # @note Will raise an exception if requested filepath is not in given version.
    def get_digest(file, version)
      # Make a hash with each individual file as a key, with the appropriate digest as value.
      inverted = get_state(version).invert
      my_files = {}
      inverted.each do |files, digest|
        files.each do |i_file|
          my_files[i_file] = digest
        end
      end
      # Now see if the requested file is actually here.
      unless my_files.key?(file)
        raise OcflTools::Errors::FileMissingFromVersionState, "Get_digest can't find requested file #{file} in version #{version}."
      end

      my_files[file]
    end

    # Gets the existing version hash for the requested version, or else creates
    # and populates a new, empty version hash.
    # @param [Integer] version
    # @return [Hash] version block, if it exists, or creates new with prior version state in it.
    # @note If a (n-1) version exists in the object, and the requested version does not yet exist, this method will copy that version's state block into the new version.
    def get_version(version)
      unless version > 0
        raise OcflTools::Errors::NonCompliantValue, "Requested value '#{version}' for object version does not comply with specification."
      end
      if @versions.key?(OcflTools::Utils.version_int_to_string(version))
        @versions[OcflTools::Utils.version_int_to_string(version)]
      else
        # Otherwise, construct a new Version [Hash] and return that.
        @versions[OcflTools::Utils.version_int_to_string(version)] = create_version_hash

        # If version -1 exists, copy prior version state over.
        if @versions.key?(OcflTools::Utils.version_int_to_string(version - 1))
          @versions[OcflTools::Utils.version_int_to_string(version)]['state'] = OcflTools::Utils.deep_copy(@versions[OcflTools::Utils.version_int_to_string(version - 1)]['state'])
        end

        @versions[OcflTools::Utils.version_int_to_string(version)]
      end
    end

    # Returns a version hash with the correct keys created, ready for content to be added.
    # @return [Hash] empty version Hash with 'created', 'message', 'user' and 'state' keys.
    # @note internal API
    def create_version_hash
      new_version = {}
      new_version['created'] = ''
      new_version['message'] = ''
      new_version['user'] = {}
      # user is #name, # address.
      new_version['user']['name'] = ''
      new_version['user']['address'] = ''
      new_version['state'] = {}
      new_version
    end

    # When given a correctly-constructed hash, create a new OCFL version. See {create_version_hash} for more context.
    # @param [Integer] version create a new OCFL version block with this version number.
    # @param [Hash] hash use this hash for the content of the new OCFL version block.
    def set_version(version, hash)
      # SAN Check to make sure passed Hash has all expected keys.
      e216_errors = []
      %w[created message user state].each do |key|
        if hash.key?(key) == false
          e216_errors << "version #{version} hash block is missing required #{key} key."
        end
      end
      if e216_errors.size > 0
        raise OcflTools::Errors::ValidationError, details: { "E216" => e216_errors }
      end
      @versions[OcflTools::Utils.version_int_to_string(version)] = hash
    end
  end
end
