# Draft: implemented static equipment availability in replay

SOURCE ONLY, UNPARSED, UNEXECUTED. This ignored folder is not a campaign acceptance or native test result. No tracked runtime, catalogue, ability ledger, dev mapping, act content or canonical mailbox is changed.

## Policy and existing IDs

All 13 currently implemented static clothing/weapon items are initially available to the completed-level replay chooser: `CLOTH-J0/J1/J2`, `CLOTH-P0/P1/P2`, `CLOTH-S0/S1/S2`, `WEAPON-01/02/03/04`. This is explicit replay availability, not a reward, equipment introduction, permanent stat growth, farming loop or automatic equip operation. The shared Shell still begins story with `Equipment.STARTER`, carries the actual declared story kit, and equips an alternate only after the user chooses and starts an isolated replay. No story equipment selector is added. Headwear remains presentation; the four slots remain weapon/jacket/pants/shoes.

The actual read-only `python3 scripts/dev/dev.py equipment status` response is retained in [equipment-status.json](equipment-status.json): canonical revision 0, 36 catalogue entries, no creation claims, and exactly these 13 `implemented_prototype_unplaytested` static items with null perk IDs. The source is the existing `Equipment.IMPLEMENTED_IDS`; this patch does not independently infer implementation from catalogue status or admit proposed clothing/perks/powerups. References inspected: [equipment grid](../../docs/EQUIPMENT_DESIGN_GRID.md), [equipment specification](../../docs/PLAYER_EQUIPMENT_GUIDELINES.md), [canonical numbers](../../data/design/player_equipment.json), [actual Equipment implementation](../../scripts/equipment.gd).

## Narrow runtime seam

[attempts.candidate.gd](attempts.candidate.gd) is a full copy of [attempts.original.gd](attempts.original.gd), with [candidate.patch](candidate.patch) limited to fresh initial availability, extracting the existing recovery staging body, and `load_saved` migration. Actual Menu/Equipment/Player/Shell are unchanged: their current replay selector already filters implemented slot definitions against attempt availability and resolves the chosen native Player stats.

`restore_session` remains an in-memory-only API. It validates/recoverably sanitizes the submitted ownership policy exactly as before, preserves that submitted availability, and never writes or expands it. The extracted `_stage_session` performs the original protected-core → remembered-kit → side-attempt checks in their original order and with original errors/warnings. It performs no model-state commit.

`load_saved` reads through the existing SaveStore protected-core validator, stages under ORIGINAL saved ownership, then copies and appends missing `IMPLEMENTED_IDS` to `unlocked_equipment`. Invalid protected story/progress/unknown/unimplemented IDs still reject. An old side/remembered kit not owned in the original saved list is still discarded with the existing warning BEFORE expansion; the policy cannot retroactively legalize it. Only availability changes for a valid session: story, side snapshot/checkpoint, selected gear, remembered kit, resources, clocks, progress and once-only reward stamps retain their exact existing payload values. Submitted containers are not mutated through staging aliases.

If availability expands, `load_saved` publishes the complete staged payload through the existing `SaveStore.write_payload` before assigning live model memory. Failure leaves prior model state and prior primary save intact, with `last_error` visible. A subsequent retry can migrate after the publication blocker is removed. A fully available session loads without a redundant write. Existing recoverable-side/kit behavior for an already available session remains memory-only as before; this patch does not introduce a general save-repair rewrite.

Attempt schema remains 1 with eight keys; SaveStore format remains 2 with the exact tagged-number transport and existing valid-generation backup/rename transaction. Older format-2 ownership subsets need no new migration envelope/version/key. The existing Store version-1 compatibility reader is unchanged; this policy cannot recover precision already absent in historical decimal saves. Process-level atomic publication is not a power-loss guarantee.

## Proposed focused native test

[test-leaf.gd](test-leaf.gd) is intended for later selection as `tests/replay_static_availability_smoke.gd` AFTER the runtime candidate is promoted and its sources frozen. It inherits only helper infrastructure from the existing Shell smoke and overrides `_run`/paths/finish; it does not execute the default or focus-notification suites. All writes use isolated `user://test-replay-static-availability/` paths.

The planned workload is:

- A real shared Player/AshEnemy/Box-floor fixture behind TEST ONLY cloned accepted metadata. Explicit resource/supply/enemy seeds and fixture completion open a completed-node replay; this is not an authored clear/reward or campaign acceptance.
- Four actual OptionButton callbacks expose the canonical 13 items and select `WEAPON-04/CLOTH-J2/CLOTH-P1/CLOTH-S1` with no `grant_equipment` call. Story/kit choices and preset callbacks remain exact. Starting replay installs the real differently equipped Player/resolver and its real fresh resource policy.
- The Shell intentionally records its latest story before side admission. The pre-boundary assertion preserves exact actor/level/equipment/aim/input/profile/checkpoint values, while allowing camera follow to settle across those deferred frames. The resulting stored WHOLE protected story is then compared exactly throughout side persistence, migration, relaunch and return; camera state is not omitted from those comparisons.
- A real exact format-2 interrupted payload, retaining its genuinely selected side and remembered kit but an older valid eight-item availability subset, migrates once. Two real Shell relaunches preserve the full native side and protected story, and the second load causes no generation increase. A separate public `restore_session` control preserves that same submitted policy and creates no file.
- A genuine filesystem backup-path directory blocks SaveStore publication of a valid starter-only legacy payload. Failure retains a preexisting coherent in-memory story/remembered kit, exact primary bytes/generation, and no temporary file. Removing only that blocker permits an exact retry.
- Real Store load tests reject arbitrary IDs, proposed perk clothing, a perk ID, unowned protected gear and a wrong slot. Recoverable unavailable old side/remembered gear is discarded before migration rather than legalized by it. Exact comparisons require BOTH encodings nonempty; no empty-encoding equality credit.

Controls exercise UI signal callbacks, not injected native GUI gestures, a portrait screenshot, act-specific mechanics, every mixed-kit route or balance/performance. No native count/pass, UID, engine exit, timing, visual acceptance or new catalogue/ability allocation is claimed. Root will choose and run the one new focused target and directly affected model/menu checks only after its current engine/source freeze ends. Existing immutable results are not re-attributed to this draft.

## Freeze

[manifest.json](manifest.json) records the original base, exact candidate/test/patch bytes and explicit inspected source subset. It is a bounded source-only receipt, not the full transitive import/resource graph or native launch provenance. Live base bytes are independently checked unchanged at draft freeze.
