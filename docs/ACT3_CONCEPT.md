# Act 3 — Tormance: The False World

**Design proposal, researched 8 October 2026.** Five main levels target **45 minutes** for a player who has finished Acts 1 and 2. Three separately entered optional levels add **3–5 minutes each**. These are first-clear pacing estimates, including movement, encounters and brief transitions; they are neither countdowns nor instructions to pad a fight. The campaign content, timings and combat rules here are unimplemented and unplaytested.

The reference is David Lindsay's *A Voyage to Arcturus* (1920). The act compresses several places and themes into the already selected sequence: **Twin Suns → Living Forest → Mirror Sea → False Paradise → Crystalman**. It follows the game's existing protagonist rather than making the player literally perform Maskull's entire journey. The novel's characters, the game's invented enemies and the interpretation of its ending are recorded separately in the [research database](reference-library/act3/research/RESEARCH.md). The [original novel and chapter contents](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html) remain the primary source.

## Shared character contract

[PLAYER_EQUIPMENT_GUIDELINES.md](PLAYER_EQUIPMENT_GUIDELINES.md) defines the authoritative campaign-wide player and item rules. Acts 1, 2 and 3 use the same base gesture mechanics, controller, and underlying stats. Replaceable jacket, pants, shoes and one carried weapon may modify effective stats or provide bounded conditional effects. **Fixed baseline damage** means unchanged underlying damage: no act multiplier and no farmed permanent stat growth. Acts change encounters and available item themes within equal balance budgets.

Every required route and fight must remain practical with the standard reference loadout, ordinary dash and slash-only attacks. Existing fixed-stat completion tests refer to that loadout. Equipment or temporary powerups may offer alternatives; they never become mandatory traversal or boss keys. The shared guidelines take precedence over earlier unresolved equipment, duration or stacking proposals in this document.

## Scale inherited from Act 1

Act 1 supplies level count, approximate duration, separately entered side levels, parent-kit reuse, encounter checkpoints and interruption handling. **Its art direction does not carry over.** The campaign-wide portrait format, pixelated 2.5D presentation, fixed-angle overhead camera, ground-plane movement and confirmed gesture mapping still apply.

| Pacing rule | Act 1 working design | Act 3 proposal |
| --- | --- | --- |
| Main levels | 5 | 5 |
| First-clear targets | 6 / 8 / 9 / 10 / 10 min | **8 / 9 / 9 / 9 / 10 min** |
| Main-act total | 43 min | **45 min** |
| Opening purpose | Teach controls and useful landings | Use mastered controls immediately; establish the new sun-state rule in one exchange |
| Major bosses | 2, in levels 4 and 5 | **2, in levels 4 and 5** |
| Optional levels | 3 examples, 3–5 min each | **3 proposals, 3–5 min each** |
| Optional production rule | Parent terrain, scenery, enemies and effects plus a few additions | Same; encounter arrangement creates most of the difference |
| Checkpoints | Completed encounters and boss phases | **About 1–3 min** between saved completions; before each boss and after each phase |
| Interruption | Freeze simulation and resume with a consumed overlay tap | Same; the sun clock, attack previews and echo replays freeze too |
| Persistent progress | Access, completion and optional cosmetics | Same; **fixed baseline damage**, no required grind |

The three proposed main acts total **133 minutes**: 43 + 45 + 45. Completing all three acts' three 3–5-minute optional levels would bring the target to **160–178 minutes**, before retries, deliberate replays or database reading. This fits the campaign's rough 2–3-hour first-completion ambition. The authorized desktop scope includes all nine documented optional levels, three per act. Their pacing and encounter tuning remain unplaytested proposals; the existing Act 1 document is a design baseline, not a measured production schedule. [Campaign baseline](GAME_CONCEPT.md), [Act 2 proposal](ACT2_CONCEPT.md).

## What the experienced player learns

The act's question is **Which visible rule will change next, and where should I commit so the change leaves me an opening?** The player can already dash, aim a slash from the last swipe's screen-space endpoint, chain one blast with a quick second tap, and read a committed attack. Act 3 tests anticipation, prioritisation and restraint with that same vocabulary.

The playable cycle is **read a sun-state preview and an enemy's windup → swipe to choose a useful landing → let the threat commit → tap to punish its local recovery → decide whether to chain the blast → plan the next landing before the sun state changes**. Later, the player deliberately chooses a dash-and-attack path that will also be safe to evade when echoed.

No direction-target exercise or control lecture repeats. The first encounter has room to observe one new rule, then immediately asks the player to use it. The progression is a readable instance, a rearranged application, and a combination. Experts can shorten individual exchanges by recognising the rule quickly; slow attacks, inflated health and compulsory waits do not supply the act's duration.

