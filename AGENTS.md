# Instructions for agents working on Cinder

## Parallel act development

- Before implementing an act in parallel, read [the development workflow](docs/development/PARALLEL_ACT_DEVELOPMENT.md) and [the setup record](docs/development/SETUP_RECORD.md). These define the shared level interface, worktree ownership, engine commands and launch conditions.
- When deciding or changing a level's **playstyle**, consult [the equipment design grid](docs/EQUIPMENT_DESIGN_GRID.md) and query its live canonical catalogue/claims before choosing loadout opportunities, rewards, perks or powerups. This is a level-design decision gate, not a mandatory review at every agent startup. Record the existing IDs/type matches and the new player decision in the level notes.
- Reuse an existing equipment type under its canonical ID. A new name, palette, model or numerical retune is not a new type. Claim shared implementation work or a genuinely new equipment type through the canonical equipment-grid CLI before creating it; the separate ability ledger still governs perk/powerup introductions in levels.
- Use one checkout and `codex/` branch per act, with only that act's assigned content paths writable by its worker. Shared controller, HUD, camera, equipment catalogue, cue logic and project settings belong to the integration owner.
- Use `python3 scripts/dev/dev.py` for Godot jobs and canonical equipment/ability operations. Its Godot lock is shared across linked worktrees. Open the generated `.cinder/cinder.code-workspace` for the correct engine and ports. Do not bypass a queued job by starting another heavy engine process or delete a held lock.
- All act agents share the integration checkout's authoritative equipment creation claims and ability ledger. Private worktree copies do not allocate campaign work. Do not merge stale ledger copies or another worker's local settings.

## Read before making game content

- Read [the campaign concept](docs/GAME_CONCEPT.md), [the shared style and motion guidelines](docs/GAME_STYLE_GUIDELINES.md), and [the asset reuse guide](docs/ASSET_REUSE_GUIDE.md) before changing gameplay, animation, effects, environments or art.
- For character, equipment or powerup work, also read [the equipment specification](docs/PLAYER_EQUIPMENT_GUIDELINES.md) and its [numerical design data](data/design/player_equipment.json).
- Read the relevant `docs/ACT1_CONCEPT.md`, `docs/ACT2_CONCEPT.md` or `docs/ACT3_CONCEPT.md`, plus that act's concept-art README and any available adaptation notes. Act 2's adaptation boundaries are in its README. Act 1 also has a [source-specific style guide](docs/reference-library/act1/STYLE_GUIDE.md) and [superseded explorations](docs/concept-art/act1/LEGACY_EXPLORATIONS.md).
- Preserve the distinction between confirmed requirements, current prototype behaviour and unplaytested proposals. The playable game is currently one mechanics arena. Concept images are references, not implemented scenes, sprite sheets or finished runtime assets.

## Consistency reminders

- Keep portrait pixelated 2.5D, a close fixed-angle following camera, and one shared player controller/stat definition across all three acts. Act palettes and scenery may change; gesture meanings and cue meanings stay consistent.
- The protagonist always wears a round astronaut-like helmet. All worn jackets, pants, shoes and weapons must visually suit it, including mixed-act loadouts. Follow `REQ-08`, `REQ-09` and `LOOK-01`–`LOOK-05` in the equipment guidelines; older protagonist hats are superseded. The Character Lab implements the shared helmeted player; its asset manifest records production and device-review limits.
- Preserve swipe-only ground movement, exact aiming from the last swipe's final screen-space release point, an immediate first-tap primary attack and one blast on a nearby second tap within the existing timing window. No joystick, jump, auto-aim or weapon hotbar.
- Preserve the current dash's deliberate start and stop. Treat acceleration, knockback, enemy turning, commitment and recovery as explicit tuning data; cosmetic animation must not silently change travel distance, hit timing or momentum.
- Use the shared warning → lock → active → recovery grammar. An attack source, its footprint and a reachable safe landing must read together. Pixel style does not justify delaying input or shortening reaction time through faster animation.
- Give actionable props a restrained, repeated cue and visible available/active/spent states. Decoration must not impersonate that cue. Keep contact collection/exits distinct from attackable clusters/weak points; combat taps keep their existing meaning.
- Check existing code and the asset reuse guide before creating a new kit. Reuse parent terrain, scenery, enemies, animations and effects for optional levels, with only a few additions. Share effect/cue logic across acts while keeping each act's art vocabulary.
- Do not infer new mechanics, extra bosses or damage effects from an illustration. In particular, hittable mushroom spores repel living enemies; Act 3 white shadows and harmless reflections are scenery; boss weak points remain reachable with ordinary close-range attacks.
- Keep equipment within the shared specification. Required encounters work without pickups or blast ammo; permitted loadouts retain an escape and attack opportunity. No permanent stat growth through act progression or farming.
- When introducing an asset, record its source, readiness, native scale, pivot, collision/occlusion role, animation states and reuse family. Existing boards need production work; do not claim they are ready to drop into Godot.
- Validate the changed behaviour in the actual portrait view. Report what is still proposed, unimplemented or untested. For documentation-only changes, verify links and consistency without implying gameplay was tested.

