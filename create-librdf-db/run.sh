#!/usr/bin/env bash

# checks
if [ $# -ne 2 ]; then
    echo "usage: run.sh RDF_FILE DB_FILE" 1>&2
    exit 1
fi
RDF_FILE="$1"
if [ ! -r "$RDF_FILE" ]; then
    echo "$RDF_FILE cannot be read" 1>&2
    exit 1
fi
DB_FILE="$2"
CONCEPTS_JSON_FILE="rdf_concepts.json"

# Steps

# 1. Build database from RDF triples (SQLite via redlander).
echo "running create-sqlite-db.rb..."
echo "...start: `date`"
./create-sqlite-db.rb \
  --name "$DB_FILE" --file "$RDF_FILE" --new --debug
echo "...end: `date`"

# 2. Export concepts to JSON for loading into FTS index.
echo "running export-concepts.rb..."
echo "...start: `date`"
./export-concepts.rb \
  --name "$DB_FILE" --output-file "$CONCEPTS_JSON_FILE" --debug
echo "...end: `date`"

# 3. Build annotation and namespace FTS index (SQLite).
echo "running build-fts-table.rb..."
echo "...start: `date`"
./build-fts-table.rb \
  --name "$DB_FILE" --input-file "$CONCEPTS_JSON_FILE" --debug
echo "...end: `date`"
