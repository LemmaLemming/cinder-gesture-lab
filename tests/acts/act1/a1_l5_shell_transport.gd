extends SceneTree
## SOURCE ONLY until genuinely imported/executed by the Act1 owner.
## Actual production A1-L5, shared Shell/Hero/Scheduler/eye/consumer.
## Isolated TEST registry and four predecessor completion IDs are setup,
## not earned playthroughs or canonical acceptance. Only A1-L1 Replay uses
## the existing generic TEST scene. No stage/sample/checkpoint/eye-HP seed.
## Optional --blink-warning-dash uses labelled public rusher injury and real
## Hero placement, then lets the authored parent publish/start its own flow.

const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Attempts = preload("res://scripts/campaign/attempts.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Equipment = preload("res://scripts/equipment.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Layout = preload("res://scripts/acts/act1/living_moon_layout.gd")
const MoonCodec = preload("res://scripts/acts/act1/living_moon_codec.gd")
const LevelScript = preload("res://scripts/acts/act1/living_moon.gd")
const Body = preload("res://scripts/acts/act1/living_moon_body.gd")
const Nose = preload("res://scripts/acts/act1/living_moon_nose.gd")
const Consumer = preload("res://scripts/combat/native_sampled_circle.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Rush = preload("res://scripts/acts/act1/rush_selenite.gd")
const Lane = preload("res://scripts/combat/lane_mechanism.gd")
const Threat = preload("res://scripts/cues/threat_cue.gd")
const Interaction = preload("res://scripts/cues/interaction_cue.gd")
const ScenePath: String = "res://scenes/acts/act1/a1_l5.tscn"
const ReplayFixture: String = "res://tests/fixtures/campaign/live_a1_l1.tscn"
const Prefix: Array[String] = ["A1-L1", "A1-L2", "A1-L3", "A1-L4"]
const WatchdogMs: int = 120000

class NativeTickProbe extends Node:
	signal tick_finished
	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_physics_priority = 120
	func _physics_process(_delta: float) -> void:
		tick_finished.emit()

var game: CinderCampaignShell
var fresh: CinderCampaignShell
var candidate: Dictionary = {}
var probe: NativeTickProbe
var raw: Dictionary = {}
var registry_bytes: PackedByteArray
var test_root: String
var checks: int = 0
var failures: int = 0
var started_ms: int = 0
var finishing: bool = false
var aborted: bool = false
var operation: String = "setup"
var observe_new: bool = false
var quiet_levels: Array[int] = []
var quiet_players: Array[int] = []
var events: Array[Dictionary] = []
var observations: Array[Dictionary] = []
var setups: Array[Dictionary] = []
var receipts: Array[Dictionary] = []
var first_failure: Dictionary = {}
var old_fps: int
var old_audio: AudioBusLayout


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	old_fps = Engine.max_fps
	old_audio = AudioServer.generate_bus_layout()
	test_root = "user://test-act1-moon-shell-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	process_frame.connect(_watchdog)
	node_added.connect(_observe_added)
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--level-scene") or argument in ["--capture", "--capture-polish"]:
			_expect(false, "Shell transport cannot run through Main preview-mode arguments"); await _finish(); return
	registry_bytes = FileAccess.get_file_as_bytes(Registry.DATA_PATH)
	var parsed: Variant = JSON.parse_string(registry_bytes.get_string_from_utf8())
	if not _expect(parsed is Dictionary and parsed.get("levels") is Array, "canonical registry supplies isolated TEST metadata"):
		await _finish(); return
	raw = parsed.duplicate(true)
	for entry: Dictionary in raw.levels:
		if entry.id == Layout.LEVEL_ID or entry.id == "A1-L1":
			setups.append({"kind": "TEST in-memory registry override", "level_id": entry.id, "canonical_readiness_before": entry.readiness, "canonical_scene_before": entry.scene_path, "canonical_accepted_commit_before": entry.accepted_commit})
			entry.scene_path = ScenePath if entry.id == Layout.LEVEL_ID else ReplayFixture
			entry.readiness = "accepted"; entry.accepted_commit = "f".repeat(40); entry.api_revision = Registry.API_REVISION
	var registry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error(Layout.LEVEL_ID).is_empty(), "in-memory candidate L5 registration only; canonical route/links/acceptance remain untouched"):
		await _finish(); return
	probe = NativeTickProbe.new(); root.add_child(probe)
	if not await _seed_actual_pristine_story(registry): await _finish(); return
	game = _new_shell()
	if game == null or not await _settle(): await _finish(); return
	if not _expect(paused and game.active_level == null and game.player == null and game.menu.page_name() == "title" and game.campaign_error.is_empty(), "fresh actual Title reads the isolated format2 Story without installing a world") or not await _click(game, "ContinueStoryButton") or not _bindings(game):
		await _finish(); return
	var pristine: Dictionary = game.capture_campaign_snapshot()
	if not _closed(pristine) or not _expect(pristine.level.local.stage == "return" and pristine.level.local.blink.status == "idle" and pristine.level.local.blink.cycle == 0 and pristine.level.local.scheduler.clock_s == 0.0 and pristine.level.local.scheduler.reservations.is_empty() and pristine.level.progress.checkpoint_ids.is_empty() and not pristine.level.progress.completed and game.attempts.state().completed_main == Prefix and game.attempts.state().side_attempt == null, "actual pristine L5 Story has one schema4 source registration, no earned L5 progress and unstarted Blink"):
		await _finish(); return
	var protected_wire: String = Exact.stringify(game.attempts.state().story.checkpoint)
	if not _expect(protected_wire == Exact.stringify(pristine) and _durable(game), "real pristine whole unit is the earlier protected Retry checkpoint") or not _direct_candidate(pristine): await _finish(); return
	receipts.append({"stage": "actual pristine Story", "exact_snapshot": Exact.stringify(pristine)})
	if not await _click(game, "ResumeButton"): await _finish(); return
	var hp_before: float = game.player.hp
	game.player.take_damage(2.0, Vector3.ZERO)
	setups.append({"kind": "TEST public Hero injury", "before_hp": hp_before, "after_hp": game.player.hp, "amount": 2.0})
	if not _expect(game.player.hp < hp_before and not game.player.dead, "actual public injury gives the later saved unit distinct real resources") or not await _wait(func() -> bool: return _impact_warning(), "actual initial return impact warning", 10.0): await _finish(); return
	if not await _pause(): await _finish(); return
	var warning: Dictionary = game.capture_campaign_snapshot()
	if not _closed(warning) or not _expect(warning.level.local.stage == "return" and warning.level.local.impact.status == "running" and warning.level.local.impact.phase == "warning" and warning.level.local.blink.status == "idle" and warning.level.local.blink.cycle == 0 and warning.level.local.scheduler.schema_version == 4 and warning.player.resources.hp == game.player.hp and Exact.stringify(game.attempts.state().story.checkpoint) == protected_wire and _durable(game), "public Pause saves genuine return warning, registered idle Blink and actual resources while preserving pristine Retry"):
		await _finish(); return
	receipts.append({"stage": "actual return warning", "exact_snapshot": Exact.stringify(warning), "exact_earlier_checkpoint": protected_wire})
	var frozen: Dictionary = _donor()
	await create_timer(0.08, true).timeout
	if not _expect(_donor() == frozen, "paused actual whole unit/native registrations/clocks/UI/disk remain exact") or not _malformed(warning) or not _direct_candidate(warning) or not await _fresh_continue(warning): await _finish(); return
	if not await _gui_retry(protected_wire, "initial return warning"): await _finish(); return
	if "--blink-warning-dash" in OS.get_cmdline_user_args():
		if not await _representative_blink(): await _finish(); return
	if not await _protected_replay(): await _finish(); return
	await _finish()


func _new_shell() -> CinderCampaignShell:
	var shell: CinderCampaignShell = Shell.new()
	if not _expect(shell.configure_runtime(raw, test_root + "campaign.json", test_root + "settings.json", test_root + "preferences.json"), "actual Shell uses process-isolated save/settings/preference paths"):
		shell.free(); return null
	root.add_child(shell)
	return shell


func _seed_actual_pristine_story(registry: CinderCampaignRegistry) -> bool:
	# Reuse the actual Shell fresh-candidate capture seam from A1-L4 tests.
	# Only the campaign model's explicit TEST prefix is arranged; all Player,
	# local mechanics, source binding, view and progress are genuinely captured.
	game = _new_shell()
	if game == null or not await _settle(): return false
	candidate = game._prepare(Layout.LEVEL_ID, Equipment.STARTER)
	if not _expect(not candidate.is_empty(), "actual shared Shell constructs the production L5 entrance"): return false
	var pristine: Dictionary = game._capture_fresh_candidate(candidate, game._fresh_shell_state())
	if not _closed(pristine): return false
	var model = Attempts.new(registry)
	var payload: Dictionary = model.state()
	payload.completed_main = Prefix.duplicate()
	payload.story = {"kind": "story", "level_id": Layout.LEVEL_ID, "snapshot": pristine.duplicate(true), "checkpoint": pristine.duplicate(true)}
	var store = Store.new(test_root + "campaign.json")
	store.payload_validator = model.saved_payload_error
	if not _expect(model.state_error(payload).is_empty() and store.write_payload(payload), "public validated store accepts disclosed four-predecessor TEST prefix plus genuinely captured pristine L5 Story: " + model.last_error + store.last_error): return false
	setups.append({"kind": "TEST sequential predecessor prefix, not earned playthrough", "completed_main": Prefix.duplicate(), "candidate_scene": ScenePath, "local_snapshot_version": 1, "canonical_registry_changed": false})
	operation = "explicit seed candidate disposal"
	game._dispose(candidate); candidate = {}
	var refs: Array[WeakRef] = _refs(game)
	game.free(); game = null
	return _expect(_freed(refs), "seed Shell and actual candidate dispose normally before fresh Title")


func _direct_candidate(saved: Dictionary) -> bool:
	var donor: Dictionary = _donor()
	candidate = game._prepare(Layout.LEVEL_ID, saved.equipment_ids, {}, saved)
	if not _expect(not candidate.is_empty(), "canonical Shell constructs a distinct actual L5 restore candidate"): return false
	var level: CinderLevel = candidate.level
	var player: CinderPlayer = candidate.player
	var eye: CharacterBody3D = level.get("eye") as CharacterBody3D
	var blink: CinderNativeSampledCircle = level.get("blink") as CinderNativeSampledCircle
	var sched: CinderThreatScheduler = level.get("scheduler") as CinderThreatScheduler
	var before: String = _physical(level, player)
	if not _expect(not before.is_empty() and level.is_restore_candidate() and not level.finish_restore_candidate() and not level.request_checkpoint("TEST-forbidden") and not level.request_completion("TEST-forbidden") and eye.get("hp") == Layout.BOSS_MAX_HP and eye.velocity == Vector3.ZERO and blink.state().status == "idle" and blink.state().cycle == 0 and sched.source_control_state(eye).reservations.is_empty() and eye.call("get_sampled_circle_binding").hero == player and player != game.player, "fresh actual candidate has a closed physical signature, pristine eye and idle cycle-zero consumer bound to its own authoritative Hero"): return false
	_begin_watch("direct quiet candidate prevalidation/commit", level, player)
	if not _expect(level.snapshot_error_with_player(saved.level, saved.player).is_empty() and _physical(level, player) == before and _donor() == donor and events.is_empty(), "complete saved Player/eye/Scheduler/consumer prevalidation leaves fresh candidate and donor unchanged"): return false
	if not _expect(player.restore_state(saved.player) and level.restore_state(saved.level), "quiet actual Player then parent physical-eye/Scheduler/source commit succeeds"): return false
	var optical: String = game._candidate_presentation_error(candidate, saved.shell)
	var local: Dictionary = level.call("_capture_local_state")
	if not _expect(optical.is_empty() and _same(player.snapshot_state(), saved.player) and _same(local, saved.level.local) and events.is_empty() and level.is_restore_candidate() and _donor() == donor, "actual complete fresh commit preserves exact resources/sample/clock/lease/phase/cues/proof with zero recipient callbacks"): return false
	receipts.append({"stage": "direct actual quiet candidate", "saved_stage": saved.level.local.stage, "blink_status": local.blink.status, "blink_cycle": local.blink.cycle, "quiet_callbacks": events.duplicate(true)})
	_end_watch("explicit direct candidate disposal")
	var refs: Array[WeakRef] = _refs(candidate.container)
	game._dispose(candidate); candidate = {}
	return _expect(_freed(refs) and _donor() == donor, "normal candidate disposal frees its native descendants without donor or disk changes")


func _malformed(saved: Dictionary) -> bool:
	var rows: Array[Dictionary] = []
	var bad: Dictionary = saved.duplicate(true); bad.level.local["unknown_local"] = true; rows.append({"label": "unknown local key", "unit": bad})
	bad = saved.duplicate(true); bad.level.local.eye.source_binding.generation = 2; rows.append({"label": "changed actual source incarnation", "unit": bad})
	bad = saved.duplicate(true); bad.level.local.eye.source_binding["hero"] = game.player; rows.append({"label": "received Hero Object in closed source wire", "unit": bad})
	bad = saved.duplicate(true); bad.level.local.eye.position[0] += 0.125; rows.append({"label": "changed fixed real eye pivot", "unit": bad})
	bad = saved.duplicate(true); bad.level.local.eye.phase = 2; rows.append({"label": "incoherent HP phase", "unit": bad})
	bad = saved.duplicate(true); bad.level.local.scheduler.schema_version = 1; bad.level.local.scheduler.erase("sampled_circle_sources"); rows.append({"label": "registered schema4 downgrade", "unit": bad})
	bad = saved.duplicate(true); bad.level.local.scheduler.sampled_circle_sources[Layout.EYE_ID].alive = false; rows.append({"label": "wrong paired actual eye lifecycle", "unit": bad})
	bad = saved.duplicate(true); bad.level.local.scheduler.clock_s += 0.125; rows.append({"label": "changed paired native clock", "unit": bad})
	bad = saved.duplicate(true); bad.level.local.blink.clock_s += 0.000000001; rows.append({"label": "exact consumer clock mismatch", "unit": bad})
	bad = saved.duplicate(true); bad.player.world_actions.clock_s = INF; rows.append({"label": "nonfinite complete Player clock", "unit": bad, "local_restore": false})
	bad = saved.duplicate(true); bad.level.progress.checkpoint_id = "moon-phase-3"; rows.append({"label": "fabricated checkpoint history", "unit": bad})
	if saved.level.local.blink.status == "running":
		bad = saved.duplicate(true); bad.level.local.blink.sample.ground_position[0] += 0.125; rows.append({"label": "retargeted original sampled point", "unit": bad})
		bad = saved.duplicate(true); bad.level.local.blink.source_binding.definition.radius += 0.125; rows.append({"label": "changed immutable native recipe", "unit": bad})
	for row: Dictionary in rows:
		var before: Dictionary = _donor()
		_begin_watch("malformed installed-donor refusal: " + row.label, game.active_level, game.player)
		var local_rejected: bool = true
		if row.get("local_restore", true): local_rejected = not game.active_level.restore_state(row.unit.level)
		var rejected: bool = not game.active_level.snapshot_error_with_player(row.unit.level, row.unit.player).is_empty() and not String(game.attempts.snapshot_validator.call(row.unit)).is_empty() and local_rejected and not game.attempts.record_snapshot(row.unit)
		if not _expect(rejected and _donor() == before and events.is_empty(), "public local/restore/durable validation refuses before installed state/cue/resources/UI/identity/disk writes: " + row.label): return false
		_end_watch("malformed validation candidate retirement")
	# Clear rejection diagnostics through the real valid reader, never a write to
	# campaign_error or hidden operation flags. Its candidate is not installed.
	candidate = game._prepare_snapshot(saved)
	if not _expect(not candidate.is_empty(), "valid whole reader remains usable after malformed packets"): return false
	game._dispose(candidate); candidate = {}
	return true


func _fresh_continue(saved: Dictionary) -> bool:
	var donor: Dictionary = _donor()
	operation = "fresh Title validation observations"
	fresh = _new_shell()
	if fresh == null or not await _settle(): return false
	if not _expect(paused and fresh.player == null and fresh.active_level == null and fresh.menu.page_name() == "title" and fresh.campaign_error.is_empty(), "second actual Shell validates format2 at fresh Title without installed sources"): return false
	_begin_watch("fresh GUI Continue recipient observations", null, null, true)
	if not await _click(fresh, "ContinueStoryButton"): return false
	if not _expect(paused and _same(fresh.capture_campaign_snapshot(), saved) and _ids(fresh.active_level, fresh.player) != _ids(game.active_level, game.player) and _durable(fresh) and _donor() == donor and events.is_empty(), "fresh GUI Continue restores independent exact actual native unit/resources without new-recipient callbacks or donor/checkpoint mutation") or not _bindings(fresh): return false
	receipts.append({"stage": "fresh actual GUI disk Continue", "saved_stage": saved.level.local.stage, "recipient_observations": events.duplicate(true)})
	_end_watch("normal fresh Continue world disposal")
	var refs: Array[WeakRef] = _refs(fresh)
	fresh.free(); fresh = null
	return _expect(_freed(refs) and _donor() == donor, "normal fresh Shell disposal leaves no duplicate native recipients")


func _gui_retry(expected_wire: String, label: String) -> bool:
	var old_ids: Dictionary = _ids(game.active_level, game.player)
	var refs: Array[WeakRef] = _refs(game.world)
	_begin_watch("actual GUI Retry new recipient observations", null, null, true)
	if not await _click(game, "RetryButton"): return false
	if not _expect(paused and game.menu.page_name() == "resume" and Exact.stringify(game.capture_campaign_snapshot()) == expected_wire and _ids(game.active_level, game.player) != old_ids and _freed(refs) and _durable(game) and events.is_empty(), "actual GUI Retry restores the earlier coherent whole checkpoint/resources with zero new-recipient callbacks and disposes later donor: " + label) or not _bindings(game): return false
	receipts.append({"stage": "actual GUI Retry", "label": label, "exact_checkpoint": expected_wire, "new_recipient_observations": events.duplicate(true)})
	_end_watch("after actual GUI Retry")
	return true


func _representative_blink() -> bool:
	# No parent stage/clock/history, eye HP, sample or checkpoint field is seeded.
	if not await _click(game, "ResumeButton") or not await _wait(func() -> bool: return game.active_level.get("impact_demonstrated") == true, "authored return impact completes its genuine active interval", 12.0): return false
	var rusher: CharacterBody3D = game.active_level.get("rusher") as CharacterBody3D
	var hp_before: float = rusher.get("hp")
	var answer: Dictionary = rusher.call("take_damage", hp_before, Vector3.ZERO)
	setups.append({"kind": "TEST public native return-rusher lethal injury, not earned combat", "source_id": Layout.RUSHER_ID, "amount": hp_before, "answer": _encode(answer), "clock_s": _scheduler().get_clock()})
	if not _expect(answer.get("accepted") == true and rusher.get("dead") == true, "actual public rusher injury commits real defeat/cleanup"): return false
	if not await _place(-4.7): return false
	if not await _wait(func() -> bool: return game.active_level.current_checkpoint().id == "capsule-ready", "authored blocked-capsule boundary publishes its real checkpoint", 10.0, true) or not await _settle(): return false
	var earlier: Dictionary = game.attempts.state().story.checkpoint
	var earlier_wire: String = Exact.stringify(earlier)
	if not _closed(earlier) or not _expect(earlier.level.local.stage == "capsule" and earlier.level.local.impact_demonstrated and earlier.level.local.actors[Layout.RUSHER_ID].dead and earlier.level.progress.checkpoint_ids == {"capsule-ready": "encounter"} and earlier.level.local.blink.cycle == 0 and _durable(game), "actual capsule checkpoint preserves native history and unstarted eye consumer"): return false
	if paused and not await _click(game, "ResumeButton"): return false
	if not await _place(Layout.EYE_APPROACH_POSITION.z) or not await _wait(func() -> bool: return _blink_warning(), "authored boss threshold admits genuine warning-start sampled Blink", 12.0): return false
	if not await _pause(): return false
	var warning: Dictionary = game.capture_campaign_snapshot()
	if not _closed(warning) or not _expect(warning.level.local.stage == "blink" and warning.level.local.blink.status == "running" and warning.level.local.blink.phase == "warning" and warning.level.local.blink.cycle == 1 and warning.level.local.eye.hp == Layout.BOSS_MAX_HP and warning.level.local.scheduler.sampled_circle_sources[Layout.EYE_ID] == warning.level.local.eye.source_binding and Exact.stringify(game.attempts.state().story.checkpoint) == earlier_wire, "actual first Blink joins real eye/native sample/original lease/schema4 without replacing capsule Retry"): return false
	receipts.append({"stage": "TEST representative actual Blink warning", "exact_snapshot": Exact.stringify(warning), "exact_earlier_checkpoint": earlier_wire})
	if not _malformed(warning) or not _direct_candidate(warning) or not await _fresh_continue(warning): return false
	var path: Array = warning.level.local.framing[Layout.EYE_ID].proof.path
	var escape: Dictionary = path[1]
	var direction: Vector3 = Codec.read_vector3(escape.to) - Codec.read_vector3(escape.from)
	direction.y = 0.0
	if not await _click(game, "ResumeButton"): return false
	if not _expect(direction.length() > 0.0 and game.player.request_dash(direction.normalized()), "actual public Hero dash follows the retained native proved escape direction"): return false
	await probe.tick_finished
	if not await _pause(): return false
	var moving: Dictionary = game.capture_campaign_snapshot()
	if not _closed(moving) or not _expect(moving.player.clocks.dash_left_s > 0.0 and moving.level.local.blink.phase == "warning" and _same(moving.level.local.blink.sample, warning.level.local.blink.sample) and not _same(moving.player.motion.position, moving.level.local.blink.sample.hero_position) and Exact.stringify(game.attempts.state().story.checkpoint) == earlier_wire and _durable(game), "actual mid-dash warning saves current Hero motion while preserving original fixed native sample and capsule checkpoint"): return false
	receipts.append({"stage": "actual moving Hero sampled-warning", "exact_snapshot": Exact.stringify(moving)})
	if not _direct_candidate(moving) or not await _fresh_continue(moving): return false
	return await _gui_retry(earlier_wire, "later sampled-warning/moving-Hero unit")


func _protected_replay() -> bool:
	var protected: Dictionary = game.attempts.state().story.duplicate(true)
	var story_wire: String = Exact.stringify(game.capture_campaign_snapshot())
	operation = "disclosed TEST A1-L1 Replay namespace"
	game.menu.replay_requested.emit("A1-L1", Equipment.STARTER)
	if not await _settle(): return false
	if not _expect(paused and game.active_level.level_id == "A1-L1" and game.active_level.scene_file_path == ReplayFixture and game.attempts.active_kind() == "replay" and game.player.hp == game.player.max_hp and game.player.shells == game.player.max_shells and _same(game.attempts.state().story, protected), "eligible four-prefix TEST Replay creates its own fresh resources while protecting the entire L5 Story/checkpoint"): return false
	if not await _click(game, "ResumeButton"): return false
	var before: float = game.player.hp
	game.player.take_damage(1.0, Vector3.ZERO)
	setups.append({"kind": "TEST public Replay Hero injury", "amount": 1.0, "before_hp": before, "after_hp": game.player.hp})
	if not _expect(game.player.hp < before, "actual replay resources become independently injured") or not await _pause(): return false
	if not _expect(_same(game.attempts.state().story, protected) and _durable(game), "actual worn replay Save leaves full protected L5 Story/resources exact"): return false
	var refs: Array[WeakRef] = _refs(game.world)
	game.menu.leave_side_requested.emit()
	if not await _settle(): return false
	return _expect(paused and game.attempts.state().side_attempt == null and _same(game.attempts.state().story, protected) and Exact.stringify(game.capture_campaign_snapshot()) == story_wire and _freed(refs) and _durable(game), "normal Replay Leave frees side descendants and quietly restores exact protected actual L5 Story") and _bindings(game)


func _impact_warning() -> bool:
	if not _live(): return false
	var current: Dictionary = game.active_level.get("impact").state()
	return current.status == "running" and current.phase == "warning" and not current.reservation_id.is_empty()


func _blink_warning() -> bool:
	if not _live(): return false
	var current: Dictionary = game.active_level.get("blink").state()
	return game.active_level.get("stage") == "blink" and current.status == "running" and current.phase == "warning" and not current.reservation_id.is_empty()


func _place(z: float) -> bool:
	if not await _wait(func() -> bool: return game.player.get_threat_response_state().stable and game.player.velocity == Vector3.ZERO, "actual stopped supported Hero before TEST placement", 8.0, true): return false
	if paused: return _expect(false, "TEST placement cannot force Resume an unexpected native pause")
	var before: Vector3 = game.player.global_position
	game.player.global_position = Vector3(0.0, before.y, z)
	setups.append({"kind": "TEST Hero placement on the same actual level floor, not earned travel", "from": Codec.vector3(before), "to": Codec.vector3(game.player.global_position), "clock_s": _scheduler().get_clock()})
	return true


func _scheduler() -> CinderThreatScheduler:
	return game.active_level.get("scheduler") as CinderThreatScheduler


func _live() -> bool:
	return is_instance_valid(game) and is_instance_valid(game.active_level) and is_instance_valid(game.player) and game.active_level.get_script() == LevelScript and game.campaign_error.is_empty()


func _closed(saved: Dictionary) -> bool:
	return _expect(not saved.is_empty() and saved.get("level") is Dictionary and saved.level.get("local") is Dictionary and MoonCodec.envelope_error(saved.level.local).is_empty() and saved.level_id == Layout.LEVEL_ID and saved.scene_path == ScenePath and saved.level.local_snapshot_version == 1 and saved.level.local.eye.schema_version == 2 and saved.level.local.scheduler.schema_version == 4 and not Exact.stringify(saved).is_empty(), "complete actual L5/Shell/Player transport retains closed local1/eye2/Scheduler4 and exact typed values")


func _bindings(shell: CinderCampaignShell) -> bool:
	var level: CinderLevel = shell.active_level
	if not _expect(level != null and shell.player != null and level.get_script() == LevelScript and level.hero == shell.player and level.shared_shell == shell and _count_players(shell.world) == 1, "installed L5 retains exactly one actual shared Player/Shell/camera/HUD world"): return false
	var eye: CharacterBody3D = level.get("eye") as CharacterBody3D
	var blink: CinderNativeSampledCircle = level.get("blink") as CinderNativeSampledCircle
	var binding: Dictionary = eye.call("get_sampled_circle_binding")
	var owners: Dictionary = level.call("scheduler_bindings").owners
	return _expect(eye.get_script() == Body and blink.get_script() == Consumer and blink.get_parent() == eye and level.get("nose").get_script() == Nose and level.get("scheduler").get_script() == Scheduler and binding.hero == shell.player and binding.opening_position == eye.global_position and eye.global_position == Layout.EYE_POSITION and eye.velocity == Vector3.ZERO and owners[Layout.EYE_ID] == eye and owners[Layout.RUSHER_ID] == level.get("rusher") and owners[Layout.NOSE_ID] == level.get("nose") and owners[Layout.IMPACT_ID] == level.get("impact"), "genuine eye lease owner/child consumer/native Hero and complete actual owner aliases survive Shell transport")


func _physical(level: CinderLevel, player: CinderPlayer) -> String:
	var owners: Dictionary = level.call("scheduler_bindings").owners
	var sources: Dictionary = {}
	var sched: CinderThreatScheduler = level.get("scheduler") as CinderThreatScheduler
	for id: String in owners:
		var node: Node3D = owners[id]
		var value: Dictionary = {"id": str(node.get_instance_id()), "parent": str(node.get_parent().get_instance_id()), "transform": _encode(node.global_transform), "visible": node.visible, "control": _encode(sched.source_control_state(node))}
		if node is CharacterBody3D: value["velocity"] = Codec.vector3(node.velocity)
		var collision: CollisionShape3D = node.get_node_or_null("BodyCollision") as CollisionShape3D
		if collision != null: value["collision"] = {"id": str(collision.get_instance_id()), "shape": str(collision.shape.get_instance_id()), "transform": _encode(collision.transform), "disabled": collision.disabled}
		if node.has_method("get_cue"): value["cue"] = _cue_signature(node.call("get_cue"))
		sources[id] = value
	sources[Layout.EYE_ID]["hp"] = owners[Layout.EYE_ID].get("hp")
	sources[Layout.EYE_ID]["dead"] = owners[Layout.EYE_ID].get("dead")
	sources[Layout.EYE_ID]["phase"] = owners[Layout.EYE_ID].get("phase")
	var blink: Node = level.get("blink")
	return Exact.stringify({"ids": _ids(level, player), "player": player.snapshot_state(), "sources": sources, "blink": _encode(blink.call("state")), "blink_cue": _cue_signature(blink.call("get_cue")), "hatch_cue": _cue_signature(level.get("_hatch_cue")), "art_pose": level.get("_moon_art").call("pose_state")})


func _cue_signature(cue: Node3D) -> Dictionary:
	var result: Dictionary = {"id": str(cue.get_instance_id()), "state": _encode(cue.call("state")), "parts": []}
	for node: Node in cue.get_children():
		if node is MeshInstance3D:
			var material: Material = node.material_override
			var part: Dictionary = {"id": str(node.get_instance_id()), "visible": node.visible, "transform": _encode(node.transform), "mesh_id": str(node.mesh.get_instance_id()) if node.mesh != null else "none", "material_id": str(material.get_instance_id()) if material != null else "none"}
			if material is StandardMaterial3D: part["color"] = _encode(material.albedo_color)
			result.parts.append(part)
	return result


func _ids(level: CinderLevel, player: CinderPlayer) -> Dictionary:
	return {"level": str(level.get_instance_id()), "hero": str(player.get_instance_id()), "eye": str(level.get("eye").get_instance_id()), "blink": str(level.get("blink").get_instance_id()), "nose": str(level.get("nose").get_instance_id()), "scheduler": str(level.get("scheduler").get_instance_id()), "rusher": str(level.get("rusher").get_instance_id())}


func _donor() -> Dictionary:
	var ui: Dictionary = {}
	for surface: Node in [game.menu, game.hud]:
		for node: Node in surface.find_children("*", "Control", true, false):
			var control: Control = node
			var row: Array = [control.visible, control.is_visible_in_tree()]
			if control is Label: row.append(control.text)
			if control is Button: row.append(control.disabled)
			ui[String(control.get_path())] = row
	return {"snapshot": Exact.stringify(game.capture_campaign_snapshot()), "native": _physical(game.active_level, game.player), "attempts": Exact.stringify(game.attempts.state()), "disk": _disk(), "ui": ui, "camera": game.camera.global_transform, "input": game.get_input_observation_state(), "effects": _effects(game.fx), "paused": paused}


func _effects(fx: PixelEffects) -> Array:
	var result: Array = []
	for node: Node in fx.find_children("*", "", true, false):
		var value: Dictionary = {"id": str(node.get_instance_id()), "class": node.get_class(), "queued": node.is_queued_for_deletion()}
		if node is Node3D: value["transform"] = node.transform; value["visible"] = node.visible
		if node is AudioStreamPlayer: value["playing"] = node.playing; value["paused"] = node.stream_paused
		result.append(value)
	return result


func _durable(shell: CinderCampaignShell) -> bool:
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(test_root + "campaign.json"))
	if not envelope is Dictionary or envelope.get("format_version") != Store.FORMAT_VERSION: return false
	var decoded: Dictionary = Exact.parse(String(envelope.get("payload_json", "")))
	return decoded.get("accepted") == true and _same(decoded.value, shell.attempts.state())


