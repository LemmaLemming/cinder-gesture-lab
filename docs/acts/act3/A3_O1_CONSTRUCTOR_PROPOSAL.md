# A3-O1: proposed closed construction seam

**Source proposal only — 20 October 2026.** REQUEST `0fcf59b8-4047-481d-898f-979f432ef070`, ACK `f77bfcfc-b6a6-40f4-83d8-c0bd721cb933`; reviewed owner source `087643f79835ea732d10422488171fb383806a17`, actually adopted Shared74. Root selects the wire and implementation next. The [single existing hypothesis](A3_O1_DIFFICULTY_PROPOSAL.md) remains unselected: only fresh Challenge would move the whole central home `(0,.1,-1)` → `(-3,.1,1)`. No new placement or player decision is proposed here.

## One proposed wire

Keep the outer `campaign-level-1`/schema1 and `local_snapshot_version=2` unchanged. Distinguish the inner local formats explicitly:

| Branch | Inner API / schema | Exact local keys |
| --- | --- | --- |
| Literal old | `act3-pillars-before-time-2` / existing schema1 predicate | `api_revision,schema_version,scenery,scheduler,sources,route` — six |
| Proposed new | `act3-pillars-before-time-3` / int2 | Same six plus `construction` — seven |

New `construction` has exactly four String keys: `api_revision:String="act3-pillars-construction-1"`, `schema_version:int=1`, `profile:Dictionary`, `recipe_id:String`. Its profile is the complete canonical eight-key value returned by [Difficulty.profile](../../../scripts/combat/difficulty.gd): `id:String`, `name:String`, `raw_damage_multiplier:float`, `windup_multiplier:float`, `recovery_multiplier:float`, `reserved_threat_budget:float`, `commit_stagger_s:float`, `arrangement:String`. The budget is a **float in the native catalogue decoder**, despite its integral value. Require finite, exact typed equality with the canonical profile and the saved Scheduler profile; ID-only or approximate numeric equality is insufficient for this new authority. Retain defensive copies; do not cast or resolve multipliers a second time.

| Construction branch / saved profile | Required finite recipe | Homes |
| --- | --- | --- |
| Any literal old profile, including Challenge | Internally `A3-O1/canonical-homes@v1`; never add it to an old packet | All three original homes |
| New Assisted or Standard | `A3-O1/canonical-homes@v1` | Original homes |
| New Challenge | `A3-O1/challenge-central-southwest@v2` | Only central becomes `(-3,.1,1)` |

Resolve these constants from the unchanged native base map. No serialized coordinates, row overrides, source permutation, or different profile/recipe pairing. All genuinely fresh attempts would emit the new branch; every restored old attempt continues emitting its literal six-key branch through Save, Continue, its own earlier Retry and completion. Keep the old profile/type acceptance predicates rather than silently tightening legacy numeric transport to the new typed policy; validate the full old saved profile under the existing canonical comparison before configuration. Quiet restore/recapture preserves that original validated legacy Scheduler profile; do not normalize it or add an exact typed legacy construction-to-live guard. Neither branch follows a later menu preference.

## Exact entry and restore seam

[Shell](../../../scripts/campaign/shell.gd) `618–625` instantiates/adds the level, so `_ready()` precedes Player creation and both entry hooks. Fresh entry is `652–653`; saved raw recipients remain paused for floor registration, then `_enter_registered_candidate` `1059–1073` invokes restore entry. There is no shared pre-`_ready` selection callback. [CinderLevel](../../../scripts/campaign/level.gd) `129–156` validates the envelope and saved Player before calling the local restore constructor. Preserve that ordering and both O1 restore opt-ins.

Use the existing **unconfigured-body** seam, as the accepted [Twin Suns implementation](../../../scripts/acts/act3/twin_suns_level.gd) `220–255` already does. [O1](../../../scripts/acts/act3/pillars_before_time.gd) `_ready` `55–114` can retain its floor, scenery, Scheduler, three ready but unconfigured dormant bodies, contact props and canonical scene-home templates. Those templates are checked against the immutable base, not yet treated as a selected attempt. No configured source, lease or history may be relocated.

Proposed synchronous order:

