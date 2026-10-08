# A2-L3 B02 Handling-Machine visual

Status: cosmetic revision 2 is statically reviewed and awaiting the owner's
new native portrait run. The prior TEST ONLY component run passed 41 checks
and staged shared-Game asset capture passed 48 checks, with clean exits; these
results precede this visual revision. Review of its seven B02 frames found the
central low opening and Place plate hidden, the held Reach claw indistinct,
and local arm disengagement difficult to recognize. Those presentation
failures prompted the correction below. No corrected-native result, actual
boss attack, smoke, route or whole aggregate acceptance is claimed here.
The parent owns B02 gameplay, phase transition, transport and engine checks.

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

Revision 2 removes the forward 120-degree sectors from the belly and canopy,
retaining rounded rear/side facets, their exposed metal edges and rivets. This
is an authored open work bay adapted from G10's exposed operator and tooling;
it adds no hole to the floor or collider. The operator moves up and back into
that bay, leaving the unchanged central low-joint source below it. The tool
shoulder moves outboard, held Reach and Place tools occupy opposite sides,
and the Place plate receives restrained metal edge trim. Defeat leaves an
empty framed socket and detached lower lever outboard, while its Place plate
remains grounded at the source. No new action, cue glyph or emission state is
introduced.

## Native scale, pivot and bounds

This is procedural 2.5D mesh artwork, not an extracted concept sprite sheet.
Inherited nearest-filtered 32×32 metal and 16×16 rubber cluster textures use
the existing rust/black/ivory family; the shared player remains 48×64 at
0.0225 world units per texel. No new renderer, palette, shader or player scale
is introduced. Parent/source view validation must establish the final apparent
pixel scale at native 540×1170. The prior native scale was inspected at that
resolution; the corrected open bay and tool silhouettes still require a new
capture.

The visual root is the actual floor-level low-joint source, with unit scale,
zero local rotation and fixed local +Z. The parent plans world source
`(0,0,-35)`, Reach length 3.8, and Place circle origin `(0,0,0)` with
radius 1.1. The parent binds physical floors,
footprint, ordinary-primary target and source/art framing; this visual has no
collider, body, hitpoint, HP, target group or independent contact damage.

| Construction | Static envelope in local world units |
| --- | --- |
| Five support feet | Centers at `(-.98,.045,.59)`, `(.98,.045,.58)`, `(-1.07,.045,-.30)`, `(1.07,.045,-.33)`, `(0,.045,-1.12)`; inherited .16×.09×.20 foot boxes touch Y0. Largest corner radius is `sqrt(1.06²+.69²) = 1.264792`, below 1.30. Toe plates remain inside that bound. |
| Case/canopy | Case origin remains `(0,.81,-.23)`; open canopy lower radius .88, upper radius .59, height .19 at local case Y.35 gives maximum top Y1.255. The .895-radius retaining edge has the same open forward sectors. Rear/side facets remain inside radius 1.30; supports are unchanged. |
| Rounded operator | New head center `(0,1.05,.08)`, radius .25 and Y scale .80; top Y1.25. Dark eyes, beak and two groups of eight two-segment tentacles are retained within the open bay, with a rear saddle. Its projection no longer coincides with the ground mount; no humanoid torso/limbs. |
| Low joint | Coupler center `(0,.235,.194)`, size .40×.13×.04: top Y.30, below .35. Opening guards swing locally; the actual source/root and coupler do not move. |
| Reach | Active/recovery wrist `(0,.08,3.50)` and elbow `(.12,.36,1.76)`; zero-grip claw reaches at most Z3.776 by endpoint-plus-radius bound. Ground skid bottom is Y0. It never advances the logical 3.8 lane or creates a new footprint. |
| Place | Active/recovery plate remains .88×.08×.88 at `(0,.04,0)`, bottom Y0; defeat also retains that grounded center. Front/side brass edge strips remain within its .88 footprint. The parent circle remains the sole authoritative footprint. |
| Warning/lock | Reach lock wrist `(.84,.84,.32)` and elbow `(.68,1.06,.15)` hold the claw outside the canopy; elbow top is Y1.165. Place lock wrist `(-.55,.89,.29)` and elbow `(-.66,1.05,-.01)` hold the tilted plate outboard; plate-part corner bound is Y1.032397 and radius 1.228929. Warning interpolates supplied progress into those poses; its largest conservative plate radius is below the unchanged support radius 1.264792. |
| Local disengagement | Lower lever rests between elbow `(.91,.14,.10)` and wrist `(.61,.08,.63)`; the detached Reach claw has radial bound 1.181249 and skid bottom Y0. The empty socket remains on the original mount, with trim top Y.322; the original coupler/source are unchanged. |

These are analytic construction bounds, including foot/toe half-extents and
primitive radius allowances. With the shared camera offset `(0,18,13)` and
width 7.2, the revised head/coupler centers separate by about .5696 projected
world units (42.7 pixels at 540 width), compared with approximately 1.1 pixels
in the failed arrangement. This center separation does not establish complete
surface visibility. The unchanged supports still define the folded radial
envelope, and canopy top Y1.255 remains the overall upper bound. Actual Godot
mesh vertices, intermediate poses and corrected native projection remain
engine validation work.
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

Warning raises the selected tool outboard using the supplied progress; Reach
occupies the right and Place the left. Lock holds that exact prepared pose. Active
immediately plants the complete selected endpoint. Recovery keeps the same
ground plant at every supplied progress while guards expose the low coupler;
there is no inherited early arm withdrawal. Defeated hides the upper attached
lever/sleeve/rod, exposes the framed empty socket and rests the lower tool
outboard. The Place plate remains centered and grounded even when detached,
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

The directly affected owner checks are import/parse, actual revised vertex
bounds and deterministic quiet pose/material isolation, followed by the seven
B02 native frames. They must show the central recovery coupler, held Reach
claw, centered planted Place plate and locally disengaged arm/socket alongside
the actual shared Hero/HUD. Prior staged framing contained the assembly and
kept Hero torso/facing/feet readable, but did not establish those four asset
requirements. Individual tentacle strands and the rear fifth support may
merge or hide at portrait scale; the next native review must assess the
rounded operator, paired eyes, two bunches and distinct support family.

Actual ordinary-primary opening reach, source/cue/footprint/landing framing,
fixed source/feet during real actions, full recovery opportunity, actual smoke,
phase transition, whole-level transport and full route remain parent runtime
work. No human balance, all-pose, mobile, export or release claim is made.
The original seven-frame review is retained as a presentation failure baseline;
the prior 41/48 successful component checks do not override it.


## Corrected native result and scoped review

At preserved registration-adoptione664619, affected `a2_l3_asset_capture.gd --boss-only` passes **50/0 clean exit0**, seven actual540×1170 frames with actual source-local mesh vertices grounded/≤1.35m and quiet boss action/phase pose reconstruction. [Separate corrected record](evidence/A2-L3/index.json) preserves first48/10 material failure and the original teardown failure. Peer reviewed all seven, root Place-recovery/Reach-lock: the four obscuration/disengagement defects now pass in these staged poses, Hero face/torso/feet remain clear. Rear fifth support/fine strands merge; Place rear edge under mount and detached lever/right-support overlap remain fine limits. No actual cue/admitted attack/phase checkpoint/route/full aggregate or all-camera art claim. Existing actor41/0 retains originalsource31475/visualac74 provenance; gameplay gates/setter/restore contracts are unchanged, but that old result is not relabelled as a new visual test.
