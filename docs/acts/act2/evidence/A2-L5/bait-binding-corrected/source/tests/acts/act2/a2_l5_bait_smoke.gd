extends SceneTree
## TEST ONLY controller/API fixture for B05's completed physical bait cache.
## Uses native Player, actual static floor/wall and public dash/primary requests.
## No gesture recognizer, screen aim, camera, ray, combat, whole L5 or art credit.
## Spawn and static geometry are authored before entering the native tree; live
## Player position, clocks, resources, equipment and phases are never assigned.

const PlayerScript: GDScript = preload("res://scripts/player.gd")
const BaitScript: GDScript = preload("res://scripts/acts/act2/dead_london_bait.gd")
const Codec: GDScript = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson: GDScript = preload("res://scripts/campaign/exact_json.gd")
const MAX_TICKS: int = 180
var _checks: int = 0
var _failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if "--binding-only" in OS.get_cmdline_user_args():
		await _native_binding_checks()
	elif "--nested-only" in OS.get_cmdline_user_args():
		await _nested_publication_checks()
	else:
		await _completed_and_boundary_checks()
		await _wall_checks()
		await _pending_pause_checks()
		await _cancel_release_checks()
		if "--base-only" not in OS.get_cmdline_user_args():
			await _nested_publication_checks()
	paused = false
	print("A2-L5 bait controller smoke: %d checks, %d failures; controller/API only, no ray, recognizer, camera, combat, whole-level or art credit" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _native_binding_checks() -> void:
	var fixture: Dictionary = _fixture(false)
	var hero: CinderPlayer = fixture.hero
	var bait: Variant = fixture.bait
	var other: CinderPlayer = PlayerScript.new()
	other.name = "TEST_ONLY_DistinctNativePlayer"
	other.position = Vector3(4, 0.02, 0)
	fixture.arena.add_child(other)
	var unbound: Variant = BaitScript.new()
	_expect(not unbound.is_bound_to(hero) and not unbound.is_bound_to(other) and not unbound.is_bound_to(null), "unbound cache grants no native identity")
	if not _expect(await _wait_ready(hero) and await _wait_ready(other), "two distinct real Players settle on native dry floor"):
		unbound.release()
		await _dispose(fixture)
		return
	_expect(bait.is_bound_to(hero) and not bait.is_bound_to(other) and not bait.is_bound_to(null) and bait.sample_for_ray().is_empty() and _same(bait.state(), {"version": 1, "boundary": "", "initial_floor": null, "initial_sequence": 0, "last_sequence": 0, "landing": null, "last_dash": null}), "actual binding identifies only its native Hero without initializing bait")
	_expect(unbound.bind(other) and unbound.is_bound_to(other) and not unbound.is_bound_to(hero), "second cache retains distinct actual Hero identity in the same World3D")
	_expect(bait.begin_boundary("sentry-entry") and unbound.begin_boundary("sentry-entry"), "both boundaries use their respective actual supported floor")
	paused = true
	var before: Dictionary = {"hero": hero.snapshot_state(), "other": other.snapshot_state(), "bait": bait.state(), "other_bait": unbound.state()}
	var diagnostic: String = bait.last_error
	_expect(not before.hero.is_empty() and not before.other.is_empty(), "both complete native Players are captured at actual paused barrier")
	_expect(bait.is_bound_to(hero) and unbound.is_bound_to(other) and not bait.is_bound_to(other), "paused identity keeps the exact native bijection")
	var after: Dictionary = {"hero": hero.snapshot_state(), "other": other.snapshot_state(), "bait": bait.state(), "other_bait": unbound.state()}
	_expect(_same(before, after) and bait.last_error == diagnostic and fixture.events.is_empty(), "custody reads mutate neither actual Player/cache/diagnostic nor publish callbacks")
	bait.release()
	_expect(not bait.is_bound_to(hero) and not bait.is_bound_to(other) and not bait.bind(hero), "permanent cache retirement closes actual identity and rebinding")
	_expect(unbound.is_bound_to(other), "one cache retirement leaves the other actual binding intact")
	paused = false
	var retired: WeakRef = weakref(other)
	other.queue_free()
	_expect(not unbound.is_bound_to(other), "a queued native recipient immediately loses binding authority")
	await process_frame
	await process_frame
	_expect(retired.get_ref() == null and not unbound.is_bound_to(null) and unbound.state().is_empty(), "freed native recipient cannot retain bait authority")
	unbound.release()
	await _dispose(fixture)
	_expect(not bait.is_bound_to(null) and not unbound.is_bound_to(null), "complete fixture cleanup leaves both caches disarmed")

func _completed_and_boundary_checks() -> void:
	var fixture: Dictionary = _fixture(false)
	var hero: CinderPlayer = fixture.hero
	var bait: Variant = fixture.bait
	if not _expect(await _wait_ready(hero), "entry settles on actual supported native floor"):
		await _dispose(fixture)
		return
	_expect(not bait.begin_boundary("sentry-phase-2"), "phase two cannot precede actual sentry entry")
	_expect(bait.begin_boundary("sentry-entry"), "actual stable supported entry seeds one floor point")
	var initial: Dictionary = bait.state()
	_expect(initial.initial_sequence == 0 and initial.last_sequence == 0 and initial.last_dash == null and _same(initial.landing, Codec.vector3(_floor_point(hero.global_position))), "initial bait uses actual supported X/Z and no invented completed receipt")
	_expect(not hero.request_dash(Vector3.ZERO) and _same(bait.state(), initial) and hero.get_world_action_records().is_empty(), "rejected zero dash changes neither native history nor bait")
	_expect(hero.request_dash(Vector3.RIGHT), "first actual dash is accepted")
	_expect(hero.get_committed_dash_state().active and hero.get_world_action_records().is_empty() and _same(bait.state(), initial), "accepted but unfinished dash cannot retarget bait")
	_expect(not bait.begin_boundary("sentry-phase-2") and _same(bait.state(), initial), "moving native Player cannot reset a boundary")
	_expect(not hero.request_dash(Vector3.BACK) and _same(bait.state(), initial), "buffered request is not completed bait")
	if not _expect(await _wait_count(hero, 1), "bounded native ticks complete first dash"):
		await _dispose(fixture)
		return
	var records: Array[Dictionary] = hero.get_world_action_records()
	var first: Dictionary = records[0].duplicate(true)
	var first_sample: Dictionary = bait.sample_for_ray()
	var held_sample: Dictionary = first_sample.duplicate(true)
	_expect(first_sample.last_sequence == 1 and first_sample.dash_sequence == 1 and first_sample.point == _floor_point(first.landing), "first sample retains actual completed landing and cursor")
	_expect(_native_path_valid(first) and not first.blocked and not first.collision_shortened, "unblocked completion retains actual native path and travel result")
	if not _expect(await _wait_count(hero, 2) and await _wait_ready(hero), "public buffered dash completes once through original native cadence"):
		await _dispose(fixture)
		return
	records = hero.get_world_action_records()
	var second: Dictionary = records[1].duplicate(true)
	_expect(records.size() == 2 and fixture.events.size() == 2 and fixture.accepted == [true, true], "owner signal consumes both genuine contiguous completions exactly once")
	_expect(second.direction == Vector3.BACK and second.sequence == 2 and _native_path_valid(second), "buffered completion is its own truthful world-action receipt")
	_expect(bait.sample_for_ray().point == _floor_point(second.landing) and bait.state().last_sequence == 2, "later completed movement updates current bait")
	_expect(first_sample == held_sample and first_sample.point != bait.sample_for_ray().point, "later dash cannot mutate an earlier sampled cycle copy")
	var before_copy: Dictionary = bait.state()
	first_sample["point"] = Vector3(999, 0, 999)
	var caller_state: Dictionary = bait.state()
	caller_state.last_dash.path[0].position[0] = 999.0
	_expect(_same(bait.state(), before_copy), "sample and nested state accessors cannot mutate retained bait")
	var publication_count: int = hero.get_world_action_records().size()
	hero.slash(Vector3.FORWARD)
	_expect(hero.get_world_action_records().size() == publication_count + 1 and hero.get_world_action_records()[-1].kind == "primary", "actual immediate primary publishes a genuine nonmovement receipt")
	_expect(bait.state().last_sequence == 3 and bait.sample_for_ray().dash_sequence == 2 and _same(bait.state().landing, before_copy.landing), "primary advances contiguous cursor without replacing physical dash bait")
	hero.slash(Vector3.LEFT)
	_expect(hero.get_world_action_records().size() == 3 and bait.state().last_sequence == 3, "cooldown-rejected primary produces no receipt or bait change")
	var before_observe: Dictionary = bait.state()
	_expect(bait.observe_record(second) and _same(bait.state(), before_observe), "genuine already-consumed notification succeeds without cache mutation")
	var forged: Dictionary = second.duplicate(true)
	forged["sequence"] = 4
	forged["landing"] = Vector3(500, 0, 500)
	_expect(not bait.observe_record(forged) and _same(bait.state(), before_observe), "fabricated future event absent from bound native history is rejected")
	if not _expect(await _wait_ready(hero), "native primary commitment finishes before paused transport"):
		await _dispose(fixture)
		return
	paused = true
	var pack: Dictionary = {"player": hero.snapshot_state(), "bait": bait.state()}
	if not _expect(not pack.player.is_empty() and hero.snapshot_error(pack.player).is_empty() and bait.snapshot_error(pack.bait, pack.player).is_empty(), "completed bait cross-validates against the complete paused native Player"):
		await _dispose(fixture)
		return
	var wire: String = ExactJson.stringify(pack)
	var decoded: Dictionary = ExactJson.parse(wire)
	if not _expect(not wire.is_empty() and decoded.get("accepted", false) and ExactJson.stringify(decoded.value) == wire, "completed Player plus cached bait round-trips exact JSON"):
		paused = false
		await _dispose(fixture)
		return
	var transported: Dictionary = decoded.value
	var bad: Dictionary = transported.bait.duplicate(true)
	bad["extra"] = true
	_atomic_refusal(bait, hero, bad, transported.player, "closed bait envelope rejects an extra key")
	bad = transported.bait.duplicate(true)
	bad["version"] = 2
	_atomic_refusal(bait, hero, bad, transported.player, "unsupported bait version rejects atomically")
	bad = transported.bait.duplicate(true)
	bad["boundary"] = "invented-boundary"
	_atomic_refusal(bait, hero, bad, transported.player, "foreign boundary rejects atomically")
	bad = transported.bait.duplicate(true)
	bad["last_sequence"] = int(transported.player.world_actions.sequence) + 1
	_atomic_refusal(bait, hero, bad, transported.player, "future bait publication cursor rejects atomically")
	bad = transported.bait.duplicate(true)
	bad.initial_floor[0] = NAN
	_atomic_refusal(bait, hero, bad, transported.player, "nonfinite authored point rejects atomically")
	bad = transported.bait.duplicate(true)
	bad.landing[0] = float(bad.landing[0]) + 0.125
	_atomic_refusal(bait, hero, bad, transported.player, "landing different from the completed receipt rejects atomically")
	bad = transported.bait.duplicate(true)
	bad["last_dash"] = PlayerScript.encode_world_action_record(first, float(transported.player.world_actions.clock_s))
	bad["landing"] = Codec.vector3(_floor_point(first.landing))
	_expect(PlayerScript.world_action_record_error(bad.last_dash, float(transported.player.world_actions.clock_s)).is_empty(), "mismatched earlier dash remains an independently canonical valid receipt")
	_atomic_refusal(bait, hero, bad, transported.player, "valid but older receipt cannot replace the latest retained completed dash")
	bad = transported.bait.duplicate(true)
	bad["last_dash"] = null
	bad["landing"] = bad.initial_floor.duplicate(true)
	_atomic_refusal(bait, hero, bad, transported.player, "initial point cannot erase a native completed dash")
	var receiver: Dictionary = _fixture(false)
	var received_hero: CinderPlayer = receiver.hero
	var received_bait: Variant = receiver.bait
	var quiet: Array[String] = _watch(received_hero)
	_expect(received_hero.snapshot_error(transported.player).is_empty() and received_bait.snapshot_error(transported.bait, transported.player).is_empty(), "fresh recipient preflights complete staged Player independently of current pose/history")
	var before_received_player: Dictionary = received_hero.snapshot_state()
	var before_received_bait: Dictionary = received_bait.state()
	_expect(not received_bait.restore_state(transported.bait, transported.player) and _same(received_hero.snapshot_state(), before_received_player) and _same(received_bait.state(), before_received_bait) and quiet.is_empty(), "prospective completed bait refuses before actual native Player restore atomically")
	_expect(received_hero.restore_state(transported.player) and received_bait.restore_state(transported.bait, transported.player), "fresh restore commits native Player before quiet bait cache")
	_expect(_same(received_hero.snapshot_state(), transported.player) and _same(received_bait.state(), transported.bait) and quiet.is_empty(), "fresh completed restoration preserves exact Player/cursor/receipt without events")
	transported.bait.last_dash.path[0].position[0] = -999.0
	_expect(_same(received_bait.state(), pack.bait), "restoration owns a deep copy of the accepted encoded receipt")
	paused = false
	await _dispose(receiver)
	_expect(await _wait_ready(hero) and bait.begin_boundary("sentry-phase-2"), "actual stable phase-two boundary resets at current supported floor")
	var reset: Dictionary = bait.state()
	_expect(reset.boundary == "sentry-phase-2" and reset.initial_sequence == 3 and reset.last_sequence == 3 and reset.last_dash == null and _same(reset.initial_floor, Codec.vector3(_floor_point(hero.global_position))) and _same(reset.landing, reset.initial_floor), "reset preserves actual completed cursor and clears prior-boundary dash bait")
	_expect(not bait.begin_boundary("sentry-phase-2") and _same(bait.state(), reset), "authored phase-two boundary advances only once")
	_expect(await _wait_dash_ready(hero) and hero.request_dash(Vector3.LEFT) and await _wait_count(hero, 4), "new boundary admits a fresh actual completed dash")
	_expect(bait.sample_for_ray().boundary == "sentry-phase-2" and bait.sample_for_ray().dash_sequence == 4 and fixture.accepted == [true, true, true, true], "new epoch consumes genuine contiguous events without replaying the old dash")
	# Deliberately hold one genuine event outside the owner callback to exercise
	# native identity validation at the correct next sequence, not just malformed
	# or duplicate-cursor rejection. No action or cache state is fabricated.
	hero.world_action_executed.disconnect(fixture.callback)
	_expect(await _wait_dash_ready(hero) and hero.request_dash(Vector3.FORWARD) and await _wait_count(hero, 5), "actual native history retains next completion before manual public consumption")
	if hero.get_world_action_records().size() == 5:
		var actual: Dictionary = hero.get_world_action_records()[-1]
		var changed: Dictionary = actual.duplicate(true)
		var shift: Vector3 = Vector3(0.5, 0, -0.25)
		changed["world_origin"] = (changed.world_origin as Vector3) + shift
		changed["landing"] = (changed.landing as Vector3) + shift
		for sample: Dictionary in changed.path:
			sample["position"] = (sample.position as Vector3) + shift
		_expect(not PlayerScript.encode_world_action_record(changed, hero.get_world_action_clock()).is_empty(), "translated next receipt is independently canonical before identity rejection")
		var unchanged: Dictionary = bait.state()
		_expect(not bait.observe_record(changed) and _same(bait.state(), unchanged), "canonical altered next receipt cannot substitute for bound native history")
		_expect(bait.observe_record(actual) and bait.state().last_sequence == 5 and bait.sample_for_ray().point == _floor_point(actual.landing), "unchanged genuine retained next event remains consumable after refusal")
	hero.world_action_executed.connect(fixture.callback)
	await _dispose(fixture)

func _wall_checks() -> void:
	var fixture: Dictionary = _fixture(true)
	var hero: CinderPlayer = fixture.hero
	var bait: Variant = fixture.bait
	if not _expect(await _wait_ready(hero) and bait.begin_boundary("sentry-entry"), "wall fixture seeds actual supported entry"):
		await _dispose(fixture)
		return
	_expect(hero.request_dash(Vector3.RIGHT) and await _wait_count(hero, 1), "actual native wall dash completes")
	var records: Array[Dictionary] = hero.get_world_action_records()
	if records.size() != 1:
		await _dispose(fixture)
		return
	var shortened: Dictionary = records[0]
	_expect(shortened.blocked and shortened.collision_shortened and float(shortened.distance) > 0.5 and float(shortened.distance) < 1.3 and _native_path_valid(shortened), "native wall produces truthful collision shortening and path")
	_expect(bait.sample_for_ray().point == _floor_point(shortened.landing) and bait.sample_for_ray().point.x < 1.1 and absf(bait.sample_for_ray().point.x - (shortened.world_origin.x + float(shortened.resolved_stats.dash_distance))) > 1.0, "bait follows completed collision endpoint instead of nominal travel or aim release")
	_expect(await _wait_dash_ready(hero) and hero.request_dash(Vector3.RIGHT) and await _wait_count(hero, 2), "second dash really completes against the blocking wall")
	records = hero.get_world_action_records()
	if records.size() == 2:
		var blocked: Dictionary = records[1]
		_expect(blocked.blocked and blocked.collision_shortened and float(blocked.distance) < 0.01 and _native_path_valid(blocked), "fully blocked native completion still has a truthful receipt")
		_expect(bait.state().last_sequence == 2 and bait.sample_for_ray().dash_sequence == 2 and bait.sample_for_ray().point == _floor_point(blocked.landing) and fixture.accepted == [true, true], "even near-zero completed travel replaces bait with its actual physical landing")
	await _dispose(fixture)

func _pending_pause_checks() -> void:
	var donor: Dictionary = _fixture(false)
	var hero: CinderPlayer = donor.hero
	var bait: Variant = donor.bait
	if not _expect(await _wait_ready(hero) and bait.begin_boundary("sentry-entry") and hero.request_dash(Vector3.FORWARD), "pending transport begins actual native movement"):
		await _dispose(donor)
		return
	if not _expect(await _pause_after_measured_tick(hero), "pause follows an actual measured native tick before completion"):
		await _dispose(donor)
		return
	_expect(hero.get_committed_dash_state().active and hero.get_world_action_records().is_empty(), "pause is taken before actual dash completion")
	var pending: Dictionary = {"player": hero.snapshot_state(), "bait": bait.state()}
	if not _expect(not pending.player.is_empty() and not pending.player.world_actions.pending_dash.is_empty() and pending.player.world_actions.history.is_empty() and pending.bait.last_dash == null, "genuine paused capture retains native unfinished path without invented bait"):
		await _dispose(donor)
		return
	var paused_position: Vector3 = hero.global_position
	var paused_clock: float = hero.get_world_action_clock()
	for _index: int in range(4):
		await process_frame
	_expect(hero.global_position == paused_position and hero.get_world_action_clock() == paused_clock and _same(hero.snapshot_state(), pending.player) and _same(bait.state(), pending.bait), "paused process frames freeze exact movement, clock, pending path and bait")
	var pending_wire: String = ExactJson.stringify(pending)
	var decoded: Dictionary = ExactJson.parse(pending_wire)
	if not _expect(not pending_wire.is_empty() and decoded.get("accepted", false) and ExactJson.stringify(decoded.value) == pending_wire, "pending native Player and initial bait round-trip exact JSON"):
		paused = false
		await _dispose(donor)
		return
	var staged: Dictionary = decoded.value
	var receiver: Dictionary = _fixture(false)
	var next_hero: CinderPlayer = receiver.hero
	var next_bait: Variant = receiver.bait
	var quiet: Array[String] = _watch(next_hero)
	_expect(next_hero.snapshot_error(staged.player).is_empty() and next_bait.snapshot_error(staged.bait, staged.player).is_empty(), "fresh pending recipient purely validates the complete staged native tuple")
	var before_next_player: Dictionary = next_hero.snapshot_state()
	var before_next_bait: Dictionary = next_bait.state()
	_expect(not next_bait.restore_state(staged.bait, staged.player) and _same(next_hero.snapshot_state(), before_next_player) and _same(next_bait.state(), before_next_bait) and quiet.is_empty(), "prospective pending bait refuses before actual native Player restore atomically")
	_expect(next_hero.restore_state(staged.player) and next_bait.restore_state(staged.bait, staged.player), "fresh pending restore follows Player then bait order")
	_expect(_same(next_hero.snapshot_state(), staged.player) and _same(next_bait.state(), staged.bait) and quiet.is_empty(), "pending restore is exact and emits no action, equipment, damage or death event")
	var donor_node: Node3D = donor.arena
	var donor_weak: WeakRef = weakref(donor_node)
	bait.release()
	hero.world_action_executed.disconnect(donor.callback)
	donor_node.queue_free()
	await process_frame
	await process_frame
	_expect(donor_weak.get_ref() == null, "retired original pending native world is freed before resumed continuation")
	paused = false
	_expect(await _wait_count(next_hero, 1) and await _wait_ready(next_hero), "restored native unfinished movement completes through real physics once")
	var records: Array[Dictionary] = next_hero.get_world_action_records()
	_expect(records.size() == 1 and receiver.accepted == [true] and quiet == ["world_action"], "resume publishes exactly one genuine completion and no restore replay")
	if records.size() == 1:
		_expect(_native_path_valid(records[0]) and records[0].world_origin == Codec.read_vector3(staged.player.world_actions.pending_dash.world_origin) and records[0].started_at_s == staged.player.world_actions.pending_dash.started_at_s, "completion retains original pre-pause path origin and simulation interval")
		_expect(next_bait.sample_for_ray().point == _floor_point(records[0].landing) and next_bait.state().last_sequence == 1, "bait changes only after restored pending movement really completes")
	var completed_before: int = records.size()
	for _index: int in range(24):
		await _step()
	_expect(next_hero.get_world_action_records().size() == completed_before and receiver.events.size() == 1, "continued native ticks cannot republish the completed movement")
	await _dispose(receiver)

func _cancel_release_checks() -> void:
	var fixture: Dictionary = _fixture(false)
	var hero: CinderPlayer = fixture.hero
	var bait: Variant = fixture.bait
	if not _expect(await _wait_ready(hero) and bait.begin_boundary("sentry-entry") and hero.request_dash(Vector3.RIGHT) and await _wait_count(hero, 1) and await _wait_dash_ready(hero), "cancel fixture first earns actual completed dash bait"):
		await _dispose(fixture)
		return
	var before: Dictionary = bait.state()
	var from: Vector3 = hero.global_position
	_expect(hero.request_dash(Vector3.FORWARD), "next actual movement starts before public capture cancellation")
	if not _expect(await _pause_after_measured_tick(hero), "cancel fixture pauses after actual measured native movement"):
		await _dispose(fixture)
		return
	_expect(hero.get_committed_dash_state().active, "cancel acts on an actual unfinished native capture")
	hero.cancel_world_action_capture()
	var canceled_player: Dictionary = hero.snapshot_state()
	if not _expect(not canceled_player.is_empty() and canceled_player.world_actions.pending_dash.is_empty() and hero.get_committed_dash_state().active and _same(bait.state(), before), "public cancellation drops unfinished recording without changing motion or completed bait"):
		await _dispose(fixture)
		return
	_expect(hero.snapshot_error(canceled_player).is_empty() and bait.snapshot_error(before, canceled_player).is_empty(), "genuine paused canceled-capture tuple remains natively valid")
	var wire: String = ExactJson.stringify({"player": canceled_player, "bait": before})
	var decoded: Dictionary = ExactJson.parse(wire)
	_expect(not wire.is_empty() and decoded.get("accepted", false) and ExactJson.stringify(decoded.value) == wire, "canceled unfinished capture transports without inventing a completion")
	var position: Vector3 = hero.global_position
	var clock: float = hero.get_world_action_clock()
	for _index: int in range(4):
		await process_frame
	_expect(hero.global_position == position and hero.get_world_action_clock() == clock and _same(bait.state(), before), "genuine pause freezes canceled movement and prior bait")
	paused = false
	_expect(await _wait_ready(hero), "canceled recording still permits original native dash to finish")
	_expect(Vector2(hero.global_position.x - from.x, hero.global_position.z - from.z).length() > 2.6 and hero.get_world_action_records().size() == 1 and _same(bait.state(), before), "capture cancellation changes neither actual travel nor prior completed cursor/landing")
	_expect(bait.begin_boundary("sentry-phase-2"), "stable boundary after canceled movement uses actual supported current floor")
	var reset: Dictionary = bait.state()
	_expect(_same(reset.landing, Codec.vector3(_floor_point(hero.global_position))) and not _same(reset.landing, before.landing) and reset.last_dash == null and reset.initial_sequence == 1, "new boundary may truthfully differ from prior completed bait after canceled capture")
	paused = true
	var valid_player: Dictionary = hero.snapshot_state()
	_expect(hero.snapshot_error(valid_player).is_empty() and bait.snapshot_error(reset, valid_player).is_empty(), "post-cancellation reset preflights with complete native Player")
	bait.release()
	_expect(bait.state().is_empty() and bait.sample_for_ray().is_empty() and not bait.bind(hero) and not bait.begin_boundary("sentry-entry") and not bait.restore_state(reset, valid_player) and not bait.observe_record(hero.get_world_action_records()[0]), "release permanently removes binding and all bait authority")
	paused = false
	_expect(await _wait_dash_ready(hero) and hero.request_dash(Vector3.LEFT) and await _wait_count(hero, 2), "released cache does not alter real Player controller continuation")
	_expect(fixture.accepted == [true, false] and bait.state().is_empty(), "owner callback after disarm cannot resurrect authority from a later genuine event")
	await _dispose(fixture)

func _fixture(with_wall: bool) -> Dictionary:
	var arena: Node3D = Node3D.new()
	arena.name = "TEST_ONLY_BaitWorld"
	_world_box(arena, "DryFloor", Vector3(0, -0.5, 0), Vector3(40, 1, 40))
	if with_wall:
		_world_box(arena, "ShorteningWall", Vector3(1.5, 1, 0), Vector3(0.3, 2, 4))
	root.add_child(arena)
	var hero: CinderPlayer = PlayerScript.new()
	hero.name = "TEST_ONLY_NativePlayer"
	hero.position = Vector3(0, 0.02, 0)
	arena.add_child(hero)
	var bait: Variant = BaitScript.new()
	_expect(bait.bind(hero), "cache binds once to actual ready native Player")
	var events: Array[Dictionary] = []
	var accepted: Array[bool] = []
	var fixture: Dictionary = {"arena": arena, "hero": hero, "bait": bait, "events": events, "accepted": accepted}
	var callback: Callable = func(record: Dictionary) -> void:
		accepted.append(bait.observe_record(record))
		events.append(record.duplicate(true))
	fixture["callback"] = callback
	hero.world_action_executed.connect(callback)
	return fixture

func _watch(hero: CinderPlayer) -> Array[String]:
	var events: Array[String] = []
	hero.world_action_executed.connect(func(_record: Dictionary) -> void: events.append("world_action"))
	hero.fired.connect(func(_kind: String) -> void: events.append("fired"))
	hero.action_resolved.connect(func(_kind: String, _hits: int, _damage: float) -> void: events.append("action"))
	hero.equipment_changed.connect(func(_id: String) -> void: events.append("equipment"))
	hero.died.connect(func() -> void: events.append("death"))
	return events

func _atomic_refusal(bait: Variant, hero: CinderPlayer, rejected: Dictionary, saved_player: Dictionary, description: String) -> void:
	var before_bait: Dictionary = bait.state()
	var before_player: Dictionary = hero.snapshot_state()
	_expect(not bait.snapshot_error(rejected, saved_player).is_empty(), description + " preflight")
	_expect(not bait.restore_state(rejected, saved_player) and _same(bait.state(), before_bait) and _same(hero.snapshot_state(), before_player), description + " leaves both cache and native Player unchanged")

func _wait_count(hero: CinderPlayer, count: int) -> bool:
	for _index: int in range(MAX_TICKS):
		if hero.get_world_action_records().size() >= count:
			return hero.get_world_action_records().size() == count
		await _step()
	return false

func _wait_ready(hero: CinderPlayer) -> bool:
	for _index: int in range(MAX_TICKS):
		var response: Dictionary = hero.get_threat_response_state()
		if response.stable and response.motion.grounded and not hero.action_in_progress():
			return true
		await _step()
	return false

func _wait_dash_ready(hero: CinderPlayer) -> bool:
	for _index: int in range(MAX_TICKS):
		var response: Dictionary = hero.get_threat_response_state()
		if response.stable and response.motion.grounded and not hero.action_in_progress() and float(response.dash_cooldown_left_s) == 0.0:
			return true
		await _step()
	return false

func _pause_after_measured_tick(hero: CinderPlayer) -> bool:
	var initial_clock: float = hero.get_world_action_clock()
	var initial_count: int = hero.get_world_action_records().size()
	for _index: int in range(MAX_TICKS):
		await _step()
		if not hero.get_committed_dash_state().active or hero.get_world_action_records().size() != initial_count:
			return false
		if hero.get_world_action_clock() > initial_clock:
			# External frame barrier: the originating Player transaction is over.
			paused = true
			return true
	return false

func _step() -> void:
	await physics_frame
	await process_frame

func _dispose(fixture: Dictionary) -> void:
	paused = false
	var hero: CinderPlayer = fixture.hero
	var bait: Variant = fixture.bait
	bait.release()
	if is_instance_valid(hero) and hero.world_action_executed.is_connected(fixture.callback):
		hero.world_action_executed.disconnect(fixture.callback)
	var arena: Node3D = fixture.arena
	var retired: WeakRef = weakref(arena)
	arena.queue_free()
	await process_frame
	await process_frame
	_expect(retired.get_ref() == null, "fixture owner disconnects and frees its complete native world")

func _world_box(parent: Node3D, node_name: String, at: Vector3, size: Vector3) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = at
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "Shape"
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)

