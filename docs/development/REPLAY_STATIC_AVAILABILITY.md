# Existing static equipment in completed-level replay

Shared43 exposes the thirteen existing implemented static items to the four-slot replay chooser: `WEAPON-01/02/03/04`, `CLOTH-J0/J1/J2`, `CLOTH-P0/P1/P2` and `CLOTH-S0/S1/S2`. This is availability for an explicit replay choice, not a reward, automatic equip operation or permanent stat growth. Story starts with the canonical starter kit and retains its actual carried gear. Only starting an isolated replay installs its selected alternate kit. Weapon, jacket, pants and shoes remain the only slots; headwear is presentation.

The source is `Equipment.IMPLEMENTED_IDS`. The canonical equipment grid remains revision0, with thirteen implemented static entries, null perk IDs and no creation claims. Ability usage remains revision0 with no placements. Proposed catalogue clothing, perks and powerups are not made available by this change. Existing stat definitions and numeric identity stay unchanged.

## Persistence and compatibility

Fresh Attempts sessions list the thirteen static items. `load_saved` first validates and stages a saved session under its **original** ownership list: protected story/progress, remembered kit, then side attempt. An originally unavailable side or remembered kit is still discarded with the existing warning before availability expands. Unknown IDs, unimplemented items, an unowned protected story kit and wrong-slot payloads still reject; migration does not legalize malformed saves.

Only after that validation does load append missing implemented IDs to a copied availability array. A changed legacy session is published through the existing atomic SaveStore transaction before live model memory commits. A write failure retains the prior live model and exact primary bytes with a visible error; retry can succeed after the publication blocker is removed. An already available session loads without a redundant disk generation. The whole story, side snapshot/checkpoint, equipped kit, remembered replay kit, resources, clocks, progression and once-only reward stamps retain their original values.

`restore_session` retains the submitted availability and its original strict recovery semantics. It remains an in-memory-only API: no expansion or disk write. Attempt schema1/eight keys, SaveStore format2/exact tagged-number transport and existing backup/rename behavior are unchanged. Process-level atomic publication is not a power-loss guarantee; migration cannot restore precision absent in old decimal saves.

## Focused verification

All three canonical queued native jobs closed with clean diagnostics: new replay availability **92/0**, directly affected campaign persistence **45/0**, and menu **67/0**. [Original inputs, commands, raw logs and results](evidence/shared43-replay-static-availability/index.json), SHA256 `6a11685689c40cc0b5e24648a4bda0d2ec55a931bc7dfc4346a9211a240440b9`, preserve407 artifacts:280 original bounded native-test inputs plus94 separately scoped resource-import inputs. The closed import generated only the new test UID, recorded separately. The original unparsed draft remains separate from the executed jobs; no historical UID backfill.

The new leaf uses actual shared Shell/Player/AshEnemy/floor/format2 transport and four real selector callbacks. TEST ONLY registry metadata, resource/supply/enemy seeds and fixture completion open replay. It selects `WEAPON-04/CLOTH-J2/CLOTH-P1/CLOTH-S1`, resolves the actual native Player stats, persists an interrupted side and remembered kit, and verifies the exact protected story across migration, two relaunches and Journey return. Only camera-follow settling may differ at the earlier live side-admission boundary; every saved camera field is included in subsequent whole-unit comparisons.

A genuine backup-directory publication failure tests atomic failure and retry with a preexisting live model. Negative legacy saves reject arbitrary/proposed/perk IDs and unowned/wrong-slot protected gear. An unavailable old side and remembered kit are recovered before expansion, never retroactively legalized. The original memory-only restore control creates no file.

These are automated native UI-callback/model/storage checks. No real GUI gesture injection, new portrait capture, authored-level clear, all mixed-kit routes, balance, full campaign playthrough, human/mobile testing or performance claim follows. The menu layout is unchanged. No accepted-level blanket rerun was required; campaign remains9/24.
