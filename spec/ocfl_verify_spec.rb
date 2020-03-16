# frozen_string_literal: true

require 'ocfl-tools'

describe OcflTools::OcflVerify do
  OcflTools.config.content_directory = 'data'

  describe 'verifies object A' do
    ocfl = OcflTools::OcflInventory.new
    object_root_dir = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', 'object_a')
    ocfl.from_file("#{object_root_dir}/inventory.json")

    verify = OcflTools::OcflVerify.new(ocfl)

    it 'returns a verify object' do
      expect(verify).to be_instance_of(OcflTools::OcflVerify)
    end

    results = verify.check_all

    it 'expects to get a results object' do
      expect(verify.check_all).to be_instance_of(OcflTools::OcflResults)

      expect(results.results).to match(
        {"error"=>{"E111"=>{"check_version"=>["Version v0001 created block is empty.", "Value in version v0001 user name block cannot be empty.", "Version v0002 created block is empty.", "Value in version v0002 user name block cannot be empty.", "Version v0003 created block is empty.", "Value in version v0003 user name block cannot be empty."]}}, "warn"=>{"W201"=>{"check_id"=>["OCFL 3.5.1 Inventory ID present, but does not appear to be a URI."]}, "W111"=>{"check_version"=>["Value in version v0001 user address block SHOULD NOT be empty.", "Value in version v0002 user address block SHOULD NOT be empty.", "Value in version v0003 user address block SHOULD NOT be empty."]}, "W220"=>{"check_digestAlgorithm"=>["OCFL 3.5.1 sha256 SHOULD be Sha512."]}}, "info"=>{"I200"=>{"check_head"=>["OCFL 3.5.1 Inventory Head version 3 matches highest version in versions."]}, "I220"=>{"check_digestAlgorithm"=>["OCFL 3.5.1 sha256 is a supported digest algorithm."]}}, "ok"=>{"O200"=>{"check_type"=>["OCFL 3.5.1 Inventory Type is OK."], "check_head"=>["OCFL 3.5.1 Inventory Head is OK."], "check_manifest"=>["OCFL 3.5.2 Inventory Manifest syntax is OK."], "check_versions"=>["OCFL 3.5.3 Found 3 versions, highest version is 3"], "crosscheck_digests"=>["OCFL 3.5.3.1 Digests are OK."], "check_digestAlgorithm"=>["OCFL 3.5.1 Inventory Algorithm is OK."]}}}
      )
      # puts JSON.pretty_generate(results.results)
    end
  end

  describe 'finds problems with 01_bad_missing_created' do
  #  puts "Loading up 01_bad_missing_created here"
    ocfl2 = OcflTools::OcflInventory.new
    object_root_dir2 = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', '01_bad_missing_created')
    ocfl2.from_file("#{object_root_dir2}/inventory.json")

    verify2 = OcflTools::OcflVerify.new(ocfl2)

    it 'returns a verify object' do
      expect(verify2).to be_instance_of(OcflTools::OcflVerify)
    end

    results2 = verify2.check_all
  #  puts "I'm Outputting a bad boy here:"
  #  puts results2.results

  end

  # Bad101 is a modified of3 object, deliberately broken v4.
  describe 'checks bad101 for logical path content issues' do
    # There are 5 errors with this object, and they are all E260 syntax errors.
    bad101 = OcflTools::OcflInventory.new
    bad101_rootdir = File.join(File.dirname(__dir__), 'spec', 'fixtures', '1.0', 'bad-objects', 'bad101_content')
    bad101.from_file("#{bad101_rootdir}/inventory.json")

    verify_bad101 = OcflTools::OcflVerify.new(bad101)
    # puts verify_bad101.check_all.print
    it 'expects 5 problems' do
      expect(verify_bad101.check_all.error_count).to equal 5
    end

    bad101_errors = verify_bad101.check_all.get_errors

    # expects a single error code: E260
    it 'expects only 1 error code' do
      expect(bad101_errors).to include('E260')
      expect(bad101_errors.count).to equal 1
    end
  end

end
