# Stationary lane and circle mechanisms

This compatible extension resolves the shared consumer part of Act 1 A1-L2
request `d02f12e5-797d-463f-84f5-7caafd3d26d5` from worker
`01a11adf-2ec8-7702-96c6-0fa1e240c332`, submitted at owned candidate
`70c6be72abf4e524bcc5a1116fdcf4aaa488b27f` on campaign-shared-11.
Level placement, square-puff artwork, the physical C30 rusher, its HP/recovery
and combined aggregate hooks remain Act 1 owned. No equipment, ability, actor,
gesture, scheduler, collision solver or campaign registration is introduced.

## Compatible public seam

`CinderLaneMechanism` remains the existing class and script at
`res://scripts/combat/lane_mechanism.gd`. Its `lane-mechanism-1` API revision and
ordinary schema-1 snapshot envelope remain supported. Existing two-argument lane callers
remain supported. A callback-paused unprocessed path uses conditional schema2,
as described below; older consumers must adopt this implementation before loading
that envelope. Legacy decimal snapshots are valid only when parsing preserves
their copied floating identities exactly; use ExactJson for general exact saves.
No saved opening is rewritten or migrated. Circles and per-cycle opening overrides
require no additional field; only an unresolved callback-paused path does.

```gdscript
configure(mechanism_id: String, geometry: Dictionary,
          opening_position: Vector3,
          raw_role: Dictionary = DEFAULT_RAW_ROLE,
          timing_floors: Dictionary = DEFAULT_TIMING_FLOORS) -> bool
bind(scheduler: CinderThreatScheduler, heroes: Dictionary) -> bool
start(hero_id: String, response_context: Dictionary,
      opening_position: Variant = null) -> Dictionary
```

`configure` accepts authoritative `Geometry.lane(from, to, radius)` or
`Geometry.circle(origin, radius)` with positive finite radius. Other geometry
kinds reject. Configuration copies the canonical shape and immutable raw role
before binding. The actual stationary mechanism occupies `lane.from` or
`circle.origin`, respectively. A circle is serialized as exactly `kind`, `origin`
and `radius`; it never becomes a zero-length lane.

`bind`, `cancel(reason)`, `clear(reason)`, `get_cue()`, `state()`, `state_changed`
and `hit_resolved(hero_id, cycle, result)` retain their existing contracts.
The mechanism is an HP-free, nonattackable `Node3D`; it creates no collider,
enemy/target group, damageable actor or living-enemy reload credit. Artwork
attaches to the public mechanism and cue hooks. Decorative square puffs do not
change the authoritative circle.

The third `start` argument is optional native data. Omitted or null uses the
configured default opening, preserving existing calls. A supplied argument must
be a finite world `Vector3`; arrays, dictionaries, strings and nonfinite vectors
reject. The selected position enters the actual shared scheduler request, which
must prove a normal escape and an ordinary-primary opening through the committed
union. An unreachable position fails before accepting a cycle. `state()` and the
accepted exchange expose the scheduler's exact accepted per-cycle opening.
Changing it does not move the physical circle source or footprint.

The response context still has exactly `encounter_id`, `world_revision`,
`recognition_s`, `attack_input_margin_s`, `escape_directions`, `return_directions`
and actual `floor_regions`. The consumer obtains current player stats,
commitment, motion and cooldowns through the public shared player accessor.
It does not accept caller-provided proxy stats or assume blast ammunition.

## Combined actual rusher opening

The optional vector is a **reachable position seam**, not actor custody or a
claim that a fixed environmental source can be attacked. For a combined circle
and rusher exchange, the level must:

1. Obtain a real accepted rusher lunge reservation using its actual
   `CharacterBody3D`, retained capsule and committed physical route.
2. Pass that reservation's `opening_position` as the circle cycle override.
   Do not substitute the environmental source, a decorative marker or the
   intended unshortened endpoint.
3. Retain and validate both reservations and the actual rusher actor state. The
   ordinary witness proves the new candidate's recovery window; the level must
   also confirm its returned `primary_time_s` and `response_complete_s` fit the
   actual rusher's stationary recovery interval. A reachable vector alone
   proves neither that actor's HP nor its recovery commitment.
4. Observe the real stopped source at its actual committed shortened endpoint.
   Keep its HP, attackability, stagger/cancel handling, cue and recovery coherent.
   Cancel/clear the environmental cycle when target clear, source interruption
   or exit invalidates the combined encounter.

The shared scheduler still enforces the full preparing/active geometry union,
source cooldown, explicit floors/candidates, profile budget and visible
activation stagger. Standard/Challenge permit two preparing/active sources;
Assisted permits one. The consumer cannot create a simultaneous third source or
use private damage clocks to bypass that admission.

## Damage, timing and quiet paired restore

