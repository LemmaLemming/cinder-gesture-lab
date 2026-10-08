# Cinder — shared visual, motion and interaction guidelines

**Review date: 8 October 2026.** This guide brings together the full three-act concept, equipment specification, current Godot prototype and art review. It gives future agents a consistent implementation default. The [Character Lab](CHARACTER_LAB.md) now implements a shared helmeted player, static equipment visuals, target/pickup cues and bounded arena threat feedback. Campaign scenery, authored enemy animation and the wider interaction cues still need production and playtesting.

## Authority and scope

The [game concept](GAME_CONCEPT.md) owns confirmed presentation and gestures. The [equipment specification](PLAYER_EQUIPMENT_GUIDELINES.md) owns player/item behaviour; its [JSON data](../data/design/player_equipment.json) owns proposed numerical values. The [Act 1](ACT1_CONCEPT.md), [Act 2](ACT2_CONCEPT.md) and [Act 3](ACT3_CONCEPT.md) plans own encounters and source/adaptation boundaries. This guide owns shared visual language and motion defaults. The [asset reuse guide](ASSET_REUSE_GUIDE.md) identifies what already exists and what needs building.

**Must** preserves a confirmed constraint or an implementation contract adopted in this guide. **Default** is a new art/motion recommendation that may be revised with documented visual or playtest evidence. **Observed** describes code or imagery as reviewed, not proof that it satisfies the intended campaign. User instructions take precedence. Resolve disagreements explicitly; a generated illustration must not override the written mechanics.

## One game across three different worlds

The common identity is a readable pixel traveller in a close portrait view, moving across a continuous floor through deliberate dashes. Protagonist headwear follows each act's selected concept art and has no equipment slot or bonuses. Strong silhouettes, shared action/facing language, restrained square effects and visibly committed threats carry the action. Worn equipment remains compatible with every selected act presentation, including mixed-act loadouts.

| Element | Shared contract | Permitted act variation |
| --- | --- | --- |
| Camera and space | Portrait, fixed-angle overhead orthographic camera following the player; free X/Z ground movement | Local scenery composition and boss poses; large forms can extend beyond the view while their relevant parts remain visible |
| Player | One controller, base stats, equipment system, collision body, feet pivot and readable action/facing language | Headwear and presentation derived from selected act concept art, without a slot or bonus; compatible jacket, pants, shoes and weapon appearances; retain the carried loadout across act transitions |
| Pixel treatment | Crisp edges, deliberate clusters, a common apparent pixel scale and clear feet-to-floor contact | Act-specific materials, controlled dithering and decorative patterns |
| Motion | Immediate gesture response, predictable dash landing, readable commitment and recovery | Acrobatic Selenites, articulated machines, organic tightening and finite apparitions |
| Interaction language | The same cues mean available, locked, active, vulnerable and spent everywhere | Different physical objects and palette accents expressing those states |
| Effects | One continuous dash plume, pale slash arc, bright barrel-origin shotgun flare and tiny impact flecks; warnings stay readable | Act-specific smoke/material colours while preserving release direction and cue meaning |

| Act | Palette and material vocabulary | Keep distinct |
| --- | --- | --- |
| Moon | Moon-white, dusty silver and black; painted rock flats, shallow mushroom caps, period costumes, crescents and curling court panels | Stage scenery, human celestial tableaux and upright masked Selenites; avoid reviving the old finned rocket, beetles or Gothic dungeon |
| Invasion | Rust-red and black with pale warnings; ruined masonry, industrial joints, canisters and red weed | Three-legged fighting-machines versus five-legged handling-machines; cinematic scale must leave a local readable combat apron |
| False World | Black, unnatural violet and sulphur-green; white shadows, organic forms, reflective layers and stripped beauty | White shadows and reflections are decorative; real threat sources, stable floor and external tethers stay unambiguous |

Do not apply the lab's neutral test palette or the earlier red/black prototype palette to the whole campaign. Reuse rendering, state logic and cue geometry across acts; preserve the different source vocabulary. Violet/green are game interpretations, not literal reproductions of the novel's invented colours.

