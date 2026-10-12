class_name CinderMenuScenery
extends Control
## Decorative menu pixels only. Root supplies actual act/reveal context.
## No player/equipment/Registry reference, scene load, input, signal, RNG or clock.
## The existing shared48x64 TextureRect remains outside this drawing consumer.

const API_REVISION: String = "menu-scenery-1"
const TITLE_GRID := Vector2i(160, 88)
const ROUTE_GRID := Vector2i(160, 360)
const PALETTES: Array[Dictionary] = [
	{"sky": "11161c", "far": "252d35", "shade": "37414a", "light": "637079", "accent": "819096", "soil": "1b2229"},
	{"sky": "191418", "far": "2c2023", "shade": "493035", "light": "73504a", "accent": "9b6654", "soil": "211b1d"},
	{"sky": "171422", "far": "272138", "shade": "3d3051", "light": "5a4b6c", "accent": "817b57", "soil": "211d2c"},
]
var _act: int = 1
var _mode: String = "title"
var _revealed: bool = true
var _earth_launch: bool = true


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true
	set_process(false)
	set_physics_process(false)


func configure(act: int, mode: String = "title", revealed: bool = true, earth_launch: bool = false) -> bool:
	if act < 1 or act > 3 or mode not in ["title", "route"] or (earth_launch and act != 1):
		return false
	_act = act
	_mode = mode
	_revealed = revealed
	_earth_launch = earth_launch
	queue_redraw()
	return true


func presentation_state() -> Dictionary:
	var metrics: Dictionary = _metrics()
	var motifs: Array[String] = _motif_ids()
	return {"api_revision": API_REVISION, "act": _act, "mode": _mode, "revealed": _revealed, "earth_launch": _earth_launch, "motif_ids": motifs, "palette": PALETTES[_act - 1].duplicate(true), "grid": metrics, "mouse_filter": mouse_filter, "focus_mode": focus_mode, "texture_filter": texture_filter, "animated": false, "owns_traveller_texture": false, "gameplay_or_interaction": false}


func _motif_ids() -> Array[String]:
	if not _revealed: return ["abstract_edge_terrain"]
	if _act == 1:
		if _mode == "route": return ["observatory_roof", "finless_shell"] if _earth_launch else ["painted_rock_flats", "distant_astronomy"]
		return ["earth_roof", "finless_shell", "telescope"] if _earth_launch else ["painted_rock_flats", "finless_shell", "distant_astronomy"]
	if _act == 2: return ["broken_masonry", "buried_cylinder", "red_weed_clusters"]
	return ["white_blue_sun_discs", "organic_ridge", "quiet_crystal"]


func traveller_rect() -> Rect2:
	if _mode != "title": return Rect2()
	var metrics: Dictionary = _metrics()
	if not metrics.fits: return Rect2()
	var origin := Vector2(float(metrics.origin[0]), float(metrics.origin[1]))
	var step: float = float(metrics.pixel_step)
	# Same shared source feet pivot(24,64): rect56,14 yields centre80/feet78.
	return Rect2(origin + Vector2(56, 14) * step, Vector2(48, 64) * step)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED: queue_redraw()


func _metrics() -> Dictionary:
	var grid: Vector2i = TITLE_GRID if _mode == "title" else ROUTE_GRID
	var step: int = maxi(1, int(floor(minf(size.x / float(grid.x), size.y / float(grid.y)))))
	return {"virtual_size": [grid.x, grid.y], "pixel_step": step, "origin": [int(floor((size.x - float(grid.x * step)) * .5)), int(floor((size.y - float(grid.y * step)) * .5))], "fits": size.x >= float(grid.x * step) and size.y >= float(grid.y * step), "traveller_foot_virtual": [80, 78] if _mode == "title" else [], "route_central_reserve_virtual": [24, 0, 112, 360] if _mode == "route" else []}


func _draw() -> void:
	var metrics: Dictionary = _metrics()
	if not metrics.fits: return
	var origin := Vector2(float(metrics.origin[0]), float(metrics.origin[1]))
	var step: float = float(metrics.pixel_step)
	# Draw-command transform only; no Control/Camera/actor transform changes.
	draw_set_transform(origin, 0.0, Vector2(step, step))
	var palette: Dictionary = PALETTES[_act - 1]
	if _mode == "title":
		_cell(0, 0, 160, 88, Color(palette.sky))
		_cell(0, 77, 160, 11, Color(palette.soil))
		if not _revealed: _title_abstract(palette)
		elif _act == 1 and _earth_launch: _title_earth(palette)
		elif _act == 1: _title_moon(palette)
		elif _act == 2: _title_invasion(palette)
		else: _title_tormance(palette)
		# Quiet solid contact patch under shared feet; no ring/broken target cue.
		_cell(66, 77, 28, 2, Color(palette.far))
	else:
		_route_edges(palette) # transparent central area; no region fill or links.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _title_abstract(p: Dictionary) -> void:
	_silhouette([Vector2i(0,77),Vector2i(0,60),Vector2i(12,57),Vector2i(24,63),Vector2i(44,72),Vector2i(44,77)], Color(p.far))
	_silhouette([Vector2i(120,77),Vector2i(132,65),Vector2i(149,59),Vector2i(160,64),Vector2i(160,77)], Color(p.far))


