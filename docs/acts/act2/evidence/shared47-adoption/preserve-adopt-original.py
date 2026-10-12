#!/usr/bin/env python3
"""Prepared Root-run preservation helper. Never imported or invoked by its author.
From the assigned Act2 checkout, AFTER owned jobs are closed and changes sealed:
  python3 /private/tmp/cinder_a2_shared47_preserve_adopt.py --closed-owned-jobs
Only this explicit main invocation may write its new receipt and merge the exact
published supplement. No Godot/import/helper subprocess or automatic rollback.
"""
import argparse
import datetime
import hashlib
import json
import os
import pathlib
import re
import shutil
import stat
import subprocess
import sys

ASSIGNED_CHECKOUT = "/Users/howardchen/.codex/worktrees/campaign-act2/video game idea"
PUBLICATION = "cf423911844d63c458c59e5503f82c8b1e61574b"
BASE = "6718844ff429821b031ab98a232026cf1a2d7cba"
OWNED = ("scripts/acts/act2/", "scenes/acts/act2/", "assets/acts/act2/",
         "data/campaign/act2/", "tests/acts/act2/", "docs/acts/act2/")
GAME_FOLDERS = ("scripts", "scenes", "assets", "data", "tests", "docs", "captures")
SETTINGS = ("project.godot", ".cinder/local.json", ".vscode/settings.json")
OUT_NAME = "docs/acts/act2/evidence/shared47-adoption"
UID_SUFFIXES = (".gd.uid", ".gdshader.uid")
UID_PATTERN = re.compile(r"uid://[a-z0-9]+")


RETURNED_UID_AUTHORITY = {'message_id': 'afb78bd3-b653-48a0-9208-5fea7ee02340', 'sha256': '9568e2cd678e3d6c72fbcb8d41b0cbe985099071bf3b96a1472f891d18c82525', 'publication': 'cf423911844d63c458c59e5503f82c8b1e61574b', 'verification_supplement_not_merged': 'a8bbe9ea40b6f45c80c0dc9aa28f5302cc236e86'}
OWNED_UID_RETURNS = {'tests/acts/act2/a2_l5_production_proof_diagnostic.gd.uid': {'uid': 'uid://chdwqmw03oinp', 'sha256': '65cf33e6c806eade8faba1f95e0e71b0cf22bab334eee117dd4b862cd11602a0', 'size': 20, 'git_mode': '100644', 'stat_mode': '0o644'}, 'tests/acts/act2/a2_l5_act3_transition_interface_smoke.gd.uid': {'uid': 'uid://b8ef6x5qdommh', 'sha256': '0f577b68142e409a6ef9b3a431158a51c3ba5b4c5ae2119004d3585034470710', 'size': 20, 'git_mode': '100644', 'stat_mode': '0o644'}, 'tests/acts/act2/a2_l5_production_guard_diagnostic.gd.uid': {'uid': 'uid://bv0d8eiee1yfd', 'sha256': 'db0eca924354558b22bde0e59d6f4b3adf8d8efbd051725285ff08a49ea4b3d6', 'size': 20, 'git_mode': '100644', 'stat_mode': '0o644'}, 'tests/acts/act2/a2_l5_sentry_phase_transport_smoke.gd.uid': {'uid': 'uid://b244msmst40cf', 'sha256': 'a1a29a2a42e5a5884d64203ec0481e1cb58923823ae2272e8e6e81de0f18052a', 'size': 20, 'git_mode': '100644', 'stat_mode': '0o644'}, 'tests/acts/act2/fixtures/a2_l5_tracking_commit_observer.gd.uid': {'uid': 'uid://tjdq46jpgj3h', 'sha256': 'd3831e90f013614f3cb25e5a84552f095a56b9a13bff5154a5c3a8cc71991261', 'size': 19, 'git_mode': '100644', 'stat_mode': '0o644'}}

def digest(data):
    return hashlib.sha256(data).hexdigest()


def git(root, *args):
    return subprocess.check_output(["git", *args], cwd=root)


