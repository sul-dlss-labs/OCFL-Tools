module OcflTools
  class OcflVersion

    attr_accessor :created, :state, :message, :user
    attr_reader :version

    def initialize(version)
      # Parameters that must be serialized.
      @created  = ''
      @state    = Hash.new # key is sha256 file digest, value is array of filenames relative to version dir.
      @message  = ''
      @user     = '' # hash of arbitrary key/values
      # Place above params into a hash, with a single key of @version and value being the above hash.
      @version  = version # the string version that this is of. Must be 1 level above all other params.
    end

    def serialize
      # Returns a Hash suitable for upstream serializing.
    end

    def add_entry(digest, filename)
      # @params [String] digest, [Array] filename(s) associated with given digest.
      # Actually needs to check if it's already here, and append filename to array if so.
      @state[digest] = filename
    end
  end
end
