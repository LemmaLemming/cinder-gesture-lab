# A1-O3 native reuse preparation

Read-only source review; no engine, parser, gameplay, portrait, balance or O3 acceptance credit. No project files changed. This is an implementation reuse plan, not the authoritative level design or equipment allocation.

## Recommended boundary

Implement an O3-owned CinderLevel controller/layout/aggregate over the existing C32 component and one shared Scheduler. Do not subclass the complete court or reinterpret its saved envelope: the controller, layout and codec require A1-L4's exact eight native IDs, five rooms, King, helper history and roundel (selenite_court.gd:66, 791; selenite_court_codec.gd:29, 57, 91). mushroom_caverns.gd provides useful C32 admission/cleanup patterns but its base builds grotto geometry and explicitly refuses a campaign aggregate (lines 51, 740, 746); it is not a generic optional court host.

No genuine missing shared implementation API was found for three finite guard formations, a contact bell, one pre-final checkpoint and a contact exit. Existing shared runtime remains Integration-owned; canonical registry registration follows the established handoff. The new controller, formation metadata, progress validation, bell geometry and aggregate are Act1-owned work. This source inspection does not guarantee that a chosen formation will obtain an actual safe native admission.

## C32 creation and birth

- mushroom_selenite.gd:140: configure("C32", stable_id, true, false), before binding. This keeps canonical A1-E3 / 24 HP / stationary 2.0-length, 0.38-radius thrust and existing timing data; no enemy type or controller fork.
- Allocate each finite source once in _ready, at its authored position, retain its actual handle/collision/cue/art/configuration, then bind(scheduler, hero) after entering (448). Scheduler and Player must be in the same World3D and run before the guard's physics priority 100; court parent priority is 200.
- activate() (307) requires an actual fresh Scheduler profile at clock 0, no committed exchange, pristine dormant full-HP source, and a parent activation_guard with a one-source entitlement. Native birth emits state_changed. Do not write dormant, HP, cycle, clocks or visibility directly.
- Future formations remain pristine dormant. For separate finite formations, end the cleared epoch and start the next before one-time activation of its own identities. If the design keeps living identities while changing arrangement, retain the epoch/HP/cycle/profile and native cooldown; court's same-pair change uses cancel("court_formation_inward"), never rebirth (selenite_court.gd:165).
- activate_court_entry and court movement functions are specifically gated to the exact A1-L4 helper IDs/script. O3 should use ordinary stationary activation and needs none of those special King/helper APIs.

## Bell and formation admission

Use a normal Area3D plus CinderInteractionCue.present("available"|"active"|"spent", "contact") (interaction_cue.gd:35). The cue supplies presentation only. Reuse the guarded/deferred contact structure from selenite_court.gd:501-514: actual body == hero, native overlap, running/current stage, cue/area/framing custody, a pending flag, call_deferred, then recheck before native lifecycle changes. It prevents a repeated body-entered event or stale callback from starting another formation and avoids changing collision flags during physics-query delivery. Keep attack controls separate; bell contact is not a damage target.

For every attack:
1. Read pure_presentation_state() / get_spore_response_state() / scheduler.source_control_state(actor); avoid state()/reservation_state() in pure custody checks because those can prune (mushroom_caverns.gd:290-326; mushroom_selenite.gd:650-659).
2. Pass target and the exact closed context to preview_start(target, context) (473): encounter_id, world_revision, recognition_s, attack_input_margin_s, escape_directions, return_directions, floor_regions, world_root. Use the actual common same-world parent and real retained floor collision/safe rect. Court uses 16 planar escape/return directions, recognition 0.18 and input margin 0.08 (selenite_court.gd:582).
3. Retain the native candidate/proof. Require ordinary-only response (no blast/invulnerability), primary after active end and complete response within recovery. Present source, full footprint and genuine safe landing/primary opening together; camera_framing_plan feasibility alone is insufficient—current camera_framing_error must also pass (court:226-268, 614).
4. Call start(target, context, preview) (480); it requests the actual shared stationary lease. Recheck same source/Player/Scheduler, source transaction completion and exact returned reservation against current source_control_state before retaining the witness or publishing an admission. Base mushroom_caverns.gd:290-344 is a stronger explicit post-callback custody template.
5. Preserve the returned original proof and lease ID for capture; a forecast is only presentation state, never admission authority.

Concrete formation vocabulary already exists: court runtime uses parallel target = source + (0,0,2), inward target = (0, source.y, source.z + 1.6) (court:234-243). Do not confuse this actual inward diagonal with layout's illustrative +/-X facings (layout:66-70). A third arrangement still needs root-authored positions/targets/meaningful gap and fresh native proofs; no new attack geometry is implied.

## Progress and lifecycle

