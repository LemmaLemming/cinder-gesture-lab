extends RefCounted
## Original deterministic pixel-cluster artwork adapted from inspected selected
## concept boards. No board pixels are imported; IDs are cosmetic, never gear.
const IDS: Array[String] = ["helmeted_lab", "act1_expedition", "act2_survivor", "act3_traveller"]
const OUTLINE: Color = Color("101218")
const INK: Color = Color("202229")
const GREY: Color = Color("666b70")
const PALE: Color = Color("e8e7df")
const SILVER: Color = Color("a8adb0")

static func for_act(act: int) -> String:
	return {1: "act1_expedition", 2: "act2_survivor", 3: "act3_traveller"}.get(act, "helmeted_lab")

static func finish_palette(image: Image, id: String) -> void:
	if id != "act1_expedition": return
	# Selected lunar theatre is neutral grayscale, including carried gear.
	for y: int in range(64):
		for x: int in range(48):
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a > 0.0:
				var grey: float = (pixel.r + pixel.g + pixel.b) / 3.0
				image.set_pixel(x, y, Color(grey, grey, grey, pixel.a))

static func draw_body(image: Image, id: String, direction: int, state: String, frame: int, lean: int, crouch: int, breath: int, torso_y: int, pose: Dictionary, gear: Dictionary) -> void:
	var lunar: bool = id == "act1_expedition"
	var tormance: bool = id == "act3_traveller"
	var coat: Color = Color("d9d6c5") if tormance else Color("2b2d32")
	var shade: Color = Color("96978c") if tormance else Color("171a21")
	var light: Color = Color("f2efe2") if tormance else Color("535961")
	var trousers: Color = Color("555960") if lunar else Color("292c35")
	var skin: Color = Color("bcbdb8") if lunar else (Color("a6a197") if tormance else Color("c2ad96"))
	if gear["jacket"] == "CLOTH-J1":
		coat = coat.lightened(0.12)
		light = light.lightened(0.12)
	elif gear["jacket"] == "CLOTH-J2":
		coat = coat.darkened(0.07)
	if gear["pants"] == "CLOTH-P1":
		trousers = trousers.lightened(0.17)
	elif gear["pants"] == "CLOTH-P2":
		trousers = trousers.lightened(0.07)
	var legs: Array = [16, 27]
	var raised: int = -1
	if state == "dash":
		legs = [[12, 29], [10, 31], [11, 30], [13, 29], [15, 28], [16, 27]][frame]
		raised = 1 if frame < 3 else 0
	for index: int in range(2):
		var x: int = legs[index]
		var lift: int = 2 if index == raised else 0
		_rect(image, x - 1, 42 + crouch, 9, 18 - crouch - lift, OUTLINE)
		_rect(image, x, 43 + crouch, 7, 15 - crouch - lift, trousers)
		_rect(image, x + 5, 45 + crouch, 2, 12 - crouch - lift, shade)
		_rect(image, x + 1, 45 + crouch, 1, 10 - crouch - lift, light)
		if gear["pants"] == "CLOTH-P1":
			_rect(image, x + 3, 45 + crouch, 1, 9 - crouch, SILVER)
		elif gear["pants"] == "CLOTH-P2":
			_rect(image, x - 1, 45 + crouch, 4, 5, OUTLINE)
			_rect(image, x, 46 + crouch, 3, 3, GREY)
		_draw_boot(image, x - 2, 56 - lift, String(gear["shoes"]), index)

	# Period coat tails form new body silhouettes rather than retaining a suit's
	# chest unit, rear life-support pack, protective knees or neck seal.
	var cx: int = 24 + lean
	var billow: int = [1, 3, 4, 3, 2, 0][frame] if state == "dash" else 0
	var left_tail: int = cx - 13 - (billow if direction == 3 else 0)
	var right_tail: int = cx + 13 + (billow if direction == 2 else 0)
	_polygon(image, PackedVector2Array([Vector2(cx - 9, torso_y + 9), Vector2(left_tail - 1, 54), Vector2(cx - 2, 52), Vector2(cx + 2, torso_y + 12)]), OUTLINE)
	_polygon(image, PackedVector2Array([Vector2(cx + 9, torso_y + 9), Vector2(right_tail + 1, 54), Vector2(cx + 2, 52), Vector2(cx - 2, torso_y + 12)]), OUTLINE)
	_polygon(image, PackedVector2Array([Vector2(cx - 8, torso_y + 11), Vector2(left_tail + 1, 52), Vector2(cx - 3, 50), Vector2(cx, torso_y + 13)]), coat)
	_polygon(image, PackedVector2Array([Vector2(cx + 8, torso_y + 11), Vector2(right_tail - 1, 52), Vector2(cx + 3, 50), Vector2(cx, torso_y + 13)]), shade if direction != 2 else coat)
	_line(image, Vector2i(cx - 6, torso_y + 14), Vector2i(left_tail + 3, 50), light, 1)
	_line(image, Vector2i(cx + 6, torso_y + 14), Vector2i(right_tail - 3, 50), light, 1)
	var body_x: int = (16 if direction > 1 else 13) + lean
	var body_width: int = 17 if direction > 1 else 23
	if gear["jacket"] == "CLOTH-J1":
		body_x -= 1
		body_width += 2
	_rounded(image, body_x, torso_y, body_width, 22 - crouch, OUTLINE)
	_rounded(image, body_x + 1, torso_y + 1, body_width - 2, 20 - crouch, coat)
	_rect(image, body_x + body_width - 4, torso_y + 3, 2, 17 - crouch, shade)
	_rect(image, body_x + 2, torso_y + 3, 1, 16 - crouch, light)
	if direction == 1:
		_rect(image, cx, torso_y + 3, 1, 16 - crouch, shade)
		_rect(image, cx - 5, torso_y + 16 - crouch, 10, 2, shade)
		_rect(image, cx - 4, torso_y + 16 - crouch, 2, 1, SILVER)
		_rect(image, cx + 3, torso_y + 16 - crouch, 2, 1, SILVER)
	else:
		var chest: int = cx if direction == 0 else cx + (-4 if direction == 2 else 4)
		_polygon(image, PackedVector2Array([Vector2(chest - 4, torso_y + 1), Vector2(chest + 4, torso_y + 1), Vector2(chest + 2, torso_y + 16), Vector2(chest - 2, torso_y + 16)]), INK if tormance else GREY)
		_line(image, Vector2i(chest - 6, torso_y + 2), Vector2i(chest - 2, torso_y + 12), light, 2)
		_line(image, Vector2i(chest + 5, torso_y + 2), Vector2i(chest + 2, torso_y + 12), light, 2)
		for button_y: int in range(torso_y + 7, torso_y + 18, 4):
			_rect(image, chest, button_y, 1, 1, PALE if lunar else shade)
		_rect(image, chest - 7, torso_y + 15, 4, 1, light)
		_rect(image, chest + 3, torso_y + 15, 4, 1, shade)
	if gear["jacket"] == "CLOTH-J1":
		_rect(image, body_x + 2, torso_y + 3, 5, 3, SILVER)
		_rect(image, body_x + body_width - 7, torso_y + 3, 5, 3, SILVER)
	elif gear["jacket"] == "CLOTH-J2":
		for stitch_y: int in range(torso_y + 5, torso_y + 19, 3):
			_rect(image, body_x + 3, stitch_y, 1, 1, PALE)
			_rect(image, body_x + body_width - 5, stitch_y, 1, 1, PALE)
	if id == "act2_survivor":
		var sash_from := Vector2i(cx - 7, torso_y + 1)
		var sash_to := Vector2i(cx + 5, torso_y + 18)
		if direction == 2:
			sash_from.x = cx + 3
			sash_to.x = cx - 5
		_line(image, sash_from, sash_to, OUTLINE, 5)
		_line(image, sash_from, sash_to, PALE, 3)
		_rect(image, sash_to.x - 2, sash_to.y, 4, 2, SILVER)

	var active_hand: Vector2i = pose["hand"]
	var left_hand := Vector2i(11 + lean, torso_y + 18 - crouch)
	var right_hand := Vector2i(37 + lean, torso_y + 18 - crouch)
	if state == "idle":
		var arm: int = [0, 1, 1, 1, 0, -1, -1, 0][frame]
		left_hand.x += arm
		right_hand.x -= arm
	if state == "dash":
		left_hand.y -= [1, 3, 4, 3, 2, 0][frame]
	if state == "primary" or state == "blast":
		if direction == 2: left_hand = active_hand
		else: right_hand = active_hand
		if state == "blast": left_hand = active_hand + Vector2i(-3, 2) if direction != 2 else active_hand
	_draw_arm(image, Vector2i(16 + lean, torso_y + 4), left_hand, coat, light, skin)
	_draw_arm(image, Vector2i(33 + lean, torso_y + 4), right_hand, coat, light, skin)
	_rect(image, cx - 3, torso_y - 5, 6, 7, OUTLINE)
	_rect(image, cx - 2, torso_y - 4, 4, 6, skin)
	_polygon(image, PackedVector2Array([Vector2(cx - 8, torso_y - 2), Vector2(cx - 2, torso_y - 4), Vector2(cx, torso_y + 3), Vector2(cx - 5, torso_y + 2)]), PALE)
	_polygon(image, PackedVector2Array([Vector2(cx + 8, torso_y - 2), Vector2(cx + 2, torso_y - 4), Vector2(cx, torso_y + 3), Vector2(cx + 5, torso_y + 2)]), PALE if lunar or tormance else SILVER)
	_draw_head(image, id, direction, cx, 14 + crouch - breath, skin)

