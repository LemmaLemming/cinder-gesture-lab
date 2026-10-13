#!/usr/bin/env python3
"""Generate ignored machine/worktree settings; tracked VSCode files stay portable."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

from dev import DevError, ProjectContext

SLOTS = {"integration": (6005, 6006, 6007), "act1": (6015, 6016, 6017),
         "act2": (6025, 6026, 6027), "act3": (6035, 6036, 6037)}
CODE = Path("/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code")


def write_json(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


def configure_godot(root: Path, godot: Path) -> Path:
    version = subprocess.check_output([str(godot), "--version"], text=True).strip()
    match = re.match(r"(\d+\.\d+)\.", version)
    if not match:
        raise ValueError("Cannot identify Godot settings version")
    settings = Path.home() / "Library/Application Support/Godot" / f"editor_settings-{match[1]}.tres"
    text = settings.read_text(encoding="utf-8")
    if "[resource]" not in text:
        raise ValueError("Godot editor settings are not a recognized text resource")
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    backup = root / ".cinder/backups" / f"{settings.name}.{stamp}.bak"
    backup.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(settings, backup)
    values = {
        "text_editor/external/use_external_editor": "true",
        "text_editor/external/exec_path": json.dumps(str(CODE)),
        "text_editor/external/exec_flags": json.dumps('{project} --goto {file}:{line}:{col}'),
        "text_editor/behavior/files/auto_reload_scripts_on_external_change": "true",
        "interface/editor/behavior/import_resources_when_unfocused": "true",
    }
    for key, value in values.items():
        pattern = re.compile(r"^" + re.escape(key) + r"\s*=.*$", re.MULTILINE)
        line = f"{key} = {value}"
        if pattern.search(text):
            text = pattern.sub(lambda _: line, text)
        else:
            text = text.replace("[resource]\n", "[resource]\n" + line + "\n", 1)
    settings.write_text(text, encoding="utf-8")
    print(f"Configured Godot external editor: {settings}")
    print(f"Previous settings saved at: {backup}")
    print("Already-open Godot editors may retain old settings; reopen them after saving your work.")
    return settings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--slot", choices=SLOTS, default="integration")
    parser.add_argument("--canonical-root", type=Path, required=True)
    parser.add_argument("--godot", type=Path)
    parser.add_argument("--configure-godot", action="store_true",
                        help="Back up and update this Mac's Godot external-editor preferences")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    canonical = args.canonical_root.expanduser().resolve()
    if not (canonical / "data/design/ability_usage.json").is_file():
        parser.error("Canonical root must contain the shared campaign ability ledger")
    if not (canonical / "project.godot").is_file():
        parser.error("Canonical root must be a Cinder project")
    try:
        # Validate the supplied root rather than an older local/environment
        # setting, and do so before replacing either generated settings file.
        context = ProjectContext(root, {**os.environ, "CINDER_CANONICAL_ROOT": str(canonical)})
        context.design_root("scripts/design/ability_usage.py")
        context.design_root("scripts/design/equipment_grid.py")
    except DevError as exc:
        parser.error(str(exc))
    godot = (args.godot or canonical / ".tools/Godot.app/Contents/MacOS/Godot").expanduser().resolve()
    if not godot.is_file():
        parser.error("Godot executable missing; pass --godot with the installed editor binary")
    if not CODE.is_file():
        parser.error("VSCode's application CLI is missing")
    lsp, dap, debug = SLOTS[args.slot]
    write_json(root / ".cinder/local.json", {
        "canonical_root": str(canonical), "godot": str(godot), "slot": args.slot,
    })
    workspace = root / ".cinder/cinder.code-workspace"
    write_json(workspace, {
        "folders": [{"name": f"Cinder {args.slot}", "path": ".."}],
        "settings": {
            "godotTools.editorPath.godot4": str(root / "scripts/dev/godot-vscode"),
            "godotTools.lsp.headless": False,
            "godotTools.lsp.serverHost": "127.0.0.1", "godotTools.lsp.serverPort": lsp,
        },
        "launch": {
            "version": "0.2.0", "configurations": [{
                "name": f"Cinder {args.slot}: Debug lab (close queued editor first)",
                "type": "godot", "request": "launch", "project": "${workspaceFolder}",
                "editor_path": str(root / "scripts/dev/godot-vscode"),
                "address": "127.0.0.1", "port": debug, "scene": "main",
            }],
        },
        "extensions": {"recommendations": ["geequlim.godot-tools"]},
    })
    print(f"Local settings: {root / '.cinder/local.json'}")
    print(f"Open workspace: {workspace}")
    print(f"Slot {args.slot}: LSP={lsp}, DAP={dap}, debugger={debug}")
    if args.configure_godot:
        configure_godot(root, godot)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, subprocess.SubprocessError) as exc:
        print(f"VSCode setup failed: {exc}", file=sys.stderr)
        raise SystemExit(2)