Use one closed O3 stage model including bell state, current/awaiting formation, completed prefix and final checkpoint state. After actual second-formation defeat and retirement, publish request_checkpoint(stable_id, "encounter") at a settled boundary before starting the final epoch. Set the awaiting/final-gate state consistently before the deferred Shell save; a synchronous checkpoint observer may pause or dispose the level. Recheck retained lifecycle after event delivery.

CinderLevel request_checkpoint (268), request_completion (245), request_contact_exit (256) provide event/idempotence machinery, not O3-specific completion legality. The O3 controller/aggregate must reject premature progress and require the genuine completed formation prefix. Contact exit requires completed level plus actual Hero/Area overlap and matching saved capsule geometry. Retain final dormant sources in the pre-final checkpoint, so Retry restores that exact boundary rather than recomputing or skipping formation history.

Use normal exit cleanup while the tree still exists: mark stopped, disconnect parent/Hero/source callbacks, cancel actual guards, disable their processing/remove enemy group, end Scheduler, disable contact monitoring, clear cues and forecast/proof caches, disable parent processing (mushroom_caverns.gd:752; court:1166). Do not free a donor before its normal level exit.

## Exact aggregate / quiet restore

Implement a small O3-specific closed codec; reuse native envelopes, not field-by-field reconstructed enemy state. Save complete stage/prefix, exact source IDs/configurations, actual native actor packets, Scheduler packet, original proof/framing witnesses and progress. Parent court's prevalidator is intentionally not reusable for this different topology.

Capture from a paused boundary: scheduler.snapshot_state(bindings), then actor.snapshot_state(paired_scheduler) (court:866; guard:1432-1466). Guard envelopes support ordinary schema 1 and schema 2 when native pending segments exist; do not silently discard pending data. No spore consumer is required.

Restore construction:
- Override restore_candidate_construction_required() true. _on_enter_restore_candidate binds real fresh sources and pins their ready-time configuration SHA and positions.
- Build exact exposed-prefix descriptors using api_revision "act1-restore-recipient-construction-1", source_id, room_id, installed_rooms, installed_fields: [], configuration_sha256, authored_position.
- Guard.construct_restore_recipient(candidate, descriptor) (208) is generic across CinderLevel owners. It requires the parent's pure restore_recipient_construction_error entitlement and true retained same-world aliases; it only exposes a pristine recipient once. Three rooms fit its bounded maximum of five. Do not call ordinary activate during restore.
- Prevalidate each actor with actor_snapshot_error(packet, saved_scheduler, saved_player); merge staged_actor_bindings into scheduler bindings and saved Hero position, then validate Scheduler and the whole O3 stage/progress/proof.
- Commit actual Player first (Shell), all actor.restore_actor_state, scheduler.restore_state, then actor.restore_exchange_state (court:1022). Restore O3 metadata and contact/art presentation quietly. This preserves original clocks, cooldowns, HP, phase, current warnings and finite history without replay.
- Supply normal live capture and explicit snapshot_state_for_presentation + _restore_candidate_presentation_error optical hooks using actual camera/HUD. Quiet cue reconstruction can use the existing save/block-signals/restore pattern at court:1049, followed by binding/readback checks.
- Existing CinderLevel physics-registration opt-in defaults false (level.gd:116). Court currently uses false; O2 opts in. Choose based on O3's actual query/constructor requirements, without treating an available API as a new prerequisite.

## Focused checks to adapt

- a1_l4_curtain_greybox.gd:101-164: real C32 lease and lane, warning/lock/active/recovery, full legal ordinary escape, recovery primary, native damage cancellation retaining cooldown. Its GUI gesture path is a reference, not a mandatory full-route gate.
- a1_l4_whole_entry.gd:101-139: factual same-pair arrangements and checkpoint/contact sequencing, with explicit TEST damage/placement disclosed; King/helper portions are irrelevant.
- a1_l4_whole_save.gd:512-568: one-shot constructor refusals, pure whole prevalidation, Player->local quiet commit, actual optics, zero callbacks, malformed identity/clock/progress refusal with unchanged donor/disk.
- a1_l4_whole_save.gd:571-617 and the accepted O2 campaign fixtures: real public Shell/isolated Store Save, fresh disk Continue, enabled Retry button, distinct identities, protected Story, no unearned reward and cleanup.
- For O3 target bell duplicate/foreign contact refusal, each actual formation admission, pre-final checkpoint and Retry, representative active-warning Save/Continue, completion/exit/once-only stamp, and brief portrait inspection. Reuse unchanged component evidence; no full-route or every-enemy defeat is an acceptance prerequisite.

No equipment/ability decisions, catalogue queries, allocations, implementation or tests were performed by this preparation task.
