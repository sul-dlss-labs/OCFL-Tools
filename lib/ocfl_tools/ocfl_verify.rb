# frozen_string_literal: true

module OcflTools
  # Class to verify that an instance of {OcflTools::OcflObject} or {OcflTools::OcflInventory} is composed of valid data and structures.
  class OcflVerify # < OcflTools::OcflObject
    # @return {OcflTools::OcflResults} containing check results.
    attr_reader :my_results

    # Create a new OCFLVerify object, using an OcflTools::Ocflobject as source.
    # @param {OcflTools::OcflObject} ocfl_object an ocfl object or inventory to verify.
    def initialize(ocfl_object)
      @my_victim = ocfl_object
      @my_results = OcflTools::OcflResults.new

      # check .respond_to? first for all expected methods.
      preflight
    end

    # @return {OcflTools::OcflResults} containing information about actions taken
    # against this object.
    def results
      @my_results
    end

    # Performs all checks on the given object and reports results.
    # @return {Ocfltools::OcflResults} of results.
    def check_all
      # Duck-typing the heck out of this, assuming @my_victim will respond to ocflobject methods.
      check_id
      check_type
      check_head
      check_fixity
      check_manifest
      check_versions
      crosscheck_digests
      check_digestAlgorithm
      @my_results
    end

    # Checks OCFL Object for valid value in the id attribute.
    # Id value MUST be present and SHOULD be a URI.
    # @return {Ocfltools::OcflResults} of results.
    def check_id
      case @my_victim.id
        when nil
          @my_results.error('E202', 'check_id', 'OCFL 3.5.1 Object ID cannot be nil')
        when 0
          @my_results.error('E201', 'check_id', 'OCFL 3.5.1 Object ID cannot be 0 length')
        when !String
          @my_results.error('E201', 'check_id', 'OCFL 3.5.1 Object ID must be a string.')
        when /\S+:\S+/ # Hacky? check for URI pattern matching.
          if check_for_uri(@my_victim.id) == false
              @my_results.warn('W201', 'check_id', 'OCFL 3.5.1 Inventory ID present, but does not appear to be a URI.')
            else
              @my_results.ok('O200', 'check_id', 'OCFL 3.5.1 Inventory ID is OK.')
          end
        else
          @my_results.warn('W201', 'check_id', 'OCFL 3.5.1 Inventory ID present, but does not appear to be a URI.')
      end
      @my_results
    end

    # Checks OCFL Object for valid value in the head attribute.
    # @return {Ocfltools::OcflResults} of results.
    def check_head
      case @my_victim.head
      when nil
        @my_results.error('E212', 'check_head', 'OCFL 3.5.1 @head cannot be nil')
      when Integer
        @my_results.error('E213', 'check_head', 'OCFL 3.5.1 @head cannot be an Integer')
      when String
        version = OcflTools::Utils.version_string_to_int(@my_victim.head)
        target_version = @my_victim.version_id_list.max
        if version == target_version
          @my_results.ok('O200', 'check_head', 'OCFL 3.5.1 Inventory Head is OK.')
          @my_results.info('I200', 'check_head', "OCFL 3.5.1 Inventory Head version #{version} matches highest version in versions.")
        else
          @my_results.error('E214', 'check_head', "OCFL 3.5.1 Inventory Head version #{version} does not match expected version #{target_version}")
        end
      else
        # default case error
        @my_results.error('E911', 'check_head', 'An unknown error has occurred.')
      end
      @my_results
    end

    # Checks OCFL Object for valid value in the type attribute.
    # @return {Ocfltools::OcflResults} of results.
    def check_type
      case @my_victim.type
      when nil
        @my_results.error('E230', 'check_type', 'OCFL 3.5.1 Required OCFL key type not found.')
      when 'https://ocfl.io/1.0/spec/#inventory'
        @my_results.ok('O200', 'check_type', 'OCFL 3.5.1 Inventory Type is OK.')
      else
        @my_results.error('E231', 'check_type', 'OCFL 3.5.1 Required OCFL key type does not match expected value.')
      end
      @my_results
    end

    # Checks OCFL Object for valid value in the digestAlgorithm attribute.
    # @return {Ocfltools::OcflResults} of results.
    def check_digestAlgorithm
      # If there's no digestAlgorithm set in the inventory, that's a showstopper.
      if @my_victim.digestAlgorithm == nil
        @my_results.error('E222', 'check_digestAlgorithm', "Algorithm cannot be nil")
        return @my_results
      end

      # must be one of sha256 or sha512
      if @my_victim.digestAlgorithm.downcase == 'sha256'
        @my_results.ok('O200', 'check_digestAlgorithm', 'OCFL 3.5.1 Inventory Algorithm is OK.')
        @my_results.info('I220', 'check_digestAlgorithm', "OCFL 3.5.1 #{@my_victim.digestAlgorithm.downcase} is a supported digest algorithm.")
        @my_results.warn('W220', 'check_digestAlgorithm', "OCFL 3.5.1 #{@my_victim.digestAlgorithm.downcase} SHOULD be Sha512.")
      elsif @my_victim.digestAlgorithm.downcase == 'sha512'
        @my_results.ok('O200', 'check_digestAlgorithm', 'OCFL 3.5.1 Inventory Algorithm is OK.')
        @my_results.info('I220', 'check_digestAlgorithm', "OCFL 3.5.1 #{@my_victim.digestAlgorithm.downcase} is a supported digest algorithm.")
      else
        @my_results.error('E223', 'check_digestAlgorithm', "OCFL 3.5.1 Algorithm #{@my_victim.digestAlgorithm} is not valid for OCFL use.")
      end
      @my_results
    end

    # Checks OCFL Object for a well-formed manifest block.
    # @return {Ocfltools::OcflResults} of results.
    def check_manifest
      # Should pass digest cross_check.
      # can be null if it passes cross_check? (empty inventories are valid, but warn)
      # There MUST be a block called 'manifests'
      errors = nil
      if @my_victim.manifest.nil?
        @my_results.error('E250', 'check_manifest', 'OCFL 3.5.2 there MUST be a manifest block.')
        errors = true
      elsif @my_victim.manifest == {}
        @my_results.error('E251', 'check_manifest', 'OCFL 3.5.2 manifest block cannot be empty.')
        errors = true
      end

      # TODO: Should check that it's a hash of digests and filepaths somehow...?
      # Get digest Algo type, use that to get key length.
      # check all keys in manifest to make sure they're all that length.

      if errors.nil?
        @my_results.ok('O200', 'check_manifest', 'OCFL 3.5.2 Inventory Manifest syntax is OK.')
      end

      @my_results
    end

    # Checks OCFL Object for a well-formed versions block.
    # @return {Ocfltools::OcflResults} of results.
    def check_versions
      version_count   = @my_victim.version_id_list.length
      highest_version = @my_victim.version_id_list.max
      my_versions     = @my_victim.version_id_list.sort

      @version_check = nil
      if version_count != highest_version
        @my_results.error('E014', 'check_versions', "OCFL 3.5.3 Found #{version_count} versions, but highest version is #{highest_version}")
        @version_check = true
      elsif version_count == highest_version
        @my_results.ok('O200', 'check_versions', "OCFL 3.5.3 Found #{version_count} versions, highest version is #{highest_version}")
      end
      # should be contiguous version numbers starting at 1.
      count = 0
      until count == highest_version
        # (count - 1) is a proxy for the index in @my_victim.version_id_list.sort
        count += 1
        if count != my_versions[count - 1]
          @my_results.error('E015', 'check_versions', "OCFL 3.5.3 Expected version sequence not found. Expected version #{count}, found version #{my_versions[count]}.")
          @version_check = true
        end
      end
      # We do NOT need to check the @versions.keys here for 'v0001', etc.
      # That's already been done when we looked at version_id_list and
      # checked for contiguous version numbers in my_versions.

      @my_victim.versions.each do |version, hash|
        %w[created message user state].each do |key|
          if hash.key?(key) == false
            @my_results.error('E016', 'check_versions', "OCFL 3.5.3.1 version #{version} is missing #{key} block.")
            @version_check = true
            next
          end # key is present, does it conform?

          case key
            when 'created'
              check_version_created(hash['created'], version)
            when 'user'
              check_version_user(hash['user'], version)
            when 'state'
              check_version_state(hash['state'], version)
            when 'message'
              check_version_message(hash['message'], version)
            else
              @my_results.error('E111', 'check_versions', "OCFL 3.5.3.1 version #{version} contains unknown key #{key} block.")
              @version_check = true
          end
        end
      end

      if @version_check.nil?
        @my_results.ok('O200', 'check_versions', 'OCFL 3.5.3.1 version syntax is OK.')
      end
      @my_results
    end

    # Checks OCFL Object for a well-formed fixity block, if present. We do not compute fixity here; only check existence.
    # @return {Ocfltools::OcflResults} of results.
    def check_fixity
      # If present, should have at least 1 sub-key and 1 value.
      errors = nil
      unless @my_victim.fixity.empty?
        @my_results.info('I111', 'check_fixity', 'Fixity block is present.')
      end
      # Set OcflTools.config.fixity_algorithms for what to look for.
      @my_victim.fixity.each do |algorithm, _digest|
        unless OcflTools.config.fixity_algorithms.include? algorithm
          @my_results.error('E111', 'check_fixity', "Fixity block contains unsupported algorithm #{algorithm}")
          errors = true
        end
      end

      if errors.nil? && !@my_victim.fixity.empty?
        @my_results.ok('O111', 'check_fixity', 'Fixity block is present and contains valid algorithms.')
      end

      @my_results
    end

    # Checks the contents of the manifest block against the files and digests in the versions block to verify all
    # files necessary to re-constitute the object at any version are correctly referenced in the OCFL Object.
    # @return {Ocfltools::OcflResults} of results.
    def crosscheck_digests
      # requires values in @versions and @manifest.
      # verifies that every digest in @versions can be found in @manifest.
      errors = nil
      my_checksums = []

      @my_victim.versions.each do |version, block|
        if !block.is_a?(Hash)
          @my_results.error('E111', 'crosscheck_digests', "version #{version} block is wrong type.")
          next
        end
        version_digests = block['state']
        if !version_digests.is_a?(Hash)
          @my_results.error('E111', 'crosscheck_digests', "version #{version} state block is wrong type.")
          next
        end
        version_digests.each_key { |k| my_checksums << k }
      end

      unique_checksums = my_checksums.uniq

      # First check; there should be the same number of entries on both sides.
      if unique_checksums.length != @my_victim.manifest.length
        @my_results.error('E050', 'crosscheck_digests', "OCFL 3.5.3.1 Digests missing! #{unique_checksums.length} digests in versions vs. #{@my_victim.manifest.length} digests in manifest.")
        errors = true
      end

      # Second check; each entry in unique_checksums should have a match in @manifest.
      unique_checksums.each do |checksum|
        if @my_victim.manifest.member?(checksum) == false
          @my_results.error('E051', 'crosscheck_digests', "OCFL 3.5.3.1 Checksum #{checksum} not found in manifest!")
          errors = true
        end
      end

      if errors.nil?
        @my_results.ok('O200', 'crosscheck_digests', 'OCFL 3.5.3.1 Digests are OK.')
      end
      @my_results
    end

    # Verifies that the object passed to this class at instantiation responds to the expected
    # methods and attributes. Raises an exception on failure.
    # @return [Boolean] true
    def preflight
      # check for expected instance_variables with .instance_variable_defined?(@some_var)
      ['@id', '@head', '@type', '@digestAlgorithm', '@contentDirectory', '@manifest', '@versions', '@fixity'].each do |var|
        unless @my_victim.instance_variable_defined?(var)
          raise "Object does not have instance var #{var} defined"
        end
      end

      # check for all methods we need to validate OCFL structure
      %w[get_files get_current_files get_state version_id_list get_digest].each do |mthd|
        unless @my_victim.respond_to?(mthd)
          raise "Object does not respond to #{mthd}"
        end
      end
    end

    private

    def check_version_message(value, version)
      # version.message must be a String.
      if !value.is_a?(String)
        @my_results.error('E111', 'check_version', "Value in version #{version} message block is wrong type.")
        @version_check = true
        return # No point in processing further.
      end
      # version.message is valid!
    end

    # 'user'.'name' must contain a string value.
    # 'user'.'address' should contain value
    def check_version_user(value, version)
      # 'user' must be a hash.
      if !value.is_a?(Hash)
        @my_results.error('E111', 'check_version', "Value in version #{version} user block is wrong type.")
        @version_check = true
        return # No point in processing further.
      end

      # 'user' must contain 'name'
      # 'user' must contain 'address'
      value.each do |user_key, user_value|
        case user_key
          when 'name'
            # user_name must be String.
            if !user_value.is_a?(String)
              @my_results.error('E111', 'check_version', "Value in version #{version} user name block is not a String.")
              @version_check = true
              next
            end
            # user_name must have content.
            if user_value.empty?
              @my_results.error('E111', 'check_version', "Value in version #{version} user name block cannot be empty.")
              @version_check = true
            end
            # user.name is valid!
          when 'address'
            # user_address must be String.
            if !user_value.is_a?(String)
              @my_results.error('E111', 'check_version', "Value in version #{version} user address block is not a String.")
              @version_check = true
              next
            end
            # user_address SHOULD have content.
            if user_value.empty?
              @my_results.warn('W111', 'check_version', "Value in version #{version} user address block SHOULD NOT be empty.")
              next
            end
            # user.address should be either mailto: or URI.
            if check_for_mailto(user_value) == true
              next # It's a mailto:, we don't need to process further.
            end

            if check_for_uri(user_value) == true
              next # It's a URI, don't need to process further.
            end
            # If we get to here, it wasn't a mailto or a URI.
            @my_results.error('E111', 'check_version', "Value in #{version} #{user_value} is not a valid URI or mailto: format.")
            @version_check = true

          else           # unexpected value in user block.
            @my_results.error('E111', 'check_version', "Unexpected value in version #{version} user block #{user_key}.")
            @version_check = true
          end

      end
      # user block is valid!
    end

    # used by user.address validation. RFC6068.
    def check_for_mailto(value)
      # For now, very simple regex.
      if value =~ /^mailto:*/
        return true
      else
        return false
      end
    end

    # used by check_id and user.address validation. RFC3986.
    def check_for_uri(value)
      if value =~ /\w+:(\/?\/?)[^\s]+/
        # very crappy check for URI.
        return true # emits OK result.
      else
        # if it doesn't pass the check, it's a problem.
        return false
      end
    end

    # 'state' must be a hash.
    # 'state' must contain at least 1 key/value pair
    def check_version_state(value, version)
      if !value.is_a?(Hash)
        @my_results.error('E111', 'check_version', "Value in version #{version} state block is wrong type.")
        @version_check = true
        return # No point in processing further.
      end
      # State hash must have content.
      if value.empty?
        @my_results.error('E111', 'check_version', "Version #{version} state block is empty.")
        @version_check = true
        return # No point in processing further.
      end
      # State block is valid!
    end

    # 'created' block must be a String.
    # 'created' must contain ISO8601 value.
    def check_version_created(value, version)
      if !value.is_a?(String)
        @my_results.error('E111', 'check_version', "Value in version #{version} created address block is not a String.")
        @version_check = true
        return
      end
      # 'created' cannot be empty.
      if value.empty?
        @my_results.error('E111', 'check_version', "Version #{version} created block is empty.")
        @version_check = true
        return # No point in processing further.
      end

      #  This throws an exception if 'value' isn't a String in iso8601 notation.
      begin
        Time.iso8601(value)
      rescue ArgumentError => e
        @my_results.error('E111', 'check_version', "Version #{version} created block contains #{e}.")
        @version_check = true
        return
      end
      # Created block is valid!
    end
  end
end
