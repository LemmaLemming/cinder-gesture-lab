#!/usr/bin/env python3
"""Reserve campaign ability introductions safely; this is design tooling, not gameplay.

All commands emit one JSON object. Run with --help for the CLI contract. Formula
strings are fingerprinted as text and are never evaluated.
"""

from __future__ import annotations

import argparse
import contextlib
import copy
from datetime import datetime, timezone
import fcntl
import hashlib
import json
import math
import os
from pathlib import Path
import re
import sys
import tempfile
import time


SCHEMA_VERSION = 1
ACTIVE_STATUSES = {"reserved", "planned", "implemented"}
ALL_STATUSES = ACTIVE_STATUSES | {"cancelled", "withdrawn"}
KINDS = {"introduction", "carryover"}
ID_RE = re.compile(r"^(PERK|POWER)-[0-9]{2,}$")
USE_RE = re.compile(r"^USE-[0-9]{6,}$")
NUMBER_RE = re.compile(r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?")
ORDINAL_RE = re.compile(r"(?<![a-z])(?:first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth)(?=_|\b)")
MECHANIC_KEYS = {
    "trigger", "effect", "limits", "eligible_origin", "count_scope",
    "can_trigger_other_effects", "expression", "modifiers", "duration_s",
    "charges", "shape_override", "same_id_repickup", "different_id_repickup",
    "expires_on", "timer_clock", "eligible_charge_action", "action_modifiers",
    "resource", "target", "reset",
}
IGNORED_NESTED_KEYS = {
    "id", "name", "display_name", "description", "notes", "art", "art_path",
    "color", "colour", "status", "acts", "ui", "ui_label", "source",
    "source_ref", "target_evaluation", "cooldown_start", "required_tradeoff",
}
SET_LIKE_KEYS = {"reset_on", "expires_on", "requires_all", "requires_any"}
POLICY = {
    "scope": "player_perks_and_temporary_powerups_design_placements",
    "repeat_policy": "meaningful_variants_only",
    "introduction_uniqueness": "one_active_introduction_per_concrete_ability_across_all_acts_and_optional_levels",
    "reservations_block_introductions": True,
    "names_art_and_numeric_retuning_create_novelty": False,
    "variant_requires_changed_structural_axis_and_new_player_decision": True,
    "signature_is_semantic_proof": False,
    "carryover": "equipped_perk_only_from_prior_planned_or_implemented_introduction",
    "automatic_reservation_expiry": False,
    "withdrawal": "planned_only_and_no_active_dependent_carryovers",
    "fixed_core_exempt": ["swipe_dash", "tap_primary_slash", "nearby_second_tap_blast", "aim_anchor"],
    "enemy_reinforcement_outside_scope": True,
}


class UsageError(Exception):
    def __init__(self, code: str, message: str, **details):
        super().__init__(message)
        self.code = code
        self.message = message
        self.details = details


def fail(code: str, message: str, **details):
    raise UsageError(code, message, **details)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def json_text(value) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"), allow_nan=False)


def reject_constant(value):
    fail("invalid_json", "Non-finite numbers are not supported.", value=value)


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            fail("invalid_json", "Duplicate JSON object keys are not supported.", key=key)
        result[key] = value
    return result


def read_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique_object, parse_constant=reject_constant)
    except UsageError:
        raise
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        fail("invalid_json", "Cannot read valid JSON; existing files were not changed.", path=str(path), reason=str(exc))


def normalize_mechanics(value, key: str | None = None):
    """Conservative structural fingerprint: cosmetic text and tuning are excluded.

    Number-bearing field names remain: a health-below condition differs from an
    enemy-count condition. Numbers and English ordinals *inside* text do not
    grant novelty. Known reset/condition sets are order-independent. Action
    sequences and unknown arrays preserve order so a changed sequence can be a
    meaningful mechanic.
    """
    if isinstance(value, bool) or value is None:
        return value
    if isinstance(value, (int, float)):
        if isinstance(value, float) and not math.isfinite(value):
            fail("invalid_definition", "A mechanic contains a non-finite number.")
        return "<number>"
    if isinstance(value, str):
        value = ORDINAL_RE.sub("ordinal", value.strip().lower())
        return re.sub(r"\s+", "", NUMBER_RE.sub("<number>", value))
    if isinstance(value, list):
        normalized = [normalize_mechanics(item) for item in value]
        return sorted(normalized, key=json_text) if key in SET_LIKE_KEYS else normalized
    if isinstance(value, dict):
        return {
            key: normalize_mechanics(item, key)
            for key, item in sorted(value.items()) if key not in IGNORED_NESTED_KEYS
        }
    fail("invalid_definition", "Unsupported value in a mechanic definition.")


