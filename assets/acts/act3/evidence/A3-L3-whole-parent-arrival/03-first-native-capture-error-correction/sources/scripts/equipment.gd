class_name CinderEquipment
extends RefCounted

## Shared, data-driven starter loadout. This first lab stage implements only
## static presets; perk clothing and powerups remain catalogue proposals.
## The player owns action snapshots, pending swaps, HP, ammo and deadlines.

const DATA_PATH: String = "res://data/design/player_equipment.json"
const SLOTS: Array[String] = ["jacket", "pants", "shoes", "weapon"]
const STARTER: Dictionary = {
	"jacket": "CLOTH-J0", "pants": "CLOTH-P0", "shoes": "CLOTH-S0", "weapon": "WEAPON-01"
}
const IMPLEMENTED_IDS: Array[String] = [
	"CLOTH-J0", "CLOTH-J1", "CLOTH-J2",
	"CLOTH-P0", "CLOTH-P1", "CLOTH-P2",
	"CLOTH-S0", "CLOTH-S1", "CLOTH-S2",
	"WEAPON-01", "WEAPON-02", "WEAPON-03", "WEAPON-04"
]

var equipped: Dictionary = STARTER.duplicate(true)
var _data: Dictionary = {}
var _items: Dictionary = {}


func _init() -> void:
	var file: FileAccess = FileAccess.open(DATA_PATH, FileAccess.READ)
	assert(file != null, "Cannot read canonical equipment data: " + DATA_PATH)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert(parsed is Dictionary, "Canonical equipment data must contain a JSON object")
	_data = parsed as Dictionary
	for group: String in ["clothing", "weapons"]:
		for definition: Dictionary in _data[group]:
			_items[String(definition["id"])] = definition
	for id: String in IMPLEMENTED_IDS:
		assert(_items.has(id), "Missing implemented item in canonical data: " + id)
		assert(_items[id].get("perk_id") == null, "Static lab preset must not silently grant a perk: " + id)


func item(id: String) -> Dictionary:
	return (_items.get(id, {}) as Dictionary).duplicate(true)


func item_name(id: String) -> String:
	return String(_items.get(id, {}).get("name", id))


func is_implemented(id: String) -> bool:
	return IMPLEMENTED_IDS.has(id)


func owns(id: String) -> bool:
	# The mechanics lab exposes these presets for comparison, with no unlock grind.
	return is_implemented(id)


func implemented_item_ids() -> Array[String]:
	return IMPLEMENTED_IDS.duplicate()


