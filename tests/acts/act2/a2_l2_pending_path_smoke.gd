extends "res://tests/acts/act2/a2_l2_retry_level_smoke.gd"
## Shared19 authored-parent migration regression, Standard/Heavy by default.
## Reuses the frozen real primary/contact/foot/dash route only to the apron pair.
## A required active foot cue synchronously requests the PUBLIC shell pause.
## The retained path must come from actual sampled actor physics; none is forged.
## Whole player/level ExactJson, fresh staged preflight and quiet ordered restore.
## TEST ONLY preceding prefix/unlocks/initial loadout/destination are inherited.
## No live HP/ammo/transform/phase/clock/pose or earned progression assignment.
## No full clear, future-level acceptance, native art or human-balance claim.

var _pending_seen: bool = false
var _pending_previous_sample: Dictionary = {}
var _pending_observation: Dictionary = {}
var _pending_hits: Array[Dictionary] = []
var _pending_pause_on_hit: bool = false
var _pending_resume_paused: bool = false
var _pending_checkpoint: Dictionary = {}

func _run() -> void:
	if not _read_options() or not _expect(_profile_id == "standard" and not _capture_live, "pending-path fixture selects Standard actual pair without native capture"):
		quit(1)
		return
	root.size = Vector2i(540, 1170)
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	_l1_fixture_bytes = FileAccess.get_file_as_string("res://tests/acts/act2/fixtures/a2_l1_transition_destination.tscn")
	_cleanup()
	print("Weybridge pending-path scope: Standard/%s; real two primary defeats, yard checkpoint, isolated foot and actual apron dash; required active cue/public pause; complete shared19 pending2 aggregate; TEST ONLY prior prefix/unlocks" % _loadout_name)
	var failures_before: int = _failures
	if not await _pending_route() and _failures == failures_before:
		_expect(false, "actual pending-path route aborted: " + _diagnostic())
	if is_instance_valid(_fresh):
		var fresh_level: CinderLevel = _fresh.get("active_level") as CinderLevel
		if is_instance_valid(fresh_level): fresh_level.exit_level()
		_fresh.free()
		_fresh = null
	if is_instance_valid(_game):
		if is_instance_valid(_game.active_level): _game.active_level.exit_level()
		_game.free()
	_game = null
	paused = false
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical and FileAccess.get_file_as_string("res://tests/acts/act2/fixtures/a2_l1_transition_destination.tscn") == _l1_fixture_bytes, "pending fixture preserves canonical registry and existing L1 fixture bytes")
	_cleanup()
	print("Weybridge authored pending-path smoke: %d checks, %d failures; genuine active publication/public pause and exact nested migration only; no full clear/native art/future-level acceptance" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _pending_route() -> bool:
	var raw: Dictionary = JSON.parse_string(_canonical)
	for info: Dictionary in raw.levels:
		if info.id in ["A2-L2", "A2-L3"]:
			info.scene_path = LevelPath if info.id == "A2-L2" else NextPath
			info.readiness = "accepted"
			info.accepted_commit = "b".repeat(40)
			info.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty(), "isolated inherited TEST ONLY registry retains canonical links") or not await _seed(registry): return false
	_game = Shell.new() as CinderCampaignShell
	if not _expect(_game.configure_runtime(raw, TEST_ROOT + "campaign.json", TEST_ROOT + "settings.json", TEST_ROOT + "preferences.json"), "actual shell uses isolated inherited save paths"): return false
	root.add_child(_game)
	await _settle()
	_game.menu.difficulty_preference_requested.emit(_profile_id)
	_game.resume_campaign()
	await _settle()
	if not _expect(_live() and paused, "actual authored L2 installs paused: " + _game.campaign_error): return false
	var level: CinderLevel = _game.active_level
	var hero: CinderPlayer = _game.player
	_expect(hero.hp == hero.max_hp and hero.shells == 0 and hero.equipment.snapshot() == _loadout and Codec.same_values(hero.stats, _expected_stats), "actual seed starts with full normal HP, zero ammo and canonical gear/stats")
	_actors = level.get("_actors").duplicate()
	if not _expect(_actors.size() == 6 and not _contains_pickup(level), "actual authored targets contain no victory pickup"): return false
	var defeats: Array[String] = []
	var checkpoints: Array[String] = []
	var completions: Array[String] = []
	var exits: Array[String] = []
	for actor: Node in _actors.values(): actor.connect("defeated", func(id: String) -> void: defeats.append(id))
	level.checkpoint_requested.connect(func(_id: String, checkpoint: String, kind: String) -> void:
		checkpoints.append(checkpoint)
		_expect(kind == "encounter", "real contact uses the shared encounter checkpoint boundary")
	)
	level.completion_requested.connect(func(_id: String, id: String) -> void: completions.append(id))
	level.contact_exit_requested.connect(func(_id: String, id: String) -> void: exits.append(id))
	hero.world_action_executed.connect(func(record: Dictionary) -> void: _actions.append(record.duplicate(true)))
	_game.resume_campaign()
	if not await _clear(["village_scout"]) or not await _clear(["yard_handler"]) or not await _contact("yard_exit", checkpoints): return false
	await _settle()
	_pending_checkpoint = _game.attempts.state().story.checkpoint.duplicate(true)
	if not _expect(not _pending_checkpoint.is_empty() and checkpoints == [RETRY_CHECKPOINT_ID] and _pending_checkpoint.level.progress.checkpoint_id == RETRY_CHECKPOINT_ID, "first two actual kills and dry yard contact durably earn the real yard checkpoint"): return false
	_expect(defeats == ["village_scout", "yard_handler"] and _pending_checkpoint.level.local.sequence.defeated_ids == defeats and not _pending_checkpoint.level.progress.completed, "checkpoint preserves exactly the earned initial defeat prefix")
	if paused: _game.resume_campaign()
	if not await _complete_foot("foot_demo") or not await _retry_navigate_pair(): return false
	var arrival_dash: Dictionary = _last_dash()
	if not _expect(_state().beat == "apron_pair" and defeats == ["village_scout", "yard_handler"] and arrival_dash.get("kind") == "dash" and arrival_dash.get("path", []).size() >= 2 and RETRY_PAIR_REGION.has_point(Vector2(arrival_dash.landing.x, arrival_dash.landing.z)), "real HP-free foot demo and measured shared dash reach the living apron pair"): return false
	var mechanisms: Dictionary = level.get("_mechanisms")
	var foot: CinderLaneMechanism = mechanisms[RETRY_FOOT_ID] as CinderLaneMechanism
	for id: String in [RETRY_TOOL_ID, RETRY_FOOT_ID]:
		mechanisms[id].connect("hit_resolved", Callable(self, "_pending_on_hit").bind(id))
	foot.get_cue().state_changed.connect(_pending_on_active_cue)
	_pending_previous_sample = {"position": hero.global_position, "clock_s": _state().clock_s}
	for frame: int in range(600):
		if _pending_seen: break
		if not _live() or _state().beat != "apron_pair" or _state().foot_id != RETRY_FOOT_ID: break
		await _pending_tick()
		if not _pending_seen:
			_pending_previous_sample = {"position": hero.global_position, "clock_s": _state().clock_s}
	if not _expect(_pending_seen and paused and _pending_observation.get("paused_synchronously", false), "actual required active cue synchronously invokes public shell pause before outgoing foot resolution; no synthetic pending path"):
		print("Pending publication evidence: ", _state(), " observation=", _pending_observation)
		return false
	await _settle()
	if not _expect(_game.campaign_error.is_empty(), "public deferred pause captures the whole authoritative tuple: " + _game.campaign_error): return false
	var saved: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(not saved.is_empty() and saved.has_all(["player", "level", "shell"]), "whole actual player/level capture succeeds at the deferred paused barrier: " + _game.campaign_error): return false
	var retained: Dictionary = saved.level.local.mechanisms[RETRY_FOOT_ID]
	if not _expect(retained.get("schema_version") == 2 and retained.get("pending_segments") is Dictionary and not retained.pending_segments.is_empty(), "authored parent preserves genuine shared19 schema2 with a nonempty unresolved actual path"):
		print("Pending cadence evidence: source=", retained, " publication=", _pending_observation)
		return false
	if not _pending_check_tuple(saved, retained): return false
	var frozen: String = ExactJson.stringify(saved)
	var decoded: Dictionary = ExactJson.parse(frozen)
	if not _expect(not frozen.is_empty() and decoded.get("accepted", false) and decoded.get("value") is Dictionary, "ExactJson transports the complete genuine pending aggregate without downgrading/reconstruction"): return false
	var transported: Dictionary = decoded.value
	_expect(ExactJson.stringify(transported) == frozen and ExactJson.stringify(transported.level.local.mechanisms[RETRY_FOOT_ID]) == ExactJson.stringify(retained), "every complete nested schema2 field, endpoint, interval and copied deadline survives exact transport")
	var quiet: Array[String] = []
	_retry_observe(level, hero, quiet)
	var model_before: String = ExactJson.stringify(_game.attempts.state())
	await _settle()
	_expect(ExactJson.stringify(_game.capture_campaign_snapshot()) == frozen and quiet.is_empty(), "genuine shell pause freezes complete actor resources, phases, paths, scheduler and parent state")
	if not _pending_corruptions(transported, quiet): return false
	if not _retry_fresh_preflight(transported): return false
	if not _expect(hero.snapshot_error(transported.player).is_empty() and level.snapshot_error_with_player(transported.level, transported.player).is_empty(), "complete pure staged-player preflight accepts original genuine pending tuple before commit"): return false
	if not _expect(hero.restore_state(transported.player) and level.restore_state(transported.level) and String(level.get("runtime_error")).is_empty(), "actual paused player then level commit quietly restores pending history with authoritative current endpoint"): return false
	_expect(ExactJson.stringify(_game.capture_campaign_snapshot()) == frozen and quiet.is_empty() and ExactJson.stringify(_game.attempts.state()) == model_before, "quiet restore changes no actual HP/ammo/gear/input/action/progression/cooldown and emits no threat/source/opening events")
	_expect(Codec.same_values(_game.attempts.state().story.checkpoint, _pending_checkpoint), "pending restore leaves the earned yard retry checkpoint unchanged")
	return await _pending_resume(transported, defeats, checkpoints, completions, exits)

