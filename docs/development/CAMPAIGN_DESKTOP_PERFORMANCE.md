# Actual accepted-scene opening measurements

The [graphical harness](../../scripts/dev/campaign_desktop_profile.gd) completed twelve valid instrumented opening cells through actual canonical accepted A1-L1/A2-L1, unchanged `scenes/main.tscn` and shared Game/controller/recognizer/camera/HUD/effects. This is separate from the earlier [plain-floor shared-fixture profile](DESKTOP_PERFORMANCE.md).

```sh
python3 scripts/dev/dev.py engine --path . --log-file .cinder/campaign-desktop-profile-final.log --script res://scripts/dev/campaign_desktop_profile.gd -- --scripted-background --profile-output=res://.cinder/campaign-desktop-profile-final.json
```

The harness requires an actual graphical renderer and explicit scripted-background scope. Native window/output is 540×1170; the unchanged production nearest world raster remains 270×585. It creates twelve fresh-scene cells: A1-L1/A2-L1 × Low/Standard/High × 30/60 FPS, with 1.5 seconds of warmup and eight seconds of measurement each. The normal starter equipment/resources/physics, renderer, VSync, collision, scenery, warnings and action effects stay intact. Reduced motion is false throughout this initial bounded matrix; reduced-motion performance remains unmeasured.

Each cell updates a local `CinderGameSettings` using `update(..., false)`, calls public `apply_runtime()` and configures actual effects with `cosmetic_policy()`. It never persists production settings or saves. Normal FPS/audio state restores on finalization. The sole initial resume uses public `resume_lab()`; normal app/focus pause notifications remain active. A later pause, death, level error, scene/registry change, nonadvancing simulation or incomplete real workload invalidates the run. No focus grab, notification override, macOS unlock, repeated unpause or process-mode override occurs. Native focus transitions are observed; OS lock state is neither inspected nor asserted as measured.

Four actual routed swipes alternate along the opening floor at sampled actor times 0.2/2.2/4.2/6.2 seconds; four ordinary aimed primary taps execute at 0.7/2.7/4.7/6.7. The same real viewport input reaches the shared recognizer, exact release anchor and ordinary actor actions. No actor transforms, HP/ammo/clocks or encounter phases are assigned; no extra artificial particle workload or blasts are injected. Actual completed action counts and source phase/stage observations are retained. Quiet rehearsal or out-of-range primary samples are reported accurately rather than treated as complete combat measurements.

Raw monotonic intervals between `RenderingServer.frame_post_draw` signals provide mean FPS and nearest-rank p50/p95/max; they include cap, VSync, OS scheduling and the harness itself, and do not measure physical presentation latency. Actual actor seconds, physics/drawn frames, actions, HP, scene identity, phase-frame counts, focus transitions and cosmetic policy accompany each cell. The observer reads the registry file each rendered frame, copies public encounter/source state and serializes phase keys. These operations and enabled render timing instrumentation are included in the intervals; their overhead was not separately measured or removed. The A2 observer copies a larger encounter than A1. These measurements therefore cannot attribute a slowdown to gameplay, physics, rendering, a quality preset or the observer.

The raw `diagnostics.process_ms` and `diagnostics.physics_process_ms` fields preserve sampled `Performance.TIME_PROCESS`/`TIME_PHYSICS_PROCESS` values. The inspected engine publishes approximately one-second cached `process_max`/`physics_process_max`, rather than a fresh per-frame cost. Their reported p50/p95/mean summarize repeated cached values weighted by observed frames; they are **not per-frame process/physics cost percentiles**, and cache windows can straddle warmup or cell boundaries. Treat them as diagnostic cached maxima. Draw/object/FX monitors can also lag; none of these counters measures whole-system CPU utilization.

