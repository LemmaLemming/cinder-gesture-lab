"""Queued, bounded A2-L2 focused arrangement checks through the canonical queue.

seal is host-only. Engine phases use dev.py shared-lock and child validation.
Evidence is retained under .cinder/weybridge-arrangement.
This named subset is not a global dependency, resource, UID or bank census.
"""
from pathlib import Path
import argparse
import contextlib
import datetime
import hashlib
import importlib.util
import json
import math
import os
import re
import struct
import sys
import time
import uuid
import zlib

ROOT = Path(__file__).resolve().parents[2]
HERE = ROOT / ".cinder" / "weybridge-arrangement"
HERE.mkdir(parents=True, exist_ok=True)
RUNNER = str(Path(__file__).resolve().relative_to(ROOT))
SCRIPTS = {
    "pure": "tests/act2_l2_arrangement_pure.gd", "legacy": "tests/act2_l2_arrangement_legacy.gd",
    "shell": "tests/act2_l2_arrangement_shell.gd", "pair": "tests/act2_l2_arrangement_pair.gd",
    "child-l3": "scripts/acts/act2/ruined_house.gd", "child-l4": "scripts/acts/act2/london_approaches.gd",
}
ENV = {name: "CINDER_A2_L2_ARRANGEMENT_" + name.upper() + "_REPORT" for name in ("pure", "legacy", "shell", "pair")}
PARSER_ONLY = {"child-l3", "child-l4"}
PAIR_SOURCE_ENV = "CINDER_A2_L2_ARRANGEMENT_PAIR_SOURCES"
PAIR_PORTRAIT_ENV = "CINDER_A2_L2_ARRANGEMENT_PAIR_PORTRAITS"
OWN_ENV = (*ENV.values(), PAIR_SOURCE_ENV, PAIR_PORTRAIT_ENV)
FIXTURE = "tests/acts/act2/fixtures/a2_l2_difficulty_legacy/"
FIXTURES = [FIXTURE + p + "-" + s + e for p in ("standard", "challenge") for s in ("entrance", "ray-warning") for e in (".exact.json", ".store.json")] + [FIXTURE + "PROVENANCE.json"]
SOURCE_FILES = [
    RUNNER, "scripts/dev/dev.py", "project.godot",
    "scenes/main.tscn", "scenes/player.tscn", "scenes/acts/act2/a2_l2.tscn",
    "scripts/game.gd", "scripts/player.gd", "scripts/equipment.gd",
    "scripts/effects.gd", "scripts/hud.gd", "scripts/campaign/level.gd",
    "scripts/acts/act2/horsell_common.gd", "scripts/acts/act2/horsell_sequence.gd",
    "scripts/acts/act2/weybridge.gd", "scripts/acts/act2/weybridge_sequence.gd",
    "scripts/acts/act2/weybridge_kit.gd", "scripts/acts/act2/heath_kit.gd",
    "scripts/acts/act2/weybridge_scout_actor.gd",
    "scripts/acts/act2/ray_scout_actor.gd", "scripts/acts/act2/ray_scout_visual.gd",
    "scripts/acts/act2/ray_scout_exchange.gd",
    "scripts/acts/act2/salvage_handler_actor.gd",
    "scripts/acts/act2/salvage_handler_visual.gd",
    "scripts/acts/act2/giant_foot_visual.gd",
    "scripts/combat/threat_scheduler.gd", "scripts/combat/lane_mechanism.gd",
    "scripts/combat/threat_geometry.gd", "scripts/combat/difficulty.gd",
    "scripts/combat/body_sweep.gd", "scripts/combat/encounter_arrangement.gd",
    "scripts/cues/threat_cue.gd", "scripts/cues/interaction_cue.gd",
    "scripts/campaign/snapshot_codec.gd", "scripts/campaign/exact_json.gd",
    "scripts/campaign/save_store.gd", "data/design/player_equipment.json",
    "data/design/difficulty_profiles.json", "data/campaign/act2/a2_l2_difficulty_arrangements.json",
    "scripts/campaign/shell.gd", "scripts/campaign/registry.gd", "scripts/campaign/attempts.gd",
    "scripts/settings/game_settings.gd", "scripts/ui/campaign_menu.gd",
    "scripts/ui/campaign_scenery.gd", "scripts/pixel_sprite.gd",
    "scripts/character/player_presentations.gd",
    "scripts/presentation/camera_framing.gd", "data/campaign/registry.json",
    *SCRIPTS.values(), *FIXTURES,
]
FILES = tuple(sorted(set(SOURCE_FILES) | {p + ".uid" for p in SOURCE_FILES if p.endswith(".gd")}))
NEW_UIDS = {SCRIPTS[name] + ".uid" for name in ("shell", "pair")}
TIMEOUT = 180
SCOPE = "Fixed named changed A2-L2 and directly affected source/UID subset plus eight literal original packets and provenance; not complete resource/global UID/dependency or bank closure. Optional actual renderer artifacts require separate optical review. No full route, campaign clear, all-kit, balance or performance credit."
SHELL_NATIVE_FILES = {
    SCRIPTS["shell"], "scenes/acts/act2/a2_l2.tscn", "scenes/main.tscn", "scenes/player.tscn",
    "scripts/game.gd", "scripts/player.gd", "scripts/campaign/shell.gd", "scripts/campaign/level.gd",
    "scripts/campaign/registry.gd", "scripts/campaign/attempts.gd", "scripts/campaign/save_store.gd",
    "scripts/campaign/exact_json.gd", "scripts/campaign/snapshot_codec.gd", "scripts/settings/game_settings.gd",
    "scripts/ui/campaign_menu.gd", "scripts/acts/act2/weybridge.gd", "scripts/acts/act2/weybridge_sequence.gd",
    "scripts/acts/act2/ray_scout_actor.gd", "scripts/acts/act2/ray_scout_exchange.gd",
    "scripts/acts/act2/salvage_handler_actor.gd", "scripts/combat/encounter_arrangement.gd",
    "scripts/combat/lane_mechanism.gd", "scripts/combat/threat_scheduler.gd",
    "data/campaign/act2/a2_l2_difficulty_arrangements.json", "data/campaign/registry.json",
}


