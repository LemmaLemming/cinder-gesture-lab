# Native warning-start sampled circle

Integration owns `scripts/combat/native_sampled_circle.gd` and the Scheduler extension. This implements the B02 dependency for Act 1 L5: sample the actual grounded, stopped shared Player when warning begins; keep that circle fixed while the Player moves. The genuine stationary eye owns HP, its physical opening and its Scheduler reservation. The child consumer owns phases, cues and contact consumption. Published as `campaign-shared-56` for owned integration. Component evidence is complete; whole-level acceptance remains with each act.

## Composition and start

Use one actual `CinderPlayer`, the level Scheduler and an actual stationary `CharacterBody3D` eye with a supported Box/Capsule collision body. The eye implements `take_damage(amount, impulse)` and the pure zero-argument `get_sampled_circle_binding()`. The latter returns exactly `CinderNativeSampledCircle.SOURCE_KEYS`: source API `sampled-circle-source-1`, stable source/hero IDs, stable incarnation epoch/generation, immutable definition, true alive state, actual opening position and the actual Player reference. Definition contains radius, raw role and timing floors. See the executable [eye fixture](../../tests/fixtures/sampled_eye_fixture.gd) for the complete contract.

Add the consumer as the eye's child and call `bind(eye, scheduler, hero_id, hero, world_root, floor_regions)` once after ready. This establishes identity without allocating an attack. Bind the level's two-argument presentation guard before the first cycle; it validates its actual source and required art at gameplay boundaries. Preserve native required cue nodes/resources and the consumer's physics priority after both Player and Scheduler.

Begin the encounter through the shared Scheduler. Supply exactly `CONTEXT_KEYS` to `preview_start(context)` and `start(context, preview)`. The preview is pure and a stale preview is rejected. The Scheduler derives the sample from the live Player, including actual support, source identity, clocks and floor. Callers cannot choose a remote target coordinate. A moving/airborne Player cannot start this attack; movement after admission preserves the original sample. Finite expired motion timers follow the Player's stopped-state semantics.

The genuine source marker remains at the eye, separate from the sampled footprint. The existing Scheduler proves combined preparing/active geometry and a reachable ordinary-primary opening. A consumer does not automatically rearm: after finite recovery and the original cooldown, the owner explicitly starts another cycle. Keep the same source incarnation across cycles. On real eye death, cancel that eye's reservation with `source_defeated` before notifying observers.

## Contact, pause and cleanup

Native physics samples the real Player path. Supported contact during the original active interval consumes one opportunity per cycle; the actual Player decides whether damage succeeds, including its ordinary invulnerability. Unsupported contact causes no hurt and does not cancel or retarget the exchange. Missing/replaced required source, floor or cue resources invalidate danger. Parent presentation is rechecked across observer boundaries before damage.

Pausing from a phase observer retains an unresolved path suffix. Capture only after leaving the physics/callback transaction at a stable paused barrier. Parent removal, cancellation and ordinary level disposal release the reservation and required cues. Do not repair actors, timers or geometry from a validator.

## Whole-parent persistence

A registered sampled source uses Scheduler schema 4. Existing unsampled schema paths remain supported. Use exact typed transport (`ExactJson`) for the new packets; preserve String dictionary keys and original float values. Validation rejects cycles, Objects, foreign StringName keys and malformed or altered sample/exchange data.

Capture actual Player, eye HP/death/pose, Scheduler and consumer packets at one paused barrier. A fresh restore candidate constructs and binds the genuine source/consumer before prevalidation. Validate complete saved Player and eye packets first, then derive Scheduler bindings `hero_positions`, `hero_action_clocks`, `owner_positions`, `owner_velocities` and `sampled_owner_bindings` from those validated packets. Pass the paired saved Scheduler packet to `consumer.snapshot_error`.

Commit quietly in order: **Player → physical eye → Scheduler → fresh consumer**. The consumer recipient must be idle at cycle zero. At commit, use actual bindings and actual restored nodes. Preserve original deadlines, historical sample, current Player dash state, consumed opportunity and pending suffix; do not rerun preview/start or resample a saved attack. The level remains responsible for whole-parent atomic refusal, authored topology, its own art guards and the existing Shell candidate contract.

## Validation scope

The targeted native suite is `python3 scripts/dev/dev.py test sampled_circle`. Directly affected compatibility suites are `threat_scheduler` and `threat_snapshot`; all use the common Godot queue. Original unsuccessful runs remain under `.cinder/sampled-circle-native/`. The full new component suite passes 103/103 with no engine diagnostics; existing Scheduler69/69 and Snapshot35/35 checks also pass. The narrow repaired held-restore case passed 17/17 before the full run. [Original failed and clean results](evidence/sampled-circle/index.json) retain their scope. The queued graphical check passes17/17. Integration inspected all three540x1170 warning/active/recovery captures: original sample, safe real-dash landing and distinct source marker remain readable. The first TEST solid box covered its source marker; the corrected open TEST frame and original failed view are both retained. This is a primitive component view, not authored level-art acceptance.

Act 2 prepares independent [Shell persistence support](ACT2_SHARED_SUPPORT.md), including disk Continue, GUI Retry, malformed refusal, protected Story/replay state and cleanup. Its fixtures await an exact published revision for execution. Primitive component checks do not accept Act 1 L5 or prove whole-campaign flows. Full playthroughs remain untested and are not acceptance gates.
