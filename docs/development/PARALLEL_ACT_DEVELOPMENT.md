# Parallel act development with Godot and VSCode

Cinder uses Godot 4.7.2 and GDScript. Three act workers can author independent content while an integration owner maintains the shared game. Start with one greybox level per act, integrate those, then complete each act one level at a time toward the authorized desktop campaign of fifteen main and nine optional levels. The current playable content is the Character Lab; this setup supplies development infrastructure, not completed acts, production art, campaign menus or saves.

Read [AGENTS.md](../../AGENTS.md) and the [setup record](SETUP_RECORD.md). The existing campaign, style, reuse and act-specific reading requirements still apply before changing game content. Protagonist headwear follows selected act concept art as presentation without a slot or bonuses. Retain one shared player/controller/stat/equipment system, collision, feet pivot and readable action/facing language. Portrait gesture meanings and warning → lock → active → recovery remain consistent.

## Ownership

| Owner | Content it changes | Shared dependencies |
| --- | --- | --- |
| Integration owner | `scripts/game.gd`, `scripts/campaign/`, shared player/equipment/HUD/effects, `project.godot`, canonical design catalogues, tooling and campaign/menu/save systems | Reviews requests from all acts and integrates one act change at a time |
| Act 1 worker | `scenes/acts/act1/`, `scripts/acts/act1/`, `assets/acts/act1/`, `data/campaign/act1/`, Act 1 encounter notes/tests | Campaign/style/reuse rules, shared core and equipment grid |
| Act 2 worker | Corresponding `act2/` paths and Act 2 encounter notes/tests | Same shared systems; Act 2 adaptation boundaries |
| Act 3 worker | Corresponding `act3/` paths and Act 3 encounter notes/tests | Same shared systems; Act 3 adaptation boundaries |

The integration owner can be the coordinating agent; it need not run a fourth game/editor. Workers propose changes to shared systems instead of copying those systems into their act. Existing art and concepts outside act-owned runtime paths remain reference material. Use distinct script class names, resource paths, node groups and stable level/entity IDs. Commit `.gd.uid` sidecars with their scripts. Each checkout has its own `.godot/` cache; never share or commit that cache.

## Common baseline and worktrees

Before dispatching act workers, select a common reviewed commit containing the current prototype and this setup. Worktrees do not copy uncommitted changes; a fresh worktree from an older commit may omit the shared contract or current assets. Verify the selected commit and avoid starting workers from different versions of shared systems.

Create three separate linked Git worktrees from that baseline with branches such as `codex/act1`, `codex/act2` and `codex/act3`. Reuse existing suitable worktrees when present. Use the Codex managed-worktree capability when available; creating these preparatory files does not itself create worktrees or launch act workers. A plain subagent in this chat shares its parent's filesystem: it does not automatically obtain a separate worktree. Supply an explicit assigned checkout to each worker.

In each worktree, run the setup generator with its slot and the absolute integration root:

```sh
python3 scripts/dev/setup_vscode.py --slot act1 --canonical-root '/absolute/path/to/integration-checkout'
python3 scripts/dev/dev.py doctor
```

Repeat with `act2` and `act3` in their corresponding checkouts. The generator writes ignored `.cinder/local.json` and `.cinder/cinder.code-workspace`. Engine paths are local settings, not tracked machine-specific values. The three workers can share the integration root's installed engine instead of copying `.tools/`.