func _pending_on_active_cue(value: Dictionary) -> void:
	if _pending_seen or value.get("phase") != "active" or not is_instance_valid(_game): return
	var state: Dictionary = _state()
	if state.beat != "apron_pair" or state.foot_id != RETRY_FOOT_ID: return
	var source: Dictionary = state.mechanisms[RETRY_FOOT_ID]
	if source.status != "running" or source.phase != "active": return
	_pending_seen = true
	_pending_observation = {"previous": _pending_previous_sample.duplicate(true), "position": _game.player.global_position, "clock_s": state.clock_s, "cycle": source.cycle, "reservation_id": source.reservation_id, "hp": _game.player.hp, "foot_hits": _pending_foot_hits().size()}
	_game.request_pause()
	_pending_observation["paused_synchronously"] = paused

func _pending_on_hit(hero_id: String, cycle: int, result: Dictionary, source_id: String) -> void:
	_pending_hits.append({"source_id": source_id, "hero_id": hero_id, "cycle": cycle, "result": result.duplicate(true)})
	if source_id == RETRY_FOOT_ID and _pending_pause_on_hit and not _pending_resume_paused:
		_pending_resume_paused = true
		_game.request_pause()

func _pending_check_tuple(saved: Dictionary, retained: Dictionary) -> bool:
	var local: Dictionary = saved.level.local
	var clock: float = float(local.scheduler.clock_s)
	var path: Array = retained.pending_segments.get("hero", [])
	if not _expect(retained.pending_segments.keys() == ["hero"] and not path.is_empty() and retained.hit_ids.is_empty() and retained.status == "running" and retained.phase == "active", "pending batch names the actual stable unconsumed hero of the still-live active foot"): return false
	var first: Dictionary = path.front()
	var last: Dictionary = path.back()
	var previous: Dictionary = _pending_observation.previous
	_expect(first.from == Codec.vector3(previous.position) and float(first.start_s) == float(previous.clock_s) and float(last.end_s) > float(first.start_s), "retained path begins at the observed previous actual actor/scheduler sample and spans genuine physics")
	_expect(last.to == saved.player.motion.position and last.to == Codec.vector3(_pending_observation.position) and float(last.end_s) == clock and float(retained.hero_samples.hero.clock_s) == clock and retained.hero_samples.hero.position == last.to and float(_pending_observation.clock_s) == clock, "pending endpoint and sampled actor/player/scheduler clock preserve the exact authoritative tuple")
	_expect(retained.cycle == _pending_observation.cycle and retained.exchange.id == _pending_observation.reservation_id and saved.player.resources.hp == _pending_observation.hp and _pending_observation.foot_hits == 0 and _pending_foot_hits().is_empty(), "pause retains original live reservation/cycle without any active opportunity or same-callback HP loss")
	_expect(local.sequence.stage_index == 4 and local.sequence.defeated_ids == ["village_scout", "yard_handler"] and local.sequence.completed_feet == ["foot_demo"] and local.sequence.crossed_contacts == ["yard_exit"] and not saved.level.progress.completed and saved.equipment_ids == _loadout, "complete parent keeps earned first-two/contact/demo history and actual gear; pair remains unfinished")
	_expect(local.views[RETRY_FOOT_ID].target_id == "apron_handler" and local.mechanisms[RETRY_FOOT_ID].exchange.opening_position == local.handlers.apron_handler.root_position and local.views[RETRY_FOOT_ID].equipment_ids == saved.equipment_ids, "retained foot keeps actual low Handler opening and canonical gear witness")
	_expect(float(local.mechanisms[RETRY_TOOL_ID].clock_s) == clock and local.mechanisms[RETRY_TOOL_ID].hero_samples.hero.position == saved.player.motion.position and float(local.mechanisms[RETRY_TOOL_ID].hero_samples.hero.clock_s) == clock and float(local.rays.clock_s) == clock, "prior tool, rays, foot and parent remain in the same actual shared sampling batch")
	return _expect(_game.player.snapshot_error(saved.player).is_empty() and _game.active_level.snapshot_error_with_player(saved.level, saved.player).is_empty(), "whole saved-player staged preflight retains complete pending schema2 and exact actor/consumer clock pairing")

