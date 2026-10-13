extends "res://tests/acts/act3/twin_suns_level_smoke.gd"
## TEST ONLY production-shell consumer of the unchanged actual full-route driver.
## Accepted L1/L2 and ten predecessor completions exist only in memory. The next
## scene inherits the existing shared test floor/guard, with only its ID changed.
## No canonical acceptance, authored L2 content, native input or human review.
## No HP/source poses/leases/clocks are written. Only public ammo is depleted.
## --assisted: actual menu/store preference, then public predecessor-floor exit
## creates a genuinely fresh Assisted L1. Preparing budget1 replaces required
## crossing-union coverage; actual recovery overlap remains fully monitored.

const ProductionShell = preload("res://scripts/campaign/shell.gd")
const ProductionRegistry = preload("res://scripts/campaign/registry.gd")
const ProductionStore = preload("res://scripts/campaign/save_store.gd")
const ProfileCatalogue = preload("res://scripts/combat/difficulty.gd")
const NextFixturePath: String = "res://tests/acts/act3/fixtures/twin_suns_transition_l2.tscn"
const PredecessorFixturePath: String = "res://tests/acts/act3/fixtures/twin_suns_assisted_predecessor.tscn"

var _shell: CinderCampaignShell
var _test_root: String = ""
var _canonical_bytes: String = ""
var _prefix: Array[String] = []
var _restore_events: Array[String] = []
var _watch_restore: bool = false
var _completed_state: Dictionary = {}
var _departure_actor: Dictionary = {}
var _departure_anchor: Vector2 = Vector2.ZERO
var _contact_state: Dictionary = {}
var _contact_supported: bool = false
var _departed_refs: Array = []
var _transition_seen: bool = false
var _active_pause_done: bool = false
var _profile_id: String = "standard"
var _expected_profile: Dictionary = {}
var _expected_roles: Dictionary = {}
var _maximum_preparing: int = 0
var _preparing_sources: Dictionary = {}


func _initialize() -> void:
	_ensure_owned_test_uids()
	super._initialize()


func _ensure_owned_test_uids() -> void:
	for path: String in ["res://tests/acts/act3/twin_suns_production_transition_smoke.gd.uid", "res://tests/acts/act3/stalker_framing_guard_smoke.gd.uid"]:
		if FileAccess.file_exists(path):
			continue
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if not _expect(file != null, "first meaningful production run creates only missing owned test UID: " + path):
			continue
		file.store_line(ResourceUID.id_to_text(ResourceUID.create_id()))
		file.close()


func _options() -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--assisted" and _profile_id == "standard":
			_profile_id = "assisted"
		else:
			return "unsupported or repeated production fixture selector: " + argument
	return ""


func _requires_crossing_union() -> bool:
	return _profile_id != "assisted"


func _prepare() -> String:
	_test_root = "user://test-act3-production-transition-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	_canonical_bytes = FileAccess.get_file_as_string(ProductionRegistry.DATA_PATH)
	var canonical: Variant = JSON.parse_string(_canonical_bytes)
	if not canonical is Dictionary:
		return "canonical registry cannot be read"
	var initial: Dictionary = {}
	if _profile_id == "assisted":
		initial = await _initial_predecessor_seed()
	else:
		initial = await _initial_production_seed()
	if initial.is_empty():
		return "actual paused full-route initial seed is unavailable"
	var raw: Dictionary = canonical.duplicate(true)
	for info: Dictionary in raw.levels:
		if info.id in ["A3-L1", "A3-L2"] or (_profile_id == "assisted" and info.id == "A2-L5"):
			info.scene_path = PredecessorFixturePath if info.id == "A2-L5" else (FullPath if info.id == "A3-L1" else NextFixturePath)
			info.readiness = "accepted" # TEST ONLY, no registry file write.
			info.accepted_commit = "a".repeat(40)
			info.api_revision = ProductionRegistry.API_REVISION
	_shell = ProductionShell.new()
	_game = _shell
	if not _shell.configure_runtime(raw, _test_root + "campaign.json", _test_root + "settings.json", _test_root + "preferences.json"):
		return "isolated production shell configuration rejected"
	root.add_child(_shell)
	await _settle_shell()
	for id: String in _shell.registry.main_route():
		if id == "A3-L1":
			break
		_prefix.append(id)
	if _prefix.size() != 10 or not _shell.registry.scene_error("A3-L2").is_empty():
		return "test-only next floor fails the actual registry identity/root contract"
	var session: Dictionary = _shell.attempts.state()
	session.completed_main = _prefix.duplicate() # TEST ONLY predecessor seed.
	session.story = {"kind": "story", "level_id": "A2-L5" if _profile_id == "assisted" else "A3-L1", "snapshot": initial.duplicate(true), "checkpoint": initial.duplicate(true)}
	if not _shell.attempts.restore_session(session):
		return "public initial session proof rejected: " + _shell.attempts.last_error
	_shell.resume_campaign()
	await _settle_shell()
	if _profile_id == "assisted":
		initial = await _enter_fresh_assisted(initial)
		if initial.is_empty():
			return "actual public predecessor transition did not create a fresh Assisted L1: " + _shell.campaign_error
	_hero = _shell.player
	_level = _shell.active_level
	if not _shell.campaign_error.is_empty() or not paused or _shell.menu.page_name() != "resume" or not is_instance_valid(_level) or _level.scene_file_path != FullPath or _level.get_script().resource_path != RuntimePath or not _level.contract_error().is_empty() or _level.shared_shell != _shell:
		return "actual production authored world failed to enter paused: " + _shell.campaign_error
	var error: String = _bind_runtime()
	if not error.is_empty():
		return error
	_hp_before = _hero.hp
	_topology = _world_topology()
	if not _exact(_shell.capture_campaign_snapshot(), initial):
		return "actual shell initial install differs from the independently valid full5 seed"
	if not _resume_consumed("initial production entry"):
		return "actual initial Resume input leaked"
	_route_deadline = _scheduler.get_clock() + RouteBudgetS
	# One real routed left swipe makes anchor carryover nontrivial and joins
	# the same west corridor used by the original actual route driver.
	return await _routed_initial_dash()


