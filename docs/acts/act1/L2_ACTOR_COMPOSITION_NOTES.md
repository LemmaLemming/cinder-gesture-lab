# Retained C30 composition: bounded checks passed

Current actor custody: corrected callback fixture **114/0 headless**, clean exit, on API22/merge6f5ee645 with actor5a46be35. Ordinary snapshots remain2; conditional nonempty pending paths use3. Actual sampled relative paths precede cue/state observers; held pause retains delivery, source/cue/native-part loss cancels before damage without resetting the original cooldown. Fifteen malformed pending variants, exact native-vector preservation and zero-time jump rejection are checked. Affected ordinary46/0 and dormant71/0 retain API21 attribution. The53/0 costume portraits below remain historical API20; current whole Main compound pause still fails17/2 (later circle sample and parent puff pose), REQUEST66ead603. Full L2/graphical compound acceptance is pending.

The owned actor lifecycle/preview seam passed the owner-run narrow four-source fixture on campaign-shared-20: **71 headless checks, zero failures**, after preserving the first45/1 native-key failure and replacing new dictionary dot insertion with an explicit String key. The affected default-live C30 regression passed **53 scripted graphical checks, zero failures**, including real gestures, zero-ammo primary and exact unfinished-active/dead restoration. All six actual front-facing portraits were reviewed by the owner. See the [dormant/preview archive](../../../data/campaign/act1/evidence/A1-L2/dormant-preview/index.json) and [schema2 C30 archive](../../../data/campaign/act1/evidence/A1-L2/schema2-rusher/index.json). Earlier API18 46/53 evidence keeps its original attribution. These checks do not finish the main five-beat route, compound circles, all kits/profiles or campaign Continue/Retry. Main composition is being drafted and remains unvalidated/unaccepted; Act1 remains1/8 accepted.

## Minimal lifecycle seam

The existing actor and physical capsule now expose these compatible calls:

```gdscript
configure(source_id: String,
          raw_role: Dictionary = DEFAULT_RAW_ROLE,
          timing_floors: Dictionary = DEFAULT_TIMING_FLOORS,
          lunge: Dictionary = DEFAULT_LUNGE,
          initially_dormant: bool = false) -> bool
activate() -> bool
preview_lunge(response_context: Dictionary, direction: Vector3,
              world_root: Node3D) -> Dictionary
start(response_context: Dictionary, direction: Vector3,
      world_root: Node3D = null, preview: Dictionary = {}) -> Dictionary
var activation_guard: Callable
```

Store `initially_dormant` in immutable configuration and one mutable `dormant`
boolean in actor state/snapshot. With the default false, existing configure and
two-argument start calls retain their live prototype behavior. There is no public
deactivate, reset, heal or actor-replacement operation. Within live play, a true
dormant flag becomes false once; only an independently validated earlier aggregate
restore can return the retained actor to its original dormant state.

Configure initializes HP only on the first immutable configuration. An identical
configure call returns without resetting HP or lifecycle. Activate and repeat
start never write HP; current raw and all resolved profiles keep max HP 20.

Activate requires ready same-world bindings, pristine dormant state, no actor
transaction/restore/cancellation, and the parent's actual fresh broad encounter.
The parent owns the chosen-route/beat predicate. For an initially dormant actor,
its assigned pure `activation_guard(source_id)` must return literal `true`; an
invalid guard, false or a truthy integer rejects. Public scheduler checks also
require a nonempty frozen profile, clock exactly zero and no committed exchange.
The parent establishes a source entitlement only immediately after its actual
successful public `begin_encounter` for the fresh authored beat, calls activate
synchronously, then clears that entitlement after every attempt. It validates the
saved beat/route/actor relationship separately. The Callable never enters immutable
configuration or closed transport. Clock/profile checks alone do not authenticate
the parent's route choice or encounter identity.
No automatic activation occurs in bind, preview, start or restore.
The parent must actually succeed in fresh begin_encounter; clock zero and an empty
lease table alone cannot prove that a same-tick cancellation left no cooldown.

Collision enabling must happen at a safe deferred boundary, never halfway through
a physics-query flush or snapshot transaction. The actor now validates its actual
retained collision node, original CapsuleShape3D resource, native registrations,
transform/body properties, lifecycle flags and costume bindings directly before
unpaused activation. Canonical native readbacks are retained while the original
capsule is enabled during ready, before dormant flags are applied. No disabled
collider is temporarily enabled for measurement, paused-only staging is not called
unpaused, and no shared solver is copied. Paused aggregate prevalidation still uses
the existing public `Motion.staged_source_description` on the actual retained body.
Admission remains a later unpaused public preview/request, with normal input and
no newly imposed timer or mandatory wait.

