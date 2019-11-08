require 'ocfl-tools'
require 'digest'

describe OcflTools::OcflValidator do

  # resolve our path to test fixtures to a full system path
  object_a =  File.expand_path('./spec/fixtures/validation/object_a')
  #puts "Object a is at: #{object_a}"
  validate = OcflTools::OcflValidator.new(object_a)
  OcflTools.config.content_directory = 'data'

  describe ".new" do
    # shameless green
    it "returns an OcflValidator" do
      expect(validate).to be_instance_of(OcflTools::OcflValidator)
    end
  end


  describe "well-formed object A" do
      it "verifies the structure" do
        validate.verify_structure
        expect(validate.results.all).to match(
          {"error"=>{}, "warn"=>{"W111"=>{"verify_structure"=>["OCFL 3.1 optional logs directory found in object root."]}}, "info"=>{}, "ok"=>{"O111"=>{"version_format"=>["OCFL conforming first version directory found."], "verify_structure"=>["OCFL 3.1 Object root passed file structure test."]}}}
        )
      end

      it "checks the root inventory" do
          expect(validate.verify_inventory.results).to match(
            {"error"=>{}, "warn"=>{"W220"=>{"check_digestAlgorithm"=>["OCFL 3.5.1 sha256 SHOULD be Sha512."]}}, "info"=>{"I200"=>{"check_head"=>["OCFL 3.5.1 Inventory Head version 3 matches highest version in versions."]}, "I220"=>{"check_digestAlgorithm"=>["OCFL 3.5.1 sha256 is a supported digest algorithm."]}}, "ok"=>{"O200"=>{"check_id"=>["OCFL 3.5.1 Inventory ID is OK."], "check_type"=>["OCFL 3.5.1 Inventory Type is OK."], "check_head"=>["OCFL 3.5.1 Inventory Head is OK."], "check_manifest"=>["OCFL 3.5.2 Inventory Manifest syntax is OK."], "check_versions"=>["OCFL 3.5.3.1 version syntax is OK."], "crosscheck_digests"=>["OCFL 3.5.3.1 Digests are OK."], "check_digestAlgorithm"=>["OCFL 3.5.1 Inventory Algorithm is OK."]}, "I200"=>{"check_versions"=>["OCFL 3.5.3 Found 3 versions, highest version is 3"]}}}
      )
      end

      it "checks checksums from manifest" do
        validate.verify_checksums
      end

      it "tries to validate only version 2 files against the inventory" do
        expect(validate.verify_directory(2).results).to match(
          {"error"=>{}, "warn"=>{"W111"=>{"verify_structure"=>["OCFL 3.1 optional logs directory found in object root."]}}, "info"=>{}, "ok"=>{"O111"=>{"version_format"=>["OCFL conforming first version directory found."], "verify_structure"=>["OCFL 3.1 Object root passed file structure test."], "verify_checksums"=>["All discovered files on disk are referenced in inventory.", "All discovered files on disk match stored digest values."], "verify_directory v0002"=>["All discovered files on disk are referenced in inventory.", "All discovered files on disk match stored digest values."]}}}
        )
      end

  end

  describe "version_format" do
      it "returns the correct version format" do
        expect(validate.version_format).to match("v%04d")
      end
  end

  # object_b has a directory called 'v' in it
  object_b =  File.expand_path('./spec/fixtures/validation/object_b')
  #puts "Object b is at: #{object_b}"
  validate_b = OcflTools::OcflValidator.new(object_b)

  describe "Object B is not compliant" do
      it "finds an additional directory 'v' in object root" do
        validate_b.verify_structure
        expect(validate_b.results.all).to match(
          {"error"=>{"E100"=>{"verify_structure"=>["Object root contains noncompliant directories: [\"v\"]"]}}, "warn"=>{"W111"=>{"verify_structure"=>["OCFL 3.1 optional logs directory found in object root."]}}, "info"=>{}, "ok"=>{"O111"=>{"version_format"=>["OCFL conforming first version directory found."]}}}        )
      end
  end


  # Object_c has version dirs 1, 3 and 4, but not 2.
  object_c =  File.expand_path('./spec/fixtures/validation/object_c')
  #puts "Object c is at: #{object_c}"
  validate_c = OcflTools::OcflValidator.new(object_c)

  describe "Object C is not compliant" do
      it "is missing an expected version directory" do
        validate_c.verify_structure
        expect(validate_c.results.all).to match(
          {"error"=>{"E013"=>{"verify_structure"=>["Expected version directory v0002 missing from directory list [\"v0001\", \"v0003\", \"v0004\"] "]}, "E111"=>{"verify_structure"=>["Inventory file expects a highest version of v0003 but directory list contains [\"v0001\", \"v0003\", \"v0004\"] "]}}, "warn"=>{"W111"=>{"verify_structure"=>["OCFL 3.1 optional logs directory found in object root."]}}, "info"=>{}, "ok"=>{"O111"=>{"version_format"=>["OCFL conforming first version directory found."]}}} )
      end

      it "tries to validate only version 2 files against the inventory" do
        expect{validate_c.verify_directory(2).results}.to raise_error(RuntimeError)
      end

  end

  # Object_h has no inventory files in the version directories.
  object_h =  File.expand_path('./spec/fixtures/validation/object_h')
  #puts "Object h is at: #{object_h}"
  validate_h = OcflTools::OcflValidator.new(object_h)

  describe "Object H is compliant with warnings" do
      it "is missing inventory files in version directories" do
        validate_h.verify_structure
        expect(validate_h.results.all).to match(
          {"error"=>{}, "warn"=>{"W111"=>{"verify_structure"=>["OCFL 3.1 optional logs directory found in object root.", "OCFL 3.1 optional inventory.json missing from v0001 directory", "OCFL 3.1 optional inventory.json.sha512 missing from v0001 directory", "OCFL 3.1 optional inventory.json missing from v0002 directory", "OCFL 3.1 optional inventory.json.sha512 missing from v0002 directory", "OCFL 3.1 optional inventory.json missing from v0003 directory", "OCFL 3.1 optional inventory.json.sha512 missing from v0003 directory"]}}, "info"=>{}, "ok"=>{"O111"=>{"version_format"=>["OCFL conforming first version directory found."], "verify_structure"=>["OCFL 3.1 Object root passed file structure test."]}}}
        )
      end

      it "tries to validate only version 2 files against the inventory" do
          expect(validate_h.verify_directory(2).results).to match(
            {"error"=>{}, "warn"=>{"W111"=>{"verify_structure"=>["OCFL 3.1 optional logs directory found in object root.", "OCFL 3.1 optional inventory.json missing from v0001 directory", "OCFL 3.1 optional inventory.json.sha512 missing from v0001 directory", "OCFL 3.1 optional inventory.json missing from v0002 directory", "OCFL 3.1 optional inventory.json.sha512 missing from v0002 directory", "OCFL 3.1 optional inventory.json missing from v0003 directory", "OCFL 3.1 optional inventory.json.sha512 missing from v0003 directory"]}}, "info"=>{}, "ok"=>{"O111"=>{"version_format"=>["OCFL conforming first version directory found."], "verify_structure"=>["OCFL 3.1 Object root passed file structure test."], "verify_directory v0002"=>["All discovered files on disk are referenced in inventory.", "All discovered files on disk match stored digest values."]}}}
          )
      end

  end

  # Back to A!
  object_a =  File.expand_path('./spec/fixtures/validation/object_a')
  #puts "Object a is at: #{object_a}"
  validate_a = OcflTools::OcflValidator.new(object_a)
  OcflTools.config.content_directory = 'data'

  describe "check results" do
#  validate_a.verify_inventory.results
#  puts "This is verify structure:"
#  puts validate_a.verify_structure.results
#  puts "This is verify inventory:"
#  puts validate_a.verify_inventory.results
  puts "This is a combined results:"
  validate_a.validate_ocfl_object_root.results
  puts "This is a validate_a.results.warn_count : #{validate_a.results.warn_count}"
  puts "This is a validate_a.results.error_count: #{validate_a.results.error_count}"
  puts "This is a validate_a.results.info_count : #{validate_a.results.info_count}"
  puts "This is a validate_a.results.ok_count   : #{validate_a.results.ok_count}"

  #puts validate_a.verify_manifest
  #puts validate_a.validate_ocfl_object_root.results
  end



end
