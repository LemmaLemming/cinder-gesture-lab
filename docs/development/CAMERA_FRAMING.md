# Pure fixed-width encounter framing

`camera-framing-1` in [camera_framing.gd](../../scripts/presentation/camera_framing.gd) is a pure native geometry leaf. It proposes a bounded X/Z correction to the shared camera's already eased focus while preserving focusY, orthographic width, offset and basis. It moves no camera/actor, changes no release anchor or input, reads no tree clock and authorizes no attack. The shell owns applying a proposal and guarding actual presentation.

```gdscript
var spec = {
    "basis": camera.global_basis,
    "offset": shared_camera_offset,
    "width": camera.size,
    "viewport_size": viewport_size,
    "safe_rect": normalized_hud_safe_rect,
    "max_shift": 2.0,
    "safety_margin": 0.055,
    "near": camera.near,
    "far": camera.far,
}
var proposed = CinderCameraFraming.plan(required_points, desired_focus, spec)
var current_error = CinderCameraFraming.containment(required_points, current_focus, spec)
```

The static signatures are `plan(required_points: Array, desired_focus: Vector3, spec: Dictionary) -> Dictionary` and `containment(required_points: Array, focus: Vector3, spec: Dictionary) -> String`. Plan rejection returns `{accepted: false, reason, api_revision}`; acceptance additionally returns `focus`, `desired_focus`, `shift`, `shift_distance`, `camera_position`, `camera_plane_correction`, `camera_plane_shift_intervals`, normalized `screen_bounds`, `depth_range`, `safe_rect`, `safety_margin`, `point_count`, `width`, `basis` and `numerical_headroom`. Returned containers have no retained shared state. Containment returns an empty string only for the exact supplied unshaken focus, including the same protected screen/depth margin.

## Required inputs and limits

Only the shared shell supplies the exact spec fields. The projection must be orthographic `KEEP_WIDTH`, without h/v viewport offsets or alternate frustum projection. The leaf receives this contract through its native spec; it cannot inspect a camera object to enforce it. The native basis must be finite, right-handed, orthonormal within1e-5 and unrolled (`right.y` within1e-5). Its X/Z→camera right/up determinant must have magnitude at least0.1; near-horizontal viewing cannot supply this planar model. Width is positive and at most1024; max shift and safety margin are finite nonnegative values at most1024. Native viewport dimensions must be finite/positive; derived orthographic height must not exceed2048. Near is positive and far exceeds it. `safe_rect` is a nonempty normalized rectangle entirely inside[0,1]², with enough room after the margin.

Supply1–256 finite native `Vector3` corners. Corners, desired/proposed focus, offset and resulting camera origin have coordinates within±1024. Points must bound actual required source/crest/art/body geometry, full authoritative footprint including endcaps, the hero and supported landing/recovery opening. Include committed moving-source/art bounds before motion begins; don't wait until an already clipped endpoint appears. Owners must refresh for actual alternative movement, rather than assuming only the preferred response is used. All remote possible responses need not be visible simultaneously, but a merely preferred fitting path cannot license damage with the actual hero/required source off-screen.

No `billboard_points` adapter is provided. Owner world corners must account for the actual billboard orientation, native scale, texture extent and offset. A billboard's ordinary node transform/AABB cannot be assumed to describe its camera-facing rendered corners. The integration owner can add a separately verified native adapter later.

## Projection and guard

Every point constrains one feasible correction interval along camera right and another along camera up. The planner clamps zero (the desired normal-follow correction) to those intervals, then inverts the full2×2 camera-right/up projection of X/Z to recover planar world translation. It never changes focusY, the basis, width or player travel. The intervals are eroded by the requested safety margin plus0.001m numerical planning headroom; strict actual containment retains the requested margin without allowing points outside it. A union that cannot fit, a correction beyond `max_shift`, coordinate overflow or protected near/far clipping rejects. This finite plane-clamp algorithm does not search other corrections to rescue a depth failure or globally minimize world-distance correction; conservative rejection is explicit.

The root should bound actual shake in camera-plane coordinates and add a pixel guard when selecting `safety_margin`;0.055m is its current proposed policy for the shared0.035m shake and pixel protection. Plan acceptance is a **future proposal**, not proof that current rendering is safe. The shell must establish framing during warning, retain required bounds through active/recovery, and check actual current containment before damaging execution. Failed/unsupported framing needs visible holding/cancellation. Returning to normal follow after the exchange uses the existing easing. A level's optional hook, shell wiring, HUD safe rectangle, pause/retry reconstruction and failure policy belong to integration/act consumers and are not implemented by this leaf.

Containment proves bounded projection/depth only. It does not establish scenery occlusion, contrast, pixel readability, collision safety, fairness, whole-encounter completion or human recognition. Those require actual owned portrait evidence. Camera translation alone keeps the fixed basis used by existing screen-delta aim and leaves the stored final release point unchanged.

