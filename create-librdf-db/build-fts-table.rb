#!/usr/bin/env ruby

require 'optparse'
require 'sqlite3'
require 'multi_json'
require_relative 'fts_functions'

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

def value_s(value)
  if value.respond_to?(:each)
    value.join(' ')
  else
    value.to_s
  end
end

def concept_text(concept)
  whole = ""
  whole.concat(
    value_s(concept[:identifier])
  ).concat(" ")
  whole.concat(
    value_s(concept[:prefLabel])
  ).concat(" ")
  whole.concat(
    value_s(concept[:title])
  ).concat(" ")
  whole.concat(
    value_s(concept[:altLabel])
  )
  divide_value(whole)
end

db = SQLite3::Database.new options[:name]
jf = File.new(options[:input_file], "r")
db.execute('''PRAGMA journal_mode = OFF''')
db.execute('''PRAGMA synchronous = OFF''')
db.execute('''
  CREATE VIRTUAL TABLE
    concepts_fts
  USING
    fts4(
      uri, concept_type, scheme_uri, identifier, pref_label, title, alt_labels, text,
      notindexed=uri, notindexed=concept_type, notindexed=scheme_uri, tokenize=unicode61 "tokenchars=,-()\'./[]+")
''')
fts_db_stmt = db.prepare(
  '''insert into
       concepts_fts(uri, concept_type, scheme_uri, identifier, pref_label, title, alt_labels, text)
     values
       (:uri, :concept_type, :inScheme, :identifier, :prefLabel, :title, :alt_labels, :text)'''
)
begin
  i = 0
  jf.each do |line|
    concept = symbolize_keys!(MultiJson.load(line))
    fts_db_stmt.execute(
      :uri          => value_s(concept[:uri]),
      :concept_type => value_s(concept[:concept_type]),
      :inScheme     => value_s(concept[:inScheme].first),
      :identifier   => value_s(concept[:identifier]),
      :prefLabel    => value_s(concept[:prefLabel]),
      :title        => value_s(concept[:title]),
      :alt_labels   => value_s(concept[:altLabel]),
      :text         => value_s(concept_text(concept))
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
