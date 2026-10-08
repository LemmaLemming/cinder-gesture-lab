#!/usr/bin/env python3
"""Inspect the live equipment grid and atomically claim shared catalogue work.

Consult the live grid when deciding/changing a level's playstyle or equipment
opportunities; this is not a mandatory check at every agent startup. Creation
claims are not campaign placements, gameplay implementation or balance approval.
Use the authoritative --root for all agents, including Git worktrees. Formula
text is fingerprinted as documentation and never executed.
"""

from __future__ import annotations

import copy
from datetime import datetime
import hashlib
import json
import math
from pathlib import Path
import re
import sys

import ability_usage as usage


POLICY = {
    "scope": "shared_player_equipment_catalogue_creation_and_implementation_ownership",
    "campaign_placements": "separate_ability_usage_ledger",
    "names_art_and_numeric_retuning_create_novelty": False,
    "static_identity": "kind_slot_modifier_directions_and_referenced_perk_mechanics",
    "ability_identity": "ability_usage_structural_signature",
    "signature_is_semantic_proof": False,
    "automatic_claim_expiry": False,
    "completion": "canonical_definition_integrated_not_gameplay_or_balance_approval",
}
CLAIM_RE = re.compile(r"^EQCL-[0-9]{6,}$")
ITEM_RE = re.compile(r"^(CLOTH-[JPS][0-9]+|WEAPON-[0-9]{2,}|PERK-[0-9]{2,}|POWER-[0-9]{2,})$")
STATES = {"reserved", "completed", "cancelled"}
BLOCKING_STATES = {"reserved", "completed"}


def item_kind(definition: dict) -> str:
    if not isinstance(definition, dict) or not isinstance(definition.get("id"), str) or not ITEM_RE.fullmatch(definition["id"]):
        usage.fail("invalid_definition", "Equipment needs a stable CLOTH, WEAPON, PERK or POWER ID.")
    return {"CLOTH": "clothing", "WEAPON": "weapon", "PERK": "perk", "POWER": "powerup"}[definition["id"].split("-", 1)[0]]


def fingerprint(definition: dict, definitions: dict, stats: dict) -> tuple[str, dict]:
    kind = item_kind(definition)
    usage.require_text(definition.get("name"), "name")
    usage.require_text(definition.get("status"), "status")
    if kind in {"perk", "powerup"}:
        _, mechanics = usage.mechanic_signature(definition)
        normalized = {"kind": kind, "mechanics": mechanics}
    else:
        expected_slot = {"J": "jacket", "P": "pants", "S": "shoes"}[definition["id"].split("-", 1)[1][0]] if kind == "clothing" else "weapon"
        if definition.get("kind") != kind or definition.get("slot") != expected_slot:
            usage.fail("invalid_definition", "Equipment kind, ID and slot must agree.", item_id=definition["id"])
        modifiers = definition.get("modifiers")
        if not isinstance(modifiers, dict):
            usage.fail("invalid_definition", "Static equipment requires an explicit modifiers object.")
        directions = {}
        for stat, amount in modifiers.items():
            if stat not in stats or isinstance(amount, bool) or not isinstance(amount, (int, float)) or not math.isfinite(amount):
                usage.fail("invalid_definition", "Static modifiers require known stats and finite numbers.", stat=stat)
            if amount != 0:
                directions[stat] = "positive" if amount > 0 else "negative"
        perk_id = definition.get("perk_id")
        perk_mechanics = None
        if perk_id is not None:
            perk = definitions.get(perk_id)
            if not perk or item_kind(perk) != "perk":
                usage.fail("unknown_perk", "Equipment must reference an existing canonical perk; claim and integrate a new perk first.", perk_id=perk_id)
            _, perk_mechanics = usage.mechanic_signature(perk)
        normalized = {"kind": kind, "slot": expected_slot, "modifier_directions": directions, "perk_mechanics": perk_mechanics}
    digest = hashlib.sha256(usage.json_text(normalized).encode("utf-8")).hexdigest()
    return digest, normalized


