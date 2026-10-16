"""Pure host parser/comparison for the unchanged authored113 native workload.

No filesystem, engine, timers, source changes or calibration at module load.
All costs are measured inclusive wall intervals, not exclusive CPU or FPS.
"""
import hashlib
import json
import math
import re

PROBES = ["replay_reservation_error", "authored_replay_source_error", "cue.projection_error", "renderer_guard.current_error", "cursor.snapshot_error"]
PHASES = ["warning", "lock", "active", "recovery"]
METRICS = ["inclusive_total_us", "mean_us", "p50_us", "p95_us", "max_us"]
SEMANTIC_KEYS = ["api_revision", "schema_version", "engine", "display_driver", "physics_ticks_per_second", "viewport_size", "native_output", "required_native_visuals", "simulation_start_s", "simulation_finish_s", "simulation_elapsed_s", "automatic_native_advances", "native_phases_observed", "actual_world_actions", "advance_samples_without_cost_or_absolute_frame_counters", "fixed_clock_probe_results_without_cost"]


def require(value, reason):
    if not value:
        raise ValueError(reason)


def number(value):
    return type(value) in (int, float) and math.isfinite(value)


def native_number(value):
    # Preserve the original fixture's Godot JSON.stringify default15-digit
    # transport. Integer microseconds remain exact; no report is rewritten.
    return float(format(value, ".15g"))


def summary(values):
    require(type(values) is list and values and all(type(value) is int and value >= 0 for value in values), "Nonnegative integer microsecond samples required")
    ordered = sorted(values)
    count = len(ordered)
    return {"count": count, "inclusive_total_us": sum(ordered), "mean_us": sum(ordered) / count,
            "p50_us": ordered[math.ceil(count * .50) - 1], "p95_us": ordered[math.ceil(count * .95) - 1], "max_us": ordered[-1]}


def summary_matches(actual, expected):
    return (type(actual) is dict and set(actual) == set(expected) and
            all(type(actual[key]) is int and actual[key] == expected[key] for key in expected if key != "mean_us") and
            number(actual["mean_us"]) and actual["mean_us"] == native_number(expected["mean_us"]))


def extract_profile(raw):
    lines = re.findall(r"^AUTHORED_ECHO_PROFILE_JSON (.+)$", raw, re.M)
    require(len(lines) == 1, "Exactly one actual native profile line required; missing/partial is not reconstructed")
    return lines[0]


