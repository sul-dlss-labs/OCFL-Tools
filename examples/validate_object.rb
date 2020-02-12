# Usage: ruby ./validate_object.rb /path/to/directory/to/check
require 'ocfl-tools'
require 'optparse'

options = {}

opts = OptionParser.new do |opts|
  opts.on('-d DIRECTORY', '--dir DIRECTORY', 'A directory containing an OCFL object') do |dir|
    unless Dir.exist?(dir)
      raise "#{dir} is not a valid directory path."
    end
    options[:object_root] = dir
  end
end

opts.parse(ARGV)

raise OptionParser::MissingArgument if options[:object_root].nil?

object_root = options[:object_root]


OcflTools::OcflValidator.new(object_root).validate_ocfl_object_root.print
