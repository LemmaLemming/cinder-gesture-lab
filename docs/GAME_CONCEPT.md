# Cinder: current game concept

## Confirmed direction

A pixelated 2.5D action game for iOS and Android, displayed vertically in portrait. A pixel sprite can move in any direction across the floor, like the spatial layout of Undertale or Pokémon. A fixed-angle overhead camera locks onto and follows the player. Closer camera zoom makes the person larger on screen without scaling the sprite. **A directional swipe causes a dash; swipes are the player's only voluntary movement. The entire game uses taps and swipes or combinations of them.**

Combat happens at close range. Swords and shotguns operate in a comparable danger zone. Explosions scatter square particles with convincing gravity, collisions, bounce, and weight.

The campaign has one carried weapon and no weapon-switching hotbar. Picking up another weapon replaces the current one. Baseline damage does not grow through progression. New bosses, encounter rules, and player mastery provide progress. Situational pickups can boost dash speed, boost dash length, or turn a swing into a 360-degree attack. Pickup duration and stacking remain design questions.

## Current prototype scope

One red-and-black mechanics arena with a pixel player, three enemy variants, obstacles, sword strikes, shotgun blasts, HP, two automatically reloading shells, and bounded physical square debris. Enemies stagger or launch when hit and drop a small collectible core. A tap resets the arena. The prototype has fixed slash/blast actions; weapon replacement, campaign powerups, and the acts below are planned content.

The first controller used a side-scrolling platforming interpretation. The implemented version now uses free X/Z movement across a floor and gesture-only dashes.

## Current gesture mapping

- Swipe at any angle: one dash in that direction, with fixed distance and a short cooldown. One subsequent swipe may be buffered during cooldown.
- Tap: an immediate sword strike in the direction from the final screen endpoint of the latest swipe to the tap. A swipe ending upper-left followed by a center tap strikes bottom-right, regardless of the player's world position. There is no target redirection.
- A second quick tap: chain a shotgun blast after the first strike.
- Tap Reset: restart the test.

The aim anchor updates on the final finger release, rather than when the drag first becomes a swipe. It stays in screen space until another swipe. Reset initializes it at screen center. A tap exactly on the anchor retains the last facing direction. The first tap slashes immediately; a nearby second tap within 280 ms fires the shotgun.

The user confirmed this attack mapping, swipe-only movement, the all-gesture control requirement, portrait layout, and closer camera zoom.

## Planned campaign

This is concept documentation, not implemented campaign content. The player should be able to play on a bus or while waiting for friends, replay earlier levels, and see clear progress toward finishing the game.

- Target level length: around 10 minutes, with shorter levels where appropriate.
- Target first campaign completion: roughly 2–3 hours.
- Working structure: three acts of approximately five levels each. Actual level count and clear times need playtesting.
- Proposed interruption handling: immediate pause when the app backgrounds, frequent encounter/boss-phase checkpoints, and a paused resume that the player continues with a tap.
- Proposed replay rewards: optional challenges and cosmetics. Replays do not grant permanent damage increases.

Each act draws on late-19th- or early-20th-century science fiction and has a distinct palette, setting, movement problem, and climax. The red-and-black prototype palette is not a requirement for every act.

**Optional-level asset rule**

Optional levels share most of their assets with the corresponding regular level, with a small set of additions. Reuse its terrain pieces, scenery, enemy sprites and animations, palette, and effects. Distinguish an optional level through a different arrangement, encounter pattern, or objective, plus a few new props or hazards. A complete new environment kit or enemy cast is not the default scope.

Optional levels are separately entered side levels; optional routes inside regular levels can use the same rule. Their challenges retain taps and swipes, one carried weapon, and fixed baseline damage. Required traversal works with the normal dash; situational powerups offer additional opportunities.

### Act 1 — The Moon

The selected reference is Georges Méliès's [A Trip to the Moon (1902)](https://en.wikipedia.org/wiki/Le_Voyage_dans_la_Lune).

