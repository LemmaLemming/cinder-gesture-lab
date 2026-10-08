# Shared systems implementation research

Inspected 8 October 2026 by the integration research helper; reviewed by integration. These observations inform implementation and tests. They do not prove Cinder's behavior or balance. API sources are explicitly Godot **4.7**, with JSON source inspected at **4.7.2-stable**, matching the reported installed baseline. Historical accounts do not establish current engine behavior.

## Coherent snapshots and persistence

Sources actually read: [JSON methods](https://docs.godotengine.org/en/4.7/classes/class_json.html) (`parse`, `stringify`, `from_native`, `to_native`); [tagged JSON implementation](https://github.com/godotengine/godot/blob/4.7.2-stable/core/io/json.cpp) (`_get_token`, `_from_native`); [saving games](https://docs.godotengine.org/en/4.7/tutorials/io/saving_games.html) (Some notes, JSON limitations, Binary serialization); [GlobalScope](https://docs.godotengine.org/en/4.7/classes/class_@globalscope.html) (`var_to_bytes`, `bytes_to_var`).

Plain JSON numbers parse as doubles, so large RNG state integers must not be written as raw JSON numbers. Native conversion tags ordinary integer values and vectors; objects are disabled by default. Packed integer arrays need separate scrutiny because the inspected encoder places elements into numeric arguments. Disabling object conversion alone does not validate a snapshot: unsupported values may become empty/null placeholders.

Proposed Cinder adaptation: use versioned plain-value records with explicit vector arrays, stable entity IDs, integer sequence/RNG fields encoded as decimal strings where exactness matters, and remaining simulation seconds for deadlines. Reject Object/Node/RID/Callable/Signal before encoding. Validate all shared and local state before applying; construct local entities and resolve relationships by IDs. Never restore an old encounter alongside refreshed HP/ammo/loot. Keep protected story and side attempts separate, with a validated backup and once-only completion/reward records.

Validation required: large signed integers, vectors/nested records, malformed/missing fields, version migration, interrupted writes, corrupt replay recovery without story loss, retry coherence, deduplicated drops/rewards and cleanup. This document does not implement those tests.

[RNG seed/state](https://docs.godotengine.org/en/4.7/classes/class_randomnumbergenerator.html) was inspected: assigning `seed` mutates `state`. Restore seed first, then saved state, and check identical subsequent draws. Record engine/save version; deterministic continuation across engine upgrades is unverified.

[Timer](https://docs.godotengine.org/en/4.7/classes/class_timer.html) (`time_left`, `paused`, `start`, `wait_time`) was inspected: `time_left` is read-only, start requires tree membership and does not unpause, and tiny intervals depend on processing cadence. Keep existing controller-owned simulation countdowns; restore while gameplay remains paused. Validate warning/active/recovery/reload/cooldown/effect clocks together at 30/60 rendering FPS.

## Collision and combined-threat safety

Sources actually read: [PhysicsDirectSpaceState3D](https://docs.godotengine.org/en/4.7/classes/class_physicsdirectspacestate3d.html) (`cast_motion`, `collide_shape`, `intersect_shape`), [shape query parameters](https://docs.godotengine.org/en/4.7/classes/class_physicsshapequeryparameters3d.html) (transform, shape, mask, exclusions), and [ray-casting](https://docs.godotengine.org/en/4.7/tutorials/physics/ray-casting.html) (Accessing space).

A shape sweep supplies static clearance evidence. `cast_motion` ignores shapes already overlapping at the origin; overlap queries ignore the motion field. Check start and endpoint overlap separately, using the controller's capsule transform/offset, mask, exclusions and margin. Physics-space queries belong at physics boundaries rather than input/menu callbacks. A center ray or clear endpoint cannot prove capsule clearance, and an empty sweep cannot establish supported floor.

Proposed Cinder validation extends beyond static clearance: wait through remaining dash cooldown; evaluate the whole timed route and arrival against **all preparing and active** authoritative footprints; verify floor support/body occupancy and a safe landing interval. Include commitment, movement and recovery, minimum legal dash speed/reach and spent ammo. Defer the next threat when no candidate is validated. Two attackers or staggered locks alone do not establish fairness. Compare queries with actual collision-shortened controller travel at corners, narrow passages, initial penetration and obstacle-side landings.

[Godot Forum Jolt discussion](https://forum.godotengine.org/t/so-whats-exactly-the-deal-with-jolt-physics/136341), 29 March 2026, posts 1–4, and maintainer mihe's linked [integration PR](https://github.com/godotengine/godot/pull/99895), Shape-casting/Motion queries, were inspected. The maintainer describes backend differences and approximate query resolution/cost. This is historical integration evidence, not a 4.7.2 benchmark. [Official 4.7 Jolt guidance](https://docs.godotengine.org/en/4.7/tutorials/physics/using_jolt_physics.html) describes the new-project default; Cinder's actual backend and costs must be measured locally.

## Pixel actors and modular 2.5D spaces

[SpriteBase3D](https://docs.godotengine.org/en/4.7/classes/class_spritebase3d.html) was inspected for offset, pixel size, billboard, alpha modes, depth test and render priority. Positive Y offset lifts artwork; pixel size defines world scale. Ordinary transparent blending can have sorting issues. Alpha discard removes partial alpha. Transparent render priority does not establish order against opaque geometry.

Preserve shared feet pivot/world footprint, nearest filtering and normal depth when adding act presentations. Review opaque actor edges separately from translucent effects, and fix occluding scenery rather than hiding depth defects. Inspect facing, mixed clothing, floor contact, muzzle attachment and warning visibility in actual portrait captures.

Developer Tom Coxon's [Technical Look: The Park](https://www.cassettebeasts.com/2021/08/09/technical-look-the-park/), 9 August 2021, Design and Using Godot sections, was inspected. It describes fixed-camera 2.5D spaces as top-down flow networks, structural layout iteration before decoration and modular terrain reuse. Apply the workflow to broad dash landings and optional parent-kit loops while retaining Cinder's no-jump/gesture boundaries. This historical account is not current Godot API evidence.

## YouTube review candidate — footage not inspected

[KiriSoft Games: Make Stunning 2D Characters in a 3D World](https://www.youtube.com/watch?v=s5pvDsDDxAY), published 24 October 2025. Only creator description/chapter metadata were accessible: importing 00:51, sharp Sprite3D 01:30, shadows 02:00, billboarding 02:46 and final setup 03:00. Opening the video failed; no footage or transcript was viewed. Those chapters are follow-up candidates and provide **no technical validation evidence** in this run.

## Bounded scheduler physics applicability (8 October 2026)

Inspected official [PhysicsDirectSpaceState3D](https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate3d.html): `cast_motion` returns safe/unsafe travel fractions and ignores already-overlapping shapes; `intersect_shape` does not use query motion. Adaptation: explicit start/end intersections plus actual capsule motion cast, combined with analytic support coverage rather than sparse floor probes. Targeted Godot4.7.2 scheduler suite validates wall/hole/step/union cases; numerical physics tolerances and finite candidate false rejection remain limits.

Inspected official [PhysicsBody3D](https://docs.godotengine.org/en/stable/classes/class_physicsbody3d.html) scale guidance and [pausing](https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html): supported proof requires unscaled fixed capsules/unrotated floor boxes; simulation uses PAUSABLE processing and explicit request guards because signals may still run while paused. Actor snapshot suite validates callback guards/static-floor continuation. These readings and automated checks do not establish human recognition time or campaign balance.
