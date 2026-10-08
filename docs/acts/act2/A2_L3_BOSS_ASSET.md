# A2-L3 B02 Handling-Machine visual

Status: new owned procedural visual draft, statically reviewed. No import,
engine, full encounter, snapshot or native portrait result is claimed here.
The parent owns B02 gameplay, phase transition, transport and later validation.

The canonical boss is one five-legged industrial machine with a reachable
planted tool joint. Its two authored actions are Reach and Place. Local arm
disengagement opens the ruined-house exit; this asset does not portray killing
the Martian operator or add a sweep, crescent, third attack or helper wave.

## Sources and reuse

Visually inspected the selected [G10 v2 handling-machine board](../../concept-art/act2/bosses/handling-machine-boss-v2.png)
and [G19 ruined-house game view](../../concept-art/act2/gameplay/02-ruined-house-gameplay.png)
at original resolution. G10 supplies the low broad five-support silhouette,
rounded head-body, dark eyes, two tentacle bunches, riveted canopy, sliding
joints, disc-muscle sleeves and grapple tooling. G19 supplies the visible low
ordinary-melee opening. Illustrated sweeps, red weed, rubble and broad scenery
do not authorize additional B02 attacks or hazards. Superseded humanoid G10 v1
is not used. Canonical research identity is B02/T08/T11, with rounded operator
anatomy C98/T15; the opening and combat scale are game adaptations.

