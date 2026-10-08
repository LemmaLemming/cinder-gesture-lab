# Authored Echo native playback fixture

This is a bounded **TEST ONLY** C52 prototype, separate from captured Player replay. The actual HP owner subclasses the shared `CinderReplayPlayback` and stays at its finite authored route endpoint. Its own visible native mesh travels and presents its own slash. It never equips, captures or renders Player gear, moves a physical enemy body, damages during travel or introduces a Player ability.

The new fixture is authored and statically reviewed; no engine import, parse, queued suite, portrait or human test result is claimed yet. Integration owns core changes and the native queue. This document records the fixture contract and intended checks, rather than acceptance of an authored level.

## Owned files

- `tests/fixtures/authored_echo_actor.gd` and UID: actual stationary owner, source-owned renderer, ordinary-primary HP endpoint.
- `tests/fixtures/authored_echo_native_codec.gd` and UID: closed source resource/lifecycle codec paired with separate Player, Scheduler and Playback envelopes.
- `tests/authored_echo_playback_smoke.gd` and UID: targeted native fixture.

No existing controller, actor, Scheduler, Cursor, Playback, geometry, cue, difficulty, ledger, level or developer command file is changed by this fixture leaf.

## Actual source and renderer

`initialize_source(source_id, epoch, generation, definition, profile_id, prepared_world) -> bool` uses the strict authored constructor against actual measured native world descriptors before copying the native definition. Initialization occurs before admission. It sets one immutable fixed knot, raw-profile-derived maximum HP, and the source presentation. `attach_source_scheduler(actual_scheduler) -> bool` binds the same actual same-world Scheduler.

The source hook is the exact seven-field `authored-echo-source-1` binding:

```text
api_revision, source_id, source_epoch, generation,
definition (native vectors), alive, knot_position (native Vector3)
```

`get_authored_echo_renderer() -> Node3D` returns its retained child. The child's exact `authored-echo-renderer-1` binding contains `api_revision`, the original `presentation`, and `[actual RequiredEnemySilhouette MeshInstance3D]`. Its `present_authored_echo_pose(pose, quiet) -> bool` accepts the four fields `position`, `direction`, `action`, and float `progress`. The shared guard validates the native pose and custody. The hook only translates/yaws the root, records its pose and optionally publishes `pose_presented`; it never changes child transforms, geometry, materials, collision or damage. Quiet construction emits no signal.

The fixed 0.30 × 1.0 × 0.30 m Box silhouette has its feet at the source pivot, stays inside the explicitly authored radius/height, and uses opaque depth-tested unshaded nearest material. The fixture supplies native script, object, primitive and material identity checks; replacing a resource by an equivalent copy still rejects. There are no collision descendants in the renderer. `native_pose()` exposes defensive actual root transform, action/facing/progress, visibility and child transform for fresh-restore comparisons. The mesh is deliberately simple fixture art, not selected Act 3 production art or a Player substitute.

`take_damage(amount: float, impulse: Vector3) -> Dictionary` follows the common Player target-result fields: `accepted`, `hp_damage`, `target_id`, `target_alive_before_hit`. It is eligible only while the actual shared cursor is in recovery, outside pause/own callbacks, with intact native source resources. The target is in `enemies` while living. This stationary prototype consumes damage without moving its fixed knot. HP/lifecycle/hit count commit before observers; defeat calls actual `Scheduler.cancel_owner` with `authored_source_defeated`, retains the canonical cooldown/tombstone and removes the living target group. No loot or HP side effect is invented. The 12 HP fixture supports one lethal ordinary primary per cycle, not a general moving-enemy hurt/reaction implementation.

## Whole native save and restore

The source codec's exact schema 1 fields are:

```text
api_revision, schema_version, source_id, source_epoch, generation,
sequence, native, hp, max_hp, alive, source_hits, defeated_at_s,
physical, phase, clock_s
```

The new source API is `authored-echo-fixture-native-1`. `native` contains stable actual script/node paths, primitive dimensions/local pose, renderer layers/material policy and source presentation. Live capture additionally checks retained native script/mesh/material object identity and visibility. `physical` is the immutable knot and identity basis. `phase` joins the shared Playback cursor/status; `clock_s` joins the exact actual Scheduler clock. The renderer's animated root is owned by Playback's canonical cursor/pending receipt, and is never independently moved by this source codec.

