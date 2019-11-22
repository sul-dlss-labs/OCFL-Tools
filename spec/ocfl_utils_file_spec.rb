# frozen_string_literal: true

require 'ocfl-tools'

describe OcflTools::Utils::Files do
  object_root_dir = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', 'object_a')

  describe 'testing' do
    # puts OcflTools::Utils::Files.get_dir_files(object_root_dir)

    it 'gets the correct version format' do
      expect(OcflTools::Utils::Files.get_version_format(object_root_dir)).to match(
        'v%04d'
      )
    end

    it 'expects 3 version directories' do
      expect(OcflTools::Utils::Files.get_version_directories(object_root_dir)).to match(
        %w[v0001 v0002 v0003]
      )
    end

    it 'expects contentDirectory to be data' do
      expect(OcflTools::Utils::Inventory.get_contentDirectory("#{object_root_dir}/inventory.json")).to match(
        'data'
      )
    end

    it 'expects digestAlgorithm to be sha256' do
      expect(OcflTools::Utils::Inventory.get_digestAlgorithm("#{object_root_dir}/inventory.json")).to match(
        'sha256'
      )
    end
    # puts OcflTools::Utils::Inventory.get_fixity("#{object_root_dir}/inventory.json")

    files = ['content/a_file.txt', 'home/dir/b_file.txt', "#{object_root_dir}/c_file.pdf"]
    it 'expects an array of filepaths' do
      expect(OcflTools::Utils::Files.expand_filepaths(files, object_root_dir)).to match(
        ["#{object_root_dir}/content/a_file.txt", "#{object_root_dir}/home/dir/b_file.txt"]
      )
    end

    # What if I just give you one file?
    it 'expects an expanded filepath' do
      expect(OcflTools::Utils::Files.expand_filepaths('a/fine/single_file.txt', object_root_dir)).to match(
        ["#{object_root_dir}/a/fine/single_file.txt"]
      )
    end

    it 'returns the latest inventory' do
      expect(OcflTools::Utils::Files.get_latest_inventory(object_root_dir)).to match(
        "#{object_root_dir}/v0003/inventory.json"
      )
    end

    puts OcflTools::Utils::Files.get_version_dir_files(object_root_dir, 3)
    it 'returns the files in version 3 on disk' do
      expect(OcflTools::Utils::Files.get_version_dir_files(object_root_dir, 3)).to match(
        ["#{object_root_dir}/v0003/data/my_content/dickens.txt"]
      )
    end
    # puts OcflTools::Utils::Files.get_versions_dir_files(object_root_dir, 1, 3)
  end
end
