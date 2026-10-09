extends "res://scripts/acts/act3/mirror_echo_rule_room.gd"
## TEST ONLY managed native C52 court. Reuses the actual owned floor, fixed
## obstacle, immutable 36HP definition and sixteen-mesh source. No campaign
## completion, checkpoint, reward or whole Mirror Sea acceptance is granted.

const Authored = preload("res://scripts/combat/authored_enemy_sequence.gd")
const History = preload("res://scripts/combat/authored_echo_terminal_receipt.gd")
const FIXTURE_API: String = "act3-echo-lifecycle-fixture-1"
const PEER_ID: String = "mirror-rule/test-only-ready-peer"
const PEER_EPOCH: String = "A3-L3/test-only-ready-peer"
var _fixture_enabled: bool = false
var _fixture_busy: bool = false
var _peer: Node3D


func _on_enter_level() -> void:
	# Initial configuration stays strict API1 until the test's public opt-in.
	# A fresh paused saved recipient must remain untracked before preparation.
	super._on_enter_level()
	if last_configuration_error.is_empty() and not echo.call("retain_source_environment", get_parent() as Node3D, [_floor]):
		last_configuration_error = String(echo.get("source_snapshot_error"))
	objective_text = "TEST ONLY / ONE RETAINED REAL ECHO"


func enable_cycles() -> bool:
	if _fixture_busy or _fixture_enabled or not last_configuration_error.is_empty():
		return false
	var accepted: bool = echo.call("enable_authored_cycle_tracking", threat_scheduler, {"hero": hero}, [_floor], _context)
	_fixture_enabled = accepted
	last_admission_reason = "" if accepted else String(echo.get("source_snapshot_error"))
	return accepted


func prepare_next_cycle() -> bool:
	if _fixture_busy or not _fixture_enabled or get_tree().paused or bool(echo.get("dead")):
		return false
	var generation: int = echo.call("get_authored_cycle_generation") + 1
	var reader = Authored.new()
	if not reader.configure(SOURCE_ID + "/own-sequence-%d" % generation, echo.call("source_definition"), SOURCE_ID, SOURCE_EPOCH, generation, echo.call("source_profile"), echo.call("prepared_world")):
		last_admission_reason = reader.last_error
		return false
	if not echo.call("prepare_next_authored_cycle", SOURCE_ID + "/playback-%d" % generation, reader.snapshot_state()):
		last_admission_reason = String(echo.get("last_error"))
		return false
	_context.generation = generation
	_projection = {}
	_proof = {}
	_lease = {}
	_view_positions.clear()
	_admitted = false
	_locked = false
	last_admission_reason = ""
	return true


func admit_cycle() -> bool:
	if _fixture_busy or not _fixture_enabled or get_tree().paused or _admitted or not hero.is_on_floor() or String(echo.call("source_phase")) != "cycle_ready":
		return false
	_context.generation = echo.call("get_authored_cycle_generation")
	# Current actual witness and native portrait checks precede real request.
	super._try_admit()
	return _admitted and last_configuration_error.is_empty()


func _physics_process(_delta: float) -> void:
	if not _active or not _fixture_enabled or _fixture_busy or not is_instance_valid(hero):
		return
	_follow_scenery()
	if _admitted and not _locked and not _lease.is_empty() and threat_scheduler.get_clock() >= float(_lease.lock_from_s):
		last_camera_error = _current_view_error()
		_locked = true
		if not last_camera_error.is_empty():
			echo.call("cancel", "test_actual_locked_view_unreadable")
		else:
			var answer: Dictionary = threat_scheduler.commit_authored_replay(String(_lease.id), combat_response())
			if answer.get("accepted", false):
				_lease = answer.reservation.duplicate(true)
				_proof = answer.proof.duplicate(true)
				_retain_view_positions(_proof)
			else:
				last_admission_reason = String(answer.get("reason", "Actual lock refused"))
	if _admitted and _locked and String(echo.call("source_phase")) not in ["complete", "cancelled", "defeated"]:
		last_camera_error = _current_view_error()
		if not last_camera_error.is_empty():
			echo.call("cancel", "test_actual_exchange_view_unreadable")


func _current_view_error() -> String:
	var points: Array = camera_framing_points()
	if not last_camera_framing_error.is_empty():
		return last_camera_framing_error
	return shared_shell.call("camera_framing_error", points)


