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

