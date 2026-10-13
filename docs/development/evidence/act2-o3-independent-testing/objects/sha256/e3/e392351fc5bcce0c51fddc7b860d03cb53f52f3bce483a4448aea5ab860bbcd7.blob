#!/usr/bin/env python3
"""Screen proposed equipment data; this does not simulate Godot or prove balance.

Run from any directory: python3 scripts/design/validate_equipment.py
An optional JSON path allows review of a candidate without changing canonical data.
Formula strings in the JSON are documentation. They are never evaluated as code.
"""

from __future__ import annotations

import argparse
import itertools
import json
import math
import re
import sys
from pathlib import Path


EPSILON = 1e-9
STAT_NAMES = {
    "damage", "attack_speed", "attack_range", "dash_speed",
    "dash_distance", "max_health", "armour",
}
MODELLED_PERKS = {"PERK-01", "PERK-02", "PERK-03"}
TOP_KEYS = {
    "schema_version", "design_status", "date", "authority",
    "confirmed_preferences", "controls", "baseline", "modifier_contract",
    "stats", "budgets", "loadout_gates", "lifecycle", "effect_event_order",
    "perks", "clothing", "weapons", "powerups", "numeric_fixtures",
    "validation_status", "hit_contract",
}
ITEM_KEYS = {
    "id", "name", "kind", "slot", "status", "acts", "modifiers", "perk_id",
    "role", "tradeoff",
}
POWER_KEYS = {
    "id", "name", "kind", "status", "group", "acts", "modifiers",
    "duration_s", "charges", "shape_override", "max_stacks",
    "same_id_repickup", "different_id_repickup", "expires_on", "timer_clock",
    "eligible_charge_action", "action_modifiers",
}
PERK_KEYS = {
    "id", "name", "status", "trigger", "effect", "limits", "required_tradeoff",
    "eligible_origin", "count_scope", "can_trigger_other_effects", "cooldown_start",
}
SECTION_KEYS = {
    "authority": {"normative_rules", "numeric_values", "research",
                  "formula_strings_are_documentation_not_executable_code"},
    "confirmed_preferences": {"combo_interpretation", "equipment_between_acts", "status"},
    "controls": {"voluntary_movement", "primary", "followup", "double_tap_window_s",
                 "double_tap_distance_virtual_px_strictly_less_than", "aim_origin",
                 "initial_aim_origin", "zero_direction", "dash_buffer_capacity",
                 "auto_aim", "act_specific_controller"},
    "lifecycle": {"clothing_swap", "weapon_swap", "one_weapon_defines", "swap_health",
                  "weapon_swap_ammo", "weapon_swap_reload", "cooldown_swap", "buff_pause",
                  "checkpoint", "between_acts", "neutral_loadout_available_at_checkpoints", "death",
                  "weapon_swap_action_end"},
    "validation_status": {"numerical_screen", "real_gesture_cadence", "encounter_balance",
                          "mobile_device_validation"},
    "hit_contract": {"primary_hit", "primary_miss", "immune_overlap_counts_as_hit",
                     "per_target_result_fields", "target_scoped_bonuses", "first_opening_ledger"},
}
PERK_NESTED_KEYS = {
    "trigger": {"event", "distinct_primary_actions", "max_gap_s", "health_fraction_below",
                "reads", "requires", "stationary_time_s", "distinct_live_enemy_targets_min",
                "shells_at_action_begin", "previous_dash_gap_s_max", "direction_dot_max",
                "target_state", "crosses_health_fraction_below", "distinct_live_enemy_targets_exact",
                "requires_alive_after_hit", "requires_no_threat_collision_even_if_invulnerability_blocks_damage"},
    "effect": {"stat", "delta", "delta_max", "scope", "amount", "scaling_coefficient"},
    "limits": {"reset_on", "advance_on_followup", "advance_on_prop_hit",
               "max_bonus_at_health_fraction", "snapshot", "self_damage_rewards",
               "reads_current_health", "reads_temporary_armour", "changes_distance",
               "duration_s", "cooldown_s", "consumed_on", "awards_for_invulnerability_tanking",
               "line_of_sight_required", "maximum_total_reload_credit_per_action_s",
               "no_credit_when_full", "no_instant_shell_refill", "boss_displacement",
               "no_damage_bonus", "extra_damage_does_not_make_enemy_vulnerable",
               "uses_per_encounter", "affects_triggering_hit", "healing_amount", "refreshes",
               "duration_refresh_on_miss", "no_credit_from_props", "uses_per_enemy",
               "boss_uses_per_phase", "generated_hits_eligible", "target_evaluation", "uses_per_completed_dash"},
}


class InvalidStructure(ValueError):
    """A malformed value prevents safe enumeration of the remaining data."""


