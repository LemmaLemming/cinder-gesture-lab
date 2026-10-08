# Cinder — asset reuse guide for future agents

**Review date: 8 October 2026.** Read this with the [shared style and motion guidelines](GAME_STYLE_GUIDELINES.md) and the relevant act concept. There are useful reusable systems already in Godot and strong modular ideas in the art. The art PNGs are full-frame planning illustrations, not ready-made production sprites or environment kits.

## What is available now

| Readiness | Meaning in this repository |
| --- | --- |
| Implemented system | Existing code can be reused or extended, preserving its current behaviour and verification. It may still lack the campaign features described in the concepts |
| Prototype artwork/scaffold | Existing runtime-generated art establishes a test scale or role. It is reusable in greyboxes, not a finished campaign character design |
| Concept reference | Reuse its shapes, material language, module ideas or composition when authoring an asset once, then instance that production asset. It has no verified atlas, pivot, collision, state machine or animation sequence |
| Superseded reference | Keep for history or a specifically identified scenery idea; it cannot establish current mechanics or the visual baseline |

The `generated-manifest.json` files preserve art prompts and provenance. Their study-slot counts are drawing requests, not inventories of finished game assets. A grid-looking board does not guarantee transparent, aligned, consistent-scale cells or seamless textures. A gameplay illustration does not establish world dimensions, timing or collision.

## Reuse these implemented systems first

| Existing source | Reusable part | Limits to remember |
| --- | --- | --- |
| [game.gd](../scripts/game.gd), [lab_arena.tscn](../scenes/lab_arena.tscn) and [project.godot](../project.godot) | Portrait 270 × 585 nearest-filtered gameplay, fixed-angle orthographic follow with 0.16 s exponential easing, gesture recognition, screen-space aiming and editable lab floor | Reset snaps follow focus; delayed translation never moves the final release anchor. Exercises and core collection remain lab logic |
| [player.gd](../scripts/player.gd) and [player.tscn](../scenes/player.tscn) | One any-angle dash controller, exact primary/follow-up actions, collisions, ammo/reload, armour, action snapshots and queued weapon replacement | Static lab gear is implemented; conditional perks, powerups and campaign save/checkpoints remain future work. Do not make an act-specific replacement controller |
| [equipment.gd](../scripts/equipment.gd) and [lab_bench.gd](../scripts/lab_bench.gd) | Canonical-data stat resolution, static presets and paused before/after comparison with safe clothing replacement | Nine static clothing presets and four weapon profiles only; no perk/powerup grants or campaign catalogue persistence |
| [pixel_sprite.gd](../scripts/pixel_sprite.gd) and [character manifest](../assets/characters/manifest.json) | Shared 48 × 64 permanent-helmet player, four artwork facings, compatible clothing/weapon layers and six to eight frames for immediately entered action states | Original lab artwork, unchanged world footprint/collider. Slower cosmetic settling is interruptible and does not extend hit/input deadlines. Existing enemies retain their older art |
| [enemy.gd](../scripts/enemy.gd) | Approach acceleration, variant parameters, accepted hit results, cone warning/countdown, locked direction and visible stationary recovery | Grunt/armoured/hopper remain arena roles. The cone and 0.60 s recovery are lab scaffolding, not authored campaign enemy animation or validated reaction budgets |
| [effects.gd](../scripts/effects.gd), [curling_smoke.gd](../scripts/curling_smoke.gd), [shotgun_flare.gd](../scripts/shotgun_flare.gd) and [attack_footprint.gd](../scripts/attack_footprint.gd) | One connected 16-frame plume per dash, the original slower pale slash arc, bright 10-frame barrel-origin shotgun flare, tiny blood flecks, physical debris, resolved floor outlines, cone/ring meshes, text and sounds | [Effect manifest](../assets/effects/manifest.json) records scale, pivots and clocks. Cosmetics have no damage or collider; warning geometry and LOS remain authoritative. Reuse bounded pause-aware cleanup; these are capped/retired nodes, not an object pool |
| [hud.gd](../scripts/hud.gd) and [lab_bench.gd](../scripts/lab_bench.gd) | HP/ammo/profile display, lab action feedback, comparison and tap-consuming pause/resume | Lab pause freezes the scene tree, including on focus loss/backgrounding. Future powerup/perk icons and campaign resume persistence remain unimplemented |
| [practice_target.gd](../scripts/practice_target.gd) and [weapon_pickup.gd](../scripts/weapon_pickup.gd) | Safe attackable test props and finite contact weapon stands with available/taken feedback | Lab prototypes with instance-local state, not a general campaign interactable framework. Practice props never grant enemy reload rewards |
| [mechanics_smoke.gd](../tests/mechanics_smoke.gd), [equipment_smoke.gd](../tests/equipment_smoke.gd), [character_lab_smoke.gd](../tests/character_lab_smoke.gd) and [visual_effects_smoke.gd](../tests/visual_effects_smoke.gd) | Regression checks for controls, framing, static stats, swaps, hit results, actual dash trails, barrel attachment, pause and cleanup | Reuse relevant checks when gameplay changes; these do not validate campaign animation, human encounter balance or phone performance |

