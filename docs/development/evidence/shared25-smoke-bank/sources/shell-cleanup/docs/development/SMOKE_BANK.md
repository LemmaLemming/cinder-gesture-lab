# Finite smoke bank

`scripts/combat/smoke_bank.gd` implements `CinderSmokeBank`, revision
`smoke-bank-1`, as an opt-in stationary environmental Circle. It has no HP,
enemy identity, emitter reference, ability or player-controller override.
This is a shared consumer for future authored smoke placement; the test level
is an isolated fixture, not A2-L3 acceptance or a complete encounter.

**Validation status: runtime target passed; teardown subset pending.** The first native fixture run
completed 306 checks with one failure and two script errors: a cached deleted
bar child was cast before its validity check. The failed log and original
source receipt are preserved in `.cinder/smoke-bank-first.log` and
`.cinder/smoke-bank-first-source/manifest.json`. That run is not a passing result.
The repaired native run `.cinder/smoke-bank-second.log` completed **353 checks,
0 failures, exit 0**, with no script/parse errors. Its wrapper reported retained
WAV/playback objects and an Effects StringName at final shutdown, so clean fixture
teardown is still pending. Runtime source hash is
`aee34e8db765585252fcbbb6b1f0e2a5334b4118c11497c12e6c9de8a6318ffc`.
Only public Shell fixture teardown changed after that run; the full runtime
source remains frozen. The focused `--shell-only` selector reruns all four
public Shell cases and is a subset result, not another complete leaf run.
No portrait gameplay, authored placement, full encounter, mobile or campaign
fairness result is claimed here.

## Public API

```gdscript
configure(bank_id: String, circle: Dictionary, opening_position: Vector3,
    raw_role: Dictionary = DEFAULT_RAW_ROLE,
    timing_floors: Dictionary = DEFAULT_TIMING_FLOORS,
    contact: Dictionary = DEFAULT_CONTACT) -> bool
bind(scheduler: CinderThreatScheduler, heroes: Dictionary) -> bool
preview_start(hero_id: String, response_context: Dictionary,
    opening_position: Variant = null) -> Dictionary
start(hero_id: String, response_context: Dictionary,
    opening_position: Variant = null, preview: Dictionary = {}) -> Dictionary
cancel(reason: String = "smoke_cancelled") -> bool
state() -> Dictionary
get_cue() -> CinderThreatCue
get_grace_indicator() -> Node3D
get_required_camera_points() -> Array
snapshot_state(scheduler_bindings: Dictionary) -> Dictionary
snapshot_error(snapshot: Dictionary, scheduler_bindings: Dictionary,
    staged_scheduler_snapshot: Dictionary = {},
    saved_player: Dictionary = {}) -> String
restore_state(snapshot: Dictionary, scheduler_bindings: Dictionary) -> bool
```

Signals are `state_changed(bank_state: Dictionary)` and
`tick_resolved(hero_id: String, cycle: int, result: Dictionary)`.
Returned state, result and transport Dictionaries are defensive copies.
`last_error` and `last_snapshot_error` report command/transport failures.
Pure preview never writes either bank or Scheduler diagnostic, advances time,
prunes leases, reserves a source, changes a cue or touches the actor.

Configure before binding. Binding requires exactly one stable ID mapped to the
actual shared `CinderPlayer`, the same World3D and actual earlier-physics
Scheduler. A subclass, fake Hero, unsupported physical capsule or replacement
binding is rejected. Bank physics priority is 100 and is pausable; Player and
Scheduler priorities must be lower. The stationary source retains its native
identity and original world position/basis.

The level supplies a closed response context:

```gdscript
{
    "encounter_id": "A2-L3/section-1",
    "world_revision": 1,
    "recognition_s": 0.12,
    "attack_input_margin_s": 0.02,
    "escape_directions": [Vector3.RIGHT, Vector3.LEFT],
    "return_directions": [Vector3.LEFT, Vector3.RIGHT],
    "floor_regions": [{"collision": floor_collision,
                       "safe_rect": Rect2(-10, -10, 20, 20)}]
}
```

