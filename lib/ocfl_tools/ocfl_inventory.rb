module OcflTools

  class OcflInventory
    # create and manipulate an OCFL inventory file.

    attr_accessor :manifest, :versions, :fixity

    def initialize(id, version)
      # Parameters that must be serialized into JSON
      @id               = id
      @type             = 'https://ocfl.io/1.0/spec/#inventory'
      @digestAlgorithm  = 'sha256' # sha512 is recommended, Stanford uses sha256.
      @head             = OcflTools::Utils.version_int_to_string(version)
      @contentDirectory = 'data' # default is 'content', Stanford uses 'data'
      @manifest         = Hash.new
      @versions         = Hash.new # A hash of Version hashes.
      @fixity           = Hash.new # Optional. Same format as Manifest.
    end

    def serialize
      # return serialized JSON of OCFL object at most recent version.
      output_hash = Hash.new

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

    def to_file(directory)
      # @param [String] resolvable directory to write inventory.json to.
      # Also needs to create inventory_digest file.
      inventory = File.new("#{directory}/inventory.json", "w+")
      inventory.syswrite(self.serialize)

      checksum = OcflTools::Utils.generate_file_digest(inventory.path, @digestAlgorithm)

      inventory_digest = File.new("#{inventory.path}.#{@digestAlgorithm}", "w+")
      inventory_digest.syswrite("#{checksum} inventory.json")
    end

    def crosscheck_digests
      # requires values in @versions and @manifest.
      # verifies that every digest in @versions can be found in @manifest.
    end

  end
end