func camera_framing_points() -> Array:
	last_camera_framing_error = ""
	if not _active:
		return [] # Exited native level has released its actual Hero/shell binding.
	var art: Dictionary = echo.call("framing_points") if is_instance_valid(echo) else {"error": "Missing actual source", "points": []}
	if not String(art.error).is_empty():
		last_camera_framing_error = String(art.error)
		return []
	var points: Array = []
	_enclose(points, art.points)
	var danger: Array = []
	for endpoint: Dictionary in native_definition().route:
		_append_box(danger, endpoint.position, 0.65, 1.45)
	for event: Dictionary in _projection.get("events", []):
		var bounds: Array = event.bounds
		for x: float in [float(bounds[0]), float(bounds[2])]:
			for z: float in [float(bounds[1]), float(bounds[3])]:
				danger.append(Vector3(x, float(event.floor_y) + 0.035, z))
	for cue: Node3D in echo.call("get_cues"):
		for label: String in ["RequiredSourceMarker", "RequiredFootprintOutline", "RequiredFootprintFill"]:
			var visual: MeshInstance3D = cue.get_node_or_null(label) as MeshInstance3D
			if visual != null and visual.is_visible_in_tree() and visual.mesh != null:
				_mesh_corners(danger, visual)
	var route: MeshInstance3D = echo.get_node_or_null("ExactHarmlessRoutes") as MeshInstance3D
	if route != null and route.is_visible_in_tree() and route.mesh != null:
		_mesh_corners(danger, route)
	_enclose(points, danger)
	# Native live Game supplies the unchanged Hero quad/shadow/capsule. These
	# translated path display bounds do not establish saved-candidate optics.
	var hero_points: Array = shared_shell.call("player_camera_framing_points")
	if hero_points.is_empty():
		last_camera_framing_error = "Actual native Hero display bounds required"
		return []
	for position: Vector3 in _view_positions:
		var landing: Array = []
		for corner: Vector3 in hero_points:
			landing.append(corner + position - hero.global_position)
		_enclose(points, landing)
	return points


func _mesh_corners(points: Array, visual: MeshInstance3D) -> void:
	var bounds: AABB = visual.mesh.get_aabb()
	for index: int in range(8):
		points.append(visual.global_transform * bounds.get_endpoint(index))


func _enclose(points: Array, complete: Array) -> void:
	if complete.is_empty():
		return
	var low: Vector3 = complete[0]
	var high: Vector3 = complete[0]
	for point: Vector3 in complete:
		low = low.min(point)
		high = high.max(point)
	var box := AABB(low, high - low)
	for index: int in range(8):
		points.append(box.get_endpoint(index))


func state() -> Dictionary:
	var result: Dictionary = super.state()
	result.api_revision = FIXTURE_API
	result["managed_enabled"] = _fixture_enabled
	return result


func scheduler_bindings() -> Dictionary:
	var result: Dictionary = super.scheduler_bindings()
	if is_instance_valid(_peer):
		result.owners[PEER_ID] = _peer
	return result


func _peer_context(generation: int) -> Dictionary:
	var result: Dictionary = _context.duplicate(true)
	result.source_id = PEER_ID
	result.source_epoch = PEER_EPOCH
	result.generation = generation
	return result


func _construct_peer() -> bool:
	if is_instance_valid(_peer) or not get_tree().paused:
		return false
	_peer = Echo.new()
	_peer.name = "TestOnlyReadyNativePeer"
	add_child(_peer)
	return _peer.call("configure_source", PEER_ID, PEER_EPOCH, 1, native_definition(), echo.call("source_profile"), echo.call("prepared_world"), threat_scheduler) and _peer.call("retain_source_environment", get_parent() as Node3D, [_floor])


func add_ready_peer() -> bool:
	if _fixture_busy or not _fixture_enabled or String(echo.call("source_phase")) != "defeated" or not _construct_peer():
		return false
	return _peer.call("enable_authored_cycle_tracking", threat_scheduler, {"hero": hero}, [_floor], _peer_context(1))


func construct_saved_recipients(data: Dictionary, player: Dictionary) -> String:
	# Immutable native topology only, before source/journal preflight. No saved
	# HP, generation/history, event, lease or actual Player state is committed.
	if _fixture_busy or _fixture_enabled or not get_tree().paused:
		return "Construct only the fresh paused untracked recipient topology"
	var error: String = History.transport_error(data)
	if error.is_empty():
		error = hero.snapshot_error(player)
	if not error.is_empty():
		return error
	if not data.get("peers") is Array or data.peers.size() > 1:
		return "Bounded explicit test-only peer topology required"
	if data.peers.is_empty():
		return ""
	var packet: Variant = data.peers[0]
	if not packet is Dictionary or not Value.keys_error(packet, ["source", "playback"]).is_empty() or not packet.source is Dictionary or not packet.playback is Dictionary or packet.source.get("source_id") != PEER_ID or packet.source.get("source_epoch") != PEER_EPOCH or packet.playback.get("source_id") != PEER_ID or packet.playback.get("source_epoch") != PEER_EPOCH:
		return "Only the labelled actual fixed-recipe peer can be constructed"
	return "" if _construct_peer() else "Actual immutable peer recipient construction failed"


