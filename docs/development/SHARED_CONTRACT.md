# Cinder shared contract

Revision: **campaign-shared-1** (8 October 2026), composed of `campaign-level-1` and `world-actions-1`. Integration owns this document and shared runtime. Engine verification is recorded in shared progress; planned APIs below remain unavailable until a tested revision publishes them. See [campaign memory](CAMPAIGN_MEMORY.md) and [progress](SHARED_PROGRESS.md).

## Ownership and baseline

The canonical integration root is `/Users/howardchen/Documents/ChatGPT/video game idea`. Integration owns shared player/controller/stats, equipment catalogue and runtime, camera, HUD/menus, saves/campaign registry, scheduler, cues/effects, tooling, project settings and shared assets. Integration may delegate scoped shared work to helpers in its checkout; this does not create an act owner.

Act N owns only `scenes/acts/actN/`, `scripts/acts/actN/`, `assets/acts/actN/`, `data/campaign/actN/`, `tests/acts/actN/`, and `docs/acts/actN/`. Each act has one registered linked checkout and one `codex/` branch. Confirm worker identity in the run record before editing. No duplicate act owners or stale-status ownership takeover. Ask integration for shared changes; do not fork the player, cues, scheduler or persistence.

Use the exact reviewed baseline in the ignored run record. Worktrees do not carry uncommitted edits. Integrate one named level commit at a time, review ownership and exclude private ledgers/local settings. Commit `.gd.uid` sidecars with scripts; ignore `.godot`, `.tools`, `.cinder`, captures and exports.

## Compatible level-preview-1 APIs

`scripts/campaign/level.gd` defines `CinderLevel extends Node3D`:

| API | Implemented behavior |
| --- | --- |
| `spawn_path: NodePath` | Defaults to `PlayerSpawn`; must resolve to a `Marker3D`. Its world position places shared player feet over reachable floor, with collision clearance. |
| `objective_text: String` | Supplies custom-preview HUD objective text. |
| `contract_error() -> String` | Returns a spawn, canonical identity or local-version error, or empty string. Level authors still validate floor clearance themselves. |
| `spawn_position() -> Vector3` | Returns the marker's world position. |
| `enter_level(player, shared_effects)` | Guarded once per entry; assigns `hero: CinderPlayer`, `effects: PixelEffects`, then `_on_enter_level()`. |
| `exit_level()` | Calls `_on_exit_level()` once, then releases shared references; `_exit_tree()` also invokes it. |
| `_on_enter_level()`, `_on_exit_level()` | Level-owned setup and signal/resource cleanup hooks. Keep local runtime children under the level root. |

`scripts/game.gd` owns one shared world, player, camera, effects, input and HUD. `load_level_scene(path) -> bool` validates an existing project-local `.tscn` and root/spawn before replacing selection. On rejection it preserves the current selection and exposes `level_load_error`. Empty selection loads the lab. CLI `--level-scene=res://...tscn` uses the same loader; invalid startup exits 2. Never launch an act as a separate main scene or add another player/camera/gesture recognizer/HUD inside it.

Custom previews omit lab stands/exercises and use a resume-only overlay. Preview RESET creates fresh level/player state with full HP/shells while preserving static gear. **This is development reset, not coherent campaign checkpoint retry.** Do not claim completion/save/reward support from these semantics.

The current equipment resolver supports static loadouts with exactly `weapon`, `jacket`, `pants`, `shoes`, including `equipment.snapshot()` and validated `restore()`. Existing pause/resume consumes UI gestures and freezes scene-tree simulation. Legacy player `action_resolved`/`last_action` continue to report hit summaries. Use the world-action API below for executed movement/attack data, rather than reading private fields or the input aim anchor. The visual footprint helper remains separate from safe-path validation.

## campaign-level-1 additions

`CinderLevel.API_REVISION = "campaign-level-1"`. Optional exported `level_id` accepts empty anonymous preview identity or canonical A1–A3 L1–L5/O1–O3 IDs; registered campaign scenes require nonempty identity. `local_snapshot_version` defaults to 1. Identity, scene path and local version latch on entry.

| API | Behavior |
| --- | --- |
| `completion_requested(level_id, completion_id)` | Authored objective-clear request; the shell owns persistent completion. |
| `contact_exit_requested(level_id, exit_id)` | One contact transition request, after completion, from the same live shared hero. |
| `checkpoint_requested(level_id, checkpoint_id, boundary_kind)` | Unique encounter or boss-phase boundary request; no implicit heal or disk write. |
| `request_completion(completion_id = "complete") -> bool` | Idempotent, commits its state before emitting. |
| `request_contact_exit(exit_id, body: Node3D) -> bool` | Rejects other actors, dead hero, incomplete levels and duplicate exits. |
| `request_checkpoint(checkpoint_id, boundary_kind = "encounter") -> bool` | Accepts stable IDs and `encounter`/`boss_phase`, once per ID. |
| `is_completed() -> bool`, `current_checkpoint() -> Dictionary` | Read local progress; checkpoint view is a copy. |
| `snapshot_state() -> Dictionary` | Defensive envelope: API/schema, level/scene identity, local version, progress/dedupe, local payload. Returns empty with `last_snapshot_error` on rejection. |
| `snapshot_error(snapshot) -> String`, `restore_state(snapshot) -> bool` | Full validation before local commit; no progression signals/healing/resource refresh. Restore an earlier snapshot to reopen completion/exit for retry. |