**Confirmed player appearance:** the latest user decision removes the permanent helmet rule. Select protagonist headwear from each act's chosen concept art, then author compatible carried clothing and weapon layers around that presentation. Keep the shared collision, feet pivot and readable action/facing language. Headwear introduces no equipment slot or bonuses. Follow `REQ-08`, `REQ-09` and `LOOK-01`–`LOOK-05` in the [equipment guidelines](PLAYER_EQUIPMENT_GUIDELINES.md#act-presentation-and-compatible-equipment-appearance). Existing helmeted lab assets and their reviews remain truthful prototype history; selected act variants still require production and portrait review.

## Pixel scale, camera and scenery

**Observed lab setup:** [project.godot](../project.godot) uses 540 × 1170 portrait presentation. [game.gd](../scripts/game.gd) creates a 270 × 585 initial 3D subviewport, a nearest-filtered container with shrink factor 2, and an orthographic width of 7.2 world units. [pixel_sprite.gd](../scripts/pixel_sprite.gd) generates 48 × 64 player cells at `pixel_size = 0.0225`, retaining the previous 1.08 × 1.44 world quad and fixed collision body. The user's astronaut reference prompted this deliberate increase in player detail; legacy arena enemies retain their coarser prototype art pending their own production pass. These are lab settings, not measured mobile performance targets.

**Confirmed camera direction:** follow translation eases with `1 - exp(-delta / 0.16 s)`. The camera moves faster when farther from its target and slows as it settles, without overshoot. Angle and width stay fixed; a separate unshaken focus prevents feedback shake accumulating into drift. Lab reset snaps the focus. Camera translation never changes the stored final screen-space swipe-release anchor.

- Must keep crisp nearest-filtered gameplay and a consistent apparent pixel scale for actors, scenery and effects. Default: use the existing actor footprint as the first greybox reference. If a richer production sprite grid is selected, record it and convert the shared actor family together; do not introduce one high-detail character amid coarse sprites without a deliberate scale reason.
- Default: use broad light/dark clusters, stepped outlines and sparse texture. Reduce fine noise on playable floor before adding stronger glows to compensate. The concept boards are much more detailed than the procedural arena and are not a source-pixel specification.
- Keep simulation positions and exact attack directions continuous. Crisp pixels do not require quantising physics, forcing eight-direction aim or lowering the simulation rate. The current four artwork facings depict continuous world directions; they do not limit gameplay to four directions.
- Anchor characters at their feet with a consistent pivot/contact shadow. Headgear, coats and weapon tips may extend past the body; they must not imply a larger collision shape. Player apparel preserves the selected presentation's facing cues and never changes the shared collision body or feet pivot.
- Keep camera angle and combat zoom consistent. Make enemies and boss contact points fit the local view by posing and arranging them. A wide establishing tableau cannot establish a different combat camera or an offscreen attack rule.
- Separate grounded obstacles from overhead scenery through visible bases and depth. Grounded stalks, trunks and wall bases can block; decorative caps, stars, canopy and reflections do not acquire invisible colliders.
- Move or fade foreground scenery when it hides the player, a target, warning or safe landing. Warnings and active footprints stay legible over smoke, spores, reflections and white shadows. This is a readability requirement, not permission to draw hazards through walls.
- Default: share one HUD/icon family and stable placement across acts. Mockups with no HUD do not remove required HP, ammo or effect feedback; invented labels on study boards do not define the interface.

## Acceleration, stopping and momentum

Use explicit motion profiles in world units and simulation seconds. A change of palette, sprite sheet or animation speed must not change those profiles.

