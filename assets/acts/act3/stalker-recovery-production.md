# Sunbound Stalker — recovery art candidate

Generated 8 October 2026 with the built-in `image_gen` tool in default edit mode, `referenced_image_paths` pointing to the existing Branchspell cutout and `transparent_background: true`. One edit, one selected output, one pose. Native PNG is copied byte-for-byte; no CLI fallback, raster editing, resizing, cropping, alpha rewriting or fabricated atlas.

- Asset ID: `A3-E1-ART-RECOVERY-01`.
- Enemy identity remains `C50` / `A3-E1`; reuse family remains `A3-SUNBOUND-STALKER`. A different pose is not a new enemy, equipment type or ability variant.
- File: `assets/acts/act3/sunbound-stalker-recovery.png`.
- Edit target: [sunbound-stalker-branchspell.png](sunbound-stalker-branchspell.png), source SHA-256 `4b26a05de4d86848bb8d1d40d6567097bcc85f9b083d07c2ded110ac5836dcaa`; [existing source record](stalker-production.md) preserves its earlier generation.
- Generation output: `/Users/howardchen/.codex/generated_images/01a11ae1-57cb-79d2-8e89-eb9c0e75834b/exec-988aef9a-a666-42bd-a67f-39df0f1d75b8.png`.
- SHA-256: `8aab2d8763885d4f198b2c346658987145bf585a7b72f31703b32207602c59ac`.
- Native dimensions/mode: 1254 × 1254, RGBA; alpha range 0–255.
- Raw nonzero-alpha bounds: `[0, 31, 1240, 1238]` (right/bottom exclusive); faint peripheral alpha persists.
- Visible silhouette at alpha >=128: `[129, 416, 1153, 1060]`, 1024 × 644 native pixels.
- Alpha counts: 1,256,459 fully transparent; 686 fully opaque; 315,371 partial. Of the partial pixels, 274,804 have alpha 192–254. Original generated alpha is preserved.
- Proposed feet pivot: `(635, 1060)`, normalized approximately `(0.506, 0.845)`, centrally below the lowest visible planted foot. Full-source Sprite3D offset proposal: `(-8, 433)` using the 1254-square source centre. This is an art placement proposal, not a verified collision/body centre or runtime floor-contact result.
- Facing/view: same three-quarter lower-right direction and overhead orthographic interpretation as the edit target.
- State coverage: ONE static low settled recovery pose. No warning/lock/lunge/hurt/defeated animation, alternate facing, Alppain crest or phase durations.
- Collision/damage: none in the PNG. Gameplay and supported shared enemy/cue adapters own actual collider, active footprint, vulnerability, recovery duration and damage.
- Rendering candidate: nearest filtering, ordinary depth test, alpha discard 0.5 to disregard faint peripheral pixels without rewriting source alpha. Imported and rendered by root in a noninteractive art harness; not connected to an enemy state.
- Readiness: edited still candidate inspected natively and in actual portrait. Family scale/baseline and visible lowering reviewed. Crest/seam readability, moving/lateral contact, grayscale/source-warning contrast and gameplay pose transition remain pending. The asset helper performed no engine work; root's later study is recorded below.

## Identity, source and visual review

Actually opened before editing: [G12 threat studies](../../../docs/concept-art/act3/bosses/03-candidates-and-threats.png), [G18 Twin Suns game view](../../../docs/concept-art/act3/gameplay/01-twin-suns-gameplay.png) and the existing Branchspell cutout. G12's violet glassy hide and low seam plus G18's close portrait composition inform the family; the existing runtime cutout is the exact edit target. G18's drawn line remains a committed lunge lane rather than a laser.

The output retains the violet/black-purple angular plate organism, tapered head, ridge/crest arrangement, four bent limbs and clawed planted feet. Torso and head settle lower, the near limb bends more deeply, and the existing ivory/muted-lime near-flank plate join becomes a broader stepped shape. The main surface highlights are broad planes; a few pointed specular accents remain. The seam is anatomy, without a surrounding halo, detached target gem or new organ. No equipment, laser, attack footprint, trail, contact shadow, background, text or atlas is present.

This is an original game-art pose for Cinder's invented C50 creature. It does not authenticate a species from Lindsay, allocate an ability or independently promise hittability. Expose it only under the gameplay recovery state and shared cue meaning. Cosmetic artwork cannot change tracking cutoff, lunge travel, damage time or the usable recovery interval.

## Scale continuity and outstanding checks

Root selected the preparation cutout's 1.35-world-unit visible height as a candidate. The shared player's 1.44-world-unit value describes its maximum quad, not the visible human silhouette; compare the actual act3_traveller portrait before accepting relative scale. The preparation's alpha>=128 source height is 807 pixels. Preserve that family's pixel scale (approximately `1.35 / 807 = 0.001673` world units per source pixel) when trying this new pose. The recovery silhouette is 644 pixels tall, so at the same scale its visible height is approximately 1.077 world units; that lowering is the intended pose change. Rescaling each pose independently to 1.35 visible height would enlarge recovery anatomy and undo consistent family scale.

