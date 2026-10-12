# Root-network v2 derivative

12 October 2026. This ignored, unexecuted derivative resumes the correction recorded in [PAUSE_CORE.md](PAUSE_CORE.md). The [original 797-line core](garden_root_network.gd), [original notes](CORE_NOTES.md), [original custody](core-custody.json) and [independent finding](independent-core-review.md) remain unchanged. Root handles publication, import and native tests.

[The v2 source](garden_root_network_v2.gd) uses `api_revision: act3-garden-root-network-2` and core `schema_version: 2`. It deliberately rejects the original core wire. The native Tether stays schema1; native LaneMechanism leaves stay their actual schema1 or2. The whole authored parent codec remains explicit refusal until the owner completes and tests it. This file does not enable partial Save.

## Bounded recovery receipt

Each of the at most two phase boundaries is a closed record:

`{from_phase,to_phase,clock_s,kind,cycle,exchange_id,recovery_receipt:{exchange,sun_choice}}`

`exchange` retains exactly the twelve public `LaneMechanism.EXCHANGE_KEYS`: id, source_position, geometry, opening_position, start_s, lock_from_s, active_from_s, active_until_s, recovery_until_s, cooldown_until_s, profile_id and world_revision. Only native vectors are encoded to codec arrays; scalar values and all geometry fields are copied from the actual public native record. The receipt does not reconstruct geometry from expectations or infer saved deadlines.

At the genuine Tether phase callback, the core first identifies the accepted old-phase recovery, then samples public non-pruning `Scheduler.source_control_state(actual_source)` while that lease still exists. It joins the actual source instance, cycle, reservation ID, encounter/world/clock, armed recovery, fixed source/opening/geometry and native resolved profile. The held `sun_choice` comes from that accepted cycle, including if the parent sun subsequently changed. It copies the receipt before cancelling either source or emitting the phase signal. Missing/inconsistent native data records a configuration error and does not manufacture an earned boundary.

The receipt carries no HP component, provider, instance ID, live topology flag, fake proof or second Scheduler envelope. It is bounded owned boundary history; the one complete actual Scheduler remains the parent's authority for every actual owner and managed Echo lifecycle journal.

## Pure validation joins

The existing pure whole-pair path first validates the saved Hero, full actual bindings, full Scheduler and both native mechanism packets. Native Lane validation resolves immutable RAW_ROLE/TIMING_FLOORS against the catalogue profile and checks each latest packet exactly. Receipt validation then uses that already-validated same-profile resolved role.

Every boundary, including an older boundary whose original exchange was replaced, must preserve:

- Exact closed receipt fields, source/opening vectors, native fixed geometry, profile/world and its canonical consumed exchange ID.
- Exact original deadlines derived in the same arithmetic order as native Lane: active_from=start+resolved windup, lock_from=active_from−resolved lock, active_until=active_from+resolved active, recovery_until=active_from+resolved active+resolved recovery, cooldown_until=active_from+resolved interval.
- A crossing strictly after its own active_until and at or before its own recovery_until. Raw windup2.2 includes lock1.1; it is not an extra2.2 warning.
- The actual phase prefix 1→2→3, positive consumed cycle/serial, strict serial and boundary-clock ordering, and phase-1 held sun choice 0.
- Full exact exchange equality and matching phase/sun when the triggering cycle is still the source's latest native cycle.
- An older cycle/serial before the later native cycle/serial, enough intervening global serials for the consumed source cycles, and receipt/crossing clocks before that later admission.
- For every latest phase-2 native exchange and the recovery receipt earning 2→3, admission at or after the first boundary clock plus the existing .25 retry delay. The saved final retry preference remains exactly the latest boundary clock plus .25.

No scalar tolerance is introduced. A boundary clock edited before its retained recovery interval now fails even if a later same-source admission replaces the original native exchange. Replacing or altering the receipt's deadlines cannot evade the exact immutable-role deadline calculation. These are source-level validation properties, not executed negative-test results.

The complete future parent still must join each latest cycle **and each retained boundary receipt's** held sun choice/original start clock to its independently validated phase-2 sun timeline. V2 contains no independent sun clock. It also does not provide cryptographic authenticity for an externally replaced complete history.

## Interfaces preserved

All original public method signatures, source coordinates, root geometry, raw role/timing floors, 60→30→0 target clamp, actual admission/callback barrier, native cue/material custody and actual parent Camera/HUD guards remain. The core never begins/resets/ends an encounter, changes floor/controller/equipment or filters Scheduler history.

The original quiet ordering remains: pure whole-unit prevalidation; staged target/physical commit; full Scheduler restore; **all managed Playback recipient commits**; native Lane restores; checked paused target palette/control; parent remaining state and actual candidate Camera/HUD gate; independent installed/live capture. Lane.restore_state reads ordinary full Scheduler.snapshot_state, so a still-pending Playback cannot be bypassed with a special authored-restore capture. Commit failure after physical mutation requires whole-candidate disposal.

## Readiness

The changed public contracts were read directly in [LaneMechanism](../../scripts/combat/lane_mechanism.gd), [Scheduler](../../scripts/combat/threat_scheduler.gd), [difficulty resolution](../../scripts/combat/difficulty.gd) and [codec](../../scripts/campaign/snapshot_codec.gd). Static delimiter/function/preload/link/whitespace/hash checks and an independent narrow peer review are recorded in [v2 custody](v2-core-custody.json). These checks do not parse or execute GDScript.

The independent test-draft peer reviewed source SHA `a587f6a172f723d568241efaf9fff6e744ab724c1c35e2c2e639cecfa7cc68ae` and found no concrete changed public API/type mismatch. It confirmed the actual public lease fields, complete exchange keys, encoding, deadline arithmetic, current/replaced receipt joins and both existing .25 phase-2 admission joins. This was read-only source review.

No Godot/import, native receipt capture, saved JSON round-trip, fresh candidate restore, rendering, camera fit, profile viability, art readiness or level acceptance is claimed. Initial loading/source-only work can proceed while whole transport still refuses. A focused later custody check can earn 1→2, genuinely admit a later cycle of the same source, capture the coherent paused pair, and verify that altering the earlier crossing/receipt cannot pass; root chooses and runs the actual fixture.
