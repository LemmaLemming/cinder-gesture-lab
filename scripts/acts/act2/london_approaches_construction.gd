extends RefCounted
## INERT SOURCE DRAFT. Pure finite construction selection for A2-L4.
## No Nodes, configure/bind/restore calls, preferences, native state or events.
## Original known/native validators still run after this constructor selection.
## The returned positions are derived native Vector3 values, never save fields.

const Sequence: Script = preload("res://scripts/acts/act2/london_approaches_sequence.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact: Script = preload("res://scripts/campaign/exact_json.gd")
const Difficulty: Script = preload("res://scripts/combat/difficulty.gd")
const API_REVISION: String = "act2-london-putney-construction-1"
const SCHEMA_VERSION: int = 1
const LEVEL_EPOCH: String = "A2-L4-london-approaches"
const CANONICAL_RECIPE: String = "canonical-putney-slots-1"
const EXCHANGED_RECIPE: String = "challenge-putney-slots-exchanged-1"
const PROFILE_IDS: Array[String] = ["assisted", "standard", "challenge"]
const DESCRIPTOR_KEYS: Array[String] = ["api_revision", "schema_version", "profile", "recipe_id"]
const PROFILE_KEYS: Array[String] = ["id", "name", "raw_damage_multiplier", "windup_multiplier", "recovery_multiplier", "reserved_threat_budget", "commit_stagger_s", "arrangement"]
const KNOWN_KEYS: Array[String] = ["sequence", "scheduler", "rays", "targets", "mechanisms", "views", "profile_id", "world_revision", "scenic_clock", "last_action_sequence", "contact_seen", "pending_checkpoints", "completion_pending", "exit_requested"]
const LOCAL_KEYS: Array[String] = ["sequence", "scheduler", "rays", "targets", "mechanisms", "views", "profile_id", "world_revision", "scenic_clock", "last_action_sequence", "contact_seen", "pending_checkpoints", "completion_pending", "exit_requested", "banks", "bank_views"]
const SELECTION_KEYS: Array[String] = ["error", "legacy", "descriptor", "profile_id", "profile", "positions"]


static func fresh(profile_id: String) -> Dictionary:
	var profile: Dictionary = _canonical_profile(profile_id)
	if profile.is_empty(): return _failure("L4 construction requires an available canonical profile")
	var recipe: String = EXCHANGED_RECIPE if profile_id == "challenge" else CANONICAL_RECIPE
	var descriptor: Dictionary = {
		"api_revision": API_REVISION,
		"schema_version": SCHEMA_VERSION,
		"profile": profile.duplicate(true),
		"recipe_id": recipe,
	}
	return _selection(false, descriptor, profile_id, profile, recipe)


static func saved(local: Variant) -> Dictionary:
	if not local is Dictionary: return _failure("L4 construction requires a local dictionary")
	var error: String = Codec.value_error(local)
	var keys: Array[String] = LOCAL_KEYS.duplicate()
	var has_descriptor: bool = local.has("arrangement")
	if has_descriptor: keys.append("arrangement")
	if error.is_empty(): error = Codec.keys_error(local, keys)
	if not error.is_empty(): return _failure("L4 construction local envelope: " + error)
	# Only absence selects the literal old16 format. Explicit null/{} is new and
	# invalid; it must not reach select_known's internal legacy null sentinel.
	if has_descriptor and not local.arrangement is Dictionary:
		return _failure("L4 arrangement must be the complete new descriptor")
	var known: Dictionary = local.duplicate()
	known.erase("banks")
	known.erase("bank_views")
	known.erase("arrangement")
	return select_known(known, local.arrangement if has_descriptor else null)


static func select_known(known: Variant, arrangement: Variant = null) -> Dictionary:
	if not known is Dictionary: return _failure("L4 construction requires a known dictionary")
	var error: String = Codec.value_error(known)
	if error.is_empty(): error = Codec.keys_error(known, KNOWN_KEYS)
	if not error.is_empty(): return _failure("L4 construction known envelope: " + error)
	if not known.profile_id is String or known.profile_id not in PROFILE_IDS:
		return _failure("L4 construction profile ID is unsupported")
	var profile_id: String = known.profile_id
	var profile: Dictionary = _canonical_profile(profile_id)
	if profile.is_empty(): return _failure("L4 construction canonical profile is unavailable")
	if arrangement == null:
		# No new exact typed comparison is imposed on old Scheduler/native packets.
		# Existing KnownRules/SmokeRules/native validation owns their old accepted
		# numeric set, complete sequence and paired native coherence unchanged.
		return _selection(true, {}, profile_id, profile, CANONICAL_RECIPE)
	error = _descriptor_error(arrangement, profile_id, profile)
	if not error.is_empty(): return _failure(error)
	error = _new_scheduler_join_error(known, arrangement.profile)
	if not error.is_empty(): return _failure(error)
	return _selection(false, arrangement, profile_id, profile, arrangement.recipe_id)


static func binding(local: Variant, constructed: Dictionary) -> String:
	# Pure retained-constructor comparison, not a native binding authorization.
	# The host still validates the actual actors, tools, Rays and paired Player.
	var expected: Dictionary = saved(local)
	if not expected.error.is_empty(): return expected.error
	var error: String = Codec.keys_error(constructed, SELECTION_KEYS)
	if not error.is_empty(): return "L4 retained construction envelope: " + error
	if not constructed.error is String or not constructed.error.is_empty() or not constructed.legacy is bool or not constructed.profile_id is String or not constructed.descriptor is Dictionary or not constructed.profile is Dictionary or not constructed.positions is Dictionary:
		return "L4 retained construction has invalid field types or a prior error"
	if constructed.legacy != expected.legacy or constructed.profile_id != expected.profile_id or not _same_exact(constructed.descriptor, expected.descriptor) or not _same_exact(constructed.profile, expected.profile):
		return "L4 saved construction differs from the once-selected format/profile/recipe"
	if not Codec.keys_error(constructed.positions, Sequence.ACTORS.keys()).is_empty():
		return "L4 retained construction must contain exactly the nine authored actors"
	for id: String in Sequence.ACTORS:
		var actual: Variant = constructed.positions[id]
		var selected: Vector3 = expected.positions[id]
		if not actual is Vector3 or not actual.is_finite():
			return "L4 retained construction requires finite native positions: " + id
		if actual.x != selected.x or actual.y != selected.y or actual.z != selected.z:
			return "L4 retained construction root differs from the closed recipe: " + id
	return ""


static func _descriptor_error(value: Variant, profile_id: String, canonical: Dictionary) -> String:
	if not value is Dictionary: return "L4 arrangement must be a dictionary"
	var error: String = Codec.value_error(value)
	if error.is_empty(): error = Codec.keys_error(value, DESCRIPTOR_KEYS)
	if not error.is_empty(): return "L4 arrangement envelope: " + error
	if not value.api_revision is String or value.api_revision != API_REVISION or typeof(value.schema_version) != TYPE_INT or value.schema_version != SCHEMA_VERSION:
		return "L4 arrangement requires its exact API and integer schema 1"
	if not value.profile is Dictionary or not Codec.keys_error(value.profile, PROFILE_KEYS).is_empty() or not _same_exact(value.profile, canonical):
		return "L4 arrangement requires the exact full canonical profile and scalar types"
	if value.profile.id != profile_id or not value.recipe_id is String:
		return "L4 arrangement profile/recipe identity differs"
	if value.recipe_id not in [CANONICAL_RECIPE, EXCHANGED_RECIPE]:
		return "L4 arrangement recipe is unsupported"
	if value.recipe_id == EXCHANGED_RECIPE and profile_id != "challenge":
		return "L4 exchanged Putney slots require the retained Challenge profile"
	# Canonical Challenge is intentionally valid on read; do not rerun fresh().
	return ""


static func _new_scheduler_join_error(known: Dictionary, profile: Dictionary) -> String:
	if not known.scheduler is Dictionary or not known.scheduler.get("profile") is Dictionary or not known.scheduler.get("encounter_id") is String:
		return "L4 arrangement requires the actual saved Scheduler profile/epoch"
	var scheduler: Dictionary = known.scheduler
	if not scheduler.profile.is_empty():
		if scheduler.encounter_id != LEVEL_EPOCH or not _same_exact(scheduler.profile, profile):
			return "L4 new construction and live Scheduler must retain the exact same full profile"
		return ""
	# The descriptor survives a genuinely retired Scheduler. Do not infer a
	# profile from empty Scheduler data or recreate an encounter to stamp it.
	if not scheduler.encounter_id.is_empty() or not known.sequence is Dictionary or not known.completion_pending is bool or known.completion_pending or not scheduler.get("reservations") is Array or not scheduler.reservations.is_empty():
		return "L4 empty Scheduler profile requires committed quiet clear"
	var error: String = Sequence.new().snapshot_error(known.sequence)
	if not error.is_empty(): return error
	if Sequence.STAGES[int(known.sequence.stage_index)] != "clear":
		return "L4 retained construction outlives the Scheduler only at clear"
	return ""


static func _canonical_profile(profile_id: String) -> Dictionary:
	if profile_id not in PROFILE_IDS: return {}
	var difficulty = Difficulty.new()
	var profile: Dictionary = difficulty.profile(profile_id)
	if not Codec.value_error(profile).is_empty() or not Codec.keys_error(profile, PROFILE_KEYS).is_empty() or profile.get("id") != profile_id or Exact.stringify(profile).is_empty():
		return {}
	# Preserve JSON.parse's actual numeric types. Rebuilding the eight fields
	# or coercing the budget/multipliers would change the strict new contract.
	return profile


static func _selection(legacy: bool, descriptor: Dictionary, profile_id: String, profile: Dictionary, recipe: String) -> Dictionary:
	var positions: Dictionary = Sequence.ACTORS.duplicate(true)
	if recipe == EXCHANGED_RECIPE:
		var scout: Vector3 = Sequence.ACTORS.putney_scout
		var handler: Vector3 = Sequence.ACTORS.putney_handler
		positions["putney_scout"] = Vector3(handler.x, scout.y, handler.z)
		positions["putney_handler"] = Vector3(scout.x, handler.y, scout.z)
	return {"error": "", "legacy": legacy, "descriptor": descriptor.duplicate(true), "profile_id": profile_id, "profile": profile.duplicate(true), "positions": positions}


static func _same_exact(left: Variant, right: Variant) -> bool:
	var wire: String = Exact.stringify(left)
	return not wire.is_empty() and wire == Exact.stringify(right)


static func _failure(error: String) -> Dictionary:
	return {"error": error, "legacy": false, "descriptor": {}, "profile_id": "", "profile": {}, "positions": {}}