static func _draw_head(image: Image, id: String, direction: int, cx: int, cy: int, skin: Color) -> void:
	var lunar: bool = id == "act1_expedition"
	var front: int = -1 if direction == 2 else 1
	_rounded(image, cx - 7, cy - 5, 14, 15, OUTLINE)
	if direction == 1:
		_rounded(image, cx - 6, cy - 5, 12, 13, INK)
		_rect(image, cx - 4, cy - 4, 2, 4, GREY)
		_rect(image, cx - 4, cy + 7, 8, 2, PALE if lunar else skin.darkened(0.2))
	else:
		_rounded(image, cx - 5, cy - 3, 10, 12, skin)
		_rect(image, cx + 3, cy, 2, 7, skin.darkened(0.25))
		if direction == 0:
			_rect(image, cx - 4, cy, 3, 1, OUTLINE)
			_rect(image, cx + 2, cy, 3, 1, OUTLINE)
			_rect(image, cx, cy + 1, 2, 3, skin.lightened(0.12))
			_rect(image, cx - 2, cy + 6, 4, 1, OUTLINE)
		else:
			var nose_x: int = cx + 6 if front > 0 else cx - 9
			_rect(image, nose_x, cy + 1, 4, 3, OUTLINE)
			_rect(image, nose_x + (0 if front > 0 else 1), cy + 1, 3, 2, skin)
			_rect(image, cx + front * 4, cy, 2, 1, OUTLINE)
			_rect(image, cx - front * 3, cy + 2, 2, 4, skin.darkened(0.15))
	if lunar:
		if direction != 1:
			var beard_cx: int = cx if direction == 0 else cx + front * 3
			_polygon(image, PackedVector2Array([Vector2(beard_cx - 6, cy + 4), Vector2(beard_cx + 6, cy + 4), Vector2(beard_cx + 4, cy + 13), Vector2(beard_cx + 1, cy + 17), Vector2(beard_cx - 3, cy + 13)]), PALE)
			_line(image, Vector2i(beard_cx - 2, cy + 6), Vector2i(beard_cx - 1, cy + 13), SILVER, 1)
			_line(image, Vector2i(beard_cx + 3, cy + 7), Vector2i(beard_cx + 2, cy + 12), SILVER, 1)
			_rect(image, beard_cx - 3, cy + 4, 7, 2, PALE)
		# Broad flat brim and a stepped crown, never a round shell or visor.
		_ellipse(image, cx, cy - 4, 14, 2, OUTLINE)
		_rect(image, cx - 12, cy - 5, 24, 1, GREY)
		_rounded(image, cx - 6, cy - 12, 12, 8, OUTLINE)
		_rect(image, cx - 5, cy - 11, 10, 6, INK)
		_rect(image, cx - 4, cy - 11, 3, 2, GREY)
		_rect(image, cx - 5, cy - 6, 10, 1, SILVER)
	else:
		var hair_height: int = 7 if id == "act2_survivor" else 6
		_rounded(image, cx - 6, cy - 7, 12, hair_height, OUTLINE)
		_rect(image, cx - 4, cy - 6, 8, hair_height - 2, INK)
		_rect(image, cx - 3, cy - 6, 2, 2, GREY)
		if id == "act2_survivor":
			_rect(image, cx - 5, cy - 8, 4, 2, OUTLINE)
			_rect(image, cx + 1, cy - 8, 3, 2, INK)
		if direction > 1:
			_rect(image, cx - front * 5, cy - 1, 2, 5, INK)