Both shapes use the existing warning → lock → active → recovery deadlines and
the required shared `CinderThreatCue`. Physics priority 100 samples actual hero
positions after scheduler/player physics and clips each actual segment to the
active interval through `Geometry.timed_path_hits`. Shared capsule radius pads
the shape. An exact nonempty interval intersection is required before that spatial
test; geometric epsilon cannot cause damage in a clock just before activation.
One hit opportunity per stable live hero per accepted cycle is
consumed before synchronous damage/hit callbacks. Dash/hurt invulnerability can
reject HP damage while that opportunity remains consumed. Damage uses the
resolved raw role through actual player armor with `Vector3.ZERO` impulse.

Act 2 request `dcc047b7-8dac-40a1-8869-ad7690889601` identified a synchronous
active-publication boundary: an observer could pause or hide the cue after phase
publication but before actual damage. The consumer now stages every actual hero
endpoint and its piecewise path **before** publishing phase/cue observers. It
rechecks the live lease, source/bindings, tree pause, authoritative cue state and
visible native required marker/outline/fill after publication, before each hero,
after actual Player hurt callbacks, and after `hit_resolved` callbacks. Hidden,
cleared or removed required cue parts cancel the remaining cycle immediately and
retain the original source cooldown. The Player's damage method is unchanged.

Pause retains unresolved paths without consuming their opportunities or dealing
HP damage. On resume, the actual next actor/scheduler tick is sampled and appended
to those paths before observers run. Every segment stays exact; turns are never
collapsed into a guessed straight route. The consumer clips that retained path
to the original active interval and uses the actor's actual live defenses when
resolving it. It creates no new active interval or refreshed deadline. A hero path
and its opportunity are committed before entering damage callbacks; reporting the
already completed result may finish while paused, but no remaining hero receives
damage until a supported unpaused tick. Further callback pauses remain coherently
capturable. Paths are bounded to 256 segments per hero; exhaustion visibly cancels
with `pending_path_budget_exceeded` and retains cooldown, rather than dropping an
unresolved path or manufacturing a hit.

Default provisional raw role remains damage 4, warning 1.1 + lock 1.1 seconds,
active 0.2, recovery 1.6 and interval 1.8 from activation. Raw move speed 0 is a
stationary source. Role transport's max_hp 1 is unused compatibility metadata,
not a health component. A fresh cycle resolves immutable raw data once against
the actual selected profile. No autonomous loop, extra success delay, healing,
ammo spend, input controls or action publication is added.

`snapshot_state(bindings)`, `snapshot_error(snapshot, bindings,
staged_scheduler_snapshot = {})` and `restore_state(snapshot, bindings)` keep
their existing signatures and paused deferred callback/physics barrier.
The existing `exchange.opening_position` now stores the accepted override when
present; `configuration.opening_position` keeps the immutable default. Running
transport validates exact numeric equality with the independently validated
actual/staged scheduler exchange, including that opening, all copied deadlines,
profile/world identity and clock. Hero samples share the exact actor/scheduler
tick. Immutable configuration, resolved role and retained cooldown identity also
use exact numeric equality. Legacy integral JSON number representation remains
accepted; copied floating identities must survive exactly. Full-precision decimal
parsing alone is insufficient in general; use ExactJson. Geometry/physical
placement tolerances remain separate from copied transport identity.

Ordinary snapshots continue to write schema1, with exactly the previous keys.
Only a nonempty unresolved path writes schema2 with `pending_segments`:

```gdscript
{
    "hero-stable-id": [
        {"from": [x, y, z], "to": [x, y, z],
         "start_s": exact_scheduler_clock, "end_s": exact_scheduler_clock}
    ]
}
```

The new reader accepts strict schema1 without that field and strict schema2 with
a nonempty bounded running path. Entries name unconsumed bound heroes. Each piece
has finite endpoints, a nonnegative interval of at most one physics tick, exact
position/clock joins and the unchanged exchange. The last endpoint and clock must
exactly match the same independently paired hero sample, actual/staged actor and
scheduler clock. Remaining heroes share the latest sampled batch. Copied clock,
endpoint, join, hit prefix or schema mutations reject atomically. The small
one-tick duration allowance covers derived subtraction only; copied identities
and clocks still use exact equality. Clearing/canceling discards pending danger;
after draining, the writer returns to schema1.

Schema2 cannot be faithfully downgraded by removing the path. An older consumer
must reject it and adopt the shared update; no deadline/clock migration is used.
The parent saves and validates the whole trusted actor/scheduler/mechanism
aggregate through ExactJson/SaveStore. Current endpoint pairing cannot independently
authenticate an arbitrarily rewritten complete historical path or save. The
consumer validates the closed path's continuity, bounds and current custody; it
does not claim cryptographic authority over prior history.

Validate the entire player/rusher/scheduler/mechanism aggregate before mutation.
Optional native `hero_positions` and existing scheduler owner staging support
pure prevalidation. Commit the actual actors/positions, then scheduler, then each
mechanism without yielding. Mechanism commit requires the already restored
actual scheduler and hero samples. It silently restores the original cycle,
shape, opening, phase and consumed opportunities and rebuilds the cue; it emits
no phase/hit/cue events, performs no damage, requests no reservation and refreshes
no deadlines. Level art re-reads public state after aggregate commit. Cancellation
keeps the scheduler's original cooldown while clearing all required hazard parts.

