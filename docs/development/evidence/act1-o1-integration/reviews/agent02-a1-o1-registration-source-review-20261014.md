# A1-O1 canonical registration source review — 14 October 2026

REQUEST `32d0e327-222d-4162-a1fc-31b078ddad32`; Act2 support only. Integration remains sole promoter and registrar. One bounded source pass found no demonstrated compile/interface/cleanup incompatibility. Two assurance/reporting gaps should be addressed in the Root-owned draft before promotion. Neither is a reproduced runtime defect or a human decision gate. Act1 and Act3 optional development remains independent.

## Exact inspected inputs

| Input | SHA256 |
| --- | --- |
| Canonical `.cinder/level-testing/optional-registration-prep/act1_o1_registration_smoke.gd.txt` | `70491f2ade7a4db4625a98feb9be63708814854891e67b43308d3b67c3bb2a13` |
| Canonical preparation `HANDOFF_AND_VALIDATION.md` | `4c35eb9e1d838877bcadb7fbbf2636240e1607f1e8c9120c8b89f7317db49cee` |
| Act1 owned `tests/acts/act1/a1_o1_campaign.gd` | `37b7df85460f1d11c8d8da0dfd5fdb1511c8b2307542f6a33ed548ba27fccc50` |
| Shared59 `scripts/campaign/shell.gd` | `f8df3b798544b79d66985f5e468f13ade5485bccc6050b54c9d9d242b3211a0f` |
| Shared `scripts/campaign/exact_json.gd` | `c383cbcc2391aadb4ef4c44e772ec4130038c84a7e074ea8889b56f5f08833fc` |
| Act1 `.cinder/a1-o1-campaign-79846-772192.json` | `407b5120f0dd4c395945df284c26f199d0f1891b66c294d8bce44af6682b6f96` |

Canonical root is `/Users/howardchen/Documents/ChatGPT/video game idea`; Act1 checkout is `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea`. Owner fixture and draft hashes were unchanged on the concluding read. Owner source remains mutable until the exact handoff. Content-commit and completed-file placeholders are deliberate pending handoff inputs, not errors.

## Concrete gaps and minimal corrections

1. **Initial protected Story capture lacks an explicit closure/equality assertion (draft lines40–43).** Add `_closed(protected_unit)`, `_same(protected_unit, protected_story.snapshot)` and `_durable()` before Optional entry, following the existing owner's initial Story assertion. Current return checks independently compare captures with `protected_unit` and attempt metadata with `protected_story`; `_same` can accept two exact empty dictionaries. They therefore do not establish that the initially captured native unit was nonempty or equal to the saved Story snapshot. No empty capture was observed here. This is a missing assertion, not a claim that current Shell restoration fails.
2. **The overridden finish drops retained diagnostics (lines105–128).** Owner `_expect` still collects `first_failure`, and observers still collect records, but Root `_initialize` never sets `report_path` and Root `_finish` never writes them. This avoids falsely emitting the owner's long-route scope, as intended, but leaves only errors/footer as retained output. Give the registration fixture its own unique report path and write its own short-flow checks/failures/first failure, completed flag, source/receipt pins and scope. Preserve its explicit failure exit when registration is incomplete. Do not call the inherited long-scope `_finish`. This is an evidence/reporting improvement, not a compile error: the inherited helpers inspected here do not themselves read `report_path`.

No Root draft, Act1 source or shared code was edited; these corrections are recommendations for Integration.

## Interface, state and cleanup findings

- Canonical Registry/configure_runtime({}) remains intact. Parent A1-L2, locked empty/L1 prefixes, actual L1+L2 TEST prefix, once-only existing stamp and L2→L3 main successor are checked. The label “A1-L2 alone” means parent requirement; no earlier campaign route is earned.
- Overridden `_new_shell() -> bool`, `_seed_story(registry)`, `_await_operation(predicate,label,seconds)`, `_retry_checkpoint(expected)` and the inherited constants/variables match current source signatures. Parser execution remains pending promotion. Entrance Retry is compatible with the helper's dormant-final assertion and distinct IDs/zero installed-recipient callbacks; it must keep its entrance-only scope even though inherited labels say pre-final.
- `world` is the installed candidate stage. Its parent is the SubViewport and grandparent the replaceable SubViewportContainer (Shell constructor lines591–641, install785–803). The draft's grandparent WeakRefs correctly cover the retired world container; they do not include the persistent Shell. Whole-Shell `_refs(game)` is appropriate for independent startup and final teardown. Shell `_exit_tree`947–959 invokes public level cleanup and disposes candidates; the draft's direct normal `game.free()` does not bypass that cleanup. No retirement defect was found by source inspection.
- Entry and early Leave check complete metadata/capture/durable state, no unearned completion/stamp, unchanged unlocks and protected Story. Replay startup validates the entire completed session; pristine replay and Leave retain the existing stamp/main/equipment/Story boundary. These checks cover retention, not another completed replay or duplicate-completion idempotence. Public menu signals provide API evidence, not GUI clicks.
- The second startup intentionally uses the owner's completed-return Story, rather than requiring equality with the separately constructed initial Story. Equality with that owner's packet is checked on Continue and Replay Leave. Do not add an unrelated cross-producer exactness requirement.

## Genuine completed-session join

The declared49/0 boundary has a usable existing receipt. In the exact report above, `receipts[10]` has label `actual completed optional protected-story return`; its `exact_attempts` is a61018-byte UTF-8 Exact wire string, SHA256 `2df0773bfbcd3a0fa22f907ae0df5502ef96c8f72966f33806299eee34efb79a`. Extract those bytes without a newline or JSON reserialization. It is tagged Exact JSON, not an ordinary attempts dictionary; use production Exact.parse when executing. Source inspection of the tagged structure shows TEST completed_main[L1,L2], completed_optional[A1-O1], exactly one A1-O1-completion-stamp, null side_attempt, A1-L2 Story and the existing13 unlocked equipment IDs. The receipt's `exact_story` tagged value equals its Story snapshot.

The report itself declares49 checks/0 failures. Actual clean exit/source custody are owner-reported in UPDATE `54124460-1cc3-4fa4-996a-41732805f22d` and wrapper SHA `faeee9197799faf91645189b284175b4379f5affdaa3cef6f9ac4cedc691647a`; they are not new independently executed evidence in this review. Final handoff remains pending portrait and seven-category packaging.

HANDOFF_AND_VALIDATION.md already requires report hash/extraction location/packet hash/original arrangement and explicitly forbids treating an arbitrary caller file as original evidence. Root must preserve that join on promotion; runtime file checksum alone establishes only caller-file integrity. No missing route export or new route run is necessary. Pending accepted-content/completed-file pins remain expected preparation work.

## Validation and limits

Source references, exact signatures, relevant native hierarchy/cleanup, report49/0 header and receipt identity/structure were inspected. No engine, parser, GUI, portrait, mechanics/art re-review, helper agent, full-playthrough, timing run or evidence-bank copy. No new acceptance or performance credit. Existing failed/nonclean and bounded94/0 exit2 evidence remains unchanged. Authored Act2 remains8/8 accepted; no human action is required.