def mechanic_signature(definition: dict) -> tuple[str, dict]:
    mechanics = {key: definition[key] for key in sorted(MECHANIC_KEYS) if key in definition}
    if not mechanics:
        fail("invalid_definition", "Ability must have an explicit mechanical definition.", ability_id=definition.get("id"))
    normalized = normalize_mechanics(mechanics)
    digest = hashlib.sha256(json_text(normalized).encode("utf-8")).hexdigest()
    return digest, normalized


def structural_axes(normalized: dict) -> dict:
    trigger = normalized.get("trigger", {})
    effect = normalized.get("effect", {})
    limits = normalized.get("limits", {})
    trigger = trigger if isinstance(trigger, dict) else {"definition": trigger}
    effect = effect if isinstance(effect, dict) else {"definition": effect}
    limits = limits if isinstance(limits, dict) else {"definition": limits}
    target_keys = lambda key: "target" in key or key == "scope"
    resource_keys = lambda key: any(word in key for word in ("shell", "ammo", "resource", "reload", "charge"))
    reset_keys = lambda key: any(word in key for word in ("reset", "consum", "refresh", "expires", "uses_per", "duration"))
    return {
        "trigger": {key: value for key, value in trigger.items() if not target_keys(key) and not resource_keys(key)},
        "effect": {
            "effect": {key: value for key, value in effect.items() if not target_keys(key)},
            **{key: normalized[key] for key in ("modifiers", "action_modifiers", "shape_override", "expression") if key in normalized},
        },
        "resource": {
            "trigger": {key: value for key, value in trigger.items() if resource_keys(key)},
            "limits": {key: value for key, value in limits.items() if resource_keys(key)},
            **{key: normalized[key] for key in ("resource", "charges", "eligible_charge_action") if key in normalized},
        },
        "target": {
            "trigger": {key: value for key, value in trigger.items() if target_keys(key)},
            "effect": {key: value for key, value in effect.items() if target_keys(key)},
            **{key: normalized[key] for key in ("target", "eligible_origin") if key in normalized},
        },
        "reset": {
            "limits": {key: value for key, value in limits.items() if reset_keys(key)},
            **{key: normalized[key] for key in ("reset", "expires_on", "same_id_repickup", "different_id_repickup", "duration_s") if key in normalized},
        },
    }


def load_context(root: Path) -> tuple[dict, dict]:
    catalogue = read_json(root / "data/design/player_equipment.json")
    if not isinstance(catalogue, dict):
        fail("invalid_catalogue", "Equipment catalogue must be a JSON object.")
    definitions = {}
    for group, prefix in (("perks", "PERK"), ("powerups", "POWER")):
        records = catalogue.get(group)
        if not isinstance(records, list):
            fail("invalid_catalogue", "Equipment catalogue needs perks and powerups lists.")
        for record in records:
            if not isinstance(record, dict) or not isinstance(record.get("id"), str) or not ID_RE.fullmatch(record["id"]):
                fail("invalid_catalogue", "Abilities need stable PERK-NN or POWER-NN IDs.")
            ability_id = record["id"]
            if not ability_id.startswith(prefix + "-") or ability_id in definitions:
                fail("invalid_catalogue", "Ability IDs must be unique and match their collection.", ability_id=ability_id)
            definitions[ability_id] = record
    levels = {}
    for act in range(1, 4):
        data = read_json(root / f"docs/reference-library/act{act}/research/levels.json")
        if not isinstance(data, dict) or data.get("act") != act:
            fail("invalid_levels", "Level research must identify its act.", act=act)
        for group, kind in (("levels", "main"), ("optional_levels", "optional")):
            if not isinstance(data.get(group), list):
                fail("invalid_levels", "Level research must contain main and optional lists.", act=act)
            for row in data[group]:
                if not isinstance(row, dict):
                    fail("invalid_levels", "Each level needs an ID.", act=act)
                level_id = row.get("id")
                if not isinstance(level_id, str) or not re.fullmatch(fr"A{act}-{'L' if kind == 'main' else 'O'}[1-9][0-9]*", level_id) or level_id in levels:
                    fail("invalid_levels", "Level IDs must be unique and match act and main/optional kind.", level_id=level_id)
                levels[level_id] = {"id": level_id, "act": act, "kind": kind, "name": row.get("name", level_id), "parent_level_id": row.get("parent_level_id")}
    for level in levels.values():
        if level["kind"] == "optional" and level["parent_level_id"] not in levels:
            fail("invalid_levels", "Optional levels must identify a known parent level.", level_id=level["id"])
    return definitions, levels


