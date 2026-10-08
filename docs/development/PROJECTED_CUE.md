# Projected required threat cues

`CinderThreatCue` has an additive opt-in presentation binding for one exact
`CinderReplayFootprint.plan(...).events` entry. Ordinary unbound cues keep
`threat-cue-1`, full canonical geometry, phase callbacks and null meshes after
clear. This adapter adds no capture custody, reservation, clock, damage,
equipment, floor membership or native LOS authority. The parent must first
validate the whole projection through `ReplayFootprint.projection_error`
against its original sealed Sequence and current actual world/floors.

```gdscript
var error: String = cue.projection_binding_error(event)
# A parent may prevalidate all event cues before its silent transaction.
if error.is_empty():
    cue.bind_projection(event)
    cue.present(original_cone, "warning")
var intact: String = cue.projection_error(event)
var copied_event: Dictionary = cue.projection_state()
```

Binding requires a live ready cue in fresh/clear state and occurs without a
callback or yield. Reentrant binding during `state_changed` rejects. The pure
preflight writes no diagnostics, nodes or resources; rejected binding retains
the previous state/binding without downgrading to ordinary meshes. Binding an
already active cue rejects. The parent uses `projection_error` for an existing
live binding, rather than calling the fresh/clear binding preflight again.

The exact event keys are `event_id`, `kind`, `slot_id`, `record_sequence`,
`at_s`, `record`, `floor_y`, `triangle_vertices`, `boundary_contours` and
`bounds`. Every contour contains `hole` and `vertices`, including its repeated
last/first endpoint. All data must be bounded closed finite JSON; public Player
record validation checks the original direct primary/blast record. ExactJson
identity retains numeric bits/types. The cue itself cannot establish that
caller-created clipping actually came from a current Footprint plan.

Fill stages consecutive encoded triangles directly. Every real outer and hole
contour edge drives a common-width boundary ribbon, intersected with the
projection's already inward filled triangle cells. Only convex intersections
are triangulated; no outer/hole contour is fan-filled, and decomposition seams
never become outlines. The accepted-cell inset keeps the native outline as
well as fill out of floor holes and scenery shadows. Each edge must retain a
nondegenerate native fragment or binding rejects conservatively. This can
reject otherwise valid but unusually thin/complex projections; it never hides
an unsupported required contour by substituting an ordinary footprint.

Coordinates are translated from encoded absolute positions to the original
source anchor before native Vector3 conversion. Existing lifts remain:
outline `floor_y + 0.025`, fill `floor_y + 0.021`, source marker at its original
recorded origin plus `0.029`. A transformed art parent does not rotate/scale
these top-level world meshes. The phase state retains the full original raw
cone/source; clipped triangles do not replace hit geometry. Source marker
shape and phase colors retain the existing warning → lock → active → recovery
grammar. Source visibility persists during recovery; the danger outline/fill
hide. Signals retain their prior order, defensive state copy, idempotence and
quiet `set_block_signals` behavior.