func _initial_predecessor_seed() -> Dictionary:
	# This is only the existing TEST ONLY floor/guard with a predecessor ID.
	# No authored A3 unit is created, edited or retuned by this seed helper.
	paused = false
	var preview: Node = MainScene.instantiate()
	preview.set("level_scene_path", PredecessorFixturePath)
	root.add_child(preview)
	preview.call("resume_lab")
	for _tick: int in range(12):
		await physics_frame
		await process_frame
	preview.call("open_bench")
	await _settle_shell()
	var actor: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var result: Dictionary = {}
	if is_instance_valid(actor) and is_instance_valid(level) and level.level_id == "A2-L5" and level.scene_file_path == PredecessorFixturePath and _exact(actor.equipment.snapshot(), _kit) and _exact(actor.stats, _stats):
		actor.shells = 0
		var player_state: Dictionary = actor.snapshot_state()
		var level_state: Dictionary = level.snapshot_state()
		if not player_state.is_empty() and not level_state.is_empty() and not level.is_completed():
			var fresh_shell: Dictionary = {"api_revision": ProductionShell.SHELL_API, "anchor_normalized": [0.5, 0.5], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(actor.global_position + Vector3.UP * 0.75), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}
			result = {"schema_version": 1, "level_id": "A2-L5", "scene_path": PredecessorFixturePath, "paused": true, "equipment_ids": actor.equipment.snapshot(), "player": player_state, "level": level_state, "shell": fresh_shell}
	preview.free()
	paused = false
	await _settle_shell()
	return result


func _enter_fresh_assisted(predecessor: Dictionary) -> Dictionary:
	if not _expect(paused and _shell.campaign_error.is_empty() and is_instance_valid(_shell.active_level) and _shell.active_level.level_id == "A2-L5" and _shell.active_level.scene_file_path == PredecessorFixturePath and _exact(_shell.capture_campaign_snapshot(), predecessor), "Assisted setup loads only the actual TEST ONLY predecessor floor with the declared prefix10"):
		return {}
	var before: Dictionary = _shell.capture_campaign_snapshot()
	_shell.menu.show_settings()
	var selector: OptionButton = _shell.menu.find_child("DifficultySelector", true, false) as OptionButton
	if not is_instance_valid(selector):
		_expect(false, "actual menu exposes its fresh-encounter difficulty selector")
		return {}
	var assisted_index: int = -1
	for index: int in range(selector.item_count):
		if selector.get_item_metadata(index) == "assisted":
			assisted_index = index
	if assisted_index < 0:
		_expect(false, "actual menu selector retains the canonical Assisted option")
		return {}
	selector.select(assisted_index)
	selector.item_selected.emit(assisted_index)
	var preferences = ProductionStore.new(_test_root + "preferences.json")
	var stored: Dictionary = preferences.read_payload()
	if not _expect(_shell.get_difficulty_preference() == "assisted" and preferences.last_error.is_empty() and not preferences.loaded_backup and _exact(stored, {"schema_version": 1, "profile_id": "assisted"}) and _exact(_shell.capture_campaign_snapshot(), before), "actual menu stores Assisted through the production preference API without retuning the paused current unit", preferences.last_error):
		return {}
	var old_refs: Array = [_shell.player, _shell.active_level, _shell.world, _shell.active_level.get("guard")]
	# These public progression requests concern only this fixture floor. The
	# prefix already records its historical clear; no A3 completion is seeded.
	if not _shell.active_level.request_completion("test-only-predecessor-clear"):
		_expect(false, "test-only predecessor accepts its public completion request")
		return {}
	await _settle_shell()
	if not _expect(_shell.campaign_error.is_empty() and paused and _shell.active_level.is_completed() and _shell.attempts.state().completed_main == _prefix, "fixture predecessor completion retains the exact ten-level prefix", _shell.campaign_error):
		return {}
	if not _shell.active_level.request_contact_exit("test-only-assisted-entry", _shell.player):
		_expect(false, "test-only predecessor accepts its public contact transition")
		return {}
	await _settle_shell()
	var fresh: Dictionary = _shell.capture_campaign_snapshot()
	if not _expect(_shell.campaign_error.is_empty() and paused and not fresh.is_empty() and fresh.level_id == "A3-L1" and fresh.scene_path == FullPath and fresh.shell.difficulty_at_entry == "assisted" and fresh.player.world_actions.clock_s == 0.0 and fresh.player.world_actions.history.is_empty() and fresh.player.world_actions.pending_dash.is_empty() and fresh.level.local.scheduler.clock_s == 0.0 and fresh.level.local.scenery.sun_elapsed_s == 0.0 and fresh.level.local.route.entries.is_empty() and fresh.level.local.route.deaths.is_empty() and _shell.attempts.state().completed_main == _prefix, "public production predecessor exit creates an actual fresh Assisted A3-L1 with zero clocks/history and prefix10", _shell.campaign_error):
		return {}
	for old: Variant in old_refs:
		if is_instance_valid(old):
			_expect(false, "fresh Assisted entry retires the actual fixture predecessor world/hero/guard")
			return {}
	var reader = ProductionStore.new(_test_root + "campaign.json")
	var disk: Dictionary = reader.read_payload()
	var durable: Dictionary = _shell.attempts.state()
	if not _expect(reader.last_error.is_empty() and _exact(disk, durable) and _exact(durable.story.snapshot, fresh) and _exact(durable.story.checkpoint, fresh) and get_nodes_in_group("enemies").size() == SourceIds.size(), "fresh Assisted unit is durably captured by the real shell with only its five actual actors alive", reader.last_error):
		return {}
	return fresh