- **Player mastery:** planning one sun change ahead, reading world-space attack shapes, distinguishing an attack source from a harmless reflection, selecting a priority threat, and composing a safe echo path.
- **Attempt state:** health, carried weapon, temporary pickups, current encounter and finite boss replay buffer. Retrying restores the coherent section start, including its intended supplies and initial sun state.
- **Persistent state:** level access, completed encounters and boss phases, optional completion and cosmetics. Information learned by the human survives failure. No permanent damage increase is needed to clear the finale.

Temporary extra eyes or limbs may appear as optional, clearly named pickup concepts in the art library. An extra eye could preview an already visible opening earlier; an extra limb could use the campaign's proposed 360-degree swing pickup. Neither is a required sensory organ, traversal ability or permanent power tree. Final tuning is deferred until the base interaction works with ordinary dash and slash.

## Novel anchors and adaptation boundary

The novel does not contain these five action levels, this enemy cast or these boss fights. The following links explain the source material used, without claiming that an invented mechanic is canonical.

| Novel material | Contribution to this act | Invented game interpretation |
| --- | --- | --- |
| Branchspell's intense white heat, unfamiliar colours and a temporal mirage in Poolingdred | Alien perception and a world that resists ordinary intuition. [Chapter 6](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0006) | Fast, previewed alternating sun states; spectral patterns and route markings. The novel's daily heat period is not this game's combat clock. |
| Changing Ifdawn terrain and fantastic vegetation | A landscape with unstable or surprising forms. [Chapters 8–9](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0008) | Safe, compact floor arrangements under two suns; readable shifting layers rather than simulated mountains. |
| Wombflash's immense trees, wet leaves, mist and strange perception | Scale, damp silence and a difficult-to-read forest. [Chapter 13](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0013) | Flesh-like bark, watching forms and combat roots. The original forest is not authenticated as a cast of predatory tree monsters. |
| The Sinking Sea, Polecrab's shore, Swaylone's Island, reflected sunset and Earthrid's lake-instrument Irontick | Water, island silhouettes, beauty and destructive entrancement. [Chapters 14–15](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0014) | A dry playable Mirror Sea margin, harmless reflections and clearly previewed echoes. Mirror Sea is our level name; it is not a named canonical sea. |
| Sullenbode in the Lichstorm/Sarclash journey, guiding toward Adage and contemplating sacrifice | Intimacy, attachment, vulnerability and a tragic cost of failed love. [Chapters 18–19](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0018) | **Sullenbode's Garden**, an entirely fabricated false-world manifestation that projects her likeness. She is not a canonical garden keeper or a villain who traps the player. |
| Gangnet's reassuring presence, then Crystalman's world, repetition, a glassy sea and the Muspel tower | Comfort exposed as a deeper deception; escape does not end all struggle. [Chapters 20–21](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0020) | A luminous landscape-body, player-action replays and slash-range tethers. Severing those tethers opens this game's escape; it is not a definitive canonical defeat of Crystalman. |

Joiwind, Panawe, Polecrab, Gleameil, Leehallfae, Corpang, Sullenbode, Krag and Nightspore can inform nonhostile vignettes, silhouettes or optional journal entries. Do not turn the novel's named people into repeated combat drops. Their disagreements can make the world feel morally unsettled without a quest log requiring the player to kill every viewpoint. Krag's harshness and the final liberation also argue against a simple rule that attractive light is always good and darkness always evil.

## Sun states without unreliable controls

**Branchspell state** and **Alppain state** are game labels for two legible encounter states, not a claim that the suns alternate this quickly in Lindsay. The original novel's white daylight shadows and invented colours are motifs; violet, sulphur-green and pixel patterns are visual equivalents, not literal reproductions of ulfire or jale.

Use a stable ground floor for all required travel. Light changes the appearance of terrain layers, which side of a rooted enemy opens, and which *previewed* local hazard is active. It never swaps the swipe axis, rotates the aim anchor, reverses inputs or secretly redirects an attack. Required travel uses the normal dash distance; no jump, swim, climb, fly, boat control or boosted-gap requirement appears.

1. **Preview:** an outlined next-state footprint appears over the existing floor, with a distinct silhouette icon and repeated tick marks counting down. The affected object visibly prepares too. Use the same shapes throughout the act; hue is supporting information. White shadows remain separate from filled active-attack footprints.
2. **Lock:** the next arrangement stops moving before activation. Give enough lead time to recognise it, finish any remaining dash cooldown and perform one ordinary escape dash. This is a testable timing requirement, not a fixed millisecond claim.
3. **Change:** the base floor and the player's current safe pocket remain intact. Required clear approaches remain usable through the change. Do not replace occupied safe ground with a damaging patch or an impassable root. In the first prototype, changing terrain layers have no dynamic collision at all.
4. **Attack:** a sun change alone deals no damage. A separate enemy or hazard windup, lock and active state authorises each strike. A newly active patch cannot hit an overlapping player immediately; its activation is delayed until they clear it, with a clear waiting outline. Never use that delay to create an unavoidable surrounding cage.
5. **Recovery:** each regular threat still offers an ordinary slash opening in either sun state. The state changes the best approach or the length of a useful window, not whether the enemy can be defeated. The game does not make the player wait through an entire sun cycle for permission to attack.

