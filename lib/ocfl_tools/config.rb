require 'anyway'

module OcflTools

  class Config < Anyway::Config
   attr_config version_format: "v%04d",
                 content_type: 'https://ocfl.io/1.0/spec/#inventory',
            content_directory: 'content',
             digest_algorithm: 'sha512',
            fixity_algorithms: ['md5', 'sha1', 'sha256']  # site-specific allowable fixity algorithms
  end

  def self.config
    @config ||= Config.new
  end

end
