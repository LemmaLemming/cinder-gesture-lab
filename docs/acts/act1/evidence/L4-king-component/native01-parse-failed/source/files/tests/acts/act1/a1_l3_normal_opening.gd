extends "res://tests/acts/act1/a1_l3_crowd.gd"
## Owned normal-route opening fixture; unexecuted until its recorded job. Reuses actual touch/drag,
## accepted native response and crowd ordinary-hit accounting; never a pair
## restore, HP/phase/body seed, private field bind, teleport or full-route proof.
## Expected promoted scene: a1_l3_route_greybox.tscn. Root owns promotion/jobs.

const NormalOpeningPath: String = "res://scenes/acts/act1/a1_l3_route_greybox.tscn"

var opening_readiness: Array[Dictionary] = []
var opening_query_costs: Array[Dictionary] = []


func _ready_input(label: String) -> bool:
	# Cooldowns run on the actual Player simulation clock. The original 4s
	# wall deadline could expire after only .30s of simulation once native spore
	# bindings exist. Keep a 4s native window and the inherited 70s wall watchdog.
	var first: Dictionary = hero.get_threat_response_state()
	var start_clock: float = float(first.action_clock_s)
	var start_wall: int = Time.get_ticks_usec()
	var deadline: float = start_clock + 4.0
	while not aborted and not finishing:
		if not _guard_input(): return false
		var state: Dictionary = hero.get_threat_response_state()
		if state.stable and float(state.dash_cooldown_left_s) == 0.0 and float(state.primary_cooldown_left_s) == 0.0 and float(state.commitment_remaining_s) == 0.0:
			opening_readiness.append({"label": label, "start_clock_s": start_clock, "ready_clock_s": state.action_clock_s, "wall_elapsed_us": Time.get_ticks_usec() - start_wall, "actual_response": state.duplicate(true)})
			_measure_breathing_queries()
			return _require(true, label + " reaches actual native input readiness")
		if float(state.action_clock_s) >= deadline:
			_opening_diagnostic(label + " native readiness window expired")
			return _require(false, label + " reaches actual native readiness within four simulation seconds")
		_sample_preparing()
		await process_frame
	return false


func _measure_breathing_queries() -> void:
	if not opening_query_costs.is_empty() or not is_instance_valid(level) or level.call("route_state").get("beat_index") != 1: return
	# Pure actual public readers only. These timings identify repeated validation
	# work; they grant no field, actor, camera or clock authority.
	for child: Node in level.get_children():
		if child is CinderSporeRepulsion:
			var begin: int = Time.get_ticks_usec()
			var accepted: bool = child.placement_accepted()
			opening_query_costs.append({"query": "actual consumer placement_accepted", "elapsed_us": Time.get_ticks_usec() - begin, "accepted": accepted})
		elif child is CinderSporeField:
			var begin: int = Time.get_ticks_usec()
			var error: String = child.binding_error()
			opening_query_costs.append({"query": "actual field binding_error", "elapsed_us": Time.get_ticks_usec() - begin, "error": error})
	if not opening_query_costs.is_empty():
		var begin: int = Time.get_ticks_usec()
		var points: Array = level.camera_framing_points()
		opening_query_costs.append({"query": "actual complete level camera corners", "elapsed_us": Time.get_ticks_usec() - begin, "point_count": points.size(), "error": level.last_camera_framing_error})
const NormalIds: Array[String] = ["umbrella-1", "umbrella-2", "umbrella-3", "breathing-1", "breathing-2", "breathing-3", "crossed-1", "crossed-2", "crossed-3", "crossed-4", "crossed-5", "crossed-6", "crossed-7", "crossed-8", "lone-guard", "court-1", "court-2", "court-3", "court-guard"]
const BreathingIds: Array[String] = ["breathing-1", "breathing-2", "breathing-3"]
var opening_references: Dictionary = {}
var opening_activation_counts: Dictionary = {}
var opening_dormancy: Dictionary = {}
var opening_epochs: Array[String] = []
var opening_last_epoch: String = ""
var opening_last_clock: float = 0.0
var opening_checkpoint_events: Array[Dictionary] = []
var opening_completion_events: int = 0
var opening_contact_events: int = 0
var opening_nested_rejected: bool = false
var opening_diagnostics: Array[Dictionary] = []


