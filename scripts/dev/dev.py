#!/usr/bin/env python3
"""Code-first Cinder project commands; Python 3 standard library only.

Godot sessions share one advisory lock across linked Git worktrees. Children
inherit the locked descriptor, so closing or killing this wrapper cannot allow
a second session to overlap a still-running child. Interactive processes are
never auto-killed; bounded validation commands stop only their own child.
"""

from __future__ import annotations

import argparse
import contextlib
import fcntl
import json
import os
from pathlib import Path
import queue
import re
import shutil
import subprocess
import sys
import threading
import time


ROOT = Path(__file__).resolve().parents[2]
GODOT_APP = Path(".tools/Godot.app/Contents/MacOS/Godot")
SUITES = {
    "mechanics": "tests/mechanics_smoke.gd",
    "equipment": "tests/equipment_smoke.gd",
    "character_lab": "tests/character_lab_smoke.gd",
    "visual_effects": "tests/visual_effects_smoke.gd",
    "level_contract": "tests/level_contract_smoke.gd",
    "world_actions": "tests/world_action_smoke.gd",
    "player_snapshot": "tests/player_snapshot_smoke.gd",
    "campaign_persistence": "tests/campaign_persistence_smoke.gd",
    "settings": "tests/settings_smoke.gd",
    "threat_scheduler": "tests/threat_scheduler_smoke.gd",
    "enemy_snapshot": "tests/enemy_snapshot_smoke.gd",
    "campaign_menu": "tests/campaign_menu_smoke.gd",
    "input_response": "tests/input_response_smoke.gd",
    "effects_settings": "tests/effects_settings_smoke.gd",
    "practice_target": "tests/practice_target_smoke.gd",
    "threat_snapshot": "tests/threat_snapshot_smoke.gd",
    "campaign_shell": "tests/campaign_shell_smoke.gd",
    "player_presentation": "tests/player_presentation_smoke.gd",
    "cues": "tests/cue_smoke.gd",
}
SLOT_PORTS = {
    "integration": (6005, 6006, 6007),
    "act1": (6015, 6016, 6017),
    "act2": (6025, 6026, 6027),
    "act3": (6035, 6036, 6037),
}
ABILITY_COMMANDS = {
    "status", "available", "check", "reserve", "record", "cancel",
    "withdraw", "register", "validate", "init",
}
EQUIPMENT_COMMANDS = {"status", "check", "reserve", "cancel", "complete", "validate"}
IMPORT_TIMEOUT = 300
TEST_TIMEOUT = 600
SCRIPT_FAILURE = re.compile(
    r"\bSCRIPT ERROR:|\bParse Error:|\bFailed to (?:load|compile) script\b|"
    r"\bError loading script\b|\bERROR:\s+Failed loading resource:",
    re.IGNORECASE,
)


class DevError(Exception):
    """An actionable local configuration or command error."""