class Screen:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.extrema: dict[str, tuple[float, float]] = {}

    def check(self, condition: bool, message: str) -> None:
        if not condition:
            self.errors.append(message)

    def keys(self, obj: object, label: str, required: set[str],
             optional: set[str] | None = None) -> dict:
        if not isinstance(obj, dict):
            raise InvalidStructure(f"{label}: expected an object")
        missing = required - obj.keys()
        unknown = obj.keys() - required - (optional or set())
        if missing:
            raise InvalidStructure(f"{label}: missing keys {sorted(missing)}")
        self.check(not unknown, f"{label}: unknown keys {sorted(unknown)}")
        return obj

    def number(self, value: object, label: str, positive: bool = False) -> float:
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            raise InvalidStructure(f"{label}: expected a finite number")
        if not math.isfinite(value):
            raise InvalidStructure(f"{label}: expected a finite number")
        if positive and value <= 0:
            raise InvalidStructure(f"{label}: must be greater than zero")
        return float(value)

    def observe(self, name: str, value: float) -> None:
        low, high = self.extrema.get(name, (value, value))
        self.extrema[name] = min(low, value), max(high, value)

    def report_errors(self) -> int:
        errors = list(dict.fromkeys(self.errors))
        if not errors:
            return 0
        print(f"FAIL: {len(errors)} equipment validation error(s).", file=sys.stderr)
        for error in errors[:25]:
            print(f"  - {error}", file=sys.stderr)
        if len(errors) > 25:
            print(f"  ... {len(errors) - 25} further errors omitted.", file=sys.stderr)
        return 1


def clamp(value: float, lower: float, upper: float) -> float:
    return max(lower, min(upper, value))


def last_thread_delta(perk: dict, health_fraction: float) -> float:
    """PERK-02: linear missing-health bonus between two authored thresholds."""
    start = perk["trigger"]["health_fraction_below"]
    peak = perk["limits"]["max_bonus_at_health_fraction"]
    return perk["effect"]["delta_max"] * clamp(
        (start - health_fraction) / (start - peak), 0.0, 1.0)


def stride_delta(perk: dict, armour: float, health_multiplier: float) -> float:
    """PERK-03: only preperk gear armour and maximum-health ratio are read."""
    return min(perk["effect"]["delta_max"],
               perk["effect"]["scaling_coefficient"] * (armour - 1.0) / health_multiplier)


def formula_number(value: float) -> str:
    """Render authored numeric parameters with at least two decimal places."""
    rendered = f"{value:.12f}".rstrip("0").rstrip(".")
    if "." not in rendered:
        return rendered + ".00"
    return rendered + "0" * max(0, 2 - len(rendered.split(".")[1]))


