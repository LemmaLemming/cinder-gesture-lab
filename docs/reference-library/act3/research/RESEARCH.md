# Act 3 novel research — A Voyage to Arcturus

Researched **8 October 2026** from David Lindsay’s complete 21-chapter novel, first published in 1920. The research uses the [Project Gutenberg primary text](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html). This folder holds **129 research records**: 48 character/role records, 37 environments, 25 props/anatomy/ecology records, 11 mood readings and 8 proposed boss roles. The campaign and art are proposals, not implemented or playtested content.

The primary creative thread is **an experienced traveller learns that perception, pleasure and apparent authority can mislead**. For the game, that makes a sequence of readable commitments, scenery changes and delayed echoes useful. Difficulty comes from better decisions about landings and recovery, using the already mastered ground dash, slash and second-tap blast. Bodily organs in the novel are source imagery; they do not require new inputs, damage upgrades or a compulsory mutation system.

`entities.json` is the editable database source. Every record has a stable ID, category, `canon_status`, short description, separate `visual_facts` and `game_adaptation`, `source_ids` and structured `chapter_refs` with direct URLs. `sources.json` records provenance; `chapters.json` supplies all 21 chapter anchors. The derived browser/CSV/SQLite catalogue is built separately by the project’s Act 3 library script.

## Reading the status field

- **novel_fact:** a name, appearance, incident, place or attributed statement found in the novel. An attributed doctrine is a fact *about what that speaker says*, not an endorsed law of reality.
- **interpretation:** a mood reading tied to events. The labels are our synthesis, not claims about Lindsay’s stated intention.
- **game_proposal:** an invented enemy, boss role, warning, arena or gameplay behavior. All generated art uses this status even when it preserves many textual features.

## Cast completeness and identity

The named cast appears in **C01–C38**. Minor/offstage people are included: Mr. Trent, Sature, Muremaker, Nuclamp, Lodd, Hator, Maulger and legendary Swaylone. Earth guests are individually indexed. C39–C45 cover creature groups, the unnamed families, the séance apparition, divine aspects and attendants. C50–C52 are the three invented regular enemies and are excluded from the novel-cast count.

**Do not read the record count as a count of unrelated beings.** Maskull and Nightspore are two narrative appearances linked by `identity_group_id: I01`; the ending relates them directly. Krag and Surtur are one merged record. Crystalman, Shaping, Faceny and the Gangnet appearance are indexed together. Faceny, Amfuse and Thire are additionally catalogued as the Three Figures in C44, related to C04; the text exposes their masks without requiring an invented pantheon of three independent liberating gods. A reference to a named composer, a staged Pharaoh, Prometheus or other comparison is not a new plot character. Arg is a common creature name; dolm is a color.

**Leehallfae is not sexless, male or female.** The narrator explicitly describes a third positive sex and shifts to **ae / aer / aerself**. Panawe’s earlier shared male/female body is a different story, not the same condition. The catalogue records the narrator’s distinction without converting either into a player upgrade system.

## Art facts that are easy to misread

- Poolingdred is the cup-shaped mountain and cave refuge. Maskull first wakes in the scarlet desert on the approach. Shaping’s desert well is **dark green**, while pure gnawl water in Poolingdred is **crystal clear**. The **iron-red fountain** belongs to Crimtyphon’s peninsula in Ifdawn.
- Branchspell is white, Alppain blue; ulfire and jale are fictional additional primaries. An RGB palette can suggest their described emotional character but cannot literally reproduce new primary colors.
- Wombflash chapter 13 describes immense **widely spaced trunks, no underbrush, dead wet leaves, mist and very high sunlit tops**. Dark red trunks and pale ulfire leaves are verified in Panawe’s chapter 7 recollection. Flesh-like bark, embedded eyes, a purple/pink canopy and hostile root growth are art inventions.
- Dreamsinter is a phosphorescent **giant** taller than Maskull, with **three pale-green luminous eyes**, thick coiled black hair and a staff. Polecrab is bald, short, sturdy and walnut-skinned, with three differently colored eyes. Gleameil is young, tall, lightly tanned and **three-eyed**, with coiled **yellow** hair. Earthrid has a pale weak-looking face and an **ear-like convoluted forehead organ**.
- Leehallfae has luminous **copper-colored** skin, angular/faceted anatomy, two eyes, a dark frock, turban and ankle-length plait. Haunte has a stump-like forehead organ; the source of his protecting light is the male stones, not a canonical forehead lamp.
- Sullenbode’s meeting place has a huge glowing, **leafless** tree bearing red lantern-like fruit. Her character is a guide and sacrificing lover. **Sullenbode’s Garden is entirely a game fabrication**; her projected likeness is not a damage target.
- Crystalman’s final presence is a vast **bright nebulous shadow**, without definite shape or color. A crystal-armored humanoid is an art interpretation. Krag/Surtur belongs to liberation and pain; he is not the evil final boss.
- The final tower reveals an **ongoing struggle**. A local manifestation can be defeated to open the game’s exit; this does not claim that one weapon strike erases Crystalman’s universe.

