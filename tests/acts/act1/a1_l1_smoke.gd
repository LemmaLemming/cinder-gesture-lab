extends SceneTree
## Bounded opening core. Full arm progression and campaign aggregate retry
## remain separate checks; local transport uses the published paused barrier.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const LevelPath: String = "res://scenes/acts/act1/a1_l1.tscn"
const TargetScript: GDScript = preload("res://scripts/acts/act1/rehearsal_target.gd")

var _checks: int = 0
var _failures: int = 0
var _progress_events: Array[String] = []
var _target_visual_events: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game: Node = MainScene.instantiate()
	game.set("level_scene_path", LevelPath)
	root.add_child(game)
	var level: CinderLevel = game.get("active_level") as CinderLevel
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	if level == null or hero == null:
		_expect(false, "A1-L1 starts through the shared shell")
		quit(1)
		return
	_expect(level.level_id == "A1-L1" and level.contract_error().is_empty(), "level has canonical identity and a valid shared spawn contract")
	_expect(level.hero == hero and level.effects == game.get("fx") and _player_count(game) == 1, "level receives exactly one shared actor and effects")
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("lab_weapons").is_empty(), "friendly rehearsal introduces no lab enemies or weapon stands")
	_expect(hero.global_position.is_equal_approx(level.spawn_position()), "shared player starts at the authored feet marker")
	level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: _progress_events.append("checkpoint"))
	level.completion_requested.connect(func(_id: String, _completion: String) -> void: _progress_events.append("completion"))
	level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: _progress_events.append("exit"))
	var targets: Dictionary = level.get("targets")
	_expect(targets.size() == 4 and targets.has_all(["hall", "workshop", "roof", "finale"]), "four stable rehearsal target IDs are exposed")
	if targets.size() != 4 or not targets.has_all(["hall", "workshop", "roof", "finale"]) or not level.has_method("dash_marker_position"):
		_expect(false, "opening exercise exposes its marker and target contract")
		game.queue_free()
		quit(1)
		return
	for id: String in ["hall", "workshop", "roof", "finale"]:
		var observed_id: String = id
		(targets[id] as PracticeTarget).visual_state_changed.connect(func(state: String) -> void: _target_visual_events.append(observed_id + ":" + state))
	hero.shells = 0
	await create_timer(0.6).timeout
	_expect(_beat(level) == 0 and _exercise_count(level) == 0, "elapsed time alone cannot complete the dash exercise")
	var initial: Dictionary = await _capture_level(level)
	_expect(not initial.is_empty(), "initial authored state is snapshot-ready")
	_expect(not initial.is_empty() and initial["local_snapshot_version"] == 3 and (initial["local"] as Dictionary).size() == 5 and initial["local"].has_all(["beat_index", "completed_exercises", "targets", "scheduler", "arms"]) and initial["local"]["targets"]["hall"].has("hit_feedback_left_s"), "v3 snapshot declares five local roots including paired scheduler/arms and exact target feedback")
	var foreign_actor := Node3D.new()
	root.add_child(foreign_actor)
	_expect(not level.request_contact_exit("capsule-hatch", hero) and not level.request_contact_exit("capsule-hatch", foreign_actor), "uncleared hatch rejects both shared hero and unrelated contact")
	foreign_actor.queue_free()

	# Future targets cannot be pre-cleared to skip their actual exercises.
	var workshop: PracticeTarget = targets["workshop"] as PracticeTarget
	var workshop_hp: float = workshop.hp
	_place_for_target(hero, workshop)
	hero.shells = 0
	var premature_hits: int = hero.slash(Vector3.FORWARD)
	_expect(premature_hits == 0 and workshop.hp == workshop_hp and _beat(level) == 0, "out-of-order primary leaves an inactive workshop target and progression intact")
	hero.global_position = level.spawn_position()
	await create_timer(0.5).timeout
	var marker: Vector3 = level.call("dash_marker_position")
	var dash_direction: Vector3 = marker - hero.global_position
	dash_direction.y = 0.0
	_expect(hero.request_dash(dash_direction), "opening dash is accepted by the shared controller")
	_expect(_beat(level) == 0, "dash request alone cannot complete a landing exercise")
	await create_timer(0.4).timeout
	var records: Array[Dictionary] = hero.get_world_action_records()
	_expect(not records.is_empty() and records[-1].kind == "dash" and (records[-1].landing as Vector3).distance_to(marker) < 1.0, "exercise observes a real completed dash landing at the authored marker")
	_expect(_beat(level) == 1 and _exercise_count(level) == 1, "first real landing advances exactly one exercise")

	var hall: PracticeTarget = targets["hall"] as PracticeTarget
	_place_for_target(hero, hall)
	var hall_hp: float = hall.hp
	hero.shells = 0
	_expect(hero.slash(Vector3.BACK) == 0 and hall.hp == hall_hp and _beat(level) == 1, "wrong primary direction gives a miss without resetting or advancing the lesson")
	await create_timer(0.5).timeout
	hero.shells = 0
	paused = true
	var actor_before_hit: Dictionary = hero.snapshot_state()
	_expect(hero.slash(Vector3.FORWARD) == 1 and hall.hp == 0.0 and hero.shells == 0, "ordinary primary genuinely clears the safe hall target with empty shells")
	var actor_after_hit: Dictionary = hero.snapshot_state()
	_expect(not actor_before_hit.is_empty() and not actor_after_hit.is_empty() and actor_before_hit["clocks"]["reload_s"] == actor_after_hit["clocks"]["reload_s"] and not hall.is_in_group("enemies"), "authored practice primary grants no living-enemy reload credit")
	_expect(_cloth_state_matches(hall, true) and _cue_matches(hall, "spent") and _label_count(hall) == 0, "accepted hit immediately folds authored cloth with a spent attack cue and no generic DONE label")
	paused = false
	_expect(_beat(level) == 2 and _exercise_count(level) == 2, "successful hall hit advances immediately without an instruction timer")
	hero.shells = 0
	_expect(hero.slash(Vector3.FORWARD) == 0 and _beat(level) == 2 and _exercise_count(level) == 2, "rejected repeat input cannot duplicate exercise progress")
	var after_hall: Dictionary = await _capture_level(level)
	if after_hall.is_empty():
		_expect(false, "completed hall boundary has a valid paused v3 snapshot")
		game.queue_free()
		quit(1)
		return
	await _test_rejections(level)
	await create_timer(0.5).timeout
	hero.shells = 0
	_expect(hero.slash(Vector3.FORWARD) == 0 and _beat(level) == 2 and _exercise_count(level) == 2, "accepted primary at the already cleared target cannot duplicate progress")
	await create_timer(0.5).timeout
	_place_for_target(hero, workshop)
	hero.shells = 0
	_expect(hero.slash(Vector3.FORWARD) == 1 and workshop.hp == 0.0 and hero.shells == 0, "workshop approach also clears through a real primary without blast ammo")
	_expect(_beat(level) == 3 and _exercise_count(level) == 3 and not level.is_completed(), "three opening exercises do not falsely complete the arm-dependent rehearsal")
	var event_count: int = _progress_events.size()
	hero.hp = 35.0
	var hp_before_restore: float = hero.hp
	var shells_before_restore: int = hero.shells
	var visual_events_before: int = _target_visual_events.size()
	paused = true
	await process_frame
	_expect(level.restore_state(after_hall), "valid local snapshot restores the completed hall boundary")
	_expect(_beat(level) == 2 and _exercise_count(level) == 2 and workshop.hp == workshop_hp and hall.hp == 0.0, "restore coherently reopens workshop while preserving the cleared hall")
	_expect(_progress_events.size() == event_count and hero.hp == hp_before_restore and hero.shells == shells_before_restore, "local restore emits no progression and does not heal or refill the shared actor")
	_expect(hall.hit_feedback_left() == after_hall["local"]["targets"]["hall"]["hit_feedback_left_s"] and workshop.hit_feedback_left() == after_hall["local"]["targets"]["workshop"]["hit_feedback_left_s"], "paused restore applies exact captured shared feedback clocks")
	_expect(_target_visual_events.size() == visual_events_before and _cloth_state_matches(hall, true) and _cloth_state_matches(workshop, false) and _cue_matches(hall, "spent") and _cue_matches(workshop, "available") and _label_count(workshop) == 0, "silent restore redraws cleared and standing cloth/cues without target state notifications")
	await create_timer(0.08, true).timeout
	_expect(level.snapshot_state() == after_hall and _target_visual_events.size() == visual_events_before and hero.hp == hp_before_restore and hero.shells == shells_before_restore, "paused restored target clocks and resources remain exact without another hit or event")
	paused = false
	await _test_missing_node(level, hall, after_hall)

	# Preview RESET is a fresh exercise, not a campaign checkpoint retry.
	await create_timer(0.5).timeout
	_expect(hero.equip_item("WEAPON-02"), "idle static weapon can be selected before preview reset")
	var old_level: CinderLevel = level
	var old_hero: CinderPlayer = hero
	var old_target: PracticeTarget = hall
	game.call("reset_lab")
	level = game.get("active_level") as CinderLevel
	hero = game.get("player") as CinderPlayer
	_expect(level != old_level and hero != old_hero and _beat(level) == 0 and _exercise_count(level) == 0, "preview reset creates a fresh opening instead of pretending to retry a checkpoint")
	_expect(old_level.hero == null and old_level.effects == null and not old_level.request_checkpoint("stale") and old_level.snapshot_state().is_empty(), "exited level releases shared references and cannot allocate stale progress")
	_expect(not old_target.is_processing() and _cue_matches(old_target, "clear"), "exit freezes the retired shared target clock and clears its required cue")
	var disconnected: bool = true
	for connection: Dictionary in old_hero.world_action_executed.get_connections():
		var callback: Callable = connection["callable"]
		disconnected = disconnected and callback.get_object() != old_level
	_expect(disconnected, "exit disconnects its shared action observer")
	_expect(hero.hp == hero.max_hp and hero.shells == hero.max_shells and hero.equipment.snapshot().weapon == "WEAPON-02", "fresh preview restores HP/ammo and keeps static equipment")
	_expect(_player_count(game) == 1 and hero.global_position.is_equal_approx(level.spawn_position()), "reset retains one shared actor at the authored spawn")
	await process_frame
	_expect(not is_instance_valid(old_level) and not is_instance_valid(old_hero) and not is_instance_valid(old_target), "old level, actor and level-owned target are freed")
	game.queue_free()
	paused = false
	await process_frame
	await _test_reentrant_checkpoint()
	await _test_authored_capture_envelope()
	await _test_authored_target_hook()
	print("A1-L1 opening core: %d checks, %d failures" % [_checks, _failures])
	print("NOT TESTED: loading arm, full-level completion, coherent campaign retry/transition and portrait art.")
	quit(0 if _failures == 0 else 1)


