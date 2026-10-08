extends "res://tests/acts/act2/a2_l3_full_transport_smoke.gd"
## Focused actual running road-bank transport. Reuses initial full transport's
## native unit refs, filtered quiet observers, release and ExactJson helpers.
## Two real ground dashes earn continuous smoke contact and delivered damage.
## No live HP/ammo/transform/target/phase/progression or Scheduler-clock writes.
## Original unit resumes its real cycle before release; distinct fresh Main
## restores the saved active Player/whole level quietly and stays paused.
## No full route, checkpoint, Shell input/camera, portrait or art acceptance.

const SmokeBank: Script = preload("res://scripts/combat/smoke_bank.gd")
const Codec: Script = preload("res://scripts/campaign/snapshot_codec.gd")
var _actions: Array[Dictionary] = []
var _phases: Dictionary = {}
var _first_receipt: Dictionary = {}
var _first_pause_requested: bool = false
var _recovery_pause_requested: bool = false
var _resumed_receipts: Array[Dictionary] = []

func _run() -> void:
	root.size = Vector2i(540, 1170)
	_game = Main.instantiate()
	_game.set("level_scene_path", "res://scenes/acts/act2/a2_l3.tscn")
	root.add_child(_game)
	_game.call("resume_lab")
	await _settle(15)
	var level := _game.get("active_level") as CinderLevel
	var hero := _game.get("player") as CinderPlayer
	if not _expect(is_instance_valid(level) and is_instance_valid(hero) and level.level_id == "A2-L3" and String(level.get("runtime_error")).is_empty(), "actual shared Main constructs authored L3 running-bank unit"):
		await _finish(); return
	var bank: Node3D = level.get("_clouds").road_bank as Node3D
	if not _expect(is_instance_valid(bank) and bank.get_script() == SmokeBank and hero.hp == 100.0 and hero.equipment.snapshot() == {"weapon": "WEAPON-01", "jacket": "CLOTH-J0", "pants": "CLOTH-P0", "shoes": "CLOTH-S0"}, "actual original standard Hero/bank start with canonical baseline gear and full health"):
		await _finish(); return
	hero.world_action_executed.connect(func(record: Dictionary) -> void: _actions.append(record.duplicate(true)))
	bank.connect("state_changed", func(state: Dictionary) -> void:
		if state.status == "running": _phases[state.phase] = true
	)
	bank.connect("tick_resolved", _pause_after_first_damage)
	if not await _dash(hero, Vector3.FORWARD) or not await _dash(hero, Vector3.FORWARD):
		await _finish(); return
	var position: Vector3 = hero.global_position
	var radius: float = float(bank.call("state").geometry.radius) + 0.32
	_expect(hero.is_on_floor() and Vector2(position.x - bank.global_position.x, position.z - bank.global_position.z).length() < radius and _actions.size() == 2 and _actions[0].kind == "dash" and _actions[1].kind == "dash", "two public completed ground dashes actually land inside the native road-bank contact disc")
	for frame: int in range(600):
		if paused and not _game.call("is_pause_requested"): break
		if not _healthy(level, hero) or bank.call("state").status == "cancelled": break
		await _native_step()
	if not _expect(paused and not _game.call("is_pause_requested") and _first_pause_requested and _first_receipt.get("accepted", false) and _first_receipt.get("hp_damage") == 2.0, "actual first2HP delivery requests and reaches the complete native deferred pause"):
		print("Running bank first-contact failure: hero=", hero.global_position, " hp=", hero.hp, " bank=", bank.call("state"), " root=", level.call("encounter_state"))
		await _finish(); return
	_expect(_phases.has_all(["warning", "lock", "active"]) and _first_receipt.index == 1 and hero.hp == 98.0, "actual native warning/lock/active and first delivered2HP receipt precede capture")
	var indicator: Node3D = bank.call("get_grace_indicator") as Node3D
	var points: Array = bank.call("get_required_camera_points")
	_expect(indicator.get_node("GraceBackground").is_visible_in_tree() and indicator.global_position == hero.global_position + Vector3.UP * 2.75 and points.size() == 9, "earned native grace bar is exactly2.75m above actual Hero and supplies all9 current camera points")
	_expect(String(_game.call("camera_framing_error", points)).is_empty(), "actual current camera fits native road-bank rim/source/grace and complete Hero bounds")
	var player: Dictionary = hero.snapshot_state()
	_whole = level.snapshot_state()
	if not _expect(not player.is_empty() and not _whole.is_empty() and hero.snapshot_error(player).is_empty() and level.snapshot_error_with_player(_whole, player).is_empty(), "public complete Player/whole CinderLevel capture preflights at the actual active barrier"):
		print("Running bank capture errors: player=", hero.last_snapshot_error, " level=", level.last_snapshot_error, " runtime=", level.get("runtime_error"))
		await _finish(); return
	var saved_bank: Dictionary = _whole.local.banks.road_bank
	_expect(saved_bank.status == "running" and saved_bank.phase == "active" and saved_bank.receipts.size() == 1 and saved_bank.receipts[0].stage == "done" and saved_bank.pending_stage.is_empty() and saved_bank.processed_count == saved_bank.trace.size(), "complete native pause retains delivered receipt and fully processed actual history without invented pending work")
	_expect(saved_bank.sample.position == player.motion.position and saved_bank.sample.actor_clock_s == player.world_actions.clock_s and saved_bank.sample.clock_s == _whole.local.scheduler.clock_s and saved_bank.contact_since_s >= saved_bank.exchange.active_from_s and saved_bank.trace.size() > 1, "actual current Player endpoints/clocks and earned continuous-contact history match the active bank")
	_expect(_whole.local.bank_views.has("road_bank") and _whole.local.bank_views.road_bank.reservation_id == saved_bank.exchange.id and saved_bank.configuration.contact == SmokeBank.DEFAULT_CONTACT and saved_bank.resolved_role.damage == 2.0, "actual original native lease/framing view and published contact budget remain paired")
	var whole_encoded: String = Exact.stringify(_whole)
	var player_encoded: String = Exact.stringify(player)
	var whole_decoded: Dictionary = Exact.parse(whole_encoded)
	var player_decoded: Dictionary = Exact.parse(player_encoded)
	if not _expect(not whole_encoded.is_empty() and not player_encoded.is_empty() and whole_decoded.get("accepted", false) and player_decoded.get("accepted", false) and Exact.stringify(whole_decoded.value) == whole_encoded and Exact.stringify(player_decoded.value) == player_encoded, "ExactJson preserves complete real active Player/level/trace/grace/receipt bits and types"):
		await _finish(); return
	var saved_level: Dictionary = whole_decoded.value
	var saved_player: Dictionary = player_decoded.value
	_expect(level.snapshot_error_with_player(saved_level, saved_player).is_empty(), "decoded complete active pair validates without decimal-clock tolerance")
	var events: Array[String] = []
	_observe_quiet(level, hero, events)
	var variants: Array[Dictionary] = _bank_corruptions(saved_level)
	for variant: Dictionary in variants:
		_expect(not level.snapshot_error_with_player(variant.state, saved_player).is_empty() and not level.restore_state(variant.state), "public staged preflight/restore reject malformed active bank: " + variant.label)
		_expect(Exact.stringify(level.snapshot_state()) == whole_encoded and Exact.stringify(hero.snapshot_state()) == player_encoded and events.is_empty(), "active bank refusal is atomic for actual whole level/Player/events: " + variant.label)
	# Continue the original correctly framed Main unit. A blocked opportunity
	# still consumes its index; preserved hurt invulnerability is not a refill.
	bank.connect("tick_resolved", func(_id: String, cycle: int, result: Dictionary) -> void:
		_resumed_receipts.append({"cycle": cycle, "result": result.duplicate(true)})
	)
	bank.connect("state_changed", func(state: Dictionary) -> void:
		if state.status == "running" and state.phase == "recovery" and state.cycle == saved_bank.cycle and not _recovery_pause_requested:
			_recovery_pause_requested = true
			_expect(_game.call("request_pause_deferred"), "original recovery publication requests its complete native pause")
	)
	_game.call("resume_lab")
	for frame: int in range(360):
		if paused and not _game.call("is_pause_requested"): break
		if not _healthy(level, hero) or bank.call("state").status == "cancelled": break
		await _native_step()
	if not _expect(paused and _recovery_pause_requested and not _game.call("is_pause_requested") and bank.call("state").phase == "recovery", "original active cycle advances naturally into its original recovery without a refreshed start"):
		print("Running bank continuation failure: ", bank.call("state"), " root=", level.call("encounter_state"))
		await _finish(); return
	var continued: Dictionary = level.snapshot_state()
	if not _expect(not continued.is_empty(), "actual resumed recovery still supplies a coherent complete CinderLevel transport"):
		await _finish(); return
	var continued_bank: Dictionary = continued.local.banks.road_bank
	_expect(continued_bank.cycle == saved_bank.cycle and Exact.stringify(continued_bank.exchange) == Exact.stringify(saved_bank.exchange) and continued_bank.clock_s > saved_bank.clock_s and continued_bank.last_cancel_reason.is_empty(), "actual continuation retains original cycle/source/geometry/deadlines/cooldown and advances only native clocks")
	_expect(Exact.stringify(continued_bank.trace.slice(0, saved_bank.trace.size())) == Exact.stringify(saved_bank.trace) and Exact.stringify(continued_bank.receipts.slice(0, saved_bank.receipts.size())) == Exact.stringify(saved_bank.receipts), "resuming preserves the exact already processed trace and delivered receipt prefix")
	_expect(continued_bank.trace.size() > saved_bank.trace.size() and continued_bank.trace[saved_bank.trace.size()].start_s == saved_bank.trace[-1].end_s, "first continued real tick joins the original trace without replaying a native interval")
	_expect(continued_bank.receipts.size() == SmokeBank.DEFAULT_CONTACT.max_opportunities and _resumed_receipts.size() == continued_bank.receipts.size() - saved_bank.receipts.size(), "same actual contact consumes its bounded five opportunities without duplicating delivered receipt1")
	var delivered_damage: float = 0.0
	var index: int = saved_bank.receipts.size() + 1
	for delivered: Dictionary in _resumed_receipts:
		_expect(delivered.cycle == saved_bank.cycle and delivered.result.index == index and delivered.result.consumed_s > saved_bank.receipts[-1].consumed_s, "actual resumed notification has only its new original-cycle receipt index: " + str(index))
		delivered_damage += float(delivered.result.hp_damage)
		index += 1
	if continued_bank.receipts.size() > 1:
		_expect(continued_bank.receipts[1].eligible_s == maxf(float(saved_bank.contact_since_s) + float(SmokeBank.DEFAULT_CONTACT.grace_s), float(saved_bank.receipts[-1].consumed_s) + float(SmokeBank.DEFAULT_CONTACT.tick_s)), "next opportunity retains its original grace/receipt spacing rather than restarting exposure")
	_expect(hero.hp == float(saved_player.resources.hp) - delivered_damage and _actions.size() == 2 and not level.is_completed() and level.current_checkpoint().id.is_empty() and continued.local.sequence.stage_index == 0, "continuation grants no heal/input/target defeat/checkpoint/clear and never replays first damage")
	var original_refs: Array[Dictionary] = _unit_refs(level, hero)
	await _release()
	_expect(_refs_freed(original_refs) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "original Main/Player/seven targets/banks/tools/scenery/cues release before fresh receiving unit")
	_game = Main.instantiate()
	_game.set("level_scene_path", "res://scenes/acts/act2/a2_l3.tscn")
	root.add_child(_game)
	_game.call("resume_lab")
	await _settle(15)
	var fresh_level := _game.get("active_level") as CinderLevel
	var fresh_hero := _game.get("player") as CinderPlayer
	if not _expect(is_instance_valid(fresh_level) and is_instance_valid(fresh_hero) and fresh_level.hero == fresh_hero and String(fresh_level.get("runtime_error")).is_empty(), "separate actual Main builds fresh native receiving bindings"):
		await _finish(); return
	_expect(_game.call("request_pause_deferred"), "fresh receiver uses supported full-native-tick pause")
	for ignored: int in range(3): await process_frame
	if not _expect(paused and not _game.call("is_pause_requested"), "fresh receiver reaches its own quiet native barrier"):
		await _finish(); return
	var fresh_events: Array[String] = []
	_observe_quiet(fresh_level, fresh_hero, fresh_events)
	var fresh_before: String = Exact.stringify(fresh_level.snapshot_state())
	var fresh_player_before: String = Exact.stringify(fresh_hero.snapshot_state())
	var original_ids: Dictionary = {}
	for item: Dictionary in original_refs: original_ids[item.instance_id] = true
	var distinct: bool = true
	for node: Node in _unit_nodes(fresh_level, fresh_hero): distinct = distinct and not original_ids.has(node.get_instance_id())
	_expect(distinct and fresh_hero.global_position != Codec.read_vector3(saved_player.motion.position), "fresh Player/bank/source/scenery/cue bindings are genuinely distinct and its default feet differ")
	_expect(fresh_hero.snapshot_error(saved_player).is_empty(), "fresh shared Player public preflight accepts the complete original damaged actor")
	_expect(not fresh_level.snapshot_error(saved_level).is_empty() and not fresh_level.restore_state(saved_level), "running bank rejects default fresh Hero sample before its actual saved Player is committed")
	var staged: String = fresh_level.snapshot_error_with_player(saved_level, saved_player)
	_expect(staged.is_empty(), "public whole-level preflight accepts staged original Player against fresh bindings before any actor commit: " + staged)
	_expect(Exact.stringify(fresh_level.snapshot_state()) == fresh_before and Exact.stringify(fresh_hero.snapshot_state()) == fresh_player_before and fresh_events.is_empty(), "default refusal and staged acceptance remain pure for every fresh native binding/resource/event")
	for variant: Dictionary in variants:
		_expect(not fresh_level.snapshot_error_with_player(variant.state, saved_player).is_empty(), "fresh staged full pair rejects the same actual-bank corruption before mutation: " + variant.label)
	_expect(Exact.stringify(fresh_level.snapshot_state()) == fresh_before and Exact.stringify(fresh_hero.snapshot_state()) == fresh_player_before and fresh_events.is_empty(), "all fresh malformed pair preflights preserve initial actual receiver atomically")
	# The actual complete Player commits first. No yield/admission/damage is
	# permitted between this public restore and complete CinderLevel restore.
	if not _expect(fresh_hero.restore_state(saved_player) and fresh_level.restore_state(saved_level), "public quiet Player then CinderLevel restores the complete original active bank pack"):
		print("Fresh running restore errors: player=", fresh_hero.last_snapshot_error, " level=", fresh_level.last_snapshot_error, " runtime=", fresh_level.get("runtime_error"))
		await _finish(); return
	_expect(Exact.stringify(fresh_hero.snapshot_state()) == player_encoded and Exact.stringify(fresh_level.snapshot_state()) == whole_encoded and fresh_events.is_empty(), "distinct fresh native whole level/Player reconstruct exactly with no phase/tick/hit/input/checkpoint/resource events")
	var fresh_bank: Node3D = fresh_level.get("_clouds").road_bank as Node3D
	var fresh_bank_saved: Dictionary = fresh_level.snapshot_state().local.banks.road_bank
	_expect(Exact.stringify(fresh_bank_saved) == Exact.stringify(saved_bank) and fresh_bank.call("state").opportunities_consumed == 1 and fresh_bank_saved.pending_stage == saved_bank.pending_stage and fresh_bank_saved.trace.size() - fresh_bank_saved.processed_count == saved_bank.trace.size() - saved_bank.processed_count, "quiet fresh restore retains exact original deadlines/grace/trace/delivered receipt and conditional pending count")
	_expect(fresh_hero.hp == 98.0 and fresh_hero.get_world_action_records().size() == 2 and not fresh_level.is_completed() and fresh_level.current_checkpoint().id.is_empty() and paused, "fresh active bank restoration publishes no heal/movement/damage/progression and remains paused")
	_expect(fresh_level.restore_state(saved_level) and Exact.stringify(fresh_level.snapshot_state()) == whole_encoded and Exact.stringify(fresh_hero.snapshot_state()) == player_encoded and fresh_events.is_empty(), "repeated public quiet whole restore does not refresh clocks/grace/deadlines or replay the delivered notification")
	var fresh_refs: Array[Dictionary] = _unit_refs(fresh_level, fresh_hero)
	await _release()
	_expect(_refs_freed(fresh_refs) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "fresh whole native receiving unit also releases all owned targets/banks/art/cues")
	print("A2-L3 running bank transport: %d checks, %d failures; genuine road-bank contact/damage/deferred barrier/original continuation/fresh quiet full restore only; no route/Shell-camera/native-art acceptance" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _pause_after_first_damage(_id: String, _cycle: int, result: Dictionary) -> void:
	if _first_pause_requested or not result.get("accepted", false): return
	_first_receipt = result.duplicate(true)
	_first_pause_requested = true
	_expect(_game.call("request_pause_deferred"), "real smoke tick callback requests supported deferred full native pause")

func _bank_corruptions(saved: Dictionary) -> Array[Dictionary]:
	var variants: Array[Dictionary] = []
	var changed: Dictionary = saved.duplicate(true)
	changed.local.banks.road_bank.clock_s += 0.000000001
	variants.append({"label": "copied bank/Scheduler clock drift", "state": changed})
	changed = saved.duplicate(true); changed.local.bank_views.erase("road_bank")
	variants.append({"label": "missing original running bank framing view", "state": changed})
	changed = saved.duplicate(true); changed.local.banks.road_bank.contact_since_s -= 1.0 / float(Engine.physics_ticks_per_second)
	variants.append({"label": "fabricated earlier continuous exposure", "state": changed})
	changed = saved.duplicate(true); changed.local.banks.road_bank.receipts.clear()
	variants.append({"label": "forgotten already delivered native opportunity", "state": changed})
	changed = saved.duplicate(true); changed.local.banks.road_bank.receipts[0].eligible_s += 1.0 / float(Engine.physics_ticks_per_second)
	variants.append({"label": "changed original receipt eligibility", "state": changed})
	changed = saved.duplicate(true); changed.local.banks.road_bank.trace[-1].to[0] += 0.01
	variants.append({"label": "latest retained native endpoint disagrees with actual saved Player", "state": changed})
	changed = saved.duplicate(true); changed.local.banks.road_bank.pending_stage = "notification"
	variants.append({"label": "invented pending delivery after completed native tick", "state": changed})
	changed = saved.duplicate(true); changed.local.banks.road_bank.exchange.active_until_s += 1.0 / float(Engine.physics_ticks_per_second)
	variants.append({"label": "refreshed immutable active deadline", "state": changed})
	return variants

func _dash(hero: CinderPlayer, direction: Vector3) -> bool:
	var ready: bool = false
	for frame: int in range(180):
		var response: Dictionary = hero.get_threat_response_state()
		if not paused and not hero.dead and response.stable and float(response.dash_cooldown_left_s) <= 0.00001:
			ready = true; break
		await _native_step()
	if not _expect(ready, "real dash waits shared stable ground response/cooldown"): return false
	var before: int = _actions.size()
	if not _expect(hero.request_dash(direction), "actual shared Hero accepts ordinary forward ground dash"): return false
	for frame: int in range(180):
		if _actions.size() > before:
			var action: Dictionary = _actions.back()
			return _expect(action.kind == "dash" and action.path.size() >= 2 and action.landing.is_finite() and hero.is_on_floor(), "actual completed ground dash retains native sampled path/landing")
		if hero.dead or paused: break
		await _native_step()
	return _expect(false, "actual shared ground dash did not complete")

func _healthy(level: CinderLevel, hero: CinderPlayer) -> bool:
	return is_instance_valid(level) and is_instance_valid(hero) and not hero.dead and String(level.get("runtime_error")).is_empty()

func _native_step() -> void:
	await physics_frame
	await process_frame

func _refs_freed(refs: Array[Dictionary]) -> bool:
	for item: Dictionary in refs:
		if item.reference.get_ref() != null: return false
	return true

func _finish() -> void:
	await _release()
	print("A2-L3 running bank transport aborted: %d checks, %d failures" % [_checks, _failures])
	quit(1)
