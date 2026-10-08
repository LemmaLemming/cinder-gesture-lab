# Measured body sweep

`body-sweep-1` is a pure scenery/support query implemented in [body_sweep.gd](../../scripts/combat/body_sweep.gd). Integration owns its use by lunge, repulsion and replay adapters. It does not execute movement, reserve threats, establish timed escape fairness or accept an authored level.

## Installed engine evidence

The inspected and tested build is Godot **4.7.2 stable official**, commit `ed1daf0bf001b61586d9930840f2f1394092c079`. The helper independently adapts the installed [PhysicsBody3D wrapper](https://raw.githubusercontent.com/godotengine/godot/ed1daf0bf/scene/3d/physics/physics_body_3d.cpp) (lines 98–131, 149–163) and its [default cancellation declaration](https://raw.githubusercontent.com/godotengine/godot/ed1daf0bf/scene/3d/physics/physics_body_3d.h) (line 50). A raw `test_move` result bypasses the wrapper's bounded off-axis recovery cancellation. This difference caused the Act 3 grounded source preflight rejection.

The wrapper starts with 0.001m precision, adds motion length times unsafe-minus-safe fraction when colliding, and retains recovery if collision depth exceeds margin plus precision. Otherwise it cancels orthogonal recovery only when its length is below that threshold. The helper uses the same 0.001m margin and cancellation arithmetic. Runtime execution must still call `body.move_and_collide(motion, false, 0.001, false, 1)`.

The [4.7 motion parameters](https://docs.godotengine.org/en/4.7/classes/class_physicstestmotionparameters3d.html) and [motion result](https://docs.godotengine.org/en/4.7/classes/class_physicstestmotionresult3d.html) document query transforms, recovery reporting, body RID exclusions, travel, depth and safe/unsafe fractions. A floor-excluded zero-motion query is supplementary classification only. The execution-compatible motion query includes the actual floors. The helper never adds collision exceptions, raises the actor, moves a proxy, changes velocity or teleports a physics body.

## API and supported geometry

```gdscript
var measured = CinderBodySweep.source_description(body)
var result = CinderBodySweep.step(body, virtual_from, motion, floor_regions)
var result = CinderBodySweep.sweep(body, virtual_from, motion, floor_regions)
```

`body` is the actual live `CharacterBody3D`; `virtual_from` is a `Transform3D`. Each floor entry is `{collision: CollisionShape3D, safe_rect: Rect2}` in world X/Z. Queries return `{error, api_revision}` on rejection. Accepted step results contain `motion`, `travel`, `end`, `collided`, `collider_rid`, `normal`, `raw_travel`, `floor_recovery`, `cancelled_recovery`, and safe/unsafe fractions. A nonzero sweep adds its ordered step records. RID/contact results are live query diagnostics, not a JSON snapshot format.

The body must have one upright centred native capsule or box, identity global basis, scenery mask 1, a body layer outside scenery, unlocked linear axes, finite velocity, no collision exceptions and no moving-platform carry. Moving-source velocity is permitted and remains untouched by preflight; the integration owner still cancels or leases real motion before execution. Support requires live coplanar unrotated static box floors with one active shape each. Animatable floors and nonzero constant floor velocities are rejected.

Steps are at most 0.05m; sweeps at most 16m; virtual coordinates stay within ±512m. Continuous floor coverage uses the measured X/Z footprint plus the query's 0.001m margin. Actual support rays check the registered floors. Callers retain their own larger escape/fairness margins, immutable geometry guards and before-execution endpoint comparison: a new wall returns a newly shortened endpoint, which cannot authorize an earlier committed route.

## Resting contact and snapshots

Act 3's actual grounded capsule measured a bottom clearance of `-0.0000781416893m`; its reported floor-only recovery was `+0.000894890167m`. The shared-size fixture reproduced `-0.000078130048m` through ordinary gravity and `move_and_slide`, with unchanged native 0.32m radius, 1.45m height and 0.73m centre. The existing AshEnemy box remains 0.75 × 1.45 × 0.65m, centred at Y 0.725m.

Measured feet may lie within **−0.001m to +0.015m** of the same supported floor. Negative resting clearance requires a reporting-enabled zero-motion query at the exact virtual pose to identify actual validated floor RID contacts with UP normals. Recovery must be upward only, at most 0.002m, and explain the motion query's orthogonal correction. Any non-floor recovery rejects. A 0.005m actual embedding rejects before motion. These are source collision tolerances, not looser player escape clearance or time tolerances.

The contact proof uses the actual world and collider at the virtual saved pose. It does not rely on a fresh recipient's cached `is_on_floor` state. Snapshot owners must still validate geometry identities, clocks, actor state and their atomic restore contract; this module neither serializes nor restores them.

## Targeted verification

[body_sweep_smoke.gd](../../tests/body_sweep_smoke.gd) ran through the shared queue:

```sh
python3 scripts/dev/dev.py engine --headless --path "$PWD" \
  --script tests/body_sweep_smoke.gd \
  --log-file "$PWD/.cinder/body-sweep-final-engine.log"
```

Result: **62 checks, 0 failures, exit 0**, on the exact build above. Ignored log: `.cinder/body-sweep-final.log`. Tests cover natural grounded native capsule/box, fresh recipient virtual saved pose, untouched pose/velocity/exceptions, per-step real execution parity including the installed sub-epsilon zero-normal cancellation, thin-wall shortening, added wall, deep floor and shallow side-wall embedding, support gaps, bounded work and unsupported exceptions/moving floors. The engine also emitted the existing macOS CA certificate warning; no script errors occurred.

This is headless shared physics fixture evidence. Act-specific integration, portrait playability, live paused actor snapshot execution and other engine builds remain separate validation obligations. No mobile performance or campaign completion is claimed.

## Translated native coordinates

Shared14 corrects a real Act3 prediction at source `(-2.663714647293091, -0.00415944354608655, 30.974029541015625)`. Sixty clear virtual steps previously accumulated a 0.000048084m off-axis bend, despite no collision and correctly cancelled floor recovery. A separate clear route near Z−12.4 was incorrectly marked collision-shortened. Both diagnostics remain preserved in the owner's mailbox evidence.

Sweep points now derive from the original start and displacement using scalar arithmetic, then construct one native vector. Real lunge substeps similarly derive from the original frame path and still execute actual `move_and_collide`; no body is teleported or lifted. A collision-shortened plan requires a measured actual query contact and a shorter projected route. The unchanged physics contact margin is 0.001m and endpoint guard is 0.005m.

Godot's [large-world coordinate documentation](https://docs.godotengine.org/en/stable/tutorials/physics/large_world_coordinates.html) explains that ordinary GDScript scalar floats use 64 bits while default Vector3 components use 32 bits. This correction applies that distinction to the measured native route. Only derived represented position/route arithmetic uses the existing 0.00001m local epsilon plus two √3 native coordinate ULPs. At the supported ±512m boundary this allowance is below 0.000222m. Invalid or out-of-bounds saved positions reject before the allowance is calculated. Copied clocks, identities, capsule dimensions, vertical resting clearance, source bindings and contact tolerances retain their existing strict checks.

Run `python3 scripts/dev/dev.py test translated_lunge`. The new headless fixture passed **294 checks, zero failures** on the installed 4.7.2 build: actual capsule/box query-to-motion parity at signed Z31/−12.4 and inward ±510m, full and incremental real capsule stops, real walls/new walls/deep embedding/out-of-envelope rejection, and a moving-active exact paused/fresh player/source/scheduler continuation. Logs are `.cinder/translated-lunge-second.log` and `.cinder/translated-lunge-second-engine.log`; first fixture282/1 lacked a legal diagonal return candidate and remains diagnostic evidence. No player stats or clocks were changed to fix it.

Directly affected body62, motion19, adapter35, snapshot35, staged lifecycle62, repulsion95 and replay witness60 checks passed with zero failures. An initial root adapter invocation used a nonexistent plural script path and produced no checks despite engine exit0; its preserved log is excluded from passing evidence. The corrected named adapter target passed35. These shared fixtures do not accept the authored first pocket, multi-fatal overlap, camera framing or complete Act3 route; those require the owner's targeted adoption checks.

Independent fixture measurements across28 clear capsule/box sweeps found0.0m native endpoint error and0.0m maximum per-step actual M&C parity error at sampled poses. Test acceptance derives four coordinate ULPs independently from production, with a2µm minimum. This bounded sample does not establish arbitrary world geometry or other engine builds.
