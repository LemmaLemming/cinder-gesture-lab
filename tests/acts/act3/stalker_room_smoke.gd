extends SceneTree
## Owned physical-lunge rule fixture, using the actual room/shared player.
## request_dash/slash are public mechanic calls: no native gesture, human play,
## portrait readability, production registry, checkpoint allocation or gear-matrix
## acceptance is established here. Sun 1 is a validated local-state fixture,
## not evidence of a naturally completed scenic cycle. No blast is invoked.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const RoomPath: String = "res://scenes/acts/act3/a3_l1_stalker_room.tscn"
const SourcePath: String = "res://scripts/acts/act3/sunbound_stalker.gd"
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson: GDScript = preload("res://scripts/campaign/exact_json.gd")
const EndpointTolerance: float = 0.005
const CombinedContactRadius: float = 0.42 + 0.32
const DeadlineKeys: Array[String] = ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]

var _checks: int = 0
var _failures: int = 0
var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _source: CharacterBody3D
var _scheduler: CinderThreatScheduler
var _events: Dictionary = {}
var _hit_results: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var selectors: Array[String] = ["--sun0-only", "--sun1-only", "--contact-only", "--snapshot-only", "--combat-only"]
	var selected: String = ""
	for arg: String in args:
		if arg in selectors:
			_expect(selected.is_empty(), "one supported focused selector at a time")
			selected = arg
		else:
			_expect(false, "unknown owned fixture selector: " + arg)
	if _failures > 0:
		_finish()
		return
	if selected.is_empty() or selected in ["--sun0-only", "--combat-only"]:
		await _combat_case(0)
	if selected.is_empty() or selected in ["--sun1-only", "--combat-only"]:
		await _combat_case(1)
	if selected.is_empty() or selected == "--contact-only":
		await _contact_case()
	if selected.is_empty() or selected == "--snapshot-only":
		await _snapshot_case()
	_finish()


func _open_case(label: String, sun: int = 0) -> bool:
	print("CASE: " + label)
	_events.clear()
	_hit_results.clear()
	_game = MainScene.instantiate()
	_game.set("level_scene_path", RoomPath)
	root.add_child(_game)
	# _ready constructs the shared hero synchronously, before any room tick.
	var spawned: CinderPlayer = _game.get("player") as CinderPlayer
	if spawned != null:
		spawned.shells = 0
	await _ticks(12)
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	if not _expect(_level != null and _hero != null and _level.scene_file_path == RoomPath and _level.contract_error().is_empty(), "actual Stalker room enters through shared scene selection"):
		return false
	_source = _level.get("stalker") as CharacterBody3D
	_scheduler = _level.get("threat_scheduler") as CinderThreatScheduler
	if not _expect(_source != null and _scheduler != null and _source.has_method("state") and _source.has_method("snapshot_error"), "authored room exposes its actual source and shared scheduler"):
		return false
	_expect(_hero.presentation_id == "act3_traveller" and _hero.is_on_floor(), "shared Act 3 traveller settles on the authored floor")
	_expect(_source.get_script().resource_path == SourcePath and _source.is_in_group("enemies") and _source.get_world_3d() == _hero.get_world_3d(), "real owned CharacterBody source participates in ordinary enemy targeting")
	var collision: CollisionShape3D = _source.get_node_or_null("BodyCollision") as CollisionShape3D
	var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D if collision != null else null
	_expect(capsule != null and is_equal_approx(capsule.radius, 0.32) and is_equal_approx(capsule.height, 1.45) and is_equal_approx(collision.position.y, 0.73) and _source.collision_layer == 2 and _source.collision_mask == 1, "source uses its actual authored capsule/body collision contract")
	var scenery: Node = _level.get("scenery") as Node
	var floor_body: StaticBody3D = scenery.get("floor_body") as StaticBody3D if scenery != null else null
	var floor_shape: BoxShape3D = null
	if floor_body != null and floor_body.get_child_count() > 0 and floor_body.get_child(0) is CollisionShape3D:
		floor_shape = (floor_body.get_child(0) as CollisionShape3D).shape as BoxShape3D
	_expect(floor_shape != null and floor_shape.size == Vector3(14, 1, 22) and get_nodes_in_group("practice_targets").is_empty(), "isolated rule uses the actual continuous 14 by 22 shelf without proxy targets")
	_hero.shells = 0 # Public depleted-ammo fixture; natural reload remains active.
	_source.connect("state_changed", _on_source_state)
	_source.connect("hit_resolved", _on_source_hit)
	_source.connect("died", _on_source_died)
	_scheduler.reservation_invalidated.connect(_on_invalidated)
	_hero.world_action_executed.connect(_on_world_action)
	_hero.action_resolved.connect(_on_action_resolved)
	_hero.fired.connect(_on_fired)
	_hero.died.connect(_on_hero_died)
	_hero.equipment_changed.connect(_on_equipment)
	_level.completion_requested.connect(_on_completion)
	_level.checkpoint_requested.connect(_on_checkpoint)
	_level.contact_exit_requested.connect(_on_exit_request)
	if sun == 1:
		var pair: Dictionary = await _pause_pair("configured second sun")
		if pair.is_empty():
			return false
		var configured: Dictionary = pair["level"].duplicate(true)
		configured["local"]["scenery"]["sun_state"] = 1
		var before_events: Dictionary = _events.duplicate(true)
		if not _expect(_level.snapshot_error(configured).is_empty() and _level.restore_state(configured), "validated local scenery fixture selects the second sun without changing the paired source"):
			return false
		_expect(_exact(_events, before_events) and int(_level.get("sun_state")) == 1, "configured second sun emits no gameplay event")
		_game.call("resume_lab")
	_expect(int(_level.get("sun_state")) == sun and _hero.hp == _hero.max_hp, "fresh case begins in its selected harmless sun with full HP")
	return true


