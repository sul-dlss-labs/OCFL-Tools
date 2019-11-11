require 'ocfl-tools'
require 'digest'

describe OcflTools::OcflDeposit do

  basedir     = Dir.pwd
  # set site-specific settings.
  OcflTools.config.content_directory  = 'content'
  OcflTools.config.digest_algorithm   = 'sha256'
  OcflTools.config.version_format     =  "v%04d"

  describe "creates a new object" do

    deposit_dir =  "#{basedir}/spec/fixtures/deposit/source_a"
    object_dir  =  "#{basedir}/spec/fixtures/deposit/object_a"

    if !Dir.empty?(object_dir)
      # prep/reset destination
      FileUtils.rm_r object_dir
      FileUtils.mkdir_p object_dir
    end

    deposit = OcflTools::OcflDeposit.new(deposit_directory: deposit_dir, object_directory: object_dir)


    deposit.deposit_new_version

    puts deposit.results.results


    # shameless green
    it "returns a deposit object" do
      expect(deposit).to be_instance_of(OcflTools::OcflDeposit)
    end
  end

  #Dir.chdir(basedir)

  describe "Adds a new version to an existing a object" do

    deposit_dir =  "#{basedir}/spec/fixtures/deposit/source_b"
    object_dir  =  "#{basedir}/spec/fixtures/deposit/object_b"

    deposit = OcflTools::OcflDeposit.new(deposit_directory: deposit_dir, object_directory: object_dir)
    #puts deposit.results.results

    # shameless green
    it "returns a deposit object" do
      expect(deposit).to be_instance_of(OcflTools::OcflDeposit)
    end
  end


end
