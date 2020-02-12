# A simple example to demonstrate the relationship between logical content in an OCFL object
# and the fully-resolved path to those binaries on the local storage system.

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

  opts.on('-v VERSION', '--version VERSION', 'An optional version number') do |ver|
    options[:version] = ver.to_i
  end

end

opts.parse(ARGV)

raise OptionParser::MissingArgument if options[:object_root].nil?

object_root = options[:object_root]

# The inventory we're working on might not conform to the site default version format.
# Inspect the object root to determine what version format we should use, and use it.
OcflTools.config.version_format = OcflTools::Utils::Files.get_version_format(object_root)

# Get the latest inventory file from the object root.
inventory_file = OcflTools::Utils::Files.get_latest_inventory(object_root)

# Create an ocfl object from that inventory.
ocfl_object = OcflTools::OcflInventory.new.from_file(inventory_file)

# If we've been asked for a specific version, use it.
if options[:version].nil?
  version = OcflTools::Utils.version_string_to_int(ocfl_object.head)
else
  version = options[:version]
end

local_files = ocfl_object.get_files(version)

# Prepend the object root path to content_path to get fully-resolvable files.
local_files.each do | logical_path, content_path |
  local_files[logical_path] = object_root + '/' + content_path
end

# Output a pretty result, for demo purposes.
local_files.each do | logical_path, content_path |
  puts "  #{logical_path} => #{content_path}"
end