static func _draw_boot(image: Image, x: int, y: int, id: String, index: int) -> void:
	var toe: int = x - 1 if index == 0 else x
	_rect(image, x, y - 1, 9, 6, OUTLINE)
	_rect(image, x + 1, y, 7, 4, INK)
	_rect(image, x + 2, y, 2, 3, GREY)
	_rounded(image, toe, y + 3, 11, 5, OUTLINE)
	_rect(image, toe + 1, y + 3, 8, 2, INK)
	_rect(image, toe + 1, y + 6, 9, 1, GREY)
	if id == "CLOTH-S1":
		_rect(image, toe + 1, y + 5, 9, 1, SILVER)
		_rect(image, x + 1, y - 1, 7, 1, SILVER)
	elif id == "CLOTH-S2":
		_rect(image, toe, y + 4, 11, 2, GREY)
		for lug_x: int in range(toe + 1, toe + 10, 3):
			_rect(image, lug_x, y + 7, 2, 1, INK)

static func _draw_arm(image: Image, shoulder: Vector2i, hand: Vector2i, coat: Color, light: Color, skin: Color) -> void:
	var elbow := Vector2i((shoulder.x + hand.x) / 2, (shoulder.y + hand.y) / 2 - 1)
	_line(image, shoulder, elbow, OUTLINE, 7)
	_line(image, elbow, hand, OUTLINE, 6)
	_line(image, shoulder, elbow, coat, 5)
	_line(image, elbow, hand, coat, 4)
	_line(image, elbow + Vector2i(-1, 0), hand + Vector2i(-1, 0), light, 1)
	_rect(image, hand.x - 3, hand.y - 1, 6, 3, PALE)
	_rounded(image, hand.x - 2, hand.y + 1, 5, 5, OUTLINE)
	_rect(image, hand.x - 1, hand.y + 1, 3, 3, skin)

