module OcflTools
  class MoabExport

    # @return [Array] A series of [Integer] representing all versions of the Moab object.
    attr_reader :versions

    # @return [String] The digital object ID (Stanford druid)
    attr_reader :digital_object_id

    # @return [String] The algorithm used to compute hashes.
    attr_accessor :digest

    # @param moab [Moab::StorageObject] The Moab object on which to perform work.
    def initialize(moab)
      raise "This isn't a Moab object, n00b" unless moab.is_a?(Moab::StorageObject)

      @moab               = moab
      @versions           = @moab.version_id_list  # remember, versions must be Integers.
      @digital_object_id  = @moab.digital_object_id
      @digest             = 'md5' # default value, but can be changed to sha1 or sha256.

    end

    # used by get_deltas
    def version_inventory(version)
      # @param [Integer] version of object to generate inventory for.
      # @return [Hash] of all files and checksums that represent the object at given version.
      self.get_inventory('version', version)
    end

    # Not really used; here for completeness because I indirected get_inventory.
    def version_additions(version)
      # @param [Integer] version of object to generate inventory for.
      # @return [Hash] of all files and checksums that were added or modified at this version.
      self.get_inventory('additions', version)
    end

    # used by get_prior_delta
    def get_FileInventory(version)
      # @param [Integer] version of object to generate inventory file for.
      # @return [Moab::FileInventory] for given version.
      moab_version = @moab.find_object_version(version)
      moab_version.file_inventory( 'version' )
    end

    def version_int_to_string(version)
      # converts [Integer] version to [String] v0001 format.
      result = "v%04d" % version.to_i
    end

    def list_all_files
      # @return [Array] of all files found relative to Moab object root.
      results = Array.new
      Dir.chdir("#{@moab.object_pathname}")
      @versions.each do | version |
        version_name = self.version_int_to_string(version)
        # Files only, Dir.glob('path/**/*').select{ |e| File.file? e }
        Dir.glob("#{version_name}/data/**/*").select.each do |e|
          if File.file? e
              results << e
            end
          end
        end
        return results
    end

    def generate_file_digest(file)
      # Given a fully-resolvable file path, calculate and return @digest.
      case @digest
        when 'md5'
          checksum = Digest::MD5.hexdigest(File.read(file))
        when 'sha1'
          checksum = Digest::SHA1.hexdigest(File.read(file))
        when 'sha256'
          checksum = Digest::SHA256.hexdigest(File.read(file))
        else
          raise "Unknown digest type!"
      end
      return checksum
    end

    def generate_ocfl_manifest
      # @return [Hash] of digests with [Array] of filenames as values.
      # The returned [Hash] is the Manifest block of an OCFL object. 
      my_files = self.list_all_files
      my_manifest = Hash.new

      my_files.each do | file |
        full_filepath = "#{@moab.object_pathname}" + "/" + "#{file}"
        checksum = self.generate_file_digest(full_filepath)
        if my_manifest.has_key? checksum
          existing_entries = my_manifest[checksum]
          existing_entries.concat( [ file ] ) # NOT the FULL filepath; relative to object root.
          # Make unique.
          unique_entries = existing_entries.uniq
          my_manifest[checksum] = unique_entries
        end
        # if the checksum isn't already there, add it as a new key. File must be in an array.
        my_manifest[checksum] = [ file ]
      end
      return my_manifest
    end

    def print_deltas
      # @return Puts all deltas of this object to std out.
      # Convenience method for CLI and debugging.
      self.get_deltas.each do | version, delta |
        puts "#{@digital_object_id},#{version}"
        delta.each do | action, result|
          puts "  #{action}:"
          result.each do | filestream |
            filestream.each do | filename, checksums |
              if checksums.length > 1
                # Highest value in checksums array is most recent.
              puts "    #{filename} new #{self.digest}: #{checksums[1]} previous #{self.digest}: #{checksums[0]}"
                else
              puts "    #{filename} new #{self.digest}: #{checksums[0]}"
              end
            end
          end
        end
      end
    end

    def get_deltas
      # @return Nested [Hash] of changes for all versions. {Version{Change{File [checksums]}}}
      my_versions = Hash.new

      # version 1 is a special case because it a) always exists and b) has no prior version to compare to.
      v1 = Hash.new
      added = self.version_inventory(1) # Hash of first version is all additions.

      # self.version_inventory returns a Hash of files and checksums.
      # It needs re-formatting to align with the results of Moab::FileInventoryDifference.
      my_array = []
      added.each do | k,v |
          my_hash = {}
          my_hash[k] = v
          my_array << my_hash # Creates an Array of single key/value Hashes.
      end

      # The change key 'added' needs to contain values as an array, to match format of other versions
      v1["added"] = my_array # and again, all actions in version 1 are additions.

      # Add the version 1 hash to our final Hash'o'hashes report out.
      my_versions[1] = v1

      # We are assuming the Moab is well-formed, so length == 1 == only 1 version in the Moab.
      if @versions.length == 1
        return my_versions
      end
      # otherwise, do versions > 1.
      version = 1
      while version < @versions.length
        version = version + 1
        my_versions[version] = self.get_prior_delta(version)
      end
      return my_versions
    end

    def get_prior_delta(version)
      # @param [Integer] version of object to generate delta for.
      # @return [Hash] of actions that have been performed on this Moab since the prior version.

      raise "Provided version must be greater than 1!" unless version > 1

      prior_version = version - 1

      current_version_inventory = self.get_FileInventory(version)
      prior_version_inventory   = self.get_FileInventory(prior_version)

      inventory_diff = Moab::FileInventoryDifference.new
      inventory_diff.compare(prior_version_inventory, current_version_inventory)

      my_results = Hash.new
      my_results = inventory_diff.differences_detail # returns a [Hash] of results

      combined_results = Hash.new # The Hash we'll use to report out.

      my_results["group_differences"].each do | group |
        # Group is an [Array] of arrays, one array per group.
        # each group array consists of two elements: group_id and a [Hash] of content.
        # Everything we need is in the second element (the Hash).
        if group[1]["difference_count"] == 0
          next # If there are no differences in this group between versions, skip it.
        end

        my_group = group[1]["group_id"] # Get this for later. It'll be 'metadata' or 'content'

        group[1]["subsets"].each do |  subset |
          # A subset value is 'added' 'modified' 'deleted' or 'renamed'(?)
          # A subset is an Array containing 2 elements; 1 [String] (name) and 1 [Hash].
          # As before, everything we need is in the [Hash] in the 2nd element.

          change = "#{subset[1]["change"]}" # capture the type of change for later.

          subset[1]["files"].each do | file |
            # This is also an Array of 2 elements. First element is a [Integer].
            # 2nd element is a [Hash] of useful data.

            # 'modified' has filename in basis_path, 'same' in other_path, 2 checksums.
            # 'added' has null in basis_path, filename in other_path, 1 checksum.
            # presumably renames have value in both; we just want the NEW name (we can work out the old one from checksums)

            file_path = "#{my_group}/#{file[1]["other_path"]}"
            file_path = "#{my_group}/#{file[1]["basis_path"]}" unless file[1]["basis_path"] == ''

            my_checksums = []
            file[1]["signatures"].each do | signature |
              # Modified has 2 signatures. Adds have 1. We need to capture these in an array.
              # Each signature block has 3 different digests. Pick one (md5, sha1, sha256).
              my_checksums << signature[1][@digest]
            end
            # Now make a [Hash] of our results for this file, a single key with an Array of checksums.
            my_file_and_sums = { "#{file_path}" => my_checksums }

            # create the key (with the type of change) with an empty [Array] as value if it doesn't already exist.
            combined_results["#{change}"] = [] unless combined_results.has_key? "#{change}"

            # Now get that [Array] and append my_file_and_sums to it.
            add_me = combined_results["#{change}"]  # Get the existing [Array] out of the [Hash]
            add_me << my_file_and_sums              # Add our new [Hash] to the [Array].
            combined_results["#{change}"] = add_me  # and put the expanded [Array] back into combined_results.
          end
        end
      end
      return combined_results
    end

    def get_inventory(inventory, version)
      # @param [String] one of 'additions', 'manifests', 'version'.
      # @param [Integer] version of Moab to get inventory for.
      # @return [Hash] of files and checksums for given inventory type and version.

      moab_version = @moab.find_object_version( version )

      file_inventory = moab_version.file_inventory( inventory ) # String is one of : additions, manifests, version

      my_files = Hash.new # Our Hash return value.

      file_inventory.groups.each do | group |
        group.files.each do | file |
          file.instances.each do | instance |
            #           Moab::StorageServices.retrieve_file(file_category, file_id, object_id, version_id = nil)
            file_path = Moab::StorageServices.retrieve_file( "#{group.group_id}", "#{instance.path}", @moab.digital_object_id , version )
            case @digest
              when 'md5'
                checksum = file.signature.md5
              when 'sha1'
                checksum = file.signature.sha1
              when 'sha256'
                checksum = file.signature.sha256
              else
                raise "Unknown digest type!"
            end
             # And checksum needs to be in an array.
             my_checksums = []
             my_checksums << checksum
             my_files["#{group.group_id}/#{instance.path}"] = my_checksums
          end
        end
      end
      return my_files
    end

  end
end
