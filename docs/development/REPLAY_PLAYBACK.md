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

`advance()` takes no caller clock. It reads the actual scheduler clock, stages a defensive cursor copy, and checks **every** due event against `0.05` seconds plus the canonical `1e-9` derived-time epsilon before committing any prefix. One overdue event cancels the entire due batch visibly with no new event prefix or damage, retaining the source cooldown. A canceled/changed lease likewise rejects. Actual committed lock deadlines arm the cursor once; playback never extends lead, regrants a reservation or rewrites routes.

Before any cue, damage or event callback, the entire due cursor prefix and original target contact receipts are committed. Every opportunity records `event_id`, `hero_id`, exact scheduled/dispatch clocks, `contact` and `damage_attempted`. Contact is an instantaneous original dispatch sample using the actual current player and scenery. It remains immutable through a held synchronous pause; resuming a real player dash does not resample that historical contact at the new position. `damage_attempted` becomes true immediately before the one actual `take_damage` call. It means an attempt, rather than accepted HP damage; armour and invulnerability still decide HP loss. An uncontacted opportunity remains false/false and is never retried.

A cue/hurt/event observer may hold the whole tree paused. Playback stops immediately and retains a contiguous delivery suffix, advancing each stage before its callback. Equal-clock or nested calls cannot repeat presentation, damage or event notification. Genuine paused time advances no clock. Once simulation resumes, a retained event suffix must drain within **0.05 seconds plus the canonical derived-time epsilon from its original dispatch clock**. This is a separate bounded callback latency, not a new attack admission window: original scheduled-time admission is unchanged and neither clock nor contact is rewritten. A valid contact admitted near the original grace endpoint survives one normal resumed physics tick. A controlled caller that advances the scheduler for many unpaused ticks without playback loses the retained opportunity through visible cancellation, rather than delivering stale damage or declaring it complete. A notification-only suffix uses the same conservative bound.

Before presentation, after each observer and immediately before damage, playback checks the actual proved player/source/lease and required cue nodes. A dead, removed or replaced player terminates remaining damage. Required source markers, outlines and active fills cannot be hidden/cleared and silently reconstructed to regain damage authority. Cue loss cancels the existing lease and retains its source cooldown. Running snapshot writers and existing running readers also reject actual cleared, hidden or removed required nodes purely, without callbacks or mutation; saved phase data cannot heal live damage authority. Terminal cleanup hides containers with broken renderer children without dereferencing them. Canceled historical receipts may still be captured and quietly restored to intact fresh nodes because they license no future attack. Harmless route ornament and the pose-empty warning apparition are optional; active fill is required only during active. Public recursive `cancel()` remains rejected; terminal observer losses use the internal fail-closed path.

Live contact duplicates the canonical player's radial range, cone/origin disk, maximum vertical difference and scenery ray at its recorded height/mask. A contacted living target receives `take_damage(record.damage, Vector3.ZERO)` once; the actual target's armour/invulnerability/death implementation decides HP loss. The original validated static damage is not amplified. Playback never calls player attacks, equip, perk/proc, capture, reload or collection APIs and never consumes ammo. Historical `player_direct` records are retained as provenance data, not republished as player actions.

`preview_state()` defensively exposes all ordered absolute route samples and canonical instant events, per-action loadouts, explicit recognition/warning/lead/gap/recovery/tether timing and unchanged source epoch/generation. Travel has no damage; inter-echo gaps have no ghost and no interpolated connecting route. The render root follows exact route/action origins; its sprite child retains the shared cosmetic feet offset. Each recorded attack has its own required source/footprint cue and instantaneous active transition, then spent recovery marker. Renderer hooks may attach act-owned cosmetics to these public nodes/signals without changing mechanics. `state_changed`, `event_dispatched` and `playback_failed` publish defensive copies/results outside quiet restore.

`state().visual_pose` normally derives cosmetic progress from the frozen record and cursor clock separately from logical commitment. During a held delivery remainder, it reports the last attack actually presented, even when the cursor already consumed a later equal-time blast. Quiet restore reproduces that original action/frame/facing/static gear and native root pose; it does not show the unpresented next attack. It uses the existing player slash duration `cooldown * 0.28/0.30` and blast duration `cooldown * 0.24/0.45`, so a slower slash is not compressed into the shorter logical commitment. The original last executed attack origin/gear is held during that slot's settling; no damage interval is extended. Idle breathing, plume and particle cosmetics may be added through renderer hooks; this leaf has no independent cosmetic clock to restore.