func _disk() -> Dictionary:
	var result: Dictionary = {}
	var directory := DirAccess.open(test_root)
	if directory != null:
		for name: String in directory.get_files(): result[name] = FileAccess.get_file_as_bytes(test_root + name)
	return result


func _begin_watch(label: String, level: CinderLevel, player: CinderPlayer, newly_added: bool = false) -> void:
	operation = label; events.clear(); quiet_levels.clear(); quiet_players.clear(); observe_new = newly_added
	if level != null: quiet_levels.append(level.get_instance_id())
	if player != null: quiet_players.append(player.get_instance_id())


func _end_watch(label: String) -> void:
	operation = label; observe_new = false; quiet_levels.clear(); quiet_players.clear()


func _observe_added(node: Node) -> void:
	if observe_new and node is CinderLevel: quiet_levels.append(node.get_instance_id())
	if observe_new and node is CinderPlayer: quiet_players.append(node.get_instance_id())
	var ref: WeakRef = weakref(node)
	if node is CinderPlayer:
		node.fired.connect(func(kind: String) -> void: _record("fired", ref, {"kind": kind}))
		node.died.connect(func() -> void: _record("hero-died", ref, {}))
		node.world_action_executed.connect(func(value: Dictionary) -> void: _record("world-action", ref, value))
		node.action_resolved.connect(func(kind: String, hits: int, damage: float) -> void: _record("action-resolved", ref, {"kind": kind, "hits": hits, "damage": damage}))
		node.equipment_changed.connect(func(id: String) -> void: _record("equipment", ref, {"id": id}))
	if node is CinderLevel:
		node.checkpoint_requested.connect(func(id: String, checkpoint: String, kind: String) -> void: _record("checkpoint", ref, {"level_id": id, "checkpoint": checkpoint, "kind": kind}))
		node.completion_requested.connect(func(id: String, complete: String) -> void: _record("complete", ref, {"level_id": id, "id": complete}))
		node.contact_exit_requested.connect(func(id: String, contact: String) -> void: _record("contact", ref, {"level_id": id, "id": contact}))
	if node.get_script() in [Consumer, Nose, Rush, Lane]:
		node.connect("state_changed", func(value: Dictionary) -> void: _record("source-phase", ref, value))
		if node.get_script() == Rush:
			node.connect("defeated", func(id: String) -> void: _record("rusher-defeated", ref, {"id": id}))
		node.connect("hit_resolved", func(id: String, cycle: int, result: Dictionary) -> void: _record("source-hit", ref, {"id": id, "cycle": cycle, "result": result}))
	if node.get_script() == Body:
		node.connect("state_changed", func(value: Dictionary) -> void: _record("eye-state", ref, value))
		node.connect("phase_changed", func(id: String, phase: int) -> void: _record("eye-phase", ref, {"id": id, "phase": phase}))
		node.connect("defeated", func(id: String) -> void: _record("eye-defeated", ref, {"id": id}))
	if node.get_script() == Scheduler:
		node.connect("reservation_invalidated", func(id: String, reason: String) -> void: _record("cancel", ref, {"id": id, "reason": reason}))
	if node.get_script() in [Threat, Interaction]:
		node.connect("state_changed", func(value: Dictionary) -> void: _record("cue", ref, value))


