# Retained source collision staging

This additive hook supports an earlier live lunge snapshot when its bound actual
source is now defeated but retained. It addresses Act 3 request
`dd7bc9cc-14cc-42ca-be42-4d137ae85d66`, acknowledged by integration response
`30b5793e-a482-45b8-a969-d93f1c2c559e`, against shared11
`4ed79c406550ea0b70ccf35b3f6b07e0bb753bea`.
It does not implement the worker-owned Act 3 aggregate hook or certify that
worker's encounter restore. It leaves replay, live motion and collision queries
unchanged.

## Public API and native bindings

`CinderLungeMotion.staged_source_description(owner: CharacterBody3D,
state: Dictionary) -> Dictionary` is a pure paused-tree descriptor. It returns
the same derived `signature`, `radius`, `height`, `foot_offset` and actual
`collision` node as the live descriptor, or `{ "error": String }`. The returned
signature is newly constructed; the collision node is an actual diagnostic
reference, never transport data or a caller substitute.

Scheduler snapshot methods accept optional **native** bindings:

```gdscript
bindings["owner_collision_states"] = {
    "sun-0": {
        "collision_path": "BodyCollision",
        "enabled": true,
        "layer": 2,
        "mask": 1,
    },
}
```

The map keys are stable String owner IDs already mapped uniquely to actual
`CharacterBody3D` nodes under `bindings.world_root`. Each state is a closed
dictionary with exactly the four fields shown. `enabled` must be boolean true;
`layer` and `mask` must be native integers. Layer values may be 0 through
4294967295 with scenery layer 1 absent. Mask must equal 1, the supported scenery mask.
Layer 2 is the fixture and current source convention, rather than a requirement.
The path must name the actual capsule as a direct child under its canonical
relative path; aliases and absent/wrong-parent paths reject.

The actor's already validated snapshot determines these lifecycle flags. The
caller must derive them in its actor hook, bind the same actual actor, and
prevalidate the whole aggregate before committing anything. Neither this native
map nor the scheduler is an actor-state validator. Omit entries for actors whose
saved state is dead or does not need a live lunge lease; this hook accepts only
live capsule staging. It does not accept caller geometry, shape resources,
proxy bodies, replacement fingerprints or serialized hash overrides.

The descriptor reads the retained actual capsule even when its node is disabled
and its current body layer/mask are zero. It requires a paused live, unrotated
body with unlocked linear axes, one upright centred `CapsuleShape3D`, exactly one
retained registered shape owner, and exactly one collider child. The registered
owner, shape resource, transform and disabled state must agree with the actual
collision node. Extra enabled, disabled, empty or pending colliders/owners
reject. Radius, height, shape margin, solver bias and centre come from the actual
resource/node. Their derived signature, the staged layer/mask, axes and path must
equal the saved lunge `body_signature` exactly during staged prevalidation.
An altered actual capsule cannot be repaired by this binding.

`snapshot_error(snapshot, bindings)` may use the map alongside the existing
`owner_positions` and `owner_velocities`. It does not enable collision, move a
body, advance a clock, mutate a reservation or emit a callback. The same
snapshot callback/physics transaction barrier remains required.

`restore_state(snapshot, bindings)` repeats full prevalidation, then checks the
**actual** source through the original strict live `source_description` and
`_lunge_source_valid` commit path. Actual enabled collision, layer/mask, pose and
velocity must already match the saved exchange. Merely supplying staged values,
or restoring pose and velocity while leaving the capsule disabled, cannot
commit. Rejection leaves the scheduler unchanged. The caller remains responsible
for completing atomic aggregate prevalidation before actor commits.

## Quiet aggregate order

1. Pause at a deferred shell boundary outside physics and all actor/scheduler
   callbacks. Finish pending collision flag updates before inspecting retained
   registrations.
2. Validate player and source actor envelopes. Build native owner pose, velocity
   and optional collision states from those validated actors. Bind current
   actual retained nodes and authored floors/world.
