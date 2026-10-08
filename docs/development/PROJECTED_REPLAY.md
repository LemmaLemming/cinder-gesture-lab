# Opt-in projected replay consumer

The isolated consumer fixture is `tests/projected_replay_smoke.gd`. It exercises optional clipped presentation and floor membership through the actual shared Player, sealed ReplaySequence, complete-union Scheduler admission and ReplayPlayback. The [footprint leaf](REPLAY_FOOTPRINT.md) supplies finite immutable native projection data; the [capture gate](REPLAY_CAPTURE_GATE.md) still owns real capture retirement. Neither meshes nor a copied context authorize an encounter, admission or reuse of a consumed capture.

## Public opt-in boundary

The integration owner supplies these additive Playback APIs:

```gdscript
bind_projected(scheduler: Node3D, reservation_id: String, heroes: Dictionary,
    floor_regions: Array, projection: Dictionary, context: Dictionary) -> bool
get_footprint_projection() -> Dictionary
snapshot_error(snapshot: Dictionary, scheduler: Node3D,
    scheduler_snapshot: Dictionary, bindings: Dictionary, heroes: Dictionary,
    floor_regions: Array = [], projection_context: Dictionary = {}) -> String
restore_state(snapshot: Dictionary, scheduler: Node3D,
    scheduler_snapshot: Dictionary, bindings: Dictionary, heroes: Dictionary,
    floor_regions: Array = [], projection_context: Dictionary = {}) -> bool
```

Ordinary `bind(scheduler, reservation_id, heroes)` retains its existing behavior. The parent holds the exact same admitted `world_root`, real floor bindings, original source epoch/generation and both collision/floor signatures captured at the original arm. The projection is recomputed and matched against the unchanged sealed sequence and exact real world before any native cue or binding commit. An explicitly projected owner rejects empty or altered projections and mode downgrades. The defensive getter supplies display/camera information, never admission or retirement authority.

ThreatCue adds `projection_binding_error(event_projection) -> String`, `bind_projection(event_projection) -> bool`, `projection_state() -> Dictionary` and `projection_error(expected_event) -> String`. Binding is a fresh clear-cue operation; subsequent presentation retains the original canonical logical cone and original source. Fill uses the precomputed triangles, and outline uses every closed outer/hole boundary at the encoded floor plane with the existing common lifts. The outline must stay inward within the authenticated conservative fill so its visible width cannot extend into a physical hole or blocked shadow. Native nodes, mesh resources/surface buffers, transforms, required visibility and material policy remain guarded. Clearing or re-presenting a phase cannot repair a lost or substituted damaging renderer.

## Contact and paused custody

Projection triangles and curve chords are presentation only. Live contact keeps the unchanged original record range, origin disk, cone dot, vertical limit and native scenery ray, with authenticated valid-floor membership as an additional predicate. The actual admitted hero is sampled at the original dispatch boundary. The complete event-prefix receipts commit before callbacks; active presentation, damage attempt and notification keep their original order. A callback pause retains the original contact and scheduled/dispatch clocks instead of sampling a later hero pose.

Projected snapshots use conditional schema **3**, carrying the immutable `projection` and `pending_delivery` only while an original callback remainder exists. Ordinary schemas **1/2** retain their exact old shapes. The owning parent validates the saved actor and Scheduler with the same external floor/context bindings, then commits **actor → Scheduler → Playback** at a paused deferred barrier. Fresh quiet construction reproduces native clipped meshes, the actual last-presented apparition and partial cue phases without emitting warnings, damage, events, clocks or new resources. A live projected owner cannot restore an ordinary snapshot to discard its required projection.

Schema3 validation recomputes the projection against the original world and floor bindings even for a canceled owner. A cancellation after immutable scenery or authored-floor drift can be restored only after the parent restores that original world/domain; saving it against the changed world is unsupported. This conservative limit adds no live attack authority and does not change ordinary cancellation schemas.

## Native fixture and evidence

The original selector runs against the actual published shared23 Playback and ThreatCue:

```sh
python3 scripts/dev/dev.py engine --headless --path . \
  --script res://tests/projected_replay_smoke.gd \
  --log-file "$PWD/.cinder/projected-replay-original.log" -- --original-warning
```