func _title_earth(p: Dictionary) -> void:
	# Earth workshop/observatory: no unreached lunar cavern, court or Moon face.
	_cell(0, 67, 50, 10, Color(p.far))
	_cell(7, 62, 5, 5, Color(p.shade)); _cell(31, 59, 7, 8, Color(p.shade))
	_cell(30, 58, 9, 2, Color(p.light))
	_capsule(9, 41, p)
	_cell(10, 64, 39, 2, Color(p.shade))
	_cell(118, 56, 32, 3, Color(p.shade))
	_cell(123, 47, 25, 5, Color(p.light)); _cell(146, 46, 4, 7, Color(p.accent))
	_cell(126, 52, 3, 5, Color(p.shade))
	_silhouette([Vector2i(127,56),Vector2i(130,56),Vector2i(139,75),Vector2i(135,75)], Color(p.shade))
	_silhouette([Vector2i(127,56),Vector2i(130,56),Vector2i(122,75),Vector2i(119,75)], Color(p.shade))
	_cell(9, 22, 2, 1, Color(p.light)); _cell(144, 17, 1, 2, Color(p.light))


func _title_moon(p: Dictionary) -> void:
	_silhouette([Vector2i(0,77),Vector2i(0,46),Vector2i(7,46),Vector2i(13,21),Vector2i(18,21),Vector2i(24,47),Vector2i(34,38),Vector2i(46,70),Vector2i(50,77)], Color(p.far))
	_silhouette([Vector2i(116,77),Vector2i(126,50),Vector2i(132,57),Vector2i(145,31),Vector2i(151,31),Vector2i(160,49),Vector2i(160,77)], Color(p.far))
	_silhouette([Vector2i(7,60),Vector2i(13,29),Vector2i(17,50),Vector2i(15,63)], Color(p.shade))
	_silhouette([Vector2i(137,66),Vector2i(146,38),Vector2i(149,57),Vector2i(144,69)], Color(p.shade))
	_capsule(9, 53, p)
	_cell(124, 12, 2, 1, Color(p.light)); _cell(150, 21, 1, 2, Color(p.light))


func _capsule(x: int, y: int, p: Dictionary) -> void:
	# Squat horizontal shell: rounded blunt nose, cylindrical body, no fins.
	_cell(x + 5, y, 19, 19, Color(p.shade))
	_ellipse(x, y, 12, 19, Color(p.light))
	_ellipse(x + 17, y, 17, 19, Color(p.shade))
	_cell(x + 7, y + 2, 19, 2, Color(p.light))
	_cell(x + 8, y + 15, 18, 2, Color(p.far))
	_cell(x + 5, y + 6, 4, 6, Color(p.far))


func _title_invasion(p: Dictionary) -> void:
	_silhouette([Vector2i(0,77),Vector2i(0,45),Vector2i(9,45),Vector2i(9,33),Vector2i(16,33),Vector2i(16,42),Vector2i(28,42),Vector2i(28,52),Vector2i(40,52),Vector2i(40,77)], Color(p.far))
	_cell(5, 55, 5, 8, Color(p.sky)); _cell(16, 48, 7, 11, Color(p.sky))
	_cell(30, 70, 22, 5, Color(p.shade))
	_cell(121, 56, 32, 19, Color(p.far)); _cell(139, 37, 6, 19, Color(p.far))
	_cell(137, 35, 10, 3, Color(p.shade))
	# The cylinder is a static buried prop, not a boss silhouette or active mouth.
	_cell(12, 53, 25, 17, Color(p.shade)); _ellipse(7, 53, 13, 17, Color(p.light))
	_cell(12, 56, 3, 10, Color(p.far)); _cell(24, 56, 2, 11, Color(p.light))
	_weed_patch(2, 71, Color(p.accent)); _weed_patch(136, 72, Color(p.light))