1. Pure preflight closes the old/new API, keys, types, full profile and finite recipe. On fresh entry select once from the public preference; on restore read only that packet. Produce a defensive selected home map without native mutation. The unchanged envelope/progress checks remain pure; they must not lazily choose or configure anything.
2. Before `_configure_sources` or the first native source configuration, freeze writer mode/profile/recipe/map; bind all three scene homes and unconfigured bodies to that map exactly once. Mark the construction consumed before a partial failure could retry configuration. Retain the actual registered floor untouched. Only central differs for the proposed new Challenge.
3. Begin the existing encounter once; configure all three real Stalkers once from unchanged raw roles/floors. Retain priority, grounded wake radius, dormant processing and actual collision resources. Fresh play becomes active only after successful configuration. Failed construction is disposed normally, never repaired by a second begin/configure.
4. Restore constructs those recipients, then performs the complete existing paired Player/source/Scheduler/route validation. Quiet commit retains physical sources → Scheduler → Sun/route/presentation, followed by the existing final optical gate. No saved HP, clock, awakening, collection, progress or future resources are applied during construction.

`contract_error()` currently runs before selection: keep an explicit inert-template check there, then strict selected-home checks after binding. Replace every **attempt-home** use together: body origins, `_home_marker_error`, `_source_is_near`, awakening receipt and dormant-pose validation (`166–173,292–305,723–747`). Base JSON validation `117–141` still requires original authoring. Awakened actors, including their later tombstones, retain actual moved poses; unawakened living/dead actors retain the existing selected-home/dormant predicate. Full-HP dormant velocity, genuine damage/death exceptions, paired samples, any-order contacts, CP1/CP2 and no-CP3 rules remain unchanged. The native `Vector3` map retains existing conversion semantics, rather than comparing JSON decimal text with float32 components.

## Completion and empty Scheduler

O1 keeps its genuine encounter/full profile and all three living/dead recipients through third collection and later exit (`250–271,645–680`). Only `_on_exit_level` ends it (`234–247`). Shared `end_encounter` clears profile/ID; the generic idle Scheduler may accept empty ID/profile, but O1's existing exact encounter/revision and source checks reject that state as a resumable local packet. Preserve this rejection. Empty reservations are normal; they do not mean an ended encounter or permit choosing a new profile. No disposed-stage fallback or reconstruction of a historical profile is needed here.

## Minimal checks after selection

These are proposed checks, **not executed fixtures or results**:

- One focused format/construction check: all three fresh profiles, literal old-six versus new-seven dispatch, full typed profile, wrong/unknown recipe, hybrid/missing/extra fields, partial home drift, repeated configuration and defensive-copy mutation. Refusals must preserve input and installed donor Player/local/native IDs, leases, input/optics, session/disk and events; dispose only the failed candidate.
- Reuse the [known Standard archive](evidence/A3-O1-difficulty-proposal/OLD_WRITER_CUSTODY.md) for its real entrance/CP1/held scope and old writer recapture; pure old-Challenge dispatch can be tested as a disclosed synthetic branch, without calling it authentic old-Challenge save coverage. No mandatory new packet producer. Existing completion/return evidence keeps its original attribution; no separately archived Challenge/CP2/completed packet is claimed.
- Only Root-selected execution may try the original proposal's **one** declared same-start autonomous native discriminator, complete ordinary response/recovery and zero consumed contacts/damage as well as unchanged HP. Stop unsafe/equivalent/inconclusive; no layout search or ordinary-lease replay-only Hero-ID assumption.
- Only a meaningful safe result warrants new whole Optional/session Save, fresh disk Side Resume and its own earlier Retry under opposite future preference, protected Story/cleanup and one changed-pressure portrait. These do not require a full route, kills, earned exit, all kits or human balance approval.

Closed format checks cannot authenticate every consistently forged historical map after sources have moved; genuine saved-pair custody retains its stated limits. No playstyle/catalogue/ability decision changed, so earlier query receipts are reused at their recorded scope. This proposal changes no runtime, data notes, fixture, parser, engine/import/producer, allocation, shared or other-act source. Original eight Act3/all24 acceptances and17 difficulty policies remain unchanged. **Stop at this document handoff for Root review.**
