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

  end
end
