extends SceneTree
## Native consumer fixture. Records come only from real shared Player actions.
## The original selector intentionally exposes the ordinary, unclipped meshes.
const Player = preload("res://scripts/player.gd")
const Capture = preload("res://scripts/combat/action_capture.gd")
const Sequence = preload("res://scripts/combat/replay_sequence.gd")
const Playback = preload("res://scripts/combat/replay_playback.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Footprint = preload("res://scripts/combat/replay_footprint.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const CueMesh = preload("res://scripts/cues/cue_mesh.gd")
const EPOCH: String = "projected/actual"
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
var _binding_rejections_checked: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if "--original-warning" in OS.get_cmdline_user_args():
		await _original_warning()
	else:
		await _projected_phases()
		await _contacts()
		await _held_phases()
		await _held_restore()
		await _forgeries()
		await _lost_meshes()
	print("Projected replay smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _original_warning() -> void:
	var arena: Dictionary = await _arena()
	var recorded: Dictionary = await _record(arena)
	var installed: Dictionary = _install(arena, recorded, false)
	if installed.is_empty():
		await _dispose(arena)
		return
	var cue: Node3D = installed.playback.get_cues()[0]
	var outline: MeshInstance3D = cue.get_node("RequiredFootprintOutline")
	var fill: MeshInstance3D = cue.get_node("RequiredFootprintFill")
	var record: Dictionary = recorded.native.timeline.slots[0].events[0].record
	_expect(cue.state().phase == "warning" and outline.is_visible_in_tree() and not fill.is_visible_in_tree(), "original actual bound owner presents visible warning outline and retains its future active fill")
	var hole_fill: bool = _native_intersects_rect(fill, arena.hole)
	var shadow_fill: bool = _native_covers(fill, record.world_origin + Vector3(1.5, 0, 1.0))
	var blocked_outline: int = _blocked_vertices(outline, arena, record)
	print("ORIGINAL native warning: hole_fill=%s shadow_fill=%s blocked_visible_outline_vertices=%d" % [hole_fill, shadow_fill, blocked_outline])
	_expect(not hole_fill, "required recorded warning/future-active native fill must exclude the actual physical floor hole")
	_expect(not shadow_fill, "required recorded warning/future-active native fill must exclude the wall's full native LOS shadow")
	_expect(blocked_outline == 0, "visible warning outline must not extend into scenery-blocked floor")
	var projected: Dictionary = Footprint.plan(arena.scheduler, recorded.sequence, arena.world, arena.floors, arena.context)
	_expect(projected.get("accepted", false), "same actual recorded sequence/world has a supported clipped projection: " + str(projected.get("reason", "")))
	await _lock(arena, installed)
	var active_seen: Array[bool] = []
	cue.state_changed.connect(func(value: Dictionary) -> void:
		if value.phase == "active":
			active_seen.append(true)
			_expect(not _native_intersects_rect(fill, arena.hole), "actual original active callback still exposes the missing physical-hole clipping")
			_expect(not _native_covers(fill, record.world_origin + Vector3(1.5, 0, 1.0)), "actual original active callback still exposes the missing native wall-shadow clipping")
			paused = true
	)
	var at_s: float = float(installed.lease.adapter.timeline_origin_s) + float(recorded.native.timeline.slots[0].events[0].at_s)
	await _until(arena.scheduler, at_s)
	installed.playback.advance()
	await process_frame
	_expect(active_seen == [true] and paused, "original regression reaches the actual active event callback once without fabricated actions or missing-API assertions")
	await _dispose(arena)


func _projected_phases() -> void:
	var arena: Dictionary = await _arena()
	var recorded: Dictionary = await _record(arena, true)
	var installed: Dictionary = _install(arena, recorded, true)
	if installed.is_empty():
		await _dispose(arena)
		return
	var playback: Node3D = installed.playback
	var projection: Dictionary = playback.call("get_footprint_projection")
	_expect(ExactJson.stringify(projection) == ExactJson.stringify(installed.projection), "bound owner retains the exact independently authenticated projection")
	var copy: Dictionary = projection.duplicate(true)
	copy.events[0].triangle_vertices[0][0] += 0.01
	_expect(ExactJson.stringify(playback.call("get_footprint_projection")) == ExactJson.stringify(projection), "projection getter never grants mutable renderer/collision custody")
	_check_native(playback.get_cues()[0], projection.events[0], "warning", arena)
	_expect(_has_physical_hole_edge(projection.events[0], arena.hole), "actual clipped contour retains physical-hole boundary where the hole opens onto the recorded cone edge")
	await _lock(arena, installed)
	_check_native(playback.get_cues()[0], projection.events[0], "lock", arena)
	var raw: Dictionary = recorded.native.timeline.slots[0].events[0].record
	arena.player.global_position = raw.world_origin + Vector3.RIGHT * 0.2
	var hp: float = arena.player.hp
	var ammo: int = arena.player.shells
	var history: Array = arena.player.get_world_action_records()
	var active: Array[String] = []
	for index: int in range(playback.get_cues().size()):
		var event_index: int = index
		playback.get_cues()[index].state_changed.connect(func(value: Dictionary) -> void:
			if value.phase == "active":
				active.append(projection.events[event_index].event_id)
				_check_native(playback.get_cues()[event_index], projection.events[event_index], "active", arena)
		)
	await _until(arena.scheduler, _event_clock(installed, 0))
	var delivery: Dictionary = playback.advance()
	_expect(delivery.accepted and active.size() == 2 and playback.state().opportunities.size() == 2, "real equal-time primary/blast consume original ordered events and expose clipped active meshes")
	_expect(arena.player.hp == hp - float(raw.damage) and arena.player.shells == ammo and ammo == 0 and arena.player.get_world_action_records() == history, "ordinary recorded primary damages once with current empty ammo and no proc/history/ammo mutation")
	for index: int in range(playback.get_cues().size()):
		_check_native(playback.get_cues()[index], projection.events[index], "recovery", arena)
	paused = true
	await process_frame
	var bundle: Dictionary = _bundle(arena, installed)
	_expect(bundle.playback.get("schema_version") == 3 and not bundle.playback.has("pending_delivery"), "fully drained projected owner stores schema3 without inventing pending callbacks")
	var fresh: Dictionary = _fresh(arena, recorded, bundle)
	if not fresh.is_empty():
		_expect(_native_state(fresh.playback) == bundle.native and fresh.events.is_empty(), "quiet completed-event restore reproduces clipped native meshes and no damage/event callback")
		_expect(fresh.player.hp == float(bundle.actor.resources.hp) and fresh.player.shells == int(bundle.actor.resources.shells) and ExactJson.stringify(fresh.player.snapshot_state()) == ExactJson.stringify(bundle.actor), "projected save carries no duplicate resources or regenerated capture history")
		paused = false
		fresh.playback.advance()
		_expect(fresh.events.is_empty() and fresh.player.hp == float(bundle.actor.resources.hp), "equal-clock completed-event restore cannot redeliver a recorded hit")
	await _dispose(arena)


func _has_physical_hole_edge(event: Dictionary, hole: Rect2) -> bool:
	# The native ring's hole intersects the original cone boundary, so its
	# clipped boundary is an outer indentation rather than a closed inner loop.
	# Compare actual encoded edge locations; this display check does not tune
	# production contact, projection validation or native collision tolerances.
	var epsilon: float = 0.00001
	for contour: Dictionary in event.boundary_contours:
		for index: int in range(contour.vertices.size() - 1):
			var a: Array = contour.vertices[index]
			var b: Array = contour.vertices[index + 1]
			for x: float in [hole.position.x, hole.end.x]:
				if absf(float(a[0]) - x) <= epsilon and absf(float(b[0]) - x) <= epsilon and minf(float(a[2]), float(b[2])) < hole.end.y - epsilon and maxf(float(a[2]), float(b[2])) > hole.position.y + epsilon and absf(float(a[2]) - float(b[2])) > epsilon:
					return true
			for z: float in [hole.position.y, hole.end.y]:
				if absf(float(a[2]) - z) <= epsilon and absf(float(b[2]) - z) <= epsilon and minf(float(a[0]), float(b[0])) < hole.end.x - epsilon and maxf(float(a[0]), float(b[0])) > hole.position.x + epsilon and absf(float(a[0]) - float(b[0])) > epsilon:
					return true
	return false


func _contacts() -> void:
	for label: String in ["open", "disk", "cone", "range", "vertical", "shadow", "hole", "blast", "fall"]:
		var arena: Dictionary = await _arena()
		var recorded: Dictionary = await _record(arena, label == "blast")
		var installed: Dictionary = _install(arena, recorded, true)
		if installed.is_empty():
			await _dispose(arena)
			continue
		await _lock(arena, installed)
		var raw: Dictionary = recorded.native.timeline.slots[0].events[0].record
		var target: Vector3 = raw.world_origin + Vector3.RIGHT * 0.2
		match label:
			"disk": target = raw.world_origin - Vector3.RIGHT * float(raw.geometry.origin_disk_radius) * 0.5
			"cone", "blast": target = raw.world_origin + Vector3.LEFT * 0.6
			"range": target = raw.world_origin + Vector3.RIGHT * (float(raw.geometry.reach) + 0.2)
			"vertical": target = raw.world_origin + Vector3.UP * (float(raw.geometry.max_vertical_distance) + 0.2)
			"shadow": target = raw.world_origin + Vector3(1.5, 0, 1.0)
			"hole", "fall": target = Vector3(arena.hole.get_center().x, raw.world_origin.y, arena.hole.get_center().y)
		# Explicit live-contact fixture arrangement; never modifies a recorded sample.
		arena.player.global_position = target
		if label in ["shadow", "hole"]:
			_expect(_canonical_geometry(raw, target), label + " control lies inside unchanged recorded range/cone/height")
			var ray: bool = _los_clear(arena, raw, target)
			_expect(ray == (label == "hole"), label + " control observes actual scenery LOS separately from floor membership")
		if label == "fall":
			await _until(arena.scheduler, _event_clock(installed, 0) - 0.08)
			var initial_ammo: int = arena.player.shells
			var initial_actor_clock: float = arena.player.get_world_action_clock()
			arena.player.set_physics_process(true)
			await _ticks(4)
			arena.player.set_physics_process(false)
			target = arena.player.global_position
			print("FALL_NATIVE_RELOAD: ", ExactJson.stringify({"initial_ammo": initial_ammo, "post_gravity_ammo": arena.player.shells, "actor_clock_before": initial_actor_clock, "actor_clock_after": arena.player.get_world_action_clock(), "scheduler_clock": arena.scheduler.get_clock()}))
			_expect(not arena.player.is_on_floor() and arena.player.velocity.y < 0.0 and target.y < -0.02 and _canonical_geometry(raw, target) and _los_clear(arena, raw, target), "actual gravity over the physical hole produces a below-floor native contact inside original cone/height/LOS")
		var hp: float = arena.player.hp
		var ammo: int = arena.player.shells
		var history: Array = arena.player.get_world_action_records()
		var calls: Array[String] = []
		installed.playback.event_dispatched.connect(func(event: Dictionary, _receipt: Dictionary) -> void: calls.append(event.kind))
		await _until(arena.scheduler, _event_clock(installed, 0))
		var delivery: Dictionary = installed.playback.advance()
		var receipts: Array = installed.playback.state().opportunities
		var hit: bool = label in ["open", "disk"]
		_expect(delivery.accepted and not receipts.is_empty() and receipts[0].contact == hit and receipts[0].damage_attempted == hit, label + " preserves original instantaneous geometry/native LOS and adds only authenticated floor membership: " + str(delivery.get("reason", "")))
		if label == "blast":
			var blast_raw: Dictionary = recorded.native.timeline.slots[0].events[1].record
			_expect(receipts.size() == 2 and not receipts[0].contact and receipts[1].contact and receipts[1].damage_attempted and arena.player.hp == hp - float(blast_raw.damage), "independently left-aimed actual recorded blast retains its original one contact with live ammo zero")
		else:
			_expect(arena.player.hp == hp - (float(raw.damage) if hit else 0.0), label + " live HP records exactly the original accepted or missed primary opportunity")
		_expect(arena.player.shells == ammo and (label == "fall" or ammo == 0) and arena.player.get_world_action_records() == history, label + " replay preserves actual current ammo/history; other contact controls remain empty-ammo")
		installed.playback.advance()
		_expect(calls.size() == (2 if label == "blast" else 1), label + " equal-clock advance never repeats an original notification")
		await _dispose(arena)


func _held_restore() -> void:
	var arena: Dictionary = await _arena()
	var recorded: Dictionary = await _record(arena, true)
	var installed: Dictionary = _install(arena, recorded, true)
	if installed.is_empty():
		await _dispose(arena)
		return
	await _lock(arena, installed)
	var raw: Dictionary = recorded.native.timeline.slots[0].events[0].record
	arena.player.global_position = raw.world_origin + Vector3.LEFT * 0.3
	var held: Array[bool] = [false]
	var nested: Array[Dictionary] = []
	installed.playback.get_cues()[0].state_changed.connect(func(value: Dictionary) -> void:
		if value.phase == "active" and not held[0]:
			held[0] = true
			nested.append(installed.playback.advance())
			arena.player.request_dash(Vector3.RIGHT)
			paused = true
	)
	await _until(arena.scheduler, _event_clock(installed, 0))
	installed.playback.advance()
	await process_frame
	var bundle: Dictionary = _bundle(arena, installed)
	if bundle.playback.is_empty():
		await _dispose(arena)
		return
	_expect(bundle.playback.schema_version == 3 and bundle.playback.pending_delivery.events == [{"event_index": 0, "stage": "damage"}, {"event_index": 1, "stage": "present"}] and not bundle.playback.opportunities[0].contact and bundle.playback.opportunities[1].contact and not bundle.playback.opportunities[1].damage_attempted, "held active callback stores the complete original batch, exact delivery stage and independently sampled blast contact in schema3")
	_expect(nested.size() == 1 and not nested[0].accepted and arena.player.get_committed_dash_state().active, "clipped active observer cannot recurse and retains a genuine unfinished player dash")
	var fresh: Dictionary = _fresh(arena, recorded, bundle)
	if fresh.is_empty():
		await _dispose(arena)
		return
	var once: Array[bool] = [false]
	fresh.playback.event_dispatched.connect(func(_event: Dictionary, _receipt: Dictionary) -> void:
		if not once[0]:
			once[0] = true
			paused = true
	)
	var before: Vector3 = fresh.player.global_position
	await _resume_tick(fresh.playback)
	_expect(paused and fresh.events == ["primary"] and fresh.player.global_position != before and fresh.player.get_committed_dash_state().active, "first resumed real physics tick moves the restored actor and stops after exactly the original primary notification")
	await process_frame
	var next_installed: Dictionary = installed.duplicate()
	next_installed.playback = fresh.playback
	var event_bundle: Dictionary = _bundle(fresh, next_installed)
	_expect(event_bundle.playback.pending_delivery.events == [{"event_index": 1, "stage": "present"}] and fresh.playback.state().visual_pose.action == "primary", "popped first event preserves actual primary pose and clipped partial cue history before the untouched blast presentation")
	var second: Dictionary = _fresh(fresh, recorded, event_bundle)
	if second.is_empty():
		await _dispose(arena)
		return
	var second_held: Array[bool] = [false]
	second.playback.get_cues()[1].state_changed.connect(func(value: Dictionary) -> void:
		if value.phase == "active" and not second_held[0]:
			second_held[0] = true
			paused = true
	)
	await _resume_tick(second.playback)
	_expect(paused and second.player.global_position.x > raw.world_origin.x + float(raw.geometry.origin_disk_radius), "second real restored dash tick leaves the original left-blast cone and disk without changing its saved contact")
	await process_frame
	next_installed.playback = second.playback
	var final_bundle: Dictionary = _bundle(second, next_installed)
	_expect(final_bundle.playback.opportunities[1].contact and not final_bundle.playback.opportunities[1].damage_attempted and final_bundle.playback.pending_delivery.events == [{"event_index": 1, "stage": "damage"}], "held clipped blast retains original contact and exact damage stage instead of resampling current actor")
	var native_before: Dictionary = _native_state(second.playback)
	_expect(second.playback.call("restore_state", final_bundle.playback, second.scheduler, final_bundle.scheduler, second.bindings, {"hero": second.player}, second.floors, second.context) and _native_state(second.playback) == native_before and second.events.is_empty(), "idempotent paused exact restore never emits/represents a consumed clipped cue/event")
	var hp: float = second.player.hp
	paused = false
	second.playback.advance()
	var delivered: Array = second.playback.state().opportunities
	_expect(second.events == ["blast"] and delivered[1].contact and delivered[1].damage_attempted and second.player.hp == hp, "saved original contact has exactly one damage attempt; actual dash invulnerability truthfully prevents current HP loss")
	for index: int in range(2):
		_expect(delivered[index].scheduled_at_s == bundle.playback.opportunities[index].scheduled_at_s and delivered[index].dispatch_clock_s == bundle.playback.opportunities[index].dispatch_clock_s, "held event " + str(index) + " keeps exact original scheduled and dispatch clocks through fresh restores")
	second.playback.advance()
	_expect(second.events == ["blast"] and second.player.hp == hp, "drained equal-clock clipped delivery cannot duplicate an event or HP opportunity")
	paused = true
	await process_frame
	next_installed.playback = second.playback
	var drained: Dictionary = _bundle(second, next_installed)
	_expect(drained.playback.get("schema_version") == 3 and not drained.playback.has("pending_delivery"), "drained projected owner retains schema3 and removes only the exhausted pending field")
	await _dispose(arena)


func _held_phases() -> void:
	for phase: String in ["warning", "lock"]:
		var arena: Dictionary = await _arena()
		var recorded: Dictionary = await _record(arena, true)
		var held: Array[bool] = [false]
		var callback: Callable = func(value: Dictionary) -> void:
			if value.phase == phase and not held[0]:
				held[0] = true
				paused = true
		var installed: Dictionary = _install(arena, recorded, true, callback)
		if installed.is_empty():
			await _dispose(arena)
			continue
		if phase == "lock":
			await _lock(arena, installed)
		await process_frame
		var bundle: Dictionary = _bundle(arena, installed)
		if bundle.playback.is_empty():
			await _dispose(arena)
			continue
		_expect(paused and held[0] and bundle.playback.schema_version == 3 and bundle.playback.pending_delivery.events.is_empty() and bundle.playback.pending_delivery.cue_phases == (["warning", "clear"] if phase == "warning" else ["lock", "warning"]), "partial clipped " + phase + " persists only the native presented prefix and untouched original suffix")
		var fresh: Dictionary = _fresh(arena, recorded, bundle)
		if fresh.is_empty():
			await _dispose(arena)
			continue
		_expect(fresh.playback.get_cues()[0].state().phase == phase and fresh.playback.get_cues()[1].state().phase == ("clear" if phase == "warning" else "warning"), "quiet fresh schema3 restore preserves genuinely partial " + phase + " native meshes/phases")
		paused = false
		fresh.playback.advance()
		_expect(fresh.events.is_empty() and fresh.playback.state().get("pending_delivery", {}).is_empty(), "resume finishes partial " + phase + " cues without dispatching an attack or refreshing geometry")
		paused = true
		await process_frame
		installed.playback = fresh.playback
		var drained: Dictionary = _bundle(fresh, installed)
		_expect(drained.playback.get("schema_version") == 3 and not drained.playback.has("pending_delivery"), "finished " + phase + " keeps immutable projected mode with no fictitious pending field")
		await _dispose(arena)


func _forgeries() -> void:
	var arena: Dictionary = await _arena()
	var recorded: Dictionary = await _record(arena, true)
	var installed: Dictionary = _install(arena, recorded, true)
	if installed.is_empty():
		await _dispose(arena)
		return
	paused = true
	await process_frame
	var bundle: Dictionary = _bundle(arena, installed)
	if bundle.playback.is_empty():
		await _dispose(arena)
		return
	var owner: Node3D = installed.playback
	var frozen: Dictionary = owner.state()
	var actor_wire: String = ExactJson.stringify(arena.player.snapshot_state())
	var schedule_wire: String = ExactJson.stringify(arena.scheduler.snapshot_state(_bindings(arena, owner)))
	for label: String in ["event_id", "record", "order", "triangle", "contour", "floor", "collision", "version", "downgrade"]:
		var forged: Dictionary = bundle.playback.duplicate(true)
		match label:
			"event_id": forged.projection.events[0].event_id += "/forged"
			"record": forged.projection.events[0].record.damage += 1.0
			"order": forged.projection.events.reverse()
			"triangle": forged.projection.events[0].triangle_vertices[0][0] = _one_bit(float(forged.projection.events[0].triangle_vertices[0][0]))
			"contour": forged.projection.events[0].boundary_contours[0].vertices[0][0] = _one_bit(float(forged.projection.events[0].boundary_contours[0].vertices[0][0]))
			"floor": forged.projection.floor_signature[0].safe_rect[0] = _one_bit(float(forged.projection.floor_signature[0].safe_rect[0]))
			"collision": forged.projection.collision_fingerprint.colliders[0].priority = _one_bit(float(forged.projection.collision_fingerprint.colliders[0].priority))
			"version": forged.projection.schema_version += 1
			"downgrade":
				forged.schema_version = 1
				forged.erase("projection")
		var error: String = owner.call("snapshot_error", forged, arena.scheduler, bundle.scheduler, _bindings(arena, owner), {"hero": arena.player}, arena.floors, arena.context)
		_expect(not error.is_empty(), label + " forged projected unit rejects before any aggregate mutation")
		_expect(not owner.call("restore_state", forged, arena.scheduler, bundle.scheduler, _bindings(arena, owner), {"hero": arena.player}, arena.floors, arena.context) and owner.state() == frozen and ExactJson.stringify(arena.player.snapshot_state()) == actor_wire and ExactJson.stringify(arena.scheduler.snapshot_state(_bindings(arena, owner))) == schedule_wire, label + " restore rejection is atomic for owner/actor/scheduler state")
	for label: String in ["context_floor", "context_collision", "context_generation", "safe_rect", "scene"]:
		var context: Dictionary = arena.context.duplicate(true)
		var floors: Array = arena.floors.duplicate(true)
		var body: StaticBody3D = arena.floors[0].collision.get_parent()
		var priority: float = body.collision_priority
		match label:
			"context_floor": context.capture_floor_signature[0].safe_rect[0] = _one_bit(float(context.capture_floor_signature[0].safe_rect[0]))
			"context_collision": context.capture_collision_fingerprint.colliders[0].priority = _one_bit(float(context.capture_collision_fingerprint.colliders[0].priority))
			"context_generation": context.generation += 1
			"safe_rect": floors[0].safe_rect = Rect2(-10, -10, 12, 20)
			"scene": body.collision_priority = _one_bit32(priority)
		var error: String = owner.call("snapshot_error", bundle.playback, arena.scheduler, bundle.scheduler, _bindings(arena, owner), {"hero": arena.player}, floors, context)
		_expect(not error.is_empty() and owner.state() == frozen and ExactJson.stringify(arena.player.snapshot_state()) == actor_wire, label + " original-arm/current-native guard mismatch rejects purely")
		body.collision_priority = priority
	_expect(String(owner.call("snapshot_error", bundle.playback, arena.scheduler, bundle.scheduler, _bindings(arena, owner), {"hero": arena.player}, arena.floors, arena.context)).is_empty(), "restoring exactly the original immutable world/floor guard restores valid pure validation")
	_expect(not owner.bind(arena.scheduler, installed.id, {"hero": arena.player}) and owner.state() == frozen, "already projected owner cannot downgrade through the ordinary bind API")
	await _dispose(arena)


func _lost_meshes() -> void:
	for label: String in ["lost", "hidden", "replacement", "surface", "transform", "source"]:
		var arena: Dictionary = await _arena()
		var recorded: Dictionary = await _record(arena)
		var installed: Dictionary = _install(arena, recorded, true)
		if installed.is_empty():
			await _dispose(arena)
			continue
		paused = true
		await process_frame
		var bundle: Dictionary = _bundle(arena, installed)
		var owner: Node3D = installed.playback
		var cue: Node3D = owner.get_cues()[0]
		var fill: MeshInstance3D = cue.get_node("RequiredFootprintFill")
		var outline: MeshInstance3D = cue.get_node("RequiredFootprintOutline")
		var calls: Array[String] = []
		owner.event_dispatched.connect(func(event: Dictionary, _receipt: Dictionary) -> void: calls.append(event.kind))
		var hp: float = arena.player.hp
		match label:
			"lost": fill.free()
			"hidden": outline.hide()
			"replacement": fill.mesh = fill.mesh.duplicate()
			"surface": (fill.mesh as ArrayMesh).clear_surfaces()
			"transform": fill.position.x += 0.001
			"source": (cue.get_node("RequiredSourceMarker") as MeshInstance3D).hide()
		var frozen: Dictionary = owner.state()
		_expect(owner.snapshot_state(bundle.scheduler, _bindings(arena, owner)).is_empty() and not owner.call("restore_state", bundle.playback, arena.scheduler, bundle.scheduler, _bindings(arena, owner), {"hero": arena.player}, arena.floors, arena.context) and owner.state() == frozen and calls.is_empty() and arena.player.hp == hp, label + " lost native projected renderer cannot heal itself through paused capture or restore")
		paused = false
		var answer: Dictionary = owner.advance()
		_expect(not answer.accepted and owner.state().status == "cancelled" and owner.state().cursor.next_event_index == 0 and calls.is_empty() and arena.player.hp == hp, label + " native binding failure visibly cancels before any original attack opportunity")
		await _dispose(arena)


func _arena() -> Dictionary:
	paused = false
	var world := Node3D.new()
	world.name = "ProjectedWorld"
	root.add_child(world)
	var player: CinderPlayer = Player.new()
	player.name = "Hero"
	world.add_child(player)
	var d: float = float(player.get_threat_response_state().stats.dash_distance)
	var edge: float = ceilf(d * 4.0) / 4.0 + 0.5
	var hole := Rect2(edge, -1.0, 0.8, 0.7)
	var floors: Array = []
	floors.append(_region(_box(world, "FloorLeft", Vector3((edge - 10) * 0.5, -0.5, 0), Vector3(edge + 10, 1, 20))))
	floors.append(_region(_box(world, "FloorRight", Vector3((edge + 0.8 + 10) * 0.5, -0.5, 0), Vector3(10 - edge - 0.8, 1, 20))))
	floors.append(_region(_box(world, "FloorTop", Vector3(edge + 0.4, -0.5, 4.85), Vector3(0.8, 1, 10.3))))
	floors.append(_region(_box(world, "FloorBottom", Vector3(edge + 0.4, -0.5, -5.5), Vector3(0.8, 1, 9))))
	var wall: StaticBody3D = _box(world, "Wall", Vector3(d + 0.8, 1, 0.65), Vector3(0.25, 3, 0.5))
	var scheduler = Scheduler.new()
	scheduler.name = "Scheduler"
	world.add_child(scheduler)
	await _ticks(8)
	return {"world": world, "player": player, "scheduler": scheduler, "floors": floors, "hole": hole, "wall": wall}


func _record(arena: Dictionary, blast: bool = false) -> Dictionary:
	paused = true
	await process_frame
	var capture = Capture.new()
	_expect(capture.arm(EPOCH, 1, 0, arena.player.get_world_action_clock()), "capture arms at real paused shared-player boundary")
	var signature: Dictionary = Footprint.floor_signature(arena.world, arena.floors)
	_expect(signature.get("accepted", false), "actual immutable four-Box floor ring has a supported capture signature")
	arena.context = {"source_epoch": EPOCH, "generation": 1, "capture_collision_fingerprint": arena.scheduler.pure_collision_fingerprint(arena.world), "capture_floor_signature": signature.get("signature", [])}
	arena.player.shells = 1 if blast else 0 # Explicit isolated fixture supply, not replay consumption.
	var callback: Callable = func(record: Dictionary) -> void:
		_expect(capture.ingest(record, EPOCH), "capture ingests actual contiguous " + record.kind)
		if record.kind == "dash":
			arena.player.slash(Vector3.RIGHT)
			if blast:
				arena.player.blast(Vector3.LEFT)
	arena.player.world_action_executed.connect(callback)
	paused = false
	arena.player.request_dash(Vector3.RIGHT)
	for _tick: int in range(65):
		await _ticks(1)
		capture.advance(arena.player.get_world_action_clock())
	paused = true
	await process_frame
	capture.advance(arena.player.get_world_action_clock())
	arena.player.world_action_executed.disconnect(callback)
	_expect(capture.slots().size() == 1 and capture.snapshot_state().pending.is_empty(), "completed native dash and real primary seal exactly one immutable slot")
	var sequence = Sequence.new()
	_expect(sequence.configure("projected/sequence", capture.snapshot_state(), {"recognition_s": 0.12, "warning_s": 0.5, "locked_lead_s": 1.1, "inter_echo_gap_s": 0.9, "final_recovery_s": 2.2, "tether_position": arena.player.global_position}, EPOCH, 1), "sealed Sequence derives its unchanged original event order/deadlines: " + sequence.last_error)
	_expect(arena.context.capture_collision_fingerprint == arena.scheduler.pure_collision_fingerprint(arena.world), "original capture and present admission use exactly the same real scenery")
	arena.player.shells = 0
	# Contact controls later arrange this same actual body; history is immutable.
	arena.player.set_physics_process(false)
	paused = false
	return {"capture": capture, "sequence": sequence.snapshot_state(), "native": sequence.state()}


func _install(arena: Dictionary, recorded: Dictionary, projected: bool, phase_callback: Callable = Callable()) -> Dictionary:
	var playback = Playback.new()
	playback.name = "Playback"
	arena.world.add_child(playback)
	playback.set_physics_process(false)
	_expect(playback.configure("projected/owner", recorded.sequence, EPOCH, 1), "actual Playback configures exact sealed Sequence")
	playback.global_position = recorded.native.authored.tether_position
	_expect(arena.scheduler.begin_encounter("standard", "projected/encounter", 1), "real Scheduler starts the shared Standard profile")
	var context := {"world_root": arena.world, "source_epoch": EPOCH, "generation": 1, "capture_collision_fingerprint": arena.context.capture_collision_fingerprint}
	var answer: Dictionary = arena.scheduler.request_replay(playback, recorded.sequence, _response(arena), context)
	_expect(answer.get("accepted", false), "actual complete-union full-cone witness admits the native ring/wall world: " + str(answer.get("reason", "")))
	if not answer.get("accepted", false):
		return {}
	var projection: Dictionary = {}
	var accepted: bool
	if phase_callback.is_valid():
		playback.get_cues()[0].state_changed.connect(phase_callback)
	if projected:
		projection = Footprint.plan(arena.scheduler, recorded.sequence, arena.world, arena.floors, arena.context)
		if projection.get("accepted", false) and not _binding_rejections_checked:
			_binding_rejections_checked = true
			var cap_before: Dictionary = recorded.capture.snapshot_state()
			var owner_before: Dictionary = playback.state()
			var actor_before: Array = [arena.player.hp, arena.player.shells, arena.player.global_position, arena.player.velocity, arena.player.get_world_action_clock()]
			var notifications: Array[String] = []
			playback.state_changed.connect(func(_value: Dictionary) -> void: notifications.append("owner"))
			for cue: Node3D in playback.get_cues():
				cue.state_changed.connect(func(_value: Dictionary) -> void: notifications.append("cue"))
			var forged: Dictionary = projection.duplicate(true)
			var last: int = forged.events.size() - 1
			forged.events[last].triangle_vertices[0][0] = _one_bit(float(forged.events[last].triangle_vertices[0][0]))
			for bad: Dictionary in [{}, forged]:
				_expect(not playback.call("bind_projected", arena.scheduler, answer.reservation_id, {"hero": arena.player}, arena.floors, bad, arena.context) and playback.state() == owner_before and playback.call("get_footprint_projection").is_empty() and notifications.is_empty(), "empty or altered later-event projection rejects before any native owner/cue publication")
				_expect(recorded.capture.snapshot_state() == cap_before and [arena.player.hp, arena.player.shells, arena.player.global_position, arena.player.velocity, arena.player.get_world_action_clock()] == actor_before and playback.get_cues().all(func(cue: Node3D) -> bool: return cue.call("projection_state").is_empty()), "rejected projected binding consumes no parent capture or actor state and leaves no partial cue binding")
	var retired: Dictionary = recorded.capture.take_next()
	_expect(not retired.is_empty() and recorded.capture.take_next().is_empty(), "fixture parent retires its one original current sealed slot once before bind")
	if projected:
		accepted = playback.call("bind_projected", arena.scheduler, answer.reservation_id, {"hero": arena.player}, arena.floors, projection, arena.context)
	else:
		accepted = playback.bind(arena.scheduler, answer.reservation_id, {"hero": arena.player})
	_expect(accepted, "actual consumer binds exactly its admitted player/lease: " + playback.last_error)
	if not accepted:
		return {}
	return {"playback": playback, "id": answer.reservation_id, "lease": arena.scheduler.replay_reservation_state(answer.reservation_id), "projection": projection, "recorded": recorded}


func _lock(arena: Dictionary, installed: Dictionary) -> void:
	await _until(arena.scheduler, float(installed.lease.lock_from_s))
	var answer: Dictionary = arena.scheduler.commit_replay(installed.id, _response(arena))
	_expect(answer.get("accepted", false), "actual lock freshly reproves original full-cone complete union: " + str(answer.get("reason", "")))
	installed.lease = arena.scheduler.replay_reservation_state(installed.id)
	_expect(installed.playback.advance().accepted, "consumer observes exact real immutable lock deadlines")


func _response(arena: Dictionary) -> Dictionary:
	var response: Dictionary = arena.player.get_threat_response_state()
	response.merge({"world_revision": 1, "recognition_s": 0.12, "attack_input_margin_s": 0.02, "escape_directions": [Vector3.LEFT, Vector3.BACK], "return_directions": [Vector3.RIGHT, Vector3.FORWARD], "floor_regions": arena.floors})
	return response


func _event_clock(installed: Dictionary, index: int) -> float:
	return float(installed.lease.adapter.timeline_origin_s) + float(installed.recorded.native.timeline.slots[0].events[index].at_s)


func _bindings(arena: Dictionary, playback: Node3D) -> Dictionary:
	var floors: Dictionary = {}
	for index: int in range(arena.floors.size()):
		floors["floor-%d" % index] = arena.floors[index]
	return {"world_root": arena.world, "owners": {"source": playback}, "actors": {"hero": arena.player}, "floors": floors}


func _bundle(arena: Dictionary, installed: Dictionary) -> Dictionary:
	var bindings: Dictionary = _bindings(arena, installed.playback)
	var schedule: Dictionary = arena.scheduler.snapshot_state(bindings)
	var saved: Dictionary = installed.playback.snapshot_state(schedule, bindings)
	var actor: Dictionary = arena.player.snapshot_state()
	_expect(not actor.is_empty() and not schedule.is_empty() and not saved.is_empty(), "paused aggregate captures actual actor/scheduler/projected playback: " + installed.playback.last_snapshot_error)
	if actor.is_empty() or schedule.is_empty() or saved.is_empty():
		return {"playback": {}}
	var wire: String = ExactJson.stringify({"actor": actor, "scheduler": schedule, "playback": saved})
	var parsed: Dictionary = ExactJson.parse(wire)
	_expect(not wire.is_empty() and parsed.get("accepted", false) and parsed.get("value") is Dictionary and ExactJson.stringify(parsed.get("value")) == wire, "exact native tagged transport preserves the whole finite projected aggregate without decimal clock tolerance")
	if not parsed.get("accepted", false):
		return {"playback": {}}
	var result: Dictionary = parsed.value
	result["native"] = _native_state(installed.playback)
	result["runtime_owner"] = installed.playback # Observation outside the transported save.
	return result


func _fresh(arena: Dictionary, recorded: Dictionary, bundle: Dictionary) -> Dictionary:
	if bundle.get("playback", {}).is_empty():
		return {}
	var hero: CinderPlayer = Player.new()
	hero.name = "FreshProjectedHero"
	arena.world.add_child(hero)
	var scheduler = Scheduler.new()
	scheduler.name = "FreshProjectedScheduler"
	arena.world.add_child(scheduler)
	var owner = Playback.new()
	owner.name = "FreshProjectedPlayback"
	arena.world.add_child(owner)
	owner.set_physics_process(false)
	_expect(owner.configure("projected/owner", recorded.sequence, EPOCH, 1), "fresh native candidate retains immutable original Sequence identity")
	owner.global_position = Codec.read_vector3(bundle.playback.exchange.source_position)
	var fresh: Dictionary = {"world": arena.world, "player": hero, "scheduler": scheduler, "playback": owner, "floors": arena.floors, "context": arena.context, "hole": arena.hole, "wall": arena.wall, "events": []}
	fresh["bindings"] = _bindings(fresh, owner)
	var callbacks: Array[String] = []
	owner.state_changed.connect(func(_value: Dictionary) -> void: callbacks.append("state"))
	owner.event_dispatched.connect(func(event: Dictionary, _receipt: Dictionary) -> void:
		callbacks.append("event")
		fresh.events.append(event.kind)
	)
	hero.fired.connect(func(_kind: String) -> void: callbacks.append("actor"))
	for cue: Node3D in owner.get_cues():
		cue.state_changed.connect(func(_value: Dictionary) -> void: callbacks.append("cue"))
	var actor_before: Dictionary = hero.snapshot_state()
	var owner_before: Dictionary = owner.state()
	var error: String = owner.call("snapshot_error", bundle.playback, scheduler, bundle.scheduler, fresh.bindings, {"hero": hero}, fresh.floors, fresh.context)
	_expect(hero.snapshot_error(bundle.actor).is_empty() and error.is_empty() and hero.snapshot_state() == actor_before and owner.state() == owner_before and callbacks.is_empty(), "fresh schema3 whole-unit prevalidation is pure before actor/scheduler mutation: " + error)
	var accepted: bool = hero.restore_state(bundle.actor) and scheduler.restore_state(bundle.scheduler, fresh.bindings) and owner.call("restore_state", bundle.playback, scheduler, bundle.scheduler, fresh.bindings, {"hero": hero}, fresh.floors, fresh.context)
	_expect(accepted and callbacks.is_empty() and _native_state(owner) == bundle.native, "real actor then scheduler then projected playback restore is quiet and reproduces actual native pixels/geometry/partial phases: " + owner.last_snapshot_error)
	if not accepted:
		return {}
	_expect(ExactJson.stringify(hero.snapshot_state()) == ExactJson.stringify(bundle.actor) and ExactJson.stringify(scheduler.snapshot_state(fresh.bindings)) == ExactJson.stringify(bundle.scheduler) and ExactJson.stringify(owner.snapshot_state(bundle.scheduler, fresh.bindings)) == ExactJson.stringify(bundle.playback), "fresh unit preserves exact motion, original capture history, deadlines, projection and receipt clocks")
	# No duplicate live authoritative unit survives this successful paired retry.
	bundle.runtime_owner.free()
	arena.scheduler.end_encounter()
	arena.scheduler.free()
	arena.player.free()
	return fresh


func _native_state(playback: Node3D) -> Dictionary:
	var sprite = playback.get_apparition()
	var cues: Array = []
	for cue: Node3D in playback.get_cues():
		var nodes: Array = []
		for node_name: String in ["RequiredFootprintOutline", "RequiredFootprintFill", "RequiredSourceMarker"]:
			var node: MeshInstance3D = cue.get_node(node_name)
			var surfaces: Array = []
			if node.mesh != null:
				var native_mesh: ArrayMesh = node.mesh as ArrayMesh
				for surface: int in range(native_mesh.get_surface_count()):
					surfaces.append({"primitive": native_mesh.surface_get_primitive_type(surface), "vertices": native_mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]})
			nodes.append({"name": node_name, "transform": node.global_transform, "visible": node.visible, "surfaces": surfaces})
		cues.append({"state": cue.state(), "nodes": nodes})
	return {"root_transform": playback.get_apparition_root().global_transform, "sprite_transform": sprite.transform, "visible": sprite.visible, "texture": sprite.texture.get_image().get_data(), "presentation": sprite.presentation_id, "weapon": sprite.weapon_visual_id, "jacket": sprite.jacket_visual_id, "pants": sprite.pants_visual_id, "shoes": sprite.shoes_visual_id, "cues": cues, "pose": playback.state().visual_pose}


func _check_native(cue: Node3D, projection_event: Dictionary, phase: String, arena: Dictionary) -> void:
	var observed: Dictionary = cue.state()
	var raw: Dictionary = projection_event.record
	var origin: Vector3 = Codec.read_vector3(raw.world_origin)
	var direction: Vector3 = Codec.read_vector3(raw.direction)
	var expected: Dictionary = Geometry.cone(origin, direction, float(raw.geometry.reach), float(raw.geometry.cone_min_dot), float(raw.geometry.origin_disk_radius))
	_expect(observed.phase == phase and observed.geometry == CueMesh.canonical_geometry(expected) and observed.source_position == origin, phase + " keeps full original raw logical geometry/source despite clipped presentation")
	_expect(String(cue.call("projection_error", projection_event)).is_empty(), phase + " actual required mesh nodes/resources/surfaces/transforms match the immutable bound event")
	var fill: MeshInstance3D = cue.get_node("RequiredFootprintFill")
	var outline: MeshInstance3D = cue.get_node("RequiredFootprintOutline")
	_expect(fill.visible == (phase == "active") and outline.visible == (phase != "recovery") and (cue.get_node("RequiredSourceMarker") as MeshInstance3D).is_visible_in_tree(), phase + " preserves shared warning/lock/active/recovery required visibility grammar")
	if projection_event.kind == "primary":
		_expect(not _native_intersects_rect(fill, arena.hole) and not _native_covers(fill, origin + Vector3(1.5, 0, 1.0)) and _native_covers(fill, origin + Vector3.RIGHT * 0.2), phase + " native-converted fill retains open floor while excluding the physical hole and entire Box shadow")
		var native_record: Dictionary = raw.duplicate(true)
		native_record.world_origin = origin
		native_record.direction = direction
		_expect(not _native_vertices(outline).is_empty() and not _native_intersects_rect(outline, arena.hole) and _blocked_vertices(outline, arena, native_record) == 0, phase + " inward native boundary outline never expands across the physical hole or scenery LOS shadow")
	var vertices: Array[Vector3] = _native_vertices(fill)
	var correct_y: bool = not vertices.is_empty()
	for vertex: Vector3 in vertices:
		correct_y = correct_y and absf(vertex.y - (float(projection_event.floor_y) + 0.021)) < 0.000001
	_expect(correct_y, phase + " actual mesh lies on the authenticated floor plane with only the common fill lift")


func _canonical_geometry(record: Dictionary, position: Vector3) -> bool:
	var offset: Vector3 = position - record.world_origin
	if absf(offset.y) > float(record.geometry.max_vertical_distance):
		return false
	offset.y = 0.0
	return offset.length() <= float(record.geometry.reach) and (offset.length() <= float(record.geometry.origin_disk_radius) or offset.normalized().dot(record.direction) >= float(record.geometry.cone_min_dot))


func _los_clear(arena: Dictionary, record: Dictionary, position: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(record.world_origin + Vector3.UP * float(record.geometry.los.height), position + Vector3.UP * float(record.geometry.los.height), int(record.geometry.los.collision_mask))
	return arena.world.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _one_bit(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes.encode_u64(0, bytes.decode_u64(0) + 1)
	return bytes.decode_double(0)


func _one_bit32(value: float) -> float:
	var bytes := PackedByteArray()
	bytes.resize(4)
	bytes.encode_float(0, value)
	bytes.encode_u32(0, bytes.decode_u32(0) + 1)
	return bytes.decode_float(0)


func _resume_tick(playback: Node3D) -> void:
	var delivery := ResumeTick.new()
	delivery.delivery = playback.advance
	root.add_child(delivery)
	paused = false
	for _frame: int in range(20):
		await process_frame
		if delivery.done:
			break
	_expect(delivery.done and paused, "one real ordered physics tick reaches the bounded held delivery barrier")
	delivery.queue_free()


func _native_vertices(mesh: MeshInstance3D) -> Array[Vector3]:
	var result: Array[Vector3] = []
	if mesh.mesh == null:
		return result
	for surface: int in range(mesh.mesh.get_surface_count()):
		var local: PackedVector3Array = mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		for vertex: Vector3 in local:
			result.append(mesh.global_transform * vertex)
	return result


func _native_covers(mesh: MeshInstance3D, point: Vector3) -> bool:
	var vertices: Array[Vector3] = _native_vertices(mesh)
	for index: int in range(0, vertices.size(), 3):
		if Geometry2D.point_is_inside_triangle(Vector2(point.x, point.z), Vector2(vertices[index].x, vertices[index].z), Vector2(vertices[index + 1].x, vertices[index + 1].z), Vector2(vertices[index + 2].x, vertices[index + 2].z)):
			return true
	return false


func _native_intersects_rect(mesh: MeshInstance3D, rect: Rect2) -> bool:
	var polygon := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var vertices: Array[Vector3] = _native_vertices(mesh)
	for index: int in range(0, vertices.size(), 3):
		var triangle := PackedVector2Array([Vector2(vertices[index].x, vertices[index].z), Vector2(vertices[index + 1].x, vertices[index + 1].z), Vector2(vertices[index + 2].x, vertices[index + 2].z)])
		for intersection: PackedVector2Array in Geometry2D.intersect_polygons(triangle, polygon):
			if intersection.size() >= 3:
				return true
	return false


func _blocked_vertices(mesh: MeshInstance3D, arena: Dictionary, record: Dictionary) -> int:
	var count: int = 0
	for vertex: Vector3 in _native_vertices(mesh):
		var from: Vector3 = record.world_origin + Vector3.UP * float(record.geometry.los.height)
		var to: Vector3 = Vector3(vertex.x, record.world_origin.y, vertex.z) + Vector3.UP * float(record.geometry.los.height)
		if not arena.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, int(record.geometry.los.collision_mask))).is_empty():
			count += 1
	return count


func _region(body: StaticBody3D) -> Dictionary:
	var collision: CollisionShape3D = body.get_child(0)
	var size: Vector3 = (collision.shape as BoxShape3D).size
	return {"collision": collision, "safe_rect": Rect2(Vector2(body.position.x - size.x * 0.5, body.position.z - size.z * 0.5), Vector2(size.x, size.z))}


func _box(parent: Node3D, node_name: String, position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "Shape"
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	body.add_child(collision)
	parent.add_child(body)
	body.position = position
	return body


func _until(scheduler: Node3D, clock_s: float) -> void:
	for _tick: int in range(900):
		if scheduler.get_clock() >= clock_s:
			return
		await _ticks(1)
	_expect(false, "bounded real simulation reaches required deadline")


func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame


func _dispose(arena: Dictionary) -> void:
	paused = false
	arena.world.queue_free()
	await process_frame


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