def require_text(value, field: str, minimum: int = 1):
    if not isinstance(value, str) or len(value.strip()) < minimum or len(value) > 4000:
        fail("invalid_argument", f"{field} must contain {minimum}–4000 characters.", field=field)
    return value.strip()


def validate_source(root: Path, source: str) -> str:
    source = require_text(source, "source")
    path_text = source.split("#", 1)[0]
    path = Path(path_text)
    if path.is_absolute() or not path_text or ".." in path.parts or "\\" in path_text:
        fail("invalid_source", "Source must be an existing repository-relative .md or .json document; traversal is forbidden.", source=source)
    resolved = (root / path).resolve()
    if not resolved.is_relative_to(root.resolve()) or not resolved.is_file() or resolved.suffix.lower() not in {".md", ".json"}:
        fail("invalid_source", "Source document does not exist inside this repository or uses an unsupported format.", source=source)
    return source


def identity(definition: dict, *, revision: int = 0, parent: dict | None = None, owner: str = "bootstrap", player_decision: str = "", difference: str = "") -> dict:
    digest, normalized = mechanic_signature(definition)
    ability_id = definition["id"]
    axes = structural_axes(normalized)
    changed = []
    if parent:
        parent_axes = structural_axes(parent["signature_mechanics"])
        changed = [axis for axis in axes if axes[axis] != parent_axes[axis]]
    return {
        "id": ability_id,
        "family_id": parent["family_id"] if parent else f"FAMILY-{ability_id}",
        "kind": "equipped_perk" if ability_id.startswith("PERK-") else "temporary_powerup",
        "name": definition.get("name", ability_id),
        "source": f"data/design/player_equipment.json#{ability_id}",
        "signature_version": 1,
        "signature": digest,
        "signature_mechanics": normalized,
        "variant_of": parent["id"] if parent else None,
        "changed_axes": changed,
        "player_decision": player_decision,
        "difference": difference,
        "registered_by": owner,
        "registered_revision": revision,
    }


def initial_ledger(definitions: dict, levels: dict) -> dict:
    expected = [f"PERK-{number:02d}" for number in range(1, 15)] + [f"POWER-{number:02d}" for number in range(1, 7)]
    missing = [ability_id for ability_id in expected if ability_id not in definitions]
    if missing:
        fail("missing_seed_abilities", "Initial catalogue needs the canonical 14 perks and six powerups.", missing=missing)
    return {
        "schema_version": SCHEMA_VERSION,
        "policy": copy.deepcopy(POLICY),
        "revision": 0,
        "abilities": [identity(definitions[ability_id]) for ability_id in expected],
        "uses": [],
        "history": [],
        "suggestions": [
            {"id": "SUGGEST-01", "ability_id": "POWER-02", "level_id": "A1-O1", "status": "unassigned_suggestion", "source": "docs/ACT1_CONCEPT.md", "note": "Optional authoring suggestion only; not reserved, planned or implemented."},
            {"id": "SUGGEST-02", "ability_id": "POWER-06", "level_id": "A1-O2", "status": "unassigned_suggestion", "source": "docs/ACT1_CONCEPT.md", "note": "Optional authoring suggestion only; not reserved, planned or implemented."},
        ],
    }


def level_after(prior: dict, later: dict) -> bool:
    """Accept only chronology established by acts/main sequence or unlock parents.

    Optional levels may be played late, so a branch cannot guarantee availability
    in a subsequent required main level. Across acts it is an explicitly
    conditional carryover, never a required availability promise.
    """
    if prior["act"] != later["act"]:
        return prior["act"] < later["act"]
    if prior["id"] == later["id"]:
        return False
    if prior["kind"] == "main":
        prior_number = int(prior["id"].split("L", 1)[1])
        if later["kind"] == "main":
            return prior_number < int(later["id"].split("L", 1)[1])
        return prior_number <= int(later["parent_level_id"].split("L", 1)[1])
    return False


