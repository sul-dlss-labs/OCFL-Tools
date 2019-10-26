require 'ocfl-tools'
require 'digest'

describe OcflTools::OcflValidator do
  # resolve our path to test fixtures to a full system path
  object_a =  File.expand_path('./spec/fixtures/validation/object_a')
  validate_a = OcflTools::OcflValidator.new(object_a)
  OcflTools.config.content_directory = 'data'

  # TODO: fix expand_path so we're not tying the results to my local machine's directory structure.
  local_path = object_a.delete_suffix('/spec/fixtures/validation/object_a')
  # local_path should stay the same for all fixtures. 

  describe "perfect object a" do

    it "checks checksums from manifest" do
      expect(validate_a.verify_checksums).to match(
        {
          "errors"=>{},
          "warnings"=>{},
          "pass"=>
            {
              "verify_checksums"=>
                ["#{local_path}/spec/fixtures/validation/object_a All discovered files on disk are referenced in inventory manifest.",
                  "#{local_path}/spec/fixtures/validation/object_a All discovered files on disk match stored digest values."]
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
        {"errors"=>{"verify_checksums"=>["#{local_path}/spec/fixtures/validation/object_e/v0003/data/my_content/dickens.txt in manifest but not found on disk."]}, "warnings"=>{}, "pass"=>{}}
      )
    end
  end

  object_f =  File.expand_path('./spec/fixtures/validation/object_f')
  validate_f = OcflTools::OcflValidator.new(object_f)

  describe "object f has a file on disk version 3 that does not exist in manifest version 3" do
    it "checks checksums from manifest" do
      #puts validate_f.verify_checksums
        expect(validate_f.verify_checksums).to match(
          {"errors"=>{"verify_checksums"=>["#{local_path}/spec/fixtures/validation/object_f/v0003/data/my_content/dickens.txt found on disk but missing from inventory.json."]}, "warnings"=>{}, "pass"=>{}}
        )
    end
  end

end
