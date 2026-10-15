# Royal Rehearsal runtime art

Source authored 15 October 2026 after the corrected greybox’s owner-reported **45 passed, 0 failed** result. This record covers only the small bell and station-marker addition. The initial source freeze was unparsed and unexecuted. A later owner-reported portrait run passed **18 native checks, 0 failed**, but inspection of its actual first-warning image found a visual failure: the centered bell/stand obscured the Hero torso and feet. The new rear-offset correction is **source-only, unparsed and unexecuted** pending a focused owner rerun. The earlier native pass does not establish visual acceptance.

## Source and inspected references

[Implementation](../../../scripts/acts/act1/royal_rehearsal_art.gd), [asset manifest](../../../assets/acts/act1/o3/manifest.json), [original reuse plan](O3_ASSET_REUSE.json) and [kickoff](O3_KICKOFF.md).

The art author opened the actual 1536×1024 pixels of [G19](../../concept-art/act1/environments/04-selenite-court.png) and [G15](../../concept-art/act1/props/lunar-grotto-and-court-modular-kit.png). G19 panel 8 shows a small dark wooden two-post stand, crossbeam and feet with a pale flared hanging bell. Its quiet floor roundels and G15’s radial star supply the station ornament. G19 panel 5’s active warning treatment is excluded. Full source hashes are in the manifest. These are concept references; no pixels were extracted, and their captions establish no runtime mechanics.

The mesh addition preserves the existing CourtArt floor, curtain, flats, crescents and radial ornament, native C32 guard family and shared traveller. No existing art, actor, cue or collider file was edited. The asset directory contains provenance for code-authored geometry; it has no new raster, sprite atlas or import dependency.

## Authored asset roles

The bell is 1.0 m wide, 1.5 m high and 0.4 m deep, with its scenic feet now at (-2.4, 0, -0.30), north of the unchanged contact anchor (-2.4, 0, 0). Dark joined posts, pale edge paint, a stepped twelve-facet flared body, dark underside and separate clapper preserve the small theatrical stand silhouette. The gap between its feet stays open. Available has an upright pale bell; active has a fixed 10-degree lean and offset clapper; spent has a muted bell and broad felt band. These are instantaneous state poses, with no animation timer, ringing sound, emitted signal or simulation authority. The existing host BellArea and shared contact cue remain responsible for interaction.

The six authored station positions each have a radius 0.4 m disc, 0.002 m thick, offset 0.012 m above the native floor. Only the host-selected current pair is shown. A low-contrast five-point star sits inside the closed muted disc; it has no segmented warning edge, countdown, pulse or active fill. Markers supply neither collision nor activation/attack/progress authority. The host may hide all markers after completion. Reusing the source positions does not make markers follow a guard after knockback.

All meshes use opaque, depth-tested, unshaded grayscale vertex colours with no shadow casting or texture. Native bitmap scale/pixel pivot is not applicable. World feet/ground pivots, bounds and material/state details are recorded in the manifest. The original contact-center portrait visibly failed traveller readability. Revised contact-center readability still needs an actual portrait check; moving overlap, remote cropping, all-loadout readability and performance are not established by the static source revision.

## Host API and framing

`Act1RoyalRehearsalArt.build_geometry_art(level: Node3D) -> Node3D` creates and attaches `RehearsalArt` once under an actual live identity-frame level. It retains its off-tree authored nodes/resources before attachment and rejects a failed binding.

`apply_state(bell_state: String, exercise_index: int, markers_visible: bool) -> void` accepts available/active/spent and index 0–2. It changes only fixed pose/marker visibility. It is quiet and idempotent, so the same call is suitable for ordinary presentation sync and quiet restore. Invalid state or a changed binding refuses the update. `presentation_state() -> Dictionary` returns detached scalar readback with API `act1-rehearsal-art-1`. `binding_error() -> String` checks held native geometry, material, tree, frames and expected visibility; it does not inspect unrelated combat or shared state.

`landmark_world_corners(id: String) -> Array` accepts `bell` or `marker:<source_id>`. It reads all visible native meshes under that landmark, transforms their real AABB corners and returns eight world-enclosure corners. Hidden markers return an empty array; an invalid ID/binding returns `[Vector3.INF]`. These bounds are not a contact-box or silhouette proxy.

The host owner alone wires construction, state sync/quiet restore, binding refusal and actual camera containment. When the bell is relevant to local contact presentation, acquire its actual bounds. All bell geometry stays inside the existing 1.1 × 1.6 × 1.1 m native BellArea BOX after its scenic-only rear offset: the host can verify every returned art corner lies inside that actual BOX, then use the existing eight BOX corners as one conservative enclosure of contact and bell. This adds no required framing points. If containment fails, reject rather than dropping the art or another required point. Quiet station decoration stays outside the required interaction union. Preserve the original 224-point limit and all source, response, body and cue bounds. Actual optics must prove the composition; a future desired fit alone is insufficient. New art adds no private camera or fit override.

## Contact-center occlusion correction

The art author inspected the actual 540 × 1170 first-warning capture at `.cinder/captures/o3-18947-1267551/02-first-warning.png` (SHA256 `047ec9072d855677cb600c0e8f064cb78fcacc131d0a32daf5b6cf6c26d32af3`). It shows the bell body over the traveller’s torso and the stand/feet crowding the player’s feet. That original image and its owner-reported native 18/0 result remain a visual failure record.

Only the complete `PracticeBell` group moves by `(0, 0, -0.30)`. The offset is retained in the authored transform chain and read by the existing actual mesh-bounds method. Bell dimensions, all three clockless poses, floor markers, collisionless role, contact trigger, native contact box, shared cue and API remain unchanged. Relative to the contact feet anchor, the conservative art extent becomes x[-0.50, 0.50], y[0, 1.50], z[-0.50, -0.10], inside the original native x/z[-0.55, 0.55], y[0, 1.60]. This is source arithmetic, not native or visual acceptance; the host retains its actual eight-corner containment check and the 224-point limit.

## Validation handoff

This author made no engine/import/commit or host/layout/scene changes. The owner must parse the changed source and rerun the directly affected native portrait/bounds check, then inspect the corrected actual contact-center view. Prior evidence retains its original source scope. Necessary host persistence and quiet-restore checks belong to the host owner and its codec/native interfaces. No full route, all-kit, performance, export or device claim is made. The original planned asset record is preserved as kickoff history; this manifest documents the later source-authored state.
