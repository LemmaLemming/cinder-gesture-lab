# Lunar celestial accents and opaque rock surface

Original integer-pixel artwork produced on 2026-10-08. **Produced pixels only:
runtime unbound and portrait unverified.** This new four-texture set complements
the existing lunar kit. Existing environment resources remain untouched.

## Source and identity

Actual current G09 celestial performers, G15 modular lunar kit, G17 Crater Gardens
and G24 portrait gameplay boards were inspected, together with actual A09 planetary
and A10 star tableaux and F08 film frame. Their original image/catalogue hashes
are recorded in `lunar_accents_manifest.json`. The boards are contemporary game
concepts; the film/tableau records remain distinct historical references.

Earth is a standalone painted globe component of the existing E08/P11/C19/O42
tableau, not a new character or verified mythological identity. No complete robed
bearer is supplied here. The single human-faced star reuses **C15/O39**, with a
friendly anonymous face and swept hair. It does not claim to depict a particular
historical performer, all seven original stars in their exact arrangement, or the
distinct C18 twin-star composition. **C17/O41** preserves a seated bearded human
and inclined ringed globe as one scenic composite. The crown is costume only;
no scepter, weapon, equipment slot or bonus is supplied.

A09/A10 local Commons records retain the exhibition publicity attribution; F08
retains the recorded film-frame credit. These are provenance declarations from
the existing catalogue, not new licensing determinations. No historical or
generated source pixels are sampled, cropped, edited or traced. Every shape,
continental patch, face, fold, ring and brush streak was drawn from original
integer coordinates using Pillow. The globe is a theatrical approximation,
not a geographical accuracy claim.

## Native contract

| File | Grid | Pivot | Tentative pixel size | Role/state/family |
| --- | --- | --- | --- | --- |
| `earth_globe.png` | 64×64 | (32,32), centre attachment | .024 | Static globe component, celestial_globe_P11 |
| `human_star_performer.png` | 64×64 | (32,32), centre attachment | .020 | Static human face, human_faced_stars_C15 |
| `saturn_performer.png` | 80×96 | (40,96), bottom composite anchor | .024 | Static seated performer, ringed_performer_C17 |
| `painted_rock_surface.png` | 64×64 | (32,32), UV centre | .024 art texel scale | Fully opaque surface, lunar_painted_rock_material |

The seven object grays match the existing launch/rusher/lunar palette: ink20,
coal39, shade67, mid105, silver147, light193 and white231. Three cutouts have only
alpha0/255; the rock tile has **alpha255 at every pixel**, including every edge.
All use nearest filtering and deliberate stepped clusters, with no antialiasing,
blur or uniform noisy dithering. Dimensions, exclusive opaque bounds, provisional
world quad sizes, pivots and all output hashes are in the manifest.

Earth and star use centre attachments, so a centred Sprite3D needs zero offset
for that pivot. Saturn uses the lower composite anchor; a centred Sprite3D can
offset Y by48 native pixels. That anchor is the bottom of scenic planet/cloth,
not a physics actor's feet. Root must verify actual billboard frame and apparent
scale in the normal following portrait. Whole cutouts must remain intact, with
ordinary depth; their placing/visibility does not authorize source occlusion.

The opaque material translates **O34/P10** broad pale painted rock streaks and
black creases onto the **existing complete low-divider BoxMesh**. Root should
keep its full dimensions, identity and physical footprint, then bind this tile
as an ordinary opaque albedo texture. It must not be used as a cutout shader,
alpha mask, substitute mesh, collision mask or excuse to hide the low solid body.
The provisional .024 texel size suggests 1.536 world units per 64-pixel repeat;
UV scale and face orientation are owner presentation decisions. It is not a
seamless terrain atlas and adds no painted floor warning, circle, arrow or cue.
Its contrast belongs on a solid scenic surface, not the playable ground.

## Authority and readiness

**Collision, damage, cues and clocks: none.** Every celestial figure remains
friendly, nonhostile scenery outside the immediate combat floor. No new enemy,
boss, pickup, resting/healing mechanic, optional room or campaign reward is
introduced. The rock material supplies pixels only; all collision, floor support,
camera witnesses, controls and action timings remain existing owner/shared work.

Rebuild using `python3 assets/acts/act1/lunar/accents/build_lunar_accents.py`.
The generator writes only these four PNGs, manifest and contact sheet inside its
own new directory. It reads references only to record source hashes. Static PNG
checks and actual native-pixel/contact-sheet inspection establish file readiness;
they do not establish engine import, binding, actual portrait composition or
human understanding. The root owner performs those steps after handback.
