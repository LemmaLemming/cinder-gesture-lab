extends "res://tests/authored_echo_lifecycle_smoke.gd"
## TEST ONLY controls: one actual paused ready-generation-one packet,
## no admission, terminal receipt, gameplay route or same-owner cycle2 claim.
## The hostile recipient subclass is NOT the production native codec2 Script;
## only the public immutable recipe-preparation boundary is exercised here.
const RestoreInputActor = preload("res://tests/fixtures/authored_echo_restore_input_actor.gd")


func _run() -> void:
	root.size = Vector2i(540, 1170)
	print("TEST ONLY hostile native restore inputs: actual paused ready-gen1 donor, fresh native recipient; no admission/earned history/physical restore/campaign claim")
	var donor: Dictionary = await _arena()
	var saved: Dictionary = _capture(donor, "restore-input-initial-ready")
	_expect(not saved.is_empty() and saved.playback.status == "cycle_ready" and saved.playback.generation is int and saved.playback.generation == 1 and saved.playback.lifecycle.terminal_receipts.is_empty() and saved.scheduler.reservations.is_empty() and saved.source.hp == 32.0 and not donor.actor.dead, "genuine paused initial packet has native HP32 and no admission, consumed event or fabricated terminal history")
	if not saved.is_empty():
		for kind: String in ["cycle", "object", "overbudget", "nan"]:
			await _hostile_restore_input(saved, kind)
		for seam: String in ["enable", "prepare"]:
			await _freed_hero_input(saved, seam)
		await _native_handshake_reentrance()
	await _dispose(donor)
	print("Authored echo restore-input smoke: %d checks, %d failures; initial ready recipe controls only" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _new_input_recipient() -> Dictionary:
	# Same real native floor/Player/Scheduler/camera constructor as the released
	# lifecycle fixture. This fresh paused world never executes next to donor.
	var viewport := SubViewport.new()
	viewport.name = "TestOnlyLifecycleWorld"
	viewport.size = Vector2i(270, 585)
	viewport.own_world_3d = true
	viewport.handle_input_locally = false
	root.add_child(viewport)
	var world := Node3D.new()
	world.name = "NativeWorld"
	viewport.add_child(world)
	var body := StaticBody3D.new()
	body.name = "DryFloor"
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector3(0, -0.5, 0)
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var box := BoxShape3D.new()
	box.size = Vector3(16, 1, 16)
	collision.shape = box
	body.add_child(collision)
	world.add_child(body)
	var camera := Camera3D.new()
	camera.name = "NativeCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 7.2
	world.add_child(camera)
	camera.position = Vector3(0, 18, 13)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var hero = Player.new()
	hero.name = "ActualSharedPlayer"
	world.add_child(hero)
	hero.position = Vector3(0.6, 0.1, 0)
	var scheduler = Scheduler.new()
	scheduler.name = "ActualScheduler"
	world.add_child(scheduler)
	_expect(scheduler.begin_encounter("standard", "test-only/own-echo", 1), "fresh native recipient begins its actual initial encounter while paused")
	var host = InputHost.new()
	host.name = "ActualRecognizerHost"
	host.player = hero
	host.world = world
	host.camera = camera
	root.add_child(host)
	var floors: Array = [{"collision": collision, "safe_rect": Rect2(-8, -8, 16, 16)}]
	var signature: Dictionary = ReplayProjection.floor_signature(world, floors)
	var context: Dictionary = {"world_root": world, "source_id": SOURCE_ID, "source_epoch": EPOCH, "generation": 1, "world_collision_fingerprint": scheduler.pure_collision_fingerprint(world), "world_floor_signature": signature.get("signature", [])}
	var actor = RestoreInputActor.new()
	actor.name = "ActualFixedKnotC52"
	world.add_child(actor)
	var prepared: Dictionary = {"world_revision": 1, "collision_fingerprint": context.world_collision_fingerprint, "floor_signature": context.world_floor_signature}
	_expect(actor.initialize_source(SOURCE_ID, EPOCH, 1, _definition(), "standard", prepared) and actor.attach_source_scheduler(scheduler) and actor.retain_fixture_environment(world, floors), "fresh TEST ONLY input subclass initializes genuine native source/script/renderer resources at the immutable HP32 knot")
	_expect(actor.configure_authored(FIRST_PLAYBACK, actor.source_program(), EPOCH, 1), "fresh input source configures initial authored recipe without managed registration or admission")
	return {"viewport": viewport, "world": world, "floor": collision, "floors": floors, "camera": camera, "host": host, "player": hero, "scheduler": scheduler, "actor": actor, "context": context}


func _hostile_restore_input(saved: Dictionary, kind: String) -> void:
	var fresh: Dictionary = _new_input_recipient()
	var actor = fresh.actor
	var callbacks: Array[String] = []
	actor.state_changed.connect(func(_value: Dictionary) -> void: callbacks.append("state"))
	actor.event_dispatched.connect(func(_event: Dictionary, _receipt: Dictionary) -> void: callbacks.append("event"))
	actor.source_hit_resolved.connect(func(_hit: Dictionary) -> void: callbacks.append("hit"))
	actor.source_defeated.connect(func(_hit: Dictionary) -> void: callbacks.append("defeat"))
	actor.get_enemy_apparition().pose_presented.connect(func(_value: Dictionary) -> void: callbacks.append("renderer"))
	fresh.scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: callbacks.append("invalidation"))
	fresh.player.world_action_executed.connect(func(_value: Dictionary) -> void: callbacks.append("player-action"))
	for cue: Node3D in actor.get_cues(): cue.state_changed.connect(func(_value: Dictionary) -> void: callbacks.append("cue"))
	var before: PackedByteArray = var_to_bytes(_input_probe(fresh))
	var bad: Dictionary = actor.source_definition()
	var loop: Dictionary = {}
	var native_object: RefCounted
	var oversized: Array = []
	match kind:
		"cycle":
			loop["self"] = loop
			bad["raw_role"] = loop
		"object":
			native_object = RefCounted.new()
			bad.raw_role["raw_damage"] = native_object
		"overbudget":
			oversized.resize(CycleReceipt.MAX_CONTAINER_ENTRIES + 1)
			oversized.fill(0.0)
			bad["route"] = oversized
		"nan":
			bad.raw_role["raw_damage"] = NAN
	# Test-only flags are deliberately outside authority/probe state. The hook
	# builds a CLEAN binding then substitutes the actual hostile branch; neither
	# this fixture nor its observer probe recursively serializes hostile input.
	actor.set("_test_restore_input_definition", bad)
	actor.set("_test_restore_input_enabled", true)
	var accepted: bool = actor.prepare_authored_restore(saved.playback, fresh.scheduler, {"hero": fresh.player}, fresh.floors, fresh.context)
	_expect(not accepted and not actor.last_error.is_empty(), kind + " actual native hook rejects preparation with an honest reason before recursive copy/allocation")
	_expect(var_to_bytes(_input_probe(fresh)) == before and callbacks.is_empty(), kind + " failed preparation preserves complete Player/Scheduler/source clocks, HP, original script/mesh/material/cue identities, native renderer pose and empty history without callbacks")
	actor.set("_test_restore_input_enabled", false)
	actor.set("_test_restore_input_definition", null)
	# Break the intentional self-reference and release the native Object exactly;
	# never stringify or deep-copy cyclic/object/overbudget foreign controls.
	loop.clear()
	bad.clear()
	oversized.clear()
	native_object = null
	var clean_before: Dictionary = _input_probe(fresh)
	var recovered: bool = actor.prepare_authored_restore(saved.playback, fresh.scheduler, {"hero": fresh.player}, fresh.floors, fresh.context)
	_expect(recovered, kind + " same actual recipient remains usable for clean bounded native recipe preparation: " + actor.last_error)
	var after: Dictionary = _input_probe(fresh)
	_expect(EnemySequence.exact_equal(after.player, clean_before.player) and EnemySequence.exact_equal(after.scheduler, clean_before.scheduler) and after.resources == clean_before.resources and after.renderer == clean_before.renderer and after.hp == 32.0 and not after.dead and after.source_hits == 0 and callbacks.is_empty(), kind + " clean quiet preparation changes no true native HP/resources/renderer pose, Player/Scheduler clocks or callbacks")
	var recipe: Dictionary = actor.get_authored_cycle_restore_recipe()
	_expect(not recipe.is_empty() and EnemySequence.exact_equal(recipe.lifecycle, saved.playback.lifecycle) and actor.get_authored_cycle_terminal_receipt().is_empty() and fresh.scheduler.authored_cycle_state(actor).is_empty() and actor.get_authored_cycle_generation() == 1, kind + " successful construction has only the exact prepared ready recipe, no earned receipt or committed Scheduler journal")
	await _retire(fresh)


