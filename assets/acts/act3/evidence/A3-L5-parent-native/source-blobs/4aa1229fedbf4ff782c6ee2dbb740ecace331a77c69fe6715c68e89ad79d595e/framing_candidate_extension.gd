extends RefCounted
## UNEXECUTED TEST ONLY extension for the existing genuine parent phase fixture.
## Call run() only after REAL routed recording has entered framing and normal
## shared camera follow has fitted its actual union. Never write phase/Player pose,
## recording/history/sequence/proof/deadline, or force an impossible view to fit.
const MainScene = preload("res://scenes/main.tscn")
const Exact = preload("res://scripts/campaign/exact_json.gd")
var checks: int = 0
var failures: Array[String] = []
var quiet: int = 0

class FramingPauseObserver extends Node:
	signal observed
	var game: Node
	var unit: CinderLevel
	var armed: bool = false
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_priority = 10000 # Observe AFTER normal shared Game camera process.
	func _process(_delta: float) -> void:
		if not armed or get_tree().paused or not is_instance_valid(unit) or String(unit.get("phase")) != "framing": return
		var points: Array = unit.camera_framing_points()
		if points.is_empty() or not String(game.call("camera_framing_error", points)).is_empty(): return
		armed = false
		game.call("open_bench") # Real public Pause; no gameplay gesture submitted.
		_notify.call_deferred() # Outside camera/physics/Gate callbacks.
	func _notify() -> void: observed.emit()

## Root integrates this bounded observer into the existing REAL recording
## arrange case before its last natural combo seal. An expected observer Pause
## needs its own observation wait; do not suppress the ordinary tick assertions.
## If no actual framing/fitting boundary occurs within the fixture's bound, keep
## that unexecuted/failed case; never synthesize framing or move the camera.
func run(outer: CinderLevel, hero: CinderPlayer, game: Node, capacity: int) -> Dictionary:
	checks = 0; failures.clear(); quiet = 0
	var tree: SceneTree = outer.get_tree()
	var unit: CinderLevel = outer.get("current_unit") as CinderLevel
	if not check(tree.paused and unit != null and String(unit.get("phase")) == "framing" and capacity in [1, 2], "Genuine paused current framing unit required"): return result()
	# Ordinary deferred public advance only. This reads the actual Actor clock
	# after callback unwind; it never changes Player/Scheduler or repairs a wire.
	var gate: CinderReplayCaptureGate = unit.get("capture_gate") as CinderReplayCaptureGate
	var scheduler: CinderThreatScheduler = unit.get("threat_scheduler") as CinderThreatScheduler
	var player_before: Dictionary = hero.snapshot_state()
	var scheduler_before: Dictionary = scheduler.snapshot_state(unit.call("scheduler_bindings"))
	var retirement_before: Dictionary = gate.retirement_state()
	if not check(gate.synchronize() and same(hero.snapshot_state(), player_before) and same(scheduler.snapshot_state(unit.call("scheduler_bindings")), scheduler_before) and same(gate.retirement_state(), retirement_before), "Public deferred Gate synchronize preserves actual Actor/Scheduler/history/retirement"): return result()
	var gate_now: Dictionary = gate.snapshot_state()
	if not check(gate.snapshot_error(gate_now, player_before).is_empty() and gate_now.clock_s == hero.get_world_action_clock() and gate_now.capture.max_slots == capacity and gate_now.prepared_sequence.is_empty() and gate_now.consumed_sequence.is_empty() and gate_now.retirement.is_empty() and not is_instance_valid(unit.get("playback")), "Complete original unadmitted Gate joins actual Player without Playback/retirement"): return result()
	var saved: Dictionary = pair(outer, hero, game)
	if not check(not saved.level.is_empty() and outer.snapshot_error_with_player(saved.level, saved.player).is_empty(), "Whole real framing parent/current unit snapshot", outer.last_snapshot_error): return result()
	var parsed: Dictionary = Exact.parse(Exact.stringify(saved))
	if not check(parsed.get("accepted", false) and same(parsed.value, saved), "Complete framing exact JSON retains immutable records/art/native optics"): return result()
	var input_before: PackedByteArray = var_to_bytes(game.call("get_input_observation_state"))
	for _i: int in range(3): await tree.process_frame
	if not check(same(saved, pair(outer, hero, game)) and input_before == var_to_bytes(game.call("get_input_observation_state")), "Real Pause preserves whole donor/input"): return result()
	negative_packets(outer, saved)
	await candidate(saved, game, outer.scene_file_path)
	check(same(saved, pair(outer, hero, game)) and input_before == var_to_bytes(game.call("get_input_observation_state")), "Independent candidate/native faults leave complete installed donor/input exact")
	return result()

func pair(outer: CinderLevel, hero: CinderPlayer, game: Node) -> Dictionary:
	return {"player": hero.snapshot_state(), "level": outer.snapshot_state_for_presentation(game.get("camera"), game.get("hud"))}

func negative_packets(outer: CinderLevel, saved: Dictionary) -> void:
	for kind: String in ["missing", "epoch", "position", "image", "alpha", "typed"]:
		var bad: Dictionary = saved.duplicate(true)
		var frame: Dictionary = bad.level.local.current_unit.state.owned.frame_art
		match kind:
			"missing": frame.clear()
			"epoch": frame.recipe.source_epoch += "/wrong"
			"position": frame.recipe.slots[0].position[0] += 0.25
			"image": frame.native.slots[0].texture_sha256 = "0".repeat(64)
			"alpha": frame.native.slots[0].modulate[3] = 0.0
			"typed": frame.recipe.slots[0].equipment_ids.weapon = true
		check(not outer.snapshot_error_with_player(bad.level, bad.player).is_empty(), "Copied malformed/altered whole framing packet refuses: " + kind)