def validate_structure(data: dict, screen: Screen) -> dict[str, dict]:
    screen.keys(data, "root", TOP_KEYS)
    for section, keys in SECTION_KEYS.items():
        screen.keys(data[section], section, keys)
    screen.check(data["authority"]["formula_strings_are_documentation_not_executable_code"] is True,
                 "authority: formula strings must remain documentation, never executable code")
    controls = data["controls"]
    screen.check(controls["voluntary_movement"] == "swipe_dash_only" and
                 controls["primary"] == "immediate_first_tap" and
                 controls["followup"] == "second_nearby_tap" and
                 controls["aim_origin"] == "last_completed_swipe_release_screen_position" and
                 controls["auto_aim"] is False and controls["act_specific_controller"] is False,
                 "controls: catalogue must preserve the shared confirmed gesture controller")
    for key in ("double_tap_window_s", "double_tap_distance_virtual_px_strictly_less_than",
                "dash_buffer_capacity"):
        screen.number(controls[key], f"controls.{key}", positive=True)
    screen.check(controls["dash_buffer_capacity"] == 1,
                 "controls.dash_buffer_capacity: preserve one buffered dash")
    screen.check(math.isclose(controls["double_tap_window_s"], 0.280, abs_tol=EPSILON) and
                 controls["double_tap_distance_virtual_px_strictly_less_than"] == 90,
                 "controls: preserve the 0.280 s / strictly-less-than-90-pixel followup recognizer")
    screen.check(controls["initial_aim_origin"] == "viewport_center" and
                 controls["zero_direction"] == "retain_last_facing",
                 "controls: reset at viewport center; zero-direction attacks retain last facing")
    preferences = data["confirmed_preferences"]
    screen.check(preferences["combo_interpretation"] == "three_landed_primary_actions_with_modest_finisher" and
                 preferences["equipment_between_acts"] == "carry_equipped_loadout" and
                 preferences["status"] == "user_confirmed",
                 "confirmed_preferences: preserve the confirmed modest three-hit finisher and carried loadout")
    lifecycle = data["lifecycle"]
    screen.check(lifecycle["between_acts"] == "carry_equipped_loadout_clear_temporary_effects" and
                 lifecycle["weapon_swap_action_end"] == "end_of_resolved_dash_or_attack_phase; not_cooldown_expiry" and
                 lifecycle["swap_health"] == "min(old_current_health, new_max_health)" and
                 lifecycle["weapon_swap_ammo"] == "preserve_current_shells" and
                 lifecycle["weapon_swap_reload"] == "preserve_elapsed_reload_time" and
                 lifecycle["cooldown_swap"] == "preserve_outstanding_deadline_never_shorten",
                 "lifecycle: preserve carried gear, resolved-action swaps, health, ammo, reload and cooldown deadlines")
    hit = data["hit_contract"]
    screen.check(hit["primary_hit"] == "accepted_nonzero_direct_damage_to_enemy_alive_at_action_begin_including_lethal_hits" and
                 hit["primary_miss"] == "executed_primary_with_zero_accepted_live_enemy_damage_results" and
                 hit["immune_overlap_counts_as_hit"] is False and
                 hit["per_target_result_fields"] == ["accepted", "hp_damage", "target_id", "target_alive_before_hit"] and
                 hit["target_scoped_bonuses"] == "all_qualifying_targets_from_pre_action_snapshot; commit_cooldown_once_after_resolution",
                 "hit_contract: require accepted live-enemy damage, lethal hits and pre-action target evaluation")
    screen.check(data["schema_version"] == "1.0.0",
                 "schema_version: unsupported version; update the validator deliberately")
    screen.keys(data["stats"], "stats", STAT_NAMES)
    for name, stat in data["stats"].items():
        screen.keys(stat, f"stats.{name}", {
            "gear_min", "gear_max", "total_min", "total_max",
            "budget_step", "budget_weight",
        })
        for key, value in stat.items():
            screen.number(value, f"stats.{name}.{key}", positive=True)
        screen.check(stat["total_min"] <= stat["gear_min"] <= 1 <=
                     stat["gear_max"] <= stat["total_max"],
                     f"stats.{name}: require total_min <= gear_min <= 1 <= gear_max <= total_max")

    screen.keys(data["baseline"], "baseline", {
        "max_health", "primary_damage", "primary_range_world_units",
        "primary_cooldown_s", "primary_cone_min_dot", "followup_damage",
        "followup_range_world_units", "followup_cooldown_s", "followup_cone_min_dot",
        "shell_capacity", "shell_reload_s", "primary_hit_reload_credit_s",
        "dash_speed_world_units_per_s", "dash_distance_world_units", "dash_cooldown_s",
        "dash_invulnerability_s", "hurt_invulnerability_s", "armour_multiplier",
    })
    for key, value in data["baseline"].items():
        screen.number(value, f"baseline.{key}", positive=True)
    baseline = data["baseline"]
    screen.check(baseline["armour_multiplier"] == 1,
                 "baseline.armour_multiplier: the authored delta model requires neutral armour 1")
    screen.check(baseline["shell_capacity"] == int(baseline["shell_capacity"]),
                 "baseline.shell_capacity: expected an integer")
    for key in ("primary_cone_min_dot", "followup_cone_min_dot"):
        screen.check(-1 <= baseline[key] <= 1, f"baseline.{key}: outside [-1, 1]")

    screen.keys(data["budgets"], "budgets", {
        "clothing_net_points_max", "perk_points", "drawback_credit_fraction",
        "drawback_credit_points_max", "nonzero_stats_without_perk_max",
        "nonzero_stats_with_perk_max", "positive_static_stats_with_perk_max", "formula",
        "same_budget_all_acts", "rarity_adds_power_budget",
        "weapon_neutral_primary_dps_ratio_min", "weapon_neutral_primary_dps_ratio_max",
        "range_has_separate_cost",
    })
    screen.keys(data["loadout_gates"], "loadout_gates", {
        "gear_primary_dps_proxy_ratio_max", "conditional_primary_dps_proxy_ratio_max",
        "temporary_primary_dps_proxy_ratio_max", "gear_effective_health_ratio_max",
        "total_effective_health_ratio_max", "primary_per_hit_damage_ratio_max",
        "evaluate_all_conditional_peaks_not_expected_uptime_only", "dps_proxy",
        "geometry_min_primary_range_world_units", "geometry_min_dash_distance_world_units",
        "max_active_perks", "max_active_powerup_groups",
    })
    screen.keys(data["modifier_contract"], "modifier_contract", {
        "combine", "gear_stage", "total_stage", "damage_received", "effective_health",
        "dash_duration_s", "attack_cooldown_s", "act_number_enters_equation",
        "negative_dash_distance_modifiers_allowed", "rounding",
        "followup_range_absolute_max_world_units", "same_ability_multiple_sources",
        "reload_extra_credit_policy", "reload_total_credit_cap_per_action_s",
        "scoped_modifiers", "primary_only_cadence_planning_margin_s",
    })
    for section in ("budgets", "loadout_gates", "modifier_contract"):
        for key, value in data[section].items():
            if isinstance(value, (int, float)) and not isinstance(value, bool):
                screen.number(value, f"{section}.{key}", positive=True)
    contract = data["modifier_contract"]
    screen.check(contract["combine"] == "add_fractional_deltas_then_clamp_once_per_stage",
                 "modifier_contract.combine: validator only supports additive per-stage deltas")
    screen.check(not contract["act_number_enters_equation"],
                 "modifier_contract: act number must not affect character stats")
    screen.check(not contract["negative_dash_distance_modifiers_allowed"],
                 "modifier_contract: required traversal requires no negative dash-distance modifiers")
    screen.check(data["budgets"]["same_budget_all_acts"] and
                 not data["budgets"]["rarity_adds_power_budget"],
                 "budgets: all acts/rarities must use the same power budget")
    screen.check(data["loadout_gates"]["evaluate_all_conditional_peaks_not_expected_uptime_only"],
                 "loadout_gates: all conditional peak subsets must be screened")

    all_ids: set[str] = set()
    perks: dict[str, dict] = {}
    for section, prefix in (("perks", "PERK"), ("clothing", "CLOTH"),
                            ("weapons", "WEAPON"), ("powerups", "POWER"),
                            ("numeric_fixtures", "FIX")):
        if not isinstance(data[section], list):
            raise InvalidStructure(f"{section}: expected an array")
        for index, record in enumerate(data[section]):
            if not isinstance(record, dict) or not isinstance(record.get("id"), str):
                raise InvalidStructure(f"{section}[{index}]: expected an object with a string id")
            identifier = record["id"]
            screen.check(identifier not in all_ids, f"{identifier}: duplicate ID")
            screen.check(bool(re.fullmatch(prefix + r"-[A-Z0-9]+", identifier)),
                         f"{identifier}: ID must start with {prefix}- and contain A-Z/0-9")
            all_ids.add(identifier)
            if section == "perks":
                screen.keys(record, identifier, PERK_KEYS, {"expression"})
                expected_origin = "accepted_enemy_or_environment_damage" if identifier == "PERK-11" else "player_direct"
                screen.check(record["eligible_origin"] == expected_origin and
                             record["count_scope"] == "once_per_action" and
                             record["can_trigger_other_effects"] is False,
                             f"{identifier}: require {expected_origin}, once-per-action, nonrecursive triggers")
                screen.check(record["cooldown_start"] == "first_eligible_trigger_event",
                             f"{identifier}: cooldown begins at the first eligible trigger event")
                for field in ("trigger", "effect", "limits", "required_tradeoff"):
                    if not isinstance(record[field], dict):
                        raise InvalidStructure(f"{identifier}.{field}: expected an object")
                for field, allowed in PERK_NESTED_KEYS.items():
                    required = {"event"} if field == "trigger" else {"stat"} if field == "effect" else set()
                    screen.keys(record[field], f"{identifier}.{field}", required, allowed - required)
                    for key, value in record[field].items():
                        if isinstance(value, (int, float)) and not isinstance(value, bool):
                            screen.number(value, f"{identifier}.{field}.{key}")
                screen.check(record["limits"].get("target_evaluation") ==
                             "snapshot_all_qualifying_targets_before_action; commit_state_after_resolution",
                             f"{identifier}: evaluate all qualifying targets before committing action state")
                if identifier == "PERK-04":
                    screen.check(record["trigger"].get("requires_no_threat_collision_even_if_invulnerability_blocks_damage") is True,
                                 f"{identifier}: invulnerability collision must not qualify as an escaped threat")
                elif identifier == "PERK-05":
                    screen.check(record["limits"].get("uses_per_completed_dash") == 1,
                                 f"{identifier}: allow one use per completed dash")
                elif identifier == "PERK-11":
                    screen.check(record["trigger"].get("requires_alive_after_hit") is True,
                                 f"{identifier}: reserve armour can activate only after a survived hit")
                screen.check(record["effect"].get("stat") in STAT_NAMES | {"reload_credit_s", "knockback"},
                             f"{identifier}: unknown effect stat")
                screen.check(bool(record["required_tradeoff"]),
                             f"{identifier}: at least one compulsory static tradeoff is required")
                validate_modifiers(record["required_tradeoff"], identifier + ".required_tradeoff", screen)
                for stat, delta in record["required_tradeoff"].items():
                    screen.check(delta < 0, f"{identifier}: compulsory {stat} tradeoff must be negative")
                perks[identifier] = record
            elif section in ("clothing", "weapons"):
                screen.keys(record, identifier, ITEM_KEYS)
                screen.check(record["kind"] == ("clothing" if section == "clothing" else "weapon"),
                             f"{identifier}: wrong kind for {section}")
                screen.check(record["slot"] in ({"jacket", "pants", "shoes"} if section == "clothing" else {"weapon"}),
                             f"{identifier}: invalid slot {record['slot']!r}")
                validate_modifiers(record["modifiers"], identifier, screen)
                validate_acts(record, screen)
            elif section == "powerups":
                screen.keys(record, identifier, POWER_KEYS)
                validate_modifiers(record["modifiers"], identifier, screen)
                if not isinstance(record["action_modifiers"], dict):
                    raise InvalidStructure(f"{identifier}.action_modifiers: expected an object")
                screen.check(not (record["action_modifiers"].keys() - {"primary", "followup"}),
                             f"{identifier}: action_modifiers supports only primary and followup actions")
                for action, modifiers in record["action_modifiers"].items():
                    validate_modifiers(modifiers, f"{identifier}.action_modifiers.{action}", screen)
                    screen.check(not (modifiers.keys() - {"damage", "attack_speed", "attack_range"}),
                                 f"{identifier}.{action}: action-scoped stats must be damage, attack_speed or attack_range")
                validate_acts(record, screen)
                screen.check(record["kind"] == "powerup", f"{identifier}: kind must be powerup")
                screen.check(record["group"] in {"mobility", "combat"}, f"{identifier}: unknown powerup group")
                screen.check(record["max_stacks"] == 1, f"{identifier}: max_stacks must be 1")
                timed = record["duration_s"] is not None
                charged = record["charges"] is not None
                screen.check(timed != charged, f"{identifier}: define exactly one of duration_s or charges")
                if timed:
                    screen.number(record["duration_s"], identifier + ".duration_s", positive=True)
                if charged:
                    value = screen.number(record["charges"], identifier + ".charges", positive=True)
                    screen.check(value == int(value), f"{identifier}: charges must be an integer")
                screen.check(record["shape_override"] in {None, "primary_360_degrees"},
                             f"{identifier}: unsupported shape_override")
                if record["shape_override"] == "primary_360_degrees":
                    screen.check(charged and record["eligible_charge_action"] == "executed_primary",
                                 f"{identifier}: primary 360-degree shape must consume executed-primary charges")
                    primary = record["action_modifiers"].get("primary", {})
                    screen.check(primary.get("damage", 0) < 0,
                                 f"{identifier}: primary 360-degree shape requires a primary-scoped damage tradeoff")
                    screen.check(not record["modifiers"] and
                                 not record["action_modifiers"].get("followup"),
                                 f"{identifier}: primary 360-degree powerup must leave the followup unchanged")
                screen.check(record["timer_clock"] == "active_simulation" and
                             record["different_id_repickup"] == "replace_same_group" and
                             record["same_id_repickup"] == "replace_remaining_duration_or_charges_with_initial_value",
                             f"{identifier}: unsupported timer or replacement policy")
            else:
                screen.keys(record, identifier, {"id", "input", "expected"})

    for identifier in MODELLED_PERKS:
        screen.check(identifier in perks, f"{identifier}: required numeric perk model is missing")
    if not MODELLED_PERKS <= perks.keys():
        return perks
    screen.check(perks["PERK-01"]["effect"].get("stat") == "damage" and
                 perks["PERK-01"]["trigger"].get("distinct_primary_actions") == 3,
                 "PERK-01: validator models a damage bonus on every third distinct primary action")
    screen.number(perks["PERK-01"]["effect"].get("delta"), "PERK-01.effect.delta")
    second = perks["PERK-02"]
    start = screen.number(second["trigger"].get("health_fraction_below"), "PERK-02.threshold")
    peak = screen.number(second["limits"].get("max_bonus_at_health_fraction"), "PERK-02.peak")
    screen.check(0 <= peak < start <= 1, "PERK-02: require 0 <= peak health < trigger health <= 1")
    screen.check(second["effect"].get("stat") == "damage", "PERK-02: effect stat must be damage")
    screen.number(second["effect"].get("delta_max"), "PERK-02.delta_max", positive=True)
    third = perks["PERK-03"]
    screen.check(third["effect"].get("stat") == "dash_speed", "PERK-03: effect stat must be dash_speed")
    screen.number(third["effect"].get("delta_max"), "PERK-03.delta_max", positive=True)
    screen.number(third["effect"].get("scaling_coefficient"), "PERK-03.scaling_coefficient", positive=True)
    screen.check(third["limits"].get("reads_current_health") is False and
                 third["limits"].get("reads_temporary_armour") is False and
                 third["limits"].get("changes_distance") is False,
                 "PERK-03: must read static gear maximum health/armour and leave distance unchanged")
    # Documentation and numeric models must be revised together; do not eval text.
    expected_expressions = {
        "PERK-02": f"{formula_number(second['effect']['delta_max'])} * clamp(({formula_number(start)} - health_fraction) / {formula_number(start - peak)}, 0, 1)",
        "PERK-03": f"min({formula_number(third['effect']['delta_max'])}, {formula_number(third['effect']['scaling_coefficient'])} * (gear_armour - 1) / gear_health_multiplier)",
    }
    for identifier, expression in expected_expressions.items():
        screen.check(perks[identifier].get("expression") == expression,
                     f"{identifier}: expression documentation changed; update explicit numeric model deliberately")
    return perks


