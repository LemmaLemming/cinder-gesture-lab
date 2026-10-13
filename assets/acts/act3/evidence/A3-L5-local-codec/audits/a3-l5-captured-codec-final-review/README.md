# Final sealed captured-rule codec source review

Reviewed READY SHA `31296482fd6d80bc76293fd6acf6d1858be95d93dc2f1181381b60f59af00898`. All five source hashes, 17 shared freezes and 36 unchanged V2 live functions match. Base `915252a2`, helper `6c3cfc22`, max2 helper `35c35fa0` remain pinned.

No engine, parser, UID generation or new codec native result was run. Only this report folder was written.

## Findings

- **F1 / P1 — interrupted suffix fixture clock ordering.** [Fixture line 303](/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/a3-l5-captured-codec-plan/tests/captured_rule_save_codec_smoke.gd:303) pauses from Playback's event observer before the late sole Gate observes the already advanced actual Player clock. The subsequent pending-suffix aggregate capture has no authoritative Gate synchronization. The public Gate/ActionCapture pair validator should reject the stale source clock. Arrange a supported authoritative observation at the deferred boundary; retain the original actual clocks and suffix rather than rewriting payloads.
- **F2 / P2 — current marker material visibility.** [Recipient line 821](/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/a3-l5-captured-codec-plan/runtime/captured_rule_codec_room.gd:821) validates marker visibility, mesh and material type but omits state-derived material/color/render policy. A zero-alpha current exposed marker can pass capture and geometry containment, then be visibly rebuilt by fresh shared `present()` while exact local recapture passes. Authenticate the public current marker resource, including its required visible rendering policy.

## Contracts checked

The packet retains one outer full Player, complete Gate/retirement and whole Scheduler1/projected Playback3. Fresh native restore follows actual Player → Gate → whole Scheduler → projected Playback → owned state → exact mechanical recapture → actual Camera/HUD gate. Original FIFO hash/clock custody and independent Actor/Scheduler clocks remain exact. Restore requests no admission, bind, proof, damage, reward or retiming. The corrected nested-type, marker-mode and full projection guards precede their dependent native helpers.

Framing optics, canceled/missing owner histories, unconfigured/transient states and an external full-parent floor/Scheduler3 remain explicitly unsupported. Source review establishes no new native pass, campaign Continue/Retry, production art or full level acceptance.

Full evidence, hashes, pointers and correction scope are in [report.json](/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/a3-l5-captured-codec-final-review/report.json).