func _run() -> void:
	portrait = "--portrait" in OS.get_cmdline_user_args()
	root.size = PortraitSize
	if portrait:
		if not _require(DisplayServer.get_name() != "headless", "normal opening portrait requires the actual graphical renderer"):
			await _finish(); return
		capture_dir = "res://.cinder/captures/l3-normal-opening-%d" % Time.get_ticks_usec()
		if not _require(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir)) == OK, "normal opening capture directory is writable"):
			await _finish(); return
		print("SCRIPTED NORMAL L3 OPENING native_focus_observed=", DisplayServer.window_is_focused(), "; one initial public resume; unchanged normal FOCUS_OUT")
	if not await _open_world(NormalOpeningPath, "normal-opening", Vector3(0, .1, 15)):
		await _finish(); return
	if not await _capture("pristine-nineteen"):
		await _finish(); return
	process_frame.connect(_sample_opening)
	process_frame.connect(_sample_crowd)
	# One genuine forward release crosses the broad first-room entrance.
	if not await _swipe(Vector3.FORWARD, "actual first normal entrance"):
		_opening_diagnostic("first gesture failed"); await _finish(); return
	_sample_opening() # Observe the final public boundary without callback-order assumptions.
	var route: Dictionary = level.call("route_state")
	var control: Dictionary = scheduler.source_control_state(sources["umbrella-1"])
	if not _require(route.beat_index == 0 and route.room_stage == "active" and route.encounter_started and route.completed_beats.is_empty() and level.call("current_source_ids") == CrowdIds and scheduler.encounter_profile().get("id") == "standard" and control.encounter_id == "a1_l3_umbrella" and control.world_revision == 1, "real entrance begins the actual Standard umbrella epoch with only its three entitled sources"):
		_opening_diagnostic("first room boundary"); await _finish(); return
	if not _require(hero.equipment.snapshot() == {"jacket": "CLOTH-J0", "pants": "CLOTH-P0", "shoes": "CLOTH-S0", "weapon": "WEAPON-01"}, "normal opening uses the actual existing neutral starter types"):
		await _finish(); return
	for id: String in CrowdIds:
		var actor: CharacterBody3D = sources[id]
		var state: Dictionary = actor.call("pure_presentation_state")
		if not _require(opening_activation_counts[id] == 1 and not state.dormant and not state.dead and state.hp == 16.0 and actor.is_in_group("enemies") and actor.call("get_spore_response_state").consumer_id == "", id + " activates once, unharmed and genuinely unbound"):
			await _finish(); return
	if not _future_pristine(CrowdIds, "first entrance future sixteen") or not _environment_absent() or not _framing("all three actual opening sources") or not await _capture("genuine-umbrella-entrance"):
		await _finish(); return
	var rounds: int = 0
	while not _all_three_defeated() and rounds < 6 and not aborted:
		if not await _wait(func() -> bool: return _fresh_warning() != "" or (full_cycle_followed and _reachable_source() != ""), "genuine umbrella ordinary opportunity", 12.0):
			_opening_diagnostic("first room opportunity"); await _finish(); return
		var id: String = _fresh_warning()
		if not id.is_empty():
			# No inherited four-actor pair pause or restore is invoked here.
			if not await _fight_cycle(id, false):
				_opening_diagnostic("actual response/primary failed"); await _finish(); return
			full_cycle_followed = true
		else:
			id = _reachable_source()
			if id.is_empty() or not await _primary(sources[id], id + " genuine normal crowd opening"):
				_opening_diagnostic("reachable ordinary failed"); await _finish(); return
		rounds += 1
	if not await _wait(func() -> bool:
		var current: Dictionary = level.call("route_state")
		return _all_three_defeated() and current.beat_index == 1 and current.room_stage == "approach", "native parent publishes only the real umbrella clear", 2.0):
		_opening_diagnostic("first clear"); await _finish(); return
	route = level.call("route_state")
	if not _require(route.completed_beats == ["umbrella-grove"] and not route.encounter_started and level.current_checkpoint() == {"id": "umbrella-grove", "kind": "encounter"} and opening_checkpoint_events == [{"level_id": "A1-L3", "checkpoint_id": "umbrella-grove", "kind": "encounter"}] and opening_nested_rejected and not level.is_completed() and opening_completion_events == 0 and opening_contact_events == 0, "three genuine ordinary defeats publish exactly the first checkpoint and reject nested premature/duplicate public progress"):
		await _finish(); return
	if not _require(full_cycle_followed and not crowd_admissions.is_empty() and not crowd_primary_receipts.is_empty() and hero.hp == initial_hp and hit_events.is_empty() and not preparing_violation and max_preparing == 1 and opening_epochs == ["a1_l3_umbrella"] and scheduler.encounter_profile().is_empty(), "first clear preserves real HP, one preparing source and the one observed native encounter epoch"):
		await _finish(); return
	if not _retained_truth("first genuine clear") or not _future_pristine(CrowdIds, "cleared room future sixteen") or not _environment_absent() or not await _capture("actual-first-checkpoint"):
		await _finish(); return
	# Only genuine whole forward recognizer dashes; no waypoint/position seed.
	# An actual collider/visibility failure is diagnosed, not shortened or hidden.
	var advances: int = 0
	while level.call("route_state").room_stage == "approach" and advances < 8 and not aborted:
		if not await _swipe(Vector3.FORWARD, "actual forward breathing entrance %d" % [advances + 1]):
			_opening_diagnostic("next entrance genuine forward route"); await _finish(); return
		advances += 1
	if not await _wait(func() -> bool: return _breathing_installed(), "actual three-source breathing native binding at its real threshold", 2.0):
		_opening_diagnostic("breathing binding"); await _finish(); return
	_sample_opening() # The actual new epoch is queried before its exact assertion.
	if not _retained_truth("breathing install") or not _check_breathing() or not _future_pristine(CrowdIds + BreathingIds, "breathing future thirteen") or not _framing("actual breathing source/field/cluster union") or not await _capture("actual-breathing-install"):
		_opening_diagnostic("breathing actual resources/framing"); await _finish(); return
	if not await _unsupported_save_barrier():
		_opening_diagnostic("explicit save refusal"); await _finish(); return
	_opening_diagnostic("bounded opening complete")
	if not await _close_world(false):
		await _finish(); return
	await _finish()


