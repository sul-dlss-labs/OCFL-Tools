require 'ocfl-tools'

describe OcflTools::OcflObject do
  ocfl = OcflTools::OcflObject.new

  describe ".new" do
    # shameless green
    it "returns an OCFLObject" do
      expect(ocfl).to be_instance_of(OcflTools::OcflObject)
    end

    describe "add id" do
      ocfl.id = 'bb123cd4567'
      it "returns the expected id" do
        expect(ocfl.id).to eql('bb123cd4567')
      end
    end

  end

  describe "add version" do

    it "returns an empty version hash" do
        expect(ocfl.get_version(1)).to include(
        "created" => '',
        "message" => '',
        "state" => {},
        "user"=>{"address"=>"", "name"=>""}
      )
    end

    it "adds a file to version 1" do
      expect(ocfl.add_file('my_content/this_is_a_file.txt', 'checksum_aaaaaaaaaaaa', 1)).to include(
        "checksum_aaaaaaaaaaaa"=>["my_content/this_is_a_file.txt"]
      )
      expect(ocfl.manifest).to include(
        "checksum_aaaaaaaaaaaa"=>["v0001/my_content/this_is_a_file.txt"]
      )
    end

    it "adds a file to version 2" do
      expect(ocfl.add_file('my_content/a_second_file.txt', 'checksum_bbbbbbbbbbbb', 2)).to include(
        "checksum_bbbbbbbbbbbb"=>["my_content/a_second_file.txt"]
      )
      expect(ocfl.manifest).to include(
        "checksum_aaaaaaaaaaaa"=>["v0001/my_content/this_is_a_file.txt"],
        "checksum_bbbbbbbbbbbb"=>["v0002/my_content/a_second_file.txt"]
      )
      # expect version 1 state to NOT contain file 2.
      expect(ocfl.get_state(1)).to_not include(
        "checksum_bbbbbbbbbbbb"=>["my_content/a_second_file.txt"]
      )

      expect(ocfl.get_state(2)).to include(
        "checksum_aaaaaaaaaaaa"=>["my_content/this_is_a_file.txt"],
        "checksum_bbbbbbbbbbbb"=>["my_content/a_second_file.txt"]
       )
    end

  end

end