func _freed_hero_input(saved: Dictionary, seam: String) -> void:
	var fresh: Dictionary = _new_input_recipient()
	var callbacks: Array[String] = []
	fresh.actor.state_changed.connect(func(_state: Dictionary) -> void: callbacks.append("state"))
	fresh.actor.event_dispatched.connect(func(_event: Dictionary, _receipt: Dictionary) -> void: callbacks.append("event"))
	fresh.scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: callbacks.append("invalidation"))
	var freed_hero = Player.new()
	freed_hero.name = "TestOnlyFreedHeroInput"
	fresh.world.add_child(freed_hero)
	var heroes: Dictionary = {"hero": freed_hero}
	freed_hero.free()
	_expect(not is_instance_valid(heroes.hero), seam + " control retains the genuinely freed native Hero Variant, no caller proxy")
	var before: PackedByteArray = var_to_bytes(_input_probe(fresh))
	var accepted: bool
	if seam == "enable":
		accepted = fresh.actor.enable_authored_cycle_tracking(fresh.scheduler, heroes, fresh.floors, fresh.context)
	else:
		accepted = fresh.actor.prepare_authored_restore(saved.playback, fresh.scheduler, heroes, fresh.floors, fresh.context)
	_expect(not accepted and not fresh.actor.last_error.is_empty(), seam + " rejects a retained freed Hero honestly before a native cast/access")
	_expect(var_to_bytes(_input_probe(fresh)) == before and callbacks.is_empty(), seam + " freed-Hero rejection preserves the complete actual recipient Player/source/controller/resources/pose/clock/history without callbacks")
	var clean: bool
	if seam == "enable":
		clean = fresh.actor.enable_authored_cycle_tracking(fresh.scheduler, {"hero": fresh.player}, fresh.floors, fresh.context)
	else:
		clean = fresh.actor.prepare_authored_restore(saved.playback, fresh.scheduler, {"hero": fresh.player}, fresh.floors, fresh.context)
	_expect(clean and callbacks.is_empty() and fresh.actor.hp == 32.0 and fresh.actor.source_hits == 0 and fresh.scheduler.get_clock() == 0.0 and fresh.actor.get_authored_cycle_terminal_receipt().is_empty(), seam + " same actual recipient recovers through the matching clean public seam without HP/clock changes or invented earned history: " + fresh.actor.last_error)
	await _retire(fresh)


