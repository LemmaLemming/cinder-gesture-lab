# Pure prospective stationary attack

`CinderThreatScheduler.preview_stationary(owner, threat, response)` implements additive `stationary-preview-1` on the existing `threat-scheduler-4`. It provides the prospective ordinary candidate, selected supported escape/primary-opening witness and exact current guard before source owners decide whether the required portrait view can contain that exchange. Only a successful actual request allocates a reservation or cooldown.

```gdscript
func preview_stationary(owner: Node3D, threat: Dictionary, response: Dictionary) -> Dictionary
func request_attack(owner: Node3D, threat: Dictionary, response: Dictionary, preview: Dictionary = {}) -> Dictionary
```

The legacy three-argument request and empty fourth argument retain ordinary cleanup/admission semantics. A nonempty preview requires contemporaneous exact correspondence both before cleanup and after cleanup, before committing the same common candidate/proof. Preview itself performs no pruning, callback, clock advance, request/snapshot flag or diagnostic change, serial allocation, reservation/cooldown admission, source movement or velocity correction. Stale retained threats and expired retained cooldowns reject until ordinary cleanup occurs; preview cannot cancel an obstructing source to create its own opportunity.

## Actual source, response and world

Construct response from the exact shared Player's public `get_threat_response_state()`, then add the existing authored `world_root`, `world_revision`, recognition/input margins, bounded normalized escape/return directions and supported floor regions. The containing same-World3D root must include the actual source, Hero, Scheduler, floors and every scenery blocker. Shared Game's containing `world` is ordinarily the common root because its Hero and level are siblings. A level-only root cannot substitute for that containing world.

The same exact public live response and supported Hero physics guards used by [pure lunge preview](LUNGE_PREVIEW.md) apply. Copied stats, gear, timing, commitment, pending equipment and resource-independent response values must match the actual public getter. The Hero's measured native capsule, masks, collision exceptions, axis locks and moving-platform carry must support the proved response. Physical/contact tolerances remain unchanged.

Stationary geometry must use the actual source position as `origin` for circle/cone/crescent or `from` for lane, within the existing geometry epsilon. Both stationary source/opening flags must be true. A native CharacterBody source must have exactly zero commanded velocity and pass the measured BOX/CAPSULE body descriptor. Unsupported moving physics sources, including RigidBody/AnimatableBody or moving StaticBody, reject. A plain Node3D may host a genuine stationary environmental source; no fake HP, capsule or enemy proxy is created. Source owners must keep the source stationary through the accepted lease and preserve their own source/cue/callback custody guards. An authored stationary recovery target may differ from source position; it still must pass the ordinary range/LOS and timing proof.

The proof uses the existing complete preparing/active/recovery union, fixed difficulty role, supported static coplanar box floors, capsule clearance and ordinary-primary opening. Existing [measured motion](BODY_SWEEP.md), logical geometry and scheduler snapshot semantics are unchanged. Generated/unbound/moving scenery, invalid response/body support and unsupported input reject conservatively.

## Returned data and correspondence

Rejected preview returns `{accepted: false, reason}` without changing Scheduler diagnostics. Accepted preview returns a defensive native dictionary:

```gdscript
{
    accepted: true,
    reason: "",
    api_revision: "stationary-preview-1",
    candidate: prospective_ordinary_candidate,
    proof: selected_supported_response,
    guard: exact_current_context
}
```

The candidate retains the actual circle/cone/lane/crescent geometry, authored stationary opening, prospective warning/lock/active/recovery/cooldown deadlines, source identity/position, fixed profile and world revision. It has no reservation ID. The proof provides full timed paths, reachable `landing`, `attack_position`, primary timing and complete response deadline. Blast ammo, invulnerability and ideal instant input are not credited.

The common native guard binds Scheduler/source/Hero/root identities; exact clock/serial/profile/encounter/world revision; actual source/Hero transforms, velocities and supported physical/resource identities; original threat and authored response values; floor node/body/shape identities and signatures; full actual static collision fingerprint; complete retained union with actual sources; and retained cooldowns. One-bit copied scalar changes and Vector3/transform-to-array substitutions reject. Native values are bounded before any recursive deep copy, so cyclic/oversized/object input rejects without engine recursion.

Supply the entire unchanged native result synchronously as the optional fourth argument to `request_attack`, using the same actual source, threat and live response. The request freshly reproves and exactly compares all prospective data before and after ordinary cleanup. Accepted admission has the same candidate and selected proof, plus the newly allocated ID/lease. Simulation, actor/source/world/floor/resource, role/candidate-order, clock/serial/union/cooldown changes require a fresh preview. This ephemeral native dictionary is not a save format, reservation token, damage authority or historical witness.

A camera owner should frame actual source/art/cue and full footprint bounds, the actual player/art and the prospective supported landing/attack position before admission, then maintain current required projection/cue visibility through active callbacks. Scheduler preview does not control the camera, certify all future player input, implement a source HP/damage consumer or accept an authored encounter.

## Focused validation

`tests/stationary_preview_smoke.gd` uses the actual shared Hero, independent native stationary sources, registered box floor/wall and real public response. It checks all four logical geometry kinds; full exact snapshot/flag/clock/source/diagnostic/event purity; candidate/proof correspondence; one-bit and native-type forgeries; live actor/source/world/floor/resource/clock changes; preparing/active union and source cooldown; stale retained cleanup and callback transaction barriers; actual BOX source and unsupported native body/movement; and malformed/cyclic/oversized/object inputs. Legacy ordinary cleanup remains explicit in the same fixture.

The first focused queued run passed **146 checks, 0 failures**, exit 0, on Godot `4.7.2.stable.official.ed1daf0bf`:

```sh
python3 scripts/dev/dev.py engine --headless --path . --log-file '/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/stationary-preview-first.log' --script tests/stationary_preview_smoke.gd
```

The source was frozen throughout this run: Scheduler SHA256 `5e7ae27fc3f274fe8c49d266fd6611aca0300e5b975b4d1591c6839f45d83d7f`; fixture SHA256 `9134cd4ec8cda560ed580c0072f381cade127141919e936d6a3f0ff0b2f634de`. There were no script or runtime errors. Native macOS startup emitted the `get_system_ca_certificates` `ret != noErr` diagnostic; it did not prevent execution. No production source repair or repeated engine run was needed. The root owns the directly affected existing lunge-preview check because its exact guard assembly is now shared; its result is separate from this leaf evidence.

These fixture checks do not certify authored level choreography, source HP/damage callbacks or actual portrait camera integration. Existing Scheduler snapshot format and three-argument request semantics remain compatible; preview is an additive ephemeral API rather than a snapshot migration.
