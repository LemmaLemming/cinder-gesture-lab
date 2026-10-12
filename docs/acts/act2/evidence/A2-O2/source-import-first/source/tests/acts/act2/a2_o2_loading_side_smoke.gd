extends SceneTree
## Focused: production O2 Shell loading/side flow and complete quiet transport.
## TEST_ONLY canonical earlier prefix and pending optional readiness in memory.
## TEST_ONLY Hero placements isolate native Smoke contact, CP and exit boundaries.
## TEST_ONLY public Actor.take_damage(10000,ZERO) is accepted only by its real
## recovery gate to arrange both clear orders/final boundary; no HP/phase/proof/
## clock/deadline/progress writes. These injuries are not ordinary-combat credit.
## Real Smoke active/grace and a defeated Tender's admitted original tail are
## captured/restored through full Player+actors+Scheduler+both Banks+Lane units.
const Shell: Script = preload("res://scripts/campaign/shell.gd")
const Registry: Script = preload("res://scripts/campaign/registry.gd")
const Attempts: Script = preload("res://scripts/campaign/attempts.gd")
const Store: Script = preload("res://scripts/campaign/save_store.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact: Script = preload("res://scripts/campaign/exact_json.gd")
const Smoke: Script = preload("res://scripts/combat/smoke_bank.gd")
const Scheduler: Script = preload("res://scripts/combat/threat_scheduler.gd")
const InteractionCue: Script = preload("res://scripts/cues/interaction_cue.gd")
const ThreatCue: Script = preload("res://scripts/cues/threat_cue.gd")
const Lane: Script = preload("res://scripts/combat/lane_mechanism.gd")
const Tender: Script = preload("res://scripts/acts/act2/canister_tender_actor.gd")
const Handler: Script = preload("res://scripts/acts/act2/salvage_handler_actor.gd")
const MainScene: PackedScene = preload("res://scenes/main.tscn")
const STORY_PATH: String = "res://scenes/acts/act2/a2_l4.tscn"
const O2_PATH: String = "res://scenes/acts/act2/a2_o2.tscn"
const CP_ID: String = "clear-air-before-final-handler"
const COMPLETE_ID: String = "clear-air-circuit-complete"
const EXIT_ID: String = "clear-air-circuit-return"
const PREFIX: Array[String] = ["A1-L1","A1-L2","A1-L3","A1-L4","A1-L5","A2-L1","A2-L2","A2-L3"]
const BANK_FOR: Dictionary = {"west_tender":"west_bank","east_tender":"east_bank"}
const TARGETS: Array[String] = ["west_tender","east_tender","final_handler"]
const ORDERS: Array[Array] = [["east_tender","west_tender"],["west_tender","east_tender"]]
const MAX_TICKS: int = 900
class NativeTickProbe extends Node:
	signal tick_finished
	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 120
	func _physics_process(_delta: float) -> void: tick_finished.emit()
var _checks: int = 0
var _failures: int = 0
var _finished: bool = false
var _test_root: String
var _raw: Dictionary
var _registry_bytes: String
var _shell: CinderCampaignShell
var _preview: Node
var _probe: NativeTickProbe
var _events: Array[String] = []
var _watch: bool = false
var _old_audio: AudioBusLayout
var _old_fps: int
var _injuries: Array[Dictionary] = []

func _initialize() -> void:
	_test_root = "user://test-a2-o2-loading-side-%d/" % OS.get_process_id()
	_old_audio = AudioServer.generate_bus_layout()
	_old_fps = Engine.max_fps
	_run.call_deferred()

func _run() -> void:
	create_timer(150.0,true).timeout.connect(func() -> void:
		if not _finished: _expect(false,"bounded O2 loading watchdog"); _finish())
	root.size = Vector2i(540,1170)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_probe = NativeTickProbe.new(); root.add_child(_probe)
	node_added.connect(_observe_added)
	_registry_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH)
	_raw = JSON.parse_string(_registry_bytes)
	for entry: Dictionary in _raw.levels:
		if entry.id == "A2-O2":
			entry.scene_path = O2_PATH; entry.readiness = "accepted"
			entry.accepted_commit = "e".repeat(40); entry.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(_raw)
	print("TEST_ONLY pending O2 readiness/prior prefix; actual protected A2-L4. Hero placements/public gated Actor injuries isolate native contact and progression boundaries; no route/ordinary-combat/GUI-pointer/art/balance credit.")
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A2-O2").is_empty(),"isolated canonical optional links/parent/stamp retain valid O2 identity"): _finish(); return
	if not await _seed_story(registry) or not await _new_shell(): _finish(); return
	_shell.menu.continue_story_requested.emit(); await _settle()
	if not _expect(paused and _shell.active_level.level_id == "A2-L4" and _shell.campaign_error.is_empty(),"disk Continue installs actual protected Story paused"): _finish(); return
	var story: Dictionary = _shell.capture_campaign_snapshot()
	_shell.menu.optional_requested.emit("A2-O2"); await _settle()
	if not _expect(_live() and paused and _shell.attempts.active_kind() == "optional","public parent-clear optional entry installs actual O2 paused: " + _shell.campaign_error): _finish(); return
	var protected: Dictionary = _shell.attempts.story_snapshot()
	var entrance: Dictionary = _shell.capture_campaign_snapshot()
	_expect(_same(story,protected) and _same(_shell.attempts.state().side_attempt.checkpoint,entrance),"entry protects the whole actual Story and pristine optional entrance checkpoint")
	_expect(entrance.level.local.size() == 16 and entrance.level.local.actors.size() == 3 and entrance.level.local.banks.size() == 2 and entrance.level.local.defeated_ids.is_empty() and entrance.level.local.scheduler.reservations.is_empty() and int(entrance.level.local.tool.cycle) == 0,"initial full16/three actors/two banks/one lane is unstarted without invented defeats or leases")
	_expect(not _shell.active_level.request_contact_exit(EXIT_ID,_shell.player),"uncleared contact exit refuses")
	var input: Dictionary = _shell.get_input_observation_state()
	_shell.handle_tap(root.get_visible_rect().size * 0.5)
	_expect(_shell.get_input_observation_state() == input and _same(_shell.capture_campaign_snapshot(),entrance),"paused entry consumes tap without input/action/state mutation")
	# TEST_ONLY real native contact setup. It changes actual feet, not the
	# consumer's sample/phase/trace/grace/clock or any saved local field.
	_shell.player.global_position = Vector3(-1.5,0.04,-4.3)
	_shell.player.velocity = Vector3.ZERO
	_shell.menu.resume_requested.emit()
	var contact: bool = false
	for _tick: int in range(MAX_TICKS):
		await _probe.tick_finished
		if not _live() or _shell.player.dead: break
		var bank: Dictionary = _bank("west_bank").call("state")
		if bank.status == "running" and bank.phase == "active" and bank.contact_since_s != null and bank.grace_progress > 0.0 and bank.grace_progress < 1.0:
			contact = true; _shell.request_pause(); break
	await _settle()
	var saved: Dictionary = _shell.capture_campaign_snapshot()
	if not _expect(contact and paused and not saved.is_empty() and _shell.campaign_error.is_empty(),"actual admitted bank earns active/grace and public deferred full-unit pause: " + _shell.campaign_error): _finish(); return
	var saved_bank: Dictionary = saved.level.local.banks.west_bank
	_expect(saved_bank.status == "running" and saved_bank.phase == "active" and saved_bank.contact_since_s >= saved_bank.exchange.active_from_s and saved_bank.receipts.is_empty() and saved_bank.sample.position == saved.player.motion.position and saved_bank.sample.actor_clock_s == saved.player.world_actions.clock_s,"complete active contact captures actual current Player endpoint/clocks/earned grace before first delivered tick")
	_expect(saved_bank.clock_s == saved.level.local.scheduler.clock_s and saved_bank.processed_count == saved_bank.trace.size() and saved_bank.pending_stage.is_empty() and saved.level.local.views.has("west_bank"),"original Scheduler/processed contact trace/native view pair remains exact at complete barrier")
	var parsed: Dictionary = Exact.parse(Exact.stringify(saved))
	_expect(parsed.get("accepted",false) and _same(parsed.value,saved),"ExactJSON roundtrip preserves complete native active/grace types and floating bits")
	_shell.menu.difficulty_preference_requested.emit("challenge")
	_expect(saved.level.local.profile_id == "standard" and _shell.get_difficulty_preference() == "challenge","saved fixed Standard remains distinct from new preference")
	for variant: Dictionary in _corruptions(saved):
		var bad: Dictionary = variant.state
		_expect(not _shell.active_level.snapshot_error_with_player(bad,saved.player).is_empty() and not _shell.active_level.restore_state(bad) and _same(_shell.capture_campaign_snapshot(),saved),"malformed " + variant.label + " rejects atomically before native mutation")
	if not await _disk_restore(saved,"active/grace under changed preference"): _finish(); return
	_expect(_shell.active_level.get("_profile_id") == "standard" and _same(_shell.attempts.story_snapshot(),protected),"fresh complete native restore retains saved encounter profile/protected Story")
	_shell.menu.resume_requested.emit()
	for _tick: int in range(4): await _probe.tick_finished
	_shell.player.take_damage(_shell.player.max_hp * 4.0,Vector3.ZERO)
	await _settle()
	_expect(paused and _shell.player.dead and _shell.campaign_error.is_empty(),"public TEST lethal Hero injury captures dead optional unit; no enemy attribution")
	var dead: Dictionary = _shell.capture_campaign_snapshot()
	_shell.menu.resume_requested.emit(); await _settle()
	_expect(paused and _same(dead,_shell.capture_campaign_snapshot()),"dead Resume leaves the frozen optional pair intact")
	_events.clear(); _watch = true
	_shell.menu.retry_requested.emit(); await _settle(); _watch = false
	if not _expect(_live() and paused and _same(_shell.capture_campaign_snapshot(),entrance) and _events.is_empty(),"public Retry restores pristine earlier Player/gear/ammo/HP/floor/actors/banks/lane/Scheduler without events"): _finish(); return
	_shell.menu.leave_side_requested.emit(); await _settle()
	_expect(paused and _shell.menu.page_name() == "journey" and _shell.attempts.active_kind() == "story" and _same(_shell.capture_campaign_snapshot(),protected),"early abandon returns exact protected Story to Journey")
	_expect(_shell.attempts.state().completed_main == PREFIX and _shell.attempts.state().completed_optional.is_empty() and _shell.attempts.state().reward_ids.is_empty(),"abandon awards no stamp, growth or main progress")
	# Both order prefixes are exercised in separate actual optional instances.
	# The second is a replay after completion and still grants only one stamp.
	for order: Array in ORDERS:
		_shell.menu.optional_requested.emit("A2-O2"); await _settle()
		if not _expect(_live() and paused and _shell.active_level.get("_profile_id") == "challenge","fresh/repeated optional applies current Challenge at its own entry"): _finish(); return
		protected = _shell.attempts.story_snapshot()
		var gear: Dictionary = _shell.player.equipment.snapshot()
		var stats: Dictionary = _shell.player.stats.duplicate(true)
		for id: String in order:
			if not await _test_gated_defeat(id): _finish(); return
			_expect(_state().cleared_ids.has(id),"real gated defeated callback commits order member " + id)
			var bank_id: String = BANK_FOR[id]
			_shell.request_pause(); await _settle()
			var tail: Dictionary = _shell.capture_campaign_snapshot()
			if not _expect(paused and not tail.is_empty() and tail.level.local.actors[id].hp == 0.0 and tail.level.local.banks[bank_id].status == "running" and tail.level.local.banks[bank_id].phase == "recovery" and tail.level.local.banks[bank_id].last_cancel_reason.is_empty(),"HP0 Tender preserves its original admitted recovery tail in complete paused aggregate: " + _shell.campaign_error): _finish(); return
			if not await _disk_restore(tail,"HP0 original tail " + id): _finish(); return
			var original: Dictionary = tail.level.local.banks[bank_id]
			_shell.menu.resume_requested.emit()
			for _tick: int in range(MAX_TICKS):
				await _probe.tick_finished
				if not _live() or _shell.player.dead: break
				var current: Dictionary = _bank(bank_id).call("state")
				if current.status == "complete": break
			var ended: Dictionary = _bank(bank_id).call("state")
			_expect(ended.status == "complete" and ended.cycle == original.cycle and _same(_encode(ended.exchange),original.exchange) and _same(ended.receipts,original.receipts) and ended.last_cancel_reason.is_empty(),"fresh recipient lets the same original HP0 tail finish without cancel/restart/refill: " + id)
		_expect(_state().cleared_ids == order and _state().stage == "before-final" and int(_shell.active_level.call("get_tool").call("state").cycle) == 0,"both unique Tender defeat orders reach before-final with Handler unadmitted")
		if not await _test_contact(Vector3(0,0,-6.7)): _finish(); return
		_shell.request_pause(); await _settle()
		var checkpoint: Dictionary = _shell.attempts.state().side_attempt.checkpoint
		if not _expect(paused and _shell.active_level.current_checkpoint().id == CP_ID and checkpoint.level.progress.checkpoint_id == CP_ID and int(checkpoint.level.local.tool.cycle) == 0 and checkpoint.level.local.defeated_ids == order,"quiet native contact durably drains exact before-final checkpoint prior to Handler admission"): _finish(); return
		if not await _final_active_transport(): _finish(); return
		if not await _test_gated_defeat("final_handler"): _finish(); return
		for _tick: int in range(MAX_TICKS):
			await _probe.tick_finished
			if _shell.active_level.is_completed() or not _live() or _shell.player.dead: break
		_shell.request_pause(); await _settle()
		var completed: Dictionary = _shell.capture_campaign_snapshot()
		if not _expect(paused and not completed.is_empty() and _shell.active_level.is_completed() and _state().exit_open and _shell.campaign_error.is_empty(),"real final defeat/harmless consumers completes through supported Shell"): _finish(); return
		_expect(completed.level.local.defeated_ids == order + ["final_handler"] and completed.level.local.scheduler.reservations.is_empty() and completed.level.local.scheduler.encounter_id.is_empty(),"quiet completion retains exact actual defeat prefix and ended native Scheduler")
		_expect(_shell.attempts.state().completed_optional == ["A2-O2"] and _shell.attempts.state().reward_ids == ["A2-O2-completion-stamp"] and _same(_shell.attempts.story_snapshot(),protected) and _shell.player.equipment.snapshot() == gear and _shell.player.stats == stats,"actual optional completion stamps once with no equipment/stat/main-route growth")
		_expect(not _shell.active_level.request_completion(COMPLETE_ID),"completed boundary cannot issue duplicate completion")
		if not await _test_contact(Vector3(0,0,-13.9)): _finish(); return
		await _settle()
		_expect(paused and _shell.menu.page_name() == "journey" and _shell.attempts.active_kind() == "story" and _same(_shell.capture_campaign_snapshot(),protected),"native completed contact exit returns whole protected Story to Journey")
		_expect(_shell.attempts.state().reward_ids == ["A2-O2-completion-stamp"] and _shell.attempts.state().completed_main == PREFIX,"held/repeated optional return preserves exactly one stamp and unchanged main prefix")
	_shell.menu.continue_story_requested.emit(); await _settle()
	_expect(paused and _shell.menu.page_name() == "resume" and _same(_shell.capture_campaign_snapshot(),protected),"explicit Continue Story offers paused Resume after side return")
	_finish()

