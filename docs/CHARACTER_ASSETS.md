# Shared helmeted character assets

**8 October 2026 — implemented Character Lab artwork.** The shared player now wears a permanent round astronaut helmet with a dark visor, stepped pale rim, neck seal and glint. The 48 × 64 body adds padded panels, chest controls, reinforced gloves, knees and boots. It replaces the earlier hat/beard artwork under the user's direction and [equipment appearance rules](PLAYER_EQUIPMENT_GUIDELINES.md#permanent-helmet-and-compatible-equipment-appearance).

The original [generated astronaut turnaround](../assets/references/astronaut-turnaround-v1.png) is a visual model, created with the built-in image generation tool using the supplied astronaut as a silhouette/detail reference. Its [reference manifest](../assets/references/manifest.json) saves the exact final prompt and provenance. The 1536 × 1024 RGBA concept has soft alpha and unaligned pixels; it is not a runtime atlas. Aligned pixel clusters and poses are separately authored in [pixel_sprite.gd](../scripts/pixel_sprite.gd). Neither reference image is cropped into runtime textures.

The reusable [player scene](../scenes/player.tscn) contains the shared controller, named capsule, billboard sprite and contact shadow; its sprite script runs in the editor. `CinderPlayer.new()` retains fallback node creation. Acts can reuse it with carried equipment IDs.

| Field | Asset contract |
| --- | --- |
| Stable family | `shared_astronomer_player`; retained when appearance changed |
| Source and machine record | [authoring code](../scripts/pixel_sprite.gd), [runtime manifest](../assets/characters/manifest.json) |
| Readiness | Implemented lab pixel asset; campaign scenery integration and physical-phone review remain outstanding |
| Native grid | 48 × 64 transparent RGBA cells; 32 columns × six rows, 1536 × 384 pixels per sheet |
| World size | `pixel_size = 0.0225`; unchanged 1.08 × 1.44 full quad |
| Foot pivot | Bottom centre (24, 64); offset (0, 32), origin 0.025 world units above floor |
| Collision | Unchanged capsule radius 0.32, height 1.45, centre Y 0.73; apparel and weapons do not enlarge it |
| Palette | Moon-white, cool silver, charcoal outline, subdued navy visor, sparse muted red trim |
| Role / occlusion | Player actor, ordinary world depth, separate floor shadow; weapon pixels are cosmetic |
| Reuse | Shared actor for lab exercises and future three acts |

Gameplay renders through a nearest-filtered 270 × 585 viewport inside the 540 × 1170 portrait presentation, preserving the 7.2-unit camera width and world footprint. This deliberate increase in player detail follows the user's new direction. Legacy arena enemies retain their coarse prototype art pending enemy production.

Each facing owns eight atlas columns, ordered **front, back, left, right**. Artwork facings depict continuous movement/aim and do not quantize physics. Rows are **idle, dash, landing, primary, blast, hurt**; six-frame states leave their final two cells transparent.

| State | Frames per facing | Cosmetic timing |
| --- | ---: | --- |
| Idle | 8 | Quiet 1.2-second breathing loop |
| Dash | 6 | Resolved distance / speed; neutral 0.18 s |
| Landing | 6 | 0.22 s |
| Primary | 8 | 0.28 / resolved attack speed |
| Blast | 8 | 0.24 / resolved attack speed |
| Hurt | 6 | 0.28 s |

Damage remains immediate. Logical phases remain 0.13 / attack speed for primary, 0.10 / attack speed for blast and 0.16 s for hurt. Longer cosmetic settling never extends commitment, weapon replacement, invulnerability, cooldown or travel; accepted input interrupts it immediately. The controller supplies action progress and advances idle with simulation delta, so pause freezes both.

One carried weapon profile governs blade and compact short-barrel blast. Stable asset names and equipment IDs stay unchanged:

| Asset / profile | Sheet | Visual difference |
| --- | --- | --- |
| PLAYER-ASTRONOMER-W01 / WEAPON-01 | [Balanced Edge](../assets/characters/astronomer-weapon-01.png) | Reference blade / blast housing |
| PLAYER-ASTRONOMER-W02 / WEAPON-02 | [Quick Edge](../assets/characters/astronomer-weapon-02.png) | Shorter narrow blade |
| PLAYER-ASTRONOMER-W03 / WEAPON-03 | [Heavy Edge](../assets/characters/astronomer-weapon-03.png) | Broader compact blade |
| PLAYER-ASTRONOMER-W04 / WEAPON-04 | [Long Edge](../assets/characters/astronomer-weapon-04.png) | Longer narrow blade |

Runtime `set_loadout_visual(weapon, jacket, pants, shoes)` builds clothing on this shared helmeted body. Jackets vary panel value/trim, pants vary seams/pockets, shoes vary cuffs/sole. Helmet, neck, separated legs, feet and collider remain shared. No helmet slot or new gameplay ability was introduced.

`get_muzzle_pixel_position()` uses the same hand position and barrel angle as the current blast pose. `get_muzzle_world_position(camera)` maps that texel centre through the billboard's camera basis and foot pivot. The [shotgun flare](../scripts/shotgun_flare.gd) therefore releases at the visible barrel tip for all facings and profiles, while its outward fan follows the exact accepted aim. Its initial recoil attachment never changes the immediate hit origin or range.

Regenerate native PNGs with:

```sh
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /private/tmp/cinder-character-export.log --script scripts/art/build_character_assets.gd
```

The [nearest-filtered atlas preview](character-atlas-preview.png) is for review. The exporter covers all 168 supported state/facing/frame combinations per profile. Representative outfit/facing reviews and compatibility fields are recorded in the runtime manifest. See [Character Lab validation](CHARACTER_LAB.md#validation-and-limits) for integrated gameplay and portrait motion checks; these records do not establish mobile performance or campaign readiness.
