# Act II library verification

Checked on 8 October 2026. This is a research and concept-art delivery; the Act II campaign remains an unimplemented, unplaytested proposal.

## Completed checks

- The final research contains 199 uniquely identified entities and four source records. All 398 entity/source relationships resolve. The 452 chapter references are retained; ordinary chapter labels are also parsed into book, chapter, and title fields for database queries.
- All 20 image files listed in the generation manifest were present. Each has recorded dimensions, byte size, and SHA-256 hash; the files have 20 distinct hashes. The three game-view images are portrait compositions.
- The JSON, offline JavaScript data, CSV, and SQLite exports agree. The CSV contains 219 entity/art rows. The 134 art/entity relationships, six canonical-basis relationships, boss assignments, optional-level parents, and regular-enemy relationships resolve.
- SQLite reports `integrity_check = ok` and no foreign-key violations. Five main-level budgets total 45 minutes. All 22 encounter/boss beats match their level budgets. Three optional levels each target 3–5 minutes and sit outside the main total.
- Every local link in the gallery, library readme, credits, art collection readme, and category readmes resolves. The gallery has no external script, stylesheet, font, or image dependency; research source links intentionally open online.
- Gallery JavaScript parses under the user's nvm-managed Node.js runtime. A simulated-DOM smoke check exercised collection counts, search, category/provenance filtering, clearing filters, detail opening/closing, and source-link construction. It confirmed 17 concept studies, three game-view records, and eight pacing rows. This is a code-level check, not a rendered-browser test.
- Git reports no changes to the Godot project, game scenes, runtime `.gd` scripts, or mechanics tests. Only research, concept documents, generated art, catalogue code, and related documentation were added or changed for this work.

## Visual verification limit

The generated image files were reviewed separately from the gallery. Image generation can simplify anatomical or mechanical details; the source observations and gameplay rules remain explicit in the database and design document.

The browser tool rejected the local `file://` gallery address because its URL policy allows only HTTP and HTTPS and forbids workarounds for that rejected action. No browser workaround was attempted. **The gallery's rendered layout and browser interaction were not visually verified.** It uses a local `catalog-data.js` script and relative links so it can be opened directly from the saved folder without a server.

## Rechecking after an image revision

Run this from the repository root after the final image and manifest edits:

```sh
python3 scripts/research/build_invasion_library.py --strict-art
```

The builder refreshes local image hashes, dimensions, availability, all portable exports, and SQLite relationships. It refuses missing manifest images, invalid PNG headers, duplicate IDs, unknown sources or related entities, invalid image paths, inconsistent level budgets, and failed SQLite integrity checks. A successful rebuild does not constitute a visual browser check or gameplay playtest.

The selected G10 handling-machine board was revised to match the researched Martian operator anatomy, saved as v2, and rebuilt with `--strict-art`. Its superseded v1 remains in the separate revisions folder. The updated image hash and all local links were checked after that revision.