func _open_world(path: String, scope: String, spawn: Vector3) -> bool:
	await process_frame
	current_scope = scope
	sources.clear(); admissions.clear(); phase_observations.clear()
	world_records.clear(); input_observations.clear(); hit_events.clear()
	events = 0; max_preparing = 0; preparing_violation = false
	game = MainScene.instantiate()
	game.set("level_scene_path", path)
	root.add_child(game)
	level = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	scheduler = level.get("scheduler") as CinderThreatScheduler if level != null else null
	if not _require(level != null and hero != null and scheduler != null and level.contract_error().is_empty() and level.hero == hero and hero.global_position == spawn, "normal preview enters the one actual shared Hero at the exact authored spawn"):
		return false
	sources = (level.get("sources") as Dictionary).duplicate()
	initial_hp = hero.hp
	var spec: Dictionary = level.call("normal_route_spec")
	if not _require(Codec.keys_error(sources, NormalIds).is_empty() and spec.sources == NormalIds and level.call("current_source_ids") == CrowdIds and level.call("route_state").room_stage == "approach" and not level.call("route_state").encounter_started and scheduler.encounter_profile().is_empty() and scheduler.get_clock() == 0.0 and hero.get_world_action_records().is_empty(), "fresh normal spawn retains the exact nineteen cast while no actual encounter has begun"):
		return false
	for id: String in NormalIds:
		var raw: Variant = sources.get(id)
		if not _require(is_instance_valid(raw) and raw is CharacterBody3D, "fresh retained normal source is a live actual body: " + id): return false
		var actor: CharacterBody3D = raw
		var body := actor.get_node_or_null("BodyCollision") as CollisionShape3D
		var art := actor.call("get_art") as Node3D
		var cue := actor.call("get_cue") as CinderThreatCue
		var native: Dictionary = actor.call("get_spore_native_bindings")
		if not _require(body != null and body.shape is CapsuleShape3D and art != null and cue != null and not native.is_empty() and native.scheduler == scheduler and native.player == hero and native.source_id == id, id + " retains the actual configured native Player/Scheduler/body/art/cue binding"):
			return false
		opening_references[id] = {"actor": actor, "body": body, "shape": body.shape, "art": art, "cue": cue, "configuration": native.configuration.duplicate(true)}
		opening_activation_counts[id] = 0
		opening_dormancy[id] = true
		approach_displacement[id] = 0.0
		actor.connect("state_changed", Callable(self, "_notice_phase").bind(id))
		actor.connect("hit_resolved", Callable(self, "_notice_hit").bind(id))
		cue.state_changed.connect(func(_state: Dictionary) -> void: events += 1)
	if not _future_pristine([], "exact pristine spawn") or not _environment_absent(): return false
	level.connect("native_admission_published", _notice_admission)
	level.checkpoint_requested.connect(_notice_checkpoint)
	level.completion_requested.connect(func(_id: String, _completion: String) -> void: opening_completion_events += 1)
	level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: opening_contact_events += 1)
	hero.world_action_executed.connect(func(record: Dictionary) -> void: world_records.append(record.duplicate(true)); events += 1)
	game.connect("input_observed", func(observation: Dictionary) -> void: input_observations.append(observation.duplicate(true)))
	var checkpoint: bool = level.request_checkpoint("umbrella-grove", "encounter")
	var completion: bool = level.request_completion("mushroom-caverns-clear")
	var contact: bool = level.request_contact_exit("open-court", hero)
	if not _require(not checkpoint and not completion and not contact and level.current_checkpoint().id == "" and not level.is_completed() and opening_checkpoint_events.is_empty(), "pristine normal preview rejects progress/contact before real defeats"):
		return false
	game.call("resume_lab") # Exactly one public initial resume; normal focus remains.
	return _require(not paused, "normal initial public preview resume is real and focus handling remains enabled")