`projection_error(expected_event)` is pure. It checks exact event identity,
ready native parent/world custody, required classification, actual child
identity, transforms, inherited phase visibility, mesh/material identity and
native buffers. All staged source-phase meshes are guarded, preventing a later
phase from healing a mutated future marker. Native vertex/attribute/index/LOD
buffers, primitive/format metadata and AABB are read through ArrayMesh's
installed `_surfaces` serialization accessor; shadow/surface material/blend
shape substitutions reject. Renderer/material properties retain their native
values and resource identities, with only grammar-controlled albedo/visibility
changes allowed. The installed build's accessor reads the RenderingServer
surface buffers. [Godot source at ed1daf0bf, mesh.cpp](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/scene/resources/mesh.cpp#L1398).
The triangle and index-array surface construction follows the native
[ArrayMesh interface](https://docs.godotengine.org/en/stable/classes/class_arraymesh.html).
The source commit, rather than the current stable-doc label, identifies the
installed 4.7.2 build used for this integration.

Bound clear keeps hidden nonnull fill/outline resources and an intact empty
source ArrayMesh receipt. It permits explicit later binding only while custody
remains intact. Cancellation may hide broken children, but latches the broken
binding so clear/present/rebind cannot restore lost required authority. A valid
empty event can retain native empty ArrayMesh receipts; it cannot use null as a
fallback. The leaf fixture's caller-created empty event is a structural receipt
control and deliberately fails whole-plan authentication.

Additional presentation bounds are ±512 metres, 16,384 combined encoded event
vertices, 1,048,576 contour-edge/triangle pair tests and 131,072 native outline
vertices. ExactJson supplies independent total node/depth/byte bounds before
copying. Budget failures are pure preflight refusals. These limits establish
bounded work, not measured performance or unrestricted geometry support.

The new [projected_cue_smoke fixture](../../tests/projected_cue_smoke.gd)
passed **271 checks, 0 failures**, native exit 0 on installed
`4.7.2.stable.official.ed1daf0bf`. It uses real completed Player primary/blast
records, actual static Box floor holes/blockers and authenticated Footprint
plans. It checks native fill/outline hole and LOS exclusion, exact floor
placement under transformed parents, raw state, all phases/quiet callbacks and
native child/resource/vertex/index/LOD/material mutation refusal. It also
checks pure malformed/cyclic/object/nonfinite and bounded-work preflight,
nonhealing cancellation, defensive exact event copies and intact empty
structural receipts. No authored boss/level, damage consumer, screenshot,
human input, mobile or performance acceptance is claimed by this leaf. The
directly affected existing ordinary cue suite separately passes **82/0**; the
projected Playback consumer separately passes **467/0**. Their logs and declared
source subsets are preserved in the [portable evidence index](evidence/shared24-projected-replay/index.json).

The final scoped command was:

```sh
python3 scripts/dev/dev.py engine --headless --path . --log-file '/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/projected-cue-final.log' --script tests/projected_cue_smoke.gd
```

Final ignored evidence is `.cinder/projected-cue-final.log` and
`.cinder/projected-cue-final-sources/index.json`; the latter retains byte-exact
Cue, Playback, Footprint, fixture and UID sources. The final Cue SHA256 is
`2996af6fc2bc4314599615a5753f1d4baf7940dce91a2f8e262f018e64b36cbb`;
the final fixture SHA256 is
`9cf8817021744b741c1e56363c2f9452243bce03c9de4e4f89ba0c627b039f81`.
There were no script/parse/GDScript errors or null-material teardown errors in
this final run. The native startup log still records the macOS certificate-read
sandbox diagnostic at `platform/macos/os_macos.mm:1035`; this result does not
claim a completely diagnostic-free engine launch.

Earlier logs and frozen sources remain separate:

| Local log | Native result | Interpretation |
| --- | --- | --- |
| `projected-cue-first.log` | 270 checks / 3 failures, exit 1 | The LOD corruption fixture supplied LODs to a nonindexed surface; Godot ignored that request, leaving the actual receipt unchanged. |
| `projected-cue-second.log` | Reported 270 / 0, exit 0 | **Excluded from acceptance**: the added fixture assertion called an internal method not bound to GDScript and emitted a script error. |
| `projected-cue-third.log` | 271 / 0, exit 0 | Native LOD retention and all guards passed; deliberate surface-override deletion emitted a dummy-renderer teardown diagnostic. |
| `projected-cue-final.log` | 271 / 0, exit 0 | Same runtime and assertions; fixture-only cleanup removes the deliberately injected override after completed fault/latch assertions and flushes the paused native frame before deletion. |

The installed RenderingServer accepts supplied LODs only when a base index
array exists and a LOD has fewer indices than that base. The corrected fixture
installs valid full base indices plus a smaller LOD, then verifies the actual
`_surfaces` index count and LOD bytes before asserting custody rejection. The
production guard was unchanged across these runs. [Installed source,
rendering_server.cpp](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/servers/rendering/rendering_server.cpp#L1232).
