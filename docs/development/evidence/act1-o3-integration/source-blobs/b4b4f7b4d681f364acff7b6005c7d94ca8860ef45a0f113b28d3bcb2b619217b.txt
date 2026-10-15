extends SceneTree
## Focused production Shell cases. Source-only until the owner runs dev.py.
## --case=entry
## --case=checkpoint --source-report=<successful entry JSON>
## --case=final --profile=standard|challenge --source-report=<checkpoint JSON>
## --case=retry|completion --source-report=<successful final JSON>
## --case=replay --source-report=<successful completion JSON>
## Downstream cases restore an unchanged original exact Session, not invented
## actor packets. Only disclosed same-floor Hero positions and an unlock prefix
## are TEST setup. Ordinary public primary supplies every recorded guard defeat.
## No native clocks, HP, phases, custody, proofs or saved packets are assigned.

const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Attempts = preload("res://scripts/campaign/attempts.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Equipment = preload("res://scripts/equipment.gd")
const MainScene = preload("res://scenes/main.tscn")
const Layout = preload("res://scripts/acts/act1/royal_rehearsal_layout.gd")
const RehearsalCodec = preload("res://scripts/acts/act1/royal_rehearsal_codec.gd")
const RehearsalScript = preload("res://scripts/acts/act1/royal_rehearsal.gd")
const Actor = preload("res://scripts/acts/act1/mushroom_selenite.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Threat = preload("res://scripts/cues/threat_cue.gd")
const Interaction = preload("res://scripts/cues/interaction_cue.gd")
const Sweep = preload("res://scripts/combat/body_sweep.gd")
const O3_PATH: String = "res://scenes/acts/act1/a1_o3.tscn"
const STORY_PATH: String = "res://scenes/acts/act1/a1_l4.tscn"
const PREFIX: Array[String] = ["A1-L1", "A1-L2", "A1-L3", "A1-L4"]
const REWARD_ID: String = "A1-O3-completion-stamp"
const WATCHDOG_MS: int = 120000

var game: CinderCampaignShell
var preview: Node
var raw: Dictionary = {}
var registry_bytes: PackedByteArray
var test_root: String
var report_path: String
var checks: int = 0
var failures: int = 0
var first_failure: Dictionary = {}
var assertions: Array[Dictionary] = []
var started_ms: int
var finishing: bool = false
var scope_complete: bool = false
var operation: String = "source setup"
var case_name: String = ""
var profile: String = "standard"
var source_path: String = ""
var source_reports: Array[Dictionary] = []
var observations: Array[Dictionary] = []
var admission_events: Array[Dictionary] = []
var operation_wait_overruns: Array[Dictionary] = []
var registration_barriers: Array[Dictionary] = []
var receipts: Array[Dictionary] = []
var setups: Array[Dictionary] = []
var protected_story: Dictionary = {}
var unlocked_before: Array = []
var original_unit: Dictionary = {}
var original_checkpoint: Dictionary = {}
var old_fps: int
var old_audio: AudioBusLayout


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	test_root = "user://test-act1-o3-campaign-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	report_path = "res://.cinder/a1-o3-campaign-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	old_fps = Engine.max_fps; old_audio = AudioServer.generate_bus_layout()
	process_frame.connect(_watchdog); node_added.connect(_observe_added)
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	if not _arguments() or not _configure_registry(): await _finish(); return
	var ok: bool = false
	if case_name == "entry":
		ok = await _run_entry()
	else:
		if not _restore_original_session() or not await _new_shell(): await _finish(); return
		if case_name == "replay": ok = await _run_replay()
		else:
			if not await _load_original(): await _finish(); return
			match case_name:
				"checkpoint": ok = await _run_checkpoint()
				"final": ok = await _run_final()
				"retry": ok = await _run_retry()
				"completion": ok = await _run_completion()
	scope_complete = ok and failures == 0
	await _finish()


func _arguments() -> bool:
	var seen: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		var key: String = argument.get_slice("=", 0)
		if not _expect(key in ["--case", "--profile", "--source-report"] and not seen.has(key) and argument.find("=") >= 0, "only unique named case/profile/source-report arguments are supported"): return false
		seen[key] = true
		match key:
			"--case": case_name = argument.trim_prefix("--case=")
			"--profile": profile = argument.trim_prefix("--profile=")
			"--source-report": source_path = argument.trim_prefix("--source-report=")
	return _expect(case_name in ["entry", "checkpoint", "final", "retry", "completion", "replay"] and (source_path.is_empty() == (case_name == "entry")) and (seen.has("--profile") == (case_name == "final")) and profile in ["standard", "challenge"], "explicit bounded case and genuine source report required; only final selects an explicit profile")


func _configure_registry() -> bool:
	registry_bytes = FileAccess.get_file_as_bytes(Registry.DATA_PATH)
	var parsed: Variant = JSON.parse_string(registry_bytes.get_string_from_utf8())
	if not _expect(parsed is Dictionary and parsed.get("levels") is Array, "actual canonical Registry supplies the TEST clone"): return false
	raw = parsed.duplicate(true)
	var changed: int = 0
	for row: Dictionary in raw.levels:
		if row.id == Layout.LEVEL_ID:
			setups.append({"kind": "TEST in-memory O3 Registry row only", "before": row.duplicate(true), "scene_path": O3_PATH, "accepted_commit": "f".repeat(40)})
			row.scene_path = O3_PATH; row.readiness = "accepted"; row.accepted_commit = "f".repeat(40); row.api_revision = Registry.API_REVISION
			changed += 1
	var registry: CinderCampaignRegistry = Registry.new(raw)
	if not _expect(changed == 1 and registry.last_error.is_empty() and registry.scene_error(Layout.LEVEL_ID).is_empty() and registry.scene_error("A1-L4").is_empty(), "only O3 readiness is TEST enabled; accepted L4 remains authoritative"): return false
	var entry: Dictionary = registry.entry(Layout.LEVEL_ID)
	return _expect(entry.parent_level_id == "A1-L4" and not registry.is_unlocked(Layout.LEVEL_ID, ["A1-L1", "A1-L2", "A1-L3"]) and registry.is_unlocked(Layout.LEVEL_ID, PREFIX) and entry.reward_id == REWARD_ID and entry.reward_policy == "once_only_completion_stamp_no_stat_growth", "canonical L4 parent, unlock and once-only existing stamp govern O3")


func _run_entry() -> bool:
	if not await _seed_story(Registry.new(raw)) or not await _new_shell(): return false
	operation = "public Continue Story"
	game.menu.continue_story_requested.emit()
	if not await _observe_registration("Continue accepted L4", 1, func() -> bool: return _live("A1-L4") and paused and game.menu.page_name() == "resume"): return false
	protected_story = game.attempts.state().story.duplicate(true)
	unlocked_before = game.attempts.state().unlocked_equipment.duplicate()
	if not _expect(_same(game.capture_campaign_snapshot(), protected_story.snapshot) and _durable(), "actual complete L4 Story becomes the protected unit"): return false
	operation = "public Optional entry"
	game.menu.optional_requested.emit(Layout.LEVEL_ID)
	if not await _observe_registration("Optional record/fresh installation", 2, func() -> bool: return _live(Layout.LEVEL_ID) and paused and game.menu.page_name() == "resume" and game.attempts.active_kind() == "optional"): return false
	var entrance: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_pristine(entrance) and _bindings() and _same(game.attempts.state().side_attempt.checkpoint, entrance) and _unchanged_story(false) and _durable(), "actual six-dormant entrance is the original whole checkpoint and protects Story"): return false
	_receipt("pristine-entrance", entrance)
	if not await _pause("pristine Save") or not _expect(_same(game.capture_campaign_snapshot(), entrance), "pristine public Save preserves exact whole unit") or not await _reopen_side(entrance, "pristine entrance"): return false
	if not await _start_exercise(0): return false
	if not await _wait_live(func() -> bool: return not _current_admissions(0).is_empty(), "genuine first parallel admission", 12.0): return false
	if not await _pause("actual first-pair native admission Save"): return false
	var partial: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_valid_unit(partial) and partial.level.local.exercise_index == 0 and partial.level.local.stage == "active" and partial.level.local.scheduler.profile.id == "standard" and not partial.level.local.scheduler.reservations.is_empty() and not partial.level.local.admission_gate.is_empty() and _same(game.attempts.state().side_attempt.checkpoint, entrance), "representative first-pair Save retains real native lease/proof/gate and earlier entrance"): return false
	_receipt("first-pair-save", partial)
	if not await _preference_reopen(partial, "challenge", "first-pair standard recipe"): return false
	return await _leave(false)