The harness enables native root and actual world viewport render CPU/GPU timing only when the installed singleton exposes the supported methods. Each viewport counter reports availability; no positive native samples means unavailable, not zero rendering cost. CPU viewport counters exclude unrelated script/physics costs; GPU clocks and cap/power states can affect measurements. See the inspected [official RenderingServer APIs](https://docs.godotengine.org/en/4.6/classes/class_renderingserver.html#class-renderingserver-method-viewport-set-measure-render-time). Installed Godot version and observed support are authoritative.

Outputs remain ignored under `.cinder`. Exit 0 requires all twelve valid cells and an unchanged isolated settings path. The 180-second watchdog fails incomplete runs. This single fixed-order, short, debug-runtime, scripted background/possibly locked-Mac opening matrix cannot establish thermal/sustained performance, release performance, human-input latency, campaign fairness, all 24 levels, mobile/device/export readiness, or a causal quality ranking. Startup/source construction and warmup are excluded; effects generated during sampling are included. No broader suite is required by this measurement.

## Observed run

The final canonical graphical job completed **12/12 valid cells**, exit 0, in **117.47 seconds**, using Godot `4.7.2.stable.official.ed1daf0bf` on Apple M3/8 logical CPUs, macOS Compatibility/OpenGL3 through OpenGL4.1 Metal90.5. VSync remained enabled, physics remained 60Hz and time scale remained 1. All focus observations were false. OS lock state was not measured. Original local evidence is `.cinder/campaign-desktop-profile-final.json` and `.cinder/campaign-desktop-profile-final.log`; [portable original reports/logs and interpretation](evidence/campaign-openings-performance/index.json) are also retained; the final log contains no error/warning/script diagnostics.

| Scene | Quality | Cap | Mean FPS | p50 ms | p95 ms | Max ms |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| A1-L1 | Low | 30 | 29.27 | 33.36 | 35.85 | 135.10 |
| A1-L1 | Low | 60 | 57.67 | 16.68 | 21.57 | 112.66 |
| A1-L1 | Standard | 30 | 29.23 | 33.31 | 35.88 | 137.50 |
| A1-L1 | Standard | 60 | 55.82 | 16.68 | 20.61 | 242.99 |
| A1-L1 | High | 30 | 29.29 | 33.26 | 35.72 | 143.37 |
| A1-L1 | High | 60 | 57.27 | 16.62 | 19.31 | 120.46 |
| A2-L1 | Low | 30 | 23.83 | 33.35 | 121.18 | 163.73 |
| A2-L1 | Low | 60 | 45.87 | 16.70 | 56.70 | 185.41 |
| A2-L1 | Standard | 30 | 21.24 | 33.40 | 140.00 | 179.05 |
| A2-L1 | Standard | 60 | 45.46 | 16.69 | 80.73 | 145.16 |
| A2-L1 | High | 30 | 21.17 | 33.53 | 128.39 | 240.24 |
| A2-L1 | High | 60 | 45.28 | 16.68 | 70.30 | 152.87 |

Every cell observed exactly four completed routed dashes and four executed ordinary primaries, with no blasts or collision-shortened dashes. Actual actor simulation advanced 7.82–8.03 seconds/469–482 physics frames. A1 advanced real beats 0→1→2, accepted one primary hit and stayed at 100HP; both loading arms remained clear. A2 remained in `arrival`, observed genuine warning/lock/active/recovery across the arrival Scout's cycles, accepted zero primary hits and ended at 90HP from real damage. No death, later pause, route clear, resource assignment or fabricated combat coverage occurred.

Native root/world render CPU counters returned positive values. Both native GPU counters returned zero throughout and are marked unavailable; the renderer still used the actual Apple M3 GPU. Neither zeros nor positive render CPU counters identify the cause of the frame stalls. FPS restored to its original 0, the original audio layout was restored and the isolated settings path remained unchanged. Reduced-motion timing, other encounters, menu/save workload and all remaining levels remain unmeasured.

The initial run also produced twelve valid cells but logged a finalization-only stale viewport diagnostic after freeing the last scene before disabling native timing. Its original `.cinder/campaign-desktop-profile-initial.json`/`.log` are retained. The harness-only cleanup ordering was repaired and the targeted matrix repeated once; measurement/workload code stayed unchanged. No shared gameplay/settings/source file or baseline suite changed.

The cached monitor interpretation was checked against [the installed engine source](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/main/main.cpp#L4723-L4762). Independent review confirmed sample-only actions, exact measured interval sums, actual accepted scene/script identity, pure encounter observation, unmodified normal focus behavior and FPS/audio restoration.
