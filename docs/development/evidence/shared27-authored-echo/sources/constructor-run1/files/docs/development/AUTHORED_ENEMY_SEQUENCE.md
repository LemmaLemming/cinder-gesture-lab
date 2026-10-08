# Authored enemy replay data

`CinderAuthoredEnemySequence` describes the confirmed C52 Mirror Echo's **own** finite dash/slash cycle. It is separate from Crystalman's captured Player actions. `CinderReplayProgram` reads either this typed transport or the existing captured `CinderReplaySequence`; it does not broaden Player records, ActionCapture or CaptureGate.

This leaf supplies immutable data and codecs. It does not move an actor, render a source, apply damage, reserve a Scheduler exchange, authenticate a native owner, retire a cycle or prove an escape. The native constructor fixture is authored but has not yet been imported or executed; integration owns queued engine validation and the physical consumer.

## Public API

`scripts/combat/authored_enemy_sequence.gd` defines `CinderAuthoredEnemySequence`:

```gdscript
configure(sequence_id: String, native_definition: Dictionary,
    source_id: String, source_epoch: String, generation: int,
    profile_id: String, prepared_world: Dictionary) -> bool
snapshot_error(snapshot: Dictionary, source_epoch: String,
    generation: int) -> String
binding_error(snapshot: Dictionary, expected_source_id: String,
    source_epoch: String, generation: int, profile_id: String,
    expected_native_definition: Dictionary, actual_world: Dictionary) -> String
restore_state(snapshot: Dictionary, source_epoch: String,
    generation: int) -> bool
state() -> Dictionary
snapshot_state() -> Dictionary
static action_record_error(record: Dictionary) -> String
static decode_action_record(record: Dictionary) -> Dictionary
static exact_equal(left: Variant, right: Variant) -> bool
```

`configure` and `restore_state` commit only after complete validation. A configured plan cannot be replaced, including by a separately valid alternate definition or profile. `state` returns defensive native vectors; `snapshot_state` returns defensive finite JSON values. Errors are reported through `last_error` and `last_snapshot_error`. Restoration is quiet and has no clock, scene or actor side effects.

`scripts/combat/replay_program.gd` defines `CinderReplayProgram` with `snapshot_error`, `restore_state`, `state`, `snapshot_state` and `is_authored_enemy() -> bool`. Its `TIME_EPSILON_S` equals the captured reader's existing derived-boundary epsilon. The reader selects a registered API, validates through that reader, and commits atomically. It cannot switch provenance after configuration. Captured transport and its validator remain unchanged.

## Closed definition and timetable

The new transport is `api_revision = authored-enemy-sequence-1`, integer `schema_version = 1`, and `provenance = enemy_authored`. Its exact header fields are:

```text
api_revision, schema_version, provenance, sequence_id, source_id,
source_epoch, generation, profile_id, definition, resolved_role,
world, authored, timeline
```

The constructor's exact native definition is:

```text
definition_id, definition_revision, role_id, raw_role, timing_floors,
recognition_s, route, travel_clearance, slash, presentation
```

- `role_id` is `C52`. `raw_role` contains exactly `raw_damage`, `windup_s`, `lock_s`, `active_s`, `recovery_s`, `attack_interval_s`, `max_hp`, `move_speed`. Physical `move_speed` must be zero. `timing_floors` contains exactly `windup_s`, `lock_s`, `recovery_s`. Difficulty resolves fresh from this raw definition and the named profile; input cannot contain already resolved fields.
- `route` contains exactly two `{position: Vector3, at_s: number}` endpoints. It starts at local time zero, has positive duration and travel, and retains the same Y. These are absolute positions. `travel_clearance` contains `radius_m` and `height_m` for later scenery proof of the harmless rendered route; this is not permission to move a physical body.
- `slash` contains exactly `world_origin: Vector3`, `direction: Vector3`, `reach`, `cone_min_dot`, `origin_disk_radius`, `max_vertical_distance`, `los_height`, `commitment_duration_s`, `visual_duration_s`. Origin must equal the route endpoint exactly. There is no snapping, translation, retargeting or arbitrary idle padding. Geometry uses the existing ground radial cone and scenery ray policy, mask 1.
- `presentation` contains only `presentation_id` and integer `presentation_revision`. It identifies source-owned art. There is no Player sprite, helmet assumption, loadout, equipment, proc or capture record in this branch.

