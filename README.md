# Cinder Character Lab

A playable Godot character and equipment test for Cinder's portrait pixel 2.5D game. One shared helmeted astronaut traveller dashes in any direction across the floor, aims from the latest swipe's final screen release and uses a close slash with an optional short-range blast. The lab includes safe targets, one-enemy and three-enemy exercises, nine static clothing presets, four replaceable weapon profiles, one long dash smoke plume, a slower pale slash arc, bright shotgun flares and tiny impact flecks. [Character Lab instructions and implementation scope](docs/CHARACTER_LAB.md) record controls, starter IDs, resets and asset readiness.

The current campaign work targets all fifteen main levels and nine documented optional levels on desktop. Protagonist headwear follows each act's selected concept art, as presentation without a slot or stat bonus; one shared controller, equipment system, collision body, feet pivot and action/facing language remain. The helmeted lab sheets record the earlier prototype appearance. Concept-derived act presentations have passed native and shared portrait fixture checks; authored campaign content and its encounter/scenery validation remain in progress. Mobile export and release follow this desktop endpoint.

The [game concept and campaign plan](docs/GAME_CONCEPT.md#planned-campaign) records the planned acts, including **Tormance — The False World**, inspired by David Lindsay's *A Voyage to Arcturus*. Campaign levels/bosses and selected conditional perks/temporary powerups remain in progress. The tested shared desktop shell provides coherent saves/checkpoint retry and isolated story/side attempts over readiness-gated metadata. Static equipment, armour, comparison and safe weapon replacement are implemented in the separate lab.

The [UI design plan](docs/UI_DESIGN_PLAN.md) records the title screen, a winding journey menu with main levels and optional branches, and customizable replays that automatically restore the story equipment and checkpoint. It includes a saved interactive layout reference; campaign menus and separate story/replay saves now have tested live fixture consumers. Real scenes appear as Awaiting integration until individually accepted.

The [main character and equipment guidelines](docs/PLAYER_EQUIPMENT_GUIDELINES.md) define one shared character kit across all three acts, replaceable jackets/pants/shoes and weapon profiles, temporary pickup rules, 14 conditional ability proposals and provisional balance budgets. [Machine-readable design data](data/design/player_equipment.json) supplies the lab's static numbers and stable IDs; the [research notes](docs/research/EQUIPMENT_BALANCE_RESEARCH.md) separate six primary developer sources from original Cinder proposals. Carrying equipment between acts is a campaign requirement; the lab keeps gear when changing or resetting exercises. Passed numerical checks do not establish human balance.

Future agents should begin with [AGENTS.md](AGENTS.md), then the durable [campaign memory](docs/development/CAMPAIGN_MEMORY.md), [shared API/ownership contract](docs/development/SHARED_CONTRACT.md) and [integration progress](docs/development/SHARED_PROGRESS.md). The [shared style and motion guidelines](docs/GAME_STYLE_GUIDELINES.md) cover pixel scale, animation timing, acceleration/momentum and consistent interaction cues across acts. The [asset reuse guide](docs/ASSET_REUSE_GUIDE.md) maps existing code and modular art references to reuse opportunities, with production-readiness limits and parent-kit rules for optional levels. These guides do not implement campaign assets or mechanics.

The [difficulty design plan](docs/DIFFICULTY_DESIGN.md) proposes a campaign learning curve, Assisted/Standard/Challenge presets, shared attack scheduling and a bounded arena playtest. Difficulty settings and campaign scheduling remain unimplemented; the proposed numbers need portrait-view playtesting.

The [ability usage workflow](docs/ABILITY_USAGE_WORKFLOW.md) gives level-building agents a campaign-wide ledger for introductions, reservations and meaningful variants. Run `python3 scripts/dev/dev.py ability status` from a configured checkout to see what is available or already allocated across main and optional levels in the canonical ledger. [ability_usage.json](data/design/ability_usage.json) tracks stable mechanical identities and placement history; [AGENTS.md](AGENTS.md) makes reserving and validating abilities part of the repository workflow. Renaming, reskinning or retuning an ability does not make it new. Carried equipment and the shared core controls remain usable.

Act 1's [design document](docs/ACT1_CONCEPT.md) develops five newcomer levels over 43 minutes, with three optional levels that reuse the parent kits. Its expanded [film database and offline gallery](docs/reference-library/act1/index.html) cover the identifiable cast, environments, boss candidates, story mood, props and historical references. The [concept-art collection](docs/concept-art/act1/README.md) adds character, environment, boss, mood and prop boards, plus three portrait game-view proposals. JSON, CSV, SQLite, source credits and generation prompts are included; campaign content remains unimplemented.

Act 2's [design document](docs/ACT2_CONCEPT.md) proposes five levels over 45 minutes for experienced players, drawing on *The War of the Worlds*. Its [novel database and offline gallery](docs/reference-library/act2/README.md) and [concept-art folders](docs/concept-art/act2/README.md) cover the cast, settings, machines, bosses, story mood and three illustrative game views. These are research and design artifacts; the playable prototype remains the mechanics arena.

Act 3's [novel research and concept gallery](docs/reference-library/act3/index.html) covers *A Voyage to Arcturus* with JSON/CSV/SQLite exports and [20 concept images](docs/concept-art/act3/README.md). The [Act 3 proposal](docs/ACT3_CONCEPT.md) targets five main levels in 45 minutes for an experienced player.

## Play

Default Play still opens the Character Lab while the campaign opening is awaiting acceptance. To inspect the tested desktop Title/Journey/settings shell, run `python3 scripts/dev/dev.py engine --path . res://scenes/campaign_main.tscn`; its scene readiness gates deliberately prevent launching unfinished levels. Campaign RETRY restores coherent checkpoint resources and encounter state; the lab RESET below creates fresh resources.

Open `project.godot` with Godot 4.7.2, then click Play in the editor. On this Mac the engine is at `.tools/Godot.app`; `Play.command` and `Edit.command` launch it from Finder. The launchers also find a Godot app in Applications or `godot` on PATH. Play opens a dedicated full-screen macOS Space.

For a fresh clone, download the **standard** macOS build from [Godot’s official download page](https://godotengine.org/download/archive/4.7.2-stable/) and extract `Godot.app` into `.tools/`. On other operating systems, open `project.godot` with the corresponding Godot 4.7.2 editor. No third-party packages are required.

- **Swipe:** dash in the swipe direction. Any angle works, and diagonal dashes travel the same distance. A swipe triggers one dash; another swipe can queue the next dash during the short cooldown.
- **Tap:** slash in the direction from the last swipe's final finger-release position toward the tap. For example, release a swipe at the upper left and tap the center to strike down-right. The anchor stays at that screen position until the next swipe; camera movement does not move it. Before the first swipe, the anchor is screen center. Tapping exactly on the anchor keeps the last facing direction.
- **Double tap:** slash, then fire the shotgun on the second tap. The first slash happens immediately.
- **Tap Reset:** restore the arena.

On a Mac, click is a tap and dragging with the mouse is a swipe. There is no keyboard or virtual-stick movement. The starter is Standard Jacket/Pants/Shoes (`CLOTH-J0`, `CLOTH-P0`, `CLOTH-S0`) and Balanced Edge (`WEAPON-01`). One carried weapon profile governs both attacks. The blast has two shells and automatic reload; accepted living-enemy slash hits earn reload progress once per action. Practice targets give feedback without reload rewards. Defeated enemies drop a core that increments a counter.

Tap **LOADOUT** to pause and compare resolved gear values, then use the top **RESUME** control to return. Clothing changes require a safe boundary with no enemies. **TARGETS**, **ONE ENEMY** and **THREE ENEMIES** select bounded exercises. **RESET** or selecting an exercise explicitly restores full HP/shells and fresh targets/pickup supplies while keeping your gear. Application focus loss/backgrounding also pauses; resuming consumes its UI tap. Contact with a marked weapon stand replaces the carried profile after an ongoing action phase finishes, preserving shells, reload progress and remaining cooldowns. Each stand is finite until reset.

The virtual display is 540 × 1170 in portrait, rendered through a nearest-filtered 270 × 585 gameplay viewport. The fixed-angle camera has a 7.2-unit orthographic width and eases toward the player with a 0.16-second follow time constant: faster while farther behind, slower as it settles. Reset snaps it to the fresh player. The more detailed 48 × 64 helmeted sprite keeps the same world size and collision body. Attack direction remains exact.

Touch events are implemented, but this version has only been tested on the Mac. iOS/Android packages and real-device performance testing remain future work. The project uses the Compatibility renderer.

## Development

The [parallel act development workflow](docs/development/PARALLEL_ACT_DEVELOPMENT.md) and [setup record](docs/development/SETUP_RECORD.md) describe the VSCode workspace, official Godot Tools extension, shared level-preview entry point and three-agent ownership rules. Run `python3 scripts/dev/dev.py doctor` to inspect this checkout and `python3 scripts/dev/dev.py check` for serialized import and smoke checks. Generate this checkout's ignored machine settings with `python3 scripts/dev/setup_vscode.py --slot integration --canonical-root "$PWD"`, then open `.cinder/cinder.code-workspace` in VSCode. Act worktrees use their own slot and the same absolute canonical root.

When deciding a level's playstyle, consult [the equipment design grid](docs/EQUIPMENT_DESIGN_GRID.md). Its live catalogue and shared creation claims prevent three workers independently creating the same equipment type; the existing ability ledger separately coordinates campaign introductions. The grid review is triggered by playstyle decisions, not every startup.

Godot 4.7.2 came from the official download and matched its SHA-512 checksum. macOS accepted it as a notarized developer build. It is kept locally in `.tools`, which is excluded from Git.

Use `python3 scripts/dev/dev.py check` for queued import, all available smoke suites (including the shared level contract) and canonical equipment-grid validation. Use `python3 scripts/dev/dev.py test SUITE` to rerun an affected suite; see the parallel workflow for available commands and shared resource scheduling. Verified runs passed **78 mechanics, 50 equipment, 39 character-lab and 102 visual-effects checks**. They cover eased portrait camera follow, gestures, static stats, safe swaps, action snapshots, accepted-hit/reload rules, slower cosmetic clocks, pause, consumed resume input, connected actual-path smoke, barrel-origin flares and tiny blood/debris cleanup. See [Character Lab validation and limits](docs/CHARACTER_LAB.md#validation-and-limits); these checks do not establish human encounter balance or mobile-device performance.

Run `python3 scripts/design/validate_equipment.py` to check the proposed equipment catalogue's item budgets, combined loadouts, temporary effects and numerical fixtures. This numerical screen does not simulate touch cadence or verify encounter balance.

Run `python3 scripts/design/ability_usage.py validate` to check ability identities, lifecycle records and campaign allocation conflicts. Run `python3 -m unittest discover -s tests -p 'test_ability_usage.py'` for the ledger's CLI and concurrency regression checks.

## Reusable design skill

[`skills/game-design-mechanics/SKILL.md`](skills/game-design-mechanics/SKILL.md) turns the two requested video reviews into guidance for mechanics prototypes, learning curves, and persistent progression. Its [source notes](skills/game-design-mechanics/references/progression-videos.md) contain the summaries, timestamps, and limits of the review. It is also installed locally for use as `$game-design-mechanics` in Codex.

## Repository layout

- `project.godot` — open this in Godot.
- `scenes/` — entry scene, reusable player/target scenes and editable lab arena.
- `scripts/` — gestures, player, static equipment resolver, loadout comparison, targets/pickups, enemies, pixel sprites, physics effects and HUD.
- `tests/` — bounded integration checks.
- `docs/` — [game concept and campaign plan](docs/GAME_CONCEPT.md).
- `data/design/` — canonical character/equipment numbers and structured catalogue; the lab loads the static subset, while perk/powerup records remain proposals.
- `assets/characters/` — original 48 × 64-cell helmeted player atlases and provenance/readiness manifest.
- `assets/references/` — original generated astronaut turnaround used as a visual model, separate from runtime cells.
- `skills/` — reusable game design guidance and video source notes.
- `.tools/` — local engine download, excluded from Git.
- `.godot/`, `captures/`, and `exports/` — generated local files, excluded from Git.

Keep Godot `.gd.uid` files with their scripts; they preserve stable resource references.