def validate_ledger(ledger: dict, definitions: dict, levels: dict, root: Path):
    if not isinstance(ledger, dict) or ledger.get("schema_version") != SCHEMA_VERSION:
        fail("invalid_ledger", "Unsupported or missing ledger schema_version.")
    if ledger.get("policy") != POLICY:
        fail("policy_drift", "Ledger policy disagrees with the enforced CLI contract.")
    revision = ledger.get("revision")
    if not isinstance(revision, int) or isinstance(revision, bool) or revision < 0:
        fail("invalid_ledger", "Ledger revision must be a nonnegative integer.")
    for key in ("abilities", "uses", "history", "suggestions"):
        if not isinstance(ledger.get(key), list):
            fail("invalid_ledger", f"Ledger {key} must be a list.")
    abilities = {}
    signatures = {}
    for row in ledger["abilities"]:
        if not isinstance(row, dict):
            fail("invalid_ledger", "Ability identities must be objects.")
        ability_id = row.get("id")
        if not isinstance(ability_id, str) or not ID_RE.fullmatch(ability_id) or ability_id in abilities:
            fail("invalid_ledger", "Registered ability IDs must be valid and unique.", ability_id=ability_id)
        if ability_id not in definitions:
            fail("definition_missing", "A registered ability was removed from the equipment catalogue.", ability_id=ability_id)
        digest, normalized = mechanic_signature(definitions[ability_id])
        if row.get("signature_version") != 1 or row.get("signature") != digest or row.get("signature_mechanics") != normalized:
            fail("signature_drift", "Registered mechanic changed structurally. Restore its definition or add and register a meaningful variant under a new ID.", ability_id=ability_id)
        if digest in signatures:
            fail("duplicate_mechanic", "Registered abilities have the same mechanics despite different IDs.", ability_id=ability_id, duplicate_of=signatures[digest])
        signatures[digest] = ability_id
        expected_kind = "equipped_perk" if ability_id.startswith("PERK-") else "temporary_powerup"
        if row.get("kind") != expected_kind or not isinstance(row.get("family_id"), str) or not row["family_id"]:
            fail("invalid_ledger", "Ability family and kind must be valid.", ability_id=ability_id)
        if row.get("source") != f"data/design/player_equipment.json#{ability_id}":
            fail("invalid_ledger", "Ability source must point at its equipment definition.", ability_id=ability_id)
        registered_revision = row.get("registered_revision")
        if not isinstance(registered_revision, int) or isinstance(registered_revision, bool) or not 0 <= registered_revision <= revision:
            fail("invalid_ledger", "Ability registered_revision is invalid.", ability_id=ability_id)
        require_text(row.get("registered_by"), "registered_by")
        abilities[ability_id] = row
    expected = {f"PERK-{number:02d}" for number in range(1, 15)} | {f"POWER-{number:02d}" for number in range(1, 7)}
    if not expected.issubset(abilities):
        fail("invalid_ledger", "Canonical seeded identities cannot be removed.", missing=sorted(expected - set(abilities)))
    for row in abilities.values():
        parent_id = row.get("variant_of")
        if parent_id is None:
            if row["family_id"] != f"FAMILY-{row['id']}" or row.get("changed_axes") != []:
                fail("invalid_ledger", "Root ability family must match its stable ID.", ability_id=row["id"])
        else:
            parent = abilities.get(parent_id)
            if not parent or parent["id"] == row["id"] or parent["registered_revision"] >= row["registered_revision"]:
                fail("invalid_variant", "Variant parent must be registered before its child.", ability_id=row["id"])
            if row["kind"] != parent["kind"] or row["family_id"] != parent["family_id"]:
                fail("invalid_variant", "Variant must preserve parent's kind and family.", ability_id=row["id"])
            current_axes = structural_axes(row["signature_mechanics"])
            parent_axes = structural_axes(parent["signature_mechanics"])
            changed = [axis for axis in current_axes if current_axes[axis] != parent_axes[axis]]
            if not changed or changed != row.get("changed_axes"):
                fail("invalid_variant", "Variant must change a trigger, effect, resource, target or reset axis.", ability_id=row["id"])
        if row["registered_revision"] > 0:
            require_text(row.get("player_decision"), "player_decision", 10)
            require_text(row.get("difference"), "difference", 10)
    uses = {}
    active_introductions = {}
    active_per_level = set()
    for row in ledger["uses"]:
        if not isinstance(row, dict) or not isinstance(row.get("id"), str) or not USE_RE.fullmatch(row["id"]) or row["id"] in uses:
            fail("invalid_ledger", "Use IDs must be valid and unique.")
        ability = abilities.get(row.get("ability_id"))
        level = levels.get(row.get("level_id"))
        if not ability or not level or row.get("family_id") != ability["family_id"] or row.get("act") != level["act"]:
            fail("invalid_ledger", "Use must identify a registered ability and known level.", use_id=row["id"])
        if row.get("kind") not in KINDS or row.get("status") not in ALL_STATUSES:
            fail("invalid_ledger", "Use kind or lifecycle status is invalid.", use_id=row["id"])
        require_text(row.get("owner"), "owner")
        require_text(row.get("purpose"), "purpose")
        validate_source(root, row.get("source"))
        for field in ("created_at", "updated_at"):
            try:
                if datetime.fromisoformat(row[field]).tzinfo is None:
                    raise ValueError("timezone missing")
            except (KeyError, TypeError, ValueError):
                fail("invalid_ledger", "Use timestamps must include timezone.", use_id=row["id"])
        if row["kind"] == "introduction" and row.get("from_use") is not None:
            fail("invalid_ledger", "An introduction cannot have from_use.", use_id=row["id"])
        if row["status"] in ACTIVE_STATUSES:
            key = (row["ability_id"], row["level_id"])
            if key in active_per_level:
                fail("duplicate_placement", "An ability has multiple active placements in the same level.", use_id=row["id"])
            active_per_level.add(key)
            if row["kind"] == "introduction":
                if row["ability_id"] in active_introductions:
                    fail("ability_already_used", "An ability has multiple active campaign introductions.", use_id=row["id"])
                active_introductions[row["ability_id"]] = row["id"]
        uses[row["id"]] = row
    for row in uses.values():
        if row["kind"] == "carryover":
            origin = uses.get(row.get("from_use"))
            if not origin or origin["kind"] != "introduction" or origin["ability_id"] != row["ability_id"] or abilities[row["ability_id"]]["kind"] != "equipped_perk":
                fail("invalid_carryover", "Carryover must reference the same concrete equipped perk's original introduction.", use_id=row["id"])
            if not level_after(levels[origin["level_id"]], levels[row["level_id"]]):
                fail("invalid_carryover", "Carryover must be later than its introduction in known campaign order.", use_id=row["id"])
            if row["status"] in ACTIVE_STATUSES and origin["status"] not in {"planned", "implemented"}:
                fail("invalid_carryover", "Active carryover needs a planned or implemented introduction.", use_id=row["id"])
        if row["status"] in {"cancelled", "withdrawn"}:
            require_text(row.get("reason"), "reason")
    # Replaying snapshots detects accidental hand-editing of current ownership,
    # lifecycle, placements or registrations. This is an audit, not a security
    # boundary against an actor able to rewrite the entire repository.
    replayed_uses = {}
    replayed_registered = {}
    if len(ledger["history"]) != revision:
        fail("history_mismatch", "Revision and append-only history length disagree.")
    for expected_revision, event in enumerate(ledger["history"], 1):
        if not isinstance(event, dict) or event.get("revision") != expected_revision or not isinstance(event.get("after"), dict):
            fail("history_mismatch", "History must contain consecutive revisions and complete state snapshots.")
        require_text(event.get("owner"), "history owner")
        action = event.get("action")
        entity_id = event.get("entity_id")
        if action == "register":
            if entity_id in replayed_registered or entity_id in expected or event.get("before") is not None:
                fail("history_mismatch", "An ability registration was rewritten.")
            replayed_registered[entity_id] = event["after"]
        elif action in {"reserve", "record", "cancel", "withdraw"}:
            before = replayed_uses.get(entity_id)
            if event.get("before") != before or event["after"].get("id") != entity_id or event["after"].get("owner") != event["owner"]:
                fail("history_mismatch", "Use history does not match prior state or its owner.", use_id=entity_id)
            if action == "reserve" and before is not None:
                fail("history_mismatch", "A use was reserved twice.", use_id=entity_id)
            if action != "reserve" and before is None:
                fail("history_mismatch", "A use changed before it was reserved.", use_id=entity_id)
            replayed_uses[entity_id] = event["after"]
        else:
            fail("history_mismatch", "Unknown history action.", action=action)
    if replayed_uses != uses or replayed_registered != {key: row for key, row in abilities.items() if row["registered_revision"] > 0}:
        fail("history_mismatch", "Current ledger differs from its recorded event history.")
    for row in ledger["suggestions"]:
        if not isinstance(row, dict) or row.get("status") != "unassigned_suggestion" or row.get("ability_id") not in abilities or row.get("level_id") not in levels:
            fail("invalid_ledger", "Suggestions must remain nonblocking references to known abilities and levels.")
    return abilities, uses


