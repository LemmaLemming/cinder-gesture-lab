#!/usr/bin/env python3
"""Prepared Root-run preservation helper. Never imported or invoked by its author.
From the assigned Act2 checkout, AFTER owned jobs are closed and changes sealed:
  python3 /private/tmp/cinder_a2_shared52_preserve_adopt.py --closed-owned-jobs
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
PUBLICATION = "ffdf26e0c77bb0a5a33e52aadcf45f1610a56a3f"
BASE = "16311879af3e4dde69f96574d32572796bcf0d23"
OWNED = ("scripts/acts/act2/", "scenes/acts/act2/", "assets/acts/act2/",
         "data/campaign/act2/", "tests/acts/act2/", "docs/acts/act2/")
GAME_FOLDERS = ("scripts", "scenes", "assets", "data", "tests", "docs", "captures")
SETTINGS = ("project.godot", ".cinder/local.json", ".vscode/settings.json")
OUT_NAME = "docs/acts/act2/evidence/shared52-adoption"
UID_SUFFIXES = (".gd.uid", ".gdshader.uid")
UID_PATTERN = re.compile(r"uid://[a-z0-9]+")


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


def incoming_preflight(root, incoming, index, physical):
    failures = []
    for name, row in incoming.items():
        before, target = row["before"], row["target"]
        if name.startswith(OWNED) or name in SETTINGS:
            failures.append("target changes owned/settings path: " + name)
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
        raise RuntimeError("Actual HEAD/target lack the required published Shared51 baseline")
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
    all_incoming = incoming_delta(root, BASE, PUBLICATION)
    owned_incoming = {name: row for name, row in all_incoming.items() if name.startswith(OWNED)}
    incoming = {name: row for name, row in all_incoming.items() if not name.startswith(OWNED)}
    # Shared52 contains our already submitted O1. Every incoming owned path
    # must already exist; immutable evidence/runtime must match exactly. Only
    # the owner's newer committed notes may differ, and the merge keeps them.
    for name, row in owned_incoming.items():
        live, target = index.get(name), row["target"]
        if live is None or target is None:
            raise RuntimeError("Unallocated owned addition/removal in publication: " + name)
        if not name.startswith(("data/campaign/act2/", "docs/acts/act2/")) or "evidence" in pathlib.PurePosixPath(name).parts:
            if live["git_mode"] != target["git_mode"] or live["blob"] != target["blob"]:
                raise RuntimeError("Owned runtime/original differs from submitted publication: " + name)
    if not incoming:
        raise RuntimeError("Published supplement has no actual base delta")
    incoming_preflight(root, incoming, index, physical)
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
              "settings": settings, "incoming_delta": incoming, "preserved_owned_publication_delta": owned_incoming,
              "counts": {"owned_tracked": len(tracked), "owned_physical": len(physical["owned"]),
                         "historical_evidence_files": len(physical["historical_evidence"]),
                         "gdignore_boundaries": len(physical["gdignore_boundaries"]),
                         "recursive_UID_rows": len(physical["all_script_shader_UIDs"]),
                         "actual_active_unique_UIDs": len(active_before), "ignored_UID_rows": len(inactive_before),
                         "incoming_paths": len(incoming), "owned_publication_paths": len(owned_incoming), "settings": len(settings)},
              "count_policy": "All counts and HEAD derive from actual clean checkout at invocation; historical UID copies are not active identities",
              "scope": "Original preservation only; no new native/import/portrait acceptance credit"}
    write_json(output / "before.json", before)
    refuse_dirty(root, OUT_NAME)
    if git(root, "rev-parse", "HEAD").decode().strip() != old_head:
        raise RuntimeError("Actual HEAD changed before merge; original receipt retained")
    with (output / "merge.log").open("x", encoding="utf-8") as log:
        merged = subprocess.run(["git", "merge", "--no-ff", "--no-commit", PUBLICATION],
                                cwd=root, stdout=log, stderr=subprocess.STDOUT)
        conflicts = [os.fsdecode(name) for name in git(root, "diff", "--name-only", "--diff-filter=U", "-z").split(b"\0") if name]
        shared_conflicts = [name for name in conflicts if not name.startswith(OWNED)]
        if merged.returncode not in (0, 1) or shared_conflicts or (merged.returncode == 1 and not conflicts):
            write_json(output / "merge-failure.json", {"exit_code": merged.returncode, "before_head": old_head,
                       "publication": PUBLICATION, "unmerged_paths": conflicts,
                       "shared_conflicts": shared_conflicts, "scope_complete": False, "rollback_performed": False})
            raise RuntimeError("Merge precommit failed outside owned preservation; no automatic rollback")
        # Explicit scope-preserving merge resolution, not rollback: Root's
        # imported O1 overlaps our earlier submission. Restore every assigned
        # prefix from the captured clean owner HEAD before committing, so newer
        # owner notes and all original runtime/evidence/sidecars stay exact.
        restored = subprocess.run(["git", "restore", "--source=" + old_head, "--staged", "--worktree", "--", *OWNED],
                                  cwd=root, stdout=log, stderr=subprocess.STDOUT)
        if restored.returncode != 0 or git(root, "diff", "--name-only", "--diff-filter=U", "-z"):
            raise RuntimeError("Owned preservation resolution failed; original receipt/log retained")
        committed = subprocess.run(["git", "commit", "-m", "Merge compatible Shared52 publication into Act 2 preserving originals"],
                                   cwd=root, stdout=log, stderr=subprocess.STDOUT)
        if committed.returncode != 0:
            raise RuntimeError("Preserving merge commit failed; original receipt/log retained")
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
    if set(after_tracked) != set(tracked) or set(after["owned"]) != set(physical["owned"]):
        findings.append("unexpected owned resource additions/removals outside new receipt")
    for name, row in settings.items():
        if record(safe_path(root, name)) != row:
            findings.append("setting:" + name)
    for name, row in incoming.items():
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
               "status": "exact preserving Shared52 publication adoption" if not findings else "post-merge custody verification FAILED",
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
               "local_settings_preserved": len(settings), "incoming_exact_target_git_physical_bytes_modes": len(incoming),
               "owned_publication_paths_deliberately_retained_from_captured_owner_HEAD": len(owned_incoming),
               "new_incoming_exact_rows": additions, "new_actual_active_UID_rows": {name: row for name, row in active_after.items() if name not in active_before},
               "unexpected_final_status": unexpected_status, "findings": findings, "rollback_performed": False,
               "scope": "Exact declared supplement and preservation custody only. Counts/HEAD are actual invocation data, archives excluded from active UIDs through all .gdignore ancestor boundaries. Prior native failures/passes retain original revisions/scopes; no engine/import/portrait/whole-level acceptance execution."}
    write_json(output / "adoption.json", receipt)
    print(json.dumps({key: value for key, value in receipt.items()
                      if key not in {"new_incoming_exact_rows", "new_actual_active_UID_rows"}}, sort_keys=True))
    if findings:
        raise RuntimeError("Post-merge original custody failed; inspect preserved adoption.json, no automatic rollback")
    return 0


if __name__ == "__main__":
    sys.exit(main())