func _view_receipt() -> Dictionary:
	var positions: Array = []
	for position: Vector3 in _view_positions:
		positions.append(Value.vector3(position))
	return {"api_revision": "act3-managed-echo-view-1", "source_id": SOURCE_ID, "source_epoch": SOURCE_EPOCH, "generation": echo.call("get_authored_cycle_generation"), "positions": positions}


func _fixture_view_error(view: Dictionary, generation: int) -> String:
	if not Value.keys_error(view, ["api_revision", "source_id", "source_epoch", "generation", "positions"]).is_empty() or view.get("api_revision") != "act3-managed-echo-view-1" or view.get("source_id") != SOURCE_ID or view.get("source_epoch") != SOURCE_EPOCH or not view.get("generation") is int or view.generation != generation or not view.get("positions") is Array or view.positions.size() > 12:
		return "Closed same-generation native view positions required"
	var unique: Array[Vector3] = []
	for value: Variant in view.positions:
		if not Value.is_vector3(value):
			return "Exact native view position transport required"
		var position: Vector3 = Value.read_vector3(value)
		if unique.has(position) or not FloorRect.grow(-0.33).has_point(Vector2(position.x, position.z)) or absf(position.y) > 0.05:
			return "View-only positions must remain on the actual permanent floor"
		unique.append(position)
	return ""


func _capture_local_state() -> Dictionary:
	if _fixture_busy or not _fixture_enabled:
		return {}
	var player: Dictionary = hero.snapshot_state()
	var bindings: Dictionary = scheduler_bindings()
	var scheduler: Dictionary = threat_scheduler.snapshot_state(bindings)
	var playback: Dictionary = echo.call("snapshot_state", scheduler, bindings)
	var source: Dictionary = echo.call("capture_source", player, scheduler, playback)
	var peers: Array = []
	if is_instance_valid(_peer):
		var peer_playback: Dictionary = _peer.call("snapshot_state", scheduler, bindings)
		var peer_source: Dictionary = _peer.call("capture_source", player, scheduler, peer_playback)
		if peer_playback.is_empty() or peer_source.is_empty():
			return {}
		peers.append({"source": peer_source, "playback": peer_playback})
	return {"scheduler": scheduler, "playback": playback, "source": source, "view": _view_receipt(), "peers": peers} if not source.is_empty() and not playback.is_empty() and not scheduler.is_empty() else {}


func _preflight(data: Dictionary, player: Dictionary, paired: bool) -> String:
	var error: String = History.transport_error(data)
	if error.is_empty():
		error = History.transport_error(player)
	if error.is_empty():
		error = Value.keys_error(data, ["source", "scheduler", "playback", "view", "peers"])
	if not error.is_empty():
		return error
	for key: String in ["source", "scheduler", "playback", "view"]:
		if not data[key] is Dictionary:
			return "Complete typed managed fixture unit required"
	if not data.playback.get("generation") is int:
		return "Exact actual managed generation required"
	if not data.peers is Array or data.peers.size() > 1 or data.peers.size() != (1 if is_instance_valid(_peer) else 0):
		return "Actual full test-only recipient topology must match the saved unit"
	error = hero.snapshot_error(player)
	if error.is_empty():
		error = _fixture_view_error(data.view, data.playback.generation)
	if error.is_empty():
		error = echo.call("source_record_error", data.source, player, data.scheduler, data.playback)
	if not error.is_empty():
		return error
	var staged: Dictionary = scheduler_bindings()
	staged["authored_owner_bindings"] = {SOURCE_ID: echo.call("staged_source_binding", data.source, player, data.scheduler, data.playback)}
	staged["authored_cycle_playback_ids"] = {SOURCE_ID: data.playback.playback_id}
	for packet: Variant in data.peers:
		if not packet is Dictionary or not Value.keys_error(packet, ["source", "playback"]).is_empty() or not packet.source is Dictionary or not packet.playback is Dictionary or packet.source.get("source_id") != PEER_ID or packet.source.get("source_epoch") != PEER_EPOCH:
			return "Complete exact labelled peer unit required"
		error = _peer.call("source_record_error", packet.source, player, data.scheduler, packet.playback)
		if not error.is_empty():
			return error
		staged.authored_owner_bindings[PEER_ID] = _peer.call("staged_source_binding", packet.source, player, data.scheduler, packet.playback)
		staged.authored_cycle_playback_ids[PEER_ID] = packet.playback.playback_id
	error = threat_scheduler.snapshot_error(data.scheduler, staged)
	if not error.is_empty():
		return error
	if data.scheduler.get("encounter_id") != ENCOUNTER_ID or not data.scheduler.get("world_revision") is int or data.scheduler.world_revision != 1:
		return "Exact actual fixture encounter/world epoch required"
	if paired:
		var saved_context: Dictionary = _context.duplicate(true)
		saved_context.generation = data.playback.generation
		error = echo.call("snapshot_error", data.playback, threat_scheduler, data.scheduler, staged, {"hero": hero}, [_floor], saved_context)
		if error.is_empty() and not data.peers.is_empty():
			error = _peer.call("snapshot_error", data.peers[0].playback, threat_scheduler, data.scheduler, staged, {"hero": hero}, [_floor], _peer_context(data.peers[0].source.generation))
		return error
	return ""