- Palette: moon-white, dusty silver, and black.
- Art direction: handmade lunar theatre, using painted-looking rock flats, broad white streaks and black creases, human figures in stars and planetary discs, oversized fungi, and celestial court ornament. Keep the moon-white, dusty-silver and black palette as our game interpretation; surviving handcoloured film prints are separately documented.
- Character and prop vocabulary: Victorian expedition coats, hats, beards and umbrellas; embroidered ceremonial astronomer robes; a squat, finless bullet capsule; upright masked Selenites with rib bands, projecting headpieces and spears. The court uses curling panels, crescents, radial roundels and drapery.
- Proposed movement identity: choose a useful dash landing, preserve a retreat, then punish a visibly committed attack. Each level adds a different spatial problem using the same gestures.
- Proposed earlier boss: the Selenite King in level 4.
- **Act 1 final boss: the Man in the Moon.** He closes this act; the campaign has a separate final encounter in Act 3.

**Design follow-up — environment interactables**

The user wants to return to a broader set of environment interactables **after enemy design**, with each interaction based on an enemy behaviour it answers. Keep this as a future design topic; do not expand the interactable roster yet. The mushroom-spore interaction below is the first confirmed example. For each later proposal, identify the enemy pressure, the existing tap/swipe action that activates the prop, and the opening it creates.

**Enemy design — proposed Act 1 roster**

Start with three regular enemy roles and the two already planned bosses. Reuse the upright masked Selenite family, pale rib patterns and projecting headpieces from O49–O51; size, movement and attack poses distinguish the roles. These variants are new game designs, not three authenticated species from the film. The Earth's workers and astronomers remain friendly; the celestial dream figures remain scenery.

| Enemy | First appearance | Tell and behaviour | Player decision |
| --- | --- | --- | --- |
| Rush Selenite | Crater Gardens | Crouches, locks a visible short rush lane, commits, then takes a moment to recover. | Dash sideways after commitment; choose a landing near its stopped position and punish recovery. |
| Swarm Selenite | Mushroom Caverns | Small acrobatic bipeds approach in groups. The next attackers visibly crouch and raise their arms before short hopping strikes. | Preserve an escape landing, slash the nearest attackers, or release mushroom spores to open space in the crowd. |
| Spear Guard | Late Mushroom Caverns; developed further in the court | Raises its oversized spear and braces toward one short lane, then thrusts and recovers. | Approach around a stalk or its flank; choose between attacking the guard and dealing with nearby swarmers. |

Swarm pressure comes from bodies taking up useful approaches. A starting test can use about eight swarmers with only one or two preparing attacks at the same time. Their bodies should yield enough space for a normal dash; a surrounding crowd must not become an unavoidable collision cage. Every actual strike has a tell: simply brushing against a swarmer does not cause repeated contact damage. Swarmers can be fragile enough to fall to one ordinary slash as an initial tuning proposal, with several catchable in a well-aimed swing. This creates a crowd-clearing rhythm with fixed player damage.

The blast remains an optional way to exploit a cluster or launch a larger threat. Every regular encounter and boss opening remains viable with ordinary slashes. Introduce each role alone before combinations: rush plus spear, swarm plus mushroom, then swarm plus one spear guard. Court formations reuse spear guards rather than adding a fourth support enemy. Enemy counts, attack concurrency, health and timings need testing; do not lock these proposals as final balance.

**Confirmed mushroom interaction — falling spores repel enemies**

The user wants a swarm in the mushroom map and spores **on the mushrooms that the player can hit**. Hitting them makes spores fall around the mushroom, **temporarily repelling enemies**. This replaces the earlier automatic damaging spore-vent proposal for the main grotto. It uses ordinary attack gestures and creates space through enemy movement.

Proposed detailed rules:

1. Put a clearly visible hanging spore cluster on the mushroom, low enough for an ordinary slash. A tall unreachable cap cannot be the required target; no jump, ranged-only shot or new interaction button is introduced.
2. A normal hit releases square spores from the cap above. Their falling motion conveys the effect while a restrained floor boundary shows its useful area. The player remains unharmed by this friendly effect.
3. Affected regular enemies cancel their current attack, visibly recoil, turn and retreat beyond that boundary. They remain alive and avoid the active spore area; they are repelled, not merely stunned. Rushers and spear guards also respect the field when used in a mixed encounter.
4. Use the resulting opening to dash through, change sides, isolate an enemy or reach another mushroom. Enemies regroup outside the boundary. As the spores thin, they can approach again, using their normal readable attack tells.
5. Starting tuning proposal: two visible clusters per mushroom, each consumed by one hit; roughly three seconds of repulsion, with a visibly thinning final half-second. Try a radius of about three-quarters of the normal dash distance. Do not replenish clusters during that encounter in the first test. These quantities, duration and replenishment rules are proposals, not user-confirmed requirements.
6. A spent cluster leaves a visible empty patch. One strike consumes one cluster per mushroom; while its release/field is active, extra hits do not consume the remaining cluster or refresh the effect. This prevents an ordinary slash-then-blast combination from accidentally spending both charges. Reset its supply on an encounter retry. The field footprint is predictable; random decorative particles do not decide which enemy is repelled.

