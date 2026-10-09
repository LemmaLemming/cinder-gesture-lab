class_name CinderAct3MirrorSeaCodec
extends RefCounted
## Closed whole-parent transport. Constructor entitlement is separate from
## earned route/history. All native recipients are proved before quiet commit.
## The level owns presentation assembly and calls the post-quiet optical gate.

const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/combat/authored_enemy_sequence.gd")
const Receipt = preload("res://scripts/combat/authored_echo_terminal_receipt.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Stalker = preload("res://scripts/acts/act3/sunbound_stalker.gd")
const Echo = preload("res://scripts/acts/act3/mirror_echo.gd")
const Mechanism = preload("res://scripts/combat/lane_mechanism.gd")
const API: String = "act3-mirror-sea-snapshot-1"
const PARENT_PATH: String = "res://scripts/acts/act3/mirror_sea_level.gd"
const LAYOUT_PATH: String = "res://data/campaign/act3/mirror_sea_layout_candidate.json"
const ENCOUNTER_ID: String = "A3-L3/mirror-sea-shore"
const PULSE_ID: String = "l3-resonant-pulse"
const RESONANT_ID: String = "l3-resonant-echo"
const EXIT_ID: String = "mirror-sea-dry-threshold"
const COMPLETION_ID: String = "mirror-sea-clear"
const FLOOR_RECT: Rect2 = Rect2(-7, -54, 14, 108)
const EXIT_RECT: Rect2 = Rect2(-1.2, -47.65, 2.4, 1.3)
const PULSE_ORIGIN: Vector3 = Vector3(2.6, 0, -21)
const FIRST_OPENING: Vector3 = Vector3(1.9, 0, -20.35)
const ENTRY_IDS: Array[String] = ["shore-and-doubled-sky", "one-real-body", "useful-ending-west", "useful-ending-east", "resonant-apron", "shore-falls-silent"]
const ENTRY_Z: Array[float] = [39.0, 27.0, 15.0, 2.0, -14.0, -32.0]
const ENTRY_BEATS: Array[int] = [1, 2, 3, 3, 4, 5]
const ENTRY_SOURCES: Array = [["l3-threshold-stalker"], ["l3-first-echo"], ["l3-useful-west-echo"], ["l3-useful-east-echo"], [RESONANT_ID, PULSE_ID], ["l3-priority-echo", "l3-priority-stalker"]]
const STALKERS: Array[String] = ["l3-threshold-stalker", "l3-priority-stalker"]
const ECHOES: Array[String] = ["l3-first-echo", "l3-useful-west-echo", "l3-useful-east-echo", RESONANT_ID, "l3-priority-echo"]
const LOCAL_KEYS: Array[String] = ["api_revision", "schema_version", "world", "scheduler", "sources", "route", "ring", "view"]
const ROUTE_KEYS: Array[String] = ["entries", "deaths", "pending_checkpoint_boundaries", "exit_state", "contact"]
const RING_KEYS: Array[String] = ["stage", "history", "exchanges", "between_receipt", "mechanism"]
const WORLD_KEYS: Array[String] = ["layout_sha256", "encounter_id", "world_revision", "profile_id", "collision_fingerprint", "floor_signature"]
const MAX_RING_HISTORY: int = 4096
const MAX_VIEW_POSITIONS: int = 12
const REQUIRED_HOOKS: Array[String] = ["mirror_sea_codec_owned_state", "mirror_sea_codec_checkpoint_ids", "mirror_sea_codec_apply_owned_state", "mirror_sea_codec_framing_union"]
var last_error: String = ""


func capture(parent, player: Dictionary) -> Dictionary:
	last_error = _access_error(parent)
	if last_error.is_empty():
		last_error = parent.hero.snapshot_error(player)
	if last_error.is_empty() and not _same(player, parent.hero.snapshot_state()):
		last_error = "Capture requires the actual current native Hero packet"
	if last_error.is_empty():
		last_error = live_presentation_error(parent)
	if not last_error.is_empty():
		return {}
	var owned: Variant = parent.call("mirror_sea_codec_owned_state")
	last_error = Receipt.transport_error(owned)
	if last_error.is_empty() and (not owned is Dictionary or not Value.keys_error(owned, ["route", "ring", "view"]).is_empty()):
		last_error = "Closed transport-only owned route/ring/view required"
	if not last_error.is_empty():
		return {}
	var bindings: Dictionary = parent.scheduler_bindings()
	var scheduler: Dictionary = parent.threat_scheduler.snapshot_state(bindings)
	if scheduler.is_empty():
		last_error = parent.threat_scheduler.last_snapshot_error
		return {}
	var sources: Dictionary = {}
	for id: String in parent.sources:
		var source: Node3D = parent.sources[id]
		if STALKERS.has(id):
			var actor: Dictionary = source.call("snapshot_state")
			if actor.is_empty():
				last_error = id + ": " + String(source.get("last_snapshot_error"))
				return {}
			sources[id] = {"kind": "stalker", "actor": actor}
		elif ECHOES.has(id):
			var playback: Dictionary = source.call("snapshot_state", scheduler, bindings)
			var actor: Dictionary = source.call("capture_source", player, scheduler, playback)
			if actor.is_empty() or playback.is_empty():
				last_error = id + ": " + String(source.get("source_snapshot_error")) + "; " + String(source.get("last_snapshot_error"))
				return {}
			sources[id] = {"kind": "echo", "actor": actor, "playback": playback}
		else:
			last_error = "Unknown retained source cannot be omitted: " + id
			return {}
	var local: Dictionary = {"api_revision": API, "schema_version": 1, "world": native_world(parent), "scheduler": scheduler, "sources": sources, "route": owned.route.duplicate(true), "ring": owned.ring.duplicate(true), "view": owned.view.duplicate(true)}
	local.ring["mechanism"] = parent.mechanism.snapshot_state(bindings) if is_instance_valid(parent.mechanism) else {}
	last_error = record_error(local, parent, player)
	return local.duplicate(true) if last_error.is_empty() else {}


## Pure immutable constructor recipe; no saved HP/pose/generation/history is
## supplied as native state. The caller disposes a failed candidate wholesale.
func constructor_recipe(local: Dictionary, parent, player: Dictionary) -> Dictionary:
	var error: String = envelope_error(local, parent, player)
	if not error.is_empty():
		return {"accepted": false, "error": error}
	var entitled: Array[String] = entitled_sources(local.route.entries.size())
	var actors: Array[String] = entitled.duplicate()
	actors.erase(PULSE_ID)
	return {"accepted": true, "error": "", "recipe": {"api_revision": "act3-mirror-sea-constructor-1", "profile_id": local.world.profile_id, "source_ids": actors, "mechanism_entitled": entitled.has(PULSE_ID), "world": local.world.duplicate(true)}}


func envelope_error(local: Dictionary, parent, player: Dictionary) -> String:
	var error: String = _access_error(parent)
	if error.is_empty():
		error = Receipt.transport_error(local)
	if error.is_empty():
		error = Receipt.transport_error(player)
	if error.is_empty():
		error = parent.hero.snapshot_error(player)
	if not error.is_empty():
		return error
	if not Value.keys_error(local, LOCAL_KEYS).is_empty() or local.get("api_revision") != API or not local.get("schema_version") is int or local.schema_version != 1:
		return "Closed Mirror Sea parent snapshot1 required"
	for key: String in ["world", "scheduler", "sources", "route", "ring", "view"]:
		if not local[key] is Dictionary:
			return "Complete typed Mirror Sea local units required"
	if not local.scheduler.get("clock_s") is float or not Receipt.clock_valid(local.scheduler.clock_s) or not local.scheduler.get("schema_version") is int or not local.scheduler.get("serial") is int or local.scheduler.serial < 0 or not local.scheduler.get("reservations") is Array or not local.scheduler.get("cooldowns") is Array or not player.get("world_actions") is Dictionary or not _same(player.world_actions.get("clock_s"), local.scheduler.clock_s):
		return "Exact same native Hero/Scheduler outer tick required"
	if not Value.keys_error(local.world, WORLD_KEYS).is_empty() or local.world.get("layout_sha256") != FileAccess.get_sha256(LAYOUT_PATH) or local.world.get("encounter_id") != ENCOUNTER_ID or not local.world.get("world_revision") is int or local.world.world_revision != 1 or not local.world.get("profile_id") is String or not local.world.get("collision_fingerprint") is Dictionary or not local.world.get("floor_signature") is Array:
		return "Immutable authored layout and exact whole world/epoch recipe required"
	var profile: Dictionary = Difficulty.new().profile(local.world.profile_id)
	if profile.is_empty() or not _same(profile, local.scheduler.get("profile")) or local.scheduler.get("encounter_id") != ENCOUNTER_ID or not _same(local.scheduler.get("world_revision"), 1) or not _same(local.scheduler.get("collision"), local.world.collision_fingerprint):
		return "Parent world/profile must join the complete continuous Scheduler"
	var actual_world: Dictionary = native_world(parent)
	if actual_world.is_empty():
		return "Actual full permanent shore floor signature unavailable"
	# Fresh constructors may initialize the saved canonical profile separately;
	# floor/static collision custody is already present and never replaced.
	for key: String in ["layout_sha256", "encounter_id", "world_revision", "collision_fingerprint", "floor_signature"]:
		if not _same(local.world[key], actual_world.get(key)):
			return "Actual original shore world binding differs: " + key
	error = _route_error(local, parent, player)
	if not error.is_empty():
		return error
	var entitled: Array[String] = entitled_sources(local.route.entries.size())
	var actors: Array[String] = entitled.duplicate()
	actors.erase(PULSE_ID)
	if not Value.keys_error(local.sources, actors).is_empty():
		return "All and only the earned entry prefix's retained actual sources are required"
	for id: String in actors:
		var packet: Variant = local.sources[id]
		var echo: bool = ECHOES.has(id)
		if not packet is Dictionary or not Value.keys_error(packet, ["kind", "actor", "playback"] if echo else ["kind", "actor"]).is_empty() or packet.get("kind") != ("echo" if echo else "stalker") or not packet.get("actor") is Dictionary or (echo and not packet.get("playback") is Dictionary):
			return "Exact typed native source envelope differs: " + id
		if not packet.actor.get("clock_s") is float or not _same(packet.actor.clock_s, local.scheduler.clock_s):
			return "Native source and whole parent clocks differ: " + id
		if echo:
			if packet.actor.get("api_revision") != "act3-mirror-echo-source-2" or not packet.actor.get("schema_version") is int or packet.actor.schema_version != 2 or packet.actor.get("source_id") != id or packet.actor.get("source_epoch") != source_epoch(id) or not packet.actor.get("generation") is int or not Value.is_integer(packet.actor.generation, 1, 64):
				return "Owned managed production source2 identity required: " + id
			var reader = Exact.new()
			if not packet.actor.get("sequence") is Dictionary or not reader.restore_state(packet.actor.sequence, source_epoch(id), packet.actor.generation):
				return id + ": canonical saved authored program required"
			error = reader.binding_error(packet.actor.sequence, id, source_epoch(id), packet.actor.generation, local.world.profile_id, parent.native_definition(id), prepared_world(local.world))
			if not error.is_empty():
				return id + ": " + error
		else:
			error = _stalker_shape_error(packet.actor, id)
			if not error.is_empty():
				return error
	error = _death_error(local)
	if error.is_empty():
		error = _ring_error(local, parent)
	if error.is_empty():
		error = _view_error(local)
	if error.is_empty():
		error = _contact_error(local, parent, player)
	return error


## Whole pure Hero/physical/journal preflight. paired=false is only the first
## stage on an untracked fresh recipient; Scheduler proof is NEVER skipped.
func record_error(local: Dictionary, parent, player: Dictionary, paired: bool = true) -> String:
	var error: String = envelope_error(local, parent, player)
	if not error.is_empty():
		return error
	if not _same(local.world.profile_id, parent.threat_scheduler.encounter_profile().get("id")):
		return "Actual fresh Scheduler must already use the saved canonical profile"
	if not Value.keys_error(parent.sources, local.sources.keys()).is_empty() or is_instance_valid(parent.mechanism) != (not local.ring.mechanism.is_empty()):
		return "Construct exactly the immutable entitled recipient topology first"
	var staged: Dictionary = parent.scheduler_bindings()
	staged["hero_positions"] = {"hero": Value.read_vector3(player.motion.position)}
	staged["owner_positions"] = {}
	staged["owner_velocities"] = {}
	staged["owner_collision_states"] = {}
	staged["authored_owner_bindings"] = {}
	staged["authored_cycle_playback_ids"] = {}
	var echoes: Array[String] = []
	for id: String in local.sources:
		var source: Node3D = parent.sources[id]
		var packet: Dictionary = local.sources[id]
		var actor: Dictionary = packet.actor
		if STALKERS.has(id):
			if source.get_script() != Stalker:
				return "Actual original Stalker script required: " + id
			error = source.call("snapshot_error", actor, local.scheduler)
			if not error.is_empty():
				return id + ": " + error
			staged.owner_positions[id] = Value.read_vector3(actor.position)
			staged.owner_velocities[id] = Value.read_vector3(actor.velocity)
			if not actor.dead and not String(actor.reservation_id).is_empty():
				staged.owner_collision_states[id] = {"collision_path": "BodyCollision", "enabled": true, "layer": 2, "mask": 1}
			if _same(actor.previous.clock_s, local.scheduler.clock_s) and not _same(actor.previous.hero_position, player.motion.position):
				return "Current native Stalker sample differs from paired saved Hero: " + id
		else:
			if source.get_script() != Echo:
				return "Actual original managed Echo script required: " + id
			error = source.call("source_record_error", actor, player, local.scheduler, packet.playback)
			if not error.is_empty():
				return id + ": " + error
			staged.authored_owner_bindings[id] = source.call("staged_source_binding", actor, player, local.scheduler, packet.playback)
			staged.authored_cycle_playback_ids[id] = packet.playback.playback_id
			echoes.append(id)
	var journal: Variant = local.scheduler.get("authored_source_cycles", {})
	if echoes.is_empty():
		if local.scheduler.get("schema_version") != 1 or not journal.is_empty():
			return "Unentered Echo topology cannot invent managed source history"
	else:
		if local.scheduler.get("schema_version") != 3 or not journal is Dictionary or not journal.get("sources") is Array or journal.sources.size() != echoes.size():
			return "Whole Scheduler3 must retain every entitled managed source"
		for entry: Dictionary in journal.sources:
			if not echoes.has(entry.source_id):
				return "Foreign or unentered managed history is forbidden"
	if is_instance_valid(parent.mechanism):
		if parent.mechanism.get_script() != Mechanism or parent.mechanism.global_transform != Transform3D(Basis.IDENTITY, PULSE_ORIGIN):
			return "Actual fixed original bounded disk mechanism required"
		staged.owner_positions[PULSE_ID] = PULSE_ORIGIN
	error = parent.threat_scheduler.snapshot_error(local.scheduler, staged)
	if not error.is_empty():
		return "Whole native Scheduler preflight: " + error
	if is_instance_valid(parent.mechanism):
		error = parent.mechanism.snapshot_error(local.ring.mechanism, staged, local.scheduler)
		if not error.is_empty():
			return "Bounded native mechanism: " + error
	if paired:
		for id: String in echoes:
			var packet: Dictionary = local.sources[id]
			error = parent.sources[id].call("snapshot_error", packet.playback, parent.threat_scheduler, local.scheduler, staged, {"hero": parent.hero}, staged.floors.values(), echo_context(local.world, parent, id, packet.actor.generation))
			if not error.is_empty():
				return id + ": complete paired Playback preflight: " + error
	return ""


func prepare_sources(local: Dictionary, parent, player: Dictionary) -> String:
	var error: String = record_error(local, parent, player, false)
	if not error.is_empty():
		return error
	# Validate every source before changing ANY immutable Playback recipe.
	for id: String in local.sources:
		if ECHOES.has(id) and (parent.sources[id].call("source_cycles_managed") or not parent.sources[id].call("get_authored_cycle_restore_recipe").is_empty() or parent.sources[id].call("state").get("status") != "idle"):
			return "Prepare only fresh untracked immutable recipients: " + id
	for id: String in local.sources:
		if ECHOES.has(id):
			var packet: Dictionary = local.sources[id]
			if not parent.sources[id].call("prepare_authored_restore", packet.playback, parent.threat_scheduler, {"hero": parent.hero}, parent.scheduler_bindings().floors.values(), echo_context(local.world, parent, id, packet.actor.generation)):
				return id + ": " + String(parent.sources[id].get("source_snapshot_error")) + "; " + String(parent.sources[id].get("last_error"))
	return record_error(local, parent, player, true)


## Caller quietly restores the independently validated actual Hero first.
## No yield/event/admission, and a failed candidate is disposed, never healed.
func restore_local(local: Dictionary, parent, player: Dictionary) -> bool:
	last_error = record_error(local, parent, player)
	if last_error.is_empty() and not _same(player, parent.hero.snapshot_state()):
		last_error = "Restore actual validated Hero before any source/journal commit"
	if not last_error.is_empty():
		return false
	for id: String in local.sources:
		var packet: Dictionary = local.sources[id]
		var accepted: bool = parent.sources[id].call("apply_validated_state", packet.actor) if STALKERS.has(id) else parent.sources[id].call("restore_source_physical", packet.actor, player, local.scheduler, packet.playback)
		if not accepted:
			last_error = "Prevalidated native physical commit changed: " + id
			return false
	var bindings: Dictionary = parent.scheduler_bindings()
	if not parent.threat_scheduler.restore_state(local.scheduler, bindings):
		last_error = "Prevalidated whole Scheduler commit changed: " + parent.threat_scheduler.last_snapshot_error
		return false
	for id: String in local.sources:
		if ECHOES.has(id):
			var packet: Dictionary = local.sources[id]
			if not parent.sources[id].call("restore_state", packet.playback, parent.threat_scheduler, local.scheduler, bindings, {"hero": parent.hero}, bindings.floors.values(), echo_context(local.world, parent, id, packet.actor.generation)) or not parent.sources[id].call("verify_restored_source_phase", packet.actor):
				last_error = "Prevalidated native Playback commit changed: " + id + "; " + String(parent.sources[id].get("last_snapshot_error"))
				return false
	if is_instance_valid(parent.mechanism) and not parent.mechanism.restore_state(local.ring.mechanism, bindings):
		last_error = "Prevalidated native mechanism commit changed: " + parent.mechanism.last_snapshot_error
		return false
	for id: String in local.sources:
		if STALKERS.has(id) and not parent.sources[id].call("refresh_presentation"):
			last_error = "Native Stalker quiet presentation declined: " + id
			return false
	if not _same(parent.threat_scheduler.snapshot_state(bindings), local.scheduler):
		last_error = "Final native whole Scheduler pair differs"
		return false
	last_error = String(parent.call("mirror_sea_codec_apply_owned_state", {"route": local.route.duplicate(true), "ring": local.ring.duplicate(true), "view": local.view.duplicate(true)}))
	return last_error.is_empty()


func progress_error(local: Dictionary, progress: Dictionary, parent) -> String:
	var error: String = Receipt.transport_error(local)
	if error.is_empty():
		error = Receipt.transport_error(progress)
	if not error.is_empty():
		return error
	if not local.get("route") is Dictionary or not local.route.get("entries") is Array or not local.route.get("pending_checkpoint_boundaries") is Array or local.route.pending_checkpoint_boundaries.size() > local.route.entries.size() or local.route.entries.size() > ENTRY_IDS.size() or not local.route.get("deaths") is Dictionary or not local.route.get("exit_state") is String or not local.get("sources") is Dictionary or not local.get("ring") is Dictionary or not local.ring.get("stage") is String or not local.get("scheduler") is Dictionary or not local.scheduler.get("reservations") is Array:
		return "Validate complete local route before progression joins"
	if not Value.keys_error(progress, ["completed", "completion_id", "contact_exit_id", "checkpoint_id", "checkpoint_kind", "checkpoint_ids"]).is_empty() or not progress.get("completed") is bool or not progress.get("checkpoint_ids") is Dictionary:
		return "Closed native CinderLevel progression required"
	for key: String in ["completion_id", "contact_exit_id", "checkpoint_id", "checkpoint_kind"]:
		if not progress.get(key) is String:
			return "Exact progression strings required"
	var complete: bool = _cleared(local)
	if progress.completed != complete or progress.completion_id != (COMPLETION_ID if complete else "") or progress.contact_exit_id != (EXIT_ID if local.route.exit_state == "spent" else ""):
		return "Completion/contact must join all genuine deaths and both real pulses"
	var ids: Variant = parent.call("mirror_sea_codec_checkpoint_ids")
	if not ids is Array or ids.size() != ENTRY_IDS.size():
		return "Explicit canonical parent checkpoint mapping required"
	var seen: Dictionary = {}
	for id: Variant in ids:
		if not Receipt.stable_id(id) or seen.has(id):
			return "Checkpoint identities must be distinct stable existing parent events"
		seen[id] = true
	var acknowledged: int = local.route.entries.size() - local.route.pending_checkpoint_boundaries.size()
	var expected: Array = ids.slice(0, acknowledged)
	if not Value.keys_error(progress.checkpoint_ids, expected).is_empty():
		return "Only genuinely dispatched entry checkpoints may appear in progression"
	for id: String in expected:
		if progress.checkpoint_ids[id] != "encounter":
			return "Spatial checkpoints require genuine encounter boundaries"
	var latest: String = expected[-1] if not expected.is_empty() else ""
	if progress.checkpoint_id != latest or progress.checkpoint_kind != ("encounter" if not latest.is_empty() else ""):
		return "Current protected checkpoint must match the acknowledged entry prefix"
	return ""


func live_presentation_error(parent) -> String:
	var error: String = _access_error(parent)
	if not error.is_empty():
		return error
	var union: Variant = parent.call("mirror_sea_codec_framing_union", null)
	error = _union_error(union)
	if not error.is_empty():
		return error
	return String(parent.shared_shell.call("camera_framing_error", union.points))


## Called ONLY by CinderLevel's Shared34 wrapper, after actual quiet commits.
## This neither translates a fresh Hero nor fits/moves the saved camera.
func candidate_presentation_error(parent, camera: Camera3D, hud: GameHUD) -> String:
	var error: String = _access_error(parent)
	if not error.is_empty():
		return error
	if not is_instance_valid(camera) or not is_instance_valid(hud) or not parent.shared_shell.has_method("camera_framing_error_for_context"):
		return "Actual quiet candidate Camera/native HUD context required"
	var union: Variant = parent.call("mirror_sea_codec_framing_union", camera)
	error = _union_error(union)
	return error if not error.is_empty() else String(parent.shared_shell.call("camera_framing_error_for_context", union.points, parent.hero, camera, hud))


static func native_world(parent) -> Dictionary:
	var bindings: Dictionary = parent.scheduler_bindings()
	var signature: Dictionary = Footprint.floor_signature(bindings.world_root, bindings.floors.values())
	if not signature.get("accepted", false) or not signature.get("signature") is Array or signature.signature.is_empty():
		return {}
	return {"layout_sha256": FileAccess.get_sha256(LAYOUT_PATH), "encounter_id": ENCOUNTER_ID, "world_revision": 1, "profile_id": String(parent.threat_scheduler.encounter_profile().get("id", "")), "collision_fingerprint": parent.threat_scheduler.pure_collision_fingerprint(bindings.world_root), "floor_signature": signature.get("signature", []).duplicate(true)}


static func prepared_world(world: Dictionary) -> Dictionary:
	return {"world_revision": world.world_revision, "collision_fingerprint": world.collision_fingerprint.duplicate(true), "floor_signature": world.floor_signature.duplicate(true)}


static func echo_context(world: Dictionary, parent, id: String, generation: int) -> Dictionary:
	return {"world_root": parent.get_parent() as Node3D, "source_id": id, "source_epoch": source_epoch(id), "generation": generation, "world_collision_fingerprint": world.collision_fingerprint.duplicate(true), "world_floor_signature": world.floor_signature.duplicate(true)}


static func source_epoch(id: String) -> String:
	return "A3-L3/" + id + "/own-sequence"


static func entitled_sources(count: int) -> Array[String]:
	var result: Array[String] = []
	for index: int in range(count):
		for id: String in ENTRY_SOURCES[index]:
			result.append(id)
	return result


static func encode_pulse_exchange(native: Dictionary) -> Dictionary:
	if native.is_empty():
		return {}
	if not native.get("geometry") is Dictionary or native.geometry.get("kind") != "circle" or not native.geometry.get("origin") is Vector3 or not native.get("source_position") is Vector3 or not native.get("opening_position") is Vector3:
		return {}
	# A real public Scheduler reservation has additional live fields. Keep only
	# the native mechanism's closed reduced exchange, never its instance ID or
	# a copied diagnostic armed/state value as historical authority.
	var result: Dictionary = {}
	for key: String in Mechanism.EXCHANGE_KEYS:
		if not native.has(key):
			return {}
		result[key] = native[key]
	result.geometry = {"kind": "circle", "origin": Value.vector3(native.geometry.origin), "radius": native.geometry.radius}
	result.source_position = Value.vector3(native.source_position)
	result.opening_position = Value.vector3(native.opening_position)
	return result


static func decode_pulse_exchange(saved: Dictionary) -> Dictionary:
	if saved.is_empty():
		return {}
	if not Receipt.transport_error(saved).is_empty() or not Value.keys_error(saved, Mechanism.EXCHANGE_KEYS).is_empty() or not saved.get("geometry") is Dictionary or saved.geometry.get("kind") != "circle" or not _vector(saved.geometry.get("origin")) or not _vector(saved.get("source_position")) or not _vector(saved.get("opening_position")):
		return {}
	var result: Dictionary = saved.duplicate(true)
	result.geometry = {"kind": "circle", "origin": Value.read_vector3(saved.geometry.origin), "radius": saved.geometry.radius}
	result.source_position = Value.read_vector3(saved.source_position)
	result.opening_position = Value.read_vector3(saved.opening_position)
	return result


func _route_error(local: Dictionary, parent, player: Dictionary) -> String:
	var route: Dictionary = local.route
	if not Value.keys_error(route, ROUTE_KEYS).is_empty() or not route.get("entries") is Array or route.entries.size() > ENTRY_IDS.size() or not route.get("deaths") is Dictionary or not route.get("pending_checkpoint_boundaries") is Array or route.pending_checkpoint_boundaries.size() > route.entries.size() or not route.get("exit_state") is String or route.exit_state not in ["clear", "available", "active", "spent"] or not route.get("contact") is Dictionary:
		return "Closed bounded ordered route/checkpoint/contact history required"
	var radius: float = _native_radius(parent.hero)
	if radius <= 0.0:
		return "Actual unchanged native Hero capsule dimensions required"
	var prior: float = -1.0
	for index: int in range(route.entries.size()):
		var entry: Variant = route.entries[index]
		if not entry is Dictionary or not Value.keys_error(entry, ["id", "beat", "clock_s", "hero_position", "capsule_radius"]).is_empty() or entry.get("id") != ENTRY_IDS[index] or not entry.get("beat") is int or entry.beat != ENTRY_BEATS[index] or not entry.get("clock_s") is float or not Receipt.clock_valid(entry.clock_s) or entry.clock_s > local.scheduler.clock_s or (index > 0 and entry.clock_s <= prior) or not _vector(entry.get("hero_position")) or not _same(entry.get("capsule_radius"), radius):
			return "Each entry retains one actual canonical capsule crossing/tick"
		var at: Vector3 = Value.read_vector3(entry.hero_position)
		if at.z + radius > ENTRY_Z[index] or not FLOOR_RECT.grow(-radius).has_point(Vector2(at.x, at.z)) or absf(at.y) > 0.2 or (_same(entry.clock_s, local.scheduler.clock_s) and not _same(entry.hero_position, player.motion.position)):
			return "Entry receipt does not retain the actual supported capsule crossing"
		prior = entry.clock_s
	var acknowledged: int = route.entries.size() - route.pending_checkpoint_boundaries.size()
	for index: int in range(route.pending_checkpoint_boundaries.size()):
		if not _same(route.pending_checkpoint_boundaries[index], route.entries[acknowledged + index]):
			return "Pending boundaries must be the exact undelivered suffix, not earned checkpoints"
	# Source/death proof follows the topology check in envelope_error.
	return ""


func _death_error(local: Dictionary) -> String:
	var route: Dictionary = local.route
	for id: Variant in route.deaths:
		if not id is String or not local.sources.has(id):
			return "Only entitled retained owners may have actual deaths"
	for id: String in local.sources:
		var actor: Dictionary = local.sources[id].actor
		var echo: bool = ECHOES.has(id)
		if (echo and not actor.get("alive") is bool) or (not echo and not actor.get("dead") is bool) or not actor.get("hp") is float or not actor.get("max_hp") is float:
			return "Exact native source HP/lifecycle types required: " + id
		var dead: bool = not actor.alive if echo else actor.dead
		if dead != route.deaths.has(id):
			return "Route death history must match exact native source lifecycle: " + id
		if not dead:
			continue
		var death: Variant = route.deaths[id]
		var index: int = _entry_index(id)
		var position: Variant = actor.get("physical", {}).get("position") if echo else actor.get("position")
		if actor.hp != 0.0 or not death is Dictionary or not Value.keys_error(death, ["clock_s", "source_position"]).is_empty() or not death.get("clock_s") is float or not Receipt.clock_valid(death.clock_s) or death.clock_s < local.route.entries[index].clock_s or death.clock_s > local.scheduler.clock_s or not _vector(death.get("source_position")) or not _same(death.source_position, position) or (echo and not _same(death.clock_s, actor.get("defeated_at_s"))):
			return "Death receipt must join its actual lethal clock/frozen physical owner: " + id
	for index: int in range(1, route.entries.size()):
		for id: String in ENTRY_SOURCES[index - 1]:
			if id == PULSE_ID:
				continue
			if not route.deaths.has(id) or route.deaths[id].clock_s > route.entries[index].clock_s:
				return "Later entry cannot precede the previous court's actual defeat"
	return ""


func _ring_error(local: Dictionary, parent) -> String:
	var ring: Dictionary = local.ring
	if not Value.keys_error(ring, RING_KEYS).is_empty() or not ring.get("stage") is String or not ring.get("history") is Array or ring.history.size() > MAX_RING_HISTORY or not ring.get("exchanges") is Dictionary or not ring.get("between_receipt") is Dictionary or not ring.get("mechanism") is Dictionary:
		return "Complete bounded ring/one-Echo-between-pulses history required"
	if local.route.entries.size() < 5:
		return "Unentered resonance cannot invent topology or history" if ring.stage != "uninstalled" or not ring.history.is_empty() or not ring.exchanges.is_empty() or not ring.between_receipt.is_empty() or not ring.mechanism.is_empty() else ""
	if ring.history.is_empty() or ring.mechanism.is_empty() or not ring.mechanism.get("clock_s") is float or not _same(ring.mechanism.clock_s, local.scheduler.clock_s):
		return "Entitled resonance requires its actual native mechanism and outer clock"
	var shape_error: String = _mechanism_shape_error(ring.mechanism, local.world.profile_id)
	if not shape_error.is_empty():
		return shape_error
	var transitions: Dictionary = {"uninstalled": ["pulse1_wait"], "pulse1_wait": ["pulse1"], "pulse1": ["pulse1_wait", "echo_wait"], "echo_wait": ["echo"], "echo": ["echo_wait", "pulse2_wait"], "pulse2_wait": ["pulse2"], "pulse2": ["pulse2_wait", "terminal"], "terminal": []}
	var phase: String = "uninstalled"
	var previous: float = local.route.entries[4].clock_s
	var starts: Dictionary = {}
	var cycles: int = 0
	var terminal_clock: float = -1.0
	for raw: Variant in ring.history:
		if not raw is Dictionary or not Value.keys_error(raw, ["id", "clock_s"]).is_empty() or not raw.get("id") is String or not transitions.get(phase, []).has(raw.id) or not raw.get("clock_s") is float or not Receipt.clock_valid(raw.clock_s) or raw.clock_s < previous or raw.clock_s > local.scheduler.clock_s:
			return "Ring stages must retain the actual finite native transition order"
		phase = raw.id
		previous = raw.clock_s
		if phase in ["pulse1", "pulse2"]:
			cycles += 1
			starts["1" if phase == "pulse1" else "2"] = raw.clock_s
		elif phase == "terminal":
			terminal_clock = raw.clock_s
	if phase != ring.stage or not Value.keys_error(ring.exchanges, starts.keys()).is_empty() or not ring.mechanism.get("cycle") is int or ring.mechanism.cycle != cycles:
		return "Ring current stage/cycle/latest exchanges must join the entire actual start history"
	for label: String in starts:
		var exchange: Variant = ring.exchanges[label]
		var error: String = _pulse_exchange_error(exchange, local.world.profile_id, FIRST_OPENING if label == "1" else (parent.native_definition(RESONANT_ID).slash.world_origin as Vector3))
		if not error.is_empty():
			return error
		if not _same(exchange.start_s, starts[label]):
			return "Each retained pulse exchange keeps its actual latest admission tick"
		if exchange.start_s > local.scheduler.clock_s or int(exchange.id.substr(7)) > local.scheduler.serial:
			return "Retained pulse cannot precede the actual native clock/serial authority"
	if starts.has("2") and ring.exchanges["1"].id == ring.exchanges["2"].id:
		return "Two actual pulse admissions require distinct native reservation identities"
	if cycles == 0:
		if ring.mechanism.status != "idle" or not ring.mechanism.exchange.is_empty():
			return "Unadmitted first pulse cannot invent a native cycle"
	else:
		var label: String = "2" if starts.has("2") else "1"
		if not _same(ring.mechanism.exchange, ring.exchanges[label]):
			return "Actual current native mechanism must retain the latest real pulse exchange"
		if ring.stage in ["pulse1", "pulse2"] and ring.mechanism.status != "running":
			return "A claimed live pulse requires the genuine current native lease"
		if ring.stage in ["echo_wait", "echo"] and ring.mechanism.status != "complete":
			return "The actual Echo interval requires the first completed pulse"
		if ring.stage in ["pulse1_wait", "pulse2_wait"] and ring.mechanism.status == "running":
			return "Waiting cannot hide an actual held pulse"
		if ring.stage == "terminal" and (ring.mechanism.status != "complete" or local.scheduler.clock_s <= ring.exchanges["2"].recovery_until_s):
			return "Terminal resonance requires the second real completed native recovery"
	var needs_between: bool = ring.stage in ["pulse2_wait", "pulse2", "terminal"]
	if needs_between:
		var error: String = Receipt.snapshot_error(ring.between_receipt)
		if not error.is_empty():
			return "Between-pulses original Echo terminal: " + error
		var actor: Dictionary = local.sources[RESONANT_ID].actor
		if not actor.get("lifecycle") is Dictionary or not actor.lifecycle.get("terminal_receipts") is Array or not _contains_exact(actor.lifecycle.terminal_receipts, ring.between_receipt) or ring.between_receipt.source_id != RESONANT_ID or (ring.between_receipt.outcome != "complete" and not (not actor.alive and ring.between_receipt.reason == "authored_source_defeated")) or ring.between_receipt.exchange.start_s <= ring.exchanges["1"].recovery_until_s:
			return "Pulse2 requires one actual complete or ordinary-defeated native Echo between pulses"
		if starts.has("2") and ring.exchanges["2"].start_s < ring.between_receipt.terminal_at_s:
			return "Second pulse cannot precede the real Echo terminal boundary"
	elif not ring.between_receipt.is_empty():
		return "A future second pulse cannot invent Echo terminal authority"
	if local.route.entries.size() == 6 and (ring.stage != "terminal" or terminal_clock > local.route.entries[5].clock_s):
		return "Final court entry must follow the actual two-pulse terminal boundary"
	return ""


func _pulse_exchange_error(exchange: Variant, profile_id: String, opening: Vector3) -> String:
	if not exchange is Dictionary or not Value.keys_error(exchange, Mechanism.EXCHANGE_KEYS).is_empty() or not exchange.get("id") is String or not exchange.id.begins_with("threat-") or not exchange.id.substr(7).is_valid_int() or exchange.id != "threat-%d" % int(exchange.id.substr(7)) or int(exchange.id.substr(7)) < 1 or exchange.get("profile_id") != profile_id or not _same(exchange.get("world_revision"), 1) or not _same(exchange.get("source_position"), Value.vector3(PULSE_ORIGIN)) or not _same(exchange.get("opening_position"), Value.vector3(opening)) or not _same(exchange.get("geometry"), {"kind": "circle", "origin": Value.vector3(PULSE_ORIGIN), "radius": 1.15}):
		return "Each pulse retains the exact original fixed disk/opening/profile/serial"
	var resolved: Dictionary = Difficulty.new().resolve_role(Mechanism.DEFAULT_RAW_ROLE, profile_id, Mechanism.DEFAULT_TIMING_FLOORS)
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not exchange.get(key) is float or not Receipt.clock_valid(exchange[key]):
			return "Pulse copied deadlines retain exact native float types"
	var active: float = exchange.start_s + float(resolved.windup_s)
	var expected: Dictionary = {"lock_from_s": active - float(resolved.lock_s), "active_from_s": active, "active_until_s": active + float(resolved.active_s), "recovery_until_s": active + float(resolved.active_s) + float(resolved.recovery_s), "cooldown_until_s": active + float(resolved.attack_interval_s)}
	for key: String in expected:
		if not _same(exchange[key], expected[key]):
			return "Pulse deadlines must derive exactly once from the immutable native role"
	return ""


func _view_error(local: Dictionary) -> String:
	if not Value.keys_error(local.view, ["echoes", "pulse"]).is_empty() or not local.view.get("echoes") is Dictionary or not local.view.get("pulse") is Array:
		return "Closed native view-only path positions required"
	var ids: Array[String] = []
	for id: String in local.sources:
		if ECHOES.has(id):
			ids.append(id)
	if not Value.keys_error(local.view.echoes, ids).is_empty():
		return "View state cannot omit or invent an entitled native Echo"
	for id: String in ids:
		var points: Variant = local.view.echoes[id]
		var ready: bool = local.sources[id].playback.get("status") == "cycle_ready"
		var error: String = _positions_error(points)
		if not error.is_empty() or (ready and not points.is_empty()) or (not ready and points.is_empty()):
			return "Native selected path belongs to its actual admitted generation: " + id + "; " + error
	var error: String = _positions_error(local.view.pulse)
	if not error.is_empty() or (local.ring.exchanges.is_empty() != local.view.pulse.is_empty()):
		return "Native pulse view must retain its actual selected response path; " + error
	var cleared: bool = _cleared(local)
	if not cleared and (local.route.exit_state != "clear" or not local.route.contact.is_empty()):
		return "Contact exit cannot precede all seven real defeats and both pulses"
	if cleared and local.route.exit_state == "clear":
		return "Completed quiet route must expose its genuine contact-only exit"
	return ""


func _contact_error(local: Dictionary, parent, player: Dictionary) -> String:
	var contact: Dictionary = local.route.contact
	if local.route.exit_state not in ["active", "spent"]:
		return "Unused exit cannot retain contact" if not contact.is_empty() else ""
	var radius: float = _native_radius(parent.hero)
	if not Value.keys_error(contact, ["clock_s", "hero_position"]).is_empty() or not contact.get("clock_s") is float or not Receipt.clock_valid(contact.clock_s) or contact.clock_s > local.scheduler.clock_s or not _vector(contact.get("hero_position")):
		return "Actual bounded native capsule contact receipt required"
	var at: Vector3 = Value.read_vector3(contact.hero_position)
	if not EXIT_RECT.grow(-radius).has_point(Vector2(at.x, at.z)) or absf(at.y) > 0.2 or (_same(contact.clock_s, local.scheduler.clock_s) and not _same(contact.hero_position, player.motion.position)):
		return "Contact receipt must retain the actual supported Hero capsule crossing"
	for death: Dictionary in local.route.deaths.values():
		if contact.clock_s < death.clock_s:
			return "Contact cannot precede the final genuine defeat"
	for stage: Dictionary in local.ring.history:
		if stage.id == "terminal" and contact.clock_s < stage.clock_s:
			return "Contact cannot precede the second genuine completed pulse"
	return ""


static func _stalker_shape_error(actor: Dictionary, id: String) -> String:
	if not Value.keys_error(actor, Stalker.SNAPSHOT_KEYS).is_empty() or actor.get("stable_id") != id or actor.get("api_revision") != Stalker.API_REVISION or not actor.get("schema_version") is int or actor.schema_version != 3 or not actor.get("cycle") is int or not actor.get("previous") is Dictionary or not Value.keys_error(actor.previous, ["clock_s", "source_position", "hero_position"]).is_empty():
		return "Owned closed native Stalker3 identity/fields required: " + id
	for key: String in ["clock_s", "cooldown_until_s", "retry_at_s", "stagger_until_s"]:
		if not actor.get(key) is float or not Receipt.clock_valid(actor[key]):
			return "Stalker copied clocks retain exact native float types: " + id
	for key: String in ["position", "velocity", "facing"]:
		if not _vector(actor.get(key)):
			return "Stalker native body Vector3 transport required: " + id
	if not actor.previous.get("clock_s") is float or not Receipt.clock_valid(actor.previous.clock_s) or not _vector(actor.previous.get("source_position")) or not _vector(actor.previous.get("hero_position")) or not actor.get("exchange") is Dictionary:
		return "Stalker current sample retains exact native types: " + id
	if not actor.exchange.is_empty():
		for key: String in Stalker.EXCHANGE_KEYS:
			if not actor.exchange.get(key) is float or not Receipt.clock_valid(actor.exchange[key]):
				return "Stalker retained deadlines preserve native float types: " + id
	return ""


static func _mechanism_shape_error(saved: Dictionary, profile_id: String) -> String:
	var keys: Array[String] = ["api_revision", "schema_version", "mechanism_id", "configuration", "status", "phase", "cycle", "clock_s", "resolved_role", "exchange_encounter_id", "exchange", "hero_samples", "hit_ids", "last_cancel_reason"]
	if saved.get("schema_version") == 2:
		keys.append("pending_segments")
	if not Value.keys_error(saved, keys).is_empty() or saved.get("api_revision") != Mechanism.API_REVISION or saved.get("mechanism_id") != PULSE_ID or not saved.get("schema_version") is int or not Value.is_integer(saved.schema_version, 1, 2) or not saved.get("cycle") is int or saved.cycle < 0 or not saved.get("status") is String or saved.status not in ["idle", "running", "cancelled", "complete"] or not saved.get("phase") is String or not saved.get("exchange") is Dictionary or not saved.get("resolved_role") is Dictionary or not saved.get("hero_samples") is Dictionary or not saved.get("hit_ids") is Array or not saved.get("exchange_encounter_id") is String or not saved.get("last_cancel_reason") is String:
		return "Closed actual native bounded mechanism schema/types required"
	var expected: Dictionary = {"mechanism_id": PULSE_ID, "geometry": {"kind": "circle", "origin": Value.vector3(PULSE_ORIGIN), "radius": 1.15}, "opening_position": Value.vector3(FIRST_OPENING), "raw_role": Mechanism.DEFAULT_RAW_ROLE, "timing_floors": Mechanism.DEFAULT_TIMING_FLOORS}
	if not _same(saved.get("configuration"), expected):
		return "Mechanism immutable filled-disk/raw-role configuration differs"
	if saved.status != "idle" and (saved.exchange_encounter_id != ENCOUNTER_ID or not _same(saved.resolved_role, Difficulty.new().resolve_role(Mechanism.DEFAULT_RAW_ROLE, profile_id, Mechanism.DEFAULT_TIMING_FLOORS))):
		return "Executed mechanism retains its exact native role/encounter"
	return ""


func _positions_error(points: Variant) -> String:
	if not points is Array or points.size() > MAX_VIEW_POSITIONS:
		return "Finite full selected native response positions required"
	var seen: Array = []
	for point: Variant in points:
		if not _vector(point) or seen.has(point):
			return "Exact unique native world Vector3 transport required"
		var at: Vector3 = Value.read_vector3(point)
		if not FLOOR_RECT.grow(-0.33).has_point(Vector2(at.x, at.z)) or absf(at.y) > 0.05:
			return "Selected view path must retain permanent dry support"
		seen.append(point)
	return ""


func _access_error(parent) -> String:
	if typeof(parent) != TYPE_OBJECT or not is_instance_valid(parent) or not parent is CinderLevel or parent.get_script() == null or parent.get_script().resource_path != PARENT_PATH or not parent.is_inside_tree() or not parent.is_node_ready() or parent.is_queued_for_deletion() or not parent.get_tree().paused:
		return "Actual ready owned parent at deferred paused whole-unit barrier required"
	for method: String in REQUIRED_HOOKS:
		if not parent.has_method(method):
			return "Required explicit parent integration hook: " + method
	if not is_instance_valid(parent.hero) or not is_instance_valid(parent.shared_shell) or not is_instance_valid(parent.threat_scheduler):
		return "Actual shared Hero/Shell/Scheduler bindings required"
	return String(parent.runtime_error())


static func _union_error(union: Variant) -> String:
	if not union is Dictionary or not Value.keys_error(union, ["error", "points"]).is_empty() or not union.get("error") is String or not union.get("points") is Array:
		return "Complete actual native current-court render union required"
	if not union.error.is_empty():
		return union.error
	if union.points.is_empty() or union.points.size() > 224:
		return "Native render union must preserve complete bounded required groups"
	for point: Variant in union.points:
		if not point is Vector3 or not point.is_finite():
			return "Actual native render corners required, no transport/proxy stamp"
	return ""


static func _native_radius(hero: CinderPlayer) -> float:
	var body: CollisionShape3D = hero.get_node_or_null("BodyCollision") as CollisionShape3D
	return (body.shape as CapsuleShape3D).radius if body != null and body.shape is CapsuleShape3D and body.basis == Basis.IDENTITY else -1.0


static func _entry_index(id: String) -> int:
	for index: int in range(ENTRY_SOURCES.size()):
		if ENTRY_SOURCES[index].has(id):
			return index
	return -1


static func _cleared(local: Dictionary) -> bool:
	if local.route.entries.size() != 6 or local.route.deaths.size() != 7 or local.ring.stage != "terminal" or not local.scheduler.reservations.is_empty():
		return false
	for id: String in STALKERS + ECHOES:
		var packet: Variant = local.sources.get(id)
		if not packet is Dictionary or not packet.get("actor") is Dictionary or not _same(packet.actor.get("hp"), 0.0):
			return false
		if STALKERS.has(id):
			if not _same(packet.actor.get("dead"), true):
				return false
		else:
			if not _same(packet.actor.get("alive"), false) or not packet.get("playback") is Dictionary or packet.playback.has("pending_delivery") or not packet.playback.get("lifecycle") is Dictionary or not packet.playback.lifecycle.get("terminal_receipts") is Array or packet.playback.lifecycle.terminal_receipts.is_empty():
				return false
	return true


static func _vector(value: Variant) -> bool:
	return value is Array and value.size() == 3 and value[0] is float and value[1] is float and value[2] is float and Value.is_vector3(value)


static func _same(left: Variant, right: Variant) -> bool:
	return Exact.exact_equal(left, right)


static func _contains_exact(values: Array, expected: Variant) -> bool:
	for value: Variant in values:
		if _same(value, expected):
			return true
	return false
