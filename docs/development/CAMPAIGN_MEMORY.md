# Cinder campaign memory

## Latest user acceptance decision — 9 October 2026

The latest direct human instruction establishes [focused-desktop-level-1](LEVEL_ACCEPTANCE.md): focused automated mechanics/loading/transitions/saves/Retry/cleanup checks plus brief visual inspections. Agents need no full route, defeat-all, earned exit or campaign playthrough before level acceptance and next-level work. Record untested full-playthrough behavior and continue autonomously. This supersedes historical forward playthrough requirements below while preserving their original test results and source custody.

Campaign8/24 remains accepted. Root notified all three existing workers immediately through canonical UPDATE1518a40b (Act1),4747655d (Act2),8cb5d40f (Act3) and their actual chats. Current frontier reviews are A1-L3, A2-L5 and A3-L3 against focused evidence, not route completion. Workers update their owned current progress/level records; Root retains shared ownership and first-help responsibility. Changed-level/directly affected suites only; no blanket requalification or mobile gate.

Updated 9 October 2026. Integration owns this durable record. Read it with [SHARED_CONTRACT](SHARED_CONTRACT.md) and [SHARED_PROGRESS](SHARED_PROGRESS.md) after context recovery and before reviewing an act handoff.

## Authorized endpoint and precedence

Complete a playable, integrated, tested **desktop campaign: 15 main levels and 9 optional levels**. Each act owner completes one level at a time, in authored order, followed by its three existing optional levels. Integration accepts tested levels independently. Stop before mobile export, SDK/signing setup, store submission and subsequent release work. Mobile remains a later release direction, not a gate on this authorized desktop work.

The user's latest explicit decisions override older repository requirements and exploratory images:

- A permanent astronaut helmet is no longer required. Protagonist headwear follows selected act concept art, agreed with each act owner. Headwear is presentation only, with no equipment slot or bonus.
- Preserve one player/controller/stat/equipment system, shared collision and feet pivot, exact aiming, and readable action/facing language. Carried equipment must suit selected presentations, including mixed-act loadouts.
- Hit-activated mushroom spores repel living enemies and cause **no damage**.
- Build the complete authored campaign sequentially; implement the equipment and abilities it selects, rather than every unused catalogue proposal.
- Existing helmeted Character Lab assets and captures are truthful historical/current prototype work. Preserve their provenance. New campaign presentations are not implemented merely because the rule changes.

Source precedence: latest user decisions → confirmed controls and equipment requirements → authored act mechanics/adaptation boundaries → versioned implemented shared contracts → documented art defaults/provisional tuning → illustrative concept boards. Numerical equipment identity and values belong to [player_equipment.json](../../data/design/player_equipment.json); allocations belong to the canonical CLI ledgers. Generated captions and alternative boss studies do not authorize mechanics.

## Shared play loop and controls

Read a committed threat → swipe to a useful landing → aim an immediate primary → choose a blast follow-up → read the next threat. Mastery, attempt resources and persistent completion/catalogue access are separate. Acts and farming do not grow base statistics.

- Voluntary movement is any-angle ground dash by swipe only, with normalized diagonal distance and one buffered dash. No joystick, walking control, jump, auto-aim or hotbar.
- Aim from the latest completed swipe's **final screen-space release point** toward the tap. Camera movement does not move the anchor. Before the first swipe it is screen center; zero direction retains facing.
- First tap immediately attempts a primary. A nearby second tap within the existing 280 ms window and strictly below 90 virtual pixels attempts one blast. An empty blast creates no replacement primary.
- Keep deliberate dash start/stop, fixed collision, continuous exact aim and simulation-owned timing. Cosmetics cannot change dash travel, hit timing, cooldowns or momentum.
- Portrait pixel 2.5D, close fixed-angle following camera, nearest-filtered pixels. Shared warnings follow warning → lock → active → recovery, with source, footprint and a reachable safe landing visible together.
- Contact collection/exits differ from attackable clusters/weak points and from decoration. Actionable objects show available/active/spent states. Menus and resume consume gestures before combat; all simulation clocks freeze together.
- Exactly weapon, jacket, pants and shoes. Required encounters work with ordinary primary attacks, empty blast ammo and no pickups; all permitted loadouts retain escape and attack opportunities.

## Three-act arc and canonical route

| Act | Arc and distinct art | Main route |
| --- | --- | --- |
| 1 — The Moon | Invitation and rehearsal → lunar curiosity → crowded grotto → royal formation → departure refused. Handmade lunar theatre: period expedition silhouettes, painted rock flats, pale fungi, masked upright Selenites, crescents and court drapery. | A1-L1 Observatory and Launch; A1-L2 Crater Gardens; A1-L3 Mushroom Caverns; A1-L4 Selenite Court; A1-L5 The Living Moon |
| 2 — The Invasion | Curiosity → flight → enclosure → transformed approaches → recovery in dead London. Victorian ruins, rust-red weed, industrial machines; distinguish three-legged fighting-machines from five-legged handling-machines. | A2-L1 Horsell Common; A2-L2 Weybridge and Shepperton; A2-L3 Black Smoke and the Ruined House; A2-L4 Red Weed and the London Approaches; A2-L5 Dead London and Regent's Park |
| 3 — Tormance, The False World | Alien wonder → watched life → deceptive reflection → false comfort → repetition exposed and local escape. Scarlet/violet shelves, dark rock spines, white/blue suns, living roots, firm black shores, luminous gardens, crystals and stripped scenery. | A3-L1 Twin Suns; A3-L2 Living Forest; A3-L3 Mirror Sea; A3-L4 False Paradise / Sullenbode's Garden; A3-L5 Crystalman |

