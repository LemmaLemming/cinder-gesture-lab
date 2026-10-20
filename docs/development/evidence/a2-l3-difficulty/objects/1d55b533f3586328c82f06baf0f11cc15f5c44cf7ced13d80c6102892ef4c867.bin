extends "res://scripts/acts/act2/ruined_house.gd"
## INERT TEST TEXT. Proposed promoted helper path below must be Root-reviewed.
const TestFocusPolicy = preload("res://tests/acts/act2/fixtures/a2_l3_difficulty_focus_policy.gd")
func _ready() -> void:
	super._ready()
	assert(not _entered and not is_instance_valid(hero) and not is_instance_valid(_scheduler))
	# New TEST policy before enter constructs ANY native recipient. Do not edit
	# production HouseSequence, invent its earned prefix, or save this component.
	_crossing = TestFocusPolicy.new()
func spawn_position() -> Vector3:
	# Called exactly once by inherited Game reset during fresh Player construction.
	# Use actual original built floor top; canonical Player capsule feet offset is
	# .73 - 1.45/2 = .005, pinned and checked against the actual Player at birth.
	for region: Dictionary in _floors:
		if region.id == "boss_opening":
			var collision: CollisionShape3D = region.collision
			assert(collision.shape is BoxShape3D and collision.global_basis == Basis.IDENTITY)
			var top: float = collision.global_position.y + (collision.shape as BoxShape3D).size.y * 0.5
			return Vector3(0.0, top - (Scheduler.CAPSULE_CENTER_Y - Scheduler.CAPSULE_HEIGHT * 0.5), -33.4)
	assert(false, "Original boss_opening support missing; never guess another spawn")
	return Vector3.INF
# No _on_enter_level / cursor / HP / native guard override. Original control
# retains original Reach. Future Place must come only from Root's actual fresh
# selector, on its separate pinned build, and is asserted by comparison.gd.

# TEST-only read view of the pinned parent publication branches. The production
# camera aggregate remains unchanged: its idle forecasts still drive planning.
# This body is original House728 _camera_framing_points verbatim, with ONLY its
# two non-running elif _forecast_points branches omitted. Native running source,
# footprint and retained landing/attack corners are never filtered by position.
func test_published_camera_framing_points() -> Array:
	if not runtime_error.is_empty(): return []
	if not _entered or not is_instance_valid(hero): return []
	var points: Array[Vector3] = []
	for id: String in _mechanisms:
		var state: Dictionary = _mechanisms[id].call("state")
		if state.status == "running":
			points.append_array(_source_points(id))
			if state.phase != "recovery": points.append_array(_lane_points(state.geometry))
			if _views.has(id):
				for key: String in ["landing", "attack_position"]: points.append_array(_landing_points(Codec.read_vector3(_views[id][key])))
	if is_instance_valid(_exchange):
		var scout: Dictionary = _exchange.call("state", "apron_scout")
		if scout.get("status") == "running":
			points.append_array(_source_points("apron_scout"))
			if scout.phase != "recovery":
				points.append_array(_lane_points(_state_geometry(scout)))
				var proof: Dictionary = scout.get("proof", {})
				if not proof.get("landing") is Vector3: proof = scout.get("presentation_witness", {})
				for key: String in ["landing", "attack_position"]:
					if proof.get(key) is Vector3: points.append_array(_landing_points(proof[key]))
	for id: String in _clouds:
		if _clouds[id].call("state").status == "running":
			points.append_array(_required_source_points(_actors[BANK_TO_TENDER[id]]))
			points.append_array(_clouds[id].call("get_required_camera_points"))
			if _bank_views.has(id):
				for key: String in ["landing", "attack_position"]: points.append_array(_landing_points(Codec.read_vector3(_bank_views[id][key])))
	return points