func _final_active_transport() -> bool:
	# TEST_ONLY representative side-of-tool placement. The real Lane earns
	# warning/lock/active and samples the actual shared Hero; no phase, target,
	# deadline, swept path or hit latch is assigned.
	paused = true
	var actor: Node3D = _shell.active_level.call("get_actor","final_handler") as Node3D
	_shell.player.global_position = actor.global_position + Vector3.LEFT*1.5 + Vector3.UP*0.04
	_shell.player.velocity = Vector3.ZERO
	_shell.menu.resume_requested.emit()
	var reached: bool = false
	for _tick: int in range(MAX_TICKS):
		await _probe.tick_finished
		if not _live() or _shell.player.dead: break
		var lane: Dictionary = _shell.active_level.call("get_tool").call("state")
		if lane.status == "running" and lane.phase == "active": reached = true; _shell.request_pause(); break
	await _settle()
	var saved: Dictionary = _shell.capture_campaign_snapshot()
	if not _expect(reached and paused and not saved.is_empty() and saved.level.local.tool.status == "running" and saved.level.local.tool.phase == "active","actual Lane active native full-unit pause preserves all original consumers: " + _shell.campaign_error): return false
	var tool: Dictionary = saved.level.local.tool
	_expect(tool.clock_s == saved.level.local.scheduler.clock_s and tool.hero_samples.hero.position == saved.player.motion.position and tool.hero_samples.hero.clock_s == saved.level.local.scheduler.clock_s,"actual original Lane sample/endpoint matches complete saved Player/Scheduler")
	if tool.has("pending_segments"):
		var count: int = 0
		for segments: Array in tool.pending_segments.values(): count += segments.size()
		_expect(int(tool.schema_version) == 2 and count > 0,"naturally retained piecewise pending Lane schema2 remains complete and nonempty")
		print("ACTUAL O2 conditional pending Lane segments: ",count," original schema2 snapshot retained exactly")
	else:
		_expect(int(tool.schema_version) == 1,"complete native Lane barrier has no invented pending path/schema2")
		print("O2 pending_segments2 transport unexecuted: no naturally retained pending path at this complete actual native barrier; initial/running schema1 remains exact.")
	if not await _disk_restore(saved,"actual running Handler/Lane" ): return false
	return _expect(_same(_shell.capture_campaign_snapshot().level.local.tool,tool),"fresh quiet whole restore preserves exact original Lane deadlines/sample/hit latches and conditional pending pieces")

