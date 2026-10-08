class_name CinderThreatGeometry
extends RefCounted
## Logical planar committed geometry, independent of decorative footprint meshes.
## Continuous segment tests conservatively pad by actor radius. Cone padding is
## an enclosing intersection of expanded halfplanes/disk (false positives near
## corners); scenery LOS never removes danger. A lane reserves its entire swept
## capsule during activation, not an inferred moving-source interpolation.

const EPSILON: float = 0.00001


static func circle(origin: Vector3, radius: float) -> Dictionary:
	return {"kind": "circle", "origin": origin, "radius": radius}


static func cone(origin: Vector3, direction: Vector3, reach: float, min_dot: float, origin_radius: float = 0.1) -> Dictionary:
	return {"kind": "cone", "origin": origin, "direction": direction, "reach": reach, "min_dot": min_dot, "origin_radius": origin_radius}


static func lane(start: Vector3, finish: Vector3, radius: float) -> Dictionary:
	return {"kind": "lane", "from": start, "to": finish, "radius": radius}


static func error(shape: Dictionary) -> String:
	var kind: Variant = shape.get("kind")
	if kind not in ["circle", "cone", "lane"]:
		return "Unsupported committed threat geometry"
	for key: String in (["from", "to"] if kind == "lane" else ["origin"]):
		if not finite_vector(shape.get(key)):
			return "Missing finite threat point: " + key
	if kind == "cone":
		if not finite_vector(shape.get("direction")):
			return "Cone requires a finite committed direction"
		var direction: Vector3 = shape["direction"]
		if absf(direction.y) > EPSILON or absf(direction.length() - 1.0) > EPSILON:
			return "Cone direction must be a normalized ground direction"
		for key: String in ["reach", "origin_radius", "min_dot"]:
			if not finite_number(shape.get(key)):
				return "Missing finite cone parameter: " + key
		if float(shape["reach"]) <= 0.0 or float(shape["origin_radius"]) < 0.0 or float(shape["origin_radius"]) > float(shape["reach"]) or float(shape["min_dot"]) < 0.0 or float(shape["min_dot"]) >= 1.0:
			return "Supported cone needs positive reach and a convex angle"
	else:
		if not finite_number(shape.get("radius")) or float(shape["radius"]) <= 0.0:
			return "Threat radius must be positive and finite"
		if kind == "lane" and absf((shape["from"] as Vector3).y - (shape["to"] as Vector3).y) > EPSILON:
			return "Lane must lie in a single ground plane"
	return ""


static func segment_hits(shape: Dictionary, start: Vector3, finish: Vector3, actor_radius: float) -> bool:
	if not error(shape).is_empty() or not finite_vector(start) or not finite_vector(finish) or not finite_number(actor_radius) or actor_radius < 0.0:
		return true # Unknown logical geometry cannot prove a safe route.
	var a: Vector2 = planar(start)
	var b: Vector2 = planar(finish)
	if shape["kind"] == "lane":
		return _segment_distance(a, b, planar(shape["from"]), planar(shape["to"])) <= float(shape["radius"]) + actor_radius + EPSILON
	var origin: Vector2 = planar(shape["origin"])
	if shape["kind"] == "circle":
		return _circle_interval(a - origin, b - origin, float(shape["radius"]) + actor_radius).x <= _circle_interval(a - origin, b - origin, float(shape["radius"]) + actor_radius).y
	if _circle_interval(a - origin, b - origin, float(shape["origin_radius"]) + actor_radius).x <= _circle_interval(a - origin, b - origin, float(shape["origin_radius"]) + actor_radius).y:
		return true
	var interval: Vector2 = _circle_interval(a - origin, b - origin, float(shape["reach"]) + actor_radius)
	var forward: Vector2 = planar(shape["direction"])
	var side: Vector2 = Vector2(-forward.y, forward.x)
	var cosine: float = float(shape["min_dot"])
	var sine: float = sqrt(1.0 - cosine * cosine)
	for normal: Vector2 in [forward * sine + side * cosine, forward * sine - side * cosine]:
		interval = _clip_linear(interval, normal.dot(a - origin), normal.dot(b - origin), -actor_radius)
	return interval.x <= interval.y


static func timed_path_hits(shape: Dictionary, path: Array[Dictionary], active_from: float, active_until: float, actor_radius: float) -> bool:
	for segment: Dictionary in path:
		var begin: float = maxf(float(segment["start_s"]), active_from)
		var end: float = minf(float(segment["end_s"]), active_until)
		if begin > end + EPSILON:
			continue
		var duration: float = float(segment["end_s"]) - float(segment["start_s"])
		var start: Vector3 = segment["from"]
		var finish: Vector3 = segment["to"]
		var a: Vector3 = start if duration <= EPSILON else start.lerp(finish, clampf((begin - float(segment["start_s"])) / duration, 0.0, 1.0))
		var b: Vector3 = finish if duration <= EPSILON else start.lerp(finish, clampf((end - float(segment["start_s"])) / duration, 0.0, 1.0))
		if segment_hits(shape, a, b, actor_radius):
			return true
	return false


static func planar(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)


static func finite_vector(value: Variant) -> bool:
	return value is Vector3 and is_finite(value.x) and is_finite(value.y) and is_finite(value.z)


static func finite_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


static func _circle_interval(a: Vector2, b: Vector2, radius: float) -> Vector2:
	var movement: Vector2 = b - a
	var aa: float = movement.length_squared()
	var cc: float = a.length_squared() - radius * radius
	if aa <= EPSILON * EPSILON:
		return Vector2(0, 1) if cc <= EPSILON else Vector2(1, 0)
	var bb: float = 2.0 * a.dot(movement)
	var discriminant: float = bb * bb - 4.0 * aa * cc
	if discriminant < -EPSILON:
		return Vector2(1, 0)
	var root: float = sqrt(maxf(0.0, discriminant))
	return Vector2(maxf(0.0, (-bb - root) / (2.0 * aa)), minf(1.0, (-bb + root) / (2.0 * aa)))


static func _clip_linear(interval: Vector2, start: float, finish: float, minimum: float) -> Vector2:
	var change: float = finish - start
	if absf(change) <= EPSILON:
		return interval if start >= minimum - EPSILON else Vector2(1, 0)
	var crossing: float = (minimum - start) / change
	return Vector2(maxf(interval.x, crossing), interval.y) if change > 0.0 else Vector2(interval.x, minf(interval.y, crossing))


static func _point_segment_distance(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var edge: Vector2 = finish - start
	var along: float = clampf((point - start).dot(edge) / edge.length_squared(), 0.0, 1.0) if edge.length_squared() > EPSILON * EPSILON else 0.0
	return point.distance_to(start + edge * along)


static func _segment_distance(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> float:
	var ab: Vector2 = b - a
	var cd: Vector2 = d - c
	var denominator: float = ab.cross(cd)
	if absf(denominator) > EPSILON:
		var along_ab: float = (c - a).cross(cd) / denominator
		var along_cd: float = (c - a).cross(ab) / denominator
		if along_ab >= 0.0 and along_ab <= 1.0 and along_cd >= 0.0 and along_cd <= 1.0:
			return 0.0
	return minf(minf(_point_segment_distance(a, c, d), _point_segment_distance(b, c, d)), minf(_point_segment_distance(c, a, b), _point_segment_distance(d, a, b)))