The default safe geometry contains two broad connected pockets, at least one reachable by a normal dash from the current valid position. Only one additional hazard patch may overlap a sun transition during the first tests. Scenic mist, reflections and falling pixels sit below or behind active warning shapes. Audio may enhance a warning, but a muted portrait screen must carry the whole decision.

## Three regular enemy roles

These are **invented game creatures**, indexed separately from Lindsay's cast: C50–C52 in the entity database, with gameplay aliases A3-E1–A3-E3. Begin with a small roster that changes its arrangements across the five levels.

| Enemy | First appearance | Readable commitment and recovery | Mastery decision |
| --- | --- | --- | --- |
| **Sunbound Stalker** (C50 / A3-E1) | Twin Suns | A low asymmetric creature braces toward one short dash lane. Its head crest locks with the lane; it lunges once, then exposes a low flank. Its two crest shapes identify the sun state and the easier flank. Recovery is slashable in both states. | Bait the lane toward ground you will not need, then land near the useful flank as the light changes. |
| **Root Latcher** (C51 / A3-E2) | Living Forest | A clearly rooted bulb lifts two root ends, previews one short crescent or strip, locks, then tightens there. It retracts and leaves its low knot open. It does not secretly follow the player's dash or produce endless sprouts. | Remove the area-denial source or use its fixed commitment to get around the Stalker. |
| **Mirror Echo** (C52 / A3-E3) | Mirror Sea | A filled, floor-rooted body is accompanied by one harmless outlined reflection. The real body previews its own short dash and slash arc, locks both, replays once, then becomes a grounded hittable knot. | Read the actual route rather than chase the reflection, and punish where the replay ends. |

Keep shapes distinct: Stalker's crest and narrow lane; Latcher's rooted bulb and crescent; Echo's continuous body-to-floor line and route-plus-arc preview. The harmless reflection has no collider, damage, item drop or threat warning. Do not ask the player to guess which identical copy is real, or hide the answer in a colour tint. The Echo previews **its own** action; recording the player's action is reserved for the final boss.

Initial mixes use at most **two enemies preparing attacks at once**, with staggered locks. Bodies yield a normal dash lane; touching an enemy is not repeated contact damage. Later difficulty comes from choosing which known threat to commit first and where its recovery ends, not larger health bars, faster invisible attacks or a bigger list of species. Normal slashes can finish every required enemy. A second-tap blast provides a situational commitment and impact, never a mandatory armour key.

## Main sequence

Every level has exactly five budgeted beats below. The budgets sum to its target; the saved-completion markers in [levels.json](reference-library/act3/research/levels.json) use the same elapsed seconds. A skilled player can finish sooner. Encounter assembly, not extra waves, should fill a pacing gap discovered by testing.

| Level | Objective | Distinct question | Target | Boss |
| --- | --- | --- | --- | --- |
| A3-L1 **Twin Suns — A Useful Shadow** | Reach the Poolingdred exit across stable sunlit shelves | Where should I land before the next state becomes active? | **8 min** | None |
| A3-L2 **Living Forest — The Floor Remembers** | Cross the Wombflash-inspired grove and open its dry exit | Which rooted source should I commit before the path tightens? | **9 min** | None |
| A3-L3 **Mirror Sea — Refuse the Reflection** | Traverse the dry sea margin and leave the resonant island apron | Which body owns the warning, and where will its replay finish? | **9 min** | None; a short Irontick-inspired resonance set piece |
| A3-L4 **False Paradise — The Cost of Staying** | Disengage the garden manifestation and reach the Adage threshold | Can I reject the comfortable-looking route while keeping an opening? | **9 min** | **Sullenbode's Garden** (B05) |
| A3-L5 **Crystalman — Compose an Escape** | Break local landscape tethers and leave the false-world arena | Can I create a path I can evade when the world repeats it? | **10 min** | **Crystalman** (B06); campaign finale |

### A3-L1: Twin Suns — A Useful Shadow

**Source:** Poolingdred's alien light, colours, temporal mirage and Branchspell heat; later two-sun imagery. [Chapter 6](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0006), [Chapter 20](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0020).

**Layout:** broad coloured-sand shelves around distant pillar forms → two stable approaches past low purple trees → an open departure basin. White shadows stretch across the floor as a motif, but their decorative extent is not a hitbox. No cliff edge punishes an ordinary dash. The enormous suns remain framing landmarks above readable local combat.

