require 'ocfl-tools'
require 'digest'

describe OcflTools::OcflValidator do
  puts "Shameful green"
  # resolve our path to test fixtures to a full system path
  object_a =  File.expand_path('./spec/fixtures/validation/object_a')
  validate_a = OcflTools::OcflValidator.new(object_a)
  OcflTools.config.content_directory = 'data'

  describe "perfect object a" do
    # shameless green

    it "checks checksums from manifest" do
      expect(validate_a.verify_checksums).to match(
        {
          "errors"=>{},
          "warnings"=>{},
          "pass"=>
            {
              "verify_checksums"=>
                ["/Users/jmorley/Documents/github/OCFL-Tools/spec/fixtures/validation/object_a All discovered files on disk are referenced in inventory manifest.",
                  "/Users/jmorley/Documents/github/OCFL-Tools/spec/fixtures/validation/object_a All discovered files on disk match stored digest values."]
            }
        }
      )
    end
  end

  object_e =  File.expand_path('./spec/fixtures/validation/object_e')
  validate_e = OcflTools::OcflValidator.new(object_e)

  describe "object e is missing a file on disk" do
    it "checks checksums from manifest" do
      expect(validate_e.verify_checksums).to match(
        {"errors"=>{"verify_checksums"=>["/Users/jmorley/Documents/github/OCFL-Tools/spec/fixtures/validation/object_e/v0003/data/my_content/dickens.txt in manifest but not found on disk."]}, "warnings"=>{}, "pass"=>{}}
      )
    end
  end

  object_f =  File.expand_path('./spec/fixtures/validation/object_f')
  validate_f = OcflTools::OcflValidator.new(object_f)

  describe "object f has a file on disk version 3 that does not exist in manifest version 3" do
    it "checks checksums from manifest" do
      #puts validate_f.verify_checksums
        expect(validate_f.verify_checksums).to match(
          {"errors"=>{"verify_checksums"=>["/Users/jmorley/Documents/github/OCFL-Tools/spec/fixtures/validation/object_f/v0003/data/my_content/dickens.txt found on disk but missing from inventory.json."]}, "warnings"=>{}, "pass"=>{}}
        )
    end
  end

end
