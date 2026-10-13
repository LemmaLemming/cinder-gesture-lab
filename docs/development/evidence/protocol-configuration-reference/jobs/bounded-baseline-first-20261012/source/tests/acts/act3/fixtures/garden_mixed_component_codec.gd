extends RefCounted
## TEST ONLY component wire. Never a canonical late A3-L4 route packet.
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/combat/authored_enemy_sequence.gd")
const Transport = preload("res://scripts/combat/authored_echo_terminal_receipt.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Model = preload("res://scripts/acts/act3/false_paradise_codec.gd")
const Core = preload("res://scripts/acts/act3/garden_root_network.gd")
const Echo = preload("res://scripts/acts/act3/mirror_echo.gd")
const Helper = preload("res://scripts/acts/act3/garden_root_latcher.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const RECIPIENT_PATH: String = "res://tests/acts/act3/fixtures/garden_mixed_component.gd"
const API: String = "TEST-act3-garden-mixed-components-1"
const KEYS: Array[String] = ["api_revision", "schema_version", "world", "scheduler", "echo", "core", "helper", "control", "sun", "view", "presentation"]
const WORLD_KEYS: Array[String] = ["declaration_id", "cell", "encounter_id", "world_revision", "profile_id", "collision_fingerprint", "floor_signature"]
const CONTROL_KEYS: Array[String] = ["anchor_s", "core_enabled", "pending_release", "released", "helper_retired", "helper_death"]
const DECLARATION: String = "TEST/A3-L4/mixed-full-floor-near-root-echo"
var last_error: String = ""

func _same(a: Variant, b: Variant) -> bool:
	return Exact.exact_equal(a, b)

func world(p) -> Dictionary:
	var bindings: Dictionary = p.scheduler_bindings()
	var floors: Dictionary = Footprint.floor_signature(bindings.world_root, bindings.floors.values())
	return {} if not floors.get("accepted", false) else {"declaration_id": DECLARATION, "cell": p.declared_cell, "encounter_id": p.ENCOUNTER, "world_revision": 1, "profile_id": p.threat_scheduler.encounter_profile().get("id", ""), "collision_fingerprint": p.threat_scheduler.pure_collision_fingerprint(bindings.world_root), "floor_signature": floors.signature}

func capture(p, player: Dictionary, camera: Camera3D = null, hud: GameHUD = null, check_optics: bool = true) -> Dictionary:
	last_error = _access(p)
	if last_error.is_empty(): last_error = p.hero.snapshot_error(player)
	if last_error.is_empty() and not _same(player, p.hero.snapshot_state()): last_error = "Capture requires the actual native Hero pair"
	if last_error.is_empty() and check_optics: last_error = optics(p, camera, hud)
	if not last_error.is_empty(): return {}
	var bindings: Dictionary = p.scheduler_bindings()
	var scheduler: Dictionary = p.threat_scheduler.snapshot_state(bindings)
	if scheduler.is_empty(): return _failed("Scheduler: " + p.threat_scheduler.last_snapshot_error)
	var playback: Dictionary = p.echo.call("snapshot_state", scheduler, bindings)
	var source: Dictionary = p.echo.call("capture_source", player, scheduler, playback)
	if source.is_empty() or playback.is_empty(): return _failed("Echo: " + String(p.echo.get("source_snapshot_error")) + "; " + String(p.echo.get("last_snapshot_error")))
	var core: Dictionary = p.root_network.call("capture", bindings, scheduler)
	if core.is_empty(): return _failed("Core: " + String(p.root_network.get("last_snapshot_error")))
	var helper: Dictionary = p.helper.call("snapshot_state", bindings) if is_instance_valid(p.helper) else {}
	if is_instance_valid(p.helper) and helper.is_empty(): return _failed("Helper: " + String(p.helper.get("last_snapshot_error")))
	var owned: Dictionary = p.owned_transport()
	var unit: Dictionary = {"api_revision": API, "schema_version": 1, "world": world(p), "scheduler": scheduler, "echo": {"source": source, "playback": playback}, "core": core, "helper": helper, "control": owned.control, "sun": owned.sun, "view": owned.view, "presentation": owned.presentation}
	last_error = prevalidate(unit, p, player)
	return unit if last_error.is_empty() else {}

func _failed(error: String) -> Dictionary:
	last_error = error
	return {}

func shape_error(u: Dictionary, p) -> String:
	var error: String = Transport.transport_error(u)
	if not error.is_empty(): return error
	if not Value.keys_error(u, KEYS).is_empty() or u.get("api_revision") != API or not u.get("schema_version") is int or u.get("schema_version") != 1: return "Closed declared TEST component1 required"
	for key: String in KEYS.slice(2):
		if not u[key] is Dictionary: return "Typed component packet required: " + key
	if not Value.keys_error(u.world, WORLD_KEYS).is_empty() or u.world.get("declaration_id") != DECLARATION or u.world.get("cell") != p.declared_cell or u.world.get("encounter_id") != p.ENCOUNTER or u.world.get("world_revision") != 1 or not u.world.get("profile_id") is String or not u.world.get("collision_fingerprint") is Dictionary or not u.world.get("floor_signature") is Array: return "Original declared component topology/world required"
	var profile: Dictionary = Difficulty.new().profile(u.world.profile_id)
	if profile.is_empty() or not _same(profile, u.scheduler.get("profile")) or u.scheduler.get("encounter_id") != p.ENCOUNTER or u.scheduler.get("world_revision") != 1 or not Transport.clock_valid(u.scheduler.get("clock_s")) or u.scheduler.get("schema_version") != 3 or not _same(u.scheduler.get("collision"), u.world.collision_fingerprint): return "Single actual native Scheduler3/profile/clock required"
	var journal: Variant = u.scheduler.get("authored_source_cycles")
	if not journal is Dictionary or not journal.get("sources") is Array or journal.sources.size() != 1 or not journal.sources[0] is Dictionary or journal.sources[0].get("source_id") != p.ECHO_ID: return "Exactly one typed declared native Echo journal required"
	var actual: Dictionary = world(p)
	for key: String in ["declaration_id", "cell", "encounter_id", "world_revision", "collision_fingerprint", "floor_signature"]:
		if not _same(u.world[key], actual.get(key)): return "Actual native component world differs: " + key
	if not Value.keys_error(u.echo, ["source", "playback"]).is_empty() or not u.echo.get("source") is Dictionary or not u.echo.get("playback") is Dictionary or not u.echo.source.get("physical") is Dictionary or not u.echo.source.get("generation") is int or not Value.is_integer(u.echo.source.generation, 1, 64) or u.echo.source.get("source_id") != p.ECHO_ID or u.echo.source.get("source_epoch") != p.ECHO_EPOCH or not _same(u.echo.source.get("clock_s"), u.scheduler.clock_s): return "Original declared managed native Echo source required"
	if not Value.keys_error(u.core, Core.UNIT_KEYS).is_empty() or u.core.get("schema_version") != 2 or not u.core.get("tether") is Dictionary or not u.core.get("mechanisms") is Dictionary or not u.core.get("control") is Dictionary or not u.core.control.get("boundaries") is Array or not u.core.control.get("cycle_records") is Dictionary: return "Original complete native Core2 required"
	var target: Dictionary = u.core.tether
	if not target.get("hp") is float or not target.get("phase") is int or not target.get("dead") is bool or target.hp < 0.0 or target.hp > 60.0 or target.phase != (3 if target.hp == 0.0 else (1 if target.hp > 30.0 else 2)) or target.dead != (target.hp == 0.0) or u.core.control.boundaries.size() != target.phase - 1 or not _same(target.get("clock_s"), u.scheduler.clock_s): return "Native monotonic60/30/0 target and genuine boundary prefix required"
	if not Value.keys_error(u.control, CONTROL_KEYS).is_empty() or not u.control.get("core_enabled") is bool or not u.control.get("pending_release") is bool or not u.control.get("released") is bool or not u.control.get("helper_retired") is Dictionary or not u.control.get("helper_death") is Dictionary or u.control.pending_release and u.control.released or target.dead != (u.control.pending_release or u.control.released): return "Exact component boundary/release state required"
	if not u.control.core_enabled and (target.phase != 1 or not u.core.control.cycle_records.is_empty()): return "Declared inactive core cannot manufacture a played cycle"
	var anchor: Variant = null
	if target.phase >= 2:
		var first: Variant = u.core.control.boundaries[0]
		if not first is Dictionary or not Transport.clock_valid(first.get("clock_s")): return "Actual first target boundary required"
		anchor = first.clock_s
	if not _same(anchor, u.control.anchor_s) or not _same(u.sun, Model.sun_at(anchor, u.scheduler.clock_s)): return "Sun derives only from real first boundary and actual outer clock"
	if (target.phase >= 2) != (not u.helper.is_empty()): return "Exactly one helper is entitled by the real first target boundary"
	if not u.helper.is_empty():
		if not u.helper.get("dead") is bool or not u.helper.get("hp") is float or not u.helper.get("mechanism") is Dictionary or not _same(u.helper.get("clock_s"), u.scheduler.clock_s) or u.helper.get("stable_id") != p.HELPER_ID or not _same(u.helper.get("position"), Value.vector3(p.HELPER_POSITION)): return "Original fixed actual helper/lifecycle required"
		if u.helper.dead != (not u.control.helper_death.is_empty()): return "Real helper death receipt agrees with native lifecycle"
		if u.helper.dead:
			var death: Dictionary = u.control.helper_death
			if not Value.keys_error(death, ["clock_s", "position"]).is_empty() or not Transport.clock_valid(death.get("clock_s")) or death.clock_s < anchor or death.clock_s > u.scheduler.clock_s or not _same(death.position, u.helper.position) or u.helper.hp != 0.0 or u.helper.mechanism.get("last_cancel_reason") != "source_defeated" or not u.control.helper_retired.is_empty(): return "Dead helper retains real source_defeated clock/body receipt"
		elif u.control.released:
			var retired: Dictionary = u.control.helper_retired
			if not Value.keys_error(retired, ["clock_s", "cycle", "hp", "reason"]).is_empty() or not Transport.clock_valid(retired.get("clock_s")) or not retired.get("cycle") is int or not _same(retired.get("hp"), u.helper.hp) or retired.reason != "test_garden_released" or retired.clock_s > u.scheduler.clock_s or not _same(retired.cycle, u.helper.mechanism.get("cycle")) or u.helper.mechanism.get("last_cancel_reason") != retired.reason or u.helper.mechanism.get("status") != ("idle" if retired.cycle == 0 else "cancelled"): return "Living helper retirement preserves its real HP/cycle/reason"
		elif not u.control.helper_retired.is_empty(): return "Unsettled release cannot invent retirement"
	elif not u.control.helper_retired.is_empty() or not u.control.helper_death.is_empty(): return "Absent helper cannot manufacture lifecycle"
	if not Value.keys_error(u.view, ["positions"]).is_empty() or not u.view.get("positions") is Array or u.view.positions.size() > 12: return "Bounded native current-generation view transport required"
	for point: Variant in u.view.positions:
		if not _vector(point): return "View retains exact native vector triples"
	if u.echo.playback.get("status") == "cycle_ready" and not u.view.positions.is_empty(): return "Declared ready generation has no forged proof path"
	return String(p.scenery.call("presentation_error", u.presentation, true, u.control.released))

func _vector(value: Variant) -> bool:
	if not value is Array or value.size() != 3: return false
	for x: Variant in value:
		if not x is float or not is_finite(x): return false
	return _same(value, Value.vector3(Value.read_vector3(value)))

func _staged(u: Dictionary, p, player: Dictionary) -> Dictionary:
	var bindings: Dictionary = p.scheduler_bindings()
	bindings.hero_positions = {"hero": Value.read_vector3(player.motion.position)}
	bindings.owner_positions = {"l4-garden-draw": Vector3(-1, 0, 1.25), "l4-garden-enclose": Vector3.ZERO}
	if not u.helper.is_empty(): bindings.owner_positions[p.HELPER_ID + "/attack"] = p.HELPER_POSITION
	bindings.authored_owner_bindings = {p.ECHO_ID: p.echo.call("staged_source_binding", u.echo.source, player, u.scheduler, u.echo.playback)}
	bindings.authored_cycle_playback_ids = {p.ECHO_ID: u.echo.playback.get("playback_id", "")}
	return bindings

func prevalidate(u: Dictionary, p, player: Dictionary, paired: bool = true) -> String:
	var error: String = _access(p)
	if error.is_empty(): error = shape_error(u, p)
	if error.is_empty(): error = p.hero.snapshot_error(player)
	if not error.is_empty(): return error
	if not _vector(player.motion.position) or not _same(player.world_actions.clock_s, u.scheduler.clock_s) or not _same(u.world.profile_id, p.threat_scheduler.encounter_profile().get("id")): return "Actual saved Hero/native clock/profile pair required"
	if is_instance_valid(p.helper) != (not u.helper.is_empty()): return "Exact declared recipient helper topology required"
	error = p.echo.call("source_record_error", u.echo.source, player, u.scheduler, u.echo.playback)
	if not error.is_empty(): return error
	var bindings: Dictionary = _staged(u, p, player)
	error = p.threat_scheduler.snapshot_error(u.scheduler, bindings)
	if not error.is_empty(): return "Whole Scheduler: " + error
	error = p.root_network.call("snapshot_error", u.core, player, bindings, u.scheduler)
	if not error.is_empty(): return "Core: " + error
	if not u.helper.is_empty():
		error = p.helper.call("snapshot_error", u.helper, bindings, u.scheduler)
		if not error.is_empty(): return "Helper: " + error
	if paired:
		error = p.echo.call("snapshot_error", u.echo.playback, p.threat_scheduler, u.scheduler, bindings, {"hero": p.hero}, p.floor_regions(), p.context_for_generation(u.echo.source.generation))
		if not error.is_empty(): return "Playback: " + error
	for kind: String in u.core.control.cycle_records:
		var record: Dictionary = u.core.control.cycle_records[kind]
		var exchange: Dictionary = u.core.mechanisms[kind].exchange
		if not _same(record.sun_choice, Model.effective_sun(u.control.anchor_s, exchange.start_s)): return "Real held Core choice remains its original admission sun"
	for boundary: Dictionary in u.core.control.boundaries:
		var receipt: Dictionary = boundary.recovery_receipt
		if not _same(receipt.sun_choice, Model.effective_sun(u.control.anchor_s, receipt.exchange.start_s)): return "Historical Core recovery keeps its original admission sun"
	if not u.control.helper_death.is_empty():
		var exchange: Dictionary = u.helper.mechanism.exchange
		if u.control.helper_death.clock_s <= exchange.active_until_s or u.control.helper_death.clock_s > exchange.recovery_until_s: return "Helper death receipt must join its genuine ordinary recovery"
	if not u.control.helper_retired.is_empty() and u.control.helper_retired.clock_s < u.core.control.boundaries[-1].clock_s: return "Helper retirement cannot precede actual final target boundary"
	return ""

func commit(u: Dictionary, p, player: Dictionary, abort_after_scheduler: bool) -> String:
	var error: String = prevalidate(u, p, player)
	if not error.is_empty(): return error
	if not p.is_restore_candidate() or not _same(player, p.hero.snapshot_state()): return "Quiet component commit requires its actual restored Hero/fresh candidate"
	var staged: Dictionary = _staged(u, p, player)
	if not p.root_network.call("stage_quiet_restore", u.core, player, staged, u.scheduler): return String(p.root_network.get("last_snapshot_error"))
	if not p.echo.call("restore_source_physical", u.echo.source, player, u.scheduler, u.echo.playback): return String(p.echo.get("source_snapshot_error"))
	if not u.helper.is_empty() and not p.helper.call("apply_validated_state", u.helper): return String(p.helper.get("last_snapshot_error"))
	if not p.root_network.call("apply_staged_target"): return "Actual prevalidated tether physical commit changed"
	var bindings: Dictionary = p.scheduler_bindings()
	if not p.threat_scheduler.restore_state(u.scheduler, bindings): return p.threat_scheduler.last_snapshot_error
	if abort_after_scheduler: return "TEST ONLY deliberate abort after actual Scheduler commit before Playback/Lane"
	if not p.echo.call("restore_state", u.echo.playback, p.threat_scheduler, u.scheduler, bindings, {"hero": p.hero}, p.floor_regions(), p.context_for_generation(u.echo.source.generation)) or not p.echo.call("verify_restored_source_phase", u.echo.source): return String(p.echo.get("last_snapshot_error"))
	if not u.helper.is_empty() and not p.helper.call("restore_mechanism_state", u.helper, bindings): return String(p.helper.get("last_snapshot_error"))
	if not p.root_network.call("restore_staged_mechanisms") or not p.root_network.call("finish_staged_restore"): return String(p.root_network.get("last_snapshot_error"))
	error = p.apply_component_control(u)
	if not error.is_empty(): return error
	var native: Dictionary = capture(p, player, null, null, false)
	return "" if not native.is_empty() and _same(native, u) else "Independent complete native component recapture differs: " + last_error

func optics(p, camera: Camera3D = null, hud: GameHUD = null) -> String:
	if (camera == null) != (hud == null): return "Complete actual component Camera/HUD pair required"
	var actual_camera: Camera3D = camera if camera != null else p.get_viewport().get_camera_3d()
	var bounds: Dictionary = p.framing_union(actual_camera)
	if not String(bounds.error).is_empty(): return String(bounds.error)
	return String(p.shared_shell.call("camera_framing_error", bounds.points)) if camera == null else String(p.shared_shell.call("camera_framing_error_for_context", bounds.points, p.hero, camera, hud))

func _access(p) -> String:
	if not is_instance_valid(p) or not p is CinderLevel or p.get_script() == null or p.get_script().resource_path != RECIPIENT_PATH or not p.is_inside_tree() or not p.is_node_ready() or p.is_queued_for_deletion() or not p.get_tree().paused or not is_instance_valid(p.hero): return "Actual paused retained TEST component and native Hero required"
	if not is_instance_valid(p.root_network) or p.root_network.get_script() != Core or not is_instance_valid(p.echo) or p.echo.get_script() != Echo or not is_instance_valid(p.threat_scheduler) or p.threat_scheduler.get_script() != Scheduler or (is_instance_valid(p.helper) and p.helper.get_script() != Helper): return "Original actual native component actors and one Scheduler required"
	return String(p.runtime_error())