func _initial_production_seed() -> Dictionary:
	paused = false
	var preview: Node = MainScene.instantiate()
	preview.set("level_scene_path", FullPath)
	root.add_child(preview)
	preview.call("resume_lab")
	for _tick: int in range(12):
		await physics_frame
		await process_frame
	preview.call("open_bench")
	await _settle_shell()
	var actor: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	var result: Dictionary = {}
	if is_instance_valid(actor) and is_instance_valid(level) and _exact(actor.equipment.snapshot(), _kit) and _exact(actor.stats, _stats):
		actor.shells = 0 # Public no-blast fixture; no HP or reload clock write.
		var player_state: Dictionary = actor.snapshot_state()
		var level_state: Dictionary = level.snapshot_state()
		if not player_state.is_empty() and not level_state.is_empty() and level_state.local_snapshot_version == 5 and (level.call("state") as Dictionary).entered.is_empty():
			# Only fresh shell metadata is fixture-declared. All later anchors,
			# input/camera records and checkpoints come from the actual shell.
			var fresh_shell: Dictionary = {"api_revision": ProductionShell.SHELL_API, "anchor_normalized": [0.5, 0.5], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(actor.global_position + Vector3.UP * 0.75), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}
			result = {"schema_version": 1, "level_id": "A3-L1", "scene_path": FullPath, "paused": true, "equipment_ids": actor.equipment.snapshot(), "player": player_state, "level": level_state, "shell": fresh_shell}
	preview.free()
	paused = false
	await _settle_shell()
	return result


## Production retry restores the real dead retained body before this bind.
## Retain the original driver's identities/geometry/observers, allowing genuine
## tombstones as well as living sources. No substitute actor enters the driver.
func _bind_runtime() -> String:
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	var public_sources: Variant = _level.get("sources")
	if _scheduler == null or not public_sources is Dictionary or not Codec.keys_error(public_sources, SourceIds).is_empty():
		return "actual exact five-source scheduler binding is unavailable"
	var catalogue = ProfileCatalogue.new()
	_expected_profile = catalogue.profile(_profile_id)
	if _expected_profile.is_empty() or not _exact(_scheduler.encounter_profile(), _expected_profile):
		return "actual fresh scheduler profile differs from the canonical selected profile: " + _profile_id
	_sources = public_sources.duplicate()
	var scenery: Node = _level.get("scenery") as Node
	_floor = scenery.get("floor_body") as StaticBody3D if scenery != null else null
	_motifs = _level.find_child("ScenicSuns", true, false) as Node3D
	_exit_cue = _level.get("exit_cue") as CinderInteractionCue
	if _floor == null or _motifs == null or _exit_cue == null or _hero.presentation_id != "act3_traveller" or not _exact(_hero.equipment.snapshot(), _kit) or not _exact(_hero.stats, _stats):
		return "actual floor/traveller/cues/equipment differ"
	var solid: CollisionShape3D = _floor.get_node_or_null("Solid") as CollisionShape3D
	if solid == null or not solid.shape is BoxShape3D or (solid.shape as BoxShape3D).size != Vector3(14, 1, 108):
		return "actual full route lacks the unchanged continuous floor"
	for id: String in SourceIds:
		var source: CinderAct3SunboundStalker = _sources[id] as CinderAct3SunboundStalker
		if not is_instance_valid(source) or source.get_world_3d() != _hero.get_world_3d() or source.state().stable_id != id or source.is_in_group("enemies") == source.dead:
			return "real living/tombstone stable source binding differs: " + id
		var native: Dictionary = source.snapshot_state()
		if native.is_empty() or native.api_revision != "act3-stalker-snapshot-3" or native.schema_version != 3:
			return "actual source3 snapshot is unavailable: " + id + "; " + source.last_snapshot_error
		var resolved: Dictionary = catalogue.resolve_role(native.raw_role, _profile_id, native.timing_floors)
		if resolved.is_empty() or not _exact(native.resolved_role, resolved) or native.max_hp != resolved.max_hp:
			return "actual actor did not resolve immutable authored raw role exactly once under " + _profile_id + ": " + id + "; " + catalogue.last_error
		_expected_roles[id] = resolved
		_expected_hp[id] = source.hp
		source.state_changed.connect(_on_source_state.bind(id))
		source.hit_resolved.connect(_on_contact.bind(id))
		source.died.connect(_on_death.bind(id))
		source.get_cue().state_changed.connect(func(_value: Dictionary) -> void: _event("cue"))
	_scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: _event("cancel"))
	_hero.world_action_executed.connect(_on_action)
	_hero.fired.connect(func(kind: String) -> void: _event("fired_" + kind))
	_hero.action_resolved.connect(func(kind: String, _hits: int, _damage: float) -> void: _event("resolved_" + kind))
	_hero.equipment_changed.connect(func(_id: String) -> void: _event("equipment"))
	_hero.died.connect(func() -> void: _event("hero_death"))
	_level.checkpoint_requested.connect(_on_checkpoint)
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _event("completion"))
	_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _event("exit"))
	_exit_cue.state_changed.connect(func(_state: Dictionary) -> void: _event("exit_cue"))
	return ""


