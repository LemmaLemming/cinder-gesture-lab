# Cinder — title, journey menu and replay equipment

**Saved: 8 October 2026.** This records the UI direction agreed in the design conversation. The title, journey menu and separate story/replay saves are planned features; they are not implemented in Godot or validated on a phone. The existing [Character Lab](CHARACTER_LAB.md) implements static equipment and paused comparisons, which can support later implementation.

## Requirements and design authority

The user wants a **Duolingo-inspired journey menu**, with several levels scattered along a winding path. Players can replay previously completed levels with equipment they choose. Finishing or leaving that replay automatically returns them to their main storyline equipment.

The accepted screen flow is **Title → Journey → select a completed level → choose replay equipment → replay → return to Journey or Continue Story**. The current story level also has a direct Continue action.

The layout and behaviours below are implementation defaults for that direction. Exact spacing, artwork, transitions and interruption handling remain proposals to test. The [game concept](GAME_CONCEPT.md), [shared style guidelines](GAME_STYLE_GUIDELINES.md), [asset reuse guide](ASSET_REUSE_GUIDE.md) and [equipment specification](PLAYER_EQUIPMENT_GUIDELINES.md) remain authoritative for campaign, art, controls and item rules. This plan introduces no new equipment abilities or campaign placements.

## Title screen

Use a quiet portrait tableau, with the CINDER logo above a recognisable traveller and one landmark from the current act. Leave generous clear space around the menu. Keep future locations and boss reveals out of the opening art.

The traveller always wears the permanent round astronaut-like helmet. Clothing in the title and equipment preview follows the same compatible equipment family used in gameplay, including pieces mixed across acts. The helmet is part of the character, not another equipment slot.

Place the main actions in the lower, comfortable reach area:

- **Continue Story:** primary action when a story save exists; show the act, level and saved checkpoint nearby.
- **Journey:** opens level selection without changing story equipment or progress.
- **Settings:** smaller action, with sound and credits available within it.

For a new save, replace Continue Story with **Begin Story**. After campaign completion, Journey becomes the main action. Show main-level completion separately from optional content; derive the count from campaign data rather than artwork or a fixed UI constant.

## Journey menu

Use a vertically scrolling journey with a winding path and large level nodes staggered left and right. The scattering is authored and stable, so players can learn where each location is. A connecting path makes sequence clear. Scrolling this menu never moves the gameplay character.

Each act forms a different region. Start with the current campaign plan's five main nodes per act and optional side branches; the campaign counts remain subject to the act plans and playtesting. Opening Journey should bring the current story node into view. Provide an act shortcut so returning to an earlier region does not require scrolling through the whole campaign.

| Node state | Appearance | Selection and action |
| --- | --- | --- |
| Completed main level | Filled medallion, level number and checkmark | Show the level card with **Replay · Choose Equipment**. |
| Current story level | Strong outline, current marker and the helmeted traveller beside it | Show the saved checkpoint and **Continue Story**. |
| Locked main level | Muted medallion and lock label | Explain which previous level must be cleared; hide unreached boss art and reveal-sensitive names. |
| Available optional level, not yet completed | Smaller branch node, Optional label and available state | Show **Play Optional Level**; do not call its first attempt a replay. |
| Completed optional level | Smaller branch node with a checkmark | Show **Replay · Choose Equipment**. |
| Locked optional level | Muted branch node and lock label | Name the parent-clear requirement. |

Keep optional branches short and visibly separate from the main route. Completing a parent level immediately unlocks its optional level. Side-level completion never blocks the main route. Main and optional completion use separate counters.

Tapping an available node opens a small level card or bottom sheet with its name, completion/checkpoint state and one main action. Selection must not start combat immediately. A completed level proceeds to replay equipment; the current level continues its saved story attempt.

Use landmarks, sparse terrain silhouettes and quiet scenery between nodes. Keep labels and paths legible. Decorations are not additional levels, rewards or gameplay interactions.

### Act identity and example route

Keep one shared node, icon and text family across all acts. Change the surrounding scenery and palette:

