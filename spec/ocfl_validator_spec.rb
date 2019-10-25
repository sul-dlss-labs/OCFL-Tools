require 'ocfl-tools'

describe OcflTools::OcflValidator do
  validate = OcflTools::OcflValidator.new('./spec/fixtures/validation/object_a')

  describe ".new" do
    # shameless green
    it "returns an OcflValidator" do
      expect(validate).to be_instance_of(OcflTools::OcflValidator)
    end
  end

  describe "versions" do
    it "returns the correct version format" do
      validate.get_version_format
      expect(validate.version_format).to match("v%04d")
    end
  end
end