def git_output(root: Path, *arguments: str) -> str | None:
    try:
        result = subprocess.run(
            ["git", "-C", str(root), *arguments], capture_output=True,
            text=True, check=False, timeout=15,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    return result.stdout.strip() if result.returncode == 0 else None


def git_directory(root: Path, option: str) -> Path | None:
    value = git_output(root, "rev-parse", option)
    if not value:
        return None
    path = Path(value)
    return (path if path.is_absolute() else root / path).resolve()


def absolute_path(value: object, label: str) -> Path:
    if not isinstance(value, str) or not value.strip():
        raise DevError(f"{label} must be a nonempty absolute path.")
    path = Path(value).expanduser()
    if not path.is_absolute():
        raise DevError(f"{label} must be an absolute path; relative roots are ambiguous.")
    return path.resolve()


class ProjectContext:
    def __init__(self, root: Path = ROOT, environ: dict | None = None):
        self.root = Path(root).resolve()
        self.environ = dict(os.environ if environ is None else environ)
        config_path = self.root / ".cinder/local.json"
        self.config = {}
        if config_path.exists():
            try:
                self.config = json.loads(config_path.read_text(encoding="utf-8"))
            except (OSError, UnicodeError, json.JSONDecodeError) as exc:
                raise DevError(f"Cannot read {config_path}: {exc}") from exc
            if not isinstance(self.config, dict):
                raise DevError(".cinder/local.json must contain a JSON object.")
        slot = self.config.get("slot")
        if slot is not None and (not isinstance(slot, str) or slot not in SLOT_PORTS):
            raise DevError("slot must be integration, act1, act2 or act3.")
        self.slot = slot
        canonical = self.environ.get("CINDER_CANONICAL_ROOT")
        if canonical is None:
            canonical = self.config.get("canonical_root")
        self.canonical_explicit = canonical is not None
        self.canonical_root = (
            absolute_path(canonical, "canonical_root / CINDER_CANONICAL_ROOT")
            if self.canonical_explicit else self.root
        )
        if not (self.root / "project.godot").is_file():
            raise DevError(f"No project.godot in {self.root}.")
        if not (self.canonical_root / "project.godot").is_file():
            raise DevError(f"Canonical root has no project.godot: {self.canonical_root}")

    def ability_root(self) -> Path:
        """Only the primary checkout may be the shared introduction registry."""
        return self.design_root("scripts/design/ability_usage.py")

    def design_root(self, script_relative: str) -> Path:
        """Resolve the canonical introduction or equipment-creation registry."""
        current_git = git_directory(self.root, "--git-dir")
        current_common = git_directory(self.root, "--git-common-dir")
        linked = current_git is not None and current_git != current_common
        if not self.canonical_explicit and (linked or self.slot in {"act1", "act2", "act3"}):
            raise DevError(
                "Shared design commands in an act slot or linked worktree need an explicit "
                "canonical_root in .cinder/local.json or CINDER_CANONICAL_ROOT; "
                "a private ledger is not a safe fallback."
            )
        canonical_git = git_directory(self.canonical_root, "--git-dir")
        canonical_common = git_directory(self.canonical_root, "--git-common-dir")
        if canonical_git is not None and canonical_git != canonical_common:
            raise DevError("The canonical design root must be the primary checkout, not a linked worktree.")
        if current_common is not None and canonical_common != current_common:
            raise DevError("Canonical design root must belong to this checkout's shared Git repository.")
        if current_common is not None and git_output(self.root, "remote", "get-url", "origin") != git_output(self.canonical_root, "remote", "get-url", "origin"):
            raise DevError("Canonical design root and current checkout must have the same origin.")
        script = self.canonical_root / script_relative
        if not script.is_file():
            raise DevError(f"Canonical design tool is missing: {script}")
        return self.canonical_root


def executable_path(value: object, label: str) -> Path:
    path = absolute_path(value, label)
    if path.is_dir() and path.suffix == ".app":
        path = path / "Contents/MacOS/Godot"
    if not path.is_file() or not os.access(path, os.X_OK):
        raise DevError(f"{label} does not identify an executable Godot binary: {path}")
    return path


def resolve_godot(context: ProjectContext) -> Path:
    if "CINDER_GODOT" in context.environ:
        return executable_path(context.environ["CINDER_GODOT"], "CINDER_GODOT")
    if "godot" in context.config:
        return executable_path(context.config["godot"], ".cinder/local.json godot")
    for root in dict.fromkeys((context.root, context.canonical_root)):
        for relative in (GODOT_APP, Path(".tools/godot"), Path(".tools/Godot")):
            candidate = root / relative
            if candidate.is_file() and os.access(candidate, os.X_OK):
                return candidate.resolve()
    for command in ("godot", "Godot"):
        candidate = shutil.which(command, path=context.environ.get("PATH", ""))
        if candidate:
            return Path(candidate).resolve()
    raise DevError(
        "Godot was not found. Set CINDER_GODOT to an absolute executable path, "
        "configure .cinder/local.json, place Godot in .tools, or add it to PATH."
    )


def shared_lock_path(root: Path) -> Path:
    common = git_directory(root, "--git-common-dir")
    if common is not None:
        # Discover the primary checkout from shared Git identity, not local
        # canonical_root config, which could otherwise split a worktree lock.
        primary = common.parent
        if common.name == ".git" and (primary / "project.godot").is_file() and git_directory(primary, "--git-dir") == common:
            return primary / ".cinder/locks/godot.lock"
        # Separate/bare Git directories cannot reliably identify a checkout.
        return common / "cinder-dev/godot.lock"
    return root / ".cinder/locks/godot.lock"


@contextlib.contextmanager
def godot_lock(root: Path):
    path = shared_lock_path(root)
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        lock = path.open("a+")
    except OSError as exc:
        raise DevError(f"Cannot open shared Godot lock {path}: {exc}") from exc
    try:
        try:
            fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print("Waiting for the shared Godot session to close…", flush=True)
            fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
        os.set_inheritable(lock.fileno(), True)
        yield lock.fileno()
    finally:
        # Do not LOCK_UN: a running child inherits this same open description.
        # Closing our copy leaves its lock in place until the last child exits.
        lock.close()


def run_child(command: list[str], context: ProjectContext, lock_fd: int | None = None) -> int:
    # subprocess.call/run kill a child when the wrapper raises KeyboardInterrupt.
    # Keep ownership explicit so closing a terminal does not auto-kill an editor.
    child = subprocess.Popen(
        command, cwd=context.root, env=context.environ,
        pass_fds=() if lock_fd is None else (lock_fd,),
    )
    return child.wait()


def stop_validation(child: subprocess.Popen) -> None:
    """Stop only a noninteractive subprocess this wrapper created."""
    if child.poll() is None:
        child.terminate()
        try:
            child.wait(timeout=5)
        except subprocess.TimeoutExpired:
            child.kill()
            child.wait(timeout=5)


def run_validation(
    command: list[str], context: ProjectContext, lock_fd: int | None,
    timeout: float, *, detect_godot_errors: bool = True,
) -> int:
    """Stream bounded checks and reject script errors even when Godot exits 0."""
    child = subprocess.Popen(
        command, cwd=context.root, env=context.environ,
        pass_fds=() if lock_fd is None else (lock_fd,),
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, errors="replace", bufsize=1,
    )
    lines = queue.Queue()

    def read_output():
        try:
            with child.stdout:
                for line in child.stdout:
                    lines.put(line)
        finally:
            lines.put(None)

    reader = threading.Thread(target=read_output, daemon=True)
    reader.start()
    deadline = time.monotonic() + timeout

    def drain_output():
        reader.join(timeout=1)
        while not lines.empty():
            line = lines.get_nowait()
            if line is not None:
                sys.stdout.write(line)
        sys.stdout.flush()

    def timed_out():
        print(f"Cinder dev: validation timed out after {timeout:g}s; stopping its owned subprocess.", file=sys.stderr)
        stop_validation(child)
        drain_output()
        return 124

    try:
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                return timed_out()
            try:
                line = lines.get(timeout=min(0.2, remaining))
            except queue.Empty:
                continue
            if line is None:
                try:
                    return child.wait(timeout=max(0.0, deadline - time.monotonic()))
                except subprocess.TimeoutExpired:
                    return timed_out()
            sys.stdout.write(line)
            sys.stdout.flush()
            if detect_godot_errors and SCRIPT_FAILURE.search(line):
                print("Cinder dev: Godot reported a script or project-resource error; validation failed.", file=sys.stderr)
                stop_validation(child)
                drain_output()
                return 1
    except KeyboardInterrupt:
        stop_validation(child)
        drain_output()
        raise


def editor_arguments(context: ProjectContext, arguments: list[str]) -> list[str]:
    result = list(arguments)
    ports = SLOT_PORTS.get(context.slot or "integration")
    flags = result[:result.index("--")] if "--" in result else result
    for flag, value in zip(
        ("--lsp-port", "--dap-port", "--debug-server"),
        (str(ports[0]), str(ports[1]), f"tcp://127.0.0.1:{ports[2]}"),
    ):
        if not any(argument == flag or argument.startswith(flag + "=") for argument in flags):
            # Insert before any user-argument separator; later args belong to the game.
            index = result.index("--") if "--" in result else len(result)
            result[index:index] = [flag, value]
    return result


def suite_paths(context: ProjectContext, suite: str = "all") -> list[str]:
    names = list(SUITES) if suite == "all" else [suite]
    selected = []
    for name in names:
        relative = SUITES[name]
        if not (context.root / relative).is_file():
            if suite == "all" and name == "level_contract":
                continue
            raise DevError(f"Smoke suite is missing: {relative}")
        selected.append("res://" + relative)
    return selected


def scene_uri(context: ProjectContext, value: str) -> str:
    text = value.removeprefix("res://")
    candidate = Path(text)
    if not candidate.is_absolute():
        candidate = context.root / candidate
    candidate = candidate.resolve()
    try:
        relative = candidate.relative_to(context.root)
    except ValueError as exc:
        raise DevError("Level scene must be inside the current checkout.") from exc
    if candidate.suffix not in {".tscn", ".scn"} or not candidate.is_file():
        raise DevError(f"Level scene does not exist or is not a Godot scene: {value}")
    return "res://" + relative.as_posix()


def ability_command(context: ProjectContext, arguments: list[str]) -> list[str]:
    return design_command(context, arguments, "ability", "scripts/design/ability_usage.py", ABILITY_COMMANDS)


def equipment_command(context: ProjectContext, arguments: list[str]) -> list[str]:
    return design_command(context, arguments, "equipment", "scripts/design/equipment_grid.py", EQUIPMENT_COMMANDS)


def design_command(context: ProjectContext, arguments: list[str], name: str, script: str, choices: set[str]) -> list[str]:
    for argument in arguments:
        if argument in {"--root", "--ledger"} or argument.startswith(("--root=", "--ledger=")):
            raise DevError(f"The {name} proxy fixes the canonical root and ledger; root/ledger overrides are forbidden.")
    if arguments and arguments[0] not in choices | {"--help", "-h"}:
        raise DevError(f"Unknown {name} command. Run 'dev.py {name} --help' for stable registry commands.")
    root = context.design_root(script)
    return [sys.executable, str(root / script), "--root", str(root), *(arguments or ["--help"])]


def export_template_directory(version: str | None, environ: dict) -> Path | None:
    match = re.match(r"(\d+\.\d+(?:\.\d+)?\.(?:stable|beta\d*|rc\d*))", version or "")
    if not match:
        return None
    if sys.platform == "darwin":
        parent = Path.home() / "Library/Application Support/Godot/export_templates"
    elif sys.platform == "win32":
        parent = Path(environ.get("APPDATA", str(Path.home()))) / "Godot/export_templates"
    else:
        parent = Path(environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share"))) / "godot/export_templates"
    return parent / match.group(1)


def doctor(context: ProjectContext) -> int:
    print(f"Checkout: {context.root}")
    print(f"Slot: {context.slot or 'standalone'}")
    print(f"Canonical root: {context.canonical_root} ({'explicit' if context.canonical_explicit else 'standalone default'})")
    print(f"Shared Godot lock: {shared_lock_path(context.root)}")
    git_status = git_output(context.root, "status", "--porcelain", "--untracked-files=normal")
    if git_status is None:
        print("Git: unavailable or not a repository")
    else:
        branch = git_output(context.root, "branch", "--show-current") or "detached HEAD"
        print(f"Git: {branch}; {len(git_status.splitlines()) if git_status else 0} changed/untracked entries")
    disk = shutil.disk_usage(context.root)
    print(f"Disk free: {disk.free / (1024 ** 3):.1f} GiB")
    version = None
    missing_engine = False
    try:
        godot = resolve_godot(context)
        result = subprocess.run(
            [str(godot), "--version"], capture_output=True, text=True,
            cwd=context.root, env=context.environ, timeout=15, check=False,
        )
        version = result.stdout.strip().splitlines()[0] if result.stdout.strip() else None
        print(f"Godot: {godot}; {version or 'version query failed'}")
        missing_engine = result.returncode != 0 or not version
    except (DevError, OSError, subprocess.TimeoutExpired) as exc:
        print(f"Godot: {exc}")
        missing_engine = True
    project = (context.root / "project.godot").read_text(encoding="utf-8")
    baseline = re.search(r'config/features=PackedStringArray\("([^\"]+)"', project)
    print(f"Project feature baseline: Godot {baseline.group(1) if baseline else 'not recorded'}")
    if version and baseline and not version.startswith(baseline.group(1) + "."):
        print("Engine/project baseline differs; run check before relying on this checkout.")
    cache = context.root / ".godot/global_script_class_cache.cfg"
    present = [name for name, relative in SUITES.items() if (context.root / relative).is_file()]
    print(f"Import cache: {'present' if cache.is_file() else 'missing'}; smoke suites present: {', '.join(present) or 'none'}")
    print("Baseline readiness: unverified by doctor; run check for import and smoke results.")
    print("When designing a level's playstyle: dev.py equipment status (canonical equipment grid and creation claims).")
    templates = export_template_directory(version, context.environ)
    for label, files in (("iOS", ("ios.zip",)), ("Android", ("android_debug.apk", "android_release.apk"))):
        installed = templates is not None and all((templates / name).is_file() for name in files)
        print(f"{label} export templates: {'present' if installed else 'missing or version unknown'}")
    print(f"Export presets: {'present' if (context.root / 'export_presets.cfg').is_file() else 'not configured'}")
    print(f"iOS xcodebuild command: {'available' if shutil.which('xcodebuild', path=context.environ.get('PATH', '')) else 'missing'}")
    sdk = context.environ.get("ANDROID_HOME") or context.environ.get("ANDROID_SDK_ROOT")
    sdk_ready = bool(sdk) and (Path(sdk) / "platforms").is_dir() and (Path(sdk) / "build-tools").is_dir()
    print(f"Android SDK environment: {'platforms/build-tools present' if sdk_ready else 'missing or incomplete'}")
    print(f"Java command: {'available' if shutil.which('java', path=context.environ.get('PATH', '')) else 'missing'}")
    print("Export status is an inventory; signing and device performance are not validated.")
    return 1 if missing_engine else 0


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    commands = result.add_subparsers(dest="command", required=True)
    commands.add_parser("doctor", help="Report local engine, baseline, Git, disk and export prerequisites.")
    commands.add_parser("import", help="Import this checkout headlessly, then quit.")
    commands.add_parser("check", help="Import and run all present smoke suites in one locked session.")
    tests = commands.add_parser("test", help="Run one smoke suite or all (without reimporting).")
    tests.add_argument("suite", nargs="?", default="all", choices=["all", *SUITES])
    run = commands.add_parser("run", help="Play the shared entry scene, optionally with a level contract.")
    run.add_argument("--level-scene", help="Repository-relative or res:// Godot scene for the shared controller.")
    commands.add_parser("editor", help="Open the editor using this slot's LSP/DAP/debug ports.")
    commands.add_parser("engine", help="Pass raw arguments to Godot (used by the VS Code executable wrapper).")
    commands.add_parser("ability", help="Proxy ledger commands to the canonical root; use ability --help.")
    commands.add_parser("equipment", help="Proxy equipment grid/creation claims to the canonical root; use equipment --help.")
    return result


def main(argv: list[str] | None = None) -> int:
    arguments = list(sys.argv[1:] if argv is None else argv)
    try:
        # These commands deliberately preserve the underlying tool's arguments.
        if arguments and arguments[0] in {"ability", "equipment", "engine"}:
            command, forwarded = arguments[0], arguments[1:]
            context = ProjectContext()
            if command == "ability":
                return run_child(ability_command(context, forwarded), context)
            if command == "equipment":
                return run_child(equipment_command(context, forwarded), context)
            godot = resolve_godot(context)
            engine_args = list(forwarded)
            flags = engine_args[:engine_args.index("--")] if "--" in engine_args else engine_args
            if "--version" in flags or "--help" in flags or "-h" in flags:
                return run_child([str(godot), *engine_args], context)
            if "--editor" in flags or "-e" in flags:
                engine_args = editor_arguments(context, engine_args)
            with godot_lock(context.root) as lock_fd:
                return run_child([str(godot), *engine_args], context, lock_fd)
        options = parser().parse_args(arguments)
        context = ProjectContext()
        if options.command == "doctor":
            return doctor(context)
        godot = resolve_godot(context)
        base = [str(godot), "--path", str(context.root)]
        commands = []
        if options.command in {"import", "check"}:
            commands.append([*base, "--headless", "--import"])
        if options.command in {"check", "test"}:
            suites = suite_paths(context, getattr(options, "suite", "all"))
            commands.extend([*base, "--headless", "--script", suite] for suite in suites)
        if options.command == "check" and (context.canonical_root / "scripts/design/equipment_grid.py").is_file():
            commands.append(equipment_command(context, ["validate"]))
        if options.command == "run":
            commands.append(base)
            if options.level_scene:
                commands[-1].extend(["--", "--level-scene=" + scene_uri(context, options.level_scene)])
        if options.command == "editor":
            commands.append(editor_arguments(context, [*base, "--editor"]))
        with godot_lock(context.root) as lock_fd:
            for command in commands:
                print(("Godot: " if command[0] == str(godot) else "Design: ") + " ".join(command[1:]), flush=True)
                if options.command in {"import", "check", "test"}:
                    is_godot = command[0] == str(godot)
                    timeout = IMPORT_TIMEOUT if "--import" in command or not is_godot else TEST_TIMEOUT
                    code = run_validation(command, context, lock_fd, timeout, detect_godot_errors=is_godot)
                else:
                    code = run_child(command, context, lock_fd)
                if code:
                    return code
        return 0
    except (DevError, OSError) as exc:
        print(f"Cinder dev: {exc}", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        print("Cinder dev: interrupted; any still-running Godot child retains the shared lock.", file=sys.stderr)
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