func _test_authored_target_hook() -> void:
	var target: Act1RehearsalTarget = TargetScript.new() as Act1RehearsalTarget
	_expect(target.configure(2.0, 2.0, 0.0, false), "authored hook fixture uses shared configuration before tree entry")
	root.add_child(target)
	paused = true
	var notifications: Array[String] = []
	target.visual_state_changed.connect(func(state: String) -> void: notifications.append(state))
	target.build_presentation()
	target.set_exercise_active(false)
	_expect(target.get_child_count() == 2 and _label_count(target) == 0 and not target.is_in_group("practice_targets") and _cue_matches(target, "clear"), "authored target has one cloth/one cue and an inactive future gate without generic label geometry")
	target.set_exercise_active(true)
	_expect(target.is_in_group("practice_targets") and not target.is_in_group("enemies") and _cloth_state_matches(target, false) and _cue_matches(target, "available"), "activation presents the shared available attack cue on standing cloth")
	var hit: Dictionary = target.take_damage(0.5, Vector3.ZERO)
	var cloth: Node3D = target.get_node("RehearsalClothVisual/StandingClothFrame/ClothFacePivot") as Node3D
	_expect(hit["accepted"] and target.state() == "hit" and target.hit_feedback_left() == PracticeTarget.HIT_FEEDBACK_S and cloth.scale.y < 0.99 and cloth.scale.x > 1.01 and _cue_matches(target, "available"), "shared nonlethal hit maps to available cloth with the actual normalized feedback fraction")
	var notifications_before: int = notifications.size()
	_expect(target.configure(2.0, 0.0, 0.05, false) and _cloth_state_matches(target, true) and _cue_matches(target, "spent") and notifications.size() == notifications_before, "silent cleared configuration immediately folds cloth and redraws spent cue")
	_expect(target.configure(2.0, 2.0, 0.05, false) and target.state() == "hit" and target.hit_feedback_left() == 0.05 and _cloth_state_matches(target, false) and cloth.scale.y > 0.96 and cloth.scale.y < 0.98 and notifications.size() == notifications_before, "silent live configuration restores a partial shared feedback clock and standing cloth without notifications")
	var frozen: float = target.hit_feedback_left()
	target.set_exercise_active(false)
	target.set_exercise_active(true)
	await create_timer(0.05, true).timeout
	_expect(target.hit_feedback_left() == frozen and target.hp == 2.0 and notifications.size() == notifications_before and _cue_matches(target, "available"), "activation redraw and pause do not own or advance the shared hit clock")
	target.queue_free()
	paused = false
	await process_frame