## One lifecycle rule

Use `inactive = dead or dormant` everywhere that currently derives flags from
`dead` alone: capture checks, actor commit, exchange commit, physics and damage.

| State | Root visibility | Collision | Enemy group | Motion/damage |
| --- | --- | --- | --- | --- |
| Dormant | hidden | disabled, layer/mask 0/0 | absent | frozen, no damage or lease |
| Living activated | visible | enabled, layer/mask 2/1 | present | existing behavior |
| Defeated | hidden | disabled, layer/mask 0/0 | absent | existing dead behavior |

Dormant state requires initially-dormant configuration, HP exactly max HP,
dead=false, zero velocity/hurt/cycle, clear phase/cue, empty role/encounter/profile,
reservation/sample/hit IDs and cancellation reason. Its scheduler has no lease
or cooldown for that stable source. Do not reinterpret cancellation as dormancy:
a surviving cancelled source retains its actual history and cooldown.
Cancel on a pristine dormant source should be a no-op, including its cancellation
reason, so generic owner cleanup does not invent dormant combat history.

Create/register and measure the normal enabled 0.32-radius, 1.45-height capsule
before applying initial dormancy; otherwise the current live measurement returns
an error and an empty immutable signature. If configured before tree entry, apply
dormant flags at the end of ready before the first tick. Bind keeps all four actual
nodes and does not wake them. Physics returns before gravity/hurt/sample work for
dormant actors, and take_damage rejects them with target_alive_before_hit=false.
Retain the actual saved grounded flag; do not fabricate contact or run hidden
move_and_slide merely to settle a dormant actor. Admission checks the actual floor.

Keep the retained presentation parent, costume leaf and native sprite locally
visible. Only the actor root hides for dead/dormant states. Existing costume
identity/feet/texture guards remain strict. Living activation must also have a
visible ancestor chain; a locally visible child under a hidden external ancestor
must not become an admitted source. Camera points exclude dormant/dead roots.

## Exact aggregate transport

The actor now uses closed snapshot schema 2 for the new boolean and immutable
configuration field, while retaining the compatible method revision; do not
silently default a missing field or accept a mixed old/new envelope. There are no
accepted production C30 saves to migrate. The existing rusher greybox parent local
version is bumped to 2 for its nested schema; historical evidence keeps its original
source attribution.

The parent retains all four source IDs in bindings and snapshots, and validates
the exact dormant/activated/dead set against beat, route and completed prefix.
It also validates dormant positions against actual authored source positions;
the actor alone cannot authenticate level placement or activation entitlement.

Prevalidate all actual actor snapshots, the saved Player, Scheduler, mechanisms
and framing records without mutation. Staged collision state is the existing
enabled=true/layer2/mask1 description only for a saved live leased source, measured
against the retained actual capsule even when the current actor is dead/dormant.
Never manufacture a proxy body or mutate current collision to validate an earlier
live snapshot. Dormant/dead snapshots never stage a hidden live reservation.

Merge each source's nested owner_positions, owner_velocities and
owner_collision_states by its stable ID. Repeated top-level
`bindings.merge(staged, true)` would overwrite earlier sources' maps.

After whole-aggregate validation: commit saved Player, commit every actual actor
and its derived lifecycle flags, commit Scheduler against those actual actors,
then commit each source exchange and mechanisms. No yield, configure, activate,
damage, cancellation callbacks or new reservations occur inside restore. Rebuild
cue/art silently from public saved state and restore the parent's bound framing.
Earlier-live/dead to earlier-dormant and earlier-dormant/dead to earlier-live are
valid only as exact whole-aggregate restoration, never as gameplay reactivation.

## Prospective admission

Keep the seven authored context keys closed. Pass world_root separately instead
of admitting caller-supplied player stats. A pure input helper builds the same
resolved role, lunge and fresh public Player response for preview and start.
Resolving for preview must not store role/profile/cycle or change actor diagnostics.