The repeated decision is **see the crowd approach → dash to a useful mushroom position → aim a slash at its cluster → spores fall and the crowd retreats → spend that opening on movement or an attack**. Limited clusters make early use compete with saving an escape opportunity. All required fights remain completable without a 360-swing pickup, a dash boost or a particular carried weapon.

First test: one broad room, two mushrooms and about eight swarmers, using fixed stats, normal dash and slash only. After one small demonstration, observe whether players deliberately create and use the opening. Check that the cluster is reachable under pressure, retreating bodies leave a usable lane, and the fading spores do not hide the next attack tell. Compare immediate spore use with saving it for a tighter crowd. This is a proposed test, not implemented gameplay.

**Revised regular-level sequence — working design**

Build a journey through five theatrical places, each with a different decision. The catalogue supplies visual references and concept studies; gameplay props, animations, collisions and encounters still need production. All hazards and boss rules below are proposed game adaptations, not claims about the film.

| Level | Spatial structure | Decision that makes it different | First-clear target |
| --- | --- | --- | --- |
| 1. Observatory and Launch — The Launch Rehearsal | A procession through hall, workshop and broad loading roof | Where should I land so my next attack has a clear direction? | 6 minutes |
| 2. Crater Gardens — The Celestial Camp | Connected lunar clearings with two approaches that rejoin at camp | Can I make danger commit to one place and land somewhere useful? | 8 minutes |
| 3. Mushroom Caverns — The Breathing Grotto | Broad fungal chambers with a closing swarm and hittable mushroom spores | When should I release spores to create room, and how should I use that opening? | 9 minutes |
| 4. Selenite Court — The King's Formation | Linked open courts ending at a side-mounted throne | Which formation gap gives me the best target? | 10 minutes |
| 5. The Living Moon — Departure Refused | A short return to the capsule, then a compact face-side arena | Can I evade the Moon's committed attack and return to its eye in time? | 10 minutes |

These provisional targets total **43 minutes**, within the proposed 40–45-minute act. They are pacing targets, not timers or a reason to add repeated waves. Optional levels sit outside that total. Shorten the opening if players learn its gestures quickly.

#### 1. Observatory and Launch — The Launch Rehearsal

**Look and layout:** a lively Earth-side stage set. The blackboard, astronomical instrument and robed professors frame an open lecture floor; the capsule workshop leads onto a broad loading roof with painted chimneys, telescope and giant cannon. Roof edges and stairs are scenery around continuous navigable ground.

**Encounter sequence:**

1. **Demonstration hall:** introduce any-angle dashes around widely separated furniture. One clearly marked practice target teaches slash aiming after a swipe. Its demonstration uses the actual rule: release upper-left, tap nearer the centre, strike down-right. The target and teaching animation are new game additions.
2. **Capsule workshop:** benches and an anvil create two generous approaches to the same practice target. Try landing on a different side and aiming diagonally. Introduce the quick second tap as one blast following the first slash. The target remains beatable with slashes; the blast's immediate feedback shows its optional follow-up role.
3. **Loading roof:** a proposed slow loading arm marks a short floor lane before swinging across it. First observe it in an empty space; then use a safe side approach to reach a target. The arm does not knock the player onto a lethal rooftop edge.
4. **All aboard:** combine a practice target and the familiar loading-arm warning beside the cannon. Clearing the rehearsal opens a broad capsule approach; reaching the open hatch by contact starts the launch. Workers, professors and attendants remain friendly scenery rather than an invented Earth enemy faction.

**Film kit:** O01–O08 observatory scenery and dress; O09–O20 capsule/workshop/expedition props; O21–O31 roof, cannon and crew. Keep the capsule to one side of the combat floor so it does not hide targets.

**New production additions:** one reusable practice target, one loading-arm mechanism and its windup, active and recovery states. This is a tutorial finale, not a compulsory new boss.

**Break points:** save at the hall exit, after the workshop and before the final rehearsal. Repeat play can omit teaching pauses; completing exercises automatically advances them.

#### 2. Crater Gardens — The Celestial Camp

