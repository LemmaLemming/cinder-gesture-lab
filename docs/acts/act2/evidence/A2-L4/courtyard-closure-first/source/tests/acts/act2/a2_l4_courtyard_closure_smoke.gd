extends "res://tests/acts/act2/a2_l4_priority_repro.gd"
## TEST ONLY closure of the preserved failed1261/1 producer's earned stage6.
## Reuses its original native combat/tail/witness attribution, never replays it.
## Historical defeat records exercise the corrected typed expectation selector.
## Fresh public Store/Shell GUI Continue restores the untouched full model;
## no live HP/phase/clock/pose/input writes, fake observer flags or safety proof.
## No Putney contact, completion, exit, full-route/matrix or portrait acceptance.
const CLOSURE_ROOT: String = "user://test-a2-l4-courtyard-closure/"
const CLEARED_ROOT: String = "res://docs/acts/act2/evidence/A2-L4/priority-spatial-corrected/"
const CLEARED_SOURCE_SHA: String = "58f3df2eb662cca568819a4bfa9737587d7616c14e6464d86b8668645f0c01b4"
const CLEARED_PROVENANCE_SHA: String = "6bfa94778409877a2646440fc0039a5219e190128a53dec2b6631bf554e8bf73"
const CORRECTED_PRIORITY_SHA: String = "f2e58732e284d53be7c318b0c859209ebd983c5c8927e1ce1e0d55ee7b0d8fa5"
const PRODUCER_PRIORITY_SHA: String = "ff359cbef6973ebcecb436edcaacfe474db8f215d982f023cda76094ec25f23f"
const PRODUCER_BASE_SHA: String = "160bf73d65e2b46ff3b6ec93a937915347f5714d94241409f10a236c40999e3d"
const CORRECTED_BASE_SHA: String = "f260f5253da5d3fb3931eb1ceaeb1a05f22878c8f56b0159136122367cf6b560"
const CLEARED_HASHES: Dictionary = {
	"incomplete-actual.aggregate.exact.json": "c7c048fb7d6dbfe5a1ab14caf12ad144e5da4e534a351318af6fdb26d608719f",
	"incomplete-actual.attempts.exact.json": "a4e4362e52c96789e201bef59efc0bce67bdad29c9600af0cf49a0612e2fadc6",
	"incomplete-actual.diagnostic.exact.json": "3c16143af30817bbe1a8222e95a680a528b72dfb9183ffcba67aeb3e840e08d0",
}
var _cl_saved_selector: bool = true
var _cl_watch: bool = false
var _cl_events: Array[String] = []
var _cl_unit: Dictionary = {}
var _cl_model: Dictionary = {}
var _cl_history: Dictionary = {}
var _cl_pristine_retirements: Array[Dictionary] = []
var _cl_pristine_seen: Dictionary = {}

func _pr_saved_courtyard_selected() -> bool:
	# Pure TEST expectation configuration only, never a production state input.
	return _cl_saved_selector

func _run() -> void:
	if not _read_options() or not _expect(_profile_id == "standard" and _loadout_name == "heavy" and not _capture_live, "closure uses original Heavy/Standard metadata; no capture/combat selector"):
		quit(1); return
	root.size = Vector2i(540, 1170)
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	print("L4 courtyard closure scope: original1261/1 remains failed; native archived stage6/seven defeats/banks complete/earlier stage4 checkpoint. This checks typed expected branches and actual fresh quiet GUI transport only; no combat replay or inferred path safety.")
	var good: bool = _cl_read_original()
	if good: good = _cl_check_historical_closure()
	if good:
		node_added.connect(_cl_observe_added)
		_cl_cleanup_paths()
		good = await _cl_install_original()
		if good:
			var exact: String = PriorityJson.stringify(_cl_unit)
			var payload: String = PriorityJson.stringify(_cl_model)
			for frame: int in range(8): await process_frame
			_expect(PriorityJson.stringify(_game.capture_campaign_snapshot()) == exact and PriorityJson.stringify(_game.attempts.state()) == payload and _cl_events.is_empty(), "paused fresh earned unit holds every original clock/resource/input/history and emits no events")
			await _cl_close_whole_shell()
	_cl_watch = false
	if is_instance_valid(_game): await _cl_close_whole_shell()
	paused = false
	_cl_cleanup_paths()
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical, "TEST registry injection preserves canonical registry bytes")
	_cl_verify_artifact_hashes()
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "closure leaves no old native enemy/cue identity")
	print("L4 courtyard closure smoke: %d checks, %d failures; pristine validation retirement callbacks=%d; archived1261/1 unchanged; typed expectation/quiet earned-state transport only; no new combat/full-route claim" % [_checks, _failures, _cl_pristine_retirements.size()])
	quit(0 if good and _failures == 0 else 1)

