require 'ocfl-tools'
require 'digest'

describe OcflTools::OcflValidator do

  # resolve our path to test fixtures to a full system path
  object_root_dir =  File.expand_path('./spec/fixtures/validation/object_a')
  validate = OcflTools::OcflValidator.new(object_root_dir)
  OcflTools.config.content_directory = 'data'

  describe ".new" do
    # shameless green
    it "returns an OcflValidator" do
      expect(validate).to be_instance_of(OcflTools::OcflValidator)
    end
  end

  describe "version_format" do
      it "returns the correct version format" do
        validate.get_version_format
        expect(validate.version_format).to match("v%04d")
      end
  end

  describe "well-formed object A" do
      it "verifies the structure" do
        validate.verify_structure
        expect(validate.results).to match(
          {
            "errors"=>{},
            "warnings"=>
              {
                "verify_structure"=>["OCFL 3.1 optional logs directory found in object root."]
              },
            "pass"=>
              {
                "version_format"=>["OCFL conforming first version directory found."],
                "verify_structure"=>["OCFL 3.1 Object root passed file structure test."]
                }
              }
        )
      end

      it "checks the root inventory" do
          expect(validate.verify_inventory).to match(
          {
            "errors"=>{},
            "warnings"=>{"check_digestAlgorithm"=>["OCFL 3.5.1 sha256 SHOULD be SHA512."]},
            "pass"=>
              {
                "check_id"=>["OCFL 3.5.1 all checks passed without errors"],
                "check_type"=>["OCFL 3.5.1"],
                "check_head"=>["OCFL 3.5.1 @head matches highest version found"],
                "check_manifest"=>["OCFL 3.5.2 object contains valid manifest."],
                "check_versions"=>["OCFL 3.5.3 Found 3 versions, highest version is 3", "OCFL 3.5.3.1 version structure valid."],
                "crosscheck_digests"=>["OCFL 3.5.3.1 All digests successfully crosschecked."],
                "check_digestAlgorithm"=>["OCFL 3.5.1 sha256 is a supported digest algorithm."]
              }
            }
        )
      end

      it "checks checksums from manifest" do
        validate.verify_checksums

      end
  end


  # object_b has a directory called 'v' in it
  object_b =  File.expand_path('./spec/fixtures/validation/object_b')
  validate_b = OcflTools::OcflValidator.new(object_b)

  describe "Object B is not compliant" do
      it "finds an additional directory 'v' in object root" do
        validate_b.verify_structure
        expect(validate_b.results).to match(
          {
            "errors"=>
              {
                "verify_structure"=>["OCFL 3.1 Object root contains noncompliant directories: [\"v\"]"]
              },
            "warnings"=>
              {
                "verify_structure"=>["OCFL 3.1 optional logs directory found in object root."]
              },
            "pass"=>
              {
                "version_format"=>["OCFL conforming first version directory found."]
              }
            }
        )
      end
  end


  # Object_c has version dirs 1, 3 and 4, but not 2.
  object_c =  File.expand_path('./spec/fixtures/validation/object_c')
  validate_c = OcflTools::OcflValidator.new(object_c)

  describe "Object C is not compliant" do
      it "is missing an expected version directory" do
        validate_c.verify_structure
        expect(validate_c.results).to match(
          {
            "errors"=>
              {
                "verify_structure"=>["OCFL 3.1 Expected version directory v0002 missing from sequence [\"v0001\", \"v0003\", \"v0004\"] "]
              },
            "warnings"=>
              {
                "verify_structure"=>["OCFL 3.1 optional logs directory found in object root."]
              },
            "pass"=>
              {
                "version_format"=>["OCFL conforming first version directory found."]
              }
            }
        )

      end
  end


end