func _run_checkpoint() -> bool:
	if not _expect(_pristine(original_unit), "checkpoint producer starts only the original genuine pristine entrance"): return false
	for index: int in range(2):
		if not await _start_exercise(index) or not await _clear_pair(index): return false
		if index == 0 and not await _wait_live(func() -> bool: return _host().exercise_index == 1 and _host().stage == "awaiting_bell", "actual first pair retires", 6.0): return false
	if not await _observe_registration("actual pre-final checkpoint publication", 1, func() -> bool: return _live(Layout.LEVEL_ID) and _prefinal(game.attempts.state().side_attempt.checkpoint) and _durable()): return false
	# Authored checkpoints normally auto-resume. Public Pause captures the real
	# current unit while retaining the earlier exact checkpoint in the Session.
	if not await _pause("actual pre-final current unit"): return false
	var captured: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_prefinal(captured) and _prefinal(game.attempts.state().side_attempt.checkpoint) and _progress_events("checkpoint").size() == 1 and _unchanged_story(false) and _durable(), "actual dead-prefix/final-dormant whole pre-final checkpoint is durable with one genuine publication"): return false
	_receipt("prefinal-checkpoint", captured)
	return true


func _run_final() -> bool:
	if not _expect(_prefinal(original_unit), "final case starts the genuine original pre-final checkpoint") or not _change_preference(profile): return false
	if not await _start_exercise(2): return false
	if not await _wait_live(func() -> bool: return _current_admissions(2).size() >= 2, "both actual final native admissions", 14.0): return false
	var rows: Array[Dictionary] = _current_admissions(2)
	var first: Dictionary = rows[0]; var second: Dictionary = rows[1]
	var recipe: Dictionary = _host().recipes.staggered
	var expected: Array[String] = []
	expected.assign(["rehearsal-final-rear", "rehearsal-final-front"] if profile == "challenge" else ["rehearsal-final-front", "rehearsal-final-rear"])
	var original: Dictionary = first.answer.reservation
	var earliest: float = float(original.lock_from_s if profile == "challenge" else original.active_until_s)
	var leading: Dictionary = second.source_states[expected[0]]
	if not _expect(recipe.recipe_id == Layout.recipe_id(2, profile) and recipe.profile == profile and recipe.order == expected and first.source_id == expected[0] and second.source_id == expected[1] and float(second.clock_s) >= earliest and not leading.dead and leading.cycle == first.source_states[expected[0]].cycle and first.host.admission_gate.reservation_id == first.answer.reservation_id and first.host.admission_gate.release_phase == ("lock" if profile == "challenge" else "recovery"), "actual final admission order and original gate/cycle obey selected versioned recipe"): return false
	# Native safety may defer an eligible warning. Preserve the actual overlap
	# observation; eligibility is not a promise to bypass reciprocal proofs.
	var overlapped: bool = float(second.clock_s) < float(original.active_until_s)
	if not _expect(not overlapped or (leading.reservation_id == first.answer.reservation_id and leading.phase in ["lock", "active"]), "any observed final overlap retains the real original leading lease and phase"): return false
	for row: Dictionary in [first, second]:
		if not _expect(row.answer.accepted == true and row.answer.armed == true and row.answer.proof.accepted == true and row.answer.proof.uses_blast == false and row.answer.proof.uses_invulnerability == false, "actual native ordinary-only proof survives final arrangement union: " + String(row.source_id)): return false
	receipts.append({"label": "actual-final-arrangement", "profile": profile, "recipe": recipe.duplicate(true), "actual_overlap": overlapped, "eligibility_s": earliest, "actual_second_admission_s": second.clock_s, "scope": "original native eligibility/order/proofs; actual overlap observed separately, safe deferred admission is permitted", "first": _encode(first), "second": _encode(second)})
	if not await _pause("actual final arrangement Save"): return false
	var saved: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_valid_unit(saved) and saved.level.local.stage == "active" and saved.level.local.exercise_index == 2 and _same(game.attempts.state().side_attempt.checkpoint, original_checkpoint), "whole active final Save retains actual original pre-final checkpoint"): return false
	_receipt("final-active-save", saved)
	if not await _preference_reopen(saved, "standard" if profile == "challenge" else "challenge", "final " + profile + " recipe"): return false
	if not await _resume("final ordinary-primary producer") or not await _clear_pair(2): return false
	if not await _observe_registration("actual finite completion publication", 1, func() -> bool: return _live(Layout.LEVEL_ID) and _ready_exit(game.attempts.active_snapshot()) and _durable()): return false
	if not await _pause("genuine completed pre-contact current unit"): return false
	var complete: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_ready_exit(complete) and _progress_events("completion").size() == 1 and _progress_events("exit").is_empty() and _unchanged_story(true) and _durable(), "all original final guards actually defeated; one native completion/stamp is saved before any exit contact"): return false
	_receipt("ready-exit", complete)
	return true


