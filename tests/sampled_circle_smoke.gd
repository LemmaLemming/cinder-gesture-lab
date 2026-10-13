extends SceneTree
## Shared56 native sampled-circle focused fixture.
## Focused native integration fixture; no route/campaign/portrait acceptance.

const World = preload("res://tests/fixtures/sampled_eye_fixture.gd")
const Consumer = preload("res://scripts/combat/native_sampled_circle.gd")
const Player = preload("res://scripts/player.gd")
const Difficulty = preload("res://scripts/combat/difficulty.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const Cue = preload("res://scripts/cues/threat_cue.gd")

class NativeNose:
	extends CharacterBody3D
	var scheduler: CinderThreatScheduler
	var cue: CinderThreatCue
	func _ready() -> void:
		collision_layer = 2
		collision_mask = 1
		var collision := CollisionShape3D.new()
		collision.name = "BodyCollision"
		var box := BoxShape3D.new()
		box.size = Vector3(0.6, 0.8, 0.6)
		collision.shape = box
		collision.position.y = 0.4
		add_child(collision)
		cue = Cue.new()
		cue.name = "ThreatCue"
		add_child(cue)
	func _exit_tree() -> void:
		if is_instance_valid(scheduler): scheduler.cancel_owner(self, "nose_removed")

class NativePhysicsCallback:
	extends Node
	## Test orchestration only. Runs in the actual native physics callback order;
	## it never advances an actor/clock or replaces a production callback.
	signal finished
	var callback: Callable
	var limit: int = 360
	var ticks: int = 0
	var done: bool = false
	var exhausted: bool = false
	func _physics_process(delta: float) -> void:
		if done: return
		ticks += 1
		var accepted: bool = callback.is_valid() and callback.call(delta, ticks) == true
		if not accepted and ticks < limit: return
		done = true
		exhausted = not accepted
		set_physics_process(false)
		finished.emit()


var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if OS.get_cmdline_user_args().has("--portrait"):
		await _portrait_run()
		return
	await _original_remote_circle_refusal()
	await _pure_preview_and_real_dash_primary()
	await _active_held_suffix_fresh_quiet_restore()
	await _moving_held_suffix_fresh_quiet_restore()
	await _unsupported_contact_preserves_exchange()
	await _circle_cone_union_proof()
	await _explicit_finite_cycles_and_cleanup()
	await _late_cue_failures()
	await _native_identity_and_stale_preview()
	print("Native sampled circle draft smoke: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _portrait_run() -> void:
	## TEST component presentation only: actual Hero/eye/Scheduler/consumer,
	## native cue meshes and fixed lab camera; no authored Moon art or route.
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(540, 1170)
	var graphical: bool = DisplayServer.get_name() != "headless"
	_expect(graphical, "sampled portrait uses actual graphical renderer")
	if not graphical:
		quit(1)
		return
	var output: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--portrait-output="):
			output = argument.trim_prefix("--portrait-output=")
	var directory_ok: bool = not output.is_empty() and output.is_absolute_path() and DirAccess.make_dir_recursive_absolute(output) == OK
	_expect(directory_ok, "portrait requires explicit absolute fresh output directory")
	if not directory_ok:
		quit(1)
		return
	var arena: Dictionary = World.create(self)
	_portrait_presentation(arena)
	await _ticks(5)
	_expect(arena.scheduler.begin_encounter("standard", "sampled-component-portrait"), "portrait begins actual standard native encounter")
	var desired_phase: Array[String] = ["warning"]
	arena.consumer.state_changed.connect(func(value: Dictionary) -> void:
		if value.phase == desired_phase[0]: paused = true
	)
	var answer: Dictionary = arena.consumer.start(World.context(arena, "sampled-component-portrait"))
	_expect(answer.get("accepted", false) and paused and arena.consumer.state().phase == "warning", "portrait holds actual native warning publication")
	if not answer.get("accepted", false) or not paused:
		await _dispose(arena)
		quit(1)
		return
	var original_sample: Dictionary = arena.consumer.state().sample.duplicate(true)
	var original_exchange: Dictionary = _exchange_receipt(arena.scheduler.sampled_circle_reservation_state(answer.reservation_id))
	var events: Array = _observe_unit(arena)
	var receipts: Array[Dictionary] = []
	await process_frame # Leave start/phase transaction before native capture.
	events.clear()
	receipts.append(await _portrait_capture(arena, "warning", output, events, original_sample, original_exchange))
	desired_phase[0] = "active"
	paused = false
	_expect(arena.hero.request_dash(Vector3.RIGHT), "portrait safe landing uses actual public Player dash")
	_expect(await _until_phase(arena.consumer, "active") and paused, "portrait holds actual native active publication")
	await process_frame
	events.clear()
	receipts.append(await _portrait_capture(arena, "active", output, events, original_sample, original_exchange))
	desired_phase[0] = "recovery"
	paused = false
	_expect(await _until_phase(arena.consumer, "recovery") and paused, "portrait holds actual native recovery publication")
	await process_frame
	events.clear()
	receipts.append(await _portrait_capture(arena, "recovery", output, events, original_sample, original_exchange))
	var report_path: String = output.path_join("portrait-receipt.exact.json")
	var report: FileAccess = FileAccess.open(report_path, FileAccess.WRITE) if not FileAccess.file_exists(report_path) else null
	_expect(report != null, "portrait receipt uses a fresh evidence path")
	if report != null:
		report.store_string(ExactJson.stringify({"api_revision": "sampled-component-portrait-1", "receipts": receipts, "scope": "actual native component phases; TEST plain floor/source meshes; no authored art, route, campaign, performance or human-balance acceptance"}))
		report.close()
	print("SAMPLED COMPONENT PORTRAIT RECEIPTS ", ExactJson.stringify(receipts))
	await _dispose(arena)
	print("Native sampled component portrait: %d checks, %d failures; three540x1170 native phases; TEST floor/source presentation" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _portrait_presentation(arena: Dictionary) -> void:
	# In-memory test meshes only. The Floor/Support and Eye/BodyCollision
	# resources/transforms remain the ones bound by the real fixture.
	var floor_body: Node3D = arena.region.collision.get_parent()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(20.0, 1.0, 20.0)
	var floor := MeshInstance3D.new()
	floor.name = "TESTPlainFloorPresentation"
	floor.mesh = floor_mesh
	floor.material_override = _portrait_material(Color(0.14, 0.16, 0.19))
	floor_body.add_child(floor)
	# Open TEST frame outlines the actual body without covering the native
	# floor-level source marker. Authored eye artwork remains the act owner's.
	for side_x: float in [-0.38, 0.38]:
		for side_z: float in [-0.38, 0.38]:
			var post_mesh := BoxMesh.new()
			post_mesh.size = Vector3(0.04, 1.0, 0.04)
			var post := MeshInstance3D.new()
			post.name = "TESTSourcePost" + str(arena.eye.get_child_count())
			post.mesh = post_mesh
			post.position = Vector3(side_x, 0.5, side_z)
			post.material_override = _portrait_material(Color(0.66, 0.70, 0.74))
			arena.eye.add_child(post)
	for side: float in [-0.38, 0.38]:
		for along_x: bool in [true, false]:
			var rail_mesh := BoxMesh.new()
			rail_mesh.size = Vector3(0.8, 0.04, 0.04) if along_x else Vector3(0.04, 0.04, 0.8)
			var rail := MeshInstance3D.new()
			rail.name = "TESTSourceRail" + str(arena.eye.get_child_count())
			rail.mesh = rail_mesh
			rail.position = Vector3(0.0, 1.0, side) if along_x else Vector3(side, 1.0, 0.0)
			rail.material_override = _portrait_material(Color(0.66, 0.70, 0.74))
			arena.eye.add_child(rail)
	var environment := WorldEnvironment.new()
	environment.name = "TESTPortraitEnvironment"
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.035, 0.04, 0.05)
	environment.environment = settings
	arena.root.add_child(environment)
	var camera := Camera3D.new()
	camera.name = "TESTPortraitCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 7.2
	arena.root.add_child(camera)
	camera.position = Vector3(0.0, 18.0, 13.0)
	camera.look_at(Vector3.ZERO)
	camera.current = true


func _portrait_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material


func _portrait_capture(arena: Dictionary, phase: String, output: String, events: Array, original_sample: Dictionary, original_exchange: Dictionary) -> Dictionary:
	var before: Dictionary = _pure_state(arena)
	var packet: Dictionary = World.capture(arena)
	var wire: String = ExactJson.stringify(packet)
	_expect(paused and _packet_complete(packet) and not wire.is_empty() and arena.consumer.state().phase == phase, "portrait " + phase + " has an actual quiet whole-unit native phase packet")
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	var path: String = output.path_join(phase + ".png")
	var file_ok: bool = picture != null and picture.get_size() == Vector2i(540, 1170) and not FileAccess.file_exists(path) and picture.save_png(path) == OK
	_expect(file_ok, "actual540x1170 " + phase + " component PNG saved to fresh evidence path")
	var unchanged: bool = paused and Consumer._same_exact(before, _pure_state(arena)) and Consumer._same_exact(arena.consumer.state().sample, original_sample) and Consumer._same_exact(_exchange_receipt(arena.scheduler.sampled_circle_reservation_state(arena.consumer.state().reservation_id)), original_exchange) and events.is_empty()
	_expect(unchanged, "portrait " + phase + " draw preserves actual bodies/resources/clocks/lease/sample/cue and quiet observers")
	return {"phase": phase, "path": path, "size": [540, 1170], "png_written": file_ok, "png_sha256": FileAccess.get_sha256(path) if file_ok else "", "png_bytes": FileAccess.get_file_as_bytes(path).size() if file_ok else 0, "scheduler_clock_s": arena.scheduler.get_clock(), "remaining_s": arena.consumer.state().remaining_s, "native_packet_sha256": wire.sha256_text(), "native_state_unchanged": unchanged, "quiet_observers": events.size(), "same_warning_sample": Consumer._same_exact(arena.consumer.state().sample, original_sample), "hero_position": Codec.vector3(arena.hero.global_position), "source_position": Codec.vector3(arena.eye.global_position), "scope": "TEST plain floor/source meshes and actual native cue/player; direct540x1170 component view; no authored art or full production pixel-viewport claim"}


func _original_remote_circle_refusal() -> void:
	var arena: Dictionary = World.create(self, false)
	await _ticks(5)
	var scheduler: CinderThreatScheduler = arena.scheduler
	_expect(scheduler.begin_encounter("standard", "original-circle-refusal"), "real original stationary encounter begins")
	var difficulty := Difficulty.new()
	var role: Dictionary = difficulty.resolve_role(World.RAW_ROLE, "standard", World.TIMING_FLOORS)
	var response: Dictionary = arena.hero.get_threat_response_state()
	var context: Dictionary = World.context(arena, "original-circle-refusal")
	for key: String in Consumer.CONTEXT_KEYS:
		if key != "encounter_id": response[key] = context[key]
	var remote := {"role": role, "geometry": Geometry.circle(arena.hero.global_position, 0.8), "source_stationary": true, "opening_stationary": true, "opening_position": arena.eye.global_position, "cooldown_remaining_s": 0.0}
	var before: Dictionary = _pure_state(arena)
	var refused: Dictionary = scheduler.preview_stationary(arena.eye, remote, response)
	_expect(not refused.get("accepted", false) and String(refused.get("reason", "")).contains("origin"), "existing stationary path still rejects Hero-centered origin detached from real eye")
	_expect(Consumer._same_exact(before, _pure_state(arena)), "original remote-origin refusal is pure before sampled source registration")
	_expect(scheduler.reservations().is_empty(), "original path refusal allocates no threat")
	await _dispose(arena)


func _pure_preview_and_real_dash_primary() -> void:
	var arena: Dictionary = World.create(self)
	await _ticks(5)
	var hero: CinderPlayer = arena.hero
	var scheduler: CinderThreatScheduler = arena.scheduler
	var consumer: CinderNativeSampledCircle = arena.consumer
	_expect(arena.bound and arena.guarded, "actual eye owns source binding and bind-once two-argument parent guard")
	_expect(not consumer.has_method("take_damage") and not consumer.has_method("get_sampled_circle_binding") and not consumer.is_in_group("enemies"), "consumer has no surrogate HP/lease/hit classification")
	_expect(not consumer.set_presentation_guard(arena.eye.parent_presentation_guard), "bound parent guard cannot be replaced")
	_expect(scheduler.begin_encounter("standard", "sampled-native-dash"), "sampled circle uses shared Scheduler encounter")
	var context: Dictionary = World.context(arena, "sampled-native-dash")
	var before: Dictionary = _pure_state(arena)
	var preview: Dictionary = consumer.preview_start(context)
	_expect(preview.get("accepted", false), "native pure preview proves a stopped supported actual Hero ground sample")
	_expect(Consumer._same_exact(before, _pure_state(arena)), "pure preview changes no clock, serial, lease, phase, cue or diagnostics")
	if not preview.get("accepted", false):
		push_error(String(preview.get("reason", "Preview rejected")))
		await _dispose(arena)
		return
	var sample: Dictionary = preview.candidate.adapter.sample.duplicate(true)
	_expect(sample.api_revision == Consumer.SAMPLE_API and sample.floor_id == "Floor/Support" and sample.source_id == "moon-eye" and sample.hero_id == "hero" and Codec.read_vector3(sample.ground_position).x == hero.global_position.x and Codec.read_vector3(sample.ground_position).z == hero.global_position.z and sample.scheduler_clock_s == scheduler.get_clock() and sample.hero_action_clock_s == hero.get_world_action_clock(), "closed receipt names the exact actual Hero, eye, native floor and independent warning-start clocks")
	var answer: Dictionary = consumer.start(context, preview)
	_expect(answer.get("accepted", false), "exact preview admits the actual eye lease at warning start")
	if not answer.get("accepted", false):
		push_error(consumer.last_error)
		await _dispose(arena)
		return
	var committed: Dictionary = consumer.state()
	var reservation: Dictionary = scheduler.sampled_circle_reservation_state(answer.reservation_id)
	_expect(reservation.source_instance_id == arena.eye.get_instance_id() and reservation.source_instance_id != consumer.get_instance_id() and reservation.adapter.kind == "sampled_circle", "same genuine eye HP body owns the sampled typed lease")
	_expect(not committed.geometry.has("source_position") and consumer.get_cue().state().geometry == committed.geometry and consumer.get_cue().state().source_position == arena.eye.global_position and consumer.get_cue().global_position == committed.geometry.origin, "committed circle remains pure; native Cue gets eye marker as separate presentation data")
	_expect(not answer.proof.uses_blast and not answer.proof.uses_invulnerability and hero.shells == 0, "ordinary response proof requires neither blast supplies nor invulnerability")
	var hits: Array[Dictionary] = []
	consumer.hit_resolved.connect(func(id: String, cycle: int, result: Dictionary) -> void: hits.append({"hero_id": id, "cycle": cycle, "result": result.duplicate(true)}))
	_expect(hero.request_dash(Vector3.RIGHT), "actual Player accepts a normal dash after the warning-start sample")
	await _ticks(15)
	_expect(hero.last_dash_distance > 2.5 and hero.global_position.distance_to(Codec.read_vector3(sample.hero_position)) > 2.5, "real native dash changes the actual Hero position")
	_expect(Consumer._same_exact(consumer.state().sample, sample) and consumer.state().geometry == committed.geometry and scheduler.sampled_circle_reservation_state(answer.reservation_id).geometry == committed.geometry, "warning movement never retargets sample or committed circle")
	_expect(await _until_phase(consumer, "lock"), "sampled circle reaches native lock")
	_expect(consumer.state().geometry == committed.geometry and hits.is_empty(), "lock preserves the original circle and has no early damage")
	_expect(await _until_phase(consumer, "recovery"), "actual sampled active interval reaches recovery")
	_expect(hits.is_empty() and hero.hp == 100.0 and consumer.state().sample == sample, "dash to supported safe ground escapes the unchanged circle without damage")
	hero.shells = 0 # Focused actual resource arrangement at the real opening.
	var opening_hits: int = hero.slash((arena.eye.global_position - hero.global_position).normalized())
	_expect(opening_hits == 1 and arena.eye.dead and arena.eye.hp == 0.0 and consumer.state().status == "cancelled" and consumer.state().last_cancel_reason == "source_defeated", "actual zero-ammo ordinary primary reaches and defeats the genuine low eye HP recipient")
	_expect(hero.get_world_action_records().back().kind == "primary" and scheduler.sampled_circle_reservation_state(answer.reservation_id).is_empty() and consumer.get_cue().state().phase == "clear", "genuine primary execution retires the eye lease/cue without a fake opening target")
	await _ticks(1)
	paused = true
	var dead_packet: Dictionary = World.capture(arena)
	_expect(_packet_complete(dead_packet), "cancelled true dead-eye whole-unit packet captures at paused barrier")
	dead_packet = _exact_packet(dead_packet)
	await _dispose(arena, true)
	var fresh: Dictionary = World.create(self)
	var quiet: Array = _observe_unit(fresh)
	_expect(World.aggregate_error(fresh, dead_packet).is_empty(), "fresh pure prevalidation stages saved true dead lifecycle without replacing actual native ownership")
	_expect(World.restore_aggregate(fresh, dead_packet) and fresh.eye.hp == 0.0 and fresh.eye.dead and not fresh.eye.is_in_group("enemies") and fresh.consumer.state().status == "cancelled" and quiet.is_empty(), "fresh cancelled commit applies true HP/death and stays quiet in Player→eye→Scheduler→consumer order")
	await _dispose(fresh)


func _active_held_suffix_fresh_quiet_restore() -> void:
	var arena: Dictionary = World.create(self)
	await _ticks(5)
	var consumer: CinderNativeSampledCircle = arena.consumer
	var scheduler: CinderThreatScheduler = arena.scheduler
	arena.eye.hp = 9.0 # Representative true physical saved HP, not a caller flag.
	_expect(scheduler.begin_encounter("standard", "sampled-held"), "held suffix fixture starts actual shared encounter")
	var paused_on_active: Array[bool] = [false]
	consumer.state_changed.connect(func(value: Dictionary) -> void:
		if value.phase == "active" and not paused_on_active[0]:
			paused_on_active[0] = true
			paused = true
	)
	var answer: Dictionary = consumer.start(World.context(arena, "sampled-held"))
	_expect(answer.get("accepted", false), "real grounded Hero admits a sampled warning before held path")
	if not answer.get("accepted", false):
		await _dispose(arena)
		return
	_expect(await _until_phase(consumer, "active"), "actual active phase callback pauses after staging native Hero segment")
	await process_frame # Leave the actual synchronous phase/physics transaction.
	_expect(paused and paused_on_active[0] and consumer.state().pending_segment_count > 0 and not consumer.state().hit_consumed and arena.hero.hp == 100.0, "pause keeps the genuine sampled unresolved active suffix before hurt")
	var packet: Dictionary = World.capture(arena)
	_expect(_packet_complete(packet) and not packet.consumer.pending_segments.is_empty(), "whole-unit snapshot retains real actual held segments, clocks and source HP")
	packet = _exact_packet(packet)
	var saved_sample: Dictionary = packet.consumer.sample.duplicate(true)
	var original_clock: float = scheduler.get_clock()
	await _dispose(arena, true)
	var fresh: Dictionary = World.create(self)
	var quiet: Array = _observe_unit(fresh)
	var error: String = World.aggregate_error(fresh, packet)
	_expect(error.is_empty(), "fresh pure whole-unit prevalidation joins staged real Player, source, lease and suffix: " + error)
	var corrupt: Dictionary = packet.duplicate(true)
	corrupt.consumer.sample.ground_position[0] += 0.25
	_expect(not World.aggregate_error(fresh, corrupt).is_empty() and fresh.hero.hp == 100.0 and fresh.eye.hp == 14.0 and fresh.consumer.state().cycle == 0 and quiet.is_empty(), "copied historical sample forgery rejects before physical/cue writes or observers")
	_nondata_packet_refusals(fresh, packet, quiet)
	_expect(World.restore_aggregate(fresh, packet), "fresh whole-unit commit restores held state through actual interfaces")
	_expect(fresh.eye.hp == 9.0 and not fresh.eye.dead and fresh.scheduler.get_clock() == original_clock and fresh.consumer.state().phase == "active" and fresh.consumer.state().sample == saved_sample and fresh.consumer.state().pending_segment_count == packet.consumer.pending_segments.size() and quiet.is_empty(), "true HP and original sample/phase/suffix/deadlines commit quietly without resampling")
	var actual_scheduler_packet: Dictionary = fresh.scheduler.snapshot_state(World.bindings(fresh))
	_expect(not actual_scheduler_packet.is_empty() and Consumer._same_exact(actual_scheduler_packet, packet.scheduler) and fresh.scheduler.snapshot_error(actual_scheduler_packet, World.bindings(fresh)).is_empty() and quiet.is_empty(), "restored running Scheduler recaptures an exact native snapshot through its public interface without observers")
	var resolved: Array[Dictionary] = []
	fresh.consumer.hit_resolved.connect(func(id: String, cycle: int, result: Dictionary) -> void: resolved.append({"hero_id": id, "cycle": cycle, "result": result.duplicate(true)}))
	paused = false
	await _ticks(1)
	_expect(resolved.size() == 1 and fresh.consumer.state().hit_consumed and fresh.hero.hp < 100.0 and resolved[0].result.opportunity_consumed, "resume appends the next actual segment then consumes the held opportunity once before real Player hurt")
	var hp_after: float = fresh.hero.hp
	await _ticks(8)
	_expect(resolved.size() == 1 and fresh.hero.hp == hp_after, "continued actual exposure never retries consumed hurt opportunity")
	await _dispose(fresh)


func _nondata_packet_refusals(fresh: Dictionary, packet: Dictionary, quiet: Array) -> void:
	var before: Dictionary = _pure_state(fresh)
	var consumer_cycle: Dictionary = {}
	consumer_cycle["self"] = consumer_cycle
	var corrupt: Dictionary = packet.duplicate(true)
	corrupt.consumer = consumer_cycle
	_expect(not World.aggregate_error(fresh, corrupt).is_empty(), "cyclic foreign consumer packet refuses before recursive copy")
	consumer_cycle.clear()
	var scheduler_cycle: Dictionary = {}
	scheduler_cycle["self"] = scheduler_cycle
	corrupt = packet.duplicate(true)
	corrupt.scheduler.reservations = [scheduler_cycle]
	_expect(not World.aggregate_error(fresh, corrupt).is_empty(), "cyclic foreign Scheduler packet refuses before consumer's staged deep copy")
	scheduler_cycle.clear()
	corrupt = packet.duplicate(true)
	var nondata: Object = Object.new()
	corrupt.consumer.pending_segments.append(nondata)
	_expect(not World.aggregate_error(fresh, corrupt).is_empty(), "Object in a foreign pending path cannot enter the exact wire")
	corrupt.consumer.pending_segments.clear()
	nondata.free()
	corrupt = packet.duplicate(true)
	corrupt.consumer.erase("api_revision")
	corrupt.consumer[StringName("api_revision")] = Consumer.API_REVISION
	_expect(not World.aggregate_error(fresh, corrupt).is_empty(), "StringName wire key cannot masquerade as an exact String key")
	_expect(Consumer._same_exact(before, _pure_state(fresh)) and quiet.is_empty(), "malformed foreign packets preserve true bodies, diagnostics, native cue and all quiet observers")


func _moving_held_suffix_fresh_quiet_restore() -> void:
	# Two actual public dashes arrange a moving recipient at the original
	# active boundary; no timer, sample, checkpoint or Scheduler setter is used.
	var arena: Dictionary = World.create(self)
	await _ticks(5)
	var consumer: CinderNativeSampledCircle = arena.consumer
	var scheduler: CinderThreatScheduler = arena.scheduler
	_expect(scheduler.begin_encounter("standard", "sampled-moving-held"), "moving held fixture begins a genuine shared encounter")
	var return_attempt: Dictionary = {"attempted": false, "accepted": false}
	var paused_on_active: Array[bool] = [false]
	var active_receipt: Array[Dictionary] = [{}]
	consumer.state_changed.connect(func(value: Dictionary) -> void:
		if value.phase != "active" or paused_on_active[0]: return
		var motion: Dictionary = arena.hero.get_threat_response_state().motion
		var dash: Dictionary = arena.hero.get_committed_dash_state()
		active_receipt[0] = {"clock_s": scheduler.get_clock(), "motion": motion.duplicate(true), "dash": dash.duplicate(true)}
		# Hold only a genuine in-flight return dash. An invalid setup remains a
		# visible setup failure and cannot become a stationary restore fixture.
		if return_attempt.get("accepted", false) and dash.get("active", false) and dash.get("direction") == Vector3.LEFT and float(motion.dash_left_s) > 0.0:
			paused_on_active[0] = true
			paused = true
	)
	var answer: Dictionary = consumer.start(World.context(arena, "sampled-moving-held"))
	_expect(answer.get("accepted", false), "moving held fixture samples the initially stopped native Hero")
	if not answer.get("accepted", false):
		await _dispose(arena)
		return
	var original: Dictionary = consumer.state().sample.duplicate(true)
	_expect(arena.hero.request_dash(Vector3.RIGHT), "first real dash leaves the immutable sampled circle")
	await _ticks(15)
	var lease: Dictionary = scheduler.sampled_circle_reservation_state(answer.reservation_id)
	_expect(not lease.is_empty(), "moving warning retains the genuine lease")
	if lease.is_empty():
		await _dispose(arena)
		return
	var return_start: float = float(lease.active_from_s) - 0.10
	var previous_clock: Array[float] = [scheduler.get_clock()]
	var driver: NativePhysicsCallback = _native_callback(arena, mini(arena.hero.process_physics_priority, scheduler.process_physics_priority) - 1, func(delta: float, _tick: int) -> bool:
		var now: float = scheduler.get_clock()
		if now < return_start:
			previous_clock[0] = now
			return false
		var response: Dictionary = arena.hero.get_threat_response_state()
		return_attempt["attempted"] = true
		return_attempt["clock_s"] = now
		return_attempt["previous_clock_s"] = previous_clock[0]
		return_attempt["delta_s"] = delta
		return_attempt["intended_s"] = return_start
		return_attempt["phase"] = consumer.state().phase
		return_attempt["response"] = _response_receipt(response)
		if consumer.state().phase == "lock" and now < float(lease.active_from_s) and float(response.dash_cooldown_left_s) == 0.0:
			return_attempt["accepted"] = arena.hero.request_dash(Vector3.LEFT)
		return true
	)
	if not driver.done: await driver.finished
	print("TRACE moving return native callback: ", return_attempt, " exhausted=", driver.exhausted)
	var return_ok: bool = not driver.exhausted and return_attempt.get("accepted", false) and float(return_attempt.get("previous_clock_s", INF)) < return_start and float(return_attempt.get("clock_s", -1.0)) >= return_start and float(return_attempt.get("clock_s", INF)) < float(lease.active_from_s)
	_expect(return_ok, "a legitimate return dash starts on the first eligible actual native callback in unchanged lock after actual cooldown")
	driver.queue_free()
	var reached_active: bool = await _until_phase(consumer, "active")
	_expect(reached_active and paused_on_active[0], "native active observer pauses a genuinely moving return dash")
	await process_frame # Leave the real phase/physics transaction while paused.
	var saved_motion: Dictionary = arena.hero.get_threat_response_state().motion.duplicate(true)
	var saved_dash: Dictionary = arena.hero.get_committed_dash_state()
	var moving_held: bool = paused and paused_on_active[0] and float(saved_motion.dash_left_s) > 0.0 and saved_dash.get("active", false) and saved_dash.get("direction") == Vector3.LEFT and arena.hero.global_position.distance_to(Codec.read_vector3(original.hero_position)) > 0.1 and Consumer._same_exact(consumer.state().sample, original) and consumer.state().pending_segment_count > 0 and not consumer.state().hit_consumed
	_expect(moving_held, "saved current native Hero is mid-dash and distinct from historical warning sample with an unresolved held suffix")
	print("TRACE moving active native receipt: ", active_receipt[0])
	if not return_ok or not moving_held:
		print("TRACE moving dependent restore/contact checks unexecuted: genuine moving setup failed")
		await _dispose(arena)
		return
	var packet: Dictionary = World.capture(arena)
	_expect(_packet_complete(packet), "actual moving whole-unit packet captures at the paused transaction barrier")
	if not _packet_complete(packet):
		await _dispose(arena)
		return
	packet = _exact_packet(packet)
	var saved_position: Vector3 = Codec.read_vector3(packet.player.motion.position)
	var saved_clock: float = scheduler.get_clock()
	await _dispose(arena, true)
	var fresh: Dictionary = World.create(self)
	var quiet: Array = _observe_unit(fresh)
	var error: String = World.aggregate_error(fresh, packet)
	_expect(error.is_empty(), "fresh pure schema4 prevalidation joins the saved moving Hero without sampling constructor position: " + error)
	_expect(World.restore_aggregate(fresh, packet) and quiet.is_empty() and fresh.hero.global_position == saved_position and Consumer._same_exact(fresh.hero.get_threat_response_state().motion, saved_motion) and Consumer._same_exact(fresh.hero.get_committed_dash_state(), saved_dash) and Consumer._same_exact(fresh.hero.snapshot_state().clocks, packet.player.clocks) and fresh.scheduler.get_clock() == saved_clock and Consumer._same_exact(fresh.consumer.state().sample, original) and fresh.consumer.state().pending_segment_count == packet.consumer.pending_segments.size(), "quiet moving commit preserves exact true dash/motion/clocks, original sample and held suffix")
	var actual_scheduler_packet: Dictionary = fresh.scheduler.snapshot_state(World.bindings(fresh))
	_expect(not actual_scheduler_packet.is_empty() and Consumer._same_exact(actual_scheduler_packet, packet.scheduler) and fresh.scheduler.snapshot_error(actual_scheduler_packet, World.bindings(fresh)).is_empty() and quiet.is_empty(), "restored running Scheduler recaptures an exact native snapshot through its public interface without observers")
	var resolved: Array[Dictionary] = []
	fresh.consumer.hit_resolved.connect(func(id: String, cycle: int, result: Dictionary) -> void: resolved.append({"hero_id": id, "cycle": cycle, "result": result.duplicate(true)}))
	paused = false
	await _ticks(14)
	_expect(resolved.size() == 1 and fresh.consumer.state().hit_consumed and resolved[0].result.opportunity_consumed, "resumed return path consumes one actual supported circle contact opportunity")
	if resolved.size() == 1:
		var hp_damage: float = float(resolved[0].result.hp_damage)
		_expect((resolved[0].result.accepted and hp_damage > 0.0 and fresh.hero.hp == 100.0 - hp_damage) or (not resolved[0].result.accepted and hp_damage == 0.0 and fresh.hero.hp == 100.0), "actual Player invulnerability may accept or decline hurt; its exact result is separate from once-consumed contact")
	var hp_after: float = fresh.hero.hp
	await _ticks(8)
	_expect(resolved.size() == 1 and fresh.hero.hp == hp_after and Consumer._same_exact(fresh.consumer.state().sample, original), "continued native exposure neither retries the consumed opportunity nor resamples the warning")
	await _dispose(fresh)

func _unsupported_contact_preserves_exchange() -> void:
	var arena: Dictionary = World.create(self)
	await _ticks(5)
	var scheduler: CinderThreatScheduler = arena.scheduler
	var consumer: CinderNativeSampledCircle = arena.consumer
	scheduler.begin_encounter("standard", "sampled-contact-domain")
	var answer: Dictionary = consumer.start(World.context(arena, "sampled-contact-domain"))
	_expect(answer.get("accepted", false), "contact-domain fixture has an authentic initially grounded sampled lease")
	if not answer.get("accepted", false):
		await _dispose(arena)
		return
	var original: Dictionary = consumer.state().sample.duplicate(true)
	var lease: Dictionary = scheduler.sampled_circle_reservation_state(answer.reservation_id)
	var original_exchange: Dictionary = _exchange_receipt(lease)
	var supported_position: Vector3 = arena.hero.global_position
	# Existing TEST negative-domain injection only: not a jump or earned route.
	# Ordinary production gravity remains enabled throughout the entire active
	# interval. No deadline or actor timer is arranged to prolong that interval.
	arena.hero.global_position += Vector3.UP * 128.0
	var before: Dictionary = _pure_state(arena)
	_expect(not scheduler.sampled_circle_contact_supported(answer.reservation_id, arena.hero.global_position, arena.hero.global_position), "actual airborne receiver cannot be hurt solely from an X/Z footprint")
	_expect(not scheduler.sampled_circle_contact_supported(answer.reservation_id, Vector3(INF, 0.0, 0.0), supported_position), "nonfinite held contact endpoint is refused")
	_expect(Consumer._same_exact(before, _pure_state(arena)) and not scheduler.sampled_circle_reservation_state(answer.reservation_id).is_empty(), "unsupported contact is pure and preserves clock, lease, phase, diagnostics and original sample")
	var resolved: Array[Dictionary] = []
	consumer.hit_resolved.connect(func(id: String, cycle: int, result: Dictionary) -> void: resolved.append({"hero_id": id, "cycle": cycle, "result": result.duplicate(true)}))
	var observations: Array[Dictionary] = []
	var previous_clock: Array[float] = [scheduler.get_clock()]
	var observer: NativePhysicsCallback = _native_callback(arena, consumer.process_physics_priority + 1, func(delta: float, _tick: int) -> bool:
		var now: float = scheduler.get_clock()
		var actual: Dictionary = consumer.state()
		var record: Dictionary = scheduler.sampled_circle_reservation_state(answer.reservation_id)
		var expected_phase: String = _expected_native_phase(now, original_exchange)
		var next_deadline: String = {"warning": "lock_from_s", "lock": "active_from_s", "active": "active_until_s", "recovery": "recovery_until_s"}[expected_phase]
		var receipt := {"clock_s": now, "delta_s": delta, "continuous_clock": now == previous_clock[0] + delta, "phase": actual.phase, "expected_phase": expected_phase, "remaining_s": actual.remaining_s, "expected_remaining_s": maxf(float(original_exchange[next_deadline]) - now, 0.0), "status": actual.status, "hp": arena.hero.hp, "hit_consumed": actual.hit_consumed, "position": arena.hero.global_position, "contact_supported": scheduler.sampled_circle_contact_supported(answer.reservation_id, arena.hero.global_position, arena.hero.global_position), "same_sample": Consumer._same_exact(actual.sample, original), "same_exchange": not record.is_empty() and Consumer._same_exact(_exchange_receipt(record), original_exchange)}
		observations.append(receipt)
		previous_clock[0] = now
		return actual.status != "running" or now > float(original_exchange.active_until_s)
	)
	if not observer.done: await observer.finished
	var timeline_ok: bool = not observer.exhausted and not observations.is_empty()
	var active_count: int = 0
	var active_first: Dictionary = {}
	var active_last: Dictionary = {}
	for receipt: Dictionary in observations:
		timeline_ok = timeline_ok and receipt.continuous_clock and receipt.status == "running" and receipt.phase == receipt.expected_phase and receipt.remaining_s == receipt.expected_remaining_s and receipt.same_sample and receipt.same_exchange
		if receipt.expected_phase == "active":
			active_count += 1
			if active_first.is_empty(): active_first = receipt
			active_last = receipt
			timeline_ok = timeline_ok and not receipt.contact_supported and not receipt.hit_consumed and receipt.hp == 100.0
	var terminal: Dictionary = observations.back() if not observations.is_empty() else {}
	_expect(active_count > 0 and not active_first.is_empty() and float(active_first.clock_s) >= float(original_exchange.active_from_s), "authentic warning and lock reach observed native active ticks while Hero lacks supported contact")
	print("TRACE unsupported native interval: deadlines=", original_exchange, " active_ticks=", active_count, " first=", active_first, " last=", active_last, " terminal=", terminal, " exhausted=", observer.exhausted)
	_expect(timeline_ok and active_count > 0 and terminal.get("phase") == "recovery" and float(terminal.get("clock_s", -1.0)) > float(original_exchange.active_until_s) and float(terminal.get("clock_s", INF)) <= float(original_exchange.recovery_until_s) and resolved.is_empty() and not consumer.state().hit_consumed and arena.hero.hp == 100.0, "unsupported receiver receives no hurt across every native active tick while exact original deadlines/phase/sample/lease continue through first recovery tick")
	observer.queue_free()
	# Restore only the pre-existing deliberately injected physical test pose,
	# after the observed complete active interval. This is not stability repair.
	arena.hero.global_position = supported_position
	arena.hero.velocity = Vector3.ZERO
	await _ticks(5)
	var stable: Dictionary = _pure_state(arena)
	_expect(not scheduler.sampled_circle_contact_supported(answer.reservation_id, supported_position, Vector3(11.0, supported_position.y, 0.0)) and Consumer._same_exact(stable, _pure_state(arena)), "a finite held segment leaving actual native floor is refused without timeline mutation")
	_expect(await _until_phase(consumer, "recovery") and Consumer._same_exact(consumer.state().sample, original) and Consumer._same_exact(_exchange_receipt(scheduler.sampled_circle_reservation_state(answer.reservation_id)), original_exchange), "return to supported native floor retains the same exact original recovery timeline")
	var support: CollisionShape3D = arena.region.collision
	support.shape = support.shape.duplicate(true) # Actual resource identity fault.
	_expect(scheduler.sampled_circle_reservation_state(answer.reservation_id).is_empty(), "replaced authoritative floor resource invalidates the pure lease reader")
	await _ticks(1)
	_expect(consumer.state().status == "cancelled", "native floor-resource loss cancels danger separately from unsupported Hero contact")
	await _dispose(arena)

func _explicit_finite_cycles_and_cleanup() -> void:
	var arena: Dictionary = World.create(self)
	await _ticks(5)
	var consumer: CinderNativeSampledCircle = arena.consumer
	var invalidated: Array[Dictionary] = []
	arena.scheduler.reservation_invalidated.connect(func(id: String, reason: String) -> void: invalidated.append({"id": id, "reason": reason}))
	arena.scheduler.begin_encounter("standard", "sampled-finite")
	var context: Dictionary = World.context(arena, "sampled-finite")
	var first_answer: Dictionary = consumer.start(context)
	_expect(first_answer.get("accepted", false), "first finite native sampled cycle admits")
	if not first_answer.get("accepted", false):
		await _dispose(arena)
		return
	_expect(await _until_phase(consumer, "clear"), "original finite recovery and lease expire normally")
	var first: Dictionary = consumer.state()
	await _ticks(2)
	_expect(first.status == "complete" and first.cycle == 1 and consumer.state().cycle == 1 and arena.scheduler.reservations().is_empty() and invalidated.is_empty(), "normal finite expiry completes without invalidation, rearming or refreshing the original cooldown")
	# Observe genuine public stability and fresh native preview at bounded actual
	# callbacks. Never force exact velocity, knockback, cooldown or ground state.
	var observations: Array[Dictionary] = []
	var second: Array[Dictionary] = [{}]
	var observer: NativePhysicsCallback = _native_callback(arena, consumer.process_physics_priority + 1, func(_delta: float, _tick: int) -> bool:
		var response: Dictionary = arena.hero.get_threat_response_state()
		var receipt: Dictionary = _response_receipt(response)
		receipt["scheduler_clock_s"] = arena.scheduler.get_clock()
		if response.get("stable", false) and float(response.dash_cooldown_left_s) == 0.0 and float(response.commitment_remaining_s) <= 0.0:
			var preview: Dictionary = consumer.preview_start(context)
			receipt["preview_accepted"] = preview.get("accepted", false)
			receipt["preview_reason"] = preview.get("reason", "")
			if preview.get("accepted", false):
				# Same fresh preview, same actual callback; no hidden settling tick.
				second[0] = consumer.start(context, preview)
				observations.append(receipt)
				return true
		observations.append(receipt)
		return false
	)
	observer.limit = 180
	if not observer.done: await observer.finished
	print("TRACE second cycle bounded actual stability: ticks=", observer.ticks, " exhausted=", observer.exhausted, " first=", observations.front() if not observations.is_empty() else {}, " last=", observations.back() if not observations.is_empty() else {}, " request=", second[0])
	observer.queue_free()
	var admitted: bool = not observer.exhausted and second[0].get("accepted", false)
	_expect(admitted and consumer.state().cycle == 2 and not consumer.state().hit_consumed and consumer.state().sample.generation == first.sample.generation and consumer.state().sample.scheduler_clock_s > first.sample.scheduler_clock_s, "explicit next cycle admits after bounded observed actual public stability/native preview, preserves incarnation and takes one new sample after real cooldown")
	if not admitted:
		print("TRACE live-second-cycle parent-removal check unexecuted: bounded actual admission failed; no actor state was reset")
		_expect(false, "actual parent removal of a live second cycle remains unexecuted when genuine second admission fails")
		await _dispose(arena)
		return
	var eye = arena.eye
	arena.root.remove_child(eye)
	_expect(arena.scheduler.reservations().is_empty() and consumer.state().status == "cancelled" and consumer.state().phase == "clear", "actual parent removal quietly retires its genuine lease and child danger state")
	eye.queue_free()
	await _dispose(arena)


func _circle_cone_union_proof() -> void:
	## Admission/proof scope only. B02's production nose phase owner is level
	## work; this uses a genuine distinct stationary native nose and one Scheduler.
	var arena: Dictionary = World.create(self)
	var nose := NativeNose.new()
	nose.name = "Nose"
	nose.position = Vector3(0.0, 0.0, -1.0)
	nose.scheduler = arena.scheduler
	arena.root.add_child(nose)
	await _ticks(5)
	var scheduler: CinderThreatScheduler = arena.scheduler
	scheduler.begin_encounter("standard", "sampled-circle-cone")
	var context: Dictionary = World.context(arena, "sampled-circle-cone")
	var circle: Dictionary = arena.consumer.start(context)
	_expect(circle.get("accepted", false), "real eye sampled circle first admits in shared union")
	if not circle.get("accepted", false):
		await _dispose(arena)
		return
	var raw: Dictionary = World.RAW_ROLE.duplicate(true)
	raw.windup_s = 2.6 # Deliberately visible offset from original circle's 2.2.
	var difficulty := Difficulty.new()
	var role: Dictionary = difficulty.resolve_role(raw, "standard", World.TIMING_FLOORS)
	var shape: Dictionary = Geometry.cone(nose.global_position, Vector3.BACK, 4.2, 0.84)
	var threat := {"role": role, "geometry": shape, "source_stationary": true, "opening_stationary": true, "opening_position": arena.eye.global_position, "cooldown_remaining_s": 0.0}
	var response: Dictionary = arena.hero.get_threat_response_state()
	for key: String in Consumer.CONTEXT_KEYS:
		if key != "encounter_id": response[key] = context[key]
	response.escape_directions = [Vector3.BACK]
	_expect(not scheduler.preview_stationary(nose, threat, response).get("accepted", false), "unsafe combined witness rejects a landing remaining inside the long genuine nose cone")
	response.escape_directions = [Vector3.RIGHT]
	var preview: Dictionary = scheduler.preview_stationary(nose, threat, response)
	_expect(preview.get("accepted", false), "full sampled-circle plus genuine-cone union proves one reachable safe ordinary dash/eye opening")
	var cone: Dictionary = scheduler.request_attack(nose, threat, response, preview) if preview.get("accepted", false) else {"accepted": false}
	_expect(cone.get("accepted", false) and scheduler.reservations().size() == 2, "two distinct genuine sources share one Scheduler budget and staggered union")
	if cone.get("accepted", false):
		var presentation: Dictionary = shape.duplicate(true)
		presentation["source_position"] = nose.global_position
		_expect(nose.cue.present(presentation, "warning") and scheduler.reservation_state(cone.reservation_id).source_instance_id == nose.get_instance_id() and scheduler.sampled_circle_reservation_state(circle.reservation_id).source_instance_id == arena.eye.get_instance_id(), "cone warning presents its real nose while sampled circle retains the true eye lease")
	await _dispose(arena)


func _late_cue_failures() -> void:
	for mutation: String in ["hide", "free", "replace", "mutate"]:
		var arena: Dictionary = World.create(self)
		await _ticks(5)
		var consumer: CinderNativeSampledCircle = arena.consumer
		_expect(arena.scheduler.begin_encounter("standard", "sampled-cue-" + mutation), "native cue failure encounter begins")
		var altered: Array[bool] = [false]
		consumer.state_changed.connect(func(value: Dictionary) -> void:
			if value.phase != "active" or altered[0]: return
			altered[0] = true
			var part: MeshInstance3D = consumer.get_cue().get_node("RequiredFootprintFill")
			match mutation:
				"hide": part.visible = false
				"free": part.queue_free()
				"replace": part.mesh = part.mesh.duplicate(true)
				"mutate": (part.mesh as ArrayMesh).clear_surfaces()
		)
		_expect(consumer.start(World.context(arena, "sampled-cue-" + mutation)).get("accepted", false), "real sampled warning admits before late " + mutation)
		await _ticks(145)
		_expect(altered[0] and arena.hero.hp == 100.0 and not consumer.state().hit_consumed and consumer.state().status == "cancelled" and arena.scheduler.reservations().is_empty(), "late native Cue " + mutation + " cancels before contact and is never healed at phase publication")
		await _dispose(arena)


func _native_identity_and_stale_preview() -> void:
	var arena: Dictionary = World.create(self)
	await _ticks(5)
	var scheduler: CinderThreatScheduler = arena.scheduler
	var consumer: CinderNativeSampledCircle = arena.consumer
	scheduler.begin_encounter("standard", "sampled-custody")
	var context: Dictionary = World.context(arena, "sampled-custody")
	var preview: Dictionary = consumer.preview_start(context)
	_expect(preview.get("accepted", false), "native identity fixture has valid original preview")
	await _ticks(1)
	_expect(not consumer.start(context, preview).get("accepted", false) and consumer.state().cycle == 0 and scheduler.reservations().is_empty(), "one actual clock tick makes an exact preview stale without consuming a cycle")
	_expect(arena.hero.request_dash(Vector3.RIGHT), "native no-mid-dash check uses a real Player dash")
	var in_dash: Dictionary = consumer.preview_start(context)
	_expect(not in_dash.get("accepted", false), "actual current/queued dash admission remains rejected")
	await _ticks(16)
	var other: CinderPlayer = Player.new()
	other.name = "OtherHero"
	arena.root.add_child(other)
	await _ticks(4)
	var substituted: Dictionary = other.get_threat_response_state()
	for key: String in Consumer.CONTEXT_KEYS:
		if key != "encounter_id": substituted[key] = context[key]
	_expect(not scheduler.preview_sampled_circle(arena.eye, "hero", substituted).get("accepted", false), "another genuine Player cannot substitute under the retained Hero ID")
	other.queue_free()
	await _ticks(1)
	var answer: Dictionary = consumer.start(context)
	_expect(answer.get("accepted", false), "fresh explicit request after real movement samples the actual stopped Hero anew")
	if answer.get("accepted", false):
		var state_before: Dictionary = consumer.state()
		var diagnostic: String = scheduler.last_error
		var original: Dictionary = scheduler.sampled_circle_reservation_state(answer.reservation_id)
		_expect(not original.is_empty(), "fresh pure reservation reader validates actual source resources")
		original.adapter.sample.ground_position[0] += 900.0
		_expect(scheduler.sampled_circle_reservation_state(answer.reservation_id).adapter.sample == state_before.sample and scheduler.last_error == diagnostic, "reservation reader returns defensive native data and leaves diagnostics untouched")
		var body: CollisionShape3D = arena.eye.get_node("BodyCollision")
		body.shape = body.shape.duplicate(true)
		var serial_before: int = scheduler.get("_serial")
		_expect(scheduler.sampled_circle_reservation_state(answer.reservation_id).is_empty() and scheduler.get("_serial") == serial_before and consumer.state().status == "running", "same-looking replaced actual source resource makes pure reader empty without pruning")
		await _ticks(1)
		_expect(consumer.state().status == "cancelled" and arena.hero.hp == 100.0, "actual native source identity drift cancels before next consumer contact")
	await _dispose(arena)


func _native_callback(arena: Dictionary, priority: int, callback: Callable, limit: int = 360) -> NativePhysicsCallback:
	var node := NativePhysicsCallback.new()
	node.name = "FocusedNativePhysicsCallback"
	node.process_mode = Node.PROCESS_MODE_PAUSABLE
	node.process_physics_priority = priority
	node.callback = callback
	node.limit = limit
	arena.root.add_child(node)
	return node


func _response_receipt(response: Dictionary) -> Dictionary:
	# Pure value-only diagnostics: retain exact signed knockback remainder and
	# all public stability predicates, without carrying the native actor Object.
	return {"stable": response.get("stable"), "motion": response.get("motion", {}).duplicate(true), "dash_cooldown_left_s": response.get("dash_cooldown_left_s"), "primary_cooldown_left_s": response.get("primary_cooldown_left_s"), "commitment_remaining_s": response.get("commitment_remaining_s"), "action_clock_s": response.get("action_clock_s")}


func _exchange_receipt(record: Dictionary) -> Dictionary:
	var receipt: Dictionary = {}
	for key: String in Consumer.EXCHANGE_KEYS:
		receipt[key] = record.get(key)
	return receipt.duplicate(true)


func _expected_native_phase(now: float, exchange: Dictionary) -> String:
	# Independent deadline oracle at an observed actual scheduler clock, with
	# native inclusive active end; no process-frame count is an active deadline.
	if now < float(exchange.lock_from_s): return "warning"
	if now < float(exchange.active_from_s): return "lock"
	if now <= float(exchange.active_until_s): return "active"
	return "recovery"


func _pure_state(arena: Dictionary) -> Dictionary:
	return {"clock": arena.scheduler.get_clock(), "serial": arena.scheduler.get("_serial"), "reservations": arena.scheduler.get("_reservations").duplicate(true), "cooldowns": arena.scheduler.get("_cooldowns").duplicate(true), "scheduler_error": arena.scheduler.last_error, "scheduler_snapshot_error": arena.scheduler.last_snapshot_error, "consumer": arena.consumer.state(), "consumer_error": arena.consumer.last_error, "consumer_snapshot_error": arena.consumer.last_snapshot_error, "cue": arena.consumer.get_cue().state(), "cue_error": arena.consumer.get_cue().last_error, "eye_hp": arena.eye.hp, "eye_dead": arena.eye.dead, "hero_hp": arena.hero.hp, "hero_position": arena.hero.global_position, "hero_clock": arena.hero.get_world_action_clock()}


func _observe_unit(arena: Dictionary) -> Array:
	var observed: Array = []
	arena.hero.fired.connect(func(kind: String) -> void: observed.append(["fired", kind]))
	arena.hero.died.connect(func() -> void: observed.append(["hero_died"]))
	arena.hero.world_action_executed.connect(func(record: Dictionary) -> void: observed.append(["action", record]))
	arena.eye.damaged.connect(func(result: Dictionary) -> void: observed.append(["eye_damage", result]))
	arena.eye.died.connect(func() -> void: observed.append(["eye_died"]))
	arena.scheduler.reservation_invalidated.connect(func(id: String, reason: String) -> void: observed.append(["invalidated", id, reason]))
	arena.consumer.state_changed.connect(func(value: Dictionary) -> void: observed.append(["state", value]))
	arena.consumer.hit_resolved.connect(func(id: String, cycle: int, result: Dictionary) -> void: observed.append(["hit", id, cycle, result]))
	arena.consumer.get_cue().state_changed.connect(func(value: Dictionary) -> void: observed.append(["cue", value]))
	return observed


func _packet_complete(packet: Dictionary) -> bool:
	for key: String in ["player", "eye", "scheduler", "consumer"]:
		if not packet.get(key) is Dictionary or packet[key].is_empty(): return false
	return true


func _exact_packet(packet: Dictionary) -> Dictionary:
	var encoded: String = ExactJson.stringify(packet)
	var decoded: Dictionary = ExactJson.parse(encoded)
	_expect(not encoded.is_empty() and decoded.get("accepted", false) and Consumer._same_exact(packet, decoded.get("value")), "exact closed transport retains finite scalar bits/types through a real codec roundtrip")
	return decoded.get("value", {})


func _until_phase(consumer: CinderNativeSampledCircle, phase: String, limit: int = 320) -> bool:
	for _index: int in range(limit):
		if consumer.state().phase == phase: return true
		if consumer.state().status == "cancelled": return false
		await _ticks(1)
	return false


func _ticks(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
		await process_frame


func _dispose(arena: Dictionary, retain_pause: bool = false) -> void:
	arena.root.queue_free()
	await process_frame
	await process_frame
	paused = retain_pause


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition: return
	_failures += 1
	push_error(message)
