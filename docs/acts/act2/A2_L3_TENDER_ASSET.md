# A2-L3 Canister Tender visual — initial production

Original procedural presentation for **C102 / A2-E2**, the invented Canister Tender. Root owns Act2 gameplay and the requested shared bounded-smoke consumer. This file supplies geometry and deterministic cosmetic poses only.

**Readiness:** authored, source reviewed and construction bounds checked; no engine import, actual mesh-bound measurement, native portrait, damage gate, smoke consumer, whole-level or acceptance result yet. Root will validate directly affected poses and current camera/source/landing composition. No source board is used as a runtime atlas.

## Source and interpretation

Visually inspected [G16 technology board](../../concept-art/act2/props/martian-technology.png) (launch-tube/dark-canister/steam studies; SHA256 `d7bb3d36baf62bf424387f436dbc5145fdf6504753d7b45e91815569501b535b`) and [G07 smoke/ruined-house board](../../concept-art/act2/environments/black-smoke-ruined-house.png) (impact canister/oxidised industrial material; SHA256 `35070da144b4ae8f64916c9b568685a7fd2744f1eb8526ae6b11dd37f0a59fcb`). Read [L3 concept](../../ACT2_CONCEPT.md#a2-l3-black-smoke-and-the-ruined-house--under-the-machines), [selected-art boundaries](../../concept-art/act2/README.md), category READMEs, generation prompts, equipment/style/reuse rules, and [research records](../../reference-library/act2/research/entities.json): C102/A2-E2 derives from T03/T05; T05 describes a thick tube and impact-broken canisters releasing heavy low-pooling vapour without explosive detonation.

The two-skid compact cradle, reload mount, shutters, pose progression and short canister racks are original game interpretations. There is no separate selected Tender chassis board or authenticated Martian caste. The rig has no mirror/three-legged Scout build, no five-legged Handler build and no humanoid pilot. It communicates industrial smoke logistics through its tube and canisters; it creates no smoke or steam itself.

## Resource record

| Asset | Native scale/pivot | Collision and occlusion | States/reuse |
|---|---|---|---|
| Two-skid cradle, four short braces/pads | Feet/root `[0,0,0]`; skids1.22m long,0.15m wide; pad endpoints bounded by X±0.69,Z±0.56 | No collider, target group or movement authority. Grounded skids/pads remain fixed through every pose; broad geometry is eligible for inherited per-instance triangle cutaway | Quiet idle/approach, held support during warning/lock/release, spent deck drop. Original C102 family; later documented Tender roles can reuse after review |
| Hollow tube, muzzle lip, breech and rivets | Tube pivot `[0,0.635,-0.13]`; shell length0.82m/radius0.162m; raised X angle−0.54rad; muzzle outer radius0.185m | No projectile, aim sampler, footprint or damage. Dark recess and thick ring identify the tube; broad surfaces cut away over supplied hero bounds, small fasteners retain outlines | Raise, hold, recoil, lower/reload, spent. G16/T05-inspired tube/canister family |
| Two canister racks | Centres X±0.29,Y0.44,Z−0.43; canister radius0.106m/height0.40m | Decorative supply silhouettes only, no pickup, ammunition counter or interaction | Fixed through phases; low dark cylinders/valves distinguish logistics silhouette |
| Low reload coupler and shutters | Mount pivot `[0,0.22,0.25]`; coupler centre `[0,0.225,0.325]`, radius0.102m | Cosmetic opening only. Actor root stays the parent-owned ordinary-primary point; opening visibility does not authorize damage. Broad shutter/coupler faces share cutaway; no reserved cue glow | Closed before release; fully exposed for all recovery progress and spent state |
| Materials/cutaway | Original deterministic32px oxidation and16px rubber textures; nearest filtered; world meshes at shared apparent pixel scale | Inherited immutable texture generation and isolated per-panel material copies. Fixed mesh topology; no dynamic shape cache or per-pose allocation | Parent hit-flash boolean only; inherited `apply_readability`/`clear_readability` own disposable camera context |

Construction envelope: support pad corner radius **0.888650663m**, conservatively declared≤0.895m (required≤0.95m). Tube raised muzzle envelope **1.084162941m** above feet, conservatively declared≤1.10m (required≤1.12m). Other body/rack parts are lower and inside the support envelope. These are analytical construction bounds, not an engine all-mesh/all-pose measurement. Root yaw rotates within the same ground radius. No pose moves the actor/root or skids, and the spent tube stays above ground.

## Exact parent interface

Script: [canister_tender_visual.gd](../../../scripts/acts/act2/canister_tender_visual.gd), class `Act2CanisterTenderVisual`, subclass of the existing `Act2RayScoutVisual` helper/restore/cutaway family. Overridden `_build` creates only the Tender; it does not invoke the Scout build.

- `present(phase: String, progress: float, direction: Vector3, hit_flash: bool = false) -> void` is an alias of inherited `pose` with the same arguments.
- `pose_snapshot() -> Dictionary` returns portable cosmetic fields `phase`, `phase_progress`, `direction` (three finite numbers for valid caller input), `body_yaw`, `hit_flash`. This is not a consumer/save authority or clock.
- Inherited `get_body_yaw() -> float`, `restore_pose_error(phase, progress, direction, body_yaw) -> String`, `restore_pose(phase, progress, direction, body_yaw, hit_flash = false) -> bool` retain the existing validated quiet restoration seam. The parent converts a portable direction triple back to `Vector3`.
- Inherited `apply_readability(camera: Camera3D, hero_bounds: Array[Vector3]) -> bool`, `readability_state() -> Dictionary`, `clear_readability() -> void`; required camera is live, same-world and orthographic, with3–16 finite visible world-space hero silhouette points.
- Canonical phases: `idle`, `approach`, `warning`, `lock`, `active`, `recovery`, `defeated`. **Spent** is the `defeated` presentation, not a new consumer phase. Warning raises the tube; lock holds its angle/yaw; active adds bounded recoil; recovery lowers the tube and exposes the mount for its whole supplied window. The parent provides all phase/progress/direction/flash data from its authoritative clock.

Example root calls: instantiate/add the rig under the owned Tender actor; call `present` from the actual consumer state, refresh inherited readability after hero/camera changes, snapshot the actor-owned phase/progress/yaw fields, and use inherited `restore_pose` during quiet aggregate commit. No process/physics callback, timer, random state, signal, `TIME` shader, player control, shared consumer fork or damage logic is introduced.

## Remaining limits

Current construction has no native proof of tube silhouette, reload opening, hero overlap, source/cue/dry-landing framing or all-yaw vertex bounds. Small rivets/valves may merge at270×585 subviewport scale. Caller input/phase and damage-window custody remain the actor/consumer's responsibility; inherited pose error text still names the Scout helper family. L1/L2 provenance is retained without editing their files. Reuse of the helper technique does not transfer previous L1/L2 tests to this new Tender geometry. A2-L3 smoke, encounters, boss and checkpoint production remain root-owned work.
