# A2-O3 Bleached Canal: API and focused-check preparation

Status: read-only preparation while O2 formal acceptance is pending. No O3 implementation, ledger allocation, engine/import, Git mutation, new UID, pixel review or test result is claimed. Root remains the Act 2 owner and controls promotion and the canonical engine queue. Current shared contract is `campaign-shared-52`; original parent results retain their original revisions.

## Confirmed scope

[Canonical O3 research](</Users/howardchen/Documents/ChatGPT/video game idea/docs/reference-library/act2/research/levels.json:479>) requires **three familiar threat arrangements across broad dry pockets**, then an opened contact exit. Parent is accepted A2-L4; the checkpoint is **before the third arrangement**. Target 3–5 minutes and initial budget 5 are pacing proposals, not compulsory timers or acceptance gates. The reward is a cosmetic/completion stamp without stat growth.

[Act concept](</Users/howardchen/Documents/ChatGPT/video game idea/docs/ACT2_CONCEPT.md:188>) specifies reused weed/bleached weed, dry road, flood margins, villa walls, Scouts and Handlers; additions are exactly three route signs and one small canal-side scenic prop. Bleached vegetation is scenery, with no collapse or underwater section. Quiet links offer navigation or short tableaux, not forced waiting. A continuous dry causeway is a compatible composition of those pockets. Root's earlier “Ray ambush” shorthand adds no ambush requirement and cannot reduce the objective to one encounter. No Tender, SmokeBank, B05 completed-dash bait rule, boss, new input or ability follows from these sources.

Canonical [Registry](</Users/howardchen/Documents/ChatGPT/video game idea/data/campaign/registry.json>) currently accepts A2-L4 at `1a5e9ea197233fe2f5db808dfcce2e8288f79845`; A2-O3 remains `unimplemented` with null scene/accepted pin. Its existing reward ID is `A2-O3-completion-stamp`, policy `once_only_completion_stamp_no_stat_growth`. L4's historical handoff opening still says acceptance pending; that original wording does not supersede the current Registry. No new reward/resource/equipment type, pickup, perk or powerup is selected here.

## Minimal composition and parent reuse

Use a **new owned CinderLevel**, a small finite three-arrangement progression model, and one real shared Player/effects/Scheduler epoch. Compose unchanged existing Ray actors/driver and Handler actors/Lane consumers as Root's authored cast requires. Keep source activation, checkpoint admission, completion and contact exit in the new host. Root's current **provisional four-actor proposal** is a single Scout, a single Handler, then a Scout+Handler pair. It supplies all three documented arrangements, but has no production/native credit yet. Actor IDs, exact positions/floor extents, contact regions, scene path and closed local field count are still to be authored; this brief does not invent them.

Do not inherit or call L4's full `_ready`, `_on_enter_level`, `LondonSequence` or snapshot rules unchanged: they instantiate nine actors, three Rays, four tools, two Banks, five rooms, two blockers and specific nine-defeat/contact prefixes. O3 has no Bank/Tender dependency. Likewise, `LondonFloor.build()` and `LondonKit.build()` are a long main-route composition, not a compact optional-level factory.

| Need | Existing exact seam | O3 obligation |
| --- | --- | --- |
| Dry continuous support | [LondonFloor `_box_body` / `build`](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/scripts/acts/act2/london_approaches_floor.gd:18>) returns actual `body`, `collision`, `safe_rect` bindings with named upright layer-1 static Boxes. | Prefer the smallest authored continuous support topology. If several Boxes join, their **capsule/skin-inset safe regions**, not only visible surfaces, must overlap. Preserve full ordinary dash/return room; no thin plank, pit or swimming rule. Reuse construction patterns, not L4's five hardcoded `SPECS` and blockers. |
| Quiet scenery | [LondonKit leaf construction](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/scripts/acts/act2/london_approaches_kit.gd:78>), existing `RedWeedVisual.build(parent,variant,seed)`. | Recompose existing road/flood/facade/bleached-weed/material families; source peer handles the selected art. Signs/canal prop remain nonactionable decoration unless explicitly authored otherwise. They do not impersonate attack/contact cues or become a fragment-collection objective. |
| Ordinary Scout | `WeybridgeScoutActor` / `RayScoutActor.configure(hero,effects,id)`, `snapshot_state/error/restore`, fixed low housing, HP30 and real defeat signal. [Actor API](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/scripts/acts/act2/ray_scout_actor.gd:53>). | Configure once, retain root/script identity, preserve exact `body_yaw`/direction/HP on restore, no reconfigure heal. The driver binds its incoming damage gate. Defeated actor remains in `enemies` until tree exit for same-action reload credit. |
| Ordinary Handler | Unchanged `SalvageHandlerActor`, [L4 `_new_mechanism`](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/scripts/acts/act2/london_approaches.gd:317>) and `_handler_window` at454. | Parent gate must use actual live lease/recovery deadline and low opening, then recheck source/Player/pause/death/cue/framing after callback-producing queries. A cosmetic recovery pose grants no damage authority. |
| Finite progression | [L4 `_flush_defeats`, `_flush_progress_requests`, `_on_world_action`](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/scripts/acts/act2/london_approaches.gd:500>). | Define three new finite groups and their real clear facts. Queue progression after actor damage transactions. Checkpoint must precede third admission, with current supported stable contact if contact is chosen; stale pre-clear “ever contacted” is insufficient. Preserve earned pending defeat/progress intents through a fatal boundary. |

