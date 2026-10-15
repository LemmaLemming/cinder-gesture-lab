"""Read only explicitly indexed A3-L2 logs/records; never recreate a packet."""
from pathlib import Path
import datetime
import hashlib
import json
import re

ROOT = Path.cwd()
OUT = ROOT / ".cinder/a3-l2-legacy-fixture-prepare-20261015"
INDEXES = (
    "assets/acts/act3/evidence/A3-L2-root-scaffold/index.json",
    "assets/acts/act3/evidence/A3-L2-crescent-rule/index.json",
    "docs/development/evidence/act3-l2-root-registration/index.json",
)
decoder = json.JSONDecoder()


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def exact_envelopes(text):
    seen = set()
    for marker in re.finditer(r'"exact-json-1"', text):
        start = text.rfind("{", max(0, marker.start() - 200), marker.start())
        if start < 0 or start in seen:
            continue
        seen.add(start)
        try:
            value, length = decoder.raw_decode(text[start:])
        except ValueError:
            continue
        if not isinstance(value, dict) or value.get("api_revision") != "exact-json-1":
            continue
        wire = text[start:start + length]
        yield start, wire, value


indexes, inspected, candidates = [], [], []
for name in INDEXES:
    path = ROOT / name
    raw = path.read_bytes()
    index = json.loads(raw)
    indexes.append({"path": name, "sha256": sha(raw), "bytes": len(raw),
                    "scope": index.get("scope", index.get("execution_provenance")),
                    "declared_artifact_count": len(index.get("artifacts", []))})
    by_path = {row["path"]: row for row in index.get("artifacts", [])}
    # No recursive walk. Only log/report/record leaves declared by known index.
    for relative, declared in by_path.items():
        selected = (relative.startswith("logs/") and relative.endswith(".log")) or (
            relative.startswith("records/") and relative.endswith(".json"))
        if not selected:
            continue
        actual = path.parent / relative
        data = actual.read_bytes()
        text = data.decode("utf-8")
        envelope_rows = []
        for offset, wire, value in exact_envelopes(text):
            typed = value.get("value")
            tag = typed[0] if isinstance(typed, list) and typed else None
            full_parent = tag == "dictionary" and "act3-living-forest-level-1" in wire
            envelope_rows.append({"byte_offset": len(text[:offset].encode("utf-8")),
                                  "bytes": len(wire.encode("utf-8")),
                                  "sha256": sha(wire.encode("utf-8")),
                                  "root_tag": tag,
                                  "contains_original_full_parent_api1": full_parent})
            if full_parent:
                # Raw substring only, never decode/re-encode original packet.
                saved = "literal-exact-candidate-%02d.json" % (len(candidates) + 1)
                OUT.mkdir(parents=True, exist_ok=True)
                (OUT / saved).write_bytes(wire.encode("utf-8"))
                candidates.append({"extracted_path": saved, "producer_log": str(actual.relative_to(ROOT)),
                                   "producer_sha256": sha(data), **envelope_rows[-1],
                                   "status": "candidate literal only; native reader and whole-packet shape not executed"})
        inspected.append({"path": str(actual.relative_to(ROOT)), "sha256": sha(data),
                          "bytes": len(data), "declared_sha256": declared.get("sha256"),
                          "index_sha256_join": declared.get("sha256") == sha(data),
                          "declared_bytes_join": declared.get("bytes", len(data)) == len(data),
                          "exact_envelopes": envelope_rows,
                          "packet_or_report_markers": {key: key in text for key in (
                              "payload_json", "format_version", "exact_snapshot", "exact_local",
                              "completed_session", "REPORT path=", "report=")},
                          "diagnostic_only_context_present": "FIRST FAILURE PUBLIC CONTEXT:" in text})

result = {
    "kind": "a3-l2-literal-legacy-payload-search", "schema_version": 1,
    "observed_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "requested_path_absent": "docs/development/evidence/A3-L2-registration",
    "actual_root_registration_archive": "docs/development/evidence/act3-l2-root-registration",
    "indexes": indexes, "explicit_indexed_report_leaves_inspected": inspected,
    "all_indexed_report_hashes_join": all(row["index_sha256_join"] and row["declared_bytes_join"] for row in inspected),
    "literal_api1_parent_candidates": candidates,
    "candidate_count": len(candidates),
    "result": "No literal full-parent API1 packet was present in the inspected indexed report leaves." if not candidates else "Literal candidates retained without re-encoding; no native compatibility claim.",
    "not_inferred": ["A successful Save/Continue/Retry assertion is not a retained save payload",
                     "A decimal-formatted public diagnostic is not an Exact snapshot or original Store byte stream",
                     "No old snapshot is reconstructed from current state, source constants, assertions or numeric fragments",
                     "No absent user:// payload or private worker/frozen-bank content is claimed searched"],
    "execution": "No Godot, source/worker/production/canonical changes or engine queue activity. Only private output folder written.",
    "provenance_limits": "Original index scope/status/exit claims remain their original attribution. This review independently joins only actual inspected archive bytes to their declared hashes. No complete source graph or frozen-bank/UID census."
}
OUT.mkdir(parents=True, exist_ok=True)
(OUT / "OBSERVATIONS.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps({"indexes": len(indexes), "report_leaves": len(inspected),
                  "all_hash_joins": result["all_indexed_report_hashes_join"],
                  "candidate_count": len(candidates),
                  "whole_packet_report_markers": [{"path": row["path"], "markers": row["packet_or_report_markers"]}
                                                   for row in inspected if any(row["packet_or_report_markers"].values())],
                  "exact_envelope_logs": [{"path": row["path"], "count": len(row["exact_envelopes"]),
                                            "root_tags": sorted({str(x["root_tag"]) for x in row["exact_envelopes"]})}
                                           for row in inspected if row["exact_envelopes"]],
                  "observations_sha256": sha((OUT / "OBSERVATIONS.json").read_bytes())}, indent=2))
