# O1 authored variant — bounded source audit

**Source review only; parsing, native behavior and visuals remain unexecuted.** No active checkout, engine, parent or codec change. This review adds no route, view, test or approval gate. Exact joins and findings are in `source-audit.json`.

| Runtime path | Authored SHA256 | Greybox relationship |
| --- | --- | --- |
| `scripts/acts/act1/salvage_circuit_layout.gd` | `6a395b291698d7f1218aca81e34b53578dea3c5c772ce8b70d5afd9ccac43aec` | Byte-identical |
| `scenes/acts/act1/a1_o1.tscn` | `f8e78a67fd38a0099e50ae78971044ec396bd78c05ba24bc28fd17ad39659130` | Byte-identical |
| `scripts/acts/act1/salvage_circuit_part.gd` | `f6f19819f221ad120548f1948aab54c6e5c7df98307660d3ae77e00a2b9b72ec` | Fragment meshes/riveted material differ; eleven contact/state/bounds API bodies exact |
| `scripts/acts/act1/salvage_circuit_scenery.gd` | `d12a2500bbc9dbe8aa2fc78224b09bddd49f075aa135ce84e71796e2017e45b6` | Adds quiet L2 tile/flats and clockless hatch seams around unchanged L5 capsule |

The entire layout/scene fixes the same IDs, positions, Floor/CollisionShape3D, spawn, low edges and hatch/contact dimensions. Part `configure`, `set_state`, `presentation_state`, cue/contact accessors and all three native bounds methods are exact between variants. The actual shared Player mask is4; contacts are stationary Areas, not attack receivers. Each leaf constructs its retained shape/mesh/material objects once. Its state setter changes visibility, not physical bindings. Fresh worlds naturally have fresh identities; this audit does not claim cross-world identity equality.

Complete bounds fit the agreed leaf budget: every visible fragment mesh, native contact and visible shared cue contributes to a conservative world-AABB8; the capsule adapter similarly includes every unchanged renderer point plus visible seams. Three parts and capsule consume32 points. Separate native contact/cue corners remain available. Nonfinite input refuses. No mesh or rivet is dropped and no containment margin is widened. Parent source/footprint/Hero/landing/hatch contributions remain additional; the parent was not audited. Whole scenic floor/flats bounds may crop and are not a mandatory local framing certificate. Camera binding uses the actual current viewport camera without moving it.

Available/active parts stay visible; spent hides the fragment. The parent records collection and controls the shared **contact** cue. Damaged hatch keeps the existing closed door plus two dark latch seams; repaired hides seams and selects the existing open-hatch pose. Real hatch eligibility remains separate. No assembly, timer, flight, cord/clinger step, reward or input is added.

G17/ENV02 and G14 pixels were actually inspected during preparation: separated finless capsule components, rivets, round hatch, painted flats and broad lunar floor informed this adapter. They remain contemporary generated references, not runtime atlases or historical production sheets. Existing L2/L5 renderer, material PNG and reference pins are unchanged. Notes record native scale, ground pivots, collision/occlusion, state and readiness.

Three source-only visual uncertainties remain:

- The nose cap is an upright tapered cylinder onY, while the referenced capsule’s rounded nose followsZ. It is a simplified fragment pose, not an exact extracted nose. [Godot CylinderMesh properties](https://docs.godotengine.org/en/stable/classes/class_cylindermesh.html) support that geometry description; actual appearance is unverified.
- The torus band centre isy.11 with radii.27/.38 and no support mesh. A small floor gap is plausible under the conventional torus section; actual native AABB is unmeasured. [Godot TorusMesh radius definitions](https://docs.godotengine.org/en/stable/classes/class_torusmesh.html) establish the parameters, not a gameplay grounding result.
- The outer flat reserves reach x±6.048; the capsule and open door occupy the hatch approach. Central parts sit farther inward, but outer-landing or hatch/Hero occlusion still depends on the real camera. These uncertainties belong in Root’s already planned brief art inspection, without a separate full-view or route requirement.

Authored sources remain staged and frozen at the hashes above. No source-only acceptance, native/optical pass, full playthrough, all-kit balance, performance or mobile result is claimed.
