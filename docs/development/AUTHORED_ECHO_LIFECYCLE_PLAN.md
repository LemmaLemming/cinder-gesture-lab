# Authored Echo lifecycle supplement — proposed Shared30

This is a **design draft, not an implemented or published interface**. It follows canonical Act 3 request `a40888b2-58d1-4574-a38a-1b9b824cbe67`, a supplement to `8b06b4ea-d6f6-41f3-8931-79e6b41ec704`. The request was created on 8 October 2026 at 20:29 UTC. It asks for later full-level saves of genuinely defeated Echoes and another cycle on the same surviving actual owner. It does not request new art support, a Player ability, a moving physical Echo or concurrent mixed commitments.

The proposed Shared28 first-cycle publication remains a bounded stationary, exclusive, enemy-authored prototype. Its constructor, physical consumer and native evidence do not resolve these lifecycle requests. Shared30 must supply and test this supplement separately. This document changes no runtime, schemas, actor, engine queue or acceptance status.

## The concrete current limits

The inspected first-cycle implementation has these restrictions:

- `CinderReplayPlayback.configure_authored` configures one immutable program. There is no public next-cycle operation. Its live `advance` accepts running or complete state, and complete advances only the harmless aggregate cursor. Cancelled state does not advance.
- Playback's cancelled reader requires `cancelled_at_s == clock_s`. Its writer takes the current actual Scheduler clock. A genuine source defeated earlier therefore cannot be captured unchanged after that Scheduler advances.
- `Scheduler.replay_cancellation_state` returns an empty record when its actual clock reaches the original `cooldown_until_s`. `_expire_replay_cancellations` erases those records only on real pausable simulation ticks. `_prune` also releases ordinary cooldown entries at their original ready time. Neither pure getters nor save capture should age them.
- `_decode_authored_tombstone` requires the original cancellation to remain unexpired and paired with that actual source's original cooldown. Relaxing Playback's clock equality alone would still fail after cooldown expiry.
- Cursor validates the exact consumed prefix against its own `last_advanced_clock_s`. Advancing a cancelled Cursor to a later aggregate clock could consume previously undelivered events. That is forbidden.
- The first native fixture deliberately has one lethal ordinary-primary opening and a recovery-only damage predicate. A surviving or missed-opening production source needs its own truthful HP/weak-point policy. The fixture codec's one-hit limit is not a general production HP interface.

These facts were read from [Playback](../../scripts/combat/replay_playback.gd), [Cursor](../../scripts/combat/replay_cursor.gd), [Scheduler](../../scripts/combat/threat_scheduler.gd), and the first-cycle [native fixture](../../tests/fixtures/authored_echo_actor.gd). This draft's first review used the original bounded import receipt `.cinder/shared27-a3-resource-import1-source/manifest.json` (manifest SHA256 `1bed44c06013dbc57d061957fe02ef45c1a56e2517baa4c19309a02241bf396a`), whose Cursor was `1cbe648ad391d4363a525751fcc23e71f13292eddcc5da46233289a40a787362` and Playback was `ef11f05f6c73d7797e47894904617f154b924f642bb418765160177fb42dfaa6`. Later first-cycle callback corrections have their own root evidence. The ignored receipt path identifies inspection provenance, not a portable publication artifact or a test result for this plan.

## Keep terminal history separate from live authority

Add a durable, authored-only source-cycle journal inside the actual Scheduler. The journal records native admission, actual cancellation, completed delivery and explicit retirement. It survives the natural expiration of `cooldowns` and `replay_cancellations` while its encounter/attempt remains owned. It never creates a reservation, delays cooldown expiry, supplies contact, permits damage or makes an old source ready early.

The original expiring cancellation table retains its existing semantics. Before expiry, its authored record must exactly match the corresponding journal record. After expiry, the journal supplies inert terminal provenance; it does not reinsert a cooldown or tombstone. Do not preserve only `ready_s`, replace provenance with a digest, or clear old history to allow rearm.

Admission must retain the exact source/script, actual Scheduler/Hero, program, fixed knot and original exchange. Cancellation must preserve its terminal record before external invalidation, hurt, failure or state observers can capture a deferred aggregate. Normal completion may seal only after every canonical event opportunity and notification has been consumed and the live pending delivery is empty. Scheduler's silent expiry alone does not prove that Playback delivered the sequence.