The visible baseline is nine native pixels below the preparation source's 1051 baseline. The proposed per-source pivot adjusts this to planted feet; verify the swap without vertical pops, collider movement or unintended horizontal displacement. Use the shared enemy's authoritative collider/body centre rather than treating the entire sprite rectangle as collision.

Root queued `python3 scripts/dev/dev.py engine --path . --script res://tests/acts/act3/stalker_art_capture.gd`; `.cinder/stalker-art-recovery.log` reports three art-study captures, exit 0 and no script/resource errors. Actual 339×736 portraits `07-stalker-art-scale-135.png` and `09-stalker-art-recovery.png` preserve family pixel scale/facing/baseline; the upper recovery silhouette lowers by roughly ten screen pixels while width remains similar. The small independent contact disk has radius 0.34 world units. The low seam remains a tiny pale fleck and the crest needs stronger readable state shape; the contact centre appears slightly below the sprite body and requires moving/lateral inspection. These are decorative still studies, with no living enemy or timed exposure.

Before acceptance, hold both poses in the actual source/footprint/safe-landing exchange with eventual player presentation. Check muted/grayscale clarity, dark limb separation, crest and seam readability and retained warning/landing visibility. Verify the recovery remains visible for the full gameplay opening. Ordinary primary reach, legal loadout extremes and timings remain pending with the supported moving-lunge adapter. Neither native nor still-portrait inspection establishes human balance, source/footprint fairness or finished animation coverage.

The registered Act 3 branch is `codex/campaign-act3`; root adopted `campaign-shared-2` at `15589bfd956e74a659a63e843b1e1430d28227b8`. This asset subtask owns only the new cutout and this record, and changes no shared systems, other art/source records, scenes, tests, ledgers or commits.

## Exact edit prompt

```text
Use case: precise-object-edit.
Asset type: ONE transparent recovery-pose pixel game enemy cutout for Cinder Act 3, the existing Sunbound Stalker C50 / A3-E1.
Input image: the supplied sunbound-stalker-branchspell.png is the EDIT TARGET and exact body identity reference. G12/G18 establish context only; do not redesign from their different silhouettes.
Primary request: change only the pose from the existing braced preparation into a LOW, SETTLED, STATIONARY RECOVERY. Preserve this exact organism: the same compact violet organic plate body, tapered lowered head, recognisable dark ridge/crest arrangement, four bent angular limbs and planted clawed feet, violet/lavender/black-purple palette, and existing restrained pale ivory/lime plate-join seam. Preserve the same three-quarter lower-right facing, overhead orthographic angle, square transparent canvas, approximate object scale, body centre and foot baseline around x50 percent/y84 percent of canvas. Keep all four limbs and whole feet visible.
Recovery pose: lower and settle the torso and directional crest, bend/bracing the same four limbs into an unmistakably resting stance, and turn/open the near low flank enough that its existing pale ivory/muted-lime plate join is clearly readable. The physical seam should form one broad flat stepped value shape near the low flank, readable when the whole creature is only about 50–60 pixels high. It is exposed anatomy, not a new target gem, eye, logo, pickup or detached symbol. The head and crest still communicate the original lower-right facing.
Style refinement within the same identity: simplify the original sparkly microglints into a few broad flat violet, lavender and black-purple pixel color planes. Keep crisp stepped contours, separated limb gaps and solid opaque body planes. Reduce fine specular flecks; retain glassy violet material with only restrained large highlights. No neon outline, bloom or surrounding glow. Do not make a smooth shaded 3D model or painterly rendering.
Scene/backdrop: genuinely transparent alpha background, preserve transparency. No floor, ground plane, contact shadow, scenery or backdrop.
Constraints: exactly one whole creature and one recovery pose; no atlas, duplicate, multiple facings, extra limbs, added horn/crest design, equipment, weapon, laser, projectile, attack, warning lane, arc, trail, arrows, labels, text, border, watermark, target gem or pickup. No active motion or action effects. The image adds no mechanics, vulnerability timing, hitbox, enemy identity or ability variant. Preserve the edit target's character identity and canvas placement while changing only recovery pose and simplifying its surface highlights.
```

### Current L1 consumer readiness

Earlier generation/study readiness and native drift above retain their historical scopes. The [current L1 art and exact selected results](../../../data/campaign/act3/levels/A3-L1.md#current-shared-21-carried-route-and-production-checks), [scenery consumer record](scenery-production.md) and [portable evidence index](evidence/A3-L1/index.json) supersede unqualified pending consumer labels for this asset. Current reviewed L1 poses/scenery are suitable in the actual portrait scope; this is a tested candidate READY for autonomous HANDOFF, not integration acceptance, every-facing animation or human pacing/balance evidence. Native bytes, pivots, render-only/collision roles and anatomy/crest limits are unchanged.
