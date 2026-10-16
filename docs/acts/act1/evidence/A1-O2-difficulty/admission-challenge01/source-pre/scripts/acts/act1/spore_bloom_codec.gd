extends RefCounted
## Pure O2 metadata only. Native Player/source/Field/Scheduler/consumer/Route
## packets remain opaque, complete and untouched. The actual host separately
## validates every native packet, immutable binding, response and presentation.
## A construction plan describes saved membership; it grants no native actor
## entitlement and never supplies a descriptor, configuration hash or history.

const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Layout = preload("res://scripts/acts/act1/spore_bloom_layout.gd")
const API_REVISION: String = "act1-spore-bloom-2"
const SCHEMA_VERSION: int = 2
const LEGACY_API_REVISION: String = "act1-spore-bloom-1"
const LEGACY_SCHEMA_VERSION: int = 1
const WORLD_REVISION: int = 1
const LOCAL_KEYS: Array[String] = ["api_revision", "schema_version", "world_revision", "beat_index", "room_stage", "completed_beats", "activated_source_ids", "installed_consumers", "checkpoint_published", "sources", "fields", "consumers", "scheduler", "framing"]
const Arrangement = preload("res://scripts/combat/encounter_arrangement.gd")
const FINAL_ARRANGEMENTS_PATH: String = "res://data/campaign/act1/a1_o2_difficulty_arrangements.json"
static var _final_definition: Variant = JSON.parse_string(FileAccess.get_file_as_string(FINAL_ARRANGEMENTS_PATH))
static var _final_recipes: CinderEncounterArrangement = Arrangement.new(_final_definition)
const PROGRESS_KEYS: Array[String] = ["completed", "completion_id", "contact_exit_id", "checkpoint_id", "checkpoint_kind", "checkpoint_ids"]


static func metadata_error(local: Dictionary) -> String:
	if Exact.stringify(local).is_empty(): return "O2 requires complete exact finite typed transport"
	var current: bool = local.get("schema_version") is int and local.schema_version == SCHEMA_VERSION
	var keys: Array = LOCAL_KEYS.duplicate()
	if current: keys.append("final_arrangement")
	var error: String = Codec.keys_error(local, keys)
	if not error.is_empty(): return error
	if not local.api_revision is String or not local.schema_version is int or local.schema_version not in [LEGACY_SCHEMA_VERSION, SCHEMA_VERSION] or local.api_revision != (API_REVISION if current else LEGACY_API_REVISION) or not local.world_revision is int or local.world_revision != WORLD_REVISION:
		return "Unsupported exact O2 local metadata revision"
	if current and not local.final_arrangement is Dictionary:
		return "Closed O2 final arrangement dictionary required"
	if not local.beat_index is int or local.beat_index < 0 or local.beat_index > 3 or not local.room_stage is String:
		return "Exact O2 exercise index and authored stage required"
	if local.room_stage not in (["approach", "active"] if local.beat_index < 3 else ["hatch", "departed"]):
		return "O2 approach/active belongs to a real exercise; hatch/departed follows all three"
	if not local.completed_beats is Array or not local.activated_source_ids is Array or not local.installed_consumers is Array or not local.checkpoint_published is bool:
		return "Typed O2 completed/activation/installation prefixes and checkpoint flag required"
	if not _same(local.completed_beats, Layout.BEAT_IDS.slice(0, local.beat_index)):
		return "Completed exercises retain their exact ordered genuine prefix"
	if local.checkpoint_published != (local.beat_index >= 2):
		return "The sole pre-final checkpoint is published from final approach onward"
	for key: String in ["sources", "fields", "consumers", "scheduler", "framing"]:
		if not local[key] is Dictionary: return "Complete typed O2 dictionary required: " + key
	if not Codec.keys_error(local.sources, Layout.SOURCE_IDS).is_empty():
		return "Exactly all nine retained native O2 source packets required"
	for id: String in Layout.SOURCE_IDS:
		if not local.sources[id] is Dictionary or local.sources[id].is_empty():
			return "Complete opaque native source packet required: " + id
	if local.scheduler.is_empty(): return "Complete opaque native Scheduler packet required"
	var topology: Dictionary = _topology(local.beat_index, local.room_stage)
	if not _same(local.activated_source_ids, topology.activated_source_ids):
		return "Activated sources must retain exactly the genuine installed group prefix"
	if not _same(local.installed_consumers, topology.installed_consumers):
		return "Installed consumers retain their exact permanent ordered ID prefix"
	error = _installation_error(local.fields, Layout.FIELD_IDS, topology.installed_fields, "field")
	if not error.is_empty(): return error
	error = _installation_error(local.consumers, Layout.CONSUMER_IDS, topology.installed_consumers, "consumer")
	return _final_arrangement_metadata_error(local) if error.is_empty() else error


## The retained recipes describe admission priority only, never membership or
## native eligibility. Cache immutable source data rather than reading per tick.
static func arrangement_configuration_error() -> String:
	var error: String = Arrangement.definition_error(_final_definition)
	if not error.is_empty(): return error
	return "" if _final_definition.unit_ids == Layout.group_ids(2) else "Final recipe inventory must retain canonical four-source membership"


static func fresh_final_arrangement(profile: String) -> Dictionary:
	return {} if not arrangement_configuration_error().is_empty() else _final_recipes.select_fresh(profile)