func _cloth_state_matches(target: PracticeTarget, folded: bool) -> bool:
	var standing: Node3D = target.get_node_or_null("RehearsalClothVisual/StandingClothFrame") as Node3D
	var spent: Node3D = target.get_node_or_null("RehearsalClothVisual/FoldedSpentCloth") as Node3D
	return is_instance_valid(standing) and is_instance_valid(spent) and standing.visible == (not folded) and spent.visible == folded


func _cue_matches(target: PracticeTarget, expected_state: String) -> bool:
	var cue: CinderInteractionCue = target.get("interaction_cue") as CinderInteractionCue
	if not is_instance_valid(cue):
		return false
	var state: Dictionary = cue.state()
	return state["state"] == expected_state and state["trigger"] == "attack" and state["visible"] == (expected_state != "clear") and state["required"]


func _label_count(node: Node) -> int:
	var count: int = 1 if node is Label3D else 0
	for child: Node in node.get_children():
		count += _label_count(child)
	return count


func _test_authored_capture_envelope() -> void:
	var game: Node = MainScene.instantiate()
	game.set("level_scene_path", LevelPath)
	root.add_child(game)
	var level: CinderLevel = game.get("active_level") as CinderLevel
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	if level == null or hero == null:
		_expect(false, "capture-envelope fixture starts through the shared shell")
		game.queue_free()
		await process_frame
		return
	# Keep resources fixed while testing only public local-level transactions.
	hero.take_damage(4.0, Vector3.ZERO)
	hero.shells = 0
	paused = true
	await process_frame
	var hp_before: float = hero.hp
	var shells_before: int = hero.shells
	var initial: Dictionary = level.snapshot_state()
	_expect(not initial.is_empty() and level.snapshot_error(initial).is_empty(), "capture-envelope fixture begins with a valid authored snapshot")
	if initial.is_empty():
		game.queue_free()
		paused = false
		await process_frame
		return
	var local_before: Dictionary = (initial["local"] as Dictionary).duplicate(true)
	# No live reservation exists at opening: only the owned immutable placement
	# guard can reject these sources/opening props before a partial restore.
	var actor_before: Dictionary = hero.snapshot_state()
	var binding_events: Array[String] = []
	level.checkpoint_requested.connect(func(_id: String, _checkpoint: String, _kind: String) -> void: binding_events.append("checkpoint"))
	level.completion_requested.connect(func(_id: String, _completion: String) -> void: binding_events.append("completion"))
	level.contact_exit_requested.connect(func(_id: String, _exit: String) -> void: binding_events.append("exit"))
	var scheduler: CinderThreatScheduler = level.get("scheduler") as CinderThreatScheduler
	scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: binding_events.append("reservation"))
	var arms: Dictionary = level.get("arms")
	for id: String in arms:
		var observed_arm: CinderLaneMechanism = arms[id] as CinderLaneMechanism
		observed_arm.state_changed.connect(func(_state: Dictionary) -> void: binding_events.append("arm"))
		observed_arm.hit_resolved.connect(func(_hero_id: String, _cycle: int, _result: Dictionary) -> void: binding_events.append("hit"))
		observed_arm.get_cue().state_changed.connect(func(_state: Dictionary) -> void: binding_events.append("threat-cue"))
	var targets: Dictionary = level.get("targets")
	for id: String in targets:
		var observed_target: PracticeTarget = targets[id] as PracticeTarget
		observed_target.visual_state_changed.connect(func(_state: String) -> void: binding_events.append("target"))
		(observed_target.get("interaction_cue") as CinderInteractionCue).state_changed.connect(func(_state: Dictionary) -> void: binding_events.append("attack-cue"))
	(level.get("hatch_cue") as CinderInteractionCue).state_changed.connect(func(_state: Dictionary) -> void: binding_events.append("contact-cue"))
	var idle_arm: CinderLaneMechanism = arms["a1_l1_roof_arm"] as CinderLaneMechanism
	var roof_target: PracticeTarget = targets["roof"] as PracticeTarget
	for kind: String in ["moved-idle-arm", "rotated-idle-arm", "moved-opening-target"]:
		var binding: Node3D = roof_target if kind == "moved-opening-target" else idle_arm
		var transform_before: Transform3D = binding.transform
		var events_before: int = binding_events.size()
		if kind == "rotated-idle-arm":
			binding.rotate_y(0.2)
		else:
			binding.position.x += 0.5
		var live_error: String = level.snapshot_error(initial)
		var staged_error: String = level.snapshot_error_with_player(initial, actor_before)
		var restored: bool = level.restore_state(initial)
		_expect(not live_error.is_empty() and not staged_error.is_empty() and not restored and not level.last_snapshot_error.is_empty() and hero.snapshot_state() == actor_before and _observed_local_state(level) == local_before and binding_events.size() == events_before, "invalid " + kind + " rejects live/context/restore before actor, local, scheduler, cue or progress mutation without a live reservation")
		binding.transform = transform_before
		_expect(level.snapshot_state() == initial and hero.snapshot_state() == actor_before and binding_events.size() == events_before, "restoring the same " + kind + " transform recovers exact capture without a new cycle, hit or event")
	_expect(level.request_checkpoint("unknown-boundary", "encounter"), "public base request can create a checkpoint outside the authored exercise prefix")
	var rejected: Dictionary = level.snapshot_state()
	_expect(rejected.is_empty() and not level.last_snapshot_error.is_empty() and _observed_local_state(level) == local_before, "capture rejects inconsistent checkpoint progress with a diagnostic and no local mutation")
	_expect(level.restore_state(initial) and level.snapshot_state() == initial and hero.hp == hp_before and hero.shells == shells_before, "valid original snapshot recovers checkpoint state without healing or refilling")
	_expect(level.request_completion("premature-rehearsal"), "public base request can mark completion before authored exercises clear")
	rejected = level.snapshot_state()
	_expect(rejected.is_empty() and not level.last_snapshot_error.is_empty() and _observed_local_state(level) == local_before, "capture rejects premature completion with a diagnostic and no local mutation")
	_expect(level.restore_state(initial) and level.snapshot_state() == initial and hero.hp == hp_before and hero.shells == shells_before, "valid original snapshot recovers premature completion without healing or refilling")
	paused = false
	# Resource assertions above ran paused. Let the actual damage-feedback voice
	# finish before destroying this final fixture, as in the loadout harness.
	await create_timer(0.5).timeout
	game.queue_free()
	await process_frame


