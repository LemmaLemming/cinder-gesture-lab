# Held-legacy01: bounded refusal interpretation

Read-only source/report interpretation, 16 October 2026. No engine, rerun, runtime/test mutation or dependent new comparison. Integration RESPONSE67c87b80 stopping rule applies; the requested old safe/useful baseline was not established.

## Actual result

`.cinder/l5-difficulty/held-legacy01/native.json` SHA256 `8a35fc6cec9b2c1cc4832907f734a28e2267abd578bbba4599779543c62ef2e6` reports86 checks/1 failure, `complete=false`, `success=false`. Runner receipt is closed with exit1, no selected input changes, and the footer agrees. Its sole raw error line is the fixture's reported native-cancellation assertion; this was a normal closed failed/incomplete case, not a parser crash.

The actual full left dash ran12.716666666666878→12.90000000000022, distance2.700000047683716, with blocked/collision_shortened/movement_damage allfalse. At13.133333333333566 the trial stopped at actual held position `(-2.700000047683716,-0.004843761678785086,-7.599999904632568)`, grounded/stable, HP100, shells2. Thus13.1333 is the cancellation/stop time, not the dash-completion time.

Only `moon-eye`/`threat-4` was admitted. It was observed in warning then lock; its original active interval13.866666666666827→14.066666666666826 had not begun. The live event witness contains one cancellation, `required_parent_presentation_unavailable`, and no source-hit event. No Nose admission, completed active hold, return dash or ordinary primary was observed. The common fixture label mentions contact/cancellation, but the actual recorded event here is cancellation only; there is no damage or invulnerability-rejected contact evidence.

## Unchanged code paths

References below are to the actual frozen source-pre bank of this run; current and source-post bytes match those files.

- `scripts/combat/native_sampled_circle.gd:230–239` calls `_damage_boundary_ready()` around its ordinary physics update. At290–307, a missing/invalid required parent Callable OR a non-boolean/false parent result cancels with `required_parent_presentation_unavailable` (emission sites294/303). The reason identifies this required-parent boundary but does not select a specific parent subpredicate.
- The host binds this consumer to `_blink_presentation` in `scripts/acts/act1/living_moon.gd:117`. `_blink_presentation`350–351 checks source identity then `_source_guard`367–377. That guard checks actual running/native state, live reservation and retained framing-proof identity/deadlines, actual eye/art pose, and finally `_framing_error(_camera_framing_points(false))`. The last call excludes a prospective forecast but retains the actual live source/cue/response union.
- The retained `last_encounter_error` is `Required union cannot fit the fixed-width HUD-safe rectangle`. `_framing_ready`619–621 writes that diagnostic from `_framing_error`; `_prepare_forecast`269–280 and `_finish_admission`284–290 use it. `_framing_error`613–616 calls the shared plan first and current containment only after plan acceptance.
- The exact string originates in `scripts/presentation/camera_framing.gd:19–31`: after validating and projecting the required corners, the fixed-width planner finds an empty horizontal OR vertical permitted-shift interval. It is a union-fit refusal, not the224-corner-limit error. Shared `scripts/game.gd:501–512` appends actual mandatory Player bounds and uses the unchanged0.055 planning margin;514–529 separately checks current containment.

The host `_boss_tick`, `_admit_nose`, `_prepare_forecast`, `_finish_admission`, `_blink_presentation`, `_source_guard`, `_camera_framing_points`, `_framing_error` and `_framing_ready` bodies are byte-identical to the genuine old producer's source-pre bank. NativeCircle, shared camera planner and shared Game files are wholly byte-identical between that old writer and this dual-reader run. The amendment did not alter these gates.

## What is and is not established

The actual run proves the proposed left-held baseline was refused at an existing required-presentation boundary after a successful full dash, while the host retained a union-fit planning refusal. It does not establish the exact cancelling subpredicate or the complete failing point-set/projection. The generic cancellation reason has multiple source branches; `last_encounter_error` is a retained diagnostic, not a per-cancellation reason latch.

One concrete spatial fact is retained: this Blink's native proof selected a right landing `(+2.700000047683716,Y,-7.599999904632568)`, whereas the trial deliberately executed the left landing. `_camera_framing_points`593–606 includes actual Hero bounds and retained proof landing/attack bounds. That is a supported explanation for why this chosen action is a different presentation workload from the original certified route. It is not a measured proof that those two endpoints alone caused the refusal, or that a specific alternative would succeed.

The inherited `first_failure.capsule_framing_plan` and `capsule_current_view_error` are generated from `_capsule_preview_points` after failure. They are a different diagnostic point set and cannot substitute for the exact cancelled final encounter union. Their accepted plan does not contradict the retained full-union refusal.

No conclusion follows about new Sneeze-first held conflict, an altered useful response, two-dash equivalence or overall accepted L5 playability. Those comparisons remain unexecuted. Preserve the failed original; request Integration's exact refinement or specific retention decision. No guard relaxation, runtime fix, new comparison, portrait, metadata matrix or rerun is implied.

## Physical source hashes

- host: `89dc49fe6e37c05679d1f4592c9873f01f1c4ea92720d2ec0209624985be7e7f`
- NativeCircle: `27e212c6ae3fce94e980a59617f22732bc69300958404712be55aa82be35aa6f`
- camera planner: `daf839d1e35497c88a59d4c1c2af7bb02194418e2c667aceb677242bd642c39b`
- shared Game: `0b16d911409350a392f741a07bc163ad73c588d885ee7e1e64b951f97aa30d26`

These four selected pre/post/current byte checks and named unchanged-function comparisons are a bounded source check, not a new global dependency census.
