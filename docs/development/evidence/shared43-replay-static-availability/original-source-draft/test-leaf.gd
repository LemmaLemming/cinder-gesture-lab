extends "res://tests/campaign_shell_smoke.gd"
## DRAFT ONLY. Overrides the inherited run; no default/broad suite is executed.
## Real Shell/Player/Enemy/menus/SaveStore, TEST ONLY accepted room metadata.
## Button/OptionButton signals exercise UI callbacks, not native gesture input.
const StaticEquipment = preload("res://scripts/equipment.gd")
const StaticAttempts = preload("res://scripts/campaign/attempts.gd")
const STATIC_ROOT: String = "user://test-replay-static-availability/"
const ALTERNATE: Dictionary = {
	"weapon": "WEAPON-04", "jacket": "CLOTH-J2", "pants": "CLOTH-P1", "shoes": "CLOTH-S1",
}

func _run() -> void:
	_cleanup()
	raw = JSON.parse_string(FileAccess.get_file_as_string(Registry.DATA_PATH))
	for info: Dictionary in raw.levels:
		if ["A1-L1", "A1-L2"].has(info.id):
			info.scene_path = "res://tests/fixtures/campaign/live_" + String(info.id).to_lower().replace("-", "_") + ".tscn"
			info.readiness = "accepted"
			info.accepted_commit = "a".repeat(40)
			info.api_revision = Registry.API_REVISION
	var initial := StaticAttempts.new(Registry.new(raw))
	_expect(_all_static(initial.state().unlocked_equipment) and initial.state().story == null and initial.state().completed_main.is_empty(), "fresh policy exposes exactly 13 implemented static items without equipping or recording progress")
	game = _new_shell()
	await _settle()
	game.menu.begin_story_requested.emit()
	await _settle()
	_expect(game.campaign_error.is_empty() and is_instance_valid(game.active_level), "actual Shell begins the isolated native test room: " + game.campaign_error)
	if not is_instance_valid(game.active_level):
		_finish()
		return
	_expect(_same(game.player.equipment.snapshot(), StaticEquipment.STARTER), "story still begins with the canonical starter kit")
	game.resume_campaign()
	await create_timer(0.2).timeout
	game.request_pause()
	await _settle()
	# Explicit TEST ONLY resource/supply/enemy seeds test whole-unit isolation;
	# these are not combat, reward, checkpoint-route or campaign-clear evidence.
	game.player.hp = 37.0
	game.player.shells = 0
	game.active_level.charges = 0
	game.active_level.collected = ["supply-1"]
	game.active_level.guard.hp = 7.0
	_expect(game.active_level.request_checkpoint("static-kit-checkpoint", "encounter"), "native fixture checkpoint enters actual Shell persistence")
	await _settle()
	_expect(game.active_level.request_completion("static-kit-complete"), "TEST ONLY completion makes its real replay UI accessible")
	await _settle()
	_expect(game.attempts.state().completed_main == ["A1-L1"] and game.attempts.state().reward_ids.is_empty(), "fixture completion adds only its ordinary main prefix, with no equipment reward")
	game.menu.show_replay_setup("A1-L1")
	await _settle()
	_expect(game.menu.page_name() == "replay", "completed fixture opens the actual four-slot replay chooser")
	_check_selectors()
	_expect(_same(game.menu.replay_loadout(), StaticEquipment.STARTER), "initial replay choice follows story gear without changing it")
	var selection_protected: Dictionary = game.attempts.story_snapshot()
	_select_alternate()
	_expect(_same(game.menu.replay_loadout(), ALTERNATE) and _same(game.player.equipment.snapshot(), StaticEquipment.STARTER), "actual selector callbacks choose a mixed alternate kit before any actor equipment change")
	_press("UseStoryButton")
	_expect(_same(game.menu.replay_loadout(), StaticEquipment.STARTER), "Use Story Equipment retains the canonical story gear")
	_select_alternate()
	_expect(_same(game.attempts.story_snapshot(), selection_protected), "all synchronous equipment selection/preset callbacks preserve the exact whole protected snapshot")
	var pre_side: Dictionary = game.capture_campaign_snapshot()
	var checkpoint_before: Dictionary = game.attempts.state().story.checkpoint
	var progress_before: Array = game.attempts.state().completed_main.duplicate()
	_expect(not FocusExact.stringify(pre_side).is_empty(), "pre-side native aggregate has nonempty exact transport")
	if not _press("StartReplayButton"):
		_finish()
		return
	await _settle()
	_expect(game.campaign_error.is_empty() and game.attempts.active_kind() == "replay", "actual replay Start callback creates the isolated side attempt: " + game.campaign_error)
	if game.attempts.active_kind() != "replay":
		_finish()
		return
	var selected := StaticEquipment.new()
	_expect(selected.restore(ALTERNATE), "alternate kit uses only existing canonical slot definitions")
	_expect(_same(game.player.equipment.snapshot(), ALTERNATE) and _same(game.player.stats, selected.resolved_stats()), "the actual native Player resolves all four selected items through shared stats")
	_expect(game.player.hp == selected.resolved_stats().max_health and game.player.shells == selected.resolved_stats().shell_capacity, "fresh replay resources follow its real selected-kit policy")
	# Shell intentionally records the latest live story before side admission.
	# Its following camera can settle during deferred UI frames; copied actor,
	# level, equipment, aim/inputs/profile and checkpoint must remain exact.
	var protected: Dictionary = game.attempts.story_snapshot()
	_expect(_same(protected.player, pre_side.player) and _same(protected.level, pre_side.level) and _same(protected.equipment_ids, pre_side.equipment_ids) and _same(_without_camera(protected.shell), _without_camera(pre_side.shell)) and _same(game.attempts.state().story.checkpoint, checkpoint_before), "side admission records current presentation while preserving exact story actor/resources/level/gear/inputs/profile/checkpoint")
	_expect(game.attempts.state().completed_main == progress_before and game.attempts.state().reward_ids.is_empty(), "replay selection adds no progress or equipment reward stamp")
	# Explicitly different paused side resources expose any relaunch healing or
	# confusion between active side and protected story; no damage claim.
	game.player.hp = 19.0
	game.player.shells = 0
	game.active_level.charges = 0
	game.active_level.collected = ["supply-1"]
	game.active_level.guard.hp = 3.0
	game.request_pause()
	await _settle()
	var interrupted: Dictionary = game.attempts.state()
	_expect(_same(interrupted.story.snapshot, protected) and _same(interrupted.last_replay_equipment, ALTERNATE), "actual interrupted replay persists the remembered kit separately from protected story")
	var legacy: Dictionary = interrupted.duplicate(true)
	legacy.unlocked_equipment = StaticEquipment.STARTER.values()
	for id: String in ALTERNATE.values():
		if not legacy.unlocked_equipment.has(id):
			legacy.unlocked_equipment.append(id)
	_expect(legacy.unlocked_equipment.size() == 8 and game.attempts.state_error(legacy).is_empty(), "older availability subset is valid for these genuine story/side/remembered snapshots")
	var legacy_wire: String = FocusExact.stringify(legacy)
	var memory_path: String = _static_path("memory-only.json")
	var memory := StaticAttempts.new(game.registry, FocusStore.new(memory_path))
	memory.snapshot_validator = game._snapshot_problem
	_expect(memory.restore_session(legacy) and _same(memory.state(), legacy) and not FileAccess.file_exists(memory_path), "public restore_session remains exact in-memory-only and never migrates or writes")
	_expect(not legacy_wire.is_empty() and FocusExact.stringify(legacy) == legacy_wire, "memory restore does not mutate submitted container aliases")
	var writer := FocusStore.new(STATIC_ROOT + "campaign.json")
	var written: bool = writer.write_payload(legacy)
	_expect(written, "actual format-2 SaveStore writes the TEST ONLY older interrupted availability subset: " + writer.last_error)
	if not written:
		_finish()
		return
	var previous_generation: int = writer.generation
	var before_envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(writer.path))
	_expect(before_envelope.format_version == 2 and _same(writer.read_payload(), legacy), "legacy fixture uses the existing exact format-2 envelope without schema changes")
	game.free()
	game = _new_shell()
	await _settle()
	var migrated: Dictionary = game.attempts.state()
	_expect(game.campaign_error.is_empty() and paused and game.menu.page_name() == "title" and game.active_level == null, "relaunch migrates before installing any active actor and remains paused: " + game.campaign_error)
	if not game.campaign_error.is_empty() or game.attempts.active_kind() != "replay":
		_finish()
		return
	_expect(_all_static(migrated.unlocked_equipment) and _same(_without_availability(migrated), _without_availability(legacy)), "load expands only canonical availability, preserving exact story/side/checkpoints/remembered kit/progress/rewards")
	var durable := FocusStore.new(STATIC_ROOT + "campaign.json")
	_expect(_same(durable.read_payload(), migrated) and durable.generation == previous_generation + 1, "one verified atomic SaveStore generation durably publishes migration before live memory commit")
	var generation_after: int = durable.generation
	game.free()
	game = _new_shell()
	await _settle()
	_expect(_same(game.attempts.state(), migrated), "second relaunch keeps the complete migrated session unchanged")
	_expect(not durable.read_payload().is_empty() and durable.generation == generation_after, "already-current availability causes no redundant disk generation")
	game.resume_campaign()
	await _settle()
	_expect(is_instance_valid(game.active_level) and is_instance_valid(game.player), "relaunch installed the actual interrupted actor and level")
	if not is_instance_valid(game.active_level) or not is_instance_valid(game.player):
		_finish()
		return
	_expect(paused and game.menu.page_name() == "resume" and _same(game.capture_campaign_snapshot(), legacy.side_attempt.snapshot), "actual interrupted replay restores its native actor/enemy/supply/clock/gear as the exact paused saved aggregate")
	_expect(game.player.hp == 19.0 and game.player.shells == 0 and _same(game.player.equipment.snapshot(), ALTERNATE), "relaunch does not heal the interrupted side or revert its selected kit")
	game.menu.leave_side_requested.emit()
	await _settle()
	_expect(game.menu.page_name() == "journey" and game.attempts.state().side_attempt == null and _same(game.capture_campaign_snapshot(), protected), "leaving alternate replay restores the entire original story and returns to Journey")
	_expect(game.player.hp == 37.0 and game.player.shells == 0 and _same(game.player.equipment.snapshot(), StaticEquipment.STARTER), "protected story resources and equipment survive selection, disk migration, relaunch and side return")
	game.menu.show_replay_setup("A1-L1")
	await _settle()
	_expect(_same(game.menu.replay_loadout(), ALTERNATE), "the next replay remembers the actual chosen four-slot kit")
	_check_selectors()
	var starter_legacy: Dictionary = game.attempts.state()
	starter_legacy.unlocked_equipment = StaticEquipment.STARTER.values()
	starter_legacy.last_replay_equipment = {}
	_test_failure_atomicity(starter_legacy)
	_test_recovery_and_rejection(starter_legacy, legacy.side_attempt)
	_finish()