The implementation needs a guarded internal Scheduler/Playback terminal handshake. It must join the actual retained owner and its canonical prefix without a yield, callbacks or a temporary saveable half-record. A copied caller receipt is not enough. If the actual owner has been lost before a complete receipt can be sealed, reject aggregate capture rather than invent a completed prefix. External public `retire_authored_cycle` must verify already earned terminal provenance; it cannot synthesize a missing historical cancellation or repair a missed delivery.

Encounter/attempt cleanup retires the whole journal with its owning aggregate. A level that changes to another encounter must retain departed source history in its supported local aggregate before cleanup; calling `end_encounter` to discard a living source's cooldown/history is not a cycle operation.

## Proposed public operations

Names and signatures below are proposed, not callable APIs today.

```gdscript
# Actual Scheduler: pure native/stable view; no pruning or callbacks.
authored_source_cycle_state(owner: Node3D,
    bindings: Dictionary = {}) -> Dictionary

# Actual Playback: root-managed identity/history view, defensive copy.
get_authored_cycle_state() -> Dictionary

# Actual Playback: seal/verify its genuine terminal cycle, quietly.
retire_authored_cycle() -> bool

# Same actual Playback owner; prepares an unarmed cycle_ready state.
begin_next_authored_cycle(next_playback_id: String,
    next_sequence_snapshot: Dictionary, context: Dictionary,
    floor_regions: Array) -> bool

# Fresh, unbound actual owner only: pure complete restore preparation.
prepare_authored_restore(playback_snapshot: Dictionary,
    scheduler_snapshot: Dictionary, bindings: Dictionary,
    heroes: Dictionary, floor_regions: Array,
    projection_context: Dictionary) -> Dictionary

# Fresh owner only, paused; part of the already prevalidated parent commit.
commit_authored_restore_preparation(preparation: Dictionary) -> bool
```

The pure views must expose exact root-managed current generation, stage, original cooldown deadline and durable terminal receipts. Native weak handles/scripts are retained internally; durable transport uses independently checked stable source/Hero IDs. A native preparation object/receipt is ephemeral and rechecked against the actual same objects at commit. Copying or serializing its IDs does not turn it into a capability.

`retire_authored_cycle` is available only outside both modules' transactions at a completed deferred boundary. It changes neither source HP, generation, aggregate clock, original cursor/prefix, native source pose nor gear. Cancelled undelivered stages are archived as inert history; retirement cannot deliver them or mark damage as attempted. Complete retirement requires an empty live pending slice. Repeated retirement returns the same earned result without adding duplicate history or emitting events.

`begin_next_authored_cycle` runs only on the same retained actual owner after retirement and after the original cooldown has expired at the actual simulation clock. Ordinary execution uses an unpaused deferred boundary outside callbacks; restoration uses a separate paused boundary. It rejects dead sources, recursion, source/Scheduler/Hero replacement, a live prior lease, another damaging commitment, missing native renderer custody, or a pending live observer/damage slice. It reads actual source lifecycle through the supported native binding and never resets source HP/hit count, resources or clocks.

The next generation must be the native integer `previous_generation + 1`, within the supported safe integer range. Source ID and epoch remain unchanged; playback/sequence/reservation identities cannot reuse a retired identity. First support preserves the actual source script, immutable raw definition, fixed knot, renderer resources, encounter profile and authored world/domain. Recompute the canonical new program with that definition and generation; do not accept a new shape, position, timing, already resolved role or caller source proxy as a cycle change.

Prebuild and validate the new Program/Cursor configuration and native projection without changing the old state. Quietly commit the new managed identity and journal stage as one operation. No witness, attack, reservation, warning callback or HP change is manufactured by this preparation. Separate normal `request_authored_replay`, projected binding and actual lock still perform fresh whole-sequence proof against the current actual Player and world.

The production source hook can derive its generation from `get_authored_cycle_state`, with an explicit native initial generation before first configuration. The shared commit then updates managed generation without a source HP callback or mutating act-owned fields. The source still owns alive/HP, immutable native definition and its supported physical codec. A copied journal must not be used to change a live source hook secretly.

## Closed wire proposal and migration

Keep ordinary/captured wire untouched. The authored constructor/program remains `authored-enemy-sequence-1`; a new cycle is another immutable instance, never a mutation of the previous Program. Cursor remains its existing strict schema and validates at the appropriate original clock.

