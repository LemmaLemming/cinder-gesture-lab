extends RefCounted
## Closed final O3 world. Native Source2/Playback2, Stalker and Lane codecs
## retain complete physical/history custody under one whole Scheduler3.
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/combat/authored_enemy_sequence.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const Receipt = preload("res://scripts/combat/authored_echo_terminal_receipt.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Echo = preload("res://scripts/acts/act3/mirror_echo.gd")
const Stalker = preload("res://scripts/acts/act3/sunbound_stalker.gd")
const API: String = "act3-irontick-reflection-pair-2"
const PARENT: String = "res://scripts/acts/act3/irontick_reflection.gd"
const KEYS: Array[String] = ["api_revision","schema_version","world","scheduler","sources","pulse","view","route"]
const WORLD_KEYS: Array[String] = ["data_sha256","encounter_id","world_revision","profile_id","collision_fingerprint","floor_signature"]
const ROUTE_KEYS: Array[String] = ["active_stage","clears","deaths","exit_state","contact"]
var last_error: String = ""

func capture(parent, player: Dictionary) -> Dictionary:
	last_error=_access_error(parent)
	if last_error.is_empty(): last_error=parent.hero.snapshot_error(player)
	if last_error.is_empty() and not Exact.exact_equal(player,parent.hero.snapshot_state()): last_error="Actual current native Hero required for whole capture"
	if not last_error.is_empty(): return {}
	var bindings: Dictionary=parent.scheduler_bindings()
	var scheduler: Dictionary=parent.threat_scheduler.snapshot_state(bindings)
	if scheduler.is_empty(): last_error=parent.threat_scheduler.last_snapshot_error; return {}
	var packets: Dictionary={}
	var retry: Dictionary=parent.capture_retry_times()
	for id: String in parent.SOURCE_IDS:
		var source: Node3D=parent.sources[id]
		if parent.ECHO_IDS.has(id):
			var playback: Dictionary=source.call("snapshot_state",scheduler,bindings)
			var actor: Dictionary=source.call("capture_source",player,scheduler,playback)
			if playback.is_empty() or actor.is_empty(): last_error=id+": "+String(source.get("source_snapshot_error"))+"; "+String(source.get("last_snapshot_error")); return {}
			packets[id]={"kind":"echo","actor":actor,"playback":playback,"retry_at_s":retry.echoes[id]}
		else:
			var actor: Dictionary=source.call("snapshot_state")
			if actor.is_empty(): last_error=String(source.get("last_snapshot_error")); return {}
			packets[id]={"kind":"stalker","actor":actor}
	var mechanism: Dictionary=parent.mechanism.snapshot_state(bindings)
	if mechanism.is_empty(): last_error=parent.mechanism.last_snapshot_error; return {}
	var local: Dictionary={"api_revision":API,"schema_version":2,"world":parent.native_world(),"scheduler":scheduler,"sources":packets,"pulse":{"eligible_at_s":parent.PULSE_DUE_S,"mechanism":mechanism,"retry_at_s":retry.pulse},"view":parent.capture_view(),"route":parent.capture_route()}
	last_error=record_error(local,parent,player)
	return local if last_error.is_empty() else {}

func record_error(local: Dictionary, parent, player: Dictionary, paired: bool = true) -> String:
	var error: String=_access_error(parent)
	if error.is_empty(): error=_aggregate_transport_error(local)
	if error.is_empty(): error=Receipt.transport_error(player)
	if error.is_empty(): error=parent.hero.snapshot_error(player)
	if not error.is_empty(): return error
	if not Value.keys_error(local,KEYS).is_empty() or local.get("api_revision")!=API or not local.get("schema_version") is int or local.schema_version!=2: return "Closed final O3 paired schema2 required"
	for key: String in ["world","scheduler","sources","pulse","view","route"]:
		if not local[key] is Dictionary: return "Complete typed O3 aggregate required: "+key
	if not Value.keys_error(local.world,WORLD_KEYS).is_empty() or not local.world.get("profile_id") is String or not local.world.get("collision_fingerprint") is Dictionary or not local.world.get("floor_signature") is Array: return "Closed immutable full shore/profile recipe required"
	if not Exact.exact_equal(local.world,parent.native_world()) or local.world.data_sha256!=FileAccess.get_sha256(parent.DATA_PATH) or local.world.encounter_id!=parent.ENCOUNTER_ID or not local.world.world_revision is int or local.world.world_revision!=parent.WORLD_REVISION: return "Actual original authored world/profile/floor/epoch differs"
	var signature: Dictionary=Footprint.floor_signature(parent.get_parent() as Node3D,parent.scheduler_bindings().floors.values())
	if not signature.get("accepted",false) or not Exact.exact_equal(signature.get("signature"),local.world.floor_signature) or not Exact.exact_equal(parent.threat_scheduler.pure_collision_fingerprint(parent.get_parent() as Node3D),local.world.collision_fingerprint): return "Actual complete native floor/static-stone binding differs"
	if not Receipt.clock_valid(local.scheduler.get("clock_s")) or not local.scheduler.get("profile") is Dictionary or not Exact.exact_equal(local.scheduler.profile,Difficulty.new().profile(local.world.profile_id)) or local.scheduler.get("encounter_id")!=parent.ENCOUNTER_ID or not Exact.exact_equal(local.scheduler.get("world_revision"),parent.WORLD_REVISION) or not Exact.exact_equal(local.scheduler.get("collision"),local.world.collision_fingerprint) or not player.get("world_actions") is Dictionary or not Exact.exact_equal(player.world_actions.get("clock_s"),local.scheduler.clock_s): return "Exact shared Hero/Scheduler native tick/profile/world required"
	if not Value.keys_error(local.sources,parent.SOURCE_IDS).is_empty(): return "All retained Echo and Stalker packets are required"
	if not Value.keys_error(local.pulse,["eligible_at_s","mechanism","retry_at_s"]).is_empty() or not Exact.exact_equal(local.pulse.get("eligible_at_s"),parent.PULSE_DUE_S) or not local.pulse.get("mechanism") is Dictionary: return "Immutable independent pulse schedule/full native mechanism required"
	if not _retry_valid(local.pulse.retry_at_s,local.scheduler.clock_s,parent.RETRY_S): return "Bounded native pulse retry clock required"
	var staged: Dictionary=parent.scheduler_bindings()
	staged.hero_positions={"hero":Value.read_vector3(player.motion.position)}
	staged.owner_positions={}; staged.owner_velocities={}; staged.owner_collision_states={}; staged.authored_owner_bindings={}; staged.authored_cycle_playback_ids={}
	for id: String in parent.SOURCE_IDS:
		var packet: Variant=local.sources[id]
		var is_echo: bool=parent.ECHO_IDS.has(id)
		if not packet is Dictionary or not Value.keys_error(packet,["kind","actor","playback","retry_at_s"] if is_echo else ["kind","actor"]).is_empty() or packet.get("kind")!=("echo" if is_echo else "stalker") or not packet.get("actor") is Dictionary or (is_echo and not packet.get("playback") is Dictionary): return "Exact typed native source packet required: "+id
		var source: Node3D=parent.sources[id]
		var actor: Dictionary=packet.actor
		if is_echo:
			if source.get_script()!=Echo or actor.get("source_id")!=id or actor.get("source_epoch")!=parent.source_epoch(id) or not actor.get("generation") is int or not Value.is_integer(actor.generation,1,64) or not _retry_valid(packet.retry_at_s,local.scheduler.clock_s,parent.RETRY_S): return "Actual managed source identity/generation/retry differs: "+id
			error=source.call("source_record_error",actor,player,local.scheduler,packet.playback)
			if not error.is_empty(): return id+": "+error
			staged.authored_owner_bindings[id]=source.call("staged_source_binding",actor,player,local.scheduler,packet.playback)
			staged.authored_cycle_playback_ids[id]=packet.playback.get("playback_id")
		else:
			if source.get_script()!=Stalker: return "Actual unchanged native Stalker script required"
			error=source.call("snapshot_error",actor,local.scheduler)
			if not error.is_empty(): return id+": "+error
			staged.owner_positions[id]=Value.read_vector3(actor.position); staged.owner_velocities[id]=Value.read_vector3(actor.velocity)
			if not actor.dead and not String(actor.reservation_id).is_empty(): staged.owner_collision_states[id]={"collision_path":"BodyCollision","enabled":true,"layer":2,"mask":1}
			if Exact.exact_equal(actor.previous.clock_s,local.scheduler.clock_s) and not Exact.exact_equal(actor.previous.hero_position,player.motion.position): return "Current Stalker sample must retain the exact paired Hero"
	var journal: Variant=local.scheduler.get("authored_source_cycles")
	if local.scheduler.get("schema_version")!=3 or not journal is Dictionary or not journal.get("sources") is Array or journal.sources.size()!=parent.ECHO_IDS.size(): return "Every retained Echo must remain in the full Scheduler3 journal"
	var seen: Dictionary={}
	for entry: Variant in journal.sources:
		if not entry is Dictionary or not entry.get("source_id") is String or not parent.ECHO_IDS.has(entry.source_id) or seen.has(entry.source_id): return "Exactly one journal per retained Echo required"
		seen[entry.source_id]=true
	error=parent.threat_scheduler.snapshot_error(local.scheduler,staged)
	if error.is_empty(): error=parent.mechanism.snapshot_error(local.pulse.mechanism,staged,local.scheduler)
	if not error.is_empty(): return error
	var pulse: Dictionary=local.pulse.mechanism
	if not pulse.get("cycle") is int or pulse.cycle not in [0,1]: return "Original independent pulse has at most one actual cycle"
	if pulse.cycle==1 and (not pulse.get("exchange") is Dictionary or not Receipt.clock_valid(pulse.exchange.get("start_s")) or pulse.exchange.start_s<parent.PULSE_DUE_S): return "Pulse actual admission must respect independent eligibility"
	error=_route_error(local,parent,player)
	if error.is_empty(): error=_view_error(local,parent)
	if not error.is_empty(): return error
	if paired:
		for id: String in parent.ECHO_IDS:
			var packet: Dictionary=local.sources[id]
			error=parent.sources[id].call("snapshot_error",packet.playback,parent.threat_scheduler,local.scheduler,staged,{"hero":parent.hero},staged.floors.values(),parent.echo_context(id,packet.actor.generation))
			if not error.is_empty(): return id+": "+error
	return ""

func _retry_valid(value: Variant, clock: float, interval: float) -> bool:
	return value is float and Value.in_range(value,0.0,clock+interval)

func _route_error(local: Dictionary, parent, player: Dictionary) -> String:
	var route: Dictionary=local.route
	if not Value.keys_error(route,ROUTE_KEYS).is_empty() or not route.get("active_stage") is int or not Value.is_integer(route.get("active_stage"),0,parent.STAGE_IDS.size()) or not route.get("clears") is Array or route.clears.size()!=route.active_stage or not route.get("deaths") is Dictionary or not route.get("exit_state") is String or not route.get("contact") is Dictionary: return "Closed earned native stage/death/contact history required"
	for clear: Variant in route.clears:
		if not clear is Dictionary or not Value.keys_error(clear,["stage_id","clock_s","hero_position"]).is_empty() or not clear.get("stage_id") is String or not Receipt.clock_valid(clear.get("clock_s")) or not Value.is_vector3(clear.get("hero_position")): return "Typed native stage prefix must validate before source-history joins"
	for id: Variant in route.deaths:
		if not id is String or not parent.SOURCE_IDS.has(id): return "Foreign source death is forbidden"
	var clock: float=local.scheduler.clock_s
	for id: String in parent.SOURCE_IDS:
		var packet: Dictionary=local.sources[id]; var actor: Dictionary=packet.actor; var is_echo: bool=parent.ECHO_IDS.has(id)
		var dead: bool=not actor.alive if is_echo else actor.dead
		if dead!=route.deaths.has(id): return "Native source death and owned receipt disagree: "+id
		if dead:
			var receipt: Variant=route.deaths[id]
			var position: Variant=actor.physical.position if is_echo else actor.position
			if not receipt is Dictionary or not Value.keys_error(receipt,["clock_s","source_position"]).is_empty() or not Receipt.clock_valid(receipt.get("clock_s")) or receipt.clock_s>clock or not Value.is_vector3(receipt.get("source_position")) or not Exact.exact_equal(receipt.source_position,position) or (is_echo and not Exact.exact_equal(receipt.clock_s,actor.defeated_at_s)): return "Exact original native source death/pose clock required"
		if is_echo:
			var stage: int=parent.ECHO_IDS.find(id)
			if stage>route.active_stage:
				if dead or actor.hp!=actor.max_hp or actor.source_hits!=0 or actor.generation!=1 or packet.playback.status!="cycle_ready" or not actor.lifecycle.terminal_receipts.is_empty() or packet.retry_at_s!=0.0: return "Future-stage Echo remains pristine managed ready generation1"
			else:
				var activation: float=0.0 if stage==0 else float(route.clears[stage-1].get("clock_s",-1.0))
				if activation<0.0: return "Earlier real stage boundary required before source activity"
				for terminal: Dictionary in actor.lifecycle.terminal_receipts:
					if terminal.exchange.start_s<activation: return "Echo generation cannot predate its genuine stage activation"
				if packet.playback.status=="running" and packet.playback.exchange.start_s<activation: return "Live Echo lease cannot predate stage activation"
		else:
			if route.active_stage<2 and (actor.cycle!=0 or not String(actor.reservation_id).is_empty() or Value.read_vector3(actor.position)!=parent.SOURCE_POSITIONS[id] or actor.phase not in ["idle","defeated"]): return "Dormant final Stalker cannot move/cycle/hold a lease"
			if route.active_stage<2 and actor.hp==actor.max_hp and Value.read_vector3(actor.velocity)!=Vector3.ZERO: return "Untouched dormant Stalker cannot manufacture motion"
	var previous: float=-1.0
	for index: int in range(route.clears.size()):
		var id: String=parent.ECHO_IDS[index]
		if not route.deaths.has(id): return "Stage clear requires actual required Echo defeat"
		var clear: Variant=route.clears[index]
		if not clear is Dictionary or not Value.keys_error(clear,["stage_id","clock_s","hero_position"]).is_empty() or clear.get("stage_id")!=parent.STAGE_IDS[index] or not Receipt.clock_valid(clear.get("clock_s")) or clear.clock_s<route.deaths[id].clock_s or clear.clock_s>clock or clear.clock_s<=previous or not Value.is_vector3(clear.get("hero_position")): return "Exact chronological genuine stage-clear prefix required"
		var at: Vector3=Value.read_vector3(clear.hero_position)
		if absf(at.y)>0.2 or not parent.FLOOR_RECT.has_point(Vector2(at.x,at.z)) or (Exact.exact_equal(clear.clock_s,clock) and not Exact.exact_equal(clear.hero_position,player.motion.position)): return "Actual grounded stage-clear sample must join current paired Hero"
		previous=clear.clock_s
	if not route.clears.is_empty():
		if local.pulse.mechanism.status=="running": return "First held pulse must retire before first coherent stage checkpoint"
		if local.pulse.mechanism.cycle==1 and local.pulse.mechanism.exchange.start_s>route.clears[0].clock_s: return "First-stage pulse cannot be admitted after leaving its stage"
	if route.active_stage==parent.STAGE_IDS.size():
		if route.exit_state not in ["available","active","spent"]: return "Final required Echo clear must enable contact exit"
	elif route.exit_state!="clear" or not route.contact.is_empty(): return "Incomplete stages cannot enable or consume exit"
	if route.exit_state in ["active","spent"]:
		if not Value.keys_error(route.contact,["clock_s","hero_position"]).is_empty() or not Receipt.clock_valid(route.contact.get("clock_s")) or route.contact.clock_s<=previous or route.contact.clock_s>clock or not Value.is_vector3(route.contact.get("hero_position")): return "Grounded contact must occur on a strictly later native tick"
		var at: Vector3=Value.read_vector3(route.contact.hero_position)
		if absf(at.y)>0.2 or not parent.EXIT_RECT.has_point(Vector2(at.x,at.z)) or (Exact.exact_equal(route.contact.clock_s,clock) and not Exact.exact_equal(route.contact.hero_position,player.motion.position)): return "Actual contact position must join exit and current paired Hero"
	elif not route.contact.is_empty(): return "Unused exit cannot retain contact authority"
	return ""

func _view_error(local: Dictionary, parent) -> String:
	if not Value.keys_error(local.view,["echoes","pulse"]).is_empty() or not local.view.get("echoes") is Dictionary or not Value.keys_error(local.view.echoes,parent.ECHO_IDS).is_empty(): return "Exact retained native source render-history map required"
	for id: String in parent.ECHO_IDS:
		var error: String=_positions_error(local.view.echoes[id],parent)
		if not error.is_empty(): return error
		if local.view.echoes[id].is_empty()!=(local.sources[id].playback.status=="cycle_ready"): return "Only ready current generation omits admitted response history"
	var error: String=_positions_error(local.view.pulse,parent)
	if not error.is_empty(): return error
	return "" if local.view.pulse.is_empty()==(local.pulse.mechanism.cycle==0) else "Pulse history must match actual admission"

func _positions_error(points: Variant, parent) -> String:
	if not points is Array or points.size()>12: return "Bounded historical response positions required"
	var seen: Array=[]
	for value: Variant in points:
		if not Value.is_vector3(value): return "Finite native response-point transport required"
		var at: Vector3=Value.read_vector3(value)
		if seen.has(at) or absf(at.y)>0.05 or not parent.FLOOR_RECT.grow(-0.33).has_point(Vector2(at.x,at.z)): return "Unique historical response points must retain firm support"
		seen.append(at)
	return ""

func prepare_sources(local: Dictionary, parent, player: Dictionary) -> String:
	var error: String=record_error(local,parent,player,false)
	if not error.is_empty(): return error
	for id: String in parent.ECHO_IDS:
		if parent.sources[id].call("source_cycles_managed") or not parent.sources[id].call("get_authored_cycle_restore_recipe").is_empty() or parent.sources[id].call("state").get("status")!="idle": return "All immutable Echo recipients must remain fresh/untracked before preparation"
	for id: String in parent.ECHO_IDS:
		var packet: Dictionary=local.sources[id]
		if not parent.sources[id].call("prepare_authored_restore",packet.playback,parent.threat_scheduler,{"hero":parent.hero},parent.scheduler_bindings().floors.values(),parent.echo_context(id,packet.actor.generation)): return id+": "+String(parent.sources[id].get("source_snapshot_error"))+"; "+String(parent.sources[id].get("last_error"))
	return record_error(local,parent,player,true)

func restore_local(local: Dictionary, parent, player: Dictionary) -> bool:
	last_error=record_error(local,parent,player)
	if last_error.is_empty() and not Exact.exact_equal(player,parent.hero.snapshot_state()): last_error="Quietly restore actual validated Hero first"
	if not last_error.is_empty(): return false
	for id: String in parent.SOURCE_IDS:
		var packet: Dictionary=local.sources[id]
		var accepted: bool=parent.sources[id].call("restore_source_physical",packet.actor,player,local.scheduler,packet.playback) if parent.ECHO_IDS.has(id) else parent.sources[id].call("apply_validated_state",packet.actor)
		if not accepted: last_error="Prevalidated actual source physical commit declined: "+id; return false
	var bindings: Dictionary=parent.scheduler_bindings()
	if not parent.threat_scheduler.restore_state(local.scheduler,bindings): last_error=parent.threat_scheduler.last_snapshot_error; return false
	for id: String in parent.ECHO_IDS:
		var packet: Dictionary=local.sources[id]
		if not parent.sources[id].call("restore_state",packet.playback,parent.threat_scheduler,local.scheduler,bindings,{"hero":parent.hero},bindings.floors.values(),parent.echo_context(id,packet.actor.generation)) or not parent.sources[id].call("verify_restored_source_phase",packet.actor): last_error=id+": "+String(parent.sources[id].get("last_snapshot_error"))+"; "+String(parent.sources[id].get("source_snapshot_error")); return false
	if not parent.mechanism.restore_state(local.pulse.mechanism,bindings): last_error=parent.mechanism.last_snapshot_error; return false
	if not parent.sources[parent.STALKER_ID].call("refresh_presentation"): last_error="Native Stalker quiet presentation declined"; return false
	parent.apply_codec_control(local)
	var actual_scheduler: Dictionary=parent.threat_scheduler.snapshot_state(bindings)
	if not Exact.exact_equal(actual_scheduler,local.scheduler): last_error="Final actual complete native journal differs"; return false
	for id: String in parent.SOURCE_IDS:
		if parent.ECHO_IDS.has(id):
			var playback: Dictionary=parent.sources[id].call("snapshot_state",actual_scheduler,bindings)
			var actor: Dictionary=parent.sources[id].call("capture_source",player,actual_scheduler,playback)
			if not Exact.exact_equal(playback,local.sources[id].playback) or not Exact.exact_equal(actor,local.sources[id].actor): last_error="Final actual Echo physical/Playback differs: "+id; return false
		elif not Exact.exact_equal(parent.sources[id].call("snapshot_state"),local.sources[id].actor): last_error="Final actual Stalker physical packet differs"; return false
	if not Exact.exact_equal(parent.mechanism.snapshot_state(bindings),local.pulse.mechanism): last_error="Final actual pulse mechanism differs"; return false
	return true

func progress_error(local: Dictionary, progress: Dictionary, parent) -> String:
	var error: String=_aggregate_transport_error(local)
	if error.is_empty(): error=Receipt.transport_error(progress)
	if not error.is_empty(): return error
	if not local.get("route") is Dictionary or not Value.is_integer(local.route.get("active_stage"),0,parent.STAGE_IDS.size()): return "Typed stage route required for progression"
	if not Value.keys_error(progress,["completed","completion_id","contact_exit_id","checkpoint_id","checkpoint_kind","checkpoint_ids"]).is_empty(): return "Closed canonical O3 progress fields required"
	var expected: Dictionary={}
	var count: int=mini(local.route.active_stage,parent.CHECKPOINT_IDS.size())
	for index: int in range(count): expected[parent.CHECKPOINT_IDS[index]]="encounter"
	var completed: bool=local.route.active_stage==parent.STAGE_IDS.size()
	if not progress.completed is bool or progress.completed!=completed or progress.completion_id!=(parent.COMPLETION_ID if completed else "") or not Exact.exact_equal(progress.checkpoint_ids,expected) or progress.checkpoint_id!=(parent.CHECKPOINT_IDS[count-1] if count>0 else "") or progress.checkpoint_kind!=("encounter" if count>0 else "") or progress.contact_exit_id!=(parent.EXIT_ID if local.route.get("exit_state")=="spent" else ""): return "O3 canonical progress must equal actual earned stage prefix and later contact"
	return ""

func _access_error(parent) -> String:
	if typeof(parent)!=TYPE_OBJECT or not is_instance_valid(parent) or not parent is CinderLevel or parent.get_script()==null or parent.get_script().resource_path!=PARENT or not parent.is_inside_tree() or not parent.is_node_ready() or parent.is_queued_for_deletion() or not parent.get_tree().paused: return "Actual paused original O3 native parent required"
	return parent.runtime_error()

func _aggregate_transport_error(local: Dictionary) -> String:
	# This is a complete parent aggregate, not a single terminal receipt.
	# Native source, Playback and Scheduler journal validators retain their
	# original one-MiB limits. Whole campaign packets use canonical ExactJson.
	return "Whole O3 aggregate exceeds canonical exact transport bounds" if ExactJson.stringify(local).is_empty() else ""