func _live_error() -> String:
	var error: String = super._live_error()
	if not error.is_empty():
		return error
	if not _exact(_scheduler.encounter_profile(), _expected_profile):
		return "live scheduler profile changed during the actual " + _profile_id + " attempt"
	for id: String in SourceIds:
		var state: Dictionary = _sources[id].state()
		if not _exact(state.resolved_role, _expected_roles[id]):
			return "actual source role retuned during the current attempt: " + id
	var preparing: int = 0
	var clock: float = _scheduler.get_clock()
	for record: Dictionary in _scheduler.reservations():
		# Match the published native admission predicate, including its exact
		# active_until boundary. Recovery after that deadline retains a lease
		# and opening, but does not consume preparing/active budget.
		if float(record.active_until_s) >= clock:
			preparing += 1
			var source_id: String = _source_for_record(record)
			if source_id.is_empty():
				return "preparing budget contains a reservation from another actor"
			_preparing_sources[source_id] = true
	_maximum_preparing = maxi(_maximum_preparing, preparing)
	if preparing > int(_expected_profile.reserved_threat_budget):
		return "actual preparing/active deadline count exceeds profile budget: count=%d budget=%d clock=%.9f" % [preparing, int(_expected_profile.reserved_threat_budget), clock]
	return ""


func _pause_pair(label: String, deplete_ammo: bool = false) -> Dictionary:
	if deplete_ammo:
		_hero.shells = 0
	_shell.request_pause()
	await _settle_shell()
	var unit: Dictionary = _shell.capture_campaign_snapshot()
	if not _expect(paused and _shell.campaign_error.is_empty() and not unit.is_empty() and unit.level.local_snapshot_version == 5, label + ": production deferred pause captures the full5 native unit", _shell.campaign_error):
		return {}
	var pair: Dictionary = {"hero": unit.player, "level": unit.level}
	var encoded: String = ExactJson.stringify(pair)
	var decoded: Dictionary = ExactJson.parse(encoded)
	if not _expect(not encoded.is_empty() and decoded.get("accepted") == true and decoded.get("value") is Dictionary and Codec.value_error(decoded.value).is_empty() and _exact(pair, decoded.value), label + ": exact transport retains every actual scalar type/bit and all five actors"):
		return {}
	if not _exact(_shell.attempts.state().story.snapshot, unit):
		return {}
	await create_timer(0.08, true).timeout
	if not _expect(_exact(_shell.capture_campaign_snapshot(), unit), label + ": living pause freezes source/scheduler/sun/hero/input/camera exactly"):
		return {}
	return decoded.value


func _moving_retry() -> String:
	# The shell camera is a separate whole-unit component. A local mechanical
	# rewind cannot restore it. Production proves an actual active living pause
	# here, then uses the protected whole-unit request_retry below for restore.
	var pair: Dictionary = await _pause_pair("actual production moving-active full5 pair", true)
	if pair.is_empty():
		return "actual production moving-active full5 pause/transport failed"
	var source: CharacterBody3D = _sources[_source_id]
	if pair.level.local.sources[_source_id].phase != "active" or source.velocity.is_zero_approx() or _hero.shells != 0:
		return "production living pause lacks a genuine moving active source and depleted ammo"
	var error: String = _pure_pair_error(pair)
	if error.is_empty():
		error = _forgeries(pair)
	if not error.is_empty():
		return error
	if not _resume_consumed("actual active living pause"):
		return "actual active-pause Resume input leaked"
	# This inherited flag schedules the original driver's one-time probe;
	# this derived fixture's evidence is separately named active_pause_done.
	_roundtrip_done = true
	error = await _tick_safe()
	if not error.is_empty():
		return error
	if _scheduler.get_clock() <= float(pair.level.local.scheduler.clock_s) or float(_level.get("sun_elapsed_s")) == float(pair.level.local.scenery.sun_elapsed_s):
		return "real resumed scheduler and public sun did not advance from the exact living pause"
	_active_pause_done = true
	_expect(true, "actual moving-active production pause retains exact full5 transport/pure forged-unit rejection and consumes Resume before real scheduler/sun clocks advance")
	return ""


