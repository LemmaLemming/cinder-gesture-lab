# Difficulty completion gap — source-only audit

Observed 15 October 2026 against the production registry's20 accepted levels. No engine, test, parser, import, UID, Git, worker-message or production edit was performed. This targeted audit does not change acceptance or require a full route. `source-map.json` pins the named source/data files, actual selectors and per-level mapping; it is source observation, not runtime evidence.

**The campaign-wide authored difficulty direction is not fully implemented.** Assisted has real numeric and scheduling effects. A1-L2 has an actual Challenge ordering variant. The other19 accepted levels have no identified Challenge arrangement dispatch and use the same authored content for Standard and Challenge. This is more than missing playtest evidence: the shared catalogue's arrangement labels have no runtime reader, and the production selection paths have no corresponding preset branches/data mappings.

## Binding requirement and what is already implemented

The original objective requires “the documented Assisted/Standard/Challenge direction” with provisional values, fresh boundaries, no multiplier compounding and unchanged gestures. `docs/DIFFICULTY_DESIGN.md:67`, Step3, says: “Use explicit per-preset encounter arrangements for authored campaign rooms.” Its table and paragraphs37–55 specify simpler Assisted mixtures and more demanding Challenge target priority/positioning while retaining reference HP, geometry, approach speed, player stats and Standard/Challenge timing. The later focused-acceptance policy removes playthrough gates; it does not supersede this implementation requirement.

The requirement does not prescribe three different maps for every room or authorize generic new difficulty mechanics. A rehearsal or fixed capture phase may legitimately retain a baseline arrangement if its authored policy explicitly says why; that does not make an absent campaign policy implemented. Merely naming `authored_target_priority_and_positioning`, validating all three IDs or storing a different profile ID cannot supply a player decision.

Current implemented profile effects:

| Field | Assisted | Standard | Challenge | Actual consumer |
| --- | --- | --- | --- | --- |
| Enemy raw damage | ×0.70 | ×1.00 | ×1.00 | `difficulty.gd:84`; ordinary/own-sequence sources deliver resolved damage to the shared Player. |
| Windup | ×1.35 with authored floor | ×1.00 with floor | Same as Standard | `difficulty.gd:85`; fixed lock duration remains, so Assisted gains warning before lock. |
| Recovery | ×1.35 with floor | ×1.00 with floor | Same as Standard | `difficulty.gd:87`; roles/own-sequence programs consume it. |
| Preparing plus active budget | 1 | 2 | 2 | `threat_scheduler.gd:201–206`; recovery does not consume this budget. |
| Minimum activation stagger | 0.12 seconds | 0.12 | 0.12 | `threat_scheduler.gd:203`. |
| Catalogue `arrangement` | Different descriptive string | Different string | Different string | **No gameplay reader found.** Profile snapshots/identity validation may carry the string, but neither Difficulty nor Scheduler dispatches an authored arrangement from it. |

`resolve_role` rejects already resolved role input, changes only damage/windup/recovery and retains the raw role. Scheduler fixes its profile at `begin_encounter`; a live encounter cannot begin again. Menu selection persists through Shell's separate preference Store and does not retune existing schedulers. Parent/current-unit fresh entry paths read that preference; saved constructor/restore paths retain the saved profile. These are implemented source effects, without a new runtime verification claim.

## Accepted-level mapping

“Roles+budget” below means the ordinary source or enemy-authored program resolves the selected raw role and uses the selected scheduler budget. It does not mean every role parameter changes, every room uses two simultaneous attackers, or all presets have been freshly tested. Geometry, HP, movement, source placements and player stats remain reference values. Each named level's actual parent entrypoint and inherited/current-unit paths are pinned in `source-map.json`.