func _cl_verify_artifact_hashes() -> bool:
	if not _expect(FileAccess.get_sha256(CLEARED_ROOT + "source.json") == CLEARED_SOURCE_SHA and FileAccess.get_sha256(CLEARED_ROOT + "earned-cleared/provenance.json") == CLEARED_PROVENANCE_SHA, "original frozen producer inventory/provenance remain hash-pinned"): return false
	for name: String in CLEARED_HASHES:
		if not _expect(FileAccess.get_sha256(CLEARED_ROOT + "earned-cleared/" + name) == CLEARED_HASHES[name], "original native earned file remains byte-identical: " + name): return false
	return true

func _cl_read_original() -> bool:
	if not _cl_verify_artifact_hashes(): return false
	var inventory: Variant = JSON.parse_string(FileAccess.get_file_as_string(CLEARED_ROOT + "source.json"))
	if not _expect(inventory is Dictionary and inventory.get("files") is Dictionary and inventory.files.size() == 281, "producer retains its original complete281-source inventory"): return false
	for path: String in inventory.files:
		var recorded: Variant = inventory.files[path]
		if not _expect(not path.begins_with("/") and not path.split("/").has("..") and recorded is String and recorded.length() == 64 and FileAccess.get_sha256(CLEARED_ROOT + "source/" + path) == recorded, "literal original source copy matches frozen inventory: " + path): return false
		var current: String = FileAccess.get_sha256("res://" + path)
		if path == "tests/acts/act2/a2_l4_priority_repro.gd":
			if not _expect(recorded == PRODUCER_PRIORITY_SHA and current == CORRECTED_PRIORITY_SHA, "only explicit corrected typed-array TEST helper differs from its failed original source"): return false
		elif path == "tests/acts/act2/a2_l4_live_level_smoke.gd":
			if not _expect(recorded == PRODUCER_BASE_SHA and current == CORRECTED_BASE_SHA, "explicit TEST capture-only bank full-source/retained-opening/tail metadata correction matches production framing; capture disabled in original Priority and closure"): return false
		elif not _expect(current == recorded, "every other current producer dependency remains exact: " + path): return false
	var aggregate: Dictionary = PriorityJson.parse(FileAccess.get_file_as_string(CLEARED_ROOT + "earned-cleared/incomplete-actual.aggregate.exact.json"))
	var model: Dictionary = PriorityJson.parse(FileAccess.get_file_as_string(CLEARED_ROOT + "earned-cleared/incomplete-actual.attempts.exact.json"))
	var history: Dictionary = PriorityJson.parse(FileAccess.get_file_as_string(CLEARED_ROOT + "earned-cleared/incomplete-actual.diagnostic.exact.json"))
	if not _expect(aggregate.get("accepted", false) and aggregate.get("value") is Dictionary and model.get("accepted", false) and model.get("value") is Dictionary and history.get("accepted", false) and history.get("value") is Dictionary, "public ExactJson decodes all three complete original native packets"): return false
	_cl_unit = aggregate.value
	_cl_model = model.value
	_cl_history = history.value
	for pair: Array in [["aggregate", _cl_unit], ["attempts", _cl_model], ["diagnostic", _cl_history]]:
		var original: String = FileAccess.get_file_as_string(CLEARED_ROOT + "earned-cleared/incomplete-actual." + String(pair[0]) + ".exact.json")
		if not _expect(PriorityJson.stringify(pair[1]) == original, "exact decode preserves original complete scalar bits/types: " + String(pair[0])): return false
	return true

