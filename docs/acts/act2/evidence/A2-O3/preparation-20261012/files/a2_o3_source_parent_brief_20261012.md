# A2-O3 Bleached Canal — source and parent reuse preparation

Prepared 12 October 2026 by the Act2 source reviewer. **Preparation only:** no O3 production, gameplay, gear choice, ability allocation, Godot job or runtime readiness claim. The current durable frontier reports O2 ready for independent acceptance and Shared52 adopted; O3 implementation waits for that acceptance. Those records were read, not independently re-audited here.

## Confirmed requirements

Canonical `levels.json` and `ACT2_CONCEPT.md` agree: **A2-O3**, optional, parent **A2-L4**, unlocked by clearing that parent. Complete **three familiar threat arrangements across broad dry pockets**, retain a return landing while reading existing tells from different approaches, then reach the opened contact exit. Place one checkpoint **before the third arrangement**. The 3–5 minute range and initial five-minute budget are pacing estimates, not a timer. Reward is a cosmetic/completion stamp with **no stat increase**; it does not gate main progression.

Required reuse is weed/bleached weed, dry road, flood margins, villa walls, Ray Scouts and Salvage Handlers. The concept specifies exactly **three route signs and one small canal-side scenic prop** as additions. It does not define sign collection, supplies, sign states, actor counts or exact mixtures. Bleached vegetation is scenery: no surprise collapse, underwater section, swimming, climbing, jumping, boat control, plant attack or novel control. There is no O3 boss, Tender/smoke requirement, Foot introduction or B05 landing-bait requirement.

## Inspected source and boards

The research catalogue's **S01/S02** are the HTML/plain-text editions of the same Wells novel, not independent corroboration. Relevant confirmed records are **T19** water-loving red weed, **T20** finer climbing red creeper, **E22** flooded Thames valley, **E23** Mortlake/Roehampton/Putney approaches and **E25** Putney Bridge/Fulham. **A2-E1** and **A2-E3** are the existing fictional compact Scout/Handler adaptations; **T08/C98** inform Handler machinery and rounded Martian anatomy. Neither Regent's Canal E28 nor canal workman C53 is a mandatory O3 location/NPC merely because the optional level is named Bleached Canal.