static func _rect(image: Image, x: int, y: int, width: int, height: int, colour: Color) -> void:
	if width <= 0 or height <= 0: return
	var area := Rect2i(x, y, width, height).intersection(Rect2i(0, 0, 48, 64))
	if area.has_area(): image.fill_rect(area, colour)

static func _rounded(image: Image, x: int, y: int, width: int, height: int, colour: Color) -> void:
	_rect(image, x + 1, y, width - 2, height, colour)
	_rect(image, x, y + 1, width, height - 2, colour)

static func _line(image: Image, start: Vector2i, end: Vector2i, colour: Color, thickness: int) -> void:
	var steps: int = maxi(absi(end.x - start.x), absi(end.y - start.y))
	for index: int in range(steps + 1):
		var point: Vector2 = Vector2(start).lerp(Vector2(end), float(index) / maxi(steps, 1)).round()
		_rect(image, int(point.x) - thickness / 2, int(point.y) - thickness / 2, thickness, thickness, colour)

static func _ellipse(image: Image, cx: int, cy: int, rx: int, ry: int, colour: Color) -> void:
	for y: int in range(-ry, ry + 1):
		var extent: int = int(sqrt(maxf(0.0, 1.0 - pow(float(y) / ry, 2))) * rx)
		_rect(image, cx - extent, cy + y, extent * 2 + 1, 1, colour)

static func _polygon(image: Image, points: PackedVector2Array, colour: Color) -> void:
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points: bounds = bounds.expand(point)
	for y: int in range(maxi(0, floori(bounds.position.y)), mini(64, ceili(bounds.end.y))):
		for x: int in range(maxi(0, floori(bounds.position.x)), mini(48, ceili(bounds.end.x))):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				image.set_pixel(x, y, colour)
