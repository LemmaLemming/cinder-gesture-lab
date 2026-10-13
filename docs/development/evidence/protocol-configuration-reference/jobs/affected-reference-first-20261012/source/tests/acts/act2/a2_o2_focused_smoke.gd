extends SceneTree
## Focused O2 public ordinary Smoke/Tender + Handler/Lane responses.
## Natural claim uses admitted original proofs, public completed ground dashes,
## one real ordinary primary/source and its full cooldown; no blast or pickup.
## TEST_ONLY public shells=0 at each actual opening (reload remains native).
## TEST_ONLY later recovery-gated Actor injuries and actual Hero placements
## arrange the separate CP/final/completion/grace/crate boundaries. Those are
## labelled setups, never ordinary route/defeat credit. No HP/phase/proof/clock/
## deadline/pending-path/progression writes; no whole-route acceptance gate.
const MainScene: PackedScene = preload("res://scenes/main.tscn")
const O2_PATH: String = "res://scenes/acts/act2/a2_o2.tscn"
const Exact: Script = preload("res://scripts/campaign/exact_json.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const Equipment: Script = preload("res://scripts/equipment.gd")
const ProfileSeedGame: Script = preload("res://tests/acts/act2/fixtures/a2_l1_profile_seed_game.gd")
const EXTREME_LOADOUTS: Array[Dictionary] = [
	{"id":"slow-dash-short-reach","loadout":{"jacket":"CLOTH-J1","pants":"CLOTH-P2","shoes":"CLOTH-S2","weapon":"WEAPON-03"}},
	{"id":"slow-primary-reach","loadout":{"jacket":"CLOTH-J1","pants":"CLOTH-P1","shoes":"CLOTH-S0","weapon":"WEAPON-03"}},
]
const CP_ID: String = "clear-air-before-final-handler"
const COMPLETE_ID: String = "clear-air-circuit-complete"
const EXIT_ID: String = "clear-air-circuit-return"
const TARGET_FOR: Dictionary = {"west_bank":"west_tender","east_bank":"east_tender","final_tool":"final_handler"}
const BANK_FOR: Dictionary = {"west_tender":"west_bank","east_tender":"east_bank"}
const MAX_TICKS: int = 900
const TICK_S: float = 1.0/60.0
const DERIVED_EPS: float = 0.00001
const OWNED_CAPTURE_PREFIX: String = "res://docs/acts/act2/evidence/A2-O2/"
const LABELS: Array[String] = ["entry","tender-lock","empty-west-store","handler-lock","opened-circuit-marker","full-west-store","smoke-grace"]
class NativeTickProbe extends Node:
	signal tick_finished
	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 120
	func _physics_process(_delta: float) -> void: tick_finished.emit()
var _checks: int = 0
var _failures: int = 0
var _game: Node
var _level: CinderLevel
var _hero: CinderPlayer
var _probe: NativeTickProbe
var _abort: bool = false
var _capture: bool = false
var _capture_root: String
var _capture_pending: bool = false
var _capture_resume_events: Array[Dictionary] = []
var _frames: Array[Dictionary] = []
var _scope_complete: bool = false
var _extremes: bool = false
var _loadout: Dictionary = {}
var _stats: Dictionary = {}
var _extreme_results: Array[Dictionary] = []
var _actions: Array[Dictionary] = []
var _phases: Dictionary = {}
var _setup: Array[Dictionary] = []
var _checkpoints: Array[String] = []
var _completions: Array[String] = []
var _exits: Array[String] = []
var _lock_captured: Dictionary = {}
var _invalidations: Array[Dictionary] = []

func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	root.size = Vector2i(540,1170)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_capture = "--a2-o2-portraits" in OS.get_cmdline_user_args()
	_extremes = "--a2-o2-extremes" in OS.get_cmdline_user_args()
	if _extremes and not _expect(not _capture and DisplayServer.get_name() == "headless","explicit headless two-loadout mechanics scope excludes portraits"): _finish(); return
	if _capture:
		if not _expect(DisplayServer.get_name() != "headless","actual native graphics required for portraits") or not _prepare_capture_root(): _finish(); return
	_probe = NativeTickProbe.new(); root.add_child(_probe)
	if _extremes:
		for definition: Dictionary in EXTREME_LOADOUTS:
			_loadout = definition.loadout.duplicate(true); _stats.clear()
			var okay: bool = await _mechanics_component()
			_expect(okay,"native ordinary Smoke and Handler component for " + String(definition.id))
			var same: bool = not _actions.is_empty()
			for action: Dictionary in _actions: same = same and action.equipment_ids == _loadout and action.resolved_stats == _stats
			_expect(same,"all actual world actions retain selected complete legal gear/stats " + String(definition.id))
			_extreme_results.append({"id":definition.id,"complete":okay,"loadout":_loadout.duplicate(true),"stats":_stats.duplicate(true),"phases":_phases.duplicate(true),"actual_actions":_actions.size(),"hero_hp":_hero.hp if is_instance_valid(_hero) else null,"setups":_setup.duplicate(true)})
			await _release()
			if not okay or _failures > 0: break
		_scope_complete = _extreme_results.size() == EXTREME_LOADOUTS.size() and _failures == 0
		_expect(_scope_complete,"both existing extrema complete actual ordinary noammo responses/full cadence without pickups")
		print("O2 actual extrema: ",Exact.stringify(_extreme_results))
	else:
		_scope_complete = await _mechanics_component()
		_expect(_scope_complete,"focused actual Smoke/Tender and Handler/Lane ordinary components complete")
		await _release()
		if _capture and _scope_complete:
			_scope_complete = await _grace_portrait_component()
			_expect(_scope_complete,"separate labelled native smoke/grace portrait component completes")
			await _release()
		if _capture: _write_metadata()
	if is_instance_valid(_probe): _probe.queue_free()
	await process_frame
	_finish()

func _boot() -> bool:
	_abort = false; _actions.clear(); _phases.clear(); _setup.clear(); _checkpoints.clear(); _completions.clear(); _exits.clear(); _lock_captured.clear(); _invalidations.clear()
	_game = MainScene.instantiate()
	if not _loadout.is_empty():
		_game.set_script(ProfileSeedGame); _game.set("test_profile_id","standard")
	_game.set("level_scene_path",O2_PATH); root.add_child(_game)
	_level = _game.get("active_level") as CinderLevel
	_hero = _game.get("player") as CinderPlayer
	if not _expect(is_instance_valid(_level) and is_instance_valid(_hero) and _level.level_id == "A2-O2" and _level.contract_error().is_empty(),"actual Main installs O2 contract/shared Hero"): return false
	if not _expect(_level.has_method("get_actor") and _level.has_method("get_bank") and _level.has_method("get_tool") and _level.has_method("get_scheduler"),"new host exposes public native leaf getters"): return false
	if not _loadout.is_empty():
		paused = true
		if not _select_initial_gear(): return false
	_hero.world_action_executed.connect(func(record: Dictionary) -> void: _actions.append(record.duplicate(true)))
	var native_scheduler: Node = _level.call("get_scheduler")
	native_scheduler.connect("reservation_invalidated",func(id: String,reason: String) -> void: _invalidations.append({"reservation_id":id,"reason":reason,"clock_s":native_scheduler.call("get_clock")}))
	_level.checkpoint_requested.connect(func(_id: String,id: String,_kind: String) -> void: _checkpoints.append(id))
	_level.completion_requested.connect(func(_id: String,id: String) -> void: _completions.append(id))
	_level.contact_exit_requested.connect(func(_id: String,id: String) -> void: _exits.append(id))
	_game.call("resume_lab")
	for _tick: int in range(12): await _step()
	return _expect(_live() and _hero.presentation_id == "act2_survivor" and _hero.is_on_floor() and (_hero.equipment.snapshot() == _loadout if not _loadout.is_empty() else _hero.equipment.snapshot().weapon == "WEAPON-01"),"actual shared Act2 Hero settles on continuous native dry floor")

func _select_initial_gear() -> bool:
	if not _expect(paused and _clock() == 0.0 and _hero.get_world_action_records().is_empty() and float(_hero.get_threat_response_state().action_clock_s) == 0.0,"TEST_ONLY legal gear selection precedes every actual clock/action/admission"): return false
	var resolver: CinderEquipment = Equipment.new()
	if not _expect(resolver.restore(_loadout) and resolver.acceptance_errors().is_empty(),"canonical complete resolver accepts selected legal numerical fixture"): return false
	for slot: String in CinderEquipment.SLOTS:
		if not _expect(resolver.is_implemented(String(_loadout[slot])) and resolver.item(String(_loadout[slot])).slot == slot and resolver.item(String(_loadout[slot])).perk_id == null,"existing implemented static canonical slot/no ability introduction " + slot): return false
	_stats = resolver.resolved_stats()
	var hp: float = _hero.hp
	var ammo: int = _hero.shells
	var okay: bool = _hero.equipment.restore(_loadout) and _hero.equip_item(String(_loadout.weapon))
	return _expect(okay and _hero.equipment.snapshot() == _loadout and _hero.stats == _stats and _hero.hp == hp and _hero.shells == ammo and _clock() == 0.0,"public fresh weapon equip refreshes shared visuals/stats without HP/ammo/action seed")

func _mechanics_component() -> bool:
	if not await _boot(): return false
	if _capture: await _capture_view("entry","original actors/ruin/work apron and initial decorative stores; no full-crate-framing or encounter/progression seed claim")
	var hp_before: float = _hero.hp
	# Real initial oblique dash approaches the west source without a Hero pose
	# seed. Admission of either source is determined by the actual host; this
	# fixture does not infer the east source stays beyond its admission range.
	if not await _dash(Vector3(-0.5,0,-1.0)): return false
	var west: Dictionary = await _wait_plan("west_bank","warning")
	if west.is_empty(): return false
	if not await _follow(west): return false
	_expect(_all_phases("west_bank"),"actual west Smoke consumer traverses warning/lock/active/recovery")
	_expect(_hero.hp == hp_before and not _hero.dead,"actual ordinary Smoke escape/return loses no Hero HP")
	_expect(float(_actor("west_tender").get("hp")) > 0.0 and float(_actor("west_tender").get("hp")) < 30.0,"real ordinary primary damages Tender mount while preserving living source")
	# Subsequent progression setup uses the existing public gated injury while
	# same native recovery is still open. It is not another primary or kill.
	if not await _test_gated_defeat("west_tender",false): return false
	if not await _wait_original_tail("west_bank"): return false
	if _capture:
		if not await _test_place(Vector3(-2.3,0.1,-2.7),"spent west enemy store portrait after its actual defeat/tail"): return false
		await _capture_view("empty-west-store","actual empty west enemy store; labelled setup defeat and feet placement, no resource grant")
	if not await _test_gated_defeat("east_tender",true): return false
	if not await _wait_original_tail("east_bank"): return false
	_expect(_state().cleared_ids == ["west_tender","east_tender"] and _state().stage == "before-final" and int(_consumer("final_tool").call("state").cycle) == 0,"real labelled setup defeats retain ordered prefix before final admission")
	if not await _test_place(Vector3(0,0.1,-6.7),"before-final stable CP contact"): return false
	_expect(_checkpoints == [CP_ID] and _level.current_checkpoint().id == CP_ID and _state().checkpoint_committed,"actual local preview CP contact commits once before final source")
	# The distinct Handler component begins from a disclosed legitimate late
	# boundary placement, then only normal native dash/proof/primary controls.
	if not await _test_place(Vector3(-2.0,0.1,-8.6),"near final Handler, prior to its actual admission"): return false
	var handler_hp: float = _hero.hp
	var handler: Dictionary = await _wait_plan("final_tool","warning")
	if handler.is_empty(): return false
	if not await _follow(handler): return false
	_expect(_all_phases("final_tool"),"actual ordinary final Lane traverses all four phases")
	_expect(_hero.hp == handler_hp and not _hero.dead,"actual ordinary Handler proof-directed escape/return loses no Hero HP")
	_expect(float(_actor("final_handler").get("hp")) > 0.0 and float(_actor("final_handler").get("hp")) < 30.0,"real ordinary primary damages Handler low mount without a boss or victory dependency")
	var primary: int = 0
	var blast: int = 0
	for action: Dictionary in _actions:
		if action.kind == "primary": primary += 1
		elif action.kind == "blast": blast += 1
	_expect(primary == 2 and blast == 0,"one actual ordinary primary per natural component, no blast or pickups")
	if _capture:
		if not await _test_gated_defeat("final_handler",false): return false
		for _tick: int in range(MAX_TICKS):
			if not _live() or _level.is_completed(): break
			await _step()
		_expect(_level.is_completed() and _state().exit_open and _completions == [COMPLETE_ID] and _exits.is_empty(),"labelled final setup triggers genuine quiet completion distinct from contact exit")
		if not await _test_place(Vector3(-0.9,0.1,-13.0),"completed board/cue separated visual boundary, before contact exit"): return false
		await _capture_view("opened-circuit-marker","actual completed circuit marker; labelled gate injuries/placement, no route or reward credit")
	return _live() and _failures == 0

func _wait_plan(source: String,phase: String) -> Dictionary:
	for _tick: int in range(MAX_TICKS):
		if not _live(): break
		var state: Dictionary = _consumer(source).call("state")
		if state.status == "running" and state.phase == phase:
			var proof: Dictionary = _state().proofs.get(source,{})
			var lease: Dictionary = _level.call("get_scheduler").call("reservation_state",state.reservation_id)
			if not _expect(proof.get("accepted",false) and lease.get("armed",false) and float(lease.active_from_s)-float(lease.lock_from_s) >= 1.1-DERIVED_EPS and not proof.uses_blast and not proof.uses_invulnerability,"actual source retains armed original ordinary proof/full1.10 lock " + source): return {}
			return {"source":source,"target":TARGET_FOR[source],"cycle":state.cycle,"reservation":lease.duplicate(true),"proof":proof.duplicate(true)}
		await _step()
	_expect(false,"bounded actual armed " + source + " " + phase + ": " + str(_state()))
	return {}

func _follow(plan: Dictionary) -> bool:
	# Stationary proofs begin at their real warning admission. Follow that
	# original schedule; inspect lock portraits only during a later idle hold.
	var actor: Node3D = _actor(plan.target)
	for segment: Dictionary in plan.proof.path:
		if segment.kind not in ["escape_dash","positioning_dash","ordinary_primary"]: continue
		for _tick: int in range(MAX_TICKS):
			if not _live(): return false
			if _clock()+DERIVED_EPS >= float(segment.start_s): break
			if not await _capture_lock_during_wait(plan,float(segment.start_s)): return false
			if _clock()+DERIVED_EPS >= float(segment.start_s): break
			await _step()
		if not _expect(_clock()+DERIVED_EPS >= float(segment.start_s) and _clock() <= float(segment.start_s)+TICK_S+DERIVED_EPS,"native120 sampler reaches planned " + String(segment.kind) + " within one tick"): return false
		var same_plan: bool = _same_plan(plan)
		if not same_plan:
			var lost: Dictionary = _consumer(plan.source).call("state")
			var retained: Dictionary = _level.call("get_scheduler").call("reservation_state",plan.reservation.id)
			print("O2 passive plan loss: ",Exact.stringify(_encode({"clock_s":_clock(),"segment":segment,"consumer":lost,"original":plan.reservation,"retained":retained,"hero_position":_hero.global_position,"admission_errors":_state().admission_errors,"runtime_error":_state().runtime_error,"invalidations":_invalidations})))
		if not _expect(same_plan,"same admitted native source/cycle/deadlines still owns planned action"): return false
		var response: Dictionary = _hero.get_threat_response_state()
		if segment.kind == "ordinary_primary":
			if not _expect(response.stable and float(response.primary_cooldown_left_s) == 0.0 and float(response.commitment_remaining_s) == 0.0,"native primary readiness at actual response tick"): return false
			var state: Dictionary = _consumer(plan.source).call("state")
			if not _expect(state.phase == "recovery" and _clock()+float(_hero.stats.primary_cooldown) <= float(plan.reservation.recovery_until_s)-CinderThreatScheduler.TIME_MARGIN,"real primary and full actual cooldown fit retained native recovery"): return false
			var direction: Vector3 = actor.global_position-_hero.global_position; direction.y = 0.0
			if not _expect(direction.length() <= float(_hero.stats.primary_range)+DERIVED_EPS,"actual completed native landing reaches low ordinary mount"): return false
			var hp: float = float(actor.get("hp"))
			var seq: int = _sequence()
			_hero.shells = 0 # TEST_ONLY actual empty resource conditioning; reload unchanged.
			_setup.append({"kind":"empty-ammo","source":plan.source,"clock_s":_clock(),"scope":"TEST_ONLY public ammo=0, no pickup/reload/stat suppression"})
			var hits: int = _hero.slash(direction)
			if not _expect(hits == 1 and float(actor.get("hp")) < hp and _sequence() == seq+1 and _actions.back().kind == "primary","public ordinary primary hits actual low mount with empty ammo " + String(plan.target)): return false
			var recovered: bool = false
			for _tick: int in range(MAX_TICKS):
				if not _live(): return false
				response = _hero.get_threat_response_state()
				if response.stable and float(response.primary_cooldown_left_s) == 0.0 and float(response.commitment_remaining_s) == 0.0: recovered = true; break
				await _step()
			if not _expect(recovered and _clock() <= float(plan.reservation.recovery_until_s),"full native ordinary primary cadence finishes inside original recovery"): return false
		else:
			if not _expect(response.stable and float(response.dash_cooldown_left_s) == 0.0 and float(response.commitment_remaining_s) == 0.0,"actual proof dash ready at sampled action tick"): return false
			var direction: Vector3 = segment.to-_hero.global_position; direction.y = 0.0
			if not await _dash(direction): return false
	await _wait_capture()
	if _capture and not _expect(_lock_captured.has(String(plan.source)),"actual original lock portrait exists without delaying the warning proof: " + String(plan.source)): return false
	return _live()

func _capture_lock_during_wait(plan: Dictionary,next_action_s: float) -> bool:
	if not _capture or _lock_captured.has(String(plan.source)): return true
	var current: Dictionary = _consumer(plan.source).call("state")
	if current.status != "running" or current.phase != "lock": return true
	var response: Dictionary = _hero.get_threat_response_state()
	# An imminent scheduled action or an unfinished native dash always takes
	# priority. No post-draw await occurs inside _dash or an action window.
	if _hero.action_in_progress() or not response.stable or float(response.commitment_remaining_s) != 0.0 or _clock()+TICK_S+DERIVED_EPS >= next_action_s: return true
	if not _expect(_same_plan(plan),"original admitted source/cycle/lease still owns idle lock capture"): return false
	var expected: Dictionary = plan.duplicate(true)
	expected["next_action_s"] = next_action_s
	var sequence: int = _sequence()
	var label: String = "tender-lock" if plan.source == "west_bank" else "handler-lock"
	await _capture_view(label,"actual original native lock sampled during its proof's idle hold; warning escape already follows the original schedule",expected)
	if not _expect(_live() and _same_plan(plan) and _clock()+DERIVED_EPS < next_action_s and _sequence() == sequence,"post-draw returns before the next original action with unchanged admitted lease and no extra controls"): return false
	var after: Dictionary = _consumer(plan.source).call("state")
	if not _expect(after.phase == "lock" and after.cycle == plan.cycle and after.reservation_id == plan.reservation.id,"post-draw still retains the captured original native lock"): return false
	_lock_captured[String(plan.source)] = true
	return true

func _same_plan(plan: Dictionary) -> bool:
	var state: Dictionary = _consumer(plan.source).call("state")
	var lease: Dictionary = _level.call("get_scheduler").call("reservation_state",state.get("reservation_id",""))
	if state.status != "running" or state.cycle != plan.cycle or state.reservation_id != plan.reservation.id or not lease.get("armed",false): return false
	for key: String in ["start_s","lock_from_s","active_from_s","active_until_s","recovery_until_s","geometry","opening_position"]:
		if lease.get(key) != plan.reservation.get(key): return false
	return true
func _test_gated_defeat(id: String,reposition: bool) -> bool:
	if not _live(): return false
	if reposition:
		var actor: Node3D = _actor(id)
		if not await _test_place(actor.global_position + Vector3.BACK*1.5 + Vector3.UP*0.1,"recovering source setup " + id): return false
	for _tick: int in range(MAX_TICKS):
		if not _live(): return false
		var actor: Node3D = _actor(id)
		if actor.get("phase") == "recovery" and _hero.get_threat_response_state().stable:
			var hp: float = float(actor.get("hp"))
			var result: Dictionary = actor.call("take_damage",10000.0,Vector3.ZERO)
			_setup.append({"kind":"gated-actor-injury","id":id,"clock_s":_clock(),"hp_before":hp,"hp_after":actor.get("hp"),"result":_encode(result),"scope":"TEST_ONLY public native recovery-gated damage, not primary/defeat route credit"})
			if not _expect(result.get("accepted",false) and float(result.get("hp_damage",0.0)) == hp and float(actor.get("hp")) == 0.0,"actual gate accepts labelled public TEST defeat " + id + ": " + str(result)): return false
			for _step_index: int in range(2): await _step()
			return _expect(_state().cleared_ids.has(id),"real callback transaction flushes earned setup defeat " + id)
		await _step()
	return _expect(false,"bounded real recovery before TEST injury " + id + str(_state()))
func _wait_original_tail(id: String) -> bool:
	var original: Dictionary = _consumer(id).call("state")
	if not _expect(original.status == "running" and original.phase == "recovery" and original.last_cancel_reason.is_empty(),"HP0 source leaves original bank recovery tail running " + id): return false
	for _tick: int in range(MAX_TICKS):
		if not _live(): return false
		var current: Dictionary = _consumer(id).call("state")
		if current.status == "complete":
			return _expect(current.cycle == original.cycle and _same(_encode(current.exchange),_encode(original.exchange)) and _same(current.receipts,original.receipts) and current.last_cancel_reason.is_empty(),"original source-less bank finishes same lease/deadlines/receipts, without refresh/cancel " + id)
		if not _expect(current.status == "running" and current.cycle == original.cycle and _same(_encode(current.exchange),_encode(original.exchange)),"live HP0 tail retains immutable original cycle/deadlines " + id): return false
		await _step()
	return _expect(false,"bounded original smoke recovery tail completion " + id)
func _test_place(at: Vector3,purpose: String) -> bool:
	if not _live() or _hero.action_in_progress(): return _expect(false,"TEST placement requires native quiet living Hero")
	_hero.global_position = at
	_setup.append({"kind":"hero-placement","position":_encode(at),"purpose":purpose,"scope":"TEST_ONLY actual feet placement; no navigation/WorldAction claim"})
	for _tick: int in range(12): await _step()
	return _expect(_live() and _hero.is_on_floor() and _hero.get_threat_response_state().stable,"labelled representative placement settles on native supported floor: " + purpose)

func _grace_portrait_component() -> bool:
	if not await _boot(): return false
	if not await _test_place(Vector3(-2.3,0.1,-2.7),"full west enemy store portrait, before any native source defeat"): return false
	await _capture_view("full-west-store","actual full west enemy store; TEST feet placement, no action/resource/route claim")
	if not await _test_place(Vector3(-1.5,0.1,-4.3),"native grace/low smoke portrait, not ordinary escape test"): return false
	for _tick: int in range(MAX_TICKS):
		if not _live(): return false
		var bank: Dictionary = _consumer("west_bank").call("state")
		if bank.status == "running" and bank.phase == "active" and bank.contact_since_s != null and bank.grace_progress > 0.0:
			await _capture_view("smoke-grace","actual bounded low smoke/source/native grace bar around TEST placed Hero; no route/no-damage claim")
			return _live() and _failures == 0
		await _step()
	return _expect(false,"bounded actual active/grace portrait state " + str(_state()))

func _dash(direction: Vector3) -> bool:
	var ready: bool = false
	for _tick: int in range(MAX_TICKS):
		if not _live(): return false
		var response: Dictionary = _hero.get_threat_response_state()
		if not paused and response.stable and float(response.dash_cooldown_left_s) == 0.0 and float(response.commitment_remaining_s) == 0.0 and not _hero.action_in_progress(): ready = true; break
		await _step()
	if not _expect(ready,"bounded actual native dash readiness"): return false
	var sequence: int = _sequence()
	if not _expect(_hero.request_dash(direction),"public shared fixed-distance ground dash accepted"): return false
	for _tick: int in range(MAX_TICKS):
		await _step()
		if not _live(): return false
		if _sequence() > sequence:
			var action: Dictionary = _actions.back()
			return _expect(action.kind == "dash" and action.landing == _hero.global_position and not _hero.action_in_progress(),"actual completed dash/action record uses deliberate stopped world landing")
	return _expect(false,"bounded native completed dash")
func _step() -> void:
	if _capture and paused: _resume_capture_focus_pause()
	await _probe.tick_finished
	if not _live(): return
	for source: String in ["west_bank","east_bank","final_tool"]:
		var state: Dictionary = _consumer(source).call("state")
		if state.status == "running":
			if not _phases.has(source): _phases[source] = {}
			_phases[source][state.phase] = true
	var error: String = String(_state().get("runtime_error",""))
	if not error.is_empty(): _expect(false,"actual O2 runtime error: " + error); _abort = true
func _all_phases(source: String) -> bool: return _phases.get(source,{}).has_all(["warning","lock","active","recovery"])
func _state() -> Dictionary: return _level.call("encounter_state") if is_instance_valid(_level) else {}
func _clock() -> float: return float(_state().get("clock_s",0.0))
func _actor(id: String) -> Node3D: return _level.call("get_actor",id) as Node3D
func _consumer(id: String) -> Node3D:
	if id == "final_tool": return _level.call("get_tool") as Node3D
	return _level.call("get_bank",id) as Node3D
func _sequence() -> int:
	var records: Array[Dictionary] = _hero.get_world_action_records()
	return int(records.back().sequence) if not records.is_empty() else 0
func _live() -> bool: return not _abort and is_instance_valid(_game) and is_instance_valid(_level) and is_instance_valid(_hero) and not _hero.dead
func _same(a: Variant,b: Variant) -> bool:
	var encoded: String = Exact.stringify(a)
	return not encoded.is_empty() and encoded == Exact.stringify(b)

func _prepare_capture_root() -> bool:
	var options: Array[String] = []
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--a2-o2-capture-root="): options.append(argument.trim_prefix("--a2-o2-capture-root="))
	if not _expect(options.size() == 1 and options[0].begins_with(OWNED_CAPTURE_PREFIX),"one explicit owned new O2 capture leaf/images root"): return false
	var tail: String = options[0].trim_prefix(OWNED_CAPTURE_PREFIX)
	var parts: PackedStringArray = tail.split("/",false)
	var regex: RegEx = RegEx.new(); regex.compile("^[A-Za-z0-9][A-Za-z0-9_-]*$")
	if not _expect(parts.size() == 2 and parts[1] == "images" and regex.search(parts[0]) != null and tail == parts[0]+"/images/","capture path is exactly one owned new packet/images child"): return false
	var parent: String = ProjectSettings.globalize_path(OWNED_CAPTURE_PREFIX+parts[0]+"/")
	var images: String = ProjectSettings.globalize_path(options[0])
	if not _expect(DirAccess.dir_exists_absolute(parent) and not DirAccess.dir_exists_absolute(images) and not FileAccess.file_exists(options[0]),"fresh capture never replaces any prior output"): return false
	if not _expect(DirAccess.make_dir_absolute(images) == OK,"create only fresh owned images directory"): return false
	_capture_root = options[0]; return true
func _resume_capture_focus_pause() -> void:
	if not _capture or not paused or not _live(): return
	var before: Dictionary = {"level_clock_s":_clock(),"player_clock_s":_hero.get_threat_response_state().action_clock_s,"hp":_hero.hp,"position":_hero.global_position,"actions":_hero.get_world_action_records()}
	_game.call("resume_lab")
	var after: Dictionary = {"level_clock_s":_clock(),"player_clock_s":_hero.get_threat_response_state().action_clock_s,"hp":_hero.hp,"position":_hero.global_position,"actions":_hero.get_world_action_records()}
	_expect(not paused and before == after,"public graphical Resume preserves actual clocks/HP/pose/action history")
	_capture_resume_events.append({"before":_encode(before),"after":_encode(after),"reason":"observed production pause during graphics automation"})
func _capture_view(label: String,scope: String,expected_plan: Dictionary = {}) -> void:
	_capture_pending = true
	var live_frame: bool = false
	for _frame: int in range(4):
		if paused: _resume_capture_focus_pause()
		await RenderingServer.frame_post_draw
		if not paused: live_frame = true; break
	if not _expect(live_frame and _live(),"bounded live post-draw native portrait " + label): _capture_pending = false; return
	if not expected_plan.is_empty():
		if not _expect(_same_plan(expected_plan) and _clock()+DERIVED_EPS < float(expected_plan.next_action_s),"original proof/cycle and future action deadline survive post-draw before pixels " + label): _capture_pending = false; return
	var points: Array[Vector3] = []
	points.assign(_game.call("player_camera_framing_points"))
	points.append_array(_level.camera_framing_points())
	var subject: Dictionary = {}
	if label in ["tender-lock","handler-lock"]:
		var source: String = "west_bank" if label == "tender-lock" else "final_tool"
		var current: Dictionary = _consumer(source).call("state")
		_expect(current.status == "running" and current.phase == "lock","post-draw portrait retains original real native lock " + source)
	elif label == "smoke-grace":
		var bank: Node3D = _consumer("west_bank")
		var current: Dictionary = bank.call("state")
		points.append_array(bank.call("get_required_camera_points"))
		_expect(current.phase == "active" and current.contact_since_s != null and (bank.call("get_grace_indicator") as Node3D).get_node("GraceBackground").is_visible_in_tree(),"original native grace bar remains visible with actual active contact")
	elif label in ["full-west-store","empty-west-store","opened-circuit-marker"]:
		var kit: Dictionary = _level.get("_kit")
		var prop: Node3D = kit.marker as Node3D if label == "opened-circuit-marker" else kit.crates.west_tender as Node3D
		var subject_points: Array[Vector3] = _native_mesh_bounds(prop)
		points.append_array(subject_points)
		var expected: String = "completed" if label == "opened-circuit-marker" else ("full" if label == "full-west-store" else "empty")
		var key: String = "marker_state" if label == "opened-circuit-marker" else "store_state"
		subject = {"name":String(prop.name),"metadata_key":key,"actual_state":prop.get_meta(key,""),"expected_state":expected,"bounds":_encode(subject_points)}
		if label != "opened-circuit-marker": subject["full_canisters_visible"] = prop.get_node("FullCanisters").is_visible_in_tree()
		_expect(not subject_points.is_empty() and prop.is_visible_in_tree() and prop.get_meta(key,"") == expected and (subject.full_canisters_visible == (expected == "full") if label != "opened-circuit-marker" else true),"actual same-west full/empty crate or completed marker has native visible mesh bounds/state " + label)
	# Entire current gameplay union plus the explicit portrait subject. Other
	# outboard decoration is not required in every current gameplay frame.
	var framing: String = _game.call("camera_framing_error",points)
	_expect(framing.is_empty(),"actual required Hero/source/cue/landing/grace framing " + label + ": " + framing)
	var picture: Image = root.get_texture().get_image()
	var path: String = _capture_root+label+".png"
	if not _expect(not FileAccess.file_exists(path),"original new-job pixels never overwrite old image " + label): _capture_pending = false; return
	_expect(picture != null and picture.get_size() == Vector2i(540,1170) and picture.save_png(path) == OK,"actual540x1170 original portrait " + label)
	_frames.append({"label":label,"scope":scope,"hero_position":_encode(_hero.global_position),"hero_hp":_hero.hp,"hero_shells":_hero.shells,"hero_on_floor":_hero.is_on_floor(),"state":_encode(_state()),"checkpoint":_level.current_checkpoint(),"completed":_level.is_completed(),"actual_actions":_encode(_actions),"labelled_test_setups":_setup.duplicate(true),"portrait_subject":subject,"required_points":_encode(points),"camera_error":framing,"image_path":path,"image_sha256":FileAccess.get_sha256(path)})
	_capture_pending = false
func _wait_capture() -> void:
	for _frame: int in range(120):
		if not _capture_pending: return
		await process_frame
	_expect(false,"bounded outstanding portrait post-draw completion")
func _write_metadata() -> void:
	var labels: Array[String] = []
	for frame: Dictionary in _frames: labels.append(frame.label)
	_expect(labels == LABELS,"exact actual entry/Tender lock/same-west full-empty store/Handler lock/completed marker/grace portrait labels")
	var packet: Dictionary = {"api_revision":"act2-o2-focused-preview-1","scope":"actual ordinary two-consumer proof responses plus disclosed public gated injury/contact/portrait setups; no Shell/earned route/all-kit/balance claim","checks":_checks,"failures":_failures,"scope_complete":_scope_complete,"frames":_frames,"capture_environment_resume_events":_capture_resume_events,"source_files":_sources(),"art_accepted":false}
	var encoded: String = Exact.stringify(packet)
	if not _expect(not encoded.is_empty() and not FileAccess.file_exists(_capture_root+"metadata.exact.json"),"finite native exact metadata fits shared budget and preserves every prior original"): return
	var file: FileAccess = FileAccess.open(_capture_root+"metadata.exact.json",FileAccess.WRITE)
	if not _expect(file != null,"new native portrait metadata output opens"): return
	packet.checks = _checks; packet.failures = _failures
	file.store_string(Exact.stringify(packet)+"\n"); file.close()
func _sources() -> Dictionary:
	var pins: Dictionary = {}
	for path: String in [O2_PATH,"res://scripts/acts/act2/clear_air_circuit.gd","res://scripts/acts/act2/clear_air_circuit_kit.gd","res://scripts/acts/act2/canister_tender_actor.gd","res://scripts/acts/act2/salvage_handler_actor.gd","res://scripts/combat/smoke_bank.gd","res://scripts/combat/lane_mechanism.gd","res://scripts/game.gd","res://scripts/player.gd"]: pins[path] = FileAccess.get_sha256(path)
	return pins
func _encode(value: Variant) -> Variant:
	if value is Vector3: return [value.x,value.y,value.z]
	if value is Vector2: return [value.x,value.y]
	if value is Rect2: return {"diagnostic_native_type":"Rect2","position":_encode(value.position),"size":_encode(value.size)}
	if value is Basis: return {"x":_encode(value.x),"y":_encode(value.y),"z":_encode(value.z)}
	if value is int and (value < -9007199254740991 or value > 9007199254740991): return {"diagnostic_native_integer_decimal":str(value)}
	if value is Dictionary:
		var dict: Dictionary = {}
		for key: Variant in value: dict[String(key)] = _encode(value[key])
		return dict
	if value is Array:
		var array: Array = []
		for item: Variant in value: array.append(_encode(item))
		return array
	return value
func _native_mesh_bounds(node: Node) -> Array[Vector3]:
	var native: Array[Vector3] = []
	_append_mesh_bounds(node,native)
	if native.is_empty(): return []
	var bounds: AABB = AABB(native[0],Vector3.ZERO)
	for point: Vector3 in native: bounds = bounds.expand(point)
	var result: Array[Vector3] = []
	for index: int in range(8): result.append(bounds.get_endpoint(index))
	return result
func _append_mesh_bounds(node: Node,into: Array[Vector3]) -> void:
	if node is MeshInstance3D and is_instance_valid(node.mesh) and node.is_visible_in_tree():
		for index: int in range(8): into.append(node.global_transform*node.mesh.get_aabb().get_endpoint(index))
	for child: Node in node.get_children(): _append_mesh_bounds(child,into)
func _refs(node: Node,into: Array[WeakRef]) -> void:
	into.append(weakref(node))
	for child: Node in node.get_children(): _refs(child,into)
func _release() -> void:
	await _wait_capture()
	var refs: Array[WeakRef] = []
	if is_instance_valid(_game):
		_refs(_game,refs)
		if is_instance_valid(_level): _level.exit_level()
		_game.queue_free()
	_game = null; _level = null; _hero = null; paused = false
	for _frame: int in range(4): await process_frame
	var freed: bool = true
	for ref: WeakRef in refs: freed = freed and ref.get_ref() == null
	_expect(freed and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(),"actual whole Main/Player/actors/banks/lane/Scenery/cues release")
func _expect(ok: bool,note: String) -> bool:
	_checks += 1
	if not ok: _failures += 1; push_error("FAIL A2-O2 focused: " + note)
	return ok
func _finish() -> void:
	print("A2-O2 focused smoke: %d checks, %d failures; scope_complete=%s; actual ordinary Smoke/Tender + Handler/Lane/full cooldown/noammo/extremes, labelled recovery injuries/placements/brief portraits. No full route/Shell stamp/side-return/all-kit balance/mobile claim" % [_checks,_failures,str(_scope_complete)])
	quit(0 if _failures == 0 else 1)