| Motion | Observed current arena values | Implementation reminder |
| --- | --- | --- |
| Player dash | 15 world units/s for 0.18 s; 2.7-unit unobstructed distance; 0.34 s start-to-start cooldown; one queued direction | Starts at dash speed and stops without voluntary coasting. Normalize any-angle direction; collision can shorten the landing |
| Player hit knockback | Impulse, 0.16 s knockback timer; each X/Z component brakes at 25 units/s² while that state is processed | Distinguish forced displacement from a chosen dash; do not turn recoil into a hidden extra voluntary move |
| Enemy approach | Grunt 2.6, armoured 1.75, hopper 3.3 units/s; approach velocity moves toward its target at 12 units/s² | Smooth approach is distinct from a committed rush. Keep speed, acceleration and turning behaviour explicit per role |
| Enemy stagger | Impulse response scaled by 1.0 / 0.48 / 1.25; planar braking at 5 units/s² | Weight reads through displacement and recovery; heavy variants can resist launch without concealing whether a hit connected |
| Vertical motion | Actor gravity 24 units/s²; current hopper's launch velocity 7.8 units/s | Hops and launched enemies belong to enemies/impact response; they do not introduce a player jump or airborne aiming requirement |
| Square debris | Gravity 24, bounce 0.38, friction 0.72; at most 96 chunks and 48 transients | Share the bounded effect budget and cleanup. Decorative fragments collide with the world, never add random combat damage or block escapes |

**Player default:** preserve the deliberate dash rather than adding acceleration ramps, floor friction, slippery movement or post-dash drift as an art polish step. Momentum appears in knockback, enemy commitment, falling material and debris. A cosmetic lean, coat lag or trail may suggest speed without moving the gameplay body farther.

**Enemy default:** stage weight with preparation, a clear planted/locked pose, committed travel and visible settling. A locked lunge, ray, grab or root attack cannot keep homing after commitment. Record whether a role tracks during its initial warning and exactly when tracking stops. Do not derive a new acceleration or turn rate from how many frames an artist drew.

Equipment speed and distance remain independent: `dash_duration = resolved_distance / resolved_speed`. Increasing speed alone keeps the landing distance; increasing distance changes duration. Snapshot a dash's resolved values at action start, keep invulnerability and cooldown rules from the equipment specification, and test the slowest legal loadout. Do not duplicate those numbers in a separate style balance table.

Physics, warning clocks, knockback, reloads, sun changes, replay clocks and temporary effects must freeze together during pause/backgrounding. Resume consumes its overlay tap before combat input. Visual interpolation may not jump a frozen tell straight to damage.

## Animation speed follows the action

Low-frame artwork and responsive simulation can coexist. Must express animation durations in simulation seconds and bind visible state transitions to the same action state used for collision/damage. Exporting more frames must not make an attack faster; dropping render frames must not delay its locked footprint.

**Observed lab implementation:** the shared helmeted player enters idle, dash, landing, primary, blast and hurt immediately, with six to eight authored frames per state. A neutral dash still lasts 0.18 s; its cosmetic landing settles over 0.22 s. Primary and blast cosmetics settle over `0.28 / attack_speed` and `0.24 / attack_speed` seconds; hurt settles over 0.28 s. Their existing logical phase, hit and cooldown deadlines remain separate and unchanged. New accepted input interrupts settling immediately. Idle breathes over 1.2 s. These are simulation clocks, so pause freezes them. [The character manifest](../assets/characters/manifest.json) records scale, feet pivot and durations. Enemy artwork still uses the old two-frame locomotion scaffold; authored campaign enemy poses remain future work.

**Observed player effects:** one connected 80 × 32, 16-frame smoke plume follows each accepted dash's actual path and fades over 0.80 s; collision latches a shorter trail. Slash restores the original pale eight-segment arc with a slower 0.28-second sweep and no smoke. Blast immediately releases a bright 36 × 24, 10-frame white/gold fan from the current barrel-tip texel, spreading along exact aim and fading over 0.24 s. These pause-aware cosmetic clocks do not change travel, hits, ammo, reload or cooldowns. The [effect manifest](../assets/effects/manifest.json) records source, pivots, scales, states and reuse.

Default animation grammar:

| State | Visible evidence | Timing/behaviour contract |
| --- | --- | --- |
| Approach/idle | Quiet breathing/stride or mechanism motion; clear facing | Decorative motion does not look like a new attack warning |
| Warning/windup | Crouch, raised spear, turning mirror, lifted arm or root; outlined footprint | Tracking, if used, is shown; no damage yet |
| Lock | Planted pose and stable marked footprint; countdown visibly progresses | Sampled destination/direction stops changing before activation |
| Active | One clear strike/release and the actual filled or hatched footprint | Damage begins and ends with the explicit active state; no invisible extension |
| Recovery/vulnerable | Lowered weapon, folded mirror, planted tool, low knot or exposed rim/tether | Show the close-range opening for its whole usable duration; prevent a new attack until its specified recovery ends |
| Hit/repelled/defeated | Brief impact response, directed retreat, or clear removal | These states differ. Repelled enemies remain alive; cancelled attacks visibly remove their warnings |

