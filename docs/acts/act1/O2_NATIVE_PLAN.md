# A1-O2 native aggregate / constructor integration plan

Source reasoning only, 14 October 2026. No engine, parse, gameplay, Git,
mailbox, ledger or active-checkout edit. Root owns the host and final
implementation. `A1-O2.md` is the chosen composition; source pins accompany
this note. Existing file headers describing L3 as a private draft are historical,
not a current acceptance assessment.

## Native interfaces that accept O2

- `Actor.configure("C31"|"C32", stable_id, true, approach)` accepts O2 IDs;
  C32 must keep approach false. Base `_ready` constructs virtual
  `_all_source_ids`/`_source_spec`, then pins actual actors, capsules and cues.
- `Actor.bind(actual_scheduler, actual_hero)` is immutable and must precede
  protocol/constructor work. Keep all nine actual actors as direct children.
- `NativeProtocol.configure(actor, scheduler, hero, source_id, controller_id,
  "hero", {world_root, floors})` accepts generic IDs and the actual nearest
  containing world/floor handles. It retains body/resource/scripts/configuration,
  static signatures and native aliases. Its `binding_state()` supplies the
  immutable descriptor; do not reproduce that descriptor privately.
- `Repulsion.configure(consumer_id, normalized_directions)` before tree entry,
  then ready `bind_environment({world_root, floors, fields, sources,
  source_protocols})`. Each map must contain actual retained handles.
- `Field.configure(field_id, [{id:"cluster-left",offset:Vector3},
  {id:"cluster-right",offset:Vector3}], {radius:1.5,duration_s:3.0,
  thinning_s:0.5})` before tree entry, with its frozen position set before add.
  Two anchors are mandatory. Native fields own their independent clocks.
- Actual `Actor.construct_restore_recipient(candidate, descriptor)` is generic
  to the nearest ready CinderLevel and exact original Actor script. It is not
  an L3 whitelist. Its pure parent callback is
  `restore_recipient_construction_error(actual_actor, descriptor) -> String`.
- Native ActorCodec `configuration_error`, `schema_error`, `context_error`,
  all actual Actor capture/validation/physical/exchange/staging methods,
  Scheduler capture/error/restore, Field capture/error/restore and Consumer
  capture/error/restore accept the O2 contexts below.

Base `_admit`, correspondence/custody rejection, body/neighbor guards, render
state and exit cleanup dispatch virtually and remain reusable with O2 membership.
Base's literal Layout/GrottoArt/floor/scenery/context guards remain the chosen
14x72 world. Changing child constants does not replace that world.

## Methods that cannot be used unchanged

Full/Route/RouteCodec enforce nineteen named actors, five L3 rooms, four fields,
L3 epoch/consumer/controller IDs, four checkpoints and completion at beat 5.
Their construction/capture/validation/restore mechanics are patterns to adapt,
not callable topology adapters. Do not subclass them or copy their full FSM.

In particular Route `_install_authored_room_environment` rejects an existing
field instead of reusing it; `_topology` blindly appends room fields; native
source callbacks/route guards/current framing look up literal L3 tables.
O2 needs small owned equivalents for this exact composition. Base only captures
a refused scaffold; implement O2's local/whole hooks directly against CinderLevel
and unchanged native codecs.

## Lifetime topology and partial installation prefixes

Use the Layout agent's exact chosen group IDs consistently. Let G0/G1/G2 mean
first/paired/final, each with its disjoint frozen 2/3/4 source-ID array.

| Stable boundary | Installed consumers/groups | Unique installed fields | Activated/bound actors |
|---|---|---|---|
| first approach | [] | [] | [] |
| first active; next paired approach | [G0] | [bloom-near] | G0 cast |
| paired active; pre-final checkpoint/approach | [G0,G1] | [bloom-near,bloom-far] | G0+G1 cast |
| final active; complete/contact | [G0,G1,G2] | [bloom-near,bloom-far] | all nine |

Installation count is completed group count plus one only while active. An
internal preparing/binding/progress callback boundary is not serializable.
Every previous group must be genuinely dead; all future actors must equal their
whole actual pristine dormant packet, not merely HP/dormant flags. Every
installed group uses spores, so bound_source_ids equals activated_source_ids.
The unique field union is first-occurrence ordered, never repeated entries.

