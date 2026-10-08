# Authored Echo first-cycle integration

**Shared28 first-cycle contract.** This guide describes the tested additive implementation for the confirmed Mirror Echo's own dash/slash cycle. Adopt only its exact canonical publication and preserve owned paths; this contract does not accept A3-L3. Shared27 independently published Shell pause settlement and A3-L2 registration. Same-owner repeating cycles and late terminal saves remain the separately registered shared29 dependency. Integration owns shared publication and the canonical engine queue; the act owner owns the production actor, source codec, placement and art. Current accepted levels acquire no new gate from this future dependency.

Read [the authored data contract](AUTHORED_ENEMY_SEQUENCE.md), [projection contract](AUTHORED_ECHO_PROJECTION.md), [native fixture contract](AUTHORED_ECHO_PLAYBACK.md), [shared Playback](REPLAY_PLAYBACK.md), [whole response witness](REPLAY_WITNESS.md), and the [Act3 concept](../ACT3_CONCEPT.md) / [adaptation notes](../concept-art/act3/ADAPTATION_NOTES.md). Their copied prejob “unexecuted” statements are historical; the bounded closed results below record what has subsequently run. The test-only genuine native C52 consumer has executed; production C52 placement/controller and whole-level acceptance remain pending.

## One actual owner and one finite cycle

The production source must **subclass the canonical `scripts/combat/replay_playback.gd` itself**. That same live object is the Scheduler lease owner, ordinary-primary HP target, fixed recovery knot and Playback consumer. Its act-owned child renderer travels without collision; the HP owner stays at the original route endpoint. A generic Node3D proxy, a separate parent HP actor with a child lease owner, a cloned Scheduler, or a private Playback fork is not this supported binding.

The first branch supports one exclusive, finite, two-endpoint straight route at unchanged Y, followed by one instantaneous own `enemy_slash`. Travel is harmless. Slash commitment and cosmetic duration are distinct; neither creates sustained damage. The entire warning → full lock → travel/slash → recovery exchange excludes other preparing/active/recovery commitments. The source's physical `move_speed` is genuinely zero. Moving HP owners, concurrent mixed threats, extra authored slots, retargeting, translated recorded paths and a repeating-cycle controller are outside this first prototype.

The source supplies an immutable **native** definition containing exactly:

```text
definition_id, definition_revision, role_id, raw_role, timing_floors,
recognition_s, route, travel_clearance, slash, presentation
```

`role_id` is `C52`. `raw_role` has the eight keys `raw_damage`, `windup_s`, `lock_s`, `active_s`, `recovery_s`, `attack_interval_s`, `max_hp`, `move_speed`; submit fresh raw values and the current selected difficulty profile once, never an already resolved role. The two absolute native route positions and slash origin/direction are Vector3 values. Slash origin equals the final endpoint exactly. `active_s` equals the route duration plus slash commitment exactly. The source-owned `presentation` is `{presentation_id, presentation_revision}`; it carries no Player equipment IDs. The [data contract](AUTHORED_ENEMY_SEQUENCE.md) specifies all numeric, shape, input-budget and closed-key limits. The fixture's numerical recipe is test tuning, not fixed production level balance.

`CinderAuthoredEnemySequence.configure(sequence_id, native_definition, source_id, source_epoch, generation, profile_id, prepared_world)` builds the immutable program. `prepared_world` is exactly `{world_revision, collision_fingerprint, floor_signature}`, measured from the actual supported scene. `CinderReplayProgram` selects that typed reader without broadening the captured reader. Once configured, neither reader can switch program provenance or overwrite a valid definition/profile with a different valid one.

No Player capture, retirement slot, fake Player action record, loadout, ammo or proc enters this branch; its source-owned renderer does not render Player gear. The captured `CinderReplaySequence`, ActionCapture and CaptureGate retain their existing authority and wire contracts. A source-owned authored cycle is not Crystalman's captured replay. The level parent still owns historical source/cycle retirement and must not create a second live custodian from copied program bytes.

## Source hooks and native art limits

The actual owner implements the pure `get_authored_echo_binding() -> Dictionary` hook with exactly seven keys:

```gdscript
{
    "api_revision": "authored-echo-source-1",
    "source_id": source_id,
    "source_epoch": source_epoch,
    "generation": generation, # actual native integer cycle identity
    "definition": native_definition.duplicate(true),
    "alive": actual_source_alive,
    "knot_position": actual_fixed_knot, # native Vector3
}
```

