# Salvage Circuit source, reuse and readiness

**Source only:** these new O1 files have not been parsed, imported, run, integrated or inspected in portrait. Root owns promotion and the small functional greybox checks. All coordinates, dimensions and source placements below are authored hypotheses, not measured camera/reach/balance results. No UID is invented. Accepted L2/L5 files and existing PNGs remain unchanged.

Canonical A1-O1 research: three capsule parts collected **by contact in any order**, then a repaired hatch; parent A1-L2, one checkpoint before the final familiar exercise, completion stamp with no permanent stat increase. The parent owns collection eligibility, its full collected-ID set, encounter source admissions, cue notification ordering, shared Scheduler time, checkpoint/Save/Continue/Retry, actual hatch contact and optional completion. There is no carrying button, assembly minigame, attackable part, new input, equipment change or ability introduction.

## Actual references inspected

- Selected `docs/concept-art/act1/environments/02-crater-gardens.png` (G17/ENV02), SHA256 `b483405beccb0b282e66f2294ab8616e5e74b94f82e70b7bc74fcdbc5a87d3ea`: the optional inset shows the same painted rock ground around separated capsule front/mid/rear pieces; normal scenery is visually distinct from the drawn animated floor warning. Broad white rock streaks, black creases, finless riveted shell and round hatch informed the small source additions. Its fragment shapes do not authorize carrying or assembly gameplay.
- `docs/concept-art/act1/props/earth-launch-modular-kit.png` (G14), SHA256 `a4c2a0e1e2f5e9bcf8424edfb3a43c176a9c3b3768d0e5e6bae6015eacb3ad2d`: inspected the squat finless body, rounded nose, riveted bands and round porthole hatch/open gap. These are contemporary generated game reference boards, not runtime atlases or authenticated 1902 production sheets. No pixels/captions were cropped, traced or imported from either board.

The campaign concept, shared style/motion guide, asset reuse guide, Act1 concept/source style guide and adaptation notes govern this draft. The earlier root crater-garden exploration remains superseded. The shared traveller's headwear, clothes, weapon, collision body and carried equipment are untouched.

## Reused production kit

| Family / actual source | Native scale and pivot | Role and remaining scope |
| --- | --- | --- |
| Quiet silver floor: `assets/acts/act1/lunar/environment/floor_silver_tile.png`, inherited L2 floor material vocabulary | 64×64 pixels; 0.024 world units per pixel; 1.536-world repeat. O1 plane14×16 centred `(0,.002,0)` over continuous physical support | Quiet static paint, nearest filtering, normal depth, alpha-scissor margins reveal the115/255 base. No collision, interaction edge, warning or clock. New placement unverified. |
| Painted flats: unchanged `rock_flat_low_a.png` / `rock_flat_low_b.png` and `lunar_scenery.gd` `_cutout` implementation | Each96×56, bottom-centre `(48,56)`, 0.024 step, whole billboard reserve2.304×1.344. Four local copies at x±7.2/z±5.8 | Sparse outside-edge scenery, normal depth and no colliders/cues. `world_corners()` uses the supplied actual camera basis; full scenery may crop and is separate from the required local framing union. Occlusion still needs actual portrait inspection. |
| L2 visible low-edge convention: `crater_gardens_layout.gd` | Four matching Box meshes/Box colliders, height.4 at y.2; O1 lengths fit14×16 support | Physical outer boundary, collision layer1/mask0, fully visible low base. No central obstacle/secret progression wall is added. |
| Finless capsule: unchanged `living_moon_capsule.gd`; `launch/riveted_plate.png` | Existing scale1, floor pivot `(0,0,0)`, long axisZ, nose−Z/rear hatch+Z, radius.84 and body length2.65. O1 origin `(0,0,2)` | Cosmetic body only; no collider/contact/clock/actor. Existing hinge API supplies closed/open pose. Parent-bound actual camera affects artwork only. No flight, cord or clinger progress is requested in O1. Existing L5 evidence is not an O1 optical pass. |

`REUSED_SOURCE_PINS.json` in the scratch package records the exact existing source/PNG/reference hashes. The accepted parent renderers are reused without editing them; this optional adapter does not merge old manifests or imply every historical readiness label is a current O1 result.

## Small additions and native bounds

All three fragment roots have ground pivot `(0,0,0)` at their authored positions. They are ordinary depth-tested low meshes, not solid blockers or attack receivers. The fragment body is visible in available/active presentation, hidden when spent; the parent's shared `CinderInteractionCue` supplies the existing available/active/spent **contact** marker. The leaf changes no cue state automatically, and has no pulse/time loop or body-entered callback.

