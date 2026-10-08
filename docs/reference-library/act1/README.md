# Act I — A Trip to the Moon library

A research database and concept-art catalogue for the beginner act, inspired by Georges Méliès’s *Le Voyage dans la Lune* (1902). Researched 8 October 2026. The existing evidence and object records remain intact; new story indexes and art extend their coverage.

## Browse

Open [index.html](index.html) in a browser. Search names, performer names, IDs, scenery or design terms; filter by evidence type, scene and category. Open a card for its source, original observation, adaptation boundary, published performer attribution and related concept studies. It works offline when the repository folder structure is preserved; online source links need internet access.

The build has **240 catalogue records**, **89 research/design entities**, **15 cited research sources**, and **55 catalogued local images**. It retains all **116 earlier records**, including **70 object records** and **6 earlier generated studies**. The new concept collection adds **20 available art records**; counts describe files and records, not unique historical people or scenes.

| Research category | Records | Scope |
| --- | ---: | --- |
| Characters and roles | 35 | Named travellers, distinct unnamed roles, overlapping scene ensembles, celestial performers, fauna, published cast roles and three invented enemy variants |
| Environments | 17 | Ceremony, launch, lunar exterior/dream, grotto, palace, escape, sea return and celebration |
| Bosses and candidates | 5 | Two selected main encounters plus three explicitly unselected comparisons |
| Story moods | 12 | Interpretations of the emotional arc and their beginner-game implications |
| Prop/effect kits | 20 | Grouped index linking every O01–O70 observation |

[Film research](research/RESEARCH.md) explains naming and source qualifications. [Cast index](research/cast-index.json) retains the institutional credits: 11 named performers and two ensembles. No one-to-one map between the five named companions and five astronomer actor credits is fabricated.

## Level concept

[Act I concept](../../ACT1_CONCEPT.md) and [level data](research/levels.json) preserve **five main levels: 6, 8, 9, 10 and 10 minutes, totalling 43 minutes**. Three optional levels use their parent kits and separate 3–5 minute ranges; all-content guidance is **52–58 minutes**, excluding retries and deliberate replays. These are first-clear design estimates, not measured completion times.

L1 teaches gestures in a safe launch rehearsal; L2 introduces the rush commitment; L3 adds swarm/spore repulsion and spear grammar; L4 combines guards and the Selenite King; L5 tests learned responses against the Man in the Moon and closes with escape. Optional Salvage Circuit, Spore Bloom and Royal Rehearsal reinforce existing skills. They add no required boss rematch.

Keep the portrait pixel 2.5D camera, swipe-only ground dashes, immediate tap slash, a quick second-tap blast, aim from final swipe release, one carried weapon and fixed baseline damage. All mandatory paths work at normal dash length. Hittable spore clusters shed falling spores that temporarily repel swarmers. These mechanics, tutorial markers and boss attacks are game proposals.

## Concept art and visual continuity

The [new concept collection](../../concept-art/act1/README.md) covers characters, environments, bosses, mood, props and three proposed game views. Its [generation manifest](../../concept-art/act1/generated-manifest.json) retains exact prompts, reference inputs and research relationships. Generated studies are planning illustrations, not archival images, production sprites or implemented game screenshots.

The [style guide](STYLE_GUIDE.md) carries the established theatrical vocabulary: painted wings, jagged lunar flats, dark negative space, period hats/coats/beards, a finless bullet shell, giant shallow mushroom caps, upright masked rib-banded Selenites, and celestial court ornament. Moon-white, dusty silver and black are chosen game art direction; authentic hand-coloured prints remain separately identified.

| Earlier study | Image |
| --- | --- |
| G01 | [Lunar surface and celestial tableau](concepts/lunar-tableau-v2.png) |
| G02 | [Mushroom grotto layouts](concepts/mushroom-grotto-v2.png) — earlier vent treatment is superseded by falling-spore repulsion |
| G03 | [Selenite court](concepts/selenite-court-v2.png) |
| G04 | [Observatory and launch objects](concepts/observatory-launch-object-studies-v2.png) |
| G05 | [Lunar scenery and celestial objects](concepts/lunar-scenery-object-studies.png) |
| G06 | [Selenites and court objects](concepts/selenite-court-object-studies.png) |

The earlier [G01–G06 prompt manifest](generated-manifest.json), G04 revision input, original exploratory images, archival previews and link-only museum records remain preserved. The new studies extend rather than overwrite them.

## Data and provenance

| File | Purpose |
| --- | --- |
| [catalog.json](catalog.json) | Complete records plus research sources/entities/artworks, cast index, level plan, hashes and prompts |
| [catalog.csv](catalog.csv) | Flat record and level export; structured fields and full data use JSON cells |
| [library.sqlite](library.sqlite) | Relational source, entity, artwork, cast and level database with foreign keys |
| [catalog-data.js](catalog-data.js) | Embedded data for offline browsing without fetching JSON |
| [entities](research/entities.json), [sources](research/sources.json), [cast](research/cast-index.json) | Editable research records and performer attribution index |
| [O01–O42](objects-earth-and-dream.json), [O43–O70](objects-grotto-and-return.json) | Preserved original observation/adaptation manifests |
| [Source notes](research/SOURCES.md), [credits](CREDITS.md), [verification](VERIFICATION.md) | Evidence, licence declarations and build checks |

Legacy F01–F13/A01–A17/M01–M09/USER01/O01–O70/G01–G06 IDs remain stable. New C/E/B/D/P/S families and later G IDs connect the research and art. D01–D12 mood IDs avoid colliding with museum M IDs. Film imagery, original costume, c.1930–31 and 1937 retrospective drawings, the 1960 reconstruction, and generated game concepts retain separate provenance.

The legacy `sources` table retains its integer URL IDs. `research_sources` stores S01–S15 citation metadata. New tables include `entities`, `entity_sources`, `entity_relations`, `scene_refs`, `cast_members`, `artworks`, artwork joins, `levels`, `level_beats`, `level_bosses`, `adaptation_enemies`, and `level_enemies`. Full research/level records are preserved as JSON.

```sql
SELECT id, title, canon_status FROM entities WHERE category = 'characters';
SELECT name, role FROM cast_members;
SELECT e.title, s.title, s.url FROM entities e JOIN entity_sources es ON e.id=es.entity_id JOIN research_sources s ON s.id=es.source_id;
SELECT id, title, target_minutes FROM levels WHERE kind='main';
SELECT l.title, e.title FROM levels l JOIN level_bosses b ON l.id=b.level_id JOIN entities e ON e.id=b.entity_id;
SELECT a.title, e.title FROM artworks a JOIN artwork_entities ae ON a.id=ae.artwork_id JOIN entities e ON e.id=ae.entity_id;
```

## Rebuild

Edit the curated research/object files or generation manifest, then run from the repository root:

```sh
python3 scripts/research/build_moon_library.py --strict-art
```

The standard-library builder checks IDs, evidence references, source/entity/art joins, local art files, the five-level/43-minute budget, encounter beat sums and SQLite integrity/foreign keys. It regenerates JSON, CSV, browser data, SQLite, credits and this README. The default build omits planned/failed art records; strict mode rejects unfinished entries. Preserve the concept-art directories beside the reference library for offline image paths.

The earlier `download_moon_references.py` is optional archival collection tooling; no new archival downloads were required for this extension.
