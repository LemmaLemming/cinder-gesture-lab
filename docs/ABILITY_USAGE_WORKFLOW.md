# Ability usage workflow for game-building agents

**Purpose:** record where a player equipment ability is first introduced across the campaign, prevent duplicate introductions, and permit a new variant only when it changes the player's decision. This registry is a design coordination tool. It does not record how often the player activates an ability during gameplay.

**Current state:** the existing catalogue contains proposed, unimplemented, unplaytested abilities. No player equipment ability has a committed campaign placement. The prototype arena is not a campaign level. Item `acts: [1, 2, 3]` fields describe eligibility; they do not mean the item or ability has been used in those acts.

## Sources of truth and scope

| Source | Authority |
| --- | --- |
| [ability_usage.json](../data/design/ability_usage.json) | Registered ability identities, structural signatures, reservations, placements, transitions, history and nonblocking suggestions |
| [ability_usage.py](../scripts/design/ability_usage.py) | Validate the registry; query availability; perform atomic reservations and state changes |
| [player_equipment.json](../data/design/player_equipment.json) | Full `PERK-*` and `POWER-*` definitions, triggers, numeric values, limits and item references |
| [PLAYER_EQUIPMENT_GUIDELINES.md](PLAYER_EQUIPMENT_GUIDELINES.md) | Shared character, balance, equipment replacement, stacking and effect lifetime rules |
| Act documents and their `research/levels.json` files | Encounter design, stable campaign level IDs and evidence for a specific placement |

`USAGE-01`: Agents MUST use the CLI for ledger mutations. Do not edit `uses`, `history`, reservations, revision numbers or signatures manually. Do not overwrite the ledger with a stale copy. `init` is for an absent ledger and refuses to overwrite an existing one.

`USAGE-02`: This first registry tracks conditional player equipment abilities (`PERK-*`) and temporary powerups (`POWER-*`). It does not independently count static clothing bonuses, weapon profiles, enemy attacks, environmental interactions or the shared core controller. If an item grants a perk, track that perk's canonical ID rather than the item's visual name.

`USAGE-03`: Ordinary dash, slash, blast, automatic reload and the other shared core mechanics remain available throughout all three acts. Carrying already equipped clothing, weapon and eligible `PERK-*` abilities forward is permitted. Those persistent mechanics MUST NOT be removed to satisfy novelty bookkeeping.

`USAGE-04`: A temporary `POWER-*` effect ends according to the equipment lifecycle, including encounter end. It cannot be logged as equipment carryover to retain the effect after an encounter or into another act. A new placement of the same powerup is a repeated introduction, even after the earlier effect expires.

`USAGE-05`: Required routes and fights MUST remain viable with the standard reference loadout, ordinary dash and primary attacks. Availability in this registry is not proof of balance, necessity or implementation.

## Stable identifiers

Use the canonical ability ID from the equipment catalogue. Keep that ID when changing its name, art, act theme or numerical tuning. New registered abilities use unique `PERK-` or `POWER-` IDs followed by at least two digits. Never reuse a retired ID for another mechanic.

Campaign level IDs already exist:

- Main levels: `A1-L1` through `A1-L5`, `A2-L1` through `A2-L5`, and `A3-L1` through `A3-L5`.
- Optional levels: `A1-O1` through `A1-O3`, `A2-O1` through `A2-O3`, and `A3-O1` through `A3-O3`.

Read a level's `parent_level_id` before planning optional content. Optional levels can be played at different times after unlocking; do not assume a player's optional-level visit follows the order of a design table. `A3-L4` retains its stable ID even where prose calls its boss encounter Sullenbode's Garden and the level JSON names it False Paradise.

## Required sequence before designing a level

Run commands from the assigned checkout root after generating its local settings. The dev proxy calls the existing ability tool in the canonical integration checkout, so all three acts query and mutate one ledger. These commands use Python and require no Node runtime or package installation. See [the parallel workflow](development/PARALLEL_ACT_DEVELOPMENT.md) for configuration. New catalogue definitions and registration belong to the integration owner; act workers submit proposals in their owned paths.

```sh
python3 scripts/dev/dev.py ability status
python3 scripts/dev/dev.py ability available --level A1-L2
python3 scripts/dev/dev.py ability check --ability PERK-04 --level A1-L2 --kind introduction
```

`USAGE-06`: Start every level-design session with `status` and `available`. Inspect earlier uses across all acts, not only the target act. `status --level A1-L2` narrows the placement view; it does not replace the campaign-wide check. Availability can change when another agent reserves an ability.

`USAGE-07`: Reserve an introduction atomically before committing it to the level design. A successful availability query is not a reservation. Choose a stable, descriptive owner string and keep it for that reservation's later transitions.

