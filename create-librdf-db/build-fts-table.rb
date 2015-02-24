#!/usr/bin/env ruby

require 'optparse'
require 'sqlite3'
require 'multi_json'

# defaults
options = {
  name: 'rdf.db',
  debug: false,
  input_file: 'concepts.json'
}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: build-fts-table.rb -n DATABASE_NAME -i FILE"
  opts.on("-n", "--name NAME", "Storage name     (defaults to #{options[:name]})") do |name|
    options[:name] = name
  end
  opts.on("-i", "--input-file FILE", "Input file to read concept JSON from.    (defaults to #{options[:input_file]})") do |input_file|
    options[:input_file] = input_file
  end
  opts.on("-d", "--debug", "Debug?           (defaults to #{options[:debug]})") do
    options[:debug] = true
  end
end
parser.parse!

if not File.readable?(options[:input_file])
  $stderr.puts "The #{options[:input_file]} file is not readable.\n"
  exit 1
end

def symbolize_keys!(hash)
  hash.keys.each do |key|
    hash[key.to_sym] = hash.delete(key)
  end
  hash
end

db = SQLite3::Database.new options[:name]
jf = File.new(options[:input_file], "r")
db.execute('''PRAGMA journal_mode = OFF''')
db.execute('''PRAGMA synchronous = OFF''')
db.execute('''
  CREATE VIRTUAL TABLE
    concepts_fts
  USING
    fts4(uri, concept_type, scheme_uri, identifier, pref_label, title, text, tokenize=unicode61 "tokenchars=,-()\'./[]+")
''')
fts_db_stmt = db.prepare(
  '''insert into
       concepts_fts(uri, concept_type, scheme_uri, identifier, pref_label, title, text)
     values
       (:uri, :concept_type, :inScheme, :identifier, :prefLabel, :title, :text)'''
)
begin
  i = 0
  jf.each do |line|
    concept = symbolize_keys!(MultiJson.load(line))
    fts_db_stmt.execute(
      :uri => concept[:uri],
      :concept_type => concept[:concept_type],
      :inScheme     => concept[:inScheme].first,
      :identifier   => concept[:identifier],
      :prefLabel    => concept[:prefLabel],
      :title        => concept[:title],
      :text         => concept[:text]
    )

    i+=1
    if options[:debug] && i % 5000 == 0
      puts "#{i} concepts fts-indexed"
    end
  end
ensure
  fts_db_stmt.close
  db.execute('''INSERT INTO concepts_fts(concepts_fts) VALUES(\'optimize\')''');
  db.close
end
# vim: ts=2 sw=2