@contextlib.contextmanager
def ledger_lock(path: Path, timeout_s: float = 10):
    path.parent.mkdir(parents=True, exist_ok=True)
    lock_path = path.with_name(path.name + ".lock")
    if lock_path.is_symlink():
        fail("unsafe_ledger", "The stable ledger lock must not be a symlink.", path=str(lock_path))
    descriptor = os.open(lock_path, os.O_CREAT | os.O_RDWR | getattr(os, "O_NOFOLLOW", 0), 0o600)
    start = time.monotonic()
    try:
        while True:
            try:
                fcntl.flock(descriptor, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if time.monotonic() - start >= timeout_s:
                    fail("ledger_busy", "Ledger is locked by another author; retry after reading current status.", lock=str(lock_path))
                time.sleep(0.05)
        yield
    finally:
        fcntl.flock(descriptor, fcntl.LOCK_UN)
        os.close(descriptor)


def atomic_write(path: Path, value: dict):
    if path.is_symlink():
        fail("unsafe_ledger", "Ledger file must not be a symlink.", path=str(path))
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=path.parent, prefix=f".{path.name}.", suffix=".tmp", delete=False) as file:
            temporary = Path(file.name)
            json.dump(value, file, indent=2, ensure_ascii=False, allow_nan=False)
            file.write("\n")
            file.flush()
            os.fsync(file.fileno())
        os.replace(temporary, path)
        temporary = None
        descriptor = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(descriptor)
        finally:
            os.close(descriptor)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def audit(ledger: dict, action: str, owner: str, before: dict | None, after: dict):
    ledger["revision"] += 1
    ledger["history"].append({
        "revision": ledger["revision"], "at": utc_now(), "action": action,
        "owner": owner, "entity_id": after["id"],
        "before": copy.deepcopy(before), "after": copy.deepcopy(after),
    })


