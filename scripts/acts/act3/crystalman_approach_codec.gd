extends RefCounted
## SOURCE-ONLY whole current regular unit: complete Scheduler3 + actual C50/C52.
## Native qualification is pending. No filtered journal, re-admission or Hero writes.
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Receipt = preload("res://scripts/combat/authored_echo_terminal_receipt.gd")
const Stalker = preload("res://scripts/acts/act3/sunbound_stalker.gd")
const Echo = preload("res://scripts/acts/act3/mirror_echo.gd")
const API: String = "act3-crystalman-approach-local-1"
const IDS: Array[String] = ["l5-offered-echo","l5-plain-stalker","l5-plain-echo"]
const KEYS: Array[String] = ["api_revision","schema_version","world","stage","deaths","scheduler","sources","view"]
var last_error: String = ""

func capture(parent, player: Dictionary, optical: bool = true) -> Dictionary:
	last_error = boundary_error(parent)
	if last_error.is_empty(): last_error = parent.hero.snapshot_error(player)
	if last_error.is_empty() and not same(player,parent.hero.snapshot_state()): last_error = "Actual complete current Hero required"
	if last_error.is_empty() and optical: last_error = presentation_error(parent,parent.shared_shell.get("camera"),parent.shared_shell.get("hud"))
	if not last_error.is_empty(): return {}
	var scheduler: Dictionary = parent.threat_scheduler.snapshot_state(parent.scheduler_bindings())
	if scheduler.is_empty(): return failed(parent.threat_scheduler.last_snapshot_error)
	var packets: Dictionary = {}
	for id: String in parent.sources:
		var source: Node3D = parent.sources[id]
		if id == IDS[1]:
			var actor: Dictionary = source.call("snapshot_state")
			if actor.is_empty(): return failed(String(source.get("last_snapshot_error")))
			packets[id] = {"kind":"stalker","actor":actor}
		else:
			var playback: Dictionary = source.call("snapshot_state",scheduler,parent.scheduler_bindings())
			var actor: Dictionary = source.call("capture_source",player,scheduler,playback)
			if actor.is_empty() or playback.is_empty(): return failed(String(source.get("source_snapshot_error"))+"; "+String(source.get("last_snapshot_error")))
			packets[id] = {"kind":"echo","actor":actor,"playback":playback}
	var owned: Dictionary = parent.regular_owned_state()
	var unit: Dictionary = {"api_revision":API,"schema_version":1,"world":native_world(parent),"stage":parent.stage,"deaths":owned.deaths,"scheduler":scheduler,"sources":packets,"view":owned.view}
	last_error = record_error(unit,parent,player)
	return unit if last_error.is_empty() else {}

func failed(reason: String) -> Dictionary:
	last_error = reason
	return {}

func boundary_error(parent) -> String:
	if not parent.is_inside_tree() or not parent.get_tree().paused or parent._control_busy or parent._pre_consumer_guard_busy: return "Actual settled paused whole regular boundary required"
	return parent.runtime_error()

