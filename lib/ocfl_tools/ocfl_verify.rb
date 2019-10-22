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
      self.check_head
      self.check_versions
      self.crosscheck_digests
      self.check_digestAlgorithm

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

      case
        when @my_victim.id.length < 1
          self.error('check_id', 'Object ID cannot be 0 length')
          errors = true
        when @my_victim.id == nil
          self.error('check_id', 'Object ID cannot be nil')
          errors = true
        when @my_victim.id.length > 128
          self.error('check_id', 'Object ID cannot exceed 128 characters.') # Not actually a thing.
          errors = true
      end

      if errors == nil
        self.pass('check_id', 'all checks passed without errors')
      end
      return @my_results
    end

    def check_head
      case @my_victim.head
        when nil
          self.error('check_head', '@head cannot be nil')
        when Integer
          self.error('check_head', '@head cannot be an Integer')
        when String
          version        = OcflTools::Utils.version_string_to_int(@my_victim.head)
          target_version = @my_victim.version_id_list.sort[-1]
          if version == target_version
            self.pass('check_head', '@head matches highest version found')
          else
            self.error('check_head', "@head version #{version} does not match expected version #{target_version}")
          end
        else
          # default case error
          self.error('check_head', 'An unknown @head error has occured.')
      end
      return @my_results
    end

    def check_type
      # String should match spec URL? Shameless green.
      return @my_results
    end

    def check_digestAlgorithm
      # must be one of sha256 or sha512
      case
      when @my_victim.digestAlgorithm.downcase == 'sha256'
        self.pass('check_digestAlgorithm', "#{@my_victim.digestAlgorithm.downcase} is a supported digest algorithm.")
      when @my_victim.digestAlgorithm.downcase == 'sha512'
        self.pass('check_digestAlgorithm', "#{@my_victim.digestAlgorithm.downcase} is a supported digest algorithm.")
      else
        self.error('check_digestAlgorithm', "Algorithm #{@my_victim.digestAlgorithm} is not valid for OCFL use.")
      end
      return @my_results
    end

    def check_manifest
      # Should pass digest cross_check.
      # can be null if it passes cross_check? (empty inventories are valid, but warn)
      return @my_results # shameless green
    end

    def check_versions

      version_count   = @my_victim.version_id_list.length
      highest_version = @my_victim.version_id_list.sort[-1]
      my_versions = @my_victim.version_id_list.sort

      case
        when version_count != highest_version
          self.error('check_versions', "Found #{version_count} versions, but highest version is #{highest_version}")
        when version_count == highest_version
          self.pass('check_versions', "Found #{version_count} versions, highest version is #{highest_version}")
      end
      # should be contiguous version numbers starting at 1.
      count       = 0
      until count == highest_version do
        # (count - 1) is a proxy for the index in @my_victim.version_id_list.sort
        count += 1
        if count != my_versions[count-1]
          self.error('check_versions', "Expected version sequence not found. Expected version #{count}, found version #{my_versions[count]}.")
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
            self.error('check_versions', "version #{version} is missing #{key} block.")
          end
        end
      end
      return @my_results
    end

    def check_fixity
      # If present, should have at least 1 sub-key and 1 value.
      return @my_results # shameless green
    end

    def check_disk(object_directory=@object_directory)
      # If you give me an actual physical path, we can verify digests and files on disk.
      return @my_results
    end

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
        self.error('crosscheck_digests', "Digests missing! #{unique_checksums.length} digests in versions vs. #{@my_victim.manifest.length} digests in manifest.")
        errors = true
      end

      # Second check; each entry in unique_checksums should have a match in @manifest.
      unique_checksums.each do | checksum |
        if @my_victim.manifest.member?(checksum) == false
          self.error('crosscheck_digests', "Checksum #{checksum} not found in manifest!")
          errors = true
        end
      end

      if errors == nil
        self.pass('crosscheck_digests', "All digests successfully crosschecked.")
      end
      return @my_results
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