Not every attack needs many frames. Default: a few decisive poses with held anticipation, brief release and readable settling. Share the rhythm within a role/family, and vary named phase durations deliberately. The prototype windups are 0.55 s for grunt, 0.80 s for armoured and 0.42 s for hopper; these are arena observations, not campaign enemy assignments or approved reaction budgets.

For each dangerous exchange, warning lead time must cover recognition, remaining dash cooldown and escape travel for the supported loadout. Recovery must allow remaining cooldown, a useful positioning dash when needed, and an ordinary primary attack. Do not choose shorter tells merely because Act 2 or 3 assumes experience. Increase pressure through known combinations and positioning while preserving legibility. Start mixtures with at most two preparing attackers and stagger their commitments, as the act plans propose.

The first tap remains an immediate primary action. A preparatory weapon animation cannot delay it while waiting to decide whether the user double-taps. The nearby second quick tap adds one blast, not another slash. Equipment attack speed adjusts the relevant cooldown/recovery together without changing the gesture recognizer's 280 ms window.

## Restrained cues for things the player can use

The following is a **new shared cue default**, not an existing reusable cue component. Teach a cue once in a calm encounter, then repeat its shape and meaning throughout the campaign. Subtle means visually restrained, not hard to identify on a phone.

Default: an actionable part has a clean silhouette break or seam, a thin stepped contrast edge, and a slow two-pose glint/breath while available. Keep the highlight local to the usable part. At the current low-resolution gameplay scale, begin with a one-source-pixel edge and check its projection; enlarge it if it vanishes. Use the same authored pulse cadence for the same function across acts. Avoid giving every prop a bright halo or constant sparkle.

| Function | Available cue | Response and ending cue | Input |
| --- | --- | --- | --- |
| Hittable mushroom cluster | Low hanging cluster contrasts with the stalk; clearly separate remaining clusters; local stepped edge | Hit produces falling square spores; living enemies retreat beyond a restrained broken field boundary; field thins; spent cluster leaves an empty patch | Ordinary attack hit; primary is sufficient; extra hits during the active field do not spend another cluster |
| Enemy/boss opening | Physical target lowers or exposes; same local hittable-part edge as other attackable objects | Impact on the actual part; closed/exposed/severed/spent or equivalent poses clearly differ | Ordinary primary at close range; blast remains optional |
| Contact collectible | Compact distinct silhouette and grounded contact marker, separated from decorative fragments | Clear collection response and removal; show its actual defined reward | Contact; an existing core increments a counter only |
| Exit/hatch/threshold | Open gap or hatch pose, broad ground approach and quiet repeated contact marker | Blocked state visibly differs; clear state opens; crossing gives transition feedback | Contact after the stated encounter condition |
| Temporary pickup | Shared effect-group icon/silhouette plus local availability cue | Pickup confirms the named effect; HUD shows remaining simulation time or charges; expiry is visible | Contact according to the future pickup implementation |
| Equipment candidate | Shared slot/profile marker and identifiable item silhouette | Weapon replacement names the profile; clothing comparison occurs paused at a safe boundary | Follow the equipment specification; do not turn a combat tap into an unannounced equip command |
| Danger | Local source pose plus outlined footprint and countdown; stable footprint at lock | Active fill/hatching and release; a distinct dissipation/recovery state | Evade or punish with the existing gestures; this is not an interaction prompt |
| Decoration/reflection | Ordinary scenic value treatment without the reserved actionable edge/pulse | No collection, hit feedback or damage footprint | None |

Colour and audio support these cues; shape, value and state change must carry the meaning independently. A friendly spore boundary must differ from a damaging circle by broken edge, outward retreat response and absence of danger fill/countdown. Decorative crater rings, court roundels and white shadows cannot impersonate active warnings; only an actual hazard adds the reserved warning animation. A Mirror Echo's real body has filled floor contact; its harmless reflection stays hollow and never receives the hittable-part cue or a health bar.