func _cl_check_historical_closure() -> bool:
	var saved: Dictionary = _cl_unit
	var local: Dictionary = saved.level.local
	var seven: Array[String] = ["garden_handler", "flood_scout", "flood_tender", "villa_scout", "villa_ray_handler", "villa_tender", "villa_smoke_handler"]
	if not _expect(saved.level_id == "A2-L4" and saved.scene_path == LONDON_SCENE and saved.paused and saved.player.resources.hp == 90.0 and not saved.player.resources.dead and saved.equipment_ids == _loadout and local.profile_id == "standard" and local.sequence.stage_index == 6 and local.sequence.defeated_ids == seven and local.sequence.active_ids.is_empty() and local.sequence.crossed_contacts == ["road_entry", "villa_entry"] and not local.sequence.exit_open, "actual archived living stage6 retains seven earned defeats and no Putney contact"): return false
	_expect(saved.level.progress.checkpoint_id == "flood-margin-clear" and not saved.level.progress.completed and saved.level.progress.contact_exit_id.is_empty() and local.scheduler.reservations.is_empty(), "earned courtyard close adds no checkpoint/completion/exit or live lease")
	var checkpoint: Dictionary = _cl_model.story.checkpoint
	_expect(_cl_model.completed_main == LONDON_PREFIX and PriorityJson.stringify(_cl_model.story.snapshot) == PriorityJson.stringify(saved) and checkpoint.level.local.sequence.stage_index == 4 and checkpoint.level.local.sequence.defeated_ids == seven.slice(0, 3) and checkpoint.level.progress.checkpoint_id == "flood-margin-clear", "whole original Attempts protects actual earlier three-defeat stage4 checkpoint and prior TEST prefix")
	_expect(_cl_history.paused and _cl_history.aggregate_validation_error.is_empty() and _cl_history.campaign_error.is_empty() and float(_cl_history.encounter_state.clock_s) == float(local.scheduler.clock_s) and _cl_history.new_checkpoints.is_empty() and _cl_history.new_completions.is_empty() and _cl_history.new_exits.is_empty(), "historical producer diagnostic retains its actual clock and no new progression events")
	_cl_saved_selector = true
	var saved_expected: Array[String] = _pr_expected_defeats()
	_expect(saved_expected == ["villa_tender", "villa_smoke_handler"] and _cl_history.new_defeats == saved_expected, "corrected typed saved-boundary selector matches actual archived two-defeat delta, not replayed events")
	_cl_saved_selector = false
	var full_expected: Array[String] = _pr_expected_defeats()
	_expect(full_expected == seven.slice(3, 7), "corrected typed four-entry branch is pure TEST expectation configuration against historical courtyard prefix")
	_cl_saved_selector = true
	for id: String in ["flood_bank", "villa_bank"]:
		var bank: Dictionary = local.banks[id]
		_expect(bank.status == "complete" and bank.phase == "clear" and bank.reservation_id.is_empty() and float(bank.clock_s) == float(local.scheduler.clock_s) and float(bank.clock_s) > float(bank.exchange.recovery_until_s), "saved native bank is complete only past its original recovery deadline: " + id)
		var native: Dictionary = _cl_history.encounter_state.banks[id]
		_expect(native.status == "complete" and native.phase == "clear" and native.cycle == bank.cycle and native.reservation_id == bank.reservation_id and not PriorityJson.stringify(native.exchange).is_empty() and PriorityJson.stringify(native.exchange) == PriorityJson.stringify(bank.exchange) and PriorityJson.stringify(native.receipts) == PriorityJson.stringify(bank.receipts), "historical native complete bank retains the exact saved original exchange/deadlines/cycle/receipts: " + id)
	# Witness is archival diagnostic only; do not reconstruct fake proof paths or
	# call the collision predicate on JSON arrays and claim native route safety.
	_expect(_cl_history.replacement_spatially_clear_checks > 0 and not _cl_history.replacement_witnesses.is_empty(), "original native spatial witness remains archived; its combat attribution stays with failed producer")
	return _failures == 0

