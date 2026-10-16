extends RefCounted
## SOURCE-ONLY whole parent transport. Current native topology only; old complete
## units are normally disposed and represented by closed earned phase metadata.
## Candidate/native qualification remains required; no partial/filtered fallback.
const Value = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Policy = preload("res://scripts/acts/act3/crystalman_phase_policy.gd")
const Receipt = preload("res://scripts/combat/authored_echo_terminal_receipt.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const ApproachCodec = preload("res://scripts/acts/act3/crystalman_approach_codec.gd")
const LEGACY_API: String = "act3-crystalman-parent-local-1"
const API: String = "act3-crystalman-parent-local-2"
const POLICY_API: String = "act3-crystalman-approach-policy-1"
const CANONICAL_RECIPE: String = "canonical-approach-1"
const CHALLENGE_RECIPE: String = "challenge-west-inset-1"
const KEYS: Array[String] = ["api_revision","schema_version","world","route","current_unit","presentation"]
const POLICY_KEYS: Array[String] = ["api_revision","schema_version","profile","recipe_id"]
const PROFILE_KEYS: Array[String] = ["id","name","raw_damage_multiplier","windup_multiplier","recovery_multiplier","reserved_threat_budget","commit_stagger_s","arrangement"]
const WORLD_KEYS: Array[String] = ["layout_sha256","level_id","world_revision","floor_id","floor_signature","permanent_box","permanent_center","blockers","source_scripts"]
const ROUTE_KEYS: Array[String] = ["stage","entries","regular_metadata","phase_metadata","pending_checkpoint","phase_observed","exit_state","contact"]
var last_error: String = ""


## Pure closed construction selection. This grants no native/route authority.
## A fresh attempt resolves one canonical profile before Approach._ready copies rows.
static func fresh_selection(profile_id: String) -> Dictionary:
	var profile: Dictionary = Difficulty.new().profile(profile_id)
	if not _profile_error(profile).is_empty(): return {}
	var policy: Dictionary = {"api_revision":POLICY_API,"schema_version":1,"profile":profile.duplicate(true),"recipe_id":_recipe_id(profile_id)}
	return {"legacy":false,"policy":policy,"profile":profile.duplicate(true)}

static func selection_error(selection: Dictionary) -> String:
	var error: String = Receipt.transport_error(selection)
	if not error.is_empty(): return error
	if not Value.keys_error(selection,["legacy","policy","profile"]).is_empty() or not selection.get("legacy") is bool or not selection.get("policy") is Dictionary or not selection.get("profile") is Dictionary:
		return "Closed typed legacy/policy/full-profile selection required"
	if selection.legacy:
		if not selection.policy.is_empty(): return "Literal legacy selection has no new policy"
		# Disposed legacy stages have no retained serialized Approach profile.
		return "" if selection.profile.is_empty() else _profile_error(selection.profile)
	var policy: Dictionary = selection.policy
	if not Value.keys_error(policy,POLICY_KEYS).is_empty() or not policy.get("api_revision") is String or policy.api_revision != POLICY_API or not policy.get("schema_version") is int or policy.schema_version != 1 or not policy.get("profile") is Dictionary or not policy.get("recipe_id") is String:
		return "Closed typed four-key Approach policy1 required"
	error = _profile_error(policy.profile)
	if not error.is_empty(): return error
	if policy.recipe_id != _recipe_id(policy.profile.id): return "Approach policy requires its exact finite profile recipe"
	if not same(selection.profile,policy.profile): return "Selection and policy must retain the same full canonical profile"
	return ""

static func _profile_error(profile: Dictionary) -> String:
	if not Value.keys_error(profile,PROFILE_KEYS).is_empty() or not profile.get("id") is String or profile.id not in ["assisted","standard","challenge"] or not profile.get("name") is String or not profile.get("arrangement") is String:
		return "Full typed eight-key canonical Approach profile required"
	for key: String in ["raw_damage_multiplier","windup_multiplier","recovery_multiplier","reserved_threat_budget","commit_stagger_s"]:
		if not profile.get(key) is float or not is_finite(profile[key]) or profile[key] <= 0.0:
			return "Canonical native float profile fields required"
	var canonical: Dictionary = Difficulty.new().profile(profile.id)
	return "" if not canonical.is_empty() and same(profile,canonical) else "Approach profile must equal the complete current canonical profile"

static func _recipe_id(profile_id: String) -> String:
	return CHALLENGE_RECIPE if profile_id == "challenge" else (CANONICAL_RECIPE if profile_id in ["assisted","standard"] else "")

## Authenticate the saved mode/profile before parent-dependent strict world
## validation or adding Approach (whose _ready copies selected source rows).
func constructor_selection(unit: Dictionary) -> Dictionary:
	last_error = Receipt.transport_error(unit)
	if not last_error.is_empty(): return {}
	var legacy: bool = unit.get("api_revision") == LEGACY_API
	var keys: Array[String] = KEYS.duplicate()
	if not legacy: keys.append("approach_policy")
	if not Value.keys_error(unit,keys).is_empty() or not unit.get("api_revision") is String or unit.api_revision not in [LEGACY_API,API] or not unit.get("schema_version") is int or unit.schema_version != (1 if legacy else 2):
		return failed("Closed literal parent1/six keys or parent2/seven keys required")
	for key: String in ["world","route","current_unit","presentation"]:
		if not unit.get(key) is Dictionary: return failed("Typed whole parent branch required: "+key)
	var world: Dictionary = unit.world
	if not Value.keys_error(world,WORLD_KEYS).is_empty() or not world.get("layout_sha256") is String or not world.get("level_id") is String or world.level_id != "A3-L5" or not world.get("world_revision") is int or world.world_revision != 1 or not world.get("floor_id") is String:
		return failed("Closed original parent world identity required")
	for key: String in ["floor_signature","permanent_box","permanent_center","blockers","source_scripts"]:
		if not world.get(key) is Array: return failed("Typed original parent world branch required: "+key)
	var route: Dictionary = unit.route
	if not Value.keys_error(route,ROUTE_KEYS).is_empty() or not route.get("stage") is int or route.stage < 0 or route.stage > 4 or not route.get("entries") is Array or not route.get("regular_metadata") is Dictionary or not route.get("phase_metadata") is Array or not route.get("pending_checkpoint") is int or not route.get("phase_observed") is bool or not route.get("exit_state") is String or not route.get("contact") is Dictionary:
		return failed("Closed typed five-stage constructor route required")
	if not Value.keys_error(unit.current_unit,["kind","state"]).is_empty() or not unit.current_unit.get("kind") is String or unit.current_unit.kind != kind(route.stage) or not unit.current_unit.get("state") is Dictionary or ((route.stage == 4) != unit.current_unit.state.is_empty()):
		return failed("Exactly entitled complete current constructor topology required")
	var profile: Dictionary = {}
	if route.stage < 2:
		var regular: Dictionary = unit.current_unit.state
		if not Value.keys_error(regular,ApproachCodec.KEYS).is_empty() or regular.get("api_revision") != ApproachCodec.API or not regular.get("schema_version") is int or regular.schema_version != 1 or not regular.get("stage") is int or regular.stage != route.stage+1 or not regular.get("world") is Dictionary or not regular.get("scheduler") is Dictionary or not regular.world.get("profile_id") is String or not regular.scheduler.get("profile") is Dictionary:
			return failed("Complete entitled regular saved profile constructor required")
		profile = regular.scheduler.profile.duplicate(true)
		last_error = _profile_error(profile)
		if not last_error.is_empty(): return {}
		if profile.id != regular.world.profile_id: return failed("Saved full Approach Scheduler/world profiles differ")
	var selection: Dictionary = {"legacy":legacy,"policy":{},"profile":profile}
	if not legacy:
		if not unit.get("approach_policy") is Dictionary: return failed("New parent requires its complete Approach policy")
		selection.policy = unit.approach_policy.duplicate(true)
		selection.profile = selection.policy.get("profile",{}).duplicate(true) if selection.policy.get("profile") is Dictionary else {}
	last_error = selection_error(selection)
	if not last_error.is_empty(): return {}
	if not legacy and route.stage < 2 and not same(profile,selection.profile): return failed("New Approach policy and saved whole regular profile differ")
	return selection.duplicate(true)

func _retained_selection(parent,stage: int) -> Dictionary:
	if not parent.has_method("crystalman_approach_constructor"): return failed("Retained immutable parent Approach constructor required")
	var actual: Variant = parent.call("crystalman_approach_constructor")
	if not actual is Dictionary: return failed("Typed retained Approach constructor required")
	last_error = selection_error(actual)
	if not last_error.is_empty(): return {}
	var retained: Dictionary = actual.duplicate(true)
	# This comparison copy never rewrites retained instance policy/profile.
	if retained.legacy and stage >= 2: retained.profile = {}
	return retained

func capture(parent,player: Dictionary,camera: Camera3D=null,hud: GameHUD=null,optical: bool=true) -> Dictionary:
	last_error=parent.parent_boundary_error()
	if last_error.is_empty(): last_error=parent.hero.snapshot_error(player)
	if last_error.is_empty() and not same(player,parent.hero.snapshot_state()): last_error="Complete actual outer Hero required"
	if last_error.is_empty() and optical:
		if camera==null: camera=parent.shared_shell.get("camera") as Camera3D
		if hud==null: hud=parent.shared_shell.get("hud") as GameHUD
		last_error=parent.candidate_presentation_error(camera,hud)
	if not last_error.is_empty(): return {}
	var route: Dictionary=parent.parent_owned_state()
	var selection: Dictionary=_retained_selection(parent,route.stage)
	if selection.is_empty(): return {}
	var current: Dictionary={"kind":kind(route.stage),"state":{}}
	if is_instance_valid(parent.current_unit):
		current.state=parent.current_unit.call("capture_native_state",player,false)
		if current.state.is_empty(): return failed("Complete current unit refused: "+String(parent.current_unit.call("native_capture_error")))
	var local: Dictionary={"api_revision":LEGACY_API if selection.legacy else API,"schema_version":1 if selection.legacy else 2,"world":native_world(parent),"route":route,"current_unit":current,"presentation":parent.scenery.call("presentation_state")}
	if not selection.legacy: local["approach_policy"]=selection.policy.duplicate(true)
	last_error=record_error(local,parent,player)
	return local if last_error.is_empty() else {}

func failed(reason: String) -> Dictionary:
	last_error=reason
	return {}

func header_error(unit: Dictionary,parent,player: Dictionary) -> String:
	var error: String=parent.parent_boundary_error()
	if error.is_empty(): error=Receipt.transport_error(unit)
	if error.is_empty(): error=parent.hero.snapshot_error(player)
	if not error.is_empty(): return error
	var selected: Dictionary=constructor_selection(unit)
	if selected.is_empty(): return last_error
	var retained: Dictionary=_retained_selection(parent,unit.route.stage)
	if retained.is_empty(): return last_error
	if not same(selected,retained): return "Saved parent construction differs from its retained immutable selection"
	for key: String in ["world","route","current_unit","presentation"]:
		if not unit.get(key) is Dictionary: return "Typed whole parent branch required: "+key
	if not same(unit.world,native_world(parent)): return "Exact authored layout/floor/blockers/current source scripts differ"
	if not Value.keys_error(unit.current_unit,["kind","state"]).is_empty() or not unit.current_unit.get("state") is Dictionary or not unit.route.get("stage") is int or unit.current_unit.get("kind")!=kind(unit.route.stage): return "Only exactly entitled whole current topology may restore"
	error=route_error(unit,parent,player)
	if not error.is_empty(): return error
	if (unit.route.stage==4)!=unit.current_unit.state.is_empty(): return "Bare coda has no current native unit; combat stages require one complete unit"
	return String(parent.scenery.call("presentation_error",unit.presentation,unit.route.stage))

func record_error(unit: Dictionary,parent,player: Dictionary) -> String:
	var error: String=header_error(unit,parent,player)
	if not error.is_empty(): return error
	if unit.route.stage==4:
		return "" if not is_instance_valid(parent.current_unit) else "No disposed previous native unit may survive bare stage"
	if not is_instance_valid(parent.current_unit): return "Exact current native recipient missing"
	if unit.route.stage<2:
		if parent.current_unit.get_script()!=parent.Approach or unit.current_unit.state.get("stage")!=unit.route.stage+1: return "Exact current original regular stage required"
	else:
		if parent.current_unit.get_script()!=parent.CapturePhase or parent.current_unit.get("capture_slots")!=unit.route.stage-1: return "Exact one/two-slot current native capture recipient required"
	return String(parent.current_unit.call("native_state_error",unit.current_unit.state,player))

func route_error(unit: Dictionary,parent,player: Dictionary) -> String:
	var route: Dictionary=unit.route
	if not Value.keys_error(route,ROUTE_KEYS).is_empty() or not route.get("stage") is int or route.stage<0 or route.stage>4 or not route.get("entries") is Array or not route.get("regular_metadata") is Dictionary or not route.get("phase_metadata") is Array or not route.get("pending_checkpoint") is int or route.pending_checkpoint < -1 or route.pending_checkpoint > route.stage or not route.get("phase_observed") is bool or not route.get("exit_state") is String or not route.get("contact") is Dictionary: return "Closed typed five-stage route required"
	if route.entries.size()!=route.stage+1 or route.phase_metadata.size()!=maxi(0,route.stage-2): return "Monotonic five-entry/two-phase entitlement required"
	var previous: float=-1.0
	for index: int in range(route.entries.size()):
		var row: Variant=route.entries[index]
		if not row is Dictionary or not Value.keys_error(row,["stage","actor_clock_s","hero_position"]).is_empty() or not row.get("stage") is int or row.get("stage")!=index or not Receipt.clock_valid(row.get("actor_clock_s")) or row.actor_clock_s<previous or row.actor_clock_s>player.world_actions.clock_s or not Value.is_vector3(row.get("hero_position")): return "Actual bounded ordered entry receipts required"
		var at: Vector3=Value.read_vector3(row.hero_position)
		if not parent.FULL_RECT.has_point(Vector2(at.x,at.z)) or absf(at.y)>0.2: return "Entry receipt keeps firm ordinary ground"
		previous=row.actor_clock_s
	if route.stage<2:
		if not route.regular_metadata.is_empty(): return "No unearned disposed regular topology metadata"
	else:
		var regular: Dictionary=route.regular_metadata
		if not Value.keys_error(regular,["source_ids","deaths","completed_at_actor_s","completed_at_unit_s","disposition","journal_sha256"]).is_empty() or not same(regular.get("source_ids"),["l5-offered-echo","l5-plain-stalker","l5-plain-echo"]) or regular.get("disposition")!="whole_unit_disposal" or not regular.get("deaths") is Dictionary or not Value.keys_error(regular.deaths,regular.source_ids).is_empty() or not Receipt.clock_valid(regular.get("completed_at_actor_s")) or not Receipt.clock_valid(regular.get("completed_at_unit_s")) or regular.completed_at_actor_s>player.world_actions.clock_s or not sha_valid(regular.get("journal_sha256")): return "Closed genuinely retired regular route metadata required"
		for id: String in regular.deaths:
			var death: Variant=regular.deaths[id]
			if not death is Dictionary or not Value.keys_error(death,["clock_s","source_position"]).is_empty() or not Receipt.clock_valid(death.get("clock_s")) or death.clock_s>regular.completed_at_unit_s or not Value.is_vector3(death.get("source_position")): return "Original source death metadata required"
		# New format only: the two stationary Echo deaths join their selected
		# native knots. Dynamic C50 death stays literal actual history.
		if unit.get("api_revision") == API:
			var rows: Dictionary=parent.crystalman_source_rows()
			for id: String in ["l5-offered-echo","l5-plain-echo"]:
				if not rows.get(id) is Dictionary or not Value.is_vector3(rows[id].get("fixed_knot_world")): return "Retained selected fixed Echo knot required"
				var actual: Array=Value.vector3(Value.read_vector3(regular.deaths[id].source_position))
				var expected: Array=Value.vector3(Value.read_vector3(rows[id].fixed_knot_world))
				if not same(actual,expected): return "Retired fixed Echo death differs from its selected native knot: "+id
	var phase_clock: float=-1.0
	for index: int in range(route.phase_metadata.size()):
		if not route.phase_metadata[index] is Dictionary: return "Closed phase metadata required"
		var error: String=Policy.phase_metadata_error(route.phase_metadata[index],index+1)
		if not error.is_empty(): return error
		var at: float=route.phase_metadata[index].completed_at_actor_s
		if at<phase_clock or at>player.world_actions.clock_s: return "Phase actor clocks retain actual monotonic order"
		phase_clock=at
	if route.phase_observed:
		var current: Dictionary=unit.current_unit.state
		if route.stage not in [2,3] or not current.get("owned") is Dictionary or current.owned.get("phase")!="spent": return "Pending genuine tether observation belongs to the settled current spent unit"
	if route.stage<4:
		if route.exit_state!="clear" or not route.contact.is_empty(): return "Exit/contact cannot precede final local tether"
	else:
		if route.exit_state not in ["available","active","spent"]: return "Real contact state required after both local releases"
		if route.exit_state=="available":
			if not route.contact.is_empty(): return "Uncontacted exit has no contact receipt"
		else:
			if not Value.keys_error(route.contact,["actor_clock_s","hero_position","exit_id"]).is_empty() or route.contact.get("exit_id")!=parent.EXIT_ID or not Receipt.clock_valid(route.contact.get("actor_clock_s")) or route.contact.actor_clock_s>player.world_actions.clock_s or not Value.is_vector3(route.contact.get("hero_position")): return "Original actual Hero contact receipt required"
			var at: Vector3=Value.read_vector3(route.contact.hero_position)
			if not parent.EXIT_RECT.has_point(Vector2(at.x,at.z)): return "Contact happened on actual firm exit"
	return ""

func progress_error(unit: Dictionary,progress: Dictionary,parent) -> String:
	if not unit.get("route") is Dictionary or not unit.route.get("stage") is int or not progress.get("checkpoint_ids") is Dictionary: return "Typed parent route/progress required"
	var stage: int=unit.route.stage
	if stage<0 or stage>4: return "Valid authored route stage required"
	if progress.get("completed")!=false and progress.get("completed")!=true: return "Boolean progress required"
	if progress.completed and (stage!=4 or progress.get("completion_id")!=parent.COMPLETE_ID): return "Completion only names local final tether release"
	if not String(progress.get("contact_exit_id","")).is_empty() and (not progress.completed or unit.route.get("exit_state")!="spent" or progress.contact_exit_id!=parent.EXIT_ID): return "Production contact/completion correspondence required"
	if unit.route.get("exit_state")=="spent" and progress.get("contact_exit_id")!=parent.EXIT_ID: return "Spent actual contact requires base contact history"
	for id: String in progress.checkpoint_ids:
		var index: int=parent.CHECKPOINTS.find(id)
		if index<0 or index>stage or progress.checkpoint_ids[id]!=parent.KINDS[index]: return "Only actual entitled unique authored checkpoints may survive"
	return ""

func restore_local(unit: Dictionary,parent,player: Dictionary) -> bool:
	last_error=record_error(unit,parent,player)
	if last_error.is_empty() and not same(player,parent.hero.snapshot_state()): last_error="Actual outer Hero must commit once before current native unit"
	if not last_error.is_empty(): return false
	if is_instance_valid(parent.current_unit) and not parent.current_unit.call("restore_parent_state",unit.current_unit.state,player): last_error=parent.current_unit.last_snapshot_error; return false
	last_error=parent.parent_apply_owned_state(unit.route,unit.presentation)
	if not last_error.is_empty(): return false
	var again: Dictionary=capture(parent,player,null,null,false)
	if again.is_empty() or not same(again,unit): last_error="Independent whole quiet native parent recapture differs" if last_error.is_empty() else last_error; return false
	return true

func verify_candidate(unit: Dictionary,parent,player: Dictionary,camera: Camera3D,hud: GameHUD) -> String:
	var again: Dictionary=capture(parent,player,null,null,false)
	if again.is_empty(): return last_error
	if not same(again,unit): return "Actual full restored parent differs"
	if is_instance_valid(parent.current_unit):
		var error: String=String(parent.current_unit.call("verify_parent_candidate",unit.current_unit.state,player,camera,hud))
		if not error.is_empty(): return error
	return parent.candidate_presentation_error(camera,hud)

static func kind(stage: int) -> String:
	return "regular" if stage<2 else ("capture-one" if stage==2 else ("capture-two" if stage==3 else "none"))

static func native_world(parent) -> Dictionary:
	return {"layout_sha256":parent._layout_sha,"level_id":"A3-L5","world_revision":1,"floor_id":parent.FLOOR_ID,"floor_signature":Footprint.floor_signature(parent,[parent.crystalman_regular_floor_binding()]).get("signature",[]),"permanent_box":[12.0,1.0,54.0],"permanent_center":[0.0,-0.5,13.0],"blockers":parent.parent_blocker_recipe(),"source_scripts":["res://scripts/acts/act3/crystalman_level.gd","res://scripts/acts/act3/crystalman_approach_unit.gd","res://scripts/acts/act3/crystalman_capture_phase.gd","res://scripts/acts/act3/crystalman_scenery.gd"]}

static func sha_valid(value: Variant) -> bool:
	if not value is String or value.length()!=64: return false
	for character: String in value:
		if not "0123456789abcdef".contains(character): return false
	return true

static func same(left: Variant,right: Variant) -> bool:
	var wire: String=Exact.stringify(left)
	return not wire.is_empty() and wire==Exact.stringify(right)
