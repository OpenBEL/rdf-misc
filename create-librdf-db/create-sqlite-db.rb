#!/usr/bin/env ruby

require 'pry'
require 'optparse'
require 'redlander'
require 'sqlite3'
require 'uri'
require 'multi_json'

# defaults
options = {
  new: 'no',
  name: 'default_db',
  debug: false
}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: load-sqlite.rb -f file1 [ -f file2 ]"
  opts.on('-f', '--file FILE', 'RDF file to load (one or more)') do |f|
    if f.start_with? '/'
      path = "file://#{f}"
    else
      local_dir = File.dirname(File.expand_path(__FILE__))
      path = "file://#{local_dir}/#{f}"
    end
    (options[:files] ||= []) << path
  end
  opts.on("-n", "--name NAME", "Storage name     (defaults to 'default_db')") do |name|
    options[:name] = name
  end
  opts.on("-w", "--new", "New storage?     (defaults to 'no')") do
    options[:new] = 'yes'
  end
  opts.on("-d", "--debug", "Debug?           (defaults to off)") do
    options[:debug] = true
  end
end

parser.parse!

unless options[:files]
  $stderr.puts("An rdf file is required.\n\n");
  $stderr.puts parser
  exit 1
end

if options[:new] != 'yes' and not File.exist? options[:name]
  options[:new] = 'yes'
end

def which_parser(file)
  case
  when file.end_with?('.nt')
    'ntriples'
  when file.end_with?('.nq')
    'nquads'
  when file.end_with?('ttl')
    'turtle'
  when ['.rdfxml', '.xml'].include?(file[file.rindex('.')..-1])
    'rdfxml'
  else
    'guess'
  end
end

model = Redlander::Model.new(
  new: options[:new],
  name: options[:name],
  storage: 'sqlite',
  synchronous: 'off')

if options[:files]
  options[:files].each do |path|
    parser = which_parser(path)

    options[:debug] && $stdout.puts("Loading #{path} (parser - #{parser}).")
    model.transaction_start!
    begin
      model.from(URI(path), format: parser)
    ensure
      model.transaction_commit!
    end
  end
end
# vim: ts=2 sw=2