def validate_modifiers(modifiers: object, label: str, screen: Screen) -> None:
    if not isinstance(modifiers, dict):
        raise InvalidStructure(f"{label}.modifiers: expected an object")
    screen.check(not (modifiers.keys() - STAT_NAMES),
                 f"{label}: unknown modifier keys {sorted(modifiers.keys() - STAT_NAMES)}")
    for stat, delta in modifiers.items():
        value = screen.number(delta, f"{label}.{stat}")
        screen.check(value > -1, f"{label}.{stat}: individual fractional delta must be greater than -1")
        if stat == "dash_distance":
            screen.check(value >= 0, f"{label}: negative dash distance would break baseline traversal")


def validate_acts(record: dict, screen: Screen) -> None:
    screen.check(record["acts"] == [1, 2, 3],
                 f"{record['id']}: numeric catalogue entries must remain available in all three acts")


def aggregate(records: tuple | list, stats: dict, stage: str,
              initial: dict[str, float] | None = None) -> dict[str, float]:
    sums = dict(initial) if initial else {stat: 1.0 for stat in stats}
    for record in records:
        for stat, delta in record["modifiers"].items():
            sums[stat] += delta
    return {stat: clamp(value, stats[stat][stage + "_min"],
                       stats[stat][stage + "_max"]) for stat, value in sums.items()}