Values come from the actual retained source, including genuine HP/lifecycle, current cycle and immutable definition. Copied IDs or a caller-provided saved hook are not live admission authority. Scheduler checks actual shared Playback inheritance, source script, same world/root, fixed exact knot, profile, collision/floor domain and cycle before admission, lock, live lease use and snapshot commit.

`get_authored_echo_renderer() -> Node3D` returns the actual retained descendant. Its pure `get_authored_echo_render_bindings() -> Dictionary` returns exactly `{api_revision: "authored-echo-renderer-1", presentation, required_visuals}`, where `presentation` equals the definition and `required_visuals` is the ordered unique actual MeshInstance3D set. Its `present_authored_echo_pose(pose: Dictionary, quiet: bool) -> bool` accepts exactly native `position`, normalized horizontal `direction`, `action` (`idle`, `dash`, `enemy_slash`) and float `progress` in 0–1. It may translate/yaw only the renderer root. A quiet call emits no signals; it never moves the HP owner or changes a child/resource to disguise a new silhouette.

The current shared native guard supports **1–16 required MeshInstance3D children in a complete tree of at most 32 live Node3D nodes, totaling at most 16,384 native vertices**. Every draw child belongs to the required set. Other descendants must be plain Node3D; no CollisionObject3D, collision shape/polygon, Sprite3D, extra draw actor or top-level child is accepted. Supported mesh resources are native **BoxMesh, QuadMesh or CapsuleMesh** without scripts, with one retained StandardMaterial3D override and no overlays/surface overrides/native surface material.

This is static, untextured primitive silhouette support: nearest-filtered, unshaded, transparency-disabled, depth-tested material; no albedo texture, billboard, grow, fixed-size/FOV/clip scaling, fade, extra pass or shader-driven geometry. Native tree order, parents, scripts, visibility, renderer properties/layers, child transforms, mesh/material identities and contents are retained. Replacing an equivalent resource, hiding/freeing a required part or changing a child transform fails custody; later phase presentation or saved state cannot heal it. Only authorized root motion is updated. The renderer starts visibly at the actual fixed knot with a unit yaw basis; every vertex remains above its foot pivot and within the definition's measured radius/height clearance. Derived native measurement tolerances do not relax copied identities.

These primitive limits are real art restrictions, not a promise that selected concept art, animated sprites, textures or arbitrary meshes are supported. Production art stays act-owned and must use the supported renderer contract or a separately reviewed common extension through integration. Do not substitute Player gear/art or fork shared renderer/contact math to make an unsupported asset appear adopted. The test Box silhouette demonstrates custody, not finished Act3 presentation.

## Admission, lock and presentation

The published first-cycle seams are:

```gdscript
source.configure_authored(playback_id, program_snapshot, source_epoch, generation) -> bool
scheduler.request_authored_replay(source, program_snapshot, response, context) -> Dictionary
scheduler.commit_authored_replay(reservation_id, fresh_response) -> Dictionary
witness.prove_authored(scheduler, source, program_snapshot, response, context,
    at_lock = false, permitted_reservation_id = "") -> Dictionary
ReplayFootprint.plan_authored(scheduler, program_snapshot, world_root,
    floor_regions, context) -> Dictionary
source.bind_projected(scheduler, reservation_id, heroes, floor_regions,
    projection, context) -> bool
source.advance() -> Dictionary
```

Initialize the actual source's HP/lifecycle/immutable definition and retained renderer before configuring its canonical Playback. The [test-only source](../../tests/fixtures/authored_echo_actor.gd) shows the order through `initialize_source`, `attach_source_scheduler` and `configure_authored`; those first two names are fixture methods, not a new production actor API. Production owns its equivalent initialization and closed codec.

The context has exactly six keys:

```gdscript
{
    "world_root": actual_world_root,
    "source_id": source_id,
    "source_epoch": source_epoch,
    "generation": generation,
    "world_collision_fingerprint": scheduler.pure_collision_fingerprint(actual_world_root),
    "world_floor_signature": floor_descriptor.signature,
}
```

`floor_descriptor` comes from the pure `ReplayFootprint.floor_signature(world_root, floor_regions)` or matching `scheduler.authored_floor_signature` seam and must be accepted. Actual floor entries contain the bound CollisionShape3D plus authored safe Rect2. These are bounded coplanar unscaled axis-aligned static Box floors, stable local paths and an immutable supported static collision world; empty/unsupported descriptors reject. Do not manufacture signatures or persist the live `world_root` object.

