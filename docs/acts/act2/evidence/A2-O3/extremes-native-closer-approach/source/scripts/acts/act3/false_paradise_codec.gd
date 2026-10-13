extends RefCounted
## Complete whole A3-L4 codec source; focused native qualification pending.
## Published with complete parent/core hooks; no partial/filtered Scheduler writer.

const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/combat/authored_enemy_sequence.gd")
const Receipt = preload("res://scripts/combat/authored_echo_terminal_receipt.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Stalker = preload("res://scripts/acts/act3/sunbound_stalker.gd")
const RootLeaf = preload("res://scripts/acts/act3/root_latcher.gd")
const GardenRoot = preload("res://scripts/acts/act3/garden_root_latcher.gd")
const Echo = preload("res://scripts/acts/act3/mirror_echo.gd")
const Core = preload("res://scripts/acts/act3/garden_root_network.gd")
const API: String = "act3-false-paradise-snapshot-1"
const PARENT_PATH: String = "res://scripts/acts/act3/false_paradise_level.gd"
const LAYOUT_PATH: String = "res://data/campaign/act3/false_paradise_layout_candidate.json"
const ENCOUNTER: String = "A3-L4/false-paradise-garden"
const FLOOR: Rect2 = Rect2(-7, -14, 14, 78)
const EXIT_RECT: Rect2 = Rect2(-1.2, -8.65, 2.4, 1.3)
const EXIT_ID: String = "adage-plain-threshold"
const COMPLETE_ID: String = "false-paradise-disengaged"
const STALKER_ID: String = "l4-rest-stalker"
const ECHO_ID: String = "l4-plain-echo"
const HELPER_ID: String = "l4-garden-helper"
const ENTRY_IDS: Array[String] = ["offered-rest", "beauty-source", "plain-path", "root-court", "garden-release"]
const ENTRY_Z: Array[float] = [60.0, 42.0, 24.0, 7.0]
const CHECKPOINTS: Array[String] = ["garden-rest-entry", "garden-beauty-entry", "garden-plain-path-entry", "garden-boss-court-entry", "garden-phase2-entry"]
const ENTRY_SOURCES: Array = [[STALKER_ID], ["l4-beauty-root"], [ECHO_ID, "l4-plain-root"], [], [HELPER_ID]]
const ROOT_IDS: Array[String] = ["l4-beauty-root", "l4-plain-root", HELPER_ID]
const KEYS: Array[String] = ["api_revision", "schema_version", "world", "scheduler", "sources", "core", "route", "sun", "presentation", "view"]
const WORLD_KEYS: Array[String] = ["layout_sha256", "encounter_id", "world_revision", "profile_id", "collision_fingerprint", "floor_signature"]
const ROUTE_KEYS: Array[String] = ["entries", "deaths", "pending_checkpoint_boundaries", "retired_sources", "disengaged", "disengagement_pending", "exit_state", "contact"]
const SUN_KEYS: Array[String] = ["started", "anchor_s", "cycle", "elapsed_s", "stage", "effective_index", "incoming_index"]
const HOOKS: Array[String] = ["false_paradise_codec_owned_state", "false_paradise_codec_boundary_error", "false_paradise_codec_apply_owned_state", "false_paradise_codec_construct_recipe", "false_paradise_codec_framing_union"]
var last_error: String = ""


func capture(parent, player: Dictionary, camera: Camera3D = null, hud: GameHUD = null) -> Dictionary:
	last_error = _access_error(parent)
	if last_error.is_empty(): last_error = parent.hero.snapshot_error(player)
	if last_error.is_empty() and not _same(player, parent.hero.snapshot_state()): last_error = "Capture requires the actual current native Hero unit"
	if last_error.is_empty() and (camera == null) != (hud == null): last_error = "Complete actual Camera/HUD capture context required"
	if last_error.is_empty(): last_error = live_presentation_error(parent) if camera == null else candidate_presentation_error(parent, camera, hud)
	if not last_error.is_empty(): return {}
	var owned: Variant = parent.call("false_paradise_codec_owned_state")
	last_error = Receipt.transport_error(owned)
	if last_error.is_empty() and (not owned is Dictionary or not Value.keys_error(owned, ["route", "sun", "presentation", "view"]).is_empty()): last_error = "Closed transport-only parent custody required"
	if not last_error.is_empty(): return {}
	var bindings: Dictionary = parent.scheduler_bindings()
	var scheduler: Dictionary = parent.threat_scheduler.snapshot_state(bindings)
	if scheduler.is_empty():
		last_error = parent.threat_scheduler.last_snapshot_error
		return {}
	var packets: Dictionary = {}
	for id: String in parent.sources:
		var source: Node3D = parent.sources[id]
		if id == STALKER_ID:
			var actor: Dictionary = source.call("snapshot_state")
			if actor.is_empty(): return _capture_failed(id + ": " + String(source.get("last_snapshot_error")))
			packets[id] = {"kind": "stalker", "actor": actor}
		elif ROOT_IDS.has(id):
			var actor: Dictionary = source.call("snapshot_state", bindings)
			if actor.is_empty(): return _capture_failed(id + ": " + String(source.get("last_snapshot_error")))
			packets[id] = {"kind": "root", "actor": actor}
		elif id == ECHO_ID:
			var playback: Dictionary = source.call("snapshot_state", scheduler, bindings)
			var actor: Dictionary = source.call("capture_source", player, scheduler, playback)
			if playback.is_empty() or actor.is_empty(): return _capture_failed(id + ": " + String(source.get("source_snapshot_error")) + "; " + String(source.get("last_snapshot_error")))
			packets[id] = {"kind": "echo", "actor": actor, "playback": playback}
		else:
			return _capture_failed("Unknown retained source cannot be omitted: " + id)
	var core: Dictionary = parent.root_network.call("capture", bindings, scheduler) if is_instance_valid(parent.root_network) else {}
	if is_instance_valid(parent.root_network) and core.is_empty(): return _capture_failed(String(parent.root_network.get("last_snapshot_error")))
	var unit: Dictionary = {"api_revision": API, "schema_version": 1, "world": native_world(parent), "scheduler": scheduler, "sources": packets, "core": core, "route": owned.route.duplicate(true), "sun": owned.sun.duplicate(true), "presentation": owned.presentation.duplicate(true), "view": owned.view.duplicate(true)}
	last_error = record_error(unit, parent, player)
	return unit.duplicate(true) if last_error.is_empty() else {}


func _capture_failed(error: String) -> Dictionary:
	last_error = error
	return {}


## Pure declared immutable topology only. No saved HP/pose/phase/history is a
## constructor argument. Native whole preflight follows actual inert construction.
func constructor_recipe(unit: Dictionary, parent, player: Dictionary) -> Dictionary:
	var error: String = envelope_error(unit, parent, player)
	if not error.is_empty(): return {"accepted": false, "error": error}
	return {"accepted": true, "error": "", "recipe": {"api_revision": "act3-false-paradise-constructor-1", "profile_id": unit.world.profile_id, "source_ids": entitled_sources(unit.route.entries.size()), "core_entitled": unit.route.entries.size() >= 4, "world": unit.world.duplicate(true)}}


func envelope_error(unit: Dictionary, parent, player: Dictionary) -> String:
	var error: String = _access_error(parent)
	if error.is_empty(): error = Receipt.transport_error(unit)
	if error.is_empty(): error = Receipt.transport_error(player)
	if error.is_empty(): error = parent.hero.snapshot_error(player)
	if error.is_empty(): error = _hero_native_vector_error(player)
	if not error.is_empty(): return error
	if not Value.keys_error(unit, KEYS).is_empty() or unit.get("api_revision") != API or not unit.get("schema_version") is int or unit.schema_version != 1: return "Closed False Paradise whole local1 required"
	for key: String in ["world", "scheduler", "sources", "core", "route", "sun", "presentation", "view"]:
		if not unit[key] is Dictionary: return "Complete typed parent unit required: " + key
	var scheduler: Dictionary = unit.scheduler
	if not Receipt.clock_valid(scheduler.get("clock_s")) or not scheduler.get("schema_version") is int or not scheduler.get("serial") is int or scheduler.serial < 0 or not scheduler.get("reservations") is Array or not scheduler.get("cooldowns") is Array or not player.get("world_actions") is Dictionary or not _same(player.world_actions.get("clock_s"), scheduler.clock_s): return "Native Hero and whole Scheduler require one exact outer tick"
	if not Value.keys_error(unit.world, WORLD_KEYS).is_empty() or unit.world.get("layout_sha256") != FileAccess.get_sha256(LAYOUT_PATH) or unit.world.get("encounter_id") != ENCOUNTER or not _same(unit.world.get("world_revision"), 1) or not unit.world.get("profile_id") is String or not unit.world.get("collision_fingerprint") is Dictionary or not unit.world.get("floor_signature") is Array: return "Exact immutable full garden world/layout/profile required"
	var profile: Dictionary = Difficulty.new().profile(unit.world.profile_id)
	if profile.is_empty() or not _same(profile, scheduler.get("profile")) or scheduler.get("encounter_id") != ENCOUNTER or not _same(scheduler.get("world_revision"), 1) or not _same(scheduler.get("collision"), unit.world.collision_fingerprint): return "World/profile joins the one complete native Scheduler"
	var actual: Dictionary = native_world(parent)
	if actual.is_empty(): return "Actual original complete garden floor unavailable"
	for key: String in ["layout_sha256", "encounter_id", "world_revision", "collision_fingerprint", "floor_signature"]:
		if not _same(unit.world[key], actual.get(key)): return "Original native world differs: " + key
	error = _route_shape_error(unit, parent, player)
	if not error.is_empty(): return error
	var ids: Array[String] = entitled_sources(unit.route.entries.size())
	if not Value.keys_error(unit.sources, ids).is_empty(): return "Every and only the earned prefix's retained actual source is required"
	for id: String in ids:
		var packet: Variant = unit.sources[id]
		var kind: String = source_kind(id)
		if not packet is Dictionary or not Value.keys_error(packet, ["kind", "actor", "playback"] if kind == "echo" else ["kind", "actor"]).is_empty() or packet.get("kind") != kind or not packet.get("actor") is Dictionary or (kind == "echo" and not packet.get("playback") is Dictionary): return "Exact typed native source packet required: " + id
		if not Receipt.clock_valid(packet.actor.get("clock_s")) or not _same(packet.actor.clock_s, scheduler.clock_s): return "Source clock differs from the whole pair: " + id
		if kind == "echo":
			var actor: Dictionary = packet.actor
			if actor.get("api_revision") != "act3-mirror-echo-source-2" or not _same(actor.get("schema_version"), 2) or actor.get("source_id") != id or actor.get("source_epoch") != source_epoch(id) or not actor.get("generation") is int or not Value.is_integer(actor.generation, 1, 64) or not actor.get("sequence") is Dictionary or not actor.get("physical") is Dictionary: return "Original managed own-sequence source2 and typed physical packet required"
			var reader := Exact.new()
			if not reader.restore_state(actor.sequence, source_epoch(id), actor.generation): return reader.last_snapshot_error
			error = reader.binding_error(actor.sequence, id, source_epoch(id), actor.generation, unit.world.profile_id, parent.native_definition(id), prepared_world(unit.world))
			if not error.is_empty(): return error
		else:
			var actor: Dictionary = packet.actor
			var keys: Array = Stalker.SNAPSHOT_KEYS if kind == "stalker" else RootLeaf.SNAPSHOT_KEYS
			if not Value.keys_error(actor, keys).is_empty() or actor.get("stable_id") != id or not _same(actor.get("schema_version"), 3 if kind == "stalker" else 2) or not _vector(actor.get("position")): return "Closed actual source identity/types required: " + id
			if kind == "root" and (not actor.get("mechanism") is Dictionary or not _same(actor.position, fixed_position(id)) or not actor.get("collision") is Dictionary or not actor.collision.get("layer") is int or not actor.collision.get("mask") is int): return "Original fixed Root Latcher position/mechanism/body types required: " + id
			if kind == "root":
				error = _mechanism_types(actor.mechanism)
				if not error.is_empty(): return id + ": " + error
			if kind == "stalker" and (not actor.get("cycle") is int or not _vector(actor.get("velocity")) or not actor.get("reservation_id") is String or not actor.get("previous") is Dictionary or not Value.keys_error(actor.previous, ["clock_s", "source_position", "hero_position"]).is_empty() or not Receipt.clock_valid(actor.previous.get("clock_s")) or not _vector(actor.previous.get("source_position")) or not _vector(actor.previous.get("hero_position"))): return "Exact typed native Stalker motion/sample required before staging"
			if kind == "stalker" and (not actor.get("commit") is Dictionary or (not actor.commit.is_empty() and not _same(actor.commit.get("sun_choice"), 0))): return "Original rest Stalker retains only its actual fixed Sun0 admission"
	if (unit.route.entries.size() >= 4) != (not unit.core.is_empty()): return "Core entitlement must match the fourth genuine court entry"
	if not unit.core.is_empty():
		if not Value.keys_error(unit.core, Core.UNIT_KEYS).is_empty() or unit.core.get("api_revision") != "act3-garden-root-network-2" or not _same(unit.core.get("schema_version"), 2) or not unit.core.get("tether") is Dictionary or not unit.core.get("mechanisms") is Dictionary or not unit.core.get("control") is Dictionary or not Value.keys_error(unit.core.mechanisms, ["draw", "enclose"]).is_empty(): return "Original complete API2 root core/recovery history required"
		if not Receipt.clock_valid(unit.core.tether.get("clock_s")) or not _same(unit.core.tether.clock_s, scheduler.clock_s): return "Tether and whole Scheduler clocks differ"
		for kind: String in ["draw", "enclose"]:
			if not unit.core.mechanisms[kind] is Dictionary or not _same(unit.core.mechanisms[kind].get("clock_s"), scheduler.clock_s): return "Both root mechanism clocks join the whole pair"
			error = _mechanism_types(unit.core.mechanisms[kind])
			if not error.is_empty(): return kind + ": " + error
		if not _same(unit.core.tether.get("schema_version"), 1) or not unit.core.tether.get("collision") is Dictionary or not unit.core.tether.collision.get("layer") is int or not unit.core.tether.collision.get("mask") is int: return "Original native tether/body counter types required"
	error = _death_and_entry_error(unit)
	if error.is_empty(): error = _root_sun_error(unit)
	if error.is_empty(): error = _retirement_error(unit)
	if error.is_empty(): error = _view_error(unit, parent)
	if error.is_empty(): error = _contact_error(unit, parent, player)
	if error.is_empty(): error = String(parent.scenery.call("presentation_error", unit.presentation, unit.route.entries.size() >= 4, unit.route.disengaged and not unit.route.disengagement_pending))
	return error


## paired=false is ONLY immutable fresh preflight before public Playback recipe
## preparation. Full Scheduler validation is performed on BOTH paths.
func record_error(unit: Dictionary, parent, player: Dictionary, paired: bool = true) -> String:
	var error: String = envelope_error(unit, parent, player)
	if not error.is_empty(): return error
	if not _same(unit.world.profile_id, parent.threat_scheduler.encounter_profile().get("id")) or not Value.keys_error(parent.sources, unit.sources.keys()).is_empty() or is_instance_valid(parent.root_network) != (not unit.core.is_empty()): return "Actual native recipient topology/profile must equal immutable entitlement"
	var staged: Dictionary = _staged_bindings(unit, parent, player)
	for id: String in unit.sources:
		var source: Node3D = parent.sources[id]
		var packet: Dictionary = unit.sources[id]
		if id == STALKER_ID:
			if source.get_script() != Stalker: return "Actual original Stalker script required"
			error = source.call("snapshot_error", packet.actor, unit.scheduler)
			if error.is_empty() and _same(packet.actor.previous.clock_s, unit.scheduler.clock_s) and not _same(packet.actor.previous.hero_position, player.motion.position): error = "Current Stalker sample differs from the saved Hero"
		elif ROOT_IDS.has(id):
			if source.get_script() != GardenRoot: return "Actual additive garden Root Latcher script required"
			continue # Native Lane proof needs ALL staged authored bindings first.
		else:
			if source.get_script() != Echo: return "Actual original managed Echo script required"
			error = source.call("source_record_error", packet.actor, player, unit.scheduler, packet.playback)
			if error.is_empty():
				staged.authored_owner_bindings[id] = source.call("staged_source_binding", packet.actor, player, unit.scheduler, packet.playback)
				staged.authored_cycle_playback_ids[id] = packet.playback.get("playback_id", "")
		if not error.is_empty(): return id + ": " + error
	var journal: Variant = unit.scheduler.get("authored_source_cycles", {})
	if not journal is Dictionary: return "Whole managed journal must be a closed native Dictionary"
	if unit.sources.has(ECHO_ID):
		if unit.scheduler.schema_version != 3 or not journal is Dictionary or not journal.get("sources") is Array or journal.sources.size() != 1 or not journal.sources[0] is Dictionary or journal.sources[0].get("source_id") != ECHO_ID: return "Exactly the entitled one retained native Echo journal requires Scheduler3"
	elif unit.scheduler.schema_version != 1 or not journal.is_empty(): return "No unentered managed journal may be fabricated"
	error = parent.threat_scheduler.snapshot_error(unit.scheduler, staged)
	if not error.is_empty(): return "Whole native Scheduler preflight: " + error
	for id: String in ROOT_IDS:
		if unit.sources.has(id):
			error = parent.sources[id].call("snapshot_error", unit.sources[id].actor, staged, unit.scheduler)
			if not error.is_empty(): return id + ": complete native Root preflight: " + error
	if not unit.core.is_empty():
		if parent.root_network.get_script() != Core: return "Actual API2 native root core script required"
		error = parent.root_network.call("snapshot_error", unit.core, player, staged, unit.scheduler)
		if not error.is_empty(): return "Complete root core: " + error
	if paired and unit.sources.has(ECHO_ID):
		var packet: Dictionary = unit.sources[ECHO_ID]
		error = parent.sources[ECHO_ID].call("snapshot_error", packet.playback, parent.threat_scheduler, unit.scheduler, staged, {"hero": parent.hero}, staged.floors.values(), echo_context(unit.world, parent, packet.actor.generation))
		if not error.is_empty(): return "Complete native Playback preflight: " + error
	return ""


func _mechanism_types(packet: Dictionary) -> String:
	var keys: Array = ["api_revision", "schema_version", "mechanism_id", "configuration", "status", "phase", "cycle", "clock_s", "resolved_role", "exchange_encounter_id", "exchange", "hero_samples", "hit_ids", "last_cancel_reason"]
	if packet.get("schema_version") == 2: keys.append("pending_segments")
	if not Value.keys_error(packet, keys).is_empty() or not packet.get("schema_version") is int or not Value.is_integer(packet.schema_version, 1, 2) or not packet.get("cycle") is int or not Receipt.clock_valid(packet.get("clock_s")) or not packet.get("configuration") is Dictionary or not packet.get("exchange") is Dictionary or not packet.get("resolved_role") is Dictionary or not packet.get("hero_samples") is Dictionary or not packet.get("hit_ids") is Array: return "Exact native Lane snapshot/counter/container types required before staging"
	var exchange: Dictionary = packet.exchange
	if not exchange.is_empty():
		if not exchange.get("world_revision") is int or not _vector(exchange.get("source_position")) or not _vector(exchange.get("opening_position")) or not exchange.get("geometry") is Dictionary: return "Native consumed exchange vector/world types required"
		for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
			if not Receipt.clock_valid(exchange.get(key)): return "Native consumed deadlines preserve exact float types"
	return ""


func _staged_bindings(unit: Dictionary, parent, player: Dictionary) -> Dictionary:
	var bindings: Dictionary = parent.scheduler_bindings()
	bindings["hero_positions"] = {"hero": Value.read_vector3(player.motion.position)}
	bindings["owner_positions"] = {}
	bindings["owner_velocities"] = {}
	bindings["owner_collision_states"] = {}
	bindings["authored_owner_bindings"] = {}
	bindings["authored_cycle_playback_ids"] = {}
	for id: String in unit.sources:
		var actor: Dictionary = unit.sources[id].actor
		if id == STALKER_ID:
			bindings.owner_positions[id] = Value.read_vector3(actor.position)
			bindings.owner_velocities[id] = Value.read_vector3(actor.velocity)
			if not actor.dead and not String(actor.reservation_id).is_empty(): bindings.owner_collision_states[id] = {"collision_path": "BodyCollision", "enabled": true, "layer": 2, "mask": 1}
		elif ROOT_IDS.has(id):
			bindings.owner_positions[id + "/attack"] = Value.read_vector3(actor.position)
	if not unit.core.is_empty():
		bindings.owner_positions["l4-garden-draw"] = Vector3(-1, 0, 1.25)
		bindings.owner_positions["l4-garden-enclose"] = Vector3.ZERO
	return bindings


func prepare_sources(unit: Dictionary, parent, player: Dictionary) -> String:
	var error: String = record_error(unit, parent, player, false)
	if not error.is_empty(): return error
	if unit.sources.has(ECHO_ID):
		var source: Node3D = parent.sources[ECHO_ID]
		if source.call("source_cycles_managed") or not (source.call("get_authored_cycle_restore_recipe") as Dictionary).is_empty() or source.call("state").get("status", "idle") != "idle": return "Prepare only fresh configured untracked actual Echo recipient"
		var packet: Dictionary = unit.sources[ECHO_ID]
		if not source.call("prepare_authored_restore", packet.playback, parent.threat_scheduler, {"hero": parent.hero}, parent.scheduler_bindings().floors.values(), echo_context(unit.world, parent, packet.actor.generation)): return String(source.get("source_snapshot_error")) + "; " + String(source.get("last_error"))
	return record_error(unit, parent, player, true)


## Caller has already validated the WHOLE packet and quietly restored the actual
## Hero. No Hero writes here. Commit failure requires whole candidate disposal.
func restore_local(unit: Dictionary, parent, player: Dictionary) -> bool:
	last_error = _access_error(parent)
	if last_error.is_empty() and not parent.is_restore_candidate(): last_error = "Whole local commit requires the genuine fresh paused CinderLevel restore candidate"
	if not last_error.is_empty(): return false
	last_error = record_error(unit, parent, player)
	if last_error.is_empty() and not _same(player, parent.hero.snapshot_state()): last_error = "Actual native Hero must be quietly restored before owned physical commit"
	if not last_error.is_empty(): return false
	var staged: Dictionary = _staged_bindings(unit, parent, player)
	if unit.sources.has(ECHO_ID):
		var packet: Dictionary = unit.sources[ECHO_ID]
		staged.authored_owner_bindings[ECHO_ID] = parent.sources[ECHO_ID].call("staged_source_binding", packet.actor, player, unit.scheduler, packet.playback)
		staged.authored_cycle_playback_ids[ECHO_ID] = packet.playback.playback_id
	if not unit.core.is_empty() and not parent.root_network.call("stage_quiet_restore", unit.core, player, staged, unit.scheduler): return _restore_failed("Prevalidated root stage changed: " + String(parent.root_network.get("last_snapshot_error")))
	for id: String in unit.sources:
		var packet: Dictionary = unit.sources[id]
		var ok: bool = parent.sources[id].call("restore_source_physical", packet.actor, player, unit.scheduler, packet.playback) if id == ECHO_ID else parent.sources[id].call("apply_validated_state", packet.actor)
		if not ok: return _restore_failed("Prevalidated native physical commit changed: " + id)
	if not unit.core.is_empty() and not parent.root_network.call("apply_staged_target"): return _restore_failed("Prevalidated actual tether physical commit changed")
	var bindings: Dictionary = parent.scheduler_bindings() # ACTUAL restored bodies; no staged collision/pose stamps.
	if not parent.threat_scheduler.restore_state(unit.scheduler, bindings): return _restore_failed("Whole Scheduler commit changed: " + parent.threat_scheduler.last_snapshot_error)
	if unit.sources.has(ECHO_ID):
		var packet: Dictionary = unit.sources[ECHO_ID]
		var source: Node3D = parent.sources[ECHO_ID]
		if not source.call("restore_state", packet.playback, parent.threat_scheduler, unit.scheduler, bindings, {"hero": parent.hero}, bindings.floors.values(), echo_context(unit.world, parent, packet.actor.generation)) or not source.call("verify_restored_source_phase", packet.actor): return _restore_failed("Prevalidated actual Playback commit changed: " + String(source.get("last_snapshot_error")))
	# Every managed Playback finishes before ANY native Lane restore takes its
	# independent ordinary whole-Scheduler capture. No special capture bypass.
	for id: String in ROOT_IDS:
		if unit.sources.has(id) and not parent.sources[id].call("restore_mechanism_state", unit.sources[id].actor, bindings): return _restore_failed("Prevalidated actual Root mechanism commit changed: " + id)
	if not unit.core.is_empty():
		if not parent.root_network.call("restore_staged_mechanisms") or not parent.root_network.call("finish_staged_restore"): return _restore_failed("Prevalidated root mechanism/control/palette commit changed: " + String(parent.root_network.get("last_snapshot_error")))
	if unit.sources.has(STALKER_ID) and not parent.sources[STALKER_ID].call("refresh_presentation"): return _restore_failed("Native Stalker quiet appearance changed")
	last_error = String(parent.call("false_paradise_codec_apply_owned_state", {"route": unit.route.duplicate(true), "sun": unit.sun.duplicate(true), "presentation": unit.presentation.duplicate(true), "view": unit.view.duplicate(true)}))
	if not last_error.is_empty(): return false
	if not _same(parent.threat_scheduler.snapshot_state(bindings), unit.scheduler): return _restore_failed("Independent full native Scheduler recapture differs")
	# The Shell's actual Camera/HUD gate runs AFTER local+base progression commit.
	# Mechanical recapture here uses no optics stamp and verifies all native units.
	var recaptured: Dictionary = _capture_mechanical(parent, player)
	if recaptured.is_empty() or not _same(recaptured, unit): return _restore_failed("Independent native whole local recapture differs: " + last_error)
	return true


func _restore_failed(reason: String) -> bool:
	last_error = reason
	return false


## Independent actual native capture without a future-fit view or saved optical
## token. Only used within the paused quiet commit, before the Shell's real gate.
func _capture_mechanical(parent, player: Dictionary) -> Dictionary:
	last_error = _access_error(parent)
	if last_error.is_empty() and not parent.is_restore_candidate(): last_error = "Internal recapture requires an actual paused quiet candidate"
	if last_error.is_empty() and not _same(player, parent.hero.snapshot_state()): last_error = "Actual restored native Hero required for recapture"
	if not last_error.is_empty(): return {}
	var owned: Dictionary = parent.call("false_paradise_codec_owned_state")
	var bindings: Dictionary = parent.scheduler_bindings()
	var scheduler: Dictionary = parent.threat_scheduler.snapshot_state(bindings)
	if scheduler.is_empty(): return _capture_failed(parent.threat_scheduler.last_snapshot_error)
	var sources: Dictionary = {}
	for id: String in parent.sources:
		if id == ECHO_ID:
			var playback: Dictionary = parent.sources[id].call("snapshot_state", scheduler, bindings)
			var actor: Dictionary = parent.sources[id].call("capture_source", player, scheduler, playback)
			if playback.is_empty() or actor.is_empty(): return _capture_failed("Actual Echo recapture failed")
			sources[id] = {"kind": "echo", "actor": actor, "playback": playback}
		else:
			var actor: Dictionary = parent.sources[id].call("snapshot_state") if id == STALKER_ID else parent.sources[id].call("snapshot_state", bindings)
			if actor.is_empty(): return _capture_failed("Actual leaf recapture failed: " + id)
			sources[id] = {"kind": source_kind(id), "actor": actor}
	var core: Dictionary = parent.root_network.call("capture", bindings, scheduler) if is_instance_valid(parent.root_network) else {}
	if is_instance_valid(parent.root_network) and core.is_empty(): return _capture_failed(String(parent.root_network.get("last_snapshot_error")))
	var local: Dictionary = {"api_revision": API, "schema_version": 1, "world": native_world(parent), "scheduler": scheduler, "sources": sources, "core": core, "route": owned.route, "sun": owned.sun, "presentation": owned.presentation, "view": owned.view}
	last_error = record_error(local, parent, player)
	return local if last_error.is_empty() else {}


func progress_error(unit: Dictionary, progress: Dictionary, parent) -> String:
	var error: String = Receipt.transport_error(progress)
	if error.is_empty(): error = Receipt.transport_error(unit)
	if not error.is_empty(): return error
	if not Value.keys_error(unit, KEYS).is_empty() or not unit.get("route") is Dictionary or not Value.keys_error(unit.route, ROUTE_KEYS).is_empty() or not unit.route.get("entries") is Array or unit.route.entries.size() > 5 or not unit.route.get("pending_checkpoint_boundaries") is Array or unit.route.pending_checkpoint_boundaries.size() > unit.route.entries.size() or not unit.route.get("deaths") is Dictionary or not unit.route.get("retired_sources") is Dictionary or not unit.route.get("disengaged") is bool or not unit.route.get("disengagement_pending") is bool or not unit.route.get("exit_state") is String or not unit.get("sources") is Dictionary or not unit.get("core") is Dictionary or (not unit.core.is_empty() and not unit.core.get("tether") is Dictionary) or not unit.get("scheduler") is Dictionary or not unit.scheduler.get("reservations") is Array: return "Complete validated local route required before progression"
	if not Value.keys_error(progress, ["completed", "completion_id", "contact_exit_id", "checkpoint_id", "checkpoint_kind", "checkpoint_ids"]).is_empty() or not progress.get("completed") is bool or not progress.get("checkpoint_ids") is Dictionary: return "Closed native CinderLevel progress required"
	for key: String in ["completion_id", "contact_exit_id", "checkpoint_id", "checkpoint_kind"]:
		if not progress.get(key) is String: return "Exact native progression strings required"
	var complete: bool = _cleared(unit)
	if progress.completed != complete or progress.completion_id != (COMPLETE_ID if complete else "") or progress.contact_exit_id != (EXIT_ID if unit.route.exit_state == "spent" else ""): return "Completion/contact joins actual target/helper release and source deaths"
	var count: int = unit.route.entries.size() - unit.route.pending_checkpoint_boundaries.size()
	if count < 0 or count > CHECKPOINTS.size() or not Value.keys_error(progress.checkpoint_ids, CHECKPOINTS.slice(0, count)).is_empty(): return "Only the genuinely delivered checkpoint prefix is progress"
	for index: int in range(count):
		if progress.checkpoint_ids[CHECKPOINTS[index]] != "encounter": return "Existing garden checkpoints require actual encounter boundaries"
	var latest: String = CHECKPOINTS[count - 1] if count > 0 else ""
	if progress.checkpoint_id != latest or progress.checkpoint_kind != ("encounter" if count > 0 else ""): return "Current checkpoint must match the latest delivered entry"
	return ""


func _route_shape_error(unit: Dictionary, parent, player: Dictionary) -> String:
	var route: Dictionary = unit.route
	if not Value.keys_error(route, ROUTE_KEYS).is_empty() or not route.get("entries") is Array or route.entries.size() > 5 or not route.get("deaths") is Dictionary or not route.get("pending_checkpoint_boundaries") is Array or route.pending_checkpoint_boundaries.size() > route.entries.size() or not route.get("retired_sources") is Dictionary or not route.get("disengaged") is bool or not route.get("disengagement_pending") is bool or not route.get("exit_state") is String or route.exit_state not in ["clear", "available", "active", "spent"] or not route.get("contact") is Dictionary: return "Closed bounded native route/retirement/checkpoint/contact required"
	var radius: float = _radius(parent.hero)
	if radius <= 0.0: return "Original native Hero capsule radius required"
	var previous: float = -1.0
	for index: int in range(route.entries.size()):
		var row: Variant = route.entries[index]
		var keys: Array = ["id", "beat", "clock_s", "hero_position", "capsule_radius"] if index < 4 else ["id", "beat", "clock_s", "hero_position", "from_phase", "to_phase", "root_boundary"]
		if not row is Dictionary or not Value.keys_error(row, keys).is_empty() or row.get("id") != ENTRY_IDS[index] or not _same(row.get("beat"), index + 1) or not Receipt.clock_valid(row.get("clock_s")) or row.clock_s > unit.scheduler.clock_s or (index > 0 and row.clock_s <= previous) or not _vector(row.get("hero_position")): return "Canonical actual entry order/clock/capsule receipt required"
		var at: Vector3 = Value.read_vector3(row.hero_position)
		if not FLOOR.grow(-radius).has_point(Vector2(at.x, at.z)) or absf(at.y) > 0.2 or (_same(row.clock_s, unit.scheduler.clock_s) and not _same(row.hero_position, player.motion.position)): return "Historical entry must retain actual supported native Hero position"
		if index < 4 and (not _same(row.get("capsule_radius"), radius) or at.z + radius > ENTRY_Z[index]): return "Actual whole grounded capsule crossing required"
		if index == 4 and (not _same(row.get("from_phase"), 1) or not _same(row.get("to_phase"), 2) or not row.get("root_boundary") is Dictionary): return "Fifth entry is the genuine first target boundary"
		previous = row.clock_s
	var acknowledged: int = route.entries.size() - route.pending_checkpoint_boundaries.size()
	for index: int in range(route.pending_checkpoint_boundaries.size()):
		if not _same(route.pending_checkpoint_boundaries[index], route.entries[acknowledged + index]): return "Pending checkpoints must be the exact undelivered earned suffix"
	return ""


func _death_and_entry_error(unit: Dictionary) -> String:
	for id: Variant in unit.route.deaths:
		if not id is String or not unit.sources.has(id): return "Only retained entitled native actors may have death receipts"
	for id: String in unit.sources:
		var actor: Dictionary = unit.sources[id].actor
		var echo: bool = id == ECHO_ID
		if not actor.get("hp") is float or not actor.get("max_hp") is float or (echo and not actor.get("alive") is bool) or (not echo and not actor.get("dead") is bool): return "Native exact typed HP/lifecycle required: " + id
		var dead: bool = not actor.alive if echo else actor.dead
		if dead != unit.route.deaths.has(id): return "Actual death receipts and native lifecycle must agree: " + id
		if not dead: continue
		var receipt: Variant = unit.route.deaths[id]
		var position: Variant = actor.get("physical", {}).get("position") if echo else actor.position
		if not receipt is Dictionary or not Value.keys_error(receipt, ["clock_s", "source_position"]).is_empty() or actor.hp != 0.0 or not Receipt.clock_valid(receipt.get("clock_s")) or receipt.clock_s < unit.route.entries[_entry_index(id)].clock_s or receipt.clock_s > unit.scheduler.clock_s or not _vector(receipt.get("source_position")) or not _same(receipt.source_position, position) or (echo and not _same(receipt.clock_s, actor.get("defeated_at_s"))): return "Death retains original lethal clock/fixed physical native owner: " + id
		if ROOT_IDS.has(id):
			var exchange: Variant = actor.mechanism.get("exchange")
			if not exchange is Dictionary or not Receipt.clock_valid(exchange.get("active_until_s")) or not Receipt.clock_valid(exchange.get("recovery_until_s")) or receipt.clock_s <= exchange.active_until_s or receipt.clock_s > exchange.recovery_until_s: return "Actual low Root death must retain its original recovery window"
	for index: int in range(1, mini(unit.route.entries.size(), 4)):
		for id: String in ENTRY_SOURCES[index - 1]:
			if not unit.route.deaths.has(id) or unit.route.deaths[id].clock_s > unit.route.entries[index].clock_s: return "Next spatial court cannot precede actual previous required source death"
	return ""


func _root_sun_error(unit: Dictionary) -> String:
	if not Value.keys_error(unit.sun, SUN_KEYS).is_empty(): return "Closed derived phase2 sun timeline required"
	if unit.core.is_empty():
		if unit.route.disengaged or unit.route.disengagement_pending or not _same(unit.sun, sun_at(null, unit.scheduler.clock_s)): return "Unentered core cannot manufacture target boundary/sun/release"
		return ""
	var core: Dictionary = unit.core
	var target: Dictionary = core.tether
	if not target.get("hp") is float or not target.get("phase") is int or not target.get("dead") is bool or target.hp < 0.0 or target.hp > 60.0 or target.phase != (3 if target.hp == 0.0 else (1 if target.hp > 30.0 else 2)) or target.dead != (target.hp == 0.0): return "Monotonic60/30/0 native target phase/lifecycle required"
	if not Value.keys_error(core.control, ["next_kind", "retry_at_s", "cycle_records", "framing", "boundaries"]).is_empty() or not core.control.get("boundaries") is Array or core.control.boundaries.size() != target.phase - 1 or not core.control.get("cycle_records") is Dictionary: return "Every genuine target boundary is retained once"
	var anchor: Variant = null
	if not core.control.boundaries.is_empty():
		var boundary: Variant = core.control.boundaries[0]
		if not boundary is Dictionary or not Receipt.clock_valid(boundary.get("clock_s")): return "Exact native first boundary clock required"
		anchor = boundary.clock_s
		if unit.route.entries.size() != 5 or not _same(unit.route.entries[4].root_boundary, boundary) or not _same(unit.route.entries[4].clock_s, anchor): return "Helper entitlement joins the exact native first root recovery boundary"
	elif unit.route.entries.size() != 4: return "Phase1 root court has no phase2 helper entitlement"
	if not _same(unit.sun, sun_at(anchor, unit.scheduler.clock_s)): return "Sun state must derive from actual first boundary and same whole tick"
	for kind: Variant in core.control.cycle_records:
		if kind not in ["draw", "enclose"] or not core.control.cycle_records[kind] is Dictionary: return "Original two bounded source cycle identities required"
		var cycle: Dictionary = core.control.cycle_records[kind]
		var mechanism: Dictionary = core.mechanisms[kind]
		if not mechanism.get("exchange") is Dictionary or not Receipt.clock_valid(mechanism.exchange.get("start_s")) or not cycle.get("sun_choice") is int or not _same(cycle.sun_choice, effective_sun(anchor, mechanism.exchange.start_s)): return "Held/latest root sun choice joins its own ORIGINAL admission clock"
	for index: int in range(core.control.boundaries.size()):
		var boundary: Variant = core.control.boundaries[index]
		if not boundary is Dictionary or not Value.keys_error(boundary, ["from_phase", "to_phase", "clock_s", "kind", "cycle", "exchange_id", "recovery_receipt"]).is_empty() or not _same(boundary.get("from_phase"), index + 1) or not _same(boundary.get("to_phase"), index + 2) or not Receipt.clock_valid(boundary.get("clock_s")) or boundary.clock_s > unit.scheduler.clock_s or not boundary.get("recovery_receipt") is Dictionary: return "Exact closed sequential native root recovery boundaries required"
		var receipt: Dictionary = boundary.recovery_receipt
		if not Value.keys_error(receipt, ["exchange", "sun_choice"]).is_empty() or not receipt.get("exchange") is Dictionary or not Receipt.clock_valid(receipt.exchange.get("start_s")) or not receipt.get("sun_choice") is int or not _same(receipt.sun_choice, effective_sun(anchor, receipt.exchange.start_s)): return "Replaced native recovery receipt keeps its ORIGINAL admission sun choice"
	if unit.route.disengaged != target.dead or (unit.route.disengagement_pending and not unit.route.disengaged): return "Parent release/pending state joins actual final target boundary"
	if unit.route.disengaged and not unit.route.disengagement_pending and not unit.scheduler.reservations.is_empty(): return "Settled final release must retain an empty whole held union"
	return ""


func _retirement_error(unit: Dictionary) -> String:
	var retired: Dictionary = unit.route.retired_sources
	if retired.is_empty():
		if unit.route.disengaged and not unit.route.disengagement_pending and unit.sources.has(HELPER_ID) and not unit.sources[HELPER_ID].actor.dead: return "Surviving helper requires its actual post-target retirement receipt"
		return ""
	if not Value.keys_error(retired, [HELPER_ID]).is_empty() or not unit.route.disengaged or unit.route.disengagement_pending or not unit.sources.has(HELPER_ID): return "Only one genuinely released surviving helper can retire"
	var actor: Dictionary = unit.sources[HELPER_ID].actor
	var receipt: Variant = retired[HELPER_ID]
	if actor.dead or actor.hp <= 0.0 or unit.route.deaths.has(HELPER_ID) or not receipt is Dictionary or not Value.keys_error(receipt, ["clock_s", "reason", "alive", "cycle"]).is_empty() or not Receipt.clock_valid(receipt.get("clock_s")) or receipt.clock_s > unit.scheduler.clock_s or receipt.clock_s < unit.core.control.boundaries[-1].clock_s or receipt.get("reason") != "garden_disengaged" or not _same(receipt.get("alive"), true) or not receipt.get("cycle") is int or not _same(receipt.cycle, actor.mechanism.get("cycle")) or actor.mechanism.get("phase") != "clear" or actor.mechanism.get("status") != ("idle" if receipt.cycle == 0 else "cancelled") or actor.mechanism.get("last_cancel_reason") != "garden_disengaged" or not _same(actor.collision, {"enabled": true, "layer": 2, "mask": 1}): return "Retired helper preserves actual living HP/body/group/cycle and clear native cancellation"
	for reservation: Variant in unit.scheduler.reservations:
		if not reservation is Dictionary or reservation.get("source_id") == HELPER_ID + "/attack": return "Retired living helper cannot retain a native lease"
	return ""


func _view_error(unit: Dictionary, parent) -> String:
	var ids: Array = [ECHO_ID] if unit.sources.has(ECHO_ID) else []
	if not Value.keys_error(unit.view, ["echoes"]).is_empty() or not unit.view.get("echoes") is Dictionary or not Value.keys_error(unit.view.echoes, ids).is_empty(): return "Every entitled Echo retains one bounded historical render path"
	for id: String in ids:
		var packet: Dictionary = unit.sources[id]
		var ready: bool = packet.playback.get("status") == "cycle_ready"
		var points: Variant = unit.view.echoes[id]
		if not points is Array or points.size() > 12 or (ready and not points.is_empty()) or (not ready and points.is_empty()): return "Historical view belongs to the actual current managed generation"
		var seen: Array = []
		for point: Variant in points:
			if not _vector(point) or _contains(seen, point): return "Finite unique native Hero render positions required"
			var at: Vector3 = Value.read_vector3(point)
			if not FLOOR.grow(-_radius(parent.hero)).has_point(Vector2(at.x, at.z)) or absf(at.y) > 0.2: return "Historical view path retains actual permanent floor support"
			seen.append(point)
	if _cleared(unit) and unit.route.exit_state == "clear": return "Completed quiet release exposes the actual contact exit"
	if not _cleared(unit) and unit.route.exit_state != "clear": return "Exit remains clear until actual required release"
	return ""


func _contact_error(unit: Dictionary, parent, player: Dictionary) -> String:
	var contact: Dictionary = unit.route.contact
	if unit.route.exit_state not in ["active", "spent"]: return "Unused exit cannot retain contact" if not contact.is_empty() else ""
	if not Value.keys_error(contact, ["clock_s", "hero_position", "exit_id"]).is_empty() or contact.get("exit_id") != EXIT_ID or not Receipt.clock_valid(contact.get("clock_s")) or contact.clock_s > unit.scheduler.clock_s or not _vector(contact.get("hero_position")): return "Original actual capsule contact receipt required"
	var at: Vector3 = Value.read_vector3(contact.hero_position)
	if not EXIT_RECT.grow(-_radius(parent.hero)).has_point(Vector2(at.x, at.z)) or absf(at.y) > 0.2 or (_same(contact.clock_s, unit.scheduler.clock_s) and not _same(contact.hero_position, player.motion.position)): return "Contact joins actual supported native Hero crossing"
	if unit.core.control.boundaries.size() != 2 or contact.clock_s < unit.core.control.boundaries[-1].clock_s: return "Contact follows actual final root release"
	for death: Dictionary in unit.route.deaths.values():
		if contact.clock_s < death.clock_s: return "Contact cannot precede an actual retained source death"
	for retired: Dictionary in unit.route.retired_sources.values():
		if contact.clock_s < retired.clock_s: return "Contact cannot precede actual surviving helper retirement"
	return ""


func live_presentation_error(parent) -> String:
	var error: String = _access_error(parent)
	if not error.is_empty(): return error
	var union: Variant = parent.call("false_paradise_codec_framing_union", null)
	error = _union_error(union)
	return error if not error.is_empty() else String(parent.shared_shell.call("camera_framing_error", union.points))


func candidate_presentation_error(parent, camera: Camera3D, hud: GameHUD) -> String:
	var error: String = _access_error(parent)
	if not error.is_empty(): return error
	if not is_instance_valid(camera) or not is_instance_valid(hud) or not parent.shared_shell.has_method("camera_framing_error_for_context"): return "Explicit actual native candidate Camera/HUD required"
	var union: Variant = parent.call("false_paradise_codec_framing_union", camera)
	error = _union_error(union)
	return error if not error.is_empty() else String(parent.shared_shell.call("camera_framing_error_for_context", union.points, parent.hero, camera, hud))


## Base CinderLevel invokes its actual optical hook after quiet local AND base
## progress commit. The supplied pair remains an expectation, never a view stamp.
func verify_candidate_pair(unit: Dictionary, parent, player: Dictionary, camera: Camera3D, hud: GameHUD) -> String:
	var error: String = _access_error(parent)
	if not error.is_empty(): return error
	if not parent.is_restore_candidate(): return "Only the actual quiet CinderLevel candidate may finish this gate"
	error = candidate_presentation_error(parent, camera, hud)
	if not error.is_empty(): return error
	var native: Dictionary = capture(parent, player, camera, hud)
	return "" if not native.is_empty() and _same(native, unit) else "Post-gate independent native whole-unit recapture differs: " + last_error


func _access_error(parent) -> String:
	if not is_instance_valid(parent) or not parent is CinderLevel or parent.get_script() == null or parent.get_script().resource_path != PARENT_PATH or not parent.is_inside_tree() or not parent.is_node_ready() or parent.is_queued_for_deletion() or not parent.get_tree().paused: return "Actual ready paused A3-L4 native parent required"
	for method: String in HOOKS:
		if not parent.has_method(method): return "Explicit required parent codec hook: " + method
	if not is_instance_valid(parent.hero) or not is_instance_valid(parent.shared_shell) or not is_instance_valid(parent.threat_scheduler) or not is_instance_valid(parent.scenery): return "Actual shared Hero/Shell/Scheduler/scenery required"
	var error: String = String(parent.call("false_paradise_codec_boundary_error"))
	return error if not error.is_empty() else String(parent.runtime_error())


static func native_world(parent) -> Dictionary:
	var bindings: Dictionary = parent.scheduler_bindings()
	var signature: Dictionary = Footprint.floor_signature(bindings.world_root, bindings.floors.values())
	if not signature.get("accepted", false) or not signature.get("signature") is Array or signature.signature.is_empty(): return {}
	return {"layout_sha256": FileAccess.get_sha256(LAYOUT_PATH), "encounter_id": ENCOUNTER, "world_revision": 1, "profile_id": String(parent.threat_scheduler.encounter_profile().get("id", "")), "collision_fingerprint": parent.threat_scheduler.pure_collision_fingerprint(bindings.world_root), "floor_signature": signature.signature.duplicate(true)}


static func prepared_world(world: Dictionary) -> Dictionary:
	return {"world_revision": world.world_revision, "collision_fingerprint": world.collision_fingerprint.duplicate(true), "floor_signature": world.floor_signature.duplicate(true)}


static func echo_context(world: Dictionary, parent, generation: int) -> Dictionary:
	return {"world_root": parent.get_parent() as Node3D, "source_id": ECHO_ID, "source_epoch": source_epoch(ECHO_ID), "generation": generation, "world_collision_fingerprint": world.collision_fingerprint.duplicate(true), "world_floor_signature": world.floor_signature.duplicate(true)}


static func source_epoch(id: String) -> String:
	return "A3-L4/" + id + "/own-sequence"


static func entitled_sources(count: int) -> Array[String]:
	var result: Array[String] = []
	for index: int in range(count):
		for id: String in ENTRY_SOURCES[index]: result.append(id)
	return result


static func source_kind(id: String) -> String:
	return "stalker" if id == STALKER_ID else ("echo" if id == ECHO_ID else "root")


static func fixed_position(id: String) -> Array:
	var positions: Dictionary = {"l4-beauty-root": Vector3(0, 0, 36), "l4-plain-root": Vector3(1.2, 0, 18), HELPER_ID: Vector3(-1.5, 0, 2)}
	return Value.vector3(positions[id]) if positions.has(id) else []


static func sun_at(anchor: Variant, clock_s: float) -> Dictionary:
	if anchor == null: return {"started": false, "anchor_s": null, "cycle": 0, "elapsed_s": 0.0, "stage": "stable", "effective_index": 0, "incoming_index": 1}
	var elapsed: float = maxf(0.0, clock_s - float(anchor))
	var cycle: int = int(floor(elapsed / 14.0))
	var local_s: float = elapsed - float(cycle) * 14.0
	var effective: int = cycle % 2 if local_s < 4.0 else (cycle + 1) % 2
	return {"started": true, "anchor_s": anchor, "cycle": cycle, "elapsed_s": local_s, "stage": "preview" if local_s < 3.0 else ("lock" if local_s < 4.0 else "stable"), "effective_index": effective, "incoming_index": 1 - effective}


static func effective_sun(anchor: Variant, clock_s: float) -> int:
	return int(sun_at(anchor, clock_s).effective_index)


static func _cleared(unit: Dictionary) -> bool:
	if unit.route.entries.size() != 5 or not unit.route.disengaged or unit.route.disengagement_pending or unit.core.is_empty() or unit.core.tether.get("dead") != true or not unit.scheduler.reservations.is_empty(): return false
	for id: String in [STALKER_ID, "l4-beauty-root", ECHO_ID, "l4-plain-root"]:
		if not unit.route.deaths.has(id): return false
	return unit.route.deaths.has(HELPER_ID) or unit.route.retired_sources.has(HELPER_ID)


static func _entry_index(id: String) -> int:
	for index: int in range(ENTRY_SOURCES.size()):
		if ENTRY_SOURCES[index].has(id): return index
	return -1


static func _radius(hero: CinderPlayer) -> float:
	var body: CollisionShape3D = hero.get_node_or_null("BodyCollision") as CollisionShape3D
	return (body.shape as CapsuleShape3D).radius if body != null and body.shape is CapsuleShape3D and body.basis == Basis.IDENTITY else -1.0


static func _union_error(unit: Variant) -> String:
	if not unit is Dictionary or not Value.keys_error(unit, ["error", "points"]).is_empty() or not unit.get("error") is String or not unit.get("points") is Array: return "Complete actual native current-court union required"
	if not unit.error.is_empty(): return unit.error
	if unit.points.is_empty() or unit.points.size() > 224: return "Complete bounded actual native source/cue/Hero groups required"
	for point: Variant in unit.points:
		if not point is Vector3 or not point.is_finite(): return "Native actual corners required; no transported optical stamp"
	return ""


static func _vector(value: Variant) -> bool:
	return value is Array and value.size() == 3 and value[0] is float and value[1] is float and value[2] is float and Value.is_vector3(value) and _same(value, Value.vector3(Value.read_vector3(value)))


## A forged nonrepresentable component must fail PURELY before native Vector3
## coercion could change a valid packet during quiet commit/exact recapture.
static func _hero_native_vector_error(player: Dictionary) -> String:
	for key: String in ["position", "velocity", "facing", "dash_direction", "queued_dash"]:
		if not _vector(player.motion[key]): return "Saved Hero retains exact native Vector3 components: " + key
	if player.motion.dash_origin != null and not _vector(player.motion.dash_origin): return "Saved unfinished dash origin is an exact native Vector3"
	for column: Variant in player.motion.basis:
		if not _vector(column): return "Saved Hero basis keeps exact native columns"
	var records: Array = player.world_actions.history.duplicate()
	if not player.world_actions.pending_dash.is_empty(): records.append(player.world_actions.pending_dash)
	for record: Dictionary in records:
		for key: String in ["world_origin", "direction", "landing"]:
			if record.has(key) and not _vector(record[key]): return "Saved real world-action vectors retain native precision"
		for sample: Dictionary in record.get("path", []):
			if not _vector(sample.position): return "Saved real dash path retains native precision"
	return ""


static func _contains(values: Array, expected: Variant) -> bool:
	for value: Variant in values:
		if _same(value, expected): return true
	return false


static func _same(a: Variant, b: Variant) -> bool:
	return Exact.exact_equal(a, b)
