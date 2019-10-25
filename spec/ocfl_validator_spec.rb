require 'ocfl-tools'

describe OcflTools::OcflValidator do

  # resolve our path to test fixtures to a full system path
  object_root_dir =  File.expand_path('./spec/fixtures/validation/object_a')
  validate = OcflTools::OcflValidator.new(object_root_dir)

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

  describe "directory structure" do
      it "verifies the directories" do
        validate.verify_structure
        puts "this is validate_a results: #{validate.results}"
        #puts validate.results
      end
  end


  # object_b has a directory called 'v' in it
  object_b =  File.expand_path('./spec/fixtures/validation/object_b')
  validate_b = OcflTools::OcflValidator.new(object_b)

  describe "fails directory structure" do
      it "verifies the directories" do
        validate.verify_structure
        # b should fail directory check. 
        #expect{validate_b.verify_structure}.to raise_error(RuntimeError)
        puts "this is validate_b results: #{validate_b.results}"
      end
  end


  object_c =  File.expand_path('./spec/fixtures/validation/object_c')
  validate_c = OcflTools::OcflValidator.new(object_c)

  describe "fails directory structure" do
      it "verifies the directories" do
      #  expect{validate_c.verify_structure}.to raise_error(RuntimeError)
        validate_c.verify_structure
        puts "this is validate_c results: #{validate_c.results}"

      end
  end


end