static func final_arrangement_error(selected: Dictionary) -> String:
	var error: String = arrangement_configuration_error()
	return _final_recipes.saved_error(selected) if error.is_empty() else error


static func _final_arrangement_metadata_error(local: Dictionary) -> String:
	# Literal API1 remains API1 for the complete restored attempt, including a
	# Challenge checkpoint that has not entered the final group yet.
	if local.schema_version == LEGACY_SCHEMA_VERSION: return ""
	var selected: Dictionary = local.final_arrangement
	var started: bool = local.beat_index > 2 or local.beat_index == 2 and local.room_stage == "active"
	if not started:
		return "" if selected.is_empty() else "Final recipe cannot precede the genuine fresh final boundary"
	var error: String = final_arrangement_error(selected)
	if not error.is_empty(): return error
	if local.room_stage == "active":
		if not local.scheduler.get("profile") is Dictionary or local.scheduler.profile.get("id") != selected.profile:
			return "Final recipe differs from the actual saved native Scheduler profile"
	for id: String in Layout.group_ids(2):
		var actor: Dictionary = local.sources[id]
		if actor.get("profile_id", "") != "" and actor.profile_id != selected.profile:
			return "Retained final source differs from its saved recipe profile"
	return ""


## Saved membership alone. The host must prove actual fresh paused candidate,
## nearest owner, pristine dormant recipients, unbegun Scheduler, immutable
## configurations and one-shot entitlements through the existing actor API.
static func construction_plan(local: Dictionary) -> Dictionary:
	var error: String = metadata_error(local)
	if not error.is_empty(): return {"accepted": false, "error": error}
	var topology: Dictionary = _topology(local.beat_index, local.room_stage)
	return {
		"accepted": true,
		"error": "",
		"installed_groups": topology.installed_groups.duplicate(),
		"installed_fields": topology.installed_fields.duplicate(),
		"installed_consumers": topology.installed_consumers.duplicate(),
		"activated_source_ids": topology.activated_source_ids.duplicate(),
		"bound_source_ids": topology.activated_source_ids.duplicate(),
	}


## Call after CinderLevel and complete native aggregate prevalidation. The host
## rejects its synchronous publication window, so no half-published departure
## with an empty contact ID is a supported saved state.
static func progress_error(snapshot: Dictionary) -> String:
	if not snapshot.get("local") is Dictionary or not snapshot.get("progress") is Dictionary:
		return "Whole O2 local and CinderLevel progress dictionaries required"
	var local: Dictionary = snapshot.local
	var error: String = metadata_error(local)
	if not error.is_empty(): return error
	var progress: Dictionary = snapshot.progress
	if Exact.stringify(progress).is_empty() or not Codec.keys_error(progress, PROGRESS_KEYS).is_empty() or not progress.completed is bool or not progress.completion_id is String or not progress.contact_exit_id is String or not progress.checkpoint_id is String or not progress.checkpoint_kind is String or not progress.checkpoint_ids is Dictionary:
		return "Exact closed typed CinderLevel progress required"
	var history: Dictionary = {Layout.CHECKPOINT_ID: "encounter"} if local.checkpoint_published else {}
	if not _same(progress.checkpoint_ids, history) or progress.checkpoint_id != (Layout.CHECKPOINT_ID if local.checkpoint_published else "") or progress.checkpoint_kind != ("encounter" if local.checkpoint_published else ""):
		return "O2 retains only its actual pre-final checkpoint and original kind"
	var departed: bool = local.room_stage == "departed"
	if progress.completed != departed or progress.completion_id != (Layout.COMPLETION_ID if departed else "") or progress.contact_exit_id != (Layout.EXIT_ID if departed else ""):
		return "Only sealed actual O2 departure retains both genuine completion and contact exit"
	return ""


static func _installation_error(packets: Dictionary, all_ids: Array, installed_ids: Array, label: String) -> String:
	if not Codec.keys_error(packets, all_ids).is_empty(): return "Complete stable O2 " + label + " map required"
	for id: String in all_ids:
		var value: Variant = packets[id]
		if installed_ids.has(id):
			if not value is Dictionary or value.is_empty(): return "Installed " + label + " retains its complete opaque native packet: " + id
		elif value != null:
			return "Uninstalled " + label + " retains null, without manufactured state: " + id
	return ""


## Layout membership only. Fields use a first-installed ordered union: the same
## original bloom-near persists, and bloom-far joins at the paired exercise.
## No native object, clock, source state, packet or descriptor is accessed here.
static func _topology(beat_index: int, room_stage: String) -> Dictionary:
	var count: int = 3 if beat_index == 3 else beat_index + (1 if room_stage == "active" else 0)
	var groups: Array[String] = []
	var fields: Array[String] = []
	var consumers: Array[String] = []
	var activated: Array[String] = []
	for index: int in range(count):
		groups.append(Layout.GROUP_IDS[index])
		consumers.append(Layout.CONSUMER_IDS[index])
		for id: String in Layout.GROUP_SOURCES[index]: activated.append(id)
		for id: String in Layout.GROUP_FIELDS[index]:
			if not fields.has(id): fields.append(id)
	return {"installed_groups": groups, "installed_fields": fields, "installed_consumers": consumers, "activated_source_ids": activated}


static func _same(left: Variant, right: Variant) -> bool:
	var text: String = Exact.stringify(left)
	return not text.is_empty() and text == Exact.stringify(right)
