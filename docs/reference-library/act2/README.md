# Act II — The War of the Worlds

Open [index.html](index.html) for the offline, searchable story database and concept-art gallery. No server, install, or internet connection is needed to browse it. Source links open online.

This build contains **199 research/design entities**, **4 cited sources**, and **20 available images** (20 art records). The three gameplay images are proposed compositions, not screenshots of an implemented campaign.

Research distinguishes **Novel fact**, **Interpretation**, and **Game proposal**. Chapter references describe the novel; adaptation notes explain the proposed gameplay. Boss sheets may compare unused candidates. Human characters do not automatically become enemies.

## Files

- [Research entities](research/entities.json) and [sources](research/sources.json): editable research sources.
- [JSON](catalog.json): complete portable database with research, art, metadata, and provenance.
- [CSV](catalog.csv): flat entity and artwork export; arrays are JSON inside CSV cells.
- [SQLite](library.sqlite): relational database with foreign keys and full source-record JSON.
- [Level plan](research/levels.json): main and optional level budgets, encounter beats, checkpoints, and boss/enemy assignments.
- [Source credits](CREDITS.md): publication and generation provenance.
- [Concept-art folder](../../concept-art/act2/README.md): category folders, prompts, and game views.
- [Act II concept](../../ACT2_CONCEPT.md): proposed levels and experienced-player pacing.

- [Verification](VERIFICATION.md): completed checks and the limit on browser visual inspection.

## Rebuild

From the repository root, run:

```sh
python3 scripts/research/build_invasion_library.py
```

Add `--strict-art` for a final delivery check: every image listed in the generation manifest must exist. Default builds retain planned image records and report missing files without counting them as available art.

The builder validates unique IDs, source references, artwork-to-entity links, image paths and PNG headers; records SHA-256 hashes, sizes and dimensions; and runs SQLite foreign-key and integrity checks. It uses only Python's standard library.

## SQLite examples

```sql
SELECT id, title FROM entities WHERE category = 'characters';
SELECT id, title, game_adaptation FROM entities WHERE category = 'bosses';
SELECT e.title, c.label FROM entities e JOIN chapter_refs c ON e.id = c.entity_id;
SELECT a.title, e.title FROM artworks a JOIN artwork_entities ae ON a.id = ae.artwork_id JOIN entities e ON e.id = ae.entity_id;
SELECT e.title, s.title, s.url FROM entities e JOIN entity_sources es ON e.id = es.entity_id JOIN sources s ON s.id = es.source_id;
SELECT id, title, target_minutes FROM levels WHERE kind = 'main';
SELECT l.title, e.title FROM levels l JOIN level_bosses b ON l.id = b.level_id JOIN entities e ON e.id = b.entity_id;
```
