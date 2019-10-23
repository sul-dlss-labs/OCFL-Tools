require 'anyway'

module OcflTools

  class Config < Anyway::Config
   attr_config version_format: "v%04d",
                 content_type: 'https://ocfl.io/1.0/spec/#inventory',
            content_directory: 'content',
             digest_algorithm: 'sha512'
  end

  def self.config
    @config ||= Config.new
  end

end
