# Frozen replay cursor data

`replay-cursor-1` is a clock, route-pose and once-only event-delivery foundation over [the immutable sequence](REPLAY_SEQUENCE.md). It supports the selected Crystalman capture rules without introducing player controls, equipment or an ability. It creates no Node, ghost, collision, HP change, attack callback, signal, perk/proc or scheduler reservation. Successful configuration or arming establishes no floor, LOS, visibility, escape or tether proof.

```gdscript
func configure(sequence_snapshot: Dictionary, source_epoch: String,
    generation: int, clock_s: float) -> bool
func arm(timeline_origin_s: float, clock_s: float) -> bool
func advance(clock_s: float) -> Dictionary
func state() -> Dictionary
func snapshot_state() -> Dictionary
func snapshot_error(snapshot: Dictionary, expected_sequence_snapshot: Dictionary,
    source_epoch: String, generation: int, expected_scheduler_clock_s: float) -> String
func restore_state(snapshot: Dictionary, expected_sequence_snapshot: Dictionary,
    source_epoch: String, generation: int, expected_scheduler_clock_s: float) -> bool
```

`configure` binds a single exact canonical sequence, expected epoch/generation and preview clock. It deep-copies the JSON and decoded native data. The initial phase is `warning`, with no timeline origin, ghost or delivered attacks. Calling `advance` while unarmed cannot deliver attacks even after a prospective playback time. This module has no missed-lock policy; the future scheduler must reject/cancel its own expired unarmed reservation.

`arm` is once-only. Its clock must be monotonic and exactly at or after the configured preview clock plus authored warning. Even a one-bit earlier clock rejects; the origin is never clamped to rescue an early arm. The caller supplies the exact canonical inverse `timeline_origin_s == actual_arm_clock - authored.warning_s`. Re-adding the warning can round to an adjacent float and is not the identity test. The complete authored locked lead follows the actual lock. No sequence geometry or intrinsic spacing changes. Arming is only data assignment; the caller must obtain a fresh whole witness and actual reservation before authorizing a physical consumer.

`advance` accepts a nondecreasing finite simulation clock and returns `{accepted, events, phase, poses}`. On rejection it returns `accepted = false`, `reason`, and empty `events`, preserving data. It commits the complete newly due event prefix **before returning** any copies to the caller. A nested caller advance at that clock therefore returns no duplicate. A large time jump batches every due event in exact slot/primary/blast order; this does not authorize delayed damage against a later body position. The physical consumer must define and validate actual event execution timing separately.

Each delivered event retains the original relative `at_s`, exact `event_id`, `kind`, `record_sequence`, slot ID/generation and complete native canonical `record`. Added `scheduled_at_s` and `dispatch_clock_s` separate the sequence deadline from data delivery. Event `commitment_until_s` and `ready_s` are shifted into the supplied simulation clock. Original record clocks, world origins, independently aimed directions, geometry, resolved damage and static gear remain unchanged. Historical record `origin = player_direct` identifies the recorded action; a future apparition must use its own damage-dispatch identity and never feed this historical record back into capture.

All clocks are bounded to the capture transport's `MAX_CLOCK_S`; the entire finite sequence must fit that range at configure and arm. Immutable sequence/history numbers, the saved external scheduler clock, preview/arm/origin identities and monotonic no-rewind checks use exact numerical equality without tolerance. Persist through [the shared exact JSON transport](EXACT_JSON.md), which preserves finite scalar bits and types; decimal stringify/parse can change an actual six-tick `0.09999999999999999` clock to `0.1` and is not a valid clock identity transport.

The `1e-9` second epsilon applies only to derived inclusive event deadlines and timeline phase/action boundaries, whose additions/subtractions can round. A delivered data event retains its distinct exact scheduled and dispatch clocks even at that arithmetic edge. Route sample identities and stored deadlines are exact. This epsilon cannot license early arming, alter a saved clock, rewrite a delivered prefix or rewind an owner, and establishes no physical damage permission. The physical consumer independently enforces its admitted execution window. Equal-time events retain canonical order. Input clock regressions reject; repeating a clock delivers no additional event. There is no wall timer or automatic update. The owner freezes its simulation clock during pause/backgrounding; passing an advancing clock while paused would still advance this pure data object.

