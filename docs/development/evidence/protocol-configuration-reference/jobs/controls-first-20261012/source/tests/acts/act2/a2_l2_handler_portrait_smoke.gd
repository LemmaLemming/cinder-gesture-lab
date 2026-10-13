extends "res://tests/acts/act2/a2_l2_live_level_smoke.gd"
## Scoped actual native cosmetic acceptance: same real village/yard/apron
## route, current Handler states and paired source. No full-level clear claim.

func _run() -> void:
	if not _read_options() or not _expect(_capture_live and _profile_id == "standard" and _loadout_name == "heavy", "scoped Handler view uses native Standard/Heavy"):
		quit(1)
		return
	_capture_root = "res://captures/act2/handler-front/"
	root.size = Vector2i(540, 1170)
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_root)) == OK, "create separate current Handler portrait directory"):
		quit(1)
		return
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	_l1_fixture_bytes = FileAccess.get_file_as_string("res://tests/acts/act2/fixtures/a2_l1_transition_destination.tscn")
	_cleanup()
	var before: int = _failures
	if not await _portrait_route() and _failures == before: _expect(false, "scoped actual Handler route aborted: " + _diagnostic())
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical and FileAccess.get_file_as_string("res://tests/acts/act2/fixtures/a2_l1_transition_destination.tscn") == _l1_fixture_bytes, "scoped Handler fixture preserves canonical data/L1")
	if is_instance_valid(_game): _release_fixture_shell(_game)
	_game = null
	paused = false
	_cleanup()
	print("Weybridge actual Handler portrait smoke: %d checks, %d failures; current native states only, no full clear/balance/device claim" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _portrait_route() -> bool:
	var raw: Dictionary = JSON.parse_string(_canonical)
	for info: Dictionary in raw.levels:
		if info.id in ["A2-L2", "A2-L3"]:
			info.scene_path = LevelPath if info.id == "A2-L2" else NextPath
			info.readiness = "accepted"
			info.accepted_commit = "b".repeat(40)
			info.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A2-L3").is_empty(), "injected TEST ONLY L3 scene uses matching exported identity and shared level contract") or not await _seed(registry): return false
	_game = Shell.new() as CinderCampaignShell
	_game.configure_runtime(raw, TEST_ROOT + "campaign.json", TEST_ROOT + "settings.json", TEST_ROOT + "preferences.json")
	root.add_child(_game)
	await _settle()
	_game.menu.difficulty_preference_requested.emit(_profile_id)
	_game.resume_campaign()
	await _settle()
	if not _expect(_live() and _game.active_level.scene_file_path == LevelPath, "actual CampaignShell installs Weybridge: " + _game.campaign_error): return false
	var level: CinderLevel = _game.active_level
	var hero: CinderPlayer = _game.player
	var installed: Dictionary = level.snapshot_state()
	if not _expect(not installed.is_empty() and installed.local.profile_id == _profile_id and Codec.same_values(installed.local.rays.configuration.resolved_role, _expected_roles.ray), "actual shell restores the chosen fixed canonical profile/role"): return false
	if not _expect(hero.presentation_id == "act2_survivor" and hero.equipment.snapshot() == _loadout and Codec.same_values(hero.stats, _expected_stats) and hero.shells == 0, "real L2 entry retains Act2 presentation, canonical selected gear/stats and initial zero ammo"): return false
	if _loadout_name == "heavy": _expect(is_equal_approx(float(hero.stats.primary_range), 1.8), "Heavy uses actual shortest shared primary reach")
	_actors = level.get("_actors").duplicate()
	if not _expect(_actors.size() == 6 and _state().mechanisms.size() == 7 and not _contains_pickup(level), "six authored HP targets and three tool/four foot mechanisms; no victory pickups"): return false
	var defeats: Array[String] = []
	for actor: Node in _actors.values(): actor.connect("defeated", func(id: String) -> void: defeats.append(id))
	var checkpoints: Array[String] = []
	var completions: Array[String] = []
	var exits: Array[String] = []
	var resources_at_exit: Dictionary = {}
	level.checkpoint_requested.connect(func(_id: String, checkpoint: String, kind: String) -> void:
		checkpoints.append(checkpoint)
		_expect(kind == "encounter", "actual contact checkpoint uses shared encounter boundary")
	)
	level.completion_requested.connect(func(_id: String, completion: String) -> void: completions.append(completion))
	level.contact_exit_requested.connect(func(_id: String, exit_id: String) -> void:
		exits.append(exit_id)
		resources_at_exit["hp"] = hero.hp
		resources_at_exit["shells"] = hero.shells
		resources_at_exit["equipment"] = hero.equipment.snapshot()
	)
	hero.world_action_executed.connect(func(record: Dictionary) -> void: _actions.append(record.duplicate(true)))
	_game.resume_campaign()
	if not await _clear(["village_scout"]) or not await _clear(["yard_handler"]): return false
	_expect(defeats == ["village_scout", "yard_handler"] and _state().beat == "yard_exit" and checkpoints.is_empty(), "village Scout then lone yard Handler are real defeats before the first contact")
	if not await _contact("yard_exit", checkpoints): return false
	if not await _complete_foot("foot_demo"): return false
	_expect(_state().beat == "apron_pair" and defeats.size() == 2, "isolated foot completes without an attack/HP defeat")
	if _profile_id == "assisted":
		if not await _clear(["apron_handler"]) or not await _complete_foot("foot_apron"): return false
	elif not await _complete_foot("foot_apron") or not await _clear(["apron_handler"]): return false
	_expect((_paired_seen.has("foot_apron") if _profile_id != "assisted" else not _paired_seen.has("foot_apron")) and _state().beat == "before_crossing", "actual apron ordering preserves selected concurrent/Assisted serialized profile")
	for label: String in ["tool-warning", "tool-lock", "tool-active", "tool-recovery", "apron-combination"]:
		_expect(_captured.has(label), "current actual Handler native state exists: " + label)
	_game.request_pause()
	await _settle()
	var saved: Dictionary = _game.capture_campaign_snapshot()
	_expect(not saved.is_empty() and _game.campaign_error.is_empty() and defeats == ["village_scout", "yard_handler", "apron_handler"] and checkpoints == ["weybridge-yard-exit"] and completions.is_empty() and exits.is_empty(), "scoped actual Handler portrait retains exact first3 defeat prefix and first boundary, no final clear")
	return _failures == 0
