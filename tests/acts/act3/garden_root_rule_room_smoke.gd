extends SceneTree
## Focused two-source rule prototype. Actual engine-routed fixture gestures are not
## native OS input or a human balance/playthrough claim. Local paired capture is
## checked at warning pause; full restore/disk/campaign flow needs its own test.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const ROOM: String = "res://scenes/acts/act3/a3_l4_garden_root_rule_room.tscn"
const CASES: Array[Dictionary] = [
	{"kind": "draw", "escape": Vector3.LEFT},
	{"kind": "enclose", "escape": Vector3.RIGHT},
]
# Separately selected lateral alternatives require real current-camera admission.
# Change only authored response directions if necessary; never force the camera
# or relocate Hero/source to make a rejected native witness pass.

class PostActorBarrier extends Node:
	signal observed
	var waiting: bool = false
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 1000
	func _physics_process(_delta: float) -> void:
		if waiting:
			waiting = false
			observed.emit()
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PAUSED and waiting:
			_wake.call_deferred()
	func _wake() -> void:
		if waiting:
			waiting = false
			observed.emit()

var _game: Node
var _hero: CinderPlayer
var _level: CinderLevel
var _tether: StaticBody3D
var _mechanisms: Dictionary = {}
var _scheduler: CinderThreatScheduler
var _barrier: PostActorBarrier
var _checks: int = 0
var _failures: int = 0
var _events: Array[String] = []
var _phases: Dictionary = {}
var _kit: Dictionary = {}
var _hero_hp: float = 0.0
var _fixed_target: Transform3D
var _fixed_sources: Dictionary = {}
var _active_kind: String = ""
var _allow_cancelled: bool = false
var _capture: bool = false
var _captured: Dictionary = {}
var _compound_extreme: bool = false
var _retired_sources: Dictionary = {}
const COMPOUND_KIT: Dictionary = {"jacket": "CLOTH-J1", "pants": "CLOTH-P2", "shoes": "CLOTH-S2", "weapon": "WEAPON-03"}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--capture-portraits" and not _capture:
			_capture = true
		elif argument == "--compound-extreme" and not _compound_extreme:
			_compound_extreme = true
		elif argument == "--assisted":
			_expect(false, "Assisted selector is explicitly unimplemented: plain Main has no genuine public preference boundary; cover it through authored production L4 later")
			await _finish()
			return
		else:
			_expect(false, "one supported focused selector of each kind", argument)
			await _finish()
			return
	if _capture and not _expect(DisplayServer.get_name() != "headless", "portrait selector requires native graphical rendering"):
		await _finish()
		return
	for definition: Dictionary in CASES:
		await _case(String(definition.kind), definition.escape)
		await _close()
		if _failures > 0:
			break
	if _failures == 0:
		await _held_teardown()
	await _finish()