func _pending_corruptions(saved: Dictionary, events: Array[String]) -> bool:
	var before: String = ExactJson.stringify(_game.capture_campaign_snapshot())
	var model_before: String = ExactJson.stringify(_game.attempts.state())
	for mutation: String in ["schema", "missing", "endpoint", "clock", "consumed", "unknown"]:
		var bad: Dictionary = saved.duplicate(true)
		var source: Dictionary = bad.level.local.mechanisms[RETRY_FOOT_ID]
		match mutation:
			"schema": source.schema_version = 1
			"missing": source.erase("pending_segments")
			"endpoint": source.pending_segments.hero[-1].to[0] += 0.125
			"clock": source.pending_segments.hero[-1].end_s += 1.0 / float(Engine.physics_ticks_per_second)
			"consumed": source.hit_ids.append("hero")
			"unknown": source.pending_segments["unbound"] = source.pending_segments.hero.duplicate(true)
		var error: String = _game.active_level.snapshot_error_with_player(bad.level, bad.player)
		var refused: bool = not error.is_empty() and not _game.active_level.restore_state(bad.level) and not _game.attempts.record_snapshot(bad)
		if not _expect(refused and ExactJson.stringify(_game.capture_campaign_snapshot()) == before and ExactJson.stringify(_game.attempts.state()) == model_before and events.is_empty(), "whole parent rejects pending " + mutation + " mutation atomically without stripping its historical path"): return false
	return true

