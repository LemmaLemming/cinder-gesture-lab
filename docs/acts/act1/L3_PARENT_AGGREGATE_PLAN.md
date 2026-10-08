# L3 five-beat parent: retained aggregate plan

Owned architecture proposal, reviewed 2026-10-09. This is not implemented full-parent content or a campaign save pass. The small one-role C31 component passed 93/0 headless and 109/0 graphical state checks; all five first graphical images are obstructed by the actual Pause modal and establish no pose readability. The capture-only correction is queued separately. The full five-room Caverns parent still explicitly refuses campaign snapshots. Current tested/adopted baseline is shared26; read-only reviewed shared27 preserves the native spore APIs and adds only Shell drain settlement, with no candidate-binding preparation seam.

## Decisions supported by the inspected code

One actual level-local **shared `CinderThreatScheduler`** can serve sequential rooms while retaining earlier genuinely defeated actors. Their whole native envelopes keep their own historical `role_encounter_id`, `profile_id`, `resolved_role` and cycle; they do not receive copied current-room role history. The current codec checks inactive/no-lease units before requiring the current Scheduler encounter/profile. A defeated or dormant source must have no owned reservation or cooldown. See [codec context validation](../../../scripts/acts/act1/mushroom_selenite_codec.gd#L259) and [public encounter boundaries](../../../scripts/combat/threat_scheduler.gd#L67).

Separate **per-spore-room consumers with disjoint permanent source IDs** can all reference that same actual Scheduler and Player. Each consumer's capture must use the *current* whole Scheduler/Player pair, together with that consumer's exact actor and field subset. Its native reference hashes are recomputed from those whole actor records; an old room's previously saved Player/Scheduler envelope is never embedded as authority. The published coordinator does not store an encounter epoch in its immutable protocol references. This is a source inspection conclusion, not a tested multi-room result. See [current native pair/reference validation](../../../scripts/environment/spore_repulsion.gd#L1025) and [native current-unit capture](../../../scripts/environment/scheduler_spore_source_protocol.gd#L290).

**Fresh Continue/Retry is not expressible by the current parent simply composing its existing methods.** An entered fresh candidate has dormant/unbound future actors. Actor `_schema_error` rejects a saved bound stamp against an unbound recipient; Protocol `configure` and Consumer `bind_environment` require actual living recipients. Shell performs pure saved validation against that fresh candidate before calling either restore hook. Binding or activating sources from inside the validator would violate its purity and the documented no-activation restore order. A public candidate preparation/restore-binding path is needed before this full-parent contract can be claimed. Details below.

## Cast and authoritative scope

[Canonical research](../../../docs/reference-library/act1/research/levels.json#L419) specifies three or four initial swarmers, a reachable spore demonstration, initially about eight in the crossed grotto, one isolated guard, and a final small swarm plus guard. Timing estimates are pacing hypotheses, not timer gates. All required groups remain viable with ordinary primary, after every cluster is spent, without pickups or blast ammo. Spore use is finite harmless repulsion of living enemies, followed by visible regroup and normal fresh attack tells.

The proposed **3 / 3 / 8 / 1 / (3 + guard)** retained cast totals **19**, not 18. Three initial and three final swarmers are owned choices within the canonical descriptions; they are not new confirmed numerical requirements. The layout already supplies those positions plus a fourth optional initial position. Do not silently use that fourth position and still claim 19. See [layout source table](../../../scripts/acts/act1/mushroom_caverns_layout.gd#L26).

| Beat | Proposed retained IDs (not yet created) | Native role | Environmental consumer |
|---|---|---|---|
| Umbrella grove | existing `umbrella-1..3` | three C31 / A1-E2 | none |
| Breathing chamber | `breathing-1..3` | three C31 | one room consumer / `breathing` field |
| Crossed grotto | `crossed-1..8` | eight C31 | one room consumer / `crossed-left`, `crossed-right` fields |
| The spear braces | existing `lone-guard` | one C32 / A1-E3 | none |
| Court approach | `court-1..3`, `court-guard` | three C31, one C32 | one room consumer / `court` field |

Only the first three C31 and isolated C32 currently exist. A retained nineteen-source scene needs fifteen additional actor instances. Layout coordinates and four field definitions are scaffolding; the full rooms, route, checkpoints, exit and whole save are not already implemented. All nineteen IDs must be globally distinct even where role/art/config families are reused. A consumer has one permanent binding per source; never rebind the original `lone-guard` to impersonate the final guard. Shared limits of 16 fields and 64 sources per coordinator do not obstruct these proposed subsets.

## Minimal owned aggregate

Use a new authored main scene and explicit local snapshot version. Keep shared envelopes whole, including conditional actor 1/2/3/4 and coordinator schema 2; do not infer their schema from a level version. Proposed closed local roots:

```text
beat_index        integer 0..5
completed_beats   exact prefix of the five canonical beat IDs
room_stage        approach | preparing_environment | active
actors            exact nineteen stable IDs -> whole native actor envelopes
scheduler         one complete current shared Scheduler envelope
fields            exact four stable IDs -> null-before-install or whole Field unit
consumers         exact three room IDs -> null-before-install or whole Coordinator unit
framing           exact live native source IDs -> closed accepted response witnesses
```

`room_stage` is an owned lifecycle discriminator, not a new clock. `preparing_environment` is needed only if physical readiness genuinely leaves a quiet interval between activation and binding; prefer complete same-callback construction where supported, and suppress native admission until the room's required environment is installed. This is not a compulsory settling timer. Once a past room's resources are installed, retain them and their real supply/field clocks. Null means *no instance has been installed*; it cannot mean hidden available clusters, a fabricated spent envelope, or a consumer whose binding was discarded. Exact expected non-null keys derive from the completed prefix plus current room stage, so no extra mutable installed-ID ledger is needed.

Configuration tables, role families, room source membership, field membership, source positions and contact geometry stay immutable in code. Each actor and coordinator still preserves its own complete immutable configuration in its native envelope. Do not duplicate HP, field supply, retreat progress or profile in a second owned authority. `framing` carries accepted reservation ID, safe landing, ordinary attack pose, `primary_time_s`, and `response_complete_s`; the native Scheduler/actor carries the actual deadline/sample authority.

Accepted [L2 capture/validation](../../../scripts/acts/act1/crater_gardens.gd#L906), [progress checks](../../../scripts/acts/act1/crater_gardens.gd#L1154) and [quiet reconstruction](../../../scripts/acts/act1/crater_gardens.gd#L1168) provide the useful architecture. Do not copy its circle/custody/cursor keys into L3 when they represent no L3 state.

## Normal room lifecycle

1. All nineteen actual sources bind once to the actual Player/Scheduler. Future rooms remain pristine dormant, collider disabled, root hidden, outside `enemies`, no motion/HP/role/cycle/consumer history. Retain actual shape/script/art handles; a hidden parent is not a dormant substitute.
2. Only the next authored broad entrance is entitled. Previous required sources must actually be dead with no owner leases/cooldowns or environmental records/routes. Mark an advance from callbacks, then process it outside Actor/Scheduler/Consumer transactions. A synchronous cancellation observer cannot reset the epoch.
3. The fresh room boundary uses public `end_encounter`, followed by successful public `begin_encounter` with the shell's current preference and immutable room encounter ID/world revision. That success alone arms parent activation entitlement. Activate that room's sources once; clear entitlement on every attempt. No replayed activation, healing or synthetic cycle is allowed. Beginning resets Scheduler clock/tables; it does not reset old Field clocks/supply or old Actor role history.
4. For a spore room, preflight actual same-world body/floor/static signatures, all living recipients, permanent IDs, route guard callables and camera requirements. Configure one protocol per recipient, then construct and bind the fixed room fields and one consumer. Keep parent `_changing` across this lifecycle; no user attack or snapshot runs between a partial bind and completed installation. Public native support measurement permits fresh absent floor-history; do not fake `grounded` or wait a prescribed duration merely to satisfy it. If genuine component guards still require a physics interval, the saved `preparing_environment` state must explicitly describe it, and an early real kill cannot strand binding forever.
5. Future fields should be genuinely absent until their room is installed. Current shared clusters register in `environment_attack_targets` at ready, and Field binding requires that membership. Hiding a ready field or removing its targets from the group creates an invalid/hidden interaction; Field has no authored dormant gate. Do not set supply spent to disable it. Install at fixed actual coordinates and retain it thereafter. All four future-field absence cases require the candidate reconstruction seam below.
6. Run native pursuit/preview/admission through existing actual Actor/Scheduler APIs, public camera guards and actual body/world spacing. The first grove permits at most one preparing swarmer; shared budget/union still owns leases. Crossed/court policies need actual crowd tests; no private timer or cloned admission solver. Cancelled/repelled actors receive full normal fresh tells when genuinely eligible again.
7. Room clear is genuine required HP/death, not field expiry or a fabricated repulsion kill. Keep spent/available old clusters visibly truthful; finite field clocks may continue after a clear. There is no requirement to wait for their fade before crossing the checkpoint. Restrict living pursuit to the current authored room through actual owned movement guards, so it cannot escape its field subset and ignore later hazards. Dead old recipients cannot reactivate. Preserve failure diagnostics honestly rather than clearing them to obtain a clean save.
8. Commit the completed beat prefix and public progress together at a quiet boundary. Four nonfinal checkpoints remain proposed `umbrella-grove`, `breathing-chamber`, `crossed-grotto`, `spear-pocket`; final completion is `mushroom-caverns-clear`, followed by an actual reachable contact at the layout exit using `open-court`. Guard the public checkpoint/completion methods against external premature calls. The final contact is one native Area3D overlap by the actual Hero after all required groups are dead; taps on the curtain remain combat input, not an exit substitute.

## Capture, pure validation and reconstruction

At a complete paused deferred physics barrier, capture one whole Player and Scheduler. Capture every actual Actor against that pair, each installed Field, then each Consumer with exactly `{fields, sources, controllers, players}`: its room's installed field/source subsets, one common controller ID -> current Scheduler, `hero` -> current Player. Consumers do not include never-bound dormant actors; the root `actors` table still includes them. Never combine an earlier actor capture with a later Player or Scheduler tick.

Validate the entire closed owned progress/envelope before mutation. Validate the Player, all actor envelopes/configurations/body resources, merge the **inner** staged owner maps without losing another source's entries, and validate the one Scheduler using all actual nineteen owner bindings plus saved Hero position. Then validate all installed Fields and Consumers against the same staged whole pair. Old defeated room units need zero own leases/cooldowns/episodes but retain truthful past role history. Current live leases must belong to the exact current room epoch; future sources must be pristine dormant and unbound at exact authored positions. Past actors killed before their first attack legitimately retain cycle zero/empty role history; do not manufacture a first reservation to fill that history.

The root `framing` key set must equal live native reservation source IDs. Validate exact reservation/epoch identity, complete source/footprint, actual world-cleared safe landing and ordinary-primary reach/window using saved equipment, plus complete real Hero body/art translated to landing and attack positions. Keep native lunge endpoint tolerance only where the published native motion contract allows it; copied witness bits/IDs/clocks remain exact. Restore this accepted witness before exposing the resumed scene. The component currently clears `_framing` at [component restore](../../../scripts/acts/act1/mushroom_spore_component.gd#L304); that is insufficient for a live full-parent Continue.

Approach forecasts and provisional camera requests are derived caches, not movement authority. They can be rebuilt from actual restored motion without advancing a clock; next real motion must obtain a fresh actual guard. Keep requested-vs-accepted camera caches distinct. Native committed dash endpoints, all living room bodies/art, full required source/cues/lanes, and active field/repulsion endpoints must remain framed before danger or movement commits. The eight-body room may exceed the camera's bounded point/portrait capacity; measure it rather than omit a body or cue. Any conservative compression must enclose *all* actual required bounds and retain actual containment checks, with tests before claiming the room is supported.

After all units prevalidate, make one no-yield quiet commit: installed Fields and actual Player/Actor physical resources -> one Scheduler -> Actor exchanges/conditional repulsion stamps -> each Consumer's exact Routes -> owned prefix/stage/framing and presentation. No configure/activate/damage/cancel/request/acquire/clock advance belongs in this commit. Restore old and current coordinator contexts from the newly restored complete pair, not stored stale pair copies. The shell owns Player restoration; the root hook must not restore a second Player or heal/refill it.

## Concrete fresh-candidate dependency

The currently published combination has a specific construction gap:

- [Shell `_snapshot_problem`](../../../scripts/campaign/shell.gd#L466) calls `snapshot_error_with_player` on a fresh entered candidate; [`_prepare_snapshot`](../../../scripts/campaign/shell.gd#L451) creates a separate fresh commit candidate. Neither `_prepare` receives the saved local construction descriptor.
- [Actor `_schema_error`](../../../scripts/acts/act1/mushroom_selenite.gd#L1167) requires actual consumer-bound status to match saved conditional stamp presence. Its staging/physical/exchange methods all retain that check.
- [Protocol `configure`](../../../scripts/environment/scheduler_spore_source_protocol.gd#L44) requires an actual living unbound source, and [Consumer `bind_environment`](../../../scripts/environment/spore_repulsion.gd#L64) prevalidates living recipients plus existing actual ready Fields. Future dormant actors and genuine already-dead replacements cannot be bound through those ordinary initial paths.
- [Published protocol policy](../../../docs/development/SCHEDULER_SPORE_SOURCE.md#L73) says fresh restoration binds ready replacements before quietly applying defeat. It does not provide a level-specific way to prepare saved past/current room bindings through Shell's current factory. It also explicitly prohibits activation during restore.

Thus the logical historical-epoch support does **not** prove fresh room-2+ Continue. Request Integration guidance/a narrowly published public candidate preparation path: either explicit nonplayable paused construction of ready restore recipients/installed environments **before pure whole-unit validation**, or a reviewed staged native protocol/coordinator binding-and-validation path over actual retained dormant resources followed by an atomic binding commit. An owned factory would also need an explicit restore-recipient construction distinction from genuine gameplay activation; it must preserve immutable configuration and never expose a temporary healed actor as progress. These are proposed alternatives, not existing method names or tested permissions.

Do not activate future actors inside `snapshot_error_with_player`, toggle colliders for measurement, report dormant/dead sources as alive to configure, drop the bound stamp, configure all future consumers against every source, clone a private coordinator validator, or retain old Scheduler envelopes. Keeping null future resources is a valid desired schema but is not a way around this candidate-factory gap. Normal sequential route work and same-instance coherent component work can proceed independently; full Continue/Retry acceptance must exercise the eventual public path.

## Narrow tests for the eventual parent

- Genuine clear first room -> new epoch -> retain first whole defeat envelopes; capture all nineteen with one new Scheduler/Player. Negative old lease/cooldown, rewritten historical role, future alive/bound, duplicate room/source and wrong prefix reject atomically.
- Real field primary -> native leased C31 cancellation and C32 cancellation, no HP damage/extra refresh; real ordinary clear -> next room. Capture old active/spent Fields and dead consumers against the new current pair. Test overlapping two crossed fields and all supplies depleted without requiring their use to clear.
- Fresh candidate Continue and fresh checkpoint Retry in breathing/crossed/court with old defeated/bound, current warning/active/pending/retreat/interrupted, and future never-bound dormant records together. Injured Player, zero shells and exact clocks survive; one-bit actor/hash/field/route/pair mutations reject without donor/candidate progress mutation.
- Natural multi-source synchronous pause after one source samples but before another: capture must defer until the complete pair or transport the genuine published pending path. Do not synthesize another source's sample. Actual phase callback restore must preserve the full parent's framing witness.
- Actual eight-body portrait/source/boundary/landing frames, real input all-five-room ordinary clears after depletion, four checkpoints/final atomic completion/physical contact, instance isolation, fatal fresh Retry and entered-root direct free cleanup. Current component results do not cover these cases.

## Inspected source identities

Read-only checkout HEAD: `798d545a045963376d52168b42d9daf1c6e47296`. These identify inspected files, not a newly committed or tested candidate:

| Source | SHA-256 |
|---|---|
| `mushroom_caverns.gd` | `29a7be50cb526cebaabdd2d669aeb6957afbd99d13c526d7a795531171cb002f` |
| `mushroom_selenite.gd` | `9f677d04e276c1c63b6bd729b3425070c2f646cac8788d1723ae3965f14547fd` |
| `mushroom_selenite_codec.gd` | `bb418bacb4f1d0ac7a28cf476117730acba39bb07120fe8e6d6d02aa92ac3eae` |
| `mushroom_spore_component.gd` | `a29bb3d10cdfbc8c61b53a8a8185a48fc27bf9de931724c52928f2cc42d8314c` |
| `crater_gardens.gd` | `7e19a94cf95500932698c7502680b92eb9a1d500258cbd261f524e189bb770d9` |
| shared Scheduler | `07ed10a995d3709f6492e35dba1b1d579d7b2eb22ff9e8af7f88be9abee758e6` |
| shared SporeRepulsion | `74a9ce841f73b1550a2137f3404092f0ebd6f727126dffc487b11af739025db6` |
| shared native Protocol | `c9a1e5e16abaf4a705a4dbacb6f6926159e8718fb95503a58f815123506e5b32` |
| shared Shell | `9c70320842eec6683ce8ea853104341f75ef1faabcdbdea83b4ecd0e36eb490c` |
| shared SporeField | `b109f9872e810ec6d2b30a9d017f47e83f70fa3d086cb83f7e6717f757e51cd7` |

Only this private note was written. No source/resource/test/ledger/mailbox edit, engine/import job or commit was performed.