## Boss research versus selection

Eight roles are retained to make later changes reviewable. Only **B05 Sullenbode’s Garden** and **B06 Crystalman** are selected by the five-level concept. Crimtyphon, Tydomin, Catice and Earthrid are substantial alternatives; Muremaker/Nuclamp and the Three Figures are more expensive or less direct adaptations. Compassionate or tragic cast members are not converted wholesale into hostile encounters. The novel’s bodily absorption, flight, swimming, cliff-climbing and metaphysics are research references rather than additional input systems.

## Complete chapter route

| Chapter | Novel evidence | Use in the concept |
| --- | --- | --- |
| [Chapter 1. THE SÉANCE](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0001) | Domestic theatre becomes an uncanny materialisation; Krag kills the apparition and leaves its grin as the first false-world clue. | Earth cast and a prologue reference; no main-level tutorial needed. |
| [Chapter 2. IN THE STREET](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0002) | Krag, Maskull and Nightspore discuss Crystalman, Surtur and a voyage toward Tormance. | Transition and unresolved identities. |
| [Chapter 3. STARKNESS](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0003) | The companions arrive at an apparently deserted observatory on the northern coast; optical apparatus and an exhausting tower climb foreshadow later revelations. | Cold Earth kit, tower and ray props. |
| [Chapter 4. THE VOICE](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0004) | Maskull and Nightspore explore the Gap of Sorgie and hear mysterious drumming; a voice and light deepen the invitation. | Auditory motif, inlet and foreshadowing. |
| [Chapter 5. THE NIGHT OF DEPARTURE](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0005) | Krag returns, prepares the crystal torpedo and conducts the departure; travel uses the story’s extraordinary rays. | Departure transport and compression into a short transition. |
| [Chapter 6. JOIWIND](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0006) | Maskull wakes helpless with unfamiliar organs; Joiwind’s blood exchange restores him and her prayer gives an initially reassuring meaning to Shaping. | Scarlet desert approach, compassionate cast and sensory anatomy. |
| [Chapter 7. PANAWE](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0007) | Panawe explains his reverence for life and recalls Broodviol, Slofork, Muremaker and Nuclamp. His account of his sister challenges Broodviol’s doctrine. | Complete anecdotal cast, altered-sex history and Wombflash’s recalled colors. |
| [Chapter 8. THE LUSION PLAIN](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0008) | Maskull leaves the hosts, crosses Lusion Plain, sees a vision that calls itself Surtur and meets Oceaxe. | Broad transition and ambiguous false-authority image. |
| [Chapter 9. OCEAXE](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0009) | The sorb and third arm make Ifdawn a world of imposed will. Crimtyphon’s transformation of Sature leads Maskull to kill him. | Unstable mountains and transmutation candidate. |
| [Chapter 10. TYDOMIN](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0010) | Tydomin compels Oceaxe’s death, leads Maskull to absorb Digrung and tries to occupy his body; he escapes her domination. | Coercion motifs and delayed-echo interpretation. |
| [Chapter 11. ON DISSCOURN](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0011) | Maskull and Tydomin leave the cavern across Disscourn; Spadevil introduces a new law and changes their faculties. | Severe upland and new moral perception. |
| [Chapter 12. SPADEVIL](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0012) | In Sant, Spadevil’s doctrine conflicts with Catice’s rejection. Maskull kills Spadevil and Tydomin, then learns the name Muspel. | Ascetic cast; avoid treating every doctrine as authoritative truth. |
| [Chapter 13. THE WOMBFLASH FOREST](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0013) | In immense Wombflash, Maskull awakens to remorse and follows drumming with Dreamsinter; a vision places Nightspore beyond his own apparent story. | Great spacing, wet ground, mist, no underbrush and apparition scale. |
| [Chapter 14. POLECRAB](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0014) | Maskull meets practical Polecrab at the dangerous sea and hears Gleameil’s determination to visit the music; he recognises the earlier Surtur vision as false. | Fishing ecology, family, uneven water density and identity correction. |
| [Chapter 15. SWAYLONE’S ISLAND](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0015) | Gleameil follows her musical hunger to Earthrid’s lake. She dies during the music; Maskull takes over, breaks Irontick and finds Earthrid dead. | Music instrument, legend of Swaylone and possible alternate boss. |
| [Chapter 16. LEEHALLFAE](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0016) | A moon-responsive tree carries Maskull onward. Matterplay’s streams transform organisms; Leehallfae, a surviving phaen of a third positive sex, seeks Faceny. | Prolific ecology and faithful ae/aer/aerself cast. |
| [Chapter 17. CORPANG](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0017) | Leehallfae dies in Threal. Corpang explains and invokes the Three Figures; Muspel-light exposes their grinning falsehood and they follow the drumming outward. | Underworld, false deity aspects and shadowless sacred space. |
| [Chapter 18. HAUNTE](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0018) | Haunte brings the travellers toward Sarclash through Lichstorm, explains male stones and recounts Lodd. Deprived of his protection, he dies after kissing Sullenbode. | Painful passion, flying boat as reference and glowing tree scene. |
| [Chapter 19. SULLENBODE](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0019) | Maskull’s love awakens Sullenbode fully; she guides the party toward Adage and accompanies his search, though loss of his love must mean her death. | Human sacrifice and guidance, not a canonical botanical villain. |
| [Chapter 20. BAREY](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0020) | After Sullenbode’s burial, Krag and Gangnet accompany Maskull through Barey to the Ocean. Gangnet is exposed as Crystalman; Maskull dies and Nightspore reappears. | Soothing false beauty, aliases and departure from ordinary identity. |
| [Chapter 21. MUSPEL](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0021) | Nightspore climbs six tower windows that reveal how Crystalman degrades spirit. Krag is Surtur; the awakened traveller returns with him to an ongoing struggle. | Local game breach may conclude the act, while cosmological victory remains unresolved. |