G0 binds only near; G1 and G2 each bind the same actual retained near and far.
Field exclusivity is local to a single `bind_environment` map; each coordinator
subscribes its own `_on_activated`, and the Field has no exclusive consumer.
Permanent actor consumer identity forbids moving an actor between groups.
Keep completed actors/consumers/protocols and all fields alive for the attempt.
An old coordinator can receive a later near release: `step_source` cleans dead
records without creating an episode. Its later captured near reference uses
the field's CURRENT original clock/generation, not a frozen previous-group copy.
This is structurally supported but has not been executed as an O2 composition.

Ordinary transition: require actual unpaused quiet callbacks/leases and old
genuine clear; current full prospective source/body/Player/neighbor/view guards;
end the old epoch; begin one real new profile/epoch; use actor.activate with
one exact consumed source entitlement; install only the new field if absent;
configure that group's protocols; bind one new consumer to retained field(s).
No yield or capture between activation and completed native binding. If current
view is blocked, remain at the clear/approach boundary. A camera forecast does
not grant activation or an attack. Never reset fields or change flags manually.

Exactly one public checkpoint is emitted after G1's genuine all-dead boundary,
while final is dormant and Scheduler idle: spore-bloom-ready. Final completion
is spore-bloom-clear; only subsequent actual bloom-exit contact may depart.

## Closed native packet shapes

Actor common keys: api_revision,schema_version,role_id,source_id,configuration,
hp,dead,dormant,motion,hurt_left_s,approach_driving,role_encounter_id,profile_id,
resolved_role,reservation_id,cycle,sample,hit_ids,last_cancel_reason.
Motion is position/velocity/facing/grounded; exact serialized Vector3 arrays.
Schema1 ordinary; schema2 adds nonempty pending_segments; schema3 adds repulsion;
schema4 adds both. Pending segments retain from/to/start_s/end_s and the actual
contiguous single-tick path, including the exact final paired source/Hero tick.
Repulsion retains api_revision,consumer_id,source_id,episode_id,phase,direction,
progress. Dead previously-bound actors retain schema3 and their permanent
consumer stamp with no live episode. Future dormant actors remain schema1.
Do not strip a valid schema2/4 or invent a dead/pending normalization.

Field schema1 keys: api_revision,schema_version,definition,geometry,clock_s,
generation,spent_ids,activation_s,deadline_s,phase. Definition, geometry and all
counter/scalar/optional deadline types must retain the native writer's exact
values. Native snapshots reject refresh/spending/history inconsistencies.

Scheduler uses the actual complete ordinary schema1 packet from this cast,
including collision fingerprint, clock, profile, serial, leases and cooldowns.
No replay cancellation or sampled-circle authority is introduced by O2.

Native Consumer schema2 keys: api_revision,schema_version,definition,
field_geometry,source_environments,field_references,serial,records,failures,
source_protocols. Each source record retains episode_id,phase,age_s,phase_age_s,
members,direction,progress,original_endpoint,route_revision,route_started_age_s,
route. Route is null or the WHOLE native Route schema1 packet. Preserve its
exact world/floor/body signatures, original/current motion, direction, travel,
elapsed/remaining history and leased state. Native validators remain authority.

Every live Scheduler lease has exactly one original six-field accepted witness:
reservation_id,landing,attack_position,primary_time_s,response_complete_s,
action_escape. The latter is the whole original accepted native proof, including
its exact four- or six-segment path and flags. Base's three-field `_framing`
cache is insufficient. Connect an owned recorder to native_admission_published
before external observers; recheck actual custody; encode a detached original
answer and never regenerate the proof. Remove only genuinely retired witnesses.

## Exact capture and validation interfaces

Host's bindings map should carry actual level/player/scheduler/actors, nullable
all-field/all-consumer maps, protocols per group, scheduler_bindings and exact
pure runtime/saved-mechanical-guard Callables. Runtime guard pins paused stable
boundary, exact retained node/script/resource/parent/world aliases, all native
callbacks/guards, no constructor/activation entitlement, floor/scenery and
complete art/cue/contact resources. Native validators cannot replace this guard.