func prepare_saved_unit(data: Dictionary, player: Dictionary) -> String:
	if _fixture_busy or _fixture_enabled or not get_tree().paused:
		return "Prepare one fresh paused untracked fixture recipient"
	var error: String = _preflight(data, player, false)
	if not error.is_empty():
		return error
	_fixture_busy = true
	var saved_context: Dictionary = _context.duplicate(true)
	saved_context.generation = data.playback.generation
	var accepted: bool = echo.call("prepare_authored_restore", data.playback, threat_scheduler, {"hero": hero}, [_floor], saved_context)
	var failed_actor: Node3D = echo
	if accepted and not data.peers.is_empty():
		failed_actor = _peer
		accepted = _peer.call("prepare_authored_restore", data.peers[0].playback, threat_scheduler, {"hero": hero}, [_floor], _peer_context(data.peers[0].source.generation))
	_fixture_busy = false
	if not accepted:
		error = String(failed_actor.get("source_snapshot_error"))
		if error.is_empty():
			error = String(failed_actor.get("last_error"))
		return error if not error.is_empty() else "Actual managed recipient preparation refused"
	_context = saved_context
	_fixture_enabled = true
	return _preflight(data, player, true)


func prevalidate_saved_unit(data: Dictionary, player: Dictionary) -> String:
	# Pure first-stage actor/journal proof precedes immutable recipe construction.
	return _preflight(data, player, false)


func _local_snapshot_error(data: Dictionary) -> String:
	return _preflight(data, hero.snapshot_state(), true)


func _local_snapshot_error_with_player(data: Dictionary, player: Dictionary) -> String:
	return _preflight(data, player, true)


func _on_enter_restore_candidate(data: Dictionary, player: Dictionary) -> String:
	_on_enter_level()
	if not last_configuration_error.is_empty():
		return last_configuration_error
	var error: String = construct_saved_recipients(data, player)
	if not error.is_empty():
		return error
	return prepare_saved_unit(data, player)


func restore_candidate_construction_required() -> bool:
	return true


func _restore_local_state(data: Dictionary) -> void:
	var player: Dictionary = hero.snapshot_state()
	var physical: bool = echo.call("restore_source_physical", data.source, player, data.scheduler, data.playback)
	assert(physical, "Complete production native physical source preflight changed")
	if not data.peers.is_empty():
		var peer_physical: bool = _peer.call("restore_source_physical", data.peers[0].source, player, data.scheduler, data.peers[0].playback)
		assert(peer_physical, "Complete actual native peer physical preflight changed")
	var restored_scheduler: bool = threat_scheduler.restore_state(data.scheduler, scheduler_bindings())
	assert(restored_scheduler, "Complete actual managed Scheduler journal commit failed")
	var actual: Dictionary = threat_scheduler.snapshot_state_for_authored_restore(echo, scheduler_bindings()) if not echo.call("get_authored_cycle_restore_recipe").is_empty() else threat_scheduler.snapshot_state(scheduler_bindings())
	assert(Authored.exact_equal(actual, data.scheduler), "Actual actor/journal intermediate pair differs")
	var restored_playback: bool = echo.call("restore_state", data.playback, threat_scheduler, data.scheduler, scheduler_bindings(), {"hero": hero}, [_floor], _context)
	assert(restored_playback, "Complete production quiet Playback commit failed")
	assert(echo.call("verify_restored_source_phase", data.source), "Actual restored physical/Playback source phase differs")
	if not data.peers.is_empty():
		var peer_playback: bool = _peer.call("restore_state", data.peers[0].playback, threat_scheduler, data.scheduler, scheduler_bindings(), {"hero": hero}, [_floor], _peer_context(data.peers[0].source.generation))
		assert(peer_playback and _peer.call("verify_restored_source_phase", data.peers[0].source), "Actual quiet peer Playback/native source phase differs")
	_projection = data.playback.get("projection", {}).duplicate(true)
	_lease = data.playback.get("exchange", {}).duplicate(true)
	_admitted = data.playback.status != "cycle_ready"
	_locked = bool(_lease.get("adapter", {}).get("locked", false))
	_proof = {}
	_view_positions.clear()
	for point: Array in data.view.positions:
		_view_positions.append(Value.read_vector3(point))
	_follow_scenery()


