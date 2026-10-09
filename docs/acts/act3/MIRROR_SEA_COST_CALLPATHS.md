# Mirror Sea native-validation cost hypothesis

Read-only source review, 9 October 2026, on the actual Shared39 checkout. This identifies repeated work for later measurement; it supplies no elapsed-time, frame-rate, rendering or performance acceptance result. The review began while route session83376 was queued with339 frozen inputs. That job subsequently closed8checks/1failure/exit1 with an optional-adapter test-observer error; its original sources are archived exactly. This cost review changes no native actor validation, callback, cancellation or gameplay state.

## Repeated work within one native inspection

In [Mirror Echo](../../../scripts/acts/act3/mirror_echo.gd), `source_native_error`292–298 calls `_current_native_error`301. After retained parent/world/Scheduler/renderer/resource checks, line320 calls the owned marker's `native_error(dead)`. On success, line323 calls `_resource_receipt`; its line366 calls the same marker's `immutable_descriptor`.

In [spent marker](../../../scripts/acts/act3/mirror_echo_spent_marker.gd), `native_error`119–127 and `immutable_descriptor`77–78 each call `_immutable_error`164–177. Each successful call reconstructs `_current_descriptor`180–205. The descriptor enumerates native root properties and the three retained Box parts, reads their surface arrays and hashes node/mesh/material/array receipts. Its successful path performs13 digest calls: one root receipt and four per part. Thus a successful source-native inspection builds the same marker descriptor twice within one synchronous source call. There is no await or explicit signal/event dispatch between those two calls in the inspected path. This observation alone does not authorize reuse across callbacks or skipped native validation.

Echo `_resource_receipt`344–369 separately rebuilds native receipts for the16 renderer Boxes plus the fixed knot. `framing_points`398 first calls `source_native_error`, then line411 calls marker `framing_points`; marker132–134 invokes `native_error` again. This adds a third marker descriptor reconstruction in the ordinary successful framing path. The hidden living marker still undergoes native validation before returning no required corners.

## Production boundaries and fixture overhead

For a regular held/running Echo tick with no newly accepted lock, cancellation, fatal callback or entry transition, the following actual paths each validate the source. This is a lower bound for that stated path, not a whole-frame timing measurement.

| Boundary | Current call path | Marker descriptor passes within that call |
| --- | --- | ---: |
| Parent guard90 | parent297/303 → camera union662/693 → bounds743/745 → Echo framing398 | 3 |
| Source110 | Echo physics468/470 → source-native inspection | 2 |
| Parent130 general validation | parent266/272 → runtime_error1020/1038–1045 → source-native inspection | 2 |
| Parent130 running-source view | parent523/530–531 → view724/728 → union662/693 → bounds743/745 → Echo framing398 | 3 |

The two parent130 calls occur in one parent callback. The90 and110 callbacks remain distinct mutation boundaries. An accepted due lock at parent335/341 changes the commitment and adds the intentional fresh postcommit view at349. That check cannot be treated as equivalent to the earlier precommit view. General runtime validation also checks retained dead Echo owners; framing only includes the currently running sources plus the specified prospective candidate.

The route fixture adds separate work after its barrier: route546 calls parent `runtime_error`, and549 calls parent `state`; parent1078/1082 calls each Echo `get_source_state`284/285, which invokes `source_native_error`. Those observer costs must be reported separately from production work. Continuous route validation must remain intact during any measurement.

## Scenery boundary qualification

Parent runtime validation calls `_vignette_root_error`1057, a retained-root/identity/world/pose/process-policy check. Its comment and code explicitly exclude the193-part native property/texture walk. `_vignette_full_error`1066 reaches that full walk at finite capture1111 and saved-candidate presentation1204, or through explicitly requested optional-art bounds. The reviewed normal physics/view path does not establish193-part full-validation work every tick. Rendering cost of that art is still unmeasured and separate.

## Next supported measurement

After the current frozen job closes, measure the relevant owned validation boundaries on actual source instances by source ID, native phase and caller90/110/130. Record monotonic elapsed times and counts for `_current_native_error`, `_resource_receipt` and marker `_current_descriptor`, preserving every existing guard, callback and cancellation. Separate production callbacks from route/test observer reads and finite snapshot/candidate work. Keep real scheduling, source resources, native geometry and ordinary-input semantics unchanged. Measurement must precede a cost conclusion or implementation choice; no cache, guard skipping or timing change is proposed as verified here.

The shared runtime-cost request remains open and integration-owned. This owned call-path hypothesis adds a concrete candidate for measurement; it does not identify the cause of queue waiting, historical focus/draw failures or a particular live CPU sample.

## Exact inspected sources

- `scripts/acts/act3/mirror_echo.gd` — SHA256 `a4f5e47f457b513a348b7e201dbd3374711e4f60cd5d2a40389a5118d422da6c`.
- `scripts/acts/act3/mirror_echo_spent_marker.gd` — SHA256 `c28d5c50a697052dff14560efe0ee2d9cb3a91c9902d047d126e19bd1122129c`.
- `scripts/acts/act3/mirror_sea_level.gd` — SHA256 `4af8680418d0b7449f0750315a8672282f652d5d782878f5c4e7206d6a362b72`.
- `tests/acts/act3/mirror_sea_route_smoke.gd` — SHA256 `62158f6cd3bca6ddee7de26b198ac07438352c144af95e07821a7e24c5541521`.

## Official profiler research — inspected 9 October 2026

Godot4.7.2 selects its local debugger with `--debug`; `--profiling` starts the scripts profiler only when that debugger is active. [Pinned main.cpp, lines1429/1782/3621](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/main/main.cpp). The local profiler prints function signatures, inclusive/self times and call counts for sampled frames, then accumulated data when disabled. Its error-break option avoids the interactive error stop while ordinary errors still print. [Pinned local debugger, lines36–108/110–113/346–348](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/core/debugger/local_debugger.cpp). Normal debugger deinitialization disables active profilers. [Pinned engine debugger, lines157–169](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/core/debugger/engine_debugger.cpp).

This supports a future measurement without editing actor validation code. After the current corrected full-route target closes and its failure, if any, is resolved, the already-required recovery-death branch can carry profiling:

```sh
python3 scripts/dev/dev.py engine --headless --path . --debug --profiling --ignore-error-breaks --script res://tests/acts/act3/mirror_sea_route_smoke.gd -- --resonant-death-only
```

The actual dev.py engine path517–532 forwards these flags and preserves the shared lock249–281. The partial route accepts no final-priority selector. Raw engine jobs284–291 still require inspection of the full error log and explicit result, since they do not use the named-suite error scanner. This command is proposed and unexecuted; the closed session83376 was unprofiled. The subsequent route observer correction changes only five optional-adapter kind reads, leaving these inspected cost call paths unchanged. There is no extra engine process, runtime guard change or repeated successful target solely for this plan.

I infer from the signature-based output that it cannot directly identify each source instance, caller or phase. Inclusive totals overlap and must not be added into a frame total. Native route events can provide context, but do not turn function aggregates into isolated production costs. Profiling overhead and headless rendering also prevent an unprofiled desktop FPS claim. Verify actual profiler start/output/normal shutdown before treating the expected capability as observed on this installed build.
