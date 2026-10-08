# Pure prospective ordinary lunge

`CinderThreatScheduler.preview_lunge(owner, threat, response)` implements additive `lunge-preview-1` on the existing `threat-scheduler-4`. It returns the same measured physical plan, prospective committed candidate and selected supported response witness that an ordinary real-body lunge request evaluates. The camera owner can use its complete corridor, source endpoint, player landing and ordinary-primary attack position before deciding whether to admit a tell.

Preview performs no cleanup, simulation advance, callback, source movement, velocity change, reservation or cooldown allocation, serial increment, or request/snapshot diagnostic change. It neither reserves its candidate nor authorizes damage. A stale retained threat or expired retained cooldown rejects conservatively until ordinary scheduler cleanup occurs.

## Additive public seam

```gdscript
func preview_lunge(owner: CharacterBody3D, threat: Dictionary, response: Dictionary) -> Dictionary
func request_lunge(owner: CharacterBody3D, threat: Dictionary, response: Dictionary, preview: Dictionary = {}) -> Dictionary
```

The existing three-argument request remains compatible, including its existing generic shared-size body fixtures and ordinary cleanup. The new preview and nonempty optional correspondence argument require the actual exact shared `scripts/player.gd` actor and an explicit live `response.world_root`. That root must contain the Scheduler, source, player, authored floors, and every scenery blocker in their World3D. The shared game places its Player beside the active level under `world`; its common World parent is therefore usually the containing root, rather than the level itself. Generated collision, moving blockers and unbound scenery remain unsupported by the existing collision fingerprint contract.

Construct response from the actual Player's public `get_threat_response_state()`, then add `world_root`, current `world_revision`, positive authored `recognition_s`, `attack_input_margin_s`, at most sixteen normalized `escape_directions` and sixteen `return_directions`, and actual supported `floor_regions`. Every field supplied by the public Player getter must still exactly match a fresh getter at preview/request time, including gear/stats, action clock, motion, commitment, pending weapon and remaining cooldowns. Preview does not inspect actor private fields or accept substitute historical actor snapshots.

The actual Hero must also pass `CinderBodySweep.source_description`: its supported native capsule, scenery mask, unlocked axes, collision exceptions, fixed basis and platform carry must permit the response physics being proved. A copied valid response cannot authorize an actual body with changed unsupported physics. Current and retained lunge sources are measured through their declared `body_collision_path`, including collider and shape-resource identity; replacing an equivalent custom-path capsule invalidates an old preview even when a fresh physical plan remains legal. Retained stationary BOX sources use their actual measured BOX descriptor.

Threat and physical support follow the existing [shared lunge contract](SHARED_CONTRACT.md), [measured source motion](BODY_SWEEP.md), and current `CinderLungeMotion.plan`: stopped actual single upright native capsule, scenery-only collision, fixed straight normalized direction, bounded speed/distance, sufficient resolved active duration, supported immutable coplanar static box floors and stationary recovery at the actual collision-shortened endpoint. The capsule's actual dimensions remain intact. No BOX proxy, fake endpoint, actor lifting, gravity/knockback override or changed contact tolerance is introduced here.

## Returned data and exact correspondence

Rejection returns `{accepted: false, reason}` without changing Scheduler diagnostics. Accepted preview returns a defensive native dictionary:

```gdscript
{
    accepted: true,
    reason: "",
    api_revision: "lunge-preview-1",
    plan: measured_physical_plan,
    candidate: prospective_committed_candidate,
    proof: selected_supported_response,
    guard: exact_current_context
}
```

`plan` contains the measured source signature, start, intended direction/speed/distance/duration, full conservative damage corridor `geometry`, `planned_endpoint`, collision shortening, actual source radius and feet offset, and initial motion state. `candidate` contains the same corridor/opening, adapter and authoritative prospective warning/lock/active/recovery/cooldown deadlines, source identity/position, fixed profile and world revision that real admission will commit. It has no reservation ID. `proof` supplies the existing complete timed path, selected `landing`, `attack_position`, ordinary-primary time and complete response deadline. No blast or invulnerability is credited.

For view admission, include the actual source/art/body corners, corridor/endcaps, actual player/art corners and supported prospective landing/attack-position bounds. A camera-fit result is only prospective framing. The camera owner must still validate actual current projection before damage and preserve required cues, portrait margins, fixed angle/width and exact release-point aim. Preview does not choose a preferred path on behalf of the player or guarantee that all legal future input stays visible.