def load_catalogue(root: Path) -> tuple[dict, dict]:
    catalogue = usage.read_json(root / "data/design/player_equipment.json")
    if not isinstance(catalogue, dict) or not isinstance(catalogue.get("stats"), dict):
        usage.fail("invalid_catalogue", "Equipment catalogue requires explicit stat definitions.")
    definitions = {}
    for group, kind in (("clothing", "clothing"), ("weapons", "weapon"), ("perks", "perk"), ("powerups", "powerup")):
        if not isinstance(catalogue.get(group), list):
            usage.fail("invalid_catalogue", "Equipment catalogue requires all four item collections.", group=group)
        for record in catalogue[group]:
            if item_kind(record) != kind or record["id"] in definitions:
                usage.fail("invalid_catalogue", "Equipment IDs must be unique and match their collection.")
            definitions[record["id"]] = record
    return definitions, catalogue["stats"]


def validate_claims(ledger: dict, definitions: dict, stats: dict, root: Path) -> None:
    if not isinstance(ledger, dict) or ledger.get("schema_version") != 1 or ledger.get("policy") != POLICY:
        usage.fail("invalid_claims", "Equipment claim schema or policy does not match the CLI.")
    revision = ledger.get("revision")
    if isinstance(revision, bool) or not isinstance(revision, int) or revision < 0 or not isinstance(ledger.get("claims"), list) or not isinstance(ledger.get("history"), list):
        usage.fail("invalid_claims", "Claim ledger requires revision, claims and history.")
    if len(ledger["history"]) != revision:
        usage.fail("invalid_claims", "Every claim mutation requires retained history.")
    ids, blockers, type_blockers = {}, {}, {}
    for claim in ledger["claims"]:
        if not isinstance(claim, dict) or not isinstance(claim.get("id"), str) or not CLAIM_RE.fullmatch(claim["id"]) or claim["id"] in ids:
            usage.fail("invalid_claims", "Claim IDs must be valid and unique.")
        if claim.get("status") not in STATES or claim.get("operation") not in {"new_definition", "implement_existing"}:
            usage.fail("invalid_claims", "Unknown claim state or operation.", claim_id=claim["id"])
        for field in ("owner", "purpose"):
            usage.require_text(claim.get(field), field)
        if claim["status"] == "cancelled":
            usage.require_text(claim.get("reason"), "reason", 10)
        usage.validate_source(root, claim.get("source"))
        try:
            for field in ("created_at", "updated_at"):
                if datetime.fromisoformat(claim[field]).tzinfo is None:
                    raise ValueError("timestamp lacks timezone")
        except (ValueError, TypeError, KeyError):
            usage.fail("invalid_claims", "Claim timestamps must include a timezone.")
        digest, normalized = fingerprint(claim.get("definition"), definitions, stats)
        if claim.get("item_id") != claim["definition"]["id"] or claim.get("signature") != digest or claim.get("signature_type") != normalized:
            usage.fail("signature_drift", "Creation claim identity does not match its retained definition.", claim_id=claim["id"])
        canonical = definitions.get(claim["item_id"])
        if claim["status"] != "cancelled" and canonical is not None and fingerprint(canonical, definitions, stats)[0] != digest:
            usage.fail("signature_drift", "Claimed canonical item changed type; use a new ID for a variant.", item_id=claim["item_id"])
        if claim["status"] == "completed" and canonical is None:
            usage.fail("definition_missing", "Completed claims retain their canonical item definition.", item_id=claim["item_id"])
        if claim["status"] in BLOCKING_STATES:
            if claim["item_id"] in blockers or digest in type_blockers:
                usage.fail("duplicate_claim", "Two active/completed creation claims share an item or structural type.", claim_id=claim["id"])
            blockers[claim["item_id"]] = claim["id"]
            type_blockers[digest] = claim["id"]
        ids[claim["id"]] = claim
    latest = {}
    for revision_number, event in enumerate(ledger["history"], 1):
        if not isinstance(event, dict) or event.get("revision") != revision_number or event.get("action") not in {"reserve", "cancel", "complete"}:
            usage.fail("invalid_claims", "Claim history must be ordered and append-only.")
        after, before = event.get("after"), event.get("before")
        if not isinstance(after, dict) or event.get("entity_id") != after.get("id") or event.get("owner") != after.get("owner") or before != latest.get(after["id"]):
            usage.fail("invalid_claims", "Claim history does not preserve ownership and prior state.")
        expected_status = {"reserve": "reserved", "cancel": "cancelled", "complete": "completed"}[event["action"]]
        if after.get("status") != expected_status or (event["action"] == "reserve" and before is not None) or (event["action"] != "reserve" and (not before or before.get("status") != "reserved")):
            usage.fail("invalid_claims", "Claim history contains an invalid lifecycle transition.")
        if before and any(after.get(key) != before.get(key) for key in ("id", "item_id", "operation", "owner", "purpose", "created_at", "definition", "signature", "signature_type")):
            usage.fail("invalid_claims", "Claim transitions cannot rewrite their owner or mechanical identity.")
        latest[after["id"]] = after
    if latest != ids:
        usage.fail("invalid_claims", "Current claims must match the retained history.")


