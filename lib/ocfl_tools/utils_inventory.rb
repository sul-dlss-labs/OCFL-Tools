module OcflTools
  module Utils

    # If inventory_file is a parameter, it probably belongs in here.
    module Inventory

      # Given an inventory file and a key to search for, return the value at that key.
      # This is designed to be FAST for header keys, not for manifests and fixity retrievals.
      def self.get_value(inventory_file, key)
        raise "#{key} is not a valid OCFL inventory header key" unless ['contentDirectory', 'digestAlgorithm', 'head', 'type', 'id'].include?(key)
        result = IO.foreach(inventory_file).lazy.grep(/"#{key}"/).take(1).to_a #{ |a| puts "I got #{a}"}
        # [ " "digestAlgorithm": "sha256"," ] is my return value. It's not great.
        if result.size < 1 # if no match, result has no content.
          return nil
        end
        string = result[0]  # our result is an array with an singl element.
        result_array = string.split('"') # and we need the 4th part of the element.
        result_array[3]
      end

      # Given an inventory file, return the value of contentDirectory IF FOUND, or 'content' (per spec)
      def self.get_contentDirectory(inventory_file)
        contentDirectory = OcflTools::Utils::Inventory.get_value(inventory_file, "contentDirectory")
        if contentDirectory == nil
          contentDirectory = 'content'
        end
        contentDirectory
      end

      def self.get_digestAlgorithm(inventory_file)
        digestAlgorithm = OcflTools::Utils::Inventory.get_value(inventory_file, "digestAlgorithm")
        if digestAlgorithm == nil
          # Actually against OCFL spec
          raise "Unable to find value for digestAlgorithm in #{inventory_file}"
        end
        digestAlgorithm
      end

      # Given an inventory file, return the fixity block (if it exists) or nil.
      def self.get_fixity(inventory_file)
        inventory = OcflTools::OcflInventory.new.from_file(inventory_file)
        return nil unless inventory.fixity.size > 0
        inventory.fixity
      end

      # Given an inventory file, return [Array] of the digest types found in the fixity block, or nil.
      def self.get_fixity_digestAlgorithms(inventory_file)
      end

      # Given an inventory file and a digestAlgorithm, return [Hash] of digests and [ filepaths ], or nil.
      def self.get_fixity_digests(inventory_file, digestAlgorithm)
      end

      # Given an inventory & version, return files from that version.

      # Given an inventory and 2 versions, return all files for range of versions.

    end
  end
end
