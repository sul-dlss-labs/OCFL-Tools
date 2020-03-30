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
        raise OcflTools::Errors::ValidationError, details: { "E211" => ["#{file} is not valid JSON."] }
      rescue Errno::ENOENT
        # raise OcflTools::Errors::Error215, "expected inventory file #{file} not found!"
        raise OcflTools::Errors::ValidationError, details: { "E215" => ["expected inventory file #{file} not found!"] }
      # rescue Errno::EACCES Don't think we need to explicitly raise file permissions; let StdErr take it.
      rescue StandardError => e
        raise "An unknown error occured reading file #{file}: #{e}" # catch/encapsulate any FileIO issues
      end
    end

    # Reads in a file, parses the JSON and ingests it into an {OcflTools::OcflInventory}
    # @param [Pathname] file fully-qualified filepath to a valid OCFL inventory.json.
    # @return [self]
    def from_file(file)
      import_hash = read_json(file)

      # REQUIRED keys; raise exception if not found.
      e216_errors = []
      e217_errors = []
      error_hash  = {}
      [ 'id', 'head', 'type', 'digestAlgorithm', 'manifest', 'versions' ].each do | key |
        unless import_hash.key?(key)
          e216_errors << "Required key #{key} not found in #{file}"
          error_hash["E216"] = e216_errors # we'll keep updating this value as new errors are recorded.
        end
        if import_hash.key?(key) && import_hash[key].empty?
          # If the key exists but it's empty, that's also a problem!
          e217_errors << "Required key #{key} in #{file} must contain a value"
          error_hash["E217"] = e217_errors
        end
      end
      # Raise a problem if we have anything in error_hash.
      if error_hash.size > 0
        raise OcflTools::Errors::ValidationError, details: error_hash
      end



      @id               = import_hash['id']
      @head             = import_hash['head']
      @type             = import_hash['type']
      @digestAlgorithm  = import_hash['digestAlgorithm']
      @manifest         = import_hash['manifest']
      @versions         = import_hash['versions']
      # Optional keys - contentDirectory and fixity block.
      @fixity           = import_hash['fixity'] if import_hash.key?('fixity')
      @contentDirectory = import_hash['contentDirectory'] if import_hash.key?('contentDirectory')

      self
    end
  end
end
