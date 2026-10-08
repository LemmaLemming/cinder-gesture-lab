# Shared replay capture retirement gate

`scripts/combat/replay_capture_gate.gd` implements `replay-capture-gate-1` as a bounded `Node3D` parent custodian for one actual shared Player and one authored encounter/attempt epoch. It owns a private `CinderActionCapture`. Preparation takes no historical capture, caller clock, source actor snapshot, path, action record or geometry as authority. The gate drains its bound actor's actual defensive publication history before advancing to that actor's actual simulation clock.

This module retires recording slots and publishes the unchanged sequence. It does not prove a safe response, reserve scheduler hazards, bind playback, execute attacks, grant damage authority, or complete a boss encounter. Consumers still require the published [sequence](REPLAY_SEQUENCE.md), [playback](REPLAY_PLAYBACK.md), [witness](REPLAY_WITNESS.md) and [scheduler](REPLAY_SCHEDULER.md) contracts.

## Ownership and live ordering

The encounter parent creates exactly one gate for its recording domain, adds it to the actual actor's World3D, and binds it at a paused deferred actor barrier. The gate supports the exact shared `scripts/player.gd` script; arbitrary compatible methods or substituted actors are rejected. Owner ID, actor ID and epoch are immutable, nonempty bounded authored identifiers. They identify the parent relationship, not an equipment ability or a new capture resource.

Only this gate may authorize retirement for that domain. The parent must not construct parallel gates, reconstruct historical samples, privately mutate the bound actor/gate, manually invoke node physics processing, or use raw Capture/Sequence JSON as an alternative retirement authorization. This is an explicit integration ownership contract, not a cryptographic claim that arbitrary modified save files establish provenance.

`arm` requires a living grounded stopped actual actor with no movement/attack/knockback commitment, buffered movement or pending weapon. This preserves ActionCapture's stable arm boundary. The gate's signal listener ignores the caller-visible signal argument and instead drains the bound actor's authoritative history in sequence order; nested actual action publications are therefore handled in FIFO order. Its physics priority is 2000, after the shared Player. The normal scene tree pause freezes both; a parent choosing custom actor processing must preserve the same ordering.

At a paused deferred barrier, `prepare_sequence` builds the entire currently configured one/two-slot sealed generation. An incomplete two-slot recording cannot supply a one-slot subset. Preparation preserves every original world route and actual action. The proposal binds the exact full frozen actor snapshot and current private capture. Real clock advancement invalidates the proposal without consuming the capture; the parent may prepare again from the new current barrier.

`consume_sequence` accepts only that exact current private proposal. It stages all FIFO `take_next` operations, commits all selected slots plus retirement receipt, and only then emits `sequence_retired`. Reentrant consume, prepare, arm, capture or restore calls reject while the callback runs. Returned sequence/receipt and signal arguments are defensive copies. Rejected malformed, unsealed, altered or stale preparations consume nothing. Explicit `cancel` visibly closes a recording generation; it does not mutate player cooldowns, resources or actions. Later rearming creates a new monotonically numbered generation and retains the most recent consumed sequence and receipt.

## Public API

```gdscript
configure(owner_id: String, actor_id: String, actor: CinderPlayer, source_epoch: String) -> bool
arm(max_slots: int) -> bool
synchronize() -> bool
prepare_sequence(sequence_id: String, authored: Dictionary) -> Dictionary
discard_preparation() -> bool
consume_sequence(sequence_snapshot: Dictionary) -> Dictionary
cancel(reason: String) -> bool
state() -> Dictionary
retirement_state() -> Dictionary
snapshot_state() -> Dictionary
snapshot_error(snapshot: Dictionary, saved_player: Dictionary) -> String
restore_state(snapshot: Dictionary, saved_player: Dictionary) -> bool

signal sequence_retired(sequence_snapshot: Dictionary, retirement: Dictionary)
signal gate_failed(reason: String)
```

`prepare_sequence` returns the canonical ReplaySequence snapshot or `{}` with `last_error`. `consume_sequence` returns `{accepted, reason}` on rejection, or `{accepted: true, reason: "", sequence, retirement}` after complete retirement. The receipt contains `sequence_id`, `generation`, `slot_ids`, `clock_s`, and the original frozen `actor_sha256`; its public getter also supplies `owner_id`, `actor_id`, and `source_epoch`. `state` is a defensive diagnostic, not a restore envelope. `last_error` and `last_snapshot_error` explain failures. No caller-supplied clock advances this gate.

`accepted: true` establishes complete retirement only. After all `sequence_retired` callbacks, the gate requires its same bound actor to remain live and paused, captures the actual full player snapshot again, and compares it exactly with the frozen pre-callback unit. Damage, equipment changes and started/buffered dashes therefore fail even when no completed world action has published. On any changed boundary, retirement remains committed, `reason` reports the failure, and `gate_failed` emits before the gate releases its transaction guard. Reentrant gate operations remain blocked during that failure callback. The parent must cancel that consumer visibly; it cannot roll retirement back or treat this response as playback safety authorization.

The authored preparation dictionary follows ReplaySequence exactly: positive bounded `recognition_s`, `warning_s`, `locked_lead_s`, `inter_echo_gap_s`, `final_recovery_s`, and native `tether_position: Vector3`. Those authored timings and tether do not authorize replacing any captured action or path.