func _on_exit_level() -> void:
	_fixture_enabled = false
	_active = false
	# Managed journals deliberately refuse encounter reset. Retire each real
	# held owner BEFORE inherited exit releases Hero/shell and before removal.
	# Empty, ready and terminal sources have no held lease and remain inert.
	if is_instance_valid(threat_scheduler) and threat_scheduler.is_inside_tree() and not threat_scheduler.is_queued_for_deletion():
		for source: Node3D in [echo, _peer]:
			_retire_held_fixture_source(source)
	super._on_exit_level()


func _retire_held_fixture_source(source: Node3D) -> void:
	if not is_instance_valid(source) or source.is_queued_for_deletion() or not source.is_inside_tree():
		return
	# This public retained-owner view is pure and does not prune. A view-guard
	# fault must not hide a still-held native lease from teardown.
	var control: Dictionary = threat_scheduler.source_control_state(source)
	assert(not control.is_empty(), "Fixture exit requires actual same-world owner custody")
	var held: Array = control.reservations
	if held.is_empty():
		return
	var current: Dictionary = source.call("state")
	assert(control.outside_transaction and held.size() == 1 and current.get("status") == "running", "Retire the genuine running fixture owner outside native transactions")
	var reservation_id: String = String(held[0].id)
	assert(int(held[0].source_instance_id) == source.get_instance_id() and current.get("reservation_id") == reservation_id and held[0].adapter.get("kind") == "authored_replay", "Retirement must name this actual owned authored lease")
	var callbacks: Dictionary = {"state": 0, "failed": 0, "invalidated": 0}
	var state_observer: Callable = func(_value: Dictionary) -> void: callbacks.state += 1
	var failure_observer: Callable = func(_reason: String) -> void: callbacks.failed += 1
	var invalidation_observer: Callable = func(id: String, _reason: String) -> void:
		if id == reservation_id:
			callbacks.invalidated += 1
	source.connect("state_changed", state_observer)
	source.connect("playback_failed", failure_observer)
	threat_scheduler.reservation_invalidated.connect(invalidation_observer)
	var reason: String = "test_fixture_whole_parent_exit"
	var accepted: bool = source.call("cancel", reason)
	if is_instance_valid(source):
		source.disconnect("state_changed", state_observer)
		source.disconnect("playback_failed", failure_observer)
	if is_instance_valid(threat_scheduler):
		threat_scheduler.reservation_invalidated.disconnect(invalidation_observer)
	assert(is_instance_valid(source) and source.is_inside_tree() and is_instance_valid(threat_scheduler) and threat_scheduler.is_inside_tree(), "Native retirement callbacks must finish before whole-parent disposal")
	var after: Dictionary = threat_scheduler.source_control_state(source)
	var terminal: Dictionary = source.call("get_authored_cycle_terminal_receipt")
	assert(accepted and not after.is_empty() and after.reservations.is_empty() and source.call("state").get("status") == "cancelled" and terminal.get("outcome") == "cancelled" and terminal.get("reason") == reason and terminal.get("exchange", {}).get("id") == reservation_id, "Actual cancellation must release the original lease and seal its earned terminal receipt")
	assert(Authored.exact_equal(control.clock_s, after.clock_s) and callbacks == {"state": 1, "failed": 1, "invalidated": 1}, "Fixture retirement counts genuine cleanup callbacks separately without advancing time")
	print("TEST FIXTURE EXIT RETIREMENT: owner=", source.get_instance_id(), " reservation=", reservation_id, " clock_s=", after.clock_s, " callbacks=", callbacks, " native_owner_and_scheduler_inside_tree=true; earned journal/tombstone retained until whole-parent disposal")