Open each generated workspace in VSCode. The official extension is `geequlim.godot-tools`, from [godotengine/godot-vscode-plugin](https://github.com/godotengine/godot-vscode-plugin). Tracked `.vscode/` files supply recommendations, tasks, indentation and generated-file exclusions. The generated workspace supplies the exact engine wrapper and slot ports.

| Slot | GDScript language server | Godot DAP | Godot Tools debugger |
| --- | ---: | ---: | ---: |
| integration | 6005 | 6006 | 6007 |
| act1 | 6015 | 6016 | 6017 |
| act2 | 6025 | 6026 | 6027 |
| act3 | 6035 | 6036 | 6037 |

Ports prevent a worktree connecting to another checkout's language server. They do not authorize four simultaneous Godot sessions. Headless language servers do not start automatically in the generated workspace. Completion becomes available while that checkout's editor is running; agents can edit files without an active language server.

## Shared level entry point

Author level roots as `CinderLevel`, defined in [level.gd](../../scripts/campaign/level.gd). A custom scene must be a project-local `.tscn`, have that root type and provide a `Marker3D` through its exported `spawn_path` (default `PlayerSpawn`). The spawn's world transform must place the shared player's feet over reachable floor, with collision clearance. Do not place a second player, camera, gesture recognizer or gameplay HUD in the level scene.

The shared shell instantiates the level beneath its world, creates the existing player/camera/effects and calls `enter_level(hero, effects)`. Implement `_on_enter_level()` for level-owned setup and `_on_exit_level()` for disconnecting callbacks and releasing externally owned resources. Store all enemies, encounter props and level-local state beneath the level or arrange explicit cleanup. `objective_text` supplies development HUD text. The shell's `load_level_scene(path)` validates a scene before replacing the active one and exposes `level_load_error` if validation fails.

Preview without changing `project.godot` or a common act registry:

```sh
python3 scripts/dev/dev.py run --level-scene res://scenes/acts/act1/a1_l1.tscn
```

Equivalent engine user argument: `-- --level-scene=res://...tscn`. Do not launch a level directly as the main scene: that bypasses the shared shell. Invalid startup selections exit with status 2. An empty selection starts the existing lab.

Custom previews use a resume-only pause overlay, no lab exercise/weapon stands, and a fresh selected-level instance on reset. Development reset keeps the static loadout, restores HP/ammo and clears transient input/effects. These are preview semantics, not a campaign checkpoint/save implementation. Campaign transitions, persistent progress, conditional abilities, temporary effects and final game menus still require shared implementation and relevant tests before dependent encounters claim support.

## Equipment gate when deciding playstyle

At the point of deciding or revising a level's playstyle, read [the equipment grid workflow](../EQUIPMENT_DESIGN_GRID.md) and query the live canonical grid. Inspect all three acts' reservations, catalogue types, benefits, drawbacks and ability introductions before selecting gear opportunities, pickups or rewards. This review is not required merely to open VSCode or perform an unrelated edit.

Write a short equipment decision record in the level notes: the intended player decision, catalogue IDs/type matches, ordinary-kit viability, active creation claim IDs and applicable ability use IDs. Existing equipment may be reused/carried; creating a renamed or retuned copy does not make a new type. Reserve a shared equipment creation task before building it, and reserve an ability introduction separately before placing it. Never turn an optional pickup or carried perk into a requirement for finishing a level.

All workers use the same canonical root. New catalogue types, balance formulas and shared equipment runtime are integrated by the shared owner. Act workers keep proposals in their own content paths until reviewed. Two branches independently editing the canonical catalogue or ledger would undermine the grid's purpose.

## Godot commands and resource scheduling

Use these commands from the assigned checkout:

```sh
python3 scripts/dev/dev.py doctor
python3 scripts/dev/dev.py import
python3 scripts/dev/dev.py check
python3 scripts/dev/dev.py test level_contract
python3 scripts/dev/dev.py editor
python3 scripts/dev/dev.py run
```

Godot jobs started by this tool or the VSCode engine wrapper share an advisory lock whose location derives from the common Git identity. In this repository it is the integration checkout's ignored `.cinder/locks/godot.lock`; linked worktrees resolve that same file independently of their local settings. The child inherits the lock; closing a wrapper does not release a still-running child's slot. A queued command waits and does not kill other applications. Existing Godot processes launched outside the wrapper are outside this queue. Close or finish those deliberately before relying on it.

An editor holds the slot for its lifetime. Close that queued editor before using the VSCode Godot Tools F5 launch profile; otherwise F5 correctly waits for the slot. While the queued editor is open, Godot's own Play control can run the game under that editor's session. Close a preview when done so another worker can import/test. Use the generated workspace's slot-specific debug profile; the tracked integration profile uses port 6007.

Initially serialize imports, smoke tests, previews and asset-export scripts. Mobile exports are outside the current desktop campaign scope. Parallel work should be file authoring, design and lightweight Python checks. Keep one engine session active at a time until a measured trial on this Mac supports a higher limit. Validation permits 300 seconds for import/design commands and 600 seconds per smoke suite; it stops only its own validation subprocess on timeout or a script/resource failure. Interactive sessions and other applications are never automatically terminated. No cache deletion or memory cleanup is part of this setup.

## Acceptance and integration

For each first greybox, the worker supplies its scene path, stable research level ID, playable objective, implementation status, equipment decision record, asset readiness notes, tests and remaining limitations. Use the existing act design instead of inventing extra bosses/mechanics from an illustration.

1. Run the changed level's targeted suite through `dev.py engine --headless --path . --script <owned-level-test.gd>` and directly affected named shared suites through `dev.py test`. The reviewed full baseline is already verified; a broad rerun requires a newly identified cross-system concern.
2. Inspect the actual portrait preview. Check spawn/floor contact, exact controls, warnings/source/safe landing, occlusion, ordinary-kit viability, pause/resume and reset cleanup.
3. Review changed files against ownership. Integrate one act change at a time without replacing canonical live ledgers with branch copies.
4. Rerun affected checks and portrait inspection after integration. Publish the updated shared baseline before workers depend on new shared APIs.

For equipment/ability changes, also run the numerical equipment validator, canonical ledger validation and relevant gameplay/identity tests. Automated structural matches and budget checks do not establish semantic novelty, balance, readable animation or phone performance.

The current authorized endpoint is an integrated, playable and tested desktop campaign with fifteen main levels and nine documented optional levels. Mobile export and subsequent release work follow that endpoint and do not gate campaign completion. Matching export templates, SDKs, signing, physical-device background/resume behavior, touch cadence, thermal/frame behavior and installable builds remain future iOS/Android release work; desktop smoke checks do not establish those results.

## Future worker prompt template

> Work in ASSIGNED_CHECKOUT on the assigned act branch. Read AGENTS.md and the parallel workflow, then the campaign/style/reuse/act references required for game content. Own only this act's assigned paths. Build one playable greybox for LEVEL_ID using CinderLevel and the shared shell; derive protagonist headwear from the selected act concept art while preserving the shared actor/equipment system, collision, feet pivot, action/facing language, controls, camera and cue meanings. Headwear has no slot or bonuses. When deciding the level's playstyle, consult the canonical equipment grid, record existing type matches and reserve any creation work before building it. Reserve perk/powerup introductions separately through the canonical ability CLI. Use dev.py for queued Godot jobs. Report portrait validation, tests, asset readiness and unimplemented dependencies. Request shared API/catalogue changes from the integration owner rather than forking shared systems.

## Official references

- [Godot external editor support](https://docs.godotengine.org/en/stable/tutorials/editor/external_editor.html).
- [Official Godot Tools extension](https://github.com/godotengine/godot-vscode-plugin).
- [Codex worktrees](https://learn.chatgpt.com/docs/environments/git-worktrees).