def eligibility(ledger: dict, abilities: dict, uses: dict, levels: dict, ability_id: str, level_id: str, kind: str, from_use: str | None):
    ability = abilities.get(ability_id)
    level = levels.get(level_id)
    if not ability:
        fail("unknown_ability", "Add a full equipment definition and register its identity before placement.", ability_id=ability_id)
    if not level:
        fail("unknown_level", "Level is not in the three acts' research catalogues.", level_id=level_id)
    existing = [row for row in ledger["uses"] if row["status"] in ACTIVE_STATUSES and row["ability_id"] == ability_id]
    if kind == "introduction":
        if from_use:
            fail("invalid_carryover", "from-use is only valid with kind carryover.")
        blocking = [row for row in existing if row["kind"] == "introduction"]
        if blocking:
            fail("ability_already_used", "This exact ability is already reserved, planned or implemented in the campaign. Register a meaningful variant or choose another ability.", ability_id=ability_id, blocking_uses=blocking)
    else:
        if ability["kind"] != "equipped_perk":
            fail("powerup_carryover_forbidden", "Temporary powerups expire at encounter end and cannot be declared carried equipment.", ability_id=ability_id)
        origin = uses.get(from_use)
        if not origin or origin["ability_id"] != ability_id or origin["kind"] != "introduction" or origin["status"] not in {"planned", "implemented"}:
            fail("invalid_carryover", "Carryover needs from-use pointing at this equipped perk's planned or implemented original introduction.", from_use=from_use)
        if not level_after(levels[origin["level_id"]], level):
            fail("invalid_carryover", "Carryover destination must follow the introduction in known campaign order; optional branches cannot guarantee main-level availability.", from_level=origin["level_id"], level_id=level_id)
    same_level = [row for row in existing if row["level_id"] == level_id]
    if same_level:
        fail("duplicate_placement", "This ability already has an active placement in this level.", blocking_uses=same_level)
    return ability, level


def availability(ledger: dict, abilities: dict):
    result = []
    for ability in abilities.values():
        blocking = [row for row in ledger["uses"] if row["ability_id"] == ability["id"] and row["kind"] == "introduction" and row["status"] in ACTIVE_STATUSES]
        result.append({
            "id": ability["id"], "name": ability["name"], "kind": ability["kind"],
            "family_id": ability["family_id"], "variant_of": ability["variant_of"],
            "available": not blocking, "blocking_uses": blocking,
        })
    return result


class JsonParser(argparse.ArgumentParser):
    def error(self, message):
        fail("invalid_argument", message)