func _record(kind: String, ref: WeakRef, value: Dictionary) -> void:
	var node: Node = ref.get_ref() as Node
	if node == null: return
	var level: CinderLevel = node as CinderLevel
	var ancestor: Node = node.get_parent()
	while level == null and ancestor != null:
		if ancestor is CinderLevel: level = ancestor
		ancestor = ancestor.get_parent()
	var level_id: int = level.get_instance_id() if level != null else 0
	var watched: bool = quiet_levels.has(level_id) or quiet_players.has(node.get_instance_id())
	var row: Dictionary = {"operation": operation, "kind": kind, "emitter_id": str(node.get_instance_id()), "level_id": str(level_id), "inside_tree": node.is_inside_tree(), "watched_recipient": watched, "value": _encode(value)}
	observations.append(row)
	if watched: events.append(row)
	# Every retirement notification remains recorded. Scope is explicit native
	# recipient identity; no phase/status whitelist or hidden lifecycle override.


func _pause() -> bool:
	game.request_pause()
	if not await _settle(): return false
	return _expect(paused and game.menu.page_name() == "pause" and game.menu.is_open() and game.campaign_error.is_empty(), "public Pause drains the actual deferred save barrier: " + game.campaign_error)


func _click(shell: CinderCampaignShell, name: String) -> bool:
	var button: Button = shell.menu.find_child(name, true, false) as Button
	if not _expect(button != null and button.is_visible_in_tree() and not button.disabled, "actual enabled GUI " + name): return false
	var pressed: Array[String] = []
	button.pressed.connect(func() -> void: pressed.append(name), CONNECT_ONE_SHOT)
	var point: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new(); motion.position = point; motion.global_position = point; root.push_input(motion, true)
	var press := InputEventMouseButton.new(); press.button_index = MOUSE_BUTTON_LEFT; press.position = point; press.global_position = point; press.pressed = true; root.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton; release.pressed = false; root.push_input(release, true)
	if not await _settle(): return false
	return _expect(pressed == [name] and shell.campaign_error.is_empty(), "single actual GUI click settles " + name + ": " + shell.campaign_error)


