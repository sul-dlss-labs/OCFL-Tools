module OcflTools
  module Utils

    # converts [Integer] version to [String] v0001 format.
    # Adjust VERSION_FORMAT to format string version to local needs.
    # @return [String] of version in desired format, starting with 'v'.
    def self.version_int_to_string(version)
      result = OcflTools.config.version_format % version.to_i
    end

    # converts [String] version name to [Integer].
    # OCFL spec requires string versions to start with 'v'.
    # Chop off the 'v' at th start, make into integer.
    # @param [String] version_name string to convert to an integer.
    # @return [Integer] the version as an integer.
    def self.version_string_to_int(version_name)
      result = version_name.split("v")[1].to_i
    end

    # We sometimes need to make deep (not shallow) copies of objects, mostly hashes.
    # When we are copying state from a prior version, we don't want our copy to still
    # be mutable by that prior version hash. So a deep (serialized) copy is called for.
    # @param [Object] o object to make a deep copy of.
    # @return [Object] a new object with no links to the previous one.
    def self.deep_copy(o)
      # We need this serialize Hashes so they don't shallow'y refer to each other.
      Marshal.load(Marshal.dump(o))
    end

    # Given a fully-resolvable file path, calculate and return @digest.
    # @param [String] file fully-resolvable filesystem path to a file.
    # @param [String] digest to encode file with.
    # @return [String] checksum of requested file using specified digest algorithm.
    def self.generate_file_digest(file, digest)
      case digest
        when 'md5'
          checksum = Digest::MD5.hexdigest(File.read(file))
        when 'sha1'
          checksum = Digest::SHA1.hexdigest(File.read(file))
        when 'sha256'
          checksum = Digest::SHA256.hexdigest(File.read(file))
        when 'sha512'
          checksum = Digest::SHA512.hexdigest(File.read(file))
        else
          raise "Unknown digest type!"
      end
      return checksum
    end

    # @param [Hash] disk_checksums first hash of [ filepath => digest ] to compare.
    # @param [Hash] manifest_checksums second hash of [ filepath => digest ] to compare.
    # @param [OcflTools::OcflResults] results optional results instance to put results into.
    def self.compare_hash_checksums(disk_checksums, manifest_checksums, results=nil)
      if results == nil
        my_results = OcflTools::OcflResults.new
      end
      raise "You need to give me a results instance!" unless my_results.is_a(OcflTools::OcflResults)

      # 1st check! If everything is perfect, these two Hashs SHOULD BE IDENTICAL!
      if manifest_checksums == disk_checksums
        my_results.ok('O111', 'verify_checksums', "#{@ocfl_object_root} All discovered files on disk are referenced in inventory manifest.")
        my_results.ok('O111', 'verify_checksums', "#{@ocfl_object_root} All discovered files on disk match stored digest values.")
        return my_results
      end

      # If they are NOT the same, we have to increment thru the Hashes to work out what's up.
      # It might be a file in the manifest that's not found on disk
      # Or a file on disk that's not in the manifest.
      # Or a file that is on disk and in the manifest, but the checksums don't match.

      disk_files      = disk_checksums.keys
      manifest_files  = manifest_checksums.keys

      missing_from_manifest = disk_files - manifest_files
      missing_from_disk     = manifest_files - disk_files

      if missing_from_manifest.size > 0
        missing_from_manifest.each do | missing |
          my_results.error('E111', 'verify_checksums', "#{missing} found on disk but missing from inventory.json.")
        end
      end

      if missing_from_disk.size > 0
        missing_from_disk.each do | missing |
          my_results.error('E111', 'verify_checksums', "#{missing} in manifest but not found on disk.")
        end
      end

      # checksum mismatches; requires the file to be in both hashes, so.
      manifest_checksums.each do | file, digest |
        if disk_checksums.has_key?(file)
          if disk_checksums[file] != digest
            my_results.error('E111', 'verify_checksums', "#{file} digest in inventory does not match digest computed from disk")
          end
        end
      end
      return my_results
    end

  end
end