func _future_pristine(allowed: Array, label: String) -> bool:
	for id: String in NormalIds:
		if id in allowed: continue
		var actor: CharacterBody3D = sources[id]
		var state: Dictionary = actor.call("pure_presentation_state")
		var response: Dictionary = actor.call("get_spore_response_state")
		var control: Dictionary = scheduler.source_control_state(actor)
		var body: CollisionShape3D = opening_references[id].body
		var guard: bool = id in ["lone-guard", "court-guard"]
		if not _require(state.source_id == id and state.entity_id == ("C32" if guard else "C31") and state.hp == (24.0 if guard else 16.0) and not state.dead and state.dormant and state.status == "dormant" and state.phase == "clear" and state.cycle == 0 and state.reservation_id == "" and state.geometry.is_empty() and state.velocity == Vector3.ZERO and not state.approach_driving and state.approach_enabled == (not guard) and state.hurt_left_s == 0.0 and state.last_cancel_reason == "" and not response.is_empty() and not response.alive and response.consumer_id == "" and response.episode_id == "" and response.phase == "none" and control.reservations.is_empty() and control.cooldown == null and actor.get_parent() == level and not actor.is_in_group("enemies") and not actor.visible and body.disabled and actor.collision_layer == 0 and actor.collision_mask == 0 and opening_activation_counts[id] == 0, label + " leaves native future source pristine: " + id):
			return false
	return true