def ancestor(root, older, newer):
    result = subprocess.run(["git", "merge-base", "--is-ancestor", older, newer], cwd=root,
                            stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    if result.returncode not in (0, 1):
        raise RuntimeError("Cannot read Git ancestry: " + result.stderr.decode(errors="replace"))
    return result.returncode == 0


def safe_path(root, name):
    part = pathlib.PurePosixPath(name)
    if not name or part.is_absolute() or ".." in part.parts:
        raise ValueError("Unsupported relative source path: " + name)
    path = root.joinpath(*part.parts)
    if not path.resolve().is_relative_to(root):
        raise ValueError("Source path leaves actual checkout: " + name)
    return path


def record(path):
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode):
        raise ValueError("Custody requires an original regular file, not a symlink: " + str(path))
    content = path.read_bytes()
    mode = stat.S_IMODE(info.st_mode)
    return {"sha256": digest(content), "size": len(content), "stat_mode": oct(mode),
            "executable_bits": mode & 0o111}


def write_json(path, value):
    with path.open("x", encoding="utf-8") as stream:
        stream.write(json.dumps(value, indent=2, sort_keys=True) + "\n")


def status_rows(root):
    fields = git(root, "status", "--porcelain=v1", "-z", "--untracked-files=all").split(b"\0")
    rows = []
    index = 0
    while index < len(fields) and fields[index]:
        row = fields[index]
        index += 1
        state, name = row[:2].decode("ascii"), os.fsdecode(row[3:])
        item = {"status": state, "path": name}
        if "R" in state or "C" in state:
            item["original_path"] = os.fsdecode(fields[index])
            index += 1
        rows.append(item)
    return rows


def refuse_dirty(root, output=None):
    rows = status_rows(root)
    if output is not None:
        rows = [row for row in rows if not (row["status"] == "??" and
                row["path"].startswith(output + "/") and "original_path" not in row)]
    if rows:
        raise RuntimeError("Refuse dirty actual checkout (%d entries; first ten): %s" %
                           (len(rows), json.dumps(rows[:10], sort_keys=True)))


def indexed(root):
    rows = {}
    for item in git(root, "ls-files", "--stage", "-z").split(b"\0"):
        if not item:
            continue
        meta, raw_name = item.split(b"\t", 1)
        mode, blob, stage = meta.decode("ascii").split()
        name = os.fsdecode(raw_name)
        if stage != "0" or mode not in {"100644", "100755"}:
            raise ValueError("Unsupported/unmerged actual index row: " + name)
        rows[name] = {"git_mode": mode, "blob": blob, "stage": stage}
    return rows


def tree(root, rev):
    rows = {}
    for item in git(root, "ls-tree", "-r", "-z", rev).split(b"\0"):
        if not item:
            continue
        meta, raw_name = item.split(b"\t", 1)
        mode, kind, blob = meta.decode("ascii").split()
        name = os.fsdecode(raw_name)
        if kind != "blob" or mode not in {"100644", "100755"}:
            raise ValueError("Unsupported source tree object: " + name)
        rows[name] = {"git_mode": mode, "blob": blob}
    return rows