| Beat | Budget | Encounter and purpose | Saved elapsed time |
| --- | --- | --- | --- |
| A foreign noon | 1:00 | Brief arrival, then one isolated sun-state outline changes while the player can move freely. No control recap or damaging demonstration. | 1:00 |
| The useful flank | 2:00 | One Stalker. Its lane locks, the player evades, and the near flank opens. During the next exchange, the crest previews the other state before the same readable recovery. | 3:00 |
| Two approaches | 2:00 | Choose one of two broad shelf approaches that rejoin. One offers a direct short flank approach; the other offers more retreat room. Same enemy, different commitment placement. | 5:00 |
| Crossing the white shadow | 2:00 | Two staggered Stalkers around a low tree; one prepared state change. Preserve a retreat and choose the first source to remove. | 7:00 |
| The pillars recede | 1:00 | A final brief familiar exchange, contact exit and a distant pillar mirage. Spend no extra time waiting for a complete light cycle. | 8:00 |

**Mastery gain:** the player can predict a state change and still put the next attack within reach. First-clear time should fall through recognition on a replay with identical stats.

**Kit:** scarlet/dark sand variants, fixed shelf floor, low purple trees, mirage pillars, two-sun sky motifs, white shadow overlay, one Stalker and two crest states, common preview/lock/active/recovery shapes. The mirage is scenery outside the playable boundary.

### A3-L2: Living Forest — The Floor Remembers

**Source:** Wombflash's enormous trees, sodden leaf floor and rolling mist; changing life elsewhere on Tormance informs the imagined organic embellishments. [Chapter 13](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0013), [Chapter 16](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0016).

**Layout:** forest threshold → three broad root courts → a cleared canopy slit. Large trunks frame the view; their bases have simple visible collision shapes. High canopy, mist and eye-like bark remain outside active warning layers. Required floor is always continuous, firm and dry enough for the normal dash, even though the setting feels damp and alive.

| Beat | Budget | Encounter and purpose | Saved elapsed time |
| --- | --- | --- | --- |
| Vast trunks | 1:00 | Short quiet scale reveal, then a familiar Stalker in generous space. The world has changed; the controls have not. | 1:00 |
| A root's promise | 2:00 | One Root Latcher alone previews one crescent. Bait the crescent, circle the fixed bulb and slash its recovery knot. | 3:00 |
| Two living courts | 2:00 | Two small arrangements: Latcher beside one fixed trunk, then Stalker beside Latcher. The second encounter makes target priority matter. | 5:00 |
| The watched clearing | 2:00 | A sun preview overlaps a known root windup. Let the root lock on the less useful approach, then use the retained broad pocket to punish the Stalker or the knot. | 7:00 |
| Canopy slit | 2:00 | One deliberate mixed arrangement, then the exit opens by contact. A quiet final grove view is included in the budget. | 9:00 |

**Mastery gain:** see a fixed area-denial source as a controllable commitment, rather than treating every root as random terrain danger. Root growth animation cannot hide a changed collider under the player.

**Kit:** immense trunk sections, wet leaf-ground tiles, low visible roots, high organic canopy panels, restrained mist, one Latcher, rooted-knot states and existing Stalker/sun effects. No new full tree-monster cast is needed. Optional flesh, eye and vein textures are artistic interpretations.

### A3-L3: Mirror Sea — Refuse the Reflection

**Source:** Sinking Sea and Swaylone's Island; Irontick's reflected sunset and music; the later glassy sea. [Chapter 14](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0014), [Chapter 15](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0015), [Chapter 21](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0021).

**Layout:** a broad dry shore → firm island-margin shelves → a circular dry apron around a scenic lake-instrument. Ground planes can appear polished and reflective, but their filled border and foot contact stay obvious. The original novel's water crossing is not a swimming or vehicle requirement. Island silhouettes float in the distance; the required route has no gap beyond a normal dash.

| Beat | Budget | Encounter and purpose | Saved elapsed time |
| --- | --- | --- | --- |
| Shore and doubled sky | 1:30 | A quiet approach with one familiar threat. Clearly distinguish filled playable floor from decorative water. | 1:30 |
| One real body | 2:00 | A single Mirror Echo previews its own dash and slash. Its hollow reflection is harmless throughout. Evade the route, then attack the grounded endpoint knot. | 3:30 |
| A useful ending | 2:00 | Two short Echo arrangements around fixed shore stones; choose a landing that can reach the replay endpoint rather than only escaping its arc. | 5:30 |
| Resonant apron | 2:00 | An Irontick-inspired scenic pulse frames one bounded, independently previewed floor ring. A Mirror Echo acts between pulses. The lake and Earthrid are not a third compulsory boss. | 7:30 |
| The shore falls silent | 1:30 | One Stalker/Echo priority choice, then a quiet departure. Silence signals resolution; no concealed final hit fires after the encounter clears. | 9:00 |

