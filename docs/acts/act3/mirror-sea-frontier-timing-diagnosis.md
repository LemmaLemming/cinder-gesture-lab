# First connected Mirror Sea frontier diagnosis

Ignored / unexecuted proposal; 9 October 2026. Original actual fixture SHA256 `8f2d4f1531157ec98acffa9170ffde22da92d04add60b0755a0d5131974cbde0` and `.cinder/mirror-sea-first-two-entry-combat-shared35.log` remain unchanged. Root owns archive, publication and engine.

The first meaningful native fault is `_entry_error:202`: the conditional array literal is an untyped `Array`; assigning it to `Array[String]` raises a Script Error. The original engine then printed the entry PASS after aborting this validator, so that PASS cannot certify its complete source-entitlement assertions. The ignored proposal uses the normal typed-array `assign` operation with the identical one/two source IDs and leaves every entitlement assertion intact.

The later compound dash failure did not print its completed action, so its exact failing timing predicate is not available in the saved original. The printed Hero landing `(2.560897, -0.004844, 38.45545)` versus native proof `(2.560897, -0.004844, 38.45546)` is far below the unchanged `.005` WU landing bound. At failure the Scheduler clock is `2.38333333333333`; the proof escape is `2.18333333333333` to `2.36333333333333`. Completion at that clock would exceed the current absolute one-tick end bound of approximately `2.380001` by `.0033323`.

Actual shared Player `scripts/player.gd:271` scales the final movement fraction and publishes its completed dash only after adding the whole physics delta to its native action clock (`:304`, `:313`, `:534`). Shared Scheduler `_prove`, `scripts/combat/threat_scheduler.gd:1397`, supplies continuous `dash_start` and `dash_end = dash_start + stats.dash_duration`. The first available start and the final fractional movement completion are two separate fixed-step boundaries. Existing accepted owned consumers explicitly separate these: `stalker_primary_clear_smoke.gd:635` documents one tick for start and one for completion; its `:576` and `twin_suns_level_smoke.gd:815` require actual request/start identity, elapsed duration within one tick, and completion within two ticks of the continuous path end. Current frontier `:450` uses only one tick for the latter and lacks the elapsed/request-identity checks.

This is a concrete fixture-contract discrepancy and a plausible explanation of the saved native time. It is not evidence of a faulty source geometry, collision path or unsafe actual proof. Root authorized the same decomposed fixed-step contract as the accepted direct consumers: preserve `.005` WU landing and the first-action `<=1tick` bound; require exact native action start equal to the clock captured immediately before the real swipe, require elapsed duration within one tick of the actual resolved stat, and permit at most the separate start/completion boundary ticks after the nominal proof end. Original primary openings, source phases, actual geometry/deadlines, input and waits are unchanged. Added distance, exact sampled action endpoint/clocks, monotone complete path, straight-path `.005` bound and actual floor ray checks strengthen physical verification.

Each actual proof dash now prints the three **original** failure predicates even on a corrected pass, plus exact binary64/17-decimal request/record/proof clocks, kit duration, native landing error and the last three completed path samples. This lets the smallest corrected actual run demonstrate which original predicate failed instead of promoting the current plausible timing diagnosis to measured proof. The observations use only public clocks/action records; no action, deadline or actor is changed.

Smallest future Root-owned command after preserving originals:

```sh
python3 scripts/dev/dev.py engine --headless --path . --script res://.cinder/mirror_sea_frontier-proposed.gd
```

No Godot/parser/runtime result is claimed. Outside `_entry_error`'s typed array construction, `_dash`'s stronger decomposed timing/path verification and its bounded public diagnostic/floor helpers, the draft is byte-identical to the original. Original input, waits, world, HP/ammo/kit checks, damage assertions, actual deadlines, `.005` WU and `TIME_EPSILON` constants remain unchanged. Root may instead apply the same small diff to its preserved actual fixture before the identical target.

Root publication: the exact ignored proposal is applied to the owned actual frontier, changing only its ignored-status comment. Native rerun pending. Actual SHA 8424bedbb8001c3e02b55e7cf18ad525527936933dc1556339bdc3b8ce664fed. Original15730 and its complete frozen bytes remain archived separately.