```sh
python3 scripts/dev/dev.py ability reserve --ability PERK-04 --level A1-L2 --kind introduction --owner agent-a1-l2 --purpose 'Introduce a reward for escaping a committed threat before activation' --source docs/ACT1_CONCEPT.md
```

The returned JSON identifies the new use record in `use.id`. Copy that ID into the work notes and use it in later commands. Examples below use `USE-ID` as a placeholder; replace it with the actual ID. Do not execute the examples as instructions to place this particular perk: they show command syntax.

`USAGE-08`: A failed command has `ok: false`, a `code`, a `message` and optional `details`. Stop the dependent mutation, inspect the cause, and reread status/availability when a conflict is reported. Choose an available ability or resolve the conflicting reservation. Do not bypass a rejection by renaming the ability, creating an identical variant, changing the owner field by hand or deleting history. Successful command responses include `ok: true` and the ledger `revision`.

`available` returns an `abilities` list with each entry's `id`, `family_id`, `name`, `kind`, `available` flag and `blocking_uses`. Treat a false flag as unavailable. A `ledger_busy` failure means another operation holds the lock; retry after it completes, then reread current state. Do not delete the lock or another agent's reservation.

Campaign agents MUST use the configured dev proxy and share the authoritative ledger. It rejects root/ledger overrides and private-worktree fallback. The low-level `python3 scripts/design/ability_usage.py` accepts `--root PATH` or `--ledger PATH` before its subcommand for isolated tests or explicit integration maintenance; its default uses the repository associated with that script. Do not use a private checkout's default low-level ledger to allocate campaign work.

## Placement states and evidence

| State | Meaning | Next operation |
| --- | --- | --- |
| `reserved` | An agent has claimed this concrete introduction; encounter details are still being authored | `record --status planned` after documenting the placement, or `cancel` if abandoned |
| `planned` | A concrete placement is documented for the specified level | `record --status implemented` after implementation and verification, or `withdraw` if the design removes the placement |
| `implemented` | The ability is wired into the specified level and verified | Keep the historical record; it cannot be withdrawn through this CLI |

`USAGE-09`: `reserved`, `planned` and `implemented` introductions block a second introduction of the same concrete ability across the campaign. A reservation must not be treated as completed gameplay, and a design document must not be treated as implementation.

After writing the actual ability placement, purpose, constraints and stable IDs into the level design, record the plan:

```sh
python3 scripts/dev/dev.py ability record --use USE-ID --owner agent-a1-l2 --status planned --source docs/ACT1_CONCEPT.md
```

After implementing and verifying that specific placement, record implementation with an existing Markdown or JSON evidence document:

```sh
python3 scripts/dev/dev.py ability record --use USE-ID --owner agent-a1-l2 --status implemented --source docs/ACT1_CONCEPT.md
```

`USAGE-10`: Sources are repository-relative existing `.md` or `.json` documents; an optional `#section` reference is allowed. A valid source path establishes traceability, not proof that its contents describe completed work. Agents MUST write accurate evidence of the placement and verification before recording `implemented`. Do not claim implementation just because a catalogue entry, art mockup, plan or numeric fixture exists. Keep the source catalogue's design status accurate when gameplay is implemented.

## Abandoning or removing a placement

Cancel a reservation that will not be developed:

```sh
python3 scripts/dev/dev.py ability cancel --use USE-ID --owner agent-a1-l2 --reason 'This encounter now teaches only the baseline threat commitment'
```

Withdraw a documented plan only after removing or replacing its placement in the design source:

```sh
python3 scripts/dev/dev.py ability withdraw --use USE-ID --owner agent-a1-l2 --reason 'Placement removed from the revised level design'
```

`USAGE-11`: `cancel` changes only a `reserved` use to `cancelled`. `withdraw` changes only a `planned` use to `withdrawn`. Both release the active introduction claim and retain the record and history. Supply a specific reason. Neither operation is permitted for an `implemented` use; implementation history must not be erased to make the ability appear unused. A blocked request to remove implemented content requires a deliberate policy/data migration, not a fake cancellation.

`USAGE-12`: The owner that created a reservation is responsible for its transitions. If work moves between agents, coordinate the change through the owning agent and preserve traceability. Do not impersonate another owner to avoid a conflict.

## Equipment carryover

`USAGE-13`: Continued use of a `PERK-*` already introduced through equipped clothing is a `carryover`, not a new introduction. Reference that ability's earlier `planned` or `implemented` use. Describe why the later encounter uses the carried effect; do not describe it as a newly granted ability.

```sh
python3 scripts/dev/dev.py ability check --ability PERK-04 --level A2-L1 --kind carryover --from-use PRIOR-USE-ID
python3 scripts/dev/dev.py ability reserve --ability PERK-04 --level A2-L1 --kind carryover --from-use PRIOR-USE-ID --owner agent-a2-l1 --purpose 'Allow the equipped earlier perk during a new ray-priority encounter' --source docs/ACT2_CONCEPT.md
```

