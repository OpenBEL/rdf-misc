-- create text index for rdf literals
create index literals_text_index on literals(text);

-- create int index for object uri of rdf triples
create index triples_ou_index    on triples(objectUri);

-- create int index for object literal of rdf triples
create index triples_ol_index    on triples(objectLiteral);

-- create int index for [predicate,obj ur] of rdf triples
create index triples_pou_index   on triples(predicateUri, objectUri);

-- create int index for [predicate,obj literal] of rdf triples
create index triples_pol_index   on triples(predicateUri, objectLiteral);

-- create int index for [subject,predicate,obj uri] of rdf triples
create index triples_spou_index  on triples(subjectUri, predicateUri, objectUri);

-- create int index for [subject,predicate,obj literal] of rdf triples
create index triples_spol_index  on triples(subjectUri, predicateUri, objectLiteral);

-- create FTS4 virtual table to store SKOS concepts with uri/type/scheme/identifier/pref_label/alt_labels
CREATE VIRTUAL TABLE literals_fts USING fts4(id INTEGER, uri TEXT, scheme_uri TEXT, identifier TEXT, pref_label TEXT, alt_labels TEXT, text TEXT, tokenize=porter);