func _retained_truth(label: String) -> bool:
	for id: String in NormalIds:
		var raw: Variant = sources.get(id)
		if not _require(is_instance_valid(raw) and raw == opening_references[id].actor and raw is CharacterBody3D, label + " preserves actual source identity: " + id): return false
		var actor: CharacterBody3D = raw
		var native: Dictionary = actor.call("get_spore_native_bindings")
		if not _require(actor.get_parent() == level and actor.is_inside_tree() and not actor.is_queued_for_deletion() and actor.get_node_or_null("BodyCollision") == opening_references[id].body and opening_references[id].body.shape == opening_references[id].shape and actor.call("get_art") == opening_references[id].art and actor.call("get_cue") == opening_references[id].cue and not native.is_empty() and native.scheduler == scheduler and native.player == hero and native.configuration == opening_references[id].configuration and String(actor.call("body_binding_error")).is_empty() and String(actor.call("art_binding_error")).is_empty(), label + " preserves original actual configuration/body/art/cue resources: " + id):
			return false
	return true


func _environment_absent() -> bool:
	var field_count: int = 0
	var consumer_count: int = 0
	for child: Node in level.get_children():
		if child is CinderSporeField: field_count += 1
		if child is CinderSporeRepulsion: consumer_count += 1
	var route: Dictionary = level.call("route_state")
	return _require(field_count == 0 and consumer_count == 0 and route.installed_fields.is_empty() and route.installed_consumers.is_empty(), "no future environmental field or consumer exists before its actual room")


func _breathing_installed() -> bool:
	var route: Dictionary = level.call("route_state")
	return route.beat_index == 1 and route.room_stage == "active" and route.encounter_started and route.installed_fields == ["breathing"] and route.installed_consumers == ["breathing"]


func _check_breathing() -> bool:
	var fields: Array[CinderSporeField] = []
	var consumers: Array[CinderSporeRepulsion] = []
	for child: Node in level.get_children():
		if child is CinderSporeField: fields.append(child)
		if child is CinderSporeRepulsion: consumers.append(child)
	if not _require(fields.size() == 1 and consumers.size() == 1 and level.call("current_source_ids") == BreathingIds and opening_epochs == ["a1_l3_umbrella", "a1_l3_breathing"] and scheduler.encounter_profile().get("id") == "standard", "next real entrance installs one breathing field/consumer in the new actual epoch"):
		return false
	var field: CinderSporeField = fields[0]
	var consumer: CinderSporeRepulsion = consumers[0]
	var native: Dictionary = field.state()
	var spec: Dictionary = level.call("normal_route_spec")
	if not _require(field.global_position == spec.field_points.breathing and native.instance_id == "breathing" and native.bound and native.phase == "available" and native.generation == 0 and native.spent_ids.is_empty() and native.remaining_clusters == 2 and native.activation_s == null and native.deadline_s == null and consumer.consumer_id() == "a1_l3_breathing_spores" and consumer.placement_accepted() and consumer.snapshot_boundary_available(), "actual new field keeps its original finite supplies and valid native custody without a synthetic reaction"):
		return false
	var matched: Array[String] = []
	for id: String in NormalIds:
		var actor: CharacterBody3D = sources[id]
		var response: Dictionary = actor.call("get_spore_response_state")
		if consumer.source_binding_matches(actor, id): matched.append(id)
		if id in BreathingIds:
			var state: Dictionary = actor.call("pure_presentation_state")
			var route_guard: Callable = actor.get("spore_route_guard")
			if not _require(opening_activation_counts[id] == 1 and not state.dormant and not state.dead and state.hp == 16.0 and actor.is_in_group("enemies") and response.consumer_id == consumer.consumer_id() and response.phase == "none" and response.episode_id == "" and response.progress == 0.0 and actor.get("spore_route_guard_required") == true and route_guard.is_valid(), id + " binds its actual native source once with the required owned route guard"):
				return false
	if not _require(matched == BreathingIds, "native consumer exposes exactly the three actual breathing source bindings and no other cast recipient"):
		return false
	for id: String in ["cluster-left", "cluster-right"]:
		var cluster := field.get_node_or_null(id) as Node3D
		var art := cluster.get_node_or_null("AuthoredLowCluster") as Node3D if cluster != null else null
		if not _require(cluster != null and art != null and cluster.is_in_group("environment_attack_targets") and String(art.call("binding_error")).is_empty() and art.call("state_name") == "available", "new true low cluster retains its real available target/art: " + id): return false
	return _require(opening_checkpoint_events.size() == 1 and not level.is_completed() and hero.hp == initial_hp and hit_events.is_empty(), "binding the next room grants no progress, damage or resource repair")


