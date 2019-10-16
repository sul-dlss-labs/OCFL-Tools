module OcflTools

  class OcflInventory
    # create and manipulate an OCFL inventory file.
    def initialize(id, version)
      # Parameters that must be serialized into JSON
      @id               = id
      @type             = 'https://ocfl.io/1.0/spec/#inventory'
      @digestAlgorithm  = 'sha256' # sha512 is recommended, Stanford uses sha256.
      @head             = version
      @contentDirectory = 'data' # default is 'content', Stanford uses 'data'
      @manifest         = Hash.new
      @versions         = Hash.new # A hash of Version hashes.
    end

    def serialize
      # return serialized JSON of OCFL object at most recent version.
    end
  end

end