func _cl_install_original() -> bool:
	var raw: Dictionary = JSON.parse_string(_canonical)
	for info: Dictionary in raw.levels:
		if info.id in ["A2-L4", "A2-L5"]:
			info.scene_path = LONDON_SCENE if info.id == "A2-L4" else LONDON_DESTINATION
			info.readiness = "accepted"; info.accepted_commit = "b".repeat(40); info.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(raw)
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var store: CinderSaveStore = Store.new(CLOSURE_ROOT + "campaign.json")
	store.payload_validator = model.saved_payload_error
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A2-L5").is_empty() and model.state_error(_cl_model).is_empty() and store.write_payload(_cl_model), "public isolated Registry/SaveStore writes untouched complete earned model: " + store.last_error): return false
	var loaded: Dictionary = store.read_payload()
	if not _expect(store.last_error.is_empty() and not store.loaded_backup and PriorityJson.stringify(loaded) == PriorityJson.stringify(_cl_model), "public SaveStore reads the exact complete original model"): return false
	_game = Shell.new() as CinderCampaignShell
	if not _expect(_game.configure_runtime(raw, CLOSURE_ROOT + "campaign.json", CLOSURE_ROOT + "settings.json", CLOSURE_ROOT + "preferences.json"), "fresh actual Shell owns separate isolated closure paths"): return false
	_cl_events.clear(); _cl_watch = true
	root.add_child(_game)
	await _pr_settle()
	if not _expect(paused and _game.campaign_error.is_empty() and _game.menu.page_name() == "title" and _cl_events.is_empty() and _cl_retirements_exact(), "real fresh Shell loads genuine earned model at Title; only exact pristine validation candidates retire"): return false
	if not await _pr_click("ContinueStoryButton"): return false
	var actual: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(paused and _game.menu.page_name() == "resume" and _game.campaign_error.is_empty() and PriorityJson.stringify(actual) == PriorityJson.stringify(_cl_unit) and PriorityJson.stringify(_game.attempts.state()) == PriorityJson.stringify(_cl_model) and _cl_events.is_empty() and _cl_retirements_exact(), "actual GUI Continue quietly restores exact native Player/level/shell/history/resources: " + str(_cl_events)): return false
	_expect(_game.player.snapshot_error(actual.player).is_empty() and _game.active_level.snapshot_error_with_player(actual.level, actual.player).is_empty(), "fresh actual original stage6 passes complete saved-player/native level preflight")
	_expect(_state().beat == "putney_entry" and not _game.active_level.is_completed() and _game.player.get_world_action_records().size() == _cl_unit.player.world_actions.history.size(), "quiet receiver remains at actual courtyard boundary without manufacturing action or completion")
	return _failures == 0

