# Act 1 — A Trip to the Moon visual library

Current planning reference for the game's moon-white, dusty-silver and black act, inspired by Georges Méliès's *Le Voyage dans la Lune* (1902). Researched 8 October 2026. This library translates the film's handmade theatrical imagery into portrait, gesture-driven game concepts.

## Browse

Open [index.html](index.html) in a browser. It works offline from this folder: search words or IDs, filter by reference type and film sequence, then open a card for the full image, source, date, adaptation notes and related records. Source links need internet access. Keep `catalog-data.js`, `film-stills/` and `concepts/` beside the HTML file.

The catalogue has **116 records**:

| Group | Records | Contents |
| --- | ---: | --- |
| Film object catalogue | 70 | Props, costumes, characters, scenery, effects and a reused capsule state; each separates observation from proposed game use. |
| Archival and historical references | 40 | Film frames, production photographs, the supplied reference crop, historical drawings/posters, a surviving costume and a later reconstruction. Includes repeated compositions, alternate crops and link-only museum records. |
| New game studies | 6 | Three environment studies and three object-study boards generated from the selected references. |

There are **35 catalogued local images**: 29 archival/user previews and six final generated studies. Eleven historical records are source links without copied image pixels. The first version of G04 is also retained in `concepts/` as an uncatalogued revision input. These counts describe records and previews, not 116 unique film objects or 40 unique scenes.

## Current design direction

Use painted-looking stage wings and backdrops, jagged lunar rocks with broad white marks, Victorian travellers, a finless bullet capsule, giant shallow-capped fungi, human celestial performers, and upright rib-patterned Selenites. Build the royal court from curling panels, radial roundels, crescents and drapery. The [style guide](STYLE_GUIDE.md) connects 18 visual rules to source frames and institutional records.

The film's widescreen tableaux become layered scenery around generous playable floors. Preserve the close camera that follows the player, any-angle swipe-only dashes, tap slash, double-tap blast, swipe-end-relative aiming, one carried weapon and fixed baseline damage. Optional levels reuse their regular level's scenery and enemies with a few new props, hazards or formations. The current mushroom design uses hittable spore clusters whose falling spores temporarily repel a swarm. Broader environment interactables will be designed after enemy behaviours. Bell markers, spore interactions, salvage objectives and boss patterns are game additions.

## New concept art

Generated with the **built-in image generation tool**, using locally saved film references. These are planning illustrations, not archival pictures, production sprites, tile sets or playable levels. The monochrome treatment is the chosen game palette; the library separately tags authentic handcoloured print references.

| ID | Final saved image | Purpose |
| --- | --- | --- |
| G01 | [Lunar surface and celestial tableau](concepts/lunar-tableau-v2.png) | Jagged scenic rock wings, Earth/crescent/Saturn figures, finless capsule, Victorian traveller and biped Selenites. |
| G02 | [Giant mushroom grotto](concepts/mushroom-grotto-v2.png) | Paired regular/optional layouts sharing a fungal scenery kit. The earlier vent depiction is superseded by the current hittable-spore repulsion design; a future art pass should show clusters and retreating swarmers. |
| G03 | [Painted Selenite court](concepts/selenite-court-v2.png) | Celestial stage ornament, open combat floor and small optional rehearsal additions. |
| G04 | [Observatory and launch objects](concepts/observatory-launch-object-studies-v2.png) | Twelve labelled studies; worker costume corrected against the workshop frame. |
| G05 | [Lunar scenery and celestial objects](concepts/lunar-scenery-object-studies.png) | Twelve labelled studies of painted scenery, celestial performers and grotto pieces. |
| G06 | [Selenites and court objects](concepts/selenite-court-object-studies.png) | Twelve labelled studies of characters, court ornament, a square-puff adaptation and commemorative props. |

The complete [prompt set and generation manifest](generated-manifest.json) retains each prompt, film reference IDs, related object IDs, final image path, and G04's targeted revision. The [earlier three environment images](../../concept-art/act1/README.md) remain as a superseded exploratory pass.

## Provenance and credits

Film images provide the main evidence for visible shapes. MoMA dates its [grotto drawing](https://www.moma.org/collection/works/38318) and related scene drawings to c.1930–31. The Cinémathèque records the [two Selenites drawing](https://www.cinematheque.fr/objet/400.html) as 1937 and the [Labisse reconstruction](https://www.cinematheque.fr/objet/1540.html) as 1960. These are later interpretations, rather than automatically original 1902 production plans. Its [archives essay](https://www.cinematheque.fr/article/1881.html) distinguishes painted set designs from retrospective recompositions. The [astronomer's embroidered mantle](https://www.cinematheque.fr/objet/392.html) is a surviving film costume.

Every reference retains source URLs, creator/credit metadata, dates, licence declarations and uncertainty notes. See [CREDITS.md](CREDITS.md) and the full [Commons metadata manifest](commons-manifest.json). A03's source declares CC BY-SA 4.0; its credit and licence link are retained. Museum images are linked only. The supplied crop's provenance is unspecified. Commons date discrepancies are preserved explicitly rather than silently promoted to historical facts.

F01–F13 are numbered scene-frame records; A01–A17 are additional reproductions and historical references; M01–M09 are museum catalogue records; USER01 is the supplied crop; O01–O70 are object observations and game-use proposals; G01–G06 are newly generated concepts. No frame timestamps or animation timings are claimed from still images.

## Data files

| File | Use |
| --- | --- |
| [catalog.json](catalog.json) | Complete structured catalogue, source links, related IDs, style rules, image hashes and prompts. |
| [catalog.csv](catalog.csv) | Spreadsheet-friendly object/reference export; list fields use JSON arrays inside cells. |
| [library.sqlite](library.sqlite) | Queryable relational database with indexed type, sequence and scenery-kit fields. |
| [catalog-data.js](catalog-data.js) | The same catalogue embedded for offline browsing without fetching JSON. |
| [objects-earth-and-dream.json](objects-earth-and-dream.json) | Curated O01–O42 observations and adaptation proposals. |
| [objects-grotto-and-return.json](objects-grotto-and-return.json) | Curated O43–O70 observations and adaptation proposals. |

SQLite tables are `records`, `sources`, `record_sources` and `record_references`. Example queries:

```sql
-- Scenery, costumes, characters and props available to the court kit.
SELECT id, title, description, adaptation
FROM records
WHERE kind = 'film-object' AND sequence = 'Selenite Court';

-- Evidence images related to the crescent performer object.
SELECT r.id, r.title, r.local_path
FROM record_references AS rr
JOIN records AS r ON r.id = rr.reference_id
WHERE rr.record_id = 'O40';
```

## Maintain

Edit the curated object manifests or generation manifest, then rebuild from the repository root using Python's standard library:

```sh
python3 scripts/research/build_moon_library.py
```

The builder checks unique IDs, related IDs, local files, SQLite integrity and foreign keys, then regenerates JSON, CSV, browser data, SQLite and credits. Local image hashes are included in the catalogue.

`scripts/research/download_moon_references.py` records Commons Imageinfo metadata and downloads small source-served previews sequentially. It skips existing images and stops on a rate-limit response. It does not download the film. Re-collection is optional: inspect category/source changes and stable IDs before accepting an updated manifest.