def creation_conflicts(definition: dict, definitions: dict, stats: dict, ledger: dict, *, existing: bool) -> list[dict]:
    digest, _ = fingerprint(definition, definitions, stats)
    conflicts = []
    for item_id, candidate in definitions.items():
        if existing and item_id == definition["id"]:
            continue
        if item_id == definition["id"] or fingerprint(candidate, definitions, stats)[0] == digest:
            conflicts.append({"kind": "catalogue", "item_id": item_id, "name": candidate["name"], "reason": "ID or structural type already exists; reuse it"})
    for claim in ledger["claims"]:
        if claim["status"] in BLOCKING_STATES and (claim["item_id"] == definition["id"] or claim["signature"] == digest):
            conflicts.append({"kind": "creation_claim", "claim_id": claim["id"], "item_id": claim["item_id"], "owner": claim["owner"], "status": claim["status"]})
    return conflicts


def grid_rows(definitions: dict, stats: dict, ledger: dict, placement_ledger: dict) -> list[dict]:
    rows = []
    all_definitions = dict(definitions)
    for claim in ledger["claims"]:
        if claim["status"] == "reserved" and claim["item_id"] not in all_definitions:
            all_definitions[claim["item_id"]] = claim["definition"]
    for item_id, definition in all_definitions.items():
        kind = item_kind(definition)
        ability_id = item_id if kind in {"perk", "powerup"} else definition.get("perk_id")
        digest, normalized = fingerprint(definition, definitions, stats)
        benefit, risk_cost = effect_summary(definition)
        rows.append({
            "id": item_id, "name": definition["name"], "kind": kind,
            "slot_or_group": definition.get("slot", definition.get("group", "equipped_perk" if kind == "perk" else "")),
            "catalogue_status": definition["status"] if item_id in definitions else "reserved_proposal_not_catalogued",
            "role": definition.get("role", ""), "tradeoff": definition.get("tradeoff", ""),
            "benefit_summary": benefit, "risk_cost_summary": risk_cost,
            "modifiers": definition.get("modifiers", {}), "perk_id": definition.get("perk_id"),
            "definition": definition, "signature": digest, "signature_type": normalized,
            "creation_claims": [{key: claim[key] for key in ("id", "owner", "status", "purpose", "source")} for claim in ledger["claims"] if claim["item_id"] == item_id],
            "ability_introductions": [{key: use[key] for key in ("id", "level_id", "owner", "status", "kind", "source")} for use in placement_ledger["uses"] if ability_id and use["ability_id"] == ability_id],
        })
    return rows


def modifier_summary(modifiers: dict) -> str:
    return ", ".join(f"{key.replace('_', ' ')} {value * 100:+g}%" for key, value in modifiers.items() if value != 0) or "neutral"