The guard binds exact Scheduler/source/player/root identities; Scheduler clock and serial; encounter/profile/world revision; actual source/player transforms, velocities, physical signature/resource identities and relevant body settings; all original threat and response values; floor node/body/shape identities and signatures; actual stable-path static collision fingerprint; complete retained preparing/active/recovery union and its actual sources; and retained cooldowns. Resource IDs are represented as exact strings because reference-counted Godot IDs need not fit JSON's safe integer range.

Submit the entire unchanged native result as the fourth request argument synchronously, using the same actual source, role and response. The request freshly queries and proves the current physical world, exactly compares the complete copied plan/candidate/proof/guard, enters its ordinary transaction, performs ordinary cleanup, and freshly proves/compares again before commit. A changed clock, source, hero, role, timing/candidate enumeration, floor/resource, world fingerprint, serial, union or cooldown rejects without admission. One-bit copied clock/fingerprint/deadline changes reject; physical contact and shared14 represented-position tolerances remain unchanged. Native Vector3/transform types cannot be impersonated by JSON arrays.

Preview is ephemeral native data. It is not a save format, token, reservation, historical authority or guarantee that a later request will be accepted. A parent must obtain a new preview after actual simulation or context changes. Authored source owners may retain minimal validated view-only points bound to their accepted actual reservation under their own snapshot schema; this API neither serializes those points nor reconstructs a historical witness for them.

## Shared proof and scope

Both paths use the same pure lunge preparation and ordinary candidate/budget/stagger/response proof helpers; only the actual commit allocates serial/reservation/cooldown state. Preview rejects during snapshot, request, boundary or cancellation/physics callback transactions without altering `last_error` or `last_snapshot_error`. Existing actual admission retains its cleanup and source revalidation guards. The full conservative preparing/active union, supported floor continuity/capsule clearance, current commitment/cooldown, ordinary-primary range/LOS and recovery interval remain required.

Candidate enumeration can reject a valid escape, and an unarmed tracking lane is handled under the existing conservative union semantics. This is not whole-encounter fairness, a mandatory camera policy, an authored Act3 implementation, a new visual asset, or a replacement for actual portrait/loadout/retry checks. Unsupported body/world/response input fails closed. BodySweep, lunge motion, actor, geometry/contact tolerances and Scheduler snapshot format are unchanged.

## Focused validation

`tests/lunge_preview_smoke.gd` uses the actual shared Player, a distinct measured native source capsule, registered static floors/wall, and real public response data. It checks prospective wall shortening and camera fit without admission; full snapshot/clock/diagnostic/source/event purity; exact preview/request plan and selected-proof correspondence; copied one-bit and native-type forgeries; actual source/hero/world/floor changes; changed role/timing/directions/cooldown; preparing/active union selection; stale retained state and callback barriers; and legacy cleanup compatibility. Actual custom-path equivalent shape replacement, retained-source collision exceptions, and Hero axis locks, mask changes, collision exceptions and native moving-floor carry reject without mutation; repairing the original supported body permits a fresh preview.

```sh
python3 scripts/dev/dev.py engine --headless --path . --log-file .cinder/lunge-preview-hero-final.log --script tests/lunge_preview_smoke.gd
```

The final focused preview leaf passed **70 checks, 0 failures**, exit 0, on Godot `4.7.2.stable.official.ed1daf0bf`; `.cinder/lunge-preview-hero-final.log` contains no script errors or warnings. The directly affected ordinary suites passed adapter **35/0** (`.cinder/lunge-preview-affected-adapter.log`), Scheduler snapshot **35/0** (`.cinder/lunge-preview-affected-snapshot.log`) and Scheduler **69/0** (`.cinder/lunge-preview-affected-scheduler.log`), all exit 0. Only preview-context body/identity guards changed after those ordinary passes; their common preparation and commit helpers stayed unchanged.

An initial 52-check run had one fixture assertion comparing the actual native radius with decimal literal `0.27`; it was corrected to compare the measured native shape value exactly. The consumer's separate circular mechanism suite passed 152 checks against both the unpublished source checkpoint and exact published15 Scheduler, with the preview candidate restored byte-identically afterward. These focused checks do not accept an authored whole encounter or portrait camera integration.