**Look and layout:** the tilted capsule opens onto painted lunar clearings. Jagged side flats frame two broad routes that rejoin at the sleeping expedition. The Earth globe, crescent woman, human-faced stars and Saturn figure form the camp's celestial tableau. They are landmarks and scenery, not five additional bosses.

**Encounter sequence:**

1. **Landing clearing:** one impact warning appears on the floor before a bright square puff strikes it. A neighbouring safe landing is visible at the same time. Ordinary painted crater rings remain harmless; active warnings have an unmistakable animated outline and fill.
2. **First Selenite:** an upright creature visibly aims a short rush at the player's current position. Its floor line stops tracking before it moves. Dash aside after that commitment, then strike during recovery. Reuse the researched biped costume and headpiece.
3. **Two approaches:** the left route offers more rock cover and the right more open landing space. Both teach the same required lesson with one impact warning and one familiar Selenite. Choose either route; they rejoin without a long return through cleared rooms.
4. **Celestial camp:** the sleeping travellers mark a checkpoint. A final clearing uses two staggered impacts with safe space between them. The player chooses a useful landing that also leaves room to face a recovering Selenite. Defeat that final Selenite to stop the impacts and open the grotto passage; crossing the passage by contact ends the level.

**Film kit:** O34–O36 lunar rocks, crater-pattern scenery and landed capsule; O37–O42 dream tableau; O49–O50 Selenite body/headpiece; O58 white-puff reference.

**New production additions:** the animated impact warning and a Selenite rush/recovery sequence. An enemy's landing warning reads a world-space location; it is separate from the screen-space swipe endpoint used to aim the player's taps.

**Break points:** save after the first Selenite, at the route reunion and at camp. The camp is quiet until the player crosses the next broad encounter threshold.

#### 3. Mushroom Caverns — The Breathing Grotto

**Look and layout:** oversized shallow-capped mushrooms, porous fungi, rock shelves and a fallen trunk create irregular scenic chambers. Large stalks split the floor into two useful approaches. Reachable spore clusters make selected mushrooms temporary sources of breathing room against the swarm. The trunk sits beside a generous ground-level passage; shelving suggests depth without mandatory climbing or precision crossings.

**Encounter sequence:**

1. **Umbrella grove:** introduce a small group of swarm Selenites with clear gaps between them. Their short hopping strikes teach crowd spacing and well-aimed swings. Only clearly grounded stalks block movement and attacks; decorative caps and ceiling scenery do not.
2. **Breathing chamber:** show the reachable spore cluster in a calm approach, then let a small pack come into view. Strike the cluster to release falling spores; the approaching enemies visibly retreat. Use the space to change sides or attack an isolated swarmer. Let the cloud fade so the player sees the crowd regroup before the next threat.
3. **Crossed grotto:** two mushrooms offer different ways through a larger swarm. Spend a cluster early to open an approach, or wait until more enemies are nearby to create a bigger positional advantage. Each mushroom has a visibly limited supply in the first test. Keep the resulting lane broad enough for a normal dash, and keep a baseline escape route when spores run out.
4. **Court approach:** introduce one spear guard's windup, thrust and recovery without a crowd first. Then combine that guard with a small swarm around a mushroom. Falling spores repel both types; choose whether the opening is better spent passing the guard or attacking its recovery. Defeat the final guard and swarm to open the curtained passage; crossing it by contact ends the level.

**Film kit:** O43–O48 mushroom caps, clusters, porous forms, trunk and rock shelves; O49–O51 Selenite and spear; O56 curtain arch at the exit.

**New production additions:** the small swarmer's movement/strike/retreat poses, reachable full/spent spore clusters, falling-spore repulsion feedback and the spear windup/recovery poses. The existing grotto concept image remains a scenery reference; its earlier vent depiction needs a future art revision to show this interaction. Keep foreground fungi outside the combat sightline or fade them when they would obscure the player, cluster or warning.

**Break points:** save after the first swarm, after the spore demonstration and before the final mixed encounter. Cleared rooms remain safe; no unannounced respawns behind the player.

#### 4. Selenite Court — The King's Formation

**Look and layout:** three broad linked courts, with curling scenic panels, crescent columns, radial roundels and drapery around the edges. The throne sits to one side of the final chamber. The player enters through a curtain and sees an open performance space rather than a long narrow aisle.

**Encounter sequence:**