1. At the deferred paused boundary validate actual Player and capture its exact
   whole packet; capture Scheduler with actual scheduler_bindings().
2. Pair = {controllers:{CONTROLLER_ID:whole_scheduler},players:{hero:whole_player}}.
   For every bound source use its retained protocol.current_unit(pair); for
   future unbound actors use actor.capture_state(whole_scheduler).
3. Capture each installed Field ONCE. Uninstalled field slots are null.
4. For each installed group use ONLY this exact context:
   {fields:{its_field_ids:the_same_whole_field_packets},
   sources:{its_source_ids:their_complete_actor_packets},
   controllers:{CONTROLLER_ID:whole_scheduler},players:{hero:whole_player}}.
   consumer.snapshot_state(context); uninstalled consumer slots are null.
   Do not pass all nine sources or both fields to G0: context membership is exact.
5. Pure state validation must check own closed structure/progress/topology and
   actual configurations, Player.snapshot_error, each actor.snapshot_error with
   whole Scheduler/Player, native Field.snapshot_error and Consumer.snapshot_error.
   Compare actual immutable Field definition/geometry and original saved values.
6. Obtain each actor.staged_actor_bindings(saved_actor), merge only its exact ID
   into owner_positions/owner_velocities/owner_collision_states on a COPY of
   actual scheduler_bindings. Add hero_positions:{hero:saved_player.motion.position
   decoded by native Codec}. Preserve actual world/floors/owners; then invoke
   scheduler.snapshot_error(saved_scheduler,staged_bindings). Compare the actual
   captured immutable collision fingerprint to saved collision bytes.
7. Require future actors' complete packets to equal actual pristine captures;
   native ActorCodec.context_error validates all saved actor/config/pair values.
   Complete saved action-proof mechanical/body-floor/threat-union/reach/recovery
   checks and exact progress/contact correspondence remain owned host obligations.
8. Recheck all actual retained runtime identities/barriers after queries.

These functions do not advance clocks, call live pruning state readers, emit,
redraw, configure, activate or repair resources. Generic `state()` is not a
replacement for pure native accessors. Diagnostic last-error writes are native
diagnostics only; no gameplay or proof cache is mutated by validation.

## Fresh candidate: supported one-shot construction

`restore_candidate_construction_required() -> true` and the pure off-tree
`restore_candidate_physics_registration_required() -> true` opt in to existing
Shell operation-scoped candidate registration. Actual immutable floor/query
scenery must already exist in `_ready`. Do not add an owned registration wait,
engine loop or alias to a donor/installed world.

1. Shell owns creation of actual paused nonplayable world, real Hero, camera,
   effects/HUD and the registration frame. O2 receives saved local/Player in
   `_on_enter_restore_candidate(local,saved_player)` after ready.
2. Bind all nine ACTUAL pristine actors to the candidate's unbegun Scheduler
   and actual Hero; attach normal owned source/Hero observers and resource pins.
   Do not call ordinary enter/start/begin/activate or consume a gameplay epoch.
3. The structural codec returns the exact installed prefix. Pure bounded
   preflight also validates whole saved Player/native ActorCodec contexts,
   literal numeric types, Scheduler structure/epoch ownership and proof history
   against TRUSTED actual configurations. Full world/native Field/Consumer
   validation comes after their actual handles exist; do not claim off-tree
   metadata checks certify static collisions or route/current optics.
4. Build each activated source's descriptor from actual pinned configuration
   and authored ready position. Exact keys/values:
   {api_revision:"act1-restore-recipient-construction-1",source_id:ID,
   room_id:ITS_GROUP,installed_rooms:ORDERED_INSTALLED_GROUPS,
   installed_fields:UNIQUE_ORDERED_INSTALLED_FIELDS,
   configuration_sha256:Exact.stringify(ACTUAL_CONFIG).sha256_text(),
   authored_position:Codec.vector3(ACTUAL_AUTHORED_POSITION)}.
   Descriptor bounds are at most5 unique rooms and4 unique fields. Native Actor
   validates source/config/hash/origin and owning candidate, not prefix semantics.