Level authors override `_capture_local_state() -> Dictionary`, `_local_snapshot_error(state) -> String`, and `_restore_local_state(state) -> void`. Include all gameplay-relevant enemies, supplies, collected IDs, remaining clocks and encounter RNG. Payloads use finite JSON-compatible primitives, arrays and string-keyed dictionaries (local payload root at depth 0, up to 32 nested levels, excluding the transport envelope); encode vectors explicitly and large RNG integers as strings. Returned and accepted payloads are copied.

The local validator must check every field and required runtime node without mutation. The commit hook must then apply validated data without failure. The base cannot roll back arbitrary authored node mutations. Lifecycle/capture/validation/restore hooks suppress progression reentrancy. Event handlers may synchronously capture committed state; they may not recursively emit events or restore. The shell should defer actual scene replacement until the originating action/callback completes. These hooks provide local state, not yet coherent shared actor saves or campaign transitions.

## world-actions-1 additions

`CinderPlayer.WORLD_ACTION_SCHEMA_VERSION = 1`:

```gdscript
signal world_action_executed(record: Dictionary)
func get_world_action_records(after_sequence: int = 0) -> Array[Dictionary]
func get_world_action_clock() -> float
func cancel_world_action_capture() -> void
```

The signal supplies a defensive record after each actual accepted primary/blast execution or completed accepted dash. History retains the latest 64 records; subscribe to avoid missed events after rollover. Monotonic sequence is publication order; attacks publish before legacy `action_resolved` callbacks. The per-player clock advances with active physics, freezes with tree pause and restarts for a new player instance.

Common fields: schema, sequence, kind (`primary`, `blast`, `dash`), `origin = player_direct`, start/completion simulation times, world origin, exact direction, snapshotted equipment IDs and resolved stats. Attacks include accepted hit count, resolved damage, instantaneous damage time, separate logical commitment/cooldown, and geometry: radial cone reach/dot, origin disk, vertical allowance and layer-1 scenery-ray LOS policy at the real source/target height. Records do not contain the final screen-space swipe-release aim anchor.

Completed dashes include real landing, sampled per-physics-step path/times, distance, planar collision-contact `blocked`, `collision_shortened`, and `movement_damage = false`. A fully blocked accepted dash still publishes a zero-travel completion. Buffered requests publish only after their eventual executed dash completes; rejected requests do not publish. Death or explicit cancellation discards unfinished capture without changing movement. The shell owns lifecycle cleanup and suppression of direct combat calls while menus are paused.

Limits: path samples are not an analytic swept capsule; geometry carries a parametric shape and LOS policy rather than an immutable obstacle mesh. This is executed-action data, **not a combined-replay escape proof**. Whole-sequence preview/validation, reservation scheduling, snapshot serialization and stable collision handling remain required before Crystalman can claim support.

## Canonical campaign registry

[registry.json](../../data/campaign/registry.json) records all 15 main and 9 optional IDs, sequential main links and optional parent clears, derived from the three canonical research files. Its initial entries have `scene_path = null` and `readiness = unimplemented`. Integration alone registers a scene after accepting its exact level commit/API revision; this data is not evidence that campaign content exists. Optional completion stamps have stable once-only reward IDs and no stat growth. A future menu must gate playable routes on accepted, validated scenes.

## Required next API revisions

These interfaces remain open implementation requests. Act workers can prepare owned art/layout/notes and must request dependencies before claiming dependent gameplay complete.

- Campaign registry and shell consumers for completion/contact-exit/checkpoint requests; coherent transition lifecycle (local hooks are now available).
- Coherent shared player/resources/timers/gear and relevant enemy/supply/effect snapshots; protected story/optional/replay attempts; persistent completion and deduplicated optional rewards; interrupted sessions resume paused.
- Serialize executed-world-action capture where needed; implement finite captured-sequence composition/preview and whole-route validation. Keep final screen-space aim-anchor state separate.
- Authoritative preparing **and active** threat reservations, collision/floor-safe reachable paths, geometry and timing checks, cancellation/cleanup; non-compounding difficulty profiles fixed at fresh encounter boundaries.
- Concept-derived presentation selection with compatible carried gear; shared available/active/spent and warning/lock/active/recovery cues; campaign-selected claimed/reserved equipment abilities.
- Title/Journey/replay equipment/settings with cosmetic Low/Standard/High, 30/60 FPS (60 initial), audio, reduced motion and credits.

