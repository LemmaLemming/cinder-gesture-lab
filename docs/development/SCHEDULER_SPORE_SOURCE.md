# Scheduler-driven spore sources

This interface is **native-verified for campaign-shared-26**, resolving canonical Act1 REQUEST `27b2940a-6455-4ad5-86d0-937a437c87fc`. The [composition helper](../../scripts/environment/scheduler_spore_source_protocol.gd), additive pure Scheduler accessor and opt-in coordinator branch pass **208/0** native checks; the directly affected existing Ash leaf passes **87/0**. Both actual queued jobs exit0 with clean raw and wrapper logs. Exact publication commit and adoption responses are recorded in the canonical mailbox and [shared progress](SHARED_PROGRESS.md). This is shared API evidence; A1-L3 remains an independently authored, unaccepted level.

The confirmed rule is [harmless repulsion of living enemies](../ACT1_CONCEPT.md#hittable-spores-create-breathing-room). C31's proposed short grounded lunge with a cosmetic hop and C32's proposed stationary thrust lane can use the existing Scheduler. This interface adds their environmental binding and coherent restoration, without new damage, airborne physics, player equipment or ability allocation.

## Composition and existing authority

Use one small `CinderSchedulerSporeSourceProtocol` composition object per opted source. Do not add an actor base class. The actual source remains its own `CharacterBody3D`, with its owned controller, presentation and native codec. For example, the existing [C30 actor](../../scripts/acts/act1/rush_selenite.gd) already owns sampled damage and a two-stage physical-actor/exchange restore. An Ash-derived substitute would change that authority and manufacture an incompatible snapshot.

The composition object holds weak references to the actual source, `CinderThreatScheduler` and `CinderPlayer`. It retains the source's owned codec, script resource, immutable configuration, actual `BodyCollision` and shape resources, registered shape/body properties and [measured route binding](REPULSION_ROUTE.md). Resource identity is checked while live; persisted records contain closed values and stable authored IDs, never Objects, WeakRefs, RIDs or instance IDs. A fresh candidate measures its own actual resources against the same authored descriptor.

[SporeRepulsion](SPORE_REPULSION.md) continues to own field membership and episode/recoil/retreat/regroup clocks. [RepulsionRoute](REPULSION_ROUTE.md) continues to own its measured native lease. The Scheduler owns attack deadlines, retained cooldown and lunge movement. The actor owns HP, hurt/impulse settling, attack opportunity samples, deduplication, death and presentation. The helper owns no clocks or resource copies.

Ordinary Ash bindings, responses and coordinator schema 1 retain their existing behavior. Native CAPSULE support already exists in the route; this interface does not change its collider, support proof, floor tolerance, static-world restriction, motion execution or endpoint bounds.

## Actual source and codec interface

The available helper is at `scripts/environment/scheduler_spore_source_protocol.gd`, extending `RefCounted`. Its binding API is:

```gdscript
configure(source: CharacterBody3D, scheduler: CinderThreatScheduler,
    player: CinderPlayer, source_id: String, controller_id: String,
    player_id: String, environment: Dictionary) -> bool
binding_error() -> String
binding_state() -> Dictionary
matches_source(source: CharacterBody3D, source_id: String) -> bool
binding_compatibility_error(other: CinderSchedulerSporeSourceProtocol) -> String
bind_error(consumer: Node) -> String
bind(consumer: Node) -> bool
response_state() -> Dictionary
control_state() -> Dictionary
profile_state() -> Dictionary
unit_error(actor: Dictionary, context: Dictionary) -> String
unit_view(actor: Dictionary, context: Dictionary) -> Dictionary
current_unit(context: Dictionary) -> Dictionary
```

`environment` is the existing actual `world_root`/`floors` binding. Configuration is one-shot and validates the complete native binding before caching it. `binding_error`, `binding_state`, `bind_error`, `response_state`, `unit_error` and `unit_view` are pure defensive queries: no pruning, diagnostics assignment, callbacks, collision exceptions, pose/velocity change, serial allocation or timer advancement. Invalid views return an empty dictionary; callers first obtain the nonempty error. `current_unit` is a paused capture, with the actor's existing capture diagnostics and transaction restrictions, not a live response query.

The actual actor supplies a pure `get_spore_native_bindings()->Dictionary`, with exactly:

| Key | Required value |
| --- | --- |
| `api_revision` | `scheduler-spore-actor-1` |
| `actor_revision` | The genuine native actor envelope API revision, distinct from its environmental protocol revision |
| `source_id` | The actor's permanent configured source ID, equal to the source-map key |
| `scheduler` | The actual retained `CinderThreatScheduler` used by its attack controller |
| `player` | The actual retained `CinderPlayer` sampled by that controller |
| `codec` | Its retained owned `RefCounted` native record decoder |
| `configuration` | Defensive closed copy of its complete immutable native configuration |

The helper obtains the codec from the actual source and verifies the same object and codec script on every live guard. A caller cannot substitute a codec or controller when binding. Configuration must pass the bounded closed-value encoder before copying; unsupported/cyclic/object input rejects without allocation of a coordinator lease. The accepted actor/codec implementation remains trusted code, rather than an arbitrary callable supplied to prove itself safe.

The owned codec exposes two pure methods:

```gdscript
record_error(actor: Dictionary, scheduler: Dictionary,
    player: Dictionary, binding: Dictionary) -> String
record_view(actor: Dictionary, binding: Dictionary) -> Dictionary
```

`record_error` validates the actor's **whole native envelope** against its immutable configuration, stable source/controller/player IDs, separately validated complete Scheduler and Player units, and the actor's genuine schema. It must preserve native role/profile, HP/death/hurt, motion, sampled opportunities, pending segments, cue state and cooldown custody. It accepts actual defeated envelopes without a live source. `record_view` runs only after that validation and derives the common view from the same envelope. It cannot translate the actor into Ash's radial-cone role, fixed clocks or prototype sprite record.

The actor also implements the existing named environmental hooks: `bind_spore_repulsion`, `get_spore_response_state`, `cancel_attack_for_spores`, `present_spore_phase`, `resume_spore_retreat` and `finish_spore_episode`. Their signatures follow [the current opt-in actor hooks](SPORE_REPULSION.md#public-interfaces). A new pure `spore_bind_error(consumer: Node, source_id: String)->String` prevalidates binding; successful bind is deterministic and silent. The actor's native paused writer accepts its validated paired context and includes a conditional repulsion stamp. A helper-specific `spore_snapshot_state(scheduler: Dictionary, player: Dictionary)->Dictionary` can delegate to that writer without altering its ordinary public signature.

The common live view has exactly these keys: `api_revision`, `source_id`, `consumer_id`, `alive`, `grounded`, `position`, `velocity`, `facing`, `hurt_remaining_s`, `body_collision_path`, `support_radius`, `height`, `episode_id`, `phase`, `direction`, `progress`, `outside_transaction`. Its revision is `scheduler-spore-actor-1`; live vectors are native. The source ID is permanent, while consumer ID is empty before binding. Position/velocity and measured body values are cross-checked against the actual node and retained collider. Grounded/hurt/episode state comes from the genuine actor. There is no cloned cooldown countdown in this view.

The common saved view contains `source_id`, `consumer_id`, `alive`, `grounded`, `motion`, `repulsion` and `reservation_id`. `motion` is `{position, basis, velocity, facing}` with encoded native vectors and identity basis. The codec verifies the native actor's upright body even if its own envelope represents that basis implicitly. `repulsion` is exactly `{api_revision, consumer_id, source_id, episode_id, phase, direction, progress}`. Phase is `none`, `recoil`, `turn`, `retreat`, `hold`, `regroup`, `interrupted` or `failed`; `none` requires empty episode and zero progress. The view is validation input, never a replacement actor save or HP authority.

Before any source binding commit, pairwise `binding_compatibility_error` requires a one-to-one relation between stable controller/Player/source IDs and the retained actual objects. Two controllers or Players cannot share one ID, and one actual object cannot use conflicting IDs. These identity checks remain pure; persisted descriptors still contain no Objects. The live guard also requires source physics to remain after its actual Scheduler and Player, rather than checking ordering only at configuration.

Initial binding requires a ready actual living, active source with the supported native body and measured actual floor support. A fresh recipient's absent `is_on_floor()` history is not a substitute for, or reason to reject, that physical support proof. Dormant future encounter actors are not field consumers. A fresh restore binds ready replacements before silently applying saved defeat; it never activates a dormant target or creates a missing live actor on behalf of a level.

## Pure Scheduler accessor

Integration has adopted the additive `source_control_state(owner: Node3D)->Dictionary` accessor. Invalid owner/world returns `{}`. It reads the raw retained tables, with no `_prune`, expiry, callbacks or diagnostic mutation. Its exact native keys are:

```gdscript
{
    "api_revision": "scheduler-source-control-1",
    "source_instance_id": owner.get_instance_id(),
    "encounter_id": String,
    "world_revision": int,
    "clock_s": float,
    "outside_transaction": bool,
    "reservations": Array, # defensive public records for this exact weak owner
    "cooldown": null,     # or {"ready_s": float}
}
```

`outside_transaction` is false during snapshot/request/boundary/native update transactions. A retained expired cooldown remains present until ordinary cleanup; this query does not make a source ready. The owner must match the actual WeakRef, not merely an instance ID. Public records may have native geometry/adapter vectors; they are not a saved envelope. Copied deadlines and clock retain exact bits/types. The helper derives no new decrementing cooldown and never calls `reservations()` or `reservation_state()` to implement a pure response: both currently prune and may emit cancellations.

The helper's `matches_source` checks the exact actual node and permanent ID. Its pure `control_state` returns the guarded defensive Scheduler view through the retained controller, so a coordinator need not trust another raw `get_spore_native_bindings` invocation. Its paused writer compares actual own source/opening positions, geometry and optional full native adapter, after recursively encoding native vectors, alongside exact lease IDs/deadlines. The actor may use the pure accessor to verify its genuine reservation ID, controller ownership and post-cancellation absence of a lease. Complete paused Scheduler transport still uses its existing stable owner/floor/world bindings and validator.

## Cancellation, motion and callbacks

The coordinator proves the full actual-body outside-union route before cancellation. The actor commits suppression of attack/sample/pending damage and its episode stamp before synchronous cancellation/cue observers, then cancels its exact ordinary reservation with `cancel(id, "spore_repulsion")`. It must not use `cancel_owner` for repulsion: ordinary cancellation retains the actual Scheduler cooldown, whereas owner cancellation is for death/removal.

Before route acquisition, verify that the exact source has no retained attack reservation, the actor/controller binding and prepared pose/body/world are unchanged, and the actor remains alive without newly authoritative hurt/impulse. Copy the actual pre-cancellation control and profile, then require exact clock, encounter, world revision, profile and retained cooldown after callbacks. Require the prepared episode/direction and zero progress. A verified owned lunge legitimately changes velocity to zero when Scheduler cancels it; a stationary controller retains its actual approach velocity until acquisition. Any other velocity change is external custody and cannot be erased by `Route.acquire`. Apply these checks again around a continuation hook. The public `end_encounter` request is ignored during Scheduler cancellation transactions; `cancel_owner` can remove cooldown, which fails this custody gate for a surviving source. A callback pause retains a coherent cancellation/episode boundary without advancing field, retreat or attack clocks. If cancellation has committed but the prepared route cannot acquire, report a visible failed episode with no attack rearm; do not undo cancellation, cooldown or actual damage. Never report a successfully moving episode with an unleased route. A callback introducing real damage is handled as the same episode's interrupted state, with its real impulse preserved.

The actual actor calls `step_source` before entering its ordinary actor transaction. Held episodes suppress its ordinary movement and fresh attack admission. The Scheduler advances lunges independently before the actor's physics; a held actor flag alone cannot suppress a retained lunge. Actual reservation removal is therefore mandatory. Scheduler cooldown continues through its own one simulation clock; the actor advances its independent hurt/cosmetic clocks once, following its existing ownership.

Actual damage applies HP/impulse/hurt first, then calls `source_interrupted` before observers can reenter damage delivery. Route release preserves that external impulse. A surviving source may resume the same original episode/endpoint after genuine grounded settling; no second recoil or timer refresh. Actual death clears its real lease/cooldown and leaves defeat/drop/tombstone ownership with its actor and parent. Approaching controllers reuse `allows_source_step`; the protocol does not invent a pursuit controller.

## Conditional paired transport

Keep the old Ash-only coordinator envelope and context strictly schema 1. Opted native sources use schema 2 with one additional `source_protocols` map. Keys are exactly the opted source IDs; each value contains `api_revision`, `actor_revision`, `source_id`, `controller_id`, `player_id`, `configuration_sha256` and `actor_sha256`. The actor hash references its complete authoritative external unit, including its conditional repulsion stamp. Configuration/hash encoding must be nonempty bounded [ExactJson](../../scripts/campaign/exact_json.gd) before digesting. Digests establish exact paired identity, not authenticity of an arbitrarily modified historical save.

The new external context is `{fields, sources, controllers, players}`. `sources` retains complete native actor envelopes; it does not hold common views. `controllers` and `players` are stable-ID maps of separately validated complete units, shared by all referencing sources rather than copied per actor. Both maps have exactly the unique opted bindings needed by this coordinator. Native sources resolve their immutable controller/player IDs; ordinary Ash sources still use their existing decoder within a mixed schema-2 coordinator.

At one paused deferred boundary, the trusted parent validates the complete Player, Scheduler, native actor, field and other level units, including staged real source collision/lifecycle/motion bindings. The helper then validates each native actor/context pair and derives its common view for the coordinator's existing body/episode/route checks. Every active spore episode requires no source-owned Scheduler reservation or pending attack delivery. A defeated/dormant actor cannot retain its owner cooldown. A living cancelled source's cooldown comes from the exact paired Scheduler table and is never refreshed by the environmental record.

Staged validation uses saved controller clocks/tables and saved source motion, rather than requiring a fresh recipient's current encounter, clock, pose, floor history or cooldown to equal them. Actual retained controller/resource identities and real registered scenery remain mandatory. The virtual route proof runs at the validated saved pose with the unchanged collider; it cannot move the recipient, raise it above the floor or temporarily exclude a blocker. Actual-current equality belongs to the later commit cross-check.

All units prevalidate before any commit. Commit fields and Player/native physical actor resources, then Scheduler, then actor exchange/repulsion presentation, then coordinator routes. Actor rendering blocks its existing signals during reconstruction. The coordinator checks that actual native captures equal the staged external envelopes before adopting routes. Restore never invokes activation, attack request/cancel, damage, route `plan`/`acquire`, or simulation advancement. Fatal Player envelopes can remain dead and paused; restoration does not refill or revive them.

Retain the accepted owned codec/configuration after the actual source is removed. Its full captured defeat envelope is the source tombstone. Missing live sources reject; missing defeated sources require that validated native defeat and no source episode/reservation/cooldown. The decoder cannot manufacture HP, drop state, a replacement actor or a fresh field generation. The parent remains responsible for the genuine whole-unit capture and staged replacement; this protocol cannot authenticate arbitrary edited historical saves or police another custodian.

Older consumers cannot read schema 2. Publish an explicit adoption revision before an authored actor writes it. Native actor envelopes add their repulsion stamp only when opted in, with an explicitly documented conditional actor schema; existing unbound C30 schemas 2/3 and ordinary Ash saves retain their current keys. Copied clock, field-generation, source identity, configuration, deadline and actor-reference equality is exact; use ExactJson scalar bits/types, not `SnapshotCodec.same_values` numeric tolerance. Existing spatial query tolerances remain unchanged. In a mixed schema-2 coordinator these exact copy checks also cover ordinary Ash external units, immutable definition/body/floor/world data, every field stamp, actor-to-episode direction/progress and route direction/elapsed clock. Ash's decoder remains unchanged. The identity basis uses encoded native float components; literal integer zero/one values cannot substitute for them. Derived `age_s - route_started_age_s` and independently accumulated `phase_age_s` retain the existing arithmetic consistency rule; this is separate from copied elapsed-clock identity and grants no tolerance to copied transport fields.

## Exact core patch seams and focused evidence

The additive coordinator implementation is confined to six seams:

1. `bind_environment`: optional native `source_protocols` binding map; exact opted-source coverage; pure prevalidation of every field/source/helper before any silent actor binding. Ordinary sources remain the existing Ash branch. A permanent native source ID is checked against the map key, rather than Ash's initially empty spore ID rule.
2. Live response reads: select the validated helper for opted sources; keep actual `CharacterBody3D` as Route owner and environmental callback source. Use the measured collider for support radius/height and retain full-circle/no-wall domain restrictions.
3. Reaction acquisition: verify actual Scheduler cancellation and callback custody before acquiring the already proved route; do not substitute a proxy source or alter HP/timers.
4. Snapshot writer/reader: select schema 1 or conditional schema 2; resolve the owned native codec/context and exact actor reference, then apply existing episode/route checks to the validated common view.
5. Commit cross-check: call helper `current_unit` with its genuine paired context instead of assuming a no-argument Ash writer. Compare exact nonempty complete envelopes before adopting local routes.
6. Defeat/removal: retain the immutable native decoder/configuration for tombstones; use existing source-independent static-world proof and reject missing living nodes.

The new native leaf exercises actual warning/lock and active lane/lunge cancellation; the active lunge moves the actual capsule before cancellation. A separated real Player starts inside the conservative warning corridor but outside the moving damage body: no initial corridor-only damage occurs, then exactly one actual hit occurs after native approach. Pure accessor/resource/configuration/priority checks, retained cooldown, harmless primary/blast cluster activation, stale raw-table reads, bidirectional stable-ID/object alias rejection and freed-handle rejection also pass.

Synchronous cancellation observers pause, deliver one genuine nested source damage transaction, attempt a transaction-blocked encounter end, remove cooldown, combine damage with cooldown removal, or inject horizontal motion. Legitimate hurt/impulse settles; a custody fault cannot later reacquire a route or rearm an attack. Whole paused fresh restoration is exercised for an actual unconsumed native contact opportunity, active retreat and hurt interruption. Removed-source defeat retains its whole native codec/configuration tombstone. ExactJson and one-bit paired field/actor/configuration/hash mutations are checked. A recoil cancellation pause is captured without clock advancement; this leaf does not claim fresh reconstruction of every turn/hold/regroup boundary.

[Portable evidence](evidence/shared26-scheduler-spore/index.json) retains each original pre-job61-file source subset, raw native log and full wrapper output. The subset follows literal resource references from the two leaves, protocol document, wrapper and project file; it is not a full engine import/resource graph. Original invalid/failing runs remain distinct:

| Run | Actual result | Interpretation |
| --- | --- | --- |
| Native1 | Process0; parse error at fixture match234 | No gameplay checks; invalid |
| Native2 | Process0; printed1/0 with compile/runtime errors | New global type missing from cache; invalid |
| Native3 | Process1;151/13 plus two ScriptErrors | Missing fixture opening, one-sided retreat and wrong cue signal; failed |
| Native4 | Process0;208/0; clean | Corrected actual native target |
| Affected Ash | Process0;87/0; clean | Existing directly affected leaf, run once |

The grammar repair uses explicit callback blocks. The new helper is typed through its existing preload, without requiring a prior class-cache import. Fixture inputs supply the actual stationary recovery position and both independently proved outward directions; the shared placement/custody checks are not weakened. Copied original61-file source hashes match live files at each final job closure. Run3's empty-result cascades are guarded while retaining their failing assertions.

Named queued target: `python3 scripts/dev/dev.py test scheduler_spore_source`. The affected existing leaf is `python3 scripts/dev/dev.py test spore_repulsion`. No broad suite or unchanged authored level was repeated. Existing field/route/Ash evidence retains its historical scope. Owned C31/C32 room tests must supply actual portrait, ordinary-primary/no-ammo/depleted-supply escape, combined-threat and complete local aggregate evidence. No authored mushroom placement, room fairness, human balance, performance or mobile claim follows from this shared fixture.


## Native fixture and ownership

The NEW [native source fixture](../../tests/fixtures/environment/scheduler_spore_native_actor.gd) is a genuine `CharacterBody3D` with the shared capsule dimensions, real Scheduler lane/lunge admission and movement, a real shared `CinderPlayer`, owned HP/hurt/lifecycle and a [whole native codec](../../tests/fixtures/environment/scheduler_spore_native_codec.gd). It calls its actual bound `SporeRepulsion.step_source` before entering the ordinary actor transaction. Stationary active contact uses the actual admitted lane. Lunge contact uses sampled actual Hero-minus-source endpoints against the moving damage radius, rather than the full conservative warning corridor. Both retain exact source/Hero samples and authoritative deadlines, consume `hero` before hurt/event observers, and cancel on lost required native cue/lease. It does not claim authored C31/C32 presentation, pursuit, room fairness or accepted content.

A cue callback can pause before contact: the actor writes conditional schema 2 only while an unconsumed bounded sampled path exists, otherwise retains its schema-1 keys. The codec validates each segment's exact contiguous copied Hero/source endpoints and clocks, physical-tick span, current paired samples, native lease and hit latch. Zero-duration segments cannot contain travel; array/null cue geometry rejects before dereference. Fresh restore reconstructs this opportunity quietly; cancellation removes it. This is fixture-owned transport, not a migration of C30 or a promise that another actor already implements the protocol.

The new leaf is authored to exercise actual warning/lock and active lane/lunge contact/cancellation, exact retained cooldown and body/HP preservation, overlap without refresh, hurt impulse interruption, paused native pending/retreat/interruption restore, missing-defeat decoding, one-bit immutable/controller/field/pair mutations, and freed actual world/floor/collider/codec rejection before casts. Actual invalidation observers pause, call one genuine native public damage transaction, attempt a transaction-blocked encounter end, erase cooldown (also combined with genuine damage), or inject a clearly labelled horizontal-velocity fault. The test-only actor permits one real nested damage call during its cancellation delivery and rejects further nested calls. The paired hurt/cooldown fault also waits for genuine native hurt/airborne settling, then checks that the fault cannot reacquire a route or rearm an attack. A separate lunge fixture starts the real Hero 1.1 metres ahead inside the conservative warning corridor, checks no damage at the first active tick while the moving damage body is still out of reach, then checks one genuine hit after actual native approach. Other cases exercise stale retained table reads without cleanup, both stable-ID/object alias directions, changed live physics ordering, and shared Hero primary then blast against real clusters with ordinary ammo cost and no enemy credit. The native208/0 result has the bounded scope above. Historical ignored authoring proposals `.cinder/scheduler-spore-coordinator.patch` and `.cinder/scheduler-spore-coordinator-candidate.gd.txt` preceded the final root guards and are not the published source. Root adopted and repaired the actual coordinator, retained reviewed pure accessor/helper code, and ran both final targets before publication. Fixture corrections changed no shared collision, motion, timing, HP or route acceptance policy.


## Inspected native API guidance

The integration owner inspected these matching official 4.7 pages on 2026-10-08 UTC; this helper author rechecked the same sections on 2026-10-09. Applicability is the recorded local build `Godot 4.7.2.stable.official.ed1daf0bf`, not an inferred documentation version.

[CharacterBody3D velocity and floor state](https://docs.godotengine.org/en/4.7/classes/class_characterbody3d.html#class-characterbody3d-property-velocity): `move_and_slide` uses and may modify velocity; floor state records its last call. Adaptation: retain actual authoritative impulse, and stage the saved grounded latch alongside a pure native support proof rather than substituting a fresh recipient's floor history.

[Node physics priority](https://docs.godotengine.org/en/4.7/classes/class_node.html#class-node-property-process-physics-priority): lower physics priorities run first, with equal priorities following tree order. Adaptation: require the actual source to sample after both actual Scheduler movement and shared Player physics, rechecking that relationship during live guards.

These API descriptions guide the ownership boundary; they do not prove cancellation, contact or restoration correctness. The new native target must provide that evidence. No community content or demonstration footage was inspected for this seam.
