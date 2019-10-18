module OcflTools

  class OcflInventory < OcflTools::OcflObject
    # create and manipulate an OCFL inventory file.

    def serialize
      # return serialized JSON of OCFL object at most recent version.
      output_hash = Hash.new

      output_hash['id']               = @id
      output_hash['head']             = @head
      output_hash['type']             = @type
      output_hash['digestAlgorithm']  = @digestAlgorithm
      output_hash['contentDirectory'] = @contentDirectory
      output_hash['manifest']         = @manifest
      output_hash['versions']         = @versions
      # optional
      output_hash['fixity']           = @fixity unless @fixity.size == 0

      raise "inventory failed validation!" unless self.sanity_check_inventory(output_hash) == true

      JSON.pretty_generate(output_hash)
    end

    def to_file(directory)
      # @param [String] resolvable directory to write inventory.json to.
      # Also needs to create inventory_digest file.
      inventory = File.new("#{directory}/inventory.json", "w+")
      inventory.syswrite(self.serialize)

      checksum = OcflTools::Utils.generate_file_digest(inventory.path, @digestAlgorithm)

      inventory_digest = File.new("#{inventory.path}.#{@digestAlgorithm}", "w+")
      inventory_digest.syswrite("#{checksum} inventory.json")
    end

    def read_json(file)
      # @param [String] resolvable path to alleged inventory.json.
      # @return [Hash] of JSON keys & values.
      JSON.parse(File.read(file))
    end

    def from_file(file)
      # @param [String] a file that should contain an inventory.json.
      import_hash = self.read_json(file)
      raise "inventory failed validation!" unless self.sanity_check_inventory(import_hash) == true
      # We passed validation, so let's assign our results to our instance variables.
      @id               = import_hash['id']
      @head             = import_hash['head']
      @type             = import_hash['type']
      @digestAlgorithm  = import_hash['digestAlgorithm']
      @contentDirectory = import_hash['contentDirectory']
      @manifest         = import_hash['manifest']
      @versions         = import_hash['versions']

      if import_hash.has_key?('fixity')
        @fixity = import_hash['fixity']
      end
      return self
    end

    def sanity_check_inventory(hash)
      # TODO: spin this out to a separate class (put it in Utils?)
      # @param [Hash] that is purportedly a complete OCFL object.
      # @return [Boolean] true or raises an exception, depending on result.
      # Sanity check import_hash for expected/required keys.
      # id, head, type, digestAlgorithm, contentDirectory, manifest, versions, [fixity]
      # check 1: hash should have 7 or 8 keys.
      if hash.length < 7
        raise "Proposed inventory contains #{hash.length} keys. 7 or 8 required."
      end

      if hash.length > 8
        raise "Proposed inventory contains #{hash.length} keys. 7 or 8 required."
      end

      # check 2: keys should be named id, head, type, digestAlgorithm, contentDirectory, manifest, versions, [fixity]

      # check 3: versions key should contain contiguous version blocks, starting at 1 to versions.length.

      # check 4: 'head' value should match highest value found in versions block.

      # check 5: crosscheck digests.
      self.crosscheck_digests
      # If we make it this far, all is well.
      return true
    end

    def crosscheck_digests
      # @return [Boolean] true if crosscheck is successful; else raises exception.
      # requires values in @versions and @manifest.
      # verifies that every digest in @versions can be found in @manifest.
      my_checksums = []
      @versions.each do | version, block |
        version_digests = block['state']
        version_digests.each_key { |k| my_checksums << k }
      end
      unique_checksums = my_checksums.uniq
      # First check; there should be the same number of entries on both sides.
      raise "We're missing digests!" unless unique_checksums.length == @manifest.length
      # Second check; each entry in unique_checksums should have a match in @manifest.
      unique_checksums.each do | checksum |
        raise "Checksum #{checksum} not found in manifest!" unless @manifest.member?(checksum)
      end
      return true
    end

  end
end
