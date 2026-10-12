extends "res://scripts/campaign/level.gd"
## TEST ONLY public-Shell aggregate. Not authored A1/A2 content or acceptance.
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Bank = preload("res://scripts/combat/smoke_bank.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
var scheduler: CinderThreatScheduler
var bank: Bank
var late: MeshInstance3D
var late_clock: float = 0.0
var late_phase: String = "clear"
var restore_error: String = ""

func _on_enter_level() -> void:
	process_physics_priority = 200
	scheduler = Scheduler.new()
	scheduler.name = "Scheduler"
	add_child(scheduler)
	scheduler.begin_encounter("standard", "smoke-test", 1)
	bank = Bank.new()
	bank.name = "Bank"
	bank.configure("smoke-test/bank", Geometry.circle(Vector3.ZERO, 1.05), Vector3.ZERO)
	add_child(bank)
	bank.bind(scheduler, {"hero": hero})
	late = MeshInstance3D.new()
	late.name = "RequiredLaterPresentation"
	var marker := BoxMesh.new()
	marker.size = Vector3.ONE * 0.08
	late.mesh = marker
	late.position = Vector3(-2.5, 0.1, -2.5)
	add_child(late)
	_update_late()

func bindings() -> Dictionary:
	return {"world_root": get_parent(), "owners": {"smoke-test/bank": bank}, "floors": {"floor": {"collision": $Floor/Collision, "safe_rect": Rect2(-10, -10, 20, 20)}}}

func response_context() -> Dictionary:
	return {"encounter_id": "smoke-test", "world_revision": 1, "recognition_s": 0.12, "attack_input_margin_s": 0.02, "escape_directions": [Vector3.RIGHT, Vector3.LEFT], "return_directions": [Vector3.RIGHT, Vector3.LEFT], "floor_regions": bindings().floors.values()}

func start_bank(preview: Dictionary = {}) -> Dictionary:
	return bank.start("hero", response_context(), null, preview)

func _physics_process(_delta: float) -> void:
	# Required late presentation settles even on a real fatal native tick.
	_update_late()

func _update_late() -> void:
	late_clock = scheduler.get_clock()
	late_phase = bank.state().phase
	late.scale = Vector3.ONE * _phase_scale(late_phase)
	late.visible = late_phase != "clear"

func _phase_scale(phase: String) -> float:
	return float({"clear": 1, "warning": 2, "lock": 3, "active": 4, "recovery": 5}.get(phase, 0))

func _camera_framing_points() -> Array:
	return bank.get_required_camera_points() if is_instance_valid(bank) else []

func _capture_local_state() -> Dictionary:
	return {"scheduler": scheduler.snapshot_state(bindings()), "bank": bank.snapshot_state(bindings()), "late_clock": late_clock, "late_phase": late_phase, "late_scale": Codec.vector3(late.scale), "late_visible": late.visible}

func _local_snapshot_error(value: Dictionary) -> String:
	return _paired_error(value)

func _local_snapshot_error_with_player(value: Dictionary, saved_player: Dictionary) -> String:
	return _paired_error(value, saved_player)

func _paired_error(value: Dictionary, saved_player: Dictionary = {}) -> String:
	if not Codec.keys_error(value, ["scheduler", "bank", "late_clock", "late_phase", "late_scale", "late_visible"]).is_empty() or not value.scheduler is Dictionary or not value.bank is Dictionary: return "Complete smoke/Scheduler/later-presentation units required"
	var error: String = scheduler.snapshot_error(value.scheduler, bindings())
	if error.is_empty(): error = bank.snapshot_error(value.bank, bindings(), value.scheduler, saved_player)
	if error.is_empty() and (value.late_clock != value.scheduler.clock_s or value.late_phase != value.bank.phase or not Codec.is_vector3(value.late_scale) or Codec.read_vector3(value.late_scale) != Vector3.ONE * _phase_scale(value.bank.phase) or value.late_visible != (value.bank.phase != "clear")): error = "Later required presentation must match the complete original native tick"
	return error

func _restore_local_state(value: Dictionary) -> void:
	restore_error = ""
	if not scheduler.restore_state(value.scheduler, bindings()): restore_error = scheduler.last_snapshot_error
	elif not bank.restore_state(value.bank, bindings()): restore_error = bank.last_snapshot_error
	_update_late()

func _on_exit_level() -> void:
	if is_instance_valid(bank) and bank.is_inside_tree(): bank.cancel("fixture_exit")
	if is_instance_valid(scheduler) and scheduler.is_inside_tree(): scheduler.end_encounter("fixture_exit")