Obtain `response` fresh from the actual shared Player's `get_threat_response_state()`, then add the level-owned current `world_revision`, recognition/input margin, supported floors and finite escape/return directions. The live stats, cooldowns, commitment and actor must agree with that getter. Pending weapon changes, unsupported body/world geometry, unsafe landing/return or no full ordinary-primary opening reject. No blast ammo, immunity or HP absorption counts as an escape. The authored harmless render route uses its **own** measured radius/height for continuous floor/scenery proof; it receives no captured route's special contact allowance. An axis-aligned native Box query contains the validated upright render cylinder at every permitted yaw, padded only by the renderer's native vertex-measurement bound. It checks initial, swept and final placement, excludes only actual supported floor RIDs and applies zero query margin. A tapered capsule is insufficient near the feet: the native clearance regression retains a real low-stone overlap missed by the historical capsule control.

A successful request creates one **unarmed** `authored_replay` lease. Bind that exact actual lease to the same source with exactly one actual Hero map; derive the clipped projection from the same complete program/world/floors/context and pass it to `bind_projected`. Planning or a returned witness does not grant a lease, retire a cycle or authorize damage. If binding fails, the parent must cancel the admitted lease rather than leave a hidden attack.

At the returned `lock_from_s`, call `commit_authored_replay` with a fresh actual response. It reproves the full exclusive exchange and retains the complete locked lead. A delayed valid lock returns updated original exchange deadlines; consume those exact values rather than recalculating from copied role data or merely playing a faster animation. Failed lock cancels visibly. Playback advances from the actual Scheduler simulation clock, observes actual arming, and owns presentation/contact/opportunity delivery; the act must not separately dispatch the same slash. Neither scheduler time nor delivery advances during ordinary pause.

The witness conservatively treats the full original cone as dangerous even where the projection shows floor gaps or scenery shelter. Projection clips native warning/fill/outline against supported floor and LOS shadows; it does not relax the witness or replace attack math. Live contact retains the original origin/direction, vertical/range/cone/origin-disk/native scenery LOS tests plus projected floor membership. The original instantaneous event must dispatch within the existing 0.05s window, with no damage during travel and no sustained slash sweep.

Playback commits the canonical event prefix and original target contact/time receipt before observers. A supported held cue/event/state callback retains its pending suffix; resume does not resample contact or grant another opportunity. Recursive advance cannot redeliver. Required renderer/cue loss, changed owner/world/player or death fails closed; renderer-hook pause is currently bounded cancellation, not supported continuation. Parent portrait framing must include the actual moving source, whole required footprint, Hero, reachable landing/ordinary-primary position and fixed knot, using current public presentation/proof data. Pure proof alone does not establish their visibility.

## Typed APIs and wire migration

| Unit | Authored discriminator | Current snapshot shape |
| --- | --- | --- |
| Own program | `authored-enemy-sequence-1`, `enemy_authored` | Integer schema 1; one slot/one `enemy_slash`, `event_ordinal = 1`; no captured `record_sequence`. |
| Own action | `authored-enemy-action-1` | Integer schema 1; source/role/profile geometry and damage, no Player data. |
| Cursor | `authored-echo-cursor-1` | Schema 1; canonical lock/origin/clock and exact consumed event prefix. Captured `configure` stays separate from `configure_authored`. |
| Scheduler | Adapter `kind = authored_replay`; snapshot API stays `scheduler-snapshot-1` | Conditional schema 2 when an authored lease or retained authored cancellation is present. Ordinary/captured schema 1 remains unchanged. |
| Projection | `authored-echo-footprint-1` | Schema 1; exact source/profile/program digest, world/floor guard, original ordinal event and immutable meshes. |
| Playback | `authored-echo-playback-1` | Schema 1 when drained/unprojected, schema 2 for a genuine pending suffix, schema 3 when projected (pending key only when present). Captured Playback API remains separate. |

Do not rewrite API/kind tags, coerce integer cycle IDs to floats, remove immutable projection/pending keys or downgrade a projected owner to schema 1/2. Exact tagged transport preserves native numeric types, every finite scalar bit and signed zero; there is no generic copied-clock/fingerprint tolerance. The Cursor's existing derived timing epsilon is not authority to rewrite stored identity. Production source transport needs its own separately versioned closed actor schema paired with all these units; the test-only `authored-echo-fixture-native-1` codec is a reference pattern, not an act's production source format.

## Paused whole-unit save and fresh restore

