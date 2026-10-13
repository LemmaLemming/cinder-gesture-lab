"""Exercise the public ability-usage CLI against disposable campaign copies.

Run from the repository root with:
    python3 -m unittest discover -s tests -p 'test_ability_usage.py' -v

The canonical catalog, level plans, and ledger are never changed by these tests.
"""

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
CLI = REPOSITORY / "scripts/design/ability_usage.py"
SOURCE = "docs/test_usage.md"


class AbilityUsageCliTests(unittest.TestCase):
    """Guard the authoring workflow, rather than private implementation helpers."""

    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="ability-usage-tests-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.catalog = self.root / "data/design/player_equipment.json"
        self.catalog.parent.mkdir(parents=True)
        shutil.copy2(REPOSITORY / "data/design/player_equipment.json", self.catalog)
        for act in (1, 2, 3):
            relative = Path(f"docs/reference-library/act{act}/research/levels.json")
            destination = self.root / relative
            destination.parent.mkdir(parents=True)
            shutil.copy2(REPOSITORY / relative, destination)
        (self.root / SOURCE).write_text(
            "# Test encounter\n\nProposed ability placements are recorded by the CLI.\n",
            encoding="utf-8",
        )
        self.ledger = self.root / "data/design/ability_usage.json"
        self.invoke("init")

    def command(self, *arguments: str) -> list[str]:
        return [sys.executable, str(CLI), "--root", str(self.root), *arguments]

    def parse_result(self, result: subprocess.CompletedProcess[str]) -> dict:
        self.assertTrue(result.stdout.strip(), result.stderr)
        try:
            payload = json.loads(result.stdout)
        except json.JSONDecodeError as error:
            self.fail(
                f"CLI did not return JSON: {error}\n"
                f"stdout={result.stdout!r}\nstderr={result.stderr!r}"
            )
        self.assertIsInstance(payload, dict)
        self.assertIsInstance(payload.get("ok"), bool, payload)
        return payload

    def invoke(self, *arguments: str, ok: bool = True) -> dict:
        result = subprocess.run(
            self.command(*arguments),
            cwd=self.root,
            capture_output=True,
            text=True,
            check=False,
            timeout=20,
        )
        payload = self.parse_result(result)
        self.assertEqual(payload["ok"], ok, payload)
        if ok:
            self.assertEqual(result.returncode, 0, payload)
        else:
            self.assertNotEqual(result.returncode, 0, payload)
            self.assertTrue(payload.get("code"), payload)
            self.assertTrue(payload.get("message"), payload)
        return payload

    def reject_without_write(self, *arguments: str) -> dict:
        before = self.ledger.read_bytes()
        payload = self.invoke(*arguments, ok=False)
        self.assertEqual(self.ledger.read_bytes(), before)
        return payload

    def read_ledger(self) -> dict:
        return json.loads(self.ledger.read_text(encoding="utf-8"))

    def uses(self) -> list[dict]:
        return self.read_ledger()["uses"]

    def reserve(
        self,
        ability: str = "PERK-01",
        level: str = "A1-L1",
        owner: str = "encounter-agent",
        *,
        kind: str = "introduction",
        from_use: str | None = None,
    ) -> dict:
        arguments = [
            "reserve", "--ability", ability, "--level", level,
            "--owner", owner, "--purpose", "Teach the ability in a readable encounter.",
            "--source", SOURCE, "--kind", kind,
        ]
        if from_use is not None:
            arguments.extend(["--from-use", from_use])
        return self.invoke(*arguments)["use"]

    def reject_reservation(
        self,
        ability: str,
        level: str,
        *,
        kind: str = "introduction",
        from_use: str | None = None,
    ) -> dict:
        arguments = [
            "reserve", "--ability", ability, "--level", level,
            "--owner", "other-agent", "--purpose", "Test a conflicting placement.",
            "--source", SOURCE, "--kind", kind,
        ]
        if from_use is not None:
            arguments.extend(["--from-use", from_use])
        return self.reject_without_write(*arguments)

    def commit_introduction(self, ability: str, level: str = "A1-L1") -> dict:
        use = self.reserve(ability=ability, level=level)
        self.invoke(
            "record", "--use", use["id"], "--owner", use["owner"],
            "--status", "planned",
        )
        self.invoke(
            "record", "--use", use["id"], "--owner", use["owner"],
            "--status", "implemented",
        )
        return use

    def add_catalog_perk(self, *, change: str) -> dict:
        catalog = json.loads(self.catalog.read_text(encoding="utf-8"))
        perk = copy.deepcopy(next(p for p in catalog["perks"] if p["id"] == "PERK-01"))
        perk["id"] = "PERK-15"
        if change == "cosmetic":
            perk["name"] = "Moonlit Triple Cadence"
            perk["description"] = "A lunar jacket with bright stitching."
        elif change == "numbers":
            perk["name"] = "Retuned Triple Cadence"
            perk["trigger"]["max_gap_s"] = 1.1
            perk["effect"]["delta"] = 0.25
        elif change == "decision":
            perk["name"] = "Cadence Feed"
            perk["effect"] = {
                "stat": "reload_credit_s", "amount": 0.1,
                "scope": "third_primary_action",
            }
        elif change != "none":
            raise ValueError(change)
        catalog["perks"].append(perk)
        self.catalog.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
        return perk

    def register_variant(self, *, decision: str | None = None) -> dict:
        return self.invoke(
            "register", "--ability", "PERK-15", "--owner", "ability-designer",
            "--variant-of", "PERK-01",
            "--player-decision", decision or (
                "Spend a blast before the third landed slash to earn ammunition "
                "recovery, instead of preserving the chain for finisher damage."
            ),
            "--difference", (
                "The third landed slash grants reload progress rather than damage; "
                "ammo expenditure now determines whether the chain pays off."
            ),
        )

    def append_definition(self, collection: str, definition: dict) -> None:
        catalog = json.loads(self.catalog.read_text(encoding="utf-8"))
        catalog[collection].append(definition)
        self.catalog.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")

    def test_catalog_proposals_and_read_only_queries_do_not_mark_abilities_used(self) -> None:
        before = self.ledger.read_bytes()
        status = self.invoke("status")
        self.assertEqual(status["uses"], [])
        self.assertTrue(status["suggestions"])
        for suggestion in status["suggestions"]:
            self.assertEqual(suggestion["status"], "unassigned_suggestion")
            self.invoke(
                "check", "--ability", suggestion["ability_id"],
                "--level", suggestion["level_id"],
            )
        available = self.invoke("available", "--level", "A2-L1")
        rows = {row["id"]: row for row in available["abilities"]}
        for ability in ("PERK-01", "PERK-14", "POWER-01", "POWER-06"):
            self.assertTrue(rows[ability]["available"], rows[ability])
        self.assertEqual(self.uses(), [])
        self.assertEqual(self.ledger.read_bytes(), before)

    def test_reservation_blocks_exact_repeat_across_main_optional_and_acts(self) -> None:
        use = self.reserve()
        self.assertEqual(use["status"], "reserved")
        self.reject_reservation("PERK-01", "A1-O1")
        self.reject_reservation("PERK-01", "A2-L1")
        self.reject_reservation("PERK-01", "A3-O3")
        rows = self.invoke("available", "--level", "A3-L5")["abilities"]
        row = next(item for item in rows if item["id"] == "PERK-01")
        self.assertFalse(row["available"])
        self.assertEqual(len(self.uses()), 1)

    def test_optional_first_introduction_also_blocks_later_main_level(self) -> None:
        self.reserve(ability="PERK-02", level="A1-O1")
        self.reject_reservation("PERK-02", "A2-L3")
        self.reject_without_write(
            "check", "--ability", "PERK-02", "--level", "A3-L1",
        )

    def test_concurrent_claims_have_exactly_one_winner(self) -> None:
        levels = ("A1-L1", "A1-O1", "A2-L1", "A2-O1", "A3-L1", "A3-O1")
        processes = []
        for index in range(8):
            processes.append(subprocess.Popen(
                self.command(
                    "reserve", "--ability", "PERK-04",
                    "--level", levels[index % len(levels)],
                    "--owner", f"concurrent-agent-{index}",
                    "--purpose", "Claim the campaign's one Counterstep introduction.",
                    "--source", SOURCE,
                ),
                cwd=self.root, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
            ))
        results = []
        for process in processes:
            stdout, stderr = process.communicate(timeout=30)
            result = subprocess.CompletedProcess(process.args, process.returncode, stdout, stderr)
            payload = self.parse_result(result)
            self.assertEqual(result.returncode == 0, payload["ok"], payload)
            results.append(payload)
        successes = [result for result in results if result["ok"]]
        self.assertEqual(len(successes), 1, results)
        self.assertEqual(len(self.uses()), 1)
        self.assertEqual(self.uses()[0]["id"], successes[0]["use"]["id"])
        self.invoke("validate")

    def test_cancellation_frees_introduction_but_preserves_audit_history(self) -> None:
        first = self.reserve()
        self.invoke(
            "cancel", "--use", first["id"], "--owner", first["owner"],
            "--reason", "The encounter was removed from this level plan.",
        )
        second = self.reserve(level="A2-L1", owner="replacement-agent")
        self.assertNotEqual(first["id"], second["id"])
        rows = {row["id"]: row for row in self.uses()}
        self.assertEqual(rows[first["id"]]["status"], "cancelled")
        self.assertEqual(rows[second["id"]]["status"], "reserved")
        self.assertEqual(len(rows), 2)
        self.invoke("validate")

    def test_only_reservation_owner_can_record_cancel_or_withdraw(self) -> None:
        use = self.reserve()
        for command in ("record", "cancel", "withdraw"):
            arguments = [command, "--use", use["id"], "--owner", "different-agent"]
            if command == "record":
                arguments.extend(["--status", "planned"])
            else:
                arguments.extend(["--reason", "Attempt to alter another agent's work."])
            self.reject_without_write(*arguments)
        self.assertEqual(self.uses()[0]["status"], "reserved")
        self.invoke("record", "--use", use["id"], "--owner", use["owner"], "--status", "planned")
        self.assertEqual(self.uses()[0]["status"], "planned")
        self.invoke("record", "--use", use["id"], "--owner", use["owner"], "--status", "implemented")
        self.assertEqual(self.uses()[0]["status"], "implemented")
        self.reject_without_write(
            "record", "--use", use["id"], "--owner", use["owner"], "--status", "planned",
        )
        self.reject_without_write(
            "cancel", "--use", use["id"], "--owner", use["owner"],
            "--reason", "Attempt to cancel implemented work.",
        )

    def test_reserved_use_cannot_skip_the_planned_commit(self) -> None:
        use = self.reserve()
        self.reject_without_write(
            "record", "--use", use["id"], "--owner", use["owner"],
            "--status", "implemented",
        )
        self.assertEqual(self.uses()[0]["status"], "reserved")

    def test_cancelled_use_cannot_be_recorded_and_unknown_use_cannot_be_created(self) -> None:
        use = self.reserve()
        self.invoke(
            "cancel", "--use", use["id"], "--owner", use["owner"],
            "--reason", "Cancelled before the design was committed.",
        )
        for use_id in (use["id"], "USE-999999"):
            self.reject_without_write(
                "record", "--use", use_id, "--owner", use["owner"], "--status", "planned",
            )

    def test_withdrawn_plan_frees_introduction_and_retains_history(self) -> None:
        first = self.reserve()
        self.invoke(
            "record", "--use", first["id"], "--owner", first["owner"],
            "--status", "planned",
        )
        self.invoke(
            "withdraw", "--use", first["id"], "--owner", first["owner"],
            "--reason", "Move the planned introduction to the next act.",
        )
        replacement = self.reserve(level="A2-L1", owner="act-two-agent")
        rows = {row["id"]: row for row in self.uses()}
        self.assertEqual(rows[first["id"]]["status"], "withdrawn")
        self.assertEqual(rows[replacement["id"]]["status"], "reserved")
        self.reject_without_write(
            "record", "--use", first["id"], "--owner", first["owner"],
            "--status", "implemented",
        )
        self.invoke("validate")

    def test_withdrawal_cannot_leave_active_carryover_without_an_introduction(self) -> None:
        intro = self.reserve()
        self.invoke(
            "record", "--use", intro["id"], "--owner", intro["owner"],
            "--status", "planned",
        )
        carried = self.reserve(
            level="A2-L1", owner="act-two-agent", kind="carryover", from_use=intro["id"],
        )
        self.reject_without_write(
            "withdraw", "--use", intro["id"], "--owner", intro["owner"],
            "--reason", "Would orphan the carried equipment placement.",
        )
        self.invoke(
            "cancel", "--use", carried["id"], "--owner", carried["owner"],
            "--reason", "Remove the dependent reservation first.",
        )
        self.invoke(
            "withdraw", "--use", intro["id"], "--owner", intro["owner"],
            "--reason", "The dependent carryover was cancelled.",
        )
        self.assertEqual(self.uses()[0]["status"], "withdrawn")
        self.invoke("validate")

    def test_malformed_ledger_fails_closed_and_is_not_overwritten(self) -> None:
        for broken in (b"{invalid JSON", b'{"schema_version":"unsupported"}\n'):
            with self.subTest(broken=broken):
                self.ledger.write_bytes(broken)
                self.reject_without_write("validate")
                self.reject_without_write(
                    "reserve", "--ability", "PERK-01", "--level", "A1-L1",
                    "--owner", "agent", "--purpose", "Attempt an unsafe fallback.",
                    "--source", SOURCE,
                )
                self.reject_without_write("init")

    def test_new_id_cosmetic_and_numeric_retunes_are_rejected_as_clones(self) -> None:
        original_catalog = self.catalog.read_bytes()
        for change in ("none", "cosmetic", "numbers"):
            with self.subTest(change=change):
                self.catalog.write_bytes(original_catalog)
                self.add_catalog_perk(change=change)
                self.reject_without_write(
                    "register", "--ability", "PERK-15", "--owner", "designer",
                    "--variant-of", "PERK-01",
                    "--player-decision", "Keep landing three slashes to earn a finisher.",
                    "--difference", "A new appearance and adjusted values for the same combo.",
                )
                self.reject_reservation("PERK-15", "A2-L1")

    def test_clone_cannot_escape_detection_by_omitting_family_lineage(self) -> None:
        self.add_catalog_perk(change="cosmetic")
        self.reject_without_write(
            "register", "--ability", "PERK-15", "--owner", "designer",
            "--player-decision", "Maintain a three-hit slash combo.",
            "--difference", "This jacket uses a different visual theme.",
        )

    def test_numbers_embedded_in_powerup_shape_names_do_not_grant_novelty(self) -> None:
        catalog = json.loads(self.catalog.read_text(encoding="utf-8"))
        definition = copy.deepcopy(next(row for row in catalog["powerups"] if row["id"] == "POWER-06"))
        definition.update({"id": "POWER-07", "name": "Retuned Orbit Cut", "shape_override": "primary_270_degrees"})
        self.append_definition("powerups", definition)
        self.reject_without_write(
            "register", "--ability", "POWER-07", "--owner", "designer",
            "--variant-of", "POWER-06",
            "--player-decision", "Use the temporary wide swing to hit surrounding enemies.",
            "--difference", "The swing covers a smaller angle using the same temporary effect.",
        )

    def test_formula_constants_under_a_new_id_do_not_grant_novelty(self) -> None:
        catalog = json.loads(self.catalog.read_text(encoding="utf-8"))
        definition = copy.deepcopy(next(row for row in catalog["perks"] if row["id"] == "PERK-02"))
        definition.update({
            "id": "PERK-15", "name": "Retuned Last Thread",
            "expression": "0.18 * clamp((0.55 - health_fraction) / 0.25, 0, 1)",
        })
        definition["trigger"]["health_fraction_below"] = 0.55
        definition["effect"]["delta_max"] = 0.18
        definition["limits"]["max_bonus_at_health_fraction"] = 0.3
        self.append_definition("perks", definition)
        self.reject_without_write(
            "register", "--ability", "PERK-15", "--owner", "designer",
            "--variant-of", "PERK-02",
            "--player-decision", "Remain at low health to gain the same damage incentive.",
            "--difference", "The low health threshold and damage coefficient are retuned.",
        )

    def test_numeric_retuning_same_registered_id_keeps_existing_identity(self) -> None:
        before = self.ledger.read_bytes()
        catalog = json.loads(self.catalog.read_text(encoding="utf-8"))
        definition = next(row for row in catalog["perks"] if row["id"] == "PERK-02")
        definition["trigger"]["health_fraction_below"] = 0.55
        definition["effect"]["delta_max"] = 0.18
        definition["limits"]["max_bonus_at_health_fraction"] = 0.3
        definition["expression"] = "0.18 * clamp((0.55 - health_fraction) / 0.25, 0, 1)"
        self.catalog.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
        self.invoke("validate")
        self.invoke("check", "--ability", "PERK-02", "--level", "A2-L1")
        self.assertEqual(self.ledger.read_bytes(), before)
        self.reserve(ability="PERK-02", level="A2-L1")

    def test_structural_rewrite_under_existing_id_fails_closed(self) -> None:
        catalog = json.loads(self.catalog.read_text(encoding="utf-8"))
        definition = next(row for row in catalog["perks"] if row["id"] == "PERK-02")
        definition["trigger"]["event"] = "completed_dash"
        self.catalog.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
        response = self.reject_without_write("validate")
        self.assertEqual(response["code"], "signature_drift")
        self.reject_reservation("PERK-02", "A2-L1")

    def test_ordered_action_sequences_are_variants_but_reset_order_is_cosmetic(self) -> None:
        # Candidate signature fixtures only: these unsupported action-sequence
        # fields are never assigned to canonical equipment or implemented.
        forward = self.add_catalog_perk(change="none")
        forward["trigger"]["action_sequence"] = ["primary_hit", "followup_hit"]
        catalog = json.loads(self.catalog.read_text(encoding="utf-8"))
        catalog["perks"][-1] = forward
        self.catalog.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
        first = self.invoke(
            "register", "--ability", "PERK-15", "--owner", "designer",
            "--variant-of", "PERK-01",
            "--player-decision", "Open with a landed slash then spend ammunition on the followup.",
            "--difference", "The chain now requires an ordered slash then blast sequence.",
        )["ability"]

        reverse = copy.deepcopy(forward)
        reverse["id"] = "PERK-16"
        reverse["trigger"]["action_sequence"].reverse()
        self.append_definition("perks", reverse)
        second = self.invoke(
            "register", "--ability", "PERK-16", "--owner", "designer",
            "--variant-of", "PERK-15",
            "--player-decision", "Spend ammunition on the blast before closing for a landed slash.",
            "--difference", "The action order is reversed: blast before slash rather than slash before blast.",
        )["ability"]
        self.assertNotEqual(first["signature"], second["signature"])
        self.assertEqual(first["family_id"], second["family_id"])

        reordered_reset = copy.deepcopy(reverse)
        reordered_reset["id"] = "PERK-17"
        reordered_reset["limits"]["reset_on"].reverse()
        self.append_definition("perks", reordered_reset)
        self.reject_without_write(
            "register", "--ability", "PERK-17", "--owner", "designer",
            "--variant-of", "PERK-16",
            "--player-decision", "Use the same blast then slash chain with the same reset events.",
            "--difference", "The unordered reset event list is stored in a different order.",
        )
        self.invoke("validate")

    def test_meaningful_structural_variant_preserves_lineage_and_can_be_introduced(self) -> None:
        original = self.reserve()
        self.add_catalog_perk(change="decision")
        registration = self.register_variant()
        ability = registration["ability"]
        self.assertEqual(ability["id"], "PERK-15")
        self.assertEqual(ability["family_id"], original["family_id"])
        self.assertEqual(ability["variant_of"], "PERK-01")
        self.assertTrue(ability["player_decision"])
        variant = self.reserve(ability="PERK-15", level="A2-L1")
        self.assertEqual(variant["family_id"], original["family_id"])
        self.reject_reservation("PERK-15", "A3-L1")
        self.invoke("validate")

    def test_variant_requires_a_real_decision_note_and_existing_parent(self) -> None:
        self.add_catalog_perk(change="decision")
        self.reject_without_write(
            "register", "--ability", "PERK-15", "--owner", "designer",
            "--variant-of", "PERK-01", "--player-decision", "",
            "--difference", "Reload progress replaces finisher damage.",
        )
        self.reject_without_write(
            "register", "--ability", "PERK-15", "--owner", "designer",
            "--variant-of", "PERK-99",
            "--player-decision", "Spend ammo before completing the third slash.",
            "--difference", "Reload progress replaces finisher damage.",
        )

    def test_carried_perk_requires_committed_introduction_then_allows_later_acts(self) -> None:
        use = self.reserve(ability="PERK-02")
        self.reject_reservation("PERK-02", "A2-L1", kind="carryover", from_use=use["id"])
        self.invoke("record", "--use", use["id"], "--owner", use["owner"], "--status", "planned")
        self.invoke("record", "--use", use["id"], "--owner", use["owner"], "--status", "implemented")
        carryover = self.reserve(
            ability="PERK-02", level="A2-L1", owner="act-two-agent",
            kind="carryover", from_use=use["id"],
        )
        self.assertEqual(carryover["kind"], "carryover")
        self.assertEqual(carryover["from_use"], use["id"])
        self.reject_reservation("PERK-02", "A3-L1")
        self.invoke("validate")

    def test_carryover_cannot_point_to_other_ability_or_earlier_level(self) -> None:
        intro = self.commit_introduction("PERK-01", level="A2-L2")
        self.reject_reservation("PERK-02", "A3-L1", kind="carryover", from_use=intro["id"])
        self.reject_reservation("PERK-01", "A1-L1", kind="carryover", from_use=intro["id"])
        self.reject_reservation("PERK-01", "A2-L2", kind="carryover", from_use=intro["id"])
        self.reject_reservation("PERK-01", "A3-L1", kind="carryover")

    def test_temporary_powerups_cannot_be_marked_as_carried_equipment(self) -> None:
        intro = self.commit_introduction("POWER-01")
        self.reject_reservation("POWER-01", "A2-L1", kind="carryover", from_use=intro["id"])
        self.reject_reservation("POWER-01", "A2-L1")

    def test_unknown_levels_and_missing_or_escaping_sources_are_rejected(self) -> None:
        for level in ("A4-L1", "A1-L99", "A1-O99", "act_1_level_1"):
            with self.subTest(level=level):
                self.reject_reservation("PERK-01", level)
        for source in ("docs/missing.md", "../outside.md", str(self.root / SOURCE)):
            with self.subTest(source=source):
                self.reject_without_write(
                    "reserve", "--ability", "PERK-01", "--level", "A1-L1",
                    "--owner", "agent", "--purpose", "Test untraceable placement.",
                    "--source", source,
                )
        self.assertEqual(self.uses(), [])


if __name__ == "__main__":
    unittest.main()