The primary text describes huge fronds beside water, flooded villas, later whitening/shrivelling/brittleness and quiet road segments with much less weed. These support contrasting banks and dry pockets; source wading, climbing and foraging do not authorize Cinder controls or pickups. [Book II.6, The Work of Fifteen Days](https://etc.usf.edu/lit2go/135/the-war-of-the-worlds/2480/book-twothe-earth-under-the-martians-chapter-6-the-work-of-fifteen-days/). The already whitening obstruction at Putney Bridge supplies a further decay reference. [Book II.8, Dead London](https://etc.usf.edu/lit2go/135/the-war-of-the-worlds/2482/book-twothe-earth-under-the-martians-chapter-8-dead-london/).

All four original boards below were actually inspected with `view_image` at original detail during this preparation. They are generated concept references, **not runtime atlases or finished meshes**.

| Board / original image | Pixels | SHA256 |
|---|---|---|
| G08: [red-weed-london-approaches.png](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/docs/concept-art/act2/environments/red-weed-london-approaches.png>) | 1536×1024 | `d8cabb23e296027ed96bfbfd55d1d96ab7634325de572e2ac6630a5a0e832d3d` |
| G16: [martian-technology.png](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/docs/concept-art/act2/props/martian-technology.png>) | 1024×1536 | `d7bb3d36baf62bf424387f436dbc5145fdf6504753d7b45e91815569501b535b` |
| G17: [victorian-survival-props.png](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/docs/concept-art/act2/props/victorian-survival-props.png>) | 1024×1536 | `4fe979367f3eef6374e8758362a679b7b783f8e938aaf21011b9dfed7c0766c3` |
| G10 selected v2: [handling-machine-boss-v2.png](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/docs/concept-art/act2/bosses/handling-machine-boss-v2.png>) | 1536×1024 | `1696af701d1694d21f442dd6354f880e98733edf5f7ec582bb7bd5705bfe737b` |

G08 shows deserted brick waterside ruins, broken sash/door modules, red banks, fine pale dying vegetation and readable quiet ground. G16 separates bulky living water-fronds from wilted pale/brown branching forms and supplies oxidised mechanical materials. G17 supplies period wood, brick, brass and broken domestic objects; its boat, artillery, tins and papers are not O3 vehicle/resource requirements. Selected G10 v2 supplies low **five-legged** articulated machinery and a rounded head-body with eyes, beak and tentacle bunches, rather than the superseded humanoid operator; use that vocabulary through the existing ordinary Handler, not by adding its boss. G08's fungal/spore and foraging captions are concept interpretations and do not override the confirmed ecological/scenic boundary.

## Reuse without editing accepted L4

L4 registration identifies accepted candidate `1a5e9ea197233fe2f5db808dfcce2e8288f79845` and authored content `b3150f9748a57130d7473c7c76ab850607f546c3`. Existing family readiness belongs to its accepted L4 evidence; it does not validate new O3 placements. The registration explicitly qualifies older pending prose in the weed asset note as stale. Preserve both historical notes and accepted parent files.

| Existing family / exact interface | Native pivot, collision and state | O3 reuse constraint |
|---|---|---|
| `red_weed_visual.gd`: `static build(parent:Node3D, variant:String, seed:int=0)->Node3D`; variants `sparse`, `dense`, `bleached`, `creeper` | Scale1, grounded local origin, +Y growth; two opaque batched mesh children; deterministic eight forms; no collider, target, damage, clock or growth animation | Keep dense/bleached outboard. Metadata includes measured local bounds/footprint/base and root-relative `optional_cutaway_paths`. Each mesh has its own material override; cached immutable geometry/textures can be shared. |
| `london_approaches_kit.gd`, art revision `a2-london-approaches-5`: existing `_villa`, `_weed`, `_surface`, `_iron_fence`, `_lamp`, `_box`, `_mark_cutaway` static leaves | Brick/sash/door/chimney or broken facade; original Heath/House/Weybridge material families. Scenic water is a flat plane, collisionless and below dry ground. Static fixtures have no action states | Recompose leaves into a compact optional layout. Full `build()` hardcodes the five-room long L4 route, witnesses, gun and artillery tableau; it is not a generic O3 kit. Villa yaw and `.65,1,.65` placement scaling are explicit L4 adaptations, not a universal native scale. |
| `london_approaches_floor.gd`: existing `_box_body(parent,stable_id,at,dimensions,shape_name)->StaticBody3D` | Upright BoxShape3D bodies, native identity shape transform; floor topY0. Whole `build()` hardcodes five L4 floor rooms and two fixed blockers | A future O3 host must author its actual dry floor/blocker map. Do not copy old collider locations or a visible low-wall footprint without matching actual collision. No narrow mandatory planks. |
| `ray_scout_actor.gd` + `ray_scout_visual.gd` + `ray_scout_exchange.gd` | Existing grounded compact three-legged mirror family; ordinary low housing; actual warning/lock/active/recovery/defeated consumer projection | Reuse the ordinary actor/driver and shared Scheduler/Player/cues. No private shared fork or B05 bait adapter. |
| `salvage_handler_actor.gd` + `salvage_handler_visual.gd` | Existing grounded low five-legged machine, rounded operator and ordinary tool-mount opening; bound actual LaneMechanism phases | Keep five supports distinct from Scouts. Cosmetic poses follow the actual consumer clock; no local timer or mechanical retune. |

Weed notes record conservative analytical native bounds: sparse top1.524/radius1.027m, dense2.024/1.265m, bleached1.365/1.320m, creeper1.625/.763m. These are existing analytical family limits, **not a newly constructed or tested O3 geometry result**. Query returned native bounds for eventual placements. The creeper is a thin wall-facing XY habit with +Z front; bleaching is a static phenotype, not a collectible spent state.

Eligible scenery registers per-instance cutaway material/path metadata using the existing `weybridge_cutaway_candidate` convention. Metadata alone does not protect the Hero: the future host must apply actual Hero/source/cue/landing context. Floor planes and visible blocker footprint bases stay legible. Preserve full source, footprint, reachable landing and ordinary-primary opening in current and settled portrait camera views. No new shader/camera/controller technique is proposed by this brief.

## Realized, adapted and deferred

**Realized in accepted parent families:** static stepped opaque weed forms, pale drooping phenotype, fine facade creepers, textured Victorian brick/timber/sash modules, quiet flood-margin planes and regular Scout/Handler silhouettes. **Adapted:** enormous source growth is compact/outboard; geography is compressed into dry combat pockets; warning footprints and low primary openings are game grammar. Parent fine branches/fasteners, rear supports and cropped facades have captured-view limitations rather than complete-board fidelity.

**Not implemented for O3:** its three arrangements, floor topology, sign assets/state protocol, one selected scenic prop, checkpoint/exit/stamp, native bindings, save/retry/cleanup and new portrait inspection. No equipment opportunity or ability is selected/reserved here; Root must run the canonical design gate before choosing one. Carried shared equipment/controls stay legal; no permanent growth or resource grant is inferred.

No missing selected art file or concrete parent API blocker was identified in this preparation. Exact arrangement mixtures/counts, footprint/return geometry, sign display states and the small prop remain authored decisions, not confirmed facts. Implementation waits for O2 acceptance; thereafter use focused mechanics/loading/transitions/save/retry/cleanup and brief actual visual evidence, with untested playthrough behavior disclosed. No full-route/all-enemy/whole-kit claim follows from this source study.

## Inspected current file pins

Paths below are relative to `/Users/howardchen/.codex/worktrees/campaign-act2/video game idea`. SHA256 pins record the actual read files on 12 October; they are not an inventory audit or new runtime acceptance.

| File | SHA256 |
|---|---|
| `docs/ACT2_CONCEPT.md` | `f5596e2bb8ec70dfc9e47df60272b6a9ef1b412b1e4af05413a1a6e618e5e696` |
| `docs/reference-library/act2/research/levels.json` | `e7d42cfa6d0943d5ba59223a3685c1865f4cd8bd93035c8d18070efaded27571` |
| `docs/reference-library/act2/research/entities.json` | `02aa3e7b4e6a7ec5f205a25f7ccc3bb96a3697c52a59338fe7544a7119dbf0a7` |
| `docs/reference-library/act2/research/sources.json` | `3975a1fd7d708182964b4db7f82cbd3ef62761c9c1db6dc26a427bd12f95e68a` |
| `docs/concept-art/act2/README.md` | `fbee5d8514e9f00695eb16e918e6581740f4ae6f22c7438a7be39efd9f934133` |
| `docs/concept-art/act2/generated-manifest.json` | `1145d3d494c8fe1337364b98c432a315c6cab5837409793bef9c6b62331d66f5` |
| `docs/ASSET_REUSE_GUIDE.md` | `2507aa2d654026bb1466125bd4c9241060f073f026425287a6c8912907e7f983` |
| `docs/GAME_STYLE_GUIDELINES.md` | `9c5d7680174b240cda25eb059db6babc4b4ebf129dcfcfeae8bdd59be2b2c1d1` |
| `docs/development/ACT2_L4_REGISTRATION.md` | `d5bb1d043ca6d90fd8edbbe2b85d9c1cd8211c6f8982245b8532663d3a6fdeac` |
| `docs/acts/act2/A2_L4_HANDOFF.md` | `1fba1928bc5530386454e9f8f01b192a78462d29c4043948431d948d16497c6b` |
| `docs/acts/act2/A2_L4_SCENERY_ASSET.md` | `352db062b7eff0a1a60c98daf3fa3af655c1423f3a7fc68aeb84491e363bac00` |
| `docs/acts/act2/A2_L4_WEED_ASSET.md` | `ac73860cb428a7f207fb57a3803917a0641b5b0d34a81c861b2147b726c1ff6a` |
| `scripts/acts/act2/london_approaches_kit.gd` | `9aa9c32e5d2c5804df5dffe7b1fef1098e7c9626e4f349951d0e060680121437` |
| `scripts/acts/act2/london_approaches_floor.gd` | `38644fceaa2e40c37b26022c429f4423f17fb4533ce6f7aa5242c6d7e1830def` |
| `scripts/acts/act2/red_weed_visual.gd` | `20424e1db6b9dd771a649139a44943a762231ee4ae7d8d673b6afeb609b6e9aa` |
| `scripts/acts/act2/ray_scout_actor.gd` | `dee72b851cb20b234a05552d07eae9cebd7490ee0fad12b3970da51eae132bb7` |
| `scripts/acts/act2/ray_scout_visual.gd` | `dda58dd611044a434d25206a03ac1b2b5f73270373d613e3a2fcc7bb5539879a` |
| `scripts/acts/act2/ray_scout_exchange.gd` | `6d8e11a29254cad18947655d8e7470d7892b18e856e534859ae6211a897ae7e2` |
| `scripts/acts/act2/salvage_handler_actor.gd` | `42457249e8a30e2d28ad0d03017d16e2f5158092ad3531e528ccf6beb3f70d96` |
| `scripts/acts/act2/salvage_handler_visual.gd` | `601b6713e01d7883d729729eb30c16ca80f23b22359e32ae6bc2ee4ff1ff08d2` |

Also reread the environment/prop/boss category READMEs, research source records, durable Act2 frontier, objective attachment and applicable asset/style/adaptation guidelines. No tracked file, ledger or engine state was changed.