**Mastery gain:** associate each warning with a real local source and endpoint, even inside a deceptive scene. The visual environment can mislead thematically; a locked warning never lies about its collision footprint.

**Kit:** dark dry shore, firm shelves, fixed shore stones, reflective ground overlay, distant island outline, scenic Irontick ring, one resonance warning effect, Mirror Echo and harmless outline reflection, existing Stalker/sun system. Reflections need no damage/collision system.

### A3-L4: False Paradise — The Cost of Staying

**Source:** Lichstorm and the Sullenbode journey toward Adage. Sullenbode's softly luminous skin, dark-maroon hair, vulnerability and sacrifice contribute a human reference; they do not establish a hostile garden deity. [Chapter 18](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0018), [Chapter 19](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0019).

**Layout:** a welcoming fixed garden walk → open petal court → a compact root-court arena → the plain Adage threshold. Keep the beauty at the edge of generous playable ground. Friendly-looking flowers are not secret damage tiles. Earlier warning grammar reveals the false bond before the arena acts.

| Beat | Budget | Encounter and purpose | Saved elapsed time |
| --- | --- | --- | --- |
| An offered rest | 1:30 | Quiet garden view and one familiar Stalker. A projected still human figure appears beyond the combat boundary; no escort, health bar or compulsory conversation. | 1:30 |
| Beauty has a source | 1:30 | One Latcher exposes the low root knots that sustain the garden's luminous layers. The player attacks a physical source, not the projection. | 3:00 |
| Choose the plain path | 2:00 | An Echo/Latcher combination gives a decorative inviting route and a clear spare pocket. Both are honestly marked; use a committed root to reach the useful opening. Save at the boss court. | 5:00 |
| Garden, phase 1 | 2:00 | Separate root lane and petal-ring commitments; expose one low external tether in recovery. The human likeness remains distant and non-damageable. | 7:00 |
| Garden, phase 2 and departure | 2:00 | Combine those known commitments with a sun preview and one removable Latcher. Release the local false bond, restore the plain court and contact the threshold. No helper respawn. | 9:00 |

**Boss B05 — Sullenbode's Garden:** this is **Crystalman's fabricated manifestation of attachment**, named for its projected reference figure. It is not Sullenbode herself attacking the player, a literal scene from the novel, or a claim that her love is evil. The actual opponent is an external root network holding the attractive image in place. The player's slashes disengage that network; the likeness fades without a death animation.

Phase 1 uses **Draw** (two visible root ends preview one short lane and pull inward after lock) and **Enclose** (a petal-shaped outline previews one shallow ring segment, with two broad open approaches). Both are independently telegraphed, do not track after lock and briefly expose the same low root tether. No unavoidable full circle closes around the player. Phase 2 staggers those known attacks under the familiar sun-state preview. One Latcher is a removable pressure source: kill it once and it stays removed for that attempt. A slash can reach every required tether from safe firm floor; no blast, eye pickup or boosted dash is required.

The phase transition removes decorative flower layers while the actual floor, collisions and current safe pocket remain. The player's goal is leaving a false commitment, not defeating a human woman's desire. Any journal entry should preserve the novel's tragic Sullenbode rather than describing her as a canonical monster.

**Mastery gain:** reject scenery's emotional invitation through evidence supplied by the rules; spend an opening removing pressure or progressing the tether. Tuning starts with few successful ordinary recovery strikes, not a high-health endurance fight.

**Kit:** fixed garden floor, flowers/petals in intact and stripped states, single projected clothed human silhouette, external low root tethers, root-lane and broken-ring effects, one Latcher, existing Echo/Stalker/sun system and plain threshold. The original novel does not supply these flowers, root network or boss mechanics.

### A3-L5: Crystalman — Compose an Escape

**Source:** the final false-world revelation, rhythm/repetition, glassy sea and Muspel tower. Crystalman has related divine names/personae in the source; the boss is a landscape presence, not an invented canonical humanoid species. [Chapter 20](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0020), [Chapter 21](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0021).

**Layout:** a brief quiet approach across firm ground → one compact landscape-body arena → a plain escape platform framed by a distant tower and dark sea. The arena's beautiful scenery is Crystalman's game body. Make it small enough that the entire captured dash, its attack footprint, a clear escape pocket and the nearby low tether remain legible in the existing portrait camera. Do not require a new zoom level to make a fair attack possible.