func _native_path_valid(record: Dictionary) -> bool:
	var samples: Array = record.path
	if samples.size() < 2 or samples[0].position != record.world_origin or samples[-1].position != record.landing or samples[0].time_s != record.started_at_s or samples[-1].time_s != record.completed_at_s:
		return false
	var previous: float = float(record.started_at_s)
	for sample: Dictionary in samples:
		if not sample.position is Vector3 or not (sample.position as Vector3).is_finite() or not is_finite(float(sample.time_s)) or float(sample.time_s) < previous:
			return false
		previous = float(sample.time_s)
	return not PlayerScript.encode_world_action_record(record, float(record.completed_at_s)).is_empty()

func _floor_point(point: Vector3) -> Vector3:
	return Vector3(point.x, 0.0, point.z)

func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = ExactJson.stringify(left)
	return not encoded.is_empty() and encoded == ExactJson.stringify(right)

func _expect(condition: bool, description: String) -> bool:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
	return condition

# TEST ONLY insertion fragment for a2_l5_bait_smoke.gd.
# Add `await _nested_publication_checks()` to _run(). Uses existing native floor,
# bounded wait helpers, public requests and disposal; no live state assignments.
# Separately replace the old duplicate assertion at line 74 with:
# _expect(bait.observe_record(second) and _same(bait.state(), before_observe),
#     "genuine already-consumed notification succeeds without cache mutation")
# Changed Boolean contract only: forged/altered/gapped inputs still reject.