| Level | Actual Assisted effect | Actual Challenge arrangement relative to Standard |
| --- | --- | --- |
| A1-L1 Launch Rehearsal | Roles+budget for later Lane exercises; early practice beats stay fixed. | None. Same exercise/target/arm sequence. |
| A1-L2 Crater Gardens | Roles+budget; original A→B finale priority. | **Implemented:** fresh boundary chooses the versioned Challenge receipt, and `_circles_for_arrangement` reverses finale companions to B→A. Earlier rock/open circles remain fixed. Saved receipt/legacy absence retain their own order. |
| A1-L3 Mushroom Caverns | Inherited native roles+budget; spore repulsion remains non-damaging. | None. Same room/source/field arrangements. |
| A1-L4 Selenite Court | Guard/King/Lane roles+budget. | None. Parallel→inward formation and King sequence are ordinary stage progression for all presets, not preset selection. |
| A1-L5 The Living Moon | Rusher/sampled-circle/body roles+budget. | None. Same authored stages and samples. |
| A1-O1 Salvage Circuit | Roles+budget at circuit and final fresh epochs. | None. Same parts, collection choices and final machinery. |
| A2-L1 Horsell Common | Scout/Tool roles+budget. | None. Same authored beats and placements. |
| A2-L2 Weybridge | Roles+budget **plus** counterpart must actually die before the associated Foot starts (`weybridge.gd:213`); Standard/Challenge permit the proved paired opportunity. | None. Standard and Challenge share the paired policy. |
| A2-L3 Ruined House | Scout/Tool/SmokeBank roles+budget. | None. Same progression, bank/Tender placements and boss tool alternation. Inherited validation of preset IDs is not another variant. |
| A2-L4 London Approaches | Scout/Tool roles+budget. | None. Same weeds, source placements and progression. |
| A2-L5 Dead London | Roles+budget **plus** Sentry pair starts Ray after Foot active release with budget1; Standard/Challenge can start after Foot lock (`dead_london_sentry_encounter.gd:391`). | None. Same Standard/Challenge Foot→Ray pairing. |
| A2-O1 Cylinder Perimeter | Scout roles+budget. | None. Same fragment route/source placements. |
| A2-O2 Clear Air Circuit | Tool/SmokeBank roles+budget. | None. Same two Tender-bank pairs, then Handler. |
| A2-O3 Bleached Canal | Scout/Tool roles+budget. | None. Its “three arrangements” are stage progression shared by presets. |
| A3-L1 Twin Suns | Stalker roles+budget from fixed authored data. | None. Same sources/thresholds. |
| A3-L2 Living Forest | Stalker/Root roles+budget. | None. Its six “arrangements” are fixed entry data, not preset data. |
| A3-L3 Mirror Sea | Stalker/Lane roles+budget; enemy-authored Echo resolves damage/warning/recovery from its profile. Echo remains exclusive. | None. Same court/source sequence and Echo recipes. |
| A3-L4 False Paradise | Stalker/Root/own-Echo profile effects; exclusive Echo handling. | None. Same five entry arrangements, source IDs and garden recipe. |
| A3-L5 Crystalman | Approach Stalker/own-Echo roles respond. **Captured-player boss phases are an exception:** fixed outer timeline and recorded damage, described below. | None. Phase1 one slot and phase2 two slots are stage rules for every preset. |
| A3-O1 Pillars Before Their Time | Three Stalker roles+budget from fixed pocket data. | None. Same pocket placements/contact choices. |

The only production Challenge selector identified is Crater Gardens' real `_arrangement` choice at268–278 followed by the order dispatch at465–471. Its strict receipt validation is useful compatibility precedent, not a generic shared arrangement resolver. Other occurrences of `challenge` are allowed-ID checks, canonical role preflight or saved-profile validation. Act3 layout `arrangements` and Act2 Canal arrangements are shared stage structures; source indexing them independently of profile does not implement per-preset arrangements.

## Captured-player replay exception

Crystalman's regular approach uses `sunbound_stalker` and `authored_enemy_sequence`: the latter calls `resolve_role` at530–532, derives outer warning/recovery at541 and writes resolved damage into the enemy slash record at555. That supplies genuine profile effects.