| Beat | Budget | Encounter and purpose | Saved elapsed time |
| --- | --- | --- | --- |
| The offered world | 1:30 | Quiet glassy-sea framing and one short familiar Echo encounter on firm floor. The distant reassuring image is scenery. | 1:30 |
| A plain threshold | 1:30 | One compact familiar priority arrangement, then enter the landscape arena. Clear all regular threats before capture begins. | 3:00 |
| Crystalman, phase 1 | 2:00 | Capture one completed dash-and-attack; preview its world-space replay, resolve it once and expose a local tether. Repeat only as needed for the small phase objective. | 5:00 |
| Crystalman, phase 2 | 3:00 | At most two captured combinations, replayed sequentially in displayed order. No overlapping surprise echoes. Sever the final local tether and open firm escape ground. | 8:00 |
| Beyond the image | 2:00 | Scenic layers peel away around the retained floor. Contact the plain exit, then a brief tower/sea coda and campaign completion. No new last-second combat rule. | 10:00 |

**Boss B06 — Crystalman:** the player creates the threat's geometry by choosing a useful dash and attack. The next question is not merely whether they can dodge quickly, but whether their previous commitment left a retreat and a local tether approach. The fight formalises what the act has already taught: a warning predicts a committed action, and an opening is useful only if the player can reach it.

#### Exact capture and replay proposal

Keep **player aim input**, **completed world motion**, and **boss replay** separate. The current screen-space aim anchor is preserved without reinterpretation.

1. A capture slot arms only during the boss's clearly indicated recording state. Read a **completed** voluntary dash's actual world X/Z start, actual final world landing after collision shortening, and resolved path. A queued swipe is not a completed dash. Rejected or zero-distance movement produces no sample.
2. Pair that dash with the next normal attack that actually executes before another completed dash supersedes it. Record the slash's actual world origin, world direction, footprint and execution order. Do not store a finger endpoint as the world landing or recompute aim from the camera later. The same combo rule works with the current carried weapon's baseline close-range attack.
3. If the quick second tap actually produces the optional blast, record its actual follow-up direction and short-range footprint too. Wait for that combo window to close before locking capture. A slash-only combination is equally valid; the player never needs a loaded shell to generate an opening. Capture consumes a slot once, not once per input event.
4. Preview the **whole finite sequence** with an origin mark, world-space route, endpoint, slash arc, and a separate blast footprint only if one was recorded. Numbered pips and a shrinking tick border show order and start time. Use the actions' normal resolved durations in a short displayed playback timetable; do not reproduce an arbitrary idle wait between the player's dash and attack. Geometry and action order are exact; ornamental noise cannot add a hitbox. Give recognition + remaining cooldown + one normal escape dash before activation.
5. An apparition starts at the recorded world origin and follows that recorded route. It does not move its origin near the current player, retarget an arc, reflect a fresh tap, mirror the player's screen coordinates or chase after the replay. Its dash path is a travel preview rather than an extra damage strike; the recorded attacks are the threats.
6. Use the same stable arena collision layout through capture, preview and replay. Recorded movement is already shortened by walls. The apparition respects those boundaries and never extends through an obstacle. Captured attack footprints are clipped to the valid arena floor and cannot damage through blocking scenery. The ghost itself has no blocking body collider or contact damage. If the complete route and footprints cannot remain within the legible combat view, reject capture visibly and reopen the slot safely; do not activate an unseen echo.
7. **Before locking playback, require a feasible escape through the entire recorded sequence.** From the player's actual position and remaining dash cooldown, at least one ordinary dash must have both a clear swept floor path and a clear landing when the recorded attacks become active. A blast and slash from the same combination count together if their active times overlap. For two combinations, a cooldown-aware route must exist through both, including the separation between them; checking each footprint in isolation is insufficient. During replay, sun changes are decorative and no root, solar-lane or regular-enemy attack is added. If the bounded arena and exact recorded geometry cannot satisfy that invariant, show the rejected recording and re-arm safely without replaying or silently altering it. The arena must also allow a valid normal-dash/slash recording from every permitted capture pocket, so rejection cannot strand the player. Subsequent voluntary movement can make an otherwise available escape worse; the warning remains honest about that choice.
8. Phase 1 holds **one combination**. Phase 2 holds **at most two**, shown and played **one after the other** with a visible order and separation. The inter-echo gap must permit recognition, remaining cooldown and one ordinary clear escape dash; it is not merely a cosmetic pause. Each combination plays once, then is discarded. Replays cannot record themselves, create new replays or increase the buffer. No infinite imitation chain or third hidden slot appears.
9. After the finite replay completes, a **nearby external landscape tether** uncoils onto firm ground at ordinary slash range. Its recovery lasts long enough to finish any remaining dash cooldown, reach it with a normal dash and execute a baseline slash. Do not move the tether to the remote start of a route or put it behind a blast-only obstacle. Suggested first test: one clear successful slash per exposed tether; adjust the number of meaningful exchanges from play, not through health bloat.
10. A tether severed in a phase strips decorative scenery, exposing a void **outside or below the maintained floor**. It never drops the player, removes safe ground underneath them, spawns random debris damage or changes controls. Existing attack warnings finish or cancel visibly before a phase save occurs.
11. On phase retry, clear captures, ghosts, active attack footprints and transient effects. Restore firm floor, the phase's entry sun state and a safe player position. The recording frame re-arms for the next completed combination. Never replay stale data from a previous attempt. Backgrounding freezes the sequence exactly; the resume-overlay tap cannot become an attack or a capture event.

