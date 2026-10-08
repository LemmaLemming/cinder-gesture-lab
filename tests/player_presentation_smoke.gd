extends SceneTree
## Original native artwork and cosmetic invariants. Automated pixels/actor checks
## do not prove portrait scenery readability or physical-device performance.
const Sprite = preload("res://scripts/pixel_sprite.gd")
const Equipment = preload("res://scripts/equipment.gd")
const PlayerScene = preload("res://scenes/player.tscn")
const IDS: Array[String] = ["act1_expedition", "act2_survivor", "act3_traveller"]
var _checks: int = 0
var _failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(540, 1170)
	paused = true
	var arena := Node3D.new()
	root.add_child(arena)
	var actor: CinderPlayer = PlayerScene.instantiate()
	arena.add_child(actor)
	var sprite: LabSprite = actor.get_node("ActorSprite") as LabSprite
	await process_frame
	_expect(sprite.presentation_id == "helmeted_lab" and Sprite.PRESENTATION_IDS.size() == 4, "existing player scene retains the historical helmeted lab default")
	var logical: Dictionary = actor.snapshot_state()
	var historical := Image.new()
	var legacy_matches: bool = historical.load("res://assets/characters/astronomer-weapon-01.png") == OK
	if legacy_matches:
		for row: int in range(Sprite.PLAYER_STATES.size()):
			var state: String = Sprite.PLAYER_STATES[row]
			for direction: int in range(4):
				for frame: int in range(Sprite.PLAYER_FRAME_COUNTS[state]):
					var current: Image = sprite.call("_draw_player_image", direction, state, frame)
					var exported: Image = historical.get_region(Rect2i((direction * 8 + frame) * 48, row * 64, 48, 64))
					legacy_matches = legacy_matches and current.get_data() == exported.get_data()
	_expect(legacy_matches, "all 168 default helmeted lab poses retain the already exported historical pixels")
	var shape: CapsuleShape3D = (actor.get_node("BodyCollision") as CollisionShape3D).shape as CapsuleShape3D
	var collider: Vector2 = Vector2(shape.radius, shape.height)
	var attachments: Dictionary = {}
	for direction: int in range(4):
		for frame: int in range(Sprite.PLAYER_FRAME_COUNTS["blast"]):
			sprite.set("_direction", direction)
			sprite.set_action("blast", (float(frame) + 0.25) / Sprite.PLAYER_FRAME_COUNTS["blast"])
			attachments["%d_%d" % [direction, frame]] = sprite.get_muzzle_pixel_position()
	var action_state: Array = [sprite.get("_action"), sprite.get("_action_frame"), sprite.get("_animation_time"), sprite.get("_direction"), sprite.get("_explicit_action")]
	for act: int in range(1, 4):
		_expect(Sprite.presentation_for_act(act) == IDS[act - 1] and sprite.set_presentation(IDS[act - 1]), "selected act has a stable cosmetic presentation ID")
		_expect([sprite.get("_action"), sprite.get("_action_frame"), sprite.get("_animation_time"), sprite.get("_direction"), sprite.get("_explicit_action")] == action_state, "presentation replacement preserves current action, facing, frame and idle clock")
		_expect(sprite.texture.get_width() == 48 and sprite.texture.get_height() == 64 and sprite.offset == Vector2(0, 32) and is_equal_approx(sprite.pixel_size, 0.0225) and is_equal_approx(sprite.position.y, 0.025) and sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, "act artwork preserves native cell, feet pivot, world scale and pixel filter")
	var current_texture: Texture2D = sprite.texture
	_expect(not sprite.set_presentation("helmet_bonus") and sprite.presentation_id == "act3_traveller" and sprite.texture == current_texture, "unknown presentation cannot create a fifth slot, replace current art or grant gear")
	# Reset only the standalone visual pose, then compare the live actor before
	# and after changing presentation. This never requests an attack or movement.
	sprite.set("_animation_time", 0.0)
	sprite.set_action("idle")
	sprite.face(actor.facing)
	actor.hp = 13.25
	logical = actor.snapshot_state()
	_expect(not logical.is_empty(), "live player invariants compare a real coherent paused snapshot")
	var noncosmetic: Dictionary = _without_presentation_id(logical)
	for id: String in Sprite.PRESENTATION_IDS:
		sprite.set_presentation(id)
		var captured: Dictionary = actor.snapshot_state()
		_expect(_without_presentation_id(captured) == noncosmetic and actor.equipment.snapshot().size() == 4 and Vector2(shape.radius, shape.height) == collider, id + " has no effect on live player resources, timers, gear, action records, action pose or collision")
		_expect(not captured.is_empty() and captured.presentation.id == id and actor.presentation_id == id, id + " snapshot captures the actual sprite selection even when selected directly")
		var captured_pixels: PackedByteArray = sprite.texture.get_image().get_data()
		var other_id: String = "act1_expedition" if id == "helmeted_lab" else "helmeted_lab"
		_expect(actor.set_presentation(other_id) and actor.presentation_id == other_id and sprite.presentation_id == other_id, "player cosmetic API selects the actual sprite before restore")
		_expect(actor.restore_state(captured) and actor.presentation_id == id and sprite.presentation_id == id and sprite.texture.get_image().get_data() == captured_pixels and actor.snapshot_state() == captured, id + " captured selection restores actual artwork and the coherent paused actor without refreshing low HP")
	var legacy: Dictionary = logical.duplicate(true)
	legacy.presentation.erase("id")
	_expect(actor.set_presentation("act3_traveller") and actor.restore_state(legacy) and actor.presentation_id == "helmeted_lab" and sprite.presentation_id == "helmeted_lab" and _without_presentation_id(actor.snapshot_state()) == noncosmetic, "legacy snapshots without a presentation ID restore historical helmeted lab art and all gameplay state")
	var before_invalid: Dictionary = actor.snapshot_state()
	var before_invalid_texture: Texture2D = sprite.texture
	var unknown: Dictionary = before_invalid.duplicate(true)
	unknown.presentation["id"] = "helmet_bonus"
	_expect(not actor.snapshot_error(unknown).is_empty() and not actor.restore_state(unknown) and actor.snapshot_state() == before_invalid and sprite.texture == before_invalid_texture and actor.presentation_id == "helmeted_lab", "unknown snapshot presentation rejects atomically before resources, art, pose or collision change")
	_expect(not actor.set_presentation("helmet_bonus") and actor.snapshot_state() == before_invalid and sprite.texture == before_invalid_texture, "unknown player cosmetic API selection also leaves the live actor and artwork untouched")

	var images: Dictionary = {}
	var gallery := Image.create(48 * 6, 64 * 12, false, Image.FORMAT_RGBA8)
	gallery.fill(Color("44454a"))
	var sample_states: Array[String] = ["idle", "dash", "landing", "primary", "blast", "hurt"]
	var sample_frames: Array[int] = [0, 3, 2, 3, 2, 1]
	var equipment := Equipment.new()
	var kits: Array[Dictionary] = [Equipment.STARTER.duplicate(true)]
	for slot: String in Equipment.SLOTS:
		for item: Dictionary in equipment.available_items(slot):
			if item["id"] != Equipment.STARTER[slot]:
				var kit: Dictionary = Equipment.STARTER.duplicate(true)
				kit[slot] = item["id"]
				kits.append(kit)
	kits.append({"weapon": "WEAPON-04", "jacket": "CLOTH-J1", "pants": "CLOTH-P2", "shoes": "CLOTH-S1"})
	var checked_poses: int = 0
	for id: String in IDS:
		sprite.set_presentation(id)
		var kit_signatures: Dictionary = {}
		for kit: Dictionary in kits:
			sprite.set_loadout_visual(kit["weapon"], kit["jacket"], kit["pants"], kit["shoes"])
			var valid: bool = true
			var frames_distinct: bool = true
			var facings: Array[String] = []
			var signature: String = ""
			for direction: int in range(4):
				var idle: Image = sprite.call("_draw_player_image", direction, "idle", 0)
				facings.append(idle.get_data().hex_encode().sha256_text())
				signature += facings[-1]
				for state: String in Sprite.PLAYER_STATES:
					var hashes: Dictionary = {}
					for frame: int in range(Sprite.PLAYER_FRAME_COUNTS[state]):
						var image: Image = sprite.call("_draw_player_image", direction, state, frame)
						valid = valid and image.get_size() == Vector2i(48, 64) and _grounded_pixels(image) and image.get_used_rect().size.x > 15 and image.get_used_rect().size.y > 40
						hashes[image.get_data().hex_encode().sha256_text()] = true
						checked_poses += 1
						if state == "blast":
							sprite.set("_direction", direction)
							sprite.set_action("blast", (float(frame) + 0.25) / Sprite.PLAYER_FRAME_COUNTS["blast"])
							var tip: Vector2i = sprite.get_muzzle_pixel_position()
							valid = valid and tip == attachments["%d_%d" % [direction, frame]] and image.get_pixelv(tip).a > 0.0
					frames_distinct = frames_distinct and hashes.size() >= 3
			kit_signatures[signature] = true
			_expect(valid and frames_distinct and facings[0] != facings[1] and facings[2] != facings[3], id + " legal kit has grounded, distinct action/facing poses and exact drawn muzzle attachment: " + str(kit))
		_expect(kit_signatures.size() == kits.size(), id + " implemented clothing and weapon appearances remain distinguishable, including the mixed kit")
		sprite.set_loadout_visual("WEAPON-01", "CLOTH-J0", "CLOTH-P0", "CLOTH-S0")
		images[id] = sprite.call("_draw_player_image", 0, "idle", 0)
		for direction: int in range(4):
			for column: int in range(6):
				var image: Image = sprite.call("_draw_player_image", direction, sample_states[column], sample_frames[column])
				gallery.blit_rect(image, Rect2i(0, 0, 48, 64), Vector2i(column * 48, (IDS.find(id) * 4 + direction) * 64))
	_expect(_row_coverage(images["act1_expedition"], 10) >= 27 and _row_coverage(images["act2_survivor"], 10) <= 16 and _row_coverage(images["act3_traveller"], 10) <= 16, "broad expedition hat and uncovered smaller human heads use different production silhouettes")
	_expect(_pale_count(images["act1_expedition"], Rect2i(17, 18, 15, 15)) > _pale_count(images["act2_survivor"], Rect2i(17, 18, 15, 15)), "Act1 keeps a visible pale beard rather than a recoloured visor")
	_expect(_pale_count(images["act3_traveller"], Rect2i(13, 31, 23, 18)) > _pale_count(images["act2_survivor"], Rect2i(13, 31, 23, 18)), "ivory Tormance travelling coat remains distinct from the dark invasion coat and sash")
	var grey_only: bool = true
	for pixel: int in range(48 * 64):
		var colour: Color = (images["act1_expedition"] as Image).get_pixel(pixel % 48, pixel / 48)
		grey_only = grey_only and is_equal_approx(colour.r, colour.g) and is_equal_approx(colour.g, colour.b)
	_expect(grey_only, "Act1 player and carried gear follow the selected monochrome theatre palette")
	var review_path: String = OS.get_user_data_dir().path_join("player-presentation-review.png")
	_expect(gallery.save_png(review_path) == OK, "native review sheet is exported for human/agent visual inspection")
	print("Native presentation review (6 state columns; 4 facing rows per act): " + review_path)
	print("Player presentation smoke: %d checks, %d failures; %d native poses across %d legal kits" % [_checks, _failures, checked_poses, kits.size()])
	arena.queue_free()
	await process_frame
	paused = false
	quit(1 if _failures > 0 else 0)

func _without_presentation_id(snapshot: Dictionary) -> Dictionary:
	var state: Dictionary = snapshot.duplicate(true)
	if state.has("presentation"):
		# Pose and its simulation clock remain part of the invariant. Only the
		# cosmetic selector is permitted to differ between act presentations.
		(state.presentation as Dictionary).erase("id")
	return state

func _grounded_pixels(image: Image) -> bool:
	for x: int in range(48):
		if image.get_pixel(x, 63).a > 0.0: return true
	return false

func _row_coverage(image: Image, y: int) -> int:
	var count: int = 0
	for x: int in range(48):
		if image.get_pixel(x, y).a > 0.0: count += 1
	return count

func _pale_count(image: Image, area: Rect2i) -> int:
	var count: int = 0
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a > 0.0 and minf(pixel.r, minf(pixel.g, pixel.b)) > 0.77: count += 1
	return count

func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(description)