func _test_gated_defeat(id: String) -> bool:
	if not _live(): return false
	paused = true
	var actor: Node3D = _shell.active_level.call("get_actor",id) as Node3D
	# TEST_ONLY supported representative feet: off the bounded smoke/lane,
	# close to source. No phase/HP/proof/clock field is assigned.
	_shell.player.global_position = actor.global_position + Vector3.LEFT * 1.5 + Vector3.UP * 0.04 if id == "final_handler" else actor.global_position + Vector3.BACK * 1.5 + Vector3.UP * 0.04
	_shell.player.velocity = Vector3.ZERO
	_shell.menu.resume_requested.emit()
	for _tick: int in range(MAX_TICKS):
		await _probe.tick_finished
		if not _live() or _shell.player.dead: return _expect(false,"TEST recovery setup remains healthy " + id)
		if actor.get("phase") != "recovery" or not _shell.player.get_threat_response_state().stable: continue
		var before: float = float(actor.get("hp"))
		var result: Dictionary = actor.call("take_damage",10000.0,Vector3.ZERO)
		_injuries.append({"id":id,"clock_s":_state().clock_s,"hp_before":before,"hp_after":actor.get("hp"),"result":_encode(result),"scope":"TEST_ONLY public gated injury, not ordinary primary"})
		# A refused gate is retained and diagnosed, not hidden by a repeated attempt.
		if not _expect(result.get("accepted",false) and float(result.get("hp_damage",0.0)) == before and float(actor.get("hp")) == 0.0,"actual recovery gate accepts explicit TEST public injury for " + id + ": " + str(result)): return false
		for _step: int in range(2): await _probe.tick_finished
		return _expect(_state().cleared_ids.has(id),"native defeat transaction flushes earned local fact " + id)
	return _expect(false,"bounded genuine recovery publication before TEST injury: " + id + str(_state()))

func _test_contact(position_value: Vector3) -> bool:
	if not _live(): return false
	paused = true
	_shell.player.global_position = position_value + Vector3.UP * 0.04
	_shell.player.velocity = Vector3.ZERO
	_shell.menu.resume_requested.emit()
	for _tick: int in range(10):
		await _probe.tick_finished
		if paused: break
	return _expect(_shell.campaign_error.is_empty() and is_instance_valid(_shell.player) and not _shell.player.dead,"explicit TEST contact resolves natively without callback/runtime fault: " + _shell.campaign_error)

func _disk_restore(expected: Dictionary,label: String) -> bool:
	var refs: Array = _refs(_shell)
	_shell.free(); _shell = null
	_expect(_refs_freed(refs),"old complete optional Player/three actors/two banks/lane/Scheduler/cues are freed before " + label)
	if not await _new_shell(): return false
	_events.clear(); _watch = true
	_shell.menu.resume_requested.emit(); await _settle(); _watch = false
	return _expect(_live() and paused and _shell.menu.page_name() == "resume" and _same(_shell.capture_campaign_snapshot(),expected) and _events.is_empty(),"independent disk active Continue quietly restores exact full unit: " + label + " / " + _shell.campaign_error + str(_events))

func _corruptions(saved: Dictionary) -> Array[Dictionary]:
	var variants: Array[Dictionary] = []
	var bad: Dictionary = saved.level.duplicate(true); bad.local.defeated_ids = ["invented"]; bad.local.defeat_times = {"invented":0.0}; variants.append({"label":"unknown defeat", "state":bad})
	bad = saved.level.duplicate(true); bad.local.defeated_ids = ["west_tender","west_tender"]; bad.local.defeat_times = {"west_tender":0.0}; variants.append({"label":"duplicate defeat", "state":bad})
	bad = saved.level.duplicate(true); bad.local.defeat_times["west_tender"] = float(bad.local.scenic_clock) + 1.0; variants.append({"label":"future unmatched defeat cursor", "state":bad})
	bad = saved.level.duplicate(true); bad.local.actors.west_tender.root_position[0] += 0.01; variants.append({"label":"moved immutable source", "state":bad})
	bad = saved.level.duplicate(true); bad.local.banks.west_bank.clock_s += 0.000000001; variants.append({"label":"bank/Scheduler exact clock drift", "state":bad})
	bad = saved.level.duplicate(true); bad.local.banks.west_bank.configuration.geometry.radius += 0.01; variants.append({"label":"changed original footprint", "state":bad})
	bad = saved.level.duplicate(true); bad.local.banks.west_bank.contact_since_s -= 1.0 / float(Engine.physics_ticks_per_second); variants.append({"label":"fabricated earlier grace", "state":bad})
	bad = saved.level.duplicate(true); bad.local.banks.west_bank.exchange.active_until_s += 1.0 / float(Engine.physics_ticks_per_second); variants.append({"label":"refreshed original active deadline", "state":bad})
	bad = saved.level.duplicate(true); bad.local.views.erase("west_bank"); variants.append({"label":"missing original running presentation witness", "state":bad})
	return variants

func _seed_story(registry: CinderCampaignRegistry) -> bool:
	paused = true
	_preview = MainScene.instantiate(); _preview.set("level_scene_path",STORY_PATH); root.add_child(_preview)
	paused = true; await _settle()
	var hero: CinderPlayer = _preview.get("player") as CinderPlayer
	var level: CinderLevel = _preview.get("active_level") as CinderLevel
	if not _expect(is_instance_valid(hero) and is_instance_valid(level) and level.level_id == "A2-L4" and String(_preview.get("level_load_error")).is_empty(),"accepted actual A2-L4 pristine Story fixture"): return false
	var anchor: Vector2 = _preview.call("get_aim_anchor_normalized")
	var camera: Camera3D = _preview.get("camera") as Camera3D
	var snapshot: Dictionary = {"schema_version":1,"level_id":"A2-L4","scene_path":STORY_PATH,"paused":true,"equipment_ids":hero.equipment.snapshot(),"player":hero.snapshot_state(),"level":level.snapshot_state(),"shell":{"api_revision":Shell.SHELL_API,"anchor_normalized":[anchor.x,anchor.y],"input_sequence":0,"last_input_observation":{},"camera_focus":Codec.vector3(camera.global_position-Vector3(0,18,13)),"shake_left_s":0.0,"difficulty_at_entry":"standard"}}
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var payload: Dictionary = model.state(); payload.completed_main = PREFIX.duplicate()
	payload.story = {"kind":"story","level_id":"A2-L4","snapshot":snapshot.duplicate(true),"checkpoint":snapshot.duplicate(true)}
	var store: CinderSaveStore = Store.new(_test_root + "campaign.json"); store.payload_validator = model.saved_payload_error
	var valid: bool = not snapshot.player.is_empty() and not snapshot.level.is_empty() and model.state_error(payload).is_empty() and store.write_payload(payload)
	_expect(valid,"public validated Attempts/Store saves TEST prefix plus actual full Story unit: " + model.state_error(payload) + store.last_error)
	level.exit_level(); _preview.free(); _preview = null
	return valid

func _new_shell() -> bool:
	_events.clear(); _watch = true
	_shell = Shell.new() as CinderCampaignShell
	if not _expect(_shell.configure_runtime(_raw,_test_root+"campaign.json",_test_root+"settings.json",_test_root+"preferences.json"),"supported isolated Shell runtime configured before tree entry"): return false
	root.add_child(_shell); await _settle(); _watch = false
	return _expect(paused and _shell.player == null and _shell.menu.page_name() == "title" and _shell.campaign_error.is_empty() and _events.is_empty(),"independent disk Shell quietly validates whole session at Title: " + _shell.campaign_error + str(_events))

func _observe_added(node: Node) -> void:
	if not _watch: return
	if node is CinderPlayer:
		node.fired.connect(func(_kind: String) -> void: _events.append("fired"))
		node.died.connect(func() -> void: _events.append("death"))
		node.world_action_executed.connect(func(_record: Dictionary) -> void: _events.append("world-action"))
		node.action_resolved.connect(func(_kind: String,_hits: int,_damage: float) -> void: _events.append("action-result"))
		node.equipment_changed.connect(func(_id: String) -> void: _events.append("equipment"))
	if node is CinderLevel:
		node.checkpoint_requested.connect(func(_level: String,_id: String,_kind: String) -> void: _events.append("checkpoint"))
		node.completion_requested.connect(func(_level: String,_id: String) -> void: _events.append("completion"))
		node.contact_exit_requested.connect(func(_level: String,_id: String) -> void: _events.append("exit"))
	if node.get_script() in [Smoke,Lane]:
		node.connect("state_changed",func(_state: Dictionary) -> void: _events.append("consumer-state"))
		if node.get_script() == Smoke: node.connect("tick_resolved",func(_id: String,_cycle: int,_result: Dictionary) -> void: _events.append("smoke-tick"))
		else: node.connect("hit_resolved",func(_id: String,_cycle: int,_result: Dictionary) -> void: _events.append("lane-hit"))
	if node.get_script() in [Tender,Handler]: node.connect("defeated",func(_id: String) -> void: _events.append("actor-defeat"))
	if node.get_script() == Scheduler: node.connect("reservation_invalidated",func(_id: String,_reason: String) -> void: _events.append("reservation-invalidated"))
	if node.get_script() in [InteractionCue,ThreatCue]: node.connect("state_changed",func(_state: Dictionary) -> void: _events.append("required-cue"))
	if node is CinderCampaignShell: node.connect("input_observed",func(_record: Dictionary) -> void: _events.append("input"))

