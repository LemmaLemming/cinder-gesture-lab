# Cinder: current game concept

## Confirmed direction

A red-and-black pixelated 2.5D action game for iOS and Android. A pixel sprite can move in any direction across the floor, like the spatial layout of Undertale or Pokémon. A locked overhead camera shows the arena. **A directional swipe causes a dash; swipes are the player's only voluntary movement. The entire game uses taps and swipes.**

Combat happens at close range. Swords and shotguns operate in a comparable danger zone. Explosions scatter square particles with convincing gravity, collisions, bounce, and weight.

## Current prototype scope

One mechanics arena with a pixel player, three enemy variants, obstacles, sword strikes, shotgun blasts, HP, two automatically reloading shells, and bounded physical square debris. Enemies stagger or launch when hit and drop a small collectible core. A tap resets the arena. There is no campaign or larger loot progression yet.

The first controller used a side-scrolling platforming interpretation. The implemented version now uses free X/Z movement across a floor and gesture-only dashes.

## Current gesture mapping

- Swipe at any angle: one dash in that direction, with fixed distance and a short cooldown. One subsequent swipe may be buffered during cooldown.
- Tap toward a target: an immediate sword strike.
- A second quick tap: chain a shotgun blast after the first strike.
- Tap Reset: restart the test.

The user confirmed this attack mapping, swipe-only movement, and the all-gesture control requirement.

## Development choice

Godot 4.7.2 standard stable with GDScript, downloaded from the official vendor source. The SHA-512 checksum matched and macOS accepted its notarized signature. The engine is kept in `.tools/Godot.app`.

The prototype uses a low-resolution 3D viewport, billboard pixel sprites, a fixed orthographic camera, and Godot's Compatibility renderer. Square rigid-body debris is capped and automatically retired. Godot is being operated in a dedicated full-screen macOS Space.

iOS and Android touch event handling is implemented. App packages, signing, and physical-device testing remain future work.