## Exact paused aggregate restoration

The snapshot schema contains gate revision/version, immutable owner/actor/epoch, exact actor clock and full-player hash, private capture, optional prepared sequence and actor hash, optional original consumed sequence and retirement receipt, monotonic retired-generation watermark, and visible cancellation reason. It stores no duplicate authoritative player unit. It keeps at most two current slots and one most recently consumed sequence. The source history remains the actual Player's bounded public history.

Use the public [ExactJson transport](SHARED_CONTRACT.md) and the campaign's complete paused saved-player unit. Plain decimal JSON may change clock bits and is not supported for this exact aggregate. Hashes are deterministic bindings to exact native JSON values and scalar types; they are not signatures.

The encounter's aggregate validator calls `snapshot_error(gate_snapshot, validated_saved_player)` on a fresh configured candidate while the whole scene is paused and outside actor callbacks. Validation checks the complete saved-player schema, exact full player digest, epoch/clock/cursor, canonical sequence derivation, complete FIFO receipt, and retirement watermark before commit. Every reusable unretired action must exactly match an actual entry in that saved Player's history; rolled-off unretired samples fail closed. Consumed historical records may outlive that history because they confer no new admission.

After all other aggregate units validate, restore the actual Player first. Then `restore_state` independently revalidates and requires its actual bound player snapshot to equal the supplied saved player exactly before committing private capture state. Restoration emits no sequence, cancellation or action and does not retime deadlines. An existing gate with a recording generation permits only an exact idempotent restore; it cannot rewind to a pre-consumption envelope even when the actor clock is unchanged. Retry of an earlier complete checkpoint is the trusted parent’s separate whole-unit candidate replacement, not a live-gate rewind.

No leaf can prove that a caller-supplied complete historical player+gate save belongs to the current campaign attempt. Fresh candidate restoration is therefore available only through the owning parent's independently validated whole-unit save/retry operation. It must replace the entire old unit, retain checkpoint retirement coherently, and never mix old recording state with a refreshed player. Reusing an old pre-consumption save as an ordinary live prepare call is unsupported and has no gate API.

## Failure and scope limits

Lost publication continuity, rewound actual clock, stale actor, or actual publication during a gate transaction fails closed. `gate_failed` requests visible parent cancellation at a deferred paused barrier. Capture never fabricates a missing history record. Existing captured samples cannot be reused after complete retirement; explicit later recording generates new slots from later real actions.

This leaf does not bind an authored Crystalman parent, checkpoint save store, Echo actor, cue, scheduler or damage dispatcher. Those owners must integrate the sole-custodian contract and independently validate the physical replay/whole sequence. This fixture cannot establish campaign fairness, safe escape, whole-encounter viability or actual portrait presentation.

## Targeted validation

The new `tests/replay_capture_gate_smoke.gd` uses actual shared Player dash, primary and optional blast calls and actual physics completion, including a real wall-shortened dash and nested primary publication. It checks complete one/two-slot FIFO retirement, callback reentrancy, forged proposal rejection, consumed retry preservation, pure staged saved-player context, quiet exact aggregate restoration, actual mid-dash restoration, pause, and stale proposals after real clock advance. Additional real callback controls change HP, start or buffer a dash, equip a legal weapon, unpause, or queue the bound actor for deletion without publishing a completed world action; all retain retirement and block reentrant operations during visible failure. It never emits fabricated world-action records.

Run only the leaf through the shared queue:

```sh
python3 scripts/dev/dev.py test replay_capture_gate
```

Final targeted evidence: Godot 4.7.2 `ed1daf0bf`, **112 checks, 0 failures**, exit 0, `.cinder/replay-capture-gate-boundary-second.log`; native engine log `.cinder/replay-capture-gate-boundary-second-engine.log`. The full frozen actor/live/paused callback guard, six actual no-publication mutations and `gate_failed` reentrancy controls passed. The headless process emits the existing macOS CA-certificate startup diagnostic at `platform/macos/os_macos.mm:1035`; there are no script or fixture runtime errors.

The final command used the shared queue with an absolute engine log path:

```sh
python3 scripts/dev/dev.py engine --headless \
  --path '/Users/howardchen/Documents/ChatGPT/video game idea' \
  --script tests/replay_capture_gate_smoke.gd \
  --log-file '/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/replay-capture-gate-boundary-second-engine.log' \
  > .cinder/replay-capture-gate-boundary-second.log 2>&1
```

Preserved prior evidence: 69/0 exit 0 in `.cinder/replay-capture-gate-guard-final.log` preceded the full-actor callback guard. Earlier 63/0 and 64/0 leaf runs preceded the callback-publication guard. An intermediate paused fixture setup failed because fresh actors had not physically settled before arming. The first full-actor guard run was 112/7 exit 1 in `.cinder/replay-capture-gate-boundary-final.log`: six comparisons incorrectly sent native Vector3 history into the closed JSON codec, and the existing optional-blast setup depended on render/physics await counts for its deadline. The corrected fixture compares public canonical player-record encoding exactly and calls the actual primary then actual blast inside the actual combo window, retaining ammo cost, publication/history and footprint checks. No production guard, clock or assertion was relaxed. No broad suite, physical playback or whole encounter was run for this leaf.
