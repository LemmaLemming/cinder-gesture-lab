# Godot and VSCode parallel development setup record

Setup date: 8 October 2026. This record describes the prepared development environment and remaining launch gates. Future agents should follow [the workflow](PARALLEL_ACT_DEVELOPMENT.md), inspect current local settings and rerun checks rather than assume this snapshot is current.

## Installed and configured

- Existing VSCode: **1.139.1, Apple Silicon**. Installed the official **Godot Tools 2.7.1**, extension ID `geequlim.godot-tools`. Existing unrelated extensions were retained.
- Existing engine: **Godot 4.7.2 stable official**, `4.7.2.stable.official.ed1daf0bf`, in the integration checkout's ignored `.tools/Godot.app/Contents/MacOS/Godot`. No engine replacement or Node installation was needed.
- Configured Godot 4.7 editor preferences to use VSCode's application CLI, pass `{project} --goto {file}:{line}:{col}`, reload scripts after external changes and import resources while unfocused. Saved the previous settings in ignored `.cinder/backups/`. Already-open editors may retain previous in-memory preferences; save work and reopen them through the queued command.
- Added portable `.vscode/` extension recommendations, tasks, GDScript indentation and generated-file exclusions. Generated integration machine settings and `.cinder/cinder.code-workspace`; these absolute paths remain ignored. Act worktrees generate their own local settings with the same canonical root and different ports.
- Added queued Godot/dev commands, a VSCode engine wrapper, the shared custom-level preview interface and per-act content directories. The Character Lab stays the default entry point.
- Linked this workflow from AGENTS.md and README. Equipment-grid review is required at level-playstyle decisions; equipment creation and ability introductions use separate canonical records.

## Verification

- Opened the generated Cinder integration workspace in VSCode. The official extension displayed a live GDScript language-server connection at `127.0.0.1:6005`. The F5 debugging profile is configured; an interactive breakpoint session was not exercised.
- `python3 scripts/dev/dev.py check` completed successfully against the updated shared code: import plus **300 Godot checks, zero failures** (mechanics 78, equipment 50, Character Lab 39, visual effects 102, level contract 31), followed by canonical equipment-grid validation. The separate numerical equipment and ability-registry validators also passed. An earlier run failed a frame-sensitive effects assertion while another chat was revising that code; the final run passed. Rerun against the baseline actually dispatched to workers.
- **56 Python CLI tests passed**: dev tooling 20, equipment grid 12 and existing ability usage 24. These cover shared-worktree serialization, child-held locks, bounded validation, error detection, canonical proxy routing, concurrent equivalent equipment proposals, ownership/history and ability allocations. The setup generator also rejects private/unrelated canonical roots or missing design tools before replacing local settings; the real integration settings were regenerated successfully. Fake-engine tooling tests establish orchestration behavior, not three-editor capacity.
- Canonical equipment grid validation passed with **36 records, zero creation claims and zero duplicated structural types**. The ability registry remained at revision 0 with no introduction allocations. Test allocations occurred only in temporary fixtures; this setup reserves no campaign equipment.
- Rendered and inspected the custom level fixture through the shared shell at **340 × 736 portrait** on the Apple M3 Compatibility renderer. It showed the shared helmeted player/HUD and a plain test floor without lab stands. Lifecycle/reset/resume behavior passed the 31 contract checks. This fixture is a development smoke scene, not a finished campaign level.
- Invalid custom scene selection returned status 2. VSCode/local workspace JSON parsed, setup-document links resolved and `git diff --check` passed.

This verification does not establish campaign completeness, mobile builds, save behavior, gameplay balance or three simultaneous engine sessions. The resource queue is deliberately configured for one active Godot job. Each act still needs actual portrait encounter testing and shared mobile device validation.

## Baseline publication

On 8 October 2026 the user authorized committing the current repository to its existing private GitHub destination, [LemmaLemming/cinder-gesture-lab](https://github.com/LemmaLemming/cinder-gesture-lab), on `codex/gesture-prototype`. The baseline includes the pending prototype, equipment/ability tools, campaign and reference documentation, source assets and this development setup. Generated `.godot/`, `.tools/`, `.cinder/`, captures, exports and ledger lock files remain ignored. Confirm the actual commit and clean checkout with Git before creating worker worktrees; publication does not create those worktrees or launch act workers.

## Conditions before dispatching the three act workers

- Finish the user's RAM/disk cleanup and inspect current pressure/free space. The observed machine is an **M3 MacBook Air, 8 CPU cores, 16 GB memory**. At the earlier assessment it had about 17 GB of swap in use; disk availability fluctuated around 12–18 GiB during setup, with `doctor` reporting 12.0 GiB at the final check. These are snapshots, not a capacity benchmark. Keep heavy jobs serialized initially.
- Start all three act worktrees from the same reviewed published baseline containing the prototype/design/assets and this setup. Any later uncommitted edits must be reviewed and integrated before workers depend on them.
- Assign integration ownership and act-owned paths. Generate local settings in each worker checkout and verify that all workers resolve the same canonical ledgers and common Git lock.
- Run the shared checks and inspect one greybox level per act in the actual portrait view before expanding the scope.

## Conditions before mobile release work

Xcode is installed and selected at `/Applications/Xcode.app/Contents/Developer`. Matching Godot export templates were not present in the inspected template directory. `adb` was not on PATH, and an installed Android SDK/JDK/export configuration was not verified. No iOS/Android packages, signing credentials, store uploads or physical-device performance tests were created by this setup. Arrange a shared mobile export/device slice before committing all three acts to production scope.

## Maintenance

Keep the official extension and engine version aligned with the repo's tested baseline. Revalidate settings/schema and the game after any upgrade. Preserve `.gd.uid` files; ignore import caches, local workspace settings, credentials and build products. Use the existing nvm policy if future tooling introduces Node/npm/pnpm. Update this record when infrastructure or verified prerequisites change.
