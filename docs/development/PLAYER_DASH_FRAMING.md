# Committed Player dash framing

The additive `player-dash-framing-1` presentation query exposes the actual shared Player's accepted dash cache. It lets a camera consumer bound intended travel while current velocity is shortened by collision or scaled on the final physics step, and while current gear differs from gear accepted at dash start.

```gdscript
func get_committed_dash_state() -> Dictionary
```

The defensive native result has exactly these fields:

```gdscript
{
    api_revision: "player-dash-framing-1",
    active: true,
    origin: Vector3, direction: Vector3,
    speed: float, duration_s: float, distance: float,
    remaining_s: float
}
```

Origin, horizontal normalized direction, speed, total duration and remaining time come from the committed dash cache already saved by [player-snapshot-1](SHARED_CONTRACT.md). `distance = speed * duration_s` is the nominal full intended travel budget. It is not measured distance, remaining straight displacement, a predicted collision-shortened endpoint, supported landing, or escape authorization. The active dash can be moving, blocked or sliding. Use actual public motion/pose and validated body/static-world queries when bounding the current view; preserve the current projection and required cues before damage.

Idle, completed and dead actors return `active = false`, null origin/direction/speed/duration/distance and `remaining_s = 0.0`. Old cached values and the private inactive infinite origin sentinel do not leak. An unfinished dash whose world-action capture was cancelled still exposes its continuing physical commitment. Buffered requests do not replace the current dash; their parameters appear only when they really begin. Current clothing changes do not retune the accepted cache.

This pure accessor does not require pause, emit events, change clocks, gear, physics, diagnostics or records, or inspect/consume input. Values are native copies. It adds no snapshot fields: exact paused fresh restoration uses the existing stored cache and needs no historical framing reconstruction. Completed executed paths remain available separately through [world-actions-1](SHARED_CONTRACT.md).

Malformed/nonfinite active cache returns an empty dictionary rather than a usable span. This query does not validate scenery, supported floors, body configuration, alternative swipe input or camera containment. It changes no controller, damage, gesture, aiming, collision or simulation behavior, and does not establish a whole encounter or authored camera acceptance.

## Focused validation

`tests/player_dash_framing_smoke.gd` uses actual shared Players, real physics, a native capsule wall collision, legal paused clothing changes, buffered requests, explicit capture cancellation and real lethal damage. It checks idle/active/completion semantics, native defensive results, complete state/event/diagnostic purity, retained accepted parameters despite retuned gear or blocked velocity, exact tagged mid-dash fresh paused restoration and actual continuation. The final focused leaf passed **38 checks, 0 failures**, exit 0 on Godot `4.7.2.stable.official.ed1daf0bf` (`.cinder/player-dash-framing-final.log`), including native UID generation for the new test. Its log preserves a native macOS certificate lookup startup diagnostic; there were no script or test failures. The first run also passed 38/0 with the identical Player source (`.cinder/player-dash-framing.log`). No baseline rerun is implied.

```sh
python3 scripts/dev/dev.py engine --headless --path . --log-file .cinder/player-dash-framing-final.log --script tests/player_dash_framing_smoke.gd
```
