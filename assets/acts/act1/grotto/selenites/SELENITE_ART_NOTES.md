# C31 / C32 Mushroom Caverns costume pixels

Produced on 9 October 2026. These are original hand-authored integer-polygon
drawings, with no source crop, reference pixels or raster edits. The actual
G10 costume board, G15 lunar prop board and F10 film frame were inspected.
The manifest records their complete file hashes and the exact canonical
C31/A1-E2 and C32/A1-E3 record hashes. G10's small swarmer and spear guard are
game proposals; the upright masks, rib bands and projecting headpieces follow
the film-linked costume family. No new species or rank is introduced.

The deterministic Pillow generator creates thirty standalone transparent PNGs:
front, right side and back, each with standing, warning, lock, active and
recovery poses for both roles. Left side uses reflection of the authored right
side only. Alpha is exactly 0 or 255; all pixels use the established seven-tone
Act1 grayscale palette. Nearest filtering, unshaded material, ordinary depth
and alpha discard are required. There is no baked floor shadow, cue, source
marker, spore field or particle effect.

C31 uses a 48x80 grid with feet pivot (24,80). Its smaller opaque torso and
shorter headpiece distinguish the swarmer while retaining an upright biped.
Raised arms and bent knees distinguish warning; an extended prepared pose
marks lock; the active bent-leg pose suggests an acrobat's short grounded hop.
At least one boot remains on the same bottom row in every frame. This does not
lift, animate or alter the actual capsule, leased lunge, speed or damage.

C32 uses an 80x80 grid with feet pivot (40,80). Its wider arrowhead and long pale
shaft are attached costume pixels. The warning raises the spear, lock plants
the wide stance, active selects a short horizontal thrust, and recovery lowers
the spear and relaxes the arms. At the provisional pixel size 0.022, both grids
are 1.76 world units tall; C31 is 1.056 units wide and C32 is 1.76 wide. The
centered Sprite3D offset is (0,40) for both. The larger C32 frame requires its
actual full billboard corners in camera witnesses, including current and
committed opening positions. The spear has no separate collision or damage;
the native short lane and shared cue remain authoritative.

The clockless `Act1MushroomSeleniteArt` leaf requires `configure(role_id)` before
being added, then selects pixels from `set_pose(phase, world_facing, camera)`.
Only actual phase and continuous facing select the texture. It has no process,
physics, controller, input, motion, clock, tween, damage, cue or signal. Actor
visibility, defeat and exact paused restore remain owned by the parent. Native
sprite settings, resource handles/paths/sizes, local identity and same-world
bindings are validated by `binding_error()`.

**Readiness:** produced pixels and presentation leaf, unbound and untested in
Godot/portrait. The contact sheet was inspected at nearest scaling; it is a
review artifact and never a runtime texture. Actual source/footprint/landing
and primary-opening composition, overlap at close range, all legal equipment,
phase interruption, pause/quiet restore and native resource guards still need
the owner's targeted checks. Existing C30 art and accepted L2 source remain
unchanged. Future harmless-spore recoil, turn, retreat and regroup need their
published shared protocol and later pose assets; this kit claims no connection.

Reuse families: `act1_grotto_selenite_C31_swarm` and
`act1_grotto_selenite_C32_spear_guard`, sharing the lunar costume palette with
C30. Intended reuse is A1-L3 and its future A1-O2 parent-kit rearrangement;
court C32 placement still requires its own later authored portrait review.
