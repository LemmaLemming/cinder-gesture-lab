# Shared spore repulsion consumer

`spore-repulsion-1` in [spore_repulsion.gd](../../scripts/environment/spore_repulsion.gd) is an opt-in environmental consumer for actual living **AshEnemy BOX** actors. It composes the existing [spore field](SPORE_FIELD.md), [measured retreat route](REPULSION_ROUTE.md) and [installed-engine body sweep](BODY_SWEEP.md). Existing arena actors remain unchanged until bound; their unbound `enemy-snapshot-1` envelope keeps its old keys.

This is shared fixture implementation, not an Act 1 level handoff. Selected mushroom art, authored swarm pacing, ordinary-primary/no-pickup completion, portrait cue readability and whole encounter performance still require actual level validation. The confirmed source rule is repulsion without damage, in [ACT1_CONCEPT.md](../ACT1_CONCEPT.md); the detailed recoil/turn/lifetime values remain tuning proposals.

## Binding and reaction

Configure the coordinator before insertion, then bind ready actual fields and grounded actors in the same authored world:

```gdscript
var repel := CinderSporeRepulsion.new()
repel.configure("l3-spores", [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK])
level.add_child(repel)
repel.bind_environment({
    "world_root": level,
    "floors": {"main": {"collision": floor_collision, "safe_rect": Rect2(-10, -10, 20, 20)}},
    "fields": {"mushroom-a": mushroom_a, "mushroom-b": mushroom_b},
    "sources": {"grunt-01": actual_grunt, "guard-01": actual_armored_enemy},
})
# A rejected placement cannot be accepted as a functioning spore encounter.
assert(repel.placement_accepted())
```

One to 32 finite normalized authored X/Z directions are required. No hidden fallback direction counts as proof. Defaults are recoil **0.12s**, turn **0.10s**, regroup **0.35s**, retreat **4m/s**, maximum retreat **8m**, and **0.08m** extra exit clearance. Configuration permits bounded alternatives; source stats, equipment, attacks and HP are not retuned here.

The immutable bind preflight stages all field/source maps locally. A rejected field or later source cannot bind earlier actors or leave stale IDs in a subsequent valid retry. Supported sources are actual AshEnemy instances/derivatives with the shared `ash-spore-adapter-1` behavior and their real BOX body; arbitrary CharacterBody method stubs are rejected. The underlying route separately supports native capsules, without claiming this actor consumer implements a capsule enemy adapter.

Before cancelling an attack, the consumer proves one straight measured route over actual collision and authored floor. The native AshEnemy collider remains **0.75 × 1.45 × 0.65m**, centred at Y **0.725m**. A floor proof uses its enclosing X/Z disc plus the route's 0.01m skin. Collision shortening must still reach a landing outside every registered field circle, expanded by that measured footprint and the extra clearance. A wall contact inside the field rejects placement rather than manufacturing an outside endpoint.

Full field circles require an expanded circular domain contained in one supported floor rectangle, with no scenery wall intersecting its measured-height cylinder. Wall-separated or clipped propagation is not implemented. This conservatively rejects tight mushroom/wall layouts. The field's additive pure `binding_error()->String` guards actual ready cluster, boundary and release-square bindings, including inside normal activation callbacks. Boundary parent/position/basis/mesh vertices and square parent/XZ/basis/mesh size are fixed; animated Y and fade remain allowed. Broken bindings pause that invalid field's refresh/clock without spending supplies; restoring the original binding resumes its normal tick and actual phase event. Consumer preflight and live route guards use this diagnostic plus fixed world/body/floor signatures.

After proof, the actor cancels actual warning/active/recovery state, then the measured route acquires and stops its approach velocity. Recoil and turn change the sprite/facing only; body rotation, HP, stagger, hop, bleed, damage, death, drops and procs are not spore effects. Existing attack cooldowns continue once per simulation tick. `configure` cannot refill a bound actor; retry uses its paired snapshot.

