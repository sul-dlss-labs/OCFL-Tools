module OcflTools
  class OcflVerify < OcflTools::OcflObject
    # Pass it an OCFLInventory for it to check.
    attr_reader :my_results

    def initialize(ocfl_object)
      @my_victim = ocfl_object
      @my_results = {}
      @my_results['errors'] = {}
      @my_results['warnings'] = {}
      @my_results['pass'] = {}

      @object_directory = '' # optional path to object for digest checking.

      # check .respond_to? first for all expected methods.
      self.preflight

    end

    def check_all
      # Duck-typing the heck out of this, assuming @my_victim will respond to ocflobject methods.

      self.check_id

      return @my_results
    end

    def preflight
      # check for expected instance_variables with .instance_variable_defined?(@some_var)
      [ "@id", "@head", "@type", "@digestAlgorithm", "@contentDirectory", "@manifest", "@versions", "@fixity" ].each do | var |
        raise "Object does not have instance var #{var} defined" unless @my_victim.instance_variable_defined?(var)
      end

      # check for all methods we need to validate OCFL structure
      [ "get_files", "get_current_files", "get_state", "version_id_list", "get_digest" ].each do | mthd |
        raise "Object does not respond to #{mthd}" unless @my_victim.respond_to?(mthd)
      end

    end

    def check_id
      errors = nil
      if @my_victim.id.length < 1
        self.error('check_id', 'Object ID cannot be 0 length')
        errors = true
      end
      if @my_victim.id == nil
        self.error('check_id', 'Object ID cannot be nil')
        errors = true
      end
      if @my_victim.id.length > 128
        self.error('check_id', 'Object ID cannot exceed 128 characters.') # Not actually a thing.
        errors = true
      end
      if errors == nil
        self.pass('check_id', 'all checks passed without errors')
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
      # Should pass digest cross_check.
      # can be null if it passes cross_check? (empty inventories are valid, but warn)
    end

    def check_versions
      # should have values.
      # values should match expected version name format.
      # should be contiguous version numbers starting at 1.
    end

    def check_fixity
      # If present, should have at least 1 sub-key and 1 value.
    end

    def check_disk(object_directory=@object_directory)
      # If you give me an actual physical path, we can verify digests and files on disk.
    end

    def error(check, message)
      if @my_results['errors'].key?(check) == false
        @my_results['errors'][check] = []  # add an initial empty array.
      end
      @my_results['errors'][check] = ( @my_results['errors'][check] << message )
    end

    def warning(check, message)
      if @my_results['warnings'].key?(check) == false
        @my_results['warnings'][check] = []  # add an initial empty array.
      end
      @my_results['warnings'][check] = ( @my_results['warnings'][check] << message )
    end

    def pass(check, message)
      if @my_results['pass'].key?(check) == false
        @my_results['pass'][check] = []  # add an initial empty array.
      end
      @my_results['pass'][check] = ( @my_results['pass'][check] << message )
    end

  end
end
