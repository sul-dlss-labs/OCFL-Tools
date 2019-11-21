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
    # puts results.results

    it 'expects to get a results object' do
      expect(verify.check_all).to be_instance_of(OcflTools::OcflResults)
      expect(results.results).to match(
        'error' => {}, 'warn' => { 'W220' => { 'check_digestAlgorithm' => ['OCFL 3.5.1 sha256 SHOULD be Sha512.'] } }, 'info' => { 'I200' => { 'check_head' => ['OCFL 3.5.1 Inventory Head version 3 matches highest version in versions.'] }, 'I220' => { 'check_digestAlgorithm' => ['OCFL 3.5.1 sha256 is a supported digest algorithm.'] } }, 'ok' => { 'O200' => { 'check_id' => ['OCFL 3.5.1 Inventory ID is OK.'], 'check_type' => ['OCFL 3.5.1 Inventory Type is OK.'], 'check_head' => ['OCFL 3.5.1 Inventory Head is OK.'], 'check_manifest' => ['OCFL 3.5.2 Inventory Manifest syntax is OK.'], 'check_versions' => ['OCFL 3.5.3.1 version syntax is OK.'], 'crosscheck_digests' => ['OCFL 3.5.3.1 Digests are OK.'], 'check_digestAlgorithm' => ['OCFL 3.5.1 Inventory Algorithm is OK.'] }, 'I200' => { 'check_versions' => ['OCFL 3.5.3 Found 3 versions, highest version is 3'] } }
      )
      # puts JSON.pretty_generate(results.results)
    end
  end
end
