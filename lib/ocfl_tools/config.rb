# frozen_string_literal: true

require 'anyway'

module OcflTools
  # Site-wide configuration settings for OCFL-Tools, using the 'anyway' gem.
  # Settings and their default values are:
  #            version_format: "v%04d",
  #              content_type: 'https://ocfl.io/1.0/spec/#inventory',
  #         content_directory: 'content',
  #          digest_algorithm: 'sha512',
  #         fixity_algorithms: ['md5', 'sha1', 'sha256']
  #              ocfl_version: '1.0'
  class Config < Anyway::Config
    attr_config version_format: 'v%04d',
                content_type: 'https://ocfl.io/1.0/spec/#inventory',
                content_directory: 'content',
                digest_algorithm: 'sha512',
                fixity_algorithms: %w[md5 sha1 sha256], # site-specific allowable fixity algorithms
                ocfl_version: '1.0'
  end

  # Creates a new config instance if it doesn't already exist.
  def self.config
    @config ||= Config.new
  end
end