## Named cast index

Aliases are shown in the same row so searches do not silently multiply characters. The Three Figures have an extra group row because their names and representations matter to research.

| ID | Record | Chapter evidence |
| --- | --- | --- |
| C01 | Maskull | 1,6,9,10,12,13,19,20 |
| C02 | Nightspore | 1,3,5,13,20,21 |
| C03 | Krag / Surtur (Krag / Surtur / Pain) | 1,2,5,14,20,21 |
| C04 | Crystalman / Shaping (Crystalman / Shaping / Faceny / Gangnet) | 2,6,16,17,20,21 |
| C05 | Backhouse | 1 |
| C06 | Montague Faull (Faull / Montague) | 1 |
| C07 | Mrs. Jameson | 1 |
| C08 | Kent-Smith | 1 |
| C09 | Prior | 1 |
| C10 | Lang | 1 |
| C11 | Professor Halbart (Halbart) | 1 |
| C12 | Mrs. Trent | 1 |
| C13 | Mr. Trent (Trent) | 1 |
| C14 | Joiwind | 6,7,8 |
| C15 | Panawe | 7,8 |
| C16 | Broodviol | 7,14,15 |
| C17 | Slofork | 7 |
| C18 | Oceaxe | 8,9,10 |
| C19 | Crimtyphon | 9,10,11 |
| C20 | Tydomin | 10,11,12 |
| C21 | Digrung | 10,15,16 |
| C22 | Spadevil | 11,12 |
| C23 | Hator | 11,12 |
| C24 | Maulger | 12 |
| C25 | Catice | 12,13,14 |
| C26 | Dreamsinter | 13,14 |
| C27 | Polecrab | 14,15 |
| C28 | Gleameil | 14,15,19 |
| C29 | Earthrid | 14,15,17 |
| C30 | Swaylone | 15 |
| C31 | Leehallfae | 16,17 |
| C32 | Corpang | 17,18,19 |
| C33 | Haunte | 18,19 |
| C34 | Sullenbode | 18,19,20 |
| C35 | Lodd | 18,19 |
| C36 | Muremaker | 7 |
| C37 | Nuclamp | 7 |
| C38 | Sature | 9 |
| C44 | Faceny, Amfuse and Thire — the Three Figures (Faceny / Amfuse / Thire / Three Figures) | 17 |

The exact level count, first-clear budgets, checkpoint policy and optional side levels belong to [the Act 3 concept](../../../ACT3_CONCEPT.md) and `levels.json`. This research catalog keeps those design choices separate from the novel’s chronology and cast.