func _fresh_partial_retry(pair: Dictionary) -> String:
	var saved: Dictionary = _shell.attempts.state().story.checkpoint.duplicate(true)
	if not paused or pair.level.local.route.deaths.size() != 1 or saved.level.progress.checkpoint_id != CheckpointIds[1] or saved.level.local.route.entries.size() != 2 or saved.level.local.route.deaths.size() != 1 or not saved.level.local.sources[SourceIds[0]].dead or not saved.level.local.scheduler.reservations.is_empty() or saved.player.world_actions.pending_dash.is_empty():
		return "production fresh partial retry lacks the real protected second-entry in-flight checkpoint and first tombstone"
	var reader = ProductionStore.new(_test_root + "campaign.json")
	var disk: Dictionary = reader.read_payload()
	if not reader.last_error.is_empty() or disk.is_empty() or not _exact(disk.story.checkpoint, saved):
		return "real SaveStore protected second-entry checkpoint differs: " + reader.last_error
	var old_refs: Array = [_hero, _level, _scheduler, _shell.world]
	old_refs.append_array(_sources.values())
	var events: Dictionary = _events.duplicate(true)
	_restore_events.clear()
	_watch_restore = true
	node_added.connect(_observe_candidate)
	_shell.request_retry()
	await _settle_shell()
	_watch_restore = false
	node_added.disconnect(_observe_candidate)
	if not _shell.campaign_error.is_empty() or not paused or _shell.menu.page_name() != "resume" or not _exact(_shell.capture_campaign_snapshot(), saved) or not _restore_events.is_empty() or not _exact(_events, events):
		return "public production retry did not silently install the exact protected unit: " + _shell.campaign_error + "; " + str(_restore_events)
	for old: Variant in old_refs:
		if is_instance_valid(old):
			return "public production retry retained an old world/player/scheduler/source"
	_hero = _shell.player
	_level = _shell.active_level
	var error: String = _bind_runtime()
	if not error.is_empty():
		return error
	_topology = _world_topology()
	error = _tombstone_error(SourceIds[0])
	if not error.is_empty():
		return error
	# Rebase this test observer to the real restored public history. The saved
	# checkpoint precedes the original entry dash completion; resumed physics
	# must publish that saved pending action once.
	_actions = _hero.get_world_action_records()
	await create_timer(0.08, true).timeout
	if not _exact(_shell.capture_campaign_snapshot(), saved):
		return "actual fresh checkpoint advances while its Resume overlay is paused"
	if not _resume_consumed("protected second-entry retry"):
		return "actual checkpoint Resume input leaked"
	var sequence: int = int(saved.player.world_actions.sequence)
	var stop: float = _hero.get_world_action_clock() + maxf(0.12, float(saved.player.clocks.dash_left_s) + _tick_s())
	for _tick: int in range(_frame_limit(0.5)):
		if _hero.get_world_action_clock() >= stop:
			break
		error = await _tick_safe()
		if not error.is_empty():
			return error
	var finished: Array[Dictionary] = _hero.get_world_action_records(sequence)
	if _hero.get_world_action_clock() < stop or finished.size() != 1 or finished[0].kind != "dash" or float(finished[0].started_at_s) != float(saved.player.world_actions.pending_dash.started_at_s) or float(_level.get("sun_elapsed_s")) <= float(saved.level.local.scenery.sun_elapsed_s):
		return "production resume failed to advance the restored sun and finish only its saved entry dash"
	if not _exact(_shell.attempts.state().story.checkpoint, saved) or not _exact(_checkpoints, CheckpointIds.slice(0, 2)):
		return "actual fresh retry replaces or reemits a protected entry checkpoint"
	_fresh_partial_done = true
	_expect(true, "actual public production retry uses the durable second-entry checkpoint, retains its true tombstone, frees the old world and resumes only the saved dash/sun clocks")
	return ""


func _observe_candidate(node: Node) -> void:
	if not _watch_restore:
		return
	if node is CinderPlayer:
		var actor: CinderPlayer = node as CinderPlayer
		actor.fired.connect(func(_kind: String) -> void: _restore_events.append("fired"))
		actor.died.connect(func() -> void: _restore_events.append("hero_death"))
		actor.equipment_changed.connect(func(_id: String) -> void: _restore_events.append("equipment"))
		actor.action_resolved.connect(func(_kind: String, _hits: int, _damage: float) -> void: _restore_events.append("action"))
		actor.world_action_executed.connect(func(_record: Dictionary) -> void: _restore_events.append("world_action"))
	if node is CinderLevel:
		var level: CinderLevel = node as CinderLevel
		level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _boundary: String) -> void: _restore_events.append("checkpoint"))
		level.completion_requested.connect(func(_id: String, _completion: String) -> void: _restore_events.append("completion"))
		level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _restore_events.append("exit"))
	if node is CinderAct3SunboundStalker:
		var source: CinderAct3SunboundStalker = node as CinderAct3SunboundStalker
		source.died.connect(func(_where: Vector3) -> void: _restore_events.append("source_death"))
		source.hit_resolved.connect(func(_result: Dictionary) -> void: _restore_events.append("source_contact"))


