# Untyped native discovery — inert experiment

Source-only preparation, 14 October 2026. Nothing here has been parsed or run by Godot. Production Route remains the exact `2bdfd3ea…` original. No speedup or gameplay acceptance is claimed.

`candidate.patch` replaces only the traversal prefix of `_collision_signature` with a fresh `_collision_candidates` call and adds two private static helpers. Every existing per-collider predicate, property/shape read, error string, 256-collider limit, final sort and codec validation remains literal. `collector.gd.txt` is the same 56-line helper insertion for review. Both full Route copies retain their original global class declaration; the fixture checks their sealed SHA-256 values before compiling trusted text with only that declaration removed.

The helper calls `find_children("*", "", true, false)` anew, classifies native PhysicsBody3D/GridMap/CSGShape3D candidates, filters every ancestor edge against the ordinary-child interval, and sorts candidate-only ancestor-index tuples in reverse-sibling parent-first order. It explicitly includes the invocation root. Its data is local to this invocation; no membership, world, property or acceptance result survives it. Internal bodies and all descendants of internal ancestors stay invisible, while the original downstream shape-owner enumeration still includes internal shapes belonging to a visible body. The empty type bypasses native find_children's Script metadata fallback.

`discovery_differential.gd` compares actual instance-ID order with the literal original iterative discovery prefix on every signature case, plus explicitly authored nested orders. It compares nonempty exact JSON of the **full original Route** against the candidate on the same native world, and independently requires each intended original result/error. Coverage includes:

- Native/scripted subclasses, root candidate, an explicitly internal search root, ordinary ownerless nodes, 800 decorations, and internal FRONT/BACK ancestor subtrees.
- Nested colliders and parent/child versus reverse-sibling competing error precedence.
- Actual distinct SubViewport World3D, foreign generated/moving scenery, layer-zero and other non-scenery layers, GridMap and CSG collision toggles, and same-world scenery outside `world_root`.
- Actual shape/transform/disabled-owner/layer/reparent changes between fresh guards, internal shape owners, queued deletion and cleanup.
- Exactly 256 supported colliders, 257 refusal, and a generated-collision offender visited before or after the 257th accepted collider.

The optional prototype does **not** preserve arbitrary resource behavior: built-in recursion and materialization happen before any GDScript fallback. Internal subtrees are traversed natively even though their candidates are filtered out. Original early return may avoid materializing later subtrees; this candidate cannot. There is no invented visit/depth/output limit. Unexpected ancestry/edge inconsistency falls back to a fresh original iterative candidate walk; that fallback cannot recover native stack exhaustion, out-of-memory, wrong-thread engine refusal or failures before find_children returns. Forced inconsistency and arbitrary custom native/ScriptExtension observers are not exercised. Ordinary GDScript between-call mutations do not prove those behaviors. These limits keep this an experiment pending Root's decision.

Integration can freeze this folder plus the ordinary literal preload/UID dependencies using its existing bounded runner; no new framework or source bank is supplied. Canonical queue command forms, from the integration checkout (not executed here):

```sh
python3 scripts/dev/dev.py engine --path . --headless --script res://.cinder/spore-native-discovery-prep/discovery_differential.gd --check-only
python3 scripts/dev/dev.py engine --path . --headless --script res://.cinder/spore-native-discovery-prep/discovery_differential.gd
```

Root's existing own-process 90-second bound should wrap each job. The script-only check does not compile dynamically loaded Route text; the actual fixture does. Retain real parser/runtime/cleanup failures. A subsequent uninstrumented original/candidate Crossed pair requires Root selection/freezing and actual nineteen-packet witnesses; do not infer timing from this differential or rerun unrelated accepted levels.

The source-only host seal verifies the exact inverse transformation, unchanged original downstream guard suffix and current production hash. `manifest.json` pins all supplied inputs and the retained prior differential used as a starting fixture. No engine, import, active source, Git, queue, mailbox or other-owner mutation was performed during preparation.
