# Exclusive captured-action replay scheduling

`threat-scheduler-4` adds a dedicated replay reservation to the existing [threat scheduler](../../scripts/combat/threat_scheduler.gd). It retains the ordinary snapshot envelope revision `scheduler-snapshot-1`: ordinary records keep their existing fields, while replay records and optional cancellation history use strict additional schemas. This is shared infrastructure for an authored encounter, not acceptance of the Crystalman boss or a physical replay damage implementation.

The [sequence](../../scripts/combat/replay_sequence.gd) preserves one or two sealed combinations from the [executed-action capture](../../scripts/combat/action_capture.gd). The [witness](../../scripts/combat/replay_witness.gd) checks the complete sequence against the actual player response and immutable static collision world. The scheduler allocates only after that whole proof succeeds. It never represents replay as an ordinary circle or lane, never moves the player or apparition, never consumes ammo, and never invokes damage.

## Live API and custody

```gdscript
request_replay(owner: Node3D, sequence_snapshot: Dictionary,
    response: Dictionary, context: Dictionary) -> Dictionary
commit_replay(reservation_id: String, response: Dictionary) -> Dictionary
replay_exchange_error(sequence_snapshot: Dictionary, context: Dictionary,
    reservation_id: String = "") -> String
replay_reservation_error(reservation_id: String) -> String
replay_reservation_state(reservation_id: String) -> Dictionary
replay_target(reservation_id: String) -> CinderPlayer
replay_world_root(reservation_id: String) -> Node3D
replay_cancellation_state(reservation_id: String,
    bindings: Dictionary = {}) -> Dictionary
```

The context has exactly `world_root`, `source_epoch`, `generation`, and `capture_collision_fingerprint`. `world_root` contains the scheduler, stationary source and actual shared player in the same physics world. The source must physically occupy the authored tether. A live player with collision exceptions or platform carry is unsupported. The response uses that player's public current equipment, commitment and cooldown state, with actual authored floor regions and ordinary swipe candidates. A pending weapon change cannot license a future loadout.

A successful request returns the common `accepted`, `reservation_id`, `armed`, `profile_id`, `proof`, and `reservation` fields. Preview is unarmed and exclusive from the request through final recovery. Another replay, an ordinary attack and a tracking preview all reject while it exists, including the harmless inter-echo gap and tether recovery. Failed compound preflight does not prune another reservation, emit its callbacks, or allocate a serial.

Commit accepts only the actual player admitted at preview, retained through a weak reference. It re-proves at the live lock using the stored sequence, world and capture context. Exact self-exclusion permits only the matching unarmed replay and an otherwise empty reservation table. An early commit, including an accumulated clock one bit before its warning deadline, leaves preview intact; a repeated commit leaves an armed lease intact. An invalid due lock cancels the exchange and retains its cooldown. An uncommitted preview cancels when its first nominal playback deadline arrives.

A legal delayed commit begins the **full authored locked lead at the actual commit clock**. Its timeline origin is actual lock minus authored warning; the original request clock remains `start_s`. The live record's adapter contains:

| Field | Meaning |
| --- | --- |
| `kind` | Exactly `replay` |
| `locked` | False for preview, true after successful atomic lock |
| `sequence` | Defensive canonical JSON sequence snapshot |
| `source_epoch`, `generation` | Capture identity |
| `capture_collision_fingerprint` | Exact guarded static world from capture |
| `timeline_origin_s` | Absolute origin used by the complete compact timetable |
| `max_dispatch_delay_s` | Mandatory witness bound, currently 0.05 seconds |

The record has `response_actor_instance_id`, source position, actual tether opening and ordinary deadline/encounter metadata, and deliberately has **no `geometry` field**. `active_until_s` conservatively covers nominal replay end and the latest event plus dispatch grace and timing skin. `recovery_until_s` remains the authored tether end; cooldown lasts until that same end. The aggregate public state reports warning/lock/active/recovery; slot gaps and individual cues come from the canonical sequence and cursor.

The defensive reservation/error getters do not prune, emit callbacks or advance clocks. `replay_target` and `replay_world_root` expose raw admitted custody even when a pure guard now fails; they return null once the lease is absent or the referenced node is gone. Consumers must use the guard before acting.

## Physical consumer responsibilities

Every recorded attack is dangerous throughout its nominal time through nominal time plus the fixed 0.05-second grace. This is a provisional bounded dispatch allowance, not a change to dash or weapon timing. A physical consumer must check **all due actions for lateness and current lease/world validity before any damage**, then commit the entire due cursor prefix before callbacks. An overdue historical cursor alone cannot authorize live damage. Scheduler cancellation must stop that consumer immediately. Ordinary actor movement and unchanged collision remain authoritative.

