extends SceneTree
## PRIVATE bounded source-only self-test; no game nodes, source or gameplay calls.
const Sink = preload("res://.cinder/collision-signature-profile/sink.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	var owners: Array[RefCounted] = []
	var selected: Array[int] = []
	for index: int in range(8):
		var owner := RefCounted.new()
		owners.append(owner)
		selected.append(owner.get_instance_id())
	var outsider := RefCounted.new()
	var outsider_id: int = outsider.get_instance_id()
	var every_negative: bool = outsider_id < 0
	for id: int in selected:
		every_negative = every_negative and id < 0
	_expect(every_negative and not selected.has(outsider_id), "actual selected and unselected RefCounted IDs are distinct negative explicit owners")
	Sink.reset(selected)
	var disabled: int = Sink.begin("disabled", selected[0])
	Sink.collision_counts(90, 90, 90)
	Sink.finish("disabled", disabled)
	_expect(disabled == 0 and Sink.state().methods.is_empty() and Sink.state().primitive_counts.is_empty() and Sink.state().stack_empty, "disabled calls leave all counters and stack empty")
	Sink.enabled = true
	var outer: int = Sink.begin("selected_outer", selected[0])
	var child: int = Sink.begin("inherited_selected")
	Sink.collision_counts(3, 2, 1)
	Sink.finish("inherited_selected", child)
	var suppression: int = Sink.begin("unselected_negative", outsider_id)
	var suppressed_child: int = Sink.begin("inherited_unselected")
	Sink.collision_counts(900, 900, 900)
	Sink.finish("inherited_unselected", suppressed_child)
	var nested_explicit: int = Sink.begin("selected_negative_nested", selected[1])
	Sink.collision_counts(6, 4, 2)
	Sink.finish("selected_negative_nested", nested_explicit)
	Sink.finish("unselected_negative", suppression)
	Sink.finish("selected_outer", outer)
	var explicit_root: int = Sink.begin("selected_negative_root", selected[2])
	Sink.finish("selected_negative_root", explicit_root)
	var unowned: int = Sink.begin("unowned_zero_root")
	Sink.collision_counts(700, 700, 700)
	Sink.finish("unowned_zero_root", unowned)
	Sink.enabled = false
	var state: Dictionary = Sink.state()
	var first: Dictionary = Sink.source_state(selected[0])
	var second: Dictionary = Sink.source_state(selected[1])
	var third: Dictionary = Sink.source_state(selected[2])
	_expect(first.size() == 2 and first.has("selected_outer") and first.has("inherited_selected"), "implicit child inherits the surrounding negative selected owner")
	_expect(second.size() == 1 and second.has("selected_negative_nested") and not first.has("selected_negative_nested"), "explicit negative selected owner nested under an unselected owner keeps its own attribution")
	_expect(third.size() == 1 and third.has("selected_negative_root"), "explicit negative root owner is selected without inheritance")
	_expect(Sink.source_state(outsider_id).is_empty() and not state.methods.has("unselected_negative") and not state.methods.has("inherited_unselected"), "explicit unselected negative frame suppresses inherited descendants")
	_expect(not state.methods.has("unowned_zero_root") and state.methods.size() == 4, "zero with no enclosing frame stays unowned")
	_expect(state.primitive_counts.visited_nodes.samples == 2 and state.primitive_counts.visited_nodes.sum == 9 and state.primitive_counts.accepted_colliders.sum == 6 and state.primitive_counts.extracted_shapes.sum == 3, "primitive counts exclude unselected and unowned samples")
	_expect(Sink.source_count_state(selected[0]).visited_nodes.sum == 3 and Sink.source_count_state(selected[1]).visited_nodes.sum == 6, "count attribution follows the same negative-ID ownership rules")
	_expect(state.nearest_instrumented_edges.has("selected_outer -> inherited_selected") and state.nearest_instrumented_edges.has("unselected_negative -> selected_negative_nested"), "nearest instrumented edges retain the actual nesting labels")
	_expect(state.stack_empty and not state.stack_fault and not state.overflow and state.inherited_owner_sentinel == 0, "every enabled and disabled path closes a balanced nonfaulted stack")
	var printed_ids: Array[String] = []
	for id: int in selected:
		printed_ids.append(str(id))
	print("Collision signature sink self-test observation: " + JSON.stringify({"selected_ids": printed_ids, "unselected_id": str(outsider_id), "state": state}))
	print("Collision signature sink self-test: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + label)