The bank obtains response stats, native action commitments, motion and cooldown
from the actual public Player getter and derives the common real world root.
It resolves raw role data once for the current encounter profile, uses the
Scheduler's pure stationary preview, then freshly admits through
`request_attack` with exact preview correspondence. A preview grants no lease
or authorization. The Scheduler proves against its complete preparing/active
union and ordinary empty-ammo primary opening. The actual Tender, reachable
opening position, two clean pockets, source art and portrait framing remain
the level owner's responsibilities. The opening position is a geometric
promise, not a fictional bank target or enemy.

The provisional defaults are raw damage 2, windup 2.2 seconds, full lock 1.1,
active 3, recovery 1.9, source attack interval 2, contact grace 0.4, tick spacing
0.5, and at most five consumed opportunities in one original active cycle.
Timing floors preserve windup/full-lock/recovery minimums. Difficulty resolves
damage and timing from the immutable raw role; resolved values never compound.
The required role `max_hp` value is only role-schema compatibility and creates
no HP on the source. These numbers are configuration, not fixed A2-L3 tuning.

## Contact and native timing

Only complete real native ticks earn grace. Both retained actual Hero endpoints
must be strictly inside Circle radius plus the real 0.32m Hero radius, grounded,
within the original active interval and on the supported clean floor. The
actual Hero must have no horizontal slide collision for that tick. Partial
entry/exit, tangent and crossing ticks earn zero; an outside or collided tick
resets unearned continuous grace. Vertical endpoint deviation greater than
0.02m also rejects contact. These physical tolerances do not relax clock,
identity or transport comparisons.

The bank reads actual endpoint positions, public action clocks, native grounded
state and native slide collision normals. It does not estimate exposure from
the length of a dash chord. The supported full-tick rule can add boundary-tick
delay to the nominal 0.4 seconds, and deliberately rejects ambiguous contact.
Retained endpoints are actual samples; they are not an exact reconstruction of
an arbitrary curved trajectory. Continuous exposure is supported only in the
clean convex contact domain below.

Each tick consumes at most one opportunity. Its original eligibility,
processing clock and index are committed before entering `Player.take_damage`.
No overdue loop or catch-up burst exists. Invulnerability or a current-contact
miss still consumes the opportunity; zero impulse preserves real actor motion.
Damage callbacks cannot reset the five-opportunity budget, reenter `start`,
refresh deadlines/cooldowns, or redeliver the same receipt. Actual cancellation
and loss of required native presentation stop later delivery. Actual Hero death
closes grace without resurrection or new opportunity.

The bank carries no Tender reference. The level stops future `start` calls after
Tender death, while keeping an already admitted bank alive through its original
active/recovery deadlines. Freeing/canceling the bank itself cancels its lease;
therefore the source must not be parented under an emitter that will disappear
at death. A new explicit cycle is allowed only after the prior lease/cooldown
and a fresh Scheduler proof permit it. Source cancellation never clears the
Scheduler cooldown.

## Supported domain and required presentation

Native physics is bounded to 20–240Hz and at most 1,024 retained active-adjacent
ticks. The actual common world must have supported fixed upright Box static
collision. Floor bindings are live static axis-aligned Box shapes with finite
contained `safe_rect` regions and a common top at the circle's floor Y. One
region must contain the entire Circle plus actual Hero radius plus 0.005m skin.
Blocking scenery may exist outside the expanded disc, but may not straddle it
at Hero height. Rotated/moving/non-Box scenery, unsupported physical bodies,
walls within the contact disc, holes crossing that disc and insufficient
authored support fail closed. The actual Scheduler collision fingerprint and
floor signature are retained and compared exactly throughout the cycle.

`get_cue()` exposes the real common warning/lock/active/recovery cue. The bank
also owns an amber native contact-grace bar above the sampled actual Hero.
It is distinct from the actionable-prop grammar. The parent must include
`get_required_camera_points()` in its current portrait guard and make source
art/targets/landings visible before permitting gameplay. The leaf does not
change a camera or declare its own points fitted.