The most reliable reuse today is code and prototype assets. The [Character Lab](CHARACTER_LAB.md#runtime-assets-and-reuse-records) records the new player atlases, procedural arena, targets, weapon stands and attack-footprint helper with scale, pivots, state timing and readiness. No full-frame campaign concept PNG is a verified runtime sprite sheet. Player equipment visual layers and shared cone/ring geometry now exist; broader campaign cue components, spore fields and tether states remain proposed components to build.

## Act 1 — author one lunar theatre kit

All sources in this table are **concept references**. Use the [Act 1 source style guide](reference-library/act1/STYLE_GUIDE.md) and [adaptation notes](concept-art/act1/ADAPTATION_NOTES.md) to resolve variants.

| Family | Preferred local references | Repeated use | Production work |
| --- | --- | --- | --- |
| Finless capsule and hatch | [Earth launch modules](concept-art/act1/props/earth-launch-modular-kit.png); [revised launch studies](reference-library/act1/concepts/observatory-launch-object-studies-v2.png) | Workshop, launch, crater landing, final escape and Salvage Circuit | One squat capsule with closed/open/blocked/damaged/repaired hatch states; a readable grounded contact entrance |
| Rock flats and crater ground | [Lunar modules](concept-art/act1/props/lunar-grotto-and-court-modular-kit.png); [Crater Gardens](concept-art/act1/environments/02-crater-gardens.png) | Crater encounters, rearranged face-side return and salvage side level | A small irregular rock-flat family and floor patches. Painted crater rings remain scenery; an actual impact adds the shared animated warning |
| Mushrooms, porous forms, shelves and trunk | [Lunar modules](concept-art/act1/props/lunar-grotto-and-court-modular-kit.png); [grotto environment](concept-art/act1/environments/03-mushroom-caverns.png) | Main grotto and Spore Bloom | Separate cap/stalk/edge pieces with clear ground pivots and simple stalk colliders; keep decorative shelving around continuous floor |
| Low spore clusters and falling spores | [Grotto gameplay](concept-art/act1/gameplay/02-mushroom-spores-gameplay.png); [lunar modules](concept-art/act1/props/lunar-grotto-and-court-modular-kit.png) | Every usable mushroom, mixed enemy encounters and Spore Bloom | Separate reachable cluster with full/hit/spent states; shared predictable repulsion boundary, falling/thinning feedback and per-instance supply |
| Court flats, crescents, curtains and roundels | [Court environment](concept-art/act1/environments/04-selenite-court.png); [court object studies](reference-library/act1/concepts/selenite-court-object-studies.png) | Linked courts, King arena and Royal Rehearsal; curtains can frame several exits | Canonical modular ornament; blocked/open curtain states. A roundel used as a hazard adds known impact states; ordinary ornament stays quiet |
| Selenite body and poses | [Costumes and roles](concept-art/act1/characters/selenite-costumes-and-roles.png); [King reference](concept-art/act1/bosses/01-selenite-king.png) | Rush, Swarm and Spear Guard; finite King helpers and optional formations | Shared upright masked anatomy/rib/headpiece vocabulary; distinct size, spear and preparation. Author consistent facings and real phase animation sequences |
| Friendly cast, celestial scenery and workshop props | [Earth cast](concept-art/act1/characters/earth-supporting-cast.png); [celestial performers](concept-art/act1/characters/celestial-performers.png); [Earth modules](concept-art/act1/props/earth-launch-modular-kit.png) | Hall, roof, camp and return tableaux | Reuse costume/prop families and small scenic gestures. Friendly humans and celestial performers do not become an enemy cast |

Keep the [Moon boss](concept-art/act1/bosses/02-man-in-the-moon.png) as a special local face/eye/nose asset with explicit opening states. Reuse rocks, capsule and warnings around it; do not assume that a generic character animation covers its lowered-eye contact pose.

## Act 2 — author one industrial invasion kit

These are **concept references**, governed by [ACT2_CONCEPT.md](ACT2_CONCEPT.md). Share module and motion families without confusing fighting-machines with handling-machines.

| Family | Preferred local references | Repeated use | Production work |
| --- | --- | --- | --- |
| Cylinder/lid, pit edge and heath scenery | [Martian technology](concept-art/act2/props/martian-technology.png); [Horsell Common](concept-art/act2/environments/horsell-common.png) | Opening common, cylinder/work-apron landmarks and Cylinder Perimeter | One cylinder/lid family, pine/sand/scorch modules and broad ground pockets. Pit/cylinder mouths are scenic boundaries, not required descent or traversal |
| Martian apparatus, plates, arms, joints and canisters | [Martian technology](concept-art/act2/props/martian-technology.png); [selected handler board](concept-art/act2/bosses/handling-machine-boss-v2.png) | Ray Scout/Tender/Handler vocabulary, work apron, Handling-Machine boss and optional circuits | Canonical module scale and attachment points; five-legged handler silhouette distinct from three-legged tripod. Low housing/tool mounts remain slashable |
| Giant foot, ray apparatus and local leg joint | [Fighting-tripod board](concept-art/act2/bosses/fighting-tripod-boss.png); [bait-and-strike illustration](concept-art/act2/gameplay/sample-screenshots/03-tripod-bait-and-strike.png) | Weybridge footfall set piece, final sentry and familiar ray/impact warning systems | Lift/lock/land/recover foot states; turning/folded mirror and reachable joint states. Sample completed world dash landing for sentry bait, not the finger-release anchor |
| Victorian ruins and street furniture | [Survival props](concept-art/act2/props/victorian-survival-props.png); [Weybridge/Shepperton](concept-art/act2/environments/weybridge-shepperton.png); [London approaches](concept-art/act2/environments/red-weed-london-approaches.png); [ruined house](concept-art/act2/environments/black-smoke-ruined-house.png); [London](concept-art/act2/environments/dead-london-regents-park.png) | Street, lockside, house, villas, London and parent-based side levels | Boards visibly explore reused doors/windows/tins and modular walls/bridge parts. Author matching perspective, texel density and visible bases; board floors are not verified seamless textures |
| Red weed | [Technology/ecology props](concept-art/act2/props/martian-technology.png); [London approaches](concept-art/act2/environments/red-weed-london-approaches.png) | Flood margins, transformed villas, London decay and Bleached Canal | Sparse/dense/bleached visual variants. Static grounded obstacles and overhead fronds stay distinguishable; bleaching is scenery, not a pickup or new hazard |
| Smoke, steam, dust and ray feedback | [Smoke/house environment](concept-art/act2/environments/black-smoke-ruined-house.png); [ray evasion illustration](concept-art/act2/gameplay/sample-screenshots/01-ray-evasion.png) | Tender patches, machine releases and ruined-world dressing | Build bounded inactive/expanding/active/thinning smoke states. Share effect scaffolding, with clear danger footprints above visual smoke and no random additional clouds |

Human anatomy and costume references in [the character folder](concept-art/act2/characters/) support scenic crowds and witnesses. They do not supply three finished regular-enemy animation sets. Compact machine enemies still need dedicated production sheets even if they borrow boss joints, tubes and material treatment.

## Act 3 — author one false-world kit

These are **concept references**, governed by [ACT3_CONCEPT.md](ACT3_CONCEPT.md) and [adaptation notes](concept-art/act3/ADAPTATION_NOTES.md).

| Family | Preferred local references | Repeated use | Production work |
| --- | --- | --- | --- |
| Stone/shelves/crystals and decorative light layers | [Journey/modules](concept-art/act3/props/02-journey-and-modules.png); [Twin Suns](concept-art/act3/environments/01-twin-suns.png); [Crystalman](concept-art/act3/environments/05-crystalman-and-muspel.png) | Sun shelves, firm sea margins, final arena and optional spaces | Shared stable floor modules, palette materials and edge scenery; distant floating islands are scenery, not required platform jumps |
| Trunks, roots, low knots and tethers | [Organs/ecology](concept-art/act3/props/01-organs-and-ecology.png); [forest](concept-art/act3/environments/02-living-forest.png); [garden](concept-art/act3/bosses/01-sullenbode-garden.png) | Living Forest, root circuits, false garden and Crystalman's local tether | Shared organic segments and attachment vocabulary. Author closed/exposed/severed/spent tether states; extend root motion without importing a human projection's collider |
| Reflective ground, shore, islands and scenic ring | [Mirror Sea](concept-art/act3/environments/03-mirror-sea.png); [Mirror Sea game view](concept-art/act3/gameplay/02-mirror-sea-gameplay.png) | Dry sea apron, resonance set piece, Irontick side level and final sea framing | Separate firm playable surface from decorative water/reflection. Reuse layer/material logic, with stable floor and independently previewed hazards |
| Stalker/Latcher/Echo silhouette ideas | [Threat studies](concept-art/act3/bosses/03-candidates-and-threats.png); [Twin Suns game view](concept-art/act3/gameplay/01-twin-suns-gameplay.png) | The same three regular roles rearranged across main/optional encounters | Dedicated production sprites and states. Stalker's line is a lunge lane even where art resembles a ray; Root Latcher remains a fixed rooted bulb owning one bounded footprint despite its mobile-looking board silhouette. Named source characters and alternate boss candidates are separate |
| Apparition and route/arc preview vocabulary | [Crystalman board](concept-art/act3/bosses/02-crystalman-echo.png); [final game view](concept-art/act3/gameplay/03-crystalman-gameplay.png) | Regular Echo's own sequence and final boss's finite captured player sequence | May share ghost drawing and shape builders; behaviours differ. Real Echo has floor contact, harmless reflection has no collider, final apparition replays executed world geometry without recursion |
| Garden beauty/stripped layers and luminous presence | [False Paradise](concept-art/act3/environments/04-false-paradise.png); [garden board](concept-art/act3/bosses/01-sullenbode-garden.png) | Garden revelation and compatible final scenery stripping | Layered intact/stripped dressing while keeping the same safe floor. Sullenbode's likeness is non-damageable and fades; the external root network is the target |

The sensory-organ studies suggest optional pickup appearances; they do not grant new permanent mechanics. Any reskin must map to an explicitly specified effect and keep its shared cue/group/lifetime. White-shadow overlays and decorative reflections never reuse danger markings in a way that changes their meaning.

## Optional levels use their parent assets

These are the existing **proposed** side-level scopes. Build parent assets once, then change arrangement and objective. A side level does not require another environment kit, regular enemy cast or stronger character tier.

| Side level | Parent kit to reuse | Small additions allowed by the current plan |
| --- | --- | --- |
| Salvage Circuit | Crater rocks/floor, capsule, rusher and impacts | Three capsule parts; damaged/repaired hatch states |
| Spore Bloom | Grotto mushrooms, clusters/repulsion, swarmers and guard | Different cluster arrangement or bloom pose |
| Royal Rehearsal | Court ornament, curtains, guards and formations | Practice bell and formation markers |
| Cylinder Perimeter | Heath, cylinder, trunks, scouts and lanes | Three journal fragments and exit marker |
| Clear Air Circuit | Work apron, ruined walls, tenders, handler and smoke | Empty/full crate states and circuit marker |
| Bleached Canal | Weed variants, dry road, flood margin, villa walls, scouts/handlers | Three route signs and one canal scenic prop |
| Pillars Before Their Time | Sun shelves, pillars, trees, Stalker and light previews | Three collected/uncollected markers and exit seal |
| The Quiet Root Circuit | Trunks, roots, knots, Latcher/Stalker and sun states | Route glyphs and spent-knot completion marker |
| Irontick's Last Reflection | Dry shore, stones, scenic ring, Echo/reflection and resonance | Stage pips and one shell-like scenic collectible |

## Reuse across acts without flattening their identity

Good shared candidates are the player body/animation layers, gesture controller, action/stat definitions, pixel renderer, foot pivots/contact shadows, cue shapes, UI icon family, square debris, hit feedback and interaction-state machinery. Once built, the same cue/state component can drive a capsule hatch, ruined exit or plain threshold with different art.

For player appearance reuse, the implemented permanent round astronaut-like helmet and [compatible equipment rules](PLAYER_EQUIPMENT_GUIDELINES.md#permanent-helmet-and-compatible-equipment-appearance) take precedence over older hats in concept boards. Reuse the shared helmeted body, pivots and action layers across acts. The [generated astronaut turnaround](../assets/references/astronaut-turnaround-v1.png) is a visual model; aligned runtime cells are separately authored in Godot and recorded in their manifest.

Period coats, hats, benches, lamps or wall shapes may share underlying geometry between compatible Earth scenes, after checking the references and scale. This is an opportunity, not a requirement to make theatrical Moon scenery and ruined London look identical. Lunar fungus, red weed and organic Tormance roots should use their own visual kits; shared placement/state logic can still reduce duplicated code.

Keep each instance's supplies, timers, open/spent state and collected IDs separate. Share textures, animation resources and immutable definitions; do not let hitting one mushroom spend every instance's cluster or changing one cue material recolour unrelated hazards. A boss may reuse a creature's anatomy or articulated parts while needing its own silhouette, phase states and local weak point.

## Do not promote these images into the baseline

- Act 1's root [Crater Gardens](concept-art/act1/crater-gardens.png), [Mushroom Caverns](concept-art/act1/mushroom-caverns.png) and [Selenite Court](concept-art/act1/selenite-court.png) are [superseded explorations](concept-art/act1/LEGACY_EXPLORATIONS.md). Their modern suit/visor, finned rocket, beetles, damaging vents and Gothic architecture are historical variants.
- [mushroom-grotto-v2.png](reference-library/act1/concepts/mushroom-grotto-v2.png) still supplies useful scenery, but its automatic vent depiction is superseded by hittable clusters and harmless repulsion. Act 1's `revisions/` images are earlier passes.
- Act 2's [handling-machine v1](concept-art/act2/revisions/handling-machine-boss-v1.png) has an incorrect humanoid pilot. Prefer the v2 board and researched rounded Martian anatomy; do not use v1 as a shortcut to a new humanoid enemy.
- Mood boards, wide tableaux, alternative boss boards and illustrated captions support exploration. They are not animation-speed references, combat layouts, source quotations or authorisation to add more bosses.
- Generated game views vary player appearance, detail density and warning treatment. Select canonical production sheets and the shared cue grammar; do not copy each view's different player or hazard graphic as an independent standard.

## Procedure before creating or importing an asset

1. Search this guide, the relevant art folders/manifests and existing Godot scripts. Choose an existing family or explain the concrete new function that requires a new asset. Read the written encounter rules before interpreting the drawing.
2. Name the canonical production asset and reuse locations. Preserve provenance and any existing credits. Reference-library film frames and historical images remain reference material unless deliberately selected for an authorised in-game use; this review does not change their recorded attribution or permissions.
3. Specify native pixel grid, intended world footprint, common foot/attachment pivot, palette role, visual layer, collision/occlusion role and required state/animation list. Separate scenic pieces from actionable pieces.
4. Rebuild or carefully extract/clean the required shapes into suitable runtime resources. Remove baked captions/backgrounds, correct perspective/scale, supply transparency where needed, and author missing directions/poses. A crop of a board stays a prototype until checked in the game view.
5. Instance the canonical resource with local state; palette variants preserve cue meaning and action data. Do not copy/paste separate controllers, warning timings or depletion rules into each act.
6. Check the asset at actual portrait gameplay size with its enemy/interaction. Confirm reach, foot contact, warning contrast, foreground occlusion and available/active/spent feedback. Record remaining limitations before marking it ready.

An asset record should contain at least: stable ID, family, source path, readiness, native dimensions, world footprint, pivot, palette role, scenic/actionable role, collision/occlusion treatment, required states, animation durations, reuse locations and known limitations. Use `not_applicable` for fields that do not apply. Until an authored asset passes those checks, call it a reference or prototype rather than a reusable finished campaign asset.
