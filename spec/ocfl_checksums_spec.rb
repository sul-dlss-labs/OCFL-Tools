# frozen_string_literal: true

require 'ocfl-tools'
require 'digest'

describe OcflTools::OcflValidator do
  # resolve our path to test fixtures to a full system path
  # object_a = File.expand_path('./spec/fixtures/validation/object_a')
  local_path_a = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', 'object_a')
  validate_a = OcflTools::OcflValidator.new("#{local_path_a}")
  OcflTools.config.content_directory = 'data'

  # TODO: fix expand_path so we're not tying the results to my local machine's directory structure.
  # local_path = object_a.delete_suffix('/spec/fixtures/validation/object_a')
  # local_path = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', 'object_a')

  # local_path should stay the same for all fixtures.

  describe 'perfect object a' do
    it 'checks checksums from manifest' do
      expect(validate_a.verify_checksums.all).to match(
        'error' => {}, 'warn' => {}, 'info' => {}, "ok" => {"O200"=>{"verify_checksums"=>["All digests successfully verified."]}}
      )
    end
  end

  local_path_e = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', 'object_e')
#  object_e = File.expand_path('./spec/fixtures/validation/object_e')
  validate_e = OcflTools::OcflValidator.new("#{local_path_e}")

  describe 'object e is missing a file on disk' do
    it 'checks checksums from manifest' do
      expect(validate_e.verify_checksums.all).to match(
        'error' => { 'E111' => { 'verify_checksums' => ["#{local_path_e}/v0003/data/my_content/dickens.txt in inventory but not found on disk."] } }, 'warn' => {}, 'info' => {}, 'ok' => {}
      )
    end
  end

#  object_f = File.expand_path('./spec/fixtures/validation/object_f')
  local_path_f = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', 'object_f')
  validate_f = OcflTools::OcflValidator.new("#{local_path_f}")

  describe 'object f has a file on disk version 3 that does not exist in manifest version 3' do
    it 'checks checksums from manifest' do
      expect(validate_f.verify_checksums.all).to match(
        'error' => { 'E111' => { 'verify_checksums' => ["#{local_path_f}/v0003/data/my_content/dickens.txt found on disk but missing from inventory.json."] } }, 'warn' => {}, 'info' => {}, 'ok' => {}
      )
    end
  end

#   object_g = File.expand_path('./spec/fixtures/validation/object_g')
  local_path_g = File.join(File.dirname(__dir__), 'spec', 'fixtures', 'validation', 'object_g')
  validate_g = OcflTools::OcflValidator.new("#{local_path_g}")

  describe 'object g has a bad digest in the manifest file' do
    it 'checks checksums from manifest' do
      expect(validate_g.verify_checksums.all).to match(
        'error' => { 'E111' => { 'verify_checksums' => ["#{local_path_g}/v0003/data/my_content/dickens.txt digest in inventory does not match digest computed from disk"] } }, 'warn' => {}, 'info' => {}, 'ok' => {}
      )
    end
  end
end