func candidate(saved: Dictionary, game: Node, room_path: String) -> void:
	var tree: SceneTree = game.get_tree()
	var view := SubViewport.new()
	view.size = Vector2i(tree.root.get_visible_rect().size)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	tree.root.add_child(view)
	var receiver: Node = MainScene.instantiate()
	receiver.set("level_scene_path", room_path)
	view.add_child(receiver)
	tree.paused = true # Fresh Main resumes synchronously; no physics yield yet.
	var parent: CinderLevel = receiver.get("active_level") as CinderLevel
	var actor: CinderPlayer = receiver.get("player") as CinderPlayer
	parent.exit_level()
	var ok: bool = parent.enter_restore_candidate(actor, receiver.get("fx"), receiver, saved.level, saved.player)
	watch(parent); watch(actor)
	var quiet_before: int = quiet
	ok = check(ok and actor.get_world_3d() != (game.get("player") as CinderPlayer).get_world_3d() and parent.snapshot_error_with_player(saved.level, saved.player).is_empty() and actor.restore_state(saved.player) and parent.restore_state(saved.level), "Fresh independent native framing recipient: outer Player then public complete Gate/Scheduler quiet restore", parent.last_snapshot_error) and ok
	if ok:
		var camera: Camera3D = receiver.get("camera") as Camera3D
		camera.global_transform = (game.get("camera") as Camera3D).global_transform # TEST supplied exact saved view context only.
		var hud: GameHUD = receiver.get("hud") as GameHUD
		hud.update_status(actor.hp, actor.max_hp, actor.shells, actor.max_shells, 0, parent.objective_text)
		await tree.process_frame
		var error: String = parent.restore_candidate_presentation_error(camera, hud)
		ok = check(error.is_empty() and quiet == quiet_before and same(actor.snapshot_state(), saved.player), "Actual current candidate art/camera/HUD and whole Actor remain quiet", error)
		if ok:
			check(parent.finish_restore_candidate() and same(parent.snapshot_state_for_presentation(camera, hud), saved.level), "Exact whole native framing recapture after actual optics")
			var unit: CinderLevel = parent.get("current_unit") as CinderLevel
			var sprite: Sprite3D = unit.get_node("OriginalRecordedFrameArt/OriginalRecordedSlot1/RecordedTraveller") as Sprite3D
			var color: Color = sprite.modulate
			sprite.modulate = Color(color.r, color.g, color.b, 0.0) # TEST actual visibility fault, restored before yield.
			var refused: Dictionary = parent.snapshot_state_for_presentation(camera, hud)
			sprite.modulate = color
			check(refused.is_empty() and not parent.last_snapshot_error.is_empty() and same(parent.snapshot_state_for_presentation(camera, hud), saved.level), "Actual native recorded-art alpha0 capture refuses and exact donor renderer restores")
			var mask: int = camera.cull_mask
			camera.cull_mask = mask & ~sprite.layers
			error = String(parent.call("candidate_presentation_error", camera, hud))
			camera.cull_mask = mask
			check(not error.is_empty() and quiet == quiet_before, "Actual candidate camera excluding recorded art refuses quietly", error)
			var transform: Transform3D = camera.global_transform
			camera.global_position += Vector3(100, 0, 0)
			error = String(parent.call("candidate_presentation_error", camera, hud))
			camera.global_transform = transform
			check(not error.is_empty() and same(parent.snapshot_state_for_presentation(camera, hud), saved.level) and quiet == quiet_before, "Clipped actual camera refuses; exact view restored", error)
	parent.exit_level()
	var refs: Array[WeakRef] = [weakref(parent), weakref(actor), weakref(view)]
	view.queue_free()
	for _i: int in range(3): await tree.process_frame
	check(refs.all(func(ref: WeakRef) -> bool: return ref.get_ref() == null), "Normal whole candidate/art/floor/Player cleanup")

func watch(node: Node) -> void:
	for row: Dictionary in node.get_signal_list():
		if row.name in ["fired", "died", "action_resolved", "world_action_executed", "sequence_retired", "gate_failed", "state_changed", "event_dispatched", "recording_rejected", "recording_joined", "tether_severed", "completion_requested", "contact_exit_requested"]:
			var callback: Callable = Callable(self, "quiet" + str(row.args.size()))
			if callback.is_valid(): node.connect(row.name, callback)
	for child: Node in node.get_children(): watch(child)
func quiet0() -> void: quiet += 1
func quiet1(_a: Variant) -> void: quiet += 1
func quiet2(_a: Variant, _b: Variant) -> void: quiet += 1
func quiet3(_a: Variant, _b: Variant, _c: Variant) -> void: quiet += 1
func check(ok: bool, label: String, reason: String = "") -> bool:
	checks += 1
	if not ok: failures.append(label + (": " + reason if not reason.is_empty() else ""))
	return ok
func result() -> Dictionary:
	return {"accepted": failures.is_empty(), "checks": checks, "failures": failures.duplicate(), "scope": "real framing current-unit optics/transport only; no full route/art/campaign acceptance"}