A low cluster or tether's cue does not promise it is reachable unless the geometry supports an ordinary slash. Show targets, enemy source, full warning and at least one feasible landing together. Finger occlusion, grayscale, low screen brightness and muted audio are review conditions. Make the cue larger or simplify nearby texture before introducing more prompts.

Do not expand the environmental interactable roster as part of applying this visual language. The concept explicitly defers broader interactables until enemy design. For a future authorised prop, specify the enemy pressure it answers, existing gesture/contact trigger, opening it creates, available/active/spent states and reset rule before drawing its cue.

## Art and prototype gaps to remember

- Current concept images vary in protagonist coat/headwear, light/dark body value and detail density. Select and record one coherent act presentation with its owner rather than copying every illustrated variation. The Character Lab supplies a helmeted prototype family; reuse the shared actor/equipment interfaces, collision, feet pivot and action timings while producing the chosen act artwork. Existing sheets and source prompts retain their provenance.
- Some Act 3 scenic accents compete with usable parts: Crystalman's gold floor rings/grid nodes, Twin Suns' eye-obelisk and the forest's watching knots. Keep these quieter than the actual exposed tether or rooted enemy. Decorative eyes, rings and luminous crystals do not receive the reserved actionable edge/pulse merely because they look significant.
- Pixel-looking full-frame illustrations contain baked lighting, perspective, labels and overlapping scenery. They supply shape and composition ideas, not an atlas of aligned transparent sprites. Production conversion and reuse are detailed in the asset guide.
- Arena enemy warnings now draw the same reach/dot cone used by their discrete strike, including the small origin disk, with countdown, fixed lock and brief active fill. Player slash/blast outlines and committed enemy warning/active meshes use scenery LOS through the shared [attack-footprint helper](../scripts/attack_footprint.gd), matching their ground-target hit checks; decorative slash arcs and muzzle bursts remain separate feedback. Campaign cue polish and full obstacle/readability checks remain future work; do not shrink hit logic to fit decorative effects.
- Arena enemies now hold a proposed 0.60 s stationary recovery with a visible marker/tint after 0.12 s active feedback, with at most two preparing attackers. They still lack dedicated authored recovery sprites. Campaign recovery windows and mixtures require layout and human timing tests; the lab values do not establish approved campaign reaction budgets.
- Still images cannot establish enemy acceleration, animation speed or hit timing. The act concepts specify the decisions; code and bounded playtests establish those temporal details.
- Some older images depict automatic spore vents or narrower paths than the current concepts allow. Preserve their useful scenery ideas while following the revised repulsion, continuous-floor and local-camera rules.

## Acceptance before calling content consistent

For a changed feature, use a small room in the existing portrait camera before dressing a full level. These are future checks, not results of this documentation review.

1. Compare the same gesture trace and loadout in all relevant acts: identical action meaning, normalised dash, aim anchor and footprint. Test screen-edge releases and zero-direction taps.
2. Inspect available, warning, locked, active, recovery and spent states at actual gameplay size. A muted/grayscale view should still identify the object, its function, hazard source and safe floor. Check that decoration does not produce false interaction cues.
3. Compare motion at different render rates: landing, cooldown, acceleration, knockback and damage deadlines remain governed by simulation time. The dash pose appears during the short dash; no action waits for a cosmetic frame.
4. Complete the changed encounter with ordinary primary attacks, no pickups and no follow-up ammo, then check supported equipment extremes. A required route remains viable after spore supplies are spent.
5. Pause/resume during a warning, active field or replay. All clocks stay aligned, the resume tap is consumed, and a retry restores coherent supplies and states.
6. Record the reused family, any new asset/state and its production readiness. For optional levels, explain the different arrangement or decision and list only the small additions to the parent kit.

When gameplay changes, run the existing Godot import and mechanics checks described in [README.md](../README.md), plus a bounded check for the changed rule. Run the equipment validator when numerical item data changes. Documentation-only edits need link and consistency checks; they do not establish mobile performance or human reaction timing.
