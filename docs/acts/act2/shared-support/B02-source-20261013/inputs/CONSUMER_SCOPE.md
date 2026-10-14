# Native sampled-circle consumer draft

Status: **SOURCE_ONLY_DRAFT_UNPARSED_UNEXECUTED**. These files are inert `.gd.txt` sources. No production file, worker checkout, Git state, canonical claim/ledger, UID, engine lock, Godot job, import or runtime state was changed by this subtask. Static text inspection checked duplicate top-level function names, LF/whitespace, absence of fabricated UID references, and intended preload destinations. It is not Godot parsing or gameplay evidence.

## Intended installation

| Scratch source | Intended canonical destination |
| --- | --- |
| `consumer/native_sampled_circle.gd.txt` | `scripts/combat/native_sampled_circle.gd` |
| `tests/sampled_eye_fixture.gd.txt` | `tests/fixtures/sampled_eye_fixture.gd` |
| `tests/sampled_circle_smoke.gd.txt` | `tests/sampled_circle_smoke.gd` |

The draft deliberately uses those canonical `res://` paths. They do not resolve to the new `.gd` modules until an integration owner deliberately installs the complete draft alongside the matching Scheduler draft. New UIDs remain **pending native import**; none is fabricated. Existing Geometry, Lane, Player, Cue, CueMesh, capture/replay, controls, gear, settings and ability/equipment ledgers remain unchanged.

## Ownership and lifecycle

`CinderNativeSampledCircle` extends `Node3D` and binds once as a child of the genuine stationary eye `CharacterBody3D`. `bind(owner, scheduler, hero_id, hero, world_root, floor_regions)` calls Scheduler's one-shot native source binding. The helper has no HP, hit group, `take_damage`, source binding getter or surrogate body. The actual eye supplies the closed nine-key native getter, owns true HP/death and its actual BodyCollision, and owns the Scheduler lease. Native references are checked before casts; source/Hero/world/Cue custody is retained in the unit.

Source generation identifies a bound incarnation, while helper `cycle` and `threat-N` identify finite accepted attacks. A completed/cancelled living source can explicitly request another attack only after its real original cooldown permits it. The helper never automatically rearms, resets bindings, advances source generation or manufactures old history. Each successful start samples again at that new warning start. The current exchange, adapter/sample, role, Hero endpoint, consumed opportunity and bounded pending suffix are transported; no forever journal is introduced.

The eye fixture declares an anchored impact policy: ordinary primary changes the real receiver's HP/death, while its incoming impulse does not move that body/opening. Its real Box BodyCollision is created by the eye's native Script. It cancels its own lease before genuine death observers. There is no dummy HP object and no reset of physics to disguise a moving source.

## Shared seams used

- `bind_sampled_circle_source(owner: CharacterBody3D, hero_id: String, hero: CinderPlayer, floor_regions: Array, world_root: Node3D) -> bool`.
- `preview_sampled_circle(owner: CharacterBody3D, hero_id: String, response: Dictionary) -> Dictionary`.
- `request_sampled_circle(owner: CharacterBody3D, hero_id: String, response: Dictionary, preview: Dictionary = {}) -> Dictionary`.
- `sampled_circle_reservation_state(reservation_id: String) -> Dictionary`, a fresh pure validated reader.
- `sampled_circle_exchange_error(owner: CharacterBody3D, encoded_exchange: Dictionary, adapter: Dictionary, clock_s: float, staged_hero_clock_s: float = -1.0) -> String`, a paused pure historical join which grants no lease. The helper separately joins actual/staged source, current lease or inactive absence, serial, original cooldown, phase, pending segments and consumed opportunity.

`preview_start(context)` preserves helper/Scheduler diagnostics, cue, phase and authority. Context is closed to encounter ID, world revision, recognition/input margins, escape/return candidates, the already bound native floors and world. It supplies no target point. Actual Player response supplies stats/motion/action clock. Stopped grounded warning admission remains required; current/queued dash admission is rejected.

