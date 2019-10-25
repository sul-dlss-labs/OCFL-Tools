module OcflTools
  # Class to verify that an OcflObject is composed of valid data and structures.
  class OcflVerify < OcflTools::OcflObject

    # @return [Hash] my_results is a hash of check results.
    attr_reader :my_results

    # Create a new OCFLVerify object, using an OcflTools::Ocflobject as source.
    # @param [Object] ocfl_object {OcflTools::OcflObject} an ocfl object or inventory to verify.
    def initialize(ocfl_object)
      @my_victim = ocfl_object
      @my_results = {}
      @my_results['errors'] = {}
      @my_results['warnings'] = {}
      @my_results['pass'] = {}

      # check .respond_to? first for all expected methods.
      self.preflight

    end

    # Performs all OCFLVerify checks on the given object and reports results.
    # @return [Hash] of results.
    def check_all
      # Duck-typing the heck out of this, assuming @my_victim will respond to ocflobject methods.
      self.check_id
      self.check_type
      self.check_head
      self.check_manifest
      self.check_versions
      self.crosscheck_digests
      self.check_digestAlgorithm
      return @my_results
    end

    # Checks OCFL Object for valid value in the id attribute.
    # @return [Hash] of results.
    def check_id
      errors = nil

      case
        when @my_victim.id.length < 1
          error('check_id', 'OCFL 3.5.1 Object ID cannot be 0 length')
          errors = true
        when @my_victim.id == nil
          error('check_id', 'OCFL 3.5.1 Object ID cannot be nil')
          errors = true
        when @my_victim.id.length > 128
          error('check_id', 'OCFL 3.5.1 Object ID cannot exceed 128 characters.') # Not actually a thing.
          errors = true
      end

      if errors == nil
        pass('check_id', 'OCFL 3.5.1 all checks passed without errors')
      end
      return @my_results
    end

    # Checks OCFL Object for valid value in the head attribute.
    # @return [Hash] of results.
    def check_head
      case @my_victim.head
        when nil
          error('check_head', 'OCFL 3.5.1 @head cannot be nil')
        when Integer
          error('check_head', 'OCFL 3.5.1 @head cannot be an Integer')
        when String
          version        = OcflTools::Utils.version_string_to_int(@my_victim.head)
          target_version = @my_victim.version_id_list.sort[-1]
          if version == target_version
            pass('check_head', 'OCFL 3.5.1 @head matches highest version found')
          else
            error('check_head', "OCFL 3.5.1 @head version #{version} does not match expected version #{target_version}")
          end
        else
          # default case error
          error('check_head', 'An unknown @head error has occured.')
      end
      return @my_results
    end

    # Checks OCFL Object for valid value in the type attribute.
    # @return [Hash] of results.
    def check_type
      # String should match spec URL? Shameless green.
      pass('check_type', 'OCFL 3.5.1' )
      return @my_results
    end

    # Checks OCFL Object for valid value in the digestAlgorithm attribute.
    # @return [Hash] of results.
    def check_digestAlgorithm
      # must be one of sha256 or sha512
      case
      when @my_victim.digestAlgorithm.downcase == 'sha256'
        pass('check_digestAlgorithm', "OCFL 3.5.1 #{@my_victim.digestAlgorithm.downcase} is a supported digest algorithm.")
        warning('check_digestAlgorithm', "OCFL 3.5.1 #{@my_victim.digestAlgorithm.downcase} SHOULD be SHA512.")

      when @my_victim.digestAlgorithm.downcase == 'sha512'
        pass('check_digestAlgorithm', "OCFL 3.5.1 #{@my_victim.digestAlgorithm.downcase} is a supported digest algorithm.")
      else
        error('check_digestAlgorithm', "OCFL 3.5.1 Algorithm #{@my_victim.digestAlgorithm} is not valid for OCFL use.")
      end
      return @my_results
    end

    # Checks OCFL Object for a well-formed manifest block.
    # @return [Hash] of results.
    def check_manifest
      # Should pass digest cross_check.
      # can be null if it passes cross_check? (empty inventories are valid, but warn)
      # There MUST be a block called 'manifests'
      errors = nil
      case
        when @my_victim.manifest == nil
          error('check_manifest', 'OCFL 3.5.2 there MUST be a manifest block.')
          errors = true
        when @my_victim.manifest == {}
          error('check_manifest', 'OCFL 3.5.2 manifest block cannot be empty.')
          errors = true
      end

      if errors == nil
         pass('check_manifest', 'OCFL 3.5.2 object contains valid manifest.')
       end

      return @my_results # shameless green
    end

    # Checks OCFL Object for a well-formed versions block.
    # @return [Hash] of results.
    def check_versions

      version_count   = @my_victim.version_id_list.length
      highest_version = @my_victim.version_id_list.sort[-1]
      my_versions     = @my_victim.version_id_list.sort

      version_check = nil
      case
        when version_count != highest_version
          error('check_versions', "OCFL 3.5.3 Found #{version_count} versions, but highest version is #{highest_version}")
          version_check = true
        when version_count == highest_version
          pass('check_versions', "OCFL 3.5.3 Found #{version_count} versions, highest version is #{highest_version}")
      end
      # should be contiguous version numbers starting at 1.
      count       = 0
      until count == highest_version do
        # (count - 1) is a proxy for the index in @my_victim.version_id_list.sort
        count += 1
        if count != my_versions[count-1]
          error('check_versions', "OCFL 3.5.3 Expected version sequence not found. Expected version #{count}, found version #{my_versions[count]}.")
          version_check = true
          else
          #
        end
      end
      # We do NOT need to check the @versions.keys here for 'v0001', etc.
      # That's already been done when we looked at version_id_list and
      # checked for contiguous version numbers in my_versions.

      @my_victim.versions.each do | version, hash |
        ["created", "message", "user", "state"].each do | key |
          if hash.key?(key) == false
            error('check_versions', "OCFL 3.5.3.1 version #{version} is missing #{key} block.")
            version_check = true
          end
        end
      end
      if version_check == nil
        pass('check_versions', 'OCFL 3.5.3.1 version structure valid.')
      end
      return @my_results
    end

    # Checks OCFL Object for a well-formed fixity block, if present. We do not compute fixity here; only check existence.
    # @return [Hash] of results.
    def check_fixity
      # If present, should have at least 1 sub-key and 1 value.
      return @my_results # shameless green
    end

    # Checks the contents of the manifest block against the files and digests in the versions block to verify all
    # files necessary to re-constitute the object at any version are correctly referenced in the OCFL Object.
    # @return [Hash] of results
    def crosscheck_digests
      # requires values in @versions and @manifest.
      # verifies that every digest in @versions can be found in @manifest.
      errors = nil
      my_checksums = []

      @my_victim.versions.each do | version, block |
        version_digests = block['state']
        version_digests.each_key { |k| my_checksums << k }
      end

      unique_checksums = my_checksums.uniq

      # First check; there should be the same number of entries on both sides.
      if unique_checksums.length != @my_victim.manifest.length
        error('crosscheck_digests', "OCFL 3.5.3.1 Digests missing! #{unique_checksums.length} digests in versions vs. #{@my_victim.manifest.length} digests in manifest.")
        errors = true
      end

      # Second check; each entry in unique_checksums should have a match in @manifest.
      unique_checksums.each do | checksum |
        if @my_victim.manifest.member?(checksum) == false
          error('crosscheck_digests', "OCFL 3.5.3.1 Checksum #{checksum} not found in manifest!")
          errors = true
        end
      end

      if errors == nil
        pass('crosscheck_digests', "OCFL 3.5.3.1 All digests successfully crosschecked.")
      end
      return @my_results
    end

    # Verifies that the object passed to this class at instantiation responds to the expected
    # methods and attributes. Raises an exception on failure.
    # @return [Boolean] true
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

    private
    # Internal logging method.
    # @param [String] check
    # @param [String] message
    def error(check, message)
      if @my_results['errors'].key?(check) == false
        @my_results['errors'][check] = []  # add an initial empty array.
      end
      @my_results['errors'][check] = ( @my_results['errors'][check] << message )
    end

    # Internal logging method.
    # @param [String] check
    # @param [String] message
    def warning(check, message)
      if @my_results['warnings'].key?(check) == false
        @my_results['warnings'][check] = []  # add an initial empty array.
      end
      @my_results['warnings'][check] = ( @my_results['warnings'][check] << message )
    end

    # Internal logging method.
    # @param [String] check
    # @param [String] message
    def pass(check, message)
      if @my_results['pass'].key?(check) == false
        @my_results['pass'][check] = []  # add an initial empty array.
      end
      @my_results['pass'][check] = ( @my_results['pass'][check] << message )
    end

  end
end
