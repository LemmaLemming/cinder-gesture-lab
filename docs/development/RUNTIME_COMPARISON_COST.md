# Runtime comparison cost

The first measured reduction replaces repeated tagged JSON equality work while retaining exact values and current native authority checks. The results below concern an instrumented, headless, one-Box authored echo fixture on Godot **4.7.2.stable.official.ed1daf0bf**. They are not campaign FPS, portrait, sustained performance or latency acceptance measurements.

## Measurements and retained originals

The [native fixture](../../tests/authored_echo_performance_smoke.gd) observes one genuine authored source, the real shared Scheduler, Player, projected Cue, Cursor and renderer guard. Each successful first-cycle profile contains **72 automatic native advances**, warning/lock/active/recovery, two routed dashes and one ordinary primary. Timers surround `advance`; appended sample bookkeeping is excluded. The wider cycle wall interval includes admission, projection, separate probes, native waits and observer work.

| Profile | Checks / failures | Advance p50 | Advance p95 |
| --- | --- | --- | --- |
| [Corrected original](evidence/shared32-runtime-comparison/logs/authored-echo-performance-baseline2.log) | 100 / 0 | 135.212 ms | 228.953 ms |
| [Authored equality change only](evidence/shared32-runtime-comparison/logs/authored-echo-performance-fast1.log) | 100 / 0 | 104.627 ms | 121.318 ms |
| [Combined narrow changes](evidence/shared32-runtime-comparison/logs/authored-echo-performance-fast2.log) | 113 / 0 | 79.754 ms | 251.183 ms |

These are separate runs with variable CPU conditions, not a controlled causal percentage or an FPS conversion. The [first attempted baseline](evidence/shared32-runtime-comparison/logs/authored-echo-performance-baseline.log) remains **7 checks / 3 failures**: its instrumented Scheduler subclass failed the required actual Script identity and never admitted the workload. It is corrective fixture evidence, not a usable performance baseline.

The [separate probe run](evidence/shared32-runtime-comparison/logs/authored-echo-performance-probes3.log) passed **113 / 0**. Three samples per API at the same actual prelock clock yielded medians: Cue 22.657 ms, source guard 15.348 ms, reservation guard 19.367 ms, Cursor validation 9.072 ms and renderer guard 1.010 ms. These inspect retained native instances and preserve clocks, diagnostics and delivery state. Their call chains overlap; do not sum them or interpret them as nested runtime percentages.

## Narrow changes and verification

| Consumer | Change | Target evidence |
| --- | --- | --- |
| [AuthoredSequence](../../scripts/combat/authored_enemy_sequence.gd) | Both bounded JSON validation walks remain; recursive typed equality replaces serialization. Float64 bits, signed zero, int/float identity, String keys and ordered arrays remain exact. | [Comparison fixture](../../tests/authored_exact_comparison_smoke.gd): 270 / 0; affected constructor: 76 / 0. |
| [ReplayProgram](../../scripts/combat/replay_program.gd) | Authored restore performs its complete pure validation once before committing reader/provenance. Public validator and captured restore body remain unchanged. | [Restore controls](evidence/shared32-runtime-comparison/logs/authored-program-restore1.log): 95 / 0. |
| [ThreatCue](../../scripts/cues/threat_cue.gd) | Compare expected and mutable working events to a separate private validated reference instead of serializing both on every guard. Full binding validation retains the original 8 MiB limit. | [Native reference fixture](../../tests/threat_cue_reference_comparison_smoke.gd), [log](evidence/shared32-runtime-comparison/logs/cue-reference1.log): 325 / 0. Includes a labelled structural event above 1 MiB, aliases, hostile values and existing native corruption controls. |
| [Scheduler spore source protocol](../../scripts/environment/scheduler_spore_source_protocol.gd) | Retain configure-time exact expected bytes only; freshly read actual native values, hooks and full unit checks still run. | [Native reference controls](evidence/shared32-runtime-comparison/logs/spore-reference-native1.log): 30 / 0; [affected source suite](evidence/shared32-runtime-comparison/logs/spore-source-fast1.log): 208 / 0. Actual native one-bit body/world/floor changes still reject. |

No current world, collision, source, renderer, mesh/material, visibility, phase or callback guard is replaced by cached authority. Cue equality walks the finite validated reference, rejects candidate type/shape/key mismatches and compares float bytes. It imposes no new AuthoredSequence 1 MiB bound on projected events. The large structural Cue control explicitly fails whole-Footprint provenance; it proves transport compatibility, not new damage authority.

The Cue reference is independently cloned, private and never returned; public `projection_state()` remains a mutable defensive copy. Nested containers are marked read-only, but those flags alone are not an immutable security boundary. Matching [Array source](https://github.com/godotengine/godot/blob/ed1daf0bf/core/variant/array.cpp#L206) and [Dictionary source](https://github.com/godotengine/godot/blob/ed1daf0bf/core/variant/dictionary.cpp#L398) inspection shows native `assign` lacks the corresponding read-only guard. Custody therefore relies on keeping the reference unexposed, as the original private wire did; arbitrary private-field reflection/forgery remains unsupported. No native `assign` safety claim follows from this source inspection.

The combined [second optimized profile](evidence/shared32-runtime-comparison/logs/authored-echo-performance-fast2.log) closed cleanly: 113 / 0, 8.067477 seconds inside 72 automatic advances, 9.138079 seconds of wall time for 1.2 simulated seconds; maximum advance 856.035 ms. Fixed-clock probe medians were source 4.445 ms, Cue 4.661 ms, reservation 4.778 ms, Cursor 3.215 ms and renderer 0.506 ms. The first-cycle [affected playback](evidence/shared32-runtime-comparison/logs/authored-playback-fast2.log) also passed 312 / 0. Remaining cost and variance are substantial; the Act1/Act3 performance requests remain open. The protocol change is present in the combined source set but that one-Box profile does not exercise C31.

[Portable original evidence](evidence/shared32-runtime-comparison/index.json) preserves twelve closed jobs, 933 original source files, all full logs and closures, including the failed first baseline. All jobs use the canonical `python3 scripts/dev/dev.py engine` queue. Retained receipts separate known semantic arguments from unavailable exact argv; no reconstructed command or later publication receives execution credit. Named targets are added after these original runs. Repeating/late-dead lifecycle drafts and saved-player prevalidation framing remain separate unfinished work.