func _test_failure_atomicity(legacy: Dictionary) -> void:
	var path: String = _static_path("migration-failed.json")
	var store := FocusStore.new(path)
	_expect(store.write_payload(legacy), "real SaveStore prepares a valid starter-only legacy payload")
	var primary: PackedByteArray = FileAccess.get_file_as_bytes(path)
	var original_generation: int = store.generation
	var block_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path + ".bak"))
	_expect(block_error == OK and not primary.is_empty(), "existing backup directory provides a real bounded publication failure")
	if block_error != OK or primary.is_empty():
		return
	var attempts := StaticAttempts.new(game.registry, store)
	attempts.snapshot_validator = game._snapshot_problem
	_expect(attempts.restore_session(game.attempts.state()), "failed migration starts with an existing coherent native story/remembered-kit model")
	var memory_before: Dictionary = attempts.state()
	_expect(not attempts.load_saved() and not attempts.last_error.is_empty(), "actual migration refuses blocked backup publication visibly: " + attempts.last_error)
	_expect(_same(attempts.state(), memory_before) and FileAccess.get_file_as_bytes(path) == primary and store.generation == original_generation, "failed disk migration retains previous live model and exact primary bytes/generation")
	_expect(_temporary_count(path) == 0, "failed migration leaves no unpublished temporary payload")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".bak"))
	_expect(attempts.load_saved() and _all_static(attempts.state().unlocked_equipment) and _same(_without_availability(attempts.state()), _without_availability(legacy)), "retry after removing only the publication blocker atomically migrates without changing the protected legacy unit")
	_expect(_same(store.read_payload(), attempts.state()) and store.generation == original_generation + 1, "successful retry commits disk and memory as one migrated generation")