Main completion opens the next main level in campaign order. An optional level unlocks when its parent is cleared, and never blocks main progress. Keep `A3-L4` stable despite its prose names.

| Optional ID | Name | Parent clear |
| --- | --- | --- |
| A1-O1 | Salvage Circuit | A1-L2 |
| A1-O2 | Spore Bloom | A1-L3 |
| A1-O3 | Royal Rehearsal | A1-L4 |
| A2-O1 | Cylinder Perimeter | A2-L1 |
| A2-O2 | Clear Air Circuit | A2-L3 |
| A2-O3 | Bleached Canal | A2-L4 |
| A3-O1 | Pillars Before Their Time | A3-L1 |
| A3-O2 | The Quiet Root Circuit | A3-L2 |
| A3-O3 | Irontick's Last Reflection | A3-L3 |

Optional levels reuse parent terrain, scenery, enemies, animation and effects, with a few documented additions and a different arrangement/decision. Rewards do not create permanent stat growth. Story, optional and replay attempts preserve isolated coherent snapshots; finishing or abandoning a side attempt restores story automatically. Optional rewards are once-only.

## Binding adaptation and art priorities

Act 1 friends and celestial performers remain nonhostile. The reachable low mushroom cluster is attacked normally; falling spores cancel/recoil/repel living enemies without damage. The King and Moon have ordinary-primary openings. Superseded finned rockets, beetles, damaging vents and Gothic dungeon explorations remain historical references.

Act 2's compact enemies and local boss contact points must read at the shared camera scale. Sentry bait samples a **completed world dash landing**, not the swipe-release aim anchor. Use selected handling-machine v2 anatomy; preserve friendly/witness humans and researched machine distinctions.

Act 3 white shadows, harmless reflections, scenic eyes/crystals and distant islands remain scenery. Sun changes initially preserve stable safe floor. Mirror Echo repeats its own sequence; Crystalman captures **actually executed world movement and attack geometry**, including equipment modifiers and collision shortening. Validate the combined replay before commitment. Invalid capture visibly rearms. Apparitions do not collect, heal or proc player perks. Sullenbode's likeness is non-damageable; low external roots/tethers are ordinary-primary targets. Stripping scenery never removes safe floor.

Selected concept images have been opened in the initial audit. Act 1 expedition art shows a brimmed hat/coat/beard; Act 2 game views show a dark-haired period traveller; Act 3 game views vary pale coat/head silhouette. Final production choices require coordination with act owners. Use richer silhouettes, poses, materials and layering where the source supports them. Do not flatten all acts into the lab's visual kit or pass full concept paintings off as runtime atlases.

Every introduced asset records source, readiness, native scale, pivot, collision/occlusion, animation states and reuse family. Distinguish original production shapes, extracted prototypes and reference-only boards. Record actual portrait captures and remaining limits.

## Authoritative reading and recovery links

- [AGENTS](../../AGENTS.md), [README](../../README.md), [parallel workflow](PARALLEL_ACT_DEVELOPMENT.md), [setup record](SETUP_RECORD.md).
- [Campaign](../GAME_CONCEPT.md), [style/motion](../GAME_STYLE_GUIDELINES.md), [asset reuse](../ASSET_REUSE_GUIDE.md).
- [Act 1](../ACT1_CONCEPT.md), [selected art](../concept-art/act1/README.md), [adaptation](../concept-art/act1/ADAPTATION_NOTES.md), [source style](../reference-library/act1/STYLE_GUIDE.md), [legacy](../concept-art/act1/LEGACY_EXPLORATIONS.md), [canonical levels](../reference-library/act1/research/levels.json).
- [Act 2](../ACT2_CONCEPT.md), [selected art/adaptation boundaries](../concept-art/act2/README.md), [canonical levels](../reference-library/act2/research/levels.json).
- [Act 3](../ACT3_CONCEPT.md), [selected art](../concept-art/act3/README.md), [adaptation](../concept-art/act3/ADAPTATION_NOTES.md), [canonical levels](../reference-library/act3/research/levels.json).
- [Equipment rules](../PLAYER_EQUIPMENT_GUIDELINES.md), [equipment grid](../EQUIPMENT_DESIGN_GRID.md), [ability workflow](../ABILITY_USAGE_WORKFLOW.md).
- [UI plan](../UI_DESIGN_PLAN.md), [difficulty plan](../DIFFICULTY_DESIGN.md), [Character Lab](../CHARACTER_LAB.md), [character assets](../CHARACTER_ASSETS.md), [character manifest](../../assets/characters/manifest.json), [effect manifest](../../assets/effects/manifest.json).

