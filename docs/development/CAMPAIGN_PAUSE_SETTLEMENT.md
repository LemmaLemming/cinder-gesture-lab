# Campaign pause settlement

**Published in campaign-shared-27 with independent A3-L2 registration.** Production A3-L2 registration exposed a save ordering defect in the shared Shell: pausing at a deferred whole-tick drain could enqueue quiet native source settlement, then capture before that settlement ran. The stored unit was internally valid but differed from the later settled paused live unit. This note describes the narrow shared ordering repair, not A3-L2 acceptance or a new snapshot format.

## Exact closed reproduction

The integration-owned `tests/act3_l2_registration_smoke.gd` uses the actual production Shell and the exact A3-L2 handoff runtime (subsequently accepted independently), real routed movement and genuine first-source fatal contact. Its initial 0.1 HP/zero-ammo and eleven-predecessor prefix are disclosed TEST ONLY seeds; neither run is a full authored route-clear or human input proof.

| Closed run | Observed result | Original receipt |
| --- | --- | --- |
| `.cinder/act3-l2-registration-run1.log` plus separate full wrapper | Session 36721, exit 1, 265 checks/2 failures | 148 files; manifest `d0a04136f15d438c3dee02e89d683a7ee65abe3b79cf972c04d12296777007c0`. |
| `.cinder/act3-l2-fatal-run2.log` plus separate full wrapper | Session 93126, exit 1, 88 checks/2 failures | 148 files; manifest `da6ad7883e1dde9466f545762e561696d4d98516b7ffbdf785bc1c943aad32d4`. |
| `.cinder/act3-l2-fatal-run3.log` plus separate full wrapper | Session 62179, exit 0, 179 checks/0 failures | 148 files; manifest `5afaea9bd906b27ff7ce12083468db662a2d0c4b26b38b85fa9b3cfe66275b02`. |
| `.cinder/act3-l2-registration-portrait1.log` plus separate full wrapper | Session 26131, exit 0, 367 checks/0 failures | 148 files; manifest `e4e95a38c56e970ac26be094344025f5951ee697e199d70141a1ea713b17064d`. |
| `.cinder/act3-l2-fatal-portrait1.log` plus separate full wrapper | Session 62731, exit 0, 188 checks/0 failures | 148 files; manifest `4a497670f454cb5e1607b0bcd4c7a2a741117857ceeec0fbfc9aecc3e4175cc6`. |
| `.cinder/pause-settlement-barrier-run1.log` plus separate full wrapper | Session 47291, exit 0, 116 checks/0 failures | 119 files; manifest `71b174a64e6d9e37492bda1d312923d66dbdd5956879d6f5ef1906170692dd3a`; directly affected shared pause fixture, not an authored route. |
| `.cinder/pause-settlement-shell-run1.log` plus separate full wrapper | Session 48455, exit 0, 52 checks/0 failures | 86 files; manifest `a09a1b3dd8e9b71edc3a7aa3450c79bf467a54d4af60a55ba7e58e34898ef23d`; directly affected shared Shell TEST ONLY live fixtures, not a production level route. |

The integration owner verified every frozen original/current subset at actual closure. The [portable root registration pack](evidence/act3-l2-root-registration/index.json) preserves separate complete source receipts, native/wrapper outputs and original portraits, independently from the shared27 authored Echo archive. Neither failed run is accepted passing evidence. No active run is packaged or credited here, and independent target counts are not combined into one invented suite.

The diagnostic isolates this saved/live mismatch:

```text
unit.level.local.sources.l2-priority-stalker.actor.previous.clock_s
settled paused live: float64 bits abbbbbbbbbbb0b40 (3.4666666666666592)
persisted unit:      float64 bits 0000000000000000 (0.0)
checkpoint=same; disk=true; progress=true
fresh Continue: callbacks=[]; restores the stored 0.0
```

The earlier living checkpoint remained equal. Exact format2 disk data agreed with the captured unit, and progression agreed too. Fresh Continue emitted no gameplay callbacks and restored the **actual stored** previous sample. The two failures came from comparing that stored unit with a later settled paused sample, not from float rounding, a fabricated death, an altered checkpoint, restore event replay or save transport changing bits. Both original failed assertions remain preserved.

## Why one deferred drain was insufficient

The original [Shell](../../scripts/campaign/shell.gd) `_drain` set `_draining`, paused the SceneTree and cleared gestures, then immediately executed its existing operation/save loop. In the archived source this pause occurs at line 193. Pausing propagates `NOTIFICATION_PAUSED` synchronously. The actual [Sunbound Stalker](../../scripts/acts/act3/sunbound_stalker.gd) responds to a genuinely dead Hero by queuing `_settle_paused_hero_death.call_deferred()`.