Introduce `authored-echo-playback-2` with a closed `lifecycle` field. Do not reuse `authored-echo-playback-1` to silently relax old cancellation or owner immutability checks. The new reader supports strict legacy authored API1 and new API2 separately. API1 artifacts retain their original same-clock/unexpired-tombstone meaning. Conversion requires actual retained earned provenance before expiry; an already expired legacy cancellation cannot be fabricated from copied data.

Scheduler keeps `scheduler-snapshot-1` and adds **conditional integer schema 3** only when the new nonempty `authored_source_cycles` journal is present. Existing schema1/2 keys and readers remain strict. Older readers reject schema3; parent aggregates must adopt the new reader and preserve the whole envelope. Never strip a journal or downgrade a saved source to resume it. A malformed/empty optional journal rejects rather than being normalized away.

The separately drafted pure journal codec uses `authored-echo-cycle-journal-1`, integer schema1, with exactly `{api_revision, schema_version, sources}`. Each source entry has exactly six fields:

```text
source_id, source_epoch, generation, stage, sequence, terminal_receipts
```

`stage` is `cycle_ready`, `running`, or `terminal`. The first actual generation is **1**, fixed by the supported native lifecycle; history cannot choose an initial generation to omit predecessors. `sequence` retains the complete current canonical program. Receipts are contiguous and unique from generation1. `terminal` includes the current generation as its last exact original receipt; `cycle_ready` and `running` retain all predecessors. The current live reservation and Playback pair supply a running generation's event state. No terminal receipt exists for a prepared generation that has never been admitted. A complete history cannot be reset by a copied owner ID.

The proposed Playback API2 `lifecycle` field is that same exact six-key source entry, equal to its actual/staged Scheduler journal entry. Its ordinary running/terminal payload retains the original program/exchange/current prefix fields and projection where required. It does not embed another API2 Playback snapshot inside the journal; `terminal_receipts` is the sole terminal-history list. Never translate older speculative seven-key `initial_generation/current_generation/current_stage/history` shapes into accepted bytes or recursively nest lifecycle snapshots.

These pure codec files are a separately released implementation draft outside shared28/29. Their targeted native pure-data fixture passed233/0 on a frozen original subset; synthetic histories are not actual admissions, HP ownership or native two-cycle proof. Native Scheduler3/API2 source custody, generation management and whole-parent restoration remain to be implemented and tested before shared30 is published.

### Reduced terminal receipt

Each history entry uses `authored-echo-terminal-receipt-1`, integer schema1, and exactly:

```text
api_revision, schema_version, playback_id, source_id, hero_id,
source_epoch, generation, sequence, exchange, outcome, reason,
terminal_at_s, cursor_clock_s, cursor, opportunities,
pending_delivery, cancellation
```

`outcome` is `complete` or `cancelled`. `sequence` is the original strict canonical authored program. `exchange` is the original closed exchange and adapter with exact admission/lock/deadlines/profile/world/knot/cycle. `cursor` is the original canonical Cursor snapshot, validated at `cursor_clock_s`; its prefix and opportunities must match exactly. All copied floats retain native float type and bits; IDs/generation/schema retain integer/String types. Phase/due geometry tolerances do not normalize copied identity.

For completion, `reason` is empty, `cancellation` and `pending_delivery` are empty, the full event/notification prefix is consumed, and the cursor derives complete at its real terminal clock. For cancellation, `reason` and the exact original closed authored cancellation record are required. `terminal_at_s` equals its actual cancellation time; cursor time is at or before it. A nonempty pending slice retains the original bounded contiguous suffix/stages/opportunity latches, with damaging cues cleared and no live presentation/state callbacks. It stays permanently inert. It is neither replayed nor rewritten into success.

The reduced receipt contains no lifecycle/history, no current aggregate clock, no HP/resources and no projection renderer snapshot. It licenses no rendering or damage. Historical programs/exchanges are validated by pure canonical derivation and receipt rules at their original frozen clocks, and joined to native admission/terminal custody in the actual journal. Do not manufacture a fake historical live Scheduler/Player or insert an old reservation to reuse the current live validator. Original world/profile guards remain historical data, not proof that a past attack is safe in today's scene.

### Later terminal saves

