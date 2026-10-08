# HUD health display

The shared HUD displays canonical Cargo capacity as **HP 100 / 110**, and full Cargo health as **HP 110 / 110**. Binary64 arithmetic can resolve `100 * 1.1` to `110.00000000000001`; an unconditional ceiling previously displayed 111.

`GameHUD._display_health` applies the same display-only rule to current and maximum HP. Nonpositive values display 0. A positive value snaps to `roundf(value)` only when that integer is positive and the difference is at most `8 * 2^-52 * max(1, abs(value))`; it then uses `ceil`. The positive-integer guard keeps even `1e-300` living HP visible as 1. Meaningful fractions remain visible: 110.25 and 110.000001 display 111, while 109.25 displays 110.

Actual Player HP, equipment, capacity, clocks and snapshots are unchanged. The health-bar fraction remains the raw `clampf(hp / maxf(max_hp, 1), 0, 1)`; this change alters neither bar geometry nor HUD layout.

[The portable native evidence](evidence/hud-health-rounding/README.md) preserves both Godot 4.7.2 graphical runs and their separate original 18-source subsets. The first completed 49/1 because its fixture required exact equality for a derived native float32 width. A fixture-only repair checks the scalar fraction exactly and bounds the derived native width; the unchanged HUD then completed 49/0 clean. Both original 540×1170 PNGs show the full 110/110 label and were viewed by the integration owner.

The test uses actual HUD native labels, canonical Cargo equipment and a paused shared Player. It verifies unhealed 100/110, a disclosed TEST ONLY initial public full-HP seed, fractional/zero/tiny controls, exact unchanged actor snapshots and fitted HUD bounds. This is bounded display evidence; no campaign route, input/controller, authored-level or human play claim is made. The canonical named target is `python3 scripts/dev/dev.py test hud_health_rounding`; its mapping was added after these original direct queued graphical jobs.