def validate_profile(raw, payload):
    data = json.loads(payload, parse_constant=lambda value: (_ for _ in ()).throw(ValueError(value)))
    require(type(data) is dict and data.get("api_revision") == "test-only-authored-echo-performance-2" and type(data.get("schema_version")) is int and data["schema_version"] == 2, "Actual unchanged profile schema required")
    footers = re.findall(r"^Authored echo performance smoke: (\d+) checks, (\d+) failures; (.+)$", raw, re.M)
    require(footers == [("113", "0", "native-only first-cycle measurement")], "Actual unchanged113/0 footer required")
    labels = re.findall(r"^PASS: (.+)$", raw, re.M)
    require(len(labels) == 113 and not re.search(r"^(?:FAIL:|ERROR: FAIL)", raw, re.M), "Actual113 printed assertion rows required; no synthesized structured row array")
    samples = data.get("advance_samples")
    require(type(samples) is list and len(samples) == 73, "Unchanged73 actual advances required")
    last_clock = -1.0
    for sample in samples:
        require(type(sample) is dict and type(sample.get("automatic_native_tick")) is bool and sample.get("accepted") is True,
                "Actual accepted automatic/manual receipt required")
        require(all(type(sample.get(key)) is int and sample[key] >= 0 for key in ["start_us", "finish_us", "inclusive_us", "physics_frame", "process_frame", "event_count"]) and
                sample["finish_us"] - sample["start_us"] == sample["inclusive_us"], "Actual integer timing/frame samples required")
        require(number(sample.get("clock_s")) and sample["clock_s"] >= last_clock and sample.get("phase") in PHASES, "Real native clocks must remain monotonic and four-phase bounded")
        last_clock = sample["clock_s"]
    automatic = [sample for sample in samples if sample["automatic_native_tick"]]
    manual = [sample for sample in samples if not sample["automatic_native_tick"]]
    require(len(automatic) == 72 and type(data.get("automatic_native_advances")) is int and data["automatic_native_advances"] == 72 and len(manual) == 1,
            "Unchanged72 automatic plus1 separate manual advance required")
    automatic_summary = summary([sample["inclusive_us"] for sample in automatic])
    require(summary_matches(data.get("advance_cost_summary_us"), automatic_summary), "Automatic summary must join raw samples")
    phase_summaries = {phase: summary([sample["inclusive_us"] for sample in automatic if sample["phase"] == phase]) for phase in PHASES}
    require(type(data.get("advance_phase_summary_us")) is dict and set(data["advance_phase_summary_us"]) == set(PHASES) and
            all(summary_matches(data["advance_phase_summary_us"][phase], phase_summaries[phase]) for phase in PHASES), "Four phase summaries must join raw automatic samples")
    require(type(data.get("native_phases_observed")) is list and set(data["native_phases_observed"]) == set(PHASES), "Actual four-phase source receipts required")
    require(data.get("required_native_visuals") == 1 and data.get("physics_ticks_per_second") == 60 and
            data.get("viewport_size") == [270, 585] and data.get("native_output") == [540, 1170], "Unchanged one-visual native context required")
    actions = data.get("actual_world_actions")
    require(type(actions) is list and [row.get("kind") for row in actions] == ["dash", "dash", "primary"], "Actual two routed dashes plus ordinary primary required")
    require(all(number(row.get("started_at_s")) and number(row.get("completed_at_s")) and row["completed_at_s"] >= row["started_at_s"] for row in actions) and
            actions[-1].get("hits") == 1 and actions[-1].get("damage") == 20, "Original completed native actions/20-damage primary required")
    probes = data.get("separate_fixed_clock_guard_probes")
    require(type(probes) is list and len(probes) == 15 and
            [(row.get("repetition"), row.get("call")) for row in probes] == [(repetition, api) for repetition in range(3) for api in PROBES], "Exactly three ordered same-clock probes for each of five APIs required")
    fixed_clock = probes[0].get("fixed_clock_s")
    require(number(fixed_clock), "Actual fixed probe clock required")
    for probe in probes:
        require(probe.get("scope") == "separate_pure_probe_not_nested_native_advance" and probe.get("accepted") is True and probe.get("error") == "" and
                probe.get("fixed_clock_s") == fixed_clock and probe.get("clock_after_s") == fixed_clock, "Probe must stay separate, successful and at its actual unchanged clock")
        require(all(type(probe.get(key)) is int and probe[key] >= 0 for key in ["start_us", "finish_us", "inclusive_us"]) and
                probe["finish_us"] - probe["start_us"] == probe["inclusive_us"], "Original integer per-call probe timings required")
    probe_summaries = {api: summary([row["inclusive_us"] for row in probes if row["call"] == api]) for api in PROBES}
    require(type(data.get("separate_fixed_clock_probe_summary_us")) is dict and set(data["separate_fixed_clock_probe_summary_us"]) == set(PROBES) and
            all(summary_matches(data["separate_fixed_clock_probe_summary_us"][api], probe_summaries[api]) for api in PROBES), "Probe summaries must join their three raw calls")
    require(all(type(data.get(key)) is int and data[key] >= 0 for key in ["wall_start_us", "wall_finish_us", "wall_elapsed_us", "admission_projection_bind_inclusive_us", "separate_fixed_clock_probe_elapsed_us"]) and
            data["wall_finish_us"] - data["wall_start_us"] == data["wall_elapsed_us"], "Original actual wall/admission/probe intervals required")
    require(all(number(data.get(key)) for key in ["simulation_start_s", "simulation_finish_s", "simulation_elapsed_s"]) and
            native_number(data["simulation_finish_s"] - data["simulation_start_s"]) == data["simulation_elapsed_s"] and
            abs(data["simulation_elapsed_s"] - 1.2) <= 1e-9, "Unchanged1.2s native simulation interval required")
    joined = {"checks": 113, "failures": 0, "functional_complete": True, "printed_pass_count": len(labels),
              "printed_assertion_labels": labels, "native_structured_row_array": False,
              "profile_payload_sha256": hashlib.sha256(payload.encode()).hexdigest(),
              "automatic": automatic_summary, "phases": phase_summaries, "manual": summary([manual[0]["inclusive_us"]]), "probes": probe_summaries,
              "counter_scope": "72 actual automatic advances,1 separate manual advance,15 separately measured fixed-clock calls. No nested production call counts or exclusive CPU claim."}
    return data, joined


