extends CinderLevel
## TEST ONLY custom Main level: native eye/nose/floor/component transport.
## No Living Moon campaign scene, sampled Blink, art or progression claim.

const Body = preload("res://scripts/acts/act1/living_moon_body.gd")
const Nose = preload("res://scripts/acts/act1/living_moon_nose.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const BODY_ID: String = "moon-eye-native-component"
const NOSE_ID: String = "moon-nose-eye-component"
const ENCOUNTER_ID: String = "a1-l5-eye-component"

var body: Node3D
var nose: Node3D
var scheduler: CinderThreatScheduler
var region: Dictionary = {}
var required_points: Array = []
var setup_error: String = ""
var provider_fault: String = ""


func _on_enter_level() -> void:
	var collision: CollisionShape3D = get_node("Floor/Collision") as CollisionShape3D
	var size: Vector3 = (collision.shape as BoxShape3D).size
	region = {"collision": collision, "safe_rect": Rect2(Vector2(collision.global_position.x, collision.global_position.z) - Vector2(size.x, size.z) * 0.5, Vector2(size.x, size.z))}
	scheduler = Scheduler.new()
	scheduler.name = "ActualScheduler"
	add_child(scheduler)
	body = Body.new()
	body.name = "ActualEyeReceiver"
	add_child(body)
	body.global_position = Vector3(0.0, 0.0, -9.0)
	if not body.call("configure", BODY_ID) or not body.call("bind_opening_provider", _actual_eye_recovery) or not body.call("bind", scheduler, hero, hero.get_parent()):
		setup_error = String(body.get("last_error")); return
	nose = Nose.new()
	nose.name = "ActualNose"
	body.add_child(nose)
	nose.global_position = Vector3(-0.6, 0.0, -9.4)
	# Hero begins outside this actual fixed cone. The Scheduler still proves an
	# ordinary escape/return opening; this fixture executes no evasion route.
	var cone: Dictionary = Geometry.cone(nose.global_position, Vector3.LEFT, 1.5, 0.65, 0.1)
	if not nose.call("configure", NOSE_ID, cone, body.global_position) or not nose.call("bind", scheduler, hero, hero.get_parent(), body) or not nose.call("set_presentation_guard", _current_view_guard):
		setup_error = String(nose.get("last_error"))


func context() -> Dictionary:
	return {"encounter_id": ENCOUNTER_ID, "world_revision": 1, "recognition_s": 0.2, "attack_input_margin_s": 0.05, "escape_directions": [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK], "return_directions": [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK], "floor_regions": [region]}


func bindings() -> Dictionary:
	return {"world_root": hero.get_parent(), "owners": {NOSE_ID: nose}, "floors": {"actual-component-floor": region}, "actors": {"hero": hero}}


func frame_preview(preview: Dictionary) -> void:
	var shape: Dictionary = preview.candidate.geometry
	required_points = [shape.origin + Vector3.UP, body.global_position, body.global_position + Vector3.UP * 0.7, preview.proof.landing, preview.proof.landing + Vector3.UP * 1.5]
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			required_points.append(shape.origin + Vector3(sx * float(shape.reach), 0.0, sz * float(shape.reach)))


func _camera_framing_points() -> Array:
	return required_points.duplicate()


func _current_view_guard(id: String, current: Dictionary) -> bool:
	if id != NOSE_ID or not is_instance_valid(shared_shell) or not is_instance_valid(nose) or not is_instance_valid(body) or required_points.is_empty() or current.source_id != NOSE_ID or current.geometry.origin != nose.global_position or current.opening_position != body.global_position:
		return false
	return shared_shell.call("camera_framing_error", required_points) == ""


func _actual_eye_recovery(id: String) -> Dictionary:
	if id != BODY_ID or not is_instance_valid(nose) or not is_instance_valid(hero) or hero.dead or not is_instance_valid(scheduler) or not is_instance_valid(body) or body.call("get_native_bindings").is_empty():
		return {"eligible": false, "reason": "Actual eye/nose/Hero/Scheduler custody required"}
	var current: Dictionary = nose.call("state")
	var control: Dictionary = scheduler.source_control_state(nose)
	if current.status != "running" or current.phase != "recovery" or not _current_view_guard(NOSE_ID, current) or control.get("outside_transaction") != true or not control.get("reservations") is Array or control.reservations.size() != 1:
		return {"eligible": false, "reason": "Actual nose recovery/current view is closed"}
	var lease: Dictionary = control.reservations[0]
	var cue: CinderThreatCue = nose.call("get_cue") as CinderThreatCue
	var marker: MeshInstance3D = cue.get_node_or_null("RequiredSourceMarker") as MeshInstance3D
	if lease.id != current.reservation_id or lease.source_instance_id != nose.get_instance_id() or lease.opening_position != body.global_position or lease.state != "recovery" or lease.armed != true or scheduler.get_clock() <= float(lease.active_until_s) or scheduler.get_clock() >= float(lease.recovery_until_s) or cue.state().phase != "recovery" or not cue.state().source_visible or marker == null or marker.mesh == null or not marker.is_visible_in_tree():
		return {"eligible": false, "reason": "Actual committed recovery/cue/eye opening is unavailable"}
	# Negative protocol injection only after genuine recovery is independently
	# established. It supplies no alternate positive opening or synthetic latch.
	if provider_fault == "integer_eligibility": return {"eligible": 1, "reason": ""}
	return {"eligible": true, "reason": ""}


func _on_exit_level() -> void:
	if is_instance_valid(nose): nose.call("cancel", "test_component_exit")
	if is_instance_valid(scheduler): scheduler.end_encounter("test_component_exit")
