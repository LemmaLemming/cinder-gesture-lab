# Same-frame campaign HUD framing

`CinderCampaignShell` overrides the base Game processing loop. Its previous ordering framed the camera before updating the rendered HUD. A newly wrapped objective therefore used the preceding frame's smaller `GameHUD.combat_safe_rect()` even though the larger objective was displayed in the current frame. The base Game already updates its HUD first; this correction applies the same ordering to the production campaign override.

The narrow change updates campaign status before camera framing and optional shake. It preserves the fixed camera basis/width, following behavior, held release aim, actor state, simulation clocks and cosmetic policy.

The new [focused actual Shell fixture](../../tests/campaign_shell_hud_framing_smoke.gd) enters a [clearly test-only scene](../../tests/fixtures/campaign/shell_hud_framing_level.tscn) through public Begin, real preparation/save/install, public initial Resume and public deferred Pause. Injected registry metadata and process-specific `user://test-campaign-shell-hud-framing-*` paths never register campaign content or write production saves/settings. Its native shared player/source artwork, required lane/source meshes, crest and landing provide actual render bounds rather than a projected body substitute. No attack, damage or authored encounter is claimed.

The regression changes a short objective to a genuinely wrapped objective, calls the production Shell override exactly once without a preparatory HUD update, and compares its framing rectangle to the HUD actually rendered in that frame. It also checks the reverse transition, native frustum/unprojection containment, exact tagged actor/story invariants, camera basis/width and held release aim. Graphical execution additionally saves real 540×1170 paused portrait pixels using the unchanged nearest 270×585 world raster.

Normal native focus notifications remain active. This scripted paused fixture does not grab focus, suppress notifications, unlock macOS or claim native human gestures. It is independent of authored level acceptance, campaign fairness and full-route performance.

Verification used installed Godot 4.7.2 official `ed1daf0bf001b61586d9930840f2f1394092c079` through the canonical queue. The original Shell SHA256 `31c91a939008f03f3ddbb85d553c9fc0b2c913c0a4b01920a160714987c0e9c9` failed exactly two of twenty checks: both same-call HUD expansion and contraction framing-rectangle assertions. The corrected graphical run passed all twenty shared assertions plus four capture checks: **24 checks, zero failures, exit 0**, with no parse/script/runtime errors or warnings. The original fixture's native containment control already passed; the demonstrated defect is stale current-frame framing constraints, rather than a claim that this particular sparse arrangement visibly clipped.

```sh
# Original-order regression, before the narrow production change (exit 1).
python3 scripts/dev/dev.py engine --headless --path . --log-file "/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/campaign-shell-hud-framing-original.log" --script res://tests/campaign_shell_hud_framing_smoke.gd
# Corrected actual graphical fixture (exit 0).
python3 scripts/dev/dev.py engine --path . --log-file "/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/campaign-shell-hud-framing-final.log" --script res://tests/campaign_shell_hud_framing_smoke.gd
```

Ignored original/final logs remain separate. The earlier `.cinder/campaign-shell-hud-framing-before.log` attempt stopped at three checks/one failure because the filesystem sandbox prevented creating the isolated test save directory; its native host startup diagnostic is retained. It did not reach the camera regression. The two subsequent queued runs received narrow authorization for their isolated test saves.

Actual rendered 540×1170 views and metadata are in `.cinder/campaign-shell-hud-framing-graphical-8716/`: `01-short-objective.png`, `02-wrapped-objective.png` and `evidence.json`. Both images were opened and inspected: the native source, complete visible lane outline, source marker, landing and player remain clear below the expanded objective and above gesture hints. Captures follow `frame_post_draw` and are rendered paused views; the synchronous pre-yield assertions provide the exact one-call ordering evidence. Native focus was false. No authored level, attack, human gesture or performance acceptance is claimed. Only this new targeted fixture ran; unchanged camera, campaign Shell and authored level suites were not repeated.

[Portable original logs, metadata and captures](evidence/shared21-shell-hud/index.json) retain exact SHA256 checksums. The named queued target is `python3 scripts/dev/dev.py test campaign_shell_hud_framing`; the corrected evidence above was graphical execution of that same fixture, rather than a claim of an additional corrected headless run.

The frozen runtime, fixture and original evidence are committed at `b5c83193948e724a46b339e69e31e27978e68984`. Its documentation publication preserves those tested bytes.
