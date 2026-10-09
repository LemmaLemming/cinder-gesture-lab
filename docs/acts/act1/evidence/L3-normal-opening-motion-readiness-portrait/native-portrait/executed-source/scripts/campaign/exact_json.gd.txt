class_name CinderExactJson
extends RefCounted
## Closed JSON-value transport with exact finite scalar bits and types.
## No objects/native variants, executable metadata, clock rounding or tolerance.

const API_REVISION: String = "exact-json-1"
const MAX_DEPTH: int = 64
const MAX_ENTRIES: int = 16384
const MAX_NODES: int = 262144
const MAX_BYTES: int = 8 * 1024 * 1024
const MAX_INTEGER: int = 9007199254740991


static func stringify(value: Variant) -> String:
	var budget: Array[int] = [MAX_NODES, MAX_BYTES]
	var result: Dictionary = _encode(value, 0, budget)
	if not result.accepted:
		return ""
	var text: String = _standard_escapes(JSON.stringify({"api_revision": API_REVISION, "schema_version": 1, "value": result.value}, "", true))
	return text if text.to_utf8_buffer().size() <= MAX_BYTES else ""


static func parse(text: String) -> Dictionary:
	if text.to_utf8_buffer().size() > MAX_BYTES:
		return _error("Exact JSON exceeds the supported byte limit")
	if not _text_within_budget(text):
		return _error("Exact JSON exceeds its raw structural budget")
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return _error("Malformed exact JSON envelope")
	var envelope: Variant = parser.data
	if not envelope is Dictionary or envelope.size() != 3 or envelope.get("api_revision") != API_REVISION or not (envelope.get("schema_version") is int or envelope.get("schema_version") is float) or envelope.get("schema_version") != 1 or not envelope.has("value"):
		return _error("Unsupported exact JSON envelope")
	var budget: Array[int] = [MAX_NODES]
	return _decode(envelope.value, 0, budget)


static func _encode(value: Variant, depth: int, budget: Array[int]) -> Dictionary:
	if not _budget(depth, budget):
		return _error("Exact JSON exceeds its depth or node budget")
	# A lower bound on final bytes rejects oversized aggregate strings before
	# allocating a complete tagged tree. Final escaping is checked separately.
	budget[1] -= 8
	if value is String:
		budget[1] -= value.to_utf8_buffer().size() + 5
	if budget[1] < 0:
		return _error("Exact JSON exceeds its byte budget")
	match typeof(value):
		TYPE_NIL:
			return _value(["null"])
		TYPE_BOOL:
			return _value(["boolean", value])
		TYPE_STRING:
			return _value(["string", value])
		TYPE_INT:
			if value < -MAX_INTEGER or value > MAX_INTEGER:
				return _error("Integer exceeds the supported snapshot range")
			return _value(["integer", str(value)])
		TYPE_FLOAT:
			if not is_finite(value):
				return _error("Float must be finite")
			var bytes := PackedByteArray()
			bytes.resize(8)
			bytes.encode_double(0, value)
			return _value(["float64", bytes.hex_encode()])
		TYPE_ARRAY:
			if value.size() > MAX_ENTRIES:
				return _error("Array exceeds the supported entry limit")
			var entries: Array = []
			for child: Variant in value:
				var encoded: Dictionary = _encode(child, depth + 1, budget)
				if not encoded.accepted:
					return encoded
				entries.append(encoded.value)
			return _value(["array", entries])
		TYPE_DICTIONARY:
			if value.size() > MAX_ENTRIES:
				return _error("Dictionary exceeds the supported entry limit")
			var keys: Array = value.keys()
			for key: Variant in keys:
				if not key is String:
					return _error("Dictionary keys must be strings")
				budget[1] -= key.to_utf8_buffer().size() + 5
				if budget[1] < 0:
					return _error("Exact JSON exceeds its byte budget")
			keys.sort()
			var entries: Array = []
			for key: String in keys:
				var encoded: Dictionary = _encode(value[key], depth + 1, budget)
				if not encoded.accepted:
					return encoded
				entries.append([key, encoded.value])
			return _value(["dictionary", entries])
	return _error("Exact JSON accepts only closed JSON values")