def semantic_projection(data):
    fixed = {key: data[key] for key in SEMANTIC_KEYS if key in data}
    fixed["advance_samples_without_cost_or_absolute_frame_counters"] = [{key: row[key] for key in ["clock_s", "automatic_native_tick", "phase", "accepted", "event_count"]} for row in data["advance_samples"]]
    fixed["fixed_clock_probe_results_without_cost"] = [{key: row[key] for key in ["call", "repetition", "fixed_clock_s", "clock_after_s", "accepted", "error", "scope"]} for row in data["separate_fixed_clock_guard_probes"]]
    return json.dumps(fixed, sort_keys=True, ensure_ascii=True, allow_nan=False, separators=(",", ":"))


def comparison(original, candidate):
    def delta(left, right):
        return {"original_ms": left / 1000.0, "candidate_ms": right / 1000.0, "candidate_minus_original_ms": (right - left) / 1000.0,
                "percent_change": (right / left - 1.0) * 100.0 if left else None,
                "original_us": left, "candidate_us": right}
    def group(left, right):
        require(left["count"] == right["count"], "Cohort sample counts differ; no metric fishing or replacement run")
        return {"count_each": left["count"], "metrics": {metric: delta(left[metric], right[metric]) for metric in METRICS}}
    a = [row for row in original["advance_samples"] if row["automatic_native_tick"]]
    b = [row for row in candidate["advance_samples"] if row["automatic_native_tick"]]
    result = {"schema_version": 1, "ordered_pair": "original first, candidate second; exactly one cell each",
              "automatic_advance": group(summary([row["inclusive_us"] for row in a]), summary([row["inclusive_us"] for row in b])),
              "phase_automatic_advance": {phase: group(summary([row["inclusive_us"] for row in a if row["phase"] == phase]), summary([row["inclusive_us"] for row in b if row["phase"] == phase])) for phase in PHASES},
              "separate_manual_advance": group(summary([row["inclusive_us"] for row in original["advance_samples"] if not row["automatic_native_tick"]]), summary([row["inclusive_us"] for row in candidate["advance_samples"] if not row["automatic_native_tick"]])),
              "separate_fixed_clock_probe_calls": {api: group(summary([row["inclusive_us"] for row in original["separate_fixed_clock_guard_probes"] if row["call"] == api]), summary([row["inclusive_us"] for row in candidate["separate_fixed_clock_guard_probes"] if row["call"] == api])) for api in PROBES},
              "actual_native_fixture_intervals": {key: delta(original[key], candidate[key]) for key in ["wall_elapsed_us", "admission_projection_bind_inclusive_us", "separate_fixed_clock_probe_elapsed_us"]},
              "native_simulation_elapsed_s": {"original": original["simulation_elapsed_s"], "candidate": candidate["simulation_elapsed_s"]},
              "candidate_accepted": False, "causal_gain_claim": False, "steady_fps_or_cpu_claim": False,
              "qualification": "Descriptive inclusive wall timings of one ordered one-visual first-cycle pair. Wall includes admission/bind, fixed probes, waits and observer overhead. Probes are separate, never nested CPU costs or subtractive corrections. Order/cache/OS scheduling noise remains; no rerun, second cohort, full route or production16-visual claim."}
    return result