5. Open a copied exact entitlement map. Parent construction callback returns an
   empty String ONLY for the same retained actor/script/direct parent/world and
   exact copied unused descriptor while candidate and barriers remain valid.
   Call actor.construct_restore_recipient(self,descriptor) for ALL activated
   prefix actors before any native saved-state commit; consume entitlement on
   EVERY attempt and close/clear after loop or failure. Native constructor
   exposes a real pristine living recipient silently; no role/cycle/HP/clock,
   motion, ground, exchange or stamp is assigned. It requires Scheduler clock0,
   empty profile/leases/cooldown. Failed partially exposed candidates are disposed.
6. Construct each installed field exactly once in prefix order. For each group,
   configure native protocol for its now-real exposed recipients, then actual
   consumer with its exact near/near+far handles. No saved pose or death is applied
   until every required permanent consumer binding exists. Fresh native feet
   support is measured, not fabricated is_on_floor/grounded flags. Episode
   cancellation after playable resume still demands actual grounded response.
7. Now run the COMPLETE paused pure validation described above. Candidate still
   retains its actual pristine living prior-group recipients until quiet commit;
   a saved prior-group dead packet is validated as data, not used for binding.

## Quiet commit and actual presentation gate

No yield/events/activation/solver request; all native validation completed first:
Shell restores saved Player; confirm exact actual Player packet; restore each
installed Field ONCE; actor.restore_actor_state for ALL9; actual Scheduler
restore_state with staged real owner/floor/world bindings; actor.restore_exchange_state
for ALL9; each installed Consumer.restore_state(original_packet,exact_context);
then local metadata/original witnesses and quiet art/cue/contact synchronization.
Restore checks retain original pending paths, clocks, dead prefix and spent fields.
No native commit rollback is assumed. On unexpected failure latch the error,
freeze/dispose candidate and return false from restore_state; guard finish too,
because CinderLevel's void local hook can otherwise mark a candidate ready.

Keep saved mechanical preflight separate from actual current optics. The
`_restore_candidate_presentation_error(actual_camera,actual_hud)` hook receives
the real candidate camera with saved native focus and canonical laid-out HUD
after quiet commit. Require same ready viewport/world/native camera, exact fixed
billboard basis, actual Hero body/billboard/shadow, current source/body/cues,
field/anchor art/retreat endpoints, original live proof landing/opening and
contact bounds. Use existing public camera_framing_error_for_context with actual
Hero/camera/HUD; never borrow installed/donor positions or infer current fit from
camera_framing_plan. Preserve complete point union before convex compression.
Live snapshot_state_for_presentation uses the same explicit actual context.

## Normal disposal and focused risks

Close owned admission/constructor/activation/progression first. Interrupt each
actual source's original consumer route (actual_death for dead actors, exit
reason otherwise), disconnect owned Field callbacks, stop each Field once,
disconnect each consumer's own activated callback from its fields when retiring
it, then normal inherited source/Hero callbacks, source.cancel, Scheduler.end,
group/cue/forecast and level cleanup. Release routes through native API; never
overwrite an external injury impulse. Prefer public level.exit_level while tree
handles are valid; off-tree fallback must not call native viewport/state logic.

Most likely concrete risks: near/far expanded full circle intersects retained
stalk/scenery; prospective four-body/field/retreat union exceeds protected portrait;
near release reaches multiple consumer subscribers after earlier deaths; stale
reference copies make old consumers disagree with a shared live field; original
pending native sample lost; future body never genuinely settles before new
epoch; generic Base admission ignores an active environmental neighbor endpoint.
O2 must append each actual native consumer endpoint to Base neighbor corridors
and retain real Player committed-dash spacing/current-view guard before spore
cancel/continue, as Route does, using O2 membership and all relevant live bodies.

Suggested narrow first test: actual first native field +2 recipients, ordinary
cluster hit, no field HP damage, no refresh, full original route/hold/regroup,
then real group clear and second consumer sharing unchanged near. Later affected
aggregate/Shell/portrait checks follow Root's selected focused scope. No broader
accepted-level rerun, new balance result or runtime success is claimed here.
