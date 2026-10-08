# Desktop shared-fixture measurements

The [graphical benchmark harness](../../scripts/dev/desktop_profile.gd) completed its queued graphical run on 8 October 2026. Integration reviewed all six valid JSON cells and the runtime log. It measures scripted shared player/effects work; accepted authored campaign levels need their own later measurements.

Run from the canonical integration checkout through the shared Godot queue:

```sh
python3 scripts/dev/dev.py engine --path . --script res://scripts/dev/desktop_profile.gd -- --profile-output=res://.cinder/desktop-profile.json
```

This is a graphical job. The optional output argument accepts only ignored `.cinder/*.json` paths. Without it, the harness writes a timestamp/PID filename there. The process exits after six cells, normally about 18 seconds plus startup, with a 25-second harness watchdog. Exit 0 requires six valid cells and a written report; exit 1 records an incomplete/invalid measurement, and exit 2 means configuration/output failure. Review the JSON validity flags and runtime log before reporting performance.

All six cells use the same shared `CinderPlayer`, starter equipment, Act2 presentation, original plain static floor/two blockers and shared `PixelEffects`. The portrait output is 540 × 1170 with a nearest-filtered 270 × 585 world viewport. Camera projection, width 7.2, fixed angle/offset and 0.16-second following constant match the existing game. A fresh actor starts each cell; nothing changes a production save, registry, scene acceptance or settings file.

The cells run Low/Standard/High, each at 30 then 60 FPS, with 0.7 seconds of warmup and 2.3 seconds of sampled wall time. Public actor APIs schedule three dashes, three primary attacks and two blasts on the simulation clock. The nearby box shortens a real dash. Blasts retain the bright barrel-origin flare; the shared connected plume, slash and resolved footprints retain full settings policy. Each blast adds a bounded 24-piece optional impact and five flecks; decorative smoke is attempted every 0.2 seconds. Normal ammo and cooldown rules remain active. The report records actual executed action counts rather than assuming requests ran.

The primary samples are monotonic wall intervals between `RenderingServer.frame_post_draw` signals. Mean FPS is sampled interval count divided by elapsed wall time; p50/p95 use nearest ranks and max retains stalls. These intervals include frame-cap, VSync and OS scheduling delays. They do not measure physical screen presentation latency or isolated GPU time. [RenderingServer documentation](https://docs.godotengine.org/en/4.6/classes/class_renderingserver.html#class-renderingserver-signal-frame-post-draw) defines the signal after viewport updating.

`Performance` process/physics times, draw/object counts and actual optional-effect counts are diagnostic summaries. Engine timings are not CPU utilization, and a zero or stale counter does not prove zero cost. Some monitors can lag or be unavailable, as described by the [official Performance documentation](https://docs.godotengine.org/en/4.6/classes/class_performance.html). The API references inspected are Godot 4.6; the report records the actual installed engine/version, rendering method/driver, adapter, CPU, debug mode, physics tick rate, VSync and window focus. Integration's Godot 4.7.2 run must confirm these calls execute before measurements are accepted.

The standalone fixture has no campaign-shell app-focus pause handler and injects no native gestures. It neither unlocks macOS nor operates the locked UI. Paused trees, insufficient rendering, nonadvancing actor simulation and missing required executed actions invalidate the run. Unfocused or locked/background scheduling remains a recorded limitation even if scripted simulation advances.

This short sequential run cannot establish sustained/thermal performance, confidence intervals, loading performance, release-build performance or performance across all 24 campaign levels. Startup/source construction and warmup are excluded from each cell; effects created during sampled actions remain included. No mobile, physical-device, human-input, campaign-fairness or completed-campaign performance claim follows from this harness. The original `Engine.max_fps` is restored on normal/error finalization.

## Observed desktop run

Godot4.7.2 official debug runtime on AppleM3/8 logical CPUs, macOS, Compatibility/opengl3 through OpenGL4.1 Metal90.5, VSync enabled, 60Hz physics. All six windows were unfocused at sampling end. Total run19.25s; each cell sampled2.31–2.35s after0.7s warmup. Ignored raw evidence: `.cinder/desktop-profile.json` and `.cinder/desktop-profile.log`. All cells advanced real actor simulation2.23–2.25s/134–135physics ticks, rendered62–120frames and passed active-fixture validity.

| Quality | Cap | Mean FPS | p50 ms | p95 ms | Max ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Low | 30 | 26.81 | 33.37 | 130.06 | 140.68 |
| Low | 60 | 50.69 | 16.61 | 34.25 | 122.73 |
| Standard | 30 | 27.10 | 33.37 | 121.23 | 140.97 |
| Standard | 60 | 50.96 | 16.64 | 40.05 | 120.89 |
| High | 30 | 27.19 | 33.26 | 119.95 | 136.24 |
| High | 60 | 51.43 | 16.52 | 19.29 | 112.29 |

Every cell actually executed two completed dashes (one collision-shortened), three primaries and two blasts, with eleven decorative-smoke attempts and two optional impact emissions. Three dash requests were scheduled; the report counts only completed accepted publications and does not claim every request executed. Original max FPS0 was restored. No script/resource errors appeared in the final graphical log.

These results contain large stalls and miss both caps. The unfocused short sequential fixture cannot identify whether effects, cap/VSync, scheduling or other work caused them; it does not establish that High is faster or that Low meets a performance target. Retain required feedback. Repeat only an affected authored-level/performance concern under a recorded foreground condition; this measurement is not a release or mobile performance gate. The first sandboxed graphical attempt exited before engine startup while waiting on the queue; the successful run used normal authorized macOS display/log access through the same wrapper.
