# L3 first paused-capture correction: preserved 59/1 failure

The [original job](run/job.json) and [raw stdout](run/stdout.log) record **59 checks / 1 failure**, exit 1, one real native swipe and one ordinary primary at `e2b4d660aa6a1c92e52f897b7144323e60680881` / `campaign-shared-26`. The original assertion and GDScript backtrace remain byte-exact. No ScriptErrors or warnings occurred; this is still a failed attempt.

The [frozen fixture](executed-source/tests/acts/act1/a1_l3_spore_component.gd.txt) changes capture presentation through public HUD methods: `hide_overlay()`, native capture while the complete unit/clock remains paused, then `show_pause()` before actual GUI Resume. Exact unit/event equality and menu restoration checks pass for the two completed frames.

Root personally inspected both original unobstructed 540×1170 images. Full C31 head/feet, Hero and the low cluster cue are clear; recoil is distinct and the broken field edge is readable. This is bounded approach/recoil readability only:

- [01: bound approach](captures/01-grove-bound-approach.png)
- [02: recoil](captures/02-grove-recoil.png)

The [original evidence manifest](captures/evidence.json) contains exactly two complete paused units: bound approach and recoil. Native `native_focus=false` is retained. No retreat/hold/regroup unit or portrait was completed.

The old fixture waits only for `phase == "retreat"` at lines 56–57, then the unchanged strict compound assertion fails at line 59. Root diagnosed that this first phase stamp still has zero actual velocity: the [frozen Coordinator](executed-source/scripts/environment/spore_repulsion.gd.txt) advances Route before changing turn to retreat (lines 341–362), so movement occurs on the following native physics tick. The original log prints the compound assertion without failed operand values; no missing retreat state is reconstructed. Root plans a bounded wait for actual retreat **and nonzero native velocity**, retaining the original predicate, runtime and tolerances. Later changed sources/runs are excluded.

The 91 exact frozen sources comprise 27 inert `.gd.txt`, five inert `.tscn.txt`, five JSON records and 54 authored source PNGs/contact sheets. Those source assets are distinct from the two actual captures. The run establishes no complete environmental episode, C32 response, full L3/room/crowd/route/save/campaign acceptance, fresh recipient, depletion, separately targeted callback injury, all loadouts/profiles, human balance or performance proof. Earlier 109/0 mechanics with five modal-obscured images remain a separate immutable archive.

[The index](index.json), [origin map](origin-map.json) and [inventory](inventory.json) preserve exact run scope and byte hashes. Original producer references retain historical paths; mapped copies are portable within this directory. The declared subset is not a complete resource graph. `.gdignore` and inert suffixes exclude executable archive classes. No engine/import, current-source/record edits, old archive edits, staging or commit were performed by the archiver.
