# Explicit candidate Player camera framing

This additive Game interface is published as shared31. Adopt only the exact commit named by the canonical mailbox. Native61/0 verifies the bounded Shell/camera seam; it does not accept an authored level. The separate Echo lifecycle/performance work is outside this camera interface.

Act1 request `56d99d68-bd14-46c9-a870-47d662f4aeb3` identifies the composition need: fresh Title → Continue has no installed `Game.player`, while an earlier-room Retry can retain a donor Player elsewhere. The actual Shell already constructs a hidden independent candidate Player and stage camera. These views measure that explicit native pair without assigning either object to the installed Game aliases.

## Public views

[Game](../../scripts/game.gd) adds exactly these signatures:

```gdscript
func camera_framing_plan_for_player(
    points: Array,
    desired_focus: Vector3,
    framed_player: CinderPlayer,
    framing_camera: Camera3D
) -> Dictionary

func camera_framing_error_for_player(
    points: Array,
    framed_player: CinderPlayer,
    framing_camera: Camera3D
) -> String

func player_camera_framing_points_for(
    framed_player: CinderPlayer,
    framing_camera: Camera3D
) -> Array
```

The plan appends the explicit Player's mandatory body/art/shadow corners to the owner's supplied required points. It returns the existing [CameraFraming](../../scripts/presentation/camera_framing.gd) result: `accepted`, `reason`, and, on success, the proposed `focus`, `camera_position`, translation and projection diagnostics. Binding failures return `{accepted: false, reason}`. Returned arrays/dictionaries do not retain caller authority.

The error view checks the **actual current** candidate camera position, including any shake already present. An empty string means its supplied union currently satisfies bounded screen/depth containment. Empty owner points or unavailable mandatory Player bounds reject. The points view returns actual native corners, or an empty array for an unsupported binding.

Existing `camera_framing_plan(points, desired_focus)`, `camera_framing_error(points)`, `player_camera_framing_points()` and `camera_billboard_points(sprite)` bodies remain unchanged. Installed live callers keep their existing aliases, results and behavior. The three new views do not read `Game.player` or append a donor Player's bounds.

## Actual native binding and shared policy

The explicit Player, explicit camera, shared Game camera and HUD must be ready, in-tree and not queued for deletion. Both cameras must have no Script. The explicit Player and camera must share the same actual viewport and `World3D`; the explicit camera must be that viewport's current camera. The shared Game camera may remain in the donor world. A hidden staging container is permitted; candidate construction remains paused and nonplayable under the existing Shell lifecycle.

The explicit camera must preserve the ready shared Game camera's exact native global basis, width, near/far and cull mask. Both retain orthographic `KEEP_WIDTH`, zero horizontal/vertical offsets and zero frustum offset. This prevents an alternate zoom, rotation, cull policy or private camera spec from licensing a fit. The candidate's actual viewport size supplies the aspect; its dimensions may differ from the donor viewport. No camera is cloned or constructed by a query.

The current actual HUD supplies its dynamic normalized `combat_safe_rect()`, including fitted/wrapped objective/status bounds. The existing fixed `(0, 18, 13)` offset, planar shift limit `3.6`, focusY, width and basis stay unchanged. Planning reserves `0.055m` for the bounded `0.035m` shake plus `0.02m` pixel protection; actual containment uses `0.02m`, accounting for the camera's already applied shake. The pure leaf's finite bounds, maximum point count and numerical headroom remain those documented in [Camera framing](CAMERA_FRAMING.md).

Mandatory Player geometry comes from its actual direct native children: the `BodyCollision` capsule transformed as an enclosing box, the `ActorSprite` full native triangle quad using the explicit camera's billboard right/up axes and actual positive world scale, and `ContactShadow` mesh bounds. The capsule dimensions must be finite and valid; all returned corners must be finite and within the leaf's coordinate bound. The sprite retains the existing enabled Z-axis billboard adapter: one un-atlased frame, ordinary world sizing, no region, material override or overlay. Unsupported artwork returns empty; collision bounds alone do not substitute for visible art. No fake body or saved corner stamp is accepted.

## Paused restore composition

Use the actual candidate Player and current camera retained by [Shell construction](../../scripts/campaign/shell.gd), before installation, rather than temporarily rewriting `Game.player` or `Game.camera`. The actual camera can be obtained from the explicit Player's viewport's `get_camera_3d()`; its native current binding is checked again by the views. The owner still supplies the complete source/art/cue, committed footprint, landing and ordinary-primary opening corners.

These views read the Player's **current native physical pose**. They do not interpret a saved Player dictionary or silently translate a fresh spawn pose to a saved one. Saved physical positions must first be established through the permitted canonical paused whole-unit restoration flow before claiming that a query measures them. [Restore candidate construction](RESTORE_CANDIDATE_CONSTRUCTION.md) still constructs immutable bindings before pure aggregate validation; its constructor is not permission to apply saved HP, death, clocks or history. Existing `snapshot_error_with_player` saved-Player context remains the pure cross-component validation seam. A pure validator must not move an actor/camera or apply a saved snapshot to make a framing check pass.

After whole-unit prevalidation, Shell's existing Player → level quiet commit supplies the real saved Player before the level restores its local state. The owner may consume a proposed fit through its legitimate framing/snapshot flow, preserving the actual saved Shell camera-focus state and later installation ordering. The query itself changes no focus, diagnostic, actor, resources, clock, input anchor or lease. No alias rewrite, forged accepted stamp or activated future source is part of this interface.

The candidate camera retains its actual stage pose until the existing Shell flow applies a camera focus. Consequently an accepted plan is a **future fit**, while the error view describes current containment. Neither establishes a safe route, valid landing, native LOS, occlusion, portrait readability or damage authority. Actual required presentation must satisfy its current guard at the owner's established lock/contact boundaries; a hypothetical future correction cannot license damage now.

## Verification scope

The new targeted fixture passed **61 checks, zero failures**, with exit0 and no native/script errors. It uses the actual Shell constructor/capture/quiet saved-candidate flow, an unedited physical spawn snapshot, fresh Title with a null installed Player, a genuinely different-room donor moved by public dashes, native component/projection controls, actual viewport/HUD variations, invalid bindings and live-versus-explicit equivalence. The viewport variation is a labelled test control that temporarily disables only the hidden container's stretch and restores its exact native receipt. No full production Continue/Retry route, portrait, native OS gesture, authored A1-L3 or campaign acceptance is inferred. Original prequeue84-source subset, full logs and closure are retained in [shared31 evidence](evidence/shared31-candidate-camera/index.json). Named command: `python3 scripts/dev/dev.py test camera_candidate_framing`; the original run used the canonical `engine --headless --script` target before this name was added. Existing CameraFraming/Shell results remain separate historical scopes. Integration owns publication and remains the help contact.
