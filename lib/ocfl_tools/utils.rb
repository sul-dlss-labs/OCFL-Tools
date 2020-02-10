# frozen_string_literal: true

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
      result = version_name.split('v')[1].to_i
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
      # checksum = Digest::MD5.hexdigest(File.read(file))
        computed_hash = Digest::MD5.new
        open(file) do |s|
          while chunk=s.read(8096)
            computed_hash.update chunk
          end
        end
        return "#{computed_hash}" # return as a String, not a Digest object.
      when 'sha1'
      #  checksum = Digest::SHA1.hexdigest(File.read(file))
        computed_hash = Digest::SHA1.new
        open(file) do |s|
          while chunk=s.read(8096)
            computed_hash.update chunk
          end
        end
        return "#{computed_hash}" # return as a String, not a Digest object.
      when 'sha256'
      # checksum = Digest::SHA256.hexdigest(File.read(file))
        computed_hash = Digest::SHA256.new
        open(file) do |s|
          while chunk=s.read(8096)
            computed_hash.update chunk
          end
        end
        return "#{computed_hash}" # return as a String, not a Digest object.
      when 'sha512'
      #  checksum = Digest::SHA512.hexdigest(File.read(file))
        computed_hash = Digest::SHA512.new
        open(file) do |s|
          while chunk=s.read(8096)
            computed_hash.update chunk
          end
        end
        return "#{computed_hash}" # return as a String, not a Digest object.
      else
        raise 'Unknown digest type!'
      end
      checksum
    end

    # @param [Hash] disk_checksums first hash of [ filepath => digest ] to compare.
    # @param [Hash] inventory_checksums second hash of [ filepath => digest ] to compare.
    # @param {OcflTools::OcflResults} results optional results instance to put results into.
    def self.compare_hash_checksums(disk_checksums:, inventory_checksums:, results: OcflTools::OcflResults.new, context: 'verify_checksums')
      unless results.is_a?(OcflTools::OcflResults)
        raise 'You need to give me a results instance!'
      end

      # 1st check! If everything is perfect, these two Hashs SHOULD BE IDENTICAL!
      if inventory_checksums == disk_checksums
        results.ok('O200', context, 'All discovered files in contentDirectory are referenced in inventory.')
        results.ok('O200', context, 'All discovered files in contentDirectory match stored digest values.')
        return results
      end

      # If they are NOT the same, we have to increment thru the Hashes to work out what's up.
      # It might be a file in the manifest that's not found on disk
      # Or a file on disk that's not in the manifest.
      # Or a file that is on disk and in the manifest, but the checksums don't match.

      disk_files       = disk_checksums.keys
      inventory_files  = inventory_checksums.keys

      missing_from_inventory = disk_files - inventory_files
      missing_from_disk      = inventory_files - disk_files

      unless missing_from_inventory.empty?
        missing_from_inventory.each do |missing|
          results.error('E111', context, "#{missing} found on disk but missing from inventory.json.")
        end
      end

      unless missing_from_disk.empty?
        missing_from_disk.each do |missing|
          results.error('E111', context, "#{missing} in inventory but not found on disk.")
        end
      end

      # checksum mismatches; requires the file to be in both hashes, so.
      inventory_checksums.each do |file, digest|
        next unless disk_checksums.key?(file)

        if disk_checksums[file] != digest
          results.error('E111', context, "#{file} digest in inventory does not match digest computed from disk")
        end
      end
      results
    end
  end
end
