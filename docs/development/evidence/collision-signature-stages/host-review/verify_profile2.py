#!/usr/bin/env python3
"""Host-only supplement for immutable profile2 evidence; never starts Godot.

The native diagnostic adapter is deliberately tagged. Unpack only requested
Dictionary levels; other native types remain opaque and keep their type tags.
"""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import math
import os
import re
import struct

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
PROFILE = ROOT / ".cinder/collision-signature-profile"
JOB = PROFILE / "jobs/collision-signature-profile2"
PINS = {
    "result.json": "017afac81e9faa9460db2182c08be25fdc4fe2794b493867ed9f0a04d2f9cacf",
    "manifest.json": "aee66deeb1c44ee24425c71451ec593a6c2e2c24481498224fcc243526144c37",
    "raw.log": "d9ea213c109c15734364977a832d4fd7fcd3b26fc03e4a75b05b38da727d7d08",
    "wrapper.log": "c58dfbda273fb9714ab2430e86515488b44ecde62a3589c97bd95c3c702bc52d",
    "observed/focused-native.exact.json": "9d979a826f79bb8598128c57af7c03159bf31c45854027d2c5841833ef6cab81",
    "observed/complete19-packets.exact.json": "c2d139a2ba4371af7fff50b94e4a0317787e1de5601709c04787965d9120e568",
}
ACTORS = {"breathing-1", "breathing-2", "breathing-3", "court-1", "court-2", "court-3", "court-guard", "lone-guard", "umbrella-1", "umbrella-2", "umbrella-3", *[f"crossed-{i}" for i in range(1, 9)]}
REFERENCES = {f"crossed-{i}" for i in range(1, 9)}
FOCUSED_KEYS = {"paused", "shell_id", "shell_script", "level_id", "level_script", "hero_id", "hero_script", "controller_id", "controller_script", "controller_clock_bits", "player_clock_bits", "input", "aim", "camera_pose", "camera_size", "camera_projection", "camera_focus", "hud_safe", "attempts", "menu", "beat_index", "room_stage", "completed_beats", "sources"}
SOURCE_KEYS = {"node_id", "script_id", "pose", "velocity", "grounded", "collision_id", "shape_id", "collision_pose", "disabled"}