def validate_items(data: dict, perks: dict, screen: Screen) -> None:
    budget = data["budgets"]
    stats = data["stats"]
    for item in data["clothing"] + data["weapons"]:
        identifier = item["id"]
        perk_id = item["perk_id"]
        screen.check(perk_id is None or perk_id in perks, f"{identifier}: unknown perk_id {perk_id!r}")
        if perk_id is not None and perk_id in perks:
            screen.check(perk_id in MODELLED_PERKS,
                         f"{identifier}: {perk_id} has no numeric peak model; extend validator before assignment")
            for stat, required in perks[perk_id]["required_tradeoff"].items():
                actual = item["modifiers"].get(stat, 0)
                screen.check(actual <= required + EPSILON,
                             f"{identifier}: {perk_id} requires {stat} <= {required:g}, got {actual:g}")
        if item["kind"] == "weapon":
            screen.check(perk_id is None,
                         f"{identifier}: weapon perks need an explicit budget policy before assignment")
            neutral = aggregate([item], stats, "gear")
            ratio = neutral["damage"] * neutral["attack_speed"]
            screen.check(budget["weapon_neutral_primary_dps_ratio_min"] - EPSILON <= ratio <=
                         budget["weapon_neutral_primary_dps_ratio_max"] + EPSILON,
                         f"{identifier}: neutral primary DPS proxy {ratio:.6f} outside weapon bounds")
            continue
        nonzero = {stat: delta for stat, delta in item["modifiers"].items() if delta != 0}
        has_perk = perk_id is not None
        limit = budget["nonzero_stats_with_perk_max" if has_perk else "nonzero_stats_without_perk_max"]
        screen.check(len(nonzero) <= limit, f"{identifier}: {len(nonzero)} nonzero stats exceed {limit}")
        if has_perk:
            screen.check(sum(delta > 0 for delta in nonzero.values()) <= budget["positive_static_stats_with_perk_max"],
                         f"{identifier}: too many positive static stats accompanying a perk")
        positive = sum(delta / stats[stat]["budget_step"] * stats[stat]["budget_weight"]
                       for stat, delta in nonzero.items() if delta > 0)
        negative = sum(-delta / stats[stat]["budget_step"] * stats[stat]["budget_weight"]
                       for stat, delta in nonzero.items() if delta < 0)
        cost = positive + (budget["perk_points"] if has_perk else 0) - min(
            budget["drawback_credit_points_max"], budget["drawback_credit_fraction"] * negative)
        screen.check(cost <= budget["clothing_net_points_max"] + EPSILON,
                     f"{identifier}: net budget {cost:.6f} exceeds {budget['clothing_net_points_max']:g}")