| Region | Palette | Menu scenery references |
| --- | --- | --- |
| Act I — The Moon | Moon-white, dusty silver and black | Painted rock flats, finless capsule, shallow mushroom caps, crescents and court drapery. |
| Act II — The Invasion | Rust-red and black, with pale contrast | Ruined masonry, industrial joints, red weed and distant machine silhouettes. |
| Act III — Tormance, The False World | Black, unnatural violet and sulphur-green | Organic forms, crystals and harmless reflective layers. |

Use the [Act I](ACT1_CONCEPT.md), [Act II](ACT2_CONCEPT.md) and [Act III](ACT3_CONCEPT.md) designs and their [Moon](concept-art/act1/README.md), [Invasion](concept-art/act2/README.md) and [False World](concept-art/act3/README.md) art guidance before producing scenic assets. Existing concept boards remain references, not runtime menu artwork.

The Act I example uses existing level IDs, not new content:

| Main node | Optional branch unlocked by its completion |
| --- | --- |
| A1-L1 — Observatory and Launch | — |
| A1-L2 — Crater Gardens | A1-O1 — Salvage Circuit |
| A1-L3 — Mushroom Caverns | A1-O2 — Spore Bloom |
| A1-L4 — Selenite Court | A1-O3 — Royal Rehearsal |
| A1-L5 — The Living Moon | — |

The visual reference starts with three main levels completed, the story at Selenite Court, two completed optional branches and later content locked. This is an illustrative save, not the player's actual progress or an unlock-placement specification.

## Replay equipment

After selecting a completed node, show the level name, a helmeted outfit preview and exactly four choices: **weapon profile, jacket, pants and shoes**. One weapon profile supplies both the primary attack and blast follow-up. Reuse the shared catalogue, comparison rules and stat resolver; the menu does not create another combat controller or weapon hotbar.

Default the first replay setup to the story loadout. Remember the last chosen replay setup separately for subsequent replays, and offer **Use Story Equipment** and a neutral standard preset. Choose from equipment already unlocked in the persistent catalogue. Later unlocked equipment can be used in earlier completed levels within the same equipment budgets; replay does not grant access to locked items.

For each item, show its benefit and cost or condition. Put detailed resolved before/after damage, cooldown, reach, dash speed/distance, health, damage reduction and perks in an expandable comparison. Show caps and any health discarded by a permitted in-attempt swap, as required by the equipment specification. Do not present attack-speed percentage as measured DPS.

Above **Start Replay**, display:

> For this replay only. Your story equipment and checkpoint are preserved.

Replay pickups and equipment replacements affect that replay attempt only. Temporary powerups remain encounter-limited and cannot be selected as permanent equipment. Legal loadouts retain the normal escape and attack opportunities; replay provides no permanent damage, health or armour growth.

## Story and replay persistence

Keep **story** and **replay** as separate attempts. Create and persist the replay from a protected story snapshot instead of replacing story gear and trying to undo individual changes later. Preserve the existing story checkpoint and any supported paused attempt state as a coherent unit.