func _run_retry() -> bool:
	if not _expect(_valid_unit(original_unit) and original_unit.level.local.stage == "active" and original_unit.level.local.exercise_index == 2, "Retry donor is the original incomplete active final unit"): return false
	var checkpoint: Dictionary = game.attempts.state().side_attempt.checkpoint.duplicate(true)
	if not _expect(_prefinal(checkpoint), "Retry has its real earlier pre-final checkpoint") or not await _pause("actual RetryButton page"): return false
	var button := game.menu.find_child("RetryButton", true, false) as Button
	if not _expect(button != null and button.is_visible_in_tree() and not button.disabled and game.menu.page_name() == "pause", "actual production pause page exposes RetryButton"): return false
	var before: Dictionary = _ids(); var refs: Array[WeakRef] = _refs(game.world)
	operation = "actual RetryButton public pressed signal"; button.pressed.emit()
	if not await _observe_registration("Retry genuine pre-final whole unit", 1, func() -> bool: return _live(Layout.LEVEL_ID) and paused and game.menu.page_name() == "resume" and _ids() != before): return false
	var restored: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_same(restored, checkpoint) and _prefinal(restored) and _all_new(before, _ids()) and _freed(refs) and _recipient_callbacks().is_empty() and _bindings() and _unchanged_story(false) and _durable(), "Retry quietly restores exact pre-final native prefix/Player/progress, with distinct recipient and normal donor cleanup"): return false
	_receipt("retry-prefinal", restored)
	return true


func _run_completion() -> bool:
	if not _expect(_ready_exit(original_unit) and _unchanged_story(true), "contact case begins genuine completed unit with its already earned single stamp"): return false
	if not await _resume("natural pre-contact readiness") or not await _wait_live(_primary_ready, "healthy Hero naturally settles before contact setup", 4.0): return false
	var level_id: String = str(game.active_level.get_instance_id()); var refs: Array[WeakRef] = _refs(game.world)
	if not _place_hero(Layout.EXIT_POSITION, "real exit Area contact"): return false
	operation = "actual native ExitArea contact and protected Story return"
	if not await _wait_live(func() -> bool: return _events_for(level_id, "exit").size() == 1, "genuine deferred installed O3 exit publication", 8.0, true): return false
	if not await _observe_registration("contact live record/protected Story installation", 2, _story_returned): return false
	if not _expect(_freed(refs) and _completed_session(game.attempts.state()) and _same(game.capture_campaign_snapshot(), protected_story.snapshot) and _events_for(level_id, "exit").size() == 1 and _events_for(level_id, "completion").is_empty() and _durable(), "real contact frees O3 and returns exact Story; existing single stamp is retained without duplicate completion/main/equipment growth"): return false
	_receipt("completed-story-return", game.capture_campaign_snapshot())
	return true


func _run_replay() -> bool:
	if not _expect(_completed_session(game.attempts.state()), "Replay starts only a genuine successful completed original Session"): return false
	operation = "public completed optional Replay from fresh Title"
	game.menu.replay_requested.emit(Layout.LEVEL_ID, Equipment.STARTER)
	if not await _observe_registration("Title Replay load/record/fresh install", 3, func() -> bool: return _live(Layout.LEVEL_ID) and paused and game.menu.page_name() == "resume" and game.attempts.active_kind() == "replay"): return false
	var fresh: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_pristine(fresh) and _bindings() and game.player.hp == game.player.max_hp and game.player.shells == game.player.max_shells and _unchanged_story(true) and _durable(), "fresh Replay resets only its six finite guards and own shared Hero, preserving one existing stamp and exact Story"): return false
	_receipt("pristine-replay", fresh)
	return await _leave(true)


func _restore_original_session() -> bool:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(source_path)
	var parsed: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	var expected_case: String = {"checkpoint": "entry", "final": "checkpoint", "retry": "final", "completion": "final", "replay": "completion"}[case_name]
	var label: String = {"checkpoint": "pristine-entrance", "final": "prefinal-checkpoint", "retry": "final-active-save", "completion": "ready-exit", "replay": "completed-story-return"}[case_name]
	if not _expect(not bytes.is_empty() and parsed is Dictionary and parsed.get("case") == expected_case and parsed.get("complete") == true and parsed.get("checks", 0) > 0 and parsed.get("failures", -1) == 0 and parsed.get("first_failure") is Dictionary and parsed.first_failure.is_empty() and parsed.get("receipts") is Array, "original successful complete producer report required; failures cannot be relabeled"): return false
	var matches: Array[Dictionary] = []
	for row: Variant in parsed.receipts:
		if row is Dictionary and row.get("label") == label: matches.append(row)
	if not _expect(matches.size() == 1, "unique original producer receipt required: " + label): return false
	var row: Dictionary = matches[0]
	original_unit = _read_exact(row.get("exact_snapshot"), label + " whole unit")
	var session: Dictionary = _read_exact(row.get("exact_attempts"), label + " original Session")
	protected_story = _read_exact(row.get("exact_protected_story"), label + " protected Story")
	if not _expect(_closed(original_unit) and row.get("snapshot_sha256") == Exact.stringify(original_unit).sha256_text() and not session.is_empty() and not protected_story.is_empty() and _same(session.get("story"), protected_story) and session.get("completed_main") == PREFIX, "original exact whole unit/Session/Story/hash agree"): return false
	var model: CinderCampaignAttempts = Attempts.new(Registry.new(raw))
	if not _expect(model.state_error(session).is_empty(), "original exact Session has complete validated model shape"): return false
	unlocked_before = session.unlocked_equipment.duplicate()
	var active: Dictionary = session.story if session.side_attempt == null else session.side_attempt
	original_checkpoint = active.checkpoint.duplicate(true)
	if not _expect(_same(active.snapshot, original_unit) and ((case_name == "replay" and _completed_session(session)) or (case_name != "replay" and active.kind == "optional" and active.level_id == Layout.LEVEL_ID and _valid_unit(original_unit))), "unchanged original Session contains precisely this receipt's actual active unit"): return false
	if not _expect(model.restore_session(session) and _same(model.state(), session), "public Attempts validates/restores original Session without sanitization"): return false
	var store: CinderSaveStore = Store.new(test_root + "campaign.json"); store.payload_validator = model.saved_payload_error
	if not _expect(store.write_payload(session), "public isolated Store persists original unchanged genuine Session"): return false
	source_reports.append({"path": source_path, "sha256": FileAccess.get_sha256(source_path), "case": expected_case, "receipt": label, "snapshot_sha256": row.snapshot_sha256, "source_chain": parsed.get("source_reports", [])})
	setups.append({"kind": "TEST unchanged original successful native Session in unique validated Store; no earned route or packet construction", "source_report": source_path, "source_sha256": FileAccess.get_sha256(source_path), "receipt": label})
	return true


