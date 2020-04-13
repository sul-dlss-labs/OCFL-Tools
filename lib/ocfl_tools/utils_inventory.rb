# frozen_string_literal: true

module OcflTools
  module Utils
    # A module of convenience methods for reading information from an OCFL inventory.json file.
    # {get_value} and its children are designed to account for reading info from the top few lines of a potentially many-MB size file,
    # without having to load it all into memory by ingesting it with {OcflTools::OcflInventory}.
    module Inventory
      # Given an inventory file and a key to search for, return the value at that key.
      # @param [Pathname] inventory_file fully-qualified path to a valid OCFL inventory.json.
      # @param [String] key the JSON key in the inventory file that you want to return a value for.
      # @return [String or nil] the value of the requested key, or nil if not found.
      def self.get_value(inventory_file, key)
        unless %w[contentDirectory digestAlgorithm head type id].include?(key)
          raise "#{key} is not a valid OCFL inventory header key"
          raise OcflTools::Errors::RequestedKeyNotFound, "#{key} is not a valid OCFL inventory header key"
        end

        inventory = OcflTools::OcflInventory.new.from_file(inventory_file)

        case key
          when 'contentDirectory'
            inventory.contentDirectory
          when 'digestAlgorithm'
            inventory.digestAlgorithm
          when 'head'
            inventory.head
          when 'type'
            inventory.type
          when 'id'
            inventory.id
          else
            raise "Unknown key #{key}"
        end

      end

      # Given an inventory file, return the value of contentDirectory IF FOUND, or 'content' if contentDirectory is not set.
      # It explicitly does NOT use the config.content_directory setting for this check.
      # @param [Pathname] inventory_file fully-qualified path to a valid OCFL inventory.json.
      # @return [String] the value of content_directory in the JSON, if found, or the OCFL required default value of 'content'.
      def self.get_contentDirectory(inventory_file)
        contentDirectory = OcflTools::Utils::Inventory.get_value(inventory_file, 'contentDirectory')
        contentDirectory = 'content' if contentDirectory.nil?
        contentDirectory
      end

      # Given an inventory file, return the name of the digest algorithm used (e.g. 'sha512').
      # @param [Pathname] inventory_file fully-qualified path to a valid OCFL inventory.json.
      # @return [String] the string value describing the digest algorithm used in this inventory.
      def self.get_digestAlgorithm(inventory_file)
        digestAlgorithm = OcflTools::Utils::Inventory.get_value(inventory_file, 'digestAlgorithm')
        if digestAlgorithm.nil?
          # Actually against OCFL spec
          raise "Unable to find value for digestAlgorithm in #{inventory_file}"
        end

        digestAlgorithm
      end

      # Given an inventory file, return the fixity block (if it exists) or nil.
      # @param [Pathname] inventory_file fully-qualified path to a valid OCFL inventory.json.
      # @return [Hash or nil] the fixity block from the provided inventory.json, or nil if the inventory does not contain a fixity block.
      def self.get_fixity(inventory_file)
        inventory = OcflTools::OcflInventory.new.from_file(inventory_file)
        return nil if inventory.fixity.empty?

        inventory.fixity
      end

      # Given an inventory file, return [Array] of the digest types found in the fixity block, or nil.
      # @param [Pathname] inventory_file fully-qualified path to a valid OCFL inventory.json.
      # @return [Array or nil] an array of [String] values, with each value being a digest type found in the fixity block, e.g. 'sha1', 'md5', etc, or nil if no fixity block is found.
      def self.get_fixity_digestAlgorithms(inventory_file)
        inventory = OcflTools::OcflInventory.new.from_file(inventory_file)
        return nil if inventory.fixity.empty?

        inventory.fixity.keys
      end

      # Given an inventory file and a digestAlgorithm, return [Hash] of digests and [ filepaths ], or nil.
      # @param [Pathname] inventory_file fully-qualified path to a valid OCFL inventory.json.
      # @param [String] digestAlgorithm the algorithm used in the fixity block that you want digests for.
      # @return [Hash or nil] a hash of digests and filepaths from the fixity block for the given digest type, or nil if the inventory.json does not contain a fixity block.
      def self.get_fixity_digests(inventory_file, digestAlgorithm)
        inventory = OcflTools::OcflInventory.new.from_file(inventory_file)
        return nil if inventory.fixity.empty?

        inventory.fixity[digestAlgorithm]
      end

      # Given an inventory & version, return files from that version.

      # Given an inventory and 2 versions, return all files for range of versions.
    end
  end
end