No permanent stat growth, extra controls or gear allocation is necessary. Existing baseline/carryover equipment must retain ordinary escape and primary opportunities without pickups or blast ammo. The later Root playstyle/placement decision still follows the canonical design grid/ability workflow; this preparation does not reserve anything.

## Public combat APIs

[RayScoutExchange](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/scripts/acts/act2/ray_scout_exchange.gd:66>) already provides:

- `configure(hero,effects,scheduler,actors,profile_id,response_context) -> bool` for ready actual anchored actors, once per fresh host.
- `set_response_context_provider(Callable(actor_id,geometry)->Dictionary)` and `set_presentation_guard(Callable(actor_id,proposed_state)->bool)` at118/126. Both are ephemeral owner bindings, excluded from transport.
- `activate(actor_id,response_context={}) -> Dictionary`, `tick()`, `damage_window_open(actor_id)`, `cancel(actor_id,reason)`, `cancel_all(reason)`, `cleanup()/disarm()`.
- `state(actor_id="")`, `get_cue(actor_id)`, `get_opening_cue(actor_id)` and `scout_defeated`/state/hit signals. Public native proof is diagnostic; saved `presentation_witness` preserves landing/opening framing after fresh restore, while restored `proof` is deliberately empty.
- `snapshot_state(bindings)`, `snapshot_error(saved,bindings,staged_scheduler={})`, `restore_state(saved,bindings)` at758/779/792.

Reuse the ordinary behavior: live Hero tracking during warning → immutable committed capsule → active → recovery. Do not import the L5 Sentry's sampled completed-landing bait. Standard raw Ray data is damage10, windup1.55/lock1.10, active0.16/recovery1.60/interval1.60, HP30, stationary speed0, reach3.8/radius0.31. Shared Difficulty resolves the saved/fresh profile and timing floors. Returned lock deadlines, not a private timer or shorter animation, determine activation. The existing driver refuses pending-weapon arming and lost source/cue/presentation, retains cooldown on cancellation and consumes the swept hit opportunity before shared damage callbacks.

[Shared Lane](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/scripts/combat/lane_mechanism.gd:59>) provides `configure(id,geometry,opening,raw_role,timing_floors)`, `bind(scheduler,{"hero":hero})`, `preview_start`, `start`, `state`, `get_cue`, `cancel/clear`, and public snapshot/preflight/restore. Use the unchanged regular Handler `TOOL_ROLE` / floors at `weybridge.gd:21–22`: damage10, windup2.2/lock1.1/active0.2/recovery1.9/interval1.9, HP30/speed0. The fixed capsule pattern is `Geometry.lane(root,root+BACK*3.8,0.31)`; a different authored bearing must remain the same frozen geometry for cue and damage.

For a new host, **bind the current `Lane.set_presentation_guard` at101 once before cycle1**, including each fresh restore recipient. L4 predates that shared addition; copying its old constructor without the setter loses the supported late-publication parent guard. The native consumer owns swept paths and the one-hit latch; do not duplicate it. Its stationary attack is admitted **armed from warning** through `request_attack`, with its original stationary deadlines; it does not use the Scout's unarmed tracking/reproof protocol. Conversely, the Scout warning remains unarmed until its actual `commit_tracking` succeeds with fresh response and the full returned lock. A final mixed pair must retain that distinction in presentation, progression and saved records. Use fresh public response/stats for each future admission and treat `pending_weapon_id` as queued equipment rather than rewriting `stable` or inventing a private gear lock.

