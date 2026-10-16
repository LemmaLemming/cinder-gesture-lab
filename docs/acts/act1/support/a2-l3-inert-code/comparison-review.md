# Bounded comparison source review

Reviewed only inert source text; no parser, engine, fixture promotion, runtime change or native result. Original reviewed comparison is `comparison-v1.gd.txt`, SHA256 `166475731025ab0faf4b48ecf408d73a62391636713bb6d0575756839210f93c`. Helpers reviewed: `focus_house-v1.gd.txt`, `focus_game-v1.gd.txt`, `focus_policy-v1.gd.txt`. The current `comparison.gd.txt` was being revised during review and is not covered by this v1 conclusion.

## Concrete corrections

1. **Watchdog races normal coroutine cleanup** — comparison v1 lines 76–79, 229–236, 491–499. The timeout starts async `_finish()` without awaiting it while `_run` can be suspended on `after_probe.sampled`. Teardown then disables and frees that awaited probe. Latch the timeout failure and let the normal main wait unwind on its next actual sample; leave a wholly stalled engine to Root's external wall watchdog. Do not launch a second cleanup coroutine.
2. **Rejected existing output can still be overwritten** — lines 72–74, 469–478, 504–515. `output_root` is set before uniqueness/creation succeeds, but `_finish` writes cleanup/report files whenever that string is nonempty. Keep an ownership flag set only after successful creation and gate every write on it. A refused existing path must remain untouched.
3. **Source/control pin gate is incomplete** — lines 142–168. Only the host has a required external hash; a control JSON with `files:{}` passes the shape check and skips all dependency/helper verification. Bind literal actual fixture/control hashes externally, require the closed nonempty selected key set including the three promoted helpers, and retain/check all those hashes pre/post. Keep future Host hash separately Root-selected. Root independently identified this same issue.
4. **Successful open is not a verified evidence write** — lines 469–478 and 512–516. `store_string`/close is followed by a file hash without checking flush/write error or equality to the intended bytes; native-report write can likewise leave `complete=true` after a write failure. Flush, inspect error and compare literal readback/hash before crediting the artifact or successful footer. Root independently identified this same issue.
5. **Setup wording is stale** — focus_game v1 line 13 and comparison line 511 describe an XZ-only override. The actual focused constructor derives and overrides Y from original floor top minus canonical capsule feet offset. Say so explicitly; this is one supported constructor position, not a live relocation.

## Bounded source checks with no further definite blocker

- Focus policy is supplied before inherited entry constructs native recipients. It has empty predecessor history and no snapshot/cursor/HP setter. Expected fresh cursor is asserted after actual entry; native admission and guards remain inherited.
- First admission errors are latched at lines 324–326 regardless of `setup_ready`; bootstrap is not an ignored-denial window.
- Reach uses actual retained proof `escape_dash` and optional `positioning_dash`; it does not invent an inverse return. Player's public dash/action record fields and Scheduler's floor/capsule/opening LOS methods match the calls inspected.
- `_strict_hits` performs Lane's temporal eligibility test before native geometry, then applies the stated conservative radius. Complete current and held native exchanges are joined, and measured trajectory is separately checked. Native operations precede typed diagnostic encoding.
- Full ordinary primary cooldown/commitment, native hit events (including zero HP damage), smoke contact/attempt/consumption, HP/ammo, actual cues and current optical containment are checked. No claim of an installed House Lane presentation guard is made; the observer ordering is expressly 109/3000, not the exact guard callback.
- Typed diagnostics distinguish native vectors/rectangles/objects. Object entries are explicitly observations, not a restorable snapshot or historical authority.

These findings are source-only. No successful original response, Place hold, gameplay novelty, portrait readability, runtime cleanup or parseability is established by this review. O3 is preparing a separate corrected version; it requires a bounded delta review before being described as reviewed.
