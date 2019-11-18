module OcflTools
  # Given an inventory, show changes from previous versions.
  class OcflDelta

    attr_reader :delta

    def initialize(ocfl_object)
      # Duck sanity check.
      [ "@id", "@head", "@manifest", "@versions", "@fixity" ].each do | var |
        raise "Object #{ocfl_object} does not have instance var #{var} defined" unless ocfl_object.instance_variable_defined?(var)
      end

      [ "get_state", "version_id_list", "get_digest" ].each do | mthd |
        raise "Object #{ocfl_object} does not respond to #{mthd}" unless ocfl_object.respond_to?(mthd)
      end

      @ocfl_object = ocfl_object
      @delta = {}
      # We need to get version format, for final report-out. Assume we have a @head
      # and that it's formatted correctly (starting with a 'v').
      version_length = ocfl_object.head.length - 1
      @version_format = "v%0#{version_length}d"
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
        raise "Version #{version} not found in #{@ocfl_object}!" unless @ocfl_object.version_id_list.include?(version)
        get_version_delta(version)
      end

    end

    private

    def get_version_delta(version)
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
      @delta[version_string] = {}  # Always clear out the existing version delta.

      actions = OcflTools::OcflActions.new

      temp_digests = previous_digests.keys - current_digests.keys
      if temp_digests.size > 0
        temp_digests.each do | digest |
          missing_digests[digest] = previous_digests[digest]
        end
      end

      temp_files = previous_files.keys - current_files.keys
      if temp_files.size > 0
        temp_files.each do | file |
          missing_files[file] = previous_files[file]
        end
      end

      temp_digests = current_digests.keys - previous_digests.keys
      if temp_digests.size > 0

        temp_digests.each do | digest |
          new_digests[digest] = current_digests[digest]
        end
      end

      temp_files = current_files.keys - previous_files.keys
      if temp_files.size > 0

        temp_files.each do | file |
          new_files[file] = current_files[file]
        end
      end

      temp_digests = current_digests.keys - ( new_digests.keys + missing_digests.keys )
      if temp_digests.size > 0
        temp_digests.each do | digest |
          unchanged_digests[digest] = current_digests[digest]
        end
      end

      temp_files = current_files.keys - ( new_files.keys + missing_files.keys )
      if temp_files.size > 0
        temp_files.each do | file |
          unchanged_files[file] = current_files[file]
        end
      end

      # 1. ADD is new digest, new filepath.
      # 2. UPDATE is new digest, existing filepath
      # consult new_digests and new_files
      if !new_digests.empty?
        new_digests.each do | digest, filepaths |
          # If new_files, check for ADD.
          filepaths.each do | file |
            if new_files.has_key?(file)
              # new digest, new file, it's an ADD!
              if new_files[file] == digest
                actions.add(digest, file)
                next # need this so we don't also count it as an UPDATE
              end
            end

            # if new_files doesn't have it, check current_files
            if current_files.has_key?(file)
              # New digest, existing file
              if current_files[file] == digest
                actions.update(digest, file)
              end
            end
          end
        end
      end

      # 3. COPY is unchanged digest, additional (new) filepath
      if !unchanged_digests.empty?
        unchanged_digests.each do | digest, filepaths |
          # get previous version filepaths, compare to current version filepaths.
          if filepaths.size > previous_digests[digest].size
            # Take current array from previous array
            # What *new* filepaths do we have for this digest in this version?
            copied_files = filepaths - previous_digests[digest]
            copied_files.each do | copy_file |
              actions.copy(digest, copy_file)
            end
          end

          # 4. MOVE is unchanged digest, 1 deleted filepath, 1 added filepath.
          if filepaths.size == previous_digests[digest].size
            # For it to be a move, this digest must be listed in missing_files AND new_files.
              if missing_files.has_value?(digest) && new_files.has_value?(digest)
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
            if deleted_filepaths.size > 0
              deleted_filepaths.each do | delete_me |
                actions.delete(digest, delete_me)
              end
            end
          end

        end
      end

      # 6. DELETE of last filepath is where there's a missing_digest && the filepath is gone too.
      if !missing_digests.empty?
        missing_digests.each do | digest, filepaths |
          # For each missing digest, see if any of its filepaths are still referenced in current files.
          filepaths.each do | filepath |
            unless current_files.has_key?(filepath)
              actions.delete(digest, filepath)
            end
          end
        end
      end

      @delta[version_string] = actions.all

    end


    def get_first_version_delta
      # Everything in get_state is an 'add'
      version = 1
      actions = OcflTools::OcflActions.new

      version_string = @version_format % version.to_i
      @delta[version_string] = {}

      current_digests = @ocfl_object.get_state(version)
      current_digests.each do | digest, filepaths |
        filepaths.each do | file |
          actions.add(digest, file)
        end
      end

      @delta[version_string] = actions.all
      # Everything in Fixity is also an 'add'
    end

  end
end
