# Crystalman local save recipient: focused native results

On Shared54, the **test-only** one-slot and two-slot recipients pass **300/0** and **350/0**. This verifies an exact local captured-rule aggregate in independent paused native candidates. It does not accept A3-L5 or establish whole-parent campaign Save, Continue, Retry, framing artwork or production art support.

The active production prototype remains `scripts/acts/act3/crystalman_rule_room.gd` at `915252a2…`; its whole-parent snapshot remains explicitly unsupported. These new resources live only under `tests/acts/act3/`.

## Actual commands and custody

| Command | Result | Frozen inputs | Original raw SHA256 |
| --- | --- | --- | --- |
| `python3 scripts/dev/dev.py import` | Clean exit 0; necessary new resources and Shared54 import | 556 unchanged | `db5e2048a1fe43939e9edabd37e6574186788c0feb9075a220cd386dee649bfe` |
| `python3 scripts/dev/dev.py engine --headless --path . --script res://tests/acts/act3/captured_rule_save_codec_smoke.gd` — first run | Exit 1; 187 checks, 1 failure, 174 script errors | 559 unchanged | `d4e13059d533050e93430f0490c26592fa1f09839451d1f1aec9f29c90940978` |
| Same command after the two property corrections | Clean exit 0; 300/0, 565 actual post-actor ticks | 559 unchanged | `f707f7f7696d686b27cae2a943e8a1f04b6527f67000245aefc3d912f64c269e` |
| Same command with `-- --captured-codec-two-slot` | Clean exit 0; 350/0, 729 actual post-actor ticks | 559 unchanged | `622ca660617cf1b523d262838fbec94a919c9267dc3190be847f657eddc5444c` |

Each queued Godot job closed normally through its own handle. Frozen sources, commands, diagnostics, explicit footers and raw logs remain in the corresponding `.cinder/crystalman-codec-*` directories. Literal resources, named script dependencies and sidecars are frozen; imported `.godot` cache is excluded. This is not a claim to capture the entire import graph.

The import preserved all 468 prior UID bytes and generated exactly three genuine test script UIDs, for 471 unique values with no collisions. It establishes resource import, not gameplay success.

## Failure and correction

The first meaningful error is `Invalid access to property or key grow_enabled on StandardMaterial3D`. It interrupts the native material guard before the exposed marker's opacity check, so successful-looking checks in that failed run do not qualify the validation boundary. The failed run and original source bytes are retained.

The [official BaseMaterial3D API](https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html#class-basematerial3d-property-grow) names the boolean property `grow`; `set_grow_enabled` and `is_grow_enabled` are its accessors. The correction changes only two property reads, in the native recipient guard and fixture receipt, to `material.grow`. It preserves the false-value guard, actual alpha/mask negative checks, all mechanics, clocks, geometry, deadlines and assertions. The same affected fixture was rerun, followed by the distinct two-slot capacity case; no broad suite or repeated import was needed.

## Verified scope

Real shared input creates empty/pending recordings, the first sealed slot of two, warning, lock, active replay, an interrupted native suffix, exposed tether, spent recovery, original natural completion and pre-admission rejection. The test transports the full Player and sole Gate, whole Scheduler, projected Playback, source sequence, FIFO retirement, original leases, geometry, proof and owned state through an actual isolated JSON file. Fresh recipients restore quietly without arm, preparation, admission, consumption, reproving, clock offsets or payload repair. Exact recapture, pure malformed-packet rejection, native camera/HUD bounds, actual marker alpha and camera-mask rejection, consumed GUI Resume and normal disposal pass.

The candidate receives the saved camera transform explicitly in the test. This does not establish campaign input-anchor restoration. Headless native bounds checks do not establish rendered portrait fidelity or human balance. Framing optics deliberately remains unsupported until an inert original captured-art recipient exists; the full production parent cannot rely on partial save fallback.

Required current canonical ability, equipment and numerical specification validators all exit 0. Ability revision 0 has 20 registered abilities and no uses; equipment has 36 types, no claims and no duplicate types. No new equipment, perk, powerup or introduction was allocated. Numerical screening does not establish human balance or unsimulated timing.

## Remaining authored level work

Act3 remains **4/8 accepted**, campaign **15/24 published**. A3-L5's full approach, regular encounters, one-slot to two-slot transition, external permanent floor, scenery stripping, contact coda, whole campaign persistence and actual portrait checks are unfinished. The full production implementation is being drafted separately. O1, O2 and O3 follow L5 acceptance under focused desktop acceptance; full playthrough behavior remains untested.
