class_name CinderCameraFraming
extends RefCounted
## Pure fixed-width orthographic framing. No camera, actor, gesture or clock
## mutation. A fitting proposed focus never authorizes currently clipped damage.
## Callers supply actual required world corners, including art/cue endcaps,
## committed source motion, the player and supported landing/opening bounds.

const API_REVISION: String = "camera-framing-1"
const MAX_POINTS: int = 256
const MAX_COORDINATE: float = 1024.0
const BASIS_EPSILON: float = 0.00001
const MIN_PLANAR_DETERMINANT: float = 0.1
# Plan inward from strict containment so native Vector3 rounding at bounded
# coordinates cannot turn an accepted edge into a clipped presentation.
const NUMERICAL_HEADROOM: float = 0.001
const SPEC_KEYS: Array[String] = ["basis", "offset", "width", "viewport_size", "safe_rect", "max_shift", "safety_margin", "near", "far"]


static func plan(required_points: Array, desired_focus: Vector3, spec: Dictionary) -> Dictionary:
	var checked: Dictionary = _validated(required_points, desired_focus, spec)
	if not checked.accepted:
		return checked
	var projected: Dictionary = _measure(required_points, desired_focus, spec)
	var x_limits: Vector2 = checked.x_limits
	var y_limits: Vector2 = checked.y_limits
	# Relative to the desired camera: each point must satisfy
	# low <= point_axis - shift_axis <= high, giving one interval per axis.
	var shift_x := Vector2(float(projected.maximum.x) - float(x_limits.y) + NUMERICAL_HEADROOM, float(projected.minimum.x) - float(x_limits.x) - NUMERICAL_HEADROOM)
	var shift_y := Vector2(float(projected.maximum.y) - float(y_limits.y) + NUMERICAL_HEADROOM, float(projected.minimum.y) - float(y_limits.x) - NUMERICAL_HEADROOM)
	if shift_x.x > shift_x.y or shift_y.x > shift_y.y:
		return _reject("Required union cannot fit the fixed-width HUD-safe rectangle")
	var correction := Vector2(clampf(0.0, shift_x.x, shift_x.y), clampf(0.0, shift_y.x, shift_y.y))
	var basis: Basis = spec.basis
	var determinant: float = float(checked.planar_determinant)
	var dx: float = (float(correction.x) * float(basis.y.z) - float(basis.x.z) * float(correction.y)) / determinant
	var dz: float = (float(basis.x.x) * float(correction.y) - float(correction.x) * float(basis.y.x)) / determinant
	var focus := Vector3(float(desired_focus.x) + dx, desired_focus.y, float(desired_focus.z) + dz)
	var shift: Vector3 = focus - desired_focus
	if not _bounded(focus) or not _bounded(focus + spec.offset):
		return _reject("Proposed focus or camera origin exceeds the supported coordinate bounds")
	if not shift.is_finite() or float(shift.length()) > float(spec.max_shift):
		return _reject("Required framing exceeds the permitted planar focus shift")
	var error: String = containment(required_points, focus, spec)
	if not error.is_empty():
		return _reject("Proposed framing failed its actual projection guard: " + error)
	var measured: Dictionary = _measure(required_points, focus, spec)
	return {"accepted": true, "reason": "", "api_revision": API_REVISION, "focus": focus, "desired_focus": desired_focus, "shift": shift, "shift_distance": shift.length(), "camera_position": focus + spec.offset, "camera_plane_correction": correction, "camera_plane_shift_intervals": [shift_x, shift_y], "screen_bounds": measured.screen_bounds, "depth_range": measured.depth_range, "safe_rect": spec.safe_rect, "safety_margin": spec.safety_margin, "point_count": required_points.size(), "width": spec.width, "basis": basis, "numerical_headroom": NUMERICAL_HEADROOM}


static func containment(required_points: Array, focus: Vector3, spec: Dictionary) -> String:
	## Checks this exact unshaken focus, never a hypothetical future correction.
	## The requested margin is retained for bounded shake and pixel protection.
	var checked: Dictionary = _validated(required_points, focus, spec)
	if not checked.accepted:
		return String(checked.reason)
	var measured: Dictionary = _measure(required_points, focus, spec)
	var x_limits: Vector2 = checked.x_limits
	var y_limits: Vector2 = checked.y_limits
	if measured.minimum.x < x_limits.x or measured.maximum.x > x_limits.y or measured.minimum.y < y_limits.x or measured.maximum.y > y_limits.y:
		return "Required source, footprint, player or landing lies outside the protected screen rectangle"
	var margin: float = float(spec.safety_margin)
	if float(measured.depth_range.x) < float(spec.near) + margin or float(measured.depth_range.y) > float(spec.far) - margin:
		return "Required bounds lie outside the protected near/far depth interval"
	return ""


