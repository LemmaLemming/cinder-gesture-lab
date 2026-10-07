# Cinder Gesture Lab

A bare-bones Godot mechanics test for the red/black 2.5D game. The character is a pixel sprite that can dash in any direction across the floor. Every voluntary move comes from a swipe. There is one test arena, three enemy variants, a sword, a short-range shotgun, and square debris with gravity, collision, bounce, and cleanup.

## Play

Open `project.godot` with Godot 4.7.2, then click Play in the editor. On this Mac the engine is at `.tools/Godot.app`; `Play.command` and `Edit.command` launch it from Finder. The launchers also find a Godot app in Applications or `godot` on PATH. Play opens a dedicated full-screen macOS Space.

For a fresh clone, download the **standard** macOS build from [Godot’s official download page](https://godotengine.org/download/archive/4.7.2-stable/) and extract `Godot.app` into `.tools/`. On other operating systems, open `project.godot` with the corresponding Godot 4.7.2 editor. No third-party packages are required.

- **Swipe:** dash in the swipe direction. Any angle works, and diagonal dashes travel the same distance. A swipe triggers one dash; another swipe can queue the next dash during the short cooldown.
- **Tap:** slash toward the tap. Nearby targets receive a little aim assistance.
- **Double tap:** slash, then fire the shotgun on the second tap. The first slash happens immediately.
- **Tap Reset:** restore the arena.

On a Mac, click is a tap and dragging with the mouse is a swipe. There is no keyboard or virtual-stick movement. The shotgun has two shells, automatically reloads, and launches enemies at close range. Landing sword hits speeds up shell reload. Defeated enemies drop a core that attracts toward the player.

Touch events are implemented, but this version has only been tested on the Mac. iOS/Android packages and real-device performance testing remain future work. The project uses landscape orientation and the Compatibility renderer.

## Development

Godot 4.7.2 came from the official download and matched its SHA-512 checksum. macOS accepted it as a notarized developer build. It is kept locally in `.tools`, which is excluded from Git.

Run `godot --headless --path . --editor --quit` to import/check the project, then `godot --headless --path . --script tests/mechanics_smoke.gd` for mechanics integration checks. On this Mac replace `godot` with `./.tools/Godot.app/Contents/MacOS/Godot`. The latest test run passed 52 checks covering gestures, dash behavior, collisions, combat, ammo, reload, and debris cleanup.

## Repository layout

- `project.godot` — open this in Godot.
- `scenes/` — entry scene.
- `scripts/` — gestures, player, enemies, pixel sprites, physics effects, and HUD.
- `tests/` — bounded integration checks.
- `docs/` — [confirmed design](docs/GAME_CONCEPT.md).
- `.tools/` — local engine download, excluded from Git.
- `.godot/`, `captures/`, and `exports/` — generated local files, excluded from Git.

Keep Godot `.gd.uid` files with their scripts; they preserve stable resource references.
