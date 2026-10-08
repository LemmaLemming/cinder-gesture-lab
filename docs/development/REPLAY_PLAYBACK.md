# Replay playback API

`scripts/combat/replay_playback.gd` provides `CinderReplayPlayback` (`replay-playback-1`), a physical consumer of one confirmed captured-action exchange. It is a nonblocking `Node3D`; its stationary source owns the scheduler lease and its render child follows the unchanged absolute recorded route. There is no dash collider or dash damage. The shared Act 3 traveller renderer supplies cosmetic headwear, carried static gear and action poses without creating a player/controller/equipment instance.

The frozen [sequence](REPLAY_SEQUENCE.md) and [cursor](REPLAY_CURSOR.md) remain separate. The scheduler admits one exclusive whole-sequence witness, then proves it again at the actual lock with the full locked lead. Playback neither proves nor requests attacks. It consumes that real scheduler's clock, exact lease and proved actual player. Required cones remain conservative geometric previews; live scenery LOS is checked for damage. Preview meshes are not clipped polygons, a visibility certificate or an ordinary proxy threat.

## Public methods

```gdscript
configure(playback_id: String, sequence_snapshot: Dictionary,
    source_epoch: String, generation: int,
    presentation_id: String = "act3_traveller") -> bool
bind(scheduler: Node3D, reservation_id: String, heroes: Dictionary) -> bool
advance() -> Dictionary
cancel(reason: String = "owner_cancelled") -> bool
state() -> Dictionary
preview_state() -> Dictionary
get_apparition() -> LabSprite
get_apparition_root() -> Node3D
get_cues() -> Array[Node3D]
snapshot_state(scheduler_snapshot: Dictionary, bindings: Dictionary) -> Dictionary
snapshot_error(snapshot: Dictionary, scheduler: Node3D,
    scheduler_snapshot: Dictionary, bindings: Dictionary,
    heroes: Dictionary) -> String
restore_state(snapshot: Dictionary, scheduler: Node3D,
    scheduler_snapshot: Dictionary, bindings: Dictionary,
    heroes: Dictionary) -> bool
```

`heroes` contains exactly one stable ID mapped to a live `CinderPlayer`; aliases and multiplayer bindings reject. It must be the scheduler's admitted proof actor. The playback node itself must be the admitted stationary owner, normally at the authored tether. Scheduler and hero physics run before playback priority 110. Normal physics calls `advance()` automatically; a controlled integration caller can disable that processing and call it after scheduler/actor ticks.

`advance()` takes no caller clock. It reads the actual scheduler clock, stages a defensive cursor copy, and checks **every** due event against `0.05` seconds plus the canonical `1e-9` transport epsilon before committing any prefix. One overdue event cancels the entire due batch visibly with no new event prefix or damage, retaining the source cooldown. A canceled/changed lease likewise rejects. Actual committed lock deadlines arm the cursor once; playback never extends lead, regrants a reservation or rewrites routes.

Before any cue, damage or event callback, the entire due cursor prefix and all target opportunities are spent. Every event records `event_id`, `hero_id`, exact scheduled/dispatch clocks, `contact` and `damage_attempted`. The latter is a **latched attempt**, not accepted HP damage: scenery misses, dead targets and invulnerability are never retried. A callback that cancels/removes a lease stops subsequent damage; already latched opportunities remain consumed. Recursive advance inside callbacks rejects; equal-clock advance after delivery has no due events.

Live contact duplicates the canonical player's radial range, cone/origin disk, maximum vertical difference and scenery ray at its recorded height/mask. A contacted living target receives `take_damage(record.damage, Vector3.ZERO)` once; the actual target's armour/invulnerability/death implementation decides HP loss. The original validated static damage is not amplified. Playback never calls player attacks, equip, perk/proc, capture, reload or collection APIs and never consumes ammo. Historical `player_direct` records are retained as provenance data, not republished as player actions.

`preview_state()` defensively exposes all ordered absolute route samples and canonical instant events, per-action loadouts, explicit recognition/warning/lead/gap/recovery/tether timing and unchanged source epoch/generation. Travel has no damage; inter-echo gaps have no ghost and no interpolated connecting route. The render root follows exact route/action origins; its sprite child retains the shared cosmetic feet offset. Each recorded attack has its own required source/footprint cue and instantaneous active transition, then spent recovery marker. Renderer hooks may attach act-owned cosmetics to these public nodes/signals without changing mechanics. `state_changed`, `event_dispatched` and `playback_failed` publish defensive copies/results outside quiet restore.

