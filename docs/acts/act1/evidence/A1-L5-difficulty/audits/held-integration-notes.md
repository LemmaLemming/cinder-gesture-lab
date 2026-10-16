# Private held-response integration

`a1_l5_difficulty_held_draft.gd` SHA256 `2b1a941b3af6a4734ba96e10fa1606cb17bdaf824f738bbc24362bdbe380c0bf` is an unparsed/unexecuted private composition of frozen transport `fec85a9f85d94bfe164c389853b44650f61d89ada2ffe46373bfb51864aa10d8` and new held fragment v2 `34c6a346d52e22b5f9f3b8fab760a0c62c9d1be8c2a857f6bc6e97909a923011`. Frozen inputs remain untouched. No engine, Git or worktree writes occurred.

Changes beyond appending v2: exact parser cases/flags below; early held dispatch before producer probes, seeding or automatic admission Pause; honest dynamic scope; synchronous `_held_finalize_observations` in normal `_finish` so early assertion/watchdog exits preserve actual trace/actions/events. The original producer, selectors and transport/metadata function bodies remain intact. No portrait folded yet: o2's separate7e6a portrait fragment remains independent.

Shared62's concrete v1 review correction is incorporated: replay eligibility must include the intervening stationary hold AND full return timed path AND finishing before unchanged new Blink active. Otherwise the earlier-return candidate is considered. The original v1 fragment4b3ff is retained. V2's only additional helper flushes observations at closure without changing native state.

## Exact selectors

Old useful response, expected first invocation after owner review/promotion:

```
--case=held-legacy
--source-report=res://.cinder/l5-difficulty/legacy-producer01/native.json
--source-sha256=b0f68e2359f7703e0115f58dbf22bdfa397db6769e305a4ad9711e29993ac380
--branch=cp3
--future-profile=standard
```

New comparison only after that actual baseline closes successfully:

```
--case=held-new
--source-report=res://.cinder/l5-difficulty/fresh-producer01/native.json
--source-sha256=4375d37e0bfa65571b3a43ff080ae8b7aa7d35ad26baebb50668f87442970b14
--branch=cp3
--future-profile=standard
--baseline-report=<actual CLOSED successful held-legacy native report resource path>
--baseline-sha256=<actual complete held-legacy report SHA256>
```

These are fixture arguments, not an engine command. Root queues through `python3 scripts/dev/dev.py engine` using the existing runner. Every selector is required once, unknown/duplicate selectors fail, baseline arguments are rejected for other cases. `held-legacy` consumes genuine old16 through the promoted dual reader; it does not rerun an old producer on new code. Current runtime/recipe source pins remain gated by the frozen fresh source hashes.

## Evaluation

Successful native execution is distinct from design approval. The new receipt retains `return_policy`, original/new native clocks, paired actual paths, strict held-H counterfactual and explicit interpretation. A safe/useful return at the same actual CP3-relative old time is recorded as an equivalent two-dash option and receives no automatic difficulty credit. The0.0167 CP3 clock difference is preserved. If follower admission, support/current optics, full dash, no-contact hold or ordinary recovery fails naturally, preserve that failed/inconclusive case and ask Integration for exact refinement/retention; do not relax the guards or add a forced attack.

`held-response-draft-notes.md` contains the detailed behavioral design and source seams for v1; the v2 change above supersedes its narrower replay eligibility. This is one neutral-kit focused exchange, not a route/boss defeat/OS gesture or all-loadout test.