func _combat_case(sun: int) -> void:
	if not await _open_case("escape and ordinary primary, configured sun %d" % sun, sun):
		await _close_case()
		return
	var hp_before: float = _hero.hp
	var warning: Dictionary = await _wait_phase("warning", 4.0)
	if warning.is_empty():
		await _close_case()
		return
	var record: Dictionary = _scheduler.reservation_state(String(warning["reservation_id"]))
	if not _reservation_checks(warning, record):
		await _close_case()
		return
	var locked: Dictionary = await _wait_phase("lock", 2.0)
	if locked.is_empty():
		await _close_case()
		return
	_expect(_exact(_reservation_geometry(record), _reservation_geometry(_scheduler.reservation_state(String(record["id"])))), "accepted fixed-heading geometry remains identical from warning into lock")
	var camera: Camera3D = _game.get("camera") as Camera3D
	var camera_before: Vector3 = camera.global_position
	var origin: Vector3 = _source.global_position
	await _dash_completed(Vector3.RIGHT, "real lateral escape during lock")
	var after_dash: Dictionary = _source.call("state")
	_expect(after_dash["phase"] == "lock" and _source.global_position.distance_to(origin) <= EndpointTolerance and _hero.facing.x > 0.99, "completed right dash changes the real hero's facing while the locked source stays braced")
	_expect(camera.global_position.distance_to(camera_before) > 0.01, "fixed portrait camera actually follows the rightward hero movement")
	_expect(_exact(_reservation_geometry(record), _reservation_geometry(_scheduler.reservation_state(String(record["id"])))), "actual dash and camera follow do not retarget locked geometry")
	var reached_active: bool = false
	var invariant: bool = true
	for _index: int in range(_frame_limit(1.0)):
		var state: Dictionary = _source.call("state")
		if state["phase"] == "active":
			reached_active = true
			break
		if state["phase"] != "lock":
			invariant = false
			break
		invariant = invariant and _source.global_position.distance_to(origin) <= EndpointTolerance and _exact(_reservation_geometry(record), _reservation_geometry(_scheduler.reservation_state(String(record["id"]))))
		await _ticks(1)
	_expect(reached_active and invariant, "source and geometry stay fixed through every remaining observed lock tick")
	if not reached_active:
		await _close_case()
		return
	await _observe_lunge(record, hp_before, "lateral escape")
	if String((_source.call("state") as Dictionary)["phase"]) != "recovery":
		await _close_case()
		return
	await _dash_completed(Vector3.LEFT, "real return dash during source recovery")
	var before_primary: Dictionary = _source.call("state")
	_expect(before_primary["phase"] == "recovery" and _hero.hp == hp_before and _hit_results.is_empty(), "ordinary return reaches the real stationary recovery body without lunge damage")
	_hero.shells = 0
	_expect(_hero.shells == 0, "ordinary-primary proof starts with depleted blast ammo")
	var sequence: int = _last_sequence()
	var target_hp: float = float(before_primary["hp"])
	var primary_origin: Vector3 = _hero.global_position
	var towards: Vector3 = _source.global_position - primary_origin
	towards.y = 0.0
	var hits: int = _hero.slash(towards.normalized())
	var actions: Array[Dictionary] = _hero.get_world_action_records(sequence)
	var after_primary: Dictionary = _source.call("state")
	var primary_valid: bool = actions.size() == 1
	if primary_valid:
		var action: Dictionary = actions[0]
		primary_valid = action["kind"] == "primary" and int(action["hits"]) == 1 and float(action["damage"]) > 0.0 and (action["world_origin"] as Vector3).distance_to(primary_origin) <= EndpointTolerance
	_expect(hits == 1 and primary_valid and float(after_primary["hp"]) < target_hp and float(after_primary["hp"]) == target_hp - float(_hero.equipment.resolved_stats()["primary_damage"]), "actual public primary records one ordinary hit and decreases real source HP in sun %d" % sun)
	_expect(_hero.hp == hp_before and _no_blasts() and _scheduler.reservations().is_empty(), "primary-only recovery punishment cancels the lease without blast, hero damage or substitute target calls")
	_expect(int(_level.get("sun_state")) == sun and not _level.is_completed() and String(_level.current_checkpoint()["id"]).is_empty(), "rule exchange neither changes its sun nor grants production progress")
	await _close_case()


