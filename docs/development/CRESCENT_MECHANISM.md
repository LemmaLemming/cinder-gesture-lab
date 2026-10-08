# Per-cycle fixed crescent mechanism

This additive `CinderLaneMechanism` extension uses the existing real shared Scheduler/Hero and required warning → lock → active → recovery cue grammar for a bounded annular sector. It creates no HP component, attackable target, collider, enemy credit or player ability. The integration owner owns its runtime implementation; this note records the focused native consumer fixture.

```gdscript
configure(mechanism_id: String, geometry: Dictionary, opening_position: Vector3,
          raw_role: Dictionary = DEFAULT_RAW_ROLE,
          timing_floors: Dictionary = DEFAULT_TIMING_FLOORS) -> bool
preview_start(hero_id: String, response_context: Dictionary,
              opening_position: Variant = null, bearing: Variant = null) -> Dictionary
start(hero_id: String, response_context: Dictionary,
      opening_position: Variant = null, bearing: Variant = null,
      preview: Dictionary = {}) -> Dictionary
```

Configuration may now use canonical `Geometry.crescent(origin, direction, inner_radius, outer_radius, min_dot)` as well as the existing finite lane/circle. Its immutable configured origin/radii/sector remain fixed. A crescent cycle may select another finite normalized planar native Vector3 bearing through `preview_start`/`start`; null retains the default. Lane/circle reject any explicit bearing. No normalization, rotation of the collision world, movement of the source or change to deadlines accompanies this choice. Optional per-cycle opening remains the existing reachable-position seam; actual target HP/recovery custody belongs to its owner.

The actual accepted `exchange.geometry`, rather than the immutable default, drives public state, required cue geometry and continuous padded active path contact. Each actual Hero opportunity remains consumed before synchronous callbacks, once per cycle, with ordinary armor and zero impulse. Hollow inner space remains genuinely safe for the supported capsule/path; the crescent never becomes a filled disc or cone proxy.

## Pure preview and exact admission

`preview_start` returns the defensive native result of [stationary Scheduler preview](STATIONARY_PREVIEW.md). It changes no mechanism phase/cycle/sample/cue/diagnostic, actor/source/clock, Scheduler serial/reservation/cooldown, or event stream. Submit that exact contemporaneous result as the fifth `start` argument. The actual request rechecks the complete native source, response, geometry, role/deadlines, floor/world and retained union before and after ordinary cleanup. Changed bearing, copied scalar/type/geometry/proof or context rejects before allocation. Ordinary legacy calls remain supported without a preview.

The wrapper derives the least containing same-world Node3D ancestor of the mechanism, Scheduler, selected actual Hero **and every actual bound floor collider**, using a shared helper for preview and previewed start. A native actor-only subgroup beside its floor therefore reaches the outer ArenaRoot instead of rejecting or omitting that floor. In shared Game, Hero and active level are siblings under `world`, which contains native floors/scenery. This derives custody from actual native nodes and introduces no arbitrary caller-root or copied-instance-ID authority.

The helper rejects empty floor lists and lists above 32 entries before its native ancestor walk, and requires live same-world floor collision nodes. Supported box geometry, safe rectangles and floor continuity are still validated by Scheduler. Scheduler also scans the full World3D and rejects any omitted, generated, moving or unsupported scenery. A sibling blocker outside the derived root still fails closed; the mechanism cannot silently bypass collision by choosing a smaller domain. A context `world_root` injection remains rejected by the closed wrapper context schema. The focused fixture proves actual sibling-floor admission and full native floor/blocker fingerprint rather than requiring a proxy geometry or caller-authorized root.

## Exact paused aggregate

The existing `lane-mechanism-1` API and snapshot envelopes remain. Ordinary completed sampled batches write schema1; unresolved callback-paused segments continue to use existing conditional schema2 as documented in [Lane Mechanism](LANE_MECHANISM.md). Crescent geometry itself introduces no envelope field. Older consumers that only decode lane/circle must adopt the crescent-capable consumer and Scheduler before reading this new kind.