func _case(kind: String, direction: Vector3) -> void:
	if not await _open():
		return
	var answer: Dictionary = await _admit(kind, direction)
	if answer.is_empty():
		return
	var mechanism: CinderLaneMechanism = _source(kind)
	var held: Dictionary = mechanism.state()
	var proof: Dictionary = answer.get("proof", {})
	var reservation_id: String = String(answer.get("reservation_id", ""))
	var record: Dictionary = _scheduler.reservation_state(reservation_id)
	var selected: Dictionary = _level.call("get_selected_response", kind)
	var geometry_ok: bool = held.geometry.kind == "lane" if kind == "draw" else held.geometry.kind == "crescent" and float(held.geometry.inner_radius) > 0.0 and float(held.geometry.outer_radius) > float(held.geometry.inner_radius) and float(held.geometry.min_dot) >= 0.0 and float(held.geometry.min_dot) < 1.0
	if not _expect(held.status == "running" and held.phase == "warning" and held.cycle == 1 and String(held.reservation_id) == reservation_id and record.get("source_instance_id") == mechanism.get_instance_id() and geometry_ok and proof.get("accepted", false) and not proof.get("uses_blast", true) and not proof.get("uses_invulnerability", true) and selected.get("landing") == proof.get("landing") and selected.get("attack_position") == proof.get("attack_position"), "genuine " + kind + " holds its native finite geometry, exact lease, harmless landing and ordinary-return proof", str(answer)):
		return
	if not await _portrait(kind + "-warning") or not _closed_hit_guards():
		return
	# The first tap genuinely executes immediately, even while the closed
	# tether rejects damage. The later actual swipe clears this tap chain.
	var closed_hp: float = float(_tether.get("hp"))
	var prior_count: int = _hero.get_world_action_records().size()
	var error: String = _tap(_target_direction())
	var actual_input: Dictionary = _game.call("get_input_observation_state")
	var actions: Array[Dictionary] = _hero.get_world_action_records()
	if not _expect(error.is_empty() and actions.size() == prior_count + 1 and actions.back().kind == "primary" and actions.back().hits == 0 and _hero.last_action.hits == 0 and float(_tether.get("hp")) == closed_hp and actual_input.last_observation.kind == "primary_tap" and actual_input.last_observation.accepted, "actual first routed tap executes a zero-hit ordinary primary against the warning shutter", error):
		return
	if not await _pause_check():
		return
	var escaped: bool = false
	var returned: bool = false
	for segment: Dictionary in proof.path:
		if segment.kind not in ["escape_dash", "positioning_dash"]:
			continue
		if not await _until(float(segment.start_s)):
			return
		var intended: Vector3 = (segment.to - segment.from).normalized()
		error = _swipe(intended)
		var committed: Dictionary = _hero.get_committed_dash_state()
		if not _expect(error.is_empty() and committed.get("active", false) and (committed.direction as Vector3).distance_to(intended) < 0.000001 and committed.distance == _hero.stats.dash_distance and committed.duration_s == _hero.stats.dash_duration, "actual routed " + String(segment.kind) + " commits the complete canonical shared dash", error):
			return
		if not await _complete_dash(segment):
			return
		if segment.kind == "escape_dash":
			escaped = true
			if not await _portrait(kind + "-landing"):
				return
		else:
			returned = true
	if not await _until(float(proof.primary_time_s)):
		return
	var live_record: Dictionary = _scheduler.reservation_state(reservation_id)
	if not _expect(escaped and returned and mechanism.state().phase == "recovery" and live_record.get("state") == "recovery" and _hero.global_position.distance_to(proof.attack_position) < 0.02 and float(proof.response_complete_s) < float(record.recovery_until_s) and float(_hero.get_threat_response_state().primary_cooldown_left_s) == 0.0, "actual escape and return reach a genuine native recovery before its full ordinary-primary budget expires"):
		return
	if not await _portrait(kind + "-ordinary-return"):
		return
	if not _hidden_recovery_marker(kind) or not _hidden_physical_target():
		return
	var opening_hp: float = float(_tether.get("hp"))
	var damage: float = float(_hero.stats.primary_damage)
	prior_count = _hero.get_world_action_records().size()
	error = _tap(_target_direction())
	# Sample after routed input: conservatively later than Game's actual tap.
	var first_tap_wall_ms: int = Time.get_ticks_msec()
	actions = _hero.get_world_action_records()
	if not _expect(error.is_empty() and opening_hp == 60.0 and damage > 0.0 and damage < 30.0 and float(_tether.get("hp")) == maxf(30.0, opening_hp - damage) and int(_tether.get("phase")) == 1 and actions.size() == prior_count + 1 and actions.back().kind == "primary" and actions.back().hits == 1 and actions.back().damage == damage and _hero.last_action.hits == 1 and not bool(_tether.get("dead")), "actual first recovery primary subtracts resolved damage from the original60HP tether without resetting phase HP", error + "; " + str(_tether.call("state"))):
		return
	# Game's nearby second-tap discriminator uses wall milliseconds, whereas
	# primary readiness uses the actual Hero physics clock. Respect both.
	if not await _second_primary_ready(first_tap_wall_ms, float(record.recovery_until_s)):
		return
	prior_count = _hero.get_world_action_records().size()
	_allow_cancelled = true # Boundary cancellation is the intended next action.
	error = _tap(_target_direction())
	actions = _hero.get_world_action_records()
	actual_input = _game.call("get_input_observation_state")
	if not _expect(error.is_empty() and float(_tether.get("hp")) == 30.0 and float(_tether.get("max_hp")) == 60.0 and int(_tether.get("phase")) == 2 and not bool(_tether.get("dead")) and actions.size() == prior_count + 1 and actions.back().kind == "primary" and actions.back().hits == 1 and _hero.last_action.hits == 1 and actual_input.last_observation.kind == "primary_tap" and actual_input.last_observation.accepted and _scheduler.reservation_state(reservation_id).is_empty() and _all_sources_clear(), "second genuine ordinary tap reaches exact30HP phase boundary and synchronously clears the actual leases/cues without regeneration or blast", error + "; " + str(_tether.call("state"))):
		return
	if not _closed_hit_guards() or not await _portrait(kind + "-phase-closed"):
		return
	for _i: int in range(24):
		if not await _tick():
			return
	var dash_count: int = 0
	for action: Dictionary in _hero.get_world_action_records():
		if action.kind == "dash":
			dash_count += 1
	var checkpoint: Dictionary = _level.current_checkpoint()
	_expect(dash_count == 2 and _all_sources_clear() and _phases.has(kind + ":warning") and _phases.has(kind + ":lock") and _phases.has(kind + ":active") and _phases.has(kind + ":recovery") and not _events.has("fired_blast") and not _events.has("hit") and not _events.has("completion") and not _events.has("checkpoint") and not _events.has("exit") and not _level.is_completed() and checkpoint.id.is_empty() and checkpoint.kind.is_empty(), "finite " + kind + " exchange keeps two full dashes, ordinary actions, no Hero contact, automatic restart, reward or campaign progress")
	if _failures == 0:
		await _phase_two(kind)