An episode latches connected active field generations using measured-body-expanded circles. A newly overlapping generation joins without another recoil, cancellation or route reset. Expired circles cannot bridge a new episode. A genuinely later separate activation can trigger a new reaction. Registered **inactive** circles constrain the fixed landing only; they do not react, extend lifetime or grant immunity. This conservative fixed endpoint policy prevents a later overlapping field from engulfing the landing and requiring a second retreat.

At the real outside endpoint the source stops and avoids active-field reentry. It waits until its latched component expires, then completes an explicit regroup before returning to the ordinary controller. An old cancelled strike never resumes; a new attack pays the normal complete tell. Prefix coverage of the straight source route rejects leaving and then entering a separate active union component.

## Actual damage interruption

Actual player damage remains authoritative. It applies its existing HP loss, impulse, hurt, gravity and bleed; the consumer releases the old motion lease without overwriting that velocity. The original episode stays latched and suppresses a new spore recoil or ordinary attack. Only after real hurt ends and the source is grounded and stationary can a pure continuation proof run.

A continuation targets the **original fixed outside endpoint**. It explicitly increments `route_revision`, retains total episode age, and records the new route start age, remaining distance and elapsed time. It does not silently restart the original timer. If already outside all registered footprints, the source may hold there. A blocked original endpoint produces a visible `RETREAT BLOCKED` marker, `placement_rejected` signal and failed acceptance, preserving actual damage. Unsupported source/controller changes also fail closed. Missing coordinator cleanup preserves actual interrupted hurt motion instead of stopping its impulse.

## Public interfaces

Coordinator methods:

```gdscript
configure(instance_id: String, directions: Array, parameters: Dictionary = {}) -> bool
bind_environment(bindings: Dictionary) -> bool
consumer_id() -> String
placement_accepted() -> bool
source_state(source_id: String) -> Dictionary
step_source(source: CharacterBody3D, delta: float) -> bool
allows_source_step(source: CharacterBody3D, start: Vector3, motion: Vector3) -> bool
source_interrupted(source: CharacterBody3D, reason: String) -> void
source_binding_matches(source: Node, source_id: String) -> bool
snapshot_boundary_available() -> bool
snapshot_state(context: Dictionary) -> Dictionary
snapshot_error(snapshot: Dictionary, context: Dictionary) -> String
restore_state(snapshot: Dictionary, context: Dictionary) -> bool
```

Signals are `reaction_started(source_id: String, episode_id: String)` and `placement_rejected(source_id: String, reason: String)`. Errors set `last_error`. Returned episode records are defensive copies; they expose native route diagnostics, not campaign saves. The actor calls `step_source` before the old controller and applies its cooldown/background timers exactly once. Derivative controllers must preserve this adapter contract.

AshEnemy adds:

```gdscript
bind_spore_repulsion(consumer: Node, source_id: String) -> bool
get_spore_response_state() -> Dictionary
cancel_attack_for_spores(consumer: Node, episode_id: String, direction: Vector3) -> bool
present_spore_phase(consumer: Node, episode_id: String, phase: String, progress: float) -> bool
resume_spore_retreat(consumer: Node, episode_id: String, direction: Vector3) -> bool
finish_spore_episode(consumer: Node, episode_id: String) -> bool
spore_snapshot_error(snapshot: Dictionary) -> String
static spore_record_error(snapshot: Dictionary, consumer_id: String, source_id: String) -> String
```

The read-only response exposes actual pose/velocity, grounded and hurt state, cooldown, measured BOX dimensions/support radius, stable binding/episode IDs, phase/direction/progress and transaction availability. The consumer does not inspect private actor timers.

## Paired paused snapshots

At one paused deferred boundary, the level captures and validates its actual external field and actor units. Pass their defensive JSON envelopes as:

```gdscript
var context := {
    "fields": {"mushroom-a": field_a_snapshot, "mushroom-b": field_b_snapshot},
    "sources": {"grunt-01": enemy_snapshot},
}
var local_repulsion := repel.snapshot_state(context)
# Fresh candidate: stage every external envelope and all local level units
# before committing anything. This validates saved positions, not live poses.
var error := candidate_repel.snapshot_error(local_repulsion, context)
# After whole-level validation succeeds, commit external fields, then actors,
# then candidate_repel.restore_state(local_repulsion, context), while paused.
```

