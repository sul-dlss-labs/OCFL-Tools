# Usage: ruby ./validate_object.rb /path/to/directory/to/check
require 'ocfl-tools'
require 'digest'

object_root = ARGV[0]

unless Dir.exist?(object_root)
  raise "#{object_root} is not a valid directory path."
end

OcflTools::OcflValidator.new(object_root).validate_ocfl_object_root.print