Preview requires an activated actor and actual shared17 containing world root,
which includes the sibling Player, level, Scheduler, source, floors and blockers.
Return the complete native scheduler preview. The parent fits actual source/art,
the measured corridor/endpoint, hero, selected landing and attack position before
the tell, then synchronously supplies the unchanged result to start's fourth
argument. Start passes it to shared request_lunge and stores state only after
accepted admission. Legacy two-argument calls retain the existing live proof path
with an empty optional preview. Nonempty preview requires a valid explicit world root.

No request-and-cancel preview, saved historical preview, manual endpoint or private
shared clock is introduced. Retain only the parent's minimal accepted-reservation
framing records under its own strict snapshot schema. A circle override later uses
the actual accepted C30 opening, with both returned proof times checked against
the C30 stationary recovery. Shared19 circle callback/pending-segment safety is adopted through shared20;
its complete conditional native schema2 envelope must be preserved. Authored
compound timing, whole-source tick custody and pause/restore still need checks.

## Narrow authored fixture and remaining checks

The new [dormant/preview fixture](../../../tests/acts/act1/a1_l2_dormant_preview.gd)
composes the actual shared Game, Player, committed layout, native Scheduler and
four retained capsules at `(0, .005, 13)`, `(-2.8, .005, 0)`, `(2.8, .005, 0)` and
`(0, .005, -14)`. Its parent guard is pure, granted solely by successful public
begin_encounter and cleared after each activation attempt. The fixture contains
dormant snapshot/frozen/untargetable checks, guard/native-footprint negatives,
preview purity/correspondence and forgery checks, injured repeat rejection, quiet
exact dormant/live/dead paired restores and malformed later-source atomicity.
Owner execution passed71/0 on shared20; the first45/1 result and exact sources are
preserved in the archive above. A 45-second watchdog bounds the fixture.

Executed owner-run commands from the assigned worktree:

```sh
python3 scripts/dev/dev.py engine --headless --path . --script tests/acts/act1/a1_l2_dormant_preview.gd
python3 scripts/dev/dev.py engine --path . --resolution 540x1170 --script tests/acts/act1/a1_l2_rusher_greybox.gd -- --portrait
```

The broader main-level composition/portrait obligations below remain a plan;
the bounded default-live/dormant/preview cases above have executed. The new
fixture covers dormant/warning/dead aggregates, not unfinished active movement or
full route progression; the existing greybox fixture covers genuine active motion
under its default-live setup after the affected owner rerun.

1. Existing default-live costume greybox admission, recovery, real primary,
   earlier-live restore and silent transport remain unchanged in meaning.
2. Four actual configured/bound nodes retain the same physical shapes; dormant
   nodes remain hidden, noncolliding, untargetable and frozen through real ticks.
3. Only the entitled chosen source activates at a fresh boundary; repeat, wrong
   boundary, already live/dead and forged future activation reject without heal.
4. Direct dormant damage/preview/start reject with no lease, reload credit or cue.
5. Exact initial/dormant, warning, unfinished-active, cancelled and dead snapshots
   restore across opposite current lifecycles without callbacks or new admission.
6. Forgeries in dormant HP/history/lease/cooldown, route/beat flags, source identity,
   moved/changed capsule, hidden art leaf or missing source reject before mutation.
7. Multi-actor staging retains all four IDs; malformed later actor rejects the
   entire aggregate without moving, enabling or healing an earlier actor.
8. Pure actor preview preserves HP/state/events/diagnostics; fresh correspondence
   admits once, while changed hero/world/source/cooldown/role/clock preview rejects.
9. Actual portrait views verify no future/unchosen targets or hidden hazards and
   readable selected source/corridor/endcaps/landing/ordinary-primary opening.

Changed paths are the owned actor, rusher greybox parent scene version, new narrow
fixture and this note. No existing fixture is edited. The costume leaf and
shared modules need no changes if root-only hiding preserves their current guards.

Sources inspected: [owned actor](../../../scripts/acts/act1/rush_selenite.gd),
[costume leaf](../../../scripts/acts/act1/rush_selenite_art.gd),
[greybox aggregate](../../../scripts/acts/act1/rusher_greybox.gd),
[existing fixture](../../../tests/acts/act1/a1_l2_rusher_greybox.gd),
[shared measured motion](../../development/BODY_SWEEP.md),
[shared prospective admission](../../development/LUNGE_PREVIEW.md), and
[shared dash presentation](../../development/PLAYER_DASH_FRAMING.md).
