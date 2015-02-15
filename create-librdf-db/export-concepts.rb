#!/usr/bin/env ruby

require 'optparse'
require 'redlander'
require 'uri'
require 'multi_json'

# defaults
options = {
  new: 'no',
  name: 'rdf.db',
  debug: false,
  output_file: 'concepts.json'
}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: export-concepts.rb -n DATABASE_NAME -o FILE"
  opts.on("-n", "--name NAME", "Storage name     (defaults to #{options[:name]})") do |name|
    options[:name] = name
  end
  opts.on("-o", "--output-file FILE", "Output file to write concept JSON to.    (defaults to #{options[:output_file]})") do |output_file|
    options[:output_file] = output_file
  end
  opts.on("-d", "--debug", "Debug?           (defaults to off)") do
    options[:debug] = true
  end
end

parser.parse!

AN_CONCEPT = 'http://www.openbel.org/vocabulary/AnnotationConcept'
NS_CONCEPT = 'http://www.openbel.org/vocabulary/NamespaceConcept'
RDF_TYPE   = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'

# describe the uri and collect [predicate,object] pairs to a hash
def describe_concept(concept_uri, concept_type, rdf_model)
  concept = Hash.new { |hash, key| hash[key] = [] }
  concept[:uri] = concept_uri
  concept[:concept_type] = concept_type
  rdf_model.statements.each(
    :subject => Redlander::Node.new(concept_uri[1...-1], :resource => true),
    :predicate => nil,
    :object => nil
  ) do |rdf_s|
    predicate = rdf_s.predicate.to_s
    object    = rdf_s.object.respond_to?(:value) ? rdf_s.object.value.to_s : rdf_s.object.to_s

    index = predicate.rindex('#') || predicate.rindex('/')
    if index
      attribute = predicate[index+1...-1]
      concept[attribute.to_sym] << object
    end
  end

  # derive :text value
  [ :type, :identifier, :prefLabel, :title, :altLabel ].each do |key|
    concept[key] = concept[key].join(' ').squeeze(' ').strip()
  end
  id  = concept[:identifier]
  lbl = concept[:prefLabel]
  ttl = concept[:title]
  alt = concept[:altLabel]
  concept[:text] = "#{id} #{lbl} #{ttl} #{alt}".squeeze(' ').strip()

  concept
end

def map_concepts(rdf_model, concept_type, concept_type_uri)
  rdf_model.statements.each(
    :subject => nil,
    :predicate => Redlander::Node.new(RDF_TYPE, :resource => true),
    :object => Redlander::Node.new(concept_type_uri, :resource => true)
  ).each { |rdf_s|
    yield describe_concept(rdf_s.subject.to_s, concept_type, rdf_model)
  }
end

output_file = File.new(options[:output_file], File::CREAT|File::TRUNC|File::RDWR, 0644)
begin
  rdf_model = Redlander::Model.new(name: options[:name], storage: 'sqlite', synchronous: 'off')
  if options[:debug]
    puts "Mapping concepts to JSON for annotation concepts"
  end
  i = 0
  map_concepts(rdf_model, :annotation_concept, AN_CONCEPT) do |concept|
    output_file << (MultiJson.dump(concept) + "\n")
    i += 1
    if i % 5000 == 0
      output_file.flush
      puts "#{i} annotation concepts exported" if options[:debug]
    end
  end

  if options[:debug]
    puts "Mapping concepts to JSON for namespace concepts"
  end
  i = 0
  map_concepts(rdf_model, :namespace_concept, NS_CONCEPT) do |concept|
    output_file << (MultiJson.dump(concept) + "\n")
    i += 1
    if i % 5000 == 0
      output_file.flush
      puts "#{i} namespace concepts exported" if options[:debug]
    end
  end
ensure
  output_file.close
end
# vim: ts=2 sw=2