func _observed_local_state(level: CinderLevel) -> Dictionary:
	var states: Dictionary = {}
	var targets: Dictionary = level.get("targets")
	for id: String in ["hall", "workshop", "roof", "finale"]:
		var target: PracticeTarget = targets[id] as PracticeTarget
		states[id] = {"hp": target.hp, "active": target.is_in_group("practice_targets"), "hit_feedback_left_s": target.hit_feedback_left()}
	var completed: Array = level.get("completed_exercises")
	var bindings: Dictionary = level.call("scheduler_bindings")
	var scheduler: CinderThreatScheduler = level.get("scheduler") as CinderThreatScheduler
	var captured_arms: Dictionary = {}
	var arms: Dictionary = level.get("arms")
	for id: String in arms:
		captured_arms[id] = (arms[id] as CinderLaneMechanism).snapshot_state(bindings)
	return {"beat_index": _beat(level), "completed_exercises": completed.duplicate(), "targets": states, "scheduler": scheduler.snapshot_state(bindings), "arms": captured_arms}


func _test_reentrant_checkpoint() -> void:
	var game: Node = MainScene.instantiate()
	game.set("level_scene_path", LevelPath)
	root.add_child(game)
	var level: CinderLevel = game.get("active_level") as CinderLevel
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	var observations: Array[int] = [0, 0]
	level.checkpoint_requested.connect(func(_id: String, checkpoint: String, _kind: String) -> void:
		observations[0] += 1
		if checkpoint == "first-dash":
			_expect(level.snapshot_state().is_empty(), "checkpoint callback waits for the coherent deferred actor barrier")
			hero.shells = 0
			var targets: Dictionary = level.get("targets")
			var direction: Vector3 = (targets["hall"] as PracticeTarget).global_position - hero.global_position
			direction.y = 0.0
			observations[1] = hero.slash(direction)
	)
	var marker: Vector3 = level.call("dash_marker_position")
	_expect(hero.request_dash(marker - hero.global_position), "reentrant fixture starts a real completed dash")
	await create_timer(0.4).timeout
	paused = true
	await process_frame
	var snapshot: Dictionary = level.snapshot_state()
	_expect(observations[1] == 1 and _beat(level) == 2, "a genuine nested primary is observed after the current checkpoint leaves dispatch")
	_expect(observations[0] == 2 and not snapshot.is_empty() and level.snapshot_error(snapshot).is_empty(), "both genuine actions retain coherent local and checkpoint history")
	paused = false
	game.queue_free()
	await process_frame