Breaking changes require a published API revision, exact compatible baseline, migration message and affected reruns. Compatible additions also require documented signatures and test evidence before use. After initial baseline verification, follow the latest user test policy: targeted changed-level suites and directly affected shared checks; broaden only when a new cross-system concern warrants it.

## Presentation, actions and assets

Headwear follows selected act concept art and is presentation only. It changes neither slots nor stats/collision. Preserve the shared feet pivot, action responsiveness and readable facing. Current helmeted lab assets remain valid prototype assets with their original provenance; act variants are pending production. Menus/preview art must reflect the active chosen presentation once implemented.

Keep portrait fixed-angle camera, nearest pixels, continuous exact aim, swipe-only deliberate dashes and immediate primary/one blast gesture grammar. Warning geometry, targets, safe floor and interaction state survive quality/reduced-motion settings. Preserve connected actual-path dash smoke, slower pale slash arc and bright barrel-origin flare. Cosmetic clocks do not change simulation.

Asset records require stable ID, family, source, readiness, native dimensions/world size, pivot, palette, collision/occlusion, states/durations, reuse and known limitations. No full board is a finished runtime sheet. Optional assets principally reuse their parent kit.

## Canonical commands and engine queue

Use Python tools from the assigned checkout. Local configuration:

```sh
python3 scripts/dev/setup_vscode.py --slot act1 --canonical-root '/Users/howardchen/Documents/ChatGPT/video game idea'
python3 scripts/dev/dev.py doctor
```

Use the actual role slot. Open generated `.cinder/cinder.code-workspace`. Slots use integration 6005/6006/6007, act1 6015/6016/6017, act2 6025/6026/6027 and act3 6035/6036/6037. Distinct ports do not authorize simultaneous heavy engines.

```sh
python3 scripts/dev/dev.py import
python3 scripts/dev/dev.py check
python3 scripts/dev/dev.py test level_contract
python3 scripts/dev/dev.py run --level-scene res://scenes/acts/act1/a1_l1.tscn
python3 scripts/dev/dev.py engine --headless --path . --script scripts/art/build_character_assets.gd
python3 scripts/dev/dev.py equipment status --markdown
python3 scripts/dev/dev.py ability status --level A1-L1
python3 scripts/dev/dev.py ability available --level A1-L1
python3 scripts/dev/dev.py ability validate
python3 scripts/dev/dev.py equipment validate
python3 scripts/design/validate_equipment.py
```

All heavy Godot jobs, including exports/captures/imports/tests/previews, join the same inherited advisory lock derived from the common Git identity: canonical `.cinder/locks/godot.lock`. Keep one heavy session active, release interactive sessions promptly, and never bypass a queue or delete a held lock. Outside-wrapper sessions must close deliberately first. No mobile-export gate belongs to this desktop scope.

Catalogue values: canonical `data/design/player_equipment.json`. Creation claims: canonical `data/design/equipment_claims.json`; introductions: canonical `data/design/ability_usage.json`. Use dev proxies for atomic mutations. Mailboxes do not allocate equipment. At playstyle decisions record existing ID/type matches and the new player decision; claim shared creation and reserve level introductions separately. Do not implement unused catalogue proposals or invent reskins as new identities.

## Temporary communication protocol

Ignored mailbox: `.cinder/agent-chat/cinder-campaign/`. Integration alone writes `run.json`, with run ID, absolute roots, worker confirmations, exact checkout/branch/owned paths, baseline/API revisions. Each role writes only its own `status.md` and outgoing `messages/`; initial empty role status placeholders assert no ownership or readiness. Replace status atomically using a same-directory temporary file and rename.

Read recipient-tagged messages across all role folders. Use immutable unique message filenames and REQUEST, RESPONSE, READY, HANDOFF and ACCEPTED types. Include message/request ID, run ID, sender, recipient, level, relevant commit/API revision, request/response text and acceptance evidence. A response must name its request. Never overwrite another role's record. Acknowledgements and lasting decisions also belong in durable progress/design records; mailbox status alone never authorizes takeover.

Before a level handoff, provide `docs/acts/actN/ACT_MEMORY.md`, `PROGRESS.md`, individual level record, exact commit, scene path, canonical level ID, baseline/API revision, equipment/ability claim/use IDs, asset readiness, queued test results, actual portrait evidence and remaining limits. Integration verifies controls, no-ammo/ordinary-primary viability, legal loadout extremes, combined escape paths, boss reachability, pause/snapshot/replay/reward behavior and cleanup as applicable. Distinguish automated checks, agent-operated gameplay, human playtesting and unperformed device testing.