func _test_recovery_and_rejection(legacy: Dictionary, actual_side: Dictionary) -> void:
	# A remembered/side kit absent from its ORIGINAL ownership must be discarded
	# before all-13 expansion; availability is not an arbitrary-save repair.
	var recoverable: Dictionary = legacy.duplicate(true)
	recoverable.last_replay_equipment = ALTERNATE.duplicate(true)
	recoverable.side_attempt = actual_side.duplicate(true)
	var recovery_path: String = _static_path("recoverable-side.json")
	var recovery_store := FocusStore.new(recovery_path)
	_expect(recovery_store.write_payload(recoverable), "exact generic transport stores TEST ONLY side/kit corruption with a valid protected core")
	var recovery := StaticAttempts.new(game.registry, recovery_store)
	recovery.snapshot_validator = game._snapshot_problem
	_expect(recovery.load_saved() and recovery.active_kind() == "story" and recovery.state().last_replay_equipment.is_empty() and not recovery.last_warning.is_empty(), "old unavailable side and remembered kit are recovered before expansion, never retroactively legalized")
	_expect(_all_static(recovery.state().unlocked_equipment) and _same(recovery.story_snapshot(), legacy.story.snapshot) and _same(recovery_store.read_payload(), recovery.state()), "recovery plus availability migration durably preserves the valid protected story")
	var invalids: Array[Dictionary] = []
	var unknown: Dictionary = legacy.duplicate(true)
	unknown.unlocked_equipment.append("NOT-CANONICAL")
	invalids.append(unknown)
	var proposed: Dictionary = legacy.duplicate(true)
	proposed.unlocked_equipment.append("CLOTH-J3")
	invalids.append(proposed)
	var perk: Dictionary = legacy.duplicate(true)
	perk.unlocked_equipment.append("PERK-01")
	invalids.append(perk)
	var unowned_story: Dictionary = legacy.duplicate(true)
	unowned_story.story.snapshot.equipment_ids.weapon = "WEAPON-02"
	invalids.append(unowned_story)
	var wrong_slot: Dictionary = legacy.duplicate(true)
	wrong_slot.story.snapshot.equipment_ids.jacket = "WEAPON-01"
	invalids.append(wrong_slot)
	for index: int in range(invalids.size()):
		var path: String = _static_path("invalid-%d.json" % index)
		var store := FocusStore.new(path)
		_expect(store.write_payload(invalids[index]), "generic exact transport creates negative legacy payload %d without semantic acceptance" % index)
		var bytes_before: PackedByteArray = FileAccess.get_file_as_bytes(path)
		var model := StaticAttempts.new(game.registry, store)
		model.snapshot_validator = game._snapshot_problem
		var before: Dictionary = model.state()
		_expect(not model.load_saved() and _same(model.state(), before) and not bytes_before.is_empty() and FileAccess.get_file_as_bytes(path) == bytes_before, "malformed/unimplemented/unowned/wrong-slot protected payload %d rejects without availability repair or disk/memory mutation" % index)
		_expect(not model.restore_session(invalids[index]) and _same(model.state(), before), "in-memory protected rejection %d retains original strict ownership semantics" % index)

