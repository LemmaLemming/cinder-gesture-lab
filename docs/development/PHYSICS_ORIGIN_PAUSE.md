# Physics-origin Pause registration

Shared58 fixes a save refusal when public Pause begins from a real physics tick. The first subsequent `process_frame` signal can occur before `Engine.get_process_frames()` advances. Shared57 interpreted that signal as a failed registration boundary and rejected the operation with `Paused registration frame lost bounded donor/disk/native custody`.

The focused native reproduction records a grounded Hero, the public Pause request at process counter 50, and the first signal still at 50 with the tree paused and registration pending. The original closes **6 checks, one failure** at the first save assertion. That original remains [preserved with its source manifest and logs](evidence/physics-origin-pause/index.json).

## Repair and validation

The nine-line Shell change permits one additional signal only when the first signal retains the original counter, the Shell remains in the tree, the operation epoch matches and cancellation has not occurred. The original elapsed-time anchor and 2,000 ms limit remain. Full donor, disk, Attempts, fresh-candidate and native registration checks still run at the original final boundary; no successful validation is cached. Cancellation or disposal still releases the pending candidate worlds without installing them.

The exact candidate closes **23/0** on the private paired fixture. Its positive path observes counters 50 then 51 and compares the full actual submitted packet with committed Attempts, checksummed disk and installed state. Its two additional-wait negatives exercise public Retry cancellation and Shell disposal. Directly affected existing restore and startup-cancellation suites close **96/0** and **21/0**, clean.

The persistent [regression](../../tests/restore_candidate_physics_boundary_smoke.gd) removes only experiment-specific source-hash assertions, so unrelated future source edits do not invalidate a behavioral test. That exact installed source closes **22/0**, clean. Necessary import closes clean with one genuine new test UID and no changes to the 473 existing UID files in the scoped manifest. The original and candidate parser checks are clean. All other selected executable inputs remain unchanged within each recorded run. The evidence index describes the manifest scope; it does not claim that the four asset shader UIDs were in that scope.

Run this targeted regression through the canonical queue:

```sh
python3 scripts/dev/dev.py engine --headless --path . --script res://tests/restore_candidate_physics_boundary_smoke.gd
```

## Compatibility and remaining authored checks

This changes registration scheduling only. Save schemas, snapshot values, actor construction, final validation predicates and level interfaces are unchanged. Campaign acceptance remains 16/24. The existing accepted levels do not require a blanket rerun.

Act 2's checkpoint/native-lunge fixture and Act 3's standalone saved-warning viewer previously reported the same generic error. The tiny reproduction proves this shared timing defect; it does not retrospectively identify their exact failed operand. Act 2's subsequent passive diagnostic also closes46/1 with counter19 at preparation entry, raw-row observations and post-cleanup failure, and no post-wait donor/disk guard calls. Root verified the original raw/result hashes; those observations support the same-counter inference without inventing unobserved private timer stamps. Its owner-reported broader source/UID custody remains qualified. Their owners must run only the affected focused checkpoint or saved-session suffix after preserving adoption. Original failures and unexecuted recorder submissions remain intact.

Act 3's authentic saved-session archive pins its producer Shell. Its original archive must remain immutable. A test reader may explicitly recognize only this reviewed compatible pair for `scripts/campaign/shell.gd`: producer SHA256 `29c73f78ebf1d48545539aa3a8ffc506773b402fc2a8f075be24d14de36eed31` to consumer `f8df3b798544b79d66985f5e468f13ade5485bccc6050b54c9d9d242b3211a0f`. Every other producer/source pin and packet assertion stays exact. This source compatibility permits a focused replay test; it does not establish that the authored replay or portrait passes.

No full-route, boss victory, new portrait, balance or performance result is claimed by this shared regression. Those are separate from its actual native save/cancellation evidence.
