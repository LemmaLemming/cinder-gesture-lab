extends SceneTree
## Real actor/capture/sequence and exclusive scheduler leases. Controlled clock
## edge cases are labelled transport tests; ordinary delivery uses physics ticks.

const Player = preload("res://scripts/player.gd")
const Capture = preload("res://scripts/combat/action_capture.gd")
const Sequence = preload("res://scripts/combat/replay_sequence.gd")
const Playback = preload("res://scripts/combat/replay_playback.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const SaveStore = preload("res://scripts/campaign/save_store.gd")
const EPOCH: String = "replay/playback"
class ResumeTick:
	extends Node
	var delivery: Callable
	var done: bool = false
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 200
	func _physics_process(_delta: float) -> void:
		set_physics_process(false)
		delivery.call()
		done = true
		get_tree().paused = true

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _actual_one()
	await _actual_two_blast()
	await _wall_and_geometry()
	await _invulnerable()
	await _grace_and_cancellation()
	await _paired_restore()
	await _callback_boundaries()
	await _held_phase_restore()
	await _pending_fresh_restore()
	await _pending_expiry()
	await _freed_preview_child()
	await _pending_live_authority()
	print("Replay playback smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _actual_one() -> void:
	var arena: Dictionary = await _arena()
	var recorded: Dictionary = await _record(arena, 1)
	var installed: Dictionary = _install(arena, recorded)
	if installed.is_empty():
		await _dispose(arena)
		return
	var playback = installed.playback
	var preview: Dictionary = playback.preview_state()
	var slot: Dictionary = installed.native.timeline.slots[0]
	_expect(preview.slots[0].route == slot.route and preview.slots[0].events[0].record == slot.events[0].record and not preview.movement_damage and not preview.portrait_visibility_proved, "preview retains all exact ordered absolute samples and original instantaneous cone data without a visibility claim")
	_expect(playback.get_apparition().presentation_id == "act3_traveller" and _collider_count(playback) == 0, "apparition uses shared act3 cosmetic artwork and has no physical collider")
	var copy: Dictionary = playback.preview_state()
	copy.slots[0].events[0].record.damage = 999
	_expect(playback.preview_state().slots[0].events[0].record.damage == slot.events[0].record.damage, "native preview is a defensive nested copy")
	_expect(playback.state().cursor.next_event_index == 0 and not playback.get_apparition().visible, "unarmed warning is harmless and has no moving ghost")
	await _lock(arena, installed)
	_expect(playback.state().cursor.armed and playback.state().cursor.phase == "lock", "consumer arms only from the real freshly committed full-lead lease")
	var start: float = float(installed.lease.adapter.timeline_origin_s) + float(slot.from_s)
	await _until(arena.scheduler, start + (float(slot.dash_until_s) - float(slot.from_s)) * 0.5)
	var before_hp: float = arena.player.hp
	var before_shells: int = arena.player.shells
	var before_history: Array[Dictionary] = arena.player.get_world_action_records()
	var travel: Dictionary = playback.advance()
	_expect(travel.accepted and travel.events.is_empty() and playback.get_apparition().visible and arena.player.hp == before_hp, "actual scheduler-driven dash playback is harmless even with the live hero on its path")
	if not travel.accepted or playback.state().cursor.poses.is_empty():
		await _dispose(arena)
		return
	_expect(playback.get_apparition_root().global_position == playback.state().cursor.poses[0].position and playback.global_position == installed.source_position and playback.get_apparition().position == Vector3(0, 0.025, 0), "only the nonblocking render root follows the exact original world route while shared sprite feet offset and lease source stay fixed")
	var record: Dictionary = slot.events[0].record
	arena.player.global_position = record.world_origin + record.direction * 0.4
	var nested: Array[Dictionary] = []
	var prefix_seen: Array[int] = []
	var callback_barriers: Array[String] = []
	var damage_nested: Array[Dictionary] = []
	arena.player.fired.connect(func(kind: String) -> void:
		if kind == "hurt":
			damage_nested.append(playback.advance())
	)
	playback.event_dispatched.connect(func(_event: Dictionary, _opportunity: Dictionary) -> void:
		prefix_seen.append(playback.state().cursor.next_event_index)
		nested.append(playback.advance())
		paused = true
		callback_barriers.append(playback.snapshot_error({}, arena.scheduler, {}, _bindings(arena, playback), {"hero": arena.player}))
		paused = false
	)
	await _until(arena.scheduler, float(installed.lease.adapter.timeline_origin_s) + float(slot.events[0].at_s))
	var delivery: Dictionary = playback.advance()
	_expect(delivery.accepted and delivery.events.size() == 1 and arena.player.hp == before_hp - float(record.damage), "real ordinary-primary replay resolves its canonical damage once against a live body")
	_expect(prefix_seen == [1] and nested.size() == 1 and not nested[0].accepted and playback.advance().events.is_empty(), "prefix and opportunity commit before nested callbacks and equal-clock calls cannot duplicate damage")
	_expect(damage_nested.size() == 1 and not damage_nested[0].accepted, "actual take_damage callback cannot nest a second delivery before the outer event signal")
	_expect(callback_barriers.size() == 1 and callback_barriers[0].contains("deferred barrier"), "even paused callback capture rejects until the explicit deferred transaction barrier")
	_expect(arena.player.shells == before_shells and arena.player.get_world_action_records() == before_history, "replay consumes no blast ammo and publishes no player action/capture recursion")
	_expect(playback.state().opportunities.size() == 1 and playback.state().opportunities[0].contact and playback.state().opportunities[0].damage_attempted, "contact opportunity is retained before the damage callback")
	_expect(playback.get_apparition_root().global_position == record.world_origin and playback.get_apparition().position == Vector3(0, 0.025, 0) and playback.get_apparition().weapon_visual_id == record.equipment_ids.weapon, "attack source uses original world origin and static weapon while preserving the common cosmetic feet pivot")
	await _until(arena.scheduler, float(installed.lease.adapter.timeline_origin_s) + float(slot.events[0].at_s) + 0.20)
	playback.advance()
	_expect(playback.state().cursor.poses[0].action == "idle" and playback.state().visual_pose.action == "primary" and playback.state().visual_pose.visual_duration_s == float(record.cooldown_s) * (0.28 / 0.30), "cosmetic shared slow slash continues beyond logical commitment without another damage event")
	paused = true
	await process_frame
	var bindings: Dictionary = _bindings(arena, playback)
	var schedule: Dictionary = arena.scheduler.snapshot_state(bindings)
	var snapshot: Dictionary = playback.snapshot_state(schedule, bindings)
	_expect(not snapshot.is_empty(), "paused actor/scheduler/playback boundary yields a strict paired snapshot: " + playback.last_snapshot_error)
	var clock: float = arena.scheduler.get_clock()
	await create_timer(0.1, true).timeout
	_expect(arena.scheduler.get_clock() == clock and playback.snapshot_state(schedule, bindings) == snapshot and not playback.advance().accepted, "wall time under pause advances neither scheduler, cursor, opportunity nor damage")
	paused = false
	await _until(arena.scheduler, float(installed.lease.recovery_until_s) + 0.02)
	_expect(playback.advance().accepted and playback.state().status == "complete" and not playback.get_apparition().visible, "full recovery ends without another ghost or attack")
	await _ticks(3)
	playback.advance()
	paused = true
	await process_frame
	schedule = arena.scheduler.snapshot_state(bindings)
	var terminal: Dictionary = playback.snapshot_state(schedule, bindings)
	_expect(not terminal.is_empty() and terminal.status == "complete" and terminal.cursor.last_advanced_clock_s == schedule.clock_s and terminal.cursor.next_event_index == 1, "retained completed owner follows later aggregate clocks without redelivery and remains snapshot coherent")
	await _dispose(arena)


func _actual_two_blast() -> void:
	var arena: Dictionary = await _arena()
	var recorded: Dictionary = await _record(arena, 2, true)
	var installed: Dictionary = _install(arena, recorded)
	if installed.is_empty():
		await _dispose(arena)
		return
	var playback = installed.playback
	await _lock(arena, installed)
	var first: Dictionary = installed.native.timeline.slots[0]
	var second: Dictionary = installed.native.timeline.slots[1]
	var origin: float = installed.lease.adapter.timeline_origin_s
	var primary: Dictionary = first.events[0].record
	var blast: Dictionary = first.events[1].record
	_expect(primary.direction == Vector3.RIGHT and blast.direction == Vector3.LEFT and first.events.size() == 2, "fixture contains an actual independently aimed optional blast rather than a derived slash aim")
	arena.player.global_position = blast.world_origin + Vector3.LEFT * 0.6
	var hp: float = arena.player.hp
	var nested: Array[Dictionary] = []
	var prefix_seen: Array[int] = []
	playback.event_dispatched.connect(func(_event: Dictionary, _opportunity: Dictionary) -> void:
		prefix_seen.append(playback.state().cursor.next_event_index)
		nested.append(playback.advance())
	)
	await _until(arena.scheduler, origin + float(first.events[0].at_s))
	var result: Dictionary = playback.advance()
	_expect(result.events.size() == 2 and prefix_seen == [2, 2] and playback.state().opportunities.size() == 2, "equal-time actual primary/blast batch latches the complete two-event prefix before either callback")
	_expect(arena.player.hp == hp - float(blast.damage) and not playback.state().opportunities[0].contact and playback.state().opportunities[1].contact, "live geometry uses each independent recorded cone; missed primary and contacted blast both consume opportunities")
	_expect(nested.size() == 2 and not nested[0].accepted and not nested[1].accepted and playback.advance().events.is_empty(), "nested callbacks cannot replay either event from an already latched batch")
	var gap_clock: float = origin + (float(first.end_s) + float(second.from_s)) * 0.5
	await _until(arena.scheduler, gap_clock)
	var gap: Dictionary = playback.advance()
	_expect(gap.phase == "gap" and not playback.get_apparition().visible and playback.state().cursor.poses.is_empty(), "inter-echo gap has no ghost or fabricated travel between separate absolute origins")
	await _until(arena.scheduler, origin + float(second.from_s))
	playback.advance()
	_expect(playback.get_apparition().visible and playback.get_apparition().weapon_visual_id == installed.native.capture_snapshot.slots[1].dash.equipment_ids.weapon, "second sequential apparition retains its own legal static equipment")
	arena.player.global_position = second.events[0].record.world_origin + second.events[0].record.direction * 0.3
	await _until(arena.scheduler, origin + float(second.events[0].at_s))
	playback.advance()
	_expect(playback.state().opportunities.size() == 3 and playback.state().cursor.next_event_index == 3 and arena.player.shells == 0, "at most two captured combinations complete with no third slot, ammo use or proc")
	await _dispose(arena)


func _wall_and_geometry() -> void:
	var arena: Dictionary = await _arena(true)
	var recorded: Dictionary = await _record(arena, 1)
	var installed: Dictionary = _install(arena, recorded)
	if installed.is_empty():
		await _dispose(arena)
		return
	var playback = installed.playback
	var slot: Dictionary = installed.native.timeline.slots[0]
	_expect(installed.native.capture_snapshot.slots[0].dash.collision_shortened and slot.route[-1].position == installed.native.capture_snapshot.slots[0].dash.landing, "preexisting wall-shortened actual landing including its original Y remains untouched")
	await _lock(arena, installed)
	var event: Dictionary = slot.events[0]
	var record: Dictionary = event.record
	# The live hero is free to ignore the admitted witness; its actual contact
	# and scenery ray at delivery determine damage, not the planned escape.
	arena.player.global_position = record.world_origin + Vector3.RIGHT * 0.8
	var hp: float = arena.player.hp
	await _until(arena.scheduler, float(installed.lease.adapter.timeline_origin_s) + float(event.at_s))
	playback.advance()
	_expect(arena.player.hp == hp and not playback.state().opportunities[0].contact, "actual scenery LOS blocks the original canonical cone without retrying that spent event")
	arena.player.global_position = record.world_origin + Vector3.RIGHT * 0.1
	playback.advance()
	_expect(arena.player.hp == hp and playback.state().cursor.next_event_index == 1, "moving out of LOS shelter afterward cannot reopen a consumed opportunity")
	# Direct contact assertions use the actual same physical space and canonical
	# record, matching Player's origin disk, vertical/range boundaries and ray.
	arena.player.global_position = record.world_origin + Vector3.LEFT * 0.05
	_expect(playback._contact(record, arena.player), "origin disk accepts an actual target behind the direction within the canonical radius")
	arena.player.global_position = record.world_origin + Vector3.LEFT * 0.2
	_expect(not playback._contact(record, arena.player), "outside origin disk an actual target behind the cone misses")
	arena.player.global_position = record.world_origin + Vector3.UP * (float(record.geometry.max_vertical_distance) + 0.01)
	_expect(not playback._contact(record, arena.player), "live target above canonical vertical range misses")
	arena.player.global_position = record.world_origin + Vector3.LEFT * (float(record.geometry.reach) + 0.01)
	_expect(not playback._contact(record, arena.player), "live target beyond canonical radial reach misses")
	await _dispose(arena)


func _grace_and_cancellation() -> void:
	# Labeled controlled-clock boundary transport built from ACTUAL actor records.
	# Scheduler physics and playback auto-physics are disabled only for this edge.
	for late: bool in [false, true]:
		var arena: Dictionary = await _arena()
		var recorded: Dictionary = await _record(arena, 1)
		var installed: Dictionary = _install(arena, recorded)
		if installed.is_empty():
			await _dispose(arena)
			continue
		var playback = installed.playback
		await _lock(arena, installed)
		arena.scheduler.set_physics_process(false)
		var event: Dictionary = installed.native.timeline.slots[0].events[0]
		var scheduled: float = float(installed.lease.adapter.timeline_origin_s) + float(event.at_s)
		var dispatch: float = scheduled + Playback.MAX_DISPATCH_DELAY_S + (Playback.TIME_EPSILON_S * 2.0 if late else Playback.TIME_EPSILON_S * 0.5)
		arena.player.global_position = event.record.world_origin + event.record.direction * 0.3
		var hp: float = arena.player.hp
		arena.scheduler.set("_clock", dispatch)
		var result: Dictionary = playback.advance()
		if late:
			_expect(not result.accepted and result.events.is_empty() and playback.state().cursor.next_event_index == 0 and playback.state().opportunities.is_empty() and arena.player.hp == hp, "just beyond .05+canonical epsilon rejects the whole batch before any prefix, opportunity or HP mutation")
			_expect(playback.state().status == "cancelled" and arena.scheduler.replay_reservation_state(installed.id).is_empty() and playback.get_node("VisibleReplayFailure").visible, "late delivery visibly cancels the exact lease")
			paused = true
			await process_frame
			var bindings: Dictionary = _bindings(arena, playback)
			var schedule: Dictionary = arena.scheduler.snapshot_state(bindings)
			var saved: Dictionary = playback.snapshot_state(schedule, bindings)
			_expect(not saved.is_empty() and not schedule.get("replay_cancellations", []).is_empty() and not schedule.cooldowns.is_empty(), "canceled checkpoint retains exact cancellation identity and conservative source cooldown: " + playback.last_snapshot_error)
			var forged: Dictionary = saved.duplicate(true)
			if not forged.is_empty():
				forged.cancellation.reason = "invented"
				_expect(not playback.snapshot_error(forged, arena.scheduler, schedule, bindings, {"hero": arena.player}).is_empty(), "forged cancellation reason cannot authorize skipped attacks")
				_restore_cancelled(arena, installed, schedule, saved)
		else:
			_expect(result.accepted and result.events.size() == 1 and arena.player.hp == hp - float(event.record.damage), ".05 grace plus only half canonical epsilon accepts a real canonical event once")
		await _dispose(arena)
	# Pre-delivery world change is rejected without a partial consumed prefix.
	var arena: Dictionary = await _arena()
	var recorded: Dictionary = await _record(arena, 1)
	var installed: Dictionary = _install(arena, recorded)
	if not installed.is_empty():
		await _lock(arena, installed)
		_box(arena.root, Vector3(8, 1, 8), Vector3.ONE)
		var before: float = arena.player.hp
		var result: Dictionary = installed.playback.advance()
		_expect(not result.accepted and installed.playback.state().cursor.next_event_index == 0 and arena.player.hp == before, "unannounced live collision mutation fails visibly before event-prefix or damage delivery")
	await _dispose(arena)
	# Entire two-slot batch preflight: first overdue, last exactly due. The
	# timely final event cannot license partial delivery after the older miss.
	arena = await _arena()
	recorded = await _record(arena, 2)
	installed = _install(arena, recorded)
	if not installed.is_empty():
		await _lock(arena, installed)
		arena.scheduler.set_physics_process(false)
		var event: Dictionary = installed.native.timeline.slots[1].events[0]
		arena.scheduler.set("_clock", float(installed.lease.adapter.timeline_origin_s) + float(event.at_s))
		var hp: float = arena.player.hp
		var result: Dictionary = installed.playback.advance()
		_expect(not result.accepted and result.events.is_empty() and installed.playback.state().cursor.next_event_index == 0 and installed.playback.state().opportunities.is_empty() and arena.player.hp == hp, "one overdue earlier event rejects ALL due events including an exactly timely second slot before any prefix")
	await _dispose(arena)


func _invulnerable() -> void:
	var arena: Dictionary = await _arena()
	var recorded: Dictionary = await _record(arena, 1)
	var installed: Dictionary = _install(arena, recorded)
	if not installed.is_empty():
		await _lock(arena, installed)
		var event: Dictionary = installed.native.timeline.slots[0].events[0]
		arena.player.global_position = event.record.world_origin + event.record.direction * 0.3
		arena.player.take_damage(1.0, Vector3.ZERO)
		var hp: float = arena.player.hp
		await _until(arena.scheduler, float(installed.lease.adapter.timeline_origin_s) + float(event.at_s))
		installed.playback.advance()
		_expect(arena.player.hp == hp and installed.playback.state().opportunities[0].contact and installed.playback.state().opportunities[0].damage_attempted, "actual hurt invulnerability can reject HP damage but still consumes its contacted canonical opportunity")
		installed.playback.advance()
		_expect(arena.player.hp == hp and installed.playback.state().cursor.next_event_index == 1, "invulnerable target receives no retry after its spent event")
	await _dispose(arena)


func _restore_cancelled(arena: Dictionary, installed: Dictionary, schedule: Dictionary, saved: Dictionary) -> void:
	var hero: CinderPlayer = Player.new()
	hero.name = "CancelledRestoredHero"
	arena.root.add_child(hero)
	var scheduler = Scheduler.new()
	scheduler.name = "CancelledRestoredScheduler"
	arena.root.add_child(scheduler)
	var owner = Playback.new()
	owner.name = "CancelledRestoredPlayback"
	arena.root.add_child(owner)
	owner.set_physics_process(false)
	owner.configure("playback/test", installed.sequence, EPOCH, 1)
	owner.global_position = installed.source_position
	var bindings: Dictionary = {"world_root": arena.root, "owners": {"source": owner}, "actors": {"hero": hero}, "floors": {"floor": {"collision": arena.floor, "safe_rect": Rect2(-10, -10, 20, 20)}}}
	var calls: Array[String] = []
	owner.event_dispatched.connect(func(_event: Dictionary, _opportunity: Dictionary) -> void: calls.append("event"))
	owner.state_changed.connect(func(_state: Dictionary) -> void: calls.append("state"))
	_expect(owner.snapshot_error(_json(saved), scheduler, _json(schedule), bindings, {"hero": hero}).is_empty(), "fresh canceled pair prevalidates exact tombstone and frozen prefix without rearming")
	_expect(hero.restore_state(_json(arena.player.snapshot_state())) and scheduler.restore_state(_json(schedule), bindings) and owner.restore_state(_json(saved), scheduler, _json(schedule), bindings, {"hero": hero}), "fresh actor/scheduler/playback canceled restore commits only retained cancellation history")
	_expect(owner.state().status == "cancelled" and owner.state().cursor.next_event_index == 0 and calls.is_empty() and not owner.advance().accepted and hero.hp == arena.player.hp, "restored canceled sequence delivers no skipped attack, HP loss or callback")


func _paired_restore() -> void:
	var arena: Dictionary = await _arena()
	var recorded: Dictionary = await _record(arena, 1, true, true)
	var installed: Dictionary = _install(arena, recorded)
	if installed.is_empty():
		await _dispose(arena)
		return
	var playback = installed.playback
	await _lock(arena, installed)
	var slot: Dictionary = installed.native.timeline.slots[0]
	var origin: float = installed.lease.adapter.timeline_origin_s
	await _until(arena.scheduler, origin + float(slot.from_s) + 0.06)
	playback.advance()
	paused = true
	await process_frame
	var bindings: Dictionary = _bindings(arena, playback)
	var schedule: Dictionary = _json(arena.scheduler.snapshot_state(bindings))
	var saved: Dictionary = _json(playback.snapshot_state(schedule, bindings))
	var actor: Dictionary = _json(arena.player.snapshot_state())
	_expect(not saved.is_empty() and saved.cursor.next_event_index == 0 and saved.cursor.phase == "active", "actual paused mid-route aggregate encodes to finite JSON without consuming a future attack")
	var frozen: Dictionary = playback.state()
	for key: String in ["source_epoch", "generation", "hero_id", "reservation_id", "clock_s"]:
		var forged: Dictionary = saved.duplicate(true)
		forged[key] = 7 if key in ["generation", "clock_s"] else "forged"
		_expect(not playback.restore_state(forged, arena.scheduler, schedule, bindings, {"hero": arena.player}) and playback.state() == frozen, "invalid paired " + key + " rejects atomically")
	var forged: Dictionary = saved.duplicate(true)
	forged.exchange.adapter.timeline_origin_s += 0.01
	_expect(not playback.restore_state(forged, arena.scheduler, schedule, bindings, {"hero": arena.player}) and playback.state() == frozen, "retimed immutable arm origin rejects atomically")
	forged = saved.duplicate(true)
	forged.clock_s = _next_float(float(saved.clock_s))
	_expect(not playback.restore_state(forged, arena.scheduler, schedule, bindings, {"hero": arena.player}) and playback.state() == frozen, "one-bit paired aggregate clock mutation rejects without generic tolerance")
	forged = saved.duplicate(true)
	forged.exchange.adapter.sequence.timeline.slots[0].events[0].at_s = _next_float(float(forged.exchange.adapter.sequence.timeline.slots[0].events[0].at_s))
	_expect(not playback.restore_state(forged, arena.scheduler, schedule, bindings, {"hero": arena.player}) and playback.state() == frozen, "one-bit immutable event timeline mutation rejects without transport tolerance")
	for malformed: Variant in [[], {}, "bad", null]:
		forged = saved.duplicate(true)
		forged.cursor.last_advanced_clock_s = malformed
		_expect(not playback.restore_state(forged, arena.scheduler, schedule, bindings, {"hero": arena.player}) and playback.state() == frozen, "malformed nonnumeric cursor clock rejects atomically without conversion or callback")
	var fresh_player: CinderPlayer = Player.new()
	fresh_player.name = "FreshHero"
	arena.root.add_child(fresh_player)
	var fresh_scheduler = Scheduler.new()
	fresh_scheduler.name = "FreshScheduler"
	arena.root.add_child(fresh_scheduler)
	var fresh = Playback.new()
	fresh.name = "FreshPlayback"
	arena.root.add_child(fresh)
	fresh.set_physics_process(false)
	fresh.configure("playback/test", installed.sequence, EPOCH, 1)
	fresh.global_position = installed.source_position
	var fresh_bindings: Dictionary = {"world_root": arena.root, "owners": {"source": fresh}, "actors": {"hero": fresh_player}, "floors": {"floor": bindings.floors.floor}}
	var signals: Array[String] = []
	fresh.event_dispatched.connect(func(_event: Dictionary, _opportunity: Dictionary) -> void: signals.append("event"))
	fresh.state_changed.connect(func(_state: Dictionary) -> void: signals.append("state"))
	fresh_player.fired.connect(func(_kind: String) -> void: signals.append("damage"))
	for cue: Node3D in fresh.get_cues():
		cue.state_changed.connect(func(_state: Dictionary) -> void: signals.append("cue"))
	_expect(fresh.snapshot_error(saved, fresh_scheduler, schedule, fresh_bindings, {"hero": fresh_player}).is_empty(), "whole staged paired state prevalidates before any fresh actor/scheduler/playback commit")
	_expect(not fresh.restore_state(saved, fresh_scheduler, schedule, fresh_bindings, {"hero": fresh_player}) and fresh.state().status == "idle", "consumer commit cannot substitute for actual actor then scheduler restore")
	_expect(fresh_player.restore_state(actor) and fresh_scheduler.restore_state(schedule, fresh_bindings), "fresh actor then exact saved scheduler lease commit without reproof/rearm")
	_expect(fresh.restore_state(saved, fresh_scheduler, schedule, fresh_bindings, {"hero": fresh_player}) and signals.is_empty() and fresh.state().cursor.poses == playback.state().cursor.poses, "quiet fresh playback restore recreates identical world pose and emits no cue/damage/action events")
	_expect(fresh_player.hp == arena.player.hp and fresh_player.shells == arena.player.shells and fresh_player.get_world_action_records() == arena.player.get_world_action_records(), "paired playback carries no duplicate player HP/ammo/action state")
	# Retire old runtime explicitly; new actor has its own independent binding.
	playback.set_physics_process(false)
	arena.scheduler.set_physics_process(false)
	arena.player.set_physics_process(false)
	fresh_player.set_physics_process(false)
	arena.scheduler.end_encounter()
	paused = false
	var record: Dictionary = slot.events[0].record
	fresh_player.global_position = record.world_origin + Vector3.LEFT * 0.6
	await _until(fresh_scheduler, origin + float(slot.events[0].at_s))
	var hp: float = fresh_player.hp
	fresh.advance()
	_expect(fresh.state().cursor.next_event_index == 1 and fresh_player.hp == hp, "restored mid-route continuation consumes the missed primary once before the actual delayed blast")
	paused = true
	await process_frame
	var second_schedule: Dictionary = _json(fresh_scheduler.snapshot_state(fresh_bindings))
	var second_saved: Dictionary = _json(fresh.snapshot_state(second_schedule, fresh_bindings))
	var calls: int = signals.size()
	_expect(fresh.restore_state(second_saved, fresh_scheduler, second_schedule, fresh_bindings, {"hero": fresh_player}) and signals.size() == calls, "idempotent paused restore after consumed damage remains quiet")
	paused = false
	fresh.advance()
	_expect(fresh_player.hp == hp and fresh.state().cursor.next_event_index == 1, "equal-clock continuation after restored primary prefix cannot redeliver its opportunity")
	await _until(fresh_scheduler, origin + float(slot.events[1].at_s))
	fresh.advance()
	_expect(fresh_player.hp == hp - float(slot.events[1].record.damage) and fresh.state().cursor.next_event_index == 2, "restored pending actual blast preserves its original spacing and independent aim, dispatching once")
	await _dispose(arena)


func _callback_boundaries() -> void:
	for boundary: String in ["cue", "event", "hurt", "hide", "outline", "fill", "clear", "death"]:
		var arena: Dictionary = await _arena()
		var recorded: Dictionary = await _record(arena, 1, true)
		var installed: Dictionary = _install(arena, recorded)
		if installed.is_empty():
			await _dispose(arena)
			continue
		var playback = installed.playback
		await _lock(arena, installed)
		var slot: Dictionary = installed.native.timeline.slots[0]
		var origin: float = float(installed.lease.adapter.timeline_origin_s)
		# Real recorded simultaneous events; only the blast contacts in cue/event
		# cases, while the origin disk makes both contact for hurt/death receipts.
		arena.player.global_position = slot.events[0].record.world_origin + (Vector3.ZERO if boundary in ["hurt", "death"] else Vector3.LEFT * 0.6)
		if boundary == "death":
			arena.player.hp = 0.1 # TEST ONLY depleted fixture, actual damage kills.
		var hp: float = arena.player.hp
		var calls: Array[String] = []
		var held: Array[bool] = [false]
		var cues: Array[Node3D] = playback.get_cues()
		cues[0].state_changed.connect(func(value: Dictionary) -> void:
			if value.phase == "active" and not held[0] and boundary in ["cue", "hide", "outline", "fill", "clear"]:
				held[0] = true
				if boundary == "hide":
					cues[0].get_node("RequiredSourceMarker").hide()
				elif boundary == "outline":
					cues[0].get_node("RequiredFootprintOutline").hide()
				elif boundary == "fill":
					cues[0].get_node("RequiredFootprintFill").hide()
				elif boundary == "clear":
					cues[1].clear()
				else:
					paused = true
		)
		arena.player.fired.connect(func(kind: String) -> void:
			if kind == "hurt" and boundary == "hurt" and not held[0]:
				held[0] = true
				paused = true
		)
		arena.player.died.connect(func() -> void:
			if boundary == "death":
				paused = true
		)
		playback.event_dispatched.connect(func(event: Dictionary, _opportunity: Dictionary) -> void:
			calls.append(event.kind)
			if boundary == "event" and not held[0]:
				held[0] = true
				paused = true
		)
		await _until(arena.scheduler, origin + float(slot.events[0].at_s))
		playback.advance()
		if boundary in ["hide", "outline", "fill", "clear"]:
			_expect(playback.state().status == "cancelled" and arena.player.hp == hp and calls.is_empty() and not arena.scheduler.replay_cancellation_state(installed.id).is_empty(), "required cue " + boundary + " during active observer cancels before any damage/event and retains exact cooldown provenance")
		elif boundary == "death":
			_expect(paused and arena.player.dead and playback.state().status == "cancelled" and calls.is_empty(), "actual death observer terminates remaining echo/hit/event callbacks immediately")
			await process_frame
			var death_bundle: Dictionary = _save_pair(arena, playback, "death")
			var dead_fresh: Dictionary = _fresh_pair(arena, installed, death_bundle)
			if not dead_fresh.is_empty():
				paused = false
				_expect(dead_fresh.player.dead and dead_fresh.player.hp == 0.0 and dead_fresh.playback.state().cursor.next_event_index == 2 and not dead_fresh.playback.advance().accepted, "quiet fresh fatal aggregate retains death and consumed prefix without damage/event reexecution")
		else:
			_expect(paused and playback.state().cursor.next_event_index == 2 and calls.size() == (1 if boundary == "event" else 0) and arena.player.hp == (hp - float(slot.events[0].record.damage) if boundary == "hurt" else hp), "held " + boundary + " pause stops the exact callback remainder without losing its consumed canonical batch")
			await process_frame
			var bindings: Dictionary = _bindings(arena, playback)
			var schedule: Dictionary = arena.scheduler.snapshot_state(bindings)
			var saved: Dictionary = playback.snapshot_state(schedule, bindings)
			_expect(saved.get("schema_version") == 2 and not saved.get("pending_delivery", {}).is_empty(), "held " + boundary + " pause exposes exact conditional pending schema2 instead of pretending all callbacks finished")
			if saved.get("schema_version") == 2:
				var prefix: int = calls.size()
				paused = false
				playback.advance()
				_expect(calls.size() == 2 and playback.state().cursor.next_event_index == 2 and playback.state().get("pending_delivery", {}).is_empty(), "same-clock resume drains held " + boundary + " suffix once without republishing its delivered prefix" + str(prefix))
		await _dispose(arena)


func _held_phase_restore() -> void:
	for phase: String in ["warning", "lock"]:
		var arena: Dictionary = await _arena()
		var recorded: Dictionary = await _record(arena, 1, true)
		var held: Array[bool] = [false]
		var states: Array[String] = []
		var callback: Callable = func(value: Dictionary) -> void:
			if value.phase == phase and not held[0]:
				held[0] = true
				paused = true
		var installed: Dictionary = _install(arena, recorded, callback)
		if installed.is_empty():
			await _dispose(arena)
			continue
		installed.playback.state_changed.connect(func(value: Dictionary) -> void: states.append(value.status))
		if phase == "lock":
			await _lock(arena, installed)
		_expect(paused and held[0] and states.is_empty(), "held first " + phase + " cue stops before the final playback state callback")
		await process_frame
		var bundle: Dictionary = _save_pair(arena, installed.playback, phase)
		if bundle.playback.is_empty():
			await _dispose(arena)
			continue
		var pending: Dictionary = bundle.playback.pending_delivery
		_expect(pending.events.is_empty() and pending.visual_next_cue == 1 and pending.cue_phases == (["warning", "clear"] if phase == "warning" else ["lock", "warning"]), "partial " + phase + " retains the exact presented prefix and untouched suffix")
		_expect(not installed.playback.get_apparition().visible and bundle.playback.schema_version == 2, "pose-empty " + phase + " retains required cues without inventing an active apparition")
		var fresh: Dictionary = _fresh_pair(arena, installed, bundle)
		if fresh.is_empty():
			await _dispose(arena)
			continue
		var fresh_states: Array[String] = []
		fresh.playback.state_changed.connect(func(value: Dictionary) -> void: fresh_states.append(value.status))
		_expect(fresh.playback.get_cues()[0].state().phase == phase and fresh.playback.get_cues()[1].state().phase == ("clear" if phase == "warning" else "warning"), "quiet fresh restore preserves a genuinely partial " + phase + " refresh")
		var frozen: Dictionary = fresh.playback.state()
		var forged: Dictionary = bundle.playback.duplicate(true)
		forged.pending_delivery.cue_phases[1] = phase
		_expect(not fresh.playback.restore_state(forged, fresh.scheduler, bundle.scheduler, fresh.bindings, {"hero": fresh.player}) and fresh.playback.state() == frozen, "forged unpresented " + phase + " suffix rejects atomically")
		paused = false
		fresh.playback.advance()
		_expect(fresh_states == ["running"] and fresh.playback.state().get("pending_delivery", {}).is_empty(), "first resume finishes " + phase + " presentation and publishes its state exactly once")
		fresh.playback.advance()
		_expect(fresh_states.size() == 2, "subsequent explicit advance may publish a new state but does not repeat an interrupted callback slice")
		paused = true
		await process_frame
		var drained: Dictionary = fresh.playback.snapshot_state(fresh.scheduler.snapshot_state(fresh.bindings), fresh.bindings)
		_expect(drained.get("schema_version") == 1 and not drained.has("pending_delivery"), "fully drained " + phase + " returns the exact ordinary schema1 shape")
		await _dispose(arena)


func _pending_fresh_restore() -> void:
	var arena: Dictionary = await _arena()
	var recorded: Dictionary = await _record(arena, 1, true)
	var installed: Dictionary = _install(arena, recorded)
	if installed.is_empty():
		await _dispose(arena)
		return
	await _lock(arena, installed)
	var playback = installed.playback
	var event: Dictionary = installed.native.timeline.slots[0].events[0]
	arena.player.global_position = event.record.world_origin + Vector3.LEFT * 0.3
	var held: Array[bool] = [false]
	playback.get_cues()[0].state_changed.connect(func(value: Dictionary) -> void:
		if value.phase == "active" and not held[0]:
			held[0] = true
			arena.player.request_dash(Vector3.RIGHT) # Actual action, no position proxy.
			paused = true
	)
	await _until(arena.scheduler, float(installed.lease.adapter.timeline_origin_s) + float(event.at_s))
	playback.advance()
	await process_frame
	var bundle: Dictionary = _save_pair(arena, playback, "cue-dash")
	if bundle.playback.is_empty():
		await _dispose(arena)
		return
	_expect(bundle.playback.opportunities[0].contact == false and bundle.playback.opportunities[1].contact and not bundle.playback.opportunities[1].damage_attempted and arena.player.get_committed_dash_state().active, "held cue stores original independently aimed blast contact and an actual unfinished player dash")
	_pending_negatives(arena, playback, bundle)
	var fresh: Dictionary = _fresh_pair(arena, installed, bundle)
	if fresh.is_empty():
		await _dispose(arena)
		return
	var calls: Array[String] = []
	var event_pause: Array[bool] = [false]
	fresh.playback.event_dispatched.connect(func(value: Dictionary, _opportunity: Dictionary) -> void:
		calls.append(value.kind)
		if not event_pause[0]:
			event_pause[0] = true
			paused = true
	)
	var original_receipts: Array = bundle.playback.opportunities.duplicate(true)
	var hp: float = fresh.player.hp
	var before: Vector3 = fresh.player.global_position
	await _resume_tick(fresh.playback)
	_expect(paused and calls == ["primary"] and fresh.player.global_position != before and fresh.player.get_committed_dash_state().active, "next real physics tick moves the restored unfinished dash before the held first event callback: " + fresh.playback.state().status + "/" + fresh.playback.state().reason + " calls=" + str(calls))
	await process_frame
	var event_bundle: Dictionary = _save_pair(fresh, fresh.playback, "event-dash")
	_expect(event_bundle.playback.get("pending_delivery", {}).get("events", []) == [{"event_index": 1, "stage": "present"}] and fresh.playback.state().visual_pose.action == "primary" and fresh.playback.state().visual_pose.direction == Vector3.RIGHT, "popped first event leaves the last actually presented primary, not the consumed left blast")
	var next_installed: Dictionary = installed.duplicate()
	next_installed.playback = fresh.playback
	var second: Dictionary = _fresh_pair(fresh, next_installed, event_bundle)
	if second.is_empty():
		await _dispose(arena)
		return
	var final_calls: Array[String] = []
	var active_pause: Array[bool] = [false]
	second.playback.get_cues()[1].state_changed.connect(func(value: Dictionary) -> void:
		if value.phase == "active" and not active_pause[0]:
			active_pause[0] = true
			paused = true
	)
	second.playback.event_dispatched.connect(func(value: Dictionary, _opportunity: Dictionary) -> void: final_calls.append(value.kind))
	await _resume_tick(second.playback)
	_expect(paused and second.player.global_position.x > event.record.world_origin.x + float(event.record.geometry.origin_disk_radius), "second real resume tick moves the current hero outside the saved left blast and origin disk")
	await process_frame
	var third_bundle: Dictionary = _save_pair(second, second.playback, "blast-dash")
	_expect(third_bundle.playback.opportunities[1].contact and not third_bundle.playback.opportunities[1].damage_attempted and third_bundle.playback.pending_delivery.events == [{"event_index": 1, "stage": "damage"}], "repeated held cue pause retains original contact without a fabricated later contact sample")
	var native_before: Dictionary = _native_presentation(second.playback)
	_expect(second.playback.restore_state(third_bundle.playback, second.scheduler, third_bundle.scheduler, second.bindings, {"hero": second.player}) and _native_presentation(second.playback) == native_before and final_calls.is_empty(), "idempotent repeated-pause quiet restore preserves actual native blast pixels/pose/gear and no event callback")
	paused = false
	second.playback.advance() # Same original aggregate clock, no new movement.
	var delivered: Dictionary = second.playback.state()
	_expect(final_calls == ["blast"] and delivered.opportunities[1].contact and delivered.opportunities[1].damage_attempted and second.player.hp == hp, "original contact receives one truthful damage opportunity; actual restored dash invulnerability prevents HP loss")
	for index: int in range(2):
		_expect(delivered.opportunities[index].scheduled_at_s == original_receipts[index].scheduled_at_s and delivered.opportunities[index].dispatch_clock_s == original_receipts[index].dispatch_clock_s, "repeated pause/fresh restore retains original event " + str(index) + " clocks exactly")
	second.playback.advance()
	_expect(final_calls == ["blast"] and second.player.hp == hp, "equal-clock advance cannot repeat the transferred event notification or HP opportunity")
	paused = true
	await process_frame
	var drained: Dictionary = second.playback.snapshot_state(second.scheduler.snapshot_state(second.bindings), second.bindings)
	_expect(drained.get("schema_version") == 1 and not drained.has("pending_delivery"), "actual repeated-pause delivery drains to exact legacy schema1")
	await _dispose(arena)


func _pending_expiry() -> void:
	for mode: String in ["near-grace", "drain-late", "lease-expired"]:
		var arena: Dictionary = await _arena()
		var recorded: Dictionary = await _record(arena, 1)
		var installed: Dictionary = _install(arena, recorded)
		if installed.is_empty():
			await _dispose(arena)
			continue
		await _lock(arena, installed)
		var event: Dictionary = installed.native.timeline.slots[0].events[0]
		arena.player.global_position = event.record.world_origin + Vector3.RIGHT * 0.3
		var hp: float = arena.player.hp
		var calls: Array[String] = []
		installed.playback.event_dispatched.connect(func(value: Dictionary, _receipt: Dictionary) -> void: calls.append(value.kind))
		installed.playback.get_cues()[0].state_changed.connect(func(value: Dictionary) -> void:
			if value.phase == "active":
				paused = true
		)
		var scheduled: float = float(installed.lease.adapter.timeline_origin_s) + float(event.at_s)
		if mode == "near-grace":
			# Labelled transport admission edge from a real canonical actor record.
			# Resume below is an ACTUAL physics tick, not an injected contact clock.
			arena.scheduler.set_physics_process(false)
			arena.scheduler.set("_clock", scheduled + 0.049)
		else:
			await _until(arena.scheduler, scheduled)
		installed.playback.advance()
		_expect(paused and installed.playback.state().cursor.next_event_index == 1 and not installed.playback.state().get("pending_delivery", {}).is_empty() and arena.player.hp == hp, mode + " holds a consumed final event before its actual damage attempt")
		var original: Dictionary = installed.playback.state().opportunities[0].duplicate(true)
		arena.scheduler.set_physics_process(true)
		paused = false
		if mode == "near-grace":
			await _resume_tick(installed.playback)
			var delivered: Dictionary = installed.playback.state().opportunities[0]
			_expect(arena.scheduler.get_clock() > scheduled + Playback.MAX_DISPATCH_DELAY_S and calls == ["primary"] and delivered.contact and delivered.damage_attempted and arena.player.hp == hp - float(event.record.damage), "valid near-grace contact survives one normal resumed physics tick without recharging original scheduled admission: " + installed.playback.state().status + "/" + installed.playback.state().reason + " calls=" + str(calls))
			_expect(delivered.dispatch_clock_s == original.dispatch_clock_s and delivered.scheduled_at_s == original.scheduled_at_s, "near-grace resume retains exact original contact clocks")
		else:
			# Controlled caller: scheduler ticks while Playback remains manual.
			await _until(arena.scheduler, float(original.dispatch_clock_s) + 0.06 if mode == "drain-late" else float(installed.lease.recovery_until_s) + 0.02)
			installed.playback.advance()
			paused = true
			await process_frame
			_expect(installed.playback.state().status == "cancelled" and installed.playback.state().cursor.next_event_index == 1 and arena.player.hp == hp and calls.is_empty(), mode + " cannot mark an undelivered final suffix complete or deliver delayed damage")
			if mode == "drain-late":
				var bundle: Dictionary = _save_pair(arena, installed.playback, "expired-drain")
				_expect(bundle.playback.get("schema_version") == 2 and not bundle.playback.cancellation.is_empty() and bundle.playback.pending_delivery.events == [{"event_index": 0, "stage": "damage"}], "unpaused drain miss freezes its exact stage/receipt with retained scheduler cancellation cooldown")
			else:
				var bindings: Dictionary = _bindings(arena, installed.playback)
				var schedule: Dictionary = arena.scheduler.snapshot_state(bindings)
				_expect(installed.playback.snapshot_state(schedule, bindings).is_empty() and not installed.playback.last_snapshot_error.is_empty(), "expired scheduler lease without cancellation provenance fails closed for fresh terminal transport")
		await _dispose(arena)


func _resume_tick(playback: Node3D) -> void:
	# Actual later-priority native physics delivery, before headless catch-up can
	# execute further actor/scheduler ticks. It does not call their internals.
	var step := ResumeTick.new()
	step.delivery = func() -> void: playback.advance()
	root.add_child(step)
	paused = false
	for _wait: int in range(20):
		await physics_frame
		await process_frame
		if step.done:
			break
	_expect(step.done and paused, "bounded later-priority fixture delivers on exactly one real resumed physics tick")
	step.free()


func _freed_preview_child() -> void:
	var arena: Dictionary = await _arena()
	var recorded: Dictionary = await _record(arena, 1, true)
	var playback = Playback.new()
	arena.root.add_child(playback)
	playback.set_physics_process(false)
	playback.configure("playback/test", recorded.sequence, EPOCH, 1)
	playback.global_position = recorded.native.authored.tether_position
	arena.scheduler.begin_encounter("standard", "playback/test", 1)
	var answer: Dictionary = arena.scheduler.request_replay(playback, recorded.sequence, _response(arena), {"world_root": arena.root, "source_epoch": EPOCH, "generation": 1, "capture_collision_fingerprint": recorded.fingerprint})
	_expect(answer.get("accepted", false), "real exclusive preview admits focused renderer-removal regression")
	if not answer.get("accepted", false):
		await _dispose(arena)
		return
	while not recorded.capture.take_next().is_empty():
		pass # Parent retires actual sealed custody before bind.
	var removed: WeakRef = weakref(playback.get_cues()[1].get_node("RequiredFootprintFill"))
	var phases: Array[String] = []
	playback.get_cues()[0].state_changed.connect(func(value: Dictionary) -> void:
		phases.append(value.phase)
		if value.phase == "warning":
			playback.get_cues()[1].get_node("RequiredFootprintFill").queue_free()
			paused = true
	)
	var hp: float = arena.player.hp
	_expect(not playback.bind(arena.scheduler, answer.reservation_id, {"hero": arena.player}) and paused and playback.state().status == "cancelled", "queued child loss in an unpresented clear suffix cancels before next cue presentation")
	await process_frame
	_expect(removed.get_ref() == null and not playback.get_cues()[1].visible and playback.get_node("VisibleReplayFailure").visible, "actual freed renderer child is safely hidden without Cue.clear dereference")
	var prefix: int = playback.state().cursor.next_event_index
	paused = false
	playback.advance()
	paused = true
	await process_frame
	_expect(playback.state().cursor.next_event_index == prefix and prefix == 0 and phases == ["warning"] and arena.player.hp == hp, "broken renderer cleanup/resume performs no extra cue callback, attack or damage")
	var bindings: Dictionary = _bindings(arena, playback)
	var schedule: Dictionary = arena.scheduler.snapshot_state(bindings)
	var canceled: Dictionary = playback.snapshot_state(schedule, bindings)
	_expect(not canceled.is_empty() and canceled.status == "cancelled", "broken transient renderer retains a valid canceled historical receipt without future damage authority")
	var installed: Dictionary = {"playback": playback, "sequence": recorded.sequence, "source_position": playback.global_position}
	var fresh: Dictionary = _fresh_pair(arena, installed, {"actor": arena.player.snapshot_state(), "scheduler": schedule, "playback": canceled})
	if not fresh.is_empty():
		paused = false
		_expect(not fresh.playback.advance().accepted and fresh.player.hp == hp, "intact quiet fresh canceled restore never repairs a broken source into an active threat")
	await _dispose(arena)


func _pending_live_authority() -> void:
	for loss: String in ["clear", "hidden", "missing"]:
		var arena: Dictionary = await _arena()
		var recorded: Dictionary = await _record(arena, 1, true)
		var installed: Dictionary = _install(arena, recorded)
		if installed.is_empty():
			await _dispose(arena)
			continue
		await _lock(arena, installed)
		var event: Dictionary = installed.native.timeline.slots[0].events[0]
		arena.player.global_position = event.record.world_origin
		installed.playback.get_cues()[0].state_changed.connect(func(value: Dictionary) -> void:
			if value.phase == "active":
				paused = true
		)
		await _until(arena.scheduler, float(installed.lease.adapter.timeline_origin_s) + float(event.at_s))
		installed.playback.advance()
		await process_frame
		var bindings: Dictionary = _bindings(arena, installed.playback)
		var schedule: Dictionary = arena.scheduler.snapshot_state(bindings)
		var valid: Dictionary = installed.playback.snapshot_state(schedule, bindings)
		_expect(valid.get("schema_version") == 2 and valid.opportunities[0].contact and not valid.opportunities[0].damage_attempted, loss + " begins with an actual accepted held pending contact")
		var cue: Node3D = installed.playback.get_cues()[0]
		match loss:
			"clear": cue.clear()
			"hidden": cue.get_node("RequiredSourceMarker").hide()
			"missing": cue.get_node("RequiredFootprintFill").queue_free()
		await process_frame # Missing case is ACTUALLY freed at deferred barrier.
		var frozen: Dictionary = installed.playback.state()
		var actor: String = ExactJson.stringify(arena.player.snapshot_state())
		var calls: Array[String] = []
		installed.playback.state_changed.connect(func(_value: Dictionary) -> void: calls.append("state"))
		installed.playback.event_dispatched.connect(func(_event: Dictionary, _receipt: Dictionary) -> void: calls.append("event"))
		_expect(installed.playback.snapshot_state(schedule, bindings).is_empty() and installed.playback.state() == frozen and calls.is_empty() and ExactJson.stringify(arena.player.snapshot_state()) == actor, "paused writer purely rejects actual " + loss + " cue authority without healing/mutation/callback")
		_expect(not installed.playback.restore_state(valid, arena.scheduler, schedule, bindings, {"hero": arena.player}) and installed.playback.state() == frozen and calls.is_empty(), "existing reader cannot use a saved active phase to heal externally " + loss + " damage authority")
		paused = false
		installed.playback.advance()
		paused = true
		await process_frame
		_expect(installed.playback.state().status == "cancelled" and calls == ["state"] and ExactJson.stringify(arena.player.snapshot_state()) == actor, "actual resume after " + loss + " cancels without delivering the held contact")
		var terminal: Dictionary = installed.playback.snapshot_state(arena.scheduler.snapshot_state(bindings), bindings)
		_expect(not terminal.is_empty() and terminal.schema_version == 2 and not terminal.opportunities[0].damage_attempted and not terminal.cancellation.is_empty(), "canceled " + loss + " preserves immutable undelivered receipt/cooldown rather than granting active authority")
		await _dispose(arena)


func _save_pair(arena: Dictionary, playback: Node3D, label: String) -> Dictionary:
	var bindings: Dictionary = _bindings(arena, playback)
	var schedule: Dictionary = arena.scheduler.snapshot_state(bindings)
	var saved: Dictionary = playback.snapshot_state(schedule, bindings)
	_expect(not schedule.is_empty() and not saved.is_empty(), label + " captures exact coherent actor/scheduler/playback unit: " + playback.last_snapshot_error)
	if saved.is_empty():
		return {"actor": {}, "scheduler": schedule, "playback": saved}
	var payload: Dictionary = {"actor": arena.player.snapshot_state(), "scheduler": schedule, "playback": saved}
	var path: String = "user://test-replay-pending-%d-%s.json" % [OS.get_process_id(), label]
	var store = SaveStore.new(path)
	_expect(store.write_payload(payload), label + " writes a real isolated exact format2 save: " + store.last_error)
	var loaded: Dictionary = store.read_payload()
	_expect(ExactJson.stringify(loaded) == ExactJson.stringify(payload), label + " disk roundtrip preserves exact pending unit clocks/types/receipts")
	for suffix: String in ["", ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	return loaded if loaded.has("playback") else {"actor": {}, "scheduler": schedule, "playback": {}}


func _native_presentation(playback: Node3D) -> Dictionary:
	var sprite = playback.get_apparition()
	var cues: Array = []
	for cue: Node3D in playback.get_cues():
		cues.append(cue.state())
	return {"root_transform": playback.get_apparition_root().global_transform, "sprite_transform": sprite.transform, "visible": sprite.visible, "texture_bytes": sprite.texture.get_image().get_data(), "presentation": sprite.presentation_id, "weapon": sprite.weapon_visual_id, "jacket": sprite.jacket_visual_id, "pants": sprite.pants_visual_id, "shoes": sprite.shoes_visual_id, "cues": cues, "pose": playback.state().visual_pose}


func _fresh_pair(arena: Dictionary, installed: Dictionary, bundle: Dictionary) -> Dictionary:
	if bundle.get("playback", {}).is_empty():
		return {}
	var native_before: Dictionary = _native_presentation(installed.playback)
	var hero: CinderPlayer = Player.new()
	hero.name = "FreshPendingHero"
	arena.root.add_child(hero)
	var scheduler = Scheduler.new()
	scheduler.name = "FreshPendingScheduler"
	arena.root.add_child(scheduler)
	var owner = Playback.new()
	owner.name = "FreshPendingPlayback"
	arena.root.add_child(owner)
	owner.set_physics_process(false)
	owner.configure("playback/test", installed.sequence, EPOCH, 1)
	owner.global_position = installed.source_position
	var fresh: Dictionary = {"root": arena.root, "player": hero, "scheduler": scheduler, "floor": arena.floor, "playback": owner, "wall": arena.wall}
	fresh["bindings"] = _bindings(fresh, owner)
	var calls: Array[String] = []
	owner.state_changed.connect(func(_value: Dictionary) -> void: calls.append("state"))
	owner.event_dispatched.connect(func(_event: Dictionary, _receipt: Dictionary) -> void: calls.append("event"))
	hero.fired.connect(func(_kind: String) -> void: calls.append("actor"))
	for cue: Node3D in owner.get_cues():
		cue.state_changed.connect(func(_value: Dictionary) -> void: calls.append("cue"))
	_expect(hero.snapshot_error(bundle.actor).is_empty() and owner.snapshot_error(bundle.playback, scheduler, bundle.scheduler, fresh.bindings, {"hero": hero}).is_empty(), "fresh paused whole pending aggregate prevalidates without actor/scheduler mutation")
	var accepted: bool = hero.restore_state(bundle.actor) and scheduler.restore_state(bundle.scheduler, fresh.bindings) and owner.restore_state(bundle.playback, scheduler, bundle.scheduler, fresh.bindings, {"hero": hero})
	_expect(accepted and calls.is_empty(), "fresh real actor then scheduler then pending playback restore is quiet: " + owner.last_snapshot_error)
	if not accepted:
		return {}
	if bundle.playback.status == "running":
		_expect(_native_presentation(owner) == native_before, "quiet fresh restore reproduces ACTUAL apparition native transform/facing/action pixels/gear and every partial cue phase")
	else:
		_expect(not owner.get_apparition().visible and owner.get_cues()[0].state().phase == "clear", "quiet canceled restore discards transient pose and clears all damaging cues")
	_expect(ExactJson.stringify(hero.snapshot_state()) == ExactJson.stringify(bundle.actor) and ExactJson.stringify(scheduler.snapshot_state(fresh.bindings)) == ExactJson.stringify(bundle.scheduler) and ExactJson.stringify(owner.snapshot_state(bundle.scheduler, fresh.bindings)) == ExactJson.stringify(bundle.playback), "fresh pending unit preserves exact actor motion/capture and lease/receipt clock identity")
	var old_hero: WeakRef = weakref(arena.player)
	var old_scheduler: WeakRef = weakref(arena.scheduler)
	var old_playback: WeakRef = weakref(installed.playback)
	# Release only the superseded runtime, never a source/floor transform proxy.
	installed.playback.free()
	arena.scheduler.end_encounter()
	arena.scheduler.free()
	arena.player.free()
	_expect(old_hero.get_ref() == null and old_scheduler.get_ref() == null and old_playback.get_ref() == null, "old actor/scheduler/playback are retired after exact fresh aggregate commit")
	return fresh


func _pending_negatives(arena: Dictionary, playback: Node3D, bundle: Dictionary) -> void:
	var frozen: Dictionary = playback.state()
	var bindings: Dictionary = _bindings(arena, playback)
	for variant: String in ["index", "gap", "stage", "attempt", "time-bit", "phase", "extra", "empty", "schema", "clock-bit"]:
		var forged: Dictionary = bundle.playback.duplicate(true)
		match variant:
			"index": forged.pending_delivery.events[0].event_index = 1
			"gap": forged.pending_delivery.events[1].event_index = 0
			"stage": forged.pending_delivery.events[1].stage = "notify"
			"attempt": forged.opportunities[1].damage_attempted = true
			"time-bit": forged.opportunities[1].dispatch_clock_s = _next_float(float(forged.opportunities[1].dispatch_clock_s))
			"phase": forged.pending_delivery.cue_phases[0] = "recovery"
			"extra": forged.pending_delivery["invented"] = true
			"empty": forged.pending_delivery = {"events": [], "visual_next_cue": 0, "visuals_pending": false, "state_pending": false, "cue_phases": ["active", "lock"]}
			"schema": forged.schema_version = 1
			"clock-bit": forged.clock_s = _next_float(float(forged.clock_s))
		_expect(not playback.restore_state(forged, arena.scheduler, bundle.scheduler, bindings, {"hero": arena.player}) and playback.state() == frozen, "malformed pending " + variant + " rejects before any receipt/cue/actor mutation")


func _arena(wall: bool = false) -> Dictionary:
	var world := Node3D.new()
	world.name = "PlaybackWorld"
	root.add_child(world)
	var floor_body: StaticBody3D = _box(world, Vector3(0, -0.5, 0), Vector3(20, 1, 20))
	floor_body.name = "Floor"
	if wall:
		var wall_body: StaticBody3D = _box(world, Vector3(1.5, 1, 0), Vector3(0.3, 2, 20))
		wall_body.name = "Wall"
	var player: CinderPlayer = Player.new()
	player.name = "Hero"
	world.add_child(player)
	var scheduler = Scheduler.new()
	scheduler.name = "Scheduler"
	world.add_child(scheduler)
	await _ticks(8)
	return {"root": world, "player": player, "scheduler": scheduler, "floor": floor_body.get_child(0), "wall": wall}


func _record(arena: Dictionary, count: int, blast: bool = false, delayed_blast: bool = false) -> Dictionary:
	var capture = Capture.new()
	paused = true
	await process_frame
	_expect(capture.arm(EPOCH, count, 0, arena.player.get_world_action_clock()), "actual capture arms at a stable paused shared-player boundary")
	paused = false
	arena.player.shells = 1 if blast else 0
	var callback: Callable = func(record: Dictionary) -> void:
		capture.ingest(record, EPOCH)
		if record.kind == "dash":
			arena.player.slash(Vector3.RIGHT)
			if blast and not delayed_blast and capture.slots().is_empty() and arena.player.shells > 0:
				arena.player.blast(Vector3.LEFT)
	arena.player.world_action_executed.connect(callback)
	for index: int in range(count):
		if index == 1:
			arena.player.equip_item("WEAPON-03")
			arena.player.shells = 0
		arena.player.request_dash(Vector3.RIGHT if index == 0 else Vector3.LEFT)
		for _tick: int in range(50):
			await _ticks(1)
			if delayed_blast and index == 0 and _tick == 16:
				arena.player.blast(Vector3.LEFT)
			capture.advance(arena.player.get_world_action_clock())
	paused = true
	await process_frame
	capture.advance(arena.player.get_world_action_clock())
	var frozen: Dictionary = capture.snapshot_state()
	arena.player.world_action_executed.disconnect(callback)
	_expect(capture.slots().size() == count, "fixture freezes actual collision-resolved completed combinations")
	var sequence = Sequence.new()
	var authored := {"recognition_s": 0.12, "warning_s": 0.5, "locked_lead_s": 1.1, "inter_echo_gap_s": 0.9, "final_recovery_s": 2.2, "tether_position": arena.player.global_position}
	_expect(sequence.configure("playback/actual", frozen, authored, EPOCH, 1), "actual canonical capture seals an immutable one/two-slot sequence: " + sequence.last_error)
	var fingerprint: Dictionary = arena.scheduler.collision_fingerprint(arena.root)
	paused = false
	if arena.wall:
		# As in the witness fixture, remove the CURRENT live hero from the
		# contact skin using a real new dash; historical route stays untouched.
		arena.player.request_dash(Vector3.LEFT)
		await _ticks(50)
	# Keep the actual live collision body stationary during delivery assertions;
	# isolate replay damage/ammo from ordinary passive reload and hurt-clock ticks.
	arena.player.shells = 0
	arena.player.set_physics_process(false)
	return {"capture": capture, "sequence": sequence.snapshot_state(), "native": sequence.state(), "fingerprint": fingerprint}


func _install(arena: Dictionary, recorded: Dictionary, phase_callback: Callable = Callable()) -> Dictionary:
	var playback = Playback.new()
	playback.name = "Playback"
	arena.root.add_child(playback)
	playback.set_physics_process(false)
	_expect(playback.configure("playback/test", recorded.sequence, EPOCH, 1), "fresh physical consumer configures from exact immutable captured records")
	playback.global_position = recorded.native.authored.tether_position
	arena.scheduler.begin_encounter("standard", "playback/test", 1)
	var response: Dictionary = _response(arena)
	var answer: Dictionary = arena.scheduler.request_replay(playback, recorded.sequence, response, {"world_root": arena.root, "source_epoch": EPOCH, "generation": 1, "capture_collision_fingerprint": recorded.fingerprint})
	_expect(answer.get("accepted", false), "actual scheduler admits one exclusive whole replay witness: " + String(answer.get("reason", "")))
	if not answer.get("accepted", false):
		return {}
	# Parent-owned atomic custody step. Playback has no capture reference and
	# does not itself authenticate whether another owner retired these slots.
	var retired: int = 0
	while not recorded.capture.take_next().is_empty():
		retired += 1
	_expect(retired == recorded.native.timeline.slots.size() and recorded.capture.slots().is_empty() and recorded.capture.take_next().is_empty(), "parent transfers every sealed slot exactly once before exposing playback bind")
	_expect(not playback.bind(arena.scheduler, answer.reservation_id, {"hero": arena.player, "alias": arena.player}), "one-player consumer rejects duplicate alias bindings")
	if phase_callback.is_valid():
		playback.get_cues()[0].state_changed.connect(phase_callback)
	_expect(playback.bind(arena.scheduler, answer.reservation_id, {"hero": arena.player}), "unarmed lease binds exactly its proved actual shared player")
	return {"playback": playback, "id": answer.reservation_id, "sequence": recorded.sequence, "native": recorded.native, "source_position": playback.global_position, "lease": arena.scheduler.replay_reservation_state(answer.reservation_id)}


func _lock(arena: Dictionary, installed: Dictionary) -> void:
	await _until(arena.scheduler, float(installed.lease.lock_from_s))
	var answer: Dictionary = arena.scheduler.commit_replay(installed.id, _response(arena))
	_expect(answer.get("accepted", false), "actual lock receives a fresh complete whole-sequence proof: " + String(answer.get("reason", "")))
	installed.lease = arena.scheduler.replay_reservation_state(installed.id)
	var advanced: Dictionary = installed.playback.advance()
	_expect(advanced.accepted, "consumer synchronizes exact actual lock without request, reproof or retiming: " + String(advanced.get("reason", "")))


func _response(arena: Dictionary) -> Dictionary:
	var response: Dictionary = arena.player.get_threat_response_state()
	response.merge({"world_revision": 1, "recognition_s": 0.12, "attack_input_margin_s": 0.02, "escape_directions": _directions(), "return_directions": _directions(), "floor_regions": [{"collision": arena.floor, "safe_rect": Rect2(-10, -10, 20, 20)}]})
	return response


func _bindings(arena: Dictionary, playback: Node3D) -> Dictionary:
	return {"world_root": arena.root, "owners": {"source": playback}, "actors": {"hero": arena.player}, "floors": {"floor": {"collision": arena.floor, "safe_rect": Rect2(-10, -10, 20, 20)}}}


func _directions() -> Array[Vector3]:
	return [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK, Vector3(-1, 0, -1).normalized(), Vector3(-1, 0, 1).normalized(), Vector3(1, 0, -1).normalized(), Vector3(1, 0, 1).normalized()]


func _until(scheduler: Node3D, clock_s: float) -> void:
	for _tick: int in range(900):
		if scheduler.get_clock() >= clock_s:
			return
		await _ticks(1)
	_expect(false, "bounded fixture reaches its requested simulation deadline")


func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame


func _box(parent: Node3D, position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.name = "Shape"
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	body.position = position
	return body


func _collider_count(node: Node) -> int:
	var count: int = 1 if node is CollisionObject3D or node is CollisionShape3D or node is CollisionPolygon3D else 0
	for child: Node in node.get_children():
		count += _collider_count(child)
	return count


func _json(value: Dictionary) -> Dictionary:
	var text: String = ExactJson.stringify(value)
	var result: Dictionary = ExactJson.parse(text)
	_expect(not text.is_empty() and result.accepted and result.value is Dictionary and ExactJson.stringify(result.value) == text, "paired exact tagged JSON preserves every finite scalar bit and native type")
	return result.value if result.accepted and result.value is Dictionary else {}


func _next_float(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes.encode_u64(0, bytes.decode_u64(0) + 1)
	return bytes.decode_double(0)


func _dispose(arena: Dictionary) -> void:
	paused = false
	arena.root.queue_free()
	await process_frame


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
