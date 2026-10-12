# Shared Title and Journey scenery

Shared48 adds quiet procedural scenery around the existing shared traveller. Title shows the Earth observatory/finless shell for a new save or current A1-L1, then painted lunar rock flats after the story actually moves onward. Act2 uses ruined masonry, a buried cylinder and red-weed clusters; Act3 uses static twin suns, an organic ridge and a quiet crystal. These are interpreted menu silhouettes, not reproductions of the selected concept paintings or new gameplay objects.

Journey retains every authored node position, prerequisite, state, optional branch and connection endpoint. Static scenery sits beneath a separate connection layer; opaque region-colour header backdrops keep cross-act connections clear of the text. Unreached Act2/3 regions show only their palette and abstract terrain. A main completion stamp alone does not reveal the Moon while the story remains at the Earth entrance/coda. The current-level marker and traveller still use protected story equipment and the shared act presentation.

`CinderMenuScenery` implements `menu-scenery-1`: `configure(act, mode, revealed, earth_launch)`, a defensive `presentation_state()` descriptor and the pure `traveller_rect()` for the existing preview. Invalid configuration retains the previous presentation. It owns no actor, texture generation, equipment, save, input, clock, RNG or scene-loading authority. Mouse/focus are disabled; process/physics ticks are disabled. Title uses160×88 source pixels and Journey160×360, centred at integer pixel steps. The standard portrait uses3× scenery pixels and the same144×192 Title traveller; the narrow432×936 desktop check preserves node identities and restores original geometry on return. The manifest records pivots, palettes and source/readiness limits.

[Asset provenance](../../assets/ui/menu_scenery_manifest.json) links the selected references and [portable originals](evidence/shared48-menu-scenery/index.json) retain5,566 frozen source copies across eight jobs, exact logs/closures,24 original captures and qualified peer reviews. The `.gdignore` boundary precedes archived scripts. Import keeps all404 prior active UID bytes and generates exactly two shared sidecars, yielding406 unique identities; those late outputs are separate from the original694 inputs.

| Result | Scope |
| --- | --- |
| Necessary import: clean exit0 | New scenery/test resources and late metadata; no gameplay credit. |
| Native1: failed, no summary footer | Original `Array`/`Array[String]` descriptor mismatch and partial failed assertion remain preserved. |
| Native2:360/0, exit0, **not clean** | Test-only absent parent metadata queries logged120 generic errors. The original result is qualified, not rewritten as clean. |
| Native3:360/0, clean | `has_meta` preserves actual null-parent semantics; exact nonempty paused Shell/Player/story/gear/input/actions/format2 disk/ID and cleanup guards pass. |
| Portrait4:722/0, clean, eight images | Original scenery before heading backdrops; observed connector/text overlap remains its visual limitation. |
| Portrait5:725/3, eight images | Full heading-bound checks expose initial label rectangles478/626/515 pixels tall; original failures remain failed. |
| Final Portrait6:725/0, clean, eight images | Initial width is set before labels enter the tree; all three actual header rectangles452×64 fit their masks. All native pause/focus observations are true. |
| Affected comparison7:331/0, clean | Existing public Shell/checkpoint/completion and selector/preset callbacks preserve nested HP37/95 comparisons and complete saved/live state. |

Root and two independent reviewers inspected the final images, reusing only byte-identical earlier views. Four are actual paused A1 Title/Journey captures, with all24 real metadata nodes and unreached-region locks. Four are explicitly TEST standalone scenery/shared-traveller art previews; they do not pretend to be current A2/A3 gameplay or earned progression. The whole Title traveller/checkpoint and all header bounds are contained. The tall scrolling route intentionally intersects the viewport as a slice. The first derived Portrait5 decoder retained float64 hex strings; its separately retained correction and final derivative decode original little-endian bits without changing any log or image.

Canonical targeted command:

```sh
python3 scripts/dev/dev.py test menu_scenery
python3 scripts/dev/dev.py engine --path . --script res://tests/menu_scenery_smoke.gd -- --capture-portraits
python3 scripts/dev/dev.py test replay_comparison
```

The recorded bounded driver uses the same `ProjectContext`, runtime, shared `godot_lock` and `run_validation` functions, with its90-second owned deadline beginning after queue acquisition. It never deletes locks or terminates another owner's job. The first import waited behind Act3's actual live persistence check.

No gameplay/save schema migration, actor/controller/stat change, new ability/equipment, act-owned source change or level acceptance is introduced. Campaign remains11/24; A1-L4, A2-O1 and A3-L4 continue independently. These checks do not prove GUI hit testing, current A2/A3 campaign navigation, all-kit art, human preference/balance, full routes, sustained performance or device behaviour. The imagery is deliberately coarse and quiet; richer source fidelity remains an art refinement. Stop before mobile export/release.
