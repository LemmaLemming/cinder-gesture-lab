extends SceneTree
## Noninteractive still-art scale study in the actual shared portrait shell.
## This does not add a Stalker to either runtime level or validate an encounter,
## attack/cue state, animation, damage, lunge or final character presentation.
## Run through dev.py engine --path . --script this file, without --capture.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const RoomPath: String = "res://scenes/acts/act3/a3_l1_sun_room.tscn"
const SourcePath: String = "res://assets/acts/act3/sunbound-stalker-branchspell.png"
const RecoveryPath: String = "res://assets/acts/act3/sunbound-stalker-recovery.png"
const OutputPath: String = "res://captures/act3/twin-suns"
const NativePivot: Vector2i = Vector2i(635, 1051)
const SpriteOffset: Vector2 = Vector2(-8, 424)
const VisibleHeightPixels: float = 1051.0 - 244.0
const StudyDistance: float = 2.3

var _failed: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game: Node = MainScene.instantiate()
	game.set("level_scene_path", RoomPath)
	root.add_child(game)
	await _ticks(game, 15)
	var level: CinderLevel = game.get("active_level") as CinderLevel
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	var texture: Texture2D = load(SourcePath) as Texture2D
	if level == null or hero == null or texture == null:
		push_error("Stalker art scale study requires the shared room/player and imported source texture")
		_failed = true
	else:
		var ahead: Vector3 = hero.global_position + Vector3.FORWARD * StudyDistance
		var floor_body: StaticBody3D = (level.get("scenery") as Node).get("floor_body") as StaticBody3D
		var query := PhysicsRayQueryParameters3D.create(ahead + Vector3.UP * 0.3, ahead - Vector3.UP * 0.3, 1)
		var floor_hit: Dictionary = hero.get_world_3d().direct_space_state.intersect_ray(query)
		if floor_hit.is_empty() or floor_hit.get("collider") != floor_body:
			push_error("Stalker art scale study point lacks the authored safe floor")
			_failed = true
		else:
			var study := Node3D.new()
			study.name = "NoninteractiveStalkerArtScaleStudy"
			level.add_child(study)
			study.global_position = Vector3(ahead.x, (floor_hit["position"] as Vector3).y, ahead.z)
			var sprite := Sprite3D.new()
			sprite.name = "GeneratedStillArt"
			sprite.texture = texture
			sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
			sprite.alpha_scissor_threshold = 0.5
			sprite.no_depth_test = false
			sprite.shaded = false
			sprite.offset = SpriteOffset
			sprite.position.y = 0.025
			study.add_child(sprite)
			var shadow := MeshInstance3D.new()
			shadow.name = "FilledScenicContactShadow"
			var disk := CylinderMesh.new()
			disk.height = 0.006
			disk.radial_segments = 12
			shadow.mesh = disk
			shadow.position.y = 0.009
			shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.albedo_color = Color("17131f")
			shadow.material_override = material
			study.add_child(shadow)
			# Sprite and filled floor contact are visual-only: no target group,
			# collider, signal hookup, damage receiver or runtime scene mutation.
			print("ART SCALE STUDY ONLY: %s; native %dx%d; feet pivot %s; offset %s; visible source Y244..1051; %0.2f units ahead" % [SourcePath, texture.get_width(), texture.get_height(), NativePivot, SpriteOffset, StudyDistance])
			print("LIMITATIONS: one generated Branchspell still pose; no animation, encounter/cue or damage validation. Shared player remains the helmeted lab presentation.")
			for candidate: float in [1.1, 1.35]:
				sprite.pixel_size = candidate / VisibleHeightPixels
				disk.top_radius = 0.34
				disk.bottom_radius = disk.top_radius
				level.objective_text = "ART SCALE STUDY / STALKER %.2f" % candidate
				await _ticks(game, 3)
				await _save("06-stalker-art-scale-110.png" if candidate == 1.1 else "07-stalker-art-scale-135.png")
				print("ART SCALE CANDIDATE: visible height %.2f world units; body/low seam against shared player, tree and filled floor contact" % candidate)
			var recovery_texture: Texture2D = load(RecoveryPath) as Texture2D
			if recovery_texture == null:
				push_error("Stalker recovery art study requires its imported source texture")
				_failed = true
			else:
				# Keep anatomy at the preparation family's pixel scale: settling
				# lowers visible height, rather than enlarging the recovery body.
				sprite.texture = recovery_texture
				sprite.offset = Vector2(-8, 433)
				sprite.pixel_size = 1.35 / VisibleHeightPixels
				level.objective_text = "ART STUDY / SETTLED RECOVERY"
				await _ticks(game, 3)
				await _save("09-stalker-art-recovery.png")
				print("ART RECOVERY STUDY: native pivot (635,1060); same %.8f units per pixel; one decorative pose swap only" % sprite.pixel_size)
	game.queue_free()
	paused = false
	await process_frame
	print("Stalker art scale study: %s; outputs %s" % ["failed" if _failed else "complete", ProjectSettings.globalize_path(OutputPath)])
	quit(1 if _failed else 0)


func _ticks(game: Node, count: int) -> void:
	for _index: int in range(count):
		if paused:
			game.call("resume_lab")
		await physics_frame
		await process_frame


func _save(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OutputPath))
	if error != OK:
		push_error("Could not create Stalker art scale-study capture directory: %s" % error)
		_failed = true
		return
	var rendered: Image = root.get_texture().get_image()
	var path: String = OutputPath.path_join(filename)
	if rendered == null or rendered.is_empty() or rendered.save_png(path) != OK:
		push_error("Could not save actual Stalker art scale study: " + path)
		_failed = true
		return
	print("ART SCALE STUDY CAPTURE: ", ProjectSettings.globalize_path(path))