func _settle() -> bool:
	for frame: int in range(8):
		if aborted or finishing: return false
		await process_frame
	return true


func _wait(predicate: Callable, label: String, seconds: float, allow_checkpoint_pause: bool = false) -> bool:
	var end: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while not finishing and not aborted and Time.get_ticks_msec() <= end:
		if predicate.call() == true: return true
		if not is_instance_valid(game) or not is_instance_valid(game.player) or game.player.dead: return _expect(false, label + " lost actual living Hero")
		if paused and not allow_checkpoint_pause: return _expect(false, label + " encountered native pause; no forced Resume")
		await process_frame
	return _expect(false, "bounded observation failed: " + label)


func _same(left: Variant, right: Variant) -> bool:
	var wire: String = Exact.stringify(left)
	return not wire.is_empty() and wire == Exact.stringify(right)


func _encode(value: Variant) -> Variant:
	if value is Vector3: return Codec.vector3(value)
	if value is Color: return [value.r, value.g, value.b, value.a]
	if value is Basis: return {"x": _encode(value.x), "y": _encode(value.y), "z": _encode(value.z)}
	if value is Transform3D: return {"basis": _encode(value.basis), "origin": _encode(value.origin)}
	if value is StringName: return String(value)
	if value is int and (value < -9007199254740991 or value > 9007199254740991): return {"native_integer_decimal": str(value)}
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _encode(value[key])
		return result
	if value is Array:
		var result: Array = []
		for child: Variant in value: result.append(_encode(child))
		return result
	return value