Its captured-player phases instead use `crystalman_capture_phase.gd:353–355`: recognition0.25, warning1.3, locked lead1.5, fixed slot gap and final recovery3.5 for every preset. `replay_playback.gd:326` delivers `event.record.damage` directly. The captured record's original action durations/geometry/order are intentionally exact. Replay uses an exclusive lease, so changing the shared1/2 threat budget does not create a different boss arrangement. The retained profile ID still validates world/lease identity; that is not damage or timing assistance.

This is a **source-confirmed delivery/timing exception**, not a newly reproduced runtime defect or proof that every attack multiplier is missing. The conclusion comes from the actual `_authored` construction and damage-delivery call, not merely immutable record fields: shared Player passes that amount through equipment armour, without another difficulty scale (`player.gd:396–400`, `equipment.gd:125–126`). The general Assisted enemy-damage rule has no documented captured-player exemption in the inspected authority; the Act3 concept separately requires exact geometry/order and normal action durations. Root should reconcile that policy boundary explicitly, without assuming which raw-role promise applies to a captured-player record. Do not silently retime recorded actions, rewrite their immutable damage record, multiply already-resolved enemy-authored damage again, or relax safe-path proof. Any chosen assistance requires an explicit fixed-profile delivery/outer-budget policy and saved compatibility, preserving exact captured actions.

## Smallest faithful next action

1. **Record this named implementation gap, not “difficulty merely untested.”** Retain existing acceptance and all15 main levels. The20-level endpoint and this missing feature are separate; O2 development may continue independently. Do not mark the complete shared-system objective achieved with catalogue labels alone.
2. **Root can implement a shared pure ordering seam now.** [Concrete hook proposal](HOOK_PROPOSAL.md) names a strict owner-supplied per-profile permutation selector, with A1-L2's existing finale IDs as the first real reference plan. No generic reverse, geometry/stat/timing edits or automatic safety authorization. Root-owned helper/data/model checks are conflict-free; an unused helper alone does not close the campaign feature. Have the active Act1/Act3 owner consume it in a named fresh constructor and actual admission loop for its next authored compound room. Preserve the selected versioned recipe through Save/Continue/Retry. Apply one owned room at a time; focused selector/admission/save/Retry/cleanup and brief relevant portrait replace a route gate.
3. **Close the remaining campaign policy coverage deliberately.** A per-room source-backed mapping may explicitly retain a rehearsal/fixed phase, but every claimed preset arrangement must have a real consumer. Coordinate named ownership handoffs for modifications to already accepted act files; rerun only changed behavior. Do not invent blanket higher damage/HP/speed, extra enemies, compressed warnings or new bosses. The catalogue numbers intentionally keep Standard and Challenge equal. Agent02 is human-inactive: do not wake it or edit its owned content from stale status. Root can prepare shared support and inert exact proposals while preserving that custody.
4. **Root can separately reconcile the captured-replay policy in shared ownership.** First pin whether the documented existing0.70 Assisted raw-damage policy applies at captured-enemy delivery, and the allowed outer warning/recovery policy; preserve original captured records and already-resolved enemy-authored behavior. Bind the saved encounter profile, not the current menu preference. A deliberate change then needs only affected capture/playback/difficulty checks and explicit old-save compatibility. The Act3 owner retains its parent recipe changes. This is not a reason to invent new multipliers or to wake Agent02.

## Scope and search correction

This is a bounded lexical/manual source inspection, not a formal call-graph or a runtime equality proof. The named literal source subset is overinclusive where immutable guard strings reference another level; it is not proof that those referenced parents instantiate. Global class/dynamic loads and future worktree edits are outside the subset. Data files are inspected as leaves, not traversed into archives. A first broad data search accidentally matched stored test JSON; that search was discarded for the conclusions and repeated with evidence excluded. Subsequent reasoning uses only named production inputs. No evidence bank, UID or engine-state census was performed, and no stored result was treated as a new execution.
