extends SceneTree

const TargetScript: GDScript = preload("res://scripts/practice_target.gd")
const PlayerScript: GDScript = preload("res://scripts/player.gd")

class ClothTarget:
	extends PracticeTarget
	var accepts_hits: bool = false
	var artwork: Node3D
	var last_visual_state: String = ""
	var last_hit_fraction: float = 0.0
	func build_presentation() -> void:
		artwork = Node3D.new()
		artwork.name = "AuthoredRoundel"
		add_child(artwork)
	func present_state(visual_state: String, hit_feedback_fraction: float) -> void:
		last_visual_state = visual_state
		last_hit_fraction = hit_feedback_fraction
		artwork.visible = accepts_hits and visual_state != "cleared"
	func take_damage(amount: float, impulse: Vector3) -> Dictionary:
		# An authored future-beat gate reuses the parent's rejection/result logic.
		return super.take_damage(amount if accepts_hits else 0.0, impulse)

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var arena := Node3D.new()
	root.add_child(arena)
	_world_floor(arena)
	await _lab_state_checks(arena)
	await _authored_presentation_checks(arena)
	paused = false
	arena.queue_free()
	await process_frame
	print("Practice target smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _lab_state_checks(arena: Node3D) -> void:
	var prop: PracticeTarget = TargetScript.new()
	var changes: Array[String] = []
	prop.visual_state_changed.connect(func(visual_state: String) -> void: changes.append(visual_state))
	arena.add_child(prop)
	_expect(prop.hp == 100.0 and prop.max_hp == 100.0 and prop.state() == "available" and changes == ["available"], "default lab starts with its original full-HP available target and one state notification")
	_expect(prop.is_in_group("practice_targets") and not prop.is_in_group("enemies"), "practice target retains its prop-only hit group")
	var result: Dictionary = prop.take_damage(25.0, Vector3(8, 9, 10))
	_expect(result.accepted and result.hp_damage == 25.0 and result.target_alive_before_hit and result.target_id == prop.get_instance_id() and prop.hp == 75.0, "accepted hit retains original result shape and actual HP loss without applying enemy impulse")
	_expect(prop.state() == "hit" and _near(prop.hit_feedback_left(), PracticeTarget.HIT_FEEDBACK_S) and changes == ["available", "hit"], "accepted nonlethal hit exposes the shared hit state/clock")
	prop.take_damage(5.0, Vector3.ZERO)
	_expect(prop.hp == 70.0 and changes == ["available", "hit"], "another hit refreshes feedback without duplicating an unchanged visual-state notification")
	for amount: float in [0.0, -10.0, NAN, INF]:
		result = prop.take_damage(amount, Vector3.ZERO)
		_expect(not result.accepted and result.hp_damage == 0.0 and prop.hp == 70.0 and changes.size() == 2, "nonpositive/nonfinite damage rejects without HP or cue changes")
	paused = true
	var frozen: float = prop.hit_feedback_left()
	await create_timer(0.08).timeout
	_expect(prop.state() == "hit" and _near(prop.hit_feedback_left(), frozen), "pause freezes the actual target feedback clock")
	paused = false
	await create_timer(0.19).timeout
	_expect(prop.state() == "available" and prop.hit_feedback_left() == 0.0 and changes == ["available", "hit", "available"], "feedback expiration returns to available once")
	var unchanged: Array = [prop.hp, prop.max_hp, prop.hit_feedback_left(), prop.state(), changes.size()]
	var bad_values: Array[Array] = [[0.0, 0.0, 0.0], [100.0, 101.0, 0.0], [100.0, -2.0, 0.0], [100.0, 10.0, -0.1], [100.0, 10.0, 1.0], [NAN, 10.0, 0.0], [100.0, INF, 0.0]]
	for bad: Array in bad_values:
		_expect(not prop.configure(bad[0], bad[1], bad[2]) and [prop.hp, prop.max_hp, prop.hit_feedback_left(), prop.state(), changes.size()] == unchanged, "invalid configure rejects its complete HP/feedback tuple atomically")
	_expect(prop.configure(100.0, 12.5, 0.08, false) and prop.hp == 12.5 and prop.state() == "hit" and _near(prop.hit_feedback_left(), 0.08) and changes.size() == 3, "silent local restore uses exact supplied low HP/feedback without hit/state notifications")
	await create_timer(0.12).timeout
	_expect(prop.state() == "available" and prop.hp == 12.5, "restored feedback only advances its clock and never deals another hit")
	_expect(prop.configure(1.0) and prop.hp == 1.0 and prop.max_hp == 1.0, "explicit omitted current HP configures the one-hit rehearsal target")
	result = prop.take_damage(20.0, Vector3.ZERO)
	_expect(result.accepted and result.hp_damage == 1.0 and result.target_alive_before_hit and prop.state() == "cleared" and changes[-1] == "cleared", "ordinary primary-sized damage clears one-HP prop immediately with actual remaining loss")
	var clear_notifications: int = changes.size()
	result = prop.take_damage(20.0, Vector3.ZERO)
	_expect(not result.accepted and not result.target_alive_before_hit and result.hp_damage == 0.0 and changes.size() == clear_notifications, "cleared prop rejects repeats and never republishes clear")
	var label_text: String = ""
	for child: Node in prop.get_children():
		if child is Label3D:
			label_text = child.text
	_expect(label_text == "DONE" and prop.is_in_group("practice_targets"), "lab label remains DONE and cleared prop retains its shared group")
	prop.queue_free()
	await process_frame


func _authored_presentation_checks(arena: Node3D) -> void:
	var prop := ClothTarget.new()
	var changes: Array[String] = []
	_expect(prop.configure(1.0), "authored target can configure health before tree entry")
	prop.visual_state_changed.connect(func(visual_state: String) -> void: changes.append(visual_state))
	arena.add_child(prop)
	prop.position = Vector3(1.2, 0.02, 0.0)
	_expect(prop.get_child_count() == 1 and prop.get_node("AuthoredRoundel") == prop.artwork and prop.last_visual_state == "available" and not prop.artwork.visible, "public presentation hooks build only authored nodes without lab meshes or private visual access")
	_expect(prop.is_in_group("practice_targets") and not prop.is_in_group("enemies"), "authored art inherits shared prop classification")
	var player: CinderPlayer = PlayerScript.new()
	arena.add_child(player)
	player.position = Vector3(0, 0.02, 0)
	player.shells = 0
	_expect(player.slash(Vector3.RIGHT) == 0 and prop.hp == 1.0 and changes == ["available"], "inactive future-beat gate rejects ordinary hit through parent result logic")
	await create_timer(0.35).timeout
	paused = true
	var before: Dictionary = player.snapshot_state()
	var observed: Array[String] = []
	player.world_action_executed.connect(func(_record: Dictionary) -> void: observed.append(prop.state()))
	prop.accepts_hits = true
	_expect(player.slash(Vector3.RIGHT) == 1 and prop.state() == "cleared" and not prop.artwork.visible, "same shared ordinary-primary logic clears activated authored art with empty blast ammo")
	var after: Dictionary = player.snapshot_state()
	_expect(not before.is_empty() and not after.is_empty() and player.shells == 0 and _near(before.clocks.reload_s, after.clocks.reload_s), "accepted practice hit grants no living-enemy reload credit")
	_expect(observed == ["cleared"] and changes == ["available", "cleared"], "world-action observers see already committed shared target state")
	var before_restore_notifications: int = changes.size()
	_expect(prop.configure(1.0, 0.5, 0.05, false) and prop.last_visual_state == "hit" and _near(prop.last_hit_fraction, 1.0 / 3.0) and changes.size() == before_restore_notifications, "authored visual hook receives restored state and normalized feedback without replaying notifications")
	prop.queue_free()
	player.queue_free()
	paused = false
	await process_frame


func _world_floor(arena: Node3D) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := BoxShape3D.new()
	shape.size = Vector3(20, 1, 20)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	arena.add_child(body)
	body.position = Vector3(0, -0.5, 0)


func _near(left: Variant, right: Variant) -> bool:
	return absf(float(left) - float(right)) < 0.00001


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
