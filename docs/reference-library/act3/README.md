# Act III — A Voyage to Arcturus

Open [index.html](index.html) for the searchable, offline story database, concept-art gallery and level plan. Keep `catalog-data.js` beside it. No install, server or internet connection is needed for the library; source publications open online.

This build contains **129 story/design records**, **3 cited sources**, **20 available concept images**, and **5 main + 3 optional proposed levels**. The **3 game views** are illustrative gameplay concepts, not captures of an implemented Act III campaign.

The library labels **Novel fact**, **Interpretation**, and **Game proposal** separately. Source descriptions and chapter references summarize David Lindsay's 1920 novel; adaptation notes, bosses, invented forms, concrete appearances and generated art are proposals. See [research scope and limitations](research/RESEARCH.md) for the character-inventory boundary and edition notes.

## Files

- [JSON database](catalog.json): full research, art, level plan, joins, metadata and provenance.
- [CSV database](catalog.csv): entities, artworks and levels; arrays and full records are JSON inside cells.
- [SQLite database](library.sqlite): relational records, source and chapter joins, levels and beat/checkpoint tables. `search_records` always exists; `search_fts` is included when the Python SQLite runtime supports FTS5.
- [Research entities](research/entities.json), [source list](research/sources.json) and [level source](research/levels.json): editable inputs.
- [Novel chapter registry](research/chapters.json): chapter URLs and source IDs, also exported in JSON and SQLite.
- [Name and alias index](research/name-index.json): merged aliases, shared identities and group records, also exported in JSON and SQLite.
- [Research summary](research/RESEARCH.md) and [source notes](research/SOURCES.md).
- [Concept-art folder](../../concept-art/act3/README.md) and [generation manifest](../../concept-art/act3/generated-manifest.json).
- [Act III concept](../../ACT3_CONCEPT.md): experienced-player pacing and adaptation rationale.

## Rebuild

From the repository root:

```sh
python3 scripts/research/build_arcturus_library.py
python3 scripts/research/build_arcturus_library.py --strict-art
```

The default build retains planned or unavailable art and reports it truthfully. `--strict-art` requires every manifest image to exist, have readable image dimensions, and have `status: generated` confirmed in the source manifest. File existence alone never changes a planned record into generated art.

The builder validates IDs, source and entity links, level links, safe image paths, beat durations and checkpoint order; records file dimensions, byte sizes and SHA-256 hashes; and runs SQLite foreign-key and integrity checks. It uses only Python's standard library. Generated files can be rebuilt without changing the research inputs.

## Query examples

```sql
SELECT id, title FROM entities WHERE category = 'characters';
SELECT name, entity_id, identity_group_id, identity_parent_id FROM name_index ORDER BY name;
SELECT id, title, game_adaptation FROM entities WHERE category = 'bosses';
SELECT e.title, c.label FROM entities e JOIN chapter_refs c ON e.id = c.entity_id;
SELECT e.title, s.title, s.url FROM entities e JOIN entity_sources es ON e.id = es.entity_id JOIN sources s ON s.id = es.source_id;
SELECT a.title, e.title FROM artworks a JOIN artwork_entities ae ON a.id = ae.artwork_id JOIN entities e ON e.id = ae.entity_id;
SELECT l.title, b.name, b.seconds, b.checkpoint_elapsed_seconds FROM levels l JOIN level_beats b ON l.id = b.level_id ORDER BY l.position, b.position;
SELECT id, title FROM search_records WHERE lower(search_text) LIKE '%crystalman%';
SELECT id, title FROM search_fts WHERE search_fts MATCH 'Maskull';
```