def effect_summary(definition: dict) -> tuple[str, str]:
    kind = item_kind(definition)
    if kind in {"clothing", "weapon"}:
        return modifier_summary(definition["modifiers"]), definition.get("tradeoff", "none")
    if kind == "powerup":
        parts = []
        if definition.get("modifiers"):
            parts.append(modifier_summary(definition["modifiers"]))
        if definition.get("shape_override"):
            parts.append(str(definition["shape_override"]).replace("_", " "))
        if definition.get("duration_s") is not None:
            parts.append(f"{definition['duration_s']:g} simulation seconds")
        if definition.get("charges") is not None:
            parts.append(f"{definition['charges']:g} charges")
        costs = [f"{action}: {modifier_summary(modifiers)}" for action, modifiers in definition.get("action_modifiers", {}).items() if modifiers]
        costs.append("expires on " + ", ".join(str(value).replace("_", " ") for value in definition.get("expires_on", [])))
        costs.append(str(definition.get("different_id_repickup", "explicit replacement rule")).replace("_", " "))
        return "; ".join(parts), "; ".join(costs)
    trigger, effect = definition.get("trigger", {}), definition.get("effect", {})
    parts = [str(trigger.get("event", "explicit trigger")).replace("_", " ")]
    conditions = []
    for key, value in trigger.items():
        if key == "event":
            continue
        if key == "distinct_primary_actions":
            conditions.append(f"{value} landed actions")
        elif key == "health_fraction_below":
            conditions.append(f"health below {value:.0%}")
        elif key == "crosses_health_fraction_below":
            conditions.append(f"cross health below {value:.0%}")
        elif key in {"max_gap_s", "previous_dash_gap_s_max"}:
            conditions.append(f"gap ≤{value:g}s")
        elif key == "stationary_time_s":
            conditions.append(f"still for {value:g}s")
        elif key in {"distinct_live_enemy_targets_min", "distinct_live_enemy_targets_exact"}:
            conditions.append(f"{'≥' if key.endswith('min') else '='}{value} living enemies")
        elif key == "shells_at_action_begin":
            conditions.append(f"{value} starting shells")
        elif key == "requires":
            conditions.append(str(value).replace("_", " "))
        elif not isinstance(value, bool):
            conditions.append(key.replace("_", " ") + " " + str(value).replace("_", " "))
    if conditions:
        parts[0] += " (" + "; ".join(conditions) + ")"
    bonus = effect.get("delta", effect.get("delta_max"))
    stat = str(effect.get("stat", "bounded effect")).replace("_", " ")
    payoff = f"{stat} {bonus * 100:+g}%" if isinstance(bonus, (int, float)) else f"{stat} +{effect['amount']:g}s" if "amount" in effect and str(effect.get("stat", "")).endswith("_s") else stat
    if "delta_max" in effect:
        payoff = "up to " + payoff
    if effect.get("scope"):
        payoff += " / " + str(effect["scope"]).replace("_", " ")
    parts.append(payoff)
    limits = definition.get("limits", {})
    costs = [modifier_summary(definition.get("required_tradeoff", {}))]
    for key, label in (("duration_s", "expires after"), ("cooldown_s", "cooldown")):
        if key in limits:
            costs.append(f"{label} {limits[key]:g}s")
    if "consumed_on" in limits:
        costs.append("consumed on " + str(limits["consumed_on"]).replace("_", " "))
    if "uses_per_encounter" in limits:
        costs.append(f"{limits['uses_per_encounter']} use/encounter")
    if limits.get("reset_on"):
        costs.append("resets on " + ", ".join(str(value).replace("_", " ") for value in limits["reset_on"]))
    return " → ".join(parts), "; ".join(costs)


