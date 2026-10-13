# Next adoption: owned overlap review

Reviewed 2026-10-12T08:25:09.308388+00:00. Source-only review of the existing preserving helper and actual Shared52 receipt; no helper invocation/import, merge, engine, checkout/evidence/index/ledger mutation or future publication pin was performed.

**The helper does not reject all incoming owned overlap.** In main (lines297–311), it partitions `owned_incoming` from the full actual BASE→PUBLICATION delta. `incoming_preflight` rejects owned paths only in its nonowned input, so that check does not apply to the separately handled owned rows.

For each owned incoming row, both a current indexed path and target blob must exist (no unallocated additions/deletions). Scripts/scenes/assets/tests and every path containing an evidence directory must have the **same Git blob and mode** as the target. Only non-evidence paths under data/campaign/act2 or docs/acts/act2 may have newer committed owner content. The before receipt records this owned publication delta separately.

After the single no-commit merge, all six owned prefixes are restored from the captured clean owner HEAD in index and worktree (lines358–359), preserving newer owner notes and exact runtime/evidence/UID originals instead of substituting the publication's owned files. Subsequent checks compare captured owned Git/physical rows, historical archives, .gdignore boundaries, recursive/active UIDs and settings, reject unexpected owned additions/removals, verify every nonowned target byte/mode and require exact [captured owner HEAD, publication] merge parents. Physical custody is separately captured/rechecked; the owned equality gate itself compares index blob/mode, rather than claiming a separate target physical comparison for every owned row.

The current actual52 adoption is complete with zero findings at merge `32a683be7f2897bbf1aa5082df34a7839ff80d7e`, but **owned publication overlap was0** in both before.json and adoption.json. Thus it demonstrates the preservation/nonowned path, not an executed overlapping O2 branch. The current helper matches its archived original byte-for-byte. Its comment that Shared52 contains an incoming O1 overlap is stale for this actual52 delta.

For a forthcoming publication importing the owner's byte-identical exact O2 candidate, no mask or preservation-function relaxation is required. The smallest future preparation is:

1. Use a fresh copied helper/receipt directory, actual declared PUBLICATION and BASE, and corresponding metadata/status/commit labels. Preserve the original52 helper and receipt. The current helper deliberately refuses duplicate adoption/existing output and cannot be rerun for52.
2. After actual publication arrival, inspect its owned delta: immutable O2 runtime/evidence/sidecars must already be indexed and byte/mode identical; any allowed data/docs mismatch must be explained as committed owner notes. The exception is prefix-based, so this review does not automatically classify every future data/docs difference as harmless notes.
3. Keep the existing clean seal, closed-owned-jobs declaration, ancestry/HEAD recheck, original-custody capture, scope-preserving restore and postchecks unchanged. If a genuine new/missing/divergent owned immutable path appears, diagnose that actual publication/candidate mismatch rather than broaden the exemption. Root owns configuration/adoption once the real publication is received.

Helper SHA256 `e66d5280402f7344c394d8d43b6d6235ec2865fd2790bd7d149f1d09912dd9fb`; actual52 adoption receipt SHA256 `c54cd9c24bf3ac287c35eb029c947225d889be5a04302f6c06ad0ac342c73729`; before receipt SHA256 `2629280a590f42e90c73a12b8fb1c52b8acb26b0d854e697bda92afa2af82d71`. Actual52 had2666 nonowned incoming paths and0 owned overlaps. Broad physical counts remain the existing helper receipt's scope; this review did not recompute its full filesystem inventory.

O3 runtime still waits for canonical O2 ACCEPTED. Availability/preparation/adoption alone provides no new O2/O3 native, art or acceptance credit.