Actor wrappers are `capture_source(player, scheduler, playback)`, `source_record_error(snapshot, player, scheduler, playback)`, `staged_source_binding(snapshot)`, `restore_source_physical(snapshot, player, scheduler, playback)` and `verify_restored_source_phase(snapshot)`. The codec rejects foreign or genuinely freed source handles before cast/property/hook access. Every restoration first requires a paused deferred boundary, exact actual fixture script/resources/definition/cycle, finite native numeric types, HP/alive correspondence, fixed knot, paired clock and phase. Dead source data must join its original shared authored cancellation tombstone and defeat clock.

The parent fixture prevalidates the complete unit before changing any actor:

1. Actual Player's `snapshot_error`.
2. Native source `source_record_error`.
3. Actual Scheduler `snapshot_error`, using the validated `authored_owner_bindings` staging seam.
4. Shared Playback `snapshot_error` against the complete Scheduler/Player/source/projection pair.

Only after all succeed does it restore Player, source HP/alive/fixed physical custody, actual Scheduler, shared Playback, then verify the source phase. Playback alone rejects premature commit. Shared Playback quietly recreates native renderer pose and required cues; the codec does not reproof, rearm, heal resources, refresh gear, execute damage or reemit defeat/events. Fresh worlds use separate native `World3D` instances with matching stable local floor/source identities; the original world/recognizer is retired before resumed input.

This fixture's input host intentionally has no Shell/attempt/progression envelope. Production shell aim/camera/menu state and parent historical cycle retirement remain separate integration custody. No source or playback transport authorizes a copied caller ID as an actual owner.

## Targeted intended checks

The fixture host subclasses actual `scripts/game.gd` and overrides only `_ready`/`_process` to suppress unrelated lab/HUD construction. It assigns a genuine shared Player and native camera. Viewport touch/drag/release and first tap pass through the inherited recognizer, swipe-release anchor, aiming and attack code unchanged. Native focus behavior is retained. The ordinary scenario performs real ticks, a proof-path escape swipe, a genuine return swipe and one ordinary primary at the actual reachable recovery knot. It checks default gear and a legal Padded Jacket/Cargo Pants/Longstep Shoes/Long Edge combination. Initial zero ammo is a disclosed paused public actor seed; there is no live ammo, HP, phase, position or deadline forcing after admission. The fixture checks actual ammo at primary time rather than treating an initial seed as proof that automatic reload never ran.

Other cases cover real mid-route pause/fresh quiet restore, exact source/clock/resource/definition negatives, native current cone contact, actual pending active-cue dash, held event/state observers, a real lethal Player damage callback before pending replay damage, once-only nested/equal-clock advances, required renderer hide/free/equivalent-resource replacement, and actual renderer-hook cancellation or unsupported pause. Supported ordinary cue/event/state holds retain the original accepted contact and time; renderer-hook pause is a bounded fail-closed cancellation. The shared consumer owns all pending stages and original opportunity latches. A renderer authority fault cannot be repaired by a saved active cue.

Terminal one-bit deadline/cooldown/fixed-knot/opening, profile, equal-valued float generation and world-type negatives retain the actual cancellation pair. A separately labelled **pure transport** positive/negative-zero Cursor arm control is not a fabricated physical exchange. Save checks use actual exact format 2 writes to isolated PID test paths, delete only those test files, and never touch a real campaign save.

The focused command is to be queued by integration through `python3 scripts/dev/dev.py engine` with `--headless --script res://tests/authored_echo_playback_smoke.gd` once dependencies are frozen. No engine bypass, broad suite, authored placement, full level route, production portrait, native OS input or human acceptance is claimed. Moving HP owners, concurrent mixed commitments, extra authored slots, sustained slash damage and production art remain outside this one-cycle fixture.

Related contracts: [authored data](AUTHORED_ENEMY_SEQUENCE.md), [shared playback](REPLAY_PLAYBACK.md), [whole witness](REPLAY_WITNESS.md), [Act 3 concept](../ACT3_CONCEPT.md). Canonical request: `8b06b4ea-d6f6-41f3-8931-79e6b41ec704`.