func _phase_two(previous_kind: String) -> void:
	var kind: String = "enclose" if previous_kind == "draw" else "draw"
	var direction: Vector3 = Vector3.RIGHT if kind == "enclose" else Vector3.LEFT
	var same_hero: int = _hero.get_instance_id()
	var same_target: int = _tether.get_instance_id()
	var same_scheduler: int = _scheduler.get_instance_id()
	var phase_boundary_clock: float = _scheduler.get_clock()
	for source_kind: String in ["draw", "enclose"]:
		_retired_sources[source_kind] = _source(source_kind).state()
	_allow_cancelled = false
	var answer: Dictionary = await _admit(kind, direction)
	if answer.is_empty():
		return
	var mechanism: CinderLaneMechanism = _source(kind)
	var held: Dictionary = mechanism.state()
	var reservation_id: String = String(answer.get("reservation_id", ""))
	var record: Dictionary = _scheduler.reservation_state(reservation_id)
	var proof: Dictionary = answer.get("proof", {})
	var selected: Dictionary = _level.call("get_selected_response", kind)
	var original: Dictionary = _source(previous_kind).state()
	if not _expect(_hero.get_instance_id() == same_hero and _tether.get_instance_id() == same_target and _scheduler.get_instance_id() == same_scheduler and _scheduler.get_clock() >= phase_boundary_clock and float(_tether.get("hp")) == 30.0 and float(_tether.get("max_hp")) == 60.0 and int(_tether.get("phase")) == 2 and held.status == "running" and held.phase == "warning" and held.cycle == 1 and String(held.reservation_id) == reservation_id and record.get("source_instance_id") == mechanism.get_instance_id() and proof.get("accepted", false) and not proof.get("uses_blast", true) and not proof.get("uses_invulnerability", true) and selected.get("landing") == proof.get("landing") and selected.get("attack_position") == proof.get("attack_position") and original == _retired_sources[previous_kind], "genuine same-world phase2 preserves30HP and admits the other native source through unchanged cooldown/camera rules", str(answer)):
		return
	if not _closed_hit_guards() or not await _portrait(previous_kind + "-phase2-" + kind + "-warning"):
		return
	var escaped: bool = false
	var returned: bool = false
	for segment: Dictionary in proof.path:
		if segment.kind not in ["escape_dash", "positioning_dash"]:
			continue
		if not await _until(float(segment.start_s)):
			return
		var intended: Vector3 = (segment.to - segment.from).normalized()
		var error: String = _swipe(intended)
		var committed: Dictionary = _hero.get_committed_dash_state()
		if not _expect(error.is_empty() and committed.get("active", false) and (committed.direction as Vector3).distance_to(intended) < 0.000001 and committed.distance == _hero.stats.dash_distance and committed.duration_s == _hero.stats.dash_duration, "actual phase2 routed " + String(segment.kind) + " preserves full canonical native dash", error):
			return
		if not await _complete_dash(segment):
			return
		if segment.kind == "escape_dash":
			escaped = true
		else:
			returned = true
	if not await _until(float(proof.primary_time_s)):
		return
	var live: Dictionary = _scheduler.reservation_state(reservation_id)
	if not _expect(escaped and returned and mechanism.state().phase == "recovery" and live.get("state") == "recovery" and _hero.global_position.distance_to(proof.attack_position) < 0.02 and float(proof.response_complete_s) < float(record.recovery_until_s) and float(_hero.get_threat_response_state().primary_cooldown_left_s) == 0.0 and float(_tether.get("hp")) == 30.0 and int(_tether.get("phase")) == 2 and _hero.hp == _hero_hp and _source(previous_kind).state() == _retired_sources[previous_kind], "phase2 real escape/return exposes the same ordinary low tether without resetting HP or restarting its old source"):
		return
	if not _hidden_recovery_marker(kind) or not _hidden_physical_target() or not await _portrait(previous_kind + "-phase2-ordinary-return"):
		return
	var damage: float = float(_hero.stats.primary_damage)
	var remaining_hp: float = maxf(0.0, 30.0 - damage)
	var prior_count: int = _hero.get_world_action_records().size()
	var error: String = _tap(_target_direction())
	var first_wall_ms: int = Time.get_ticks_msec() # After real routed input.
	var actions: Array[Dictionary] = _hero.get_world_action_records()
	if not _expect(error.is_empty() and damage >= 15.0 and damage < 30.0 and remaining_hp > 0.0 and float(_tether.get("hp")) == remaining_hp and float(_tether.get("max_hp")) == 60.0 and int(_tether.get("phase")) == 2 and not bool(_tether.get("dead")) and actions.size() == prior_count + 1 and actions.back().kind == "primary" and actions.back().hits == 1 and actions.back().damage == damage and _hero.last_action.hits == 1, "first actual phase2 primary subtracts resolved damage from30HP (baseline30→10) with genuine hit credit", error + "; " + str(_tether.call("state"))):
		return
	if not await _second_primary_ready(first_wall_ms, float(record.recovery_until_s)):
		return
	prior_count = _hero.get_world_action_records().size()
	_allow_cancelled = true
	error = _tap(_target_direction())
	actions = _hero.get_world_action_records()
	var actual_input: Dictionary = _game.call("get_input_observation_state")
	if not _expect(error.is_empty() and float(_tether.get("hp")) == 0.0 and float(_tether.get("max_hp")) == 60.0 and int(_tether.get("phase")) == 3 and bool(_tether.get("dead")) and actions.size() == prior_count + 1 and actions.back().kind == "primary" and actions.back().hits == 1 and _hero.last_action.hits == 1 and actual_input.last_observation.kind == "primary_tap" and actual_input.last_observation.accepted and not _tether.is_in_group("enemies") and _tether.collision_layer == 0 and _tether.collision_mask == 0 and _scheduler.reservation_state(reservation_id).is_empty() and _all_sources_clear(), "second actual phase2 ordinary primary reaches final0 and synchronously removes target/group/leases/cues without HP reset or blast", error + "; " + str(_tether.call("state"))):
		return
	# The genuine body disable is deferred from the actual primary transaction.
	for _i: int in range(2):
		await process_frame
	var body: CollisionShape3D = _tether.get_node_or_null("RootCollision") as CollisionShape3D
	if not _expect(body != null and body.disabled and body.shape is BoxShape3D and body.get_parent() == _tether and _tether.collision_layer == 0 and _tether.collision_mask == 0 and not _tether.is_in_group("enemies") and float(_tether.get("hp")) == 0.0 and _all_sources_clear() and _hero.hp == _hero_hp and not _hero.dead and _hero.equipment.snapshot() == _kit and _level.call("runtime_error") == "", "real deferred native frame closes the spent body while preserving full Hero HP, exact kit and cleared cues"):
		return
	if not _closed_hit_guards() or not await _portrait(previous_kind + "-spent"):
		return
	for _i: int in range(24):
		if not await _tick():
			return
	var dash_count: int = 0
	for action: Dictionary in _hero.get_world_action_records():
		if action.kind == "dash":
			dash_count += 1
	var checkpoint: Dictionary = _level.current_checkpoint()
	_expect(dash_count == 4 and float(_tether.get("hp")) == 0.0 and int(_tether.get("phase")) == 3 and bool(_tether.get("dead")) and _hero.hp == _hero_hp and _hero.hp == _hero.max_hp and _hero.equipment.snapshot() == _kit and not bool(_level.get("auto_attack")) and _all_sources_clear() and _source(previous_kind).state() == _retired_sources[previous_kind] and _phases.has(kind + ":warning") and _phases.has(kind + ":lock") and _phases.has(kind + ":active") and _phases.has(kind + ":recovery") and not _events.has("fired_blast") and not _events.has("hit") and not _events.has("completion") and not _events.has("checkpoint") and not _events.has("exit") and not _level.is_completed() and checkpoint.id.is_empty() and checkpoint.kind.is_empty(), "same-world two-phase prototype ends with four genuine full dashes, final spent0, full unchanged Hero HP, no restart/reward/campaign progression")