## Custody and paired save/restore

The **parent** must transfer sealed capture slots exactly once before exposing a bound playback, atomically saving capture retirement with the scheduler/playback aggregate. Playback has no capture reference and cannot authenticate retirement or prevent a parent constructing a second owner from historical transport. The focused fixture performs and checks `take_next()` retirement before bind; this is a custody demonstration, not an implemented campaign aggregate gate.

All snapshot operations require a paused ready scene and deferred barrier outside playback/cue/damage callbacks. Scheduler `bindings` supply `world_root`, stable `owners` (the source), `floors`, and `actors` (the independently bound actual hero); staged owner positions may be supplied to scheduler prevalidation. Parent validates the saved player and aggregate, commits actual actor/source, then scheduler, then playback. Playback commit compares the actual current scheduler envelope/lease/player with the validated saved pair. It does not restore HP/resources, request/reprove, advance, damage, emit events or retime. Cue signals are blocked during visual reconstruction.

The strict finite JSON envelope retains immutable configuration/sequence/epoch/generation, stable source/hero/reservation identities, exact historical exchange, aggregate clock, cursor and consumed opportunity prefix. Use the shared `CinderExactJson.stringify/parse` transport to preserve every finite scalar bit and native type; transport identity has no generic numeric tolerance. The explicit cursor timing epsilon remains for due/derived lock arithmetic only. Running snapshots require current cursor clock equal scheduler clock and exact lock/origin/deadlines. Existing owners cannot rewind, rebind, revive or rewrite a consumed opportunity. Terminal completion requires the entire event prefix and complete final recovery; a retained completed owner continues sharing later scheduler clocks harmlessly without callbacks/redelivery. Dispose that owner before starting a different encounter/epoch.

Canceled snapshots require the exact replay-only scheduler cancellation tombstone (exchange/actor/sequence/epoch/generation/reason/cancel clock/retained cooldown), not just a source `ready_s`. The cursor freezes without fabricated late events. This bounded API captures cancellation only at its **exact cancellation aggregate clock**; pause the aggregate immediately to save that checkpoint. Missing/expired provenance or a later aggregate clock rejects fresh canceled restore. The parent must then rebuild an explicitly safe capture boundary. Historical collision fingerprints may differ after a genuine canceled world change; no future action is licensed by that history.

## Conditional pending transport and migration

Fully drained snapshots retain **schema 1 and its exact existing keys**. Only a genuine interrupted presentation/delivery uses schema 2, adding the single closed `pending_delivery` object:

```gdscript
{
    "events": [{"event_index": 0, "stage": "damage"}],
    "visual_next_cue": 0,
    "visuals_pending": true,
    "state_pending": true,
    "cue_phases": ["active", "lock"],
}
```

`events` is the canonical contiguous suffix of the already consumed opportunity prefix. Its first stage is `present`, `damage` or `notify`; all later entries are `present`. A stage is advanced before its corresponding presentation/damage/event observer. A held first-event notification may leave the next entry at `present`; its preceding event is still the actual rendered pose. The first-ever unpresented attack has no supported callback boundary before presentation, so a running index-zero `present` snapshot rejects instead of guessing a prior pose. An empty suffix can retain a partly finished final visual/state refresh. A final event notification held before refresh keeps the last presented frame; a refresh that has started uses the exact cursor pose.

`visual_next_cue` counts the already refreshed cue prefix. `cue_phases` preserves exact partial warning/clear, first-lock/warning and delivered active/recovery phases. Warning/lock interruption cannot invent presentation in the unvisited suffix. Quiet reconstruction blocks all cue/playback callbacks. `state_pending` spends the final state publication once; a held bind warning does not publish a duplicate state while paused. Conditional schema 2 rejects an empty remainder, extra keys, missing/unknown/gapped indices, malformed stages/phase arrays, false attempted-damage history and one-bit copied-clock mutations. Once all work drains, new captures return schema 1 without a silent rewrite of an old pending save.

