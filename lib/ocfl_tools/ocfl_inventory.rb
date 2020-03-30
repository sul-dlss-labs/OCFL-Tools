# frozen_string_literal: true

module OcflTools
  # create and manipulate an OCFL inventory file.
  class OcflInventory < OcflTools::OcflObject
    # serializes all versions of the object to JSON.
    # @return [JSON] complete OCFL object in serialized JSON format, suitable
    # for writing to a storage layer.
    def serialize
      output_hash = {}

      set_head_version # We're about to make an OCFL. At least pretend it'll pass validation.

      # If you've not set type by now, set it to the site default.
      @type ||= OcflTools.config.content_type

      output_hash['id']               = @id
      output_hash['head']             = @head
      output_hash['type']             = @type
      output_hash['digestAlgorithm']  = @digestAlgorithm
      unless @contentDirectory.empty?
        output_hash['contentDirectory'] = @contentDirectory
      end
      output_hash['manifest']         = @manifest
      output_hash['versions']         = @versions
      # optional
      output_hash['fixity']           = @fixity unless @fixity.empty?

      JSON.pretty_generate(output_hash)
    end

    # Sets @head to highest version found in object.
    # @return [String] current version name.
    def set_head_version
      set_head_from_version(version_id_list.max)
    end

    # Writes inventory file and inventory sidecar digest file to a directory.
    # @param [String] directory resolvable directory to write inventory.json to.
    def to_file(directory)
      inventory = File.new("#{directory}/inventory.json", 'w+')
      inventory.syswrite(serialize)

      checksum = OcflTools::Utils.generate_file_digest(inventory.path, @digestAlgorithm)

      inventory_digest = File.new("#{inventory.path}.#{@digestAlgorithm}", 'w+')
      inventory_digest.syswrite("#{checksum} inventory.json")
    end

    # Reads a file in from disk and parses the JSON within.
    # @param [Pathname] file resolvable path to alleged inventory.json.
    # @return [Hash] of JSON keys & values.
    def read_json(file)
      begin
        JSON.parse(File.read(file))
      rescue JSON::ParserError
        raise OcflTools::Errors::Error211, "#{file} is not valid JSON."
      rescue StandardError => e
        # Would be good to catch File Not Found and throw a specific error here.
        raise "An unknown error occured reading file #{file}: #{e}" # catch/encapsulate any FileIO issues
      end
    end

    # Reads in a file, parses the JSON and ingests it into an {OcflTools::OcflInventory}
    # @param [Pathname] file fully-qualified filepath to a valid OCFL inventory.json.
    # @return [self]
    def from_file(file)
      import_hash = read_json(file)

      # REQUIRED keys; raise exception if not found.
      [ 'id', 'head', 'type', 'digestAlgorithm', 'manifest', 'versions' ].each do | key |
        unless import_hash.key?(key)
          raise OcflTools::Errors::Error216, "Required key #{key} not found"
        end
        if import_hash[key].empty?
          raise OcflTools::Errors::Error217, "Required key #{key} must contain a value"
        end
      end

      @id               = import_hash['id']
      @head             = import_hash['head']
      @type             = import_hash['type']
      @digestAlgorithm  = import_hash['digestAlgorithm']
#      if import_hash.key?('contentDirectory')
#        @contentDirectory = import_hash['contentDirectory']
#      end
      @manifest         = import_hash['manifest']
      @versions         = import_hash['versions']
      # Optional keys - contentDirectory and fixity block.
      @fixity           = import_hash['fixity'] if import_hash.key?('fixity')
      @contentDirectory = import_hash['contentDirectory'] if import_hash.key?('contentDirectory')

      self
    end
  end
end
