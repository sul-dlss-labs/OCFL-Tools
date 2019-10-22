module OcflTools
  # create and manipulate an OCFL inventory file.
  class OcflInventory < OcflTools::OcflObject

    # serializes all versions of the object to JSON.
    # @return [JSON] complete OCFL object in serialized JSON format, suitable
    # for writing to storage.
    def serialize

      output_hash = Hash.new

      self.set_head_version # We're about to make an OCFL. At least pretend it'll pass validation.

      output_hash['id']               = @id
      output_hash['head']             = @head
      output_hash['type']             = @type
      output_hash['digestAlgorithm']  = @digestAlgorithm
      output_hash['contentDirectory'] = @contentDirectory
      output_hash['manifest']         = @manifest
      output_hash['versions']         = @versions
      # optional
      output_hash['fixity']           = @fixity unless @fixity.size == 0

      JSON.pretty_generate(output_hash)
    end

    # Sets @head to highest version found in object.
    # @return [String] current version name.
    def set_head_version
      self.set_head_from_version(self.version_id_list.sort[-1])
    end

    # Writes inventory file and inventory sidecar digest file to a directory.
    # @param [String] directory resolvable directory to write inventory.json to.
    def to_file(directory)
      inventory = File.new("#{directory}/inventory.json", "w+")
      inventory.syswrite(self.serialize)

      checksum = OcflTools::Utils.generate_file_digest(inventory.path, @digestAlgorithm)

      inventory_digest = File.new("#{inventory.path}.#{@digestAlgorithm}", "w+")
      inventory_digest.syswrite("#{checksum} inventory.json")
    end

    # Reads a file in from disk and parses the JSON within.
    # @param [Pathname] file resolvable path to alleged inventory.json.
    # @return [Hash] of JSON keys & values.
    # @todo fail spectacularly if the file doesn't contain JSON.
    def read_json(file)
      JSON.parse(File.read(file))
    end

    # Reads in a file, parses the JSON and ingests it into an {OcflTools::OcflInventory}
    # @param [String] file a file that should contain an inventory.json.
    # @return [self]
    def from_file(file)
      import_hash = self.read_json(file)
      # We passed validation, so let's assign our results to our instance variables.
      @id               = import_hash['id']
      @head             = import_hash['head']
      @type             = import_hash['type']
      @digestAlgorithm  = import_hash['digestAlgorithm']
      @contentDirectory = import_hash['contentDirectory']
      @manifest         = import_hash['manifest']
      @versions         = import_hash['versions']

      if import_hash.has_key?('fixity')
        @fixity = import_hash['fixity']
      end
      return self
    end

  end
end