def now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save(path, value, exclusive=False):
    if exclusive and path.exists():
        raise ValueError("Refuse overwriting retained evidence: " + str(path))
    temporary = path.with_name("." + path.name + "." + uuid.uuid4().hex)
    with temporary.open("x") as stream:
        json.dump(value, stream, indent=2, allow_nan=False)
        stream.write("\n")
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, path)


def observe():
    return {p: sha(ROOT / p) if (ROOT / p).is_file() else None for p in FILES}


def require(condition, message):
    if not condition:
        raise ValueError(message)


class Tee:
    def __init__(self, original, log):
        self.original, self.log = original, log

    def write(self, value):
        self.log.write(value)
        return self.original.write(value)

    def flush(self):
        self.log.flush()
        self.original.flush()


OBS_API_REVISION = "exact-json-1"
OBS_MAX_DEPTH = 64
OBS_MAX_ENTRIES = 16384
OBS_MAX_NODES = 262144
OBS_MAX_BYTES = 8 * 1024 * 1024
OBS_MAX_INTEGER = 9007199254740991
OBS_SCOPE = "Primitive Exact observation transport only; no saved-packet/native-state validation"


def _obs_native_string(value):
    if type(value) is not str or "\x00" in value:
        raise ValueError("Exact strings require native non-NUL text")
    try:
        value.encode("utf-8", errors="strict")
    except UnicodeError as error:
        raise ValueError("Exact string is not valid native UTF-8 text") from error
    return value


def _obs_unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("Duplicate raw JSON object key")
        result[key] = value
    return result


def _obs_reject_constant(token):
    raise ValueError("Nonfinite raw JSON constant: " + token)


def _obs_raw_budget(data):
    """Mirror Exact's pre-parser UTF-8 structural scan before allocation."""
    commas = []
    nodes = 0
    in_string = in_scalar = False
    index = 0
    while index < len(data):
        code = data[index]
        if in_string:
            if code == 92:
                if data[index:index + 6] == b"\\u0000":
                    raise ValueError("Native Godot String cannot contain U+0000")
                index += 2
                continue
            if code == 34:
                in_string = False
            index += 1
            continue
        if code == 34:
            in_string = True
            in_scalar = False
            nodes += 1
        elif code in (91, 123):
            commas.append(0)
            in_scalar = False
            nodes += 1
            if len(commas) > OBS_MAX_DEPTH * 3 + 4:
                raise ValueError("Exact wire exceeds raw depth budget")
        elif code in (93, 125):
            if commas:
                commas.pop()
            in_scalar = False
        elif code == 44:
            if commas:
                commas[-1] += 1
                if commas[-1] >= OBS_MAX_ENTRIES:
                    raise ValueError("Exact wire exceeds raw entry budget")
            in_scalar = False
        elif code in (58, 32, 9, 10, 13):
            in_scalar = False
        elif not in_scalar:
            in_scalar = True
            nodes += 1
        if nodes > OBS_MAX_NODES * 5 + 16:
            raise ValueError("Exact wire exceeds raw node budget")
        index += 1


