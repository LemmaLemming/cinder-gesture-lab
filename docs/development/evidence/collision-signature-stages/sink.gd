extends RefCounted
## PRIVATE observation only. Retains primitive IDs/labels/counters, never native values.
## 0 alone means inherited owner. Negative RefCounted IDs are explicit owners.
## Inclusive timers overlap and contain timer/counter/stack allocation overhead.
static var enabled: bool = false
static var _selected: Array[int] = []
static var _stack: Array = []
static var _methods: Dictionary = {}
static var _sources: Dictionary = {}
static var _edges: Dictionary = {}
static var _counts: Dictionary = {}
static var _source_counts: Dictionary = {}
static var _stack_fault: bool = false
static var _overflow: bool = false


static func reset(source_ids: Array[int]) -> void:
	enabled = false
	_selected = source_ids.duplicate()
	_stack.clear()
	_methods.clear()
	_sources.clear()
	_edges.clear()
	_counts.clear()
	_source_counts.clear()
	_stack_fault = false
	_overflow = source_ids.size() != 8 or source_ids.has(0)


static func begin(label: String, source_id: int = 0) -> int:
	if not enabled:
		return 0
	var owner: int = source_id
	if owner == 0 and not _stack.is_empty():
		owner = _stack.back()[1]
	# An explicit unselected owner suppresses its inherited children even when
	# surrounded by a selected owner. Negative IDs never trigger inheritance.
	_stack.append([label, owner])
	# +1 reserves zero exclusively for disabled observation, including startup.
	return Time.get_ticks_usec() + 1


static func finish(label: String, started: int) -> void:
	if started == 0:
		return
	var elapsed: int = Time.get_ticks_usec() - (started - 1)
	if _stack.is_empty() or _stack.back()[0] != label:
		_stack_fault = true
		return
	var owner: int = _stack.back()[1]
	var parent: String = _stack[_stack.size() - 2][0] if _stack.size() > 1 else "unobserved_caller"
	_stack.pop_back()
	if not _selected.has(owner):
		return
	var key: String = str(owner)
	if not _sources.has(key):
		_sources[key] = {}
	_record(_methods, label, elapsed)
	_record(_sources[key], label, elapsed)
	_record(_edges, parent + " -> " + label, elapsed)


static func collision_counts(visited_nodes: int, colliders: int, shapes: int) -> void:
	if not enabled or _stack.is_empty():
		return
	var owner: int = _stack.back()[1]
	if not _selected.has(owner):
		return
	var key: String = str(owner)
	if not _source_counts.has(key):
		_source_counts[key] = {}
	_record_count(_counts, "visited_nodes", visited_nodes)
	_record_count(_source_counts[key], "visited_nodes", visited_nodes)
	_record_count(_counts, "accepted_colliders", colliders)
	_record_count(_source_counts[key], "accepted_colliders", colliders)
	_record_count(_counts, "extracted_shapes", shapes)
	_record_count(_source_counts[key], "extracted_shapes", shapes)


static func _record(rows: Dictionary, label: String, elapsed: int) -> void:
	if not rows.has(label):
		if rows.size() >= 128:
			_overflow = true
			return
		rows[label] = {"calls": 0, "inclusive_us": 0, "max_us": 0}
	rows[label].calls += 1
	rows[label].inclusive_us += elapsed
	rows[label].max_us = maxi(rows[label].max_us, elapsed)


static func _record_count(rows: Dictionary, label: String, value: int) -> void:
	if not rows.has(label):
		rows[label] = {"samples": 0, "sum": 0, "min": value, "max": value}
	rows[label].samples += 1
	rows[label].sum += value
	rows[label].min = mini(rows[label].min, value)
	rows[label].max = maxi(rows[label].max, value)


static func source_state(source_id: int) -> Dictionary:
	return (_sources.get(str(source_id), {}) as Dictionary).duplicate(true)


static func source_count_state(source_id: int) -> Dictionary:
	return (_source_counts.get(str(source_id), {}) as Dictionary).duplicate(true)


static func state() -> Dictionary:
	return {"methods": _methods.duplicate(true), "sources": _sources.duplicate(true), "nearest_instrumented_edges": _edges.duplicate(true), "primitive_counts": _counts.duplicate(true), "source_primitive_counts": _source_counts.duplicate(true), "stack_empty": _stack.is_empty(), "stack_fault": _stack_fault, "overflow": _overflow, "selected_source_count": _selected.size(), "inherited_owner_sentinel": 0}
