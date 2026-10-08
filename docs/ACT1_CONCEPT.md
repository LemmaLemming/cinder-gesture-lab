# Act 1 — The Moon

**Expanded design proposal, researched 8 October 2026.** Keep the existing **five main levels and 43-minute first-clear target: 6 / 8 / 9 / 10 / 10 minutes**. Three separately entered optional levels add **3–5 minutes each**, bringing all proposed Act 1 content to **52–58 minutes**. These budgets include movement, encounters and brief transitions. They are estimates for a new player, not countdowns or instructions to fill spare time with more enemies. The campaign levels, new enemy animations, boss fights and timings remain unimplemented and unplaytested.

The reference is Georges Méliès's *Le Voyage dans la Lune / A Trip to the Moon* (1902). The act expands the direction already established in [GAME_CONCEPT.md](GAME_CONCEPT.md), the [film object library](reference-library/act1/README.md) and its [style guide](reference-library/act1/STYLE_GUIDE.md). Its journey is **Observatory and Launch → Crater Gardens → Mushroom Caverns → Selenite Court → The Living Moon**. The game retains its own playable protagonist. The film's expedition, celestial performers, Selenites and return scenes supply a world and dramatic vocabulary; the gestures, combat roster, hazards and close-range bosses are game adaptations. [Restorer's film stories](https://melies.lobsterfilms.com/contes.php#)

The expanded [research database](reference-library/act1/research/RESEARCH.md) records film characters, environment groups, possible bosses and mood separately. The [level data](reference-library/act1/research/levels.json) carries the pacing, learning sequence, enemy aliases, phase checkpoints and production kits used here.

## Shared character contract

[PLAYER_EQUIPMENT_GUIDELINES.md](PLAYER_EQUIPMENT_GUIDELINES.md) defines the authoritative campaign-wide player and item rules. Acts 1, 2 and 3 use the same base gesture mechanics, controller, and underlying stats. Replaceable jacket, pants, shoes and one carried weapon may modify effective stats or provide bounded conditional effects. **Fixed baseline damage** means unchanged underlying damage: no act multiplier and no farmed permanent stat growth. Acts change encounters and available item themes within equal balance budgets.

Every required route and fight must remain practical with the standard reference loadout, ordinary dash and slash-only attacks. Existing fixed-stat completion tests refer to that loadout. Equipment or temporary powerups may offer alternatives; they never become mandatory traversal or boss keys. The shared guidelines take precedence over earlier unresolved equipment, duration or stacking proposals in this document.

## The same campaign scale, a different learning job

Acts 2 and 3 already use the five-level system that Act 1 established. Bring Act 1's documentation and art coverage up to that scope without adding a longer tutorial act. Its shorter opening gives the new player time to learn one action at a time; its later levels prepare the player for the decisions the other acts expect.

| Rule | Act 1 expanded working design | Act 2 proposal | Act 3 proposal |
| --- | --- | --- | --- |
| Main levels | **5** | 5 | 5 |
| First-clear budgets | **6 / 8 / 9 / 10 / 10 min** | 8 / 9 / 9 / 9 / 10 min | 8 / 9 / 9 / 9 / 10 min |
| Main-act target | **43 min** | 45 min | 45 min |
| Learning job | Learn the actual gestures, useful landings and committed threats | Prioritise machines and area denial with mastered gestures | Plan visible world changes and echoed actions |
| Major bosses | **King in L4; Man in the Moon in L5** | Handling-Machine in L3; Fighting-Machine in L5 | Garden manifestation in L4; Crystalman in L5 |
| Optional content | **3 proposals, 3–5 min each** | Same | Same |
| Optional production | Parent kit plus a few props or states | Same | Same |
| Saved progress | Encounter completions, before bosses, after phases | Same | Same |
| Phone interruption | Freeze simulation; consumed overlay tap resumes | Same | Same |
| Long-term power | Fixed baseline damage; access, mastery and optional cosmetics | Same | Same |

The main campaign targets **133 minutes** across the three acts. All nine proposed side levels add 27–45 minutes, giving **160–178 minutes** before retries, deliberate replays or reading the reference library. These remain planning totals. Playtesting may shorten the observatory once players understand the gestures, and can change individual beat budgets while preserving the approximate ten-minute level ceiling. [Act 2 design](ACT2_CONCEPT.md), [Act 3 design](ACT3_CONCEPT.md)

The confirmed campaign format is portrait, pixelated 2.5D, a close fixed-angle overhead camera following the player, and movement across the ground plane. Swipes supply all voluntary movement. One carried weapon and fixed baseline damage carry through the act. Do not solve teaching or layout problems by adding a joystick, jump, climb, ranged-only target, hotbar or permanent upgrade requirement.

## The new player's repeated decision

The act asks **Where should I land so I can survive the next committed attack and make my own attack useful?**

The playable cycle is **read a target or windup → swipe toward a useful ground landing → let the threat lock and commit → tap in the direction measured from the last swipe's screen endpoint → the slash connects with a nearby target → optionally chain one blast → use the result to choose the next landing**. The mushroom level adds a second consequence: a slash can release spores, causing enemies to retreat and opening a route.

Three kinds of progress remain separate:

- **Player mastery:** accurate screen-space aiming, any-angle dashes, reading when a threat has committed, preserving a retreat, using spores deliberately, and reaching a boss opening while it is available. Identical character stats should be enough to improve on a replay.
- **Attempt state:** health, carried weapon, temporary pickups, available spore clusters, enemies remaining and the current encounter. An encounter retry restores its intended start and supplies. Defeated boss helpers stay defeated for the remainder of that attempt; they do not become a farming loop.
- **Persistent state:** unlocked levels, completed encounters and boss phases, optional completion and cosmetic rewards. Completing a parent level unlocks its optional level immediately. Main progression never requires a side-level reward or permanent damage purchase.

Tutorial prompts should describe the action the player can perform now. Show one short demonstration, then let doing the action advance the lesson. Do not lock successful players in an animation, require a flawless streak or make them repeat all instruction after a checkpoint retry. All confirmed combat gestures remain available from the opening; the lesson sequence controls which situations are presented.

### Teach the actual aim origin

The aim anchor is the **final finger-release endpoint of the latest swipe in screen space**, not the player sprite, the swipe's starting point, the threshold at which a drag first counts as a swipe, or the ground location where the dash ends. Camera movement does not turn it into a world target. A tap strikes along the vector from that anchor to the tap. Reset starts the anchor at screen centre. A tap exactly on it keeps the last facing direction. The first tap slashes immediately; the current prototype accepts a nearby second tap within **280 ms** and adds one blast. The blast is a follow-up, not another slash or a weapon-switch instruction. [Confirmed mapping](GAME_CONCEPT.md)

The observatory's demonstration must literally show **release upper-left → tap nearer the centre → slash down-right**, even if the character is somewhere else on the floor. A small teaching cue can temporarily show the actual anchor and the anchor-to-tap direction; its visual form is a proposal. It must not redirect aim or encourage tapping the enemy sprite as if the player were the aiming origin.

A release near a screen edge can make an outward tap impossible. Teach the remedy in the safe workshop: perform another ordinary positioning swipe that ends at a useful screen location, then aim from that new anchor. There is no separate aim-only swipe. Arrange required targets and recovery windows so the player has space and time to make that dash. Do not silently recentre the anchor after an encounter or camera movement; any new checkpoint or resume initialisation should follow the existing reset rule and make its state understandable.

### Learning sequence

| Level | First readable instance | Application | Combination or pressure | Evidence of learning |
| --- | --- | --- | --- | --- |
| L1 Observatory and Launch | Free dashes and one safe practice target | Aim from a different release point; try the optional blast | Avoid one slow loading-arm lane, then reach a target | The player can explain or demonstrate the upper-left release/centre tap result and move to a useful attack side |
| L2 Crater Gardens | One floor impact, then one Rush Selenite alone | Bait a locked rush on either of two approaches | A familiar rusher plus staggered impact warnings | The player waits for commitment, lands safely near the recovery and attacks |
| L3 Mushroom Caverns | A small swarm; one reachable cluster with room to observe | Hit the cluster and use the retreat; choose between two mushrooms | One Spear Guard alone, then guard plus swarm | The player spends spores deliberately for space, rather than assuming the cloud damages enemies |
| L4 Selenite Court | Familiar guard, then a two-guard formation | Choose a gap and punish the earlier recovery | Roundel impact plus guards; King lunge then one finite guard pair | The player identifies a priority target and keeps a return landing |
| L5 Living Moon | Separate Blink and Sneeze demonstrations | Evade each locked shape and approach the same low eye rim | Staggered circle and cone in one compact arena | The player uses known rules to reach the final opening with normal dash and slash |

Do not front-load the spore supply rule, boss phases and future acts into the hall. Give the player one immediate decision and one clear consequence. A quiet camp, cleared chamber or curtain threshold provides a natural pause after each learning block. Optional journal entries can explain characters and film material after the player has seen them.

## Film anchors and adaptation boundary

| Film/reference material | Contribution | Game interpretation |
| --- | --- | --- |
| Astronomers in ceremonial dress, lecture instruments, workshop and launch crew | Friendly preparation, theatrical scientific ambition and comic machinery. [Surviving astronomer's mantle](https://www.cinematheque.fr/objet/392.html) | Safe rehearsal targets and a telegraphed loading arm. Neither is a new hostile human faction or a film boss. |
| The capsule in the Moon's eye and the landed lunar expedition | The act's central image, finless capsule and painted rock scenery. [Lunar exterior frame](https://commons.wikimedia.org/wiki/File:M%C3%A9li%C3%A8s,_viaggio_nella_luna_(1902)_07.jpg) | A generous crater floor, readable impact warnings and a late face-side arena. The film does not stage the proposed Blink/Sneeze weak-point fight. |
| Sleeping travellers and human performers in stars, crescent and planetary forms | A dreamy rest between discovery and danger. [Celestial dream frame](https://commons.wikimedia.org/wiki/File:M%C3%A9li%C3%A8s,_viaggio_nella_luna_(1902)_08.jpg) | A quiet checkpoint tableau. Celestial figures remain scenery rather than five extra enemies or bosses. |
| Giant fungi, umbrella imagery, rock shelves and a trunk-like form | Strange but handmade lunar ecology. [Grotto frame](https://commons.wikimedia.org/wiki/File:M%C3%A9li%C3%A8s,_viaggio_nella_luna_(1902)_09.jpg) | Reachable clusters release falling spores that repel living Selenites. The clusters, finite supply and floor field are proposed game functions, not observed film mechanics. |
| Acrobatic biped Selenites, rib bands, projecting headpieces and spears | A consistent creature family with expressive poses. [Original court frame](https://commons.wikimedia.org/wiki/File:M%C3%A9li%C3%A8s,_viaggio_nella_luna_(1902)_10.jpg), [museum performer context](https://www.cinematheque.fr/objet/1540.html) | Three regular combat roles using the same visual family. Rush, swarm and guard behaviour are new designs, not three authenticated species. |
| Seated royal figure, low seat, radiant roundels, crescent columns, curling panels and curtains | A broad lunar court and the earlier boss's identity. [Court frame](https://commons.wikimedia.org/wiki/File:M%C3%A9li%C3%A8s,_viaggio_nella_luna_(1902)_10.jpg) | A short lunge, finite guard formation and animated roundel warning. The throne remains a side landmark rather than a long compulsory aisle. |
| The chase, capsule escape, cord, attached Selenite and white puffs | A playful flight and an act-ending return. [Escape frame](https://commons.wikimedia.org/wiki/File:M%C3%A9li%C3%A8s,_viaggio_nella_luna_(1902)_12.jpg) | Defeating the local Moon encounter opens a contact hatch and a short escape tableau. The game does not add swimming, a climb or capsule steering to reproduce every film action. |

The Moon-white, dusty-silver and black palette is the chosen game interpretation. Surviving hand-coloured film material is separately tagged in the library; it does not make the monochrome game palette the film's only authentic palette. Later Méliès drawings and museum reconstructions also keep their own dates and provenance. [Existing provenance guide](reference-library/act1/STYLE_GUIDE.md)

## Cast and the smallest regular enemy roster

Earth astronomers, expedition companions, workshop labourers, launch officers, sailor-style attendants and return celebrants inform friendly tableaux. They can gesture toward a practice target, work around the shell or occupy the camp beyond the collision floor. They do not attack the new player or receive enemy health bars. Celestial dream performers remain decorative characters. The player never has to protect an escort health bar, hurt a frightened civilian or clear a celestial cast to progress.

Use the three proposed regular roles already selected in the game concept. Their research entities are **C30–C32**, with gameplay aliases **A1-E1–A1-E3**. The major bosses are research **B01 / A1-B1** and **B02 / A1-B2**. Candidate bosses in the research database are alternatives for discussion; they do not expand this five-level commitment.

| Regular enemy | First appearance | Warning, commitment and recovery | Decision tested |
| --- | --- | --- | --- |
| **Rush Selenite** — C30 / A1-E1 | L2 Crater Gardens | Crouches, shows one short floor lane toward a sampled world position, locks it, rushes once and pauses at the end | Dash beside the committed lane, preferably near the stopping point, then aim a slash |
| **Swarm Selenite** — C31 / A1-E2 | L3 Mushroom Caverns | Small acrobatic bipeds close around approaches; the next attackers crouch and raise their arms before brief hopping strikes | Preserve a broad exit, catch nearby attackers in a swing or make room with spores |
| **Spear Guard** — C32 / A1-E3 | Late L3; developed in L4 | Plants its feet and raises an oversized spear, previews one short thrust lane, locks and strikes, then lowers the spear in recovery | Move around the committed lane or stalk; choose whether the guard or the nearby swarm is the better target |

A visual family saves production work and helps recognition. The rusher reads through its forward crouch, the smaller swarmer through its raised arms and scale, and the guard through its long spear and braced pose. Preserve upright masked silhouettes, pale rib bands and projecting headpieces. Do not replace them with crawling skull-faced beetles or introduce a fourth court support species. [Selenite object observations O49–O51](reference-library/act1/objects-grotto-and-return.json)

Initial proposals use one preparing attacker in first demonstrations, then at most **two preparing attacks at once**, with staggered commitments. Begin swarm teaching with three or four bodies and test approximately eight in the later two-mushroom room. Bodies yield enough space for a normal dash; surrounding the player must not create an unavoidable collision cage. Touching an enemy does not cause repeated contact damage. Every damaging strike has a tell. A swarmer falling to one baseline slash is a useful starting hypothesis; enemy health, counts, windup and recovery remain tuning proposals.

The optional blast gives impact or a better cluster payoff without becoming an armour key. A player can complete every required enemy and boss phase with ordinary slashes, fixed stats and normal dash. Temporary dash or 360-swing pickups are optional experiments after the relevant base decision is understood; they do not teach the fundamental rule on the player's behalf.

## Hittable spores create breathing room

**Confirmed direction:** spores sit on mushrooms where the player can hit them; hitting them makes spores fall around that mushroom and temporarily **repels enemies**. This replaces the old automatic damaging-vent interpretation. Enemies remain alive and visibly retreat. The player is unharmed by the field. [Current confirmed interaction](GAME_CONCEPT.md)

The following detailed rules are proposals:

1. A distinct hanging cluster sits low enough for an ordinary slash. Decorative high caps are not required targets. Approach it with a normal ground dash and aim using the actual screen anchor.
2. A hit releases restrained square spores above a predictable floor boundary. The particles suggest falling material; the boundary determines which enemies react. Random particles do not set the gameplay radius.
3. An affected regular enemy cancels its current attack, recoils, turns and retreats beyond the boundary. It avoids the active field and regroups visibly outside it. Rushers and guards also obey this rule in mixed rooms. No spore damage, enemy death, repeated stagger lock or disguised poison is implied.
4. Spend the opening on a dash through the crowd, a new attack side, an isolated enemy or a route to the second mushroom. As the field thins, enemies approach again using ordinary tells.
5. The first test uses **two visibly separate clusters per mushroom, about three seconds of repulsion, a thinning final half-second, and a radius around three-quarters of normal dash distance**. These numbers and the no-replenishment starting rule are provisional. Required escape remains possible after all clusters are spent.
6. A slash consumes one cluster per mushroom. Additional hits during its release and active field consume no second cluster and do not refresh the field. This lets the ordinary slash-then-blast sequence work without accidentally spending both supplies. A spent cluster leaves a readable empty patch; an encounter retry restores the section's original supply.

The tradeoff is **use a cluster now for a safe approach or keep it for a tighter crowd later**. The field opens space; the player's following decision spends that space. Do not make spores an obligatory weapon against every Selenite or require the player to discover a hidden damage immunity. Broader environmental interactables remain a later design topic after enemy behaviour; this expansion does not add a new menu of traps.

## Main sequence

Beat budgets below sum exactly to the existing level targets. Saved elapsed times describe the estimated first clear at each completed beat, not when a timed autosave fires. Advance and save when the exercise, encounter or phase is complete. A proficient player may finish earlier.

| Level | Objective | Main spatial question | Target | Boss |
| --- | --- | --- | --- | --- |
| A1-L1 **Observatory and Launch — The Launch Rehearsal** | Complete the launch rehearsal and reach the capsule hatch | Where should I land so the next tap has a useful direction? | **6 min** | None; loading arm is a tutorial mechanism |
| A1-L2 **Crater Gardens — The Celestial Camp** | Cross the lunar clearings and open the grotto passage | Can I make danger commit and attack from my safe landing? | **8 min** | None |
| A1-L3 **Mushroom Caverns — The Breathing Grotto** | Use the fungal chambers to break through a Selenite crowd | When should I release spores, and how should I spend the opening? | **9 min** | None |
| A1-L4 **Selenite Court — The King's Formation** | Break the royal formation and open the exterior curtain | Which gap gives me a safe landing and a worthwhile target? | **10 min** | **Selenite King** — B01 |
| A1-L5 **The Living Moon — Departure Refused** | Open the capsule hatch and escape the Moon | Can I evade a committed expression and return to the eye rim? | **10 min** | **Man in the Moon** — B02; act finale |

### A1-L1: Observatory and Launch — The Launch Rehearsal

**Source vocabulary:** O01–O08 ceremonial hall, O09–O20 capsule/workshop/expedition kit, O21–O31 roof, cannon and launch crew. The museum identifies the embroidered astronomer's costume with the early tableaux. [Original mantle record](https://www.cinematheque.fr/objet/392.html)

**Layout:** open lecture floor → workshop with two broad approaches → continuous loading roof beside the giant cannon. Benches, blackboard, instruments and friendly robed professors frame the hall. Workers handle tools around the finless shell in scenic space. Railings, steps and roof edges suggest elevation without imposing a fall hazard or mandatory climb. Keep the capsule and foreground machinery off the principal attack sightline.

| Beat | Budget | Encounter and teaching purpose | Saved elapsed time |
| --- | --- | --- | --- |
| A direction to try | 1:00 | A brief friendly arrival, then any-angle swipes between wide floor markers. Let the player observe fixed dash distance and cooldown without damage. Markers are tutorial additions, not collectible rewards. | 1:00 |
| The point you released | 1:00 | One reachable practice target. Demonstrate upper-left release and centre tap producing a down-right slash. A successful hit advances immediately; repeat a concise cue only after a clear input error. | 2:00 |
| Workshop approach | 1:30 | Benches and anvil frame two generous approaches to a target. Reposition and aim diagonally, including one safe screen-edge example. Demonstrate one optional quick second-tap blast after the immediate slash. | 3:30 |
| Loading-arm lane | 1:30 | The slow arm marks a short lane in empty space, locks, swings and rests. Observe one safe cycle, then choose a side landing near a practice target. No roof-edge knock-off or unseen moving platform. | 5:00 |
| All aboard | 1:00 | One familiar arm warning beside one target. A safe landing leaves the target in ordinary slash reach. Clearing the rehearsal opens the broad hatch approach; contact with the hatch starts the launch tableau. | 6:00 / level clear |

**Mastery gain:** the player can move to change both position and the screen anchor, then aim intentionally from that anchor. The safe target is useful because a wrong slash direction gives feedback without a punishing enemy counterattack. The loading arm applies the same preparation/lock/active/recovery grammar that lunar enemies later use.

**Replay and failure:** successful actions skip instruction pauses. Missing a target does not reset the exercise; let the player reposition and try again. A failed loading-arm exchange restarts at the roof checkpoint with the warning inactive. Checkpoint saves in the safe hall are small additional conveniences, not a requirement to complete every lesson in one sitting.

**Kit and additions:** ceremony robes, coats/hats/beards, friendly workers and attendants, hall columns/windows/blackboard, astronomical instrument, bench, hammer/anvil, finless capsule and hatch, telescope, painted roofline, chimney, cannon and railings. Add one practice target with idle/hit/cleared states, floor markers and one loading arm with warning/active/recovery states. The arm is not a boss or an additional enemy species.

### A1-L2: Crater Gardens — The Celestial Camp

**Source vocabulary:** O34–O36 jagged painted scenery and landed capsule; O37–O42 celestial dream figures; O49–O50 Selenite body/headpiece; O58 white-puff reference. [Lunar exterior](https://commons.wikimedia.org/wiki/File:M%C3%A9li%C3%A8s,_viaggio_nella_luna_(1902)_07.jpg), [dream tableau](https://commons.wikimedia.org/wiki/File:M%C3%A9li%C3%A8s,_viaggio_nella_luna_(1902)_08.jpg)

**Layout:** a tilted shell on an open landing floor → three connected lunar clearings → two approaches that rejoin → a quiet sleeping camp → grotto entrance. Jagged scenic rock wings carry broad white streaks and black creases. Ordinary painted crater rings are harmless decoration. Earth, crescent woman, human-faced stars and the Saturn performer form distant landmarks around the camp, leaving local floor warnings unobstructed.

| Beat | Budget | Encounter and teaching purpose | Saved elapsed time |
| --- | --- | --- | --- |
| Landing clearing | 1:30 | One isolated floor circle fills, locks and produces a bright square impact puff. A safe neighbouring landing is visible throughout. First dodge has low pressure; harmless crater rings look different from the animated warning. | 1:30 |
| First Selenite | 2:00 | One rusher crouches, locks its short lane and rushes. First exchange is spacious. Show its stopped body and recovery clearly so a dash can both evade and put the next slash in reach. | 3:30 |
| Two approaches | 2:00 | Choose a rock-framed route or a more open route. Each uses one familiar rusher and one impact warning. Both rejoin; neither is a locked reward path or a long return through cleared space. | 5:30 |
| Celestial camp | 1:00 | Brief movement into a quiet sleeping tableau, a clear save cue and a view of the next entrance. No attack begins until the next broad encounter threshold is crossed. Optional journal inspection is outside the time budget. | 6:30 |
| The grotto opens | 1:30 | One familiar rusher with two staggered impact warnings. At least one ordinary-dash safe pocket remains. Defeat that rusher to stop the impacts and open the passage; crossing it by contact clears the level. | 8:00 / level clear |

**Mastery gain:** danger can stop tracking before activation. The player learns to read the commitment, then select a landing near a useful recovery rather than flee to the farthest point. An enemy's world-space sampled target and the screen-space finger-release aim anchor are visibly different ideas; the lesson must never conflate them.

**Kit and additions:** painted rock flats, crater floor, capsule landing state, cloud/black-sky backdrop, camp travellers, Earth/crescent/star/Saturn scenic performers, rusher and its crouch/rush/recovery poses, animated circle impact and square puff. The final rusher visibly anchors the repeating impact mechanism; its defeat ends the known sequence rather than spawning a surprise wave.

### A1-L3: Mushroom Caverns — The Breathing Grotto

**Source vocabulary:** O43–O48 shallow-capped fungi, porous forms, trunk and rock shelving; O49–O51 Selenite family and spear; O56 exit curtain. The film frame is the direct scenery anchor. MoMA dates its separate grotto drawing to c.1930–31. [Film grotto](https://commons.wikimedia.org/wiki/File:M%C3%A9li%C3%A8s,_viaggio_nella_luna_(1902)_09.jpg), [later drawing record](https://www.moma.org/collection/works/38318)

**Layout:** broad irregular fungal chambers with large grounded stalks creating two useful approaches. Shallow caps, porous foreground forms and black openings provide theatrical depth. A fallen trunk sits beside a broad continuous passage; shelves stay scenic. Selected low clusters stand out on the mushrooms. Fade or reposition foreground caps if they obscure the player, cluster, retreat lane or warning.

| Beat | Budget | Encounter and teaching purpose | Saved elapsed time |
| --- | --- | --- | --- |
| Umbrella grove | 1:30 | Three or four small swarmers first, with generous gaps and one prepared hopping strike at a time. Use an ordinary aimed swing to clear an approach. Only grounded stalks block movement and attacks. | 1:30 |
| Breathing chamber | 2:00 | Preview one low cluster before the pack closes. Hit it with a normal slash; enemies visibly recoil and retreat. Let the player use that space, then show the thinning field and readable regroup. | 3:30 |
| Crossed grotto | 2:30 | Two mushrooms and a larger swarm, initially about eight bodies. Finite visible clusters make immediate use compete with keeping an escape opportunity. Retreating bodies must leave a broad lane, and an ordinary escape remains after supplies run out. | 6:00 |
| The spear braces | 1:00 | One guard alone in an open pocket. It raises and braces its spear, locks a short lane, thrusts and lowers the weapon. Circle the committed lane with a dash and slash the recovery. | 7:00 |
| Court approach | 2:00 | A small swarm plus one guard around a familiar mushroom. Spores repel both. Choose between passing the guard, clearing swarmers or punishing its recovery. Defeat the final group to open the curtain; contact with the passage clears the level. | 9:00 / level clear |

**Mastery gain:** the player's attack can change enemy position through an environmental prop. The player chooses when to spend a finite source of room, then uses the opening for a concrete purpose. The guard arrives alone before the combined finale; the cluster's full/spent and active/thinning states are already familiar before that pressure.

**Kit and additions:** shared fungi/stalks/porous forms, rock shelves, trunk, continuous chamber floor, curtain, swarmers and their crouch/hop/retreat poses, one guard with braced spear/recovery, reachable full/spent clusters, falling spores and a restrained field boundary. The earlier grotto concept's automatic vent depiction is superseded. New art should show a hit cluster and living enemies retreating, leaving the player unharmed.

### A1-L4: Selenite Court — The King's Formation

**Source vocabulary:** O49–O57 Selenites, spears, royal figure, low seat, roundels, crescent columns, curtain and curling ornament. The broad original tableau places the royal area to one side. [Court frame](https://commons.wikimedia.org/wiki/File:M%C3%A9li%C3%A8s,_viaggio_nella_luna_(1902)_10.jpg)

**Layout:** three linked open courts with side scenery and a compact side-mounted throne. Radial ornament and curtains frame clear floors. Entry through the curtain reveals a performance space; there is no narrow cathedral aisle, new stone dungeon kit or dense procession of bodies blocking required dashes.

| Beat | Budget | Encounter and teaching purpose | Saved elapsed time |
| --- | --- | --- | --- |
| Curtain entrance | 1:30 | One familiar guard in open space, with no mushroom required. Rehearse the brace/lock/thrust/recovery sequence from a new approach. | 1:30 |
| Formation court | 2:00 | Two guards in parallel lanes leave a wide gap; a second short arrangement turns the same pair inward. Choose the useful side and earlier recovery. Commitments stay staggered. | 3:30 |
| Royal approach | 2:30 | A low roundel brightens and produces the known circular impact. First observe one quiet cycle, then combine it with guards. Choose a guard to remove while preserving a landing away from the impact. End at the boss checkpoint. | 6:00 |
| King phase 1 — The lunge | 2:00 | The King steps away from the throne, marks a short lunge lane, locks, commits and recovers. Use a normal sideways dash and ordinary slash-range approach. The phase teaches this action with no helpers. | 8:00 / phase checkpoint |
| King phase 2 — The formation | 2:00 | One guard pair enters visibly once. Their learned thrusts commit before the King's known lunge. Attack a guard to simplify later exchanges or punish the King. Defeat the King to open the exterior curtain; contact exits. | 10:00 / level clear |

**Boss B01 / A1-B1 — Selenite King:** adapt the seated royal figure as a mobile boss with a distinct crown/headpiece silhouette, rib bands and broad gestures. Research basis **C21** and objects O52–O53 identify the source figure; the lunge and formation rules are inventions.

There are two phase budgets, with a save at their transition. Phase 1 demonstrates the lunge; phase 2 introduces one finite pair of familiar guards. Defeated guards remain defeated for the rest of that boss attempt. The King continues the known lunge without replacing them. A phase-2 retry restores that phase's coherent starting arrangement, rather than awarding repeated drops. Difficulty comes from target priority, placement and staggered timing. Health does not supply an extra sequence of identical waves.

The King's recovery must last long enough to reposition if the current screen anchor is unhelpful, approach at ordinary slash distance and make meaningful progress with one slash. The blast can add impact, but no mandatory blast shield or armoured stage appears. The player's safe pocket remains visible alongside the lunge origin and warning; the King does not dash through a camera edge and strike before reappearing.

**Mastery gain:** the first boss rewards the same deliberate landings and recovery attacks learned on regular enemies. The player can simplify a complicated space by removing a support threat, a decision Act 2 will build upon.

**Kit and additions:** guards and existing formations, roundel/circular-impact system, curling panels, crescent columns, curtains, low throne, King lunge/recovery and summon gestures, one visible finite helper entrance and defeat/open-curtain states. The roundel's animation is a game use of a film ornament. There is no fourth regular court enemy and no requirement to build a separate boss architecture kit.

### A1-L5: The Living Moon — Departure Refused

**Source vocabulary:** O32–O35 face, cloud border, rocks and crater scenery; O09/O10/O36 capsule/hatch states; O59–O61 ledge, cord and attached Selenite. The film's eye image supplies the boss identity, while the proposed fight is new. [Lunar/return reference library](reference-library/act1/README.md), [escape frame](https://commons.wikimedia.org/wiki/File:M%C3%A9li%C3%A8s,_viaggio_nella_luna_(1902)_12.jpg)

**Layout:** a short rearranged return through familiar rock clearings, then one compact battlefield along the lower face. A nearby eye, cheek and nose establish scale. The whole face can extend beyond the view, but every active attack source, warning, safe landing and local weak point appears within the ordinary following camera. The capsule and scenic ledge sit beyond the combat pocket until the hatch opens. No climb, swimming, face-wide chase or capsule-control phase is required.

| Beat | Budget | Encounter and teaching purpose | Saved elapsed time |
| --- | --- | --- | --- |
| Wrinkled return | 2:00 | Familiar rock/crater pieces now suggest facial creases. One isolated impact and one brief rusher exchange rehearse commitment and useful landings. The route is compact; it does not retrace whole earlier levels. | 2:00 |
| Capsule checkpoint | 1:00 | The hatch is visibly blocked. Show the low eye rim, nearby nose and available ground before the fight. Entering the broad threshold starts the boss; the established camera remains. | 3:00 / boss checkpoint |
| Moon phase 1 — Blink | 2:00 | The eye marks one circle at a sampled player world position, then locks and strikes there. Dash to safe ground. During recovery the injured eye leans down and its outlined rim becomes reachable by ordinary slash. | 5:00 / phase checkpoint |
| Moon phase 2 — Sneeze | 2:00 | The nearby nose visibly lifts and previews a short cone; direction locks before release. Teach it alone, then alternate it with the known circle. Recovery offers the same eye-rim target. | 7:00 / phase checkpoint |
| Moon phase 3 — Final expression | 2:00 | Combine one known impact circle and one known cone with offset commitments. A normal-dash safe landing remains visible. The eye returns to the same close-range opening; no new surprise attack appears. | 9:00 / boss clear |
| The hatch opens | 1:00 | Final flinch, short movement to the open hatch and contact-triggered escape. Reuse capsule, cord, attached Selenite and white-puff imagery. A concise return/celebration vignette can close the act and unlock Act 2. | 10:00 / level clear |

**Boss B02 / A1-B2 — Man in the Moon:** research basis **C14**, objects O32–O35. Three phase budgets teach two attacks separately before combining them. Blink samples the player's actual ground position once at the beginning of the warning; after the visible lock it does not track a new dash. Sneeze likewise locks its world-space direction before activation. These targeting rules have no relationship to the screen-space finger-release anchor used by the player's taps.

Both attacks expose the same **lowered eye rim** in recovery, at ordinary slash range. The eye is not a distant ranged target and the player does not travel across a giant face between hits. Keep that contact point low and visually distinct from the enormous decorative eye. Give enough recovery for one useful positioning dash and an aimed slash. If that cannot fit the established portrait camera, revise the arena and face pose rather than requiring a wider combat camera.

The combined phase keeps the already learned shapes and staggers their commitments. Safe movement must work without relying on the prototype's brief dash invulnerability or crossing an active damaging region. A large expression conveys escalation; it does not hide the next warning behind facial animation or debris. Boss helper waves, a new enemy and a last-second third attack are unnecessary.

**Mastery gain:** the new player has become capable of reading a large threat through local information, reaching a useful opening and aiming under controlled pressure. That prepares the player to recognise machine commitment in Act 2 without another gesture tutorial.

**Kit and additions:** shared rock flats/crater floor, face-side creases, eye/nose/cheek poses, Blink/Sneeze windup/lock/active/recovery, low eye-rim contact state, capsule blocked/open hatch, cloud/sky framing, cord and clinging pose, restrained square puffs. A short return can reuse harbour, astronomer, launch-attendant and celebrant reference pieces without becoming a sixth playable level.

## Shared layout, checkpoints and mobile sessions

Let **D** mean ordinary unobstructed dash distance. The current prototype uses **D = 2.7 world units**, a fixed-angle overhead player-following camera and a **540 × 1170 portrait reference resolution**. Start greyboxing with clearings about two dash lengths across, required openings around one dash length wide and multiple generous landing pockets. These are starting dimensions, not guaranteed final measurements; projection, sprite scale and finger occlusion need validation in the actual view. [Prototype details](GAME_CONCEPT.md)

Warnings use shape, fill and animation as well as value. The warning, its origin and a reachable safe landing must be visible together. Lead time must cover recognition, any remaining dash cooldown and one normal escape dash. First demonstrations are low pressure; later combinations stagger their locks and retain a reachable pocket. Sound supports the visible tell rather than being the only cue. Falling spores, scenic stars, face motion and square debris must not obscure the next attack or the actual cluster target.

All required ground is continuous and works with normal dash. Exit thresholds are broad. Reaching a cleared passage, collectible part or capsule hatch triggers the relevant interaction by contact; combat taps retain their slash/blast meaning. Friendly figures and decorative caps should not block required dashes. Temporary dash length never gates an exit or required gap, and the 360-swing pickup never supplies the only possible crowd solution.

Save at completed encounters and the beat/phase markers above, targeting roughly **1–3 minutes between saved completions**. A checkpoint retry starts in clear ground with no active warning, coherent enemy positions and restored intended local supplies. Boss phase saves prevent replaying an entire ten-minute level. Cleared rooms stay safe; no unannounced respawns behind the player. The safe tutorial and camp can save sooner because their exercises are brief.

When the app backgrounds, immediately freeze enemy movement, dash cooldown, warnings, active fields, pickup timers and boss phase logic together. Resume shows a paused state; its tap is consumed by the overlay and cannot become an accidental slash or start a double-tap chain. Continue from the frozen state. Saving completed sections and resuming a suspended live encounter are different operations; neither silently clears an active danger while leaving its timer running.

## Optional levels reuse their parent kits

These are separately selected side levels unlocked by clearing their parent. Their first-clear range is **3–5 minutes**; initial detailed budgets are 3, 4 and 5 minutes. Each has one checkpoint before the final exercise and uses ordinary slashes, normal dash, one carried weapon and fixed baseline damage. An optional completion earns a film-themed cosmetic or completion stamp once; retries do not multiply a stat reward. Main progression never waits for these rewards.

| Side level | Parent | Initial beat budgets | Reused kit | Small additions and distinctive decision |
| --- | --- | --- | --- | --- |
| **A1-O1 Salvage Circuit** | L2 Crater Gardens | 0:45 route read + 1:30 part circuit + 0:45 final hatch approach = **3 min** | Lunar clearings, rock flats, capsule/hatch, rushers, impacts | Three recoverable capsule parts and damaged/repaired hatch states. Collect parts by contact in any order around a compact loop, then reach the hatch. Choose an order that leaves a useful return landing; no carrying button or assembly minigame. |
| **A1-O2 Spore Bloom** | L3 Mushroom Caverns | 1:00 first room + 1:30 paired mushrooms + 1:30 final mix = **4 min** | Fungi, stalks, shelves, trunk, full/spent clusters, repulsion field, swarmers and one guard | One distinct cluster arrangement or bloom pose. Limited supplies open different routes through familiar crowds. The spores remain repulsion, and baseline escape remains after they run out. |
| **A1-O3 Royal Rehearsal** | L4 Selenite Court | 1:30 first formation + 1:30 inward pair + 2:00 final arrangement = **5 min** | Court floor, panels, crescent columns, curtains, guards and formation poses | Practice bell and formation markers. Contact with the bell starts each arrangement; clearing it opens the next. Read three variations without a required flawless streak or speed timer. No King rematch or new enemy cast is necessary. |

A temporary dash-length pickup can make Salvage Circuit's broad approaches easier; an optional 360 swing can ease Spore Bloom's final crowd. Their duration, stacking and exact replacement-weapon variants remain unconfirmed. If testing a pickup, first verify the same side level with baseline actions and no pickup. Shared spore interactions belong to the parent grotto kit, so do not count them as a wholly new side-level system.

## Art coverage at the same scope as the other acts

The [expanded concept collection](concept-art/act1/README.md) should cover **characters, environments, bosses, mood, props and three gameplay views**, using existing references and revised concepts as inputs. Every new image remains an illustrative proposal rather than an archival still, production sprite or screenshot from implemented gameplay.

| Category | Required coverage | Carry forward and revise |
| --- | --- | --- |
| Characters | Friendly Earth cast and expedition; celestial dream performers; readable Rush/Swarm/Guard roles | Keep coats/hats/beards, early ceremonial embroidery and upright rib-patterned Selenites. Separate regular variants through pose, size and weapon. Celestial cast remains scenery. |
| Environments | Hall/workshop/loading roof; crater/camp; grotto; court; face-side return arena | Reuse the revised finless-shell, jagged-painted-rock, shallow-cap and curling-court vocabulary. Compose each around broad portrait floors and useful landing pockets. |
| Bosses | King silhouette, lunge/formation and finite helpers; Moon expressions and slash-range rim; alternative candidate comparison | Keep B01/B02 as the main bosses. Candidate figures provide research options, not compulsory encounters. Show warning, safe pocket and local recovery rather than only a giant portrait. |
| Mood | Friendly rehearsal and comic ambition; wonder and celestial rest; curious ecology becoming pursuit; ceremonial opposition; offended Moon and playful escape | Preserve theatre, pantomime and abrupt magical transformations. Use enclosure and arrangement for rising pressure; avoid importing Act 2's ruined-war palette or Act 3's flesh world. |
| Props and effects | Capsule/workshop/launch objects; stars/crescents/planet discs; reachable full/spent clusters; court/spear/roundel; square puff/cord/hatch states | Keep archival objects and invented functions labelled separately. Show spore repulsion as live enemies moving outward, and keep square effects sparse over readable floor. |
| Three gameplay illustrations | Crater Gardens committed rush and safe recovery landing; grotto cluster hit and crowd retreat; Moon circle/cone and reachable eye opening | Use the same portrait, close following camera and low-resolution 2.5D presentation. No joystick, ability hotbar, aim line originating from the player or ranged-only weak point. |

The older exploratory images remain retained as earlier passes. Their sealed visor, finned rocket, beetle enemy, tiled grotto, automatic spore vent and Gothic court should not silently become the new visual baseline. The revised object studies and original film frames supply closer inputs. Existing concepts are useful for staging and asset reuse even where a mechanic has since changed. [Visual corrections and source dates](reference-library/act1/STYLE_GUIDE.md)

## Small tests before full level production

The design hypotheses below require observation; completing a fight alone does not demonstrate that the input rule or spatial lesson was understood. Record input mistakes separately from wrong positioning, missed commitment timing and unreadable scenery.

| Bounded test | Hypothesis | Observe and revise |
| --- | --- | --- |
| Hall target and two workshop approaches | After one demonstration a new player can deliberately aim using the final swipe release | Test upper-left release/centre tap, zero-vector tap, different player positions and camera follow. If errors persist, clarify the cue; preserve the mapping. |
| Screen-edge positioning | A new player can restore a useful anchor through an ordinary dash | Try releases near each display edge. Ensure a safe reposition and a reachable tap direction exist; do not introduce hidden auto-aim. |
| One rusher and one impact | The player recognises lock before activation and lands near recovery | Compare simple escape with useful evasion. A warning must allow reaction plus remaining cooldown plus a normal dash. |
| Two mushrooms and about eight swarmers | The player hits a cluster deliberately and uses enemy retreat as breathing room | Observe early use versus saved supply, attack cancellation, broad retreat lanes, supply feedback and fade readability. Verify slash-then-blast consumes one cluster, not two. |
| Lone guard, pair, then King | The player recognises the same thrust grammar and chooses a useful formation gap | Complete slash-only; check guard removal simplifies the rest of that attempt, no helper replacement occurs and phase retry restores a coherent start. |
| Moon's three compact phases | Two separately taught shapes can be combined without new controls or invulnerability dependence | Verify local origin, warning, safe landing and eye rim in the existing camera. Complete with normal dash, baseline slash and no pickups. |
| Phone interruption and muted play | The whole encounter remains understandable and coherent after interruption | Background during windup, active spores and phase transition. Resume consumes the overlay tap, timers stay aligned and all tells read without audio. |
| Full first-clear timing | The five budgets measure genuine learning and travel | Include transitions and phase resets, then adjust encounter placement or shorten excess instruction. Do not add waves solely to reach 43 minutes. |

Produce the hall, rusher, spore room, King and Moon as short greyboxes before building five full scenery kits. The art and database establish coverage now; the prototype work should establish that each important decision is playable for someone encountering the game for the first time.