func _open() -> bool:
	_game = MainScene.instantiate()
	if not _compound_extreme:
		_game.set("level_scene_path", ROOM)
	root.add_child(_game)
	_game.call("open_bench") # Public whole-world pause before yielding any tick.
	var old_lab_refs: Array[WeakRef] = []
	var carried_stats: Dictionary = {}
	if _compound_extreme:
		var lab_hero: CinderPlayer = _game.get("player") as CinderPlayer
		var lab_level: CinderLevel = _game.get("active_level") as CinderLevel
		if not _expect(lab_hero != null and lab_level != null and paused and _game.call("is_lab_level") and get_nodes_in_group("enemies").is_empty(), "actual enemy-free paused lab provides the legal carried static-equipment boundary"):
			return false
		for slot: String in ["jacket", "pants", "shoes", "weapon"]:
			if not _expect(lab_hero.equip_item(COMPOUND_KIT[slot]), "actual public lab equip accepts canonical compound " + slot):
				return false
		carried_stats = lab_hero.equipment.resolved_stats().duplicate(true)
		if not _expect(lab_hero.equipment.snapshot() == COMPOUND_KIT and lab_hero.stats == carried_stats, "actual lab holds exact selected static IDs and their resolved stats without private gear edits"):
			return false
		_weakrefs(lab_hero, old_lab_refs)
		_weakrefs(lab_level, old_lab_refs)
		for practice: Node in get_nodes_in_group("practice_targets"):
			if _game.is_ancestor_of(practice):
				_weakrefs(practice, old_lab_refs)
		if not _expect(_game.call("load_level_scene", ROOM), "genuine public fresh transition carries the chosen lab equipment into the native rule room"):
			return false
		_game.call("open_bench") # Pause the fresh transition stack before any tick.
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	if not _expect(_level != null and _hero != null and _level.scene_file_path == ROOM and paused, "actual Main opens the owned garden-root rule prototype paused"):
		return false
	_level.set("auto_attack", false) # Disclosed TEST ONLY source-control selector.
	_tether = _level.get("tether") as StaticBody3D
	_mechanisms = _level.get("mechanisms") as Dictionary
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	if not _expect(_tether != null and _scheduler != null and _mechanisms.keys().size() == 2 and _source("draw") != null and _source("enclose") != null and _level.call("runtime_error") == "" and not bool(_level.get("auto_attack")), "ready actual target/Scheduler/two native sources bind without configuration error", String(_level.call("runtime_error"))):
		return false
	_hero.shells = 0 # Disclosed TEST ONLY empty initial ammo before actual ticks.
	_hero_hp = _hero.hp
	_kit = _hero.equipment.snapshot()
	_fixed_target = _tether.global_transform
	_fixed_sources.clear()
	_events.clear()
	_phases.clear()
	_captured.clear()
	_active_kind = ""
	_allow_cancelled = false
	_retired_sources.clear()
	_barrier = PostActorBarrier.new()
	_game.add_child(_barrier)
	for kind: String in ["draw", "enclose"]:
		var mechanism: CinderLaneMechanism = _source(kind)
		_fixed_sources[kind] = mechanism.global_transform
		mechanism.state_changed.connect(func(current: Dictionary) -> void: _phases[kind + ":" + String(current.phase)] = true)
		mechanism.hit_resolved.connect(func(_id: String, _cycle: int, _result: Dictionary) -> void: _events.append("hit"))
	_hero.fired.connect(func(kind: String) -> void: _events.append("fired_" + kind))
	_level.completion_requested.connect(func(_id: String, _completion: String) -> void: _events.append("completion"))
	_level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _boundary: String) -> void: _events.append("checkpoint"))
	_level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _events.append("exit"))
	if _compound_extreme:
		if not _expect(_hero.equipment.snapshot() == COMPOUND_KIT and _hero.stats == carried_stats and _hero.hp == _hero.max_hp and _hero_hp == _hero.max_hp, "fresh actual traveller carries exact compound static gear/resolved stats with full initial HP"):
			return false
		for _i: int in range(5):
			await process_frame # Paused native queue cleanup, never a combat tick.
		var released: bool = true
		for retained: WeakRef in old_lab_refs:
			released = released and retained.get_ref() == null
		if not _expect(released and get_nodes_in_group("practice_targets").is_empty() and _scheduler.get_clock() == 0.0 and _hero.get_world_action_records().is_empty() and paused, "the real old lab/player/targets release while the fresh rule world remains paused at clock0"):
			return false
	if not _expect(_scheduler.encounter_profile().get("id") == "standard" and _hero.hp == _hero.max_hp, "plain shared Main binds genuine Standard; no Assisted profile or HP-reset claim is fabricated"):
		return false
	return _expect(_scheduler.get_clock() == 0.0 and _scheduler.reservations().is_empty() and _hero.shells == 0 and float(_tether.get("hp")) == 60.0 and float(_tether.get("max_hp")) == 60.0 and int(_tether.get("phase")) == 1 and not bool(_tether.get("dead")) and _tether.is_in_group("enemies") and _tether.collision_layer == 2 and _source("draw").state().status == "idle" and _source("draw").state().cycle == 0 and _source("enclose").state().status == "idle" and _source("enclose").state().cycle == 0 and _hero.presentation_id == "act3_traveller" and _barrier.process_physics_priority > _source("draw").process_physics_priority and _barrier.process_physics_priority > _source("enclose").process_physics_priority, "fresh native unit has original60HP phase1, empty initial ammo, canonical traveller and zero admitted cycles")


