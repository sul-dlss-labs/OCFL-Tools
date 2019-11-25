# frozen_string_literal: true

module OcflTools
  # Given an inventory, show changes from previous versions.
  # OcflDelta takes in an OCFL Inventory object and creates a delta hash containing
  # the actions performed to assemble the requested version.
  class OcflDelta
    attr_reader :delta

    def initialize(ocfl_object)
      # Duck sanity check.
      ['@id', '@head', '@manifest', '@versions', '@fixity'].each do |var|
        unless ocfl_object.instance_variable_defined?(var)
          raise "Object #{ocfl_object} does not have instance var #{var} defined"
        end
      end

      %w[get_state version_id_list get_digest].each do |mthd|
        unless ocfl_object.respond_to?(mthd)
          raise "Object #{ocfl_object} does not respond to #{mthd}"
        end
      end

      @ocfl_object = ocfl_object
      @delta = {}
      # We need to get version format, for final report-out. Assume that the ocfl_object versions are
      # formatted correctly (starting with a 'v'). We can't trust the site config setting
      # for this, as there's no guarantee the inventory we are reading in was created at this site.
      first_version = @ocfl_object.versions.keys.min # should get us 'v0001' or 'v1'
      sliced_version = first_version.split('v')[1] # cut the leading 'v' from the string.
      if sliced_version.length == 1 # A length of 1 for the first version implies 'v1'
        @version_format = 'v%d'
      else
        @version_format = "v%0#{sliced_version.length}d"
      end
    end

    # Generates a complete delta hash for all versions of this object.
    def all
      @ocfl_object.version_id_list.each do |version|
        get_version_delta(version)
      end
      @delta
    end

    # Given a version, get the delta from the previous version.
    # @param [Integer] version of object to get deltas for.
    # @return [Hash] of actions applied to previous version to create current version.
    def previous(version)
      # San check, does version exist in object?
      if version == 1
        get_first_version_delta
      else
        # verify version exists, then...
        unless @ocfl_object.version_id_list.include?(version)
          raise "Version #{version} not found in #{@ocfl_object}!"
        end
        get_version_delta(version)
      end
    end

    private

    def get_version_delta(version)

      unless version > 1
        return get_first_version_delta
      end

      current_digests = @ocfl_object.get_state(version)
      current_files = OcflTools::Utils::Files.invert_and_expand(current_digests)

      previous_digests = @ocfl_object.get_state((version - 1))
      previous_files = OcflTools::Utils::Files.invert_and_expand(previous_digests)

      missing_digests = {}
      missing_files = {}

      new_digests = {}
      new_files = {}

      unchanged_digests = {}  # digests may not have changed, but filepaths can!
      unchanged_files = {}    # filepaths may not change, but digests can!

      version_string = @version_format % version.to_i
      @delta[version_string] = {}
      @delta[version_string].clear # Always clear out the existing version delta.
      actions = OcflTools::OcflActions.new

      temp_digests = previous_digests.keys - current_digests.keys
      unless temp_digests.empty?
        temp_digests.each do |digest|
          missing_digests[digest] = previous_digests[digest]
        end
      end

      temp_files = previous_files.keys - current_files.keys
      unless temp_files.empty?
        temp_files.each do |file|
          missing_files[file] = previous_files[file]
        end
      end

      temp_digests = current_digests.keys - previous_digests.keys
      unless temp_digests.empty?

        temp_digests.each do |digest|
          new_digests[digest] = current_digests[digest]
        end
      end

      temp_files = current_files.keys - previous_files.keys
      unless temp_files.empty?

        temp_files.each do |file|
          new_files[file] = current_files[file]
        end
      end

      temp_digests = current_digests.keys - (new_digests.keys + missing_digests.keys)
      unless temp_digests.empty?
        temp_digests.each do |digest|
          unchanged_digests[digest] = current_digests[digest]
        end
      end

      temp_files = current_files.keys - (new_files.keys + missing_files.keys)
      unless temp_files.empty?
        temp_files.each do |file|
          unchanged_files[file] = current_files[file]
        end
      end

      # 1. ADD is new digest, new filepath.
      # consult new_digests and new_files
      unless new_digests.empty?
        new_digests.each do |digest, filepaths|
          # If new_files, check for ADD.
          filepaths.each do |file|
            if new_files.key?(file)
              # new digest, new file, it's an ADD!
              if new_files[file] == digest
                actions.add(digest, file)
                update_manifest_action(digest, version, actions)
                next # need this so we don't also count it as an UPDATE
              end
            end

            # 2. UPDATE is new digest, existing filepath
            # if new_files doesn't have it, check current_files
            if current_files.key?(file)
              # New digest, existing file
              if current_files[file] == digest
                actions.update(digest, file)
                update_manifest_action(digest, version, actions)
              end
            end
          end
        end
      end

      # 3. COPY is unchanged digest, additional (new) filepath
      unless unchanged_digests.empty?
        unchanged_digests.each do |digest, filepaths|
          # get previous version filepaths, compare to current version filepaths.
          if filepaths.size > previous_digests[digest].size
            # Take current array from previous array
            # What *new* filepaths do we have for this digest in this version?
            copied_files = filepaths - previous_digests[digest]
            copied_files.each do |copy_file|
              actions.copy(digest, copy_file)
            end
          end

          # 4. MOVE is unchanged digest, 1 deleted filepath, 1 added filepath.
          if filepaths.size == previous_digests[digest].size
            # For it to be a move, this digest must be listed in missing_files AND new_files.
            if missing_files.value?(digest) && new_files.value?(digest)
              # look this up in previous_files.
              old_filename = previous_digests[digest][0]
              new_filename = current_digests[digest][0]
              actions.move(digest, old_filename)
              actions.move(digest, new_filename)
            end
          end

          # 5. One possible DELETE is unchanged digest, fewer filepaths.
          if filepaths.size < previous_digests[digest].size

            # Am I in missing_files ?
            previous_filepaths = previous_digests[digest]
            deleted_filepaths = previous_filepaths - filepaths
            if deleted_filepaths.empty?
              deleted_filepaths.each do |delete_me|
                actions.delete(digest, delete_me)
              end
            end
          end
        end
      end

      # 6. DELETE of last filepath is where there's a missing_digest && the filepath is gone too.
      unless missing_digests.empty?
        missing_digests.each do |digest, filepaths|
          # For each missing digest, see if any of its filepaths are still referenced in current files.
          filepaths.each do |filepath|
            actions.delete(digest, filepath) unless current_files.key?(filepath)
          end
        end
      end

      @delta[version_string] = actions.all
    end

    def update_manifest_action(digest, version, action)
      version_string = @version_format % version.to_i
      # We need to make a deep copy here so content_paths edits don't screw up the ocfl_object's manifest.
      content_paths  = OcflTools::Utils.deep_copy(@ocfl_object.manifest[digest])
      # Find any content_path that starts with the current version's directory & contentDirectory;
      # these are bitstreams that were added to this version directory.
      content_paths.each do |content_path|
        if content_path =~ /^#{version_string}\/#{@ocfl_object.contentDirectory}/
          # Now trim from front of content_path.
          content_path.slice!("#{version_string}/#{@ocfl_object.contentDirectory}/")
          action.update_manifest(digest, content_path)
        end
      end
    end

    def get_first_version_delta
      # Everything in get_state is an 'add'
      version = 1
      actions = OcflTools::OcflActions.new

      version_string = @version_format % version.to_i
      @delta[version_string] = {} # Always clear out the existing version delta.
      @delta[version_string].clear

      current_digests = @ocfl_object.get_state(version)
      current_digests.each do |digest, filepaths|
        filepaths.each do |file|
          actions.add(digest, file)
          update_manifest_action(digest, version, actions)
        end
      end
      @delta[version_string] = actions.all
      # Everything in Fixity is also an 'add'
    end
  end
end