The boss can wait in its readable capture state while a player deliberately chooses a route. It does not drain health or create a concealed attack because someone has paused to inspect the arena. If recorded paths repeatedly lack a safe landing, simplify the arena or delay activation; do not silently rewrite the player's action. The bounded first prototype tests one dash, one slash, one echo and one tether before the second phase is attempted.

**Ending:** severing the local final tether opens an escape through this game's false-world arena. The player emerges with the same gestures and baseline damage, now able to recognise and refuse its repetition. The tower coda suggests another struggle beyond the beautiful image. Do not display “Crystalman destroyed” or claim the novel ends with this sword duel, universal salvation or uncomplicated happiness.

**Kit:** landscape arena reusing the act's stone, roots, reflective overlays and garden layers; one luminous presence; capture frame; route/arc/blast preview states; one reusable apparition; four tether visual states (closed, exposed, severed, spent); restrained scenery stripping; firm escape platform and distant tower. No new ordinary enemy role is required.

## Three optional levels with parent-kit reuse

Unlock each side level after clearing its parent. Select it separately from the level menu; it is not a mandatory detour inside the main-act budget. First testing budgets are **3 / 4 / 5 minutes**, within the **3–5-minute** range for each. Reward completion stamps or cosmetics, never damage growth, a compulsory organ upgrade or an item needed for the final boss. No fail timer is needed.

| Optional level | Parent / initial budget | Objective and mastery question | Reused kit | Few additions |
| --- | --- | --- | --- | --- |
| A3-O1 **Pillars Before Their Time** | Twin Suns / **3 min** | Contact three temporal-mirage markers in any order, then reach the exit. Which collection order leaves a useful flank when the next sun state appears? | Sand shelves, pillars, low trees, Stalker, sun previews and white shadows | Three small marker props with empty/collected states; exit seal |
| A3-O2 **The Quiet Root Circuit** | Living Forest / **4 min** | Clear three existing root courts, choosing which Latcher to remove first in the last mix. Can I preserve the return pocket by baiting the root away from it? | Trunks, leaf floor, roots, Latcher, Stalker, sun states and knots | Simple route glyphs; one spent-knot completion marker |
| A3-O3 **Irontick's Last Reflection** | Mirror Sea / **5 min** | Complete three short replay arrangements around the dry resonant apron and contact the exit. Can I repeatedly reach a replay endpoint without chasing the harmless image? | Dry shore, shelves, stones, scenic lake-ring, Echo/reflection, resonance and Stalker | Three stage pips; one small shell-like scenic collectible |

The first side level has saved completions around 1:00, 2:00 and 3:00; the second around 1:00, 2:00 and 4:00; the third around 1:30, 3:00 and 5:00. A failed final arrangement restarts there with normal supplies. The props use contact collection or existing slash actions; no new interaction button, boating, collectible farming or fourth environment kit is introduced. The optional resonance level does not add an Earthrid boss to the main production count.

## Alternate boss candidates, outside this five-level scope

The database retains these people and manifestations for comparison. They are **alternatives**, not additional required bosses or ordinary mobs. Selecting one later would replace a planned encounter and require a fresh pacing and source review.

| Candidate | Canonical reason to consider it | Adaptation question and restraint |
| --- | --- | --- |
| **Crimtyphon** (B01) | Coercive transformation and power in the Ifdawn strand. [Chapter 9](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0009) | Could support a transformation-themed local manifestation. Do not make the actual controls change or transform the player into a forced movement mode. |
| **Tydomin** (B02) | Possession, manipulation and a return to the séance strand. [Chapter 10](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0010) | Strong identity motif, but taking away voluntary input would violate the established control promise. Would need an external, previewed projection and a clear source target. |
| **Catice / Spadevil encounter** (B03 reference) | Conflicting claims of moral authority and sacrifice on Disscourn. [Chapters 11–12](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0011) | Better suited to a short narrative contrast than another health-bar duel; distinguish the two characters and their actions. |
| **Earthrid / Irontick** (B04) | The lake-instrument's destructive beauty and entrancement. [Chapter 15](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0015) | Could replace a Mirror Sea set piece with a bounded resonance boss. Warnings must work with audio muted; the instrument is not a conventional monster or canonical machine gun. |
| **Séance apparition** | A disturbing materialisation frames the journey. [Chapter 1](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0001) | A useful image for an optional journal or epilogue. Earth scenes should not displace the selected Tormance sequence. |