def peak_modifiers(active_ids: tuple[str, ...], gear: dict, perks: dict,
                   action: str = "primary") -> dict[str, float]:
    modifiers: dict[str, float] = {}
    for identifier in active_ids:
        perk = perks[identifier]
        if identifier == "PERK-01":
            if action != "primary":
                continue
            stat, delta = "damage", perk["effect"]["delta"]
        elif identifier == "PERK-02":
            stat = "damage"
            delta = last_thread_delta(perk, perk["limits"]["max_bonus_at_health_fraction"])
        elif identifier == "PERK-03":
            stat, delta = "dash_speed", stride_delta(perk, gear["armour"], gear["max_health"])
        else:
            raise InvalidStructure(f"{identifier}: no explicit peak model")
        modifiers[stat] = modifiers.get(stat, 0.0) + delta
    return modifiers


def action_power_modifiers(powers: tuple[dict, ...], action: str) -> list[dict]:
    """Return eligible global/scoped deltas without an intermediate total clamp."""
    records = []
    for power in powers:
        records.append({"modifiers": power["modifiers"]})
        records.append({"modifiers": power["action_modifiers"].get(action, {})})
    return records


def inspect_state(values: dict, label: str, stage: str, data: dict, screen: Screen) -> None:
    baseline, gates = data["baseline"], data["loadout_gates"]
    dps = values["damage"] * values["attack_speed"]
    ehp = values["max_health"] * values["armour"]
    primary_range = baseline["primary_range_world_units"] * values["attack_range"]
    dash_distance = baseline["dash_distance_world_units"] * values["dash_distance"]
    dash_speed = baseline["dash_speed_world_units_per_s"] * values["dash_speed"]
    duration = dash_distance / dash_speed
    dps_limit = gates[stage + "_primary_dps_proxy_ratio_max"]
    ehp_limit = gates["gear_effective_health_ratio_max" if stage == "gear" else "total_effective_health_ratio_max"]
    screen.check(dps <= dps_limit + EPSILON, f"{label}: {stage} DPS proxy {dps:.6f} exceeds {dps_limit:g}")
    screen.check(ehp <= ehp_limit + EPSILON, f"{label}: {stage} EHP ratio {ehp:.6f} exceeds {ehp_limit:g}")
    screen.check(values["damage"] <= gates["primary_per_hit_damage_ratio_max"] + EPSILON,
                 f"{label}: primary per-hit damage ratio {values['damage']:.6f} exceeds cap")
    screen.check(primary_range + EPSILON >= gates["geometry_min_primary_range_world_units"],
                 f"{label}: primary range {primary_range:.6f} below compulsory geometry floor")
    screen.check(dash_distance + EPSILON >= gates["geometry_min_dash_distance_world_units"],
                 f"{label}: dash distance {dash_distance:.6f} below compulsory geometry floor")
    screen.check(duration + EPSILON >= baseline["dash_invulnerability_s"] and
                 duration < baseline["dash_cooldown_s"] - EPSILON,
                 f"{label}: dash duration {duration:.6f} must satisfy invulnerability <= duration < cooldown")
    for stat, value in values.items():
        bounds = data["stats"][stat]
        bound_stage = "gear" if stage == "gear" else "total"
        screen.check(bounds[bound_stage + "_min"] - EPSILON <= value <= bounds[bound_stage + "_max"] + EPSILON,
                     f"{label}: {stat} {value:.6f} outside {bound_stage} bounds")
    for name, value in (("dps_proxy", dps), ("ehp_ratio", ehp),
                        ("dash_duration_s", duration), ("primary_range", primary_range)):
        screen.observe(name, value)


