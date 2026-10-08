class_name CinderSnapshotCodec
extends RefCounted
## Small JSON transport helpers. Callers own their versioned field schemas.
## Integral JSON numbers may arrive as floats; reject lossy large integers.

const MAX_SAFE_INTEGER: int = 9007199254740991
const MAX_DEPTH: int = 32
const MAX_CONTAINER_ENTRIES: int = 16384


static func is_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


static func is_integer(value: Variant, minimum: int = 0, maximum: int = MAX_SAFE_INTEGER) -> bool:
	return is_number(value) and float(value) >= minimum and float(value) <= maximum and float(value) == floor(float(value))


static func in_range(value: Variant, minimum: float, maximum: float) -> bool:
	return is_number(value) and float(value) >= minimum and float(value) <= maximum


static func vector3(value: Vector3) -> Array:
	return [value.x, value.y, value.z]


static func is_vector3(value: Variant) -> bool:
	return value is Array and value.size() == 3 and is_number(value[0]) and is_number(value[1]) and is_number(value[2]) and read_vector3(value).is_finite()


static func read_vector3(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))


static func keys_error(value: Dictionary, required: Array) -> String:
	if value.size() != required.size():
		return "Snapshot has missing or unsupported fields"
	for key: String in required:
		if not value.has(key):
			return "Missing snapshot field: " + key
	return ""


static func value_error(value: Variant, depth: int = 0) -> String:
	if depth > MAX_DEPTH:
		return "Snapshot nesting exceeds 32 levels"
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_STRING:
			return ""
		TYPE_INT:
			return "" if value >= -MAX_SAFE_INTEGER and value <= MAX_SAFE_INTEGER else "Snapshot integer exceeds exact JSON range"
		TYPE_FLOAT:
			return "" if is_finite(value) else "Snapshot numbers must be finite"
		TYPE_ARRAY:
			if value.size() > MAX_CONTAINER_ENTRIES:
				return "Snapshot array is too large"
			for entry: Variant in value:
				var error: String = value_error(entry, depth + 1)
				if not error.is_empty():
					return error
		TYPE_DICTIONARY:
			if value.size() > MAX_CONTAINER_ENTRIES:
				return "Snapshot dictionary is too large"
			for key: Variant in value:
				if not key is String:
					return "Snapshot dictionary keys must be strings"
				var error: String = value_error(value[key], depth + 1)
				if not error.is_empty():
					return error
		_:
			return "Snapshot contains a non-JSON value"
	return ""


static func same_values(left: Variant, right: Variant) -> bool:
	# Canonical resolved data survives JSON's int/float conversion. No keys or
	# nonnumeric identities may drift; numeric serialization tolerates roundoff.
	if is_number(left) and is_number(right):
		return is_equal_approx(float(left), float(right))
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size():
			return false
		for key: String in left:
			if not right.has(key) or not same_values(left[key], right[key]):
				return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size():
			return false
		for index: int in range(left.size()):
			if not same_values(left[index], right[index]):
				return false
		return true
	return typeof(left) == typeof(right) and left == right