func _read_exact(value: Variant, label: String) -> Dictionary:
	if not _expect(value is String and not value.is_empty(), "original exact typed wire required: " + label): return {}
	var parsed: Dictionary = Exact.parse(value)
	if not _expect(parsed.get("accepted") == true and parsed.get("value") is Dictionary and not parsed.value.is_empty() and Exact.stringify(parsed.value) == value, "exact original scalar bits roundtrip: " + label): return {}
	return parsed.value


func _load_original() -> bool:
	operation = "fresh Title public active-side Continue"
	game.menu.resume_requested.emit()
	if not await _observe_registration("original active-side disk Continue", 1, func() -> bool: return _live(Layout.LEVEL_ID) and paused and game.menu.page_name() == "resume"): return false
	return _expect(_same(game.capture_campaign_snapshot(), original_unit) and _bindings() and _recipient_callbacks().is_empty() and _same(game.attempts.state().story, protected_story) and _durable(), "fresh installed recipient quietly retains original exact native unit and complete Story; no cross-process identity comparison")


func _start_exercise(index: int) -> bool:
	if paused and not await _resume("exercise " + str(index)): return false
	if not await _wait_live(_primary_ready, "actual stable Hero before bell setup", 4.0): return false
	if not _expect(_host().exercise_index == index and _host().stage == "awaiting_bell", "only the expected next original exercise awaits contact"): return false
	if not _place_hero(Vector3(0, 0, 0), "outside bell rearm observation"): return false
	if not await _wait_live(func() -> bool: return _host().bell_armed and not (game.active_level.get_node("BellArea") as Area3D).overlaps_body(game.player) and _primary_ready(), "native outside observation arms the original bell", 4.0): return false
	if not _place_hero(Layout.BELL_POSITION, "real bell Area contact"): return false
	return await _wait_live(func() -> bool: return _host().exercise_index == index and _host().stage == "active" and not _host().bell_armed, "real overlap/deferred contact starts expected exercise", 8.0)


func _clear_pair(index: int) -> bool:
	# A bounded producer of native packets, not route/gesture/balance evidence.
	# Place only a stable living Hero behind each live guard, then use the actual
	# public primary and its native cooldown. No source/body/state is relocated.
	var initial_hp: float = game.player.hp
	for id: String in Layout.group_ids(index):
		var actor: Act1MushroomSelenite = _source(id)
		for attempt: int in range(4):
			if actor.dead: break
			if not await _wait_live(_primary_ready, "ordinary primary naturally ready for " + id, 5.0): return false
			var point: Vector3 = actor.global_position + Vector3(0, 0, -1.0)
			if not _place_hero(point, "ordinary reach behind " + id): return false
			await process_frame; await process_frame
			if not await _wait_live(_primary_ready, "actual supported primary pose for " + id, 3.0): return false
			var direction: Vector3 = actor.global_position - game.player.global_position; direction.y = 0.0; direction = direction.normalized()
			if not _expect(_reaches(actor, direction) and not actor.dead and not actor.dormant, "real ordinary range/cone/LOS reaches original current guard: " + id): return false
			var before: float = actor.hp; var shells: int = game.player.shells; var sequence: int = _last_sequence()
			var hits: int = game.player.slash(direction)
			var actions: Array[Dictionary] = game.player.get_world_action_records(sequence)
			receipts.append({"label": "actual-primary", "source_id": id, "before_hp": before, "after_hp": actor.hp, "attempt": attempt, "hero_position": _encode(game.player.global_position), "source_position": _encode(actor.global_position), "actions": _encode(actions)})
			if not _expect(hits == 1 and actions.size() == 1 and actions[0].kind == "primary" and actions[0].origin == "player_direct" and actions[0].hits == 1 and actor.hp == maxf(0.0, before - float(game.player.equipment.resolved_stats().primary_damage)) and game.player.shells >= shells and game.player.hp == initial_hp, "actual public primary alone damages one original guard without spending blast ammo: " + id): return false
		if not _expect(actor.dead and actor.hp == 0.0 and not actor.is_in_group("enemies"), "bounded actual primary defeats original guard: " + id): return false
	return true


func _place_hero(position: Vector3, label: String) -> bool:
	if not _expect(_live(Layout.LEVEL_ID) and not paused and _primary_ready() and game.player.velocity == Vector3.ZERO, "TEST Hero placement starts at actual stable uncommitted native boundary: " + label): return false
	var point := Vector3(position.x, game.player.global_position.y, position.z)
	var measured: Dictionary = Sweep.sweep(game.player, Transform3D(game.player.global_basis, point), Vector3.ZERO, (game.active_level.call("scheduler_bindings") as Dictionary).floors.values())
	if not _expect(not measured.has("error") and not measured.get("collided", true) and measured.get("end") is Vector3 and measured.end.distance_to(point) <= Sweep.position_rounding_bound(point, point), "actual full Hero capsule/floor/scenery clearance supports TEST pose: " + label): return false
	setups.append({"kind": "TEST same-floor Hero position only; no route/gesture or native-state manufacture", "label": label, "before": _encode(game.player.global_position), "after": _encode(point)})
	game.player.global_position = point
	return true


func _preference_reopen(saved: Dictionary, future: String, label: String) -> bool:
	if not _change_preference(future) or not _expect(_same(game.capture_campaign_snapshot(), saved), "menu preference leaves complete current saved unit untouched: " + label): return false
	if not await _reopen_side(saved, label): return false
	return _expect(game.get_difficulty_preference() == future and _same(game.capture_campaign_snapshot(), saved) and _same(_host().recipes, saved.level.local.recipes) and _same(_host().admission_gate, saved.level.local.admission_gate), "independent disk Continue preserves original recipe/profile/gate despite opposite future preference: " + label)


func _change_preference(value: String) -> bool:
	if not _expect(paused, "future preference changes only at a real paused boundary"): return false
	game.menu.difficulty_preference_requested.emit(value)
	setups.append({"kind": "actual public menu future difficulty preference", "value": value})
	return _expect(game.get_difficulty_preference() == value, "public menu stores requested future preference")


func _leave(completed: bool) -> bool:
	var refs: Array[WeakRef] = _refs(game.world)
	operation = "public side Leave"; game.menu.leave_side_requested.emit()
	if not await _observe_registration("Leave restores protected Story", 1, _story_returned): return false
	return _expect(_freed(refs) and _unchanged_story(completed) and game.attempts.state().side_attempt == null and _same(game.capture_campaign_snapshot(), protected_story.snapshot) and _durable(), "normal side Leave frees donor and restores entire protected Story without main/equipment or duplicate stamp growth")


func _observe_registration(label: String, scopes: int, done: Callable) -> bool:
	var begin: int = Time.get_ticks_msec(); var signals: int = 0
	# Source-derived finite budget: load/retry/leave/checkpoint/complete=1;
	# optional or contact record+install=2; Title Replay load+record+install=3.
	if not _expect(scopes >= 1 and scopes <= 3, "finite source-derived registration scope budget"): return false
	for index: int in range(scopes * 2):
		if done.call() == true: break
		await process_frame; signals += 1
		if not _operation_healthy(): return false
	registration_barriers.append({"label": label, "maximum_scopes": scopes, "maximum_process_signals_per_scope": 2, "actual_process_signals": signals, "elapsed_ms": Time.get_ticks_msec() - begin, "scope": "observation only; full native validation cost retained, no timeout/custody mutation or performance claim"})
	return await _await_operation(done, label, 12.0)