1. **Curtain entrance:** one familiar spear guard refreshes the grotto lesson on an open floor. Its silhouette and windup remain readable without a mushroom for cover.
2. **Formation court:** two guards wind up in parallel lanes, leaving a generous gap. Choose a landing beside the guard with the earlier recovery. A second arrangement turns the same pair inward; change the approach instead of learning a new enemy faction.
3. **Royal approach:** a low radial roundel briefly brightens before producing the familiar circular impact warning from Crater Gardens. Show one quiet cycle at the entrance, then combine it with a guard pair. The player can attack a guard first to simplify the space or preserve a direct route toward the next opening. Keep the roundel, participating enemies and safe alternatives in the local camera view. This animated roundel is a game use of the film ornament, not an observed film effect.
4. **The Selenite King:** first he steps away from the throne, marks a short lunge, commits and recovers. Dash aside and approach him at ordinary slash range. In the next pattern he calls one guard pair into a visible formation, lets their thrusts commit, then telegraphs his own lunge into the remaining space. Every attack has its own readable commitment; their timing leaves a reachable safe landing. Attack a guard to open more space or punish the King's recovery.

The King alternates his two learned patterns. One guard pair enters visibly at the pattern transition; defeated guards stay defeated for the remainder of that boss attempt. Clearing them makes subsequent exchanges simpler: the King proceeds directly to his already introduced lunge instead of summoning replacements. Choose whether to spend an opening removing a guard or damaging the King. A slash makes meaningful progress in each opening; a second-tap blast can exploit it further without being required. Difficulty comes from arrangement and timing, rather than padding the fight with additional health or repeating an unlimited guard wave.

**Film kit:** O49–O57 Selenites, spears, royal figure, seat and celestial court decoration; O58 puff effect vocabulary. The King is an adaptation of the seated royal figure, not a new historical creature claim.

**New production additions:** the King's lunge/recovery poses, coordinated guard formation animations and a brief brightening state for the roundel. Floor lane warnings and the roundel's impact reuse the existing systems.

**Break points:** save before the royal approach, at the boss entrance and after its major pattern transition. Defeating the King opens the curtain back onto the lunar exterior.

#### 5. The Living Moon — Departure Refused

**Look and layout:** return to the capsule through familiar rock flats and crater ground, now composed to suggest facial creases. The final combat floor is a broad clearing along the Moon's lower face. A local eye, cheek and nose suggest the enormous human face; the full face can extend beyond the view, but no attack needs the player to see the entire boss. The escape ledge is a scenic boundary around a safe capsule approach.

**Encounter sequence:**

1. **Wrinkled return route:** one isolated impact rehearses safe landing. A short encounter adds a familiar Selenite rush. This is a compact return with new staging, not a long walk through the previous levels.
2. **Capsule checkpoint:** the hatch is visibly blocked by the Moon's presence. Preview the nearby eye and the floor beneath it before combat begins. Keep the established camera angle, zoom and player follow.
3. **The Man in the Moon:** teach two attacks separately. **Blink** marks a circular patch at the player's current world position, stops tracking, then strikes it. **Sneeze** raises the nearby nose and marks a short cone; its direction locks before release. Dash toward a visible safe area before either warning activates. During recovery, the injured eye leans down into the clearing and exposes its outlined rim at ordinary slash distance. Land usefully, approach the rim, aim a tap, then decide whether to add the blast.
4. **Final expression:** alternate the learned attacks, then combine one impact patch with the familiar cone. Offset their commitments so a safe normal-dash landing always remains visible. After the exchange the same eye rim becomes reachable; finish the fight with the established close-range actions.

Keep a single compact battlefield throughout the fight. Do not send the player across an enormous face between hits, turn an eye into a ranged target, hide a danger source off-screen or require dashing through an already active damaging zone. The next strike and the safe landing matter more than the overall scale of the face. The prototype's brief dash invulnerability is not required to solve these layouts.

**Film kit:** O32–O35 Moon face, cloud border and lunar scenery; O09/O10/O36 capsule and hatch; O37/O39–O41 celestial backdrop; O59–O61 escape ledge, cord and capsule-clinging Selenite pose.

**New production additions:** a few Moon expressions, eye-rim contact/recovery poses, blocked/open hatch states and the two boss windups. Face motion, hostility and weak-point rules are game inventions. The Moon's final flinch opens the hatch; reaching it by contact triggers a short escape tableau using the same capsule, cord and Selenite assets. This closes Act 1 and unlocks Act 2, not the campaign ending.