func header_error(unit: Dictionary,parent,player: Dictionary) -> String:
	var error: String = boundary_error(parent)
	if error.is_empty(): error = Receipt.transport_error(unit)
	if error.is_empty(): error = parent.hero.snapshot_error(player)
	if not error.is_empty(): return error
	if not Value.keys_error(unit,KEYS).is_empty() or unit.get("api_revision") != API or not unit.get("schema_version") is int or unit.schema_version != 1: return "Closed regular local1 required"
	for key: String in ["world","deaths","scheduler","sources","view"]:
		if not unit.get(key) is Dictionary: return "Typed regular aggregate required: "+key
	if not unit.get("stage") is int or unit.stage not in [1,2]: return "Entitled current regular stage required"
	if not Value.keys_error(unit.sources,entitled(unit.stage)).is_empty() or not Value.keys_error(unit.view,echo_ids(unit.stage)).is_empty(): return "Every entitled original source and its whole view path required"
	if not Value.keys_error(unit.world,["encounter_id","profile_id","world_revision","collision_fingerprint","floor_signature"]).is_empty(): return "Closed immutable regular world required"
	var actual: Dictionary = native_world(parent)
	for key: String in ["encounter_id","world_revision","collision_fingerprint","floor_signature"]:
		if not same(unit.world[key],actual[key]): return "Actual regular physical world differs: "+key
	if not unit.scheduler.get("profile") is Dictionary or not unit.world.get("profile_id") is String or not Receipt.clock_valid(unit.scheduler.get("clock_s")): return "Typed whole Scheduler profile/clock required"
	if unit.scheduler.get("encounter_id") != parent.ENCOUNTER_ID or not same(unit.scheduler.get("world_revision"),1) or not same(unit.scheduler.get("collision"),unit.world.collision_fingerprint) or unit.scheduler.get("profile",{}).get("id") != unit.world.profile_id: return "Whole Scheduler/world/profile join required"
	if unit.scheduler.get("schema_version") != 3 or not unit.scheduler.get("authored_source_cycles") is Dictionary or not unit.scheduler.authored_source_cycles.get("sources") is Array or unit.scheduler.authored_source_cycles.sources.size() != echo_ids(unit.stage).size(): return "Complete actual1/2-source native managed journal required"
	if not same(unit.scheduler.get("clock_s"),player.world_actions.clock_s): return "Original Player/regular epoch shares actual clocks"
	for id: String in unit.sources:
		var packet: Variant = unit.sources[id]
		if not packet is Dictionary or not Value.keys_error(packet,["kind","actor"] if id == IDS[1] else ["kind","actor","playback"]).is_empty() or not packet.get("actor") is Dictionary or packet.kind != ("stalker" if id == IDS[1] else "echo"): return "Closed typed original leaf required: "+id
		if id != IDS[1] and (not packet.get("playback") is Dictionary or not packet.actor.get("physical") is Dictionary): return "Whole authored Playback/physical source required"
	for id: String in unit.deaths:
		if not unit.sources.has(id) or not unit.deaths[id] is Dictionary or not Value.keys_error(unit.deaths[id],["clock_s","source_position"]).is_empty() or not Receipt.clock_valid(unit.deaths[id].get("clock_s")) or unit.deaths[id].clock_s > unit.scheduler.clock_s or not Value.is_vector3(unit.deaths[id].get("source_position")): return "Original bounded source death receipt required"
		var actor: Dictionary = unit.sources[id].actor
		if id == IDS[1]:
			if actor.get("dead") != true or actor.get("hp") != 0.0 or not same(actor.get("position"),unit.deaths[id].source_position): return "Actual dead Stalker/result receipt differ"
		elif actor.get("alive") != false or actor.get("hp") != 0.0 or not same(actor.get("physical",{}).get("position"),unit.deaths[id].source_position): return "Actual dead Echo/result receipt differ"
	if unit.stage == 2 and not unit.deaths.has(IDS[0]): return "Plain entry requires actual offered source death"
	for id: String in unit.view:
		if not unit.view[id] is Array or unit.view[id].size() > 12: return "Bounded whole authored render path required"
		for at: Variant in unit.view[id]:
			if not Value.is_vector3(at): return "Finite original view point required"
	return ""

func staged_bindings(unit: Dictionary,parent,player: Dictionary) -> Dictionary:
	var bindings: Dictionary = parent.scheduler_bindings()
	bindings["hero_positions"] = {"hero":Value.read_vector3(player.motion.position)}
	bindings["owner_positions"] = {}
	bindings["owner_velocities"] = {}
	bindings["owner_collision_states"] = {}
	bindings["authored_owner_bindings"] = {}
	bindings["authored_cycle_playback_ids"] = {}
	for id: String in unit.sources:
		var packet: Dictionary = unit.sources[id]
		if id == IDS[1]:
			bindings.owner_positions[id] = Value.read_vector3(packet.actor.position)
			bindings.owner_velocities[id] = Value.read_vector3(packet.actor.velocity)
			if not packet.actor.dead and not String(packet.actor.reservation_id).is_empty(): bindings.owner_collision_states[id] = {"collision_path":"BodyCollision","enabled":true,"layer":2,"mask":1}
		else:
			bindings.authored_owner_bindings[id] = parent.sources[id].call("staged_source_binding",packet.actor,player,unit.scheduler,packet.playback)
			bindings.authored_cycle_playback_ids[id] = packet.playback.playback_id
	return bindings

func record_error(unit: Dictionary,parent,player: Dictionary,paired: bool = true) -> String:
	var error: String = header_error(unit,parent,player)
	if not error.is_empty(): return error
	if not Value.keys_error(parent.sources,unit.sources.keys()).is_empty() or parent.threat_scheduler.encounter_profile().get("id") != unit.world.profile_id: return "Actual recipient topology/profile must match entire saved unit"
	for id: String in unit.sources:
		var source: Node3D = parent.sources[id]
		var packet: Dictionary = unit.sources[id]
		if id == IDS[1]:
			if source.get_script() != Stalker: return "Exact original C50 recipient required"
			error = source.call("snapshot_error",packet.actor,unit.scheduler)
			if error.is_empty() and same(packet.actor.previous.clock_s,unit.scheduler.clock_s) and not same(packet.actor.previous.hero_position,player.motion.position): error = "Current Stalker sample differs from complete saved Hero"
		else:
			if source.get_script() != Echo: return "Exact original C52 recipient required"
			error = source.call("source_record_error",packet.actor,player,unit.scheduler,packet.playback)
		if not error.is_empty(): return id+": "+error
	var staged: Dictionary = staged_bindings(unit,parent,player)
	error = parent.threat_scheduler.snapshot_error(unit.scheduler,staged)
	if not error.is_empty(): return "Whole retained native Scheduler: "+error
	if paired:
		for id: String in echo_ids(unit.stage):
			var packet: Dictionary = unit.sources[id]
			error = parent.sources[id].call("snapshot_error",packet.playback,parent.threat_scheduler,unit.scheduler,staged,{"hero":parent.hero},staged.floors.values(),echo_context(unit.world,parent,id,packet.actor.generation))
			if not error.is_empty(): return "Complete authored Playback: "+error
	return ""