Phases derive from the authoritative clock: `warning` while unarmed, `lock` before playback, `active` during a slot's intrinsic duration, `gap` between slots, `recovery` during final tether exposure, then `complete`. `active` includes harmless travel and settling, not sustained attack damage.

`poses` contains at most one ghost pose. It is empty during preview, lock, gap, final recovery and completion. A slot begins exactly at its recorded absolute route origin, interpolates only between neighboring actual physics samples, and holds its recorded landing through intrinsic settling. It never connects the end of one route to the next route's possibly unrelated origin. Each pose exposes `slot_id`, `generation`, absolute `position`, original/current recorded `direction`, `stage` (`travel` or `settling`), logical `action`/progress, corresponding static `equipment_ids`, and `movement_damage = false`. Logical action progress uses recorded commitment, not a claim that a complete cosmetic animation is restored. Attack origins, including any small vertical difference from the landing, remain separately exact in event records; the route pose does not snap to them or invent connecting travel. A physical consumer must reconcile its actual source presentation before claiming a correct replay.

Interpolation uses scalar double arithmetic before constructing the native vector, avoiding overflow from subtracting opposite finite float32 coordinates. This does not authorize an extreme or forged route: canonical transport cannot authenticate historical motion, and the independent physical witness must enforce its own world-coordinate/collision envelope.

`state` and `snapshot_state` are defensive. Native state is a summary with current poses and delivery history; JSON transport includes exactly:

```text
api_revision, schema_version, sequence, source_epoch, generation
configured_at_s, armed, armed_at_s, timeline_origin_s
last_advanced_clock_s, phase, next_event_index, executed_events
```

`executed_events` names the **delivered data prefix**, not physical damage execution. Each entry has exactly `event_id`, `scheduled_at_s`, and `dispatch_clock_s`. There is no hit history. The physical owner must store its per-event/per-live-hero damage opportunities separately and pair them with this prefix.

Snapshot validation requires the independently expected immutable sequence, epoch/generation and exactly equal external scheduler clock. It rejects unknown fields, malformed/nonfinite values, one-bit altered sequence data or stored deadlines, incorrect arming/phase/timeline, missing due events, future events, reordered identities and inconsistent dispatch clocks. Unarmed snapshots must have null arm/origin fields and zero delivered events. Armed snapshots must contain exactly the due prefix for their last advanced clock. Restore assigns quietly only after complete validation, without event delivery, signals, actions or time advancement.

The future paired validator must also compare `configured_at_s`, `armed`, `armed_at_s`, and `timeline_origin_s` with the authoritative scheduler reservation. This component checks their canonical internal relationships and external current clock, but a fresh instance cannot infer an independently saved reservation's lock identity.

An existing instance cannot rebind its exact preview/arm/origin, unarm, rewind its clock/event cursor by even one float bit or rewrite a previously delivered prefix. An identical exact roundtrip is idempotent. A fresh instance can restore a saved continuation; subsequent advances deliver only future events. Loading an earlier whole encounter should recreate the paired owner rather than rewind a still-live cursor. This module cannot prevent two independently created objects from claiming the same saved sequence; the scheduler/aggregate must enforce one lease, once-only captured-slot transfer, cancellation, stale-epoch rejection and atomic player/level/capture/consumer/scheduler restore.

Targeted fixture: `tests/replay_cursor_smoke.gd`, using actual player/capture/sequence publications for wall-shortened slash-only travel, two combinations, independently aimed blast, a superseded unpaired dash, distinct second origin and legal gear. Exact-identity additions cover one-bit sequence/history/deadline/paired-clock mutations, immutable preview/arm changes, no-rewind, inverse-origin roundoff, and actual six/thirty/thirty-one physics tick clocks. Equal-time/finite-coordinate transport and clock manipulations are labelled data fixtures, not physical replay, encounter acceptance, portrait or balance tests. Canonical queued Godot 4.7.2 run after the exact-identity update: **118 checks, zero failures**, exit 0, with no script errors or fixture runtime errors; evidence is `.cinder/replay-cursor-exact.log` and `.cinder/replay-cursor-exact-engine.log`. Startup emitted the existing macOS `get_system_ca_certificates` diagnostic (`os_macos.mm:1035`), also present in the historical cursor/scheduler/playback logs. The earlier decimal-transport fixture's 80-check result remains historical.