def blob_records(root, blobs):
    # Read original Git bytes directly; do not check out or normalize originals.
    values = {}
    child = subprocess.Popen(["git", "cat-file", "--batch"], cwd=root,
                             stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        for blob in dict.fromkeys(blobs):
            child.stdin.write((blob + "\n").encode("ascii"))
            child.stdin.flush()
            header = child.stdout.readline().decode("ascii").split()
            if len(header) != 3 or header[:2] != [blob, "blob"]:
                raise RuntimeError("Original Git blob unavailable: " + blob)
            content = child.stdout.read(int(header[2]))
            if len(content) != int(header[2]) or child.stdout.read(1) != b"\n":
                raise RuntimeError("Truncated original Git blob: " + blob)
            values[blob] = {"sha256": digest(content), "size": len(content)}
        child.stdin.close()
        error = child.stderr.read()
        if child.wait() != 0:
            raise RuntimeError("Cannot read original Git bytes: " + error.decode(errors="replace"))
    except BaseException:
        if child.poll() is None:
            child.kill()
        child.wait()
        raise
    finally:
        child.stdout.close()
        child.stderr.close()
        if child.stdin is not None and not child.stdin.closed:
            child.stdin.close()
    return values


def add_git_bytes(root, rows):
    blobs = blob_records(root, [row["blob"] for row in rows.values()])
    return {name: dict(row, **blobs[row["blob"]]) for name, row in rows.items()}


def physical_inventory(root):
    # Only game folders: repository internals and current engine caches/logs are
    # excluded. Captured .godot/.cinder copies INSIDE historical evidence remain.
    rows, boundaries, evidence_files, uids = {}, {}, {}, {}
    output = safe_path(root, OUT_NAME)
    if (root / ".gdignore").exists() or (root / ".gdignore").is_symlink():
        boundaries[".gdignore"] = record(root / ".gdignore")
    for folder in GAME_FOLDERS:
        start = safe_path(root, folder)
        if not start.exists():
            continue
        for parent, dirs, names in os.walk(start, followlinks=False):
            at = pathlib.Path(parent)
            dirs[:] = sorted(dirs)
            if at == output or at.is_relative_to(output):
                dirs[:] = []
                continue
            for name in dirs:
                if (at / name).is_symlink():
                    raise ValueError("Unexpected source directory symlink: " + str(at / name))
            for name in sorted(names):
                path = at / name
                relative = path.relative_to(root).as_posix()
                if name == ".gdignore":
                    boundaries[relative] = record(path)
                owned = relative.startswith(OWNED)
                historical = "evidence" in pathlib.PurePosixPath(relative).parts[:-1]
                uid = name.endswith(UID_SUFFIXES)
                if owned or historical or uid:
                    row = record(path)
                    if owned:
                        rows[relative] = row
                    if historical:
                        evidence_files[relative] = row
                    if uid:
                        uids[relative] = row
    return {"owned": rows, "gdignore_boundaries": boundaries,
            "historical_evidence": evidence_files, "all_script_shader_UIDs": uids}


def active_uids(root, uids, boundaries):
    active, ignored, identities = {}, {}, {}
    boundary_dirs = {pathlib.PurePosixPath(name).parent for name in boundaries}
    for name, row in uids.items():
        parent = pathlib.PurePosixPath(name).parent
        boundary = next((str(at) for at in [parent, *parent.parents] if at in boundary_dirs), None)
        if boundary is not None:
            ignored[name] = dict(row, ignored_by=boundary + "/.gdignore")
            continue
        identity = safe_path(root, name).read_text(encoding="utf-8").strip()
        if UID_PATTERN.fullmatch(identity) is None or identity in identities:
            raise ValueError("Invalid or duplicate ACTIVE UID identity: " + name)
        identities[identity] = name
        active[name] = dict(row, identity=identity)
    return active, ignored


def incoming_delta(root, baseline, target):
    base_tree, target_tree = tree(root, baseline), tree(root, target)
    rows = {}
    for name in sorted(set(base_tree) | set(target_tree)):
        before, after = base_tree.get(name), target_tree.get(name)
        if before == after:
            continue
        rows[name] = {"change": "added" if before is None else "deleted" if after is None else "modified",
                      "before": before, "target": after}
    blobs = blob_records(root, [row[side]["blob"] for row in rows.values()
                               for side in ("before", "target") if row[side] is not None])
    for row in rows.values():
        for side in ("before", "target"):
            if row[side] is not None:
                row[side] = dict(row[side], **blobs[row[side]["blob"]])
    return rows


def incoming_preflight(root, incoming, index, physical, active_before):
    failures = []
    prior_ids = {row["identity"] for row in active_before.values()}
    for name, expected in OWNED_UID_RETURNS.items():
        row = incoming.get(name)
        target = None if row is None else row["target"]
        path = safe_path(root, name)
        if (row is None or row["before"] is not None or target is None or
                target["git_mode"] != expected["git_mode"] or
                target["sha256"] != expected["sha256"] or target["size"] != expected["size"]):
            failures.append("authorized UID is not exact added publication bytes/mode: " + name)
        if (name in index or name in physical["owned"] or
                name in physical["all_script_shader_UIDs"] or path.exists() or path.is_symlink()):
            failures.append("authorized late UID must still be absent; existing conflict: " + name)
        if expected["uid"] in prior_ids:
            failures.append("returned UID token already belongs to another active owner: " + name)
        if UID_PATTERN.fullmatch(expected["uid"]) is None or digest((expected["uid"] + "\n").encode()) != expected["sha256"]:
            failures.append("closed returned UID authority is malformed: " + name)
    if len({row["uid"] for row in OWNED_UID_RETURNS.values()}) != len(OWNED_UID_RETURNS):
        failures.append("returned UID authority contains duplicate identities")
    for name, row in incoming.items():
        before, target = row["before"], row["target"]
        if name in OWNED_UID_RETURNS:
            continue  # Fully validated as absent and exact above, not a generic override.
        if name in SETTINGS:
            failures.append("target changes local settings path: " + name)
            continue
        if name.startswith(OWNED):
            # Accepted content is already owned. A later owner record may be
            # newer than the published HANDOFF. Keep every existing original
            # stage0 blob/mode; only the five closed UID additions may be new.
            if name not in index or name not in physical["owned"] or target is None:
                failures.append("publication has unauthorized new/deleted owned path: " + name)
            continue
        prior = physical["all_script_shader_UIDs"].get(name) or physical["historical_evidence"].get(name) or physical["gdignore_boundaries"].get(name)
        if prior is not None and (target is None or target["sha256"] != prior["sha256"] or
                                  int(target["git_mode"], 8) & 0o777 != int(prior["stat_mode"], 8)):
            failures.append("target changes prior UID/archive/boundary custody: " + name)
        live = index.get(name)
        basic = None if live is None else {"git_mode": live["git_mode"], "blob": live["blob"]}
        options = [None if value is None else {"git_mode": value["git_mode"], "blob": value["blob"]}
                   for value in (before, target)]
        if basic not in options:
            failures.append("shared incoming path diverged from base/target: " + name)
        path = safe_path(root, name)
        if before is None and live is None and (path.exists() or path.is_symlink()):
            failures.append("incoming path would overwrite an unindexed original: " + name)
    if failures:
        raise RuntimeError("Incoming publication cannot preserve originals: " + json.dumps(failures[:20]))


def owned_staged_errors(root, tracked, physical):
    index = indexed(root)
    owned_now = {name: row for name, row in index.items() if name.startswith(OWNED)}
    errors = []
    if set(owned_now) != set(tracked) | set(OWNED_UID_RETURNS):
        errors.append("staged owned set differs from original plus exactly five authorized UIDs")
    for name, row in tracked.items():
        actual = owned_now.get(name)
        if actual is None or actual["git_mode"] != row["git_mode"] or actual["blob"] != row["blob"] or actual["stage"] != "0":
            errors.append("staged original owned blob/mode differs: " + name)
    now = physical_inventory(root)
    errors += compare_preserved("staged-owned-physical", physical["owned"], now["owned"])
    errors += compare_preserved("staged-archive", physical["historical_evidence"], now["historical_evidence"])
    errors += compare_preserved("staged-UID", physical["all_script_shader_UIDs"], now["all_script_shader_UIDs"])
    errors += compare_preserved("staged-gdignore", physical["gdignore_boundaries"], now["gdignore_boundaries"])
    if set(now["owned"]) != set(physical["owned"]) | set(OWNED_UID_RETURNS):
        errors.append("physical owned set differs from original plus exactly five authorized UIDs")
    for name, expected in OWNED_UID_RETURNS.items():
        path = safe_path(root, name)
        actual = owned_now.get(name)
        if not path.is_file() or path.is_symlink() or actual is None:
            errors.append("authorized UID missing/nonregular: " + name)
            continue
        row = record(path)
        if (row["sha256"] != expected["sha256"] or row["size"] != expected["size"] or
                row["stat_mode"] != expected["stat_mode"] or row["executable_bits"] != 0 or
                actual["git_mode"] != expected["git_mode"] or
                path.read_bytes() != (expected["uid"] + "\n").encode()):
            errors.append("authorized UID exact token/hash/mode differs: " + name)
    active_uids(root, now["all_script_shader_UIDs"], now["gdignore_boundaries"])
    return errors


def merge_preserving_owned(root, output, old_head, tracked, physical, incoming, settings):
    # Leave the merge uncommitted until the six-prefix original stage0 boundary
    # is restored and only the five explicitly returned UIDs are installed.
    # No global conflict strategy, rollback, archive backfill or automatic retry.
    failure = None
    with (output / "merge.log").open("x", encoding="utf-8") as log:
        merged = subprocess.run(["git", "merge", "--no-ff", "--no-commit", PUBLICATION],
                                cwd=root, stdout=log, stderr=subprocess.STDOUT)
        pending = subprocess.run(["git", "rev-parse", "-q", "--verify", "MERGE_HEAD"],
                                 cwd=root, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        conflicts = [os.fsdecode(name) for name in git(root, "diff", "--name-only", "--diff-filter=U", "-z").split(b"\0") if name]
        unsupported = [name for name in conflicts if name not in tracked]
        if merged.returncode not in (0, 1) or pending.returncode != 0 or pending.stdout.strip() != PUBLICATION or unsupported:
            failure = {"phase": "merge preparation", "exit_code": merged.returncode,
                       "unsupported_conflicts": unsupported}
        if failure is None:
            try:
                # Clean index/HEAD was captured before the merge. Path-scoped
                # restore keeps its exact stage0 blob/mode for every old owner.
                git(root, "restore", "--source=" + old_head, "--staged", "--worktree", "--", *[name.rstrip("/") for name in OWNED])
                for name, row in physical["owned"].items():
                    path = safe_path(root, name)
                    if path.is_file() and not path.is_symlink() and record(path)["stat_mode"] != row["stat_mode"]:
                        path.chmod(int(row["stat_mode"], 8))
                git(root, "restore", "--source=" + PUBLICATION, "--staged", "--worktree", "--", *sorted(OWNED_UID_RETURNS))
                for name, row in OWNED_UID_RETURNS.items():
                    safe_path(root, name).chmod(int(row["stat_mode"], 8))
                errors = owned_staged_errors(root, tracked, physical)
                errors += ["setting:" + name for name, row in settings.items() if record(safe_path(root, name)) != row]
                after_index = indexed(root)
                for name, row in incoming.items():
                    if name.startswith(OWNED) and name not in OWNED_UID_RETURNS:
                        continue
                    target = row["target"]
                    path = safe_path(root, name)
                    if target is None:
                        if name in after_index or path.exists() or path.is_symlink():
                            errors.append("staged incoming deletion differs:" + name)
                    elif not path.is_file() or path.is_symlink() or name not in after_index:
                        errors.append("staged incoming absent:" + name)
                    else:
                        actual, physical_row = after_index[name], record(path)
                        if (actual["git_mode"] != target["git_mode"] or actual["blob"] != target["blob"] or
                                physical_row["sha256"] != target["sha256"] or physical_row["size"] != target["size"] or
                                int(physical_row["stat_mode"], 8) != (int(target["git_mode"], 8) & 0o777)):
                            errors.append("staged incoming bytes/mode differs:" + name)
                if errors:
                    failure = {"phase": "before merge commit", "errors": errors[:30]}
                else:
                    committed = subprocess.run(["git", "commit", "-m", "Merge Shared47 preserving Act2 originals and five returned UID sidecars"], cwd=root, stdout=log, stderr=subprocess.STDOUT)
                    if committed.returncode != 0:
                        failure = {"phase": "merge commit", "exit_code": committed.returncode}
            except Exception as error:
                failure = {"phase": "owned preservation boundary", "error": str(error)}
    if failure is not None:
        write_json(output / "merge-failure.json", dict(failure, before_head=old_head,
                   publication=PUBLICATION, merge_log_sha256=record(output / "merge.log")["sha256"],
                   scope_complete=False, rollback_performed=False))
        raise RuntimeError("Preserving merge did not close; exact originals/receipt/log retained, inspect merge-failure.json; no rollback")


def compare_preserved(label, before, after):
    return [label + ":" + name for name, row in before.items() if after.get(name) != row]


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--closed-owned-jobs", action="store_true", required=True,
                        help="Root confirms owned jobs CLOSED and owned changes committed before invocation")
    parser.parse_args(argv)
    root = pathlib.Path.cwd().resolve()
    if root != pathlib.Path(ASSIGNED_CHECKOUT).resolve():
        raise RuntimeError("Invoke only in the registered Act2 checkout, not integration/another act")
    if git(root, "rev-parse", "--show-toplevel").decode().strip() != str(root):
        raise RuntimeError("Invoke only at the actual assigned checkout root")
    if not git(root, "branch", "--show-current").decode().strip().startswith("codex/"):
        raise RuntimeError("Actual checkout is not on an owned codex/ branch")
    refuse_dirty(root)  # Includes untracked evidence, not only diff/index changes.
    if git(root, "rev-parse", "--verify", PUBLICATION + "^{commit}").decode().strip() != PUBLICATION:
        raise RuntimeError("Exact published supplement is unavailable")
    old_head = git(root, "rev-parse", "HEAD").decode().strip()
    if not ancestor(root, BASE, PUBLICATION) or not ancestor(root, BASE, old_head):
        raise RuntimeError("Actual HEAD/target lack the required published Shared46 baseline")
    if ancestor(root, PUBLICATION, old_head):
        raise RuntimeError("Exact supplement already adopted; refuse duplicate receipt/merge")
    output = safe_path(root, OUT_NAME)
    if output.exists() or output.is_symlink():
        raise RuntimeError("Refuse replacing an existing adoption packet")
    index = indexed(root)
    tracked = add_git_bytes(root, {name: row for name, row in index.items() if name.startswith(OWNED)})
    physical = physical_inventory(root)
    active_before, inactive_before = active_uids(root, physical["all_script_shader_UIDs"], physical["gdignore_boundaries"])
    settings = {name: record(safe_path(root, name)) for name in SETTINGS}
    incoming = incoming_delta(root, BASE, PUBLICATION)
    if not incoming:
        raise RuntimeError("Published supplement has no actual base delta")
    incoming_preflight(root, incoming, index, physical, active_before)
    # Long inventories are read-only. Recheck cleanliness and the exact live
    # HEAD before creating receipts or executing the single merge mutation.
    refuse_dirty(root)
    if git(root, "rev-parse", "HEAD").decode().strip() != old_head:
        raise RuntimeError("Actual HEAD changed during original-custody capture")
    if physical_inventory(root) != physical or {name: record(safe_path(root, name)) for name in SETTINGS} != settings:
        raise RuntimeError("Actual original bytes/modes changed during capture; refuse merge")
    output.mkdir(parents=True, exist_ok=False)
    (output / ".gdignore").write_text("", encoding="utf-8")
    helper = pathlib.Path(__file__).resolve()
    shutil.copy2(helper, output / "preserve-adopt-original.py")
    before = {"at": datetime.datetime.now(datetime.timezone.utc).isoformat(), "publication": PUBLICATION,
              "preceding_actual_baseline": BASE, "before_head": old_head, "before_status": [],
              "operator_declared_owned_jobs_closed": True, "helper_sha256": record(output / "preserve-adopt-original.py")["sha256"],
              "owned_prefixes": OWNED, "owned_tracked": tracked, "owned_physical": physical["owned"],
              "historical_evidence_physical": physical["historical_evidence"],
              "gdignore_boundaries": physical["gdignore_boundaries"],
              "all_recursive_script_shader_UID_rows": physical["all_script_shader_UIDs"],
              "actual_active_UID_rows": active_before, "ignored_UID_rows": inactive_before,
              "settings": settings, "incoming_delta": incoming,
              "counts": {"owned_tracked": len(tracked), "owned_physical": len(physical["owned"]),
                         "historical_evidence_files": len(physical["historical_evidence"]),
                         "gdignore_boundaries": len(physical["gdignore_boundaries"]),
                         "recursive_UID_rows": len(physical["all_script_shader_UIDs"]),
                         "actual_active_unique_UIDs": len(active_before), "ignored_UID_rows": len(inactive_before),
                         "incoming_paths": len(incoming), "settings": len(settings)},
              "count_policy": "All counts and HEAD derive from actual clean checkout at invocation; historical UID copies are not active identities",
              "returned_UID_authority": RETURNED_UID_AUTHORITY, "authorized_new_owned_UIDs": OWNED_UID_RETURNS,
              "incoming_existing_owned_rows": sum(name.startswith(OWNED) and name not in OWNED_UID_RETURNS for name in incoming),
              "scope": "Five exact absent returned UID additions only; every other original owned row preserved. No old archive backfill or new native/import/portrait acceptance credit"}
    write_json(output / "before.json", before)
    refuse_dirty(root, OUT_NAME)
    if git(root, "rev-parse", "HEAD").decode().strip() != old_head:
        raise RuntimeError("Actual HEAD changed before merge; original receipt retained")
    merge_preserving_owned(root, output, old_head, tracked, physical, incoming, settings)
    after_index = indexed(root)
    after_tracked = add_git_bytes(root, {name: row for name, row in after_index.items() if name.startswith(OWNED)})
    after = physical_inventory(root)
    active_after, inactive_after = active_uids(root, after["all_script_shader_UIDs"], after["gdignore_boundaries"])
    findings = compare_preserved("owned-git", tracked, after_tracked)
    findings += compare_preserved("owned-physical", physical["owned"], after["owned"])
    findings += compare_preserved("archive", physical["historical_evidence"], after["historical_evidence"])
    findings += compare_preserved("gdignore", physical["gdignore_boundaries"], after["gdignore_boundaries"])
    findings += compare_preserved("all-UID", physical["all_script_shader_UIDs"], after["all_script_shader_UIDs"])
    findings += compare_preserved("active-UID", active_before, active_after)
    if set(after_tracked) != set(tracked) | set(OWNED_UID_RETURNS) or set(after["owned"]) != set(physical["owned"]) | set(OWNED_UID_RETURNS):
        findings.append("unexpected owned resource additions/removals outside new receipt")
    for name, row in settings.items():
        if record(safe_path(root, name)) != row:
            findings.append("setting:" + name)
    for name, row in incoming.items():
        if name.startswith(OWNED) and name not in OWNED_UID_RETURNS:
            continue  # Original owner version retained, not an incoming overwrite.
        target = row["target"]
        path = safe_path(root, name)
        if target is None:
            if name in after_index or path.exists() or path.is_symlink():
                findings.append("incoming deletion:" + name)
            continue
        actual = after_index.get(name)
        if not path.is_file() or path.is_symlink() or actual is None:
            findings.append("incoming missing/nonregular:" + name)
            continue
        physical_row = record(path)
        if (actual["git_mode"] != target["git_mode"] or actual["blob"] != target["blob"] or
                physical_row["sha256"] != target["sha256"] or physical_row["size"] != target["size"] or
                int(physical_row["stat_mode"], 8) != (int(target["git_mode"], 8) & 0o777)):
            findings.append("incoming bytes/mode:" + name)
    additions = {}
    for label, old_rows, new_rows in (("archive", physical["historical_evidence"], after["historical_evidence"]),
                                     ("gdignore", physical["gdignore_boundaries"], after["gdignore_boundaries"]),
                                     ("UID", physical["all_script_shader_UIDs"], after["all_script_shader_UIDs"])):
        additions[label] = {name: row for name, row in new_rows.items() if name not in old_rows}
        for name, row in additions[label].items():
            target = incoming.get(name, {}).get("target")
            if target is None or row["sha256"] != target["sha256"] or int(row["stat_mode"], 8) != (int(target["git_mode"], 8) & 0o777):
                findings.append("unexpected new " + label + ":" + name)
    head = git(root, "rev-parse", "HEAD").decode().strip()
    parents = git(root, "show", "-s", "--format=%P", head).decode().split()
    if parents != [old_head, PUBLICATION]:
        findings.append("merge parents differ from actual captured HEAD/exact publication")
    status = status_rows(root)
    unexpected_status = [row for row in status if not (row["status"] == "??" and row["path"].startswith(OUT_NAME + "/"))]
    if unexpected_status:
        findings.append("unexpected final status outside new receipt")
    receipt = {"at": datetime.datetime.now(datetime.timezone.utc).isoformat(), "scope_complete": not findings,
               "status": "exact preserving Shared47 publication adoption" if not findings else "post-merge custody verification FAILED",
               "publication": PUBLICATION, "preceding_actual_baseline": BASE,
               "merge": head, "parents": parents, "captured_actual_before_head": old_head,
               "before_sha256": record(output / "before.json")["sha256"],
               "merge_log_sha256": record(output / "merge.log")["sha256"], "helper_sha256": before["helper_sha256"],
               "owned_git_bytes_modes_preserved": len(tracked), "owned_physical_bytes_modes_preserved": len(physical["owned"]),
               "historical_evidence_original_bytes_modes_preserved": len(physical["historical_evidence"]),
               "prior_gdignore_boundaries_preserved": len(physical["gdignore_boundaries"]),
               "prior_all_recursive_UID_bytes_modes_preserved": len(physical["all_script_shader_UIDs"]),
               "actual_active_UID_count_before": len(active_before), "actual_active_UID_count_after": len(active_after),
               "actual_prior_active_UID_bytes_modes_identities_preserved": not compare_preserved("active-UID", active_before, active_after),
               "actual_active_UIDs_unique": True, "recursive_UID_count_after": len(after["all_script_shader_UIDs"]),
               "ignored_UID_count_before": len(inactive_before), "ignored_UID_count_after": len(inactive_after),
               "local_settings_preserved": len(settings), "incoming_base_delta_rows": len(incoming),
               "incoming_existing_owned_rows_preserved": sum(name.startswith(OWNED) and name not in OWNED_UID_RETURNS for name in incoming),
               "incoming_exact_target_git_physical_bytes_modes": sum(not name.startswith(OWNED) or name in OWNED_UID_RETURNS for name in incoming),
               "returned_UID_authority": RETURNED_UID_AUTHORITY, "authorized_new_owned_UIDs": OWNED_UID_RETURNS,
               "five_returned_UIDs_exact": not owned_staged_errors(root, tracked, physical),
               "new_incoming_exact_rows": additions, "new_actual_active_UID_rows": {name: row for name, row in active_after.items() if name not in active_before},
               "unexpected_final_status": unexpected_status, "findings": findings, "rollback_performed": False,
               "scope": "Exact Shared47 adoption with only five absent authorized owned UID additions. Every prior owned stage0 blob/Gitmode and physical hash/statmode, including later owner metadata, retained. Nonowned incoming exacttarget rows installed; alreadyowned publication rows stay original owner bytes. Historical archives never backfilled. Dynamic counts/HEAD and .gdignore-activeUID split; no engine/import/native/art acceptance execution."}
    write_json(output / "adoption.json", receipt)
    print(json.dumps({key: value for key, value in receipt.items()
                      if key not in {"new_incoming_exact_rows", "new_actual_active_UID_rows"}}, sort_keys=True))
    if findings:
        raise RuntimeError("Post-merge original custody failed; inspect preserved adoption.json, no automatic rollback")
    return 0


if __name__ == "__main__":
    sys.exit(main())