Scheduler public methods remain `begin_encounter(profile,id,revision)`, stationary preview/request, tracking request/update/commit, `reservation_state`, `cancel/cancel_owner`, `end_encounter`, `get_clock`, and snapshot/preflight/restore. Reuse these through the existing consumers rather than adding a controller or scheduler. Use one common actual world ancestor containing Hero, Scheduler, floors and sources: Hero is normally a sibling under `Game.world`. [L4 bindings](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/scripts/acts/act2/london_approaches.gd:670>) maps actual Ray actors plus Lane nodes as owners, with stable `{collision,safe_rect}` floor entries.

### Final mixed-pair seams

For Root's provisional final Scout+Handler, keep two distinct real Scheduler owners: the actual Scout actor and the persistent Handler Lane node. The existing Ray driver and Lane each retain their own geometry, reservation, original deadlines, phase, path/hit latch and low opening. The new host contributes a **view-only** union of both actual sources/cues, current and incoming full footprints, and accepted landing/opening witnesses; it does not copy a private source state or make one consumer's cosmetic phase authorize the other's hit.

[L4 `_activate_mechanism`](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/scripts/acts/act2/london_approaches.gd:392>), `_response_context` at435, `_exchange_framed` at587 and `_mechanism_framed` at600 are the relevant mixed-source assembly patterns. The Scout's fresh lock reproof considers the real already committed threat union; the stationary Handler preview/start must retain its actual corresponding source/opening/proof. Do not import L2's coupled Foot recovery rule, old full London sequence, or discard a valid source just because its partner changes phase. If the new union/callback guard rejects, use visible public cancellation with conservative original cooldown, not hidden re-request or a fabricated proof.

The smallest additional transport checks are **both sources genuinely running** and **one member actually defeated while the other remains running**, in each legal defeat order. Restore the dead member's exact tombstone and retained original consumer receipt, keep the surviving source's actual lease/deadlines/view, and emit no new damage/defeat/admission/progression. End the arrangement only from its authored real clear predicate. Third-arrangement admission stays blocked until the actual durable before-third checkpoint; exact Retry must return that complete earlier tuple. New mixed-pair layout/guard/interruption cadence is untested; existing L4 patterns establish available seams, not a new O3 native proof or shared blocker.

## Camera, cues and reachable return

[L4 `_required_source_points` / `_conservative_corners`](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/scripts/acts/act2/london_approaches.gd:569>) enclose **all actual visible meshes** before reducing each group to eight conservative world AABB corners. Its `_exchange_framed` / `_mechanism_framed` at587/600 include actual source, full harmful capsule/endcaps and original landing/attack witness. Reuse that geometric pattern, but use the current shared HUD APIs rather than copying inherited fixed safe-rectangle constants.

- `Game.camera_framing_error(points)` checks the actual current projection and canonical HUD; `player_camera_framing_points_for(hero,camera)` supplies actual full render/collision bounds; `camera_framing_error_for_context(points,hero,camera,hud)` checks the actual restored recipient. [Game APIs](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/scripts/game.gd:514>).
- Before admission, filter actual authored escape/return candidates and check the full current union **and conservative settled-follow endpoints**. Native Scheduler proof establishes support/collision/timing/ordinary opening; projection alone is not a response proof. A proposed camera fit cannot authorize currently clipped damage.
- Keep the close fixed portrait camera: nominal width7.2, no zoom/focus write. Native float properties need native conversion or projection-contract assertions, not exact comparison with a double literal `7.2`.
- `CinderLevel.camera_framing_points()` limits authored points to224; shared framing allows256 including mandatory Hero bounds. Current Hero supplies22 points. Bound groups using every real mesh corner; do not discard legs/openings or invent tiny useful-source boxes to fit limits. Cosmetic helpers that accept≤16 can use conservative eight corners enclosing all Hero points while mechanical checks keep complete required bounds.
- Include actual required native cue children, low attack opening, full harmful geometry and proved supported landing/return; current plus accepted view witnesses must remain visible together. Quiet/spent far corpses and nonactionable canal scenery need not force stale encounter geometry into the exit union.
- A new host should opt into CinderLevel's pure `_restore_candidate_presentation_error(camera,hud)` after quiet commit. [Base hook](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/scripts/campaign/level.gd:144>), existing opted example `cylinder_perimeter.gd:740`. Inspect actual restored native bounds/current saved projection, including a legitimate hidden staging ancestor outside the candidate world; reject hidden required children within that world. Do not repair visibility, move the camera, replace the actor or emit events there.

