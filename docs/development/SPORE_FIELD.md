# Shared mushroom supply and field seam

`spore-field-1` implements finite hit-activated environmental supplies, pausable field clocks, required cues and silent local JSON restoration. It does **not** implement living-enemy repulsion, retreat or avoidance. Its domain API is input for that forthcoming consumer, not a damage reservation or a proof of safe retreat. No authored Act 1 scene is accepted by this shared fixture.

Confirmed direction comes from [Act 1's spore interaction](../ACT1_CONCEPT.md#hittable-spores-create-breathing-room): ordinary attacks release harmless spores; living enemies must retreat; the player remains unharmed. [Shared style](../GAME_STYLE_GUIDELINES.md#restrained-cues-for-things-the-player-can-use) requires distinct full/spent clusters and a friendly broken boundary without danger fill/countdown. [Asset reuse](../ASSET_REUSE_GUIDE.md) requires per-instance supplies and clocks. [USAGE-17](../ABILITY_USAGE_WORKFLOW.md) places this environmental interaction outside player equipment introductions.

The default **provisional** fixture uses exactly two clusters, a three-second field including its immediate release, a final half-second thinning phase and radius `2.025` world units (¾ of baseline dash distance `2.7`). The radius comes from the immutable field definition; carried gear does not change it. Thinning changes presentation while retaining the full logical radius until expiry. No automatic replenishment is implemented. Duration, thinning and radius may be explicitly configured within validated bounds before binding; this is no balance acceptance.

## Public surfaces

- [CinderSporeField](../../scripts/environment/spore_field.gd): `configure(instance_id, clusters, parameters={})` before tree binding. Exactly two cluster dictionaries contain `id` and a finite world-axis `offset:Vector3`; IDs are distinct and anchors separated. Authoring must assign unique instance IDs within the encounter. Binding fixes the finite, unrotated/unscaled world origin and geometry.
- [CinderSporeCluster](../../scripts/environment/spore_cluster.gd): each HP-free anchor joins `environment_attack_targets`. `receive_attack({kind:"primary"|"blast", origin:"player_direct"})` delegates to its mushroom's atomic `activate_cluster(id)`. It returns separate interaction acceptance and rejected/zero damage accounting; it has no HP or `take_damage` interface.
- `state()`, `active_domain()` and `get_cue_state()` return defensive data. The domain is empty after expiry; otherwise it includes stable instance/generation field identity, origin, fixed radius, phase, remaining time and unchanged deadline. It explicitly reports `causes_damage:false` and `retreat_implemented:false`. A future consumer must add matching floor/scenery membership and safe routing; the circle alone is not an implemented propagation or navigation rule.
- `snapshot_state()`, `snapshot_error(snapshot)` and `restore_state(snapshot)` require the paused deferred boundary outside callbacks. Snapshots use JSON arrays for vectors and preserve immutable definition/geometry, actual clock, generation, distinct spent IDs, activation, deadline and canonical phase. Validation precedes mutation; restoration updates required presentation without field, activation or child cue signals. The level's aggregate snapshot remains responsible for restoring matching enemies/player/supplies together.

The first eligible hit commits one consumed cluster, activation and deadline before callbacks. It is immediately an active domain in the `releasing` phase; the next pausable physics advance moves to `active`. Hits on either anchor during releasing, active or thinning neither spend nor refresh. After expiry, remaining supply becomes available; after the second field expires, the mushroom stays spent. Explicit restoration can restore earlier recorded supplies as part of a coherent checkpoint; restoration never performs another hit.

[The shared player](../../scripts/player.gd) reuses the existing range, height, cone/origin-disk and scenery LOS checks for a separate environmental dispatch after damage targets. Environmental results never enter hit counters, living-enemy reload credit, death or damage/hit perk events. Existing primary/blast records and costs remain unchanged. A spore-directed blast spends its ordinary shell and resets ordinary reload. Future normal action/miss perk semantics remain governed by `PROC-01`; a scenery-only primary is still a miss.

## Presentation provenance and readiness

The current full-cluster cubes, empty patches, local interaction markers, four falling square release markers and broken floor boundary are original procedural shared-fixture geometry authored in the scripts above. They are not converted film assets, final lunar mushrooms or production Selenite art. No external texture or generated raster asset was added.

Native dimensions: full cluster `0.16×0.12×0.16` world units at local y `0.09`; empty patch `0.17×0.025×0.17` at y `0.015`; release square `0.045` per side; boundary radius `2.025` by default at floor offset y `0.025`, with 32 separated perimeter arcs. Cluster anchor offsets and the mushroom ground origin supply pivots. These visual meshes have no collision or HP, retain nearest filtering and depth occlusion, and are persistent required cues. They do not consume optional quality/density budgets. Existing scenery still owns physical occlusion/collision. Required falling markers derive from field age without gameplay RNG.

The states available/releasing/active/thinning/spent share one supply owner. Spent clusters retain readable empty patches; a remaining full cluster displays active gating while its mushroom's field prevents spending. A future authored mushroom kit can compose art around these stable anchors; actual final artwork and crowd readability still need portrait review.

## Verification on Godot 4.7.2

[The targeted fixture](../../tests/spore_field_smoke.gd) passed 53 headless checks, then 54 graphical checks including a saved actual `540×1170` portrait image with a `270×585` nearest-filtered world and shared orthographic `7.2 KEEP_WIDTH` camera. Checks cover real direct-player primary/blast costs and unchanged zero-hit publications, independent mushrooms, same-action/quick-followup/reentrant gating, actual LOS and aim geometry, zero environmental HP/reload effects, one actual living-enemy damage/reload result, paused release/thinning/expiry, malformed atomic rejection and silent JSON restoration.

Ignored evidence: `.cinder/spore-field-test.log`, `.cinder/spore-field-engine.log`, `.cinder/spore-field-portrait-test.log`, `.cinder/spore-field-portrait-engine.log`, and `.cinder/spore-field-portrait.png`. The inspected image shows the two broken boundaries and original lab actor; it is a shared cue fixture, not authored mushroom-room art or human playtesting. The sandboxed graphical launch exited 250 before a log; the same queued graphical command ran successfully with approved host access. No lock-screen or native input manipulation was used.

```sh
python3 scripts/dev/dev.py engine --headless --path . --script res://tests/spore_field_smoke.gd
python3 scripts/dev/dev.py engine --path . --script res://tests/spore_field_smoke.gd -- --spore-capture=res://.cinder/spore-field-portrait.png
```

Enemy cancellation/retreat, field overlap/avoidance, wall/floor-safe movement, ordinary escape after spent supply, real authored Act 1 encounters, human input and device testing remain unverified by this seam. Those require the separate motion consumer and subsequent targeted fixtures.