func _admit(kind: String, direction: Vector3) -> Dictionary:
	_active_kind = kind
	if paused:
		_game.call("resume_lab")
	for _i: int in range(180):
		if bool(_hero.get_threat_response_state().stable):
			var answer: Dictionary = _level.call("start_attack", kind, direction)
			if answer.get("accepted", false):
				var error: String = _game.call("camera_framing_error", _level.camera_framing_points())
				if _expect(error.is_empty() and _source(kind).state().status == "running" and _source(kind).state().phase == "warning", "current real shared camera admits " + kind + " before its actual source is armed", error):
					return answer
				return {}
		if not await _tick():
			return {}
	_expect(false, "finite ordinary camera settling admits " + kind, str(_level.call("state")))
	return {}


func _hidden_recovery_marker(kind: String) -> bool:
	var marker: MeshInstance3D = _source(kind).get_cue().get_node("RequiredSourceMarker") as MeshInstance3D
	var before_hp: float = float(_tether.get("hp"))
	var before_phase: int = int(_tether.get("phase"))
	# TEST ONLY synchronous native presentation fault; restore before any tick.
	marker.visible = false
	var rejected: Dictionary = _tether.call("take_damage", 1.0, Vector3.ZERO)
	var ok: bool = not rejected.get("accepted", true) and rejected.get("hp_damage") == 0.0 and float(_tether.get("hp")) == before_hp and int(_tether.get("phase")) == before_phase
	marker.visible = true
	return _expect(ok and _level.call("runtime_error") == "", "actual hidden recovery source marker rejects damage before the next mechanism tick")