static func _decode(node: Variant, depth: int, budget: Array[int]) -> Dictionary:
	if not _budget(depth, budget) or not node is Array or node.is_empty() or not node[0] is String:
		return _error("Invalid exact JSON node or budget")
	var kind: String = node[0]
	if kind == "null":
		return _value(null) if node.size() == 1 else _error("Null node has extra fields")
	if node.size() != 2:
		return _error("Exact JSON node must have its canonical fields")
	var value: Variant = node[1]
	match kind:
		"boolean":
			return _value(value) if value is bool else _error("Boolean node requires a boolean")
		"string":
			return _value(value) if value is String else _error("String node requires a string")
		"integer":
			if not value is String or value.length() > (17 if value.begins_with("-") else 16) or not value.is_valid_int():
				return _error("Integer node requires canonical decimal text")
			var integer: int = value.to_int()
			if str(integer) != value or integer < -MAX_INTEGER or integer > MAX_INTEGER:
				return _error("Integer text is noncanonical or outside the supported range")
			return _value(integer)
		"float64":
			if not value is String or value.length() != 16:
				return _error("Float node requires eight bytes of lowercase hexadecimal")
			for character: String in value:
				if not "0123456789abcdef".contains(character):
					return _error("Float node contains invalid hexadecimal")
			var bytes: PackedByteArray = value.hex_decode()
			var number: float = bytes.decode_double(0)
			return _value(number) if is_finite(number) else _error("Decoded float must be finite")
		"array":
			if not value is Array or value.size() > MAX_ENTRIES:
				return _error("Invalid bounded array node")
			var entries: Array = []
			for child: Variant in value:
				var decoded: Dictionary = _decode(child, depth + 1, budget)
				if not decoded.accepted:
					return decoded
				entries.append(decoded.value)
			return _value(entries)
		"dictionary":
			if not value is Array or value.size() > MAX_ENTRIES:
				return _error("Invalid bounded dictionary node")
			var entries: Dictionary = {}
			for entry: Variant in value:
				if not entry is Array or entry.size() != 2 or not entry[0] is String or entries.has(entry[0]):
					return _error("Dictionary entries require unique string keys")
				var decoded: Dictionary = _decode(entry[1], depth + 1, budget)
				if not decoded.accepted:
					return decoded
				entries[entry[0]] = decoded.value
			return _value(entries)
	return _error("Unsupported exact JSON node kind")


static func _budget(depth: int, budget: Array[int]) -> bool:
	budget[0] -= 1
	return depth <= MAX_DEPTH and budget[0] >= 0


static func _standard_escapes(text: String) -> String:
	# Godot leaves other C0 controls raw; standard JSON requires escaping them.
	# Native Godot Strings do not represent U+0000: chr(0) itself emits a
	# diagnostic/replacement character. Do not alias real U+FFFD to NUL.
	for code: int in range(1, 32):
		var control: String = String.chr(code)
		if text.contains(control):
			text = text.replace(control, "\\u%04x" % code)
	# Installed Godot json_escape emits nonstandard \v for vertical tabs,
	# while its JSON parser accepts standard \u000b. Replace only unescaped
	# occurrences, preserving ordinary strings containing a backslash and v.
	var parts := PackedStringArray()
	var copied: int = 0
	var searched: int = 0
	while true:
		var found: int = text.find("\\v", searched)
		if found < 0:
			break
		var preceding: int = found - 1
		while preceding >= 0 and text.unicode_at(preceding) == 92:
			preceding -= 1
		if (found - preceding - 1) % 2 == 0:
			parts.append(text.substr(copied, found - copied))
			parts.append("\\u000b")
			copied = found + 2
		searched = found + 2
	if parts.is_empty():
		return text
	parts.append(text.substr(copied))
	return "".join(parts)


static func _text_within_budget(text: String) -> bool:
	# Bound parser allocations before JSON.parse. Tagged dictionaries need
	# three wire containers per logical level and at most five raw nodes per
	# logical value (including entry/key containers); metadata adds a few more.
	var bytes: PackedByteArray = text.to_utf8_buffer()
	var commas: Array[int] = []
	var raw_nodes: int = 0
	var in_string: bool = false
	var in_scalar: bool = false
	var index: int = 0
	while index < bytes.size():
		var code: int = bytes[index]
		if in_string:
			if code == 92:
				if index + 5 < bytes.size() and bytes[index + 1] == 117 and bytes[index + 2] == 48 and bytes[index + 3] == 48 and bytes[index + 4] == 48 and bytes[index + 5] == 48:
					return false # U+0000 cannot become a native Godot String.
				index += 2
				continue
			if code == 34:
				in_string = false
			index += 1
			continue
		if code == 34:
			in_string = true
			in_scalar = false
			raw_nodes += 1
		elif code == 91 or code == 123:
			commas.append(0)
			in_scalar = false
			raw_nodes += 1
			if commas.size() > MAX_DEPTH * 3 + 4:
				return false
		elif code == 93 or code == 125:
			if not commas.is_empty():
				commas.pop_back()
			in_scalar = false
		elif code == 44:
			if not commas.is_empty():
				commas[-1] += 1
				if commas[-1] >= MAX_ENTRIES:
					return false
			in_scalar = false
		elif code == 58 or code == 32 or code == 9 or code == 10 or code == 13:
			in_scalar = false
		elif not in_scalar:
			in_scalar = true
			raw_nodes += 1
		if raw_nodes > MAX_NODES * 5 + 16:
			return false
		index += 1
	return true


static func _value(value: Variant) -> Dictionary:
	return {"accepted": true, "value": value}


static func _error(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}
