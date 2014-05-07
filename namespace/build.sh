#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -ne 1 ]; then
    echo "usage: build.sh [NS URL]" 1>&2
    exit 1
fi

URL="$1"
export JVM_ARGS="-Xmx8g"

echo "downloading from $URL"
curl $URL > namespaces.ttl

echo "stream out model + rdfs inference"
jena/bin/riot --time --check --strict --stop \
              --rdfs=schema.nt namespaces.ttl | gzip > namespaces.nq.gz

echo "build TDB"
jena/bin/tdbloader --loc=db namespaces.nq.gz

echo "infer exactMatch through CONSTRUCT"
jena/bin/tdbquery --loc=db --query=exactMatch.sparql | gzip > exactMatch.ttl.gz
jena/bin/tdbloader --loc=db exactMatch.ttl.gz

echo "infer orthologousMatch through CONSTRUCT"
jena/bin/tdbquery --loc=db --query=orthologousMatch.sparql | gzip > orthologousMatch.ttl.gz
jena/bin/tdbloader --loc=db orthologousMatch.ttl.gz

echo "dumping all"
jena/bin/tdbdump --loc=db | gzip > namespaces-inferred.nq.gz

echo "clean up"
rm namespaces.nq.gz
rm -fr ./db
rm exactMatch.ttl.gz
rm orthologousMatch.ttl.gz