func _contact_exit() -> String:
	if not _level.is_completed() or int(_events.get("completion", 0)) != 1 or (_level.call("state") as Dictionary).exit_state != "available" or not _scheduler.reservations().is_empty() or _exit_cue.state().get("trigger") != "contact" or _exit_cue.state().get("state") != "available":
		return "actual five deaths did not leave one completed full route and available contact cue"
	var error: String = await _corridor()
	if error.is_empty():
		error = await _travel_z(-40.0)
	if not error.is_empty():
		return error
	var pair: Dictionary = await _pause_pair("actual completed production route before contact", true)
	if pair.is_empty():
		return "completed actual route cannot be persisted before contact"
	_completed_state = _level.call("state")
	var completed: Array[String] = _prefix.duplicate()
	completed.append("A3-L1")
	var durable: Dictionary = _shell.attempts.state()
	var reader = ProductionStore.new(_test_root + "campaign.json")
	var disk: Dictionary = reader.read_payload()
	if not _expect(durable.completed_main == completed and completed.size() == 11 and durable.completed_optional.is_empty() and durable.reward_ids.is_empty() and _exact(disk, durable) and reader.last_error.is_empty() and pair.level.progress.completed and _completed_state.cleared.size() == 5 and _completed_state.entered.size() == 4 and _checkpoints.size() == 4, "five real ordinary-primary deaths durably complete exactly the eleven-level main prefix before contact", reader.last_error):
		return "actual main completion or independent durable payload differs"
	for id: String in SourceIds:
		error = _tombstone_error(id)
		if not error.is_empty():
			return error
	var history: Array[Dictionary] = _hero.get_world_action_records()
	if _actions.is_empty() or not _exact(_actions.slice(maxi(0, _actions.size() - history.size())), history):
		return "actual executed route history differs before contact retirement"
	for action: Dictionary in _actions:
		if action.get("kind") not in ["dash", "primary"] or not _exact(action.get("equipment_ids"), _kit):
			return "actual route used an unsupported action or changed gear"
	_departed_refs = [_hero, _level, _scheduler, _shell.world]
	_departed_refs.append_array(_sources.values())
	_level.contact_exit_requested.connect(_observe_real_contact)
	_shell.resume_campaign()
	var marker: Marker3D = _level.get_node("PoolingdredThreshold") as Marker3D
	for _attempt: int in range(8):
		error = await _ready_dash()
		if not error.is_empty():
			return error
		var actor: CinderPlayer = _hero
		var source_world: CinderLevel = _level
		var direction: Vector3 = _planar(marker.global_position - actor.global_position).normalized()
		var sequence: int = _last_sequence()
		if direction.is_zero_approx() or not actor.request_dash(direction):
			return "actual ready contact-approach dash rejected"
		# Genuine contact can retire this actor before its pending dash ends.
		# Observe the real shell transition rather than demand a completion
		# record from the deliberately freed outgoing actor.
		var finished: bool = false
		for _tick: int in range(_frame_limit(float(_stats.dash_duration) + 0.5)):
			await physics_frame
			await process_frame
			if not _shell.campaign_error.is_empty():
				return "actual deferred contact transition failed: " + _shell.campaign_error
			if not is_instance_valid(source_world) or _shell.active_level != source_world:
				_transition_seen = true
				break
			error = _live_error()
			if not error.is_empty():
				return error
			var actions: Array[Dictionary] = actor.get_world_action_records(sequence)
			if not actions.is_empty():
				if actions.size() != 1 or actions[0].kind != "dash" or actions[0].blocked or actions[0].collision_shortened or not _exact(actions[0].equipment_ids, _kit):
					return "actual contact approach published an invalid ordinary dash"
				finished = true
				break
		if _transition_seen:
			break
		if not finished:
			return "actual contact approach exceeded its finite dash bound"
	if not _transition_seen:
		return "eight actual ordinary dashes did not enter the real threshold"
	await _settle_shell()
	if _contact_state.is_empty() or not _contact_supported or _departure_actor.is_empty() or int(_events.get("exit", 0)) != 1 or int(_events.get("completion", 0)) != 1:
		return "production transition lacks one genuine supported capsule contact and its outgoing resources"
	if int(_departure_actor.resources.shells) >= int(_departure_actor.resources.max_shells) or float(_departure_actor.clocks.reload_s) <= 0.0:
		return "real contact carryover lacks depleted ammo and a naturally advancing fractional reload"
	for old: Variant in _departed_refs:
		if is_instance_valid(old):
			return "production contact retained an outgoing actor/world/scheduler/source"
	var next: Dictionary = _shell.capture_campaign_snapshot()
	if not paused or _shell.menu.page_name() != "resume" or next.is_empty() or next.level_id != "A3-L2" or next.scene_path != NextFixturePath or next.shell.difficulty_at_entry != _profile_id or _shell.active_level.shared_shell != _shell:
		return "actual next test floor failed to enter at a fresh paused production Resume boundary"
	if not _exact(next.player.resources.hp, _departure_actor.resources.hp) or next.player.resources.dead or next.player.resources.shells != _departure_actor.resources.shells or not _exact(next.player.clocks.reload_s, _departure_actor.clocks.reload_s) or not _exact(next.equipment_ids, _kit) or not _exact(next.shell.anchor_normalized, [_departure_anchor.x, _departure_anchor.y]):
		return "production next floor changed carried HP/ammo/fractional reload/gear/actual routed anchor"
	if next.player.world_actions.clock_s != 0.0 or next.player.world_actions.sequence != 0 or not next.player.world_actions.history.is_empty() or not next.player.world_actions.pending_dash.is_empty() or next.shell.input_sequence != 0 or not next.shell.last_input_observation.is_empty() or next.level.progress.completed or not String(next.level.progress.contact_exit_id).is_empty():
		return "production next floor inherited the old clock/history/pending dash/input/progression"
	durable = _shell.attempts.state()
	disk = reader.read_payload()
	if durable.completed_main != completed or durable.story.level_id != "A3-L2" or not _exact(durable.story.snapshot, next) or not _exact(durable.story.checkpoint, next) or not _exact(disk, durable) or not reader.last_error.is_empty():
		return "actual production advance did not durably retain prefix11 and the fresh next checkpoint"
	await create_timer(0.08, true).timeout
	if not _exact(_shell.capture_campaign_snapshot(), next):
		return "next floor resources/history/input/camera advance before explicit Resume"
	_expect(true, "one real capsule contact installs the next test floor with exact resource/gear/anchor carryover, fresh clocks/history, durable prefix11 and all five old actors/world/scheduler freed")
	return "" if _resume_consumed("next test-floor production transition") else "actual next-floor Resume input leaked"