`start(context, preview={})` captures only a successful fresh sampled adapter owned by the actual eye. Committed geometry remains a pure circle without `source_position`; the helper duplicates it and adds separate actual eye `source_position` only for `Cue.present`. Native sample stays immutable through warning, lock, actual Hero motion and fresh restore.

## Contact and presentation

The helper samples the actual earlier-physics Hero endpoint and Scheduler clock before phase observers, appends a bounded contiguous one-tick segment, and preserves a held suffix if an observer pauses. Resume appends the actual next segment, keeps bends, and intersects the original active interval. The opportunity and path entry are consumed before actual Player hurt; invulnerability may legitimately reject damage without granting a second opportunity. Hurt and hit observer boundaries re-read native custody, required presentation and the pure validated lease.

One ephemeral two-argument parent presentation guard may bind before cycle zero or fresh paused restoration. It cannot be replaced or serialized. Snapshot prevalidation never invokes it. Native cue validation independently retains actual nodes/materials, renderer properties, canonical phase mesh buffers, current mesh resource identity, transforms, visibility, colors and absence of surface overrides. It checks the prior phase before publication and the new canonical state after Cue callbacks. A late hidden, missing, replaced or mutated native required part cancels before contact and records a sticky in-place cue fault; clearing cannot silently heal/rearm that unit. Normal whole-parent removal cancels the actual eye lease and quietly clears held danger.

## Paused transport

Consumer schema1 is closed: API/schema, source binding, status/phase/cycle/clock, encounter ID, original exchange, sample, full typed adapter, resolved role, actual Hero endpoint, consumed flag, pending segments and cancellation reason. Exact finite scalar bits/types are preserved through the existing `ExactJson` codec. Its copied sample exactly joins the adapter and original Scheduler sample; it never calls live preview or resamples a saved Hero.

The fixture prevalidates the complete real Player and true physical eye packets first, then derives staged `hero_positions`, `hero_action_clocks`, source pose/velocity and the closed eight-key `sampled_owner_bindings` wire. These maps are derived fields of those validated packets, not alternate actors/HP or caller history authority. Fresh commit uses real interfaces in this order: **Player → true eye HP/death/pose → Scheduler → consumer/Cue/pending paths**. Final Scheduler/consumer commit uses actual restored physical state. Consumer restoration requires a fresh bound recipient and blocks Cue/state/hit observers while rebuilding. Genuine saved source defeat is the specific exception to original cooldown retention, because normal `cancel_owner` removes the dead source's cooldown.

Captured receipts establish internal sample/recipe/world/source consistency; they do not authenticate arbitrary past play. This draft makes no Shell transaction, disk save, authored format2 level owner, production B02 art/camera or release claim.

## Drafted focused checks

The source fixture drafts checks for original real remote-origin refusal before sampled registration; pure preview and exact stale receipt rejection; actual Player dash with unchanged circle; real zero-ammo public Player slash against actual recovery-eye HP; source death cancellation; another genuine Player under the same ID rejection; current/queued dash rejection; replaced source resource validation; once-consumed real hurt; explicit same-generation finite cycles and parent removal; late native cue hide/free/replacement/mesh mutation; exact codec roundtrip; fresh quiet dead-source restore; and fresh quiet active observer-pause restoration with an actual held suffix.

One distinct native nose fixture additionally drafts admission/proof checks for unsafe versus safe combined circle/cone geometry, explicit stagger, one shared Scheduler and the same actual eye recovery opening. It is a proof/admission fixture, not a production nose attack controller or nose contact test.

The dash/primary checks invoke the actual public `Player.request_dash` and `Player.slash` APIs. They do not claim gesture-router, GUI, device, portrait, full route or campaign execution. All drafted checks are **unexecuted**, including native import/parser checks. Integration must run the new leaf and directly affected Scheduler/default compatibility checks through `scripts/dev/dev.py`, then briefly inspect native portrait phases, under the existing focused acceptance policy. Actual Shell/format2 consumer integration, level-specific nose lifecycle and production eye art remain subsequent integration/level work; these are not accepted by the scratch fixture.

## Frozen draft hashes

The final hashes are reported to the parent after this document is complete. They freeze this source handoff, not a parsed or accepted implementation.
