#!/usr/bin/env ruby

require 'optparse'
require 'redlander'
require 'sqlite3'
require 'uri'

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

# create indexes post insert (if new)
if options[:new] == 'yes'
  db = SQLite3::Database.new options[:name]

  begin
    # create key indexes
    options[:debug] && $stdout.puts("Creating key indexes on tables, literals and triples.")
    db.execute('create index literals_text_index on literals(text);')
    db.execute('create index triples_ol_index on    triples(objectLiteral);')
    db.execute('create index triples_pou_index on   triples(predicateUri, objectUri);')
    db.execute('create index triples_pol_index on   triples(predicateUri, objectLiteral);')
    db.execute('create index triples_spou_index on  triples(subjectUri, predicateUri, objectUri);')
    db.execute('create index triples_spol_index on  triples(subjectUri, predicateUri, objectLiteral);')

    # create fts4 index
    options[:debug] && $stdout.puts("Creating 'literals_fts' FTS4 virtual table for 'literals' table; use Porter Stemming algorithm.")
    db.execute('create virtual table literals_fts USING fts4(id, uri, scheme_uri, text, tokenize=porter);')
  ensure
    db.close
  end
end

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

db = SQLite3::Database.new options[:name]

begin
  # refresh data in literals_fts
  options[:debug] && $stdout.puts("Refreshing 'literals_fts' FTS4 virtual table with data from 'literals' table (delete & insert).")
  db.execute('delete from literals_fts;')
  db.execute("insert into literals_fts
                select
                  L.id, U.uri, US.uri, L.text
                from
                  literals L, triples T, uris UM, uris U, triples TS, uris UP, uris US
                where
                  UM.uri in (
                    'http://purl.org/dc/terms/identifier',
                    'http://www.w3.org/2004/02/skos/core#prefLabel',
                    'http://purl.org/dc/terms/title',
                    'http://www.w3.org/2004/02/skos/core#altLabel'
                  ) and
                  T.predicateUri = UM.id and
                  T.objectLiteral = L.id and
                  T.subjectUri = U.id and
                  T.subjectUri = TS.subjectUri and
                  TS.predicateUri = UP.id and
                  UP.uri = 'http://www.w3.org/2004/02/skos/core#inScheme' and
                  US.id = TS.objectUri;")
ensure
  db.close
end

# vim: ts=2 sw=2