3. Validate the scheduler and other aggregate envelopes before any mutation.
4. Apply the validated actual player/source states, including real collision
   flags, without yielding or executing attack/damage/death/configure paths.
5. Commit the scheduler, then any separately validated level presentation state,
   without a yield or fresh attack request.
6. Resume only after the entire pair has committed. The original clock, lease,
   motion cursor, collision-shortened landing and cooldown continue.

This hook cannot restore a freed/queued-for-deletion actor or a changed capsule.
It does not revive or heal a source during prevalidation. The separately
validated actor commit applies the explicit earlier saved HP/lifecycle. No
stationary/tracking/replay adapter receives substitute physical geometry, and no
`Motion.plan`, `Motion.advance`, body sweep solver or live source guard uses
staged state.

## Compatibility and validation

`threat-scheduler-4`, `scheduler-snapshot-1` and schema version 1 are unchanged.
The new map is caller-only native binding data; no serialized field, body
signature, ordinary adapter record, replay record/tombstone or deadline changes.
Callers restoring fresh live worlds keep their existing bindings and behavior.
The unstaged live signature validator retains its existing numerical policy;
staged immutable signature identity uses exact numeric equality, and precise
transport uses the public `CinderExactJson` helper.

The focused fixture is
`res://tests/staged_lunge_collision_smoke.gd`. It uses an actual retained
`CharacterBody3D` source with a test-only actor validator, actual shared player
ordinary primary damage with zero shells, real scheduler-driven wall-shortened
motion, and exact actor/player/scheduler JSON transport. Checks cover mid-active
capture, uninterrupted endpoint, actual death with registered disabled capsule
and layer0/mask0, pure repeated prevalidation, malformed/unknown/extra bindings,
extra/pending colliders, actual and saved geometry drift, registered owner
incoherence, premature commit, quiet actor-before-scheduler restore, pause,
unchanged cooldown and no redamage, and fresh-world compatibility. No Act 3
worker files are imported or changed by this fixture.

Queue only the focused leaf and directly affected ordinary snapshot regression:

```sh
python3 scripts/dev/dev.py engine --headless --path . \
  --script tests/staged_lunge_collision_smoke.gd \
  --log-file "$PWD/.cinder/staged-lunge-collision-engine.log"
python3 scripts/dev/dev.py test threat_snapshot
```

Observed queued results: **62 checks, 0 failures** for the staged collision leaf
(`.cinder/staged-lunge-collision-final.log`) and **35 checks, 0 failures** for the
directly affected ordinary snapshot leaf
(`.cinder/staged-lunge-affected-snapshot.log`), both exit 0. Neither log contains
script/parse/test failures. These sandboxed runs contain startup user-directory
logger and macOS system-certificate diagnostics; the relative log-file argument
was interpreted under `user://`, so the repeatable command above uses an absolute
writable path. No further broad suite was run.

The implementation was checked on installed Godot 4.7.2. The applicable official
4.7 API documents distinguish retained shape-owner metadata from nodes and
expose disabled/count/resource/transform inspection:
[CollisionObject3D](https://docs.godotengine.org/en/4.7/classes/class_collisionobject3d.html).
The collision node's disabled flag controls world participation and ordinarily
uses a deferred update:
[CollisionShape3D](https://docs.godotengine.org/en/4.7/classes/class_collisionshape3d.html).
This fixture specifically checks registered/node agreement after real deferred
death and the subsequent paused actor setter commit. It establishes this
bounded aggregate mechanism, not moving-floor support, campaign acceptance,
human gesture review or an Act 3 worker runtime result.

The separate actual authored-world float32 sweep request
`4ba9b04c-02ef-44a4-87b4-e6d8697d22ca` is outside this change. This fixture uses
the existing near-origin wall-shortened route; it does not establish translated
world-axis accumulation or unobstructed long-distance sweep correctness. The
integration owner handles that motion correction separately after this handoff.
