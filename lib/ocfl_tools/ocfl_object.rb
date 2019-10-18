module OcflTools
  class OcflObject
    attr_accessor :manifest, :versions, :fixity, :id, :digestAlgorithm, :head, :type, :contentDirectory

    def initialize
      # Parameters that must be serialized into JSON
      @id               = nil
      @head             = nil
      @type             = 'https://ocfl.io/1.0/spec/#inventory'
      @digestAlgorithm  = 'sha256' # sha512 is recommended, Stanford uses sha256.
      @contentDirectory = 'data' # default is 'content', Stanford uses 'data'
      @manifest         = Hash.new
      @versions         = Hash.new # A hash of Version hashes.
      @fixity           = Hash.new # Optional. Same format as Manifest.
    end

    def set_head_from_version(version)
      # @param [Integer] current version.
      # sets @head in current format.
      @head = OcflTools::Utils.version_int_to_string(version)
    end

    # TODO; get and set version stuff?

  end
end
