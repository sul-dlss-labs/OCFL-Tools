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

    end

    # Given a version, get the delta from the previous version.
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

      @delta[version] = {}  # Always clear out the existing version delta.

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

      puts "Current files:"
      current_files.each do | file, digest |
        puts "#{digest} #{file}"
      end

      puts "Previous files:"
      previous_files.each do | file, digest |
        puts "#{digest} #{file}"
      end

      if !missing_files.empty?
        puts "Missing files:"
        missing_files.each do | file, digest |
          puts "#{digest} #{file}"
        end
      end

      if !new_files.empty?
        puts "New files:"
        new_files.each do | file, digest |
          puts "#{digest} #{file}"
        end
      end

      if !unchanged_files.empty?
        puts "Unchanged files:"
        unchanged_files.each do | file, digest |
          puts "#{digest} #{file}"
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
                if !@delta[version].key?('add')
                  @delta[version]['add'] = {}
                  @delta[version]['add'][digest] = []
                end
                @delta[version]['add'][digest] = ( @delta[version]['add'][digest] << file )
                next
              end
            end

            # if new_files doesn't have it, check current_files
            if current_files.has_key?(file)
              # New digest, existing file
              if current_files[file] == digest
                if !@delta[version].key?('update')
                  @delta[version]['update'] = {}
                  @delta[version]['update'][digest] = []
                end
                @delta[version]['update'][digest] = ( @delta[version]['update'][digest] << file )
                next
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
            copied_files = filepaths - previous_digests[digest]
            if !@delta[version].key?('copy')
              @delta[version]['copy'] = {}
              @delta[version]['copy'][previous_digests[digest][0]] = []
            end
            @delta[version]['copy'][previous_digests[digest][0]] = copied_files # ( @delta[version]['copy'][previous_digests[digest][0]] << file )
            next
          end

          # 4. MOVE is unchanged digest, 1 deleted filepath, 1 added filepath.
          if filepaths.size == previous_digests[digest].size
            # For it to be a move, this digest must be listed in missing_files AND new_files.
              if missing_files.has_value?(digest) && new_files.has_value?(digest)
                # look this up in previous_files.
                old_filename = previous_digests[digest]
                new_filename = current_digests[digest]

                if !@delta[version].key?('move')
                  @delta[version]['move'] = {}
                end
                # move is just a string key/value pair.
                @delta[version]['move'][old_filename[0]] =  new_filename[0]
                next
              end
          end

          # 5. One possible DELETE is unchanged digest, fewer filepaths.
          if filepaths.size < previous_digests[digest].size
            # Am I in missing_files ?
            previous_filepaths = previous_digests[digest]
            deleted_filepaths = previous_filepaths - filepaths

            if deleted_filepaths.size > 0
              # Yup, it's a delete!
              if !@delta[version].key?('delete')
                @delta[version]['delete'] = []
              end
              deleted_filepaths.each do | delete_me |
                @delta[version]['delete'] = ( @delta[version]['delete'] << delete_me )
              end
              next
            end
          end

        end
      end

      # 6. DELETE of last filepath is where there's a missing_digest && the filepath is gone too.
      if !missing_digests.empty?
        puts "Doing missing digests now"
        missing_digests.each do | digest, filepaths |
          # For each missing digest, see if any of its filepaths are still referenced in current files.
          filepaths.each do | filepath |
            unless current_files.has_key?(filepath)
              if !@delta[version].key?('delete')
                @delta[version]['delete'] = []
              end
              @delta[version]['delete'] = ( @delta[version]['delete'] << filepath )
            end
          end
        end
      end

    end


    def get_first_version_delta
      # Everything in get_state is an 'add'
      version = 1
      puts "New files:"
      @delta[version] = {}
      @delta[version]['add'] = {}

      current_digests = @ocfl_object.get_state(version)
      puts current_digests
      current_digests.each do | digest, filepaths |
        @delta[version]['add'][digest] = []
        filepaths.each do | file |
          @delta[version]['add'][digest] = ( @delta[version]['add'][digest] << file )
        end
      end

      # Everything in Fixity is also an 'add'
    end

  end
end