func _unsupported_save_barrier() -> bool:
	if not await _pause_pair("normal unsupported aggregate"):
		return false
	var before: Dictionary = _opening_observation()
	var player: Dictionary = hero.snapshot_state()
	var envelope: Dictionary = {"api_revision": CinderLevel.API_REVISION, "schema_version": CinderLevel.SNAPSHOT_SCHEMA_VERSION, "level_id": "A1-L3", "scene_path": level.scene_file_path, "local_snapshot_version": level.local_snapshot_version, "progress": {"completed": false, "completion_id": "", "contact_exit_id": "", "checkpoint_id": "umbrella-grove", "checkpoint_kind": "encounter", "checkpoint_ids": {"umbrella-grove": "encounter"}}, "local": {}}
	var capture: Dictionary = level.snapshot_state()
	var capture_error: String = level.last_snapshot_error
	var error: String = level.snapshot_error(envelope)
	var context_error: String = level.snapshot_error_with_player(envelope, player)
	var restored: bool = level.restore_state(envelope)
	if not _require(not player.is_empty() and capture.is_empty() and not capture_error.is_empty() and not error.is_empty() and not context_error.is_empty() and not restored and _opening_observation() == before, "normal capture/pure/context/restore rejects unsupported aggregate before any actual resource/native-clock/progress/event mutation"):
		return false
	if not _framing("normal paused exact native resources") or not await _capture("unsupported-save-paused"): return false
	return await _gui_resume_pair()


func _notice_phase(state: Dictionary, id: String) -> void:
	if opening_dormancy.get(id, true) and not state.get("dormant", true):
		opening_activation_counts[id] = int(opening_activation_counts.get(id, 0)) + 1
	opening_dormancy[id] = state.get("dormant", true)
	super._notice_phase(state, id)


func _notice_checkpoint(id: String, checkpoint: String, kind: String) -> void:
	opening_checkpoint_events.append({"level_id": id, "checkpoint_id": checkpoint, "kind": kind})
	var duplicate: bool = level.request_checkpoint(checkpoint, kind)
	var future: bool = level.request_checkpoint("breathing-chamber", "encounter")
	var completion: bool = level.request_completion("mushroom-caverns-clear")
	opening_nested_rejected = not duplicate and not future and not completion


func _sample_opening() -> void:
	if finishing or aborted or paused or not is_instance_valid(scheduler) or not is_instance_valid(sources.get("umbrella-1")): return
	var control: Dictionary = scheduler.source_control_state(sources["umbrella-1"])
	var epoch: String = String(control.get("encounter_id", ""))
	var clock: float = scheduler.get_clock()
	if not epoch.is_empty() and epoch != opening_last_epoch: opening_epochs.append(epoch)
	if epoch == opening_last_epoch and not epoch.is_empty():
		if not _require_unexpected(clock >= opening_last_clock, "actual unchanged native room clock never resets during the observed epoch"): return
	opening_last_epoch = epoch
	opening_last_clock = clock


func _sample_preparing() -> void:
	if not is_instance_valid(level) or finishing: return
	var count: int = 0
	for id: String in level.call("current_source_ids"):
		if not is_instance_valid(sources.get(id)): continue
		if sources[id].call("pure_presentation_state").phase in ["warning", "lock"]: count += 1
	max_preparing = maxi(max_preparing, count)
	if count > 1: preparing_violation = true


func _source_states() -> Dictionary:
	var result: Dictionary = {}
	for id: String in NormalIds:
		if is_instance_valid(sources.get(id)): result[id] = sources[id].call("pure_presentation_state").duplicate(true)
	return result


