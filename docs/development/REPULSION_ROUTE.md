# Measured repulsion route

`repulsion-route-1` is an implemented motion helper in [repulsion_route.gd](../../scripts/combat/repulsion_route.gd). It supports the existing AshEnemy box and a distinct upright capsule without replacing either collider. It does not implement a mushroom spore, damage, an enemy controller, a field avoidance policy, no-repeat rules, encounter acceptance or campaign fairness. Confirmed spores repel living enemies and cause no damage; their authored consumer remains separate work.

## Public API and ownership

Create one `CinderRepulsionRoute` per source lease:

```gdscript
func plan(owner: CharacterBody3D, motion: Dictionary, bindings: Dictionary) -> Dictionary
func acquire(owner: CharacterBody3D) -> bool
func advance(owner: CharacterBody3D, elapsed_s: float) -> Dictionary
func release(owner: CharacterBody3D) -> bool
func state() -> Dictionary
```

Errors return `{ "error": String }` or `false`, and set `last_error`. `plan` and `state` return defensive copies of private route data. A caller cannot enlarge the route by changing a returned dictionary. These dictionaries contain native vectors and are transient state; they are not a campaign save schema. No snapshot/retry consumer is supplied here.

```gdscript
var motion := {
    "direction": Vector3.RIGHT, # normalized world X/Z direction
    "speed": 4.0,
    "distance": 2.0,
    "body_collision_path": "BodyCollision", # optional, default shown
}
var bindings := {
    "world_root": authored_world,
    "floors": {
        "main-floor": {
            "collision": actual_floor_box,
            "safe_rect": Rect2(-10, -10, 20, 20),
        },
    },
}
var route := CinderRepulsionRoute.new()
var proposed := route.plan(enemy, motion, bindings)
# Check proposed.error before continuing. Plan has not stopped approach motion.
# The owner now cancels its attack/reservation and successfully leases its
# controller. Only then may acquire stop its velocity.
if not proposed.has("error") and route.acquire(enemy):
    pass # Call advance from the owning physics loop with elapsed simulation time.
```

Preflight accepts an actually supported source with finite planar approach velocity and leaves actor position, velocity, HP and collider untouched. The caller must perform attack cancellation and suspend its own approach/gravity/knockback writes before `acquire`; the helper cannot prove that external ownership barrier. Acquisition repeats body/world/floor and endpoint proof before stopping only velocity. Attack cooldowns, HP, player damage, cues and signals remain outside this helper.

`advance` consumes absolute, monotonic simulation time since acquisition. The owner freezes that clock with the simulation; the helper additionally rejects a paused tree. It checks the same source, expected position and velocity, original measured body, supported floors and actual static collision signature before moving. It deliberately stops on actual contact or full travel, and leaves finished routes stationary. On pre-movement rejection the actor is unchanged; the owner should release the route and handle interruption. `release` stops only a still-owned velocity. A changed pose/body or external impulse relinquishes the lease without overwriting the new owner's velocity. A synchronous physics violation after a real move disarms and stops the lease without teleporting back; arbitrary world mutation cannot be rolled back.

## Supported physics and conservative limits

- One enabled, centred, upright, unscaled **actual BOX or CAPSULE** on a live `CharacterBody3D`, identity global basis, scenery-only mask `1`, and no scenery bit on its layer. All linear/angular axis locks, collision exceptions, platform motion, vertical velocity, rotation and multiple enabled shapes reject. The shared hero's capsule is not used as a source proxy.
- Positive finite speed at most **32 m/s**, travel greater than **0.00001 m** and at most **16 m**, and intended duration at most **16 s**. Direction is a normalized planar vector. A wall may shorten actual distance and completion time.
- One to 32 distinct authored floor bindings. Each is an actual enabled, unscaled, unrotated, solid static box with one enabled shape, a safe world X/Z rectangle contained in its physical top, and the same ground height. Measured body feet may have the existing small settling gap, at most **0.015 m**; support rays confirm current physics registration rather than relying on a stale controller floor flag.
- Capsule support radius is its measured radius plus **0.01 m** skin. Box support uses `sqrt(half_width² + half_depth²) + 0.01 m`. The full centre route is analytically covered by intervals through the radius-shrunken authored rectangles. Endpoint rays supplement this continuous support proof; two successful rays alone cannot certify a middle hole. Endpoint proof also includes **0.005 m** contact tolerance.
- Prediction and execution both use bounded **0.05 m** sweeps of the actual body with **0.001 m** recovery margin. `recovery_as_collision=true` exposes depenetration. Nonplanar/off-route recovery rejects during pure prediction. Actual contact is allowed only within **0.005 m** of the supported predicted endpoint. The body does not slide, snap, jump or rotate during this helper's execution.
- The collision signature is measured from actual same-World3D SceneTree static collider paths, transforms, layers, masks, priorities, enabled shapes and shape data, plus physics engine/tick rate. Every scenery blocker must be under `world_root`; moving/animatable scenery, generated GridMap/CSG collision and unsupported shapes reject. The signature supports at most 256 scenery bodies. Native PhysicsServer-only RIDs cannot be globally enumerated by this Node helper and are prohibited by the authored-world contract.

The enclosing box disc, independently shrunken floor rectangles and strict static-world signature can falsely reject valid retreats near corners, continuous tile seams or unrelated scenery edits. Engine collision tolerances remain numerical approximations. The helper does not prove enemy separation, avoidance of a whole repelling field, correct field lifetime, no-repeat behavior, player escape or a safe combined encounter. Per-tick signature scanning has not been profiled as a campaign-wide workload.

## Evidence and API research

[repulsion_route_smoke.gd](../../tests/repulsion_route_smoke.gd) uses the **actual AshEnemy box**, plus a capsule with different dimensions, in real physics worlds. It covers wall-shortened and full-distance movement, supported endpoints separated by a middle hole, pure moving-source preflight, original collider/HP retention, overlap and floor depenetration, all axis locks, changed wall/source/floor data, moving floor and outside-root scenery, pause/time/lease guards, external impulses and external body rotation. The final targeted run passed **95 checks, 0 failures**, without runtime errors. These are helper fixtures, not portrait gameplay or authored-level acceptance.

The official [PhysicsBody3D API](https://docs.godotengine.org/en/stable/classes/class_physicsbody3d.html) documents pure `test_move`, physical `move_and_collide` and recovery reporting. The [CharacterBody3D API](https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html) documents platform velocity observations and distinguishes controller motion from body collision. Stable web documentation is not pinned to the local engine build; the targeted suite runs the project's actual **Godot 4.7.2**. Existing lunge motion remains unchanged.