The [official Camera3D API](https://docs.godotengine.org/en/stable/classes/class_camera3d.html) describes orthographic size/KEEP_WIDTH, local near/far limits and `unproject_position`; these were inspected for the projection model. Installed4.7.2 native alignment is tested independently below.

## Focused evidence

[camera_framing_smoke.gd](../../tests/camera_framing_smoke.gd) passed **68 checks, zero failures**, exit0 without script/resource errors, through `python3 scripts/dev/dev.py engine --headless --path . --log-file .cinder/camera-framing-leaf-native.log --script tests/camera_framing_smoke.gd` on Godot4.7.2 `ed1daf0bf`. It covers mirrored near/far signed examples with complete conservative source art/endcaps/hero/landing, HUD margins, infeasible unions, bounded shifts, near/far clipping, malformed native specs, full planar inversion, pause-independent purity, returned diagnostics and held release-point direction. Its ready portrait `SubViewport` compares analytic bounds with an actual orthographic `Camera3D.unproject_position` and native frustum checks, preserving exact captured native camera width/basis. The first68/3 run is retained in `.cinder/camera-framing-leaf.log`: two fixture assertions compared the native float32 camera width with literal7.2; a yawed fixture's corrections nearly cancelled worldZ, contrary to its illustrative threshold. Corrected fixtures use native getter identity and a non-cancelling two-axis case with reconstructed plane correction. No production checks were relaxed.

This uses explicit fixture geometry; it does not accept either act's art/encounter or the unwired shell camera. Targeted script execution creates only the two owned UID sidecars when absent and preserves them on later runs; no broad editor import was used.

## Shared shell and level integration

The shared `Game` now provides pure `camera_framing_plan(points, desired_focus)`, `camera_framing_error(points)` and defensive `get_camera_framing_state()`. The plan adds mandatory actual shared-player capsule, full native billboard quad and foot-shadow corners. It uses the current rendered HUD's normalized `combat_safe_rect()` and reserves .055m (maximum .035m shake plus .02m pixel protection); the current guard includes the camera's actual shake and retains .02m protection. Unsupported nonorthographic/KEEP_WIDTH or nonzero native projection offsets reject. The camera basis, width, player focusY, release anchor and tap-minus-release mapping stay unchanged.

A level may override pure `_camera_framing_points() -> Array`, returning at most224 finite bounded actual world corners. Include the full source art, complete committed footprint with endcaps, supported safe landing and required ordinary-primary opening before admission; retain forecast bounds through recovery. The shell adds the player's22 mandatory corners and applies the closest fitting X/Z translation after updating the actual same-frame wrapped HUD. An empty hook preserves the existing .16s close follow exactly. Invalid or infeasible bounds expose `last_camera_framing_error` and a rejected diagnostic; this interface does not silently change controls, motion, encounter clocks, threat leases or damage.

Use `camera_framing_plan` for future admission design and `camera_framing_error` for the actual currently rendered view before a lock/damage authorization. A hypothetical accepted future focus is not current visibility. An owner must hold/cancel a new exchange when its full required presentation cannot fit, then use a fresh warning after correction. Do not restrict the player's legitimate far-side swipe to accommodate a clipped view, move a physical source to its visual proxy, zoom, rotate, or treat the camera fit as an escape/fairness/LOS proof. Authored owners still provide their complete current and committed render/cue/landing/opening bounds.

`camera_billboard_points(sprite)` supports a ready standard enabled Z-axis Sprite3D with a single un-atlased frame, normal world pixel sizing and no material override/overlay. It derives the six actual native triangle-quad vertices, transformed by the current camera right/up axes and actual positive world scale. `player_camera_framing_points()` adds the actual common capsule box and foot-shadow mesh bounds. Atlas margins, fixed-size/custom-shader or other billboard axes return empty and require an independently verified owner adapter; there is no collider-only fallback for artwork.

Installed Godot4.7.2 source observations: [Sprite3D native quad and billboard culling bounds](https://github.com/godotengine/godot/blob/ed1daf0bf/scene/3d/sprite_3d.cpp) and [enabled billboard shader/material scale](https://github.com/godotengine/godot/blob/ed1daf0bf/scene/resources/material.cpp) were inspected. Native billboard AABB is deliberately an inflated culling sphere, so it cannot stand in for the actual render quad. Native triangle generation and the material camera-basis transform support the bounded standard adapter; Atlas texture margins require separate handling and are rejected here. Independent actual-camera projection and scripted portraits verify the common player and standard source cases on the installed engine.

The anonymous shared fixture is not an authored Sun1 encounter or physical lunge test. Its actual 3.726m far-side source separation shows clipping under ordinary follow and a complete protected union after translation on both signs. Normal native focus-out guards remain active; scripted public resume is used, actual focus=false is recorded, and no native-focused or human input/understanding claim follows. Act3 must adopt the exact publication and recapture its actual far-right warning/lock/active/recovery and ordinary-primary return before REQUEST7177 can close.