func _native_handshake_reentrance() -> void:
	var fresh: Dictionary = _new_input_recipient()
	var physical: Dictionary = {"player": fresh.player.snapshot_state(), "resources": _resources(fresh), "renderer": fresh.actor.get_enemy_apparition().native_pose(), "clock": fresh.scheduler.get_clock()}
	var callbacks: Array[String] = []
	fresh.actor.state_changed.connect(func(_state: Dictionary) -> void: callbacks.append("state"))
	fresh.scheduler.reservation_invalidated.connect(func(_id: String, _reason: String) -> void: callbacks.append("invalidation"))
	fresh.actor.set("_test_reentrant_environment_once", true)
	# The synchronous real begin handshake must be unpaused: otherwise the
	# existing pause guard could conceal the omitted update_tracking busy gate.
	# No frame is yielded and no clock/private Scheduler state is assigned.
	paused = false
	var accepted: bool = fresh.actor.enable_authored_cycle_tracking(fresh.scheduler, {"hero": fresh.player}, fresh.floors, fresh.context)
	paused = true
	var trace: Array = fresh.actor.get("_test_reentrant_trace")
	_expect(accepted and trace.size() == 2, "actual native environment getter attempts both public mutations once inside genuine Scheduler initial registration")
	if trace.size() == 2:
		_expect(trace[0].method == "commit_authored_replay" and not trace[0].accepted and trace[0].reason == "Scheduler transaction is already in progress", "nested authored commit rejects at its real managed transaction gate before nonexistent-ID validation")
		_expect(trace[1].method == "update_tracking" and not trace[1].accepted and trace[1].reason == "Unpaused scheduler callback barrier required", "nested tracking update rejects the real managed gate even while unpaused, before nonexistent-ID lookup/pruning")
	var entry: Dictionary = fresh.scheduler.authored_cycle_state(fresh.actor)
	_expect(entry.get("stage", "") == "cycle_ready" and entry.get("generation", 0) == 1 and entry.get("terminal_receipts", [1]).is_empty() and fresh.actor.get_authored_cycle_terminal_receipt().is_empty() and fresh.scheduler.source_control_state(fresh.actor).get("reservations", []).is_empty(), "outer native registration earns only one truthful ready recipe, never an attack/cancellation/history through reentrant getters")
	_expect(EnemySequence.exact_equal(fresh.player.snapshot_state(), physical.player) and _resources(fresh) == physical.resources and fresh.actor.get_enemy_apparition().native_pose() == physical.renderer and fresh.scheduler.get_clock() == physical.clock and callbacks.is_empty(), "synchronous guarded getter instrumentation changes no actual Player/source HP/resources/native pose/clock and emits no observers")
	await _retire(fresh)


