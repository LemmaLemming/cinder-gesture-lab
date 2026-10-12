extends RefCounted
## INERT owned full-route aggregate draft. Not imported, parsed or executed.
## Native codecs own all attack, motion, field, Route, timing and dedupe rules.
## The Level owns immutable world/resource custody, saved framing and progress.
## This helper never constructs recipients, restores Player, admits or advances.

const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Actor = preload("res://scripts/acts/act1/mushroom_selenite.gd")
const ActorCodec = preload("res://scripts/acts/act1/mushroom_selenite_codec.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Field = preload("res://scripts/environment/spore_field.gd")
const Consumer = preload("res://scripts/environment/spore_repulsion.gd")
const Protocol = preload("res://scripts/environment/scheduler_spore_source_protocol.gd")
const Level = preload("res://scripts/campaign/level.gd")
const Player = preload("res://scripts/player.gd")
const AUTHORED_VERSION: int = 1
const CONSTRUCTION_REVISION: String = "act1-restore-recipient-construction-1"
const SOURCE_IDS: Array[String] = ["umbrella-1", "umbrella-2", "umbrella-3", "breathing-1", "breathing-2", "breathing-3", "crossed-1", "crossed-2", "crossed-3", "crossed-4", "crossed-5", "crossed-6", "crossed-7", "crossed-8", "lone-guard", "court-1", "court-2", "court-3", "court-guard"]
const ROOM_IDS: Array[String] = ["umbrella", "breathing", "crossed", "lone-guard", "court"]
const ROOM_SOURCES: Array = [["umbrella-1", "umbrella-2", "umbrella-3"], ["breathing-1", "breathing-2", "breathing-3"], ["crossed-1", "crossed-2", "crossed-3", "crossed-4", "crossed-5", "crossed-6", "crossed-7", "crossed-8"], ["lone-guard"], ["court-1", "court-2", "court-3", "court-guard"]]
const FIELD_IDS: Array[String] = ["breathing", "crossed-left", "crossed-right", "court"]
const ROOM_FIELDS: Array = [[], ["breathing"], ["crossed-left", "crossed-right"], [], ["court"]]
const CONSUMER_ROOMS: Array[String] = ["breathing", "crossed", "court"]
const BEAT_IDS: Array[String] = ["umbrella-grove", "breathing-chamber", "crossed-grotto", "spear-pocket", "court-approach"]
const CHECKPOINT_IDS: Array[String] = ["umbrella-grove", "breathing-chamber", "crossed-grotto", "spear-pocket"]
const LOCAL_KEYS: Array[String] = ["authored_snapshot_version", "beat_index", "completed_beats", "room_stage", "actors", "scheduler", "fields", "consumers", "framing"]
const AUTHORED_KEYS: Array[String] = ["source_ids", "room_ids", "room_sources", "field_ids", "room_fields", "consumer_rooms", "beat_ids", "checkpoint_ids", "completion_id", "exit_id", "source_positions", "field_positions", "world_revision", "controller_id", "player_id"]
const BINDING_KEYS: Array[String] = ["level", "player", "scheduler", "actors", "fields", "consumers", "protocols", "scheduler_bindings", "runtime_error", "framing_error"]
const METADATA_KEYS: Array[String] = ["beat_index", "completed_beats", "room_stage", "framing"]
const FRAME_KEYS: Array[String] = ["reservation_id", "landing", "attack_position", "primary_time_s", "response_complete_s", "action_escape"]

var last_error: String = ""
var last_commit_error: String = ""


func configuration_error(authored: Dictionary) -> String:
	if Exact.stringify(authored).is_empty() or not Codec.keys_error(authored, AUTHORED_KEYS).is_empty():
		return "Closed exact authored L3 definitions required"
	var identities: Dictionary = {"source_ids": SOURCE_IDS, "room_ids": ROOM_IDS, "room_sources": ROOM_SOURCES, "field_ids": FIELD_IDS, "room_fields": ROOM_FIELDS, "consumer_rooms": CONSUMER_ROOMS, "beat_ids": BEAT_IDS, "checkpoint_ids": CHECKPOINT_IDS}
	for key: String in identities:
		if not _same(authored[key], identities[key]): return "Authored canonical cast/room/progress membership differs: " + key
	if authored.completion_id != "mushroom-caverns-clear" or authored.exit_id != "open-court" or not authored.world_revision is int or authored.world_revision != 1 or authored.controller_id != "mushroom-scheduler" or authored.player_id != "hero":
		return "Authored completion/exit/world/controller/Player identity differs"
	if not authored.source_positions is Dictionary or not authored.field_positions is Dictionary or not Codec.keys_error(authored.source_positions, SOURCE_IDS).is_empty() or not Codec.keys_error(authored.field_positions, FIELD_IDS).is_empty():
		return "Every actual authored source and field position required"
	for id: String in SOURCE_IDS:
		if not _encoded_vector(authored.source_positions[id]): return "Exact finite authored source position required: " + id
	for id: String in FIELD_IDS:
		if not _encoded_vector(authored.field_positions[id]): return "Exact finite authored field position required: " + id
	return ""


## This structural plan grants no runtime entitlement. CinderLevel has already
## validated saved Player before its construction hook; full native/world
## validation runs again AFTER actual recipients/Fields/Consumers are built.
func construction_plan(saved_local: Dictionary, saved_player: Dictionary, authored: Dictionary, configurations: Dictionary) -> Dictionary:
	var error: String = configuration_error(authored)
	if error.is_empty(): error = _local_structure_error(saved_local)
	if error.is_empty(): error = _configuration_map_error(configurations)
	if error.is_empty(): error = _saved_player_structure_error(saved_player)
	if error.is_empty(): error = _scheduler_preflight(saved_local.scheduler)
	if error.is_empty(): error = _composition_error(saved_local, saved_player, authored, configurations)
	if error.is_empty(): error = _native_exact_transport_error(saved_local)
	if error.is_empty(): error = _framing_structure_error(saved_local)
	if not error.is_empty(): return {"accepted": false, "error": error}
	var topology: Dictionary = _topology(saved_local)
	var descriptors: Dictionary = {}
	for id: String in topology.activated_source_ids:
		var room: String = ROOM_IDS[_source_room(id)]
		var encoded: String = Exact.stringify(configurations[id])
		descriptors[id] = {"api_revision": CONSTRUCTION_REVISION, "source_id": id, "room_id": room, "installed_rooms": topology.installed_rooms.duplicate(), "installed_fields": topology.installed_fields.duplicate(), "configuration_sha256": encoded.sha256_text(), "authored_position": authored.source_positions[id].duplicate()}
	return {"accepted": true, "error": "", "installed_rooms": topology.installed_rooms, "installed_fields": topology.installed_fields, "activated_source_ids": topology.activated_source_ids, "bound_source_ids": topology.bound_source_ids, "descriptors": descriptors}


## Metadata is already serialized exact JSON, including ORIGINAL six-field
## admission witnesses. A capture never recomputes an earlier proof/time.
func capture_state(metadata: Dictionary, saved_player: Dictionary, bindings: Dictionary, authored: Dictionary) -> Dictionary:
	last_error = configuration_error(authored)
	if last_error.is_empty(): last_error = _bindings_error(bindings, authored)
	if last_error.is_empty() and (Exact.stringify(metadata).is_empty() or not Codec.keys_error(metadata, METADATA_KEYS).is_empty()): last_error = "Exact closed authored capture metadata required"
	if not last_error.is_empty(): return {}
	last_error = bindings.player.snapshot_error(saved_player)
	if not last_error.is_empty(): return {}
	var current_player: Dictionary = bindings.player.snapshot_state()
	if current_player.is_empty() or not _same(current_player, saved_player):
		last_error = "Capture requires the exact current paused Player, never an earlier supplied pair"
		return {}
	var control: Dictionary = bindings.scheduler.snapshot_state(bindings.scheduler_bindings)
	if control.is_empty():
		last_error = "Whole actual Scheduler capture rejected: " + bindings.scheduler.last_snapshot_error
		return {}
	var saved: Dictionary = {"authored_snapshot_version": AUTHORED_VERSION, "beat_index": metadata.beat_index, "completed_beats": metadata.completed_beats.duplicate(true) if metadata.completed_beats is Array else metadata.completed_beats, "room_stage": metadata.room_stage, "actors": {}, "scheduler": control, "fields": {}, "consumers": {}, "framing": metadata.framing.duplicate(true) if metadata.framing is Dictionary else metadata.framing}
	var pair: Dictionary = {"controllers": {authored.controller_id: control}, "players": {authored.player_id: saved_player}}
	for id: String in SOURCE_IDS:
		var room: String = ROOM_IDS[_source_room(id)]
		var protocols: Variant = bindings.protocols[room] if room in CONSUMER_ROOMS else null
		var protocol: Variant = protocols.get(id) if protocols is Dictionary else null
		saved.actors[id] = protocol.current_unit(pair) if _object(protocol) else bindings.actors[id].capture_state(control)
		if saved.actors[id].is_empty():
			last_error = "Whole actual source capture rejected: " + id + ": " + (protocol.last_error if _object(protocol) else bindings.actors[id].last_snapshot_error)
			return {}
	for id: String in FIELD_IDS:
		var field: Variant = bindings.fields[id]
		saved.fields[id] = field.snapshot_state() if _object(field) else null
		if _object(field) and saved.fields[id].is_empty():
			last_error = "Whole actual Field capture rejected: " + id + ": " + field.last_snapshot_error
			return {}
	for room: String in CONSUMER_ROOMS:
		var consumer: Variant = bindings.consumers[room]
		saved.consumers[room] = consumer.snapshot_state(_consumer_context(saved, saved_player, room, authored)) if _object(consumer) else null
		if _object(consumer) and saved.consumers[room].is_empty():
			last_error = "Whole actual Consumer capture rejected: " + room + ": " + consumer.last_error
			return {}
	last_error = state_error(saved, saved_player, bindings, authored)
	return saved.duplicate(true) if last_error.is_empty() else {}


## Pure complete validation, including current native saved-Player context.
## Neither this path nor its mandatory parent Callables may configure, activate,
## repair a cache, redraw, prune state(), emit events or change a native clock.
func state_error(saved_local: Dictionary, saved_player: Dictionary, bindings: Dictionary, authored: Dictionary) -> String:
	var error: String = configuration_error(authored)
	if error.is_empty(): error = _local_structure_error(saved_local)
	if error.is_empty(): error = _saved_player_structure_error(saved_player)
	if error.is_empty(): error = _scheduler_preflight(saved_local.scheduler)
	if error.is_empty(): error = _bindings_error(bindings, authored)
	if not error.is_empty(): return error
	error = bindings.player.snapshot_error(saved_player)
	if not error.is_empty(): return "Player: " + error
	var configurations: Dictionary = _actual_configurations(bindings)
	error = _configuration_map_error(configurations)
	if error.is_empty(): error = _composition_error(saved_local, saved_player, authored, configurations)
	if error.is_empty(): error = _native_exact_transport_error(saved_local)
	if error.is_empty(): error = _installed_bindings_error(saved_local, bindings, authored)
	if not error.is_empty(): return error
	for id: String in SOURCE_IDS:
		error = bindings.actors[id].snapshot_error(saved_local.actors[id], saved_local.scheduler, saved_player)
		if not error.is_empty(): return id + ": " + error
	# Public pure capture provides actual static collision bytes only. Its live
	# clock/profile are not substituted for the separately saved whole pair.
	var current_control: Dictionary = bindings.scheduler.snapshot_state(bindings.scheduler_bindings)
	if current_control.is_empty() or not _same(current_control.collision, saved_local.scheduler.collision): return "Saved Scheduler must retain the exact actual static collision fingerprint"
	var topology: Dictionary = _topology(saved_local)
	for id: String in SOURCE_IDS:
		if id in topology.activated_source_ids: continue
		var pristine: Dictionary = bindings.actors[id].capture_state(current_control)
		if pristine.is_empty() or not _same(pristine, saved_local.actors[id]): return "Future source must retain its actual whole pristine dormant envelope: " + id
	var staged: Dictionary = staged_scheduler_bindings(saved_local, saved_player, bindings)
	if staged.is_empty(): return "Every inner native owner staging map and the saved Hero pose required"
	error = bindings.scheduler.snapshot_error(saved_local.scheduler, staged)
	if not error.is_empty(): return "Scheduler: " + error
	for id: String in FIELD_IDS:
		if saved_local.fields[id] == null: continue
		var actual_field: Dictionary = bindings.fields[id].snapshot_state()
		if actual_field.is_empty() or not _same(actual_field.definition, saved_local.fields[id].get("definition")) or not _same(actual_field.geometry, saved_local.fields[id].get("geometry")): return "Field must preserve exact native immutable definition/geometry bytes: " + id
		error = bindings.fields[id].snapshot_error(saved_local.fields[id])
		if not error.is_empty(): return id + ": " + error
	for room: String in CONSUMER_ROOMS:
		if saved_local.consumers[room] == null: continue
		error = bindings.consumers[room].snapshot_error(saved_local.consumers[room], _consumer_context(saved_local, saved_player, room, authored))
		if not error.is_empty(): return room + ": " + error
	error = _framing_structure_error(saved_local)
	if not error.is_empty(): return error
	var framed: Variant = bindings.framing_error.call(saved_local.duplicate(true), saved_player.duplicate(true))
	if not framed is String: return "Owned pure saved-framing guard must return String"
	if not framed.is_empty(): return framed
	# Recheck required retained handles and the pure barrier after native/parent
	# validators. No callback is allowed to replace a node or world during query.
	return _bindings_error(bindings, authored)


## Only use after complete state_error. Native staging is not serialized and
## cannot replace the actual nineteen owners/static floors/world bindings.
func staged_scheduler_bindings(saved_local: Dictionary, saved_player: Dictionary, bindings: Dictionary) -> Dictionary:
	if not saved_local.get("actors") is Dictionary or not Codec.keys_error(saved_local.actors, SOURCE_IDS).is_empty() or not _saved_player_structure_error(saved_player).is_empty() or not bindings.get("scheduler_bindings") is Dictionary or not bindings.get("actors") is Dictionary or not Codec.keys_error(bindings.actors, SOURCE_IDS).is_empty(): return {}
	var native: Dictionary = bindings.scheduler_bindings.duplicate(true)
	for key: String in ["owner_positions", "owner_velocities", "owner_collision_states"]: native[key] = {}
	for id: String in SOURCE_IDS:
		var actor: Variant = bindings.actors[id]
		if not _object(actor) or not actor is Actor or actor.get_script() != Actor or not saved_local.actors[id] is Dictionary: return {}
		var stage: Dictionary = actor.staged_actor_bindings(saved_local.actors[id])
		if stage.is_empty() or not Codec.keys_error(stage, ["owner_positions", "owner_velocities", "owner_collision_states"]).is_empty(): return {}
		for key: String in ["owner_positions", "owner_velocities", "owner_collision_states"]:
			if not stage[key] is Dictionary: return {}
			for owner_id: String in stage[key]:
				if owner_id != id or native[key].has(owner_id): return {}
				native[key][owner_id] = stage[key][owner_id]
		if not native.owner_positions.has(id) or not native.owner_velocities.has(id): return {}
	native["hero_positions"] = {"hero": Codec.read_vector3(saved_player.motion.position)}
	return native


## Shell ALREADY committed the exact saved Player. Commit has no yield/events.
## Prevalidation is atomic; unforeseen native commit failure is NOT rolled back
## by this helper or CinderLevel's void hook. The full owner must reject/dispose
## an uninstalled candidate on last_commit_error before Shell installation.
func restore_native_state(saved_local: Dictionary, saved_player: Dictionary, bindings: Dictionary, authored: Dictionary) -> bool:
	last_commit_error = state_error(saved_local, saved_player, bindings, authored)
	if not last_commit_error.is_empty(): return false
	var actual_player: Dictionary = bindings.player.snapshot_state()
	if actual_player.is_empty() or not _same(actual_player, saved_player):
		last_commit_error = "Shared Shell must commit the exact saved Player before owned native restoration"
		return false
	var native: Dictionary = staged_scheduler_bindings(saved_local, saved_player, bindings)
	if native.is_empty():
		last_commit_error = "Prevalidated native staging became unavailable"
		return false
	for id: String in FIELD_IDS:
		if saved_local.fields[id] == null: continue
		if not bindings.fields[id].restore_state(saved_local.fields[id]): return _commit_failed("Field " + id, bindings.fields[id].last_snapshot_error)
	for id: String in SOURCE_IDS:
		if not bindings.actors[id].restore_actor_state(saved_local.actors[id]): return _commit_failed("Actor physical " + id, bindings.actors[id].last_snapshot_error)
	if not bindings.scheduler.restore_state(saved_local.scheduler, native): return _commit_failed("Scheduler", bindings.scheduler.last_snapshot_error)
	for id: String in SOURCE_IDS:
		if not bindings.actors[id].restore_exchange_state(saved_local.actors[id]): return _commit_failed("Actor exchange " + id, bindings.actors[id].last_snapshot_error)
	for room: String in CONSUMER_ROOMS:
		if saved_local.consumers[room] == null: continue
		if not bindings.consumers[room].restore_state(saved_local.consumers[room], _consumer_context(saved_local, saved_player, room, authored)): return _commit_failed("Consumer " + room, bindings.consumers[room].last_error)
	last_commit_error = ""
	return true # Parent commits metadata/framing and quiet presentation next.


## Public pure wrapper seam for CinderLevel's whole envelope. Native local
## clocks/resources stay independent from authored progress and contact flags.
func progress_error(progress: Dictionary, saved_local: Dictionary, authored: Dictionary) -> String:
	var error: String = configuration_error(authored)
	if error.is_empty(): error = _local_structure_error(saved_local)
	if not error.is_empty(): return error
	if Exact.stringify(progress).is_empty() or not Codec.keys_error(progress, ["completed", "completion_id", "contact_exit_id", "checkpoint_id", "checkpoint_kind", "checkpoint_ids"]).is_empty() or not progress.completed is bool or not progress.completion_id is String or not progress.contact_exit_id is String or not progress.checkpoint_id is String or not progress.checkpoint_kind is String or not progress.checkpoint_ids is Dictionary:
		return "Closed exact native progression envelope required"
	var completed: bool = saved_local.beat_index == 5
	if progress.completed != completed or progress.completion_id != (authored.completion_id if completed else "") or (not progress.contact_exit_id.is_empty() and (not completed or progress.contact_exit_id != authored.exit_id)):
		return "Completion/contact must match the genuine five-beat prefix"
	var count: int = mini(int(saved_local.beat_index), 4)
	var expected: Dictionary = {}
	for index: int in count: expected[CHECKPOINT_IDS[index]] = "encounter"
	if not _same(progress.checkpoint_ids, expected): return "Checkpoint history must be the exact first-four completed prefix"
	if progress.checkpoint_id != (CHECKPOINT_IDS[count - 1] if count > 0 else "") or progress.checkpoint_kind != ("encounter" if count > 0 else ""):
		return "Current checkpoint must match the latest genuine completed nonfinal room"
	return ""


func consumer_context(saved_local: Dictionary, saved_player: Dictionary, room_id: String, authored: Dictionary) -> Dictionary:
	if not configuration_error(authored).is_empty() or not _local_structure_error(saved_local).is_empty() or not _saved_player_structure_error(saved_player).is_empty() or room_id not in CONSUMER_ROOMS or saved_local.consumers[room_id] == null: return {}
	return _consumer_context(saved_local, saved_player, room_id, authored)


func _local_structure_error(saved: Dictionary) -> String:
	if Exact.stringify(saved).is_empty() or not Codec.keys_error(saved, LOCAL_KEYS).is_empty() or not saved.authored_snapshot_version is int or saved.authored_snapshot_version != AUTHORED_VERSION or not saved.beat_index is int or saved.beat_index < 0 or saved.beat_index > 5 or not saved.completed_beats is Array or not saved.room_stage is String or saved.room_stage not in ["approach", "active", "complete"]:
		return "Closed exact authored L3 schema1/complete lifecycle boundary required"
	if not _same(saved.completed_beats, BEAT_IDS.slice(0, int(saved.beat_index))) or (saved.room_stage == "complete") != (saved.beat_index == 5):
		return "Completed beat order and final stage must be the literal five-room prefix"
	for key: String in ["actors", "scheduler", "fields", "consumers", "framing"]:
		if not saved[key] is Dictionary: return "Whole native unit map required: " + key
	if not Codec.keys_error(saved.actors, SOURCE_IDS).is_empty() or not Codec.keys_error(saved.fields, FIELD_IDS).is_empty() or not Codec.keys_error(saved.consumers, CONSUMER_ROOMS).is_empty():
		return "Exact retained nineteen-source/four-field/three-consumer coverage required"
	for id: String in SOURCE_IDS:
		if not saved.actors[id] is Dictionary: return "Whole native source required: " + id
	var topology: Dictionary = _topology(saved)
	for id: String in FIELD_IDS:
		if (saved.fields[id] is Dictionary) != (id in topology.installed_fields) or (id not in topology.installed_fields and saved.fields[id] != null): return "Installed/future Field presence differs from the genuine prefix: " + id
	for room: String in CONSUMER_ROOMS:
		var installed: bool = room in topology.installed_rooms
		if (saved.consumers[room] is Dictionary) != installed or (not installed and saved.consumers[room] != null): return "Installed/future Consumer presence differs from the genuine prefix: " + room
	return ""


func _saved_player_structure_error(saved_player: Dictionary) -> String:
	# Whole authoritative Player is validated by CinderLevel/Shell or the actual
	# Player below; this guards pure construction's accesses without a fake codec.
	if Exact.stringify(saved_player).is_empty() or not saved_player.get("motion") is Dictionary or not _encoded_vector(saved_player.motion.get("position")) or not saved_player.get("resources") is Dictionary or not saved_player.resources.get("dead") is bool:
		return "Separately validated exact whole saved Player context required"
	return ""


func _configuration_map_error(configurations: Dictionary) -> String:
	if Exact.stringify(configurations).is_empty() or not Codec.keys_error(configurations, SOURCE_IDS).is_empty(): return "Trusted actual configuration for all nineteen retained sources required"
	var decoder := ActorCodec.new()
	for id: String in SOURCE_IDS:
		if not configurations[id] is Dictionary: return "Whole trusted native configuration required: " + id
		var error: String = decoder.configuration_error(configurations[id])
		if not error.is_empty(): return id + ": " + error
		if configurations[id].source_id != id or configurations[id].entity_id != ("C32" if id in ["lone-guard", "court-guard"] else "C31") or configurations[id].initially_dormant != true or configurations[id].approach.enabled != (id not in ["lone-guard", "court-guard"]):
			return "Normal route's immutable role/dormancy/approach identity differs: " + id
	return ""


func _scheduler_preflight(saved: Dictionary) -> String:
	# Complete native/world validation belongs ONLY to shared snapshot_error.
	# These copied type guards keep early construction/native codec access safe.
	var keys: Array = ["api_revision", "schema_version", "encounter_id", "profile", "world_revision", "clock_s", "serial", "collision", "reservations", "cooldowns"]
	if saved.has("replay_cancellations"): keys.append("replay_cancellations")
	if Exact.stringify(saved).is_empty() or not Codec.keys_error(saved, keys).is_empty() or saved.api_revision != Scheduler.SNAPSHOT_API_REVISION or not saved.schema_version is int or saved.schema_version not in [1, 2] or not saved.encounter_id is String or not saved.profile is Dictionary or not saved.world_revision is int or not Codec.is_integer(saved.world_revision) or not saved.serial is int or not Codec.is_integer(saved.serial) or not saved.clock_s is float or not Codec.in_range(saved.clock_s, 0.0, 1000000000.0) or not saved.collision is Dictionary or not saved.reservations is Array or not saved.cooldowns is Array:
		return "Exact complete shared Scheduler envelope required before authored construction"
	if saved.has("replay_cancellations"):
		return "This literal C31/C32 route has no native replay-cancellation authority"
	var leased: Dictionary = {}
	for value: Variant in saved.reservations:
		if not value is Dictionary or not value.get("source_id") is String or value.source_id not in SOURCE_IDS or leased.has(value.source_id): return "Whole native reservation must belong uniquely to the retained cast"
		leased[value.source_id] = true
		for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
			if not value.get(key) is float or not is_finite(value[key]): return "Copied native reservation deadline must remain a literal finite float"
	var cooled: Dictionary = {}
	for value: Variant in saved.cooldowns:
		if not value is Dictionary or not value.get("source_id") is String or value.source_id not in SOURCE_IDS or cooled.has(value.source_id) or not value.get("ready_s") is float or not is_finite(value.ready_s): return "Unique retained native owner cooldown with exact float deadline required"
		cooled[value.source_id] = true
	return ""


func _composition_error(saved: Dictionary, saved_player: Dictionary, authored: Dictionary, configurations: Dictionary) -> String:
	var topology: Dictionary = _topology(saved)
	var decoder := ActorCodec.new()
	var current_ids: Array = ROOM_SOURCES[saved.beat_index] if saved.room_stage == "active" else []
	if saved.room_stage == "active":
		if saved.scheduler.encounter_id != "a1_l3_" + ROOM_IDS[saved.beat_index] or saved.scheduler.world_revision != authored.world_revision or not saved.scheduler.profile.get("id") is String:
			return "Active room requires its literal current native encounter/world/profile"
		var profile: Dictionary = Difficulty.new().profile(saved.scheduler.profile.id)
		if profile.is_empty() or not _same(saved.scheduler.profile, profile): return "Current resolved native profile must match its exact canonical catalogue"
	elif not saved.scheduler.encounter_id.is_empty() or not saved.scheduler.profile.is_empty() or not saved.scheduler.reservations.is_empty() or not saved.scheduler.cooldowns.is_empty():
		return "Approach/complete must retain a genuinely idle native Scheduler without inventing an epoch"
	if saved.room_stage != "active" and saved.scheduler.world_revision != (0 if saved.beat_index == 0 else authored.world_revision): return "Idle world revision must be the untouched spawn or genuine completed-room revision"
	if saved.room_stage == "approach" and saved.beat_index == 0 and (saved.scheduler.clock_s != 0.0 or saved.scheduler.serial != 0): return "Pristine unopened route cannot invent a prior Scheduler clock/serial"
	for id: String in SOURCE_IDS:
		var actor: Dictionary = saved.actors[id]
		var error: String = decoder.context_error(actor, saved.scheduler, saved_player, configurations[id])
		if not error.is_empty(): return id + ": " + error
		var room_index: int = _source_room(id)
		var activated: bool = id in topology.activated_source_ids
		if actor.dormant == activated: return "Only the installed prefix contains actual activated recipients: " + id
		if room_index < saved.beat_index and not actor.dead: return "Every previous required source must be genuinely defeated: " + id
		if not activated and not _same(actor.motion.position, authored.source_positions[id]): return "Future pristine dormant source moved away from its actual authored origin: " + id
		if actor.cycle > 0 and actor.role_encounter_id != "a1_l3_" + ROOM_IDS[room_index]: return "Source historical native epoch belongs only to its actual room: " + id
		var bound: bool = id in topology.bound_source_ids
		if actor.has("repulsion") != bound: return "Conditional native stamp must match actual installed spore membership: " + id
		if bound:
			error = decoder.repulsion_error(actor.repulsion, id, "a1_l3_" + ROOM_IDS[room_index] + "_spores")
			if not error.is_empty(): return id + ": " + error
		if not actor.reservation_id.is_empty() and id not in current_ids: return "Only the current actual room can retain a native lease: " + id
	for record: Dictionary in saved.scheduler.cooldowns:
		if not record.get("source_id") is String or record.source_id not in current_ids: return "Only a living current-room source can retain a native cooldown"
		for lease: Dictionary in saved.scheduler.reservations:
			if lease.get("source_id") == record.source_id and not _same(record.ready_s, lease.cooldown_until_s): return "Live lease and cooldown must retain the same exact copied deadline"
	return ""


## Native legacy readers support ordinary JSON coercion; this NEW exact local
## transport admits only the types actually emitted by its native writers.
## No phase/range/clock advance is implemented here. Native readers still prove
## every value and physical numerical bound after these lossless type checks.
func _native_exact_transport_error(saved: Dictionary) -> String:
	for id: String in SOURCE_IDS:
		if not saved.actors[id].get("hp") is float or not is_finite(saved.actors[id].hp): return "Exact native HP float required before quiet Actor commit: " + id
	for id: String in FIELD_IDS:
		var field: Variant = saved.fields[id]
		if field == null: continue
		if not field.get("schema_version") is int or not field.get("generation") is int or not field.get("clock_s") is float or not is_finite(field.clock_s): return "Exact native Field counter/clock types required: " + id
		for key: String in ["activation_s", "deadline_s"]:
			if field.get(key) != null and (not field[key] is float or not is_finite(field[key])): return "Exact native Field activation/deadline float required: " + id
	for room: String in CONSUMER_ROOMS:
		var consumer: Variant = saved.consumers[room]
		if consumer == null: continue
		if not consumer.get("schema_version") is int or consumer.schema_version != 2 or not consumer.get("serial") is int or not consumer.get("records") is Dictionary or not consumer.get("source_environments") is Dictionary: return "Whole exact native Coordinator schema2/counter/maps required: " + room
		for id: String in consumer.records:
			var record: Variant = consumer.records[id]
			if not record is Dictionary or not record.get("route_revision") is int or not record.get("members") is Array or not _encoded_vector(record.get("direction")) or not _encoded_vector(record.get("original_endpoint")): return "Exact native episode counter/vector/membership required: " + id
			for key: String in ["age_s", "phase_age_s", "route_started_age_s", "progress"]:
				if not record.get(key) is float or not is_finite(record[key]): return "Copied native episode clock/progress must remain literal float: " + id
			for member: Variant in record.members:
				if not member is String: return "Exact native latched field-instance member ID required: " + id
			if record.get("route") == null: continue
			var route: Variant = record.route
			if not route is Dictionary or not route.get("schema_version") is int or not route.get("route") is Dictionary or not consumer.source_environments.get(id) is Dictionary: return "Whole exact native environmental Route required: " + id
			var motion: Dictionary = route.route
			for key: String in ["start", "planned_endpoint", "current_position", "current_velocity", "approach_velocity", "direction"]:
				if not _encoded_vector(motion.get(key)): return "Route must retain exact native encoded motion vectors: " + id
			for key: String in ["support_radius", "foot_offset", "speed", "distance", "duration_s", "elapsed_s"]:
				if not motion.get(key) is float or not is_finite(motion[key]): return "Route must retain exact native scalar/clock types: " + id
			var environment: Dictionary = consumer.source_environments[id]
			for key: String in ["body_signature", "support_radius", "foot_offset"]:
				if not environment.has(key) or not _same(motion.get(key), environment[key]): return "Route immutable measured body bytes differ from its native bound environment: " + id
			for key: String in ["world_signature", "floor_signature"]:
				if not environment.has(key) or not _same(route.get(key), environment[key]): return "Route immutable world/floor bytes differ from its native bound environment: " + id
	return ""


func _framing_structure_error(saved: Dictionary) -> String:
	var reservations: Dictionary = {}
	for raw: Variant in saved.scheduler.reservations:
		if not raw is Dictionary or not raw.get("source_id") is String or not raw.get("id") is String or reservations.has(raw.source_id): return "Unique complete native lease IDs required for framing"
		reservations[raw.source_id] = raw
	if not Codec.keys_error(saved.framing, reservations.keys()).is_empty(): return "Accepted witnesses must cover exactly every live native reservation"
	for id: String in saved.framing:
		var value: Variant = saved.framing[id]
		var record: Dictionary = reservations[id]
		if not value is Dictionary or not Codec.keys_error(value, FRAME_KEYS).is_empty() or value.reservation_id != record.id or not _encoded_vector(value.landing) or not _encoded_vector(value.attack_position) or not value.primary_time_s is float or not value.response_complete_s is float or not is_finite(value.primary_time_s) or not is_finite(value.response_complete_s):
			return "Exact original six-field accepted native response witness required: " + id
		for key: String in ["active_until_s", "recovery_until_s"]:
			if not record.get(key) is float or not is_finite(record[key]): return "Original native recovery deadlines required for accepted witness"
		if value.primary_time_s < record.active_until_s or value.response_complete_s < value.primary_time_s or value.response_complete_s >= record.recovery_until_s: return "Ordinary-primary accepted witness must fit its exact native recovery window"
		var error: String = _action_escape_error(value, record)
		if not error.is_empty(): return id + ": " + error
	return ""


func _action_escape_error(frame: Dictionary, record: Dictionary) -> String:
	var proof: Variant = frame.action_escape
	if not proof is Dictionary or not Codec.keys_error(proof, ["accepted", "path", "landing", "attack_position", "primary_time_s", "response_complete_s", "uses_blast", "uses_invulnerability", "proof_scope"]).is_empty() or not proof.accepted is bool or proof.accepted != true or not proof.uses_blast is bool or proof.uses_blast != false or not proof.uses_invulnerability is bool or proof.uses_invulnerability != false or proof.proof_scope != "static_box_floor_full_dash_stationary_primary" or not proof.path is Array or proof.path.size() not in [4, 6]: return "Whole original supported native ordinary action-escape proof required"
	for key: String in ["landing", "attack_position", "primary_time_s", "response_complete_s"]:
		if not _same(proof[key], frame[key]): return "Accepted proof and retained witness must preserve the same exact copied endpoint/time"
	var kinds: Array = ["recognition_and_ready", "escape_dash", "recovery_wait", "ordinary_primary"] if proof.path.size() == 4 else ["recognition_and_ready", "escape_dash", "recovery_wait", "positioning_dash", "primary_ready", "ordinary_primary"]
	var previous: Dictionary = {}
	for index: int in proof.path.size():
		var segment: Variant = proof.path[index]
		if not segment is Dictionary or not Codec.keys_error(segment, ["from", "to", "start_s", "end_s", "kind"]).is_empty() or segment.kind != kinds[index] or not _encoded_vector(segment.from) or not _encoded_vector(segment.to) or not segment.start_s is float or not segment.end_s is float or not is_finite(segment.start_s) or not is_finite(segment.end_s) or segment.start_s > segment.end_s: return "Original bounded native timed path segment required"
		if index == 0 and not _same(segment.start_s, record.start_s): return "Original action path must start at its actual native admission clock"
		if not previous.is_empty() and (not _same(previous.end_s, segment.start_s) or not _same(previous.to, segment.from)): return "Original action path must retain exact contiguous endpoints/clocks"
		if segment.kind not in ["escape_dash", "positioning_dash"] and not _same(segment.from, segment.to): return "Original native waiting/ordinary primary segment must remain stationary"
		if segment.start_s == segment.end_s and not _same(segment.from, segment.to): return "Zero-time action path cannot contain displacement"
		previous = segment
	if not _same(proof.path[1].to, frame.landing) or not _same(previous.from, frame.attack_position) or not _same(previous.to, frame.attack_position) or not _same(previous.start_s, frame.primary_time_s) or not _same(previous.end_s, frame.response_complete_s): return "Original escape landing and complete ordinary-primary path must agree exactly"
	return ""


func _bindings_error(bindings: Dictionary, authored: Dictionary) -> String:
	if not Codec.keys_error(bindings, BINDING_KEYS).is_empty(): return "Closed trusted whole-parent native bindings required"
	for key: String in ["level", "player", "scheduler"]:
		if not _live(bindings[key]): return "Actual live retained parent/Player/Scheduler required: " + key
	if not bindings.level is Level or not bindings.player is Player or not bindings.scheduler is Scheduler or bindings.level.hero != bindings.player or bindings.level.get("scheduler") != bindings.scheduler or bindings.level.get_world_3d() != bindings.player.get_world_3d() or bindings.level.get_world_3d() != bindings.scheduler.get_world_3d() or not bindings.level.get_tree().paused:
		return "Same actual paused CinderLevel/Player/Scheduler authority required"
	for key: String in ["actors", "fields", "consumers", "protocols", "scheduler_bindings"]:
		if not bindings[key] is Dictionary: return "Actual native handle map required: " + key
	if not Codec.keys_error(bindings.actors, SOURCE_IDS).is_empty() or not Codec.keys_error(bindings.fields, FIELD_IDS).is_empty() or not Codec.keys_error(bindings.consumers, CONSUMER_ROOMS).is_empty() or not Codec.keys_error(bindings.protocols, CONSUMER_ROOMS).is_empty(): return "Exact retained actual source/nullable installed topology maps required"
	var used: Dictionary = {}
	for id: String in SOURCE_IDS:
		var actor: Variant = bindings.actors[id]
		if not _live(actor) or not actor is Actor or actor.get_script() != Actor or actor.get_parent() != bindings.level or actor.get_world_3d() != bindings.level.get_world_3d() or used.has(actor.get_instance_id()): return "Retain one distinct actual native source/script/direct parent: " + id
		used[actor.get_instance_id()] = true
	for id: String in FIELD_IDS:
		var field: Variant = bindings.fields[id]
		if field == null: continue
		if not _live(field) or not field is Field or field.get_script() != Field or field.get_parent() != bindings.level or field.get_world_3d() != bindings.level.get_world_3d(): return "Retain the actual installed Field/script/world: " + id
	for room: String in CONSUMER_ROOMS:
		var consumer: Variant = bindings.consumers[room]
		if consumer == null: continue
		if not _live(consumer) or not consumer is Consumer or consumer.get_script() != Consumer or consumer.get_parent() != bindings.level or consumer.get_world_3d() != bindings.level.get_world_3d() or consumer.consumer_id() != "a1_l3_" + room + "_spores" or not consumer.snapshot_boundary_available(): return "Retain actual bound Consumer at the complete native paused boundary: " + room
	if not bindings.runtime_error is Callable or bindings.runtime_error != Callable(bindings.level, "route_snapshot_runtime_error") or not bindings.runtime_error.is_valid() or not bindings.framing_error is Callable or bindings.framing_error != Callable(bindings.level, "route_snapshot_framing_error") or not bindings.framing_error.is_valid(): return "Exact pure actual parent resource/barrier and saved-framing Callables required"
	if not Codec.keys_error(bindings.scheduler_bindings, ["world_root", "owners", "floors"]).is_empty() or not bindings.scheduler_bindings.owners is Dictionary or not bindings.scheduler_bindings.floors is Dictionary or not Codec.keys_error(bindings.scheduler_bindings.owners, SOURCE_IDS).is_empty(): return "Complete actual immutable world/floor/nineteen-owner bindings required"
	var world: Variant = bindings.scheduler_bindings.world_root
	if not _live(world) or not world is Node3D or not world.is_ancestor_of(bindings.level) or not world.is_ancestor_of(bindings.player) or not world.is_ancestor_of(bindings.scheduler) or world.get_world_3d() != bindings.level.get_world_3d(): return "Retain the actual containing collision world for candidate and installed Player"
	for id: String in SOURCE_IDS:
		if bindings.scheduler_bindings.owners[id] != bindings.actors[id]: return "Staging cannot replace an actual native source owner"
	var error: Variant = bindings.runtime_error.call()
	if not error is String: return "Owned pure native runtime/barrier guard must return String"
	return error


func _installed_bindings_error(saved: Dictionary, bindings: Dictionary, authored: Dictionary) -> String:
	var topology: Dictionary = _topology(saved)
	for id: String in FIELD_IDS:
		if (bindings.fields[id] != null) != (id in topology.installed_fields): return "Actual Field installation differs from the saved prefix: " + id
		if bindings.fields[id] != null:
			if not _same(Codec.vector3(bindings.fields[id].global_position), authored.field_positions[id]) or bindings.fields[id].global_basis != Basis.IDENTITY: return "Actual immutable Field origin/frame changed: " + id
	for room: String in CONSUMER_ROOMS:
		var installed: bool = room in topology.installed_rooms
		if (bindings.consumers[room] != null) != installed or (bindings.protocols[room] is Dictionary) != installed or (not installed and bindings.protocols[room] != null): return "Actual Consumer/protocol presence differs from saved installed prefix: " + room
		if not installed: continue
		if not Codec.keys_error(bindings.protocols[room], ROOM_SOURCES[ROOM_IDS.find(room)]).is_empty(): return "Exact native protocol membership required for installed room: " + room
		for id: String in ROOM_SOURCES[ROOM_IDS.find(room)]:
			var protocol: Variant = bindings.protocols[room][id]
			if not _object(protocol) or not protocol is Protocol or protocol.get_script() != Protocol or not protocol.matches_source(bindings.actors[id], id) or not bindings.consumers[room].source_binding_matches(bindings.actors[id], id): return "Actual retained source/protocol/consumer identity changed: " + id
			var descriptor: Dictionary = protocol.binding_state()
			var native: Dictionary = bindings.actors[id].get_spore_native_bindings()
			if native.is_empty() or descriptor.get("controller_id") != authored.controller_id or descriptor.get("player_id") != authored.player_id or descriptor.get("source_id") != id or descriptor.get("configuration_sha256") != Exact.stringify(native.configuration).sha256_text(): return "Actual native protocol copied configuration/controller/Player identity changed: " + id
	return ""


func _actual_configurations(bindings: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for id: String in SOURCE_IDS:
		var native: Dictionary = bindings.actors[id].get_spore_native_bindings()
		if native.is_empty() or native.get("source_id") != id or native.get("scheduler") != bindings.scheduler or native.get("player") != bindings.player or not native.get("configuration") is Dictionary: return {}
		result[id] = native.configuration.duplicate(true)
	return result


func _consumer_context(saved: Dictionary, saved_player: Dictionary, room: String, authored: Dictionary) -> Dictionary:
	var fields: Dictionary = {}
	var actors: Dictionary = {}
	var room_index: int = ROOM_IDS.find(room)
	for id: String in ROOM_FIELDS[room_index]: fields[id] = saved.fields[id]
	for id: String in ROOM_SOURCES[room_index]: actors[id] = saved.actors[id]
	return {"fields": fields, "sources": actors, "controllers": {authored.controller_id: saved.scheduler}, "players": {authored.player_id: saved_player}}


func _topology(saved: Dictionary) -> Dictionary:
	var installed_count: int = int(saved.beat_index) + (1 if saved.room_stage == "active" else 0)
	var rooms: Array[String] = []
	var fields: Array[String] = []
	var activated: Array[String] = []
	var bound: Array[String] = []
	for index: int in installed_count:
		rooms.append(ROOM_IDS[index])
		for id: String in ROOM_FIELDS[index]: fields.append(id)
		for id: String in ROOM_SOURCES[index]:
			activated.append(id)
			if not ROOM_FIELDS[index].is_empty(): bound.append(id)
	return {"installed_rooms": rooms, "installed_fields": fields, "activated_source_ids": activated, "bound_source_ids": bound}


func _source_room(id: String) -> int:
	for index: int in ROOM_SOURCES.size():
		if id in ROOM_SOURCES[index]: return index
	return -1


func _encoded_vector(value: Variant) -> bool:
	return Codec.is_vector3(value) and _same(value, Codec.vector3(Codec.read_vector3(value)))


func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = Exact.stringify(left)
	return not encoded.is_empty() and encoded == Exact.stringify(right)


func _object(value: Variant) -> bool:
	return typeof(value) == TYPE_OBJECT and is_instance_valid(value)


func _live(value: Variant) -> bool:
	return _object(value) and value is Node and value.is_inside_tree() and not value.is_queued_for_deletion()


func _commit_failed(unit: String, error: String) -> bool:
	last_commit_error = unit + " quiet native commit unexpectedly rejected: " + error
	return false
