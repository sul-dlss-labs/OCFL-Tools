require 'ocfl-tools'


describe OcflTools::OcflDeposit do

  describe "creates a new object" do
    basedir     = Dir.pwd
    deposit_dir =  "#{basedir}/spec/fixtures/deposit/source_a"
    object_dir  =  "#{basedir}/spec/fixtures/deposit/object_a"

    deposit = OcflTools::OcflDeposit.new(deposit_directory: deposit_dir, object_directory: object_dir)

    # shameless green
    it "returns a deposit object" do
      expect(deposit).to be_instance_of(OcflTools::OcflDeposit)
    end
  end

  describe "Adds a new version to an existing a object" do
    basedir     = Dir.pwd
    deposit_dir =  "#{basedir}/spec/fixtures/deposit/source_b"
    object_dir  =  "#{basedir}/spec/fixtures/deposit/object_b"

    deposit = OcflTools::OcflDeposit.new(deposit_directory: deposit_dir, object_directory: object_dir)

    # shameless green
    it "returns a deposit object" do
      expect(deposit).to be_instance_of(OcflTools::OcflDeposit)
    end
  end


end