Sullenbode's Garden is selected for level 4 because it keeps the act's attachment and false-comfort themes immediately before Crystalman's landscape revelation. Its explicit fabrication is a deliberate boundary: preserving a sympathetic canonical person is more important than presenting every named character as an enemy.

## Art concepts should communicate the playable rule

The [concept-art library](reference-library/act3/README.md) groups character studies, environments, boss concepts, mood and gameplay studies, plus three game-view mockups. The game views are imagined screenshots, not captures of running campaign content. All images are concept references; a readable sheet still needs sprite animation, collision shapes and device validation before becoming a production asset.

Useful art review questions are concrete: can the portrait composition show the player's landing, the attack source, its locked warning and the recovery knot together? Does the safe floor remain obvious beneath white shadows, mist and reflections? Can a still frame distinguish decorative tree eyes from a Root Latcher, the harmless reflection from the real Echo, and a projected human likeness from the low tether that receives damage?

Do not derive a new art style from Act 1's timing system. Use the Act 3 identity already present in the campaign notes: unnatural light, violet/green pattern interpretations, white shadows, alive-seeming forest, reflective sea and beauty that gradually reveals a deeper structure. The novel gives specific reference cues; graphic textures, flesh-like embellishments, combat organisms and the boss garden remain inventions.

## Bounded tests before campaign production

These are hypotheses to test, not implemented tests or validated results. Start with the smallest arena that can disprove each rule.

| Hypothesis | Small test | Evidence to collect |
| --- | --- | --- |
| An experienced player predicts a sun state after one exchange | One Stalker, two safe pockets, normal dash/slash | First anticipated change, landing choice and stated reason; separate a bad reading from a gesture error |
| A sun change does not ambush a safe position | Trigger it during cooldown, at patch boundaries and while occupying the next outlined patch | Floor never disappears, delayed activation is legible, one normal escape remains possible |
| Latcher pressure creates a priority decision | One Latcher and one Stalker, two clear approaches | Deliberate target choices, root bait placement, no unavoidable cage or repeated contact damage |
| Real source and reflection are distinguishable without colour/audio | One Echo; grayscale or muted view; varied screen brightness | Correct first source identification and usable endpoint attack, rather than repeated guess attacks |
| New scenery does not obscure old rules | The same two-threat arrangement in forest, sea and garden kits | Source, warning and safe landing visibility in portrait; failures attributable to timing or positioning rather than camouflage |
| The garden fight preserves Sullenbode's role | Two-phase manifestation, non-damageable likeness and external tether | Player understands they release a false-world mechanism; no implication they killed the canonical woman |
| Crystalman records executed world geometry | Single slot; diagonal dash, collision-shortened dash, moved camera, screen-edge release, tap on aim anchor, queued/rejected dash | Recorded actual start/landing, direction and footprint; no screen endpoint substituted for a world coordinate |
| Replay is finite and fair | One slot, then two sequential slots; deliberately capture wide slash/blast footprints, corner landings and opposed routes | Exact preview/active agreement, no recursion, no third slot, collision clipping; cooldown-aware clear swept path and landing through the whole sequence, or safe visible rejection; valid baseline recordings remain available |
| Local recovery rewards composition | Single echo and tether; ordinary dash/slash only, no pickups | A clear normal-dash approach reaches slash range inside recovery; different chosen paths produce understandable tradeoffs |
| Interruption is coherent | Background during capture, warning, replay, sun change and phase transition | Timers and ghosts freeze; resume tap is consumed; retry clears samples and restores a safe consistent phase |
| The act earns its pacing without health padding | Measure each five-beat level with transitions for experienced players | Actual clear time, useful exchanges, idle waits, input failures and restarts; revise budgets before adding content |

First build **one sun-state room**, then **one Root Latcher mix**, then **one Echo room**, then the **single-slot Crystalman arena**. The five-level document is the desired campaign concept, not authorization to implement all of it now. Add the garden's second phase and two-slot finale only after the smaller rules remain clear with fixed stats, ordinary dash/slash and the current camera.

## Related artifacts

- [Act 3 research and entity database](reference-library/act3/research/RESEARCH.md)
- [Machine-readable pacing and encounter plan](reference-library/act3/research/levels.json)
- [Act 3 reference and concept-art library](reference-library/act3/README.md)
- [Campaign / Act 1 baseline](GAME_CONCEPT.md)
- [Act 2 proposal](ACT2_CONCEPT.md)

All combat organisms, attacks, boss vulnerabilities, sun-state timing, route arrangements and pacing values here are proposed game designs. Source links identify the novel material behind the interpretation.