## Measured fixture and exact dependencies

Only the existing targeted mechanism suite was queued:

```sh
python3 scripts/dev/dev.py engine --headless --path . \
  --script tests/lane_mechanism_smoke.gd \
  --log-file "$PWD/.cinder/circle-mechanism-engine.log"
```

On Godot 4.7.2, the completed repeat passed **152 checks, 0 failures**, exit 0,
at `.cinder/circle-mechanism-second.log`. The log has no script, parse or test
failures; it includes a startup macOS system-certificate lookup diagnostic from
the sandboxed host. All previous 79 lane checks remain in the suite. The first attempt
failed before logic on a test-only impossible typed class check; that assertion
was corrected before the repeat. No broader suite or act engine job was run.

The repeat loaded published14 Motion/BodySweep from
`e2e1de591d62e580dbaf1c512a78e3347e5cf277` plus an explicitly frozen **unpublished**
scheduler preview candidate. This is not a claim that the new consumer was
tested solely against published14:

| Loaded dependency | SHA256 |
| --- | --- |
| scripts/combat/threat_scheduler.gd | `7684ffd8aee0043600ef580271db516e8cb63823ca03f3fc3ef8701dc0430874` |
| scripts/combat/lunge_motion.gd | `52b048392c7ea5d5728b500d1cc68fa478947f59f5b321bd81f377c265be9a66` |
| scripts/combat/body_sweep.gd | `bddf3956d85c656fedea6bbce952ceb494c76867cdba895ff089abeb4c31eab9` |

New evidence covers actual shared-player dash crossing of a circle, consumed
invulnerable opportunity, armor-respecting ordinary exposure, unchanged HP-free
source and exact circle cues; mid-dash exact JSON path/landing/time continuation;
paused/quiet active and canceled pairs; one-bit copied clock/sample/deadline/
opening rejection; defensive copies, cooldown/dedupe and target-clear cleanup;
Standard/Challenge two staggered circles, third-source rejection and Assisted
budget one. The combined fixture commits an actual wall-shortened capsule lunge,
rejects the inaccessible circle-source default, uses the real endpoint override,
roundtrips the exact pair and executes actual proved dashes followed by a
zero-ammo ordinary primary against that real stopped rusher during recovery.

These are native scripted/headless shared-consumer checks. They do not establish
Act 1 placement, permitted-kit coverage, production portraits, human gestures,
campaign acceptance or an exhaustive fairness guarantee. The worker must still
test its actual combined recovery/HP/restore obligations and portrait source,
footprint, safe landing and target readability.


Independent published-dependency verification also passed152 checks, zero failures, exit0 in `.cinder/circle-against-published15.log`. This run loaded the exact shared15 Scheduler from88529f0f75d109be3fc9f7837dc093c55a5c31e7, SHA256 `808d56b68107ae540ddd6ae4ca11965f5e7a8fd8cfb0fb599cb75e2a59ec3921`, with the same published14 Motion/BodySweep and frozen consumer/test above. Its owner preserved and restored the preview candidate byte-identically in a finally block; no checkout/reset or lost work occurred. This establishes independent compatibility without waiting for the separate preview publication.

## Callback-boundary regression evidence

The expanded named `lane_mechanism` suite adds actual required-cue and mechanism
active observers that pause/hide/clear; native required mesh hiding; lost-lease
cancellation; a real mid-dash Player crossing; two distinct live shared Players
pausing/hiding/clearing through hurt and hit callbacks; repeated pause on the first
resumed tick; strict malformed pending transport; and exact SaveStore disk reopen
plus fresh actor → scheduler → mechanism restore.
The final authorized command was:

```sh
python3 scripts/dev/dev.py test lane_mechanism
```

The completed second run passed **243 checks, 0 failures**, exit 0 on Godot
4.7.2 `ed1daf0bf`, at `.cinder/lane-mechanism-callback-second.log`, with no script,
parse or runtime errors. All 152 prior checks remain. The first log is preserved
at `.cinder/lane-mechanism-callback-first.log`: prior checks passed, then the new
pause fixture exposed geometric epsilon consuming a hit before the active
deadline. That run stopped on a cascading test access to the absent pending field.
The lane-only exact interval gate and diagnostic guard were repaired before the
successful repeat. No broader suite was run.

The actual source-cue pause produced schema2, kept HP/opportunity unchanged,
survived exact SaveStore disk reopen into newly created actual actor/world objects,
and resumed once after the original short active interval. Its drained writer
returned to schema1. A separate real mid-dash crossing kept the unfinished actual
dash and consumed its opportunity once with live dash invulnerability. Native
source/outline/fill hiding and synchronous clear/lost lease canceled before HP
damage with original cooldown. Two-Hero hurt/hit pauses preserved the consumed
prefix and remaining path; a second pause during the first resumed tick retained
both contiguous segments at the exact new actor/scheduler endpoint and quietly
restored them. Copied one-bit clocks/endpoints/joins and malformed pending schemas
rejected without mutation.

These shared scripted checks do not accept authored A2-L2 placement or establish
portrait/human input evidence.
