require 'ocfl-tools'

describe OcflTools::OcflInventory do
  ocfl = OcflTools::OcflInventory.new
#  OcflTools::Utils::VERSION_FORMAT = "v%04d"

  ocfl.contentDirectory = 'data'
  ocfl.digestAlgorithm = 'sha256'

  describe ".new" do
    # shameless green
    it "returns an OCFLObject" do
      expect(ocfl).to be_instance_of(OcflTools::OcflInventory)
    end

    describe "add id" do
      ocfl.id = 'bb123cd4567'
      it "returns the expected id" do
        expect(ocfl.id).to eql('bb123cd4567')
      end
    end

  end

  describe "add initial versions" do

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
        "checksum_aaaaaaaaaaaa"=>["v0001/#{ocfl.contentDirectory}/my_content/this_is_a_file.txt"]
      )
    end

    it "adds a file to version 2" do
      expect(ocfl.add_file('my_content/a_second_file.txt', 'checksum_bbbbbbbbbbbb', 2)).to include(
        "checksum_bbbbbbbbbbbb"=>["my_content/a_second_file.txt"]
      )
      expect(ocfl.manifest).to match(
        "checksum_aaaaaaaaaaaa"=>["v0001/#{ocfl.contentDirectory}/my_content/this_is_a_file.txt"],
        "checksum_bbbbbbbbbbbb"=>["v0002/#{ocfl.contentDirectory}/my_content/a_second_file.txt"]
      )
      # expect version 1 state to NOT contain file 2.
      expect(ocfl.get_state(1)).to_not include(
        "checksum_bbbbbbbbbbbb"=>["my_content/a_second_file.txt"]
      )

      expect(ocfl.get_state(2)).to match(
        "checksum_aaaaaaaaaaaa"=>["my_content/this_is_a_file.txt"],
        "checksum_bbbbbbbbbbbb"=>["my_content/a_second_file.txt"]
       )
    end

    it "adds a file to version 3" do
      expect(ocfl.add_file('my_content/a_third_file.txt', 'checksum_cccccccccccc', 3)).to include(
        "checksum_cccccccccccc"=>["my_content/a_third_file.txt"]
      )
      expect(ocfl.manifest).to match(
        "checksum_aaaaaaaaaaaa"=>["v0001/#{ocfl.contentDirectory}/my_content/this_is_a_file.txt"],
        "checksum_bbbbbbbbbbbb"=>["v0002/#{ocfl.contentDirectory}/my_content/a_second_file.txt"],
        "checksum_cccccccccccc"=>["v0003/#{ocfl.contentDirectory}/my_content/a_third_file.txt"]
      )
      # expect version 1 state to NOT contain file 2.
      expect(ocfl.get_state(1)).to_not include(
        "checksum_bbbbbbbbbbbb"=>["my_content/a_second_file.txt"]
      )

      expect(ocfl.get_state(2)).to_not include(
        "checksum_cccccccccccc"=>["my_content/a_third_file.txt"]
      )

      expect(ocfl.get_state(3)).to match(
        "checksum_aaaaaaaaaaaa"=>["my_content/this_is_a_file.txt"],
        "checksum_bbbbbbbbbbbb"=>["my_content/a_second_file.txt"],
        "checksum_cccccccccccc"=>["my_content/a_third_file.txt"]
       )
    end

    it "gets the list of versions" do
      expect(ocfl.version_id_list).to eql([1, 2, 3])
    end

    it "sets head to v0003" do
      expect(ocfl.set_head_from_version(3)).to eql('v0003')
      expect(ocfl.head).to eql('v0003')
    end

  end

  describe "test file operations" do
    # This is a de-duplication test
    it "adds a second copy of file 3" do
      expect(ocfl.add_file('my_content/a_copy_of_third_file.txt', 'checksum_cccccccccccc', 3)).to include(
        "checksum_cccccccccccc" => ["my_content/a_third_file.txt", "my_content/a_copy_of_third_file.txt"]
      )
      expect(ocfl.get_state(3)).to match(
        "checksum_aaaaaaaaaaaa"=>["my_content/this_is_a_file.txt"],
        "checksum_bbbbbbbbbbbb"=>["my_content/a_second_file.txt"],
        "checksum_cccccccccccc" => ["my_content/a_third_file.txt", "my_content/a_copy_of_third_file.txt"]
       )
    end

    it "deletes file 1" do
      expect(ocfl.delete_file('my_content/this_is_a_file.txt', 4)).to match(
        "checksum_bbbbbbbbbbbb"=>["my_content/a_second_file.txt"],
        "checksum_cccccccccccc" => ["my_content/a_third_file.txt", "my_content/a_copy_of_third_file.txt"]
      )
      expect(ocfl.get_state(4)).to match(
        "checksum_bbbbbbbbbbbb"=>["my_content/a_second_file.txt"],
        "checksum_cccccccccccc" => ["my_content/a_third_file.txt", "my_content/a_copy_of_third_file.txt"]
       )
       expect(ocfl.get_state(4)).to_not include(
         "checksum_aaaaaaaaaaaa"=>["my_content/this_is_a_file.txt"]
       )
    end

    it "updates file 2 with new content" do
      expect(ocfl.update_file('my_content/a_second_file.txt', 'checksum_dddddddddddd', 5)).to match(
        "checksum_cccccccccccc" => ["my_content/a_third_file.txt", "my_content/a_copy_of_third_file.txt"],
        "checksum_dddddddddddd" => ["my_content/a_second_file.txt"]
      )
      expect(ocfl.get_state(5)).to match(
        "checksum_dddddddddddd" => ["my_content/a_second_file.txt"],
        "checksum_cccccccccccc" => ["my_content/a_third_file.txt", "my_content/a_copy_of_third_file.txt"]
       )
       expect(ocfl.manifest).to include(
         "checksum_dddddddddddd" => ["v0005/#{ocfl.contentDirectory}/my_content/a_second_file.txt"],
       )
    end

    it "copies file 2 to another location" do
      expect(ocfl.copy_file('my_content/a_second_file.txt', 'another_dir/copy_of_second_file.txt', 6)).to match(
        "checksum_cccccccccccc" => ["my_content/a_third_file.txt", "my_content/a_copy_of_third_file.txt"],
        "checksum_dddddddddddd" => ["my_content/a_second_file.txt", "another_dir/copy_of_second_file.txt"]
      )
      expect(ocfl.get_state(6)).to match(
        "checksum_dddddddddddd" => ["my_content/a_second_file.txt", "another_dir/copy_of_second_file.txt"],
        "checksum_cccccccccccc" => ["my_content/a_third_file.txt", "my_content/a_copy_of_third_file.txt"]
       )

    end

    # Try to copy a file onto an existing, different file.
    it "copies a file over another, different existing file" do
      expect(ocfl.copy_file('my_content/a_third_file.txt', 'another_dir/copy_of_second_file.txt', 6)).to match(
        "checksum_cccccccccccc" => ["my_content/a_third_file.txt", "my_content/a_copy_of_third_file.txt", "another_dir/copy_of_second_file.txt"],
        "checksum_dddddddddddd" => ["my_content/a_second_file.txt"]
      )
      expect(ocfl.get_state(6)).to match(
        "checksum_dddddddddddd" => ["my_content/a_second_file.txt"],
        "checksum_cccccccccccc" => ["my_content/a_third_file.txt", "my_content/a_copy_of_third_file.txt", "another_dir/copy_of_second_file.txt"]
       )
    end

  end

  describe "bad file operations" do

    it "fails to delete a nonexistent file" do
      expect{ocfl.delete_file('my_content/file_not_found.txt', 6)}.to raise_error(RuntimeError)
    end

    it "fails to copy a nonexistent file" do
      expect{ ocfl.copy_file('my_content/file_not_found.txt', 'another_dir/copy_of_second_file.txt', 6) }.to raise_error(RuntimeError)
    end

    it "fails to move a nonexistent file" do
      expect{ ocfl.move_file('my_content/file_not_found.txt', 'another_dir/copy_of_second_file.txt', 6 )}.to raise_error(RuntimeError)
    end

    it "tries to add a file to a previous version" do
      expect{ocfl.add_file('my_content/you_shall_not_add.txt', 'checksum_zzzzzzzzzzzz', 4)}.to raise_error(RuntimeError)
    end

    it "tries to delete a file from a previous version" do
      expect{ocfl.delete_file('my_content/a_second_file.txt', 2)}.to raise_error(RuntimeError)
    end

  end

  describe "output inventory.json" do
    it "serializes the thing" do
      # File.read("/path/to/file").should == “content”
      content = ocfl.serialize.to_s
      file    = File.read("./spec/fixtures/inventory.json")
      expect(file).to include(content)
    end
  end

  describe "fail to read bad JSON" do
    it "fails to read a bad file" do
      bad_content = OcflTools::OcflInventory.new
      bad_file = "./spec/fixtures/bad_json/inventory.json"
      expect{ocfl.from_file(bad_file)}.to raise_error(RuntimeError)
    end
  end

  describe "reads good JSON" do
    it "reads in correctly-formated JSON" do
      good_file    = "./spec/fixtures/inventory.json"
      good_content = File.read("./spec/fixtures/inventory.json")
      good_ocfl    = OcflTools::OcflInventory.new

      good_ocfl.from_file(good_file)
      verify_ocfl = OcflTools::OcflVerify.new(good_ocfl)
  
      expect(verify_ocfl.check_all).to include(
        {
          "errors"=>{},
          "warnings"=>{},
          "pass"=>{
            "check_id"=>["all checks passed without errors"],
            "check_head"=>["@head matches highest version found"],
            "check_versions"=>["Found 6 versions, highest version is 6"],
            "crosscheck_digests"=>["All digests successfully crosschecked."],
            "check_digestAlgorithm"=>["sha256 is a supported digest algorithm."]
            }
          }
      )
    end
  end


end
