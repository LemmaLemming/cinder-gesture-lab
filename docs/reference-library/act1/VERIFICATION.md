# Act I verification

Rebuilt 8 October 2026 with the standard-library catalogue builder. This report records database/file validation; it does not claim campaign implementation, playtesting or gameplay balance.

## Result

- Catalogue: **240 records**, including all **116 earlier records** and **70 existing object records**.
- Research: **89 entities**, **15 sources**, and **13 performer/ensemble attribution entries**.
- Images: **55 catalogued local images**; **20 new generated art records**. Every available image resolves locally and has a SHA-256 hash and file-size metadata.
- Level plan: **5 main levels**, budgets **6, 8, 9, 10, 10 minutes**, total **43 minutes**; **3 optional levels**.
- Strict-art mode: **enabled; every declared entry is finished and its file exists**.
- SQLite integrity check: **ok**. Foreign-key violations: **0**.
- Unique catalogue/research/source/art IDs, valid legacy evidence links, valid canonical-basis links, valid art/entity/source joins, level-boss links and encounter beat budgets: **passed**.
- P01–P20 prop kits cover **every O01–O70 record**.
- JSON, offline JS, CSV, relational SQLite, credits and README derive from the same curated input. CSV includes the eight level rows as well as catalogue records.

## Database rows

| Table | Rows |
| --- | ---: |
| `records` | 240 |
| `entities` | 89 |
| `research_sources` | 15 |
| `cast_members` | 13 |
| `artworks` | 20 |
| `artwork_entities` | 155 |
| `artwork_sources` | 67 |
| `levels` | 8 |
| `level_beats` | 35 |
| `level_bosses` | 2 |
| `adaptation_enemies` | 3 |
| `level_enemies` | 5 |
| `level_record_references` | 77 |

## Evidence limits

Original source-object manifests, archival previews, museum links, six earlier generated studies and exploratory revisions remain preserved. No new archival downloads or museum image copying were needed. Museum reconstruction and retrospective drawings retain their dates and kinds. Names, unnamed scene roles, published performer attributions and invented enemy variants remain separate.

The browser uses embedded catalog-data.js and relative image paths. Interactive gallery validation and visual inspection of generated concept art are performed separately from these database checks. Three game-view images are proposed compositions; gesture behaviour, timing, onboarding success and first-clear budgets still need implementation and playtesting.

## Final concept-art validation

The strict build contains **20 new images**: 4 character sheets, 5 environment boards, 3 boss boards, 3 mood boards, 2 prop boards and **3 proposed game views**. All 20 are actual PNG files with verified header dimensions, matching file hashes, nonempty generation prompts and valid source/entity links. There are **155 artwork/entity joins** and **67 artwork/source joins**. The CSV has **248 unique rows**: 240 catalogue records and 8 level records.

The original Commons metadata, O01–O70 manifests, G01–G06 generation manifest, film-still files and earlier reference concept images have no Git changes.

## Manual browser verification — 8 October 2026

The offline gallery was served locally and checked in the Codex in-app browser after the strict rebuild. Its header shows 240 records, 55 local images and 89 research entities. Category filters show 39 character/art records, 22 environment/art records, 8 boss/art records, 15 mood/art records, 22 prop/art records and exactly 3 game views. Search by C14 opens the Moon character evidence; G26 opens the full portrait concept with source and related-record links. All three game-view images loaded with nonzero natural dimensions. These are browser/data checks, not playable-game or mobile-device tests.