## Coherent state and optional lifecycle

Use the [CinderLevel](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/scripts/campaign/level.gd:93>) entry/exit and `request_checkpoint(id,"encounter")`, `request_completion(id)`, `request_contact_exit(id,hero)` APIs. Build the fixed complete recipient normally; no save-derived native HP, clock, root or controller construction is needed. The new O3 local envelope must close its authored three-stage history, checkpoint/pending facts, completion/exit facts, profile/revision, scenic cosmetic state, full Scheduler, full Ray driver and Handler actors/Lanes/views. Do not reuse L4's exact16 envelope/ID counts or include its Banks.

[LondonApproaches preflight/commit](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/scripts/acts/act2/london_approaches.gd:711>) is the relevant pattern:

1. Validate the complete already-staged Player and pure local/progression schemas. Stage only `bindings.hero_positions={"hero":Codec.read_vector3(saved_player.motion.position)}` for prospective sample checks; do not move a fresh Hero or substitute a diagnostic sample as Player authority.
2. Validate Scheduler and all consumer/actor tuples against that paired saved epoch/profile. Original roots/geometry/deadlines, hit/flash latches, cancelled/ended state, complete Ray deferred paths and conditional Lane `pending_segments` schema2 remain intact. No schema/key stripping, cooldown refresh, reproof or current-preference profile substitution.
3. Quiet commit: **actual Player (Shell) → all actual Ray/Handler actors and saved yaw → one Scheduler → RayExchange → Lanes → derived cues/views/props**. [L4 commit](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/scripts/acts/act2/london_approaches.gd:799>). Preserve signal-block flags. Ray driver commit checks its actual actor tuple and actual restored Hero; fresh-before-Player restore must refuse before mutation.
4. Couple Handler view to its exact reservation/target/opening and canonical admitted equipment. Preserve exact `response_complete_s == primary_time_s + primary_cooldown`, actual recovery bounds, inclusive capsule+skin-supported floor, ordinary range and real primary LOS. Approximate float comparison is not proof of copied deadlines.
5. Before third admission, compare current local checkpoint and the actual protected `side_attempt.checkpoint`, after the Shell's durable drain. Successful live checkpoint/completion may auto-resume; request a new public pause for assertions instead of assuming it stays paused. After the third real clear/quiet sources, end the encounter, request once-only completion, then require a distinct current Hero contact at the opened exit.

[Shell/Attempts](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/scripts/campaign/shell.gd:255>) owns optional/replay namespaces and protected Story. `configure_runtime(registry_data,save_path,settings_path,preferences_path)` occurs before tree entry; actual menu Optional/Replay signals perform supported entry. `capture_campaign_snapshot`, public pause/Resume, Store/Attempts and GUI Continue/Retry transport the complete unit. Early abandon or completed contact return restores the protected Story and shows Journey; explicit Continue exposes paused Resume. Completed optional re-entry uses supported Replay, not a second fresh `optional_requested` request. The cosmetic stamp is once-only and grants no stats.

Cleanup occurs through `exit_level()` before ordinary replacement/free. Base marks `_entered=false` before the owned hook. Close/disconnect owner callbacks, public driver cleanup, live Lane cancellation and Scheduler ending while recipients remain in-tree; disarm actors and release gates. Keep late fallback idempotent and never call live world `state()` on detached leaves. Shared51's detached Lane notification repair does not turn `state()` into a detached-position API. Existing parents/receipts remain frozen.

## Minimum focused checks, not a route gate