func _check_selectors() -> void:
	var total: int = 0
	for slot: String in StaticEquipment.SLOTS:
		var selector: OptionButton = game.menu.find_child(slot.capitalize() + "Selector", true, false) as OptionButton
		_expect(selector != null, "replay exposes actual " + slot + " selector")
		if selector == null:
			continue
		var expected: Array = []
		for item: Dictionary in StaticEquipment.new().available_items(slot):
			expected.append(item.id)
		var observed: Array = []
		for index: int in range(selector.item_count):
			observed.append(selector.get_item_metadata(index))
		_expect(observed == expected and selector.custom_minimum_size.y >= 44.0, "selector contains only canonical static " + slot + " items and keeps its logical touch height")
		total += observed.size()
	_expect(total == 13 and StaticEquipment.SLOTS.size() == 4, "four replay slots collectively contain exactly 13 static items; no perk, powerup or headwear slot")

func _select_alternate() -> void:
	for slot: String in StaticEquipment.SLOTS:
		var selector: OptionButton = game.menu.find_child(slot.capitalize() + "Selector", true, false) as OptionButton
		var found: int = -1
		if selector != null:
			for index: int in range(selector.item_count):
				if selector.get_item_metadata(index) == ALTERNATE[slot]:
					found = index
		_expect(found >= 0, "existing alternate " + slot + " is selectable without grant_equipment")
		if found >= 0:
			selector.select(found)
			selector.item_selected.emit(found)

