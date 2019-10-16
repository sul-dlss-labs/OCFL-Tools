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
      # If @state[digest] has a value, get it and concat filename to it.
      # Otherwise, add @state[digest] as a new k/v pair with filename as value.
      if @state.has_key? digest
        existing_entries = @state[digest]
        existing_entries.concat(filename)
        # Make unique.
        unique_entries = existing_entries.uniq
        @state[digest] = unique_entries
        return @state
      end
      # if the digest isn't already in @state, set it and return @state.
      @state[digest] = filename
      return @state
    end
  end
end
