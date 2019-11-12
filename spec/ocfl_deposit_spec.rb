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

    # This would raise exceptions on any errors.
    deposit = OcflTools::OcflDeposit.new(deposit_directory: deposit_dir, object_directory: object_dir)

    # This creates the new version.
    deposit.deposit_new_version

    it "expects zero errors" do
      expect(deposit.results.error_count).to eq 0
    end

    # If we wanted to be more thorough we can process object_dir with Validator again,
    # even though deposit.deposit_new_version does that itself.
  end

  #Dir.chdir(basedir)

  describe "Adds a new version to an existing a object" do

    deposit_dir =  "#{basedir}/spec/fixtures/deposit/source_b"
    object_dir  =  "#{basedir}/spec/fixtures/deposit/object_b"

    # Here we are creating version 4 and making a copy of an existing file, and adding a new file.

    if Dir.exists?("#{object_dir}/v0004")
      FileUtils.rm_r "#{object_dir}/v0004"
      FileUtils.rm "#{object_dir}/inventory.json"
      FileUtils.rm "#{object_dir}/inventory.json.sha256"
      FileUtils.cp "#{deposit_dir}/inventory.json", "#{object_dir}/inventory.json"
      FileUtils.cp "#{deposit_dir}/inventory.json.sha256", "#{object_dir}/inventory.json.sha256"
    end

    deposit = OcflTools::OcflDeposit.new(deposit_directory: deposit_dir, object_directory: object_dir)
    puts deposit.results.results
    deposit.deposit_new_version

    # shameless green
    it "returns a deposit object" do
      expect(deposit).to be_instance_of(OcflTools::OcflDeposit)
    end
  end


end