| Stable ID | Root position | Authored mesh reserve / states |
| --- | --- | --- |
| `nose-cap` | `(-2,0,0)` | Rounded low cap, radius.36/height.52, small eight-rivet rim; existing riveted material. Available/active visible, spent removed. |
| `rivet-band` | `(2,0,0)` | Horizontal recovered band, torus inner/outer radii.27/.38 centred y.11, eight small rivets. Same state meanings. |
| `hatch-disc` | `(0,0,-2.7)` | Round low disc radius.38/height.10, dark porthole radius.14, eight rivets. Same state meanings. |

Each retained contact `Area3D` has layer0/mask4 (actual shared Player layer), stationary native `BoxShape3D(.9,1.2,.9)` centred local `(0,.6,0)`. Thus its authored local contact reserve is x/z±.45, y[0,1.2]. `contact_corners()` reads the actual shape size and `CollisionShape3D.global_transform`; `world_corners()` includes this reserve, each visible native mesh AABB and the actual shared marker mesh AABB when visible. These functions provide native observation points after attachment, not source-only evidence that containment has passed.

Damaged/repaired hatch is a clockless O1 adapter: two shallow dark crossed latch seams in front of the existing closed door are visible while damaged; repaired removes them and calls the existing open-hatch pose. The seam root is capsuleorigin+`(0,1.02,1.57)`; each Box is1.1×.065×.025 with z-rotation±.32. No assembly, collider or new interaction marker is created by this art. `capsule_world_corners()` reports the existing capsule's complete actual visible mesh bounds plus those seams. The actual hatch remains a **separate stationary** parent-owned `Area3D`, centred `(0,.65,3.8)`, native Box1.6×1.3×.9 (world x±.8,y[0,1.3],z[3.35,4.25]), layer0/mask4. Its shared contact cue is at the same ground pivot; closed/damaged art must not grant completion eligibility.

The scene retains Floor/CollisionShape3D, native Box14×1×16 centred `(0,-.5,0)`, and PlayerSpawn `(0,.1,5)`. `SAFE_RECT=Rect2(-6.5,-7.5,13,15)` is proposed support metadata, not a private movement clamp. Familiar sources are specified only in layout data: circuit rusher`(-1.8,.005,-1.5)`, final rusher`(1.2,.005,0)`, impact`(0,0,-2.4)`/radius.85. The parent constructs their genuine actors/source/shape/cues and owns warning→lock→active→recovery. This art creates no imitation threat footprint.

## Composition API

- `Act1SalvageCircuitLayout.build_geometry(level)` retains the scene's authoritative Floor/CollisionShape3D and constructs local Parts/HatchContact/Scenery once. Returns `floor_collision`, `parts`, `hatch`, `hatch_collision`, `hatch_cue`, `scenery`. A duplicate/missing support composition is refused rather than replaced.
- `Act1SalvageCircuitPart.configure(id)` runs before tree attachment; `set_state(state)` changes renderer only. `presentation_state()`, `get_cue()`, `contact_area()`, `contact_collision()`, `contact_corners()`, `cue_corners()` and `world_corners()` expose the actual leaf without copying any gameplay state machine. Parent connects/filter contacts against the actual shared Hero and records collection before cue callbacks.
- `Act1SalvageCircuitScenery.set_repaired(bool)` / `presentation_state()` are immediate/clockless. `set_presentation_camera(actual_camera)` delegates to the existing capsule artwork binder. `capsule_world_corners()` supplies the relevant local hatch art; whole `world_corners()` also includes the floor/flats and is deliberately not the mandatory source/landing certificate.

Initial greybox may hide this decorative Scenery while retaining the same support/contact geometry. Root combines these leaves with the separate `salvage_circuit.gd` CinderLevel parent and codec, then performs focused loading/mechanics/transport/contact/cleanup and brief representative visual work through the shared queue. Parsing, all native callbacks/bounds/shape registration, dash opportunities, source/landing readability, any-order contact, damaged/repaired optical feedback and O1 acceptance remain **unexecuted**. Full playthrough, all-kit balance, sustained performance and mobile/export are not claimed or added as gates.


Complete framing extents are compacted **conservatively**, not truncated: part `world_corners()` includes all currently visible native fragment mesh AABBs plus the actual retained contact and shared cue bounds, then reports eight world-AABB corners. `contact_corners()` and `cue_corners()` remain independent native observations. Capsule adapter `capsule_world_corners()` includes every point returned by the unchanged renderer and any visible damage seam before the same eight-corner union. Nonfinite inputs refuse with Vector3.INF. Three complete part unions plus the complete capsule union therefore consume32 points; source/footprint/Hero/landing/hatch points remain the parent's additional unchanged responsibility under the shared224 limit. This can expand the guarded extent and never loosens containment or drops a rivet/cue.