func available_items(slot: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in IMPLEMENTED_IDS:
		if String(_items[id]["slot"]) == slot:
			result.append(item(id))
	return result


func equip(id: String) -> bool:
	if not owns(id):
		return false
	var slot: String = String(_items[id]["slot"])
	if not SLOTS.has(slot):
		return false
	equipped[slot] = id
	return true


func reset_starter() -> void:
	equipped = STARTER.duplicate(true)


func snapshot() -> Dictionary:
	return equipped.duplicate(true)


func restore(loadout: Dictionary) -> bool:
	# Validate the whole snapshot before committing any slot.
	for slot: String in SLOTS:
		var id: String = String(loadout.get(slot, ""))
		if not owns(id) or String(_items[id]["slot"]) != slot:
			return false
	var restored: Dictionary = {}
	for slot: String in SLOTS:
		restored[slot] = String(loadout[slot])
	equipped = restored
	return true


func baseline() -> Dictionary:
	return (_data["baseline"] as Dictionary).duplicate(true)


func resolved_stats(conditional_deltas: Dictionary = {}) -> Dictionary:
	return _resolve(equipped, conditional_deltas)


func compare(id: String, current_hp: float) -> Dictionary:
	if not owns(id):
		return {}
	var proposed: Dictionary = snapshot()
	proposed[String(_items[id]["slot"])] = id
	var before: Dictionary = resolved_stats()
	var after: Dictionary = _resolve(proposed, {})
	var new_hp: float = health_after_swap(current_hp, float(after["max_health"]))
	return {
		"id": id, "name": item_name(id), "slot": String(_items[id]["slot"]),
		"before": before, "after": after,
		"old_hp": current_hp, "new_hp": new_hp,
		"hp_discarded": maxf(current_hp - new_hp, 0.0),
		"perk_id": null, "role": String(_items[id]["role"]),
		"tradeoff": String(_items[id]["tradeoff"])
	}


func damage_received(raw_damage: float) -> float:
	return maxf(raw_damage, 0.0) / float(resolved_stats()["armour"])


static func health_after_swap(old_hp: float, new_max_hp: float) -> float:
	return minf(old_hp, new_max_hp)


func clothing_net_points(id: String) -> float:
	if not _items.has(id) or String(_items[id]["kind"]) != "clothing":
		return 0.0
	var positive: float = 0.0
	var negative: float = 0.0
	var modifiers: Dictionary = _items[id]["modifiers"]
	for stat: String in modifiers:
		var definition: Dictionary = _data["stats"][stat]
		var points: float = float(modifiers[stat]) / float(definition["budget_step"]) * float(definition["budget_weight"])
		positive += maxf(points, 0.0)
		negative += maxf(-points, 0.0)
	var budgets: Dictionary = _data["budgets"]
	var perk_points: float = float(budgets["perk_points"]) if _items[id].get("perk_id") != null else 0.0
	return positive + perk_points - minf(float(budgets["drawback_credit_points_max"]), negative * float(budgets["drawback_credit_fraction"]))


func acceptance_errors() -> Array[String]:
	var errors: Array[String] = []
	var stats: Dictionary = resolved_stats()
	var gear: Dictionary = stats["gear_multipliers"]
	var gates: Dictionary = _data["loadout_gates"]
	var base: Dictionary = _data["baseline"]
	if float(gear["damage"]) * float(gear["attack_speed"]) > float(gates["gear_primary_dps_proxy_ratio_max"]) + 0.00001:
		errors.append("gear primary throughput proxy exceeds its budget")
	if float(stats["effective_health"]) / float(base["max_health"]) > float(gates["gear_effective_health_ratio_max"]) + 0.00001:
		errors.append("gear effective health exceeds its budget")
	if float(stats["primary_range"]) + 0.00001 < float(gates["geometry_min_primary_range_world_units"]):
		errors.append("primary reach is below the supported minimum")
	if float(stats["dash_distance"]) + 0.00001 < float(gates["geometry_min_dash_distance_world_units"]):
		errors.append("dash distance is below the supported minimum")
	if float(stats["dash_duration"]) + 0.00001 < float(base["dash_invulnerability_s"]) or float(stats["dash_duration"]) >= float(base["dash_cooldown_s"]):
		errors.append("dash duration falls outside invulnerability/cooldown limits")
	return errors


func _resolve(loadout: Dictionary, conditional_deltas: Dictionary) -> Dictionary:
	var raw: Dictionary = {}
	var gear: Dictionary = {}
	var total: Dictionary = {}
	var capped: Array[String] = []
	for stat: String in _data["stats"]:
		raw[stat] = 1.0
	for slot: String in SLOTS:
		var modifiers: Dictionary = _items[String(loadout[slot])]["modifiers"]
		for stat: String in modifiers:
			raw[stat] = float(raw[stat]) + float(modifiers[stat])
	for stat: String in raw:
		var definition: Dictionary = _data["stats"][stat]
		gear[stat] = clampf(float(raw[stat]), float(definition["gear_min"]), float(definition["gear_max"]))
		var total_raw: float = float(gear[stat]) + float(conditional_deltas.get(stat, 0.0))
		total[stat] = clampf(total_raw, float(definition["total_min"]), float(definition["total_max"]))
		if not is_equal_approx(float(raw[stat]), float(gear[stat])) or not is_equal_approx(total_raw, float(total[stat])):
			capped.append(stat)
	var base: Dictionary = _data["baseline"]
	var speed: float = float(base["dash_speed_world_units_per_s"]) * float(total["dash_speed"])
	var distance: float = float(base["dash_distance_world_units"]) * float(total["dash_distance"])
	var max_health: float = float(base["max_health"]) * float(total["max_health"])
	var armour: float = float(base["armour_multiplier"]) * float(total["armour"])
	return {
		"primary_damage": float(base["primary_damage"]) * float(total["damage"]),
		"followup_damage": float(base["followup_damage"]) * float(total["damage"]),
		"primary_range": float(base["primary_range_world_units"]) * float(total["attack_range"]),
		"followup_range": minf(float(base["followup_range_world_units"]) * float(total["attack_range"]), float(_data["modifier_contract"]["followup_range_absolute_max_world_units"])),
		"primary_cooldown": float(base["primary_cooldown_s"]) / float(total["attack_speed"]),
		"followup_cooldown": float(base["followup_cooldown_s"]) / float(total["attack_speed"]),
		"primary_cone_min_dot": float(base["primary_cone_min_dot"]),
		"followup_cone_min_dot": float(base["followup_cone_min_dot"]),
		"primary_cadence_estimate": maxf(float(base["primary_cooldown_s"]) / float(total["attack_speed"]), float(_data["controls"]["double_tap_window_s"]) + float(_data["modifier_contract"]["primary_only_cadence_planning_margin_s"])),
		"dash_speed": speed, "dash_distance": distance, "dash_duration": distance / speed,
		"dash_cooldown": float(base["dash_cooldown_s"]),
		"dash_invulnerability": float(base["dash_invulnerability_s"]),
		"hurt_invulnerability": float(base["hurt_invulnerability_s"]),
		"max_health": max_health, "armour": armour,
		"damage_reduction": 1.0 - 1.0 / armour, "effective_health": max_health * armour,
		"shell_capacity": int(base["shell_capacity"]), "shell_reload": float(base["shell_reload_s"]),
		"primary_hit_reload_credit": float(base["primary_hit_reload_credit_s"]),
		"gear_multipliers": gear, "total_multipliers": total,
		"raw_gear_multipliers": raw, "capped_stats": capped,
		"weapon_id": String(loadout["weapon"]), "weapon_name": item_name(String(loadout["weapon"]))
	}
