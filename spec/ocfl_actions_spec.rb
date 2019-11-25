# frozen_string_literal: true

require 'ocfl-tools'
require 'digest'

describe OcflTools::OcflActions do
  # Run after ocf_deposit_spec, so we can use that deposit object example.
  basedir = Dir.pwd
  # set site-specific settings.
  OcflTools.config.content_directory  = 'content'
  OcflTools.config.digest_algorithm   = 'sha256'
  OcflTools.config.version_format = 'v%04d'

  object_dir = "#{basedir}/spec/fixtures/deposit/object_c"

  ocfl = OcflTools::OcflInventory.new.from_file("#{object_dir}/inventory.json")

  ocfl_actions = OcflTools::OcflActions.new

  ocfl_actions.add('1234567890', 'my_content/a_test_file.txt')
  ocfl_actions.update_manifest('1234567890', 'my_content/a_test_file.txt')
  ocfl_actions.add('1234567890', 'my_content/a_copy_of_test_file.txt') # verify de-dupe / copy.
  ocfl_actions.fixity('1234567890', 'md5', 'an_md5_sum')
  ocfl_actions.fixity('1234567890', 'md5', 'an_md5_sum') # verify de-dupe.
  ocfl_actions.fixity('1234567890', 'sha1', 'a_sha1_sum')

  it 'expects a well-formed actions block' do
    expect(ocfl_actions.all).to match(
      {"update_manifest"=>{"1234567890"=>["my_content/a_test_file.txt"]}, "add"=>{"1234567890"=>["my_content/a_test_file.txt", "my_content/a_copy_of_test_file.txt"]}, "fixity"=>{"md5"=>{"1234567890"=>"an_md5_sum"}, "sha1"=>{"1234567890"=>"a_sha1_sum"}}}
    )
  end

end
