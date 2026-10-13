extends RefCounted
## SOURCE-ONLY whole local captured-rule unit. Not native-qualified or campaign accepted.
## One outer Player; public leaf codecs; no admission/clock repair during restore.
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Capture = preload("res://scripts/combat/action_capture.gd")
const Sequence = preload("res://scripts/combat/replay_sequence.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Gate = preload("res://scripts/combat/replay_capture_gate.gd")
const Leaf = preload("res://scripts/combat/replay_playback.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const FrameArt = preload("res://scripts/acts/act3/crystalman_recorded_frame_art.gd")
const API: String = "act3-crystalman-captured-phase-2"
const BASE_SHA: String = "915252a26089e7b4ecec92a8046d42555a702af7c1566551b80e67ce39e87a6b"
const KEYS: Array[String] = ["api_revision", "schema_version", "configuration", "world", "gate", "scheduler", "playback", "owned"]
const OWNED_KEYS: Array[String] = ["frame_art", "phase", "configured", "generation", "joins", "rejections", "tether_hits", "cleared", "locked", "operation", "last_rejection", "last_camera_error", "capture_context", "sequence", "projection", "proof", "held_exchange", "join_receipt", "last_rejected_capture", "forecast", "rearm_after_clock_s", "exposure_from_s", "exposure_until_s", "presentation"]
const PROOF_KEYS: Array[String] = ["accepted", "api_revision", "proof_scope", "dispatch_delay_bound_s", "path", "attack_position", "primary_time_s", "response_complete_s", "timeline_origin_s", "evaluated_at_s", "at_lock", "event_count", "slot_count", "source_epoch", "generation", "sequence_id", "world_revision", "profile_id", "collision_fingerprint", "uses_blast", "uses_invulnerability", "reserves_threat"]
const SEGMENT_KINDS: Array[String] = ["recognition_and_ready", "first_escape_dash", "inter_echo_ready", "second_escape_dash", "tether_return_ready", "tether_positioning_dash", "ordinary_primary_ready", "tether_ready", "ordinary_primary_full_recovery"]
const EXCHANGE_KEYS: Array[String] = ["id", "source_position", "opening_position", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision", "adapter"]
const LIVE_PHASES: Array[String] = ["warning", "lock", "active", "exposed", "spent"]
var last_error: String = ""

func capture(parent, player: Dictionary, optical: bool = true) -> Dictionary:
	last_error = parent.captured_codec_boundary_error()
	if last_error.is_empty(): last_error = parent.hero.snapshot_error(player)
	if last_error.is_empty() and not same(player, parent.hero.snapshot_state()): last_error = "Writer requires the actual complete current Player"
	if last_error.is_empty() and optical: last_error = live_presentation_error(parent)
	if not last_error.is_empty(): return {}
	var gate: Dictionary = parent.capture_gate.snapshot_state()
	if gate.is_empty(): return _fail(parent.capture_gate.last_snapshot_error)
	var bindings: Dictionary = parent.scheduler_bindings()
	var scheduler: Dictionary = parent.threat_scheduler.snapshot_state(bindings)
	if scheduler.is_empty(): return _fail(parent.threat_scheduler.last_snapshot_error)
	var playback: Dictionary = {}
	if is_instance_valid(parent.playback):
		playback = parent.playback.snapshot_state(scheduler, bindings)
		if playback.is_empty(): return _fail(parent.playback.last_snapshot_error)
	var unit: Dictionary = {"api_revision": API, "schema_version": 2, "configuration": parent.captured_codec_configuration(), "world": native_world(parent), "gate": gate, "scheduler": scheduler, "playback": playback, "owned": parent.captured_codec_owned_state()}
	last_error = record_error(unit, parent, player)
	return unit if last_error.is_empty() else {}

func _fail(reason: String) -> Dictionary:
	last_error = reason
	return {}

func header_error(unit: Dictionary, parent, player: Dictionary) -> String:
	var error: String = parent.captured_codec_boundary_error()
	if error.is_empty(): error = Value.value_error(unit)
	if error.is_empty(): error = parent.hero.snapshot_error(player)
	if not error.is_empty(): return error
	if Exact.stringify(unit).is_empty() or not Value.keys_error(unit, KEYS).is_empty() or unit.get("api_revision") != API or not unit.get("schema_version") is int or unit.schema_version != 2: return "Closed exact captured production phase2 required"
	for key: String in ["configuration", "world", "gate", "scheduler", "playback", "owned"]:
		if not unit[key] is Dictionary: return "Typed whole local packet required: " + key
	if not same(unit.configuration, parent.captured_codec_configuration()): return "Immutable original room capacity/layout/source scripts differ"
	if not Value.keys_error(unit.world, ["profile_id", "encounter_id", "world_revision", "collision_fingerprint", "floor_signature"]).is_empty() or not unit.world.profile_id is String: return "Closed world/profile required"
	var profile: Dictionary = Difficulty.new().profile(unit.world.profile_id)
	if profile.is_empty() or not same(profile, unit.scheduler.get("profile")) or unit.world.encounter_id != parent.ENCOUNTER_ID or not same(unit.world.world_revision, 1): return "Original canonical active profile/encounter/world required"
	var actual: Dictionary = native_world(parent)
	for key: String in ["encounter_id", "world_revision", "collision_fingerprint", "floor_signature"]:
		if not same(unit.world[key], actual.get(key)): return "Actual original floor/collision/source world differs: " + key
	if not same(unit.scheduler.get("collision"), unit.world.collision_fingerprint) or unit.scheduler.get("encounter_id") != unit.world.encounter_id or not same(unit.scheduler.get("world_revision"), 1): return "Whole Scheduler must join original world"
	if not unit.scheduler.get("clock_s") is float or not Value.in_range(unit.scheduler.clock_s, 0.0, 1000000.0) or not same(unit.gate.get("clock_s"), player.world_actions.clock_s): return "Same observed aggregate boundary preserves Player/Gate clock and independent Scheduler clock"
	if unit.scheduler.get("schema_version") != 1 or unit.scheduler.has("replay_cancellations") or unit.scheduler.has("authored_source_cycles"): return "Canceled/managed histories are outside this retained captured-owner unit; never filter them"
	if not unit.scheduler.get("reservations") is Array or not unit.scheduler.get("cooldowns") is Array: return "Complete typed Scheduler lease/history required"
	error = leaf_shape_error(unit, parent, player)
	return error if not error.is_empty() else owned_error(unit, parent, player)

## Type/closed-envelope checks precede owned joins/arithmetic and constructor use.
## The actual shared public validators still authenticate every leaf afterward.
func leaf_shape_error(unit: Dictionary, parent, player: Dictionary) -> String:
	var gate: Dictionary = unit.gate
	if not Value.keys_error(gate, Gate.KEYS).is_empty(): return "Closed sole Gate packet required"
	for key: String in ["capture", "prepared_sequence", "consumed_sequence", "retirement"]:
		if not gate.get(key) is Dictionary: return "Typed sole Gate child required: " + key
	var error: String = parent.capture_gate.snapshot_error(gate, player)
	if not error.is_empty(): return "Sole Gate saved-player shape/provenance: " + error
	var s: Dictionary = unit.scheduler
	if not Value.keys_error(s, ["api_revision", "schema_version", "encounter_id", "profile", "world_revision", "clock_s", "serial", "collision", "reservations", "cooldowns"]).is_empty(): return "Closed complete captured Scheduler1 packet required"
	if s.get("api_revision") != Scheduler.SNAPSHOT_API_REVISION or not s.serial is int or s.serial < 0: return "Original exact Scheduler identity/serial required"
	var p: Dictionary = unit.playback
	if p.is_empty(): return ""
	var keys: Array = Leaf.SNAPSHOT_KEYS.duplicate()
	keys.append("projection")
	if p.has("pending_delivery"): keys.append("pending_delivery")
	if not Value.keys_error(p, keys).is_empty(): return "Closed whole projected Playback3 packet required"
	for key: String in ["sequence", "exchange", "cursor", "cancellation", "projection"]:
		if not p.get(key) is Dictionary: return "Typed complete Playback child required: " + key
	if p.has("pending_delivery") and not p.pending_delivery is Dictionary: return "Typed original pending suffix required"
	if not p.get("opportunities") is Array or not p.get("clock_s") is float or not p.get("source_id") is String or not p.get("hero_id") is String or not p.get("playback_id") is String: return "Exact typed Playback clock/bindings/prefix required"
	var e: Dictionary = p.exchange
	if not Value.keys_error(e, EXCHANGE_KEYS).is_empty() or not e.get("adapter") is Dictionary or not Value.is_vector3(e.get("source_position")) or not Value.is_vector3(e.get("opening_position")): return "Closed typed original exchange/source positions required"
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not e[key] is float or not Value.in_range(e[key], 0.0, 1000000.0): return "Original finite exact exchange deadline required: " + key
	var a: Dictionary = e.adapter
	if not Value.keys_error(a, Scheduler.REPLAY_ADAPTER_KEYS).is_empty() or a.get("kind") != "replay" or not a.get("locked") is bool or not a.get("sequence") is Dictionary or not a.get("generation") is int or not a.get("source_epoch") is String or not a.get("capture_collision_fingerprint") is Dictionary or not a.get("timeline_origin_s") is float or not Value.in_range(a.timeline_origin_s, 0.0, 1000000.0): return "Closed exact captured replay adapter required"
	return ""

func record_error(unit: Dictionary, parent, player: Dictionary) -> String:
	var error: String = header_error(unit, parent, player)
	if not error.is_empty(): return error
	if parent.threat_scheduler.encounter_profile().get("id") != unit.world.profile_id: return "Fresh constructor profile must match original"
	error = parent.capture_gate.snapshot_error(unit.gate, player)
	if not error.is_empty(): return "Sole Gate/outer Player: " + error
	var bindings: Dictionary = parent.scheduler_bindings()
	if not unit.playback.is_empty():
		if not is_instance_valid(parent.playback): return "Entitled actual configured captured owner required"
		bindings["owner_positions"] = {"captured-owner": Value.read_vector3(unit.playback.exchange.source_position)}
	elif is_instance_valid(parent.playback): return "No unearned captured owner may be constructed"
	error = parent.threat_scheduler.snapshot_error(unit.scheduler, bindings)
	if not error.is_empty(): return "Whole Scheduler: " + error
	if not unit.playback.is_empty():
		error = parent.playback.snapshot_error(unit.playback, parent.threat_scheduler, unit.scheduler, bindings, {"hero": parent.hero}, bindings.floors.values(), unit.owned.capture_context)
		if not error.is_empty(): return "Complete projected Playback: " + error
	if unit.owned.phase == "framing":
		error = parent.framing_art_record_error(unit.owned.frame_art, unit.gate, unit.owned.sequence)
		if not error.is_empty(): return error
	return ""

func constructor_recipe(unit: Dictionary, parent, player: Dictionary) -> Dictionary:
	var error: String = header_error(unit, parent, player)
	if not error.is_empty(): return {"accepted": false, "error": error}
	return {"accepted": true, "error": "", "profile_id": unit.world.profile_id, "source_epoch": unit.configuration.source_epoch, "generation": unit.owned.generation, "sequence": unit.owned.sequence.duplicate(true), "playback_id": unit.playback.get("playback_id", ""), "has_owner": not unit.playback.is_empty(), "has_frame_art": unit.owned.phase == "framing", "frame_recipe": unit.owned.frame_art.get("recipe", {}).duplicate(true)}

func restore_local(unit: Dictionary, parent, player: Dictionary) -> bool:
	last_error = record_error(unit, parent, player)
	if last_error.is_empty() and not same(player, parent.hero.snapshot_state()): last_error = "Commit actual outer Player before local unit"
	if not last_error.is_empty(): return false
	if not parent.capture_gate.restore_state(unit.gate, player):
		last_error = parent.capture_gate.last_snapshot_error; return false
	var bindings: Dictionary = parent.scheduler_bindings()
	if not parent.threat_scheduler.restore_state(unit.scheduler, bindings):
		last_error = parent.threat_scheduler.last_snapshot_error; return false
	if not unit.playback.is_empty() and not parent.playback.restore_state(unit.playback, parent.threat_scheduler, unit.scheduler, bindings, {"hero": parent.hero}, bindings.floors.values(), unit.owned.capture_context):
		last_error = parent.playback.last_snapshot_error; return false
	last_error = parent.captured_codec_apply_owned_state(unit.owned)
	if not last_error.is_empty(): return false
	var again: Dictionary = capture(parent, player, false)
	if again.is_empty() or not same(again, unit):
		last_error = "Quiet native whole recapture differs; dispose complete candidate" if last_error.is_empty() else last_error
		return false
	return true

func owned_error(unit: Dictionary, parent, player: Dictionary) -> String:
	var o: Dictionary = unit.owned
	var gate: Dictionary = unit.gate
	if not Value.keys_error(o, OWNED_KEYS).is_empty(): return "Closed complete owned state required"
	for key: String in ["frame_art", "capture_context", "sequence", "projection", "proof", "held_exchange", "join_receipt", "last_rejected_capture", "presentation"]:
		if not o[key] is Dictionary: return "Typed owned packet required: " + key
	for key: String in ["configured", "cleared", "locked"]:
		if not o[key] is bool: return "Boolean owned field required: " + key
	for key: String in ["generation", "joins", "rejections", "tether_hits"]:
		if not o[key] is int or o[key] < 0 or o[key] > 4096: return "Bounded actual owned counter required: " + key
	for key: String in ["phase", "operation", "last_rejection", "last_camera_error"]:
		if not o[key] is String or o[key].length() > 512: return "Bounded owned string required: " + key
	for key: String in ["rearm_after_clock_s", "exposure_from_s", "exposure_until_s"]:
		if not o[key] is float or not Value.in_range(o[key], 0.0, 1000000.0): return "Original finite native deadline required: " + key
	if o.phase != "framing" and not o.frame_art.is_empty(): return "Inert original frame artwork belongs only to genuine unadmitted framing"
	# Explicit production gen0 settling recipe: configured immutable Gate, no
	# samples/sequence/proof/replay. This is not an empty-state fallback.
	if o.phase == "settling":
		if not o.configured or o.generation != 0 or o.joins != 0 or o.rejections != 0 or o.tether_hits != 0 or o.cleared or o.locked or o.operation != "" or not o.last_rejection.is_empty() or not o.last_camera_error.is_empty(): return "Only genuine fresh settling topology may save"
		for key: String in ["capture_context","sequence","projection","proof","held_exchange","join_receipt","last_rejected_capture"]:
			if not o[key].is_empty(): return "Settling cannot retain historical native authority"
		if not o.forecast is Array or not o.forecast.is_empty() or not unit.playback.is_empty() or not unit.scheduler.reservations.is_empty() or not unit.scheduler.cooldowns.is_empty() or not gate.prepared_sequence.is_empty() or not gate.consumed_sequence.is_empty() or not gate.retirement.is_empty() or gate.capture.get("generation") != 0 or gate.capture.get("armed") != false or gate.capture.get("max_slots") != 0: return "Fresh configured gen0/empty finite capture topology required"
		if o.rearm_after_clock_s != 0.0 or o.exposure_from_s != 0.0 or o.exposure_until_s != 0.0 or o.presentation.get("tether_state") != "clear" or o.presentation.get("attack_group") != true: return "Fresh closed floor tether/no exposure required"
		var settling_presentation: Dictionary = {"tether_state":"clear","tether_trigger":"attack","tether_scale_y":1.0,"tether_color":color_wire(false),"attack_group":true,"rejection_visible":false,"marker_mode":"capture","numbers":o.presentation.get("numbers")}
		if not same(o.presentation,settling_presentation): return "Actual pristine settling display required"
		return numbers_error(o,unit.configuration.capacity)
	if o.phase not in ["recording", "rejected", "framing", "warning", "lock", "active", "exposed", "spent"]: return "Pre-arm settling/severed/preparing/transient phases are not stable captured units"
	if not o.configured or o.generation < 1 or o.operation not in ["", "arm", "join", "reject", "finish"] or (not o.last_camera_error.is_empty() and o.phase != "framing"): return "Configured clean observed native boundary required"
	if not gate.get("capture") is Dictionary or not gate.get("prepared_sequence") is Dictionary or not gate.prepared_sequence.is_empty(): return "Preparing Gate must unwind before whole capture"
	var cap: Dictionary = gate.capture
	if not same(cap.get("generation"), o.generation) or not same(cap.get("max_slots"), unit.configuration.capacity) or gate.get("source_epoch") != unit.configuration.source_epoch or gate.get("owner_id") != parent.OWNER_ID or gate.get("actor_id") != parent.ACTOR_ID: return "Exact one/two-slot sole Gate generation/identity required"
	var context: Dictionary = {"source_epoch": unit.configuration.source_epoch, "generation": o.generation, "capture_collision_fingerprint": unit.world.collision_fingerprint, "capture_floor_signature": unit.world.floor_signature}
	if not same(o.capture_context, context): return "Original exact captured projection context required"
	if not o.forecast is Array or o.forecast.size() > 224: return "Bounded original view forecast required"
	for point: Variant in o.forecast:
		if not Value.is_vector3(point) or Value.read_vector3(point).length() > 1024.0: return "Finite original native view point required"
	if not o.last_rejected_capture.is_empty():
		var rejected_reader = Capture.new()
		var rejected: Dictionary = o.last_rejected_capture
		if not rejected.get("clock_s") is float or rejected.clock_s > player.world_actions.clock_s: return "Original rejected recording clock required"
		var rejected_error: String = rejected_reader.snapshot_error(rejected, unit.configuration.source_epoch, rejected.clock_s)
		if not rejected_error.is_empty(): return "Original rejected recording: " + rejected_error
		if o.rejections < 1: return "Rejected recording requires actual rejection history"
	var admitted: bool = LIVE_PHASES.has(o.phase)
	if admitted != (not unit.playback.is_empty()) or o.joins != (1 if admitted else 0) or o.cleared != (o.phase == "spent") or o.tether_hits != (1 if o.cleared else 0): return "Owned phase/one genuine join/tether history must agree"
	if not admitted:
		if not unit.scheduler.reservations.is_empty() or not unit.scheduler.cooldowns.is_empty() or not o.held_exchange.is_empty() or not o.join_receipt.is_empty() or o.locked or o.exposure_from_s != 0.0 or o.exposure_until_s != 0.0: return "Unadmitted state cannot invent a lease, receipt or opening"
		if not gate.get("consumed_sequence") is Dictionary or not gate.get("retirement") is Dictionary or not gate.consumed_sequence.is_empty() or not gate.retirement.is_empty(): return "Post-consumption rejection lacks retained owner custody; discard unit rather than erasing history"
		if o.phase == "rejected":
			if o.rearm_after_clock_s <= player.world_actions.clock_s or cap.get("armed") != false or o.last_rejection.is_empty() or o.rejections < 1 or not o.sequence.is_empty() or not o.projection.is_empty() or not o.proof.is_empty() or not o.forecast.is_empty(): return "Genuine canceled recording/rejection display only"
		else:
			if cap.get("armed") != true: return "Recording/framing requires the genuine armed remaining capture"
		if o.phase == "recording" and (not o.sequence.is_empty() or not o.projection.is_empty() or not o.proof.is_empty() or not o.forecast.is_empty()): return "Recording cannot retain a prepared replay"
	if o.phase == "framing" or admitted:
		var reader = Sequence.new()
		if not reader.restore_state(o.sequence, unit.configuration.source_epoch, o.generation): return reader.last_snapshot_error
		if o.sequence.get("sequence_id") != "crystalman-rule/sequence-" + str(o.generation) or not same(o.sequence.get("authored"), authored(unit.configuration.capacity)): return "Original immutable sequence recipe required"
		if o.phase == "framing" and (not same(o.sequence.capture_snapshot.get("slots"), cap.get("slots")) or not same(o.sequence.capture_snapshot.get("generation"), cap.get("generation"))): return "Historical exact sealed slots/generation must match current Gate; capture clock may advance"
		# Authenticate full original mesh/floor bytes before ANY membership helper.
		var error: String = Footprint.projection_error(o.projection, parent.threat_scheduler, o.sequence, parent.actual_world_root(), parent.floor_regions(), o.capture_context)
		if not error.is_empty(): return "Original projection before view joins: " + error
		error = proof_error(o.proof, unit)
		if not error.is_empty(): return error
		if o.forecast.is_empty(): return "Actual original route/footprint/landing forecast required"
		if o.phase == "framing":
			error = FrameArt.packet_error(o.frame_art, gate, o.sequence)
			if not error.is_empty(): return error
	if admitted:
		var p: Dictionary = unit.playback
		if p.get("status") not in ["running", "complete"] or p.get("schema_version") != 3 or p.get("source_id") != "captured-owner" or p.get("hero_id") != "hero" or p.get("playback_id") != "crystalman-rule/owner-" + str(o.generation) or not same(p.get("sequence"), o.sequence) or not same(p.get("projection"), o.projection): return "Original uncanceled projected source and exact sequence required"
		if not same(gate.get("consumed_sequence"), o.sequence) or not gate.get("retirement") is Dictionary or gate.retirement.is_empty() or cap.get("armed") != false: return "Finite transfer retains original complete FIFO sequence/retirement once"
		if not Value.keys_error(o.held_exchange, EXCHANGE_KEYS).is_empty() or not same(o.held_exchange, p.get("exchange")) or not same(o.held_exchange.source_position, Value.vector3(parent.TETHER_POSITION)) or not same(o.held_exchange.opening_position, Value.vector3(parent.TETHER_POSITION)): return "Exact original stationary low tether exchange required"
		if not same(o.locked, o.held_exchange.adapter.get("locked")) or not same(o.proof.at_lock, o.locked): return "Owned lock retains the same actual exchange/proof generation"
		if not Value.keys_error(o.join_receipt, ["prepared_actor_sha256", "after_admission_actor_sha256", "after_consumption_actor_sha256", "retirement", "actor_unchanged", "actor_clock_s", "bound_before_tick"]).is_empty() or o.join_receipt.actor_unchanged != true or o.join_receipt.bound_before_tick != true or not same(o.join_receipt.retirement, joined_retirement(gate, unit.configuration)) or not same(o.join_receipt.actor_clock_s, gate.retirement.clock_s) or not sha256_valid(o.join_receipt.prepared_actor_sha256) or o.join_receipt.prepared_actor_sha256 != gate.retirement.actor_sha256 or o.join_receipt.prepared_actor_sha256 != o.join_receipt.after_admission_actor_sha256 or o.join_receipt.prepared_actor_sha256 != o.join_receipt.after_consumption_actor_sha256: return "Original no-tick once-only transfer receipt required"
		if not o.locked and (o.exposure_from_s != 0.0 or o.exposure_until_s != 0.0): return "Unarmed warning cannot invent an opening deadline"
		if not same(o.proof.timeline_origin_s, o.held_exchange.adapter.timeline_origin_s) or not same(o.proof.evaluated_at_s, o.held_exchange.lock_from_s if o.locked else o.held_exchange.start_s): return "Historical response proof retains original actual admission/lock clock"
		var expected: String = "warning"
		if o.locked:
			var timeline: Dictionary = o.sequence.timeline
			var origin: float = o.held_exchange.adapter.timeline_origin_s
			var start: float = maxf(origin + timeline.tether_from_s, o.held_exchange.active_until_s) + parent.threat_scheduler.TIME_MARGIN
			var until: float = origin + timeline.tether_until_s
			if not same(o.exposure_from_s, start) or not same(o.exposure_until_s, until): return "Ordinary opening retains original absolute timeline deadlines"
			expected = "lock" if unit.scheduler.clock_s < o.held_exchange.active_from_s else ("active" if unit.scheduler.clock_s < start else "exposed")
			if not o.cleared and unit.scheduler.clock_s >= until: return "Expired unspent opening is not a coherent stable owner"
		if o.phase != ("spent" if o.cleared else expected): return "Owned phase derives from actual same native clock"
		if p.status == "complete" and (not o.cleared or not unit.scheduler.reservations.is_empty() or unit.scheduler.clock_s <= o.held_exchange.recovery_until_s): return "Natural spent completion needs original profile/world and settled empty lease beyond recovery"
	var expected_presentation: Dictionary = {"tether_state": "spent" if o.cleared else ("available" if o.phase == "exposed" else "clear"), "tether_trigger": "attack", "tether_scale_y": float(Vector3(1.0, 0.2 if o.cleared else 1.0, 1.0).y), "tether_color": color_wire(o.cleared or o.phase == "exposed"), "attack_group": not o.cleared, "rejection_visible": o.phase == "rejected", "marker_mode": "sequence" if o.phase == "framing" or admitted else "capture", "numbers": o.presentation.get("numbers")}
	if not same(o.presentation, expected_presentation): return "Derived actual tether/cue/group/number state differs"
	return numbers_error(o, unit.configuration.capacity)

func numbers_error(o: Dictionary, capacity: int) -> String:
	var values: Variant = o.presentation.get("numbers")
	if not values is Array or values.size() != (2 if capacity == 2 else 0): return "Actual original passive number packet required"
	var palette: Array = []
	for color: Color in [Color(0.36, 0.30, 0.44), Color(0.55, 0.50, 0.62), Color(0.67, 0.61, 0.76), Color(0.23, 0.20, 0.27)]: palette.append([float(color.r), float(color.g), float(color.b), float(color.a)])
	for index: int in range(values.size()):
		var number: Variant = values[index]
		if not number is Dictionary or not Value.keys_error(number, ["position", "color"]).is_empty() or not Value.is_vector3(number.position) or not number.color is Array: return "Closed typed current passive number required"
		var expected: Vector3 = Vector3(-0.4 if index == 0 else 0.4, 0.065, 0.60)
		if o.presentation.get("marker_mode") == "sequence":
			expected = Value.read_vector3(o.sequence.timeline.slots[index].route[0].position) + Vector3(0.65, 0.065, 0.15)
		if not same(number.position, Value.vector3(expected)): return "Passive number retains its original actual route/capture position"
		var found: bool = false
		for rgba: Array in palette:
			if same(number.color, rgba): found = true
		if not found: return "Passive number must retain an original harmless native palette state"
	return ""

func proof_error(proof: Dictionary, unit: Dictionary) -> String:
	if not Value.keys_error(proof, PROOF_KEYS).is_empty() or proof.get("accepted") != true or proof.get("api_revision") != "replay-witness-1" or proof.get("proof_scope") != "static_box_floor_bounded_dispatch_replay_union_and_stationary_tether" or proof.get("uses_blast") != false or proof.get("uses_invulnerability") != false or proof.get("reserves_threat") != false or not proof.get("at_lock") is bool: return "Closed original inert whole-response view proof required"
	if not proof.get("collision_fingerprint") is Dictionary or not proof.get("path") is Array or not unit.owned.projection.get("events") is Array: return "Typed original proof/world/path/event packets required"
	if proof.source_epoch != unit.configuration.source_epoch or not same(proof.generation, unit.owned.generation) or proof.sequence_id != unit.owned.sequence.sequence_id or proof.profile_id != unit.world.profile_id or not same(proof.world_revision, 1) or not same(proof.collision_fingerprint, unit.world.collision_fingerprint) or not same(proof.slot_count, unit.configuration.capacity) or not same(proof.event_count, unit.owned.projection.get("events", []).size()) or not same(proof.dispatch_delay_bound_s, 0.05): return "Historical view proof joins exact original plan/world/profile"
	if not proof.path is Array or proof.path.is_empty() or proof.path.size() > 16 or not Value.is_vector3(proof.attack_position): return "Bounded exact historical view path required"
	for key: String in ["primary_time_s", "response_complete_s", "timeline_origin_s", "evaluated_at_s"]:
		if not proof[key] is float or not Value.in_range(proof[key], 0.0, unit.scheduler.clock_s + 30.0): return "Original finite historical proof clock required"
	var previous: Dictionary = {}
	for segment: Variant in proof.path:
		if not segment is Dictionary or not Value.keys_error(segment, ["from", "to", "start_s", "end_s", "kind"]).is_empty() or not Value.is_vector3(segment.from) or not Value.is_vector3(segment.to) or segment.kind not in SEGMENT_KINDS or not segment.start_s is float or not segment.end_s is float or not Value.in_range(segment.start_s, 0.0, 1000000.0) or not Value.in_range(segment.end_s, segment.start_s, 1000000.0): return "Closed exact inert native path segment required"
		if not previous.is_empty() and (not same(previous.to, segment.from) or not same(previous.end_s, segment.start_s)): return "Historical view path must remain contiguous"
		for key: String in ["from", "to"]:
			if not Footprint.floor_contains(unit.owned.projection, Value.read_vector3(segment[key])): return "Original response-view path must remain on real supported floor"
		previous = segment
	if not Footprint.floor_contains(unit.owned.projection, Value.read_vector3(proof.attack_position)): return "Original low-tether attack position requires native supported floor"
	if proof.evaluated_at_s > unit.scheduler.clock_s or not same(proof.path[0].start_s, proof.evaluated_at_s) or not same(previous.end_s, proof.response_complete_s) or not same(previous.to, proof.attack_position): return "Historical view proof clock/path joins must remain exact"
	return ""

static func sha256_valid(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for character: String in value:
		if not "0123456789abcdef".contains(character): return false
	return true

static func color_wire(opened: bool) -> Array:
	# Color uses float32 components; archive the actual same native bits.
	var color := Color(0.79, 0.89, 0.56) if opened else Color(0.33, 0.30, 0.39)
	return [float(color.r), float(color.g), float(color.b), float(color.a)]

static func joined_retirement(gate: Dictionary, config: Dictionary) -> Dictionary:
	var receipt: Dictionary = gate.retirement.duplicate(true)
	receipt.merge({"owner_id": config.gate_owner, "actor_id": config.actor_id, "source_epoch": config.source_epoch})
	return receipt

static func authored(capacity: int) -> Dictionary:
	return {"recognition_s": 0.25, "warning_s": 1.3, "locked_lead_s": 1.5, "inter_echo_gap_s": 1.0 if capacity == 2 else 0.0, "final_recovery_s": 3.5, "tether_position": Value.vector3(Vector3(-0.7, 0.0, -0.4))}

static func encode_proof(proof: Dictionary) -> Dictionary:
	if proof.is_empty(): return {}
	var result: Dictionary = proof.duplicate(true)
	result.attack_position = Value.vector3(proof.attack_position)
	for segment: Dictionary in result.path:
		segment["from"] = Value.vector3(segment.from)
		segment["to"] = Value.vector3(segment.to)
	return result

static func decode_proof(proof: Dictionary) -> Dictionary:
	if proof.is_empty(): return {}
	var result: Dictionary = proof.duplicate(true)
	result.attack_position = Value.read_vector3(proof.attack_position)
	for segment: Dictionary in result.path:
		segment["from"] = Value.read_vector3(segment.from)
		segment["to"] = Value.read_vector3(segment.to)
	return result

static func encode_exchange(lease: Dictionary) -> Dictionary:
	if lease.is_empty(): return {}
	var result: Dictionary = {}
	for key: String in EXCHANGE_KEYS: result[key] = lease[key]
	result.source_position = Value.vector3(lease.source_position)
	result.opening_position = Value.vector3(lease.opening_position)
	return result.duplicate(true)

static func decode_exchange(exchange: Dictionary, owner: Node3D, actor: CinderPlayer) -> Dictionary:
	if exchange.is_empty(): return {}
	var result: Dictionary = exchange.duplicate(true)
	result.source_position = Value.read_vector3(exchange.source_position)
	result.opening_position = Value.read_vector3(exchange.opening_position)
	result["source_instance_id"] = owner.get_instance_id()
	result["response_actor_instance_id"] = actor.get_instance_id()
	result["armed"] = result.adapter.locked
	result["state"] = "lock" if result.adapter.locked else "warning" # Historical diagnostics only.
	return result

static func native_world(parent) -> Dictionary:
	var floor: Dictionary = Footprint.floor_signature(parent.actual_world_root(), parent.floor_regions())
	return {"profile_id": parent.threat_scheduler.encounter_profile().get("id", ""), "encounter_id": parent.ENCOUNTER_ID, "world_revision": 1, "collision_fingerprint": parent.threat_scheduler.pure_collision_fingerprint(parent.actual_world_root()), "floor_signature": floor.get("signature", [])}

func live_presentation_error(parent) -> String:
	if not is_instance_valid(parent.shared_shell): return "Actual shared native view required"
	return candidate_presentation_error(parent, parent.shared_shell.get("camera") as Camera3D, parent.shared_shell.get("hud") as GameHUD)

func candidate_presentation_error(parent, camera: Camera3D, hud: GameHUD) -> String:
	if not is_instance_valid(parent.shared_shell) or not is_instance_valid(camera) or not is_instance_valid(hud): return "Actual candidate Camera/HUD/Shell required"
	var marker: MeshInstance3D = parent.get_node_or_null("LowFixedExternalTether/SharedOrdinaryAttackCue/RequiredInteractionMarker") as MeshInstance3D
	if marker == null: return "Actual current ordinary marker recipient required"
	if marker.visible and (camera.cull_mask & marker.layers) == 0: return "Actual current candidate camera excludes the visible required marker layer"
	for part: MeshInstance3D in parent._tether_branches:
		if part.visible and (camera.cull_mask & part.layers) == 0: return "Actual candidate camera excludes visible source mineral arms"
	var points: Array = parent.captured_codec_framing_union(camera)
	if points.is_empty(): return "Actual full local Hero/source/footprint/escape/tether union required"
	return parent.shared_shell.call("camera_framing_error_for_context", points, parent.hero, camera, hud)

func verify_candidate(unit: Dictionary, parent, player: Dictionary, camera: Camera3D, hud: GameHUD) -> String:
	var again: Dictionary = capture(parent, player, false)
	if again.is_empty(): return last_error
	if not same(again, unit): return "Current native candidate whole local unit differs from saved unit"
	return candidate_presentation_error(parent, camera, hud)

static func progress_error(progress: Dictionary) -> String:
	var empty: Dictionary = {"completed": false, "completion_id": "", "contact_exit_id": "", "checkpoint_id": "", "checkpoint_kind": "", "checkpoint_ids": {}}
	return "" if same(progress, empty) else "Local rule prototype cannot claim campaign completion, exit or checkpoints"

static func same(left: Variant, right: Variant) -> bool:
	var wire: String = Exact.stringify(left)
	return not wire.is_empty() and wire == Exact.stringify(right)