Before accepting a level or recovering context, read this file, the shared contract/progress, that act's `docs/acts/actN/ACT_MEMORY.md` and `PROGRESS.md`, and its individual level record. Pending requests and historical acceptance evidence must survive context resets. Temporary mailbox status never transfers ownership.


## Shared38 recovery point (9 October03:37UTC)

Campaign8/24 accepted: A1-L1/L2, A2-L1/L2/L3/L4, A3-L1/L2. Latest compatible registration is [A2-L4](ACT2_L4_REGISTRATION.md): complete owner1a5e9ea, exact content05a15, actual root entry243/0 and untouched earned L3→production L4 transition1375/0. Original failed sandbox setup5/1/source-only unused freeze and prior authored scopes retain their attribution in portable evidence. Gameplay kernels remain Shared37; worker adoption ACKs are separate and canonical run.json records each actual baseline.

Root remains sole integration/help owner. Act1 L3 prefix Save665/0 is independently verified; current floor/portrait/extremes/acceptance remain. Act3 headless whole-parent warning/Continue/Retry progresses while rendering timeout/focus diagnosis remains open. Act2 proceeds L5 after this acceptance; all optional levels remain separate authored work. Runtime cost requests remain open without demonstrated gain. Continue targeted changed-level/directly affected checks; full24-level desktop goal stays ACTIVE, stop before mobile/export/release.

## Shared39 recovery point (9 October 2026)

Campaign remains8/24. [Projected Cue reference bits](CUE_REFERENCE_BITS.md) provide a compatible internal comparison improvement:439/0 targeted correctness and three unchanged one-Box profiles113/0, with lower candidate medians but worse repeat tails. Exact raw sources/logs and limitations are durable; production performance requests remain OPEN. No controller/Scheduler/camera/HUD/save/schema or accepted-level content changed. All three actual Shared38 preserving adoption ACKs passed custody review; Shared39 adoption requires separate actual ACKs.

Act1 L3 portrait1140/1 now requires narrow Resume attribution; Root’s passive observation plan preserves all original input/assertions, with no shared HUD cause proved. Act3 owned corrected warning/Continue/due lock/ordinary attack/protected Retry/cleanup18/0 closes clean; fullroute/kits/zero-ammo/portrait still pending. Act2 proceeds L5 from accepted L4. Workers remain the same registered owners, Root remains first help contact, and the24-level desktop objective stays ACTIVE. Run only changed-level/directly affected checks; stop before mobile/export/release.


## Shared39 current recovery (9 October2026)

All three original workers have actual independently verified Shared39 adoptions at9ef31ace; [custody](SHARED39_WORKER_ADOPTION_VERIFICATION.json). Root remains sole shared/integration owner and first help contact. Campaign8/24: A1/A3 currentL3, A2 currentL5; later levels remain sequential. Act1 earlier Camera/HUD/temporal camera dependency is resolved; fresh Resume325/0 proves three zero-gameplay loops only, earned Crossed failure remains under actual passive diagnosis. Act3 failed8/1 pulse route lacks real approach; bounded swipe correction is owned work, with actual portrait rendering/focus proof still pending after native app access recovered from a temporary Mac lock. Act2 ray729/0 is independently verified as a bounded component with707 original copies; Foot/fullboss/level/recognizer/art/performance remain unfinished, with no fullL5 acceptance.

The [numeric Cue candidate](CUE_NUMERIC_COMPARISON_EXPERIMENT.md) is withdrawn despite2499/0 correctness: actual54.840ms median exceeds fresh39 baseline47.812ms. LiveCue remains exactc8a7; cost requests OPEN. Original raw scopes/387 inputs remain intact and no third/fullroute/broad rerun is credited. Exact generated bits-testUID metadata is adopted without code/import changes; older freezes are never backfilled. Continue targeted directly affected work and concrete worker help. Desktop24-level goal remains ACTIVE; stop before mobile/export/release.


## Shared40 current recovery

Current [private source-reference comparison](SOURCE_GUARD_REFERENCE.md) preserves actual native authority/public fallback and has clean574/0,139/0 and two unchanged113/0 profile scopes. OneBox median45.156ms versus52.422ms is bounded/noisy, not FPS/fulllevel acceptance; cost staysOPEN. Original506 inputs and complete raw receipts are durable.

Latest user [focused acceptance](LEVEL_ACCEPTANCE.md) governs pending levels: mechanics/loading/transitions/saves/Retry/cleanup plus brief visuals, no required agent fullroute/defeat-all/earnedexit/campaignplaythrough. Historical results remain truthful and untested full-playthrough behavior is explicit. Campaign8/24 remains; A1/A3 currentL3 and A2 currentL5 can be accepted independently from focused handoffs, then proceed sequentially. Allthree original assigned owners have verified actuala400 supplement custody; later Shared40 adoption requires an actual ACK. Root is sole shared/integration owner and first help contact. Stop before mobile/release.