That source settlement runs outside its damage transaction, without another contact or physics step. It updates the retained lease/phase and `_sample(_clock())`, including previous source/Hero positions and `previous.clock_s`, then presents quietly. A later source whose final physics callback was skipped by pause can therefore still need this deterministic bookkeeping. With the old Shell order, the save completed before that queued settlement; the deferred callback then changed the paused live unit after persistence. A paused SceneTree alone did not prove that its queued quiet settlement had completed.

Godot 4.7 documents that deferred calls drain during idle time, including calls queued by other deferred calls in the same idle cycle; calls made on the same thread execute in their scheduling order. A deferred call is not inherently a delay of one simulation frame. [Official `Object.call_deferred` documentation](https://docs.godotengine.org/en/4.7/classes/class_object.html#class-object-method-call-deferred), lines 567–579, supports the ordering used here.

## Two private queued phases

The root implementation splits the existing drain into:

1. `_drain`: latch `_draining`, pause the actual tree and clear the gesture chain. Pause notifications queue their quiet settlements. Keep `_draining` true and schedule `_commit_drain.call_deferred()` after those already queued callbacks.
2. Quiet native settlement: finish the final real tick's sampled contact history/phase without new movement, attack, damage, public observer delivery or simulation-clock advancement.
3. `_commit_drain`: execute the unchanged queued operation loop against the settled paused aggregate. Preserve the existing `_perform`, failed-operation retry/error menu, validation-candidate disposal, draining release and conditional deferred Resume behavior.

This adds one private queued phase within the same idle drain. Input and simulation remain latched across it. It does not wait for another physics tick, resample a held attack as a new opportunity, normalize clocks, or add a frame-driven healing pass. New operations cannot start a competing drain while the existing `_draining` latch remains true.

The repair changes no public Shell/level method or signal signature, actor/Scheduler/level snapshot wire keys, API revisions, schema numbers, format2 exact transport, campaign progression, or Player gestures. The parent still validates the complete saved Player/level/source/Scheduler aggregate before applying it, then restores actors and controllers in their existing quiet order. Quiet settlement makes the chosen capture point stable; it is not authorization to replace native actor proof with a guessed snapshot.

## Consumer migration and limits

Act consumers keep their existing public Shell checkpoint/pause/fatal routing. Do not bypass it with a direct capture/save from a damage/cue callback, force another physics tick to make samples agree, skip previous-contact fields, weaken exact equality, or invent new stored clocks. Consumers that already perform the bounded same-thread quiet pause settlement retain it; this ordering moves persistence after that work without moving actor ownership into Shell.

A settlement callback must finish its deterministic quiet state before returning. This single continuation is a bounded ordering seam, not a generic quiescence loop for arbitrary background threads or newly nested asynchronous continuations. Future code that queues additional work beyond the retained settlement ordering must be assessed through integration rather than silently assuming the save waits for it. The source's genuine HP/death and consumed contact remain authoritative; no movement, resource grant, healing or event replay is permitted during settlement.

Integration is the help contact for this shared barrier and the A3-L2 diagnostic. Root owns the narrow Shell patch and its directly affected native queue; the act owner retains its authored source files and placement. No act rewrite, changed actor schema, new level-author acceptance gate, broad/unchanged-level rerun, human/mobile prerequisite or release work follows from this note.

## Validation status

The original **265/2 and 88/2, both exit 1**, remain preserved failure history. The narrow patched Shell `194e607221b4dfc1385dc3d4534171a5fef34c64a28953c09649bbd6e8a53b21` passed the actual focused fatal branch **179/0**, default graphical registration **367/0**, and focused fatal graphical registration **188/0**, each exit 0 with clean complete native/wrapper outputs. Root personally viewed all eight original 540×1170 default/fatal PNGs. The existing directly affected shared pause target independently passed **116/0**, exit 0, with its own 119-file receipt; it is not another authored level route. The directly affected existing Campaign Shell TEST ONLY live fixture independently passed **52/0**, exit 0, with its separate 86-file receipt. These closed observations support the documented pause-settlement repair on their exact working-source subsets.

The actual tested kernel contains unpublished shared27 draft code plus that Shell change; published shared26 `c0816fb9ed60caaac36e5e1320ab95d42589e0b8` is only the prior baseline, not the tested byte identity. The original per-run receipts define the exercised sources. No C52 authored consumer/API publication, full A3-L2 route-clear, native-human/mobile or campaign completion is inferred. Additional active targets and integration acceptance stay pending their own observed closure/review. Packaging and this documentation update ran no engine or Git operation.
