extends RefCounted
## B05's physical bait history, separate from Game's final screen release.
## This cache consumes actual published native Player records; it creates no
## movement, timing, ray, damage, scheduler lease or screen-space aim anchor.
## The owning aggregate validates the whole native Player/encounter separately.
const PlayerScript: Script = preload("res://scripts/player.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson: Script = preload("res://scripts/campaign/exact_json.gd")
const KEYS: Array[String] = ["version", "boundary", "initial_floor", "initial_sequence", "last_sequence", "landing", "last_dash"]
const BOUNDARIES: Array[String] = ["sentry-entry", "sentry-phase-2"]
var last_error: String = ""
var _hero: CinderPlayer
var _bound: bool = false
var _retired: bool = false
var _boundary: String = ""
var _initial_floor: Vector3 = Vector3.ZERO
var _initial_sequence: int = 0
var _last_sequence: int = 0
var _landing: Vector3 = Vector3.ZERO
var _last_dash: Dictionary = {}

func bind(shared_hero: CinderPlayer) -> bool:
	if _bound or _retired or not is_instance_valid(shared_hero) or not shared_hero.is_inside_tree() or not shared_hero.is_node_ready() or shared_hero.is_queued_for_deletion() or shared_hero.dead:
		return _reject("B05 bait binds once to the actual ready living Player")
	_hero = shared_hero
	_bound = true
	last_error = ""
	return true

func is_bound_to(shared_hero: CinderPlayer) -> bool:
	# Pure native identity/custody view for the owning ray consumer. It does
	# not seed bait, sample a cycle, write diagnostics or grant damage.
	return _live() and _hero == shared_hero

func begin_boundary(boundary: String) -> bool:
	if not _live() or _hero.dead or boundary not in BOUNDARIES:
		return _reject("B05 bait needs a supported actual boss boundary")
	if (boundary == "sentry-entry" and not _boundary.is_empty()) or (boundary == "sentry-phase-2" and _boundary != "sentry-entry"):
		return _reject("B05 bait boundaries advance once in authored order")
	var response: Dictionary = _hero.get_threat_response_state()
	if not response.get("stable", false) or not response.motion.get("grounded", false) or not _hero.global_position.is_finite():
		return _reject("Initialize bait at the actual supported stable starting floor")
	var records: Array[Dictionary] = _hero.get_world_action_records()
	_initial_sequence = 0 if records.is_empty() else int(records[-1].sequence)
	_last_sequence = _initial_sequence
	_initial_floor = _floor_point(_hero.global_position)
	_landing = _initial_floor
	_last_dash.clear()
	_boundary = boundary
	last_error = ""
	return true

func observe_record(record: Dictionary) -> bool:
	# A prior observer may publish an immediate native primary recursively
	# before this cache receives the outer dash notification. Player's retained
	# history is publication ordered even when callback delivery is nested.
	# Validate the notified native identity first, then preflight the whole
	# contiguous batch and commit it once without emitting callbacks.
	if not _live() or _boundary.is_empty() or not Codec.is_integer(record.get("sequence"), 1):
		return _reject("B05 bait consumes a genuine bound native publication")
	var records: Array[Dictionary] = _hero.get_world_action_records()
	var original: Dictionary = {}
	for retained: Dictionary in records:
		if int(retained.sequence) == int(record.sequence):
			original = retained
			break
	if original.is_empty() or original.size() != record.size() or original != record:
		return _reject("B05 bait requires the unchanged actual retained native receipt")
	var clock: float = _hero.get_world_action_clock()
	if PlayerScript.encode_world_action_record(original, clock).is_empty():
		return _reject("B05 bait requires a valid completed world-action receipt")
	if int(original.sequence) <= _last_sequence:
		# Successful idempotent acknowledgement: the nested batch already
		# consumed this exact native publication. No point/cursor is changed.
		last_error = ""
		return true
	var next_sequence: int = _last_sequence
	var next_landing: Vector3 = _landing
	var next_dash: Dictionary = _last_dash
	for retained: Dictionary in records:
		if int(retained.sequence) <= _last_sequence:
			continue
		if int(retained.sequence) != next_sequence + 1:
			return _reject("B05 bait cannot invent omitted native publication history")
		var encoded: Dictionary = PlayerScript.encode_world_action_record(retained, clock)
		if encoded.is_empty():
			return _reject("B05 bait batch requires canonical completed native receipts")
		next_sequence = int(retained.sequence)
		if retained.kind == "dash":
			next_landing = _floor_point(retained.landing)
			next_dash = encoded
	_last_sequence = next_sequence
	_landing = next_landing
	_last_dash = next_dash.duplicate(true)
	last_error = ""
	return true

func sample_for_ray() -> Dictionary:
	if not _live() or _boundary.is_empty():
		return {}
	# A new dictionary/value copy is diagnostic immutable cycle data. Actual
	# ray admission/lock, full cue and save custody belong to the B05 adapter.
	return {"boundary": _boundary, "point": _landing, "last_sequence": _last_sequence, "dash_sequence": 0 if _last_dash.is_empty() else int(_last_dash.sequence)}

func state() -> Dictionary:
	if not _live():
		return {}
	return {"version": 1, "boundary": _boundary, "initial_floor": null if _boundary.is_empty() else Codec.vector3(_initial_floor), "initial_sequence": _initial_sequence, "last_sequence": _last_sequence, "landing": null if _boundary.is_empty() else Codec.vector3(_landing), "last_dash": null if _last_dash.is_empty() else _last_dash.duplicate(true)}

func snapshot_error(saved: Dictionary, saved_player: Dictionary) -> String:
	# This cross-check receives the complete staged Player after the owning
	# aggregate's native Player validation. It does not replace that validation
	# or authorize restore through a mere cursor/hash/private performance cache.
	if not _live():
		return "B05 bait restoration needs its actual configured recipient"
	var error: String = Codec.value_error(saved)
	if error.is_empty(): error = Codec.keys_error(saved, KEYS)
	if not error.is_empty(): return error
	if not Codec.is_integer(saved.version, 1, 1) or not saved.boundary is String or (not saved.boundary.is_empty() and saved.boundary not in BOUNDARIES):
		return "Unsupported B05 bait version/boundary"
	if not Codec.is_integer(saved.initial_sequence) or not Codec.is_integer(saved.last_sequence) or int(saved.initial_sequence) > int(saved.last_sequence):
		return "Invalid B05 bait action cursor"
	if saved.boundary.is_empty():
		return "" if saved.initial_floor == null and saved.landing == null and saved.last_dash == null and int(saved.initial_sequence) == 0 and int(saved.last_sequence) == 0 else "Unentered B05 bait must have no invented history or point"
	if not Codec.is_vector3(saved.initial_floor) or not Codec.is_vector3(saved.landing) or Codec.read_vector3(saved.initial_floor).y != 0.0 or Codec.read_vector3(saved.landing).y != 0.0:
		return "B05 bait points retain exact completed X/Z on the floor plane"
	if not saved_player.get("world_actions") is Dictionary or not saved_player.world_actions.get("history") is Array:
		return "B05 bait needs the complete staged Player history"
	var capture: Dictionary = saved_player.world_actions
	if not Codec.is_integer(capture.get("sequence")) or not Codec.in_range(capture.get("clock_s"), 0.0, 1000000000000.0) or int(saved.last_sequence) != int(capture.sequence):
		return "B05 bait cursor must equal the complete staged Player publication"
	var latest: Dictionary = {}
	var first_sequence: int = int(capture.sequence) + 1
	for receipt: Variant in capture.history:
		if not receipt is Dictionary or not Codec.is_integer(receipt.get("sequence"), 1): return "Invalid staged Player receipt for B05 bait"
		first_sequence = mini(first_sequence, int(receipt.sequence))
		if int(receipt.sequence) > int(saved.initial_sequence) and receipt.get("kind") == "dash": latest = receipt
	if saved.last_dash == null:
		if not latest.is_empty() or not _same_exact(saved.landing, saved.initial_floor):
			return "B05 initial bait cannot replace a completed dash or leave its actual boundary point"
		return ""
	if not saved.last_dash is Dictionary:
		return "B05 last dash must be a closed canonical receipt"
	var dash: Dictionary = saved.last_dash
	error = PlayerScript.world_action_record_error(dash, float(capture.clock_s))
	if not error.is_empty(): return error
	if dash.kind != "dash" or int(dash.sequence) <= int(saved.initial_sequence) or int(dash.sequence) > int(saved.last_sequence):
		return "B05 bait needs a completed dash in this boundary epoch"
	var expected: Vector3 = _floor_point(Codec.read_vector3(dash.landing))
	if not _same_exact(saved.landing, Codec.vector3(expected)):
		return "B05 bait must match the completed receipt's exact physical landing"
	if not latest.is_empty():
		if not _same_exact(dash, latest): return "B05 bait differs from the latest retained native completed dash"
	elif int(dash.sequence) >= first_sequence:
		return "B05 bait receipt was omitted inside the retained Player history"
	# A dash older than the Player's finite history is preserved as one exact
	# independently valid receipt. Its point is never guessed from current pose.
	return ""

func restore_state(saved: Dictionary, saved_player: Dictionary) -> bool:
	last_error = snapshot_error(saved, saved_player)
	if not last_error.is_empty(): return false
	# Pure preflight is prospective; commit must follow actual quiet native
	# Player restoration and cannot bind a staged tuple to the wrong Hero.
	var actual_player: Dictionary = _hero.snapshot_state()
	if actual_player.is_empty() or not _same_exact(actual_player, saved_player):
		return _reject("B05 bait commit requires the actual restored native Player tuple")
	var accepted: Dictionary = saved.duplicate(true)
	_boundary = accepted.boundary
	_initial_sequence = int(accepted.initial_sequence)
	_last_sequence = int(accepted.last_sequence)
	_initial_floor = Vector3.ZERO if accepted.initial_floor == null else Codec.read_vector3(accepted.initial_floor)
	_landing = Vector3.ZERO if accepted.landing == null else Codec.read_vector3(accepted.landing)
	_last_dash = {} if accepted.last_dash == null else (accepted.last_dash as Dictionary).duplicate(true)
	return true

func release() -> void:
	_hero = null
	_bound = false
	_retired = true

func _live() -> bool:
	return _bound and not _retired and is_instance_valid(_hero) and _hero.is_inside_tree() and _hero.is_node_ready() and not _hero.is_queued_for_deletion()

static func _floor_point(point: Vector3) -> Vector3:
	return Vector3(point.x, 0.0, point.z)

static func _same_exact(left: Variant, right: Variant) -> bool:
	var encoded: String = ExactJson.stringify(left)
	return not encoded.is_empty() and encoded == ExactJson.stringify(right)

func _reject(reason: String) -> bool:
	last_error = reason
	return false
