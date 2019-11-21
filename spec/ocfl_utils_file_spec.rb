# frozen_string_literal: true

require 'ocfl-tools'

describe OcflTools::Utils::Files do
  object_root_dir = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', 'object_a')

  describe 'testing' do
    skip 'No specs written yet'
    puts OcflTools::Utils::Files.get_dir_files(object_root_dir)

    #  puts OcflTools::Utils::Files.get_version_format(object_root_dir)
    puts OcflTools::Utils::Files.get_version_directories(object_root_dir)

    #    puts OcflTools::Utils::Inventory.get_value("#{object_root_dir}/inventory.json", "digestAlgorithm")

    #    puts OcflTools::Utils::Inventory.get_value("#{object_root_dir}/inventory.json", "contentDirectory")

    puts OcflTools::Utils::Inventory.get_contentDirectory("#{object_root_dir}/inventory.json")
    puts OcflTools::Utils::Inventory.get_digestAlgorithm("#{object_root_dir}/inventory.json")

    puts OcflTools::Utils::Inventory.get_fixity("#{object_root_dir}/inventory.json")

    files = ['content/a_file.txt', 'home/dir/b_file.txt', "#{object_root_dir}/c_file.pdf"]
    puts OcflTools::Utils::Files.expand_filepaths(files, object_root_dir)

    # What if I just give you one file?

    puts OcflTools::Utils::Files.expand_filepaths('a/fine/single_file.txt', object_root_dir)

    puts OcflTools::Utils::Files.get_latest_inventory(object_root_dir)

    puts OcflTools::Utils::Files.get_version_dir_files(object_root_dir, 3)

    puts OcflTools::Utils::Files.get_versions_dir_files(object_root_dir, 1, 3)
  end
end