func _nested_publication_checks() -> void:
	var fixture: Dictionary = _fixture(false)
	var hero: CinderPlayer = fixture.hero
	var bait: Variant = fixture.bait
	if not _expect(await _wait_ready(hero) and bait.begin_boundary("sentry-entry"), "nested publication starts at actual supported stable entry"):
		await _dispose(fixture)
		return
	# Connect a real observer ahead of the existing cache callback. Its only
	# action is one public immediate primary during the first completed dash.
	hero.world_action_executed.disconnect(fixture.callback)
	var audit: Dictionary = {"calls": 0, "observed": [], "after_nested": {}}
	var earlier: Callable = func(record: Dictionary) -> void:
		audit.observed.append(int(record.sequence))
		if record.kind == "dash" and int(record.sequence) == 1 and int(audit.calls) == 0:
			audit.calls = int(audit.calls) + 1
			hero.slash(Vector3.FORWARD)
			# Primary 2 has returned through the cache; outer dash 1 has not.
			audit.after_nested = bait.state()
	hero.world_action_executed.connect(earlier)
	hero.world_action_executed.connect(fixture.callback)
	if not _expect(hero.request_dash(Vector3.RIGHT) and await _wait_count(hero, 2) and await _wait_ready(hero), "real first dash and nested public primary complete through native callbacks"):
		hero.world_action_executed.disconnect(earlier)
		await _dispose(fixture)
		return
	var records: Array[Dictionary] = hero.get_world_action_records()
	_expect(records.size() == 2 and records[0].sequence == 1 and records[0].kind == "dash" and records[1].sequence == 2 and records[1].kind == "primary" and _native_path_valid(records[0]), "native retained publication is dash 1 then primary 2")
	_expect(int(audit.calls) == 1 and audit.observed == [1, 2] and fixture.events.size() == 2 and fixture.events[0].sequence == 2 and fixture.events[1].sequence == 1, "earlier observer publishes once and actual cache delivery is primary 2 before dash 1")
	_expect(fixture.accepted == [true, true], "nested drain and outer genuine notification both succeed")
	_expect(bait.state().last_sequence == 2 and bait.sample_for_ray().dash_sequence == 1 and bait.sample_for_ray().point == _floor_point(records[0].landing), "nested drain consumes native publication order and retains only real dash landing")
	_expect(_same(audit.after_nested, bait.state()), "outer already-consumed dash notification makes no duplicate cache update")
	var first_sample: Dictionary = bait.sample_for_ray()
	var held_sample: Dictionary = first_sample.duplicate(true)
	if not _expect(await _wait_dash_ready(hero) and hero.request_dash(Vector3.FORWARD) and await _wait_count(hero, 3) and await _wait_ready(hero), "second public dash actually completes after native cooldown"):
		hero.world_action_executed.disconnect(earlier)
		await _dispose(fixture)
		return
	records = hero.get_world_action_records()
	_expect(records.size() == 3 and records[0].sequence == 1 and records[0].kind == "dash" and records[1].sequence == 2 and records[1].kind == "primary" and records[2].sequence == 3 and records[2].kind == "dash" and _native_path_valid(records[2]), "retained native history remains genuine dash 1, primary 2, dash 3")
	_expect(int(audit.calls) == 1 and audit.observed == [1, 2, 3] and fixture.events.size() == 3 and fixture.events[0].sequence == 2 and fixture.events[1].sequence == 1 and fixture.events[2].sequence == 3 and fixture.accepted == [true, true, true], "later genuine completion remains consumable without repeating the nested primary")
	_expect(bait.state().last_sequence == 3 and bait.state().last_dash.sequence == 3 and bait.sample_for_ray().dash_sequence == 3 and bait.sample_for_ray().point == _floor_point(records[2].landing), "final bait advances to the second actual completed physical landing")
	_expect(first_sample == held_sample and first_sample.point == _floor_point(records[0].landing) and first_sample.point != bait.sample_for_ray().point, "later native completion cannot mutate an earlier sampled cycle copy")
	var before_ack: Dictionary = bait.state()
	_expect(bait.observe_record(records[0]) and bait.observe_record(records[1]) and bait.observe_record(records[2]) and _same(bait.state(), before_ack) and hero.get_world_action_records() == records, "genuine consumed notifications are idempotent with no cache or native-history mutation")
	print("NESTED BAIT native publication=[dash 1, primary 2, dash 3]; cache delivery=[2, 1, 3]; accepted=", fixture.accepted, "; final cache cursor=", bait.state().last_sequence, "; final dash=", bait.sample_for_ray().dash_sequence)
	hero.world_action_executed.disconnect(earlier)
	await _dispose(fixture)