def enumerate_states(data: dict, perks: dict, screen: Screen) -> tuple[int, int, int, int]:
    slots = [[item for item in data["clothing"] if item["slot"] == slot]
             for slot in ("jacket", "pants", "shoes")]
    if not all(slots) or not data["weapons"]:
        raise InvalidStructure("catalogue: every clothing slot and the weapon slot need at least one item")
    groups: dict[str, list[dict]] = {}
    for power in data["powerups"]:
        groups.setdefault(power["group"], []).append(power)
    power_sets = []
    for selection in itertools.product(*[[None] + items for items in groups.values()]):
        active = tuple(item for item in selection if item is not None)
        if len(active) <= data["loadout_gates"]["max_active_powerup_groups"]:
            power_sets.append(active)
    gear_count = conditional_count = temporary_count = 0
    for loadout in itertools.product(*slots, data["weapons"]):
        gear_count += 1
        label = "/".join(item["id"] for item in loadout)
        gear = aggregate(loadout, data["stats"], "gear")
        inspect_state(gear, label, "gear", data, screen)
        equipped = tuple(sorted({item["perk_id"] for item in loadout if item["perk_id"] is not None}))
        screen.check(len(equipped) <= data["loadout_gates"]["max_active_perks"],
                     f"{label}: equipped unique perks exceed max_active_perks")
        for size in range(len(equipped) + 1):
            for active in itertools.combinations(equipped, size):
                conditional_count += 1
                peak = {"modifiers": peak_modifiers(active, gear, perks)}
                conditional = aggregate([peak], data["stats"], "total", gear)
                active_label = label + "; perks=" + (",".join(active) or "none")
                inspect_state(conditional, active_label, "conditional", data, screen)
                for powers in power_sets:
                    temporary_count += 1
                    # Add both conditional and temporary deltas before the total clamp.
                    total = aggregate([peak, *action_power_modifiers(powers, "primary")],
                                      data["stats"], "total", gear)
                    power_label = active_label + "; powerups=" + (",".join(item["id"] for item in powers) or "none")
                    inspect_state(total, power_label, "temporary" if powers else "conditional", data, screen)
                    followup_peak = {"modifiers": peak_modifiers(active, gear, perks, "followup")}
                    followup = aggregate([followup_peak, *action_power_modifiers(powers, "followup")],
                                         data["stats"], "total", gear)
                    followup_range = min(data["baseline"]["followup_range_world_units"] * followup["attack_range"],
                                         data["modifier_contract"]["followup_range_absolute_max_world_units"])
                    screen.check(followup_range <= data["modifier_contract"]["followup_range_absolute_max_world_units"] + EPSILON,
                                 f"{power_label}: followup range exceeds absolute cap")
                    screen.observe("followup_range", followup_range)
                    screen.observe("followup_damage_ratio", followup["damage"])
                    screen.observe("followup_cooldown_s", data["baseline"]["followup_cooldown_s"] / followup["attack_speed"])
    return gear_count, conditional_count, temporary_count, len(power_sets)


