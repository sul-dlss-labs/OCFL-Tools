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

    # puts deposit.results.results

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
    deposit.deposit_new_version

    # puts deposit.results.results

    # shameless green
    it "returns a deposit object" do
      expect(deposit).to be_instance_of(OcflTools::OcflDeposit)
    end

    it "expects zero errors" do
      expect(deposit.results.error_count).to eq 0
    end

  end

  describe "creates a new object C" do

    deposit_dir =  "#{basedir}/spec/fixtures/deposit/source_c_v1"
    object_dir  =  "#{basedir}/spec/fixtures/deposit/object_c"

    if !Dir.empty?(object_dir)
      # prep/reset destination
      FileUtils.rm_r object_dir
      FileUtils.mkdir_p object_dir
    end

    # This would raise exceptions on any errors.
    deposit = OcflTools::OcflDeposit.new(deposit_directory: deposit_dir, object_directory: object_dir)

    # This creates the new version.
    deposit.deposit_new_version

    # puts deposit.results.results

    it "expects zero errors" do
      expect(deposit.results.error_count).to eq 0
    end

  end

  describe "versions object C with a move and a copy action" do

    deposit_dir =  "#{basedir}/spec/fixtures/deposit/source_c_v2"
    object_dir  =  "#{basedir}/spec/fixtures/deposit/object_c"

    deposit = OcflTools::OcflDeposit.new(deposit_directory: deposit_dir, object_directory: object_dir)
    deposit.deposit_new_version
    it "expects zero errors" do
      expect(deposit.results.error_count).to eq 0
    end

  end

  describe "versions object C with an update and a delete action" do
    deposit_dir =  "#{basedir}/spec/fixtures/deposit/source_c_v3"
    object_dir  =  "#{basedir}/spec/fixtures/deposit/object_c"

    deposit = OcflTools::OcflDeposit.new(deposit_directory: deposit_dir, object_directory: object_dir)
    deposit.deposit_new_version
    it "expects zero errors" do
      expect(deposit.results.error_count).to eq 0
    end

  end

  describe "versions object C with a new file and adds fixity info" do
    # Adds Dunwich, historic fixity values for Dracula and the 1st Poe.
    deposit_dir =  "#{basedir}/spec/fixtures/deposit/source_c_v4"
    object_dir  =  "#{basedir}/spec/fixtures/deposit/object_c"
    deposit = OcflTools::OcflDeposit.new(deposit_directory: deposit_dir, object_directory: object_dir)
    deposit.deposit_new_version
    it "expects zero errors" do
      expect(deposit.results.error_count).to eq 0
    end

  end


end
