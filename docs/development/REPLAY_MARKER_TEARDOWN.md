# Replay failure-marker teardown

Shared64 guards terminal marker placement when the Playback or its marker has left the scene tree. Act3 reported the concrete problem in request `e78e9038-83c7-4674-bbc2-f118e4627241`: deleting a whole Shell while a managed Echo warning was held produced a `get_global_transform` error during cancellation. Its original143/0 assertions and native0 remain **nonclean**, with the wrapper failure and exact log preserved.

Playback now checks marker validity and both nodes' actual tree membership before making the terminal marker visible or reading/writing global positions. It keeps the original terminal seal, cancellation reason/clock, lease retirement, conservative cooldown, once-only callbacks and quiet cue clearing. A detached marker stays hidden; it is not reattached, replaced or used to repair a damaged source. Normal attached cancellation keeps the existing marker and offset. No saved schema, damage, timing, profile or input API changes.

[Portable evidence](evidence/replay-marker-teardown/index.json) retains the original owner report, narrow before/after source, queued phases, fixed63 named source/UID observations and independent reviews.

- The new native regression passes **37/0** with actual assertion rows. It admits and locks a genuine managed Echo, pauses publicly, removes the real failure-marker child while retaining the real source/Scheduler, then performs real cancellation. A fresh attached-marker control verifies normal visible placement. Terminal provenance, callback counts, exact Hero/source state, quiet cues, four paused frames and cleanup pass. Its raw macOS certificate diagnostic remains; it is not called a clean log.
- The directly affected captured-player Playback suite passes **475/0**, exit0 with no error diagnostics after granting access to its process-specific temporary Store files. This existing fixture prints its assertions/footer rather than a structured complete-scope report; its actual475 PASS lines and normal terminal closure are retained.
- Its first sandbox run remains failed **406/11**: five denied temporary-save writes, five dependent round-trip checks and one empty-bundle cascade. Disk-dependent fresh branches were unexecuted there. The retry changes filesystem access only; source, assertions and timing remain identical.

Necessary import and both selected parsers close0. Import adds the one genuine new test UID within the named scope; host certificate/editor-settings permission diagnostics remain. No global resource/UID census or new runtime credit follows from import.

The new detached-marker cell keeps the source itself inside the tree. Whole-Shell deletion, Window Manager Quit, a freed marker and current O3 gameplay are not newly executed coverage. The actual reported failing primitive is reproduced through native cancellation, while the parent-tree guard is source-reviewed. Normal authored level disposal continues to call `exit_level` while its world is intact, retire leases, then dispose the Shell. This change does not alter the public Quit/save path or claim its independent validation. Act3's supported O3 work and each level's acceptance remain separate.

For a changed teardown path, run only the focused leaf through the canonical queue:

```sh
python3 scripts/dev/dev.py engine --headless --path . --script res://tests/replay_playback_teardown_smoke.gd
```

Set `CINDER_ECHO_TEARDOWN_REPORT` to a writable output file to retain all assertion rows. The original queued runner and its exact environment are archived. Reuse the unchanged475 result unless captured Playback behavior changes; do not repeat accepted levels or bypass the shared Godot queue.
