module OcflTools

  class OcflInventory
    # create and manipulate an OCFL inventory file.
    require 'json'

    attr_accessor :manifest, :versions, :fixity

    def initialize(id, version)
      # Parameters that must be serialized into JSON
      @id               = id
      @type             = 'https://ocfl.io/1.0/spec/#inventory'
      @digestAlgorithm  = 'sha256' # sha512 is recommended, Stanford uses sha256.
      @head             = self.version_int_to_string(version)
      @contentDirectory = 'data' # default is 'content', Stanford uses 'data'
      @manifest         = Hash.new
      @versions         = Hash.new # A hash of Version hashes.
      @fixity           = Hash.new # Optional. Same format as Manifest.
    end

    def version_int_to_string(version)
      # converts [Integer] version to [String] v0001 format.
      result = "v%04d" % version.to_i
    end

    def serialize
      # return serialized JSON of OCFL object at most recent version.
      output_hash = Hash.new

      output_hash['id']               = @id
      output_hash['type']             = @type
      output_hash['digestAlgorithm']  = @digestAlgorithm
      output_hash['head']             = @head
      output_hash['contentDirectory'] = @contentDirectory
      output_hash['manifest']         = @manifest
      output_hash['versions']         = @versions
      # optional
      # output_hash['fixity'] = @fixity
      JSON.pretty_generate(output_hash)
    end

    def crosscheck_digests
      # requires values in @versions and @manifest.
      # verifies that every digest in @versions can be found in @manifest.
      
    end
  end
end
