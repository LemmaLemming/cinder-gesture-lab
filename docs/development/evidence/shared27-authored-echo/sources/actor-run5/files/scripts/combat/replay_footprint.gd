class_name CinderReplayFootprint
extends RefCounted
## Pure presentation projection. Neither capture custody, damage, reservation,
## dispatch timing nor the conservative full-cone escape witness is granted here.
## Curves retain CueMesh's 64 chords. Linear clipping uses a bounded planar
## arrangement; its filled trapezoids never triangulate an outer ring over holes.

const Sequence = preload("res://scripts/combat/replay_sequence.gd")
const Authored = preload("res://scripts/combat/authored_enemy_sequence.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const CueMesh = preload("res://scripts/cues/cue_mesh.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const ExactJson = preload("res://scripts/campaign/exact_json.gd")
const API_REVISION: String = "replay-footprint-1"
const AUTHORED_API_REVISION: String = "authored-echo-footprint-1"
const MAX_COORD: float = 512.0
const MAX_FLOORS: int = 32
const MAX_BLOCKERS: int = 32
const MAX_SCENERY_BOXES: int = 256
const MAX_EDGES: int = 512
const MAX_X_EVENTS: int = 2048
const MAX_PAIR_TESTS: int = 131072
const MAX_SWEEP_TESTS: int = 1048576
const MAX_VERTICES: int = 16384
const EPS: float = 0.000000001
const OUTPUT_GRID: float = 0.00000001
# Cosmetic conservative fill clearance exceeds float32 conversion error at
# MAX_COORD. It is never an actor/collision/LOS skin or logical cone change.
const FILL_INSET_M: float = 0.00025
const FLOOR_Y_TOLERANCE: float = 0.02
const HEADER_KEYS: Array[String] = ["accepted", "api_revision", "schema_version", "sequence_id", "source_epoch", "generation", "sequence_digest", "collision_fingerprint", "floor_signature", "curve_segments", "boundary_grid_m", "fill_inset_m", "events"]

const AUTHORED_HEADER_KEYS: Array[String] = ["accepted", "api_revision", "schema_version", "sequence_id", "source_id", "source_epoch", "generation", "profile_id", "program_digest", "collision_fingerprint", "floor_signature", "curve_segments", "boundary_grid_m", "fill_inset_m", "events"]
const AUTHORED_CONTEXT_KEYS: Array[String] = ["world_root", "source_id", "source_epoch", "generation", "world_collision_fingerprint", "world_floor_signature"]

static func floor_signature(world_root: Node3D, floor_regions: Array) -> Dictionary:
	## Safe rectangles are the authored valid domain, not its convex hull and
	## not every physical floor elsewhere. No capsule-radius claim is made.
	if not _live(world_root) or floor_regions.is_empty() or floor_regions.size() > MAX_FLOORS:
		return _reject("One to 32 live authored floor boxes required")
	var signatures: Array = []
	var top_y: float = INF
	for region: Variant in floor_regions:
		if not region is Dictionary or not region.get("safe_rect") is Rect2:
			return _reject("Floor binding requires its actual collider and finite safe_rect")
		var collision: CollisionShape3D = region.get("collision") as CollisionShape3D
		if not _live(collision) or collision.disabled or not collision.shape is BoxShape3D or collision.global_basis != Basis.IDENTITY or not collision.get_parent() is StaticBody3D or collision.get_parent() is AnimatableBody3D:
			return _reject("Floor must be an unscaled axis-aligned static Box")
		var body: StaticBody3D = collision.get_parent()
		if not _live(body) or not _under(body, world_root) or body.get_world_3d() != world_root.get_world_3d() or (body.collision_layer & 1) == 0 or body.constant_linear_velocity != Vector3.ZERO or body.constant_angular_velocity != Vector3.ZERO:
			return _reject("Floor must be immutable same-world scenery under world_root")
		var count: int = 0
		for owner_id: int in body.get_shape_owners():
			if not body.is_shape_owner_disabled(owner_id):
				count += body.shape_owner_get_shape_count(owner_id)
		if count != 1:
			return _reject("A supported floor body owns exactly one enabled Box")
		var size: Vector3 = (collision.shape as BoxShape3D).size
		var position: Vector3 = collision.global_position
		var rect: Rect2 = region.safe_rect
		if not _bounded(position) or not _bounded(size) or size.x <= 0 or size.y <= 0 or size.z <= 0 or not rect.position.is_finite() or not rect.size.is_finite() or rect.size.x <= 0 or rect.size.y <= 0:
			return _reject("Floor dimensions/domain exceed the finite supported envelope")
		var actual := Rect2(Vector2(position.x - size.x * 0.5, position.z - size.z * 0.5), Vector2(size.x, size.z))
		if not actual.encloses(rect) or not _bounded2(rect.position) or not _bounded2(rect.end):
			return _reject("Authored floor domain must be contained in the actual Box top")
		var top: float = position.y + size.y * 0.5
		if is_finite(top_y) and top != top_y:
			return _reject("Floor Boxes must be exactly coplanar")
		top_y = top
		var body_path: String = String(world_root.get_path_to(body))
		var shape_path: String = String(body.get_path_to(collision))
		if not _stable_path(body_path) or not _stable_path(shape_path):
			return _reject("Floor paths must have stable authored identities")
		signatures.append({"body_path": body_path, "shape_path": shape_path, "safe_rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "top_y": top})
	# Canonical order is independent of caller Array order; duplicate physical
	# bindings with different valid rectangles are intentionally supported.
	signatures.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return ExactJson.stringify(a) < ExactJson.stringify(b))
	return {"accepted": true, "signature": signatures}


static func plan(scheduler: Node3D, sequence_snapshot: Dictionary, world_root: Node3D, floor_regions: Array, context: Dictionary) -> Dictionary:
	var guards: Dictionary = _guards(scheduler, world_root, floor_regions)
	if not guards.accepted:
		return guards
	if not context.get("source_epoch") is String or not Codec.is_integer(context.get("generation"), 1):
		return _reject("Explicit original capture epoch/generation required")
	var sequence = Sequence.new()
	if not sequence.restore_state(sequence_snapshot, context.source_epoch, int(context.generation)):
		return _reject("Invalid sealed Sequence: " + sequence.last_snapshot_error)
	if not _same(context.get("capture_collision_fingerprint"), guards.fingerprint) or not _same(context.get("capture_floor_signature"), guards.floors):
		return _reject("Actual world and authored floor bindings must exactly match capture guards")
	var sequence_wire: String = ExactJson.stringify(sequence_snapshot)
	if sequence_wire.is_empty():
		return _reject("Sequence exceeds exact transport bounds")
	var native: Dictionary = sequence.state()
	var top: float = float(guards.floors[0].top_y)
	var events: Array = []
	var vertex_count: int = 0
	for slot_index: int in range(native.timeline.slots.size()):
		var slot: Dictionary = native.timeline.slots[slot_index]
		for event_index: int in range(slot.events.size()):
			var event: Dictionary = slot.events[event_index]
			var record: Dictionary = event.record
			var origin: Vector3 = record.world_origin
			if not _bounded(origin) or absf(origin.y - top) > FLOOR_Y_TOLERANCE or not _floor_point(guards.floors, origin):
				return _reject("Captured attack origin must remain on the supported authored floor plane")
			var raw: Dictionary = record.geometry
			if raw.shape != "radial_cone" or raw.los.policy != "scenery_ray_from_source_to_target" or int(raw.los.collision_mask) != 1 or not Codec.in_range(raw.reach, EPS, 32.0) or not Codec.in_range(raw.los.height, EPS, 4.0):
				return _reject("Unsupported original recorded geometry/LOS envelope")
			var geometry: Dictionary = Geometry.cone(origin, record.direction, float(raw.reach), float(raw.cone_min_dot), float(raw.origin_disk_radius))
			var geometry_error: String = Geometry.error(geometry)
			if not geometry_error.is_empty():
				return _reject(geometry_error)
			var polygons: Array = []
			var curve: Array = []
			for point: Vector3 in CueMesh.boundary(geometry):
				# Use the exact same native curve vertices as the existing cue.
				var absolute: Vector3 = origin + point
				curve.append([float(absolute.x), float(absolute.z)])
			polygons.append({"kind": "attack", "points": curve})
			for floor_unit: Dictionary in guards.floors:
				polygons.append({"kind": "floor", "points": _rect_points(floor_unit.safe_rect)})
			var shadows: int = 0
			for box: Dictionary in guards.boxes:
				var shadow: Dictionary = _box_shadow(box, origin, raw, top)
				if not shadow.accepted:
					return shadow
				if not shadow.points.is_empty():
					shadows += 1
					if shadows > MAX_BLOCKERS:
						return _reject("Relevant LOS blockers exceed the bounded projection budget")
					polygons.append({"kind": "shadow", "points": shadow.points})
			var clipped: Dictionary = _arrangement(polygons, top)
			if not clipped.accepted:
				return clipped
			vertex_count += clipped.triangle_vertices.size() + clipped.boundary_vertices
			if vertex_count > MAX_VERTICES:
				return _reject("Combined event mesh exceeds the finite vertex budget")
			var original: Dictionary = sequence_snapshot.timeline.slots[slot_index].events[event_index]
			events.append({"event_id": event.event_id, "kind": event.kind, "slot_id": slot.slot_id, "record_sequence": event.record_sequence, "at_s": event.at_s, "record": original.record.duplicate(true), "floor_y": top, "triangle_vertices": clipped.triangle_vertices, "boundary_contours": clipped.boundary_contours, "bounds": clipped.bounds})
	if events.is_empty() or events.size() > 4:
		return _reject("Exactly one to four original primary/blast events required")
	var result := {"accepted": true, "api_revision": API_REVISION, "schema_version": 1, "sequence_id": native.sequence_id, "source_epoch": native.source_epoch, "generation": native.generation, "sequence_digest": sequence_wire.sha256_text(), "collision_fingerprint": guards.fingerprint, "floor_signature": guards.floors, "curve_segments": CueMesh.SEGMENTS, "boundary_grid_m": OUTPUT_GRID, "fill_inset_m": FILL_INSET_M, "events": events}
	if not Codec.value_error(result).is_empty() or ExactJson.stringify(result).is_empty():
		return _reject("Projection exceeds finite exact transport bounds")
	return result


static func projection_error(projection: Dictionary, scheduler: Node3D, sequence_snapshot: Dictionary, world_root: Node3D, floor_regions: Array, context: Dictionary) -> String:
	## Authenticate all mesh bytes by recomputation, including IDs/order/raw
	## records. A world-only check alone does not authenticate caller mesh data.
	var expected: Dictionary = plan(scheduler, sequence_snapshot, world_root, floor_regions, context)
	if not expected.accepted:
		return expected.reason
	return "" if _same(projection, expected) else "Projection differs from the exact original Sequence/current-world recomputation"


static func plan_authored(scheduler: Node3D, program_snapshot: Dictionary, world_root: Node3D, floor_regions: Array, context: Dictionary) -> Dictionary:
	## Pure typed presentation only. The parent must authenticate the actual
	## stationary source/definition/profile/cycle and its admitted program.
	## This path never decodes Player gear, capture or completed-action clocks.
	if not Codec.keys_error(context, AUTHORED_CONTEXT_KEYS).is_empty() or not is_instance_valid(context.get("world_root")) or not context.get("world_root") is Node3D or context.world_root != world_root or not context.get("source_id") is String or not context.get("source_epoch") is String or typeof(context.get("generation")) != TYPE_INT or not Codec.is_integer(context.generation, 1):
		return _reject("Exact authored source/cycle/current-world context required")
	var program_wire: String = ExactJson.stringify(program_snapshot)
	if program_wire.is_empty():
		return _reject("Authored program exceeds closed finite exact transport bounds")
	var program = Authored.new()
	if not program.restore_state(program_snapshot, context.source_epoch, int(context.generation)):
		return _reject("Invalid authored enemy program: " + program.last_snapshot_error)
	if program_snapshot.source_id != context.source_id:
		return _reject("Authored projection source differs from the admitted owner")
	var guards: Dictionary = _guards(scheduler, world_root, floor_regions)
	if not guards.accepted:
		return guards
	if not _same(context.world_collision_fingerprint, guards.fingerprint) or not _same(context.world_floor_signature, guards.floors) or not _same(program_snapshot.world.collision_fingerprint, guards.fingerprint) or not _same(program_snapshot.world.floor_signature, guards.floors):
		return _reject("Authored program and context must exactly retain the actual world/floor domain")
	var native: Dictionary = program.state()
	var slot: Dictionary = native.timeline.slots[0]
	var event: Dictionary = slot.events[0]
	var record: Dictionary = event.record
	var top: float = float(guards.floors[0].top_y)
	var origin: Vector3 = record.world_origin
	if not _bounded(origin) or absf(origin.y - top) > FLOOR_Y_TOLERANCE or not _floor_point(guards.floors, origin):
		return _reject("Authored slash origin must remain on the supported authored floor plane")
	var raw: Dictionary = record.geometry
	var geometry: Dictionary = Geometry.cone(origin, record.direction, float(raw.reach), float(raw.cone_min_dot), float(raw.origin_disk_radius))
	var polygons: Array = []
	var curve: Array = []
	for point: Vector3 in CueMesh.boundary(geometry):
		var absolute: Vector3 = origin + point
		curve.append([float(absolute.x), float(absolute.z)])
	polygons.append({"kind": "attack", "points": curve})
	for floor_unit: Dictionary in guards.floors:
		polygons.append({"kind": "floor", "points": _rect_points(floor_unit.safe_rect)})
	var shadows: int = 0
	for box: Dictionary in guards.boxes:
		var shadow: Dictionary = _box_shadow(box, origin, raw, top)
		if not shadow.accepted:
			return shadow
		if not shadow.points.is_empty():
			shadows += 1
			if shadows > MAX_BLOCKERS:
				return _reject("Relevant LOS blockers exceed the bounded projection budget")
			polygons.append({"kind": "shadow", "points": shadow.points})
	var clipped: Dictionary = _arrangement(polygons, top)
	if not clipped.accepted:
		return clipped
	if clipped.triangle_vertices.size() + clipped.boundary_vertices > MAX_VERTICES:
		return _reject("Authored event mesh exceeds the finite vertex budget")
	var original: Dictionary = program_snapshot.timeline.slots[0].events[0]
	var projected := {"event_id": event.event_id, "kind": event.kind, "slot_id": slot.slot_id, "event_ordinal": event.event_ordinal, "at_s": event.at_s, "record": original.record.duplicate(true), "floor_y": top, "triangle_vertices": clipped.triangle_vertices, "boundary_contours": clipped.boundary_contours, "bounds": clipped.bounds}
	var result := {"accepted": true, "api_revision": AUTHORED_API_REVISION, "schema_version": 1, "sequence_id": native.sequence_id, "source_id": native.source_id, "source_epoch": native.source_epoch, "generation": native.generation, "profile_id": native.profile_id, "program_digest": program_wire.sha256_text(), "collision_fingerprint": guards.fingerprint, "floor_signature": guards.floors, "curve_segments": CueMesh.SEGMENTS, "boundary_grid_m": OUTPUT_GRID, "fill_inset_m": FILL_INSET_M, "events": [projected]}
	if ExactJson.stringify(result).is_empty():
		return _reject("Authored projection exceeds finite exact transport bounds")
	return result


static func projection_error_authored(projection: Dictionary, scheduler: Node3D, program_snapshot: Dictionary, world_root: Node3D, floor_regions: Array, context: Dictionary) -> String:
	var expected: Dictionary = plan_authored(scheduler, program_snapshot, world_root, floor_regions, context)
	if not expected.accepted:
		return expected.reason
	return "" if _same(projection, expected) else "Projection differs from the exact authored program/current-world recomputation"


static func current_world_error(projection: Dictionary, scheduler: Node3D, world_root: Node3D, floor_regions: Array) -> String:
	var error: String = Codec.value_error(projection)
	if error.is_empty():
		error = Codec.keys_error(projection, AUTHORED_HEADER_KEYS if projection.get("api_revision") == AUTHORED_API_REVISION else HEADER_KEYS)
	if not error.is_empty() or projection.get("accepted") != true or projection.get("api_revision") not in [API_REVISION, AUTHORED_API_REVISION] or projection.get("schema_version") != 1:
		return "Invalid finite projection header"
	var guards: Dictionary = _guards(scheduler, world_root, floor_regions)
	if not guards.accepted:
		return guards.reason
	return "" if _same(projection.collision_fingerprint, guards.fingerprint) and _same(projection.floor_signature, guards.floors) else "Projection world/floor bindings changed"


static func floor_contains(projection: Dictionary, point: Vector3) -> bool:
	## Pure X/Z membership above the declared floor lower bound. The trusted
	## parent must first authenticate the projection and current world. This
	## does not test attack range, capsule support, target height, LOS or HP.
	return _bounded(point) and projection.get("api_revision") in [API_REVISION, AUTHORED_API_REVISION] and projection.get("accepted") == true and projection.get("floor_signature") is Array and _floor_point(projection.floor_signature, point)


static func _guards(scheduler: Node3D, world_root: Node3D, floor_regions: Array) -> Dictionary:
	if not _live(scheduler) or not scheduler is Scheduler or scheduler.get_script() != Scheduler or not _live(world_root) or scheduler.get_world_3d() != world_root.get_world_3d() or not scheduler.has_method("pure_collision_fingerprint"):
		return _reject("Live actual shared Scheduler and same-world root required")
	var floors: Dictionary = floor_signature(world_root, floor_regions)
	if not floors.accepted:
		return floors
	var fingerprint: Dictionary = scheduler.call("pure_collision_fingerprint", world_root)
	if fingerprint.is_empty():
		return _reject("Unsupported immutable actual collision fingerprint")
	var boxes: Array = []
	for body: Dictionary in fingerprint.colliders:
		if not _identity_transform(body.transform):
			return _reject("Projection supports unscaled axis-aligned static Box bodies only")
		for shape: Dictionary in body.shapes:
			if boxes.size() >= MAX_SCENERY_BOXES:
				return _reject("Actual scenery Boxes exceed the bounded world descriptor budget")
			if shape.data.type != "BoxShape3D" or not _identity_transform(shape.transform):
				return _reject("Unsupported rotated/scaled/non-Box scenery topology")
			var position: Vector3 = Codec.read_vector3(body.transform[3]) + Codec.read_vector3(shape.transform[3])
			var size: Vector3 = Codec.read_vector3(shape.data.size)
			if not _bounded(position) or not _bounded(size) or size.x <= 0 or size.y <= 0 or size.z <= 0:
				return _reject("Actual Box exceeds the finite projection envelope")
			boxes.append({"position": position, "size": size})
	return {"accepted": true, "fingerprint": fingerprint, "floors": floors.signature, "boxes": boxes}


static func _box_shadow(box: Dictionary, origin: Vector3, raw: Dictionary, floor_y: float) -> Dictionary:
	var position: Vector3 = box.position
	var size: Vector3 = box.size
	var rect: Array = [position.x - size.x * 0.5, position.z - size.z * 0.5, size.x, size.z]
	var ox: float = origin.x
	var oz: float = origin.z
	var reach: float = raw.reach
	var dx: float = ox - clampf(ox, rect[0], rect[0] + rect[2])
	var dz: float = oz - clampf(oz, rect[1], rect[1] + rect[3])
	if dx * dx + dz * dz > reach * reach:
		return {"accepted": true, "points": []}
	# A wall shadow is independent of target height only when the wall covers
	# this full supported LOS band. Partial/edge coverage is explicitly rejected;
	# no horizontal proxy silently replaces a potentially sloping native ray.
	var low: float = floor_y - FLOOR_Y_TOLERANCE + float(raw.los.height)
	var high: float = origin.y + float(raw.max_vertical_distance) + float(raw.los.height)
	var bottom: float = position.y - size.y * 0.5
	var top: float = position.y + size.y * 0.5
	if top < low - EPS or bottom > high + EPS:
		return {"accepted": true, "points": []}
	if bottom >= low - EPS or top <= high + EPS:
		return _reject("Relevant Box only partially covers supported LOS heights")
	if dx == 0.0 and dz == 0.0:
		return _reject("Captured source lies in/on a relevant blocking Box")
	var corners: Array = _rect_points(rect)
	var hull: Array = _hull(corners + [[ox, oz]])
	var index: int = hull.find([ox, oz])
	if index < 0 or hull.size() < 3:
		return _reject("Ambiguous source/Box tangent topology")
	var result: Array = _rect_points([ox - reach, oz - reach, reach * 2.0, reach * 2.0])
	result = _clip(result, hull[(index + hull.size() - 1) % hull.size()], hull[index])
	result = _clip(result, hull[index], hull[(index + 1) % hull.size()])
	# Near faces, plus the tangent cone, are exactly {t*q | q in Box,t>=1}.
	if ox < rect[0]:
		result = _clip(result, [rect[0], oz], [rect[0], oz - 1.0])
	elif ox > rect[0] + rect[2]:
		result = _clip(result, [rect[0] + rect[2], oz], [rect[0] + rect[2], oz + 1.0])
	if oz < rect[1]:
		result = _clip(result, [ox, rect[1]], [ox + 1.0, rect[1]])
	elif oz > rect[1] + rect[3]:
		result = _clip(result, [ox, rect[1] + rect[3]], [ox - 1.0, rect[1] + rect[3]])
	return {"accepted": true, "points": result}


static func _arrangement(polygons: Array, floor_y: float) -> Dictionary:
	var edges: Array = []
	var xs: Array[float] = []
	for polygon_index: int in range(polygons.size()):
		var polygon: Dictionary = polygons[polygon_index]
		for index: int in range(polygon.points.size()):
			var a: Array = polygon.points[index]
			var b: Array = polygon.points[(index + 1) % polygon.points.size()]
			if a == b:
				continue
			edges.append({"a": a, "b": b, "polygon": polygon_index})
			xs.append(float(a[0]))
	if edges.size() > MAX_EDGES or edges.size() * (edges.size() - 1) > MAX_PAIR_TESTS * 2:
		return _reject("Planar input edges exceed the bounded arrangement budget")
	for i: int in range(edges.size()):
		for j: int in range(i):
			var crossing: Variant = _crossing_x(edges[i], edges[j])
			if crossing is float:
				xs.append(crossing)
				if xs.size() > MAX_PAIR_TESTS:
					return _reject("Arrangement crossings exceed their bounded budget")
	xs.sort()
	var events: Array[float] = []
	for x: float in xs:
		if events.is_empty() or x - events.back() > EPS:
			events.append(x)
	if events.size() > MAX_X_EVENTS or events.size() * edges.size() > MAX_SWEEP_TESTS:
		return _reject("Planar slabs exceed the bounded sweep budget")
	var triangles: Array = []
	var boundary: Array = []
	var previous: Array = []
	for index: int in range(events.size() - 1):
		var left: float = events[index]
		var right: float = events[index + 1]
		var bands: Dictionary = _bands(edges, polygons, (left + right) * 0.5)
		if not bands.accepted:
			return bands
		var intervals: Array = bands.intervals
		var current_left: Array = []
		var current_right: Array = []
		for band: Dictionary in intervals:
			var lo_left: float = _edge_y(band.low, left)
			var lo_right: float = _edge_y(band.low, right)
			var hi_left: float = _edge_y(band.high, left)
			var hi_right: float = _edge_y(band.high, right)
			if hi_left < lo_left - EPS or hi_right < lo_right - EPS:
				return _reject("Numerically ambiguous arrangement edge order")
			var a: Array = [left, lo_left]
			var b: Array = [right, lo_right]
			var c: Array = [right, hi_right]
			var d: Array = [left, hi_left]
			_inset_fill(triangles, [a, b, c, d], floor_y)
			_edge(boundary, _point(a[0], a[1]), _point(b[0], b[1]))
			_edge(boundary, _point(c[0], c[1]), _point(d[0], d[1]))
			current_left.append([lo_left, hi_left])
			current_right.append([lo_right, hi_right])
		_vertical(boundary, left, previous, current_left)
		previous = current_right
		if triangles.size() + boundary.size() * 2 > MAX_VERTICES:
			return _reject("Projection output exceeds its finite mesh budget")
	if not events.is_empty():
		_vertical(boundary, events.back(), previous, [])
	var contours: Dictionary = _contours(boundary, floor_y)
	if not contours.accepted:
		return contours
	if triangles.is_empty() and not contours.contours.is_empty():
		return _reject("Projection is too thin for supported conservative native fill")
	var bounds: Array = []
	var bounded_vertices: Array = triangles.duplicate()
	for contour: Dictionary in contours.contours:
		bounded_vertices.append_array(contour.vertices)
	for vertex: Array in bounded_vertices:
		if bounds.is_empty():
			bounds = [vertex[0], vertex[2], vertex[0], vertex[2]]
		else:
			bounds = [minf(bounds[0], vertex[0]), minf(bounds[1], vertex[2]), maxf(bounds[2], vertex[0]), maxf(bounds[3], vertex[2])]
	return {"accepted": true, "triangle_vertices": triangles, "boundary_contours": contours.contours, "boundary_vertices": contours.count, "bounds": bounds}


static func _bands(edges: Array, polygons: Array, x: float) -> Dictionary:
	var crossings: Array = []
	for edge: Dictionary in edges:
		if x > minf(edge.a[0], edge.b[0]) and x < maxf(edge.a[0], edge.b[0]):
			crossings.append({"y": _edge_y(edge, x), "edge": edge})
	crossings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.y < b.y)
	var inside: Array[bool] = []
	inside.resize(polygons.size())
	inside.fill(false)
	var floor_count: int = 0
	var shadow_count: int = 0
	var low: Dictionary = {}
	var intervals: Array = []
	var cursor: int = 0
	while cursor < crossings.size():
		var group: Array = [crossings[cursor]]
		cursor += 1
		while cursor < crossings.size() and absf(crossings[cursor].y - group[0].y) <= EPS:
			if not _same_line(crossings[cursor].edge, group[0].edge):
				return _reject("Distinct arrangement boundaries are numerically indistinguishable")
			group.append(crossings[cursor])
			cursor += 1
		var before: bool = inside[0] and floor_count > 0 and shadow_count == 0
		for crossing: Dictionary in group:
			var polygon: int = crossing.edge.polygon
			var delta: int = -1 if inside[polygon] else 1
			inside[polygon] = not inside[polygon]
			if polygons[polygon].kind == "floor":
				floor_count += delta
			elif polygons[polygon].kind == "shadow":
				shadow_count += delta
		var after: bool = inside[0] and floor_count > 0 and shadow_count == 0
		if not before and after:
			low = group[0].edge
		elif before and not after:
			intervals.append({"low": low, "high": group[0].edge})
	if inside.has(true):
		return _reject("Open planar input contour")
	return {"accepted": true, "intervals": intervals}


static func _vertical(edges: Array, x: float, left: Array, right: Array) -> void:
	var ys: Array[float] = []
	for interval: Array in left + right:
		ys.append(interval[0])
		ys.append(interval[1])
	ys.sort()
	for index: int in range(ys.size() - 1):
		if ys[index + 1] - ys[index] <= EPS:
			continue
		var y: float = (ys[index] + ys[index + 1]) * 0.5
		var in_left: bool = _interval_contains(left, y)
		var in_right: bool = _interval_contains(right, y)
		if in_left != in_right:
			var a: Array = _point(x, ys[index])
			var b: Array = _point(x, ys[index + 1])
			_edge(edges, a if in_left else b, b if in_left else a)


static func _contours(edges: Array, floor_y: float) -> Dictionary:
	var outgoing: Dictionary = {}
	var incoming: Dictionary = {}
	for edge: Array in edges:
		var a: String = _key(edge[0])
		var b: String = _key(edge[1])
		if outgoing.has(a) or incoming.has(b):
			return _reject("Point-touch/thin boundary topology is unsupported")
		outgoing[a] = edge
		incoming[b] = true
	for key: String in outgoing:
		if not incoming.has(key):
			return _reject("Clipped boundary does not form closed contours")
	var contours: Array = []
	var count: int = 0
	var starts: Array = outgoing.keys()
	starts.sort()
	for start: String in starts:
		if not outgoing.has(start):
			continue
		var points: Array = []
		var cursor: String = start
		var area: float = 0.0
		while outgoing.has(cursor):
			var edge: Array = outgoing[cursor]
			outgoing.erase(cursor)
			points.append([edge[0][0], floor_y, edge[0][1]])
			area += float(edge[0][0]) * float(edge[1][1]) - float(edge[0][1]) * float(edge[1][0])
			cursor = _key(edge[1])
		if cursor != start or points.size() < 3 or absf(area) <= EPS * EPS:
			return _reject("Degenerate/nonclosed clipped contour")
		points.append(points[0].duplicate())
		count += points.size()
		contours.append({"hole": area < 0.0, "vertices": points})
	return {"accepted": true, "contours": contours, "count": count}


static func _hull(points: Array) -> Array:
	points.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	var low: Array = []
	var high: Array = []
	for point: Array in points:
		while low.size() >= 2 and _cross(low[-2], low[-1], point) <= 0.0:
			low.pop_back()
		low.append(point)
	for index: int in range(points.size() - 1, -1, -1):
		var point: Array = points[index]
		while high.size() >= 2 and _cross(high[-2], high[-1], point) <= 0.0:
			high.pop_back()
		high.append(point)
	low.pop_back()
	high.pop_back()
	return low + high


static func _clip(points: Array, a: Array, b: Array) -> Array:
	var result: Array = []
	for index: int in range(points.size()):
		var from: Array = points[index]
		var to: Array = points[(index + 1) % points.size()]
		var first: float = _cross(a, b, from)
		var second: float = _cross(a, b, to)
		if first >= 0.0:
			result.append(from)
		if (first >= 0.0) != (second >= 0.0):
			var fraction: float = first / (first - second)
			result.append([float(from[0]) + (float(to[0]) - float(from[0])) * fraction, float(from[1]) + (float(to[1]) - float(from[1])) * fraction])
	return result


static func _crossing_x(first: Dictionary, second: Dictionary) -> Variant:
	var rx: float = float(first.b[0]) - float(first.a[0])
	var ry: float = float(first.b[1]) - float(first.a[1])
	var sx: float = float(second.b[0]) - float(second.a[0])
	var sy: float = float(second.b[1]) - float(second.a[1])
	var denominator: float = rx * sy - ry * sx
	if denominator == 0.0:
		return null
	var dx: float = float(second.a[0]) - float(first.a[0])
	var dy: float = float(second.a[1]) - float(first.a[1])
	var t: float = (dx * sy - dy * sx) / denominator
	var u: float = (dx * ry - dy * rx) / denominator
	return float(first.a[0]) + rx * t if t >= 0.0 and t <= 1.0 and u >= 0.0 and u <= 1.0 else null


static func _same_line(first: Dictionary, second: Dictionary) -> bool:
	return absf(_cross(first.a, first.b, second.a)) <= EPS and absf(_cross(first.a, first.b, second.b)) <= EPS


static func _edge_y(edge: Dictionary, x: float) -> float:
	return float(edge.a[1]) + (float(edge.b[1]) - float(edge.a[1])) * ((x - float(edge.a[0])) / (float(edge.b[0]) - float(edge.a[0])))


static func _cross(a: Array, b: Array, c: Array) -> float:
	return (float(b[0]) - float(a[0])) * (float(c[1]) - float(a[1])) - (float(b[1]) - float(a[1])) * (float(c[0]) - float(a[0]))


static func _triangle(vertices: Array, a: Array, b: Array, c: Array, y: float) -> void:
	if _cross(a, b, c) > EPS * EPS:
		vertices.append_array([[a[0], y, a[1]], [b[0], y, b[1]], [c[0], y, c[1]]])


static func _inset_fill(vertices: Array, cell: Array, y: float) -> void:
	# Every cell is convex and already lies in the exact linear arrangement.
	# Shift each supporting halfplane inward; rounding/converting the resulting
	# encoded doubles to native float32 cannot expand fill into a hole/shadow.
	var filled: Array = cell.duplicate(true)
	for index: int in range(cell.size()):
		var a: Array = cell[index]
		var b: Array = cell[(index + 1) % cell.size()]
		var dx: float = float(b[0]) - float(a[0])
		var dz: float = float(b[1]) - float(a[1])
		var length: float = sqrt(dx * dx + dz * dz)
		if length <= EPS:
			continue
		var nx: float = -dz / length * FILL_INSET_M
		var nz: float = dx / length * FILL_INSET_M
		filled = _clip(filled, [float(a[0]) + nx, float(a[1]) + nz], [float(b[0]) + nx, float(b[1]) + nz])
		if filled.size() < 3:
			return
	for index: int in range(1, filled.size() - 1):
		_triangle(vertices, filled[0], filled[index], filled[index + 1], y)


static func _edge(edges: Array, a: Array, b: Array) -> void:
	if a != b:
		edges.append([a, b])


static func _point(x: float, z: float) -> Array:
	return [roundf(x / OUTPUT_GRID) * OUTPUT_GRID, roundf(z / OUTPUT_GRID) * OUTPUT_GRID]


static func _key(point: Array) -> String:
	return "%d:%d" % [roundi(float(point[0]) / OUTPUT_GRID), roundi(float(point[1]) / OUTPUT_GRID)]


static func _interval_contains(intervals: Array, y: float) -> bool:
	for interval: Array in intervals:
		if y > interval[0] and y < interval[1]:
			return true
	return false


static func _rect_points(rect: Array) -> Array:
	var x: float = rect[0]
	var z: float = rect[1]
	var right: float = x + float(rect[2])
	var top: float = z + float(rect[3])
	return [[x, z], [right, z], [right, top], [x, top]]


static func _floor_point(floors: Array, point: Vector3) -> bool:
	for floor_unit: Variant in floors:
		if not floor_unit is Dictionary or not floor_unit.get("safe_rect") is Array or floor_unit.safe_rect.size() != 4 or not Codec.is_number(floor_unit.get("top_y")):
			return false
		var rect: Array = floor_unit.safe_rect
		for value: Variant in rect:
			if not Codec.is_number(value):
				return false
		if point.y >= float(floor_unit.top_y) - FLOOR_Y_TOLERANCE and point.x >= rect[0] and point.x <= float(rect[0]) + float(rect[2]) and point.z >= rect[1] and point.z <= float(rect[1]) + float(rect[3]):
			return true
	return false


static func _identity_transform(encoded: Array) -> bool:
	return encoded.size() == 4 and encoded[0] == [1.0, 0.0, 0.0] and encoded[1] == [0.0, 1.0, 0.0] and encoded[2] == [0.0, 0.0, 1.0]


static func _same(left: Variant, right: Variant) -> bool:
	var encoded: String = ExactJson.stringify(left)
	return not encoded.is_empty() and encoded == ExactJson.stringify(right)


static func _bounded(point: Vector3) -> bool:
	return point.is_finite() and absf(point.x) <= MAX_COORD and absf(point.y) <= MAX_COORD and absf(point.z) <= MAX_COORD


static func _bounded2(point: Vector2) -> bool:
	return point.is_finite() and absf(point.x) <= MAX_COORD and absf(point.y) <= MAX_COORD


static func _live(node: Node) -> bool:
	return is_instance_valid(node) and node.is_inside_tree() and not node.is_queued_for_deletion()


static func _under(node: Node, world_root: Node) -> bool:
	return node == world_root or world_root.is_ancestor_of(node)


static func _stable_path(path: String) -> bool:
	return not path.is_empty() and not path.contains("@") and not path.contains("\n") and not path.contains("\r")


static func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}
