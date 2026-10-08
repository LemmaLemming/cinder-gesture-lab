# Equipment grid for level playstyle decisions

All three act agents consult the same equipment grid **when deciding or changing a level's playstyle**. Review it before deciding what equipment, rewards, perks or temporary pickups the level would encourage or introduce. Opening a checkout, installing tools or making an unrelated edit does not trigger this review.

The existing grid consists of the shared [equipment specification](PLAYER_EQUIPMENT_GUIDELINES.md) and [canonical catalogue](../data/design/player_equipment.json). The [visual equipment review grid](../assets/characters/equipment-review.png) and its [row IDs](../assets/characters/equipment-review.json) show the current shared prototype clothing/weapon family. That visual grid is not a campaign allocation ledger or proof of finished act-specific artwork.

`equipment_grid.py` derives a live combined view from the canonical catalogue, equipment creation claims and ability introductions. It does not introduce a second numerical catalogue. Use the configured dev proxy so every act queries the integration root:

```sh
python3 scripts/dev/dev.py equipment status --markdown
python3 scripts/dev/dev.py ability status
python3 scripts/dev/dev.py ability available --level A1-L1
```

Use the actual research level ID. Save the relevant decision in that level's notes rather than a stale full-grid copy: intended playstyle/player decision; matching existing IDs; benefits/drawbacks; required ordinary-kit escape/attack opportunity; creation claim IDs; and applicable ability introduction/carryover use IDs. Catalogue eligibility in Acts 1–3 is not a record of introduction in any act.

## Reuse before creating a type

The current catalogue already has neutral, defensive, damage-risk, reach, health-capacity, dash-speed, dash-distance, cadence and armour-conversion clothing, plus balanced, quick, heavy and long weapon profiles. It also contains conditional perks and temporary powerups, many still proposed and unimplemented. Inspect the live records and their status before deciding that a mechanic is missing.

Reuse a matching type under its existing ID. An act-specific name, material, palette or numerical retune is not a different equipment type. Reuse and carried equipped items do not allocate a new creation task or a new introduction. Preserve compatibility with the selected act presentation, shared collision/feet pivot/facing and the common power budget. Headwear is presentation only and creates no equipment type, slot or bonus.

If shared implementation of an existing type is needed, claim that item once before building it. If a genuinely new type is needed, describe the changed player decision and submit a full candidate definition to the shared owner. Check the proposal against existing definitions and active claims before reserving its creation. A structural fingerprint is a collision screen, not semantic proof that two proposals are different.

Equipment creation claims coordinate **who creates a shared type**. The [ability ledger](ABILITY_USAGE_WORKFLOW.md) separately coordinates **where a perk or powerup is introduced**. Both checks apply when creating and placing a new ability-bearing item. Static clothes/weapons remain covered by the equipment grid even when they have no `PERK-*` ID.

Use these commands as templates, replacing the paths, item ID, owner and returned claim ID with the actual decision. A proposal is one complete canonical-style equipment definition JSON, not a level-placement record. The source must exist in the canonical checkout.

```sh
# Check a new definition; this does not reserve creation.
python3 scripts/dev/dev.py equipment check --proposal data/campaign/act1/proposed_item.json
# Reserve that definition after the playstyle decision and shared-owner review.
python3 scripts/dev/dev.py equipment reserve --proposal data/campaign/act1/proposed_item.json --owner act1-equipment --purpose "Implement the documented new player decision." --source docs/ACT1_CONCEPT.md
# Alternatively claim an existing proposed item, using its actual canonical ID.
python3 scripts/dev/dev.py equipment reserve --item PERK-01 --owner shared-equipment --purpose "Implement the approved shared perk once." --source docs/PLAYER_EQUIPMENT_GUIDELINES.md
# Complete only after the definition is integrated into the canonical catalogue.
python3 scripts/dev/dev.py equipment complete --claim EQCL-000001 --owner act1-equipment --source docs/ACT1_CONCEPT.md
# Cancel abandoned work, preserving its history.
python3 scripts/dev/dev.py equipment cancel --claim EQCL-000001 --owner act1-equipment --reason "The level now reuses existing shared equipment."
python3 scripts/dev/dev.py equipment validate
```

All claims and ability reservations use the same canonical integration checkout. Do not reserve against private worktree copies, edit reservations by hand, overwrite newer ledger revisions, change another owner's claim, silently expire claims or make a duplicate under another ID. Cancel abandoned creation work with a reason. A completed creation record means canonical catalogue integration; it does not establish gameplay balance or finished assets.

New catalogue definitions and shared runtime are integrated by the shared owner. Act workers own their proposal/encounter/art paths and preserve existing canonical resources. Validate catalogue numbers, creation claims, ability identities and actual portrait gameplay before claiming an item implemented. Required encounters work without pickups or blast ammunition.