func _test_rejections(level: CinderLevel) -> void:
	var was_paused: bool = paused
	paused = true
	await process_frame
	var before: Dictionary = level.snapshot_state()
	if before.is_empty():
		_expect(false, "rejection fixture has a valid paused baseline")
		paused = was_paused
		return
	var old_version: Dictionary = before.duplicate(true)
	old_version["local_snapshot_version"] = 1
	_expect(not level.restore_state(old_version) and level.snapshot_state() == before, "v1 snapshots cannot silently lose target feedback and paired arms in the v3 level")
	var old_v2: Dictionary = before.duplicate(true)
	old_v2["local_snapshot_version"] = 2
	_expect(not level.restore_state(old_v2) and level.snapshot_state() == before, "v2 snapshots cannot omit the v3 paired scheduler and mechanism unit")
	for value: Variant in [-0.001, PracticeTarget.HIT_FEEDBACK_S + 0.001, NAN, INF, "0.1", true]:
		var invalid_clock: Dictionary = before.duplicate(true)
		invalid_clock["local"]["targets"]["hall"]["hit_feedback_left_s"] = value
		_expect(not level.restore_state(invalid_clock) and level.snapshot_state() == before, "invalid target feedback clock rejects atomically: " + str(value))
	var missing_clock: Dictionary = before.duplicate(true)
	missing_clock["local"]["targets"]["hall"].erase("hit_feedback_left_s")
	_expect(not level.restore_state(missing_clock) and level.snapshot_state() == before, "target schema requires an explicit feedback clock")
	var extra_target_field: Dictionary = before.duplicate(true)
	extra_target_field["local"]["targets"]["hall"]["undeclared_clock"] = 0.0
	_expect(not level.restore_state(extra_target_field) and level.snapshot_state() == before, "target schema rejects undeclared fields without mutation")
	var untouched_feedback: Dictionary = before.duplicate(true)
	untouched_feedback["local"]["targets"]["workshop"]["hit_feedback_left_s"] = 0.05
	_expect(not level.restore_state(untouched_feedback) and level.snapshot_state() == before, "an untouched one-hit target cannot carry feedback from an invented hit")
	for value: Variant in [-1, 6, 1.25, "2"]:
		var invalid: Dictionary = before.duplicate(true)
		invalid["local"]["beat_index"] = value
		_expect(not level.restore_state(invalid) and level.snapshot_state() == before, "invalid beat is rejected without partial mutation: " + str(value))
	var incomplete: Dictionary = before.duplicate(true)
	incomplete["local"] = {}
	_expect(not level.restore_state(incomplete) and level.snapshot_state() == before, "missing local fields are rejected atomically")
	var impossible: Dictionary = before.duplicate(true)
	impossible["local"]["beat_index"] = 3
	_expect(not level.restore_state(impossible) and level.snapshot_state() == before, "beat cannot advance without matching completed exercises and targets")
	var wrong_type: Dictionary = before.duplicate(true)
	wrong_type["local"]["completed_exercises"] = "release-point"
	_expect(not level.restore_state(wrong_type) and level.snapshot_state() == before, "completed exercises require an array rather than a string")
	var duplicate: Dictionary = before.duplicate(true)
	duplicate["local"]["completed_exercises"] = ["first-dash", "first-dash"]
	_expect(not level.restore_state(duplicate) and level.snapshot_state() == before, "duplicate exercise IDs cannot replace the ordered completed prefix")
	var extra: Dictionary = before.duplicate(true)
	extra["local"]["undeclared_state"] = true
	_expect(not level.restore_state(extra) and level.snapshot_state() == before, "undeclared local snapshot fields are rejected without mutation")
	var fractional_hp: Dictionary = before.duplicate(true)
	fractional_hp["local"]["targets"]["hall"]["hp"] = 0.5
	_expect(not level.restore_state(fractional_hp) and level.snapshot_state() == before, "rehearsal target HP must represent an available or cleared target")
	var false_completion: Dictionary = before.duplicate(true)
	false_completion["progress"]["completed"] = true
	false_completion["progress"]["completion_id"] = "forged-clear"
	_expect(not level.restore_state(false_completion) and level.snapshot_state() == before, "valid-looking completion cannot contradict an unfinished opening")
	var foreign_boundary: Dictionary = before.duplicate(true)
	foreign_boundary["progress"]["checkpoint_ids"]["unknown-boundary"] = "encounter"
	_expect(not level.restore_state(foreign_boundary) and level.snapshot_state() == before, "otherwise valid checkpoint history rejects an unauthored boundary")
	var old_boundary: Dictionary = before.duplicate(true)
	old_boundary["progress"]["checkpoint_id"] = "first-dash"
	old_boundary["progress"]["checkpoint_kind"] = "encounter"
	_expect(not level.restore_state(old_boundary) and level.snapshot_state() == before, "current checkpoint must match the latest completed exercise, not an older valid boundary")
	paused = was_paused