def decode_observation_exact(raw):
    """Decode one bounded Exact string to primitives; ValueError on refusal.

    JSON schema1 and integral JSON schema1.0 both follow the native envelope.
    Duplicate raw object keys and invalid Unicode are rejected strictly;
    no numeric tolerance, type coercion or current gameplay policy is used.
    """
    if type(raw) is not str:
        raise ValueError("Exact wire must be a string")
    # Native String characters cannot encode to fewer than one UTF-8 byte.
    if len(raw) > OBS_MAX_BYTES:
        raise ValueError("Exact wire exceeds byte budget")
    try:
        data = raw.encode("utf-8", errors="strict")
    except UnicodeError as error:
        raise ValueError("Exact wire is not valid UTF-8") from error
    if len(data) > OBS_MAX_BYTES:
        raise ValueError("Exact wire exceeds byte budget")
    _obs_raw_budget(data)
    try:
        envelope = json.loads(raw, object_pairs_hook=_obs_unique_object,
                              parse_constant=_obs_reject_constant)
    except (ValueError, RecursionError) as error:
        raise ValueError("Malformed or unsupported Exact JSON wire") from error
    if (type(envelope) is not dict
            or set(envelope) != {"api_revision", "schema_version", "value"}
            or envelope["api_revision"] != OBS_API_REVISION
            or type(envelope["schema_version"]) not in (int, float)
            or envelope["schema_version"] != 1):
        raise ValueError("Unsupported closed Exact envelope")
    remaining = [OBS_MAX_NODES]

    def decode(node, depth=0):
        remaining[0] -= 1
        if (depth > OBS_MAX_DEPTH or remaining[0] < 0 or type(node) is not list
                or not node or type(node[0]) is not str):
            raise ValueError("Invalid Exact node/depth/node budget")
        kind = node[0]
        if kind == "null":
            if len(node) != 1:
                raise ValueError("Exact null tag has extra fields")
            return None
        if len(node) != 2:
            raise ValueError("Exact tag must have two fields")
        value = node[1]
        if kind == "boolean" and type(value) is bool:
            return value
        if kind == "string":
            return _obs_native_string(value)
        if kind == "integer":
            if (type(value) is not str
                    or len(value) > (17 if value.startswith("-") else 16)
                    or not re.fullmatch(r"0|-?[1-9][0-9]*", value)):
                raise ValueError("Exact integer requires canonical bounded decimal")
            number = int(value)
            if abs(number) > OBS_MAX_INTEGER:
                raise ValueError("Exact integer exceeds native supported range")
            return number
        if kind == "float64":
            if type(value) is not str or not re.fullmatch(r"[0-9a-f]{16}", value):
                raise ValueError("Exact float64 requires eight lowercase hex bytes")
            number = struct.unpack("<d", bytes.fromhex(value))[0]
            if not math.isfinite(number):
                raise ValueError("Exact float64 must be finite")
            return number
        if kind == "array":
            if type(value) is not list or len(value) > OBS_MAX_ENTRIES:
                raise ValueError("Invalid bounded Exact array")
            return [decode(child, depth + 1) for child in value]
        if kind == "dictionary":
            if type(value) is not list or len(value) > OBS_MAX_ENTRIES:
                raise ValueError("Invalid bounded Exact dictionary")
            result = {}
            for entry in value:
                if (type(entry) is not list or len(entry) != 2
                        or type(entry[0]) is not str or entry[0] in result):
                    raise ValueError("Exact dictionary requires unique string entries")
                result[_obs_native_string(entry[0])] = decode(entry[1], depth + 1)
            return result
        raise ValueError("Unsupported or mistyped Exact tag: " + kind)

    return decode(envelope["value"])


def retain_observational_exact(raw):
    """Retain raw receipt and decode its dictionary for caption joins only."""
    value = decode_observation_exact(raw)
    if type(value) is not dict:
        raise ValueError("Pair observation receipt root must be a dictionary")
    return {"raw_exact": raw,
            "raw_sha256": hashlib.sha256(raw.encode("utf-8")).hexdigest(),
            "value": value, "decoder_scope": OBS_SCOPE}