func _opening_observation() -> Dictionary:
	var control: Dictionary = {}
	var field_states: Dictionary = {}
	var consumer_states: Dictionary = {}
	var cues: Dictionary = {}
	for id: String in NormalIds:
		control[id] = scheduler.source_control_state(sources[id])
		cues[id] = sources[id].call("get_cue").state()
	for child: Node in level.get_children():
		if child is CinderSporeField: field_states[(child as CinderSporeField).state().instance_id] = (child as CinderSporeField).state()
		if child is CinderSporeRepulsion:
			var consumer := child as CinderSporeRepulsion
			var records: Dictionary = {}
			for id: String in NormalIds:
				if consumer.source_binding_matches(sources[id], id): records[id] = consumer.source_state(id)
			consumer_states[consumer.consumer_id()] = records
	return {"player": hero.snapshot_state(), "sources": _source_states(), "controls": control, "cues": cues, "fields": field_states, "consumer_records": consumer_states, "route": level.call("route_state"), "input": game.call("get_input_observation_state"), "world_actions": hero.get_world_action_records(), "events": events, "checkpoints": opening_checkpoint_events.duplicate(true), "completed": level.is_completed()}


func _opening_diagnostic(label: String) -> void:
	var actual: Dictionary = {"label": label, "swipes": swipes, "primaries": primaries, "epochs": opening_epochs.duplicate(), "activation_counts": opening_activation_counts.duplicate(), "route": level.call("route_state") if is_instance_valid(level) else {}, "hero": hero.global_position if is_instance_valid(hero) else Vector3.ZERO, "hp": hero.hp if is_instance_valid(hero) else -1.0, "camera": game.call("get_camera_framing_state") if is_instance_valid(game) else {}, "sources": _source_states(), "admissions": admissions, "checkpoints": opening_checkpoint_events}
	# Read actual public response data after a failed readiness wait; never
	# replace the motion, input, floor cache or dash that caused that failure.
	actual["hero_response"] = hero.get_threat_response_state() if is_instance_valid(hero) else {}
	actual["committed_dash"] = hero.get_committed_dash_state() if is_instance_valid(hero) else {}
	actual["hero_physics_processing"] = hero.is_physics_processing() if is_instance_valid(hero) else false
	actual["tree_paused"] = paused
	actual["input"] = game.call("get_input_observation_state") if is_instance_valid(game) else {}
	actual["world_actions"] = hero.get_world_action_records() if is_instance_valid(hero) else []
	actual["readiness"] = opening_readiness.duplicate(true)
	actual["pure_query_costs"] = opening_query_costs.duplicate(true)
	opening_diagnostics.append(_portable(actual))
	print("NORMAL L3 OPENING DIAGNOSTIC ", label, " ", _portable(actual))


func _finish() -> void:
	if finishing: return
	if process_frame.is_connected(_sample_crowd): process_frame.disconnect(_sample_crowd)
	if process_frame.is_connected(_sample_opening): process_frame.disconnect(_sample_opening)
	finishing = true
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(game):
		var effects: PixelEffects = game.get("fx") as PixelEffects
		if is_instance_valid(effects): effects.clear()
		game.queue_free()
	paused = false
	await process_frame
	var evidence_path: String = capture_dir.path_join("evidence.json") if portrait else "res://.cinder/l3-normal-opening-%d.json" % Time.get_ticks_usec()
	var file := FileAccess.open(evidence_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"scope": "actual neutral/Standard nineteen-source normal spawn, first three-C31 ordinary clear/checkpoint and genuine three-source breathing installation only; no reaction/full route/eight-body/campaign-save/human acceptance", "checks": checks, "failures": failures, "actual_swipes": swipes, "actual_primaries": primaries, "normal_focus_out_preserved": true, "observed_epochs": opening_epochs, "activation_counts": opening_activation_counts, "checkpoint_events": opening_checkpoint_events, "crowd_primary_receipts": crowd_primary_receipts, "admission_receipts": crowd_admissions, "diagnostics": opening_diagnostics, "worlds": worlds, "captures": shots}, "\t"))
		file.close()
	else:
		checks += 1; failures += 1
		push_error("normal opening diagnostic evidence file failed to open")
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L3 NORMAL OPENING ONLY: %d checks, %d failures; %d real swipes, %d real primaries; NO TELEPORTS / NO FULL ROUTE / FULL SAVE REJECTED" % [checks, failures, swipes, primaries])
	quit(1 if failures else 0)
