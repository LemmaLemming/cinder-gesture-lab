# Crossed entrance geometry — 13 October 2026

The retained native point payload establishes a concrete **entrance-position versus permitted-focus-shift mismatch**. The required union fits the unchanged fixed-width portrait rectangle, but the original stopped Hero at Z −10.4 cannot bring that union into view within the existing 3.6-unit shift. Waiting for ordinary following while keeping that Hero position cannot resolve this rejection. This is not a claim that the chamber is intrinsically too large, that the timeout passed, or that an accepted level must be requalified.

## Evidence and applicability

- Original `.cinder/camera-follow-native1-wrapper.log`, line 44, contains `observations_exact_json`: the actual 14-field tagged payload, including eight provider corners, 22 actual Player corners, native camera basis/spec, three focus references and original rejection results. I decoded its existing exact-json float64 leaves offline; I did not invent a replacement native observation. The portable original is `docs/development/evidence/shared50-desktop-milestone/objects/1f2869453f273d6d1e9934097b446a65a3bceaeafede3c82e0cbe59d949e8561`.
- Native1 remains **31 checks / 1 failure**; public Pause refused the clipped view, and subsequent Resume remained blocked. Native2 remains **exit124/incomplete**, with eleven logged ordinary-update samples and no successful final capture/cleanup footer. Its observations are context, not the basis of the geometric conclusion.
- Current Root source is byte-identical to native1's archived input for `scripts/game.gd` (`0b16d911409350a392f741a07bc163ad73c588d885ee7e1e64b951f97aa30d26`), `scripts/presentation/camera_framing.gd` (`daf839d1e35497c88a59d4c1c2af7bb02194418e2c667aceb677242bd642c39b`), `scripts/acts/act1/mushroom_caverns_full.gd` (`e6669c37647542b6225dbcfabd4e2ec99a4085bf77e3d8ef1b757fdf176956d5`), and `scripts/acts/act1/mushroom_caverns_route.gd` (`3784a019bfd5dec6e49b18e64e73ca00b7fd21dc6497258b9f948154762b18bb`). Therefore these source mechanisms remain applicable at Shared56.

## Exact observed geometry and offline calculation

Native Hero was `(0, −0.00484376167878509, −10.3999996185303)`. The actual camera basis columns are X `(1,0,0)`, Y `(0,0.5854905843734741,−0.8106791973114014)`, Z `(0,0.8106791973114014,0.5854905843734741)`. Width is `7.199999809265137`, viewport `270×585`, offset `(0,18,13)`, max shift `3.6`, plan safety margin `.055`, and the original plan adds `.001` numerical headroom.

Normalized HUD-safe rectangle is `(0.040740739554166794, 0.1726495772600174, 0.9185185432434082, 0.7196581363677979)`. Its camera-plane plan limits are X `[−3.251666588, 3.251666749]` and Y `[−6.065000170, 5.051666459]`.

Projecting the eight actual provider corners gives absolute camera-axis X `[−2.928099871, 2.928099871]` and Y `[8.125337262, 17.938423228]`. Their spans are **5.856199741 × 9.813085966**, smaller than the available **6.503333336 × 11.116666630**. Appending the actual mandatory Player corners does not expand these extrema. The large world-space Y/Z of the eight corners is a camera-basis bounding-box representation, not evidence of tall physical geometry: `mushroom_caverns_full.gd:647–662` compresses the complete point set in that basis.

Mirroring the original planner's scalar dot products and interval calculation offline gives:

| Reference | Original focus Z | Needed Z shift | Nearest fitting focus Z | Result versus max3.6 |
| --- | ---: | ---: | ---: | --- |
| Smoothed focus, Y .74631232 | −.51130569 | −14.84717029 | −15.35847598 | Refuses |
| Shared Hero+.75, Y .74515623 | −10.39999962 | −4.95931131 | −15.35931093 | Refuses |
| Owned Hero+.65, Y .64515620 | −10.39999962 | −5.03153356 | −15.43153318 | Refuses |

These reproduce the three original native rejection reasons without changing the rectangle, points, margins or max shift. They use double arithmetic over already rounded native inputs; a future native run must still confirm final Vector3 rounding.