API2 keeps the original `cancelled_at_s` and frozen receipt. Its outer `clock_s` equals the current actual Scheduler/native source aggregate clock exactly and may be later. The journal licenses the original cancellation independently of the expiring table. If the current clock is before original ready time, the actual original cooldown and unexpired cancellation must still match. Once it has genuinely expired, no refreshed cooldown or replacement cancellation may appear. Exact cancellation/death time is never copied forward to the later save clock.

A completed consumer may advance only its harmless current aggregate clock; its retired terminal receipt remains unchanged. A cancelled cursor is not advanced. A dead source's codec retains original defeat time, HP0 and lifecycle, joined to its original cancellation receipt while separately joining the current aggregate clock. Merely changing `cancelled_at_s == clock_s` to `<=` without the journal is insufficient.

### Saveable cycle_ready

After successful next-cycle preparation and before fresh admission, API2 uses explicit `status = cycle_ready`. It contains the canonical prospective program, current exact aggregate clock and lifecycle journal. It has no reservation/exchange, consumed cursor, opportunities, pending damage or cancellation for that new generation. The fixed-knot renderer remains visible in its idle pose and required damaging cues are clear. The previous receipts remain untouched.

Use a closed ready envelope, not the old unsaveable idle state. Its reader rejects injected attack/lease/cursor/pending fields and verifies `new_generation = retired_generation + 1`. Admission refusal leaves this exact ready state and source HP unchanged. The source owns whether its terminal knot remains hittable while waiting; the production recipe must provide an ordinary-primary resolution rather than strand an alive invulnerable target.

## Fresh reconstruction and live-owner monotonicity

A fresh generation-1 configured immutable Program cannot accept generation 2 by weakening `restore_state`, rewriting its configuration or copying a saved source hook over it. First create a fresh native source shell with the actual authored script, raw definition, fixed knot, required renderer and immutable resource descriptors. Keep it unbound to a cycle. The new prepare method reads the saved program/journal through strict pure codecs and independently matches that data to the known source recipe, native raw definition, actual current world/domain/profile and external stable bindings.

Prepare returns a defensive candidate and validated prospective native source binding for the complete saved generation. It mutates no actual generation, HP, renderer, Scheduler, Program or prefix. `authored_owner_bindings` staging is permitted only during paused complete-aggregate prevalidation. It does not replace immutable native script/definition/knot/resource checks and is not a live owner or caller proxy. A saved generation number is not independent proof of an earlier gameplay event; the parent owns the coherent saved aggregate and progression/source recipe.

After full parent prevalidation, `commit_authored_restore_preparation` rechecks the ephemeral preparation against the same actual fresh owner, Scheduler/Hero, script, native definition/resources and paused world. It installs only the saved managed program/generation needed by the native source hook and later Scheduler commit. It delivers no event, moves no renderer, changes no HP and cannot operate on a previously admitted/live owner. The source's physical codec commits its saved HP/alive/fixed pose in this same physical preparation stage. Shared Playback's normal quiet restore then joins the actual restored Scheduler; the prepare commit is not a bypass for that check.

Prevalidate all of the following before committing anything:

1. Actual Player saved resources/timers/gear/motion and the shell/level's separate input/camera context.
2. Native source HP/alive/defeat/hit lifecycle, script/resources/fixed pose, saved managed generation and raw definition.
3. Every closed terminal receipt, source journal continuity/current stage, prospective program and native world/profile bindings.
4. Actual Scheduler saved clock, journal, cooldown/live reservation and staged actual source/Hero custody.
5. API2 Playback current state, projection/pending data and the whole staged pair. Ready and terminal states cannot license current damage.

Commit quietly in the order **actual Player and source physical HP/alive/fixed pose plus managed-generation preparation → actual Scheduler journal/state → Playback's fresh prepared Program/Cursor/state → verify native source phase/generation and renderer**. Do not equip, heal, rearm, reproof, resend warnings, deliver damage, publish defeat or reset clocks. Renderer reconstruction belongs to Playback. If an actual quiet native hook violates custody after preflight, discard the candidate aggregate and retain the prior active world; do not accept a partially reconstructed world.

Fresh reconstruction may initialize an empty managed owner from an independently prevalidated saved generation; it cannot reinterpret a live owner as fresh. Existing live owners require exactly the same actual objects/epoch and an immutable history prefix. They refuse lower/skipped generation, history omission/reordering/rewrite, state revival, prefix rewind, original-clock edits or an attempt to replace a terminal outcome. Their only supported next-generation path is the public cycle operation. A new scene instance during whole fresh restoration is distinct from cloning a living same-ID actor to evade its runtime cooldown.