The scheduler authenticates its own reservation identity and live proof actor; it does **not** authenticate that arbitrary supplied JSON was historically produced by that player or retire captured slots globally. The encounter owner needs an atomic capture-custody and slot-retirement gate. Distinct source objects cannot rely on the scheduler alone for single use. Visual source/footprint/landing readability, apparition movement, contact damage, replay prefix consumption and boss tuning belong to the consumer and authored encounter validation.

## Paused transport

Capture, validation and restore require a paused live tree at a deferred physics/callback barrier. They remain quiet: no input, motion, resource mutation, cancellation, replay event, damage or timing restart. Use [exact tagged JSON](../../scripts/campaign/exact_json.gd) for saved numeric transport; native decoded snapshot schemas still contain only closed JSON values. Plain decimal JSON can round clock bits and is not the exact campaign save transport.

Replay snapshots add `response_actor_id` to their record. `bindings.actors` must explicitly map exactly one stable ID to the actual `CinderPlayer`; `bindings.owners`, `bindings.floors`, `world_root` and optional staged source positions/velocities retain their existing meaning. A staged replay source must be stationary at the saved tether, with matching actual world and floor geometry. The parent validates and applies the player's own paused actor snapshot before committing the scheduler and playback. Stable actor mappings are caller-owned authored identity, not duplicate HP or actor state inside the scheduler.

Restore checks the canonical sequence, exact numeric reservation identity and derived deadlines (without timing epsilon), phase/arming, current capture-world fingerprint, floor bindings, actor custody, exclusive reservation table and retained cooldown before committing anything. Unknown fields, proxy geometry, shortened dispatch grace, drifted timetable, wrong epoch/generation and incoherent deadlines reject atomically.

Cancellation commits a replay tombstone **before** `reservation_invalidated` emits. Native diagnostics contain source/player instance IDs; `replay_cancellation_state(id, bindings)` returns stable JSON while paused. A nonempty optional top-level `replay_cancellations` array stores `id`, `source_id`, `response_actor_id`, `sequence_id`, epoch/generation, canonical sequence, historical capture fingerprint, profile/world revision, original/locked/active/recovery/cooldown clocks, timeline origin, locked flag, fixed dispatch bound, `cancelled_at_s` and `reason`. Reasons are normalized to a nonempty string and bounded to 512 characters before both retention and notification.

A canceled historical capture fingerprint may differ from current scenery because a tombstone licenses no future action. Its original timeline and matching retained source cooldown still must validate. At most 32 unexpired cancellations are retained per encounter; new replay requests fail closed at that bound. Tombstones expire only on actual pausable simulation ticks after their cooldown, and clear at encounter end. Getters and snapshot reads never age them. A fresh canceled playback restore without its exact unexpired tombstone, or after its source/player has been removed from stable live bindings, is unsupported. The parent must also preserve the consumer's actual cancellation clock and frozen event prefix.

## Targeted validation

The [replay scheduler fixture](../../tests/replay_scheduler_smoke.gd) records actual public dash and primary actions from the shared player on real static floors, including one/two combinations with empty blast ammo. It checks allocation purity, exclusivity through recovery, actual delayed full-lead lock, same-player custody, quiet phase transport and atomic malformed restore, pause, callback ordering, retained cooldown, cancellation history, missed lock and changed real source/floor/world guards. It has no campaign scene acceptance or apparition damage claim.

Run through the shared queue:

```sh
python3 scripts/dev/dev.py engine --headless --path "$PWD" \
  --script tests/replay_scheduler_smoke.gd \
  --log-file "$PWD/.cinder/replay-scheduler-exact-engine.log"
python3 scripts/dev/dev.py test threat_scheduler
python3 scripts/dev/dev.py test threat_adapters
python3 scripts/dev/dev.py test threat_snapshot
```

Installed Godot 4.7.2 `ed1daf0bf` passed the final replay fixture **105 checks / 0 failures**, ordinary scheduler **69 / 0**, ordinary adapters **35 / 0**, and ordinary paused snapshots **35 / 0**, all exit 0 with no script/runtime errors. Logs are ignored local `.cinder/replay-scheduler-exact.log` and `.cinder/replay-affected-{scheduler,adapters,snapshot}.log`. The replay fixture uses exact tagged numeric transport and includes one-bit timing/identity rejection plus the real accumulated-clock lock boundary. Actual authored encounter and portrait replay playtesting remain pending.