func prepare_sources(unit: Dictionary,parent,player: Dictionary) -> String:
	var error: String = record_error(unit,parent,player,false)
	if not error.is_empty(): return error
	for id: String in echo_ids(unit.stage):
		var packet: Dictionary = unit.sources[id]
		if not parent.sources[id].call("prepare_authored_restore",packet.playback,parent.threat_scheduler,{"hero":parent.hero},parent.floor_regions(),echo_context(unit.world,parent,id,packet.actor.generation)): return String(parent.sources[id].get("source_snapshot_error"))+"; "+String(parent.sources[id].get("last_error"))
	return record_error(unit,parent,player,true)

func restore_local(unit: Dictionary,parent,player: Dictionary) -> bool:
	last_error = record_error(unit,parent,player)
	if last_error.is_empty() and not same(player,parent.hero.snapshot_state()): last_error = "Actual outer Hero must commit before local unit"
	if not last_error.is_empty(): return false
	for id: String in unit.sources:
		var packet: Dictionary = unit.sources[id]
		var accepted: bool = parent.sources[id].call("apply_validated_state",packet.actor) if id == IDS[1] else parent.sources[id].call("restore_source_physical",packet.actor,player,unit.scheduler,packet.playback)
		if not accepted: last_error = "Prevalidated actual source physical commit changed: "+id; return false
	var actual: Dictionary = parent.scheduler_bindings()
	if not parent.threat_scheduler.restore_state(unit.scheduler,actual): last_error = parent.threat_scheduler.last_snapshot_error; return false
	for id: String in echo_ids(unit.stage):
		var packet: Dictionary = unit.sources[id]
		if not parent.sources[id].call("restore_state",packet.playback,parent.threat_scheduler,unit.scheduler,actual,{"hero":parent.hero},parent.floor_regions(),echo_context(unit.world,parent,id,packet.actor.generation)) or not parent.sources[id].call("verify_restored_source_phase",packet.actor): last_error = "Prevalidated actual authored Playback commit changed: "+id; return false
	if unit.sources.has(IDS[1]) and not parent.sources[IDS[1]].call("refresh_presentation"): last_error = "Stalker quiet presentation declined"; return false
	last_error = parent.regular_apply_owned_state(unit)
	if not last_error.is_empty(): return false
	var again: Dictionary = capture(parent,player,false)
	if again.is_empty() or not same(again,unit): last_error = "Whole native quiet regular recapture differs" if last_error.is_empty() else last_error; return false
	return true

func presentation_error(parent,camera: Camera3D,hud: GameHUD) -> String:
	var union: Dictionary = parent.camera_framing_union("",[],true,false,{},camera)
	if not String(union.get("error","Actual native union required")).is_empty(): return String(union.error)
	return String(parent.shared_shell.call("camera_framing_error_for_context",union.points,parent.hero,camera,hud))

static func entitled(stage: int) -> Array:
	return [IDS[0]] if stage == 1 else IDS.duplicate()

static func echo_ids(stage: int) -> Array:
	return [IDS[0]] if stage == 1 else [IDS[0],IDS[2]]

static func native_world(parent) -> Dictionary:
	var floor: Dictionary = Footprint.floor_signature(parent.actual_world_root(),parent.floor_regions())
	return {"encounter_id":parent.ENCOUNTER_ID,"profile_id":parent.threat_scheduler.encounter_profile().get("id",""),"world_revision":1,"collision_fingerprint":parent.threat_scheduler.pure_collision_fingerprint(parent.actual_world_root()),"floor_signature":floor.get("signature",[])}

static func echo_context(world: Dictionary,parent,id: String,generation: int) -> Dictionary:
	return {"world_root":parent.actual_world_root(),"source_id":id,"source_epoch":String(parent._rows[id].source_epoch_recipe),"generation":generation,"world_collision_fingerprint":world.collision_fingerprint.duplicate(true),"world_floor_signature":world.floor_signature.duplicate(true)}

static func same(left: Variant,right: Variant) -> bool:
	var wire: String = Exact.stringify(left)
	return not wire.is_empty() and wire == Exact.stringify(right)