func _pending_resume(saved: Dictionary, defeats: Array[String], checkpoints: Array[String], completions: Array[String], exits: Array[String]) -> bool:
	var original: Dictionary = saved.level.local.mechanisms[RETRY_FOOT_ID]
	var hp_before: float = _game.player.hp
	var hits_before: int = _pending_hits.size()
	_pending_pause_on_hit = true
	_game.resume_campaign()
	for frame: int in range(30):
		if _pending_resume_paused: break
		if not _live(): return false
		await _pending_tick()
	if not _expect(_pending_resume_paused and paused and _pending_foot_hits().size() == 1, "actual resume resolves the retained active foot path exactly once, then hit observer uses public pause"): return false
	await _settle()
	if not _expect(_game.campaign_error.is_empty(), "post-resolution public pause durably captures the complete current tuple: " + _game.campaign_error): return false
	var drained: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(not drained.is_empty(), "whole aggregate captures after the real pending opportunity drains"): return false
	var source: Dictionary = drained.level.local.mechanisms[RETRY_FOOT_ID]
	var hit: Dictionary = _pending_foot_hits()[0]
	var hp_damage: float = 0.0
	for index: int in range(hits_before, _pending_hits.size()): hp_damage += float(_pending_hits[index].result.hp_damage)
	_expect(hit.hero_id == "hero" and hit.cycle == original.cycle and hit.result.opportunity_consumed and float(hit.result.raw_damage) == float(original.resolved_role.damage) and (not hit.result.accepted or float(hit.result.hp_damage) == _game.player.equipment.damage_received(float(original.resolved_role.damage))), "real retained opportunity uses original resolved raw damage and actual canonical armor/invulnerability")
	_expect(_game.player.hp == hp_before - hp_damage and source.hit_ids == ["hero"] and source.schema_version == 1 and not source.has("pending_segments"), "actual hit accounting consumes the original opportunity before callbacks and returns drained writer to legacy schema1")
	_expect(source.cycle == original.cycle and ExactJson.stringify(source.exchange) == ExactJson.stringify(original.exchange) and _pending_cooldown(drained.level.local.scheduler, RETRY_FOOT_ID) == _pending_cooldown(saved.level.local.scheduler, RETRY_FOOT_ID), "resume preserves exact original exchange/deadlines/cycle/source cooldown without new admission or refresh")
	_expect(drained.player.equipment == saved.player.equipment and drained.player.resources.shells == saved.player.resources.shells and Codec.same_values(_game.attempts.state().story.checkpoint, _pending_checkpoint), "real resolution changes no gear/ammo or earned retry checkpoint")
	_pending_pause_on_hit = false
	var hp_after: float = _game.player.hp
	var continued_hits_from: int = _pending_hits.size()
	_game.resume_campaign()
	for frame: int in range(16):
		if not _live(): return false
		await _pending_tick()
	_game.request_pause()
	await _settle()
	var continued: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(not continued.is_empty() and _game.campaign_error.is_empty(), "continued ordinary exposure reaches a supported public paused aggregate"): return false
	var final_source: Dictionary = continued.level.local.mechanisms[RETRY_FOOT_ID]
	_expect(_pending_foot_hits().size() == 1 and final_source.hit_ids == ["hero"] and final_source.cycle == original.cycle and final_source.schema_version == 1 and not final_source.has("pending_segments") and final_source.phase == "recovery", "continued real active exposure and recovery cannot replay the retained path or duplicate damage/opportunity")
	var continued_hp_damage: float = 0.0
	for index: int in range(continued_hits_from, _pending_hits.size()): continued_hp_damage += float(_pending_hits[index].result.hp_damage)
	_expect(_game.player.hp == hp_after - continued_hp_damage and ExactJson.stringify(final_source.exchange) == ExactJson.stringify(original.exchange) and _pending_cooldown(continued.level.local.scheduler, RETRY_FOOT_ID) == _pending_cooldown(saved.level.local.scheduler, RETRY_FOOT_ID), "continued HP accounts only for actual paired-source results, with no repeated foot hit or original deadline/cooldown refresh")
	return _expect(defeats == ["village_scout", "yard_handler"] and checkpoints == [RETRY_CHECKPOINT_ID] and completions.is_empty() and exits.is_empty() and continued.level.local.sequence.stage_index == 4 and not continued.level.progress.completed, "scoped pending migration never fabricates additional kills/contact/progression or full completion")

func _pending_foot_hits() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for hit: Dictionary in _pending_hits:
		if hit.source_id == RETRY_FOOT_ID: result.append(hit.duplicate(true))
	return result

func _pending_cooldown(scheduler: Dictionary, source_id: String) -> Dictionary:
	for value: Dictionary in scheduler.cooldowns:
		if value.source_id == source_id: return value.duplicate(true)
	return {}

func _pending_tick() -> void:
	# Unlike inherited live navigation, deliberately never auto-resume an
	# alive shell overlay: this observer's public pause is the test barrier.
	await physics_frame
	await process_frame

func _retry_observe(level: CinderLevel, hero: CinderPlayer, events: Array[String]) -> void:
	super._retry_observe(level, hero, events)
	for mechanism: CinderLaneMechanism in level.get("_mechanisms").values():
		mechanism.get_cue().state_changed.connect(func(_state: Dictionary) -> void: events.append("required-threat-cue"))