## Local Node.js policy

- Use the nvm-managed Node.js installation for all Node, npm, npx, and pnpm work on this Mac. In a shell where `nvm` is unavailable, source `$HOME/.nvm/nvm.sh` and run `nvm use default` (or the project's `.nvmrc`). Verify `command -v node` and `command -v npm` resolve under `$HOME/.nvm/versions/node/` before installing global JavaScript tools.
- Never install Homebrew `node`, any `node@*` formula, or Homebrew `npm`. Never disable or bypass `HOMEBREW_FORBIDDEN_FORMULAE`. If a Homebrew package requires Homebrew Node, use its supported npm/pnpm installation under nvm or explain the conflict before proceeding.
- For project dependencies, honor the project's package manager and lockfile while using nvm for the Node runtime.

## Shared player ability usage

- Read `docs/ABILITY_USAGE_WORKFLOW.md` before designing or implementing player equipment abilities or their level placements. The ledger tracks introductions, not each gameplay activation.
- Before allocating an ability, run `python3 scripts/dev/dev.py ability status --level LEVEL_ID` and `python3 scripts/dev/dev.py ability available --level LEVEL_ID`. The proxy calls the existing ability tool against the canonical integration checkout. Use the actual main or optional campaign level ID from the research JSONs.
- Reserve an introduction through `python3 scripts/dev/dev.py ability reserve` with its ability ID, level ID, stable owner, purpose and source document before starting placement work. A read-only check does not reserve a slot. Other agents' reservations count as occupied.
- Record the use as `planned` after writing its concrete placement, then `implemented` only after gameplay and relevant checks exist. Include the returned use ID in the level design. Catalogue proposals and suggestions are not committed or implemented uses.
- Cancel abandoned reservations with a reason. Withdraw a removed planned placement through the tool while preserving history. Do not delete committed uses, rewrite another owner's record, silently expire reservations or edit the ledger to bypass a conflict.
- The user permits meaningful variants. Give a variant a new catalogue ID, register its parent/family, and document the structural change and the new player decision. Exact copies, renamed/reskinned abilities and numeric retunes are not new abilities. Never invent a different family to evade a repeat check.
- Carried equipped perks and the shared dash/slash/blast controls remain usable across acts. A carryover record references the same perk's earlier planned or implemented introduction. Temporary powerups expire at encounter end and cannot be declared carried equipment or re-granted as a new ability.
- This ledger covers player perks and temporary powerups. Enemy/environment teaching and reinforcement remain governed by the act designs; do not claim that this first registry audits all encounter novelty.
- Run `python3 scripts/dev/dev.py ability validate`, `python3 scripts/dev/dev.py equipment validate` and `python3 scripts/design/validate_equipment.py` before completing related work. Resolve mechanical identity drift before making dependent placements. Structural novelty checks do not replace semantic design review or balance playtests.
