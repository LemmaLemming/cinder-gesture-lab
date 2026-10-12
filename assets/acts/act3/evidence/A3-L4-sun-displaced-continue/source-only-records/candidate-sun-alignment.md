# Candidate sun alignment — scoped source review

Read-only,12October2026; as-read HEAD `3449c07188436c74b597347317da8e66bbf06ef6`. No source/resource edits, engine job or native reproduction. This review investigates only the candidate Hero-restore/sun-follow concern. Root reports pending-dash production96002 had13/0 assertions but shared48 Title-lambda diagnostics were nonclean and separately reported to Integration; that result is not relabeled clean.

## Definite conditional source mismatch

1. Actual Shell `_prepare` constructs the fresh candidate Hero at `level.spawn_position()` (shell589). The candidate parent configures SunArt in `_on_enter_restore_candidate` (parent822). Configure calls present against that actual fresh Hero, so motifs initially follow spawnX/Z.
2. Full public prevalidation uses the saved Player payload without moving that Hero. Shell then calls `candidate.player.restore_state(snapshot.player)` BEFORE `candidate.level.restore_state(snapshot.level)` (shell625), as required by the whole native restore contract.
3. The parent `restore_state` repeats `snapshot_error(saved)` first (parent776). Base CinderLevel reaches its local validator before commit (level329–342/358–362); parent `_local_snapshot_error`793–794 calls the codec against `hero.snapshot_state()`.
4. Codec `_access_error` calls the parent's current `runtime_error` (codec494–500). Parent684 calls SunArt.runtime_error. Sun105 requires motifs.transform to equal the actual Hero's currentX/Z exactly. Motifs have not been re-presented after Hero restoration.
5. If saved HeroX/Z differs from spawnX/Z, that equality fails before owned local restore. The normal quiet `_update_presentation(true)` at the end of `false_paradise_codec_apply_owned_state` (parent917) is unreachable. Hidden first-entry suns still enforce the follow relation; `started=false` does not bypass it.

This is a source-derived conditional failure, not an observed failed native run. The published first-entry fixture routes LEFT and requests pause immediately with no native wait between release and request (fixture261–279). It requires a pending dash, but does not require any displacement from spawnX/Z. Its13 pass therefore does not establish the different-position case.

## Smallest compatible correction proposal

Keep Shared Shell Hero→level restore ordering. In the OWNED parent's actual `restore_state`, after the existing genuine paused `is_restore_candidate()` guard and before repeated `snapshot_error(saved)`, call the already-owned `sun_art.present(true)` against the real restored Hero and CURRENT parent model. Refuse/dispose the candidate if it fails. This is a quiet derived cosmetic alignment in the commit path, not a pure saved validator or a source/body stamp.

Do not call present inside snapshot_error/codec pure validators; do not weaken Sun follow equality, use saved pose proxies, move a live camera, or apply the saved sun model before its whole mechanical joins validate. Later owned-state apply still derives/installs the saved model from the restored full Scheduler and presents it quietly. The actual saved-position candidate Camera/HUD gate remains mandatory after local/base progress commit. Live runtime guards remain unchanged.

The smallest meaningful affected fixture change is to let the accepted ordinary LEFT dash execute one bounded post-actor native tick before its existing public pause. Require genuinely changed HeroX/Z AND a still-pending dash before disk Save/Continue/Retry, retaining strict full-unit/clock/resource/input assertions. That would exercise this precise restore condition without fabricated Hero fields, a whole route, target damage or new timing tolerance. Root owns implementation/execution; none occurred in this review.

## Selected exact as-read pins

- `scripts/campaign/shell.gd`: `8961f232a99d4d81f0c4f10d66716f7aa82fb147e3c484d6c353c78b5b46f6bc`
- `scripts/campaign/level.gd`: `1989a4170b68329afd6f49c5698b23aa96722883698ccacf32f905619539010d`
- `scripts/acts/act3/false_paradise_level.gd`: `ff5a50d895ba921a5baf8e59fdf4ce2aa5c9c00ba09b1f674bfca72afc5115cf`
- `scripts/acts/act3/false_paradise_codec.gd`: `5d49e2a69d7f3b6b345df00f226cbad69adf722f2cf73c3d2f9e6736297b386d`
- `scripts/acts/act3/garden_sun_art.gd`: `bc984527c1cd5e029924583b4349938833a9ac367193ede74be09141a365d920`
- `tests/acts/act3/false_paradise_production_entry_smoke.gd`: `3f042046683832d308f2515bd89233f0f670310501dc02e85ed8a7fd3b3a8f89`