func _cl_observe_added(node: Node) -> void:
	if node is CinderPlayer:
		node.world_action_executed.connect(func(_record: Dictionary) -> void: _cl_note("player-action"))
		node.fired.connect(func(_kind: String) -> void: _cl_note("player-fired"))
		node.action_resolved.connect(func(_kind: String, _hits: int, _damage: float) -> void: _cl_note("player-damage-action"))
		node.died.connect(func() -> void: _cl_note("player-death"))
		node.equipment_changed.connect(func(_id: String) -> void: _cl_note("player-gear"))
	elif node is CinderLevel:
		node.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: _cl_note("checkpoint"))
		node.completion_requested.connect(func(_id: String, _completion: String) -> void: _cl_note("completion"))
		node.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _cl_note("exit"))
	elif node.get_script() == RayExchange:
		node.connect("state_changed", func(id: String, state: Dictionary) -> void:
			if _cl_watch and _cl_pristine_ray_retirement(node, id, state):
				_cl_pristine_retirements.append({"node_id": node.get_instance_id(), "actor_id": id, "path": String(node.get_path())})
			else: _cl_note("ray-state:" + id))
		node.connect("hit_resolved", func(_id: String, _result: Dictionary) -> void: _cl_note("ray-hit"))
	elif node is CinderLaneMechanism:
		node.state_changed.connect(func(_state: Dictionary) -> void: _cl_note("tool-state"))
		node.hit_resolved.connect(func(_id: String, _cycle: int, _result: Dictionary) -> void: _cl_note("tool-hit"))
	elif node is CinderSmokeBank:
		node.state_changed.connect(func(_state: Dictionary) -> void: _cl_note("bank-state"))
		node.tick_resolved.connect(func(_id: String, _cycle: int, _result: Dictionary) -> void: _cl_note("bank-tick"))
	elif node is CinderThreatCue or node is CinderInteractionCue:
		node.state_changed.connect(func(_state: Dictionary) -> void: _cl_note("cue-state"))
	if node.has_signal("defeated"): node.connect("defeated", func(_id: String) -> void: _cl_note("target-defeat"))

