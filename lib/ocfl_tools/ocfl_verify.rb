module OcflTools
  class OcflVerify < OcflTools::OcflObject
    # Pass it an OCFLInventory for it to check.
    def initialize(ocfl_object)
      @my_victim = ocfl_object
      @my_results = {}
      @my_results['errors'] = []
      @my_results['warnings'] = []
      @my_results['pass'] = []

      # check .respond_to? first for all expected methods.
      self.preflight

    end

    def check_all
      # Duck-typing the heck out of this, assuming @my_victim will respond to ocflobject methods.
      # Check 1; should have content in these methods.
#      @id               = nil
#      @head             = nil
#      @type             = 'https://ocfl.io/1.0/spec/#inventory'
#      @digestAlgorithm  = 'sha256' # sha512 is recommended, Stanford uses sha256.
#      @contentDirectory = 'data' # default is 'content', Stanford uses 'data'
#      @manifest         = Hash.new
#      @versions         = Hash.new # A hash of Version hashes.
#      @fixity           = Hash.new # Optional. Same format as Manifest.

      self.check_id

      return @my_results
    end

    def preflight
      # check for all expected methods using .respond_to?
      # check for expected instance_variables with .instance_variable_defined?(@some_var)
      raise "Object does not have instance var defined" unless @my_victim.instance_variable_defined?("@id")
    end

    def check_id
      if @my_victim.id.length < 1
        self.error('Object ID cannot be 0 length')
      end
      if @my_victim.id == nil
        self.error('Object ID cannot be nil')
      end
      if @my_victim.id.length > 128
        self.error('Object ID cannot exceed 128 characters.') # Not actually a thing.
      end
    end

    def check_head
      # Must have value
      # Must match highest version found.

    end

    def check_type
      # String should match spec URL?
    end

    def check_digestAlgorithm
      # must be one of sha256 or sha512
    end

    def check_manifest
      # Should have values.
      # Should pass digest cross_check.
    end

    def check_versions
      # should have values.
      # values should match expected version name format.
      # should be contiguous version numbers starting at 1.
    end

    def check_fixity
      # If present, should have at least 1 sub-key and 1 value.
    end

    def check_disk(object_directory)
      # If you give me an actual physical path, we can verify digests and files on disk.
    end

    def error(message)
      my_errors = @my_results['errors']
      my_errors << message
      @my_results['errors'] = my_errors
    end

    def warning(message)
      my_warnings = @my_results['warnings']
      my_warnings << message
      @my_results['warnings'] = my_warnings
    end

    def pass(message)
      my_pass = @my_results['pass']
      my_pass << message
      @results['pass'] = my_pass
    end

  end
end
