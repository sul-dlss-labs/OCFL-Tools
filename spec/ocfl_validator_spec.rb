# frozen_string_literal: true

require 'ocfl-tools'
require 'digest'

describe OcflTools::OcflValidator do
  basedir = Dir.pwd

  # resolve our path to test fixtures to a full system path
  object_a = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', 'object_a')
  # puts "Object a is at: #{object_a}"
  validate = OcflTools::OcflValidator.new(object_a)
  OcflTools.config.content_directory = 'data'

  describe '.new' do
    # shameless green
    it 'returns an OcflValidator' do
      expect(validate).to be_instance_of(OcflTools::OcflValidator)
    end
  end

  describe 'well-formed object A' do
    it 'verifies the structure' do
      validate.verify_structure
      expect(validate.results.all).to match(
        'error' => {}, 'warn' => { 'W111' => { 'verify_structure' => ['OCFL 3.1 optional logs directory found in object root.'] } }, 'info' => {}, 'ok' => { 'O111' => { 'version_format' => ['OCFL conforming first version directory found.'], 'verify_structure' => ['OCFL 3.1 Object root passed file structure test.'] } }
      )
    end

    it 'checks the root inventory' do
      expect(validate.verify_inventory.results).to match(
        'error' => {}, 'warn' => { 'W220' => { 'check_digestAlgorithm' => ['OCFL 3.5.1 sha256 SHOULD be Sha512.'] } }, 'info' => { 'I200' => { 'check_head' => ['OCFL 3.5.1 Inventory Head version 3 matches highest version in versions.'] }, 'I220' => { 'check_digestAlgorithm' => ['OCFL 3.5.1 sha256 is a supported digest algorithm.'] } }, 'ok' => { 'O200' => { 'check_id' => ['OCFL 3.5.1 Inventory ID is OK.'], 'check_type' => ['OCFL 3.5.1 Inventory Type is OK.'], 'check_head' => ['OCFL 3.5.1 Inventory Head is OK.'], 'check_manifest' => ['OCFL 3.5.2 Inventory Manifest syntax is OK.'], 'check_versions' => ['OCFL 3.5.3.1 version syntax is OK.'], 'crosscheck_digests' => ['OCFL 3.5.3.1 Digests are OK.'], 'check_digestAlgorithm' => ['OCFL 3.5.1 Inventory Algorithm is OK.'] }, 'I200' => { 'check_versions' => ['OCFL 3.5.3 Found 3 versions, highest version is 3'] } }
      )
    end

    it 'checks checksums from manifest' do
      validate.verify_checksums
    end

    it 'tries to validate only version 2 files against the inventory' do
      expect(validate.verify_directory(2).results).to match(
        'error' => {}, 'warn' => { 'W111' => { 'verify_structure' => ['OCFL 3.1 optional logs directory found in object root.'] } }, 'info' => {}, 'ok' => { 'O111' => { 'version_format' => ['OCFL conforming first version directory found.'], 'verify_structure' => ['OCFL 3.1 Object root passed file structure test.'], 'verify_checksums' => ['All discovered files on disk are referenced in inventory.', 'All discovered files on disk match stored digest values.'], 'verify_directory v0002' => ['All discovered files on disk are referenced in inventory.', 'All discovered files on disk match stored digest values.'] } }
      )
    end
  end

  describe 'version_format' do
    it 'returns the correct version format' do
      expect(validate.version_format).to match('v%04d')
    end
  end

  # object_b has a directory called 'v' in it
  object_b = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', 'object_b')
  # puts "Object b is at: #{object_b}"
  validate_b = OcflTools::OcflValidator.new(object_b)

  describe 'Object B is not compliant' do
    it "finds an additional directory 'v' in object root" do
      validate_b.verify_structure
      expect(validate_b.results.all).to match(
        'error' => { 'E100' => { 'verify_structure' => ['Object root contains noncompliant directories: ["v"]'] } }, 'warn' => { 'W111' => { 'verify_structure' => ['OCFL 3.1 optional logs directory found in object root.'] } }, 'info' => {}, 'ok' => { 'O111' => { 'version_format' => ['OCFL conforming first version directory found.'] } }
      )
    end
  end

  # Object_c has version dirs 1, 3 and 4, but not 2.
  object_c = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', 'object_c')
  # puts "Object c is at: #{object_c}"
  validate_c = OcflTools::OcflValidator.new(object_c)

  describe 'Object C is not compliant' do
    it 'is missing an expected version directory' do
      validate_c.verify_structure
      expect(validate_c.results.all).to match(
        'error' => { 'E013' => { 'verify_structure' => ['Expected version directory v0002 missing from directory list ["v0001", "v0003", "v0004"] '] }, 'E111' => { 'verify_structure' => ['Inventory file expects a highest version of v0003 but directory list contains ["v0001", "v0003", "v0004"] '] } }, 'warn' => { 'W111' => { 'verify_structure' => ['OCFL 3.1 optional logs directory found in object root.'] } }, 'info' => {}, 'ok' => { 'O111' => { 'version_format' => ['OCFL conforming first version directory found.'] } }
      )
    end

    it 'tries to validate only version 2 files against the inventory' do
      expect { validate_c.verify_directory(2).results }.to raise_error(RuntimeError)
    end
  end

  # Object_h has no inventory files in the version directories.
  object_h = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', 'object_h')
  # puts "Object h is at: #{object_h}"
  validate_h = OcflTools::OcflValidator.new(object_h)

  describe 'Object H is compliant with warnings' do
    it 'is missing inventory files in version directories' do
      validate_h.verify_structure
      expect(validate_h.results.all).to match(
        'error' => {}, 'warn' => { 'W111' => { 'verify_structure' => ['OCFL 3.1 optional logs directory found in object root.', 'OCFL 3.1 optional inventory.json missing from v0001 directory', 'OCFL 3.1 optional inventory.json.sha512 missing from v0001 directory', 'OCFL 3.1 optional inventory.json missing from v0002 directory', 'OCFL 3.1 optional inventory.json.sha512 missing from v0002 directory', 'OCFL 3.1 optional inventory.json missing from v0003 directory', 'OCFL 3.1 optional inventory.json.sha512 missing from v0003 directory'] } }, 'info' => {}, 'ok' => { 'O111' => { 'version_format' => ['OCFL conforming first version directory found.'], 'verify_structure' => ['OCFL 3.1 Object root passed file structure test.'] } }
      )
    end

    it 'tries to validate only version 2 files against the inventory' do
      expect(validate_h.verify_directory(2).results).to match(
        'error' => {}, 'warn' => { 'W111' => { 'verify_structure' => ['OCFL 3.1 optional logs directory found in object root.', 'OCFL 3.1 optional inventory.json missing from v0001 directory', 'OCFL 3.1 optional inventory.json.sha512 missing from v0001 directory', 'OCFL 3.1 optional inventory.json missing from v0002 directory', 'OCFL 3.1 optional inventory.json.sha512 missing from v0002 directory', 'OCFL 3.1 optional inventory.json missing from v0003 directory', 'OCFL 3.1 optional inventory.json.sha512 missing from v0003 directory'] } }, 'info' => {}, 'ok' => { 'O111' => { 'version_format' => ['OCFL conforming first version directory found.'], 'verify_structure' => ['OCFL 3.1 Object root passed file structure test.'], 'verify_directory v0002' => ['All discovered files on disk are referenced in inventory.', 'All discovered files on disk match stored digest values.'] } }
      )
    end
  end

  # Back to A!
  object_a = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', 'object_a')
  # puts "Object a is at: #{object_a}"
  validate_a = OcflTools::OcflValidator.new(object_a)
  OcflTools.config.content_directory = 'data'

  describe 'check results' do
    validate_a.validate_ocfl_object_root.results

    it 'expects results.warn to be 2' do
      expect(validate_a.results.warn_count).to eq 2
    end

    it 'expects results.error to be 0' do
      expect(validate_a.results.error_count).to eq 0
    end

    it 'expects results.info to be 2' do
      expect(validate_a.results.info_count).to eq 2
    end

    it 'expects results.ok to be 12' do
      expect(validate_a.results.ok_count).to eq 12
    end
  end

  # Fixity!
  # Object i has a fixity block.
  # Dracula has md5
  # Poe has md5 and sha1
  # Dickens has no fixity value.
  object_i = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', 'object_i')
  validate_i = OcflTools::OcflValidator.new(object_i)

  describe 'check fixity' do
    it 'checks fixity using default md5' do
      expect(validate_i.verify_fixity.results).to match(
        'error' => {}, 'warn' => { 'W111' => { 'verify_fixity md5' => ['1 files in manifest are missing from fixity block.'] } }, 'info' => {}, 'ok' => { 'O111' => { 'verify_fixity md5' => ['All discovered files on disk are referenced in inventory.', 'All discovered files on disk match stored digest values.'] } }
      )
    end

    validate_i_sha1 = OcflTools::OcflValidator.new(object_i)

    it 'checks fixity using sha1' do
      expect(validate_i_sha1.verify_fixity(digest: 'sha1').results).to match(
        'error' => {}, 'warn' => { 'W111' => { 'verify_fixity sha1' => ['2 files in manifest are missing from fixity block.'] } }, 'info' => {}, 'ok' => { 'O111' => { 'verify_fixity sha1' => ['All discovered files on disk are referenced in inventory.', 'All discovered files on disk match stored digest values.'] } }
      )
    end

    validate_i_bad = OcflTools::OcflValidator.new(object_i)

    it 'tries to check using an algorithm not present in the fixity block' do
      expect(validate_i_bad.verify_fixity(digest: 'sha999').results).to match(
        'error' => { 'E111' => { 'verify_fixity sha999' => ['Requested algorithm sha999 not found in fixity block.'] } }, 'warn' => {}, 'info' => {}, 'ok' => {}
      )
    end

    validate_i_all = OcflTools::OcflValidator.new(object_i)

    it 'validates the entire object using the fixity block instead of manifest checksums' do
      expect(validate_i_all.validate_ocfl_object_root(digest: 'md5').results).to match(
        'error' => {}, 'warn' => { 'W111' => { 'verify_structure' => ['OCFL 3.1 optional logs directory found in object root.'], 'verify_fixity md5' => ['1 files in manifest are missing from fixity block.'] }, 'W220' => { 'check_digestAlgorithm' => ['OCFL 3.5.1 sha256 SHOULD be Sha512.'] } }, 'info' => { 'I200' => { 'check_head' => ['OCFL 3.5.1 Inventory Head version 3 matches highest version in versions.'] }, 'I111' => { 'check_fixity' => ['Fixity block is present.'] }, 'I220' => { 'check_digestAlgorithm' => ['OCFL 3.5.1 sha256 is a supported digest algorithm.'] } }, 'ok' => { 'O111' => { 'version_format' => ['OCFL conforming first version directory found.'], 'verify_structure' => ['OCFL 3.1 Object root passed file structure test.'], 'verify_fixity md5' => ['All discovered files on disk are referenced in inventory.', 'All discovered files on disk match stored digest values.'], 'check_fixity' => ['Fixity block is present and contains valid algorithms.'] }, 'O200' => { 'check_id' => ['OCFL 3.5.1 Inventory ID is OK.'], 'check_type' => ['OCFL 3.5.1 Inventory Type is OK.'], 'check_head' => ['OCFL 3.5.1 Inventory Head is OK.'], 'check_manifest' => ['OCFL 3.5.2 Inventory Manifest syntax is OK.'], 'check_versions' => ['OCFL 3.5.3.1 version syntax is OK.'], 'crosscheck_digests' => ['OCFL 3.5.3.1 Digests are OK.'], 'check_digestAlgorithm' => ['OCFL 3.5.1 Inventory Algorithm is OK.'] }, 'I200' => { 'check_versions' => ['OCFL 3.5.3 Found 3 versions, highest version is 3'] } }
      )
    end
  end

  object_i2 = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', 'object_i')
  validate_i2 = OcflTools::OcflValidator.new(object_i2)
  validate_i2.ocfl_version = '1.5'

  # NamAsTe checks; verify we alert if there's a version mismatch.
  # object i2 is an OCFLv1 object.
  describe 'Namaste file is incorrect version' do

    validate_i2.validate_ocfl_object_root.results
    it 'expects 1 specific error in verify_structure' do
      expect(validate_i2.results.error_count).to eq 1
      expect(validate_i2.results.get_errors).to match(
        {"E107"=>{"verify_structure"=>["Required NamAsTe file in object root is for unexpected OCFL version: 0=ocfl_object_1.0"]}}
      )
    end
  end



  # Namaste file issues, part 1: Nothing in Namaste file.
  object_j = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', 'object_j')
  validate_j = OcflTools::OcflValidator.new(object_j)
  describe 'Namaste file exists but is empty' do
    validate_j.validate_ocfl_object_root.results
    it 'expects 1 specific error in verify_structure' do
      expect(validate_j.results.error_count).to eq 1
      expect(validate_j.results.get_errors).to match(
        "E105" => {"verify_structure"=>["Required NamAsTe file in object root directory has no content!"]}
      )
    end
  end

  # Namaste file issues, part 2: Garbge in Namaste file.
  object_k = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', 'object_k')
  validate_k = OcflTools::OcflValidator.new(object_k)
  describe 'Namaste file exists but contains garbage' do
    validate_k.validate_ocfl_object_root.results
    it 'expects 1 specific error in verify_structure' do
      expect(validate_k.results.error_count).to eq 1
      expect(validate_k.results.get_errors).to match(
        {"E106"=>{"verify_structure"=>["Required NamAsTe file in object root directory does not contain expected string."]}}
      )
    end
  end

  # The Moab Question.
  # Object M is a copy of object A, but with a 'manifests' directory in content.
  # For now this is totally hacky, but eventually I'll reprocess Object A as a Moab
  # with correct contentDirectory and manifests directory contents.
  object_m = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', 'object_m')
  validate_m = OcflTools::OcflValidator.new(object_m)

  describe 'Ex-Moab object has a manifests directory' do
    validate_m.validate_ocfl_object_root.results
    it 'warns on manifests directory in version directory' do
      expect(validate_m.results.get_warnings).to include(
        "W101"=>{"version_structure"=>["OCFL 3.3 version directory should not contain any directories other than the designated content sub-directory. Additional directories found: [\"manifests\"]"]}
      )
    end
  end




end