def native_source_join(report, expected_keys, at_lock, whole_set=False):
    before, after = report["source_before"], report["source_after"]
    require(type(before) is dict and before == after and set(before) == expected_keys, "Native fixed source before/after/keyset drift")
    normalized = {}
    for name, digest in before.items():
        require(type(name) is str, "Native source key must be a string")
        relative = name[6:] if name.startswith("res://") else name
        require(relative in at_lock and relative not in normalized and digest is not None and digest == at_lock[relative], "Native named source does not join at-lock pin: " + name)
        normalized[relative] = digest
    if whole_set:
        require(normalized == at_lock, "Pair native relative+res:self names must join the full fixed named wrapper subset")


def inspect_portraits(captures, directory, case):
    require(type(captures) is dict, "Malformed pair capture map")
    joined = {}
    for label, capture in captures.items():
        require(directory is not None and type(label) is str and type(capture) is dict, "Unexpected native portrait output")
        actor, phase = label.rsplit("-", 1)
        require(actor in ("shelter_scout", "shelter_handler") and phase in ("warning", "lock", "active", "recovery"), "Unexpected native portrait label")
        image = Path(capture["path"])
        require(image.is_absolute() and image.resolve().parent == directory and image.name == case["profile"] + "-" + case["kit"] + "-" + label + ".png" and image.is_file(), "Portrait must be exact selected output under its new explicit directory")
        data = image.read_bytes()
        require(len(data) >= 33 and data[:8] == b"\x89PNG\r\n\x1a\n" and data[8:16] == b"\x00\x00\x00\rIHDR", "Malformed native PNG header")
        width, height = struct.unpack(">II", data[16:24])
        require((width, height) == (540, 1170) and zlib.crc32(data[12:29]) & 0xFFFFFFFF == struct.unpack(">I", data[29:33])[0], "Actual PNG dimensions/IHDR CRC differ")
        require(hashlib.sha256(data).hexdigest() == capture["sha256"], "Actual native PNG hash mismatch")
        observation = decode_observation_exact(capture["observed_native_exact"])
        require(type(observation) is dict and observation.get("profile") == case["profile"] and observation.get("kit") == case["kit"], "Portrait observation profile/kit mismatch")
        parent = observation["parent"]
        source = parent["exchanges"][actor]
        require(parent["beat"] == "shelter_pair" and parent["active_ids"] == ["shelter_scout", "shelter_handler"] and source["status"] == "running" and source["phase"] == phase, "Actual observed source/phase does not join image label")
        joined[label] = {"path": str(image), "sha256": capture["sha256"], "dimensions_from_PNG": [width, height], "observation_receipt_sha256": hashlib.sha256(capture["observed_native_exact"].encode()).hexdigest(), "scope": "Native renderer and observation receipt join only; not packet validity, route or optical review."}
    if directory is not None:
        require({p.resolve() for p in directory.iterdir() if p.is_file()} == {Path(value["path"]).resolve() for value in joined.values()}, "Isolated portrait files differ from actual native reported captures")
    return joined


def inspect_shell_receipts(report):
    receipts = report["receipts"]
    require(type(receipts) is list, "Malformed Shell receipt list")
    expected_stages = ["initial public Continue exact entrance", "actual public Pause first-warning Save", "public newer Assisted preference preserves Challenge warning", "fresh independent public disk Continue exact warning", "actual public Retry exact entrance checkpoint"]
    if report["complete"]:
        require([r["stage"] for r in receipts] == expected_stages, "Complete Shell report lacks actual transport boundaries")
    for receipt in receipts:
        require(all(type(receipt[k]) is str and receipt[k] for k in ("exact_snapshot", "exact_session", "exact_story", "exact_checkpoint")), "Shell whole opaque Exact receipts must be nonempty")
        ids = receipt["actual_native_ids_decimal"]
        require(type(ids) is dict and len(ids) == 23 and all(type(v) is str and re.fullmatch(r"-?(0|[1-9][0-9]*)", v) and str(int(v)) == v and -(2**63) <= int(v) < 2**63 and int(v) != 0 for v in ids.values()) and len(set(ids.values())) == 23, "Shell actual signed64 identity decimal-string report is incomplete/noncanonical")
        disk = receipt["campaign_disk"]
        require(disk["reader_error"] == "" and disk["loaded_backup"] is False, "Shell independent disk observation failed")
        for name in ("campaign.json", "campaign.json.bak"):
            entry = disk[name]
            if entry is None:
                require(name.endswith(".bak"), "Shell primary cannot be absent")
                continue
            encoded = entry["raw"].encode("utf-8")
            require(len(encoded) == entry["bytes"] and hashlib.sha256(encoded).hexdigest() == entry["sha256"], "Shell raw disk byte/hash receipt mismatch")
            envelope = json.loads(entry["raw"])
            require(envelope["format_version"] == 2 and hashlib.sha256(envelope["payload_json"].encode()).hexdigest() == envelope["sha256"], "Shell format2 raw envelope checksum mismatch")
            if name == "campaign.json":
                require(envelope["generation"] == disk["generation"] and envelope["payload_json"] == receipt["exact_session"], "Shell raw primary does not join entire exact session/generation")