The story snapshot includes level/checkpoint identity, equipped item IDs, HP, shells, reload progress, cooldown timing, applicable powerup/perk state, enemies, environment supplies, collected/drop IDs and RNG state if used. Follow `SAVE-04` and `SAVE-05` in the [equipment specification](PLAYER_EQUIPMENT_GUIDELINES.md#replacement-and-persistence); restoring equipment alone is insufficient.

| Event | Replay behaviour | Story behaviour |
| --- | --- | --- |
| Start replay | Start a fresh level attempt with the chosen replay loadout and authored initial supplies. Any full-HP/ammo start must be an explicit rule. | Preserve the complete story snapshot. |
| Die and retry | Restore one coherent replay checkpoint, including its replay equipment and supplies. | Keep the story snapshot untouched. |
| Restart with new equipment | Return to replay setup, then restart the replay with the new loadout. Do not combine old enemies with newly refreshed resources. | Keep the story snapshot untouched. |
| Finish or leave replay | End the replay attempt and return to Journey; the last replay preset may remain saved for later use. | Automatically restore story equipment and the complete story snapshot. |
| Continue Story | Leave an active replay through the same restoration path. | Load the saved story attempt with its original equipment. |
| Background the app | Freeze simulation and all gameplay timers. | Preserve its snapshot. |
| Close and reopen the app | Persist replay independently; offer **Resume Replay** or **Continue Story**. Resume starts paused and consumes its UI tap. | Its save remains usable even if replay recovery fails. |

Show **Story equipment restored** after finishing or leaving. No manual re-equipping should be required. Optional completion credit, challenge records and cosmetic rewards may persist under their own campaign rules, with once-only reward commits; replay equipment and pickups do not overwrite the story loadout. The exact policy for unlocking newly discovered catalogue items during replay remains a follow-up decision, not an implicit reward in this plan.

First attempts at separately selected optional levels should also preserve the main story attempt and return to its equipment on exit. Their level card says Play until completed. Reuse the same attempt-isolation mechanism; this does not allocate new abilities or change optional-level rewards.

## Interaction, readability and motion

Target the game's portrait presentation, with safe-area margins and comfortable thumb reach. Use crisp pixel artwork and borders, readable body text and one stable cue family. Keep effective touch targets at least about 44 × 44 logical pixels; smaller-looking optional nodes still need that touch area. Final spacing must be checked on actual phones.

Distinguish states through numbers, symbols, labels and contrast as well as colour. Current and selected are different states: the traveller marks story progress while the selection treatment shows the node being inspected. Use a steady current marker and restrained tap/selection motion; do not make every node pulse. Support reduced motion and readable focus states.

Consume menu taps, journey scrolls, equipment selection and resume gestures before combat input. Dismissal or resume must not leak a slash, blast or dash. The menu changes neither the last-swipe aiming rule nor the gameplay camera/controller.

## Saved visual reference

- [Interactive journey reference](ui/cinder-journey.html): a standalone browser preview of title, winding journey, level selection, equipment choice and returning to story gear.
- [Editable reference source](ui/cinder-journey.fragment.html): the original fragment used to produce that standalone preview.

These files preserve the conversation's layout reference with a schematic helmeted traveller. They contain an illustrative save and a small static equipment sample. Their CSS dimensions, simplified silhouettes and comparison values are reference material, not production sprite scale, engine assets or a second source of equipment balance data. They do not load real saves, render actual combat, prove checkpoint restoration or establish mobile layout quality. The standalone preview may use browser-local storage for its illustrative selections; it must never be connected to the player's real save files.

## Implementation and verification plan

Build in bounded stages: journey navigation and level-card states → shared equipment comparison → independent story/replay save handling → completion, exit, retry and relaunch flows → final act-specific artwork. Reuse the existing lab's static equipment resolver, comparison and tap-consuming UI where appropriate; campaign persistence must be implemented separately.

Before calling the feature implemented, verify:

1. In portrait, players can identify their current level, select an earlier completed node and find an optional branch without confusing scenery with playable content.
2. The current node opens Continue Story; a completed node opens replay setup; an unplayed optional node says Play; locked nodes explain their requirement without revealing bosses.
3. Changing all four replay slots, collecting replay equipment, finishing, abandoning and returning to story restores the original equipped IDs and the complete story state.
4. Replay retries retain the correct replay checkpoint/loadout. Restarting with new gear creates a fresh replay, without duplicated drops or refreshed resources mixed into old encounters.
5. Backgrounding, terminating during a replay, relaunching and an interrupted/corrupt replay save do not overwrite or invalidate the story save. Resume and menu gestures never trigger combat.
6. Main/optional completion, catalogue access and optional cosmetic records follow their declared persistence rules; repeated replays never grant permanent stat growth.
7. Labels, node targets, focus, safe areas, scenery contrast and reduced-motion behaviour work on real portrait phones. Until then, the UI remains untested on-device.

Documentation-only acceptance is narrower: verify local links, match the current campaign/equipment rules, and run the ability/equipment validators. Do not describe those checks or the browser reference as gameplay testing.
