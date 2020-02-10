# frozen_string_literal: true

require 'ocfl-tools'
require 'digest'

describe OcflTools::OcflDeposit do
  basedir = Dir.pwd
  # set site-specific settings.
  OcflTools.config.content_directory = 'content'
  OcflTools.config.digest_algorithm = 'sha256'
  OcflTools.config.version_format = 'v%04d'

  describe 'creates a new object' do
    deposit_dir = "#{basedir}/spec/fixtures/deposit/source_a"
    object_dir = "#{basedir}/spec/fixtures/deposit/object_a"

    unless Dir.empty?(object_dir)
      # prep/reset destination
      FileUtils.rm_r object_dir
      FileUtils.mkdir_p object_dir
    end

    # This would raise exceptions on any errors.
    deposit = OcflTools::OcflDeposit.new(deposit_directory: deposit_dir, object_directory: object_dir)

    # This creates the new version.
    deposit.deposit_new_version

    # puts deposit.results.results

    it 'expects zero errors' do
      expect(deposit.results.error_count).to eq 0
    end

    # If we wanted to be more thorough we can process object_dir with Validator again,
    # even though deposit.deposit_new_version does that itself.
  end

  # Dir.chdir(basedir)

  describe 'Adds a new version to an existing a object' do
    deposit_dir =  "#{basedir}/spec/fixtures/deposit/source_b"
    object_dir  =  "#{basedir}/spec/fixtures/deposit/object_b"

    # Here we are creating version 4 and making a copy of an existing file, and adding a new file.

    if Dir.exist?("#{object_dir}/v0004")
      FileUtils.rm_r "#{object_dir}/v0004"
      FileUtils.rm "#{object_dir}/inventory.json"
      FileUtils.rm "#{object_dir}/inventory.json.sha256"
      FileUtils.cp "#{deposit_dir}/inventory.json", "#{object_dir}/inventory.json"
      FileUtils.cp "#{deposit_dir}/inventory.json.sha256", "#{object_dir}/inventory.json.sha256"
    end

    deposit = OcflTools::OcflDeposit.new(deposit_directory: deposit_dir, object_directory: object_dir)
    deposit.deposit_new_version

    # shameless green
    it 'returns a deposit object' do
      expect(deposit).to be_instance_of(OcflTools::OcflDeposit)
    end

    it 'expects zero errors' do
      expect(deposit.results.error_count).to eq 0
    end
  end

  describe 'creates a new object C' do
    # Creates a new OCFL object and adds Dracula and Poe to it.
    deposit_dir =  "#{basedir}/spec/fixtures/deposit/source_c_v1"
    object_dir  =  "#{basedir}/spec/fixtures/deposit/object_c"

    # prep/reset destination
    FileUtils.rm_r object_dir if Dir.exist?(object_dir)
    FileUtils.mkdir_p object_dir

    deposit = OcflTools::OcflDeposit.new(deposit_directory: deposit_dir, object_directory: object_dir)
    deposit.deposit_new_version

    it 'expects zero errors' do
      expect(deposit.results.error_count).to eq 0
    end
  end

  describe 'versions object C with a move and a copy action' do
    # Moves 1st Poe to poe-nevermore.txt, adds 2 copies of Dracula, one in new subfolder.
    deposit_dir =  "#{basedir}/spec/fixtures/deposit/source_c_v2"
    object_dir  =  "#{basedir}/spec/fixtures/deposit/object_c"

    deposit = OcflTools::OcflDeposit.new(deposit_directory: deposit_dir, object_directory: object_dir)
    deposit.deposit_new_version

    it 'expects zero errors' do
      expect(deposit.results.error_count).to eq 0
    end
  end

  describe 'versions object C with an update and a delete action' do
    # Updates 1st Poe, deletes 2nd Dracula.
    deposit_dir =  "#{basedir}/spec/fixtures/deposit/source_c_v3"
    object_dir  =  "#{basedir}/spec/fixtures/deposit/object_c"

    deposit = OcflTools::OcflDeposit.new(deposit_directory: deposit_dir, object_directory: object_dir)
    deposit.deposit_new_version

    it 'expects zero errors' do
      expect(deposit.results.error_count).to eq 0
    end
  end

  describe 'versions object C with a new file and adds fixity info' do
    # Adds Dunwich, historic fixity values for Dracula and the 1st Poe.
    deposit_dir =  "#{basedir}/spec/fixtures/deposit/source_c_v4"
    object_dir  =  "#{basedir}/spec/fixtures/deposit/object_c"

    deposit = OcflTools::OcflDeposit.new(deposit_directory: deposit_dir, object_directory: object_dir)
    deposit.deposit_new_version

    it 'expects zero errors' do
      expect(deposit.results.error_count).to eq 0
    end

    # Now validate the full object!
    validate = OcflTools::OcflValidator.new(object_dir)

    it 'validates the entire object using the fixity block instead of manifest checksums' do
      validate.validate_ocfl_object_root
      expect(validate.results.ok_count).to eq 14
    end
  end

  describe 'create object D with many action files' do
    # Adds some files & immediately moves / copies them in first version.
    deposit_dir =  "#{basedir}/spec/fixtures/deposit/source_d"
    object_dir  =  "#{basedir}/spec/fixtures/deposit/object_d"

    # prep/reset destination
    FileUtils.rm_r object_dir if Dir.exist?(object_dir)
    FileUtils.mkdir_p object_dir

    deposit = OcflTools::OcflDeposit.new(deposit_directory: deposit_dir, object_directory: object_dir)
    deposit.deposit_new_version

    it 'expects zero errors' do
      expect(deposit.results.error_count).to eq 0
    end

    ocfl = OcflTools::OcflInventory.new.from_file("#{object_dir}/inventory.json")

    ocfl_delta = OcflTools::OcflDelta.new(ocfl)
   it 'expects a well-formed delta block' do
     expect(ocfl_delta.all).to match(
       {"v0001"=>{"update_manifest"=>{"cffe55838a878a29da82a0e10b2909b7e46b6f7167ed7f815782465573e98f27"=>["ingest_temp/dracula.txt"], "f512eb0a032f562225e848ce88449895f3ec19f3d4836a80df80c77c74557bab"=>["ingest_temp/poe.txt"]}, "add"=>{"cffe55838a878a29da82a0e10b2909b7e46b6f7167ed7f815782465573e98f27"=>["my_content/a_great_copy_of_dracula.txt", "my_content/another_directory/a_third_copy_of_dracula.txt"], "f512eb0a032f562225e848ce88449895f3ec19f3d4836a80df80c77c74557bab"=>["edgar/alan/poe.txt"]}}}
     )
   end

  end
end