def markdown_grid(response: dict) -> str:
    def cell(value):
        return str(value).replace("|", "\\|").replace("\n", " ")
    lines = ["# Live equipment grid", "", "Derived from the canonical catalogue, creation claims and ability introductions.", "Benefits and costs below summarize provisional definitions; read the full JSON/specification for every condition.", "Structural screening does not prove novelty or balance. Completion means catalogue integration.", "", "| ID | Kind / slot | Name | Benefit / trigger | Risk / cost | Catalogue status | Creation ownership | Ability introductions |", "| --- | --- | --- | --- | --- | --- | --- | --- |"]
    names = {row["id"]: row["name"] for row in response["items"]}
    for row in response["items"]:
        effect, cost = effect_summary(row["definition"])
        if row["perk_id"]:
            effect += "; " + names.get(row["perk_id"], row["perk_id"]) + " (" + row["perk_id"] + ")"
        creation = "; ".join(f"{c['owner']} ({c['status']}, {c['id']})" for c in row["creation_claims"]) or ("reuse existing" if row["catalogue_status"].startswith("implemented") else "unclaimed shared work")
        introductions = "; ".join(f"{u['level_id']}: {u['owner']} ({u['status']}, {u['id']})" for u in row["ability_introductions"]) or "none recorded"
        lines.append("| " + " | ".join(cell(value) for value in (row["id"], row["kind"] + " / " + row["slot_or_group"], row["name"], effect, cost, row["catalogue_status"], creation, introductions)) + " |")
    return "\n".join(lines)


def parser():
    result = usage.JsonParser(description=__doc__)
    result.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2], help="Authoritative campaign repository root; use it from all worktrees.")
    commands = result.add_subparsers(dest="command", required=True, parser_class=usage.JsonParser)
    status = commands.add_parser("status")
    status.add_argument("--markdown", action="store_true", help="Render the live grid as Markdown instead of JSON.")
    check = commands.add_parser("check")
    check.add_argument("--proposal", type=Path, required=True, help="One complete canonical-style equipment definition JSON.")
    reserve = commands.add_parser("reserve")
    selection = reserve.add_mutually_exclusive_group(required=True)
    selection.add_argument("--item", help="Canonical proposed item to implement once; existing implemented items are reused.")
    selection.add_argument("--proposal", type=Path, help="Proposed new ID and structural type to create.")
    for field in ("owner", "purpose", "source"):
        reserve.add_argument("--" + field, required=True)
    cancel = commands.add_parser("cancel")
    complete = commands.add_parser("complete")
    for command in (cancel, complete):
        command.add_argument("--claim", required=True)
        command.add_argument("--owner", required=True)
    cancel.add_argument("--reason", required=True)
    complete.add_argument("--source", required=True, help="Existing accurate evidence of canonical catalogue integration.")
    commands.add_parser("validate")
    return result