The actual bound Hero capsule's measured height/radius are retained exactly;
same-resource dimension changes also reject. Required native resources,
meshes, surface buffers, material and renderer
policy, transforms and visibility are guarded before a due opportunity and
after callbacks. Removing a child, replacing a mesh/material, hiding a part,
setting its render layers to zero or attaching an unexpected texture rejects
capture and live delivery. Cancellation tolerates freed parts without
rebuilding them. Native policy and the pre-callback owned pose are checked
before a legitimate phase/death refresh. Observer-caused actual Hero death
settles only the latest alive flag and grace; a changed native position, clock
or grounded sample cancels. A restore cannot heal a currently damaged live
binding. A nested Cue cancellation settles and guards the final owner clear
after the Cue's own notification returns.

## Quiet aggregate restoration

Transport schema 1 retains immutable configuration/domain, cycle, original
exchange/deadlines/profile/epoch, actual latest Hero sample, full bounded trace,
processed count, pending callback stage, recomputed continuous grace and every
consumed receipt. It does not duplicate the authoritative Player or Scheduler
snapshot. Native numbers must use the published exact tagged JSON codec;
decimal JSON transport is not a valid exact-clock round trip.

The parent captures only after the public Shell complete-native-tick pause
barrier. Callback-local writers reject while physics, cue, damage or tick
delivery is busy. Prevalidate the actual saved Player, staged Scheduler and
bank without mutation; then commit actual Player → Scheduler → bank without a
yield, using the same bound source and floor units. For example:

```gdscript
var bindings = {"world_root": stage,
    "owners": {"A2-L3/smoke-1": bank},
    "floors": {"pocket-1": {"collision": floor_collision,
                           "safe_rect": safe_rect}}}
var error = bank.snapshot_error(saved.bank, bindings,
    saved.scheduler, saved.player)
# Parent must first validate the Player and Scheduler with their public APIs.
# After every child is proven, commit those exact authoritative units in order.
```

All processed ticks recompute grace and mandatory receipt availability. Missing
first/last/all receipts, reordered/omitted native samples, changed deadlines,
clock bits or cross-forged Player/domain units are rejected before bank
mutation. One current sample may remain unprocessed only at a real original
phase boundary or with a retained current/prior-tick consumed notification
receipt. It cannot become an arbitrary historical suffix. Processing may be
delayed by at most one native tick; expired samples earn no new delivery.
The original result is retained across direct callback pauses and quiet fresh
restore, so notification resumption does not repeat damage or opportunity.

Restore emits no attack, phase, tick or damage event and requests no new lease.
The exact actual saved actor and staged source/floor/world must already be
committed before bank commit. This validation is a closed consistency contract
for a trusted whole-unit parent, not cryptographic authorization of arbitrary
caller-built save histories or independent resource grants.

## Targeted fixture

`tests/smoke_bank_smoke.gd` uses the actual Player, Scheduler, native Capsule,
Box floors, cue/indicator resources and real shared dash/hurt inputs. Its
TEST ONLY `tests/fixtures/smoke_bank_level.tscn` is installed through an isolated
in-memory Registry and actual public production Shell lifecycle. It uses only
PID-specific `user://test-smoke-bank-*` saves, which it cleans up; production
settings/saves are untouched.

The 353-check native run covers profile resolution and pure preview; full phases and
five-opportunity bounds; real exit/reentry and invulnerability; exact quiet
mid-grace, held phase/notification/expiry restoration; mandatory receipt/history
rejections; native missing/hidden/replaced/layer/texture faults; unsupported
worlds and stale caller bindings; independently dying emitter; real fatal Hero
including actual observer-caused death; and actual Shell deferred
pause/checkpoint/format2 fresh Continue with late presentation settling on the
same native tick. Test-only teardown now stops and detaches actual effects
AudioStreamPlayer children after assertions and allows a paused AudioServer
flush before freeing the Shell. It does not mute audio, remove a bus, resume
actors or suppress a diagnostic. The focused cleanup result will be recorded
after its authorized run.

Native API references inspected for the installed Godot4.7 implementation:
[CharacterBody3D slide collision API](https://docs.godotengine.org/en/4.7/classes/class_characterbody3d.html),
[ArrayMesh native surface storage](https://docs.godotengine.org/en/4.7/classes/class_arraymesh.html)
and [Mesh surface API](https://docs.godotengine.org/en/4.7/classes/class_mesh.html).
These are implementation references, not runtime test evidence.
