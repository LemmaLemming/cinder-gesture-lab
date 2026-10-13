"""Test the public equipment grid CLI using disposable canonical campaign roots."""

from __future__ import annotations

import copy
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


REPOSITORY = Path(__file__).resolve().parents[1]
CLI = REPOSITORY / "scripts/design/equipment_grid.py"
ABILITY_CLI = REPOSITORY / "scripts/design/ability_usage.py"
SOURCE = "docs/grid_evidence.md"


class EquipmentGridTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="equipment-grid-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        for relative in ("data/design/player_equipment.json", "data/design/ability_usage.json", "data/design/equipment_claims.json", *(f"docs/reference-library/act{act}/research/levels.json" for act in (1, 2, 3))):
            destination = self.root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPOSITORY / relative, destination)
        (self.root / SOURCE).write_text("# Catalogue integration evidence\n\nTest fixture, not gameplay approval.\n", encoding="utf-8")
        self.claims = self.root / "data/design/equipment_claims.json"
        self.catalogue = self.root / "data/design/player_equipment.json"

    def command(self, *args):
        return [sys.executable, str(CLI), "--root", str(self.root), *args]

    def invoke(self, *args, ok=True):
        result = subprocess.run(self.command(*args), cwd=self.root, text=True, capture_output=True, timeout=20, check=False)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["ok"], ok, payload)
        self.assertEqual(result.returncode, 0 if ok else 2, payload)
        return payload

    def reject_without_write(self, *args):
        before = self.claims.read_bytes()
        result = self.invoke(*args, ok=False)
        self.assertEqual(self.claims.read_bytes(), before)
        return result

    def definition(self, item_id):
        catalogue = json.loads(self.catalogue.read_text())
        return copy.deepcopy(next(row for key in ("clothing", "weapons", "perks", "powerups") for row in catalogue[key] if row["id"] == item_id))

    def proposal(self, definition, filename="proposal.json"):
        path = self.root / filename
        path.write_text(json.dumps(definition, indent=2) + "\n", encoding="utf-8")
        return str(path)

    def new_clothing(self, item_id="CLOTH-J9"):
        definition = self.definition("CLOTH-J2")
        definition.update({"id": item_id, "name": "Test expedition jacket", "status": "proposed_unplaytested", "modifiers": {"damage": 0.05, "dash_speed": -0.05}, "role": "commit slower movement for a stronger hit", "tradeoff": "slower dash"})
        return definition

    def reserve(self, *, item=None, definition=None, owner="act1-owner"):
        selection = ["--item", item] if item is not None else ["--proposal", self.proposal(definition)]
        return self.invoke("reserve", *selection, "--owner", owner, "--purpose", "Implement one shared bounded equipment definition.", "--source", SOURCE)["claim"]

    def add_canonical(self, definition):
        catalogue = json.loads(self.catalogue.read_text())
        group = {"CLOTH": "clothing", "WEAPON": "weapons", "PERK": "perks", "POWER": "powerups"}[definition["id"].split("-", 1)[0]]
        catalogue[group].append(definition)
        self.catalogue.write_text(json.dumps(catalogue, indent=2) + "\n", encoding="utf-8")

    def test_live_grid_covers_all_catalogue_types_and_readiness(self):
        response = self.invoke("status")
        self.assertEqual(response["item_count"], 36)
        rows = {row["id"]: row for row in response["items"]}
        self.assertEqual({row["kind"] for row in rows.values()}, {"clothing", "weapon", "perk", "powerup"})
        self.assertEqual(rows["CLOTH-J1"]["catalogue_status"], "implemented_prototype_unplaytested")
        self.assertEqual(rows["PERK-01"]["catalogue_status"], "proposed_unplaytested")
        self.assertEqual(response["claims"], [])
        self.assertEqual(self.invoke("validate")["catalogue_duplicate_types"], [])

    def test_markdown_is_a_live_grid(self):
        result = subprocess.run(self.command("status", "--markdown"), text=True, capture_output=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("| ID | Kind / slot |", result.stdout)
        self.assertIn("CLOTH-J1", result.stdout)
        self.assertIn("POWER-06", result.stdout)

    def test_static_reskin_and_numeric_retune_reuse_existing_type(self):
        definition = self.definition("CLOTH-J1")
        definition.update({"id": "CLOTH-J9", "name": "Moon silver coat", "art": "lunar.png", "status": "proposed_unplaytested", "modifiers": {"armour": 0.1, "attack_speed": -0.1}})
        result = self.reject_without_write("check", "--proposal", self.proposal(definition))
        self.assertEqual(result["code"], "duplicate_type")
        self.assertIn("CLOTH-J1", {row.get("item_id") for row in result["details"]["conflicts"]})

    def test_static_bonus_and_penalty_directions_are_distinct(self):
        definition = self.definition("CLOTH-J1")
        definition.update({"id": "CLOTH-J9", "status": "proposed_unplaytested", "modifiers": {"armour": 0.1, "attack_speed": 0.05}})
        response = self.invoke("check", "--proposal", self.proposal(definition))
        self.assertTrue(response["creation_available"])
        self.assertEqual(response["signature_type"]["modifier_directions"]["attack_speed"], "positive")
        self.assertFalse(response["is_reservation"])
        self.assertEqual(json.loads(self.claims.read_text())["revision"], 0)

    def test_powerup_rename_duration_and_bonus_retune_are_not_novel(self):
        definition = self.definition("POWER-01")
        definition.update({"id": "POWER-07", "name": "Red fleet", "duration_s": 5, "modifiers": {"dash_speed": 0.05}})
        result = self.reject_without_write("check", "--proposal", self.proposal(definition))
        self.assertEqual(result["code"], "duplicate_type")

    def test_new_perk_requires_changed_structure_not_combo_number(self):
        definition = self.definition("PERK-01")
        definition.update({"id": "PERK-15", "name": "Five hit cadence"})
        definition["trigger"]["distinct_primary_actions"] = 5
        self.reject_without_write("check", "--proposal", self.proposal(definition))
        definition["effect"] = {"stat": "reload_credit_s", "amount": 0.1, "scope": "third_primary_action"}
        self.assertTrue(self.invoke("check", "--proposal", self.proposal(definition))["creation_available"])

    def test_implemented_equipment_is_reused_without_creation_claim(self):
        result = self.reject_without_write("reserve", "--item", "CLOTH-J1", "--owner", "act2-owner", "--purpose", "Create the same jacket again.", "--source", SOURCE)
        self.assertEqual(result["code"], "reuse_existing")

    def test_existing_proposed_item_has_one_owner_and_cancelled_history(self):
        claim = self.reserve(item="PERK-01")
        self.assertEqual(claim["operation"], "implement_existing")
        self.assertEqual(self.reject_without_write("cancel", "--claim", claim["id"], "--owner", "other-owner", "--reason", "Other agent changed its mind.")["code"], "wrong_owner")
        self.assertEqual(self.reject_without_write("reserve", "--item", "PERK-01", "--owner", "act2-owner", "--purpose", "Duplicate the same proposed implementation.", "--source", SOURCE)["code"], "duplicate_type")
        self.invoke("cancel", "--claim", claim["id"], "--owner", claim["owner"], "--reason", "Deferred the implementation after review.")
        replacement = self.reserve(item="PERK-01", owner="act2-owner")
        self.assertNotEqual(replacement["id"], claim["id"])
        ledger = json.loads(self.claims.read_text())
        self.assertEqual(len(ledger["claims"]), 2)
        self.assertEqual(len(ledger["history"]), 3)
        self.invoke("validate")

    def test_concurrent_equivalent_new_types_have_one_winner(self):
        first, second = self.new_clothing("CLOTH-J9"), self.new_clothing("CLOTH-J10")
        commands = []
        for index, definition in enumerate((first, second)):
            path = self.proposal(definition, f"proposal-{index}.json")
            commands.append(self.command("reserve", "--proposal", path, "--owner", f"act{index + 1}-owner", "--purpose", "Author this one shared equipment type.", "--source", SOURCE))
        processes = [subprocess.Popen(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE) for command in commands]
        self.addCleanup(lambda: [process.kill() for process in processes if process.poll() is None])
        results = [process.communicate(timeout=20) for process in processes]
        payloads = [json.loads(stdout) for stdout, _ in results]
        self.assertEqual(sorted(payload["ok"] for payload in payloads), [False, True], payloads)
        self.assertEqual(sorted(process.returncode for process in processes), [0, 2])
        self.assertEqual(len(json.loads(self.claims.read_text())["claims"]), 1)
        self.invoke("validate")

    def test_completion_requires_canonical_integration_and_retains_proposed_status(self):
        definition = self.new_clothing()
        claim = self.reserve(definition=definition)
        self.assertEqual(self.reject_without_write("complete", "--claim", claim["id"], "--owner", claim["owner"], "--source", SOURCE)["code"], "definition_not_integrated")
        rows = {row["id"]: row for row in self.invoke("status")["items"]}
        self.assertEqual(rows[definition["id"]]["catalogue_status"], "reserved_proposal_not_catalogued")
        self.add_canonical(definition)
        result = self.invoke("complete", "--claim", claim["id"], "--owner", claim["owner"], "--source", SOURCE)
        self.assertEqual(result["claim"]["status"], "completed")
        self.assertTrue(result["completion_is_catalogue_integration_only"])
        rows = {row["id"]: row for row in self.invoke("status")["items"]}
        self.assertEqual(rows[definition["id"]]["catalogue_status"], "proposed_unplaytested")
        self.reject_without_write("cancel", "--claim", claim["id"], "--owner", claim["owner"], "--reason", "Try to erase a completed type claim.")

    def test_grid_joins_introduction_owner_without_allocating_it(self):
        result = subprocess.run([sys.executable, str(ABILITY_CLI), "--root", str(self.root), "reserve", "--ability", "PERK-01", "--level", "A1-L1", "--owner", "level-owner", "--purpose", "Introduce the existing cadence in one encounter.", "--source", SOURCE], text=True, capture_output=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout)
        before = self.claims.read_bytes()
        rows = {row["id"]: row for row in self.invoke("status")["items"]}
        self.assertEqual(rows["PERK-01"]["ability_introductions"][0]["owner"], "level-owner")
        self.assertEqual(rows["CLOTH-P3"]["ability_introductions"][0]["level_id"], "A1-L1")
        self.assertEqual(self.claims.read_bytes(), before)

    def test_malformed_proposal_and_hand_edited_ownership_fail_closed(self):
        path = self.proposal(self.new_clothing())
        Path(path).write_text('{"id":"CLOTH-J9","id":"CLOTH-J10"}', encoding="utf-8")
        self.assertEqual(self.reject_without_write("check", "--proposal", path)["code"], "invalid_json")
        claim = self.reserve(item="PERK-01")
        ledger = json.loads(self.claims.read_text())
        ledger["claims"][0]["owner"] = "other-owner"
        self.claims.write_text(json.dumps(ledger) + "\n", encoding="utf-8")
        self.assertEqual(self.reject_without_write("cancel", "--claim", claim["id"], "--owner", "other-owner", "--reason", "Attempt to bypass the original owner.")["code"], "invalid_claims")


if __name__ == "__main__":
    unittest.main()