func _observe_real_contact(_level_id: String, _exit_id: String) -> void:
	# After the real shell's synchronous pause, before its deferred exit.
	# Only public outgoing actor/state are sampled; no local restore occurs.
	_departure_actor = _hero.snapshot_state()
	_departure_anchor = _shell.get_aim_anchor_normalized()
	_contact_state = (_level.call("state") as Dictionary).contact.duplicate(true)
	if _contact_state.is_empty():
		return
	var point: Vector3 = Codec.read_vector3(_contact_state.hero_position)
	_contact_supported = paused and (_level.call("state") as Dictionary).exit_state == "spent" and Rect2(-1.2, -44.65, 2.4, 1.3).has_point(Vector2(point.x, point.z)) and absf(point.y) < 0.2 and point == _hero.global_position and _floor_hit(point) and _scheduler.reservations().is_empty()


func _final_error(pockets: int) -> String:
	if pockets != 4 or not _transition_seen or _completed_state.entered.size() != 4 or _completed_state.cleared.size() != 5 or _checkpoints.size() != 4 or not _active_pause_done or not _fresh_partial_done or (_requires_crossing_union() and not _union_seen):
		return "production full-route coverage incomplete: union=%s active_living_pause=%s protected_fresh_retry=%s transition=%s" % [_union_seen, _active_pause_done, _fresh_partial_done, _transition_seen]
	for id: String in SourceIds:
		if int(_death_events.get(id, 0)) != 1:
			return "actual ordinary-primary death count differs: " + id
	if int(_events.get("completion", 0)) != 1 or int(_events.get("exit", 0)) != 1 or int(_events.get("contact", 0)) != 0 or int(_events.get("hero_death", 0)) != 0 or int(_events.get("fired_blast", 0)) != 0 or int(_events.get("equipment", 0)) != 0 or float(_departure_actor.resources.hp) != _hp_before or int(_shell.get("cores")) != 0 or int(_shell.get("kills")) != 0:
		return "production route changed HP/actions/equipment/unrelated rewards or duplicated progression"
	if _profile_id == "assisted":
		if int(_expected_profile.reserved_threat_budget) != 1 or _maximum_preparing != 1 or _preparing_sources.is_empty() or (not _preparing_sources.has(SourceIds[2]) and not _preparing_sources.has(SourceIds[3])) or _crossing_primary_deferred:
			return "Assisted route lacks genuine budget1 preparing activity/crossing-priority coverage: maximum=%d observed=%s forced_union_deferral=%s" % [_maximum_preparing, _preparing_sources.keys(), _crossing_primary_deferred]
		var preferences = ProductionStore.new(_test_root + "preferences.json")
		if _shell.get_difficulty_preference() != "assisted" or not _exact(preferences.read_payload(), {"schema_version": 1, "profile_id": "assisted"}) or not preferences.last_error.is_empty():
			return "actual Assisted preference did not remain persisted through fresh retry and transition"
		_expect(true, "Assisted native profile/roles preserve actual preparing budget1 through five ordinary clears, including crossing priority; recovery-union observation=%s sources=%s" % [_union_seen, _preparing_sources.keys()])
	return ""