func _press(name: String) -> bool:
	var button: Button = game.menu.find_child(name, true, false) as Button
	var ready: bool = button != null and not button.disabled
	_expect(ready, "actual enabled replay control " + name + " exists")
	if ready:
		button.pressed.emit()
	return ready

func _all_static(ids: Array) -> bool:
	if ids.size() != StaticEquipment.IMPLEMENTED_IDS.size():
		return false
	for id: String in StaticEquipment.IMPLEMENTED_IDS:
		if ids.count(id) != 1:
			return false
	return true

func _without_availability(value: Dictionary) -> Dictionary:
	var core: Dictionary = value.duplicate(true)
	core.erase("unlocked_equipment")
	return core

func _same(left: Variant, right: Variant) -> bool:
	var before: String = FocusExact.stringify(left)
	var after: String = FocusExact.stringify(right)
	return not before.is_empty() and not after.is_empty() and before == after

func _temporary_count(path: String) -> int:
	var absolute: String = ProjectSettings.globalize_path(path)
	var count: int = 0
	for name: String in DirAccess.get_files_at(absolute.get_base_dir()):
		if name.begins_with(absolute.get_file() + ".tmp-") or name.begins_with(absolute.get_file() + ".bak.tmp-"):
			count += 1
	return count

func _without_camera(value: Dictionary) -> Dictionary:
	var result: Dictionary = value.duplicate(true)
	result.erase("camera_focus")
	return result

func _static_path(name: String) -> String:
	return STATIC_ROOT + name

func _new_shell() -> CinderCampaignShell:
	var result: CinderCampaignShell = Shell.new()
	_expect(result.configure_runtime(raw, STATIC_ROOT + "campaign.json", STATIC_ROOT + "settings.json", STATIC_ROOT + "preferences.json"), "isolated Shell configuration validates TEST ONLY registry")
	root.add_child(result)
	return result

func _cleanup() -> void:
	var names: Array = ["campaign.json", "settings.json", "preferences.json", "memory-only.json", "migration-failed.json", "recoverable-side.json", "invalid-0.json", "invalid-1.json", "invalid-2.json", "invalid-3.json", "invalid-4.json"]
	for name: String in names:
		for suffix: String in [".bak", ""]:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(STATIC_ROOT + name + suffix))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(STATIC_ROOT))

func _finish() -> void:
	if is_instance_valid(game):
		game.free()
	paused = false
	_cleanup()
	print("Replay static availability smoke: %d checks, %d failures (TEST ONLY native rooms; UI signal callbacks)" % [checks, failures])
	quit(1 if failures else 0)