`state().visual_pose` derives cosmetic progress from the frozen record and cursor clock separately from logical commitment. It uses the existing player slash duration `cooldown * 0.28/0.30` and blast duration `cooldown * 0.24/0.45`, so a slower slash is not compressed into the shorter logical commitment. The original last executed attack origin/gear is held during that slot's settling; no damage interval is extended. Idle breathing, plume and particle cosmetics may be added through renderer hooks; this leaf has no independent cosmetic clock to restore.

## Custody and paired save/restore

The **parent** must transfer sealed capture slots exactly once before exposing a bound playback, atomically saving capture retirement with the scheduler/playback aggregate. Playback has no capture reference and cannot authenticate retirement or prevent a parent constructing a second owner from historical transport. The focused fixture performs and checks `take_next()` retirement before bind; this is a custody demonstration, not an implemented campaign aggregate gate.

All snapshot operations require a paused ready scene and deferred barrier outside playback/cue/damage callbacks. Scheduler `bindings` supply `world_root`, stable `owners` (the source), `floors`, and `actors` (the independently bound actual hero); staged owner positions may be supplied to scheduler prevalidation. Parent validates the saved player and aggregate, commits actual actor/source, then scheduler, then playback. Playback commit compares the actual current scheduler envelope/lease/player with the validated saved pair. It does not restore HP/resources, request/reprove, advance, damage, emit events or retime. Cue signals are blocked during visual reconstruction.

The strict finite JSON envelope retains immutable configuration/sequence/epoch/generation, stable source/hero/reservation identities, exact historical exchange, aggregate clock, cursor and consumed opportunity prefix. Use the shared `CinderExactJson.stringify/parse` transport to preserve every finite scalar bit and native type; transport identity has no generic numeric tolerance. The explicit cursor timing epsilon remains for due/derived lock arithmetic only. Running snapshots require current cursor clock equal scheduler clock and exact lock/origin/deadlines. Existing owners cannot rewind, rebind, revive or rewrite a consumed opportunity. Terminal completion requires the entire event prefix and complete final recovery; a retained completed owner continues sharing later scheduler clocks harmlessly without callbacks/redelivery. Dispose that owner before starting a different encounter/epoch.

Canceled snapshots require the exact replay-only scheduler cancellation tombstone (exchange/actor/sequence/epoch/generation/reason/cancel clock/retained cooldown), not just a source `ready_s`. The cursor freezes without fabricated late events. This bounded API captures cancellation only at its **exact cancellation aggregate clock**; pause the aggregate immediately to save that checkpoint. Missing/expired provenance or a later aggregate clock rejects fresh canceled restore. The parent must then rebuild an explicitly safe capture boundary. Historical collision fingerprints may differ after a genuine canceled world change; no future action is licensed by that history.

## Validation and remaining work

The focused queued suite uses real actor captures and exclusive scheduler leases, live physics LOS/contact, JSON continuation and labelled controlled-clock grace edges. Target bodies are held stationary after real capture to isolate replay delivery from passive reload/hurt clocks. It tests one/two combinations, separate blast aim, actual wall-shortened original Y, empty-ammo primary, no dash damage/capture recursion, missed/invulnerable opportunity consumption, whole-batch late rejection, nested callbacks, pause and quiet restore. Run through the shared queue:

```sh
python3 scripts/dev/dev.py engine --headless --path . --script tests/replay_playback_smoke.gd
```

Verified on Godot **4.7.2**, queued headless target: **168 checks, 0 failures**, exit 0 (`.cinder/replay-playback-final.log`). No script/runtime errors. The host separately reported its existing `user://` log-write and macOS certificate diagnostics. No broad suite, graphical portrait/native input session or human playtest was run for this leaf.

Campaign capture retirement/level aggregate custody, Crystalman/Echo owner wiring, tether weak-point damage/completion, camera/occlusion/portrait readability and act-specific presentation review remain integration work. This physical leaf is not encounter acceptance, native input/human playtesting or a claim of arbitrary dynamic-world fairness. Scheduler/witness static floor/coordinate/collision limits still apply.