def parser() -> argparse.ArgumentParser:
    result = JsonParser(description=__doc__)
    result.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2], help="Repository root (isolates fixtures too).")
    result.add_argument("--ledger", type=Path, help="Ledger file; defaults to ROOT/data/design/ability_usage.json.")
    commands = result.add_subparsers(dest="command", required=True, parser_class=JsonParser)
    for command in ("status", "available"):
        sub = commands.add_parser(command)
        sub.add_argument("--level", help="Optional level context; available still lists campaign introduction availability.")
    for command in ("check", "reserve"):
        sub = commands.add_parser(command)
        sub.add_argument("--ability", required=True)
        sub.add_argument("--level", required=True)
        sub.add_argument("--kind", choices=sorted(KINDS), default="introduction")
        sub.add_argument("--from-use", help="Required original introduction ID for equipped-perk carryover.")
        if command == "reserve":
            sub.add_argument("--owner", required=True)
            sub.add_argument("--purpose", required=True)
            sub.add_argument("--source", required=True)
    sub = commands.add_parser("record")
    sub.add_argument("--use", required=True)
    sub.add_argument("--owner", required=True)
    sub.add_argument("--status", choices=["planned", "implemented"], required=True)
    sub.add_argument("--source", help="Updated existing document reference for accepted design or implementation.")
    for command in ("cancel", "withdraw"):
        sub = commands.add_parser(command)
        sub.add_argument("--use", required=True)
        sub.add_argument("--owner", required=True)
        sub.add_argument("--reason", required=True)
    sub = commands.add_parser("register")
    sub.add_argument("--ability", required=True, help="ID already added to player_equipment.json.")
    sub.add_argument("--owner", required=True)
    sub.add_argument("--variant-of", help="Registered parent; changed axis + new decision required.")
    sub.add_argument("--player-decision", required=True)
    sub.add_argument("--difference", required=True)
    commands.add_parser("validate")
    commands.add_parser("init", help="Create the initial ledger; never overwrite an existing file.")
    return result