def validate_fixtures(data: dict, perks: dict, screen: Screen) -> None:
    baseline = data["baseline"]
    for fixture in data["numeric_fixtures"]:
        identifier, values = fixture["id"], fixture["input"]
        if not isinstance(values, dict) or not isinstance(fixture["expected"], dict):
            raise InvalidStructure(f"{identifier}: input and expected must be objects")
        for key, value in values.items():
            if key in {"damage_deltas", "three_hit_damage_deltas"}:
                if not isinstance(value, list) or not value:
                    raise InvalidStructure(f"{identifier}.{key}: expected a nonempty numeric array")
                for index, delta in enumerate(value):
                    screen.number(delta, f"{identifier}.{key}[{index}]")
            else:
                screen.number(value, f"{identifier}.{key}")
                if key in {"armour_multiplier", "dash_speed_multiplier", "dash_distance_multiplier",
                           "gear_health_multiplier", "new_max_hp"}:
                    screen.number(value, f"{identifier}.{key}", positive=True)
        keys = set(values)
        if keys == {"raw_damage", "armour_multiplier"}:
            actual = {"damage_received": values["raw_damage"] / values["armour_multiplier"],
                      "damage_reduction_fraction": 1 - 1 / values["armour_multiplier"]}
        elif keys == {"dash_speed_multiplier", "dash_distance_multiplier"}:
            speed = baseline["dash_speed_world_units_per_s"] * values["dash_speed_multiplier"]
            distance = baseline["dash_distance_world_units"] * values["dash_distance_multiplier"]
            actual = {"dash_speed": speed, "dash_distance": distance, "dash_duration_s": distance / speed}
        elif keys == {"damage_deltas"}:
            stat = data["stats"]["damage"]
            actual = {"damage_multiplier": clamp(1 + sum(values["damage_deltas"]), stat["gear_min"], stat["gear_max"])}
        elif keys == {"old_hp", "new_max_hp"}:
            actual = {"new_hp": min(values["old_hp"], values["new_max_hp"])}
        elif keys == {"three_hit_damage_deltas"}:
            screen.check(len(values["three_hit_damage_deltas"]) == 3, f"{identifier}: combo fixture requires three actions")
            actual = {"cycle_average_damage_ratio": 1 + sum(values["three_hit_damage_deltas"]) / len(values["three_hit_damage_deltas"])}
        elif keys == {"gear_armour", "gear_health_multiplier"}:
            actual = {"armoured_stride_speed_delta": stride_delta(perks["PERK-03"], values["gear_armour"], values["gear_health_multiplier"])}
        elif keys == {"health_fraction"}:
            actual = {"last_thread_damage_delta": last_thread_delta(perks["PERK-02"], values["health_fraction"])}
        elif keys == {"orbit_primary_damage_delta", "baseline_primary_damage", "baseline_followup_damage"}:
            stat = data["stats"]["damage"]
            primary = clamp(1 + values["orbit_primary_damage_delta"], stat["total_min"], stat["total_max"])
            actual = {"orbit_primary_damage": values["baseline_primary_damage"] * primary,
                      "orbit_followup_damage": values["baseline_followup_damage"]}
        else:
            screen.errors.append(f"{identifier}: unsupported input keys {sorted(keys)}; add an explicit fixture model")
            continue
        screen.check(set(actual) == set(fixture["expected"]),
                     f"{identifier}: expected result keys must be {sorted(actual)}")
        for key in set(actual) & fixture["expected"].keys():
            expected = screen.number(fixture["expected"][key], f"{identifier}.expected.{key}")
            screen.check(math.isclose(actual[key], expected, rel_tol=EPSILON, abs_tol=EPSILON),
                         f"{identifier}.{key}: expected {expected:.12g}, calculated {actual[key]:.12g}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", nargs="?", type=Path,
                        default=Path(__file__).resolve().parents[2] / "data/design/player_equipment.json")
    args = parser.parse_args()
    screen = Screen()
    try:
        data = json.loads(args.path.read_text(encoding="utf-8"))
        perks = validate_structure(data, screen)
        if screen.errors:
            return screen.report_errors()
        validate_items(data, perks, screen)
        if screen.errors:
            return screen.report_errors()
        counts = enumerate_states(data, perks, screen)
        validate_fixtures(data, perks, screen)
        reload_cap = data["modifier_contract"]["reload_total_credit_cap_per_action_s"]
        extra = max((perk["effect"].get("amount", 0) for perk in perks.values()
                     if perk["effect"]["stat"] == "reload_credit_s"), default=0)
        screen.check(data["baseline"]["primary_hit_reload_credit_s"] + extra <= reload_cap + EPSILON,
                     "reload catalogue: baseline credit plus highest extra exceeds per-action cap")
        if screen.errors:
            return screen.report_errors()
    except (OSError, json.JSONDecodeError, InvalidStructure, KeyError, TypeError,
            ValueError, ZeroDivisionError) as error:
        screen.errors.append(f"{args.path}: {error}")
        return screen.report_errors()
    gear, conditional, temporary, power_sets = counts
    print(f"PASS: {len(data['clothing'])} clothing, {len(data['weapons'])} weapons, "
          f"{len(data['powerups'])} powerups, {len(data['perks'])} perk definitions; "
          f"{len(data['numeric_fixtures'])} numeric fixtures.")
    print(f"Screened {gear} gear loadouts, {conditional} conditional subsets, "
          f"{temporary} combined states across {power_sets} legal powerup combinations.")
    print("Ranges: " + "; ".join(f"{name}={low:.6f}..{high:.6f}"
                                  for name, (low, high) in screen.extrema.items()))
    print("Numeric peak models cover PERK-01/02/03; other unassigned perk definitions receive structural checks only.")
    print("Limitations: unassigned perk effects, event/cooldown/gesture timing, ammo uptime, "
          "area-hit opportunities and human balance are not simulated; "
          "DPS proxies and budgets are screening guardrails, not proof of balance.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