func _title_tormance(p: Dictionary) -> void:
	# First-act vocabulary only: twin suns/rock ecology, no likeness/echo/boss.
	_ellipse(10, 6, 16, 16, Color("898a79")); _ellipse(137, 10, 10, 10, Color("5d688e"))
	_silhouette([Vector2i(0,77),Vector2i(0,65),Vector2i(10,60),Vector2i(21,64),Vector2i(35,61),Vector2i(49,72),Vector2i(51,77)], Color(p.far))
	_silhouette([Vector2i(111,77),Vector2i(121,67),Vector2i(132,63),Vector2i(144,67),Vector2i(160,58),Vector2i(160,77)], Color(p.far))
	_silhouette([Vector2i(132,66),Vector2i(130,44),Vector2i(135,31),Vector2i(139,44),Vector2i(143,66)], Color(p.shade))
	_silhouette([Vector2i(133,61),Vector2i(134,43),Vector2i(136,37),Vector2i(136,60)], Color(p.light))
	_cell(5, 60, 2, 13, Color(p.shade)); _cell(3, 55, 7, 5, Color(p.shade))
	_cell(22, 65, 2, 8, Color(p.shade)); _cell(19, 61, 7, 4, Color(p.shade))


func _route_edges(p: Dictionary) -> void:
	# Only outer24 virtual pixels. Parent keeps actual opaque node labels and
	# draws exact route links ABOVE this child, without changing their endpoints.
	var dim: Color = Color(p.far).darkened(.18)
	_silhouette([Vector2i(0,143),Vector2i(0,118),Vector2i(8,110),Vector2i(19,124),Vector2i(23,143)], dim)
	_silhouette([Vector2i(139,267),Vector2i(146,235),Vector2i(157,230),Vector2i(160,250),Vector2i(160,267)], dim)
	if not _revealed: return
	var soft: Color = Color(p.shade).darkened(.22)
	if _act == 1:
		if _earth_launch:
			_cell(141, 145, 19, 21, soft); _cell(146, 133, 6, 12, soft)
			_cell(2, 194, 14, 9, soft); _ellipse(1, 194, 7, 9, soft)
		else:
			_silhouette([Vector2i(1,203),Vector2i(5,174),Vector2i(9,166),Vector2i(13,188),Vector2i(20,203)], soft)
			_cell(147, 75, 2, 1, soft); _cell(153, 93, 1, 2, soft)
	elif _act == 2:
		_cell(142, 146, 18, 31, soft); _cell(145, 136, 7, 10, soft)
		_cell(143, 151, 5, 7, dim); _cell(151, 163, 5, 6, dim)
		_cell(3, 194, 13, 8, soft); _ellipse(1, 194, 7, 8, soft)
		_weed_patch(0, 292, soft)
	else:
		_ellipse(3, 58, 8, 8, Color("898a79").darkened(.58)); _ellipse(147, 86, 5, 5, Color("5d688e").darkened(.58))
		_silhouette([Vector2i(2,241),Vector2i(4,218),Vector2i(9,206),Vector2i(14,226),Vector2i(18,241)], soft)
		_cell(147, 303, 2, 7, soft); _cell(143, 300, 9, 3, soft)


func _weed_patch(x: int, y: int, c: Color) -> void:
	# Pixel clusters, never branching guide lines, arrows or available-target cue.
	for cell: Vector2i in [Vector2i(0,4),Vector2i(3,1),Vector2i(5,4),Vector2i(9,0),Vector2i(12,3),Vector2i(15,5)]:
		_cell(x + cell.x, y + cell.y, 3, 2, c)


func _ellipse(x: int, y: int, width: int, height: int, c: Color) -> void:
	for row: int in range(height):
		var normalized: float = (float(row) + .5 - float(height) * .5) / (float(height) * .5)
		var half: float = float(width) * .5 * sqrt(maxf(0.0, 1.0 - normalized * normalized))
		var low: int = int(ceil(float(width) * .5 - half - .5))
		var high: int = int(floor(float(width) * .5 + half - .5))
		_cell(x + low, y + row, high - low + 1, 1, c)


func _silhouette(points: Array[Vector2i], c: Color) -> void:
	var low_y: int = points[0].y
	var high_y: int = low_y
	for point: Vector2i in points: low_y = mini(low_y, point.y); high_y = maxi(high_y, point.y)
	for row: int in range(low_y, high_y):
		var scan: float = float(row) + .5
		var crossings: Array[float] = []
		for index: int in range(points.size()):
			var a: Vector2i = points[index]
			var b: Vector2i = points[(index + 1) % points.size()]
			if (a.y <= scan and b.y > scan) or (b.y <= scan and a.y > scan):
				crossings.append(float(a.x) + (scan - float(a.y)) * float(b.x - a.x) / float(b.y - a.y))
		crossings.sort()
		for index: int in range(0, crossings.size() - 1, 2):
			var low: int = int(ceil(crossings[index] - .5))
			var high: int = int(floor(crossings[index + 1] - .5))
			_cell(low, row, high - low + 1, 1, c)


func _cell(x: int, y: int, width: int, height: int, c: Color) -> void:
	if width > 0 and height > 0: draw_rect(Rect2(float(x), float(y), float(width), float(height)), c, true)