func _count_players(node: Node) -> int:
	var count: int = 1 if node is CinderPlayer else 0
	for child: Node in node.get_children(): count += _count_players(child)
	return count


func _refs(node: Node) -> Array[WeakRef]:
	var result: Array[WeakRef] = [weakref(node)]
	for child: Node in node.get_children(): result.append_array(_refs(child))
	return result


func _freed(refs: Array[WeakRef]) -> bool:
	for ref: WeakRef in refs:
		if ref.get_ref() != null: return false
	return not refs.is_empty()


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > WatchdogMs:
		_expect(false, "bounded focused L5 Shell test watchdog"); aborted = true; _finish.call_deferred()


func _expect(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1; push_error("L5 SHELL: " + label)
		if first_failure.is_empty():
			first_failure = {"label": label, "paused": paused, "operation": operation, "campaign_error": game.campaign_error if is_instance_valid(game) else "Shell absent"}
			if is_instance_valid(game) and is_instance_valid(game.active_level):
				first_failure["level_error"] = game.active_level.last_snapshot_error
				first_failure["level_capture_error"] = game.active_level.get("_capture_error")
				first_failure["stage"] = game.active_level.get("stage")
				first_failure["eye_error"] = game.active_level.get("eye").get("last_snapshot_error") if game.active_level.get_script() == LevelScript else "TEST Replay"
				first_failure["blink_error"] = game.active_level.get("blink").get("last_snapshot_error") if game.active_level.get_script() == LevelScript else "TEST Replay"
	return ok


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true; _end_watch("normal final cleanup")
	if is_instance_valid(game) and not candidate.is_empty(): game._dispose(candidate); candidate = {}
	var refs: Array[WeakRef] = []
	for shell: CinderCampaignShell in [fresh, game]:
		if is_instance_valid(shell): refs.append_array(_refs(shell)); shell.free()
	fresh = null; game = null
	if is_instance_valid(probe): refs.append_array(_refs(probe)); probe.free()
	paused = false
	await create_timer(0.5, true).timeout
	await process_frame
	_expect(_freed(refs) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal Shell/candidate/level/Player/source/cue cleanup frees every native descendant/group")
	_expect(FileAccess.get_file_as_bytes(Registry.DATA_PATH) == registry_bytes, "all TEST metadata/prefix/replay arrangements leave canonical registry bytes unchanged")
	var report: String = "res://.cinder/a1-l5-shell-transport-%d.json" % Time.get_ticks_usec()
	var file := FileAccess.open(report, FileAccess.WRITE)
	if file == null: _expect(false, "actual focused report is writable")
	else:
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "first_failure": first_failure, "setups": setups, "receipts": receipts, "observations": observations, "fixture_mode": "blink-warning-dash" if "--blink-warning-dash" in OS.get_cmdline_user_args() else "return-warning-only", "wall_ms": Time.get_ticks_msec() - started_ms, "scope": "Actual production L5 under isolated TEST registration/four unearned predecessor IDs; actual initial return warning schema4 Pause/format2/fresh idle-recipient quiet commit/fresh Title GUI Continue/earlier GUI Retry/malformed refusal/protected full Story during separate generic TEST A1-L1 Replay/normal cleanup. Optional Blink mode uses explicit public rusher injury and same-floor Hero placements, then genuine impact/capsule/checkpoint/first Blink warning/native proved-direction Hero dash. No assigned parent phase/sample/checkpoint or eye damage. Full authored combat, Sneeze/final/hatch/escape/Act2 transition/art/kit/balance/mobile remain untested."}, "\t")); file.close()
	var directory := DirAccess.open(test_root)
	if directory != null:
		for name: String in directory.get_files(): DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root))
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-L5 SHELL TRANSPORT: %d checks/%d failures; report=%s; TEST representative persistence only" % [checks, failures, report])
	quit(1 if failures > 0 else 0)
