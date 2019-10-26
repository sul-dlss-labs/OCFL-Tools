require 'ocfl-tools'

describe OcflTools::OcflVerify do

  OcflTools.config.content_directory = 'data'

  describe "verifies object A" do

    ocfl = OcflTools::OcflInventory.new
    object_root_dir =  File.expand_path('./spec/fixtures/validation/object_a')
    ocfl.from_file("#{object_root_dir}/inventory.json")

    verify = OcflTools::OcflVerify.new(ocfl)

    it "returns a verify object" do
      expect(verify).to be_instance_of(OcflTools::OcflVerify)
    end

    results = verify.check_all
    #puts results.results

    it "expects to get a results object" do
      expect(verify.check_all).to be_instance_of(OcflTools::OcflResults)
      expect(results.results).to match(
        {"error"=>{}, "warn"=>{"W111"=>{"check_digestAlgorithm"=>["OCFL 3.5.1 sha256 SHOULD be SHA512."]}}, "info"=>{}, "ok"=>{"O111"=>{"check_id"=>["OCFL 3.5.1 all checks passed without errors"], "check_type"=>["OCFL 3.5.1"], "check_head"=>["OCFL 3.5.1 @head matches highest version found"], "check_manifest"=>["OCFL 3.5.2 object contains valid manifest."], "check_versions"=>["OCFL 3.5.3 Found 3 versions, highest version is 3", "OCFL 3.5.3.1 version structure valid."], "crosscheck_digests"=>["OCFL 3.5.3.1 All digests successfully crosschecked."], "check_digestAlgorithm"=>["OCFL 3.5.1 sha256 is a supported digest algorithm."]}}}
      )
    end

  end

end