func _test_missing_node(level: CinderLevel, target: PracticeTarget, snapshot: Dictionary) -> void:
	var was_paused: bool = paused
	paused = true
	await process_frame
	var parent: Node = target.get_parent()
	var beat_before: int = _beat(level)
	var hp_before: float = target.hp
	parent.remove_child(target)
	_expect(not level.restore_state(snapshot) and _beat(level) == beat_before and target.hp == hp_before, "restore rejects a missing required runtime target before committing fields")
	parent.add_child(target)
	paused = was_paused


func _capture_level(level: CinderLevel) -> Dictionary:
	var was_paused: bool = paused
	paused = true
	await process_frame
	var snapshot: Dictionary = level.snapshot_state()
	paused = was_paused
	return snapshot


func _place_for_target(hero: CinderPlayer, target: PracticeTarget) -> void:
	hero.global_position = target.global_position + Vector3(0.0, 0.1, 1.0)


func _beat(level: CinderLevel) -> int:
	return int(level.get("beat_index"))


func _exercise_count(level: CinderLevel) -> int:
	var completed: Array = level.get("completed_exercises")
	return completed.size()


func _player_count(node: Node) -> int:
	var count: int = 1 if node is CinderPlayer else 0
	for child: Node in node.get_children():
		count += _player_count(child)
	return count


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	print("PASS: " if condition else "FAIL: ", description)
	if not condition:
		_failures += 1