func _reservation_checks(state: Dictionary, record: Dictionary) -> bool:
	var valid: bool = not record.is_empty() and record.get("adapter") is Dictionary and record["adapter"].get("kind") == "lunge" and record.get("geometry") is Dictionary and record["geometry"].get("kind") == "lane" and bool(record.get("armed", false))
	if not _expect(valid and int(state.get("cycle", 0)) == 1 and not bool(state.get("dead", true)), "finite initial wait obtains the first armed physical-lunge reservation"):
		return false
	var proof: Dictionary = state.get("proof", {})
	_expect(bool(proof.get("accepted", false)) and not bool(proof.get("uses_blast", true)) and not bool(proof.get("uses_invulnerability", true)), "published admission supplies supported escape and ordinary-primary return proof")
	var role: Dictionary = state["resolved_role"]
	_expect(is_equal_approx(float(record["active_from_s"]) - float(record["start_s"]), float(role["windup_s"])) and is_equal_approx(float(record["active_from_s"]) - float(record["lock_from_s"]), float(role["lock_s"])) and is_equal_approx(float(record["active_until_s"]) - float(record["active_from_s"]), float(role["active_s"])), "resolved preparation includes its lock and reserves the authored active duration")
	var adapter: Dictionary = record["adapter"]
	_expect(adapter.get("planned_endpoint") is Vector3 and float(adapter["duration_s"]) <= float(role["active_s"]) and float(adapter["speed"]) == 12.0 and float(adapter["distance"]) == 3.0, "real adapter reserves three world units at twelve units per second within its active window")
	return true


func _reservation_geometry(record: Dictionary) -> Dictionary:
	if record.is_empty() or not record.get("adapter") is Dictionary:
		return {}
	return {"id": record.get("id"), "geometry": record.get("geometry"), "planned_endpoint": record["adapter"].get("planned_endpoint"), "direction": record["adapter"].get("direction"), "active_from_s": record.get("active_from_s"), "active_until_s": record.get("active_until_s"), "recovery_until_s": record.get("recovery_until_s")}


func _observe_lunge(record: Dictionary, hp_before: float, label: String) -> void:
	var start: Vector3 = record["adapter"]["start"]
	var endpoint: Vector3 = record["adapter"]["planned_endpoint"]
	var moved: float = 0.0
	var active_seen: bool = false
	var recovery_seen: bool = false
	var geometry_fixed: bool = true
	var safe: bool = true
	for _index: int in range(_frame_limit(1.0)):
		var state: Dictionary = _source.call("state")
		if state["phase"] == "recovery":
			recovery_seen = true
			break
		if state["phase"] != "active":
			break
		active_seen = true
		moved = maxf(moved, _source.global_position.distance_to(start))
		geometry_fixed = geometry_fixed and _exact(_reservation_geometry(record), _reservation_geometry(_scheduler.reservation_state(String(record["id"]))))
		safe = safe and _hero.hp == hp_before and _hit_results.is_empty()
		await _ticks(1)
	_expect(active_seen and moved > 0.1 and recovery_seen, label + ": actual source travels during active and reaches recovery within a finite wait")
	_expect(recovery_seen and _source.global_position.distance_to(endpoint) <= EndpointTolerance and _source.velocity.length() <= EndpointTolerance, label + ": actual physical endpoint is within 0.005 world units and recovery stops motion")
	_expect(geometry_fixed and safe and _hero.hp == hp_before, label + ": fixed reserved lane causes no damage to the lateral escape landing")


func _contact_case() -> void:
	if not await _open_case("real moving-radius contact and consumed-hit restore"):
		await _close_case()
		return
	var hp_before: float = _hero.hp
	var warning: Dictionary = await _wait_phase("warning", 4.0)
	if warning.is_empty():
		await _close_case()
		return
	var record: Dictionary = _scheduler.reservation_state(String(warning["reservation_id"]))
	if not _reservation_checks(warning, record):
		await _close_case()
		return
	var active: Dictionary = await _wait_phase("active", 2.0)
	if active.is_empty():
		await _close_case()
		return
	var initial_gap: Vector3 = _hero.global_position - _source.global_position
	initial_gap.y = 0.0
	_expect(initial_gap.length() > CombinedContactRadius and _hero.hp == hp_before and _hit_results.is_empty(), "hero inside the reserved lane takes no whole-lane damage while the active body is still distant")
	var distant_samples: int = 0
	var distant_safe: bool = true
	for _index: int in range(_frame_limit(0.7)):
		if not _hit_results.is_empty():
			break
		var state: Dictionary = _source.call("state")
		if state["phase"] != "active":
			break
		var gap: Vector3 = _hero.global_position - _source.global_position
		gap.y = 0.0
		if gap.length() > CombinedContactRadius + 0.005:
			distant_samples += 1
			distant_safe = distant_safe and _hero.hp == hp_before
		await _ticks(1)
	if not _expect(distant_samples > 0 and distant_safe and _hit_results.size() == 1 and _hero.hp < hp_before, "only the physically arriving moving radius consumes one contact opportunity"):
		await _close_case()
		return
	var hit: Dictionary = _hit_results[0]
	_expect(bool(hit.get("accepted", false)) and bool(hit.get("opportunity_consumed", false)) and float(hit.get("hp_damage", 0.0)) == hp_before - _hero.hp and hit.get("impulse") == Vector3.ZERO, "owned contact event reports the actual HP loss and explicit zero impulse")
	var consumed: Dictionary = await _pause_pair("consumed active contact")
	if consumed.is_empty():
		await _close_case()
		return
	_expect(consumed["level"]["local"]["stalker"]["phase"] == "active" and bool(consumed["level"]["local"]["stalker"]["hit_consumed"]), "paired JSON captures an active lunge after its real contact opportunity was consumed")
	_game.call("resume_lab")
	await _wait_phase("recovery", 1.0)
	await _pause_pair("later consumed-contact recovery")
	if not _restore_pair(consumed, "consumed contact"):
		await _close_case()
		return
	_game.call("resume_lab")
	await _wait_phase("recovery", 1.0)
	_expect(_hit_results.size() == 1 and _hero.hp == float(consumed["hero"]["resources"]["hp"]) and bool((_source.call("state") as Dictionary)["hit_consumed"]), "resuming the restored consumed active segment cannot hurt the hero a second time")
	_expect(_no_blasts() and _hero.get_world_action_records().is_empty(), "stationary contact fixture executes no movement, primary or blast")
	await _close_case()