func _pause(label: String) -> bool:
	operation = "public Pause: " + label
	var generation: int = _save_generation()
	game.request_pause()
	if not await _observe_registration(label + " native Save registration", 1, func() -> bool: return paused and game.menu.page_name() == "pause" and _save_generation() > generation): return false
	return _expect(_durable() and game.campaign_error.is_empty(), "public paused Save persists actual whole native unit: " + label)


func _valid_unit(unit: Dictionary) -> bool:
	return _closed(unit) and unit.get("level_id") == Layout.LEVEL_ID and unit.get("scene_path") == O3_PATH and unit.get("paused") == true and unit.level.get("local") is Dictionary and unit.level.get("progress") is Dictionary and RehearsalCodec.metadata_error(unit.level.local).is_empty() and RehearsalCodec.progress_error(unit.level.local, unit.level.progress).is_empty()


func _pristine(unit: Dictionary) -> bool:
	if not _valid_unit(unit): return false
	var local: Dictionary = unit.level.local
	if local.exercise_index != 0 or local.stage != "awaiting_bell" or not local.completed_exercises.is_empty() or local.checkpoint_published or not local.bell_armed or not local.recipes.is_empty() or local.scheduler.clock_s != 0.0 or not local.scheduler.profile.is_empty() or not local.scheduler.reservations.is_empty() or Codec.read_vector3(unit.player.motion.position) != Layout.SPAWN: return false
	for id: String in Layout.SOURCE_IDS:
		var actor: Dictionary = local.actors[id]
		if not actor.dormant or actor.dead or actor.hp != 24.0 or actor.cycle != 0: return false
	return true


func _prefinal(unit: Dictionary) -> bool:
	if not _valid_unit(unit): return false
	var local: Dictionary = unit.level.local
	if local.exercise_index != 2 or local.stage != "awaiting_bell" or local.completed_exercises != ["parallel", "inward"] or not local.checkpoint_published or unit.level.progress.completed or unit.level.progress.checkpoint_id != Layout.CHECKPOINT_ID or not local.scheduler.profile.is_empty(): return false
	for id: String in Layout.SOURCE_IDS:
		var actor: Dictionary = local.actors[id]; var future: bool = id in Layout.group_ids(2)
		if actor.dormant != future or actor.dead == future or actor.hp != (24.0 if future else 0.0): return false
	return true


func _ready_exit(unit: Dictionary) -> bool:
	if not _valid_unit(unit): return false
	var local: Dictionary = unit.level.local
	if local.stage != "complete" or local.completed_exercises != Layout.EXERCISE_IDS or not unit.level.progress.completed or unit.level.progress.completion_id != Layout.COMPLETION_ID or not unit.level.progress.contact_exit_id.is_empty(): return false
	for id: String in Layout.SOURCE_IDS:
		if not local.actors[id].dead or local.actors[id].hp != 0.0 or local.actors[id].dormant: return false
	return true


func _unchanged_story(completed: bool) -> bool:
	var state: Dictionary = game.attempts.state()
	return state.completed_main == PREFIX and state.completed_optional == ([Layout.LEVEL_ID] if completed else []) and state.reward_ids == ([REWARD_ID] if completed else []) and state.unlocked_equipment == unlocked_before and _same(state.story, protected_story)


func _completed_session(state: Dictionary) -> bool:
	return state.completed_main == PREFIX and state.completed_optional == [Layout.LEVEL_ID] and state.reward_ids == [REWARD_ID] and state.unlocked_equipment == unlocked_before and _same(state.story, protected_story) and state.side_attempt == null


func _story_returned() -> bool:
	return _live("A1-L4") and paused and game.attempts.active_kind() == "story" and game.menu.page_name() == "journey"


func _host() -> Dictionary:
	return game.active_level.call("rehearsal_state") if _live(Layout.LEVEL_ID) else {}