**Break points:** save at the return clearing, before the boss and after each completed boss phase. The final phase combines known rules; it does not add another surprise attack.

**Shared layout and mobile-session rules**

- Let **D** mean the ordinary unobstructed dash distance; the current prototype has D = 2.7 world units. Start greyboxing with combat clearings roughly two dash lengths across and required openings about one dash length wide. These are provisional starting dimensions, not strict measurements for every room; verify ground projection and sprite scale in the actual portrait camera.
- Use continuous broad floors, tolerant encounter thresholds and generous landing pockets. Required paths work with normal dashes and baseline attacks. Reaching the capsule, collecting a part or crossing a cleared exit triggers the relevant action by contact; all combat taps retain their slash/blast meaning.
- A warning, its attack origin and at least one reachable safe landing must be visible together. Its delay must allow reaction, any remaining dash cooldown and a normal escape dash. Distinguish warning, active and recovery states by shape and animation as well as brightness; never rely on sound or colour alone.
- Place attacking bodies and weak points within local close-range reach. Preserve the exact swipe-end-relative aim rule. An anchor at a screen boundary cannot aim outward; the player's remedy is another ordinary positioning swipe ending at a useful point on the display. Provide safe space for that dash and recovery windows long enough to reposition and slash. Test releases near every screen edge; do not rely on an impossible off-screen tap, an aim-only movement gesture, auto-aim or a silent change of aiming origin.
- Save after completed encounters and before difficult finales; boss phase checkpoints prevent replaying the whole ten-minute level. Proposed resume behaviour freezes enemies, warnings and pickup timers when backgrounded, then waits for a tap to resume before combat inputs are accepted. A resume tap is consumed as a menu action, not an accidental slash.
- Fixed stats are sufficient throughout. Replay improvements should come from recognising a tell, choosing a safer landing or exploiting an earlier opening. Level access, checkpoint access and optional challenges supply persistent progression; no mandatory farming or permanent damage rewards.
- Temporary dash-speed, dash-length and 360-swing pickups are optional experiments. Offer length boosts in broad crater spaces and 360 swings in crowd encounters; never place a required route behind either pickup. Initial powerup tests can use one encounter of duration. Duration, stacking and the exact weapon-replacement variants remain unconfirmed tuning choices.

**First design tests, before full level production**

Test the hall's direction exercise, one Selenite rush, one mushroom/swarm repulsion room, the King's formation/lunge and the Moon's warning/eye opening as short greyboxes. With fixed stats and the normal dash, a new player should identify a useful landing after one demonstration, deliberately use a spore opening and recognize where a slash can punish recovery. Observe aiming mistakes separately from missed warning timing. Try slash-only completion, screen-edge swipe releases and a pause/resume during a warning or active spore field. If safe landings or the boss opening require a wider camera, revise the encounter layout. These are proposed tests; campaign content has not been implemented or playtested.

**Optional-level examples — proposals**

| Regular level | Optional level | Reused assets | Small additions and play difference |
| --- | --- | --- | --- |
| Crater Gardens | Salvage Circuit | Lunar clearings, jagged scenic rocks, capsule/hatch model, impact warnings and the rush Selenite | Add recoverable capsule parts and a damaged hatch state. Collect three parts by contact in any order around a compact loop, then reach the repaired hatch to finish. Each clearing rearranges familiar threats. A dash-length pickup can ease the broad approaches but is unnecessary. |
| Mushroom Caverns | Spore Bloom | Stalks, caps, porous fungi, ground passages, shelves, swarmers, a spear guard, and the regular level's hittable clusters/repulsion effect | Rearrange the same mushrooms into a compact sequence where limited spore supplies open different crowd routes. Add a distinct cluster arrangement or bloom animation; an optional 360-swing pickup can ease the final crowd. Defeat the final mixed group to open the contact exit. Keep baseline completion viable. |
| Selenite Court | Royal Rehearsal | Court floors, curling panels, crescent columns, curtains, guards and their formation animations | Add only a practice bell and formation markers. Contact with the bell starts a short arrangement; clearing it opens the next. Clear three arrangements to finish. No flawless speed run is required. |

These are separately selected side levels unlocked after clearing their parent level. They need approximately 3–5 minutes each as a provisional first pass, with one checkpoint before the final exercise. Their rewards can be a film-themed cosmetic or challenge-completion stamp; none grants permanent damage. Shared main-level mechanics such as the spore vent are already in the parent kit, so do not count them as an entirely new optional-area environment.