| Category | Small relevant new O3 scope |
| --- | --- |
| Loading | Initial real production Game/Shell entry; exact O3 ID/topology/source bindings; locked optional without A2-L4 completion and unlocked TEST parent prefix disclosed; initial complete snapshot and native current view. Integration owns final canonical Registry registration. |
| Mechanics | One actual ordinary Ray warning/tracking/full returned lock/immutable capsule/recovery and one real Handler lane/low primary opening, with zero blast ammo. Exercise each arrangement's authored trigger/clear predicates in bounded focused setups; preserve all three, not a one-encounter substitute. Test the new guard/candidate union and useful return, including one relevant canonical slow/minimum-range or profile constraint if the authored geometry depends on it; no all-kit Cartesian run. |
| Saves | Paused representative warning/armed state plus quiet state: complete Player + all required actors + one Scheduler + consumers → ExactJson/format2 disk → distinct fresh recipient. Compare the exact authoritative tuple and silence, including the final mixed pair both-running and one-member-defeated/survivor-running cases for both legal orders; refuse malformed source/root/epoch/progression/view/cursor and wrong actual commit order atomically. If an actual callback retains Lane schema2 or Ray pending path, preserve/resolve it once; never manufacture a pending path. |
| Retry | **Latest checkpoint before arrangement3**, not merely an early entry checkpoint. Preserve the committed living complete tuple, advance/injure through supported public actions or explicitly labelled legal focused setup, pause/dead Resume refusal, then actual GUI Retry and exact resource/profile/clock/input restoration. New preference must not retune the saved encounter. |
| Transitions | Third-arrangement clear → one cosmetic stamp → separate contact exit/Story return; early abandon and supported completed-level Replay; protected Story is unchanged. Label any focused TEST history/injuries/placements rather than calling them an earned full route. |
| Cleanup | Explicit old unit disposal and normal whole-Shell teardown: native actors, Scheduler leases/cues, connections, effects and WeakRefs removed; old gates cannot heal/rearm. No detached-world getter errors or hidden stale authority. |
| Brief visuals | Actual quiet causeway/bleached scenery and representative Ray/Handler source+cue+reachable return in the new pockets; before-third checkpoint and opened contact marker/sign vocabulary. Postdraw metadata uses actual current camera/HUD/source/geometry/Player/proof points. A few representative views suffice; no full-route gallery or automatic pixel-readability claim. |

Useful existing **helper/assertion patterns**, not scripts to rerun unchanged:

- [L4 initial transport](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/tests/acts/act2/a2_l4_full_transport_smoke.gd:17>): actual deferred pause, complete native aggregate, ExactJson and atomic missing/root/clock/progression refusals. Original113 at Shared30 is initial-state only, not O3 or running-state credit.
- [L4 retry](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/tests/acts/act2/a2_l4_retry_level_smoke.gd:202>): `_lc_fresh_continue`, `_lc_format2`, `_lc_valid_snapshot`, real `_lc_click` at232, actual fatal/dead Resume/earlier Retry and WeakRefs. Its bank/long-route IDs and634 at Shared35 do not transfer to O3's no-Bank/latest-third-checkpoint scope.
- [L4 live-input helpers](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/tests/acts/act2/a2_l4_live_level_smoke.gd:812>): `_dash`, `_routed_swipe`, `_routed_primary`, native probe120 and actual completed action witnesses; `_follow_proof` at529 preserves complete cadence. Reuse focused input/proof assertions, not its nine-defeat/full-route/capture set, bank tails or private observed-tail flags.
- [Shared L4 registration](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/tests/act2_l4_registration_smoke.gd:59>): actual Registry/Journey/Continue/Retry setup and helper methods at222–282. It remains L4 registration evidence, not an O3 registration check.
- [L4 fresh entry](</Users/howardchen/.codex/worktrees/campaign-act2/video game idea/tests/acts/act2/a2_l4_fresh_entry_smoke.gd:56>): public replay/restart/protected-return and real mouse/ScrollContainer click pattern. It hardcodes L4 IDs and original Shared36 SHA pins; the original6620 result is not a current Shared52/O3 command.
- Current `a2_o2_loading_side_smoke.gd` contains a closer optional namespace/Replay/latest-checkpoint setup pattern, but its own three actors/Banks/closed schema and native50 results remain O2-only. Do not copy its component packet into O3.

Root may create narrow loading/side and mechanics/brief-portrait fixtures after acceptance and promote all resources atomically. Prospective command templates, **not runnable resources yet**, from the assigned checkout are:

```sh
python3 scripts/dev/dev.py import
python3 scripts/dev/dev.py engine --path . --headless --script res://tests/acts/act2/a2_o3_loading_side_smoke.gd
python3 scripts/dev/dev.py engine --path . --headless --script res://tests/acts/act2/a2_o3_focused_smoke.gd
```