static func _validated(points: Array, focus: Vector3, spec: Dictionary) -> Dictionary:
	if points.is_empty() or points.size() > MAX_POINTS:
		return _reject("One through 256 required world corners must be supplied")
	if not _bounded(focus):
		return _reject("Finite bounded focus required")
	for point: Variant in points:
		if not point is Vector3 or not _bounded(point):
			return _reject("Required corners must be finite native world vectors within 1024 units")
	if spec.size() != SPEC_KEYS.size():
		return _reject("Framing spec has missing or unsupported fields")
	for key: String in SPEC_KEYS:
		if not spec.has(key):
			return _reject("Missing framing spec field: " + key)
	if not spec.basis is Basis or not spec.offset is Vector3 or not _bounded(spec.offset) or not _bounded(focus + spec.offset):
		return _reject("Finite native fixed basis, offset and bounded camera origin required")
	var basis: Basis = spec.basis
	if not basis.is_finite() or absf(_dot(basis.x, basis.x) - 1.0) > BASIS_EPSILON or absf(_dot(basis.y, basis.y) - 1.0) > BASIS_EPSILON or absf(_dot(basis.z, basis.z) - 1.0) > BASIS_EPSILON or absf(_dot(basis.x, basis.y)) > BASIS_EPSILON or absf(_dot(basis.x, basis.z)) > BASIS_EPSILON or absf(_dot(basis.y, basis.z)) > BASIS_EPSILON or absf(basis.determinant() - 1.0) > BASIS_EPSILON or absf(basis.x.y) > BASIS_EPSILON:
		return _reject("Orthonormal fixed camera basis without roll required")
	var determinant: float = float(basis.x.x) * float(basis.y.z) - float(basis.x.z) * float(basis.y.x)
	if not is_finite(determinant) or absf(determinant) < MIN_PLANAR_DETERMINANT:
		return _reject("Camera-plane X/Z projection is unsupported or singular")
	for key: String in ["width", "max_shift", "safety_margin", "near", "far"]:
		if not _number(spec[key]):
			return _reject("Finite numeric framing spec required: " + key)
	if float(spec.width) <= 0.0 or float(spec.width) > MAX_COORDINATE or float(spec.max_shift) < 0.0 or float(spec.max_shift) > MAX_COORDINATE or float(spec.safety_margin) < 0.0 or float(spec.safety_margin) > MAX_COORDINATE or float(spec.near) <= 0.0 or float(spec.far) <= float(spec.near):
		return _reject("Invalid width, shift, margin or depth limits")
	if not spec.viewport_size is Vector2 or not spec.viewport_size.is_finite() or spec.viewport_size.x <= 0.0 or spec.viewport_size.y <= 0.0:
		return _reject("Finite positive native viewport size required")
	if not spec.safe_rect is Rect2 or not spec.safe_rect.position.is_finite() or not spec.safe_rect.size.is_finite() or spec.safe_rect.size.x <= 0.0 or spec.safe_rect.size.y <= 0.0 or spec.safe_rect.position.x < 0.0 or spec.safe_rect.position.y < 0.0 or spec.safe_rect.end.x > 1.0 or spec.safe_rect.end.y > 1.0:
		return _reject("Nonempty normalized screen-safe rectangle required")
	var height: float = float(spec.width) * float(spec.viewport_size.y) / float(spec.viewport_size.x)
	if not is_finite(height) or height <= 0.0 or height > MAX_COORDINATE * 2.0:
		return _reject("Orthographic aspect exceeds the supported numerical bounds")
	var safe: Rect2 = spec.safe_rect
	var margin: float = float(spec.safety_margin)
	var x_limits := Vector2((float(safe.position.x) - 0.5) * float(spec.width) + margin, (float(safe.end.x) - 0.5) * float(spec.width) - margin)
	var y_limits := Vector2((0.5 - float(safe.end.y)) * height + margin, (0.5 - float(safe.position.y)) * height - margin)
	if x_limits.x >= x_limits.y or y_limits.x >= y_limits.y or float(spec.near) + margin >= float(spec.far) - margin:
		return _reject("Safety margin consumes the screen or depth interval")
	return {"accepted": true, "reason": "", "x_limits": x_limits, "y_limits": y_limits, "height": height, "planar_determinant": determinant}


static func _measure(points: Array, focus: Vector3, spec: Dictionary) -> Dictionary:
	var basis: Basis = spec.basis
	var origin: Vector3 = focus + spec.offset
	var camera_x: float = _dot(origin, basis.x)
	var camera_y: float = _dot(origin, basis.y)
	var camera_z: float = _dot(origin, basis.z)
	var min_x: float = INF
	var min_y: float = INF
	var max_x: float = -INF
	var max_y: float = -INF
	var min_depth: float = INF
	var max_depth: float = -INF
	for point: Vector3 in points:
		var x: float = _dot(point, basis.x) - camera_x
		var y: float = _dot(point, basis.y) - camera_y
		var depth: float = camera_z - _dot(point, basis.z)
		min_x = minf(min_x, x)
		max_x = maxf(max_x, x)
		min_y = minf(min_y, y)
		max_y = maxf(max_y, y)
		min_depth = minf(min_depth, depth)
		max_depth = maxf(max_depth, depth)
	var height: float = float(spec.width) * float(spec.viewport_size.y) / float(spec.viewport_size.x)
	var top_left := Vector2(0.5 + min_x / float(spec.width), 0.5 - max_y / height)
	var bottom_right := Vector2(0.5 + max_x / float(spec.width), 0.5 - min_y / height)
	return {"minimum": Vector2(min_x, min_y), "maximum": Vector2(max_x, max_y), "screen_bounds": Rect2(top_left, bottom_right - top_left), "depth_range": Vector2(min_depth, max_depth)}


static func _dot(left: Vector3, right: Vector3) -> float:
	# Scalar double arithmetic avoids an extra native float32 dot/cancellation.
	return float(left.x) * float(right.x) + float(left.y) * float(right.y) + float(left.z) * float(right.z)


static func _bounded(point: Vector3) -> bool:
	return point.is_finite() and maxf(absf(point.x), maxf(absf(point.y), absf(point.z))) <= MAX_COORDINATE


static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


static func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason, "api_revision": API_REVISION}