Use the same `record`, `cancel` and `withdraw` workflow for the resulting use record. Main-level carryover requires a valid earlier introduction. Read and resolve any warning about optional-level ordering. A ledger carryover expresses design continuity; it MUST NOT make that perk mandatory, grant it to a player who never acquired it, or change checkpoint/loadout persistence rules. Do not use `--kind carryover` for another pickup grant, a renamed duplicate, or a `POWER-*` effect.

## Meaningful variants

`USAGE-14`: Meaningful mechanical variants are allowed. Exact repeated introductions, cosmetic reskins and numerical retunes are blocked. Renaming a perk, changing its clothing slot, adding an act-specific visual, or changing damage, duration, distance or cooldown numbers does not establish a new mechanical identity.

Before registering a new variant:

1. Read the existing family and prior placements. State the previous player decision and the new decision in concrete terms.
2. Define the full new ability in `player_equipment.json` with a unique ID, explicit trigger, effect, action/target scope, limits, costs, reset rules and accurate proposed status. Preserve the original ability and its ID.
3. Explain a structural change that causes the new decision: for example, a different action sequence, target-selection rule, earned-resource condition or effect scope. An altered threshold alone is numerical tuning.
4. Validate the equipment catalogue and evaluate the applicable balance budgets and combined-loadout constraints. New variants still need playtests; a structural difference does not make them balanced.
5. Register the new ID with its canonical parent and rationale, then reserve its introduction before designing its level placement.

```sh
python3 scripts/design/validate_equipment.py
python3 scripts/dev/dev.py ability register --ability NEW-ABILITY-ID --variant-of EXISTING-ABILITY-ID --owner agent-variant-author --player-decision 'Describe the new choice the player makes' --difference 'Describe the structural rule change that creates that choice'
python3 scripts/dev/dev.py ability available --level TARGET-LEVEL-ID
python3 scripts/dev/dev.py ability check --ability NEW-ABILITY-ID --level TARGET-LEVEL-ID --kind introduction
```

Replace all uppercase placeholders with real IDs and evidence. `register` reads the full definition already added to the equipment catalogue; it does not create a gameplay implementation or a level placement. Register a new root ability without `--variant-of` only when it has no existing mechanical parent; registration still requires a distinct structure and a stated player decision.

`USAGE-15`: The structural signature detects mechanically identical definitions while excluding cosmetic naming and numerical tuning. This is a screening tool, not a semantic proof of novelty. It cannot prove that two differently written rules create distinct player decisions, that the rationale is accurate, or that a new variant is balanced. Agents MUST review the actual trigger/effect/limits and the prior family. Do not manufacture a signature difference with an irrelevant field or wording change. Resolve suspicious similarities before placement.

## Existing suggestions are not committed uses

The ledger preserves two source-backed ideas as nonblocking suggestions:

| Level | Suggested ability | Source meaning |
| --- | --- | --- |
| `A1-O1` Salvage Circuit | `POWER-02` Long Arc | A temporary dash-length pickup could ease the broad approaches |
| `A1-O2` Spore Bloom | `POWER-06` Orbit Cut | An optional 360 primary swing could ease the final crowd |

Both come from [Act 1's optional-level discussion](ACT1_CONCEPT.md#optional-levels-reuse-their-parent-kits). They do not reserve an ability, count as an introduction, or promise the pickup will appear. An agent that selects one MUST perform the normal availability check and atomic reservation. Do not silently turn a suggestion into `planned`.

Act 2's “if offered” pickup examples and Act 3's extra-eye/extra-limb art ideas have no selected placement. An extra limb granting Orbit Cut is the same ability identity. The earlier-visible-opening eye idea has no approved equipment definition; it requires its own specification and balance review before registration.

## Validation and future scope

Run the registry check after a design mutation and before handing work to the next agent:

```sh
python3 scripts/dev/dev.py ability validate
python3 scripts/dev/dev.py ability status
```

`USAGE-16`: Include the ability ID, use ID, level ID, final state and source document in the handoff. Report unfinished reservations accurately. Reconcile a validation error before creating dependent placements. A successful registry validation confirms data consistency; it does not validate the game's feel or the campaign's encounter balance.

`USAGE-17`: Enemy abilities and environmental interactions require a future registry with their own stable IDs, source evidence and reuse policy. The existing campaign intentionally repeats enemy tells, spores, sun states and parent kits to teach, apply and combine rules. Do not reinterpret those repetitions as duplicate player equipment introductions or claim this ledger audits all encounter novelty. Extend the scope explicitly before enforcing such a policy.