Use the existing recorder/queue workflow, fresh owned `docs/acts/act2/evidence/A2-O3/<new-leaf>/` capture packets, unchanged source freezes/modes, exact footer/error/UID accounting, and brief explicit graphical mode. No raw engine, duplicate import, lock deletion or broad `check`/all-suite rerun. New paths/flags/footer/manifests must be real and frozen before invocation; none exists by virtue of this brief.

## Dependencies and evidence limits

No concrete missing shared API is identified for the documented three ordinary arrangements, continuous dry floor, optional checkpoint/return or complete quiet transport. Needed work is new owned composition/progression/schema/framing and focused validation. If actual native proof, current/saved view or late callback custody exposes a reproducible shared failure, preserve that exact failure and send a narrow canonical REQUEST; do not fabricate safe paths, alter controls/timing/skin or copy a private shared kernel.

[Focused acceptance](</Users/howardchen/Documents/ChatGPT/video game idea/docs/development/LEVEL_ACCEPTANCE.md:9>) supersedes old L4 full-route gates. Existing accepted parent mechanics/art/source records may be reused only for unchanged leaves and their original scope. They do not prove O3 floor joins, new source approaches/return, latest checkpoint, optional completion or new pixels. Keep original failures/cancellations and forensic pinned fixtures. Full O3 playthrough, encounter pacing, balance, every kit, mobile and campaign-wide traversal remain untested and nongating. No O3 pass/readiness/independent acceptance is asserted.

## Source pins inspected

These are bounded current-source reads, not a transitive runtime/evidence inventory or engine import claim.

```text
e7d42cfa6d0943d5ba59223a3685c1865f4cd8bd93035c8d18070efaded27571  docs/reference-library/act2/research/levels.json
f5596e2bb8ec70dfc9e47df60272b6a9ef1b412b1e4af05413a1a6e618e5e696  docs/ACT2_CONCEPT.md
72485badf7c02c0338416c2e35ff74aaebee7a56565da00f55f1602927c36a2e  docs/development/SHARED_CONTRACT.md
d2c9285122dc8cf976eb054155ad5c5a089652adbce71a5ad4f76089376f2fef  docs/development/LEVEL_ACCEPTANCE.md
f8edbdf3a34a5dc3bf424471958c8a19d803cae764e73e256ea30c55c03b1ad0  scripts/acts/act2/london_approaches.gd
38644fceaa2e40c37b26022c429f4423f17fb4533ce6f7aa5242c6d7e1830def  scripts/acts/act2/london_approaches_floor.gd
9aa9c32e5d2c5804df5dffe7b1fef1098e7c9626e4f349951d0e060680121437  scripts/acts/act2/london_approaches_kit.gd
85c470289212aaabc86c842e4d464768d7e6993ed59aac99146cde64803613b4  scripts/acts/act2/london_approaches_snapshot_rules.gd
e43236ccdc37827253533bdf999f26db2f4e3d5adfc309f1f70f98247fe8184a  scripts/acts/act2/london_approaches_sequence.gd
6d8e11a29254cad18947655d8e7470d7892b18e856e534859ae6211a897ae7e2  scripts/acts/act2/ray_scout_exchange.gd
dee72b851cb20b234a05552d07eae9cebd7490ee0fad12b3970da51eae132bb7  scripts/acts/act2/ray_scout_actor.gd
7e90bfc541c467162a5a0b0afd6891e8aa6dda9835a4da05362e9301eed78916  scripts/acts/act2/weybridge_scout_actor.gd
42457249e8a30e2d28ad0d03017d16e2f5158092ad3531e528ccf6beb3f70d96  scripts/acts/act2/salvage_handler_actor.gd
bcf6558d4ae57c4bf8714ae6fe6b1896b3c7c0be3b6a8a9f3178451653bd031d  scripts/combat/lane_mechanism.gd
1989a4170b68329afd6f49c5698b23aa96722883698ccacf32f905619539010d  scripts/campaign/level.gd
0b16d911409350a392f741a07bc163ad73c588d885ee7e1e64b951f97aa30d26  scripts/game.gd
d3417080648a047155fd631d2ba4a9c46a4674dd871335d4808dfed04c938740  tests/acts/act2/a2_l4_full_transport_smoke.gd
0187e3a34be3a8b327752303df2e5a88bc5891f0d6b1c46df0370ad259f30c49  tests/acts/act2/a2_l4_retry_level_smoke.gd
8c747662859e9e71be3296deb8d991dca67854b547c1859df472de2cb50a9b50  tests/acts/act2/a2_l4_fresh_entry_smoke.gd
```
