# O1 private job runner

Source-only adaptation of the established L5 runner. The runner has not been imported or executed; Python AST parsing succeeded. All function bodies are unchanged except the literal fixture path in `main`. The explicit source list, scope, footer and optional recipe path now identify O1. No engine or worktree mutation occurred.

The default selection contains 78 required paths, 42 paired GDScript UID paths, one optional recipe and the runner itself: 122 snapshot entries before caller additions. Missing required fixture before promotion fails before launch. Missing UID/recipe entries are recorded as absent and never created. The recipe name is provisionally `data/campaign/act1/a1_o1_difficulty_arrangements.json`; pass `--arrangement-json` to require the actual promoted recipe and update the optional path if its agreed name differs.

Baseline provenance includes `.cinder/a1-l5-retention-checkpoint-adoption.json`, `.cinder/local.json` and `docs/development/SHARED_CONTRACT.md`: current Shared73 runtime plus the documentation-only retained-policy adoption. Actual source declarations and read-only Git revision/branch/selected status are captured at invocation. No new native API is assumed: old O1 remains API1/schema1 until parent promotion, with API2/schema2 only future authorization. The source selection includes protected L2 Story construction used by the inherited O1 campaign fixture. It is not a global class/resource graph.

The fixture author confirms `--case=legacy-producer`, automatic unique native report, structured assertion rows for inherited/cleanup checks, and this footer: `A1-O1 DIFFICULTY: N checks, M failures; complete=true/false; report=res://...`. Native keys must include case, checks, failures, complete, success, first_failure, assertions; a clean pass requires first_failure={}, every assertion/count/footer identity consistent, actual exit0, complete/success true, zero raw errors/warnings and unchanged selected source bytes through closure. An existing/new UID appearing during execution counts as source change; the runner never imports to fix it.

Use the same invocation shape as L5, for example (not executed):

```sh
python3 /private/tmp/a1-o1-difficulty-implementation/run_a1_o1_difficulty_job.py --root '/Users/howardchen/.codex/worktrees/campaign-act1/video game idea' --run-dir .cinder/o1-difficulty/legacy-producer01 -- --case=legacy-producer
```

`--gui` removes only headless. Exactly one dev.py shared-queue child is launched; no retries, external watchdog, lock deletion or import. `--source` and a JSON `--source-list` add explicit frozen inputs. Forwarded `--source-*-report`/`--source-*-store` inputs are automatically banked; other file arguments must also be passed through `--source`. The optional `--branch-root` belongs to the fixture and is forwarded literally. Exact branch companion bytes embedded in native JSON are preserved by the runner; portable copying of original companion files remains a separate archive step. There is no automatic screenshot copying in this runner.