func _cl_pristine_ray_retirement(driver: Node, id: String, state: Dictionary) -> bool:
	# TEST observation only: normal cleanup publishes each initial cycle0 record.
	# Count only the exact never-installed candidate exit, never a saved epoch.
	if not LondonSequence.RAYS.has(id) or not is_instance_valid(_game) or not is_instance_valid(driver) or driver.get_script() != RayExchange: return false
	var level: CinderLevel = driver.get_parent() as CinderLevel
	if not is_instance_valid(level) or not _game.is_ancestor_of(level) or level == _game.active_level or level.level_id != "A2-L4" or level.scene_file_path != LONDON_SCENE or not level.is_restore_candidate() or level.shared_shell != _game or level.get("_entered") != false or level.get("_lifecycle_busy") != true or level.get("_restore_candidate_ready") != false: return false
	for flag: String in ["_restoring", "_snapshotting", "_validating"]:
		if level.get(flag) != false: return false
	if driver.get("_configured") != true or driver.get("_retired") != false or driver.get("_snapshot_busy") != false or driver.get("_cancelling") != true or driver.get("_transaction_depth") != 1: return false
	if state.get("actor_id") != id or state.get("status") != "idle" or state.get("phase") != "clear" or state.get("cycle") != 0 or state.get("armed") != false or state.get("remaining_s") != 0.0 or state.get("reservation_id") != "" or state.get("hit_consumed") != false or state.get("last_cancel_reason") != "" or state.get("proof_available") != false or state.get("direction") != Vector3.BACK or state.get("source_position") != LondonSequence.ACTORS[id]: return false
	for key: String in ["exchange", "geometry", "proof", "presentation_witness"]:
		if not state.get(key) is Dictionary or not state[key].is_empty(): return false
	var records: Variant = driver.get("_records")
	var actors: Variant = driver.get("_actors")
	if not records is Dictionary or records.size() != 3 or not actors is Dictionary or actors.size() != 3: return false
	for ray: String in LondonSequence.RAYS:
		if not records.get(ray) is Dictionary: return false
		var record: Dictionary = records[ray]
		for key: String in ["exchange", "context", "sample", "presentation_witness"]:
			if not record.get(key) is Dictionary or not record[key].is_empty(): return false
		if record.get("cycle") != 0 or record.get("status") != "idle" or record.get("phase") != "clear" or record.get("deferred_paths") != [] or record.get("hit_consumed") != false or record.get("observed_hp") != 30.0 or record.get("flash_until_s") != 0.0 or record.get("direction") != Vector3.BACK: return false
		var actor: Variant = actors.get(ray)
		if not is_instance_valid(actor) or not actor is Node3D or not actor.is_inside_tree() or actor.is_queued_for_deletion() or actor.get("actor_id") != ray or actor.get("hp") != 30.0 or actor.get("max_hp") != 30.0 or actor.get("phase") != "idle" or actor.get("phase_progress") != 0.0 or actor.global_position != LondonSequence.ACTORS[ray]: return false
	var all_actors: Variant = level.get("_actors")
	if not all_actors is Dictionary or all_actors.size() != LondonSequence.ACTORS.size(): return false
	for target: String in LondonSequence.ACTORS:
		var actor: Variant = all_actors.get(target)
		if not is_instance_valid(actor) or not actor is Node3D or actor.get("hp") != 30.0 or actor.get("max_hp") != 30.0 or actor.global_position != LondonSequence.ACTORS[target]: return false
	var shared_hero: Variant = driver.get("_hero")
	var scheduler: Variant = driver.get("_scheduler")
	if not is_instance_valid(shared_hero) or shared_hero != level.hero or shared_hero.dead or shared_hero.get_world_action_clock() != 0.0 or not shared_hero.get_world_action_records().is_empty() or shared_hero.global_position != level.spawn_position(): return false
	if not is_instance_valid(scheduler) or scheduler != level.get("_scheduler") or scheduler.get_clock() != 0.0: return false
	var sequence: Variant = level.get("_crossing")
	if not is_instance_valid(sequence) or sequence.get("stage_index") != 0 or sequence.get("defeated_ids") != [] or sequence.get("crossed_contacts") != [] or level.get("_last_action_sequence") != 0 or level.get("_scenic_clock") != 0.0 or level.is_completed() or level.current_checkpoint() != {"id": "", "kind": ""}: return false
	var key: String = str(driver.get_instance_id()) + "/" + id
	if _cl_pristine_seen.has(key) or _cl_pristine_seen.size() >= 12: return false
	_cl_pristine_seen[key] = true
	return true

func _cl_retirements_exact() -> bool:
	# Current pinned Shell validates snapshot+checkpoint during both semantic
	# disk read and restore_session: four distinct pristine drivers, three Rays.
	if _cl_pristine_retirements.size() != 12: return false
	var drivers: Dictionary = {}
	for entry: Dictionary in _cl_pristine_retirements:
		var key: String = str(entry.node_id)
		if not drivers.has(key): drivers[key] = []
		drivers[key].append(entry.actor_id)
	if drivers.size() != 4: return false
	for ids: Array in drivers.values():
		if ids.size() != 3: return false
		for id: String in LondonSequence.RAYS:
			if ids.count(id) != 1: return false
	return true

func _cl_note(event: String) -> void:
	if _cl_watch: _cl_events.append(event)

func _cl_close_whole_shell() -> void:
	_cl_watch = false
	var refs: Array[Dictionary] = []
	var pending: Array[Node] = [_game]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		refs.append({"label": String(node.get_path()) if node.is_inside_tree() else String(node.name), "ref": weakref(node)})
		pending.append_array(node.get_children())
	# Direct whole Shell removal, preserving the removed-tree teardown path.
	_game.queue_free()
	_game = null
	await _pr_settle()
	for entry: Dictionary in refs: _expect((entry.ref as WeakRef).get_ref() == null, "direct old whole Shell/native body/scenery/cue closure: " + String(entry.label))
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "direct quiet Shell closure retires all native source/cue groups")

func _cl_cleanup_paths() -> void:
	for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CLOSURE_ROOT + name))
