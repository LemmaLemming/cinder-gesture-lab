extends "res://tests/acts/act3/false_paradise_production_entry_smoke.gd"
## TEST ONLY displaced actual-Hero extension of verified first-entry production.
## Preserve the original pending-dash save, then actually finish that same dash.
## Fresh diskContinue must restore displaced Hero/derivedSun and exact whole unit.
## Original first-entry assertions, copied negatives, protectedRetry/GUI/cleanup remain.

func _initialize() -> void:
	# Actual public engine UID output for this first meaningful standalone script.
	# Original pre-run source map intentionally has no late UID sidecar.
	var path: String = "res://tests/acts/act3/false_paradise_displaced_continue_smoke.gd.uid"
	if not FileAccess.file_exists(path):
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if not _expect(file != null, "first native execution creates only this missing owned test UID"):
			quit(1)
			return
		file.store_line(ResourceUID.id_to_text(ResourceUID.create_id()))
		file.close()
	super._initialize()

func _save_pending_dash() -> String:
	var error: String = await super._save_pending_dash()
	if not error.is_empty(): return error
	var pending_save: Dictionary = _saved_campaign.duplicate(true)
	error = _resume_consumed()
	if not error.is_empty(): return error
	var completed: bool = false
	for _i: int in range(60):
		error = await _tick()
		if not error.is_empty(): return error
		var current: Dictionary = _hero.snapshot_state()
		if current.world_actions.pending_dash.is_empty() and float(_hero.get_threat_response_state().motion.dash_left_s) == 0.0:
			completed = true
			break
	if not completed: return "real routed dash did not complete within60 native post-actor ticks"
	if not _shell.request_pause_deferred(): return "public displaced complete-tick pause refused"
	error = await _settle_shell("pause")
	if not error.is_empty(): return error
	_saved_campaign = _shell.capture_campaign_snapshot()
	_saved_session = _shell.attempts.state()
	if _saved_campaign.is_empty(): return "actual displaced whole writer refused: " + _shell.campaign_error
	if _same(_saved_campaign.player.motion.position, pending_save.player.motion.position) or _same(_saved_campaign.player.motion.position, _checkpoint.player.motion.position) or not _saved_campaign.player.world_actions.pending_dash.is_empty() or _saved_campaign.player.world_actions.history.is_empty(): return "completed dash lacks actual changed native position/executed history"
	if not _same(_saved_session.story.snapshot, _saved_campaign) or not _same(_saved_session.story.checkpoint, _checkpoint) or not _same(_campaign_core(_saved_session), _story_core): return "displaced save lost exact protectedcheckpoint/story"
	if not _expect(true, "same real dash reaches a different Hero X/Z before whole Save", str(_saved_campaign.player.motion.position)): return "displaced observation failed"
	return _disk_error(_saved_session)