func _routed_initial_dash() -> String:
	var size: Vector2 = root.get_visible_rect().size
	var start: Vector2 = size * Vector2(0.60, 0.52)
	var finish: Vector2 = size * Vector2(0.32, 0.52)
	var sequence: int = _last_sequence()
	var down := InputEventScreenTouch.new()
	down.index = 7
	down.position = start
	down.pressed = true
	root.push_input(down, true)
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.index = 7
	drag.position = finish
	drag.relative = finish - start
	root.push_input(drag, true)
	await process_frame
	var up := InputEventScreenTouch.new()
	up.index = 7
	up.position = finish
	up.pressed = false
	root.push_input(up, true)
	for _tick: int in range(_frame_limit(1.0)):
		var records: Array[Dictionary] = _hero.get_world_action_records(sequence)
		if not records.is_empty():
			return "" if records.size() == 1 and records[0].kind == "dash" and not records[0].blocked and not records[0].collision_shortened and _shell.get_aim_anchor_normalized() == finish / size and _shell.get_input_observation_state().last_observation.get("kind") == "swipe_release" else "actual routed initial swipe failed its sole dash/exact anchor"
		var error: String = await _tick_safe()
		if not error.is_empty():
			return error
	return "actual initial routed swipe did not complete within one second"


func _resume_consumed(note: String) -> bool:
	var button: Control = _shell.menu.find_child("ResumeButton", true, false) as Control
	if not paused or not _shell.menu.is_open() or not is_instance_valid(button) or not button.is_visible_in_tree():
		return _expect(false, note + ": actual paused ResumeButton unavailable")
	var actor: CinderPlayer = _shell.player
	var before: Dictionary = {"history": actor.get_world_action_records(), "input": _shell.get_input_observation_state(), "clock": actor.get_world_action_clock(), "hp": actor.hp, "shells": actor.shells}
	var position: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	root.push_input(motion, true)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = position
	down.global_position = position
	down.pressed = true
	root.push_input(down, true)
	var down_handled: bool = root.is_input_handled()
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	root.push_input(up, true)
	# No yield: the GUI event must not change gameplay history/input/resources.
	return _expect(down_handled and root.is_input_handled() and not paused and not _shell.menu.is_open() and _exact(actor.get_world_action_records(), before.history) and _exact(_shell.get_input_observation_state(), before.input) and actor.get_world_action_clock() == before.clock and actor.hp == before.hp and actor.shells == before.shells, note + ": routed GUI Resume is consumed without a dash/primary/blast, input change or resource refill")


func _settle_shell() -> void:
	for _frame: int in range(6):
		await process_frame


func _diagnostic() -> String:
	return str({"paused": paused, "campaign_error": _shell.campaign_error if is_instance_valid(_shell) else "no shell", "active_id": _shell.active_level.level_id if is_instance_valid(_shell) and is_instance_valid(_shell.active_level) else "", "selected_profile": _profile_id, "expected_profile": _expected_profile, "maximum_preparing": _maximum_preparing, "preparing_sources": _preparing_sources.keys(), "union_observed": _union_seen, "requires_union": _requires_crossing_union(), "authored_level": _level.call("state") if is_instance_valid(_level) and _level.has_method("state") else _completed_state, "checkpoints": _checkpoints, "deaths": _death_events, "events": _events, "contact": _contact_state, "outgoing_actor_error": _hero.last_snapshot_error if is_instance_valid(_hero) else "retired", "restore_events": _restore_events})


func _dispose() -> void:
	var barrier_ref: Variant = _tick_barrier
	_free_tick_barrier()
	_watch_restore = false
	if node_added.is_connected(_observe_candidate):
		node_added.disconnect(_observe_candidate)
	var refs: Array = [_game, _hero, _level, _scheduler, _old_hero, _old_level, barrier_ref]
	refs.append_array(_sources.values())
	refs.append_array(_departed_refs)
	if is_instance_valid(_shell):
		refs.append_array([_shell.player, _shell.active_level, _shell.world])
		paused = true
		_shell.free()
	_game = null
	_shell = null
	paused = false
	await _settle_shell()
	await create_timer(0.25, true).timeout
	var clean: bool = true
	for node: Variant in refs:
		clean = clean and not is_instance_valid(node)
	for group: String in ["enemies", "practice_targets", "lab_weapons", "required_cues"]:
		clean = clean and get_nodes_in_group(group).is_empty()
	_expect(clean, "production cleanup frees authored/next/prepared worlds, actors/cues/schedulers and groups with finite audio drain")
	_expect(FileAccess.get_file_as_string(ProductionRegistry.DATA_PATH) == _canonical_bytes, "TEST ONLY production fixture leaves canonical registry bytes unchanged")
	_cleanup_test_path(_test_root)
	_hero = null
	_level = null
	_scheduler = null
	_sources.clear()


func _cleanup_test_path(path: String) -> void:
	if _test_root.is_empty() or not path.begins_with(_test_root) or not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):
		return
	for directory: String in DirAccess.get_directories_at(path):
		_cleanup_test_path(path.path_join(directory))
	for filename: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path.path_join(filename)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _finish() -> void:
	print("Twin Suns TEST ONLY production full-route transition: %d checks, %d failures; profile=%s maximum_preparing=%d union_observed=%s; no canonical/native/human acceptance" % [_checks, _failures, _profile_id, _maximum_preparing, _union_seen])
	quit(0 if _failures == 0 else 1)