def execute(args) -> dict:
    root = args.root.resolve()
    path = root / "data/design/equipment_claims.json"
    if path.is_symlink():
        usage.fail("unsafe_ledger", "Equipment claims file must not be a symlink.")
    with usage.ledger_lock(path):
        definitions, stats = load_catalogue(root)
        ability_definitions, levels = usage.load_context(root)
        placements = usage.read_json(root / "data/design/ability_usage.json")
        usage.validate_ledger(placements, ability_definitions, levels, root)
        ledger = usage.read_json(path)
        validate_claims(ledger, definitions, stats, root)
        response = {"ok": True, "command": args.command, "revision": ledger["revision"], "ability_usage_revision": placements["revision"], "semantic_review_required": True}
        if args.command in {"status", "validate"}:
            rows = grid_rows(definitions, stats, ledger, placements)
            response.update({"items": rows, "item_count": len(rows), "claims": ledger["claims"], "catalogue_duplicate_types": []})
            seen = {}
            for row in rows:
                if row["id"] in definitions:
                    if row["signature"] in seen:
                        response["catalogue_duplicate_types"].append({"item_id": row["id"], "same_type_as": seen[row["signature"]]})
                    seen[row["signature"]] = row["id"]
            if args.command == "validate" and response["catalogue_duplicate_types"]:
                usage.fail("duplicate_type", "Canonical catalogue contains repeated structural equipment types; resolve identity drift.", duplicates=response["catalogue_duplicate_types"])
            if args.command == "validate":
                response.pop("items")
                response.pop("claims")
                response.update({"claim_count": len(ledger["claims"]), "active_claim_count": sum(claim["status"] == "reserved" for claim in ledger["claims"])})
            return response
        if args.command in {"check", "reserve"}:
            existing = args.command == "reserve" and args.item is not None
            if existing:
                definition = definitions.get(args.item)
                if definition is None:
                    usage.fail("unknown_item", "Item is not in the canonical catalogue.", item_id=args.item)
                if definition["status"].startswith("implemented"):
                    usage.fail("reuse_existing", "Implemented equipment already exists; reuse its shared resource instead of creating it again.", item_id=args.item)
            else:
                definition = usage.read_json(args.proposal)
            digest, normalized = fingerprint(definition, definitions, stats)
            conflicts = creation_conflicts(definition, definitions, stats, ledger, existing=existing)
            if conflicts:
                usage.fail("duplicate_type", "Equipment ID or structural type already exists or is claimed; reuse or coordinate with its owner.", conflicts=conflicts)
            if args.command == "check":
                response.update({"creation_available": True, "item_id": definition["id"], "signature": digest, "signature_type": normalized, "is_reservation": False})
                return response
            owner = usage.require_text(args.owner, "owner")
            purpose = usage.require_text(args.purpose, "purpose", 10)
            source = usage.validate_source(root, args.source)
            now = usage.utc_now()
            claim = {"id": "EQCL-%06d" % (max((int(c["id"].split("-", 1)[1]) for c in ledger["claims"]), default=0) + 1), "item_id": definition["id"], "operation": "implement_existing" if existing else "new_definition", "status": "reserved", "owner": owner, "purpose": purpose, "source": source, "created_at": now, "updated_at": now, "definition": copy.deepcopy(definition), "signature": digest, "signature_type": normalized}
            ledger["claims"].append(claim)
            usage.audit(ledger, "reserve", owner, None, claim)
        else:
            claim = next((c for c in ledger["claims"] if c["id"] == args.claim), None)
            if claim is None:
                usage.fail("unknown_claim", "Creation claim does not exist.", claim_id=args.claim)
            owner = usage.require_text(args.owner, "owner")
            if owner != claim["owner"]:
                usage.fail("wrong_owner", "Only the claim's recorded owner may change it.", claim_id=claim["id"], owner=claim["owner"])
            if claim["status"] != "reserved":
                usage.fail("invalid_transition", "Only a reserved creation claim can be cancelled or completed.", status=claim["status"])
            before = copy.deepcopy(claim)
            if args.command == "cancel":
                claim["status"] = "cancelled"
                claim["reason"] = usage.require_text(args.reason, "reason", 10)
            else:
                canonical = definitions.get(claim["item_id"])
                if canonical is None or fingerprint(canonical, definitions, stats)[0] != claim["signature"]:
                    usage.fail("definition_not_integrated", "Complete requires the claimed type integrated in the canonical catalogue.", item_id=claim["item_id"])
                claim["status"] = "completed"
                claim["source"] = usage.validate_source(root, args.source)
            claim["updated_at"] = usage.utc_now()
            usage.audit(ledger, args.command, owner, before, claim)
        validate_claims(ledger, definitions, stats, root)
        usage.atomic_write(path, ledger)
        response.update({"revision": ledger["revision"], "claim": claim, "completion_is_catalogue_integration_only": True})
        return response


def main(argv=None) -> int:
    try:
        args = parser().parse_args(argv)
        response = execute(args)
    except usage.UsageError as exc:
        print(json.dumps({"ok": False, "code": exc.code, "message": exc.message, "details": exc.details}, ensure_ascii=False, allow_nan=False))
        return 2
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(json.dumps({"ok": False, "code": "invalid_state", "message": "Equipment operation failed closed; claims were not intentionally changed.", "details": {"reason": str(exc)}}, ensure_ascii=False))
        return 2
    if args.command == "status" and args.markdown:
        print(markdown_grid(response))
    else:
        print(json.dumps(response, ensure_ascii=False, allow_nan=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