The level parent owns the aggregate and completes a **deferred paused whole native tick barrier**, outside Player/source/Scheduler/Playback/cue/damage callbacks. A synchronous observer requests pause/checkpoint; it does not serialize halfway through physics or observer delivery. Preserve public Shell/level routing, pending native dash, resources, death, original event opportunities and current source cycle. Use actual format 2 SaveStore / `CinderExactJson` transport; do not reconstruct equivalent resources or replay controls during Retry.

Bind stable actual maps for `world_root`, `owners = {source_id: same_source}`, `actors = {hero_id: actual_player}`, and `floors = {floor_id: original_floor_binding}`. For this first-cycle contract, the aggregate `floors` map must contain **exactly the same complete floor domain** used by this source's admitted response/program/projection, with stable original floor IDs and bindings. Canceled prevalidation measures `bindings.floors.values()`; unrelated floor entries do not become an implicit subset and fail the exact signature check. Production must explicitly preserve this common domain or request a reviewed shared subset extension.

Stage a saved native source hook in `authored_owner_bindings[source_id]` **only after** the production codec has validated that complete saved actor's actual script/resources, immutable definition, fixed knot, HP/alive/death/cycle and exact paired clock/phase. This seam is paused pure prevalidation, not permission to use a caller's guessed alive state or current fresh pose.

Prevalidate all units before changing any live candidate:

1. Shared Player snapshot against its real actor.
2. Production source codec against complete Player/Scheduler/Playback data and actual native resource/cycle custody.
3. Scheduler snapshot against stable actual maps and the codec-validated staged source hook.
4. Playback snapshot against that exact Scheduler/Player/source/projection pair, original floor bindings and six-key context.

Then commit while still paused and quiet: **Player → source HP/alive/fixed physical state → Scheduler → Playback → verify source phase**. Remove staged substitution for actual Scheduler/Playback commit: they must measure the already applied actor/source, compare the actual Scheduler envelope/clock/lease and retained current native world. The source codec does not independently move the animated renderer; Playback quietly reconstructs the canonical cursor or last actually presented pending event and required native cues. Preserve once-consumed opportunity/prefix data. No callbacks, input, damage, source defeat, reproof/request, timer reset or healing occurs through restore.

This is full prevalidation followed by ordered commits, not a generic rollback transaction. If an actual quiet native renderer hook fails after preflight, Playback returns failure and the parent must discard the candidate aggregate; it cannot resume or accept a partial unit. Retire the original live recognizer/world before fresh resumed input so two custodians cannot execute the same cycle. Complete production Shell/attempt/progression/menu/camera state remains the parent level's responsibility; the standalone native fixture is not a Shell/attempt integration proof.

## Recovery, defeat and retained cooldown

The ordinary-primary opening is at the actual stationary knot, with shortest legal reach/LOS and complete primary commitment in the unchanged recovery budget. The act implements a genuine source damage transaction with the common target-result fields; HP/lifecycle commit before observers. The executed test-only fixture accepts recovery hits and exercise an ordinary lethal primary; it does not prescribe permanent production HP, loot or moving-enemy hurt behavior.

A real defeat calls `scheduler.cancel_owner(same_source, "authored_source_defeated")` after committing dead/alive state, stops future damage and removes the living target role. Replay cancellation retains the original exchange/cycle/reason/cancel clock and cooldown tombstone; it does not clear or shorten the source's original readiness. `source_ready_s = max(tether_until_s, playback_from_s + resolved.attack_interval_s)` and cooldown is the original canonical timeline origin plus that value. Changing dead/consumed transport into a fresh living cycle cannot regrant a lease. A legitimate earlier living Retry needs its complete protected original parent checkpoint and retirement of the replaced aggregate.

Keep the genuine defeated owner/native resources retained through the supported cancellation checkpoint; freeing it cannot be replaced by a fresh living clone with the same ID. Historical canceled/dead restore permits `alive = false` only with the original exact source/lifecycle/tombstone pair and licenses no future hurt. Current canceled transport is bounded to the **exact cancellation aggregate clock** while tombstone provenance remains retained; a later simulation clock, expired tombstone or incompatible world/floor/resource domain requires an explicit safe parent boundary, not a fabricated late cancellation snapshot. Completion retains its full consumed prefix and final recovery; neither complete nor canceled owners can be rewound/rearmed from a copied snapshot.

## Closed targeted evidence and remaining work

