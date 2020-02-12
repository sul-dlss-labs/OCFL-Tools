# frozen_string_literal: true

require 'ocfl-tools'

describe OcflTools::OcflDelta do
  # Run after ocf_deposit_spec, so we can use that deposit object example.
  basedir = Dir.pwd
  # set site-specific settings.
  OcflTools.config.content_directory  = 'content'
  OcflTools.config.digest_algorithm   = 'sha256'
  OcflTools.config.version_format = 'v%04d'

  object_dir = "#{basedir}/spec/fixtures/deposit/object_c"

  ocfl = OcflTools::OcflInventory.new.from_file("#{object_dir}/inventory.json")

  ocfl_delta = OcflTools::OcflDelta.new(ocfl)

    it 'expects the correct version 1 delta' do
      expect(ocfl_delta.previous(1)).to match(
        {"update_manifest"=>{"cffe55838a878a29da82a0e10b2909b7e46b6f7167ed7f815782465573e98f27"=>["my_content/dracula.txt"], "f512eb0a032f562225e848ce88449895f3ec19f3d4836a80df80c77c74557bab"=>["my_content/poe.txt"]}, "add"=>{"cffe55838a878a29da82a0e10b2909b7e46b6f7167ed7f815782465573e98f27"=>["my_content/dracula.txt"], "f512eb0a032f562225e848ce88449895f3ec19f3d4836a80df80c77c74557bab"=>["my_content/poe.txt"]}}
      )
    end

    it 'expects the correct version 2 delta' do
      expect(ocfl_delta.previous(2)).to match(
        {"copy"=>{"cffe55838a878a29da82a0e10b2909b7e46b6f7167ed7f815782465573e98f27"=>["my_content/a_second_copy_of_dracula.txt", "my_content/another_directory/a_third_copy_of_dracula.txt"]}, "move"=>{"f512eb0a032f562225e848ce88449895f3ec19f3d4836a80df80c77c74557bab"=>["my_content/poe.txt", "my_content/poe-nevermore.txt"]}}
      )
    end

    it 'expects the correct version 3 delta' do
      expect(ocfl_delta.previous(3)).to match(
        {"update_manifest"=>{"618ea77f3a74558493f2df1d82fee18073f6458573d58e6b65bade8bd65227fb"=>["my_content/poe-nevermore.txt"]}, "update"=>{"618ea77f3a74558493f2df1d82fee18073f6458573d58e6b65bade8bd65227fb"=>["my_content/poe-nevermore.txt"]}}
      )
    end

    it 'expects the correct version 4 delta' do
      expect(ocfl_delta.previous(4)).to match(
        {"update_manifest"=>{"9b4566a0455e76a392c43ec4d8b8e7d636b21ff2cf83b87fe99b97d00a501de0"=>["my_content/dunwich.txt"]}, "add"=>{"9b4566a0455e76a392c43ec4d8b8e7d636b21ff2cf83b87fe99b97d00a501de0"=>["my_content/dunwich.txt"]}}
      )
    end

  # puts JSON.pretty_generate(ocfl_delta.all)
  it 'expects a correct and well-formed JSON delta for entire object' do
    expect(ocfl_delta.all).to match(
      {"v0001"=>{"update_manifest"=>{"cffe55838a878a29da82a0e10b2909b7e46b6f7167ed7f815782465573e98f27"=>["my_content/dracula.txt"], "f512eb0a032f562225e848ce88449895f3ec19f3d4836a80df80c77c74557bab"=>["my_content/poe.txt"]}, "add"=>{"cffe55838a878a29da82a0e10b2909b7e46b6f7167ed7f815782465573e98f27"=>["my_content/dracula.txt"], "f512eb0a032f562225e848ce88449895f3ec19f3d4836a80df80c77c74557bab"=>["my_content/poe.txt"]}}, "v0002"=>{"copy"=>{"cffe55838a878a29da82a0e10b2909b7e46b6f7167ed7f815782465573e98f27"=>["my_content/a_second_copy_of_dracula.txt", "my_content/another_directory/a_third_copy_of_dracula.txt"]}, "move"=>{"f512eb0a032f562225e848ce88449895f3ec19f3d4836a80df80c77c74557bab"=>["my_content/poe.txt", "my_content/poe-nevermore.txt"]}}, "v0003"=>{"update_manifest"=>{"618ea77f3a74558493f2df1d82fee18073f6458573d58e6b65bade8bd65227fb"=>["my_content/poe-nevermore.txt"]}, "update"=>{"618ea77f3a74558493f2df1d82fee18073f6458573d58e6b65bade8bd65227fb"=>["my_content/poe-nevermore.txt"]}}, "v0004"=>{"update_manifest"=>{"9b4566a0455e76a392c43ec4d8b8e7d636b21ff2cf83b87fe99b97d00a501de0"=>["my_content/dunwich.txt"]}, "add"=>{"9b4566a0455e76a392c43ec4d8b8e7d636b21ff2cf83b87fe99b97d00a501de0"=>["my_content/dunwich.txt"]}}}
    )
  end

end
