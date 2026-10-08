# Act II novel research: The Invasion

Research date: **8 October 2026**. Reference: **H. G. Wells, *The War of the Worlds* (1898)**, the complete novel, rather than a film, radio play, television version or later sequel. The main text was read in chapter sections from [Project Gutenberg](https://www.gutenberg.org/cache/epub/36/pg36-images.html); its [plain-text edition](https://www.gutenberg.org/cache/epub/36/pg36.txt) allowed checking the smaller human roles and machine descriptions against the complete work. Both links are the same edition, not two independent witnesses.

The original novel is public domain. Database descriptions are original paraphrases. All gameplay suggestions and generated concepts are adaptation work, even when they borrow a canonical object or place. The art collection should be treated as studies for selection; it does not make every catalogued reference a required production asset.

## What is in the database

[entities.json](entities.json) has **199 records**: **108 character/name/group records, 44 environments, 30 technologies/props/organisms, 12 moods, and 5 boss candidates**. [sources.json](sources.json) identifies the sources, and [levels.json](levels.json) holds the proposed pacing and encounter structure.

Stable IDs connect research, art and the offline catalogue:

| ID family | Category | Scope |
| --- | --- | --- |
| C01–C108 | Characters | Principal humans, named minor people, distinctly described unnamed roles, civilian and military groups, alien collective, reported scholars, historical/allusive names, plus three explicitly invented regular enemy roles |
| E01–E44 | Environments | Visited settings, significant reported locations, alternate escape-route settings, distant planets and the artilleryman’s imagined underground world |
| T01–T30 | Technology | Martian machines, human infrastructure and props, alien anatomy/plants, terrestrial microbes and fauna |
| M01–M12 | Mood | Interpretations of repeated emotional and thematic patterns |
| B01–B05 | Bosses | Game encounter proposals, each with a specific canonical basis |

Each record includes `id`, `title`/`name`, `category`, `subcategory`, `canon_status`, `description`, exact Book/chapter references, `source_ids`, `game_adaptation`/`act2_role`, `notes`, and tags. The regular proposals C101–C103 also have design IDs A2-E1–A2-E3 and canonical-basis links. Unknown fields can be retained by downstream tools.

`novel_fact` means **the novel contains this person, description or report**. It does not silently convert a report into direct observation, period astronomy into current science, or a narrator’s claim into certainty. Notes flag those distinctions. `interpretation` marks themes and explicitly inferential matters. `game_proposal` marks playable designs invented for this project.

This is a complete practical cast index at the **named-person, distinct-role and narratively meaningful group** level, rather than a claim to identify every anonymous person in a vast crowd. Closely related small scene roles sometimes share a record, with the distinction stated in the notes. The same person can appear within a scene-group record and their own individual record; the group is for staging, not a duplicate identity.

The principal cast is C01–C14. The novel supplies **no personal name for the narrator, his wife, his brother, the artilleryman or the curate**. Miss Elphinstone and Mrs. Elphinstone are different women: the surgeon’s sister and wife. George is the absent surgeon, not the narrator. No named Martian commander, queen, emperor or final overlord exists in the novel.

Historical names, epigraph figures and comparisons receive separate subcategories so that Schiaparelli, Perrotin, Kepler, Lilienthal, Briareus and the other allusions are not mistaken for people encountered by the player. Smith’s newspaper concession and Thomas Lobb’s cart inscription likewise are name references, not developed onstage characters. Howes, Philips, Carver and Lessing are cited scholars in the narrator’s retrospective account; they are not a canonical quest party.

## Narrative shape and what Act II should inherit

The novel moves from confident ordinary life to first contact, destruction of organized defence, the mass exodus, claustrophobic occupation, ecological transformation, profound urban silence, and an unexpectedly natural collapse. The two story threads matter: the narrator experiences Surrey, the ruined house and London, while his brother reaches the Essex coast with the Elphinstone women. Thunder Child belongs to the latter thread. A game can use a coastal study or optional route, but should not pretend the narrator’s London walk and the brother’s sea escape occurred in one place.

The player arrives with Act I’s dash placement, commitment reading and close-range attack habits. Act II can demand those skills immediately while introducing **the changed spatial pressure**: a line of heat, a committed machine foot, a smoke patch, and later a probing manipulator. Difficulty should come from choosing a landing that both evades and preserves access to a recovery opening. Fixed damage and the established gestures remain sufficient.

The independently authored [Act II concept](../../../ACT2_CONCEPT.md) uses Act I only for structure and mobile pacing: five main levels, frequent encounter and boss-phase checkpoints, short optional levels that reuse their parent kit. It does not copy the Moon’s theatrical art. Five proposed main clear times—8, 9, 9, 9 and 10 minutes—total **45 minutes**. They are first-clear design estimates, not timers or tested completion data.

## Visual facts that should survive concept iteration

**Martians:** the later anatomical account describes a rounded head-body about four feet across, grey-brown leathery skin, two large dark eyes, a fleshy beak-like mouth, a single rear ear drum, and **sixteen slender tentacles in two bunches of eight**. They have no nostrils, clothing or ordinary digestive apparatus. The witness first experiences them as wet, heaving, bear-sized and physically uncomfortable on Earth. A two-armed humanoid in a suit is a substantial departure, not a faithful anatomical simplification. Sources: Book I, Chapter 4; Book II, Chapter 2.

**Fighting-machines:** flexible three-legged machines stride, bend knees, shorten their supports and move like living bodies. The hood turns, metallic tentacles reach, and a basket/cage carrier projects behind the main body. They are not uniformly rigid stilt tripods. Brass-toned hood, shining/white metal and green emissions are described; a coherent game material palette is still a design choice. Sources: Book I, Chapters 10–12 and 15; Book II, Chapters 2–3.

**Handling-machines:** the construction/capture machinery is separate from the fighting tripod. Its first full description gives **five agile jointed legs**, many levers and manipulator tentacles, and a visible controlling Martian. It resembles a metallic spider or crab and telescopes a probing arm through domestic ruins. Sources: Book II, Chapters 2–4.

**Heat-Ray:** the fatal heat itself is **invisible**, perceived through ignition, glowing material, steam and destruction. A camera-like generator and a proposed parabolic-mirror mechanism appear in the account, but the exact physics remains uncertain. Pale ground warnings, a visible sweep strip, outline locks and lowered slashable joints are game inventions serving readability. Sources: Book I, Chapters 5–6, 11–12; Book II, Chapter 10.

**Black Smoke:** canisters break on impact without explosive detonation, producing dense inky vapour that sinks into valleys and low streets. It deposits powder and is cleared by Martian steam. The novel does not grant the player an easy detoxification tool or a safe smoke dash; predictable bounded game patches must be explicitly marked as adaptations. Sources: Book I, Chapter 15; Book II, Chapter 1 and the epilogue.

**Red weed and red creeper:** distinguish the bulky water-loving weed from the transient climbing growth. Cactus-like branches, immense water fronds, crimson flooding and later whitening/shrivelling give an entire environmental progression. The source does not establish a conscious plant, grabbing vines, a carnivorous blossom boss or toxic attack thorns. Sources: Book II, Chapters 2, 5–9.

**Machines beyond the tripod:** the excavation mechanism works rhythmically with green vapour; aluminium manufacture uses a milk-can-like body, oscillating pear-shaped receiver, powder, clinkers and shining bars; a flat broad flying machine is only partially described. Study those objects separately instead of inventing a universal alien tank or saucer family and calling it canon. Sources: Book II, Chapters 2–3 and 8; Book I, Chapter 17.

**Human specificity:** white flag, orchids, pink newspapers, baskets, Sunday blazers, luggage, pony-chaise, lamp-lit trains, pantries and a child’s return to her mother are as important as machinery. They keep the invasion about the disruption of lives rather than an empty target range. The costume details in the novel can anchor a concept; clothing accuracy beyond those details would need separate period-source research.

## Boss selection and limits

| Record | Proposal | Canonical foundation | Use |
| --- | --- | --- | --- |
| B01 | Heat-Ray fighting tripod | Aimed heat case, flexible legs, leg damage at St. George’s Hill | Shared source vocabulary and alternate boss staging |
| B02 | Ruined-house handling-machine | Five-legged apparatus and the probe into the cellar | Selected level-three boss |
| B03 | Black Smoke deployment tripod | Thick tube, canisters, heavy vapour and steam clearance | Alternate/optional encounter study |
| B04 | Shepperton river interception | Hood destroyed by artillery; machine falls into hot water; separate Thunder Child sacrifice | Optional set-piece exploration, not a third mandatory boss |
| B05 | Primrose Hill failing sentry | Motionless tripods, final redoubt, diseased weed and microbial deaths | Selected level-five climax followed by the natural-collapse coda |

B02’s lowered manipulator coupler and B05’s reachable brace are **new close-range weak-point designs**. Neither is a claim that an ordinary sword canonically defeats a Martian invasion. A mobile fight should keep the threatening source, warning and at least one reachable normal-dash landing together in view. Machine scale can continue above the camera without concealing the next relevant attack.

B05 deliberately adds a short active encounter **before the source novel’s largely dead encampment is discovered**. Disabling that local machine enables escape. It does **not** cause the defeat of all Martians. The wider invasion collapses because of terrestrial disease, as the source explains. Crows, whitening brittle weed, faltering movement, a cry that ceases, and harmless metal in dawn light can carry this ending without an invented microbial gun or supreme alien ruler.

The database also includes C101–C103, explicitly labelled proposed regular machine variants. Ray Scout, Canister Tender and Salvage Handler are role names for this game; Wells does not name three castes or species with those titles.

## Mood palette, beyond constant destruction

The proposed rust-red, charcoal and pale-warning palette can use four distinct conditions: warm ordinary life briefly glimpsed through disorder; hot ash and green industrial emissions; a carmine flooded world that has become unfamiliar; then bleached growth and cool dawn. The book itself describes more colours than this compact game palette. Palette restriction is an adaptation, not a claim that the entire novel is literally red and black.

M01–M12 cover complacency, cosmic smallness, revulsion, industrial awe, crowd panic, failed explanations, claustrophobia, imperial reversal, ecological occupation, silence, natural limits and persistent trauma. Short quiet passages matter. Dead London is frightening partly because familiar rooms and streets remain intact but empty; destroying every building and spawning a wave in every square would discard that mood.

The opening’s colonial analogy and the narrator’s animal comparisons reverse humanity’s accustomed dominance. The artilleryman’s proposed underground society includes exclusionary, coercive breeding ideas and proves much less practical than his rhetoric. Preserve these as evidence about the character and period, not as an endorsed game survival policy. The curate’s collapse and the narrator’s violent response likewise are morally strained testimony, not an instruction to make clergy or traumatized civilians regular enemies.

## Research qualifications

- The narrator blends what he saw, what his brother told him, later reports and retrospective explanation. In-world newspaper reports are often wrong. Entries label these boundaries.
- Book I, Chapter 15 describes Martian howls as communication, while Book II, Chapter 2 argues for telepathy and interprets some hoots as feeding-related. The catalogue preserves this tension; literal telepathy is not assumed as a proven mechanic.
- Black Smoke’s unknown-element spectral description differs between the main battle account and the epilogue. The art does not need to resolve this discrepancy, and the database does not invent a chemical formula.
- The epilogue calls the microbial explanation highly probable while retaining uncertainty about the precise mechanism. This does not justify substituting a player-caused alien defeat: the narrative’s natural ending remains the key canonical foundation.
- Real-place names are narrative geography. No modern street route, travel guidance or survey-accurate level map is claimed.
- All required combat is proposed, not implemented or balanced. Concept images are not screenshots of a working Act II.