The [Act 2 concept](../../ACT2_CONCEPT.md#a2-l3-black-smoke-and-the-ruined-house--under-the-machines)
and [canonical level record](../../reference-library/act2/research/levels.json)
remain authoritative. The nine-minute target and illustrated scale are not
runtime timing or world-dimension measurements.

[handling_machine_boss_visual.gd](../../../scripts/acts/act2/handling_machine_boss_visual.gd)
extends the corrected [Salvage Handler visual](../../../scripts/acts/act2/salvage_handler_visual.gd).
It explicitly reuses that family's native primitive/material, articulated
support, segment fitting and triangle-cache helpers, plus the inherited Scout
per-instance actual projected overlap/depth cutaway. It does not build or
uniformly scale the compact Handler rig. New construction has a wider faceted
canopy, five redistributed grounded feet, larger exposed rounded operator,
folded secondary manipulators, a three-finger claw and a selectable work plate.
The lower coupler is rebuilt below the regular Handler's coupler height.

## Native scale, pivot and bounds

This is procedural 2.5D mesh artwork, not an extracted concept sprite sheet.
Inherited nearest-filtered 32×32 metal and 16×16 rubber cluster textures use
the existing rust/black/ivory family; the shared player remains 48×64 at
0.0225 world units per texel. No new renderer, palette, shader or player scale
is introduced. Parent/source view validation must establish the final apparent
pixel scale at native 540×1170.

The visual root is the actual floor-level low-joint source, with unit scale,
zero local rotation and fixed local +Z. The parent plans world source
`(0,0,-35)` and unchanged Reach length 3.8. The parent binds physical floors,
footprint, ordinary-primary target and source/art framing; this visual has no
collider, body, hitpoint, HP, target group or independent contact damage.

| Construction | Static envelope in local world units |
| --- | --- |
| Five support feet | Centers at `(-.98,.045,.59)`, `(.98,.045,.58)`, `(-1.07,.045,-.30)`, `(1.07,.045,-.33)`, `(0,.045,-1.12)`; inherited .16×.09×.20 foot boxes touch Y0. Largest corner radius is `sqrt(1.06²+.69²) = 1.264792`, below 1.30. Toe plates remain inside that bound. |
| Case/canopy | Case origin `(0,.81,-.23)`; canopy radius .88, height .19 at local case Y.35 gives maximum top Y1.255, below 1.35. Hood retaining edge is a separate .895-radius mesh; all static body/support geometry stays inside the 1.30 radial support envelope. |
| Rounded operator | Head center `(0,.92,.67)`, radius .25 and Y scale .80; top Y1.12. Dark eyes and two groups of eight two-segment tentacles remain exposed in front of the canopy lip; no humanoid torso/limbs. |
| Low joint | Coupler center `(0,.235,.194)`, size .40×.13×.04: top Y.30, below .35. Opening guards swing locally; the actual source/root and coupler do not move. |
| Reach | Active/recovery wrist `(0,.08,3.50)` and elbow `(.12,.36,1.76)`; zero-grip claw reaches at most Z3.776 by endpoint-plus-radius bound. Ground skid bottom is Y0. It never advances the logical 3.8 lane or creates a new footprint. |
| Place | Active/recovery wrist `(0,.04,0)`; .88×.08×.88 plate is centered on the actual source and its bottom is Y0. The parent circle is the sole authoritative footprint; plate artwork does not set its radius. |
| Warning/lock | Main joint top is at most 1.205. A conservative bound enclosing the whole tilted plate group gives maximum top Y1.272647, below 1.35; this bound includes combinations of extrema that individual meshes do not occupy. |

These are analytic construction bounds, including foot/toe half-extents and
primitive radius allowances. Actual Godot mesh vertices, all intermediate
poses and current fixed-camera projection remain engine validation work.
Bounds assume the parent's authored unit-scale, unrotated source transform.

## Parent pose and quiet restore protocol

```gdscript
set_action(action: String) -> bool  # exactly "reach" or "place"
get_action() -> String
pose(phase: String, progress: float, direction: Vector3, hit_flash: bool = false)
restore_pose_error(phase, progress, direction, body_yaw) -> String
restore_pose(phase, progress, direction, body_yaw, hit_flash = false) -> bool
restore_boss_pose(action, phase, progress, direction,
                  body_yaw = 0.0, hit_flash = false) -> bool
apply_readability(camera: Camera3D, hero_bounds: Array[Vector3]) -> bool
clear_readability()
readability_state() -> Dictionary
```

Direction must be exactly `Vector3.BACK` (local +Z), body yaw exactly 0 and
progress finite within [0,1]. Existing pose phases are idle/approach, warning,
lock, active, recovery and defeated; approach is compatibility presentation,
not boss travel. Invalid restored input rejects before mutation.

The parent selects the accepted actual action with `set_action` before posing
the cycle. Selection works before `_ready` and persists across inherited
`pose`/`restore_pose`; neither function chooses an action. For a fresh restore,
the parent validates its complete saved action/phase first, then either calls
`set_action(saved_action)` followed by `restore_pose(...)` without yielding or
uses the atomic visual-only `restore_boss_pose(...)`. The latter validates
action and pose together before committing either. Action defaults to Reach;
it must not be inferred from an omitted saved action or recreated reservation.

Warning visibly raises and prepares the selected tool. Lock holds it. Active
immediately plants the complete selected endpoint. Recovery keeps the same
ground plant at every supplied progress while guards expose the low coupler;
there is no inherited early arm withdrawal. Defeated hides the upper attached
lever/sleeve/rod, exposes the disconnected socket and rests the lower tool,
while case, operator and five feet remain standing. It is local mechanical
disengagement. Short parked manipulators remain harmless fixed scenery.

The rig has no process/physics callback, timer, tween, scheduler, cue,
damage callback, player reference, reward or serialization. The parent drives
every phase and progress from actual authority. Changing action is a parent
commit, not an autonomous transition or a hit gate.

## Readability and remaining validation

Broad canopy/body/support/tool panels register through the existing
per-mesh isolated material cutaway. Material duplication preserves texture
and RGB; derived alpha uses the inherited .14 only when actual projected
triangles overlap the current hero bounds and lie in front. Eyes, tentacle
strands and small rivets retain source detail. Changing cylinder heights
refreshes the inherited cached triangle geometry before recomputing overlap.
Pose/quiet restore recompute current derived readability; opacity is not
saved. Camera reference is weak and the inherited exit hook clears it.

Parent must supply the actual hero billboard points and refresh them after
movement/current-camera changes, before damage presentation and after restore.
The parent must frame the current full source/art, complete lane/circle,
low joint, supported escape landing and ordinary-primary approach together.
This hero cutaway is not proof that the source or shared cue is readable.

Required owner checks remain: import/parse; actual vertex bounds at all seven
poses for both actions; deterministic pre-ready/fresh quiet action restore and
malformed refusal; two-instance material isolation; actual ordinary-primary
low-joint reach; fixed source/feet and complete ground plant through recovery;
native warning/lock/active/recovery/phase-two close counter/arm disengagement
at 540×1170 with current HUD. Sixteen individual tentacle strands and the rear
fifth support may merge or hide in the portrait view and need source review.
No passed gameplay, whole-level acceptance, human balance, all-pose, mobile,
export or release claim is made by this draft.