func _hidden_physical_target() -> bool:
	var before_hp: float = float(_tether.get("hp"))
	var before_phase: int = int(_tether.get("phase"))
	var scenery: Node3D = _level.get("scenery") as Node3D
	for part: MeshInstance3D in [_tether.get_node("RootBody"), _tether.get_node("TetherBand"), scenery.get_node("PhysicalRootEnd0")]:
		for property: String in ["layers", "transparency"]:
			var old: Variant = part.get(property)
			# TEST ONLY synchronous native renderer fault; restore before any tick.
			part.set(property, 0 if property == "layers" else 1.0)
			var rejected: Dictionary = _tether.call("take_damage", 1.0, Vector3.ZERO)
			var ok: bool = not rejected.get("accepted", true) and rejected.get("hp_damage") == 0.0 and float(_tether.get("hp")) == before_hp and int(_tether.get("phase")) == before_phase
			part.set(property, old)
			if not _expect(ok and _level.call("runtime_error") == "", "actual hidden physical target/root " + property + " rejects recovery damage immediately"):
				return false
	return true


func _closed_hit_guards() -> bool:
	var before: Dictionary = _tether.call("state")
	var rejected: Dictionary = _tether.call("take_damage", 1.0, Vector3.ZERO)
	if not _expect(not rejected.get("accepted", true) and float(rejected.get("hp_damage", -1.0)) == 0.0 and _tether.call("state") == before, "closed actual tether rejects positive direct damage with no mutation"):
		return false
	for invalid: Dictionary in [{"damage": 0.0, "impulse": Vector3.ZERO}, {"damage": -1.0, "impulse": Vector3.ZERO}, {"damage": INF, "impulse": Vector3.ZERO}, {"damage": 1.0, "impulse": Vector3(INF, 0, 0)}]:
		rejected = _tether.call("take_damage", invalid.damage, invalid.impulse)
		if not _expect(not rejected.get("accepted", true) and float(rejected.get("hp_damage", -1.0)) == 0.0 and _tether.call("state") == before, "invalid target damage/impulse fails closed without HP/phase mutation"):
			return false
	return true


func _complete_dash(segment: Dictionary) -> bool:
	for _i: int in range(60):
		if float(_hero.get_threat_response_state().motion.dash_left_s) == 0.0:
			var actions: Array[Dictionary] = _hero.get_world_action_records()
			var final: Dictionary = {} if actions.is_empty() else actions.back()
			var planar_error: float = Vector2(_hero.global_position.x, _hero.global_position.z).distance_to(Vector2(segment.to.x, segment.to.z))
			return _expect(planar_error < 0.005 and _hero.is_on_floor() and final.get("kind") == "dash" and not final.get("collision_shortened", true) and not final.get("movement_damage", true) and absf(float(final.get("distance", 0.0)) - float(_hero.stats.dash_distance)) < 0.005 and final.get("equipment_ids") == _kit, "real complete dash reaches native proved landing with full travel and unchanged kit", str(final))
		if not await _tick():
			return false
	return _expect(false, "finite shared dash reaches its actual endpoint")