func _input_probe(arena: Dictionary) -> Dictionary:
	# Exact native bytes compare the known finite native transforms as well as
	# closed JSON. No hostile hook getter/branch appears in this snapshot.
	var cues: Array = []
	for cue: Node3D in arena.actor.get_cues():
		var parts: Array = []
		for name: String in ["RequiredSourceMarker", "RequiredFootprintOutline", "RequiredFootprintFill"]:
			var part: MeshInstance3D = cue.get_node(name)
			parts.append({"node": part.get_instance_id(), "mesh": part.mesh.get_instance_id() if part.mesh != null else 0, "material": part.material_override.get_instance_id() if part.material_override != null else 0, "visible": part.visible, "transform": part.transform})
		cues.append({"node": cue.get_instance_id(), "state": cue.state(), "visible": cue.visible, "transform": cue.transform, "parts": parts})
	return {"player": arena.player.snapshot_state(), "scheduler": arena.scheduler.snapshot_state(_bindings(arena)), "state": arena.actor.state(), "resources": _resources(arena), "renderer": arena.actor.get_enemy_apparition().native_pose(), "cues": cues, "program": arena.actor.get_authored_cycle_program(), "generation": arena.actor.get_authored_cycle_generation(), "receipt": arena.actor.get_authored_cycle_terminal_receipt(), "recipe": arena.actor.get_authored_cycle_restore_recipe(), "journal": arena.scheduler.authored_cycle_state(arena.actor), "source_clock": arena.actor.source_clock(), "hp": arena.actor.hp, "max_hp": arena.actor.max_hp, "dead": arena.actor.dead, "source_hits": arena.actor.source_hits, "defeated_at_s": arena.actor.defeated_at_s}