For this same eight-point union, same Y and central X0 approach, the closest-to-entrance Hero Z satisfying max3.6 is approximately **−11.75931093** under the shared +.75 reference, and **−11.83153318** under the stricter owned +.65 reference. Thus an owner-selected **−12.0** entry threshold is a conservative candidate: needed shifts are approximately **3.35931093 / 3.43153318**, leaving .16847 units under the stricter cap. At that position the translated actual Hero corners remain inside the measured union extrema. This is a specific offline feasibility bound, not a universal threshold for arbitrary lateral positions, motion or loadouts.

## Actual activation and safe holding

`scripts/acts/act1/mushroom_caverns_layout.gd:23` declares `BEAT_THRESHOLDS = [13,2,−10,−25,−38]`. `mushroom_caverns_route.gd:161–162` activates the current room whenever `room_stage == approach` and `hero.z <= threshold`; it does not first require a feasible/currently contained full new union. `_begin_room()` then starts the Scheduler epoch, activates all eight sources, installs the two fields, switches to `active`, and only afterward calls `_framing_ready` (`mushroom_caverns_route.gd:192–220`). That final check records a diagnostic; it cannot undo the already enlarged required union.

The central approach from Z−10 to Z−12 lies within the same existing static Box floor, `SAFE_RECT = Rect2(−6.9,−53.9,13.8,71.8)`, and within the Crossed room rectangle `Rect2(−6.35,−24.9,12.7,14.9)`. Crossed stalks are at X±5.6; their physical width is1.1, so they do not obstruct this central segment. Future sources are genuinely dormant, hidden and noncolliding, with no motion/attack processing (`mushroom_selenite.gd:839`, `1310–1340`). At Z−12 the nearest eventual source centres are `(±.8,−13.6)`, distance≈1.78885; both player and source capsule radii are.32. This supports a plausible central holding location from static source geometry, not a new native support/body/escape proof.

Delayed activation retains the existing `approach` state, prior-room completion and CP2, dormant future actors, and absent Crossed fields/protocols until the real lifecycle switch. The full framing provider explicitly skips dormant actors (`mushroom_caverns_full.gd:592`) and absent fields (`:604`). Thus it currently presents primarily the actual Hero during approach and gains the large room union only at activation. A threshold-only change would improve eventual feasibility but **does not by itself close the instant activation/Pause race**, because smoothed focus can still lag when that union appears. Wide lateral entrance positions can also demand a larger shift or a union wider than the safe rectangle; the central scalar threshold is not sufficient admission for every pose.

## Smallest ownership-safe recommendation

Ask the Act1 owner for a narrow Crossed entrance correction, leaving Root's camera limits and containment/Save guards unchanged:

1. Evaluate a central entrance near Z−12 using the existing source/field layout, and require a feasible full upcoming-room plan for the actual Hero pose before committing activation. A broad global max-shift increase is unsupported by this evidence.
2. Resolve the approach-to-active point-set discontinuity with an authored, pure entry lookahead derived from the real retained source geometry and immutable upcoming field/art definitions. Let ordinary camera following frame that upcoming union, then require **actual current containment** immediately before the real activation. This is an authored camera hint, not permission to create an attack lease, fake installed fields, mutate clocks, or suppress genuine source bounds. The owner must retain/revalidate resource correspondence and preserve supported approach snapshots; do not manufacture future snapshot topology solely to obtain points.
3. Keep existing attack/reaction current-view checks and field/body geometry intact. If the owner finds a smaller placement correction with the same full union and real entry optics, use its actual native evidence instead. Root should not edit these act-owned files without the acknowledged handoff.

The smallest useful validation is one focused actual CP2 Continue, ordinary entrance movement, finite approach hold, real activation and public Pause/Save/Resume case, plus saved approach/active Continue and normal cleanup if the entry state changes. Check the actual portrait at the switch and retain the original31/1 and incomplete124 evidence. No full-route run is needed. A direct TEST relocation to a better point may diagnose geometry but would not establish that ordinary entry is fixed.

The existing `Authored encounter context and fixed normalized world direction required` diagnostic is separate and was not explained by this camera calculation. The runtime frame-cost investigation also remains separate. No production file, accepted status, canonical record, engine process or Git state was changed by this offline review.

Integration sent canonical request `9558923d-a0ee-44cf-9a1c-64c6cd486732` to the actual Act 1 chat for an owned correction or acknowledged narrow handoff. Act 1 L3 remains accepted and L5 may continue independently. The full campaign remains 16/24 accepted.