The normalized timetable has one slot, one `enemy_slash` event and no travel damage. The event has `event_ordinal = 1`, an exact cycle-derived `event_id`, instant damage timing, an original action record, and retained commitment/ready endpoints. The slot retains absolute route samples, `from_s`, `dash_until_s`, `end_s`, and `omitted_idle_s = 0.0`. Its active budget must equal route duration plus slash commitment exactly. Recognition and the complete warning/locked lead precede it. Recovery is at the original endpoint knot. `source_ready_s` is `max(tether_until_s, playback_from_s + resolved.attack_interval_s)`, preserving the ordinary active-origin source cooldown policy. The same computed scalar is used for the slash commitment end and slot end.

The action transport is `authored-enemy-action-1`, integer schema 1, `enemy_authored`, `kind = enemy_slash`. It includes exact sequence/source/epoch/generation/role/profile identity, geometry, resolved damage, source interval and source visual duration. It has no `record_sequence`, captured publication timestamps, ammo, equipment IDs or Player cooldown. The standalone action decoder checks finite shape syntax; full sequence derivation authenticates the resolved record against its raw role. It cannot establish native ownership by itself.

## Bounds and hostile input

Native vectors are accepted only at the two route positions and slash origin/direction. Every other definition branch is closed primitive data and is checked **before any deep copy**. Cyclic numeric/presentation leaves, foreign live or freed objects, wrong native types and oversized branches reject without copying them.

Encoded inputs have global depth 32, 65,536 visited nodes, 16,384 entries per container and a 1 MiB traversal byte budget. The global budget also bounds aliased expanding trees. Scalars must be finite; integer identities retain native integer type and the exact JSON safe range. IDs use bounded ASCII path-like strings. Coordinates are at most 512 m in absolute component value; timing components at most 3,600 s; raw/resolved role values at most 1,000,000. Slash reach is 0.001–32 m, LOS/vertical budgets 0.001–4 m, travel radius 0.001–4 m and height 0.001–8 m with height at least its diameter. Direction/cone policy uses existing Geometry validation and tolerance, without an added contact epsilon.

Use `CinderExactJson.stringify/parse` for durable transport. Exact comparison retains float bits and native numeric types; one-bit differences are not normalized or accepted as immutable identity.

## Native custody and restore boundary

`prepared_world` contains exactly integer `world_revision`, native Scheduler `collision_fingerprint` and native projected Footprint `floor_signature`. The fingerprint envelope is checked and bounded; nested collider descriptors retain the existing Scheduler schema as opaque finite data. Floor signature entries retain actual body/shape paths, bounded safe rectangle and top Y. The pure codec cannot measure the scene. **A syntactically valid world descriptor or copied source ID is not native authority.**

Before admission, dispatch or aggregate restoration, integration must pair `binding_error` with the actual retained owner/script, current alive lifecycle, stable source ID/epoch/current cycle, freshly selected Scheduler profile, actual immutable native definition, measured collision fingerprint and authored floor domain. A changed world/cycle/profile/definition fails that exact pairing. Parent restore order is actor resources and source lifecycle, Scheduler, then Playback; it must stay paused and quiet and retain deadlines, original contact receipts, event prefix and cancellation tombstones. The plan alone does not authenticate a retired cycle or grant a fresh exchange.

This new API needs no migration of captured schema 1, Player snapshots or existing captured custody. Consumers opt into a separate authored branch and must preserve its source/cycle/profile identity. Physical stationary ownership, genuine HP/recovery knot, renderer policy, whole-sequence escape/LOS/world proof, once-only dispatch and parent custody are separate integration work. Moving source bodies, concurrent mixed exchanges, sustained slash damage and multi-slot authored programs are unsupported in this bounded first branch.

## Targeted fixture and evidence scope

`tests/authored_enemy_sequence_smoke.gd` builds real native floor and shore-stone bodies, obtains actual Scheduler/Footprint descriptors, and exercises fresh profiles, compact geometry/timing, exact tagged restore, defensive data, native collider/domain changes, one-bit and provenance negatives, safe maximum integer identity, cyclic/object/overbudget inputs, pause purity and reader immutability. The captured-reader compatibility case obtains real completed Player dash/primary records through public controls. Its simple stationary Node3D is a data fixture, not a C52 enemy, HP endpoint or source renderer.

No engine result, native portrait, authored encounter acceptance or human playtest is claimed by this unexecuted leaf. Integration will run the focused target through `python3 scripts/dev/dev.py` after all dependencies are frozen. This does not add a level-author acceptance gate or change the confirmed A3 playstyle.

Sources: [Act 3 concept](../ACT3_CONCEPT.md), [Act 3 canonical level research](../reference-library/act3/research/levels.json), [Act 3 adaptation notes](../concept-art/act3/ADAPTATION_NOTES.md). Canonical dependency: `8b06b4ea-d6f6-41f3-8931-79e6b41ec704`, integration acknowledgement `261e15a5-435d-4663-9c94-62c24c2395dc`. No external footage or engine documentation claim is made here.