The version-1 consumer envelope contains immutable definition and field geometry, measured source/world/floor fingerprints, exact field generation/clock/activation/deadline reference stamps, episode serials, connected members, phase/episode clocks, feedback progress, explicit route revision/start age, original endpoint, exact measured route snapshots and visible failure records. The field's clusters/spent resources and actor's HP/cooldowns/hurt remain in their authoritative external units. The consumer references them; it does not create equivalent resource copies.

Validation checks full external actor and field schemas, IDs, phase/pose agreement, connected generation membership, exact route progression and geometry against the actual static world, using the staged saved actor pose/velocity without mutation. A changed collider, floor, field, direction, progress, deadline or mismatched actor unit rejects before commit. Capture/restore reject actor/controller callbacks and running simulation. These fixtures use the existing `JSON.stringify(value, "", true, true)` transport. Root is separately validating an exact-number disk codec because decimal parsing can alter some clocks by one bit; this native consumer schema and the tested fixture transport remain unchanged pending that publication. The present fixture result does not certify arbitrary clock values through decimal JSON or campaign disk saves.

The actual external field and actor units must equal the staged units before coordinator commit. New local route instances undergo full validation before replacing existing records. Restore never calls field activation, attack cancellation, damage, reaction events, route `plan` or `acquire`, and never zeroes a restored velocity. Paused clocks remain paused.

Actual lethal damage releases the route and leaves defeat/death/drop ownership with the actor and level. Before Godot removes the node, capture its actual defeat envelope; after removal, the level retains that same full envelope as its stable-ID tombstone. `spore_record_error` validates it without creating an actor. Missing live sources require a ready external replacement and fail closed; missing defeated sources require their actual valid defeat tombstone. A fresh retry that has a ready actor commits its saved defeat normally before the coordinator. No defeated actor is regenerated by this consumer.

## Validation and limits

The focused [spore_repulsion_smoke.gd](../../tests/spore_repulsion_smoke.gd) uses separate actual World3D fixtures, natural grounded AshEnemy physics and native capsule route snapshots. Final focused queue results are **87 checks, 0 failures, exit 0** (`.cinder/spore-repulsion-accepted-final.log`); field diagnostic/required-binding tests **78/0** (`.cinder/spore-field-binding-accepted.log`); directly affected existing route **95/0** (`.cinder/repulsion-route-body-sweep.log`); existing enemy snapshot **81/0** (`.cinder/enemy-snapshot-spore-adapter.log`). No script/runtime errors were reported. It covers actual attack cancellation/cooldown countdown, connected generation joining and later fresh reaction, retained collider/HP, outside-union endpoint and hold/fresh tell, pause, paired mid-retreat and airborne damage JSON retry with identical continuation, exact phase-clock forgery rejection, floor holes/walls, blocked damage continuation, source death/removal/tombstones, unsupported source binding and atomic author bind retry.

The full-circle cylinder, enclosing BOX disc, finite authored directions, first safe union gap and independent floor rectangles can reject physically possible layouts. Other enemy/body shapes, moving platforms, arbitrary impulses during lease, rotating bodies, moving scenery, collision exceptions, generated scenery collision, unsupported floor shapes and PhysicsServer-only scenery are not accepted. The route allows bounded installed-engine floor-only settling; it does not slide or teleport. Numerical tolerances and the installed Godot **4.7.2 ed1daf0bf** wrapper are documented in [BODY_SWEEP.md](BODY_SWEEP.md).

Per-source static-world scanning and repeated physical queries have not been profiled for an authored eight-enemy swarm. The blocked-retreat label is prototype required feedback; its actual portrait readability and act-specific artwork remain untested. These headless shared fixtures do not prove a spore-enabled level, baseline completion after all clusters are spent, combined-threat fairness, human playability or mobile performance.
