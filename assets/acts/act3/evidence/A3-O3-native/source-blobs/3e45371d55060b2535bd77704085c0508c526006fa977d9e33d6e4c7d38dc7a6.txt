extends RefCounted
## Closed O3 prototype pair. Native Source2/Playback2/journal and Lane codecs
## remain authoritative; this joins one actual world and its owned view/control.
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/combat/authored_enemy_sequence.gd")
const Receipt = preload("res://scripts/combat/authored_echo_terminal_receipt.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Echo = preload("res://scripts/acts/act3/mirror_echo.gd")
const API: String = "act3-irontick-reflection-pair-1"
const PARENT: String = "res://scripts/acts/act3/irontick_reflection.gd"
const KEYS: Array[String] = ["api_revision","schema_version","world","scheduler","echo","pulse","view"]
const WORLD_KEYS: Array[String] = ["data_sha256","encounter_id","world_revision","profile_id","collision_fingerprint","floor_signature"]
var last_error: String = ""

func capture(parent, player: Dictionary) -> Dictionary:
	last_error=_access_error(parent)
	if last_error.is_empty(): last_error=parent.hero.snapshot_error(player)
	if last_error.is_empty() and not Exact.exact_equal(player,parent.hero.snapshot_state()): last_error="Writer requires the actual current paired Hero"
	if not last_error.is_empty(): return {}
	var bindings: Dictionary=parent.scheduler_bindings()
	var scheduler: Dictionary=parent.threat_scheduler.snapshot_state(bindings)
	if scheduler.is_empty(): last_error=parent.threat_scheduler.last_snapshot_error; return {}
	var playback: Dictionary=parent.echo.call("snapshot_state",scheduler,bindings)
	var actor: Dictionary=parent.echo.call("capture_source",player,scheduler,playback)
	var mechanism: Dictionary=parent.mechanism.snapshot_state(bindings)
	if playback.is_empty() or actor.is_empty() or mechanism.is_empty(): last_error=String(parent.echo.get("source_snapshot_error"))+"; "+String(parent.echo.get("last_snapshot_error"))+"; "+parent.mechanism.last_snapshot_error; return {}
	var retry: Dictionary=parent.capture_retry_times()
	var result: Dictionary={"api_revision":API,"schema_version":1,"world":parent.native_world(),"scheduler":scheduler,"echo":{"kind":"echo","actor":actor,"playback":playback,"retry_at_s":retry.echo},"pulse":{"eligible_at_s":parent.PULSE_DUE_S,"mechanism":mechanism,"retry_at_s":retry.pulse},"view":parent.capture_view()}
	last_error=record_error(result,parent,player)
	return result if last_error.is_empty() else {}

func record_error(local: Dictionary, parent, player: Dictionary, paired: bool = true) -> String:
	var error: String=_access_error(parent)
	if error.is_empty(): error=Receipt.transport_error(local)
	if error.is_empty(): error=Receipt.transport_error(player)
	if error.is_empty(): error=parent.hero.snapshot_error(player)
	if not error.is_empty(): return error
	if not Value.keys_error(local,KEYS).is_empty() or local.get("api_revision")!=API or not local.get("schema_version") is int or local.schema_version!=1: return "Closed first-court O3 local schema1 required"
	for key: String in ["world","scheduler","echo","pulse","view"]:
		if not local[key] is Dictionary: return "Every complete typed O3 native unit is required: "+key
	if not Value.keys_error(local.world,WORLD_KEYS).is_empty() or not local.world.get("profile_id") is String or not local.world.get("collision_fingerprint") is Dictionary or not local.world.get("floor_signature") is Array: return "Closed immutable native shore/profile recipe required"
	if not Exact.exact_equal(local.world,parent.native_world()): return "Actual original shore/floor/profile/epoch differs"
	if local.world.data_sha256!=FileAccess.get_sha256(parent.DATA_PATH) or local.world.encounter_id!=parent.ENCOUNTER_ID or not local.world.world_revision is int or local.world.world_revision!=parent.WORLD_REVISION: return "Exact O3 authoring/encounter/world revision required"
	var signature: Dictionary=Footprint.floor_signature(parent.get_parent() as Node3D,parent.scheduler_bindings().floors.values())
	if not signature.get("accepted",false) or not Exact.exact_equal(signature.get("signature"),local.world.floor_signature) or not Exact.exact_equal(parent.threat_scheduler.pure_collision_fingerprint(parent.get_parent() as Node3D),local.world.collision_fingerprint): return "Actual complete permanent floor/collision binding differs"
	if not Receipt.clock_valid(local.scheduler.get("clock_s")) or not local.scheduler.get("profile") is Dictionary or not Exact.exact_equal(local.scheduler.profile,Difficulty.new().profile(local.world.profile_id)) or local.scheduler.get("encounter_id")!=parent.ENCOUNTER_ID or not Exact.exact_equal(local.scheduler.get("world_revision"),parent.WORLD_REVISION) or not Exact.exact_equal(local.scheduler.get("collision"),local.world.collision_fingerprint) or not player.get("world_actions") is Dictionary or not Exact.exact_equal(player.world_actions.get("clock_s"),local.scheduler.clock_s): return "Actual profile/world and exact Hero/Scheduler native tick required"
	if not Value.keys_error(local.echo,["kind","actor","playback","retry_at_s"]).is_empty() or local.echo.get("kind")!="echo" or not local.echo.get("actor") is Dictionary or not local.echo.get("playback") is Dictionary: return "Complete typed managed Source2/Playback2 pair required"
	if not Value.keys_error(local.pulse,["eligible_at_s","mechanism","retry_at_s"]).is_empty() or not Exact.exact_equal(local.pulse.get("eligible_at_s"),parent.PULSE_DUE_S) or not local.pulse.get("mechanism") is Dictionary: return "Independent immutable pulse schedule and complete Lane snapshot required"
	for retry: Variant in [local.echo.retry_at_s,local.pulse.retry_at_s]:
		if not retry is float or not Value.in_range(retry,0.0,float(local.scheduler.clock_s)+parent.RETRY_S): return "Finite bounded actual admission retry clocks required"
	if local.echo.actor.get("source_id")!=parent.ECHO_ID or local.echo.actor.get("source_epoch")!=parent.ECHO_EPOCH or not local.echo.actor.get("generation") is int or local.echo.actor.generation!=1: return "One retained original managed Echo generation required in this prototype"
	error=parent.echo.call("source_record_error",local.echo.actor,player,local.scheduler,local.echo.playback)
	if not error.is_empty(): return error
	var journal: Variant=local.scheduler.get("authored_source_cycles")
	if local.scheduler.get("schema_version")!=3 or not journal is Dictionary or not journal.get("sources") is Array or journal.sources.size()!=1 or not journal.sources[0] is Dictionary or journal.sources[0].get("source_id")!=parent.ECHO_ID: return "Exactly one complete retained managed Scheduler3 source journal required"
	var staged: Dictionary=parent.scheduler_bindings()
	staged.hero_positions={"hero":Value.read_vector3(player.motion.position)}
	staged.authored_owner_bindings={parent.ECHO_ID:parent.echo.call("staged_source_binding",local.echo.actor,player,local.scheduler,local.echo.playback)}
	staged.authored_cycle_playback_ids={parent.ECHO_ID:local.echo.playback.get("playback_id")}
	error=parent.threat_scheduler.snapshot_error(local.scheduler,staged)
	if error.is_empty(): error=parent.mechanism.snapshot_error(local.pulse.mechanism,staged,local.scheduler)
	if not error.is_empty(): return error
	var pulse: Dictionary=local.pulse.mechanism
	if not pulse.get("cycle") is int or pulse.cycle not in [0,1]: return "At most one independently admitted pulse in this first-court prototype"
	if pulse.cycle==1:
		if not pulse.get("exchange") is Dictionary or not Receipt.clock_valid(pulse.exchange.get("start_s")) or pulse.exchange.start_s<parent.PULSE_DUE_S: return "Actual pulse admission cannot precede its own eligibility"
	error=_view_error(local,parent)
	if not error.is_empty(): return error
	if paired: return parent.echo.call("snapshot_error",local.echo.playback,parent.threat_scheduler,local.scheduler,staged,{"hero":parent.hero},staged.floors.values(),parent.echo_context(local.echo.actor.generation))
	return ""

func _view_error(local: Dictionary, parent) -> String:
	if not Value.keys_error(local.view,["echo","pulse"]).is_empty(): return "Closed historical render points required"
	for key: String in ["echo","pulse"]:
		var points: Variant=local.view[key]
		if not points is Array or points.size()>12: return "Bounded native historical response corners required"
		var unique: Array=[]
		for point: Variant in points:
			if not Value.is_vector3(point): return "Finite response-point transport required"
			var native: Vector3=Value.read_vector3(point)
			if unique.has(native) or absf(native.y)>0.05 or not parent.FLOOR_RECT.grow(-0.33).has_point(Vector2(native.x,native.z)): return "Historical response points remain on the permanent firm shore"
			unique.append(native)
	var ready: bool=local.echo.playback.get("status")=="cycle_ready"
	if local.view.echo.is_empty()!=ready: return "Only an unadmitted ready Echo has no committed response history"
	if local.view.pulse.is_empty()!=(local.pulse.mechanism.cycle==0): return "Only an unadmitted pulse has no committed response history"
	return ""

func prepare_sources(local: Dictionary, parent, player: Dictionary) -> String:
	var error: String=record_error(local,parent,player,false)
	if not error.is_empty(): return error
	if parent.echo.call("source_cycles_managed") or not parent.echo.call("get_authored_cycle_restore_recipe").is_empty() or parent.echo.call("state").get("status")!="idle": return "Only one fresh untracked native recipient may prepare saved history"
	if not parent.echo.call("prepare_authored_restore",local.echo.playback,parent.threat_scheduler,{"hero":parent.hero},parent.scheduler_bindings().floors.values(),parent.echo_context(local.echo.actor.generation)): return String(parent.echo.get("source_snapshot_error"))+"; "+String(parent.echo.get("last_error"))
	return record_error(local,parent,player,true)

func restore_local(local: Dictionary, parent, player: Dictionary) -> bool:
	last_error=record_error(local,parent,player)
	if last_error.is_empty() and not Exact.exact_equal(player,parent.hero.snapshot_state()): last_error="Quietly restore the independently validated actual Hero first"
	if not last_error.is_empty(): return false
	if not parent.echo.call("restore_source_physical",local.echo.actor,player,local.scheduler,local.echo.playback): last_error="Prevalidated actual Echo physical commit declined"; return false
	var bindings: Dictionary=parent.scheduler_bindings()
	if not parent.threat_scheduler.restore_state(local.scheduler,bindings): last_error=parent.threat_scheduler.last_snapshot_error; return false
	var recipe: Dictionary=parent.echo.call("get_authored_cycle_restore_recipe")
	var intermediate: Dictionary=parent.threat_scheduler.snapshot_state_for_authored_restore(parent.echo,bindings) if not recipe.is_empty() else parent.threat_scheduler.snapshot_state(bindings)
	if not Exact.exact_equal(intermediate,local.scheduler): last_error="Actual intermediate complete journal differs after physical/Scheduler commit"; return false
	if not parent.echo.call("restore_state",local.echo.playback,parent.threat_scheduler,local.scheduler,bindings,{"hero":parent.hero},bindings.floors.values(),parent.echo_context(local.echo.actor.generation)) or not parent.echo.call("verify_restored_source_phase",local.echo.actor): last_error=String(parent.echo.get("last_snapshot_error"))+"; "+String(parent.echo.get("source_snapshot_error")); return false
	if not parent.mechanism.restore_state(local.pulse.mechanism,bindings): last_error=parent.mechanism.last_snapshot_error; return false
	parent.apply_codec_control(local)
	var actual_scheduler: Dictionary=parent.threat_scheduler.snapshot_state(bindings)
	var actual_playback: Dictionary=parent.echo.call("snapshot_state",actual_scheduler,bindings)
	var actual_actor: Dictionary=parent.echo.call("capture_source",player,actual_scheduler,actual_playback)
	if not Exact.exact_equal(actual_scheduler,local.scheduler) or not Exact.exact_equal(actual_playback,local.echo.playback) or not Exact.exact_equal(actual_actor,local.echo.actor) or not Exact.exact_equal(parent.mechanism.snapshot_state(bindings),local.pulse.mechanism): last_error="Final actual full native quiet unit differs"; return false
	return true

func progress_error(progress: Dictionary) -> String:
	var empty: Dictionary={"completed":false,"completion_id":"","contact_exit_id":"","checkpoint_id":"","checkpoint_kind":"","checkpoint_ids":{}}
	return "" if Exact.exact_equal(progress,empty) else "First-court prototype creates no campaign progress or final-stage receipt"

func _access_error(parent) -> String:
	if not is_instance_valid(parent) or parent.get_script()==null or parent.get_script().resource_path!=PARENT or not parent.is_inside_tree() or not parent.is_node_ready() or parent.is_queued_for_deletion() or not parent.get_tree().paused: return "Actual paused original O3 native recipient required"
	return parent.runtime_error()