func _current_admissions(index: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var current: String = str(game.active_level.get_instance_id())
	for row: Dictionary in admission_events:
		if row.level_instance_id == current and row.source_id in Layout.group_ids(index): result.append(row)
	return result


func _events_for(level_id: String, kind: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row: Dictionary in observations:
		if row.level_instance_id == level_id and row.kind == kind: result.append(row)
	return result


func _progress_events(kind: String) -> Array[Dictionary]:
	return _events_for(str(game.active_level.get_instance_id()), kind)


func _receipt(label: String, unit: Dictionary) -> void:
	receipts.append({"label": label, "case": case_name, "profile": profile, "process_id": OS.get_process_id(), "exact_snapshot": Exact.stringify(unit), "snapshot_sha256": Exact.stringify(unit).sha256_text(), "exact_attempts": Exact.stringify(game.attempts.state()), "exact_protected_story": Exact.stringify(protected_story), "native_identities": _ids(), "saved_envelope_json": FileAccess.get_file_as_string(test_root + "campaign.json")})


func _bindings() -> bool:
	if not _live(Layout.LEVEL_ID) or game.active_level.hero != game.player or game.active_level.shared_shell != game or _count_players(game.world) != 1: return false
	var bindings: Dictionary = game.active_level.call("scheduler_bindings")
	if bindings.world_root != game.world or game.player.get_world_3d() != game.active_level.get_world_3d(): return false
	for id: String in Layout.SOURCE_IDS:
		var actor: Act1MushroomSelenite = _source(id); var native: Dictionary = actor.get_spore_native_bindings()
		if actor.get_parent() != game.active_level or actor.get_world_3d() != game.player.get_world_3d() or native.scheduler != _scheduler() or native.player != game.player or not actor.body_binding_error().is_empty() or not actor.art_binding_error().is_empty(): return false
	return true


func _ids() -> Dictionary:
	if not _live(Layout.LEVEL_ID): return {}
	var value: Dictionary = {"world": str(game.world.get_instance_id()), "native_world": str(game.world.get_world_3d().get_instance_id()), "player": str(game.player.get_instance_id()), "level": str(game.active_level.get_instance_id()), "scheduler": str(_scheduler().get_instance_id())}
	for id: String in Layout.SOURCE_IDS:
		value[id] = str(_source(id).get_instance_id()); value[id + "/cue"] = str(_source(id).get_cue().get_instance_id())
	return value


func _native_readback() -> Dictionary:
	return {"host": _host(), "player": game.player.get_threat_response_state(), "clock_s": _scheduler().get_clock(), "profile": _scheduler().encounter_profile()}


func _observe_added(node: Node) -> void:
	var ref: WeakRef = weakref(node)
	if node is CinderPlayer:
		node.fired.connect(func(kind: String) -> void: _record("fired", ref, {"kind": kind}))
		node.died.connect(func() -> void: _record("death", ref, {}))
		node.world_action_executed.connect(func(value: Dictionary) -> void: _record("world-action", ref, value))
		node.equipment_changed.connect(func(id: String) -> void: _record("equipment", ref, {"id": id}))
	if node is CinderLevel:
		node.checkpoint_requested.connect(func(id: String, checkpoint: String, kind: String) -> void: _record("checkpoint", ref, {"level_id": id, "id": checkpoint, "boundary": kind}))
		node.completion_requested.connect(func(id: String, complete: String) -> void: _record("completion", ref, {"level_id": id, "id": complete}))
		node.contact_exit_requested.connect(func(id: String, contact: String) -> void: _record("exit", ref, {"level_id": id, "id": contact}))
		if node.get_script() == RehearsalScript: node.connect("native_admission_published", func(id: String, answer: Dictionary) -> void: _notice_admission(ref, id, answer))
	if node.get_script() in [Actor, Threat, Interaction]: node.connect("state_changed", func(value: Dictionary) -> void: _record("source-or-cue-state", ref, value))
	if node.get_script() == Actor:
		node.connect("defeated", func(id: String) -> void: _record("defeated", ref, {"source_id": id}))
		node.connect("hit_resolved", func(id: String, cycle: int, result: Dictionary) -> void: _record("hit-resolved", ref, {"hero_id": id, "cycle": cycle, "result": result}))
	if node.get_script() == Scheduler: node.connect("reservation_invalidated", func(id: String, reason: String) -> void: _record("reservation-invalidated", ref, {"id": id, "reason": reason}))


func _notice_admission(ref: WeakRef, id: String, answer: Dictionary) -> void:
	var level: CinderLevel = ref.get_ref() as CinderLevel
	if level == null: return
	var states: Dictionary = {}
	for source_id: String in Layout.SOURCE_IDS: states[source_id] = (level.get("sources") as Dictionary)[source_id].call("pure_presentation_state")
	var row: Dictionary = {"level_instance_id": str(level.get_instance_id()), "source_id": id, "clock_s": (level.get("scheduler") as CinderThreatScheduler).get_clock(), "answer": answer.duplicate(true), "source_states": states, "host": level.call("rehearsal_state")}
	admission_events.append(row)
	_record("admission", ref, row)


func _seed_story(registry: CinderCampaignRegistry) -> bool:
	operation = "actual accepted L4 Main Story seed"; paused = true
	preview = MainScene.instantiate(); preview.set("level_scene_path", STORY_PATH); root.add_child(preview)
	paused = true # Main reset unpauses synchronously; re-latch before any frame.
	await process_frame; await process_frame
	var hero: CinderPlayer = preview.get("player") as CinderPlayer; var level: CinderLevel = preview.get("active_level") as CinderLevel
	if not _expect(hero != null and level != null and level.level_id == "A1-L4" and level.scene_file_path == STORY_PATH and level.contract_error().is_empty(), "accepted actual L4 Main constructs the protected native Story donor"): return false
	var anchor: Vector2 = preview.call("get_aim_anchor_normalized"); var camera: Camera3D = preview.get("camera") as Camera3D
	var snapshot: Dictionary = {"schema_version": 1, "level_id": "A1-L4", "scene_path": STORY_PATH, "paused": true, "equipment_ids": hero.equipment.snapshot(), "player": hero.snapshot_state(), "level": level.snapshot_state(), "shell": {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Vector3(0, 18, 13)), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}}
	var model: CinderCampaignAttempts = Attempts.new(registry); var payload: Dictionary = model.state()
	payload.completed_main = PREFIX.duplicate()
	payload.story = {"kind": "story", "level_id": "A1-L4", "snapshot": snapshot.duplicate(true), "checkpoint": snapshot.duplicate(true)}
	var store: CinderSaveStore = Store.new(test_root + "campaign.json"); store.payload_validator = model.saved_payload_error
	var pristine: bool = _closed(snapshot) and paused and hero.global_position == level.spawn_position() and snapshot.level.local.room == 0 and snapshot.level.local.scheduler.clock_s == 0.0 and snapshot.level.progress.checkpoint_ids.is_empty() and not snapshot.level.progress.completed
	var accepted: bool = pristine and model.state_error(payload).is_empty() and store.write_payload(payload)
	setups.append({"kind": "TEST completed-main unlock prefix; not earned route", "completed_main": PREFIX.duplicate(), "actual_story_scene": STORY_PATH, "exact_story_snapshot": Exact.stringify(snapshot)})
	var error: String = model.state_error(payload) + store.last_error; var refs: Array[WeakRef] = _refs(preview)
	level.exit_level(); preview.free(); preview = null
	return _expect(accepted and _freed(refs), "public validated Attempts/Store records actual whole L4 unit plus disclosed unlock prefix; donor normally disposed: " + error)


func _expect(ok: bool, label: String) -> bool:
	checks += 1; assertions.append({"index": checks, "passed": ok, "label": label})
	if not ok:
		failures += 1
		if first_failure.is_empty(): first_failure = {"label": label, "diagnostic": _diagnostic()}
		push_error(label)
	return ok


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > WATCHDOG_MS:
		_expect(false, "actual independent O3 campaign case watchdog reached120 wall seconds")
		_finish.call_deferred()


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true; operation = "normal final cleanup"
	var refs: Array[WeakRef] = []
	if is_instance_valid(preview):
		var level: CinderLevel = preview.get("active_level") as CinderLevel
		if level != null: level.exit_level()
		refs.append_array(_refs(preview)); preview.free(); preview = null
	if is_instance_valid(game):
		if is_instance_valid(game.active_level): game.active_level.exit_level()
		refs.append_array(_refs(game)); game.free(); game = null
	paused = false
	await create_timer(.5, true).timeout; await process_frame
	_expect((refs.is_empty() or _freed(refs)) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("environment_attack_targets").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal public level exit/Shell cleanup frees all native descendants and groups")
	if not registry_bytes.is_empty(): _expect(FileAccess.get_file_as_bytes(Registry.DATA_PATH) == registry_bytes, "every canonical Registry byte remains unchanged")
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	var exact_receipts: Array[String] = []; var exact_observations: Array[String] = []; var exact_ok: bool = true
	for row: Dictionary in receipts:
		var wire: String = Exact.stringify(_encode(row)); exact_ok = exact_ok and not wire.is_empty(); exact_receipts.append(wire)
	for row: Dictionary in observations:
		var wire: String = Exact.stringify(_encode(row)); exact_ok = exact_ok and not wire.is_empty(); exact_observations.append(wire)
	_expect(exact_ok, "every complete original receipt/observation retains exact native scalar transport")
	var output := FileAccess.open(report_path, FileAccess.WRITE)
	if output == null: _expect(false, "unique actual case report is writable")
	else:
		output.store_string(JSON.stringify({"complete": scope_complete and failures == 0, "checks": checks, "passes": checks - failures, "failures": failures, "first_failure": first_failure, "assertions": assertions, "case": case_name, "profile": profile, "elapsed_ms": Time.get_ticks_msec() - started_ms, "watchdog_ms": WATCHDOG_MS, "process_id": OS.get_process_id(), "actual_command_line": OS.get_cmdline_args(), "actual_user_arguments": OS.get_cmdline_user_args(), "report_path": ProjectSettings.globalize_path(report_path), "isolated_store_path": ProjectSettings.globalize_path(test_root + "campaign.json"), "source_reports": source_reports, "setups": setups, "receipts": receipts, "observations": observations, "exact_receipts": exact_receipts, "exact_observations": exact_observations, "operation_wait_overruns": operation_wait_overruns, "registration_barriers": registration_barriers, "scope": "One explicit independent production Shell case at540x1170; original finite C32/native scheduler and whole exact Sessions. Public menu signals, normal Save/Continue/Retry/Leave/Replay and measured TEST same-floor Hero positions/ordinary-primary producers as named by case. Original source reports/hashes preserved; installed-recipient silence and distinct identities apply only within this process. Actual native completion precedes exit contact. No earned route, OS click, touch/gesture recognition, human balance, all-loadout, full-playthrough, portrait pixel review, performance or mobile claim."}, "\t")); output.close()
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-O3 CAMPAIGN %s: complete=%s %d checks, %d failures; report=%s" % [case_name, str(scope_complete and failures == 0), checks, failures, ProjectSettings.globalize_path(report_path)])
	quit(1 if failures > 0 or not scope_complete else 0)


func _new_shell() -> bool:
	operation = "fresh actual disk Title"
	game = Shell.new() as CinderCampaignShell
	if not _expect(game.configure_runtime(raw, test_root + "campaign.json", test_root + "settings.json", test_root + "preferences.json"), "supported production Shell.configure_runtime uses only unique isolated stores"): return false
	root.add_child(game)
	if not await _await_operation(func() -> bool: return paused and game.player == null and game.active_level == null and game.menu.page_name() == "title" and not game.attempts.active_snapshot().is_empty(), "actual disk startup loads the saved model at Title without installed world", 8.0): return false
	return _expect(game.campaign_error.is_empty() and game.settings.storage_path() == test_root + "settings.json", "fresh Title validates the saved whole session using isolated settings")


func _reopen_side(saved: Dictionary, label: String) -> bool:
	var before: Dictionary = _ids()
	var disk: String = FileAccess.get_file_as_string(test_root + "campaign.json")
	var backup: String = FileAccess.get_file_as_string(test_root + "campaign.json.bak")
	var refs: Array[WeakRef] = _refs(game)
	operation = "normal donor Shell disposal: " + label
	# Public level cleanup while every native child still has its actual tree.
	game.active_level.exit_level()
	game.free(); game = null
	await process_frame
	if not _expect(_freed(refs), "normal closed donor Shell frees its native descendants before independent disk recipient: " + label): return false
	if not await _new_shell(): return false
	operation = "Title public active-side Continue: " + label
	# Title Resume Side loads the saved active side. Continue Story would leave it.
	game.menu.resume_requested.emit()
	if not await _observe_registration("public active-side Continue installs saved O3", 1, func() -> bool: return _live(Layout.LEVEL_ID) and paused and game.menu.page_name() == "resume"): return false
	var captured: Dictionary = game.capture_campaign_snapshot()
	var callbacks: Array[Dictionary] = _recipient_callbacks()
	if not _expect(_same(captured, saved) and _all_new(before, _ids()) and callbacks.is_empty() and _bindings() and _same(game.attempts.state().story, protected_story) and FileAccess.get_file_as_string(test_root + "campaign.json") == disk and FileAccess.get_file_as_string(test_root + "campaign.json.bak") == backup and _durable(), "fresh disk active Continue restores an exact distinct installed native recipient with zero recipient callbacks and unchanged saved/protected unit: " + label): return false
	receipts.append({"label": "fresh public active-side disk Continue", "case": label, "exact_snapshot": Exact.stringify(captured), "exact_attempts": Exact.stringify(game.attempts.state()), "saved_envelope_json": FileAccess.get_file_as_string(test_root + "campaign.json"), "new_installed_recipient_callbacks": callbacks, "new_identities": _ids()})
	return true


func _resume(label: String) -> bool:
	operation = "public Resume: " + label
	game.menu.resume_requested.emit()
	return _expect(not paused and _live(Layout.LEVEL_ID) and not game.player.dead, "public Resume releases actual healthy optional simulation: " + label)


func _last_sequence() -> int:
	var actions: Array[Dictionary] = game.player.get_world_action_records()
	return 0 if actions.is_empty() else int(actions.back().sequence)


func _live(id: String) -> bool:
	return is_instance_valid(game) and is_instance_valid(game.active_level) and is_instance_valid(game.player) and game.active_level.level_id == id and game.campaign_error.is_empty()


func _durable() -> bool:
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(test_root + "campaign.json"))
	if not envelope is Dictionary or envelope.get("format_version") != 2: return false
	var parsed: Dictionary = Exact.parse(String(envelope.get("payload_json", "")))
	return parsed.get("accepted", false) and _same(parsed.value, game.attempts.state())


func _save_generation() -> int:
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(test_root + "campaign.json"))
	return int(envelope.get("generation", 0)) if envelope is Dictionary else 0