This is structural/native custody validation within a trusted complete parent aggregate. It is not cryptographic or semantic authentication of a coherently fabricated past. Do not claim that a sequence digest, contiguous integers or a valid receipt prove actual human gameplay independently of the parent.

## Capacity and failure policy

Proposed first bounds are 64 terminal cycles per source, 64 source journal entries per Scheduler, and a total 1 MiB exact encoded journal. The implementation must also retain the shared finite depth/container/node budgets. Validate foreign/cyclic/object/overbudget data before deep copies. These values are proposed, not measured performance claims.

Reserve capacity before admission so every admitted cycle can retain its eventual terminal receipt. Refuse a new cycle or extra source before any lease, generation or state mutation if count/byte capacity cannot be guaranteed. Do not evict history, clear a tombstone, overwrite an old receipt, extend cooldown, heal HP or create a new same-ID owner to make room. The actual source remains visible at its truthful grounded knot. The production HP policy must allow ordinary-primary resolution when further cycles are refused; capacity exhaustion cannot leave it permanently invulnerable. Required role HP starts small and does not grow per cycle.

Keep rejection reasons and capacity observable through supported defensive diagnostics. An invalid pair, missing actual renderer/source, early original cooldown or unsupported world change fails closed with its retained history. This first supplement retains a fixed source/raw definition/profile/world across cycles; new patterns, changed physical owners and concurrent mixed commitments remain separate requests.

## Bounded rollout and new targeted evidence

1. Finish and accurately publish the first-cycle Shared28/native evidence and independent A3-L2 registration. Do not label the supplemental request resolved by that publication.
2. Implement the pure reduced-receipt/journal validator, conditional Scheduler3 and authored Playback API2/ready migration. Keep captured behavior and validators unchanged.
3. Implement native same-owner retirement/next-cycle operation and fresh prepare/quiet commit. Adapt a genuine production-style fixture codec to retain partial HP/hit count and managed generation; the one-hit first-cycle codec cannot prove that work.
4. Queue one new targeted lifecycle leaf only after all actual dependencies are frozen. Broaden only to directly affected existing consumers justified by runtime edits. The act owner then adopts the published seam in its owned full-level source/local persistence.

The new leaf must use actual retained native source/renderer, shared Player/Scheduler, fixed dry floor and real simulation ticks. Required cases:

- An actual missed or nonlethal opening, unchanged surviving HP, early-cooldown refusal, real expiry, same actual owner/script/renderer and generation 2, a fresh actual witness, and one new slash without redelivering generation 1.
- Genuine source defeat, later real aggregate ticks beyond original cooldown/tombstone expiry, exact format2 disk transport and fresh quiet whole restore of dead HP/original defeat/cancel time/frozen prefix at the later aggregate clock.
- Quiet fresh restore before expiry, after expiry, in `cycle_ready`, and in the second actual preview/lock/delivery. Native root pose/resources/cues and source phase must match; pause freezes clocks; restore emits no callbacks.
- A held genuine cancellation suffix archived inertly, including actual hurt/death or cue/event observer boundaries. No past opportunity, attempted hit or notification may be fabricated or replayed.
- Atomic refusal of float/lower/skipped generation, reused cycle/reservation identity, omitted/rewritten receipt/history/prefix, one-bit original clocks/cooldown/definition/world, a same-ID foreign object or clone, dead rearm, callback/transaction misuse, required renderer loss and overcapacity. Capacity rejection leaves the real terminal knot available and resources unchanged.

Any labelled synthetic transport/capacity negative is codec evidence only. It cannot replace genuine two-cycle/contact/HP tests. This plan adds no broad baseline repetition, whole-level route gate, portrait/human/device claim or equipment/ability allocation.

References: [authored program](AUTHORED_ENEMY_SEQUENCE.md), [first native playback fixture](AUTHORED_ECHO_PLAYBACK.md), [Playback contract](REPLAY_PLAYBACK.md), [Act 3 concept](../ACT3_CONCEPT.md), [canonical research](../reference-library/act3/research/levels.json). The canonical ignored request path is `.cinder/agent-chat/cinder-campaign/act3/messages/a40888b2-58d1-4574-a38a-1b9b824cbe67-REQUEST.json`; durable publication must record the eventual exact implementation/receipt and response separately.