The new reader accepts strict schema 1 and 2. Older schema-1-only readers cannot continue a schema 2 aggregate; adopt this reader before loading those saves or rebuild an explicitly safe parent capture boundary. Schema 2 is not a new scheduler reservation or an independently authenticated custody token. Historical contact and observer progress remain part of a **trusted coherent parent aggregate**: the parent must validate and preserve actor, scheduler, captured-slot retirement and playback together. This leaf cannot reconstruct whether an arbitrary forged historical `contact` boolean or a claimed past callback really happened.

A canceled interrupted suffix keeps its immutable receipt/stage and clears all future presentation/state delivery. Fresh restore still requires the exact retained scheduler cancellation tombstone at the cancellation clock. If a manual caller waits beyond final recovery and the scheduler has already normally pruned the lease, playback cancels locally but cannot manufacture that tombstone; fresh terminal transport rejects. Normal terminal completion requires an empty pending envelope. Missing/expired provenance remains the documented safe-boundary recovery restriction.

## Validation and remaining work

[Portable original evidence](evidence/shared22-replay-callbacks/index.json) records separate executed scopes, source hashes and preserved failure diagnostics.

The focused queued suite uses real actor captures and exclusive scheduler leases, live physics LOS/contact, exact JSON continuation and labelled controlled-clock grace edges. Ordinary delivery fixtures keep target bodies stationary after real capture to isolate passive reload/hurt clocks; the callback continuation fixture explicitly enables real restored unfinished dash physics. The pending unit is written/read through the actual isolated format-2 `CinderSaveStore`, then committed to fresh real actor → scheduler → playback. Native Sprite texture bytes, root/sprite transforms, static gear, diagnostic action/facing/progress and actual partial cue states are compared before/after quiet restore.

Tests cover one/two combinations, separate blast aim, actual wall-shortened original Y, empty-ammo primary, no dash damage/capture recursion, missed/invulnerable opportunity consumption, whole-batch late rejection, nested callbacks, held cue/hurt/event pauses, warning/lock partial refresh, repeated real resume ticks with immutable contact, quiet fatal restore, required source/outline/fill/hide/clear cancellation, atomic malformed schema2 rejection, near-admission-grace next-tick continuation, bounded missed drain and scheduler-only final expiry. Run only through the shared queue:

```sh
python3 scripts/dev/dev.py test replay_playback
```

Original published coverage remains **168 checks, 0 failures**. The original callback reproducer preserved **237 checks, 9 failures**, exit 1 at `.cinder/replay-playback-callback-first.log`; it retained the old regression passes and exposed held-pause/visibility/death failures without script/parse errors. The first repair passed **240 checks, 0 failures** at `.cinder/replay-playback-callback-second.log`. The expanded sandbox run at `.cinder/replay-playback-callback-expanded.log` exposed blocked test-save writes followed by a fixture missing-payload Script Error; it is environment/fixture diagnostics, not a passing gameplay result. After guarded isolated saves with approved filesystem access, `.cinder/replay-playback-callback-expanded-save.log` reached **395 checks, 4 failures** with no script/parse errors: deferred manual delivery had allowed headless catch-up to execute more than one actual resumed tick. The fixture now delivers from a test-only later-priority native physics node on exactly one real tick. `.cinder/replay-playback-callback-native-final.log` then passed **424 checks, 0 failures**, exit 0, including real resumed-dash, near-grace and actually freed child cases. The final direct writer-authority/canceled-transient extension passed **475 checks, 0 failures**, exit 0 at `.cinder/replay-playback-callback-authority-final.log`, with no script/parse/runtime errors or warnings. That final run directly verifies pure writer/existing-reader rejection of externally cleared, hidden and actually freed required cues while paused; it also verifies that canceled historical receipts with broken transients remain restorable without future damage authority. Godot **4.7.2** is the tested engine; existing host certificate diagnostics are separate from script/test failures. No broad suite, graphical portrait/native input session or human playtest was run for this repair.

Campaign capture retirement/level aggregate custody, Crystalman/Echo owner wiring, tether weak-point damage/completion, camera/occlusion/portrait readability and act-specific presentation review remain integration work. This shared repair introduces no authored replay placement, new player ability or current level acceptance gate. Scheduler/witness static floor/coordinate/collision limits still apply.