func _snapshot_case() -> void:
	if not await _open_case("active paired JSON restore and atomic malformed-state rejection"):
		await _close_case()
		return
	var warning: Dictionary = await _wait_phase("warning", 4.0)
	if warning.is_empty():
		await _close_case()
		return
	var record: Dictionary = _scheduler.reservation_state(String(warning["reservation_id"]))
	if not _reservation_checks(warning, record):
		await _close_case()
		return
	var locked: Dictionary = await _wait_phase("lock", 2.0)
	if locked.is_empty():
		await _close_case()
		return
	await _dash_completed(Vector3.RIGHT, "snapshot case real lateral escape")
	var active: Dictionary = await _wait_phase("active", 1.0)
	if active.is_empty():
		await _close_case()
		return
	await _ticks(3)
	_hero.hp = 37.25
	_hero.shells = 0
	var saved: Dictionary = await _pause_pair("fractional-resource mid-active pair")
	if saved.is_empty():
		await _close_case()
		return
	var local: Dictionary = saved["level"]["local"]
	_expect(local["stalker"]["phase"] == "active" and not bool(local["stalker"]["hit_consumed"]) and Codec.read_vector3(local["stalker"]["position"]).distance_to(record["adapter"]["start"]) > 0.1, "paired capture contains a genuinely moving active source and unconsumed contact sample")
	var frozen_events: Dictionary = _events.duplicate(true)
	await create_timer(0.08, true).timeout
	_expect(_native_pair_exact({"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}, saved) and _exact(_events, frozen_events), "paused barrier freezes actor, physical source, scheduler, scenic clock and action history exactly")
	_game.call("resume_lab")
	await _wait_phase("recovery", 1.0)
	await _dash_completed(Vector3.LEFT, "later state adds a completed return action")
	_hero.hp = 62.5
	_hero.shells = 1
	var later: Dictionary = await _pause_pair("later recovery/resources/history")
	_expect(not later.is_empty() and not _exact(later, saved) and _hero.get_world_action_records().size() == 2, "later actual recovery differs in pose, deadlines elapsed, resources and completed-action history")
	if not _restore_pair(saved, "unconsumed active segment"):
		await _close_case()
		return
	_atomic_corruptions(saved["level"])
	var restored_hp: float = _hero.hp
	_game.call("resume_lab")
	await _observe_lunge(_scheduler.reservation_state(String(record["id"])), restored_hp, "restored active segment")
	_expect(_hero.get_world_action_records().size() == 1 and _hit_results.is_empty() and _no_blasts(), "restored execution retains only saved completed history and creates no extra action or lateral hit")
	await _close_case()


func _pause_pair(label: String) -> Dictionary:
	_game.call("open_bench")
	# State boundaries must be outside the originating action/physics callbacks.
	await process_frame
	await process_frame
	var hero_state: Dictionary = _hero.snapshot_state()
	var level_state: Dictionary = _level.snapshot_state()
	if not _expect(paused and not hero_state.is_empty() and not level_state.is_empty(), label + ": complete actor/local pair captures at the deferred paused barrier; hero=" + _hero.last_snapshot_error + "; level=" + _level.last_snapshot_error):
		return {}
	var pair: Dictionary = {"hero": hero_state, "level": level_state}
	var encoded: String = ExactJson.stringify(pair)
	if not _expect(not encoded.is_empty(), label + ": published exact-json-1 encodes the complete finite native pair"):
		return {}
	var decoded: Dictionary = ExactJson.parse(encoded)
	if not _expect(decoded.get("accepted") == true and decoded.has("value"), label + ": published exact-json-1 explicitly accepts the complete transport; reason=" + String(decoded.get("reason", ""))):
		return {}
	# Validate the raw decoded value, never the canonical comparison copy.
	# Ordered actor/local consumer validators below remain authoritative.
	var transported: Variant = decoded["value"]
	var difference: String = _first_difference(pair, transported)
	if not difference.is_empty():
		print("EXACT JSON ROUND-TRIP FIRST DIFFERENCE: " + difference)
	if not _expect(transported is Dictionary and Codec.value_error(transported).is_empty() and _native_pair_exact(pair, transported), label + ": finite exact JSON preserves exact native vectors and exact scalar/clock/resource/history values"):
		return {}
	return transported


func _restore_pair(pair: Dictionary, label: String) -> bool:
	var before_events: Dictionary = _events.duplicate(true)
	var hit_count: int = _hit_results.size()
	if not _expect(paused and _hero.snapshot_error(pair["hero"]).is_empty() and _hero.restore_state(pair["hero"]), label + ": actual hero restores before its paired local source/scheduler"):
		return false
	if not _expect(_level.snapshot_error(pair["level"]).is_empty() and _level.restore_state(pair["level"]), label + ": actual local aggregate accepts coherent hero/source/scheduler state; " + _level.last_snapshot_error):
		return false
	_expect(_native_pair_exact({"hero": _hero.snapshot_state(), "level": _level.snapshot_state()}, pair), label + ": exact paused restoration preserves active position, clocks, resources, scenic state and completed history")
	var local: Dictionary = pair["level"]["local"]
	var state: Dictionary = _source.call("state")
	var restored: Dictionary = _scheduler.reservation_state(String(state["reservation_id"]))
	var deadlines_exact: bool = not restored.is_empty()
	for key: String in DeadlineKeys:
		deadlines_exact = deadlines_exact and _exact(restored.get(key), local["stalker"]["exchange"].get(key))
	_expect(_source.global_position == Codec.read_vector3(local["stalker"]["position"]) and _source.velocity == Codec.read_vector3(local["stalker"]["velocity"]) and state["facing"] == Codec.read_vector3(local["stalker"]["facing"]) and _scheduler.get_clock() == float(local["scheduler"]["clock_s"]) and deadlines_exact and bool(state["hit_consumed"]) == bool(local["stalker"]["hit_consumed"]), label + ": native source position and public scheduler deadlines/consumed flag match saved JSON exactly")
	var motion: Dictionary = pair["hero"]["motion"]
	var columns: Array = motion["basis"]
	_expect(_hero.global_position == Codec.read_vector3(motion["position"]) and _hero.velocity == Codec.read_vector3(motion["velocity"]) and _hero.facing == Codec.read_vector3(motion["facing"]) and _hero.global_basis == Basis(Codec.read_vector3(columns[0]), Codec.read_vector3(columns[1]), Codec.read_vector3(columns[2])), label + ": restored actual hero position/velocity/facing/basis equal the decoded native vectors exactly")
	var motifs: Node3D = _level.find_child("ScenicSuns", true, false) as Node3D
	_expect(motifs != null and motifs.position == Vector3(_hero.global_position.x, 0, _hero.global_position.z), label + ": distant sun motifs align with the restored hero before any simulation tick")
	_expect(_exact(_events, before_events) and _hit_results.size() == hit_count, label + ": restoration emits no hit, action, death, phase, cancellation, equipment or progression event")
	return true


func _atomic_corruptions(valid: Dictionary) -> void:
	var records: Array = valid["local"]["scheduler"]["reservations"]
	if not _expect(records.size() == 1 and records[0]["adapter"].get("planned_endpoint") is Array, "active snapshot exposes one actual physical source endpoint for corruption cases"):
		return
	var candidates: Array[Dictionary] = []
	var labels: Array[String] = []
	var endpoint: Dictionary = valid.duplicate(true)
	endpoint["local"]["scheduler"]["reservations"][0]["adapter"]["planned_endpoint"][0] += 0.125
	candidates.append(endpoint)
	labels.append("spoofed physical source endpoint")
	var clock: Dictionary = valid.duplicate(true)
	clock["local"]["scheduler"]["clock_s"] += 0.2
	candidates.append(clock)
	labels.append("mismatched scheduler/source clock")
	var cooldown: Dictionary = valid.duplicate(true)
	cooldown["local"]["stalker"]["cooldown_until_s"] += 0.5
	candidates.append(cooldown)
	labels.append("mismatched retained source cooldown")
	var role: Dictionary = valid.duplicate(true)
	role["local"]["stalker"]["resolved_role"]["max_hp"] += 1.0
	candidates.append(role)
	labels.append("spoofed resolved difficulty role")
	for index: int in range(candidates.size()):
		var hero_before: Dictionary = _hero.snapshot_state()
		var local_before: Dictionary = _level.snapshot_state()
		var events_before: Dictionary = _events.duplicate(true)
		var hit_count: int = _hit_results.size()
		var error: String = _level.snapshot_error(candidates[index])
		var accepted: bool = _level.restore_state(candidates[index])
		_expect(not error.is_empty() and not accepted, labels[index] + " rejects through the actual local validator")
		_expect(_exact(_hero.snapshot_state(), hero_before) and _exact(_level.snapshot_state(), local_before) and _exact(_events, events_before) and _hit_results.size() == hit_count, labels[index] + " leaves actor/source/scheduler/scenery/history and event counts unchanged")
	_expect(_level.snapshot_error(valid).is_empty(), "prior valid paired snapshot remains acceptable after all rejected candidates")


func _wait_phase(wanted: String, seconds: float) -> Dictionary:
	var deadline: float = _scheduler.get_clock() + seconds
	for _index: int in range(_frame_limit(seconds)):
		var state: Dictionary = _source.call("state")
		if _scheduler.get_clock() > deadline:
			break
		if state.get("phase") == wanted:
			return state
		if bool(state.get("dead", false)):
			break
		await _ticks(1)
	var final_state: Dictionary = _source.call("state")
	_print_grounded_lunge_diagnostic(final_state)
	_expect(false, "bounded wait did not reach " + wanted + "; phase=" + String(final_state.get("phase", "")) + "; rejection=" + String(final_state.get("last_rejection", "")) + "; cancel=" + String(final_state.get("last_cancel_reason", "")) + "; scheduler=" + _scheduler.last_error)
	return {}


## Diagnostic only: one public nonmutating .05m query from the actual pose.
## No source teleport, recovery move, margin change or private helper call.
func _print_grounded_lunge_diagnostic(source_state: Dictionary) -> void:
	var before_position: Vector3 = _source.global_position
	var before_velocity: Vector3 = _source.velocity
	var from_transform: Transform3D = _source.global_transform
	var diagnostic: Dictionary = {
		"scope": "nonmutating_first_step_from_actual_grounded_source",
		"clock_s": _scheduler.get_clock(),
		"phase": source_state.get("phase", ""),
		"last_rejection": source_state.get("last_rejection", ""),
		"source": {
			"path": String(_source.get_path()),
			"position_before": Codec.vector3(before_position),
			"velocity_before": Codec.vector3(before_velocity),
			"is_on_floor": _source.is_on_floor(),
			"floor_normal": Codec.vector3(_source.get_floor_normal()),
			"position_delta": Codec.vector3(_source.get_position_delta()),
			"real_velocity": Codec.vector3(_source.get_real_velocity()),
			"safe_margin": _source.safe_margin,
			"floor_snap_length": _source.floor_snap_length,
			"layer": _source.collision_layer,
			"mask": _source.collision_mask,
			"global_basis": [Codec.vector3(from_transform.basis.x), Codec.vector3(from_transform.basis.y), Codec.vector3(from_transform.basis.z)],
			"linear_axis_locks": [_source.axis_lock_linear_x, _source.axis_lock_linear_y, _source.axis_lock_linear_z],
		},
	}
	var collision: CollisionShape3D = _source.get_node_or_null("BodyCollision") as CollisionShape3D
	var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D if is_instance_valid(collision) else null
	if is_instance_valid(collision) and is_instance_valid(capsule):
		var bottom_y: float = collision.global_position.y - capsule.height * collision.global_basis.y.length() * 0.5
		diagnostic["capsule"] = {
			"path": String(collision.get_path()),
			"local_position": Codec.vector3(collision.position),
			"global_position": Codec.vector3(collision.global_position),
			"global_basis_identity": collision.global_basis.is_equal_approx(Basis.IDENTITY),
			"radius": capsule.radius,
			"height": capsule.height,
			"shape_margin": capsule.margin,
			"custom_solver_bias": capsule.custom_solver_bias,
			"disabled": collision.disabled,
			"bottom_y": bottom_y,
		}
		var bindings_value: Variant = _level.call("scheduler_bindings")
		if bindings_value is Dictionary and bindings_value.get("floors") is Dictionary:
			var region: Variant = bindings_value["floors"].get("shelf-floor")
			if region is Dictionary:
				var floor_collision: CollisionShape3D = region.get("collision") as CollisionShape3D
				var floor_box: BoxShape3D = floor_collision.shape as BoxShape3D if is_instance_valid(floor_collision) else null
				if is_instance_valid(floor_collision) and is_instance_valid(floor_box):
					var floor_top_y: float = floor_collision.global_position.y + floor_box.size.y * floor_collision.global_basis.y.length() * 0.5
					diagnostic["floor"] = {
						"path": String(floor_collision.get_path()),
						"local_position": Codec.vector3(floor_collision.position),
						"global_position": Codec.vector3(floor_collision.global_position),
						"global_basis_identity": floor_collision.global_basis.is_equal_approx(Basis.IDENTITY),
						"box_size": Codec.vector3(floor_box.size),
						"shape_margin": floor_box.margin,
						"top_y": floor_top_y,
						"capsule_bottom_clearance_y": bottom_y - floor_top_y,
					}
	var direction_value: Variant = source_state.get("facing")
	if direction_value is Vector3 and (direction_value as Vector3).is_finite():
		var step: Vector3 = (direction_value as Vector3) * 0.05
		var check := KinematicCollision3D.new()
		var blocked: bool = _source.test_move(from_transform, step, check, 0.001, true, 1)
		var contacts: Array = []
		for index: int in range(check.get_collision_count()):
			var collider: Object = check.get_collider(index)
			contacts.append({"collider_path": String((collider as Node).get_path()) if collider is Node else "", "collider_class": collider.get_class() if is_instance_valid(collider) else "", "position": Codec.vector3(check.get_position(index)), "normal": Codec.vector3(check.get_normal(index))})
		diagnostic["query"] = {"requested_step": Codec.vector3(step), "safe_margin": 0.001, "recovery_as_collision": true, "max_collisions": 1, "blocked": blocked, "reported_travel": Codec.vector3(check.get_travel()), "interpreted_travel": Codec.vector3(check.get_travel() if blocked else step), "remainder": Codec.vector3(check.get_remainder()), "collision_count": check.get_collision_count(), "contacts": contacts}
	else:
		diagnostic["query_error"] = "Actual public source facing is not a finite Vector3"
	diagnostic["source"]["position_after"] = Codec.vector3(_source.global_position)
	diagnostic["source"]["velocity_after"] = Codec.vector3(_source.velocity)
	diagnostic["source"]["position_unchanged"] = _source.global_position == before_position
	diagnostic["source"]["velocity_unchanged"] = _source.velocity == before_velocity
	print("Grounded lunge first-step diagnostic: " + JSON.stringify(diagnostic, "", true, true))


func _dash_completed(direction: Vector3, label: String) -> void:
	var origin: Vector3 = _hero.global_position
	var sequence: int = _last_sequence()
	var stats: Dictionary = _hero.equipment.resolved_stats()
	var accepted: bool = _hero.request_dash(direction)
	var actions: Array[Dictionary] = []
	for _index: int in range(_frame_limit(float(stats["dash_duration"]) + 0.25)):
		actions = _hero.get_world_action_records(sequence)
		if not actions.is_empty():
			break
		await _ticks(1)
	var valid: bool = accepted and actions.size() == 1
	if valid:
		var action: Dictionary = actions[0]
		valid = action["kind"] == "dash" and not bool(action["blocked"]) and not bool(action["collision_shortened"]) and float(action["completed_at_s"]) > float(action["started_at_s"]) and (action["world_origin"] as Vector3).distance_to(origin) <= EndpointTolerance and (action["landing"] as Vector3).distance_to(_hero.global_position) <= EndpointTolerance and absf(float(action["distance"]) - float(stats["dash_distance"])) <= 0.02
		var path: Array = action["path"]
		valid = valid and path.size() >= 2
	_expect(valid, label + ": one actual ordinary full-distance dash publishes its completed world path and landing")


func _last_sequence() -> int:
	var records: Array[Dictionary] = _hero.get_world_action_records()
	return int(records[-1]["sequence"]) if not records.is_empty() else 0


func _no_blasts() -> bool:
	for action: Dictionary in _hero.get_world_action_records():
		if action.get("kind") == "blast":
			return false
	return true


func _frame_limit(seconds: float) -> int:
	return int(ceilf(seconds * float(Engine.physics_ticks_per_second))) + 8


func _ticks(count: int) -> void:
	for _index: int in range(count):
		if paused and is_instance_valid(_game) and _game.has_method("resume_lab"):
			_game.call("resume_lab")
		await physics_frame
		await process_frame


func _close_case() -> void:
	if is_instance_valid(_level):
		_level.exit_level()
	if is_instance_valid(_scheduler):
		_expect(_scheduler.reservations().is_empty(), "public level exit releases all source reservations")
	if is_instance_valid(_game):
		_game.queue_free()
	paused = false
	await process_frame
	# The actual slash/hit voices are 0.09s (minimum pitch0.92). Keep their
	# finite audio-server retirement alive after world deletion; no live
	# gameplay clock remains and no warning or sound policy is suppressed.
	await create_timer(0.15, true).timeout
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("practice_targets").is_empty(), "fresh-case cleanup frees enemy/proxy group remnants")
	_game = null
	_level = null
	_hero = null
	_source = null
	_scheduler = null


## Correct the fixture's known all-promoted-double expectation, not runtime
## acceptance: .cinder/stalker-room-sun1-json-diagnostic.log first differed at
## hero.motion.position[1] by 7 double ULPs, while both restored float32 bits
## were 6bb89ebb. Codec.vector3/read_vector3 define these fields as native
## Vector3, not independent 64-bit coordinates. Canonicalize only those exact
## codec paths before comparing transport/native recapture. The raw decoded
## value remains unmodified and is still the actual restore input. No timing, role,
## radius, resource, config or other scalar receives tolerance or conversion.
## Schemas inspected: player.snapshot_state/_encode_world_record;
## sunbound_stalker.snapshot_state; threat_scheduler._capture_snapshot,
## _encode_adapter/_encode_geometry/_transform_data/_shape_data;
## lunge_motion.source_description. This fixture has no camera snapshot.
func _native_pair_exact(a: Dictionary, b: Dictionary) -> bool:
	var left: Dictionary = _canonical_native_vectors(a)
	var right: Dictionary = _canonical_native_vectors(b)
	var identical: bool = _exact(left, right)
	if not identical:
		print("JSON NATIVE-SCHEMA FIRST DIFFERENCE: " + _first_difference(left, right))
	return identical


func _canonical_native_vectors(pair: Dictionary) -> Dictionary:
	var result: Dictionary = pair.duplicate(true)
	# Each terminal below is an actual Codec.vector3 field, never a guess
	# based on length, suffix or a generic 'position' field name. Wildcards
	# visit only the declared array elements/basis/transform vector rows.
	var vector_paths: Array = [
		["hero", "motion", "position"],
		["hero", "motion", "velocity"],
		["hero", "motion", "facing"],
		["hero", "motion", "dash_direction"],
		["hero", "motion", "queued_dash"],
		["hero", "motion", "dash_origin"],
		["hero", "motion", "basis", "*"],
		["hero", "world_actions", "history", "*", "world_origin"],
		["hero", "world_actions", "history", "*", "direction"],
		["hero", "world_actions", "history", "*", "landing"],
		["hero", "world_actions", "history", "*", "path", "*", "position"],
		["hero", "world_actions", "pending_dash", "world_origin"],
		["hero", "world_actions", "pending_dash", "direction"],
		["hero", "world_actions", "pending_dash", "landing"],
		["hero", "world_actions", "pending_dash", "path", "*", "position"],
		["level", "local", "stalker", "position"],
		["level", "local", "stalker", "velocity"],
		["level", "local", "stalker", "facing"],
		["level", "local", "stalker", "previous", "source_position"],
		["level", "local", "stalker", "previous", "hero_position"],
		["level", "local", "stalker", "commit", "source_position"],
		["level", "local", "stalker", "commit", "hero_position"],
		["level", "local", "stalker", "commit", "facing"],
		["level", "local", "scheduler", "reservations", "*", "source_position"],
		["level", "local", "scheduler", "reservations", "*", "opening_position"],
		["level", "local", "scheduler", "reservations", "*", "geometry", "from"],
		["level", "local", "scheduler", "reservations", "*", "geometry", "to"],
		["level", "local", "scheduler", "reservations", "*", "geometry", "origin"],
		["level", "local", "scheduler", "reservations", "*", "geometry", "direction"],
		["level", "local", "scheduler", "reservations", "*", "adapter", "start"],
		["level", "local", "scheduler", "reservations", "*", "adapter", "planned_endpoint"],
		["level", "local", "scheduler", "reservations", "*", "adapter", "current_position"],
		["level", "local", "scheduler", "reservations", "*", "adapter", "current_velocity"],
		["level", "local", "scheduler", "reservations", "*", "adapter", "direction"],
		["level", "local", "scheduler", "reservations", "*", "adapter", "body_signature", "centre"],
		["level", "local", "scheduler", "reservations", "*", "floors", "*", "signature", "transform", "*"],
		["level", "local", "scheduler", "reservations", "*", "floors", "*", "signature", "size"],
		["level", "local", "scheduler", "collision", "colliders", "*", "transform", "*"],
		["level", "local", "scheduler", "collision", "colliders", "*", "shapes", "*", "transform", "*"],
		["level", "local", "scheduler", "collision", "colliders", "*", "shapes", "*", "data", "size"],
		["level", "local", "scheduler", "collision", "colliders", "*", "shapes", "*", "data", "points", "*"],
	]
	for path: Array in vector_paths:
		_canonical_vector_path(result, path)
	return result


func _canonical_vector_path(value: Variant, path: Array, index: int = 0) -> Variant:
	if index == path.size():
		return Codec.vector3(Codec.read_vector3(value)) if Codec.is_vector3(value) else value
	var key: String = String(path[index])
	if value is Dictionary and value.has(key):
		value[key] = _canonical_vector_path(value[key], path, index + 1)
	elif value is Array and key == "*":
		for element: int in range(value.size()):
			value[element] = _canonical_vector_path(value[element], path, index + 1)
	return value


## Exact transport/state comparison: JSON integer/float representation changes
## are allowed only when the numeric value is equal, never by approximate clock.
func _exact(a: Variant, b: Variant) -> bool:
	if (a is float or a is int) and (b is float or b is int):
		return float(a) == float(b)
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for key: Variant in a:
			if not b.has(key) or not _exact(a[key], b[key]):
				return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for index: int in range(a.size()):
			if not _exact(a[index], b[index]):
				return false
		return true
	return typeof(a) == typeof(b) and a == b


## Diagnostic only; the comparator and transport assertion remain strict.
## Historical decimal JSON lost a real scalar-clock bit; exact-json-1 now
## carries production snapshot values without that decimal parser path.
## Ordinary JSON formatting here is only human-readable diagnostic text,
## accompanied by native byte evidence, never decoded restore input.
func _first_difference(a: Variant, b: Variant, path: String = "$") -> String:
	if (a is float or a is int) and (b is float or b is int):
		if float(a) == float(b):
			return ""
		return path + ": left " + _diagnostic_value(a) + "; right " + _diagnostic_value(b) + "; delta=" + JSON.stringify(float(b) - float(a), "", false, true) + "; left_float_bytes=" + var_to_bytes(float(a)).hex_encode() + "; right_float_bytes=" + var_to_bytes(float(b)).hex_encode()
	if a is Dictionary and b is Dictionary:
		for key: Variant in a:
			var child_path: String = path + "." + String(key)
			if not b.has(key):
				return child_path + ": missing decoded key (native key type=" + type_string(typeof(key)) + ")"
			var difference: String = _first_difference(a[key], b[key], child_path)
			if not difference.is_empty():
				return difference
		for key: Variant in b:
			if not a.has(key):
				return path + "." + String(key) + ": extra decoded key"
		return ""
	if a is Array and b is Array:
		if a.size() != b.size():
			return path + ": array size left=" + str(a.size()) + "; right=" + str(b.size())
		for index: int in range(a.size()):
			var difference: String = _first_difference(a[index], b[index], path + "[%d]" % index)
			if not difference.is_empty():
				return difference
		return ""
	if typeof(a) == typeof(b) and a == b:
		return ""
	return path + ": left " + _diagnostic_value(a) + "; right " + _diagnostic_value(b)


func _diagnostic_value(value: Variant) -> String:
	var label: String = type_string(typeof(value))
	if value is Dictionary or value is Array:
		return label + "(size=" + str(value.size()) + ")"
	return label + "(" + JSON.stringify(value, "", false, true) + ")"


func _record_event(kind: String) -> void:
	_events[kind] = int(_events.get(kind, 0)) + 1


func _on_source_state(_state: Dictionary) -> void:
	_record_event("source_state")


func _on_source_hit(result: Dictionary) -> void:
	_hit_results.append(result.duplicate(true))
	_record_event("source_hit")


func _on_source_died(_where: Vector3) -> void:
	_record_event("source_death")


func _on_invalidated(_id: String, _reason: String) -> void:
	_record_event("reservation_invalidated")


func _on_world_action(_record: Dictionary) -> void:
	_record_event("world_action")


func _on_action_resolved(_kind: String, _hits: int, _damage: float) -> void:
	_record_event("action_resolved")


func _on_fired(_kind: String) -> void:
	_record_event("fired")


func _on_hero_died() -> void:
	_record_event("hero_death")


func _on_equipment(_id: String) -> void:
	_record_event("equipment")


func _on_completion(_level_id: String, _completion_id: String) -> void:
	_record_event("completion")


func _on_checkpoint(_level_id: String, _checkpoint_id: String, _boundary: String) -> void:
	_record_event("checkpoint")


func _on_exit_request(_level_id: String, _exit_id: String) -> void:
	_record_event("exit")


func _expect(ok: bool, label: String) -> bool:
	_checks += 1
	if ok:
		print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label)
	return ok


func _finish() -> void:
	print("Act 3 Stalker rule smoke: %d checks, %d failures. Public mechanic fixtures only." % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