def sha(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        assert key not in result, "Duplicate raw JSON key"
        result[key] = value
    return result


def strict_json(text):
    def reject_constant(value):
        raise AssertionError("Nonstandard nonfinite JSON constant: " + value)
    return json.loads(text, object_pairs_hook=unique_object, parse_constant=reject_constant)


def decode_exact_bytes(raw):
    assert len(raw) <= 8 * 1024 * 1024, "Exact byte bound"
    envelope = strict_json(raw)
    assert type(envelope) is dict and set(envelope) == {"api_revision", "schema_version", "value"}
    assert envelope["api_revision"] == "exact-json-1" and type(envelope["schema_version"]) is int and envelope["schema_version"] == 1
    budget = [262144]

    def decode(node, depth=0):
        budget[0] -= 1
        assert budget[0] >= 0 and depth <= 64, "Exact structural bound"
        assert type(node) is list and node and type(node[0]) is str
        kind = node[0]
        if kind == "null":
            assert len(node) == 1
            return None
        assert len(node) == 2
        value = node[1]
        if kind == "boolean":
            assert type(value) is bool
            return value
        if kind == "string":
            assert type(value) is str
            return value
        if kind == "integer":
            assert type(value) is str and re.fullmatch(r"-?(?:0|[1-9][0-9]*)", value)
            parsed = int(value)
            assert str(parsed) == value and abs(parsed) <= 9007199254740991
            return parsed
        if kind == "float64":
            assert type(value) is str and re.fullmatch(r"[0-9a-f]{16}", value)
            parsed = struct.unpack("<d", bytes.fromhex(value))[0]
            assert math.isfinite(parsed)
            return parsed
        assert type(value) is list and len(value) <= 16384
        if kind == "array":
            return [decode(child, depth + 1) for child in value]
        assert kind == "dictionary"
        result, keys = {}, []
        for entry in value:
            assert type(entry) is list and len(entry) == 2 and type(entry[0]) is str and entry[0] not in result
            keys.append(entry[0])
            result[entry[0]] = decode(entry[1], depth + 1)
        assert keys == sorted(keys), "Canonical Exact dictionary order"
        return result
    return decode(envelope["value"])


def decode_exact(path):
    return decode_exact_bytes(Path(path).read_bytes())


def unpack_native_dictionary(value, label="native Dictionary", required=None):
    """Strict one-level view; never normalize native Vector/Object/etc tags."""
    assert type(value) is dict and set(value) == {"native_type", "entries"}, label
    assert value["native_type"] == "Dictionary", label
    entries = value["entries"]
    assert type(entries) is list and len(entries) <= 16384, label
    result = {}
    for entry in entries:
        assert type(entry) is list and len(entry) == 2 and type(entry[0]) is str, label
        assert entry[0] not in result, label + ": duplicate native entry"
        result[entry[0]] = entry[1]
    if required is not None:
        assert set(result) == set(required), label + ": missing/extra keys"
    return result


def exact_same(left, right):
    if type(left) is not type(right):
        return False
    if type(left) is float:
        return struct.pack("<d", left) == struct.pack("<d", right)
    if type(left) is dict:
        return set(left) == set(right) and all(exact_same(left[k], right[k]) for k in left)
    if type(left) is list:
        return len(left) == len(right) and all(exact_same(a, b) for a, b in zip(left, right))
    return left == right


def float_bits(value):
    assert type(value) is float and math.isfinite(value)
    return struct.pack("<d", value).hex()


def native_id(value):
    assert type(value) is str and re.fullmatch(r"-?(?:0|[1-9][0-9]*)", value)
    parsed = int(value)
    assert str(parsed) == value and -(2**63) <= parsed < 2**63 and parsed != 0


def vector(value, kind="Vector3"):
    assert type(value) is dict and set(value) == {"native_type", "components"} and value["native_type"] == kind
    components = value["components"]
    assert type(components) is list and len(components) == 3
    assert all(type(x) is float and math.isfinite(x) for x in components)
    return components


def transform(value):
    assert type(value) is dict and set(value) == {"native_type", "basis", "origin"} and value["native_type"] == "Transform3D"
    basis, origin = value["basis"], value["origin"]
    assert type(basis) is list and len(basis) == 3 and all(type(row) is list and len(row) == 3 for row in basis)
    assert all(type(x) is float and math.isfinite(x) for row in basis for x in row)
    assert type(origin) is list and len(origin) == 3 and all(type(x) is float and math.isfinite(x) for x in origin)
    return value


def trace_rows(text, stage):
    rows = []
    for line in text.splitlines():
        marker = line.find("{")
        if marker < 0:
            continue
        try:
            row = strict_json(line[marker:])
        except json.JSONDecodeError:
            continue
        if type(row) is dict and row.get("stage") == stage:
            rows.append(row)
    assert len(rows) == 1, "Exactly one " + stage
    return rows[0]


def active_uids():
    rows = []
    for directory, dirs, files in os.walk(ROOT):
        parent = Path(directory)
        if parent != ROOT and (parent / ".gdignore").exists():
            dirs[:] = []
            continue
        dirs[:] = [name for name in dirs if name not in {".git", ".godot", ".tools", ".cinder", "exports", "captures", "__pycache__"}]
        for name in files:
            if name.endswith(".uid"):
                path = parent / name
                rows.append({"path": str(path.relative_to(ROOT)), "sha256": sha(path), "uid": path.read_text().strip(), "bytes": path.stat().st_size, "mode": path.stat().st_mode & 0o777})
    return sorted(rows, key=lambda row: row["path"])


def self_test():
    cases = [
        lambda: unpack_native_dictionary({"native_type": "Dictionary", "entries": [["a", 1], ["a", 2]]}),
        lambda: unpack_native_dictionary({"native_type": "Array", "entries": []}),
        lambda: unpack_native_dictionary({"native_type": "Dictionary", "entries": [[{"native_type": "StringName", "text": "a"}, 1]]}),
        lambda: unpack_native_dictionary({"native_type": "Dictionary", "entries": [["a", 1, 2]]}),
        lambda: unpack_native_dictionary({"native_type": "Dictionary", "entries": []}, required={"paused"}),
        lambda: strict_json('{"a":1,"a":2}'),
        lambda: decode_exact_bytes(b'{"api_revision":"exact-json-1","schema_version":true,"value":["null"]}'),
        lambda: decode_exact_bytes(b'{"api_revision":"exact-json-1","schema_version":1,"value":["float64","000000000000f07f"]}'),
    ]
    for case in cases:
        try:
            case()
        except AssertionError:
            continue
        raise AssertionError("A host negative unexpectedly passed")
    assert not exact_same(0.0, -0.0) and not exact_same(1, 1.0)
    return {"negative_cases_refused": len(cases), "signed_zero_and_scalar_type_distinctions": True}


def verify():
    pinned = {name: sha(JOB / name) for name in PINS}
    assert pinned == PINS, "Immutable original evidence hash drift"
    result = strict_json((JOB / "result.json").read_text())
    manifest = strict_json((JOB / "manifest.json").read_text())
    assert result["returncode"] == 0 and result["clean"] is True and result["footers"] == [["25", "0"]]
    assert result["successful_scope"] is False and result["witness_verification_error"] == "'sources'"
    assert result["closure_error"] == "" and all(result[k] is True for k in ["source_archive_current_exact_at_closure", "active_uids_unchanged", "engine_binary_verified_at_closure"])
    assert all(type(v) is int and v == 0 for row in result["diagnostics"].values() for v in row.values())
    assert result["manifest_sha256"] == pinned["manifest.json"] and result["source_count"] == len(manifest["files"]) == 803
    raw = (JOB / "raw.log").read_text()
    wrapper = (JOB / "wrapper.log").read_text()
    for stream, filename in [("native", "raw.log"), ("wrapper", "wrapper.log")]:
        record = result["streams"][stream]
        assert record["sha256"] == pinned[filename] and record["bytes"] == (JOB / filename).stat().st_size
        text = raw if stream == "native" else wrapper
        assert not re.search(r"SCRIPT ERROR|Parse Error|Compile Error|(?m:^ERROR:|^WARNING:)|FAIL:|leaked|Orphan StringName|unclaimed", text, re.I)
        assert re.findall(r"Collision signature profile: (\d+) checks, (\d+) failures;", text) == [("25", "0")]
    trace = trace_rows(raw, "collision_signature_profile_paused_witness")
    interval = trace_rows(raw, "collision_signature_profile_interval")
    assert exact_same(trace, trace_rows(wrapper, "collision_signature_profile_paused_witness"))
    assert exact_same(interval, trace_rows(wrapper, "collision_signature_profile_interval"))
    witnesses = {}
    decoded = {}
    for key, filename, prefix in [("native", "focused-native.exact.json", "native"), ("packets", "complete19-packets.exact.json", "packet")]:
        path = JOB / "observed" / filename
        expected = trace[prefix + "_file"]
        assert set(expected) == {"path", "bytes", "sha256", "exact_decoded_and_reencoded"}
        assert expected["path"] == "res://" + str(path.relative_to(ROOT)) and expected["exact_decoded_and_reencoded"] is True
        assert path.stat().st_size == expected["bytes"] == trace[prefix + "_bytes"]
        assert sha(path) == expected["sha256"] == trace[prefix + "_sha256"]
        decoded[key] = decode_exact(path)
        witnesses[key] = {"path": str(path), "bytes": path.stat().st_size, "sha256": sha(path), "host_strict_exact_decode": True, "native_printed_byte_sha_join": True}
    packets, native = decoded["packets"], decoded["native"]
    assert type(packets) is dict and set(packets) == {"actors", "player", "scheduler"} and set(packets["actors"]) == ACTORS
    assert type(native) is dict and set(native) == {"references", "diagnostics", "focused_native", "scope"}
    assert type(native["references"]) is dict and set(native["references"]) == REFERENCES
    focused = unpack_native_dictionary(native["focused_native"], "focused native", FOCUSED_KEYS)
    sources = unpack_native_dictionary(focused["sources"], "focused sources", ACTORS)
    assert focused["paused"] is True and trace["paused"] is True and focused["menu"] == "pause"
    assert focused["room_stage"] == trace["room_stage"] == "active" and focused["beat_index"] == trace["beat_index"] == 2
    assert focused["controller_clock_bits"] == trace["scheduler_clock_bits"] == float_bits(packets["scheduler"]["clock_s"])
    assert focused["player_clock_bits"] == trace["player_clock_bits"] == float_bits(packets["player"]["world_actions"]["clock_s"])
    assert packets["player"]["resources"]["hp"] == trace["hp"] == 100.0 and packets["player"]["resources"]["shells"] == trace["shells"] == 2
    assert packets["player"]["resources"]["dead"] is False
    for key in ["shell_id", "shell_script", "level_id", "level_script", "hero_id", "hero_script", "controller_id", "controller_script"]:
        native_id(focused[key])
    source_rows = {}
    grounded_differences = []
    for key in sorted(ACTORS):
        row = unpack_native_dictionary(sources[key], key, SOURCE_KEYS)
        for field in ["node_id", "script_id", "collision_id", "shape_id"]:
            native_id(row[field])
        pose = transform(row["pose"])
        transform(row["collision_pose"])
        velocity = vector(row["velocity"])
        assert type(row["grounded"]) is bool and type(row["disabled"]) is bool
        actor = packets["actors"][key]
        assert actor["source_id"] == key and exact_same(actor["motion"]["position"], pose["origin"])
        assert exact_same(actor["motion"]["velocity"], velocity) and type(actor["motion"]["grounded"]) is bool
        if actor["motion"]["grounded"] is not row["grounded"]:
            grounded_differences.append({"source_id": key, "packet_logical_grounded": actor["motion"]["grounded"], "native_is_on_floor": row["grounded"], "native_collision_disabled": row["disabled"], "packet_dormant": actor["dormant"]})
        source_rows[key] = {field: row[field] for field in ["node_id", "script_id", "collision_id", "shape_id", "disabled"]}
    assert len({row["node_id"] for row in source_rows.values()}) == 19 and len({row["collision_id"] for row in source_rows.values()}) == 19
    for key in sorted(REFERENCES):
        ref = native["references"][key]
        assert type(ref) is dict and set(ref) == {"descriptor", "fresh_environment", "fresh_body"}
        descriptor, environment = ref["descriptor"], ref["fresh_environment"]
        assert descriptor["source_id"] == key and re.fullmatch(r"[0-9a-f]{64}", descriptor["configuration_sha256"])
        assert set(environment) == {"world_signature", "floor_signature"} and type(ref["fresh_body"]) is dict and ref["fresh_body"]
        assert exact_same(descriptor["source_environment"]["world_signature"], environment["world_signature"])
        assert exact_same(descriptor["source_environment"]["floor_signature"], environment["floor_signature"])
    proof = strict_json((PROFILE / "statement-proof.json").read_text())
    restored = {row["path"]: row for row in proof["sources"]}
    archive_count = 0
    for row in manifest["files"]:
        archived = JOB / row["archived_path"]
        assert archived.resolve().is_relative_to((JOB / "source").resolve())
        assert archived.stat().st_size == row["bytes"] and sha(archived) == row["sha256"] and archived.stat().st_mode & 0o777 == row["mode"]
        current = ROOT / row["path"]
        assert current.resolve().is_relative_to(ROOT.resolve())
        original = restored.get(row["path"])
        assert sha(current) == (original["original_sha256"] if original else row["sha256"])
        assert current.stat().st_size == (original["original_bytes"] if original else row["bytes"]) and current.stat().st_mode & 0o777 == row["mode"]
        archive_count += 1
    assert len(manifest["uids"]) == 470 and active_uids() == manifest["uids"]
    engine = manifest["engine_binary"]
    assert engine == result["engine_binary"]
    engine_path = ROOT / engine["path"]
    assert str(engine_path.resolve()) == engine["absolute_path"] and engine_path.stat().st_size == engine["bytes"] and sha(engine_path) == engine["sha256"] and engine_path.stat().st_mode & 0o777 == engine["mode"]
    profile = interval["profile"]
    assert interval["physics_frames"] == 8 and interval["process_frames"] == 1 and interval["wall_us"] == 6092211 and interval["actor_identities_unchanged"] is True
    assert profile["selected_source_count"] == 8 and profile["stack_empty"] is True and profile["stack_fault"] is False and profile["overflow"] is False and profile["inherited_owner_sentinel"] == 0
    assert set(interval["per_source"]) == set(interval["per_source_counts"]) == REFERENCES
    methods = profile["methods"]
    assert methods["Route.collision_signature"]["calls"] == 2944
    for label, unit in profile["primitive_counts"].items():
        assert label in {"visited_nodes", "accepted_colliders", "extracted_shapes"} and unit["samples"] == 2944
        expected = 846 if label == "visited_nodes" else 10
        assert unit["min"] == unit["max"] == expected and unit["sum"] == expected * 2944
    for key in REFERENCES:
        assert interval["per_source"][key]["Route.collision_signature"]["calls"] == 368
        for label, unit in interval["per_source_counts"][key].items():
            expected = 846 if label == "visited_nodes" else 10
            assert unit == {"min": expected, "max": expected, "samples": 368, "sum": expected * 368}
    for label, total in methods.items():
        assert total["calls"] == sum(interval["per_source"][key][label]["calls"] for key in REFERENCES)
        assert total["inclusive_us"] == sum(interval["per_source"][key][label]["inclusive_us"] for key in REFERENCES)
        assert total["max_us"] == max(interval["per_source"][key][label]["max_us"] for key in REFERENCES)
    assert {name: sha(JOB / name) for name in PINS} == pinned, "Original evidence changed during host review"
    stages = {key: methods[key] for key in ["Collision.traversal_filtering", "Collision.collider_shape_extraction", "Collision.sorting", "Collision.codec_validation"]}
    return {
        "status": "SUPPLEMENTAL_HOST_WITNESS_VERIFICATION_PASS", "at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "native_rerun": False, "original_result_or_logs_modified": False,
        "original_wrapper": {"successful_scope": False, "witness_verification_error": result["witness_verification_error"], "qualification": "Original host wrapper exits1 under tools.py because it indexed the tagged native Dictionary as plain focused_native.sources; native child returned0 with25/0 clean. Original result remains unsuccessful."},
        "native_result": {"checks": 25, "failures": 0, "returncode": 0, "clean": True},
        "original_evidence_sha256": pinned, "witnesses": witnesses,
        "witness_joins": {"packet_actors": 19, "focused_native_actors": 19, "fresh_references": 8, "paused": True, "native_menu": "pause", "all_actor_pose_velocity_joins_exact": True, "scheduler_and_player_clock_bits_join": True, "source_rows": source_rows, "logical_vs_native_grounded_differences": grounded_differences, "grounded_qualification": "Preserved distinct fields: actor packet uses _grounded()/restored floor contact, while focused diagnostic deliberately records native is_on_floor(). No whole-state normalization or forced equality."},
        "custody": {"archived_files_verified": archive_count, "current_files_match_with_only_two_withdrawn_originals": True, "active_uid_rows_verified": 470, "engine_binary_sha_verified_without_execution": True, "restored_originals": {key: value["original_sha256"] for key, value in restored.items()}, "scope": manifest["scope"]},
        "interval": {"physics_frames": 8, "process_frames": 1, "wall_us": interval["wall_us"], "scheduler_elapsed_s": interval["scheduler_elapsed_s"], "player_elapsed_s": interval["player_elapsed_s"], "collision_calls": 2944, "visited_nodes_per_call": 846, "colliders_per_call": 10, "shapes_per_call": 10, "sequential_collision_stages": stages, "collision_inclusive": methods["Route.collision_signature"], "all_method_source_aggregates_verified": True},
        "retained_diagnostics": {"paused_campaign": native["diagnostics"]["campaign"], "measured_encounter": interval["encounter_error"], "qualification": "Host packet custody does not grant optical parent Save, current-view acceptance, arbitrary Script-state completeness or gameplay/FPS/optimization acceptance."},
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="supplement-result.json")
    args = parser.parse_args()
    output = HERE / args.output
    assert output.resolve().is_relative_to(HERE.resolve()) and not output.exists(), "New private report only"
    tests = self_test()
    report = verify()
    report["host_verifier_checks"] = tests
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"status": report["status"], "output": str(output), "sha256": sha(output), "native_rerun": False, "packet_actors": 19, "native_references": 8, "archived_files": 803, "active_uids": 470, "original_wrapper_successful_scope": False}))
