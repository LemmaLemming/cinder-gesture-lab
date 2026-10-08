extends SceneTree
## Regenerate the existing helmeted lab sheets, not future act presentations.
## Helmet assertions below verify this asset's provenance; they are not a
## campaign-wide headwear requirement. Shared dimensions/feet remain invariant.

const SpriteScript = preload("res://scripts/pixel_sprite.gd")


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/characters")
	var sprite: LabSprite = SpriteScript.new()
	sprite.setup("player")
	for weapon_index: int in range(1, 5):
		var weapon_id: String = "WEAPON-%02d" % weapon_index
		sprite.set_loadout_visual(weapon_id, "CLOTH-J0", "CLOTH-P0", "CLOTH-S0")
		var atlas := Image.create(1536, 384, false, Image.FORMAT_RGBA8)
		atlas.fill(Color.TRANSPARENT)
		for state_index: int in range(LabSprite.PLAYER_STATES.size()):
			for direction: int in range(4):
				for frame: int in range(LabSprite.PLAYER_FRAME_COUNTS[LabSprite.PLAYER_STATES[state_index]]):
					var pose: Image = sprite._draw_player_image(direction, LabSprite.PLAYER_STATES[state_index], frame)
					if pose == null or pose.is_empty():
						push_error("Character pose generation failed")
						quit(1)
						return
					atlas.blit_rect(pose, Rect2i(0, 0, 48, 64), Vector2i((direction * 8 + frame) * 48, state_index * 64))
		var path: String = "res://assets/characters/astronomer-weapon-%02d.png" % weapon_index
		var result: Error = atlas.save_png(path)
		if result != OK:
			push_error("Character sheet export failed: " + path)
			quit(1)
			return
		print("Exported ", path)
		if weapon_index == 1:
			var preview: Image = atlas.duplicate()
			preview.resize(3072, 768, Image.INTERPOLATE_NEAREST)
			preview.save_png("res://docs/character-atlas-preview.png")
			var turnaround := Image.create(192, 64, false, Image.FORMAT_RGBA8)
			turnaround.fill(Color.TRANSPARENT)
			for direction: int in range(4):
				turnaround.blit_rect(sprite._draw_player_image(direction, "idle", 0), Rect2i(0, 0, 48, 64), Vector2i(direction * 48, 0))
			turnaround.save_png("res://assets/characters/astronaut-turnaround-pixels.png")
			turnaround.resize(1152, 384, Image.INTERPOLATE_NEAREST)
			turnaround.save_png("res://docs/character-turnaround-preview.png")
	_export_equipment_review(sprite)
	sprite.free()
	quit(0)


func _export_equipment_review(sprite: LabSprite) -> void:
	var reviewed: Array[Dictionary] = []
	for slot: String in ["weapon", "jacket", "pants", "shoes"]:
		var prefix: String = "WEAPON-" if slot == "weapon" else {"jacket": "CLOTH-J", "pants": "CLOTH-P", "shoes": "CLOTH-S"}[slot]
		var first: int = 1 if slot == "weapon" else 0
		var last: int = 5 if slot == "weapon" else 3
		for index: int in range(first, last):
			var kit: Dictionary = {"weapon": "WEAPON-01", "jacket": "CLOTH-J0", "pants": "CLOTH-P0", "shoes": "CLOTH-S0"}
			var item: String = prefix + ("%02d" % index if slot == "weapon" else str(index))
			kit[slot] = item
			kit["reviewed_id"] = item
			reviewed.append(kit)
	reviewed.append({"weapon": "WEAPON-03", "jacket": "CLOTH-J1", "pants": "CLOTH-P2", "shoes": "CLOTH-S2", "reviewed_id": "MIXED-STATIC-KIT"})
	var review := Image.create(1152, reviewed.size() * 64, false, Image.FORMAT_RGBA8)
	review.fill(Color.TRANSPARENT)
	var total_poses: int = 0
	for row: int in range(reviewed.size()):
		var kit: Dictionary = reviewed[row]
		sprite.set_loadout_visual(kit["weapon"], kit["jacket"], kit["pants"], kit["shoes"])
		for state_index: int in range(LabSprite.PLAYER_STATES.size()):
			var state: String = LabSprite.PLAYER_STATES[state_index]
			for direction: int in range(4):
				for frame: int in range(LabSprite.PLAYER_FRAME_COUNTS[state]):
					var pose: Image = sprite._draw_player_image(direction, state, frame)
					assert(pose.get_width() == 48 and pose.get_height() == 64)
					var foot_pixels: int = 0
					var shell_pixels: int = 0
					var visor_pixels: int = 0
					for x: int in range(48):
						if pose.get_pixel(x, 63).a > 0.0:
							foot_pixels += 1
						for y: int in range(27):
							var pixel: Color = pose.get_pixel(x, y)
							if pixel.to_html(false) == LabSprite.SUIT_WHITE.to_html(false):
								shell_pixels += 1
							if pixel.to_html(false) == LabSprite.VISOR.to_html(false):
								visor_pixels += 1
					assert(foot_pixels >= 8, "Every pose retains floor contact at the shared pivot")
					assert(shell_pixels > 30, "This lab export retains its authored helmet shell")
					assert(direction == 1 or visor_pixels > 25, "This lab export retains its authored visor facing")
					total_poses += 1
					var shown_frame: int = 2 if state == "primary" or state == "dash" else 0
					if frame == shown_frame:
						review.blit_rect(pose, Rect2i(0, 0, 48, 64), Vector2i((state_index * 4 + direction) * 48, row * 64))
	review.save_png("res://assets/characters/equipment-review.png")
	var record := FileAccess.open("res://assets/characters/equipment-review.json", FileAccess.WRITE)
	record.store_string(JSON.stringify({"rows": reviewed, "columns": "idle,dash,landing,primary,blast,hurt; front/back/left/right within each state", "native_cell_pixels": [48,64], "all_frames_checked": total_poses, "checks": ["dimensions", "foot_contact", "helmet_shell", "visor_facing"]}, "  ") + "\n")
	print("Reviewed ", total_poses, " poses across all 13 static item appearances and one mixed outfit")
