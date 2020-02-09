# frozen_string_literal: true

require 'ocfl-tools'
require 'digest'

describe OcflTools::OcflValidator do

  # Initial hard-coded tests to make sure we get errors (and no crashes) for all of the bad fixture objects.

  bad_objects  = []

  Dir.chdir('/Users/jmorley/Documents/github/fixtures/1.0/bad-objects/')
  Dir.glob('*').select do |file|
    bad_objects << file if File.directory? file
  end

#  puts "I've found these directories:"
#  puts bad_objects

  bad_objects.each do | bad_thing |
    my_object = '/Users/jmorley/Documents/github/fixtures/1.0/bad-objects/' + bad_thing
    puts "I'd proccess this: #{my_object}"
    validate = OcflTools::OcflValidator.new(my_object)

    describe 'srlsy borked' do
        validate.validate_ocfl_object_root.results
        puts validate.results.all
    end

  end

end