func _closed(unit: Dictionary) -> bool:
	return not unit.is_empty() and unit.get("player") is Dictionary and not unit.player.is_empty() and unit.get("level") is Dictionary and not unit.level.is_empty() and not Exact.stringify(unit).is_empty()


func _same(left: Variant, right: Variant) -> bool:
	var wire: String = Exact.stringify(left)
	return not wire.is_empty() and wire == Exact.stringify(right)


func _await_operation(predicate: Callable, label: String, seconds: float) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while not finishing:
		if not _operation_healthy(): return false
		if predicate.call() == true:
			if Time.get_ticks_msec() > deadline:
				operation_wait_overruns.append({"kind": "operation", "label": label, "late_ms": Time.get_ticks_msec() - deadline, "scope": "completed synchronous operation observed after async waiting deadline; no latency/performance pass"})
			# Observe the real completed state before applying an asynchronous wait
			# deadline. Native synchronous validation cannot be interrupted by it.
			await process_frame
			return _operation_healthy() and predicate.call() == true
		if Time.get_ticks_msec() > deadline: break
		await process_frame
	return _expect(false, "bounded actual Shell operation failed: " + label)


func _wait_live(predicate: Callable, label: String, seconds: float, allow_authored_pause: bool = false) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while not finishing:
		if not _operation_healthy(): return false
		if predicate.call() == true:
			if Time.get_ticks_msec() > deadline:
				operation_wait_overruns.append({"kind": "live", "label": label, "late_ms": Time.get_ticks_msec() - deadline, "scope": "completed native observation after async waiting deadline; no latency/performance pass"})
			return true
		if not is_instance_valid(game.player) or game.player.dead: return _expect(false, "actual living shared Player lost: " + label)
		if paused and not allow_authored_pause: return _expect(false, "actual native pause interrupted live observation; no forced Resume/focus: " + label)
		if Time.get_ticks_msec() > deadline: break
		await process_frame
	return _expect(false, "bounded actual native observation failed: " + label)


