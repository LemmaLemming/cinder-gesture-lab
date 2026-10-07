# Cinder Gesture Lab

A bare-bones Godot mechanics test for the red/black 2.5D game. The character is a pixel sprite that can dash in any direction across the floor. Every voluntary move comes from a swipe. A close, fixed-angle camera follows the player in a portrait view. There is one test arena, three enemy variants, a sword, a short-range shotgun, and square debris with gravity, collision, bounce, and cleanup.

The [game concept and campaign plan](docs/GAME_CONCEPT.md#planned-campaign) records the planned acts, including **Tormance — The False World**, inspired by David Lindsay's *A Voyage to Arcturus*. Campaign bosses, chapter palettes, weapon replacement, and powerups are currently planning concepts.

## Play

Open `project.godot` with Godot 4.7.2, then click Play in the editor. On this Mac the engine is at `.tools/Godot.app`; `Play.command` and `Edit.command` launch it from Finder. The launchers also find a Godot app in Applications or `godot` on PATH. Play opens a dedicated full-screen macOS Space.

For a fresh clone, download the **standard** macOS build from [Godot’s official download page](https://godotengine.org/download/archive/4.7.2-stable/) and extract `Godot.app` into `.tools/`. On other operating systems, open `project.godot` with the corresponding Godot 4.7.2 editor. No third-party packages are required.

- **Swipe:** dash in the swipe direction. Any angle works, and diagonal dashes travel the same distance. A swipe triggers one dash; another swipe can queue the next dash during the short cooldown.
- **Tap:** slash in the direction from the last swipe's final finger-release position toward the tap. For example, release a swipe at the upper left and tap the center to strike down-right. The anchor stays at that screen position until the next swipe; camera movement does not move it. Before the first swipe, the anchor is screen center. Tapping exactly on the anchor keeps the last facing direction.
- **Double tap:** slash, then fire the shotgun on the second tap. The first slash happens immediately.
- **Tap Reset:** restore the arena.

On a Mac, click is a tap and dragging with the mouse is a swipe. There is no keyboard or virtual-stick movement. The shotgun has two shells, automatically reloads, and launches enemies at close range. Landing sword hits speeds up shell reload. Defeated enemies drop a core that attracts toward the player.

The virtual display is 540 × 1170 in portrait, with portrait orientation requested on mobile and letterboxing on wider desktop displays. The camera is zoomed closer by narrowing its orthographic width to 7.2 world units; the sprite's world size is unchanged. Attack direction is exact, without automatic target redirection.

Touch events are implemented, but this version has only been tested on the Mac. iOS/Android packages and real-device performance testing remain future work. The project uses the Compatibility renderer.

## Development

Godot 4.7.2 came from the official download and matched its SHA-512 checksum. macOS accepted it as a notarized developer build. It is kept locally in `.tools`, which is excluded from Git.

Run `godot --headless --path . --editor --quit` to import/check the project, then `godot --headless --path . --script tests/mechanics_smoke.gd` for mechanics integration checks. On this Mac replace `godot` with `./.tools/Godot.app/Contents/MacOS/Godot`. The latest smoke run passed 71 checks covering portrait camera follow, swipe-release aiming, exact attack direction, gestures, dash behavior, collisions, combat, ammo, reload, and debris cleanup. A rendered run also verified gesture dispatch and portrait framing.

## Reusable design skill

[`skills/game-design-mechanics/SKILL.md`](skills/game-design-mechanics/SKILL.md) turns the two requested video reviews into guidance for mechanics prototypes, learning curves, and persistent progression. Its [source notes](skills/game-design-mechanics/references/progression-videos.md) contain the summaries, timestamps, and limits of the review. It is also installed locally for use as `$game-design-mechanics` in Codex.

## Repository layout

- `project.godot` — open this in Godot.
- `scenes/` — entry scene.
- `scripts/` — gestures, player, enemies, pixel sprites, physics effects, and HUD.
- `tests/` — bounded integration checks.
- `docs/` — [game concept and campaign plan](docs/GAME_CONCEPT.md).
- `skills/` — reusable game design guidance and video source notes.
- `.tools/` — local engine download, excluded from Git.
- `.godot/`, `captures/`, and `exports/` — generated local files, excluded from Git.

Keep Godot `.gd.uid` files with their scripts; they preserve stable resource references.
