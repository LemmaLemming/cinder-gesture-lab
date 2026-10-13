extends SceneTree

const EquipmentScript: GDScript = preload("res://scripts/equipment.gd")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var gear: CinderEquipment = EquipmentScript.new() as CinderEquipment
	var starter: Dictionary = gear.snapshot()
	_expect(starter == {"jacket": "CLOTH-J0", "pants": "CLOTH-P0", "shoes": "CLOTH-S0", "weapon": "WEAPON-01"}, "starter uses all canonical neutral item IDs")
	var neutral: Dictionary = gear.resolved_stats()
	_expect(_near(neutral["max_health"], 100.0) and _near(neutral["armour"], 1.0) and _near(neutral["effective_health"], 100.0), "neutral equipment keeps baseline health and mitigation")
	_expect(_near(neutral["primary_damage"], 20.0) and _near(neutral["followup_damage"], 42.0), "one neutral weapon profile defines both baseline attacks")
	_expect(_near(neutral["dash_speed"], 15.0) and _near(neutral["dash_distance"], 2.7) and _near(neutral["dash_duration"], 0.18), "starter dash preserves deliberate baseline travel and duration")
	_expect(neutral["shell_capacity"] == 2 and _near(neutral["shell_reload"], 1.15) and _near(neutral["primary_hit_reload_credit"], 0.45), "every profile retains the shared shell/reload contract")
	_expect(gear.implemented_item_ids().size() == 13 and gear.available_items("weapon").size() == 4, "lab exposes four profiles and nine static clothing choices")
	_expect(not gear.owns("CLOTH-P3") and not gear.equip("CLOTH-P3") and not gear.owns("POWER-01"), "unimplemented perks and powerups cannot be silently equipped")
	_expect(gear.snapshot() == starter, "rejecting an unavailable item does not mutate equipment")

	# Expected values come from the canonical profile's tactical tradeoffs.
	var profiles: Array[Dictionary] = [
		{"id": "WEAPON-01", "damage": 20.0, "blast": 42.0, "reach": 2.0, "blast_reach": 3.1, "cooldown": 0.30, "blast_cooldown": 0.45, "proxy": 1.0},
		{"id": "WEAPON-02", "damage": 17.0, "blast": 35.7, "reach": 1.9, "blast_reach": 2.945, "cooldown": 0.30 / 1.15, "blast_cooldown": 0.45 / 1.15, "proxy": 0.9775},
		{"id": "WEAPON-03", "damage": 24.0, "blast": 50.4, "reach": 1.8, "blast_reach": 2.79, "cooldown": 0.375, "blast_cooldown": 0.5625, "proxy": 0.96},
		{"id": "WEAPON-04", "damage": 19.0, "blast": 39.9, "reach": 2.2, "blast_reach": 3.41, "cooldown": 1.0 / 3.0, "blast_cooldown": 0.5, "proxy": 0.855}
	]
	for profile: Dictionary in profiles:
		gear.reset_starter()
		_expect(gear.equip(String(profile["id"])), "%s can replace the single weapon profile" % profile["id"])
		var stats: Dictionary = gear.resolved_stats()
		_expect(_near(stats["primary_damage"], profile["damage"]) and _near(stats["followup_damage"], profile["blast"]), "%s damage changes both attacks" % profile["id"])
		_expect(_near(stats["primary_range"], profile["reach"]) and _near(stats["followup_range"], profile["blast_reach"]), "%s reach preserves each attack's original cone" % profile["id"])
		_expect(_near(stats["primary_cooldown"], profile["cooldown"]) and _near(stats["followup_cooldown"], profile["blast_cooldown"]), "%s recovery matches its attack speed" % profile["id"])
		var multipliers: Dictionary = stats["gear_multipliers"]
		_expect(_near(float(multipliers["damage"]) * float(multipliers["attack_speed"]), profile["proxy"]), "%s neutral throughput proxy meets the reference budget" % profile["id"])
		_expect(_near(stats["primary_cone_min_dot"], 0.05) and _near(stats["followup_cone_min_dot"], 0.5), "%s profile does not widen the hit cone" % profile["id"])

	gear.reset_starter()
	gear.equip("WEAPON-02")
	_expect(_near(gear.resolved_stats()["primary_cadence_estimate"], 0.30), "Quick Edge planning cadence retains the nearby double-tap timing margin")
	gear.reset_starter()
	gear.equip("CLOTH-J1")
	_expect(_near(gear.damage_received(20.0), 20.0 / 1.2), "Padded Jacket armour divides damage and retains fractional HP")
	_expect(_near(gear.resolved_stats()["damage_reduction"], 1.0 / 6.0), "armour tooltip uses actual damage reduction")
	gear.reset_starter()
	var before: Dictionary = gear.snapshot()
	var increased: Dictionary = gear.compare("CLOTH-P2", 70.0)
	_expect(_near(increased["after"]["max_health"], 110.0) and _near(increased["new_hp"], 70.0), "increased health capacity does not heal")
	var reduced: Dictionary = gear.compare("CLOTH-J2", 95.0)
	_expect(_near(reduced["new_hp"], 90.0) and _near(reduced["hp_discarded"], 5.0), "comparison previews HP discarded by lower capacity")
	_expect(gear.snapshot() == before, "equipment comparison does not commit a replacement")
	_expect(_near(CinderEquipment.health_after_swap(0.0, 110.0), 0.0), "replacement cannot revive a dead player")

	gear.equip("CLOTH-S1")
	var faster: Dictionary = gear.resolved_stats()
	_expect(_near(faster["dash_speed"], 16.5) and _near(faster["dash_distance"], 2.7), "Burst Shoes change arrival speed without extending a landing")
	gear.reset_starter()
	gear.equip("CLOTH-S2")
	var longer: Dictionary = gear.resolved_stats()
	_expect(_near(longer["dash_speed"], 14.25) and _near(longer["dash_distance"], 2.97) and _near(longer["dash_duration"], 2.97 / 14.25), "Longstep Shoes increase distance and committed time independently")
	gear.reset_starter()
	gear.equip("CLOTH-J2")
	var additive: Dictionary = gear.resolved_stats({"damage": 0.15})
	_expect(_near(additive["primary_damage"], 25.0), "gear and eligible action deltas use one additive total bucket")
	var limited: Dictionary = gear.resolved_stats({"attack_range": 0.50, "damage": 0.90})
	_expect(_near(limited["primary_damage"], 35.0) and _near(limited["primary_range"], 2.6) and _near(limited["followup_range"], 3.8), "total caps and absolute blast range cap are applied")
	_expect(limited["capped_stats"].has("damage") and limited["capped_stats"].has("attack_range"), "comparison stat data names discarded over-cap modifiers")

	var saved: Dictionary = gear.snapshot()
	saved["weapon"] = "WEAPON-03"
	_expect(gear.snapshot()["weapon"] == "WEAPON-01", "snapshot edits cannot mutate the live loadout")
	_expect(gear.restore(saved) and gear.snapshot()["weapon"] == "WEAPON-03", "a coherent equipment snapshot restores all IDs")
	var invalid: Dictionary = gear.snapshot()
	invalid["shoes"] = "CLOTH-P2"
	var before_invalid: Dictionary = gear.snapshot()
	_expect(not gear.restore(invalid) and gear.snapshot() == before_invalid, "invalid snapshots fail atomically without partial changes")
	gear.reset_starter()
	_expect(gear.snapshot() == starter and _near(gear.resolved_stats()["primary_damage"], 20.0), "explicit fresh-run reset returns to neutral without accumulated modifiers")

	var loadout_count: int = 0
	var invalid_loadouts: Array[String] = []
	for jacket: Dictionary in gear.available_items("jacket"):
		for pants: Dictionary in gear.available_items("pants"):
			for shoes: Dictionary in gear.available_items("shoes"):
				for weapon: Dictionary in gear.available_items("weapon"):
					gear.restore({"jacket": jacket["id"], "pants": pants["id"], "shoes": shoes["id"], "weapon": weapon["id"]})
					loadout_count += 1
					if not gear.acceptance_errors().is_empty():
						invalid_loadouts.append(str(gear.snapshot()))
	_expect(loadout_count == 108 and invalid_loadouts.is_empty(), "all 108 implemented static loadouts retain escape/reach/health/output budget limits")
	var over_budget: Array[String] = []
	for slot: String in ["jacket", "pants", "shoes"]:
		for definition: Dictionary in gear.available_items(slot):
			if gear.clothing_net_points(String(definition["id"])) > 3.00001:
				over_budget.append(String(definition["id"]))
	_expect(over_budget.is_empty(), "implemented clothing follows the shared per-item authoring budget")
	print("Equipment smoke: %d checks, %d failures; %d static loadouts screened" % [_checks, _failures, loadout_count])
	quit(0 if _failures == 0 else 1)


func _near(actual: Variant, expected: Variant) -> bool:
	return absf(float(actual) - float(expected)) < 0.00001


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