func _operation_healthy() -> bool:
	if finishing: return false
	if not is_instance_valid(game): return _expect(false, "actual Shell disappeared during operation")
	if not game.campaign_error.is_empty(): return _expect(false, "first actual Shell error during " + operation + ": " + game.campaign_error)
	if is_instance_valid(game.active_level) and not game.active_level.contract_error().is_empty(): return _expect(false, "first actual native level contract error: " + game.active_level.contract_error())
	return true


func _record(kind: String, ref: WeakRef, value: Dictionary) -> void:
	var node: Node = ref.get_ref() as Node
	if node == null: return
	var level: CinderLevel = node as CinderLevel
	var ancestor: Node = node.get_parent()
	while level == null and ancestor != null:
		if ancestor is CinderLevel: level = ancestor
		ancestor = ancestor.get_parent()
	observations.append({"operation": operation, "kind": kind, "emitter_id": str(node.get_instance_id()), "level_instance_id": str(level.get_instance_id()) if level != null else "", "level_id": level.level_id if level != null else "", "inside_tree": node.is_inside_tree(), "value": _encode(value)})


func _recipient_callbacks() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var level_id: String = str(game.active_level.get_instance_id())
	var player_id: String = str(game.player.get_instance_id())
	for row: Dictionary in observations:
		if row.level_instance_id == level_id or row.emitter_id == player_id: result.append(row)
	# All validation-candidate/old-donor retirement callbacks remain separately
	# recorded in observations. Only this actual installed recipient gets credit.
	return result


func _count_players(node: Node) -> int:
	var count: int = 1 if node is CinderPlayer else 0
	for child: Node in node.get_children(): count += _count_players(child)
	return count


func _refs(node: Node) -> Array[WeakRef]:
	var result: Array[WeakRef] = [weakref(node)]
	for child: Node in node.get_children(): result.append_array(_refs(child))
	return result


func _freed(refs: Array[WeakRef]) -> bool:
	if refs.is_empty(): return false
	for ref: WeakRef in refs:
		if ref.get_ref() != null: return false
	return true


func _encode(value: Variant) -> Variant:
	if value is Vector3: return Codec.vector3(value)
	if value is Vector2: return [value.x, value.y]
	if value is Rect2: return {"native_type": "Rect2", "position": _encode(value.position), "size": _encode(value.size)}
	if value is Color: return [value.r, value.g, value.b, value.a]
	if value is Basis: return {"x": _encode(value.x), "y": _encode(value.y), "z": _encode(value.z)}
	if value is Transform3D: return {"basis": _encode(value.basis), "origin": _encode(value.origin)}
	if value is StringName: return String(value)
	if value is Object: return {"native_class": value.get_class(), "instance_id": str(value.get_instance_id())} if is_instance_valid(value) else null
	if value is int and (value < -9007199254740991 or value > 9007199254740991): return {"native_integer_decimal": str(value)}
	if value is Dictionary:
		var converted: Dictionary = {}
		for key: Variant in value: converted[String(key)] = _encode(value[key])
		return converted
	if value is Array:
		var converted: Array = []
		for child: Variant in value: converted.append(_encode(child))
		return converted
	return value


func _diagnostic() -> Dictionary:
	var value: Dictionary = {"operation": operation, "paused": paused, "elapsed_ms": Time.get_ticks_msec() - started_ms}
	if not is_instance_valid(game): return value
	value["campaign_error"] = game.campaign_error
	if game.menu != null: value["menu"] = game.menu.page_name()
	if game.attempts != null: value["active_kind"] = game.attempts.active_kind()
	if is_instance_valid(game.player): value["hero_position"] = _encode(game.player.global_position); value["hero_hp"] = game.player.hp
	if is_instance_valid(game.active_level):
		value["level_id"] = game.active_level.level_id; value["snapshot_error"] = game.active_level.last_snapshot_error; value["contract_error"] = game.active_level.contract_error()
		if game.active_level.level_id == Layout.LEVEL_ID:
			value["native_state"] = _encode(_native_readback()); value["capture_error"] = game.active_level.get("_capture_error"); value["encounter_error"] = game.active_level.get("last_encounter_error")
	return value


func _source(id: String) -> Act1MushroomSelenite:
	return (game.active_level.get("sources") as Dictionary).get(id) as Act1MushroomSelenite


func _scheduler() -> CinderThreatScheduler:
	return game.active_level.get("scheduler") as CinderThreatScheduler


func _all_new(before: Dictionary, after: Dictionary) -> bool:
	if before.is_empty() or after.is_empty(): return false
	for key: String in ["world", "native_world", "player", "level", "scheduler"]:
		if not before.has(key) or not after.has(key) or before[key] == after[key]: return false
	for key: String in after:
		if before.has(key) and before[key] == after[key]: return false
	return true


func _primary_ready() -> bool:
	if paused or not _live(Layout.LEVEL_ID) or game.player.dead: return false
	var state: Dictionary = game.player.get_threat_response_state()
	return state.stable and float(state.commitment_remaining_s) == 0.0 and float(state.primary_cooldown_left_s) == 0.0


func _distance(left: Vector3, right: Vector3) -> float:
	return Vector2(left.x - right.x, left.z - right.z).length()


func _reaches(target: Node3D, direction: Vector3) -> bool:
	var offset: Vector3 = target.global_position - game.player.global_position
	if absf(offset.y) > CinderPlayer.ATTACK_MAX_VERTICAL_DISTANCE: return false
	offset.y = 0.0
	var stats: Dictionary = game.player.equipment.resolved_stats()
	if offset.length() > float(stats.primary_range) or (offset.length() > CinderPlayer.ATTACK_ORIGIN_DISK_RADIUS and offset.normalized().dot(direction) < float(stats.primary_cone_min_dot)): return false
	var query := PhysicsRayQueryParameters3D.create(game.player.global_position + Vector3.UP * CinderPlayer.ATTACK_LOS_HEIGHT, target.global_position + Vector3.UP * CinderPlayer.ATTACK_LOS_HEIGHT, CinderPlayer.ATTACK_SCENERY_MASK)
	return game.player.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
