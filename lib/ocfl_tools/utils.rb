module OcflTools
  module Utils

    def self.version_int_to_string(version)
      # converts [Integer] version to [String] v0001 format.
      result = "v%04d" % version.to_i
    end

    def self.generate_file_digest(file, digest)
      # @param [String] fully-resolvable filesystem path to a file.
      # @param [String] digest to encode file with.
      # @return [String] checksum of requested file using specified digest algorithm.
      # Given a fully-resolvable file path, calculate and return @digest.
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