func _second_primary_ready(first_wall_ms: int, recovery_until: float) -> bool:
	for _i: int in range(90):
		if Time.get_ticks_msec() - first_wall_ms > 280 and float(_hero.get_threat_response_state().primary_cooldown_left_s) == 0.0:
			return _expect(_source(_active_kind).state().phase == "recovery" and _scheduler.get_clock() < recovery_until, "second tap clears the real280ms blast window and native cooldown while ordinary recovery remains open")
		if not await _tick():
			return false
	return _expect(false, "finite second ordinary tap timing is available")


func _pause_check() -> bool:
	if not _expect(_game.call("request_pause_deferred"), "public Game requests an actual completed native pause"):
		return false
	for _i: int in range(4):
		await process_frame
	var before: Dictionary = _observation()
	for _i: int in range(5):
		await process_frame
	if not _expect(paused and not _game.call("is_pause_requested") and before == _observation(), "whole native warning pause freezes actual Hero/target/cues/Scheduler/input/camera without snapshot claims"):
		return false
	var paired: Dictionary = _level.snapshot_state()
	var player: Dictionary = _hero.snapshot_state()
	if not _expect(not paired.is_empty() and not player.is_empty() and _level.snapshot_error_with_player(paired, player).is_empty() and float(paired.local.scheduler.clock_s) == _scheduler.get_clock() and float(paired.local.tether.clock_s) == _scheduler.get_clock() and int(paired.local_snapshot_version) == 2, "small prototype captures the complete actual paired warning at the paused barrier", _level.last_snapshot_error):
		return false
	_game.call("resume_lab")
	return _expect(not paused, "public resume continues the same actual rule unit")


func _tick() -> bool:
	if paused:
		return _expect(false, "ordinary rule response cannot tick while paused")
	_barrier.waiting = true
	await _barrier.observed
	var error: String = String(_level.call("runtime_error"))
	var fixed: bool = _tether.global_transform == _fixed_target
	for kind: String in ["draw", "enclose"]:
		var mechanism: CinderLaneMechanism = _source(kind)
		fixed = fixed and mechanism.global_transform == _fixed_sources[kind]
		if mechanism.state().status == "cancelled" and not _allow_cancelled:
			# Only an exact recorded phase1 closure may remain on the retired
			# source while its sibling owns the genuine new phase2 exchange.
			var historical_closed: bool = kind != _active_kind and _retired_sources.has(kind) and mechanism.state() == _retired_sources[kind]
			if not historical_closed:
				error = "Unexpected actual " + kind + " cancellation: " + String(mechanism.state().last_cancel_reason)
	if not error.is_empty() or not fixed or _hero.hp != _hero_hp or _hero.dead or _hero.equipment.snapshot() != _kit or _events.has("fired_blast") or _events.has("hit") or _scheduler.get_clock() > 12.0:
		return _expect(false, "finite post-actor rule ticks preserve stationary sources, Hero HP and canonical ordinary controls", error + "; " + str(_level.call("state")))
	return true


func _until(target: float) -> bool:
	for _i: int in range(360):
		if _scheduler.get_clock() >= target:
			return _expect(_scheduler.get_clock() <= target + 1.0 / float(Engine.physics_ticks_per_second) + 0.000000001, "action uses the first actual post-actor tick at its native proof deadline", "target=" + str(target) + "; actual=" + str(_scheduler.get_clock()))
		if not await _tick():
			return false
	return _expect(false, "finite native rule deadline is reachable")


func _held_teardown() -> void:
	if not await _open():
		return
	var answer: Dictionary = await _admit("draw", Vector3.LEFT)
	if answer.is_empty():
		return
	if not _expect(_source("draw").state().status == "running" and not _scheduler.reservations().is_empty() and _source("draw").get_cue().state().phase == "warning", "teardown fixture owns a genuinely held actual warning lease/cue"):
		return
	await _close(true)


func _all_sources_clear() -> bool:
	if not is_instance_valid(_scheduler):
		return false
	for kind: String in ["draw", "enclose"]:
		if not is_instance_valid(_source(kind)) or _source(kind).get_cue() == null:
			return false
	if not _scheduler.reservations().is_empty():
		return false
	for kind: String in ["draw", "enclose"]:
		var mechanism: CinderLaneMechanism = _source(kind)
		if mechanism.state().status == "running" or mechanism.state().phase != "clear" or mechanism.get_cue().state().phase != "clear":
			return false
	return true