def execute(args) -> dict:
    root = args.root.resolve()
    ledger_path = args.ledger if args.ledger is not None else root / "data/design/ability_usage.json"
    if not ledger_path.is_absolute():
        ledger_path = root / ledger_path
    # Do not resolve away a symlink before the safety check.
    if ledger_path.is_symlink():
        fail("unsafe_ledger", "Ledger file must not be a symlink.", path=str(ledger_path))
    ledger_path = ledger_path.absolute()
    with ledger_lock(ledger_path):
        definitions, levels = load_context(root)
        if args.command == "init":
            if ledger_path.exists():
                fail("ledger_exists", "init refuses to overwrite any existing ledger.", path=str(ledger_path))
            ledger = initial_ledger(definitions, levels)
            validate_ledger(ledger, definitions, levels, root)
            atomic_write(ledger_path, ledger)
            return {"ok": True, "command": "init", "revision": 0, "registered_count": len(ledger["abilities"]), "active_use_count": 0}
        if not ledger_path.is_file():
            fail("ledger_missing", "Ledger is missing; use init to create it without inventing used placements.", path=str(ledger_path))
        ledger = read_json(ledger_path)
        abilities, uses = validate_ledger(ledger, definitions, levels, root)
        response = {"ok": True, "command": args.command, "revision": ledger["revision"]}
        if args.command in {"status", "available"}:
            if args.level and args.level not in levels:
                fail("unknown_level", "Level is not in the research catalogues.", level_id=args.level)
            rows = availability(ledger, abilities)
            response.update({"abilities": rows, "level": levels.get(args.level), "unregistered_ids": sorted(set(definitions) - set(abilities))})
            if args.command == "status":
                selected = [row for row in ledger["uses"] if args.level is None or row["level_id"] == args.level]
                response.update({"uses": selected, "suggestions": [row for row in ledger["suggestions"] if args.level is None or row["level_id"] == args.level], "counts": {"registered": len(abilities), "available_introductions": sum(row["available"] for row in rows), **{status: sum(row["status"] == status for row in selected) for status in sorted(ALL_STATUSES)}}})
            return response
        if args.command == "validate":
            response.update({"registered_count": len(abilities), "use_count": len(uses), "active_use_count": sum(row["status"] in ACTIVE_STATUSES for row in uses.values()), "unregistered_ids": sorted(set(definitions) - set(abilities)), "semantic_review_required": True})
            return response
        if args.command in {"check", "reserve"}:
            ability, level = eligibility(ledger, abilities, uses, levels, args.ability, args.level, args.kind, args.from_use)
            if args.command == "check":
                response.update({"eligible": True, "ability_id": ability["id"], "level_id": level["id"], "kind": args.kind, "advisory_only": True, "semantic_review_required": True})
                return response
            owner = require_text(args.owner, "owner")
            purpose = require_text(args.purpose, "purpose")
            source = validate_source(root, args.source)
            number = max([int(row["id"].split("-", 1)[1]) for row in ledger["uses"]], default=0) + 1
            now = utc_now()
            row = {"id": f"USE-{number:06d}", "ability_id": ability["id"], "family_id": ability["family_id"], "level_id": level["id"], "act": level["act"], "kind": args.kind, "status": "reserved", "owner": owner, "purpose": purpose, "source": source, "from_use": args.from_use, "created_at": now, "updated_at": now}
            ledger["uses"].append(row)
            audit(ledger, "reserve", owner, None, row)
            response["use"] = row
        elif args.command in {"record", "cancel", "withdraw"}:
            row = uses.get(args.use)
            if not row:
                fail("unknown_use", "Use ID does not exist.", use_id=args.use)
            owner = require_text(args.owner, "owner")
            if row["owner"] != owner:
                fail("ownership_mismatch", "Only the reserving owner may change this use.", use_id=row["id"], owner=row["owner"])
            before = copy.deepcopy(row)
            if args.command == "record":
                source = validate_source(root, args.source) if args.source else row["source"]
                allowed = {"reserved": {"planned"}, "planned": {"planned", "implemented"}, "implemented": {"implemented"}}
                if args.status not in allowed.get(row["status"], set()):
                    fail("invalid_transition", "record requires reserved→planned→implemented; terminal uses cannot be revived.", status=row["status"], requested=args.status)
                if row["status"] == args.status and row["source"] == source:
                    response.update({"use": row, "unchanged": True})
                    return response
                row["status"] = args.status
                row["source"] = source
            else:
                required_status = "reserved" if args.command == "cancel" else "planned"
                if row["status"] != required_status:
                    fail("invalid_transition", f"{args.command} only applies to {required_status} uses; implemented history cannot be freed.", status=row["status"])
                dependent = [use for use in uses.values() if use["from_use"] == row["id"] and use["status"] in ACTIVE_STATUSES]
                if dependent:
                    fail("dependent_carryovers", "Cancel or withdraw unfinished dependent carryovers before withdrawing their introduction.", dependent_uses=dependent)
                row["status"] = "cancelled" if args.command == "cancel" else "withdrawn"
                row["reason"] = require_text(args.reason, "reason")
            row["updated_at"] = utc_now()
            audit(ledger, args.command, owner, before, row)
            response["use"] = row
        elif args.command == "register":
            if args.ability in abilities:
                fail("already_registered", "Registered identities are stable; do not overwrite them.", ability_id=args.ability)
            definition = definitions.get(args.ability)
            if not definition:
                fail("definition_missing", "Add the full bounded ability definition to player_equipment.json before registration.", ability_id=args.ability)
            owner = require_text(args.owner, "owner")
            decision = require_text(args.player_decision, "player_decision", 10)
            difference = require_text(args.difference, "difference", 10)
            parent = abilities.get(args.variant_of) if args.variant_of else None
            if args.variant_of and not parent:
                fail("unknown_parent", "Variant parent must already be registered.", variant_of=args.variant_of)
            row = identity(definition, revision=ledger["revision"] + 1, parent=parent, owner=owner, player_decision=decision, difference=difference)
            duplicate = [ability["id"] for ability in abilities.values() if ability["signature"] == row["signature"]]
            if duplicate:
                fail("duplicate_mechanic", "Renaming, artwork and numerical retuning do not create a new ability. Choose a changed player decision and structural mechanic.", duplicate_of=duplicate)
            if parent and (row["kind"] != parent["kind"] or not row["changed_axes"]):
                fail("invalid_variant", "A variant must preserve kind and change trigger, effect, resource, target or reset mechanics.", variant_of=parent["id"])
            ledger["abilities"].append(row)
            audit(ledger, "register", owner, None, row)
            response.update({"ability": row, "semantic_review_required": True})
        validate_ledger(ledger, definitions, levels, root)
        atomic_write(ledger_path, ledger)
        response["revision"] = ledger["revision"]
        return response


def main(argv=None) -> int:
    try:
        args = parser().parse_args(argv)
        response = execute(args)
    except UsageError as exc:
        print(json.dumps({"ok": False, "code": exc.code, "message": exc.message, "details": exc.details}, ensure_ascii=False, allow_nan=False))
        return 2
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(json.dumps({"ok": False, "code": "invalid_state", "message": "Operation failed closed; ledger was not intentionally changed.", "details": {"reason": str(exc)}}, ensure_ascii=False))
        return 2
    print(json.dumps(response, ensure_ascii=False, allow_nan=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
