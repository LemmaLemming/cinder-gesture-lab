# Immutable captured replay sequence data

`replay-sequence-1` is a bounded data layer for the confirmed Crystalman capture rules in [ACT3_CONCEPT.md](../ACT3_CONCEPT.md#a3-l5-crystalman--compose-an-escape) and [canonical research](../reference-library/act3/research/levels.json). It does not change player gestures or introduce an equipment ability. Mirror Echo can later reuse sequence composition, but its own authored sequence must have separate provenance; this revision accepts direct-player Crystalman capture only.

This module neither schedules nor executes an attack. No collision, supported-floor, LOS, visibility, escape or ordinary-primary tether witness follows from successful configuration. Physical replay and encounter acceptance remain pending.

## Public API

```gdscript
func configure(sequence_id: String, capture_snapshot: Dictionary,
    authored: Dictionary, source_epoch: String, generation: int) -> bool
func state() -> Dictionary
func snapshot_state() -> Dictionary
func snapshot_error(snapshot: Dictionary, source_epoch: String,
    generation: int) -> String
func restore_state(snapshot: Dictionary, source_epoch: String,
    generation: int) -> bool
```

`configure` accepts a canonical `CinderActionCapture.snapshot_state()` JSON envelope with one or two sealed, unretired slots and no pending combo or unpaired route. One sealed slot from a two-slot capacity is permitted. It validates the caller's intended source epoch/generation, canonical records, once-only ordered slot identity, positive completed movement and sealed combo boundary through the public capture validator and player codec. It does not consume slots. A retired prefix remains in the retained envelope; retired slots cannot enter the plan.

`sequence_id` uses the same stable ASCII ID vocabulary as capture (letters, numbers, underscore, dot, slash, colon, hyphen; 1–192 characters). `authored` has exactly these fields:

| Field | Meaning |
| --- | --- |
| `recognition_s` | Explicit future response-proof budget; retained independently of visual durations. |
| `warning_s` | Time from sequence warning start to lock. |
| `locked_lead_s` | Full displayed locked lead before playback starts. |
| `inter_echo_gap_s` | Separation after the preceding combination's complete intrinsic duration. Positive for two slots; zero is permitted for one slot. |
| `final_recovery_s` | Tether exposure window after the complete finite sequence. |
| `tether_position` | Absolute native `Vector3`; JSON triple in transport. |

All times are finite and bounded to 3,600 seconds each as a transport limit, not encounter tuning. Recognition, warning, locked lead and final recovery must be positive. This module does not certify that the supplied lead, gap or recovery is sufficient.

Primary and optional blast planar origins must be within `0.00001` metres of their slot's recorded dash landing. The complete original coordinates remain unchanged, including any vertical difference. A larger discontinuity rejects explicitly; the caller must visibly reject/re-arm rather than snap an origin or invent connecting travel. Current capture can legitimately contain such data when the hero attacks during a later unfinished dash. This bounded physical-replay subset therefore cannot accept every valid capture.

A configured instance is immutable. `restore_state` permits a first validated load or an identical idempotent JSON roundtrip, and refuses replacement by a different valid plan. Rejection preserves all existing data. Getters deeply copy records, sampled paths, geometry, gear and authored values. `last_error` and `last_snapshot_error` describe rejection. Empty unconfigured state is `{}` and is not a valid saved plan.

## Native plan and JSON schema 1

The top-level keys are `api_revision`, `schema_version`, `sequence_id`, `source_epoch`, `generation`, `capture_snapshot`, `authored`, and `timeline`. `state()` decodes record vectors, tether position and route positions; it is diagnostic native data. Use `snapshot_state()` for plain finite JSON. Unknown fields, object values, nonfinite data, wrong identity, malformed canonical records and altered derived timing reject.

`timeline` contains `warning_from_s = 0`, `lock_from_s`, `playback_from_s`, ordered `slots`, `replay_until_s`, `tether_from_s`, and `tether_until_s`. These are offsets from sequence warning start. A future scheduler shifts timestamps into its clock; absolute world positions never shift.

Each timeline slot has `slot_id`, `generation`, `from_s`, `dash_until_s`, `end_s`, `omitted_idle_s`, `route`, and `events`. Route samples are `{position, at_s}` preserving every actual collision-shortened sample. Attack events have `event_id`, `kind`, `record_sequence`, `at_s`, `commitment_until_s`, `ready_s`, `damage_timing = instant_at_execution`, and `record`. The latter is the complete canonical primary/blast record, exposing its actual origin, continuous direction, cone/LOS parameters, resolved damage, gear and original source clock.

The shared capture timetable supplies intrinsic dash duration, immediate post-dash primary, actual optional blast spacing, logical commitment and normal cooldown deadlines. Arbitrary idle between completed dash and primary is omitted only from playback timing; the original records and omitted duration remain exact. Slot end covers the later normal primary/blast ready deadline. The next slot begins after that end plus the explicit inter-echo gap. Tether exposure starts after the last slot ends, and lasts `final_recovery_s`.

Travel is harmless. Attack damage remains an instantaneous event; commitment, cosmetic settling and cooldown are not sustained damage windows. Event order is primary then optional blast, including equal-time events. A transport validator regenerates the complete timetable and compares it with at most `1e-9` seconds/numeric decimal roundoff; integral identities remain exact. Original record validation uses the public canonical player codec. Structural validation cannot authenticate a forged historical stream or prove geometry against an external world.

## Remaining integration and validation

The integration owner must validate the whole sequence against actual current hero position, commitment/cooldowns, gear, static collision/floor revision, visibility and the final ordinary-primary tether approach before locking playback. Two independent single-action witnesses are insufficient. Overlapping slash/blast events require union validation; inter-echo gaps require a cooldown-aware route through both combinations. Initial player movement, unsupported floors or a changed collision world must reject/defer visibly without manufactured safety.

Only after successful atomic validation may the caller transfer the same sealed slot IDs from capture to a physical sequence owner. This module has no consumption cursor or hit history; the future scheduler/consumer and level aggregate must persist those, prevent re-execution, reject stale epochs and keep the complete snapshot unit coherent. The ghost must follow original absolute samples, remain nonblocking/non-damaging during travel, respect floor/LOS clipping at recorded attack points, avoid player action calls/perk/collection/reload procs, and cancel on invalidation. Retry clears owned captures/ghosts/footprints/transients and safely re-arms.

Targeted fixture: `tests/replay_sequence_smoke.gd`, queued through the canonical `dev.py engine` wrapper on Godot 4.7.2: **59 checks, zero failures**. Evidence is in `.cinder/replay-sequence-test.log`; import evidence is in `.cinder/replay-sequence-import.log`. It uses actual player/capture publications for shortened routes, one/two combinations, optional blast, empty ammo, static legal gear, idle omission, pause/JSON transport and moving-origin rejection. These are data tests; they do not establish physical replay, encounter fairness, portrait readability or human balance.
