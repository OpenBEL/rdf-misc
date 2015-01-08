-- rebuild FTS data
delete from literals_fts;
insert into literals_fts
  select
    L.id,
    U.uri,
    US.uri,
    LI.text,
    LPL.text,
    (
      select
        group_concat(LA.text, '|')
      from
        uris     UA,
        triples  TA,
        literals LA
      where
        UA.uri = 'http://www.w3.org/2004/02/skos/core#altLabel' and
        TA.subjectUri   = T.subjectUri and
        TA.predicateUri = UA.id and
        LA.id = TA.objectLiteral
    ) as alt_labels,
    L.text
  from
    literals L,
    triples T,
    uris UM,
    uris U,
    triples TS,
    uris UP,
    uris US,
    uris UI,
    triples TI,
    literals LI,
    uris UPL,
    triples TPL,
    literals LPL
  where
    UM.uri in (
      'http://purl.org/dc/terms/identifier',
      'http://www.w3.org/2004/02/skos/core#prefLabel',
      'http://www.w3.org/2004/02/skos/core#altLabel'
    ) and
    T.predicateUri = UM.id and
    T.objectLiteral = L.id and
    T.subjectUri = U.id and
    T.subjectUri = TS.subjectUri and
    TS.predicateUri = UP.id and
    UP.uri = 'http://www.w3.org/2004/02/skos/core#inScheme' and
    US.id = TS.objectUri and
    UI.uri = 'http://purl.org/dc/terms/identifier' and
    TI.subjectUri = T.subjectUri and
    TI.predicateUri = UI.id and
    LI.id = TI.objectLiteral and
    UPL.uri = 'http://www.w3.org/2004/02/skos/core#prefLabel' and
    TPL.subjectUri = T.subjectUri and
    TPL.predicateUri = UPL.id and
    LPL.id = TPL.objectLiteral;