func _observation() -> Dictionary:
	var sources: Dictionary = {}
	for kind: String in ["draw", "enclose"]:
		var mechanism: CinderLaneMechanism = _source(kind)
		sources[kind] = {"state": mechanism.state(), "transform": mechanism.global_transform, "cue": mechanism.get_cue().state(), "control": _scheduler.source_control_state(mechanism)}
	return {"hero": _hero.snapshot_state(), "hero_transform": _hero.global_transform, "dash": _hero.get_committed_dash_state(), "target": _tether.call("state"), "target_transform": _tether.global_transform, "sources": sources, "clock": _scheduler.get_clock(), "level": _level.call("state"), "events": _events.duplicate(), "camera": (_game.get("camera") as Camera3D).global_transform, "input": _game.call("get_input_observation_state")}


func _portrait(label: String) -> bool:
	if not _capture or _captured.has(label):
		return true
	await RenderingServer.frame_post_draw
	var was_paused: bool = paused
	paused = true # Disclosed TEST ONLY render freeze; no camera/UI alteration.
	var before: Dictionary = _observation()
	await process_frame
	await RenderingServer.frame_post_draw
	var error: String = String(_game.call("camera_framing_error", _level.camera_framing_points()))
	var image: Image = root.get_texture().get_image()
	var directory: String = ProjectSettings.globalize_path("res://.cinder/a3-l4-rule-portraits")
	var ok: bool = error.is_empty() and before == _observation() and image != null and image.get_size() == Vector2i(339, 736)
	if ok:
		ok = DirAccess.make_dir_recursive_absolute(directory) == OK and image.save_png(directory.path_join(label + ".png")) == OK
	paused = was_paused
	if ok:
		_captured[label] = true
		print("PORTRAIT: " + directory.path_join(label + ".png"))
	return _expect(ok, "unchanged actual native339×736 portrait " + label, error)


func _source(kind: String) -> CinderLaneMechanism:
	return _mechanisms.get(kind) as CinderLaneMechanism


func _target_direction() -> Vector3:
	var direction: Vector3 = _tether.global_position - _hero.global_position
	direction.y = 0.0
	return direction.normalized()


func _swipe(direction: Vector3) -> String:
	var size: Vector2 = root.get_visible_rect().size
	var start: Vector2 = size * Vector2(0.5, 0.60)
	var finish: Vector2 = start + _screen_direction(direction) * size.x * 0.22
	if not root.get_visible_rect().has_point(finish) or finish.y < 100.0:
		return "Actual routed release is outside the viewport input region"
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = start
	root.push_input(press, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = finish
	drag.relative = finish - start
	root.push_input(drag, true)
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.pressed = false
	release.position = finish
	root.push_input(release, true)
	return "" if float(_hero.get_threat_response_state().motion.dash_left_s) > 0.0 and (_game.call("get_aim_anchor_normalized") as Vector2).distance_to(finish / size) < 0.000001 else "Shared router did not begin the actual dash and retain its final release anchor"


func _tap(direction: Vector3) -> String:
	var point: Vector2 = _game.call("get_aim_anchor") + _screen_direction(direction) * 60.0
	if not root.get_visible_rect().has_point(point) or point.y < 100.0:
		return "Actual primary tap is outside the viewport input region"
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = point
	root.push_input(press, true)
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.pressed = false
	release.position = point
	root.push_input(release, true)
	return ""


func _screen_direction(direction: Vector3) -> Vector2:
	var camera: Camera3D = _game.get("camera") as Camera3D
	var right: Vector3 = camera.global_basis.x
	var down: Vector3 = camera.global_basis.z
	right.y = 0.0
	down.y = 0.0
	return Vector2(direction.dot(right.normalized()), direction.dot(down.normalized())).normalized()


func _weakrefs(node: Node, result: Array[WeakRef]) -> void:
	result.append(weakref(node))
	for child: Node in node.get_children():
		_weakrefs(child, result)


func _close(held: bool = false) -> void:
	if not is_instance_valid(_game):
		return
	var old: Array[WeakRef] = []
	_weakrefs(_game, old)
	if is_instance_valid(_level):
		_level.exit_level()
		_expect(_all_sources_clear(), "public " + ("held-warning " if held else "") + "level exit synchronously clears actual source leases/cues")
	if is_instance_valid(_barrier):
		_barrier.waiting = false
	_game.queue_free()
	paused = false
	for _i: int in range(5):
		await process_frame
	var all_released: bool = true
	for retained: WeakRef in old:
		all_released = all_released and retained.get_ref() == null
	_expect(all_released and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "all native old-world descendants/Hero/target/sources/cues release before a replacement")
	_game = null
	_hero = null
	_level = null
	_tether = null
	_mechanisms.clear()
	_scheduler = null
	_barrier = null


func _finish() -> void:
	await _close()
	await create_timer(0.15, true, false, true).timeout # Finite actual audio drain.
	print("Garden root phase2 rule: %d checks; failures: %d. Two-source prototype through genuine final0; one selected static kit only, Standard only; no full-L4, saves, production transitions or playthrough acceptance." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	if ok:
		print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok
