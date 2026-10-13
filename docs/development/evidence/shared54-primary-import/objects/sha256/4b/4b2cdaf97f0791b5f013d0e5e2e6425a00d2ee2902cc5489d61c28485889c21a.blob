extends SceneTree
## Focused actual Shell O1 loading/side SaveContinueRetry/completion/return.
## TEST ONLY canonical prior-main prefix and isolated pending-O1 readiness.
## Five TEST placements (three journals, checkpoint, exit) isolate native contact consumers; they certify
## no route, input navigation, earned combat, art fidelity or kit balance.
const Shell: Script = preload("res://scripts/campaign/shell.gd")
const Registry: Script = preload("res://scripts/campaign/registry.gd")
const Attempts: Script = preload("res://scripts/campaign/attempts.gd")
const Store: Script = preload("res://scripts/campaign/save_store.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact: Script = preload("res://scripts/campaign/exact_json.gd")
const MainScene: PackedScene = preload("res://scenes/main.tscn")
const O1Scene: PackedScene = preload("res://scenes/acts/act2/a2_o1.tscn")
const O1: Script = preload("res://scripts/acts/act2/cylinder_perimeter.gd")
const Ray: Script = preload("res://scripts/acts/act2/ray_scout_exchange.gd")
const STORY_PATH: String = "res://scenes/acts/act2/a2_l2.tscn"
const O1_PATH: String = "res://scenes/acts/act2/a2_o1.tscn"
const PREFIX: Array[String] = ["A1-L1", "A1-L2", "A1-L3", "A1-L4", "A1-L5", "A2-L1"]

class NativeTickProbe extends Node:
	signal tick_finished
	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 120
	func _physics_process(_delta: float) -> void:
		tick_finished.emit()

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

func _initialize() -> void:
	_test_root = "user://test-a2-o1-loading-side-%d/" % OS.get_process_id()
	_old_audio = AudioServer.generate_bus_layout()
	_old_fps = Engine.max_fps
	_run.call_deferred()

func _run() -> void:
	create_timer(90.0, true).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "bounded focused loading/side watchdog")
			_finish())
	root.size = Vector2i(540,1170)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_probe = NativeTickProbe.new()
	root.add_child(_probe)
	node_added.connect(_observe_added)
	_registry_bytes = FileAccess.get_file_as_string(Registry.DATA_PATH)
	_raw = JSON.parse_string(_registry_bytes)
	for entry: Dictionary in _raw.levels:
		if entry.id == "A2-O1":
			entry.scene_path = O1_PATH
			entry.readiness = "accepted"
			entry.accepted_commit = "e".repeat(40)
			entry.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(_raw)
	print("TEST ONLY O1 readiness and prior main prefix; actual protected A2-L2 entrance/optional production unit/public Shell transactions. Contacts use explicit TEST Hero placements; no full route/combat/GUI pointer/art/kit-balance credit.")
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A2-O1").is_empty(), "isolated O1 accepted metadata retains canonical optional parent/reward/15+9 links"): _finish(); return
	if not await _seed_story(registry): _finish(); return
	if not await _new_shell(): _finish(); return
	_shell.menu.continue_story_requested.emit()
	await _settle()
	if not _expect(paused and _shell.active_level.level_id == "A2-L2" and _shell.campaign_error.is_empty(), "real disk Continue installs protected actual story paused"): _finish(); return
	var story: Dictionary = _shell.capture_campaign_snapshot()
	_shell.menu.optional_requested.emit("A2-O1")
	await _settle()
	if not _expect(_live_o1() and paused and _shell.attempts.active_kind() == "optional", "parent-clear public Optional installs actual O1 production scene paused: " + _shell.campaign_error): _finish(); return
	var protected: Dictionary = _shell.attempts.story_snapshot()
	var entrance: Dictionary = _shell.capture_campaign_snapshot()
	_expect(_same(story, protected) and _same(_shell.attempts.state().side_attempt.checkpoint, entrance), "side entry protects complete actual story and its own pristine entrance checkpoint")
	_expect(entrance.level.local.size() == 12 and entrance.level.local.exchange.actors.size() == 2 and entrance.level.local.scheduler.reservations.is_empty() and entrance.level.local.collected_ids.is_empty(), "native initial tuple retains all two Scouts/floor/profile and zero fabricated contacts/cycles")
	_expect(not _shell.active_level.request_contact_exit(O1.EXIT_ID, _shell.player), "uncleared optional contact exit rejects")
	var input: Dictionary = _shell.get_input_observation_state()
	_shell.handle_tap(root.get_visible_rect().size * 0.5)
	_expect(_shell.get_input_observation_state() == input and _same(_shell.capture_campaign_snapshot(), entrance), "entry Resume menu consumes tap without attack/movement/state mutation")
	_shell.menu.resume_requested.emit()
	for _index: int in range(8): await _probe.tick_finished
	_expect(not paused and not _shell.player.dead and _live_o1(), "public Resume runs genuine O1 simulation for eight native ticks")
	_shell.request_pause()
	await _settle()
	var saved: Dictionary = _shell.capture_campaign_snapshot()
	if not _expect(not saved.is_empty() and _shell.campaign_error.is_empty() and saved.level.local.scheduler.clock_s > 0.0, "deferred public Pause captures full Player/local fixed-profile tuple after simulation"): _finish(); return
	_shell.menu.difficulty_preference_requested.emit("challenge")
	_expect(_shell.get_difficulty_preference() == "challenge" and saved.level.local.profile_id == "standard", "new preference remains distinct from saved current fixed encounter profile")
	for kind: String in ["unknown", "duplicate", "future", "north_pending"]:
		var bad: Dictionary = saved.level.duplicate(true)
		if kind == "unknown":
			bad.local.collected_ids = ["invented"]
			bad.local.fragment_collected_at = {"invented": 0.0}
		elif kind == "duplicate":
			bad.local.collected_ids = ["west", "west"]
			bad.local.fragment_collected_at = {"west": 0.0}
		elif kind == "future":
			bad.local.collected_ids = ["east"]
			bad.local.fragment_collected_at = {"east": float(bad.local.scenic_clock) + 1.0}
		else:
			bad.local.collected_ids = ["north"]
			bad.local.fragment_collected_at = {"north": 0.0}
			bad.local.checkpoint_contact_seen = true
			bad.local.checkpoint_requested = true
			bad.local.pending_checkpoint = true
		_expect(not _shell.active_level.snapshot_error_with_player(bad, saved.player).is_empty() and not _shell.active_level.restore_state(bad) and _same(_shell.capture_campaign_snapshot(), saved), "malformed " + kind + " contact/CP tuple rejects atomically before live mutation")
	var retired: Array = _refs(_shell)
	_shell.free(); _shell = null
	_expect(_refs_freed(retired), "old optional Shell/world/Player/Scouts/Scheduler/cues released before disk recipient")
	if not await _new_shell(): _finish(); return
	_events.clear(); _watch = true
	_shell.menu.resume_requested.emit() # Title loads actual active side, paused.
	await _settle()
	_watch = false
	if not _expect(_live_o1() and paused and _shell.menu.page_name() == "resume" and _same(_shell.capture_campaign_snapshot(), saved) and _events.is_empty(), "independent disk active Continue quietly restores exact complete saved O1 under different preference: " + _shell.campaign_error + str(_events)): _finish(); return
	_expect(_shell.active_level.get("_profile_id") == "standard" and _same(_shell.attempts.story_snapshot(), protected), "fresh recipient retains saved Standard and untouched protected story")
	_shell.menu.resume_requested.emit()
	for _index: int in range(4): await _probe.tick_finished
	_shell.player.take_damage(_shell.player.max_hp * 4.0, Vector3.ZERO)
	await _settle()
	_expect(paused and _shell.player.dead and _shell.campaign_error.is_empty(), "public TEST lethal shared injury captures dead optional aggregate without enemy attribution")
	var dead: Dictionary = _shell.capture_campaign_snapshot()
	_shell.menu.resume_requested.emit()
	await _settle()
	_expect(paused and _same(dead, _shell.capture_campaign_snapshot()), "dead Resume preserves frozen tuple and requires checkpoint Retry")
	_events.clear(); _watch = true
	_shell.menu.retry_requested.emit()
	await _settle()
	_watch = false
	if not _expect(_live_o1() and paused and _same(_shell.capture_campaign_snapshot(), entrance) and _events.is_empty(), "public Retry reinstalls exact earlier optional entrance/gear/HP/ammo/clocks/aim without duplicate gameplay events"): _finish(); return
	_shell.menu.leave_side_requested.emit()
	await _settle()
	_expect(paused and _shell.menu.page_name() == "journey" and _shell.attempts.active_kind() == "story" and _same(_shell.capture_campaign_snapshot(), protected), "public early abandon returns to Journey with the whole protected story")
	_expect(_shell.attempts.state().completed_main == PREFIX and _shell.attempts.state().completed_optional.is_empty() and _shell.attempts.state().reward_ids.is_empty(), "abandon awards nothing and advances no main progress or statistics")
	_shell.menu.optional_requested.emit("A2-O1")
	await _settle()
	if not _expect(_live_o1() and _shell.active_level.get("_profile_id") == "challenge", "fresh optional applies current Challenge preference at its own entry"): _finish(); return
	protected = _shell.attempts.story_snapshot()
	for id: String in ["east", "west"]:
		if not await _test_contact(O1.FRAGMENT_POSITIONS[id]): _finish(); return
		_expect(_shell.active_level.call("encounter_state").collected_ids.has(id), "actual stable native contact collects " + id + " via TEST placement")
	if not await _test_contact(Vector3(0,0,-5.25)): _finish(); return
	# Live checkpoint drains automatically resume. Use the real public Pause
	# before asserting a frozen current unit and its durable checkpoint.
	_shell.request_pause()
	await _settle()
	if not _expect(paused and _shell.active_level.current_checkpoint().id == O1.CHECKPOINT_ID and _shell.attempts.state().side_attempt.checkpoint.level.progress.checkpoint_id == O1.CHECKPOINT_ID, "actual before-final stable contact durably drains checkpoint before final admission: " + str(_shell.active_level.current_checkpoint()) + " / " + _shell.campaign_error): _finish(); return
	_expect(int(_shell.attempts.state().side_attempt.checkpoint.level.local.exchange.records.final.cycle) == 0, "actual protected before-final checkpoint precedes final Scout admission")
	if not await _test_contact(O1.FRAGMENT_POSITIONS.north): _finish(); return
	# Completion shares the supported automatic-resume policy.
	_shell.request_pause()
	await _settle()
	if not _expect(paused and _shell.active_level.is_completed() and _shell.campaign_error.is_empty(), "third actual contact cancels threats/completes optional through real Shell: " + _shell.campaign_error): _finish(); return
	var completed: Dictionary = _shell.capture_campaign_snapshot()
	_expect(completed.level.local.collected_ids == ["east", "west", "north"] and completed.level.local.scheduler.reservations.is_empty() and completed.level.local.scheduler.encounter_id.is_empty(), "non-sorted contacts remain exact, ended Scheduler retains zero danger")
	_expect(completed.level.local.exchange.actors.west.hp > 0.0 and completed.level.local.exchange.actors.final.hp > 0.0, "journal completion accepts both living Scouts without a defeat-all requirement")
	_expect(_shell.attempts.state().completed_optional == ["A2-O1"] and _shell.attempts.state().reward_ids == ["A2-O1-completion-stamp"] and _same(_shell.attempts.story_snapshot(), protected), "actual optional completion records one canonical stamp and protects all story state")
	_expect(not _shell.active_level.request_completion(O1.COMPLETION_ID), "completed optional cannot grant a second completion")
	if not await _test_contact(Vector3(0,0,-9.9)): _finish(); return
	await _settle()
	_expect(paused and _shell.menu.page_name() == "journey" and _shell.attempts.active_kind() == "story" and _same(_shell.capture_campaign_snapshot(), protected), "actual completed stable exit contact returns to Journey with exact protected story")
	_expect(_shell.attempts.state().reward_ids == ["A2-O1-completion-stamp"] and _shell.attempts.state().completed_main == PREFIX, "return retains once-only stamp without advancing main route or equipment/stats")
	_shell.menu.continue_story_requested.emit()
	await _settle()
	_expect(paused and _shell.menu.page_name() == "resume" and _same(_shell.capture_campaign_snapshot(), protected), "explicit Continue Story offers paused Resume after optional return")
	_finish()

func _seed_story(registry: CinderCampaignRegistry) -> bool:
	paused = true
	_preview = MainScene.instantiate()
	_preview.set("level_scene_path", STORY_PATH)
	root.add_child(_preview)
	paused = true
	await _settle()
	var hero: CinderPlayer = _preview.get("player") as CinderPlayer
	var level: CinderLevel = _preview.get("active_level") as CinderLevel
	if not _expect(is_instance_valid(hero) and is_instance_valid(level) and level.level_id == "A2-L2" and String(_preview.get("level_load_error")).is_empty(), "accepted native A2-L2 entrance constructs the protected story fixture"): return false
	var anchor: Vector2 = _preview.call("get_aim_anchor_normalized")
	var camera: Camera3D = _preview.get("camera") as Camera3D
	var snapshot: Dictionary = {"schema_version":1, "level_id":"A2-L2", "scene_path":STORY_PATH, "paused":true, "equipment_ids":hero.equipment.snapshot(), "player":hero.snapshot_state(), "level":level.snapshot_state(), "shell":{"api_revision":Shell.SHELL_API, "anchor_normalized":[anchor.x,anchor.y], "input_sequence":0, "last_input_observation":{}, "camera_focus":Codec.vector3(camera.global_position - Vector3(0,18,13)), "shake_left_s":0.0, "difficulty_at_entry":"standard"}}
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var payload: Dictionary = model.state()
	payload.completed_main = PREFIX.duplicate()
	payload.story = {"kind":"story", "level_id":"A2-L2", "snapshot":snapshot.duplicate(true), "checkpoint":snapshot.duplicate(true)}
	var store: CinderSaveStore = Store.new(_test_root + "campaign.json")
	store.payload_validator = model.saved_payload_error
	var valid: bool = not snapshot.player.is_empty() and not snapshot.level.is_empty() and model.state_error(payload).is_empty() and store.write_payload(payload)
	_expect(valid, "public validated Attempts/Store saves TEST prior prefix plus actual pristine full story unit: " + model.state_error(payload) + store.last_error)
	level.exit_level()
	_preview.free(); _preview = null
	return valid

func _new_shell() -> bool:
	_events.clear(); _watch = true
	_shell = Shell.new() as CinderCampaignShell
	if not _expect(_shell.configure_runtime(_raw, _test_root+"campaign.json", _test_root+"settings.json", _test_root+"preferences.json"), "supported isolated Shell.configure_runtime before tree entry"): return false
	root.add_child(_shell)
	await _settle()
	_watch = false
	return _expect(paused and _shell.player == null and _shell.menu.page_name() == "title" and _shell.campaign_error.is_empty() and _events.is_empty(), "disk Shell validates complete session quietly at Title: " + _shell.campaign_error + str(_events))

func _test_contact(position_value: Vector3) -> bool:
	if not _live_o1(): return false
	paused = true
	# Explicit focused TEST placement, not navigation, WorldAction or earned route.
	_shell.player.global_position = position_value + Vector3.UP * 0.04
	_shell.player.velocity = Vector3.ZERO
	_shell.menu.resume_requested.emit()
	for _index: int in range(8):
		await _probe.tick_finished
		if paused: break
	return _expect(_shell.campaign_error.is_empty() and is_instance_valid(_shell.player) and not _shell.player.dead, "focused TEST contact remains native healthy and outside callback barrier: " + _shell.campaign_error)

func _live_o1() -> bool:
	return is_instance_valid(_shell) and is_instance_valid(_shell.active_level) and _shell.active_level.level_id == "A2-O1" and _shell.campaign_error.is_empty()

func _observe_added(node: Node) -> void:
	if not _watch: return
	if node is CinderPlayer:
		node.fired.connect(func(_kind: String) -> void: _events.append("fired"))
		node.died.connect(func() -> void: _events.append("death"))
		node.world_action_executed.connect(func(_record: Dictionary) -> void: _events.append("world-action"))
	if node is CinderLevel:
		node.checkpoint_requested.connect(func(_level: String, _id: String, _kind: String) -> void: _events.append("checkpoint"))
		node.completion_requested.connect(func(_level: String, _id: String) -> void: _events.append("completion"))
		node.contact_exit_requested.connect(func(_level: String, _id: String) -> void: _events.append("exit"))
	if node.get_script() == Ray:
		node.hit_resolved.connect(func(_id: String, _result: Dictionary) -> void: _events.append("ray-hit"))
		node.scout_defeated.connect(func(_id: String) -> void: _events.append("ray-defeat"))

func _refs(node: Node) -> Array:
	var refs: Array = [weakref(node)]
	for child: Node in node.get_children(): refs.append_array(_refs(child))
	return refs

func _refs_freed(refs: Array) -> bool:
	for ref: WeakRef in refs:
		if ref.get_ref() != null: return false
	return not refs.is_empty()

func _settle() -> void:
	for _index: int in range(8): await process_frame

func _same(a: Variant,b: Variant) -> bool:
	var text: String = Exact.stringify(a)
	return not text.is_empty() and text == Exact.stringify(b)

func _expect(ok: bool,note: String) -> bool:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("FAIL A2-O1 loading side: " + note)
	return ok

func _finish() -> void:
	if _finished: return
	_finished = true
	_watch = false
	if is_instance_valid(_preview):
		var level: CinderLevel = _preview.get("active_level") as CinderLevel
		if is_instance_valid(level): level.exit_level()
		_preview.free()
	if is_instance_valid(_shell):
		var refs: Array = _refs(_shell)
		_shell.free()
		_expect(_refs_freed(refs), "complete active Shell/native owned descendants freed at cleanup")
	_shell = null; _preview = null
	if is_instance_valid(_probe): _probe.free()
	paused = false
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _registry_bytes, "isolated TEST metadata leaves canonical registry bytes unchanged")
	for name: String in ["campaign.json","campaign.json.bak","settings.json","settings.json.bak","preferences.json","preferences.json.bak"]:
		var path: String = ProjectSettings.globalize_path(_test_root+name)
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	AudioServer.set_bus_layout(_old_audio)
	Engine.max_fps = _old_fps
	print("A2-O1 loading side smoke: %d checks, %d failures; production loading/paused exact disk active Continue/fixed profile/malformed atomic refusal/public fatal Retry/real optional contacts and stamp/protected Journey return/cleanup. TEST prior prefix/readiness and contact placements; no full route/ordinary combat/art/balance/mobile claim" % [_checks,_failures])
	quit(0 if _failures == 0 else 1)
