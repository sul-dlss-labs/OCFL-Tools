require 'ocfl-tools'
require 'digest'

describe OcflTools::OcflActions do
  # Run after ocf_deposit_spec, so we can use that deposit object example.
  basedir     = Dir.pwd
  # set site-specific settings.
  OcflTools.config.content_directory  = 'content'
  OcflTools.config.digest_algorithm   = 'sha256'
  OcflTools.config.version_format     =  "v%04d"

  object_dir  =  "#{basedir}/spec/fixtures/deposit/object_c"

  ocfl = OcflTools::OcflInventory.new.from_file("#{object_dir}/inventory.json")

  ocfl_actions = OcflTools::OcflActions.new

  puts ocfl_actions

  ocfl_actions.add('1234567890', 'my_content/a_test_file.txt')
  ocfl_actions.add('1234567890', 'my_content/a_test_file.txt')
  ocfl_actions.add('1234567890', 'my_content/a_copy_of_test_file.txt')
  ocfl_actions.fixity('1234567890', 'md5', 'an_md5_sum')
  ocfl_actions.fixity('1234567890', 'md5', 'an_md5_sum')
  ocfl_actions.fixity('1234567890', 'sha1', 'a_sha1_sum')


# puts JSON.pretty_generate(ocfl_delta.delta)
  puts ocfl_actions.all

end