The [portable original-source archive](evidence/shared27-authored-echo/index.json) retains the historical shared27 directory name; its current contract is shared28. Each closed scope keeps its original prequeue bounded source subset, exact manifest and separate full native/wrapper logs. Integration verifies original lengths/hashes and archive membership. No later runtime byte inherits an earlier execution claim.

| Closed target | Result | Bounded scope |
| --- | --- | --- |
| Authored constructor/program reader | 76/0, exit0 clean | Typed immutable own data, native descriptors, hostile input/identity and captured-reader compatibility. |
| Authored projection/native ThreatCue | 179/0, exit0 clean | Real floor/hole/wall/low-stone clipping, phase/quiet native cues and lost resource custody. |
| Existing captured Cursor | 118/0, exit0 clean | Actual capture/native clock/lock/transport compatibility. |
| Existing captured/projected Playback run2 | 475/0, exit0 clean | Actual Player/contact/pending/quiet cues on its original archived run2 bytes. Later authored-only corrections do not inherit475. |
| Native C52 Actor4 full matrix | 312/0, exit0 clean | Same actual stationary HP/lease/Playback owner, immutable child renderer, two legal kits, real inherited swipe/tap escape-return-primary, genuine defeat, exact paused disk/fresh aggregate restore, original opportunity/pending/callback/resource faults. This scope precedes the authored Box clearance repair. |
| Directly affected existing projected Playback | 467/0, exit0 clean | Existing captured projected branch after authored terminal corrections. The later authored-only Box query does not change this path. |
| Authored renderer clearance repair | 31/0, exit0 clean | Native floor and low-stone start/middle/end regression; historical capsule misses six actual render-volume collisions. Direct clearance helper scope, no C52/HP/portrait claim. |
| Native C52 Actor5 selected route | 161/0, exit0 clean | Post-Box-query actual Scheduler admission/lock, default and slow legal kit escape-return-primary/defeat, selected paused/fresh whole native source restore and contact. `--route-only` skips the unchanged Actor4 fault matrix; it is not another312-check run. |

The archive also preserves invalid/failing originals. Playback1 printed81/0 with preload/compile/runtime errors; renderer parse1 failed; resource import is not gameplay and retains shutdown diagnostics; Actor1/2 had parse/compile/runtime cascades despite exit0; Actor3 had308/4 fixture failures; clearance1 had31/6 genuine low-stone misses. The repair of Actor3 moved the empty-ammo control before admission and decoded genuine signed-zero transport bytes. Native ammo naturally regenerates during the no-blast ordinary route; no false empty-ammo-at-recovery claim remains. Exit0 alone never qualifies a scope.

No authored A3-L3 production placement, art/portrait, complete Shell/progression parent, repeated-cycle or late-dead terminal support is claimed by these tests. Integration owns the separately requested [lifecycle extension](AUTHORED_ECHO_LIFECYCLE_PLAN.md); its pure draft leaves are not part of shared28. Act3 may use the published first-cycle prototype while production lifecycle support remains a separate dependency. Only targeted changed/directly affected suites ran.

## Production knot after a finite cycle

For the first finite one-cycle production source, keep its actual knot on supported grounded floor and **ordinarily hittable after shared Playback reaches `complete` while the source remains alive**. The stationary HP target stays visible/reachable with ordinary primary range and scenery LOS; completion of the dash/slash is not defeat. A lowest-damage legal primary may need more than one hit, so the act-owned damage handler must allow genuine recovery hits and subsequent ordinary hits at the completed knot until HP reaches zero. Keep the same actual owner, fixed pose, native resources, original cooldown and genuine HP transactions. Do not require blast ammo, a second invented warning, forced 12 HP, a moved airborne weak point or a changed completed cursor to finish the encounter.

The executed test-only fixture's recovery-only handler and 12 HP/one-lethal-primary recipe are deliberately narrower than that production requirement; they are not the production controller or proof that a longer-HP source stays hittable after completion. A repeatable authored-cycle/re-arm seam remains future shared work when the actual selected level needs it. Until then, the finite source uses the retained ordinary-hit knot policy rather than privately resetting its immutable program/cursor, reviving a canceled owner, constructing another authority from copied history or forking Playback. Integration owns any required common extension; production HP/art/placement/controller behavior stays act-owned.

Production aggregate capture also follows the [shared pause settlement ordering](CAMPAIGN_PAUSE_SETTLEMENT.md): freeze and settle queued quiet native pause work before persistence. That ordering fix was independently tested and published in shared27; it introduces no authored source wire change.