func _bank(id: String) -> Node3D: return _shell.active_level.call("get_bank",id) as Node3D
func _state() -> Dictionary: return _shell.active_level.call("encounter_state") if _live() else {}
func _live() -> bool: return is_instance_valid(_shell) and is_instance_valid(_shell.active_level) and _shell.active_level.level_id == "A2-O2" and _shell.campaign_error.is_empty()
func _settle() -> void:
	for _frame: int in range(8): await process_frame
func _same(a: Variant,b: Variant) -> bool:
	var encoded: String = Exact.stringify(a)
	return not encoded.is_empty() and encoded == Exact.stringify(b)
func _refs(node: Node) -> Array:
	var refs: Array = [weakref(node)]
	for child: Node in node.get_children(): refs.append_array(_refs(child))
	return refs
func _refs_freed(refs: Array) -> bool:
	for ref: WeakRef in refs:
		if ref.get_ref() != null: return false
	return not refs.is_empty()
func _encode(value: Variant) -> Variant:
	if value is Vector3: return [value.x,value.y,value.z]
	if value is Vector2: return [value.x,value.y]
	if value is Rect2: return {"diagnostic_native_type":"Rect2","position":_encode(value.position),"size":_encode(value.size)}
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
func _expect(ok: bool,note: String) -> bool:
	_checks += 1
	if not ok: _failures += 1; push_error("FAIL A2-O2 loading side: " + note)
	return ok
func _finish() -> void:
	if _finished: return
	_finished = true; _watch = false
	if is_instance_valid(_preview):
		var level: CinderLevel = _preview.get("active_level") as CinderLevel
		if is_instance_valid(level): level.exit_level()
		_preview.free()
	if is_instance_valid(_shell):
		var refs: Array = _refs(_shell); _shell.free()
		_expect(_refs_freed(refs),"complete active Shell/native descendants free at final cleanup")
	_shell = null; _preview = null
	if is_instance_valid(_probe): _probe.free()
	paused = false
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_bytes,"TEST metadata preserves canonical registry bytes")
	for name: String in ["campaign.json","campaign.json.bak","settings.json","settings.json.bak","preferences.json","preferences.json.bak"]:
		var path: String = ProjectSettings.globalize_path(_test_root+name)
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	AudioServer.set_bus_layout(_old_audio); Engine.max_fps = _old_fps
	print("O2 explicit public TEST injuries: ",Exact.stringify(_injuries))
	print("A2-O2 loading side smoke: %d checks, %d failures; active/grace/fresh exact disk restore/HP0 original tails/paused fatal Retry/optional both-order gated TEST injuries/CP/final/stamp/Story return/cleanup. No earned route/ordinary combat/art/balance/mobile claim" % [_checks,_failures])
	quit(0 if _failures == 0 else 1)