The [film reference library](reference-library/act1/README.md) contains the researched scenery and object catalogue, an offline searchable gallery, and six revised concept studies. Its [style guide](reference-library/act1/STYLE_GUIDE.md) connects the visual rules to film frames and museum records. The [earlier concept art](concept-art/act1/README.md) remains as a superseded exploratory pass. New art and all encounter rules are game proposals, not original film material or implemented levels.

### Act 2 — The Invasion

The working reference is H. G. Wells's [The War of the Worlds (1898)](https://etc.usf.edu/lit2go/135/the-war-of-the-worlds/2462/book-onethe-coming-of-the-martians-chapter-5-the-heat-ray/). This act remains a proposal.

- Palette: rust-red and black, with pale attack warnings.
- Proposed scenery: ruined streets, towering tripods, invasive red weed, and encroaching smoke.
- Proposed movement identity: crossing dangerous space between sweeping beams and approaching footsteps.
- Boss candidate: a Martian Tripod that locks its ray onto the player's last dash endpoint. Bait its aim, evade after it commits, then strike an exposed leg joint at close range.

### Act 3 — Tormance: The False World

The selected reference is David Lindsay's **A Voyage to Arcturus (1920)**. The [Science Fiction Encyclopedia entry](https://sf-encyclopedia.com/entry/lindsay_david) describes its voyage to Tormance, changing beings, and unsettling relationship between the physical world and its underlying reality. The [original novel](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html) supplies two suns, Branchspell and Alppain, the unfamiliar colours ulfire and jale, and white daylight shadows cast by Alppain.

The following is our game adaptation, rather than a literal retelling of the novel. The landscape feels alive and increasingly deceptive. Player progress comes from learning its visible rules.

**Visual identity**

- Black, unnatural violet, and sulphur-green, with unusual pixel patterns suggesting unfamiliar colour. These are proposed visual equivalents, not literal depictions of Lindsay's invented colours.
- Fleshy forests, glassy seas, floating islands, and two enormous suns.
- Beautiful scenery gradually reveals watching eyes and human-like shapes.
- White shadows provide a distinctive motif, while gameplay warnings stay readable through visual changes.

**Central movement rule**

Alternating sunlight reveals different terrain and attack openings. The next arrangement appears as outlined shapes before it changes, allowing the player to plan a dash. Gestures retain their established meanings as the world changes.

Temporary sensory organs could represent powerups: extra limbs produce a 360-degree swing; an additional eye reveals openings earlier. These are proposed effects and visuals, with no permanent damage growth.

**Working five-level sequence**

1. Twin Suns — introduce the changing light and terrain.
2. Living Forest — extend the rule into an environment that appears alive.
3. Mirror Sea — explore reflections and deceptive appearances.
4. False Paradise — combine familiar rules in apparently welcoming scenery.
5. Crystalman — the act's climax and the campaign's final encounter.

**Final boss concept: Crystalman**

The entire arena acts as his body: a beautiful, deceptive landscape animated by a luminous presence. This is our gameplay interpretation of Lindsay's figure.

- After the player performs a dash-and-attack combination, Crystalman creates an apparition that repeats it.
- The apparition's route and strikes are visibly previewed. The player evades the repeated actions, then attacks an exposed tether connecting Crystalman to the landscape.
- Tethers are reachable with the game's close-range attacks. The fight uses the existing taps and swipes and the player's current weapon.
- Each severed tether strips away part of the beautiful scenery, revealing the void beneath.
- Winning opens an escape through the false world. The ending represents escape from this encounter, rather than claiming a definitive defeat of Crystalman in Lindsay's original story.

The final sense of progression is understanding the world's rules well enough to escape with the same gesture vocabulary and fixed baseline damage.

## Development choice

Godot 4.7.2 standard stable with GDScript, downloaded from the official vendor source. The SHA-512 checksum matched and macOS accepted its notarized signature. The engine is kept in `.tools/Godot.app`.

The prototype uses a low-resolution 3D viewport, billboard pixel sprites, a player-following orthographic camera with a fixed angle and 7.2-unit width, and Godot's Compatibility renderer. The portrait reference resolution is 540 × 1170. Square rigid-body debris is capped and automatically retired. Godot is being operated in a dedicated full-screen macOS Space.

iOS and Android touch event handling is implemented. App packages, signing, and physical-device testing remain future work.
