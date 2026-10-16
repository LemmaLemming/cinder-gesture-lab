# Bounded native script-profiler capture

The corrected capture completes the existing113-check authored fixture and exports1,083 native profiler function records before engine teardown. The table includes423 positive-call records and660 explicit zero-count records; it is not1,083 distinct executed functions. No production source changes. The one owned child exits0; the host remains2/nonclean because114 debug compile warnings and the original macOS certificate diagnostic are retained. All102 fixed observations—92 original runtime/config/fixture/UID inputs plus10 private driver/parser/host controls including the new UID absence—stay exact through lock, child closure and host closure. [Original evidence and Root review](evidence/runtime-dynamic-profiler/README.md) preserve both captures.

A22-line private driver awaits the unchanged fixture’s completion and disposal, then disables the scripts profiler synchronously. Actual state witnesses change active→inactive with fixture113/0 and unchanged physics103/process28 counters across the stop. The scope starts at profiler startup and ends at that explicit postfixture stop. It includes admission, manual and automatic advances,15 separate fixed-clock probes and fixture cleanup; it excludes engine teardown and unfinished outer calls. It is neither whole-process nor automatic-tick-only attribution. The original capture’s empty final accumulator remains incomplete, not evidence of zero calls. Its four periodic frames are not summed or substituted for the missing final export.

These are literal profiler-recorded counters and printed times from the corrected capture. Inclusive scopes overlap; their totals must not be added.

| Synchronous function | Reported calls | Inclusive seconds | Printed self seconds |
| --- | ---: | ---: | ---: |
| Scheduler.replay_reservation_error | 524 | 1.911713 | 0.00211 |
| Scheduler.authored_replay_source_error | 532 | 1.715497 | 0.006324 |
| Authored.snapshot_error | 690 | 0.690474 | 0.002121 |
| Authored._walk_json | 807027 | 3.066043 | 0.558383 |
| SnapshotCodec.value_error | 745674 | 2.861171 | 0.430383 |
| ExactJson._encode | 398164 | 3.355354 | 0.413474 |
| Difficulty._catalogue_validation_input_matches | 532 | 0.017308 | 0.017308 |

The output’s accumulated self total10.605272s is not wallCPU. In particular, the fixture’s TimedActor.advance and inherited physics wrapper report self3.345960s and3.301232s while nested Playback.advance reports inclusive3.344893s. This prevents an exclusive wall-cost decomposition from those fixture tallies; inheritance/instrumentation is a possible explanation, not a uniquely proved cause. General async-entry semantics are not inferred from raw call counters. Native target counters, exact decimals, all1,083 rows and the complete raw block remain available. No per-tick/probe subtraction, FPS, production16-visual cost, causal gain or campaign-wide measurement follows.

The concrete next action is a source audit of repeated validation traversals, with native binding, bounded-input checks, subclass fallbacks and error order preserved. This is an optimization hypothesis, not an implemented fix or a guarantee of material gain. The earlier [two-field projection stays withdrawn](RUNTIME_SOURCE_PROJECTION_WITHDRAWN.md), and both runtime-cost requests remain OPEN. There is no additional route, all-kit or sustained60FPS gate.

Root inspected [Godot4.7.2 local profiler export](https://github.com/godotengine/godot/blob/4.7.2-stable/core/debugger/local_debugger.cpp#L46), [shutdown ordering](https://github.com/godotengine/godot/blob/4.7.2-stable/main/main.cpp#L4881) and the [EngineDebugger profiler API](https://docs.godotengine.org/en/stable/classes/class_enginedebugger.html#class-enginedebugger-method-profiler-enable). The source places language finalization before debugger deinitialization; this motivated the earlier explicit export. Actual before/after witnesses and a nonempty final table validate the adaptation in the sealed4.7.2 engine. The first empty export and all original diagnostics remain unchanged. No engine rebuild, toolchain modification, remote debugger, mobile or export work was used.
