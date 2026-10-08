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
const EPOCH: String = "replay/playback"
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


func _install(arena: Dictionary, recorded: Dictionary) -> Dictionary:
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
