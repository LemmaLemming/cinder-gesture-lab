# HUD health display native evidence

Both original queued graphical runs are preserved independently. Portrait1 closed with **49 checks, 1 failure** (session 5555, exit 1): the fixture compared a derived native float32 `Control.size.x` exactly. Portrait2 closed with **49 checks, 0 failures** (session 80798, exit 0), after a fixture-only repair that keeps the health-bar scalar fraction exact and bounds its native width representation. The production HUD bytes are identical in both runs (`3a76c06a97da117b2fbd43824d88f3ef5150e6ad0045b5e27766b8d70542897b`). The first failure, backtrace and complete wrapper output remain intact.

The fixture uses the actual shared HUD, canonical Equipment and a ready paused shared Player on a native floor. Equipping Cargo through the public paused bench leaves current HP 100 and resolves capacity to binary64 `110.00000000000001`. Actual native label assertions read **HP 100 / 110** and, after an explicitly TEST ONLY initial paused public full-HP seed, **HP 110 / 110**. Fractional, tiny-positive, zero and negative controls preserve Player snapshots, the raw bar fraction, label layout and protected combat rectangle. The `1e-300` positive control prints as `0.0` in Godot's description string; its literal source and distinct **HP 1 / 1** expectation are retained.

Both original captures are 540×1170 and byte-identical, but retain separate filenames and run identities. Root viewed both through `view_image` and reported a clear final **HP 110 / 110** label. The PNGs show the standalone grey GUI host; **HP 100 / 110** is established by the native node assertions, not a separate screenshot.

| Run | Native log | Wrapper output | Original source manifest | Original PNG |
| --- | --- | --- | --- | --- |
| Portrait1, 49/1 | [raw](logs/hud-health-portrait1.log) | [wrapper](logs/hud-health-portrait1-wrapper.log) | [18 sources](sources/portrait1/manifest.json) | [PNG](portraits/hud-health-rounding-35862-833474.png) |
| Portrait2, 49/0 | [raw](logs/hud-health-portrait2.log) | [wrapper](logs/hud-health-portrait2-wrapper.log) | [18 sources](sources/portrait2/manifest.json) | [PNG](portraits/hud-health-rounding-85498-824151.png) |

[index.json](index.json) records exact argv, sessions, root-observed exits, source identities, artifact byte counts and SHA256 hashes. Each original source manifest and all 18 declared files were copied byte-for-byte and independently verified. These are bounded pre-queue referenced-source subsets, **not** complete engine import/resource graphs. Root added named dev targets after closure; the archived original `dev.py` bytes are not a claim about the current tool bytes.

Godot 4.7.2 (`ed1daf0bf`) used the native Apple M3 OpenGL Metal compatibility renderer. Portrait2's raw and wrapper logs contain no ERROR/WARNING/Script/Parse diagnostics. This evidence covers display-only HUD behavior and the disclosed paused actor seed. It establishes no campaign route, controller/gesture exercise, authored-level acceptance, native OS/human play or mobile export. The helper archived existing closed jobs and ran no engine. Native targets and archive review are complete; root publication remains pending.

See [HUD_HEALTH_DISPLAY.md](../../HUD_HEALTH_DISPLAY.md) for the display rule.
