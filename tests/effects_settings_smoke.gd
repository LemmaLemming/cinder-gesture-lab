extends SceneTree
## Settings consumption in real FX nodes, not performance or device evidence.
const Effects = preload("res://scripts/effects.gd")
const Settings = preload("res://scripts/settings/game_settings.gd")
const Smoke = preload("res://scripts/curling_smoke.gd")
const Flare = preload("res://scripts/shotgun_flare.gd")
var _checks: int = 0
var _failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var arena := Node3D.new()
	root.add_child(arena)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 7.2
	arena.add_child(camera)
	camera.global_position = Vector3(0, 18, 13)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var effects: PixelEffects = Effects.new()
	arena.add_child(effects)
	var settings := Settings.new("user://effects-policy-unused/settings.json")
	paused = true
	var voices: Array = effects.get("_voices")
	_expect(voices.size() == Effects.AUDIO_VOICES and AudioServer.get_bus_index("Effects") >= 0, "FX owns six voices and creates the Effects bus if needed")
	var routed: bool = true
	for voice: AudioStreamPlayer in voices:
		routed = routed and voice.bus == "Effects"
	_expect(routed, "every actual procedural audio voice routes to Effects")
	var chunk_counts: Array[int] = []
	var fleck_counts: Array[int] = []
	for quality: String in Settings.QUALITY_IDS:
		effects.clear()
		await process_frame
		_expect(settings.update({"quality": quality, "reduced_motion": false}, false) and effects.configure_policy(settings.cosmetic_policy()), quality + " canonical settings policy is accepted without a live settings global")
		var policy: Dictionary = settings.cosmetic_policy()
		effects.burst(Vector3.ZERO, Color.WHITE, 96)
		chunk_counts.append(effects.active_chunk_count())
		_expect(effects.active_chunk_count() == mini(roundi(96.0 * float(policy["optional_particle_density"])), int(policy["optional_debris_limit"])), quality + " optional physical debris obeys count and hard budget")
		var chunks: Array = effects.get("_chunks")
		var harmless: bool = true
		for chunk: RigidBody3D in chunks:
			harmless = harmless and chunk.collision_layer == 0 and chunk.collision_mask == 1
		_expect(harmless, quality + " cosmetic chunks cannot collide with actors or become a damage layer")
		# Clear optional chunks but retain the current copied policy.
		effects.clear()
		await process_frame
		for index: int in range(20):
			effects.tiny_bleed(Vector3.ZERO, 5)
		fleck_counts.append(effects.active_blood_count())
		_expect(effects.active_blood_count() == int(policy["optional_impact_fleck_limit"]), quality + " optional flecks stay inside their dedicated density budget")
		effects.clear()
		await process_frame
		var decorations: int = 0
		for index: int in range(20):
			if effects.optional_decoration_smoke(Vector3.ZERO, Vector3.LEFT) != null:
				decorations += 1
		_expect(absi(decorations - floori(20.0 * float(policy["decoration_density"]))) <= 1, quality + " decorative emission density is deterministic and bounded")
		effects.clear()
		await process_frame
		await _protected_checks(effects, quality)
	_expect(chunk_counts == [24, 64, 96] and fleck_counts == [8, 16, 24], "quality presets change only the intended optional budgets")
	var accepted: Dictionary = effects.policy_snapshot()
	var malformed: Array[Dictionary] = []
	for changes: Dictionary in [{"quality": "Ultra"}, {"optional_particle_density": INF}, {"optional_debris_limit": 1.5}, {"optional_impact_fleck_limit": 999}, {"camera_shake_scale": -0.1}, {"authoritative_feedback_scale": 0.5}, {"action_feedback_scale": 0.0}, {"nearest_filtering": false}, {"portrait_camera_unchanged": false}, {"simulation_unchanged": false}, {"protected_feedback": []}, {"optional_particle_density": true}]:
		var candidate: Dictionary = accepted.duplicate(true)
		candidate.merge(changes, true)
		malformed.append(candidate)
	var missing: Dictionary = accepted.duplicate(true)
	missing.erase("decoration_density")
	malformed.append(missing)
	for invalid: Dictionary in malformed:
		_expect(not effects.configure_policy(invalid) and effects.policy_snapshot() == accepted and not effects.last_policy_error.is_empty(), "malformed policy cannot replace accepted optional or protected settings")
	var copy: Dictionary = effects.policy_snapshot()
	copy["protected_feedback"].clear()
	copy["optional_debris_limit"] = 0
	_expect(effects.policy_snapshot() == accepted, "policy snapshots have no mutable links to retained FX policy")
	_expect(settings.update({"quality": "High", "reduced_motion": true}, false) and effects.configure_policy(settings.cosmetic_policy()), "reduced motion policy commits atomically")
	effects.burst(Vector3.ZERO, Color.WHITE, 96)
	effects.tiny_bleed(Vector3.ZERO, 5)
	_expect(effects.active_chunk_count() == 0 and effects.active_blood_count() == 0 and effects.optional_decoration_smoke(Vector3.ZERO, Vector3.LEFT) == null and effects.camera_shake_scale() == 0.0, "reduced motion suppresses optional moving decorations and shake")
	_expect(effects.find_child("ImpactConfirmation", true, false) != null, "reduced motion retains immediate impact confirmation even with zero optional debris")
	effects.clear()
	await process_frame
	await _protected_checks(effects, "Reduced motion")
	await _restore_checks(arena, effects)

	# Cleanup is immediate at a paused barrier, before queued node deletion.
	effects.clear()
	await process_frame
	settings.update({"quality": "High", "reduced_motion": false}, false)
	effects.configure_policy(settings.cosmetic_policy())
	effects.burst(Vector3.ZERO, Color.WHITE, 4)
	effects.slash(Vector3.ZERO, Vector3.RIGHT, Color.WHITE)
	effects.muzzle(Vector3.ZERO, Vector3.RIGHT)
	effects.sound("blast")
	var playing: bool = false
	for voice: AudioStreamPlayer in voices:
		playing = playing or voice.playing
	_expect(playing, "cleanup test starts a real procedural audio voice before clearing")
	var old_nodes: Array = (effects.get("_transients") as Array).duplicate()
	var old_chunks: Array = (effects.get("_chunks") as Array).duplicate()
	var old_tweens: Array = []
	for list: Array in (effects.get("_effect_tweens") as Dictionary).values():
		old_tweens.append_array(list)
	effects.clear()
	var stopped: bool = true
	for voice: AudioStreamPlayer in voices:
		stopped = stopped and not voice.playing
	for effect: Node3D in old_nodes:
		stopped = stopped and not effect.visible and not effect.is_processing() and not effect.is_physics_processing()
		if effect.has_signal("finished"):
			stopped = stopped and effect.get_signal_connection_list("finished").is_empty()
	for chunk: RigidBody3D in old_chunks:
		stopped = stopped and chunk.freeze and not chunk.visible
	for tween: Tween in old_tweens:
		stopped = stopped and not tween.is_valid()
	_expect(stopped and effects.active_chunk_count() == 0 and effects.active_transient_count() == 0 and (effects.get("_effect_tweens") as Dictionary).is_empty(), "clear immediately stops voices, kills callbacks, disconnects helper signals, hides FX and freezes debris")
	effects.slash(Vector3.ZERO, Vector3.RIGHT, Color.WHITE)
	await process_frame
	_expect(effects.active_transient_count() == 1 and get_nodes_in_group("cosmetic_slash_arcs").size() == 1, "old deferred cleanup cannot remove a new effect created in the same transition barrier")
	paused = false
	await create_timer(0.35).timeout
	_expect(effects.active_transient_count() == 0 and (effects.get("_effect_tweens") as Dictionary).is_empty(), "normal retirement cleans tracked callbacks as well as effects")
	effects.clear_lab()
	arena.queue_free()
	await process_frame
	print("Effects settings smoke: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)

func _protected_checks(effects: PixelEffects, label: String) -> void:
	effects.clear()
	await process_frame
	effects.slash(Vector3.ZERO, Vector3.RIGHT, Color.WHITE)
	var arc: Node3D = get_nodes_in_group("cosmetic_slash_arcs")[0] as Node3D
	effects.muzzle(Vector3.ZERO, Vector3.RIGHT)
	var flare: Node3D = get_nodes_in_group("shotgun_flares")[0] as Node3D
	var plume: Node3D = effects.dash_trail(Vector3.ZERO, Vector3.RIGHT)
	effects.attack_footprint(Vector3.ZERO, Vector3.RIGHT, 1.2, 0.5, Color.WHITE, 0.23)
	var footprint: MeshInstance3D = effects.find_child("ResolvedAttackFootprint", true, false) as MeshInstance3D
	_expect(arc.get_child_count() == 8 and arc.get_meta("lifetime") == 0.28 and flare.get("lifetime") == Flare.LIFETIME and plume.get("lifetime") == Smoke.DASH_LIFETIME and footprint.mesh != null, label + " preserves full slash, barrel flare, connected plume and resolved footprint geometry/clocks")
	var sprite: Sprite3D = plume.get_node("PixelSmoke") as Sprite3D
	# Sprite3D stores native pixel_size at engine float precision; compare its
	# round trip with tolerance rather than a GDScript double's exact bits.
	_expect(sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST and is_equal_approx(sprite.pixel_size, Smoke.PIXEL_SIZE) and not sprite.no_depth_test, label + " preserves smoke pixel scale, nearest filter and world occlusion")
	var geometry: PackedVector3Array = (footprint.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var lifetime: float = float(plume.get("elapsed"))
	for index: int in range(30):
		effects.tiny_bleed(Vector3.ZERO, 5)
		effects.optional_decoration_smoke(Vector3.ZERO, Vector3.LEFT)
	_expect(is_instance_valid(arc) and not arc.is_queued_for_deletion() and is_instance_valid(flare) and not flare.is_queued_for_deletion() and is_instance_valid(plume) and not plume.is_queued_for_deletion() and not footprint.is_queued_for_deletion(), label + " optional pressure cannot evict required action feedback")
	await process_frame
	_expect(float(plume.get("elapsed")) == lifetime and geometry == (footprint.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX], label + " pause freezes required effect clocks and geometry")
	effects.clear()
	await process_frame

func _restore_checks(arena: Node3D, effects: PixelEffects) -> void:
	var source := Node3D.new()
	arena.add_child(source)
	source.global_position = Vector3(1.25, 0, 0)
	var before: Transform3D = source.global_transform
	var plume: Node3D = effects.restore_dash_trail(source, Vector3.ZERO, Vector3.RIGHT, 0.2, 0.1)
	_expect(plume != null and source.global_transform == before and is_equal_approx(float(plume.get("elapsed")), 0.1) and is_equal_approx(float(plume.get("trail_length_world")), 1.25) and plume.get("emitter_tracking"), "restored connected plume uses actual origin/current head and accepted age without moving the actor")
	_expect((plume.get("tail_world") as Vector3).is_equal_approx(Vector3(-0.12, 0.08, 0)) and (plume.get("head_world") as Vector3).is_equal_approx(Vector3(1.13, 0.08, 0)), "restored plume keeps original ground attachment offsets")
	source.global_position = Vector3(1.5, 0, 0)
	plume.call("sample_emitter")
	plume.call("finish_tracking")
	var landing: Vector3 = plume.get("head_world")
	source.global_position = Vector3(9, 0, 0)
	plume.call("sample_emitter")
	_expect((plume.get("head_world") as Vector3) == landing and is_equal_approx(float(plume.get("trail_length_world")), 1.5), "restored plume latches the actual landing and later movement cannot lengthen it")
	var count: int = effects.active_transient_count()
	_expect(effects.restore_dash_trail(source, Vector3.ZERO, Vector3.RIGHT, 0.2, 0.3) == null and effects.restore_dash_trail(source, Vector3.ZERO, Vector3.RIGHT, INF, 0.1) == null and effects.active_transient_count() == count, "invalid visual restore requests create no effect or action")
	effects.retire_effect(plume)
	_expect(not plume.visible and plume.get("_emitter") == null and effects.active_transient_count() == 0, "actor presentation replacement releases the old emitter and its registry entry immediately")
	source.queue_free()
	await process_frame

func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(description)