The original run completed **22 checks, 5 expected failures, exit 1** on Godot `4.7.2.stable.official.ed1daf0bf`. Actual dash/primary recording, sealed sequence, FIFO retirement, complete-union admission, fresh lock and active callback all passed. The native committed fill covered an actual four-Box floor hole and full Box LOS shadow; **66 vertices** of the visible warning outline lay behind blocking scenery. Both missing clips remained in the actual active fill. The warning phase's fill was hidden; the original evidence distinguishes its retained future-active mesh from the visible outline and the later visible active fill. This was a concrete rendering regression, not a missing-API assertion or failed fixture setup.

The first fixture and explicit published dependency subset are preserved in `.cinder/projected-replay-original/`. Original log SHA-256 is `173006182c1d402feb84eedc1f03d95a8d882a4b83c4fbcf82e5c0a0530a2aa8`. All archived loaded sources remained byte-identical during that run. The log retains the macOS sandbox system-CA startup diagnostic; no script/parse/setup exception occurred.

The final projected consumer target passed **467 checks, 0 failures, exit 0**. It covers native warning/lock/active/recovery geometry; original empty-ammo primary and independently aimed blast contacts; physical-hole native gravity; held active and partial warning/lock callbacks; exact-tagged fresh paused restoration; immutable event/record/order/triangle/contour/one-bit guard rejection; and hidden/lost/replaced/mutated native mesh failure before damage. The footprint leaf remains unchanged at **164/0**, and the projected cue target passes **271/0**. Directly affected ordinary cue and playback targets pass **82/0** and **475/0**. The latter ran with scoped access for its isolated test SaveStore files, after the sandbox denied those writes. No broad or unchanged level suites were repeated.

The [portable evidence index](evidence/shared24-projected-replay/index.json) preserves raw logs and declared source subsets. These are not complete transitive import graphs. Final runtime SHA-256: Footprint `abc07a5ba2159a46c5726d4a7e762d2b6d425bf934efd8a29878883b4c438346`, Cue `2996af6fc2bc4314599615a5753f1d4baf7940dce91a2f8e262f018e64b36cbb`, Playback `1c90ae6c034176e785286a7b0c66a36e5f5547bdb04691588389d4ff04a1fb54`. The final consumer fixture is `c7ebd9d162d87d3681959f6adb11c72d9af260c3aacd65f30d046588aa88ffcf`.

| Consumer run | Result | Interpretation |
| --- | --- | --- |
| Published23 original | 22/5, exit1 | Concrete unclipped native fill/outline regression described above. |
| First projected | Reported146/0, exit0 | Excluded: Playback's new constant name collided with native `Projection`, causing parse/setup errors. A constant-only rename repaired compilation. |
| Second projected | 315/7, exit1 | Six fixture proofs lacked an escape for the independently left-aimed blast; the gravity control incorrectly required ammo to remain0 during native passive reload. Actual original recordings and production guards were unchanged by the fixture repair. |
| Third projected | 467/1, exit1 | The fixture incorrectly required a closed hole contour where the physical hole intersects the cone's outer boundary. A diagnostic float format was also unsupported. |
| Final projected | 467/0, exit0 | Checks the actual encoded physical-hole boundary, including the truthful outer indentation. Native records, world and proof deadlines remain unchanged. |
| Ordinary playback sandbox | 406/11, exit1 | Isolated temporary-save writes were denied; fresh saved flows could not proceed. Preserved as a failure, not a passing regression. |
| Ordinary playback with save access | 475/0, exit0 | Same frozen runtime/test sources; all pending-drain and fresh SaveStore flows pass. |

The headless sandbox runs retain the native macOS system-CA startup diagnostic. The final projected/ordinary cue runs contain no script or parse failures; the scoped native playback run loads system certificates and contains no script/parse/runtime errors. During the actual gravity control passive reload changes ammo0→1 over four native ticks; this is disclosed rather than relabeled as an inventory that remains empty. The blast controls include a valid back escape/forward return as well as the primary's left/right response.

## Bounds

The supported world is the footprint leaf's fixed coplanar axis-aligned Box floor/scenery domain, bounded LOS-height band and complexity limits. The conservative full-cone ReplayWitness remains unchanged; this fixture supplies valid ordinary escape/return responses rather than claiming that a hole or wall shadow grants a new shelter proof. Live contact controls explicitly arrange the actual hero after admission and never alter recorded world actions. The gravity case uses actual native actor progression over the physical hole.

This is a headless native shared consumer fixture, with no production saves, authored boss placement, portrait capture, human-input/balance review or complete encounter/campaign claim. It does not relax floor, dispatch, original contact or damage guards. Parent capture, level pairing, camera framing and authored source/landing readability remain the consumer's existing responsibilities.