def inspect_report(path, test, raw, at_lock, case, portrait_dir):
    report = json.loads(path.read_text())
    rows = report["rows"]
    require(type(rows) is list and len(rows) > 0, "Native report has no actual rows")
    require(all(type(row) is dict and type(row.get("ok")) is bool and type(row.get("check")) is int for row in rows), "Malformed assertion row")
    require([r["check"] for r in rows] == list(range(1, len(rows) + 1)), "Native assertion row ordering")
    false_rows = [row for row in rows if row["ok"] is False]
    require(type(report["checks"]) is int and report["checks"] == len(rows), "Native checks differ from rows")
    require(type(report["failures"]) is int and report["failures"] == len(false_rows), "Native failures differ from false rows")
    require(report["first_failure"] == (false_rows[0] if false_rows else {}), "Native first failure differs from first false row")
    require(type(report["complete"]) is bool and type(report["success"]) is bool, "Native completion flags must be boolean")
    require(report["success"] == (report["complete"] and not false_rows), "Native success flag mismatch")
    require(re.findall(r"(?m)^" + ENV[test] + r" path=(.+) sha256=([0-9a-f]{64})$", raw) == [(str(path), sha(path))], "Report path/hash footer join failed")
    footer = {"pure": "Weybridge arrangement pure: ", "legacy": "A2-L2 arrangement legacy: ", "shell": "A2-L2 arrangement Shell: ", "pair": "A2-L2 arrangement pair: "}[test]
    suffix = "; units=" + str(len(report["receipts"])) if test == "legacy" else ("; hits=" + str(len(report["target_hits"])) if test == "pair" else "")
    expected = footer + str(len(rows)) + " checks/" + str(len(false_rows)) + " failures; complete=" + str(report["complete"]).lower() + suffix
    actual = [line for line in raw.splitlines() if line.startswith(footer)]
    require(actual == [expected], "Native counts/complete/footer join failed")
    if test == "legacy":
        before = report["source_before"]
        after = report["source_after"]
        require(type(before) is dict and before == after and len(before) > 0, "Native named sources differ")
        require(all(p.startswith("res://") and p[6:] in at_lock and h is not None and h == at_lock[p[6:]] for p, h in before.items()), "Native source observations do not join at-lock named sources")
        expected_native = {"res://" + p for p in FIXTURES} | {
            "res://" + SCRIPTS["legacy"], "res://scripts/game.gd", "res://scripts/player.gd",
            "res://scripts/campaign/level.gd", "res://scripts/campaign/save_store.gd",
            "res://scripts/campaign/exact_json.gd", "res://scripts/acts/act2/weybridge.gd",
            "res://scripts/acts/act2/ray_scout_actor.gd", "res://scripts/acts/act2/ray_scout_exchange.gd",
            "res://scripts/acts/act2/salvage_handler_actor.gd", "res://scripts/combat/lane_mechanism.gd",
            "res://data/campaign/act2/a2_l2_difficulty_arrangements.json", "res://scenes/acts/act2/a2_l2.tscn", "res://scenes/main.tscn",
        }
        require(set(before) == expected_native, "Native fixed observation keyset changed")
        if report["complete"]:
            names = {p + "-" + s for p in ("standard", "challenge") for s in ("entrance", "ray-warning")}
            require(len(report["receipts"]) == 4 and {r["name"] for r in report["receipts"]} == names, "Complete legacy report lacks four actual restored pairs")
    if test == "shell":
        native_source_join(report, {"res://" + p for p in SHELL_NATIVE_FILES}, at_lock)
        inspect_shell_receipts(report)
    capture_joins = {}
    if test == "pair":
        native_keys = (set(FILES) - {SCRIPTS["pair"]}) | {"res://" + SCRIPTS["pair"]}
        native_source_join(report, native_keys, at_lock, whole_set=True)
        require(report["profile"] == case["profile"] and report["kit_name"] == case["kit"], "Actual pair profile/kit differs from closed selected case")
        require(type(report["target_hits"]) is dict and type(report["phases"]) is dict and type(report["held_union_observation"]) is dict, "Pair actual scope observations malformed")
        if report["complete"]:
            targets = ("shelter_scout", "shelter_handler")
            require(set(report["target_hits"]) == set(targets), "Complete pair report lacks actual HP loss on both targets")
            for target in targets:
                hit = report["target_hits"][target]
                require(type(hit["hp_before"]) in (int, float) and type(hit["hp_after"]) in (int, float) and hit["hp_before"] > hit["hp_after"] > 0 and hit["proof_owner"] in targets, "Pair actual hit receipt mismatch")
                require(all(report["phases"].get(target, {}).get(phase) is True for phase in ("warning", "lock", "active", "recovery")), "Complete pair lacks all four actual observed target phases")
            if case["profile"] != "assisted":
                union = report["held_union_observation"]
                require(union.get("both_real_armed_nonrecovery") is True and set(union["source_reservation_ids"]) == set(targets) and len(set(union["source_reservation_ids"].values())) == 2, "Complete Standard/Challenge pair lacks distinct actual armed nonrecovery union")
                for target in targets:
                    source = union["sources"][target]
                    lease = [r for r in union["held"] if r["id"] == union["source_reservation_ids"][target]]
                    require(source["status"] == "running" and source["phase"] in ("warning", "lock", "active") and source["reservation_id"] == union["source_reservation_ids"][target] and len(lease) == 1 and lease[0]["armed"] is True and lease[0]["state"] in ("warning", "lock", "active") and lease[0]["profile_id"] == case["profile"], "Pair union report fields contradict actual required scope")
        capture_joins = inspect_portraits(report["captures"], portrait_dir, case)
        require(not report["complete"] or portrait_dir is None or bool(capture_joins), "Requested graphical pair run completed without actual PNG receipts")
    return {"path": str(path), "sha256": sha(path), "checks": len(rows), "failures": len(false_rows), "complete": report["complete"], "success": report["success"], "first_failure": report["first_failure"], "footer_rows_and_named_source_joins": True, "portrait_joins": capture_joins}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("phase", choices=("seal", "import", "parse", "run"))
    parser.add_argument("--test", choices=SCRIPTS, default="pure")
    parser.add_argument("--seal", type=Path, required=True)
    parser.add_argument("--profile", choices=("assisted", "standard", "challenge"))
    parser.add_argument("--kit", choices=("neutral", "short", "weak", "slow"))
    parser.add_argument("--portraitsdir", type=Path)
    args = parser.parse_args()
    for flag in ("--test", "--seal", "--profile", "--kit", "--portraitsdir"):
        if sum(value == flag or value.startswith(flag + "=") for value in sys.argv[1:]) > 1:
            parser.error("Repeated selector refused: " + flag)
    if args.test in PARSER_ONLY and args.phase != "parse":
        parser.error("Child inheritance roots are parse-only; no child native/import/seal case")
    if (args.profile is not None or args.kit is not None or args.portraitsdir is not None) and not (args.test == "pair" and args.phase == "run"):
        parser.error("Profile, kit and explicit graphical portraits directory apply only to pair run")
    case = {"profile": args.profile or "challenge", "kit": args.kit or "neutral"} if args.test == "pair" else {}
    portrait_dir = args.portraitsdir.resolve() if args.portraitsdir is not None else None
    if args.phase == "seal":
        record = {"schema_version": 1, "created": now(), "root": str(ROOT), "files": observe(), "scope": SCOPE, "host_only": True}
        missing = {p for p, h in record["files"].items() if h is None}
        require(missing <= NEW_UIDS, "Missing source outside explicitly new test UIDs: " + repr(missing - NEW_UIDS))
        save(args.seal, record, exclusive=True)
        print("A2_L2_SEAL", args.seal, sha(args.seal), len(FILES), "named observations; absent", sorted(missing), flush=True)
        return 0
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    label = args.test + ("-" + case["profile"] + "-" + case["kit"] if case else "")
    out = HERE / (args.phase + "-" + label + "-" + stamp + "-" + uuid.uuid4().hex[:8])
    out.mkdir(exist_ok=False)
    print("A2_L2_EVIDENCE", out, flush=True)
    start = time.monotonic()
    result = {"phase": args.phase, "test": args.test, "case": case, "portraits_directory": str(portrait_dir) if portrait_dir else None, "started": now(), "engine_started": False, "validation_returned": False, "closed": False, "passed": False, "scope": SCOPE}
    queue = {"queued": False, "acquired": False, "timeout_seconds_after_acquisition": TIMEOUT}
    code = 2
    save(out / "queue.json", queue)
    save(out / "result.json", result)
    with (out / "raw.log").open("x") as log, contextlib.redirect_stdout(Tee(sys.stdout, log)), contextlib.redirect_stderr(Tee(sys.stderr, log)):
        try:
            seal = json.loads(args.seal.read_text())
            require(seal["root"] == str(ROOT) and set(seal["files"]) == set(FILES), "Exact fixed named source seal required")
            expected = seal["files"]
            missing = {p for p, h in expected.items() if h is None}
            require(not missing or args.phase == "import" and missing <= NEW_UIDS, "Only selected import may add the two explicitly new test UIDs")
            if portrait_dir is not None:
                require(portrait_dir.is_relative_to(ROOT) and not portrait_dir.exists(), "Graphical portraits require an explicitly new directory inside the workspace")
                portrait_dir.mkdir(parents=True, exist_ok=False)
            save(out / "seal-used.json", seal)
            before = observe()
            save(out / "sources-before-queue.json", before)
            require(before == expected, "Pre-queue sealed source drift")
            blobs = out / "source-blobs"
            blobs.mkdir()
            retention = {}
            for p, h in expected.items():
                if h is None:
                    continue
                data = (ROOT / p).read_bytes()
                require(hashlib.sha256(data).hexdigest() == h, "Source drift during named retention: " + p)
                target = blobs / (h + ".txt")
                if not target.exists():
                    target.write_bytes(data)
                retention[p] = {"sha256": h, "blob": str(target.relative_to(out)), "origin": "captured-before-queue; at-lock/after-child joins required"}
            save(out / "source-retention.json", {"scope": SCOPE, "files": retention})
            spec = importlib.util.spec_from_file_location("cinder_a2_l2_arrangement_dev", ROOT / "scripts/dev/dev.py")
            dev = importlib.util.module_from_spec(spec)
            sys.modules[spec.name] = dev
            previous = sys.dont_write_bytecode
            try:
                sys.dont_write_bytecode = True
                spec.loader.exec_module(dev)
            finally:
                sys.dont_write_bytecode = previous
            env = dict(os.environ)
            for key in OWN_ENV:
                env.pop(key, None)
            report = out / "native-report.json"
            if args.phase == "run":
                env[ENV[args.test]] = str(report)
                if args.test == "pair":
                    env[PAIR_SOURCE_ENV] = json.dumps([p for p in FILES if p != SCRIPTS["pair"]])
                    if portrait_dir is not None:
                        env[PAIR_PORTRAIT_ENV] = str(portrait_dir)
            context = dev.ProjectContext(root=ROOT, environ=env)
            command = [str(dev.resolve_godot(context)), "--path", str(ROOT), "--log-file", str(out / "engine.log")]
            if portrait_dir is None:
                command += ["--headless"]
            if args.phase == "import":
                command += ["--editor", "--import"]
            else:
                command += ["--script", "res://" + SCRIPTS[args.test]]
                if args.phase == "parse":
                    command += ["--check-only"]
                elif args.test == "pair":
                    command += ["--", "--profile=" + case["profile"], "--kit=" + case["kit"]]
            save(out / "command.json", {"argv": command, "cwd": str(ROOT), "owned_child_environment": {k: env[k] for k in OWN_ENV if k in env}, "environment_scope": "Inherited context copied; only owned report/relative named-source list/explicit graphical output variables changed. No machine configuration changed or dumped.", "timeout_seconds_after_acquisition": TIMEOUT})
            queue.update(queued=True, queued_at=now(), lock=str(dev.shared_lock_path(ROOT)))
            save(out / "queue.json", queue)
            try:
                with dev.godot_lock(ROOT) as lock_fd:
                    queue.update(acquired=True, acquired_at=now())
                    save(out / "queue.json", queue)
                    at_lock = observe()
                    save(out / "sources-at-lock.json", at_lock)
                    require(at_lock == expected, "Queued sealed source drift")
                    save(out / "lifecycle.json", {"state": "RUNNING", "at": now(), "custody": "Canonical dev owns/waits only its direct child; no foreign process/lock operation."})
                    result.update(engine_started=True, engine_started_at=now())
                    save(out / "result.json", result)
                    returned = dev.run_validation(command, context, lock_fd, TIMEOUT, detect_godot_errors=True)
                    result.update(validation_returned=True, dev_return_code=returned, returned_at=now())
                    save(out / "result.json", result)
                    after = observe()
                    save(out / "sources-after-child.json", after)
                    changed = [p for p, h in expected.items() if h is not None and after[p] != h]
                    added = [p for p in missing if after[p] is not None]
                    result["source_delta"] = {"changed": changed, "added": sorted(added)}
                    require(not changed and (args.phase == "import" and set(added) == missing or not missing and not added), "Unexpected source change or selected import UID delta")
                    log.flush()
                    if args.phase == "run" and report.is_file():
                        # Retain actual partial/failing scope observations before
                        # any host join can refuse them. Never replace false rows.
                        result["retained_native_report"] = {"path": str(report), "sha256": sha(report), "bytes": report.stat().st_size, "scope": "Original raw report retained regardless of native or host validation result."}
                        try:
                            submitted = json.loads(report.read_text())
                            result["native_observations"] = {k: submitted[k] for k in ("checks", "failures", "first_failure", "complete", "success", "profile", "kit_name", "target_hits", "phases", "held_union_observation", "captures", "progression_events", "final_or_failed_observation") if k in submitted}
                        except Exception as exc:
                            result["native_report_decode_error"] = repr(exc)
                        result["native"] = inspect_report(report, args.test, (out / "raw.log").read_text(), at_lock, case, portrait_dir)
                    require(returned == 0, "Canonical owned validation returned " + str(returned))
                    if args.phase == "run":
                        require("native" in result and result["native"]["complete"] and result["native"]["success"] and result["native"]["failures"] == 0, "Actual complete passing report required with native0")
                    result["passed"] = True
                    code = 0
            finally:
                queue["lock_context_released_at"] = now()
                save(out / "queue.json", queue)
        except KeyboardInterrupt:
            result["error"] = "Interrupted; canonical dev owns only direct-child cleanup."
            code = 130
        except Exception as exc:
            result["error"] = repr(exc)
            print("A2-L2 focused wrapper failure:", repr(exc), flush=True)
        finally:
            closed = observe()
            save(out / "sources-at-runner-close.json", closed)
            if result.get("passed") and closed != after:
                result.update(passed=False, error="Named sources drifted after owned child returned")
                code = 2
            log.flush()
            raw = (out / "raw.log").read_text()
            errors = re.findall(r"(?m)^(?:ERROR:|SCRIPT ERROR:).*", raw)
            warnings = re.findall(r"(?m)^WARNING:.*", raw)
            result.update(closed=True, closed_at=now(), runner_return_code=code, wall_s_including_queue=time.monotonic() - start, raw_error_lines=errors, raw_warning_lines=warnings, raw_error_warning_free=not errors and not warnings)
            save(out / "result.json", result)
            save(out / "lifecycle.json", {"state": "CLOSED", "at": now(), "engine_started": result["engine_started"], "validation_returned": result["validation_returned"], "runner_code": code, "custody": "Canonical dev return0 confirms owned direct-child wait0. Nonzero may be synthetic script/resource/timeout failure; no process-group or foreign cleanup claim."})
            print("A2_L2_PHASE_CLOSED", code, flush=True)
    portrait_files = {}
    if portrait_dir is not None and portrait_dir.is_dir():
        # This newly owned output directory is the only external artifact
        # inventory. Retain even unreported/failed native capture bytes.
        portrait_files = {str(p): {"sha256": sha(p), "bytes": p.stat().st_size} for p in sorted(portrait_dir.iterdir()) if p.is_file()}
    save(out / "index.json", {"created_after_raw_log_close": True, "scope": SCOPE, "files": {str(p.relative_to(out)): {"sha256": sha(p), "bytes": p.stat().st_size} for p in sorted(out.rglob("*")) if p.is_file()}, "explicit_new_portrait_directory_files": portrait_files})
    return code


if __name__ == "__main__":
    raise SystemExit(main())
