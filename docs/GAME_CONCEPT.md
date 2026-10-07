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

### Act 1 — The Moon

The selected reference is Georges Méliès's [A Trip to the Moon (1902)](https://en.wikipedia.org/wiki/Le_Voyage_dans_la_Lune).

- Palette: moon-white, dusty silver, and black.
- Proposed scenery: painted stars, crater gardens, giant mushrooms, and theatrical lunar sets.
- Proposed movement identity: choosing where to land among circular hazards and scattered safe ground.
- Earlier boss candidate: the Selenite King.
- **Act 1 final boss: the Man in the Moon.** He closes this act; the campaign has a separate final encounter in Act 3.

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
