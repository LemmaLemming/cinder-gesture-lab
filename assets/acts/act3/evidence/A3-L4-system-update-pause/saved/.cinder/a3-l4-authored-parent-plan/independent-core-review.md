# Independent root-network core review

9 October 2026. Static review of the ignored, unparsed draft only. No Godot, import, runtime mutation, native capture, or saved transport was exercised.

Reviewed [garden_root_network.gd](garden_root_network.gd) (797 lines; SHA-256 `2310cd8a242075add4a29e2d85021a5170e1f615168be07d11a35f0dc7cca232`) and [CORE_NOTES.md](CORE_NOTES.md) (SHA-256 `d8ba992d9c5dda79a88d54546724d5734e0ad99f4441825a255234456f102379`) against the current public Scheduler, LaneMechanism, Tether, codec, cue geometry and presentation interfaces. Shared-45 adoption does not change this draft. The whole parent codec still explicitly refuses; no partial Save support follows from this review.

## Finding: an older phase boundary loses its recovery proof

At core lines 680–708, a boundary whose cycle remains the source's latest packet must lie strictly after that actual exchange's `active_until_s` and at or before its `recovery_until_s` (690–693). Once a later admission replaces that exchange, the alternative branch checks only that the old serial and crossing clock precede the later admission (694–695). The saved boundary retains no original recovery deadlines, source role or exchange receipt.

Consequently, in a real phase-2 unit after the same source admits a later cycle, moving the first boundary to a clock after the old admission but before its recovery, and moving `retry_at_s` to that clock plus .25, is not rejected by this branch. The latest phase-2 exchange and all physical/native mechanism packets can stay unchanged; the classification at 701–708 still assigns that later exchange to phase 2. This is a static validator counterexample, not an executed forged-save result or a claim that a future complete parent validator accepts it. It contradicts the notes' current claim of strict actual recovery joins for every retained boundary.

Before enabling core/full-pair transport, retain a bounded receipt of the actual native exchange that earned each of the at most two boundaries, including its original recovery interval and source/phase identity. Capture it from the genuine non-pruning control/native exchange at the boundary and validate its closed fields, resolved profile and timing, geometry/opening, cycle/serial and crossing interval even after a subsequent admission. Alternatively, the complete parent must supply equivalent retained native proof and explicitly join it here. This must not replace or filter the one full Scheduler journal. Scheduler-3's managed authored Echo history does not authenticate arbitrary earlier ordinary Lane exchanges.

This does not block initial loading and source-only mechanics with transport still explicitly refused. It is a correction to the advertised future saved-unit invariant.

## Scoped checks without a concrete discrepancy

- Actual Scheduler signatures for floor custody, pure `source_control_state`, full capture/validation/restore, and the Lane configure/bind/preview/start/capture/staged-validation/restore calls match. Saved Hero positions are staged as native vectors under the actual complete owner/floor/world bindings.
- The core retains the parent Scheduler once; it neither begins/resets/ends an encounter nor creates a filtered root-only Scheduler envelope. Native root packets remain leaves of the parent's full unit, including managed Echo custody.
- The admission barrier spans preview/current optics, actual start, synchronous warning observers and accepted receipt commit. Exposure rechecks native bindings, actual parent optics and the matching pure recovery after callbacks. Genuine accepted-but-synchronously-cancelled cycles retain their accepted identity.
- Actual Draw anchor is its native `from` point; Enclose anchor is its native origin. Forecast outline/fill/source-marker offsets match the actual cue construction. The complete bound groups are conservative measured mesh bounds; no camera fit or rendered visibility is proved here.
- Target phase overflow remains handled by the unchanged low Tether: clamp 60→30→0, derive the phase, cancel actual root leases before emitting the boundary signal. A snapshot is refused during this mutation; the parent must use deferred delivery after native state settles.
- Quiet stages prevalidate before mutation, then restore target/physical state, the full Scheduler, managed Playback recipients, native root mechanisms, and checked paused target presentation without a provider callback or event. A failure after physical commit remains whole-candidate disposal.

The Playback-before-Lane order is a real condition, already stated correctly in CORE_NOTES: `LaneMechanism.restore_state` captures the ordinary full Scheduler again at its line 575. All managed Playback commits must have finished before root mechanism restore; the special authored-restore capture cannot substitute for that ordinary capture while another recipient is pending.

## Direct source pins

| Actual dependency | SHA-256 |
| --- | --- |
| [Scheduler](../../scripts/combat/threat_scheduler.gd) | `9b11730b4041dfb73a20e97bda0c72854a89af1ab79809fb3d8449fec624ae79` |
| [LaneMechanism](../../scripts/combat/lane_mechanism.gd) | `873b1728019b40b229f2b7778a970cc5c8fa0001d50800cf50f2cdd50f502253` |
| [Garden Tether](../../scripts/acts/act3/garden_root_tether.gd) | `4431b10289f5ced8fbb2e5196b423ae284c93acffc6340b6a8ef54c4e65564f0` |
| [Snapshot codec](../../scripts/campaign/snapshot_codec.gd) | `36ac4a52b08020249e4282b2788f7e4bc9d1c4af7ad45fd50586e2385f6afbac` |
| [Native cue meshes](../../scripts/cues/cue_mesh.gd) | `d63f5dfabbdae2dbd055e24013b0d822bca47ba71a457e1ab0d874e0ef22929d` |

No other blocking public-interface discrepancy was found in this scoped text review. It does not establish parsing, native behavior, camera admission, overlap fairness, art readiness or persisted full-parent transport. The next meaningful native step remains the root's initial loading/source-only fixture.