`configuration.geometry` retains the immutable default bearing. `exchange.geometry` carries the actual selected cycle's closed six fields: `kind`, `origin`, `direction`, `inner_radius`, `outer_radius`, `min_dot`. The reader validates canonical normalized direction, exact configured source/radii/sector and exact equality to the paired Scheduler's current/staged geometry, source/opening, role, deadlines, epoch/clock and samples. A legitimate selected bearing may differ from the default; a copied consumer-only valid bearing change cannot disagree with its paired Scheduler. Use [ExactJson](EXACT_JSON.md) for bit/type-preserving aggregate transport.

Validate the complete Player/Scheduler/mechanism aggregate before committing actual Player → Scheduler → mechanism. Staged `hero_positions` carry the independently validated saved actual Hero position. Fresh restore rebuilds the selected native cue silently, preserves consumed opportunities/resources/clocks and emits no warning/hurt/hit/cancel callbacks. This trusted whole-aggregate protocol does not cryptographically authenticate arbitrary jointly altered historical saves.

## Focused evidence

`tests/crescent_mechanism_smoke.gd` uses an actual shared Hero, Scheduler, immutable native floor/distant blocker and real mechanism/cue. It covers continuous nondefault preview/start correspondence and full purity; bearing/dimension/source/scalar/type tampering; actual active hollow-pocket dash with executed path samples; selected annular contact and once-hit continuation; exact closed paired JSON and fresh quiet restore; copied geometry/direction forgeries; a subsequent different accepted bearing after actual recovery/cooldown; legacy lane/circle bearing rejection; and actual floor-containing root derivation, native sibling-floor exact admission and invalid/bounded floor/context rejection.

The final targeted queued run passed **145 checks, 0 failures**, exit 0, on Godot `4.7.2.stable.official.ed1daf0bf`:

```sh
python3 scripts/dev/dev.py engine --headless --path . --log-file '/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/crescent-mechanism-final.log' --script tests/crescent_mechanism_smoke.gd
```

Final runtime/fixture bytes were frozen throughout and preserved under `.cinder/crescent-mechanism-final-source/` with `sha256.json`: Lane `52aab391c79cc235ba188066bf6dab5c0e5b81169e4d34fe5c2071ac2c5f5064`; Scheduler `5e7ae27fc3f274fe8c49d266fd6611aca0300e5b975b4d1591c6839f45d83d7f`; geometry `c82501198ea1a3b53c872caec35e52604bb7256d6e71fff2c9293b430e1d8f09`; cue mesh `d63f5dfabbdae2dbd055e24013b0d822bca47ba71a457e1ab0d874e0ef22929d`; Player `8e4dfeb2c285f1d786ec3268bdaf5efbc70b3b0f4b2473b2870e0566a88e4743`; fixture `b7b005bb8c7ae023d28012d82431fa3e080ea4662822a053f052d096fd34fd24`. The final log contains no script/runtime errors. Native macOS startup still emitted the `get_system_ca_certificates` `ret != noErr` diagnostic.

The first named `python3 scripts/dev/dev.py test crescent_mechanism` run passed **129/0**, exit 0, using Lane `bddbf081af0ddc179d5a1e1815fa64d9a646e7a73bb639bb20d5825044153b02` and fixture `fdfc915f4d9a36d2f0e7d06b5688875350e39fe13f8bca5d16157f2df19625f9`. Its source bytes remain separately preserved in `.cinder/crescent-mechanism-first-source/`; `.cinder/crescent-mechanism-first.log` SHA256 is `4190240fee5df3d32c57e7454fe71a6a894b36169b4b769af7631d46e524dd3c`. That earlier scope expected a conservative sibling-floor rejection under the narrower ancestor derivation. The integration owner then repaired the actual reusable hierarchy limitation; the final scope instead proves real sibling-floor admission plus malformed/bounded native root controls. First-run default `user://logs` rotation/write attempts were denied by the sandbox, alongside the same native certificate diagnostic, without preventing execution. The final command supplied an explicit project log path and eliminated those default logger diagnostics.

Only this new leaf was run by its author; integration owns directly affected existing suites and publication. This evidence accepts neither authored Act placement/art nor whole encounter fairness, portrait camera integration or mobile performance.
