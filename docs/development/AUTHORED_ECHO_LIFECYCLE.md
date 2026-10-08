# Authored echo lifecycle

Shared33 publishes the opt-in shared support below. Original native scopes and remaining authored-level obligations are recorded separately.

The opt-in lifecycle extends [ReplayPlayback](../../scripts/combat/replay_playback.gd) and [ThreatScheduler](../../scripts/combat/threat_scheduler.gd) so one actual surviving authored source can earn another cycle after its original cooldown. It preserves that source's HP, immutable recipe, renderer/resources, actual Hero, world and full floor domain. Captured replay and strict `authored-echo-playback-1` remain separate existing modes; they acquire no journal through ordinary configuration.

## Public native contract

Configure the genuine authored program first. Before admission, call:

```gdscript
source.enable_authored_cycle_tracking(scheduler, {hero_id: hero}, floors, context)
```

`context` retains exactly `world_root`, `source_id`, `source_epoch`, `generation`, `world_collision_fingerprint` and `world_floor_signature`. The root contains the real source, Scheduler, Hero and floors. Registered sources share the same actual Hero **and stable Hero ID**, root, exact profile/world/floor domain and native floor resources. Individually valid sources with another Hero, Hero ID or ancestor root cannot join that aggregate. Actor HP/death remains owned by its native actor and full parent codec.

The source's `get_authored_echo_binding()` reports the actual base-managed generation through `get_authored_cycle_generation()`. It retains the existing authored source definition/alive/knot contract; it does not invent a new captured Player action or query historical timers as current authority.

| Playback method | Meaning |
| --- | --- |
| `get_authored_cycle_playback_id()` | Current immutable playback identity. |
| `get_authored_cycle_program()` | Defensive current canonical authored program. |
| `get_authored_cycle_generation()` | Actual managed current generation, initially one. |
| `get_authored_cycle_environment()` | Retained native `{world_root, floor_regions}`. |
| `get_authored_cycle_terminal_receipt()` | Defensive original earned terminal receipt, empty for a prospective ready/running cycle. |
| `prepare_next_authored_cycle(next_playback_id, next_sequence)` | Prepare exactly the next generation on the same living owner after earned retirement and expiry. |
| `prepare_authored_restore(snapshot, scheduler, heroes, floors, context)` | Construct one fresh paused nonplayable recipient recipe; commits no saved HP, Scheduler clock or history. |
| `get_authored_cycle_restore_recipe()` | Distinct construction-only `{playback_id, lifecycle, terminal_receipt}`; never an earned receipt getter. |

Scheduler exposes `begin_authored_cycle_tracking(owner, sequence, hero, hero_id)`, pure defensive `authored_cycle_state(owner)`, `seal_authored_cycle(owner, receipt)` and `prepare_authored_cycle(owner, next_sequence, next_playback_id)`. Playback coordinates these; callers must not split the earned Scheduler preparation from its immediate Playback identity commit. `seal_authored_cycle_cancellation(id, reason)` is an internal silent Scheduler-to-owner handshake, not a public mechanism for fabricating past admission.

## Ready, running and terminal state

Initial `cycle_ready` has generation one, an immutable prospective program, empty terminal history and no current exchange, opportunity or admitted event. Normal request/bind then acquires the actual exclusive authored reservation and full warning/lock proof. Running delivery retains the existing exact event contact, dispatch grace, once-only opportunity and synchronous callback guards.

Completion seals the actual original exchange, frozen Cursor and consumed opportunity prefix before terminal observers. Cancellation first commits the actual tombstone and releases the lease; the internal owner handshake derives the closed receipt from that actual raw tombstone and seals it before invalidation observers. Failed sealing leaves an unsaveable/fail-closed unit, not reconstructed historical authority.

Terminal Cursor clocks, opportunities and any inert pending suffix stay at their **original** values while the outer Scheduler clock advances. Automatic terminal/ready physics skips delivery scans. Explicit capture, restore and preparation still validate current native custody. Before cooldown expiry, the terminal save retains the exact actual cooldown and, for cancellation, original tombstone. After expiry, neither table entry is synthesized; the original durable journal carries history. A missing unearned cancellation cannot be repaired by copying history.

Next preparation requires the same surviving owner, original receipt, earned recovery/cooldown expiry, truly absent prior live tables, contiguous generation and fresh sequence/playback IDs. It retains original HP, Player resources and renderer guard/resources. Detached inert cues are staged; accepted identity changes commit without callback/yield, then old genuinely clear cues retire quietly. Refusal preserves prior native state/history. Death prevents admission or another preparation. A truthful dead `cycle_ready` may persist with only predecessor history and no invented receipt for its prospective generation; the parent authenticates actual HP/death.

Managed history cannot be erased by `begin_encounter`/`end_encounter` or legacy reconfiguration. Whole parent retirement/replacement is the supported encounter reset; freeing/replacing one owner is not permission to rebind its earned identity to a clone.

## Closed transport and fresh restore order

Managed Playback uses **`authored-echo-playback-2`**. Ready saves have the closed 12-key shape declared by `CYCLE_READY_KEYS`; they contain the current program and lifecycle, with no fabricated exchange/Cursor/opportunities. Non-ready saves preserve the original delivery fields plus `lifecycle`. Conditional schema 2 adds a genuine `pending_delivery`; schema 3 adds the exact projected plan and any pending suffix. Copied clocks, IDs, generations, profile, geometry and history preserve exact scalar types/bits, including signed zero. Existing epsilon is confined to derived timeline/contact arithmetic, not copied-state equality.

Scheduler uses conditional **schema 3** only for a nonempty `authored_source_cycles` journal. Ordinary schema 1 and strict authored API1 schema 2 retain their existing shapes. [CycleJournal](../../scripts/combat/authored_echo_cycle_journal.gd) has a closed three-key envelope and six-key source entries: `source_id`, `source_epoch`, `generation`, `stage`, `sequence`, `terminal_receipts`. It requires complete contiguous original receipts, globally distinct retired identities, one stable Hero, a fixed source recipe/profile/world, at most 64 sources and 64 generations per source, and bounded transport/capacity. [TerminalReceipt](../../scripts/combat/authored_echo_terminal_receipt.gd) validates its closed 17-key reduced original packet, including exact cancellation and inert pending data.

Fresh restoration occurs under a paused whole-parent candidate barrier:

1. Purely prevalidate saved Player, complete source physical/recipe codec and whole Scheduler journal against actual fresh scripts/resources/world/floors and staged true source binding.
2. `prepare_authored_restore` installs only the validated immutable saved-generation recipe and native bindings. The recipient remains nonplayable. Complete paired Playback preflight follows before physical/history commit.
3. Quietly commit actual Player, source HP/death/physical state, then the whole Scheduler.
4. Use `snapshot_state_for_authored_restore(owner, bindings)` only for the paused intermediate pair check. It validates the distinct native prepared recipe against the already committed actual journal; normal capture, admission and sealing never use that fallback.
5. Restore Playback, exact frozen Cursor/prefix and native presentation quietly. Successful final commit removes the construction recipe; earned terminal getters then reflect the restored whole unit. Failure requires whole recipient disposal, not partial healing or retry with a new baseline.

Existing instances cannot rewind generation/history, replace the current immutable program/world/resources, revive a dead source or downgrade the mode. The full original aggregate floor binding is required; this first contract does not support arbitrary saved floor subsets.

## Cancellation inside a Cue callback

A notifying Cue can reject immediate `clear()`. Managed cancellation conceals its actual dangerous meshes immediately and retains an unsaveable native cleanup receipt. After the callback stack unwinds, guarded deferred cleanup rechecks exact source/Cue/child/resource/mesh/material/pose/policy custody, clears quietly with signals blocked, and restores only a harmless clear container. It does not replay observers, rebaseline the renderer, alter the sealed receipt or drain the inert suffix. A lost/mutated/disposed source or Cue stays concealed and faulted. Capture and next preparation remain unavailable while cleanup is unsettled.

## Evidence and limits

The new [native lifecycle fixture](../../tests/authored_echo_lifecycle_smoke.gd), [actual source](../../tests/fixtures/authored_echo_lifecycle_actor.gd) and [whole native codec](../../tests/fixtures/authored_echo_lifecycle_native_codec.gd) passed **557 checks / 0 failures**, exit0 with no native/script errors, on103 byte-verified original sources. Recorded scope is a default-kit same-owner HP32→12→0 route using two real shared primaries, original native cooldown expiry, 12 inert completed ticks, late-dead fresh restoration, native callback cancellation/concealment and held delivery/quiet restoration. Initial zero blast ammo may regenerate naturally; the ordinary route uses no blast and no post-admission resource forcing.

The earlier **233-check pure codec** result covers structural receipt/journal controls; it is not actual two-cycle gameplay. The two-source positive native control establishes registration/capture, not fresh multi-source restoration. History negatives principally exercise pure paired preflight; default-kit two-cycle coverage is not a legal-extreme two-cycle claim. Dead-ready persistence is supported but not independently exercised by this fixture. Existing first-cycle kit evidence retains its own attribution.

Native parent custody and these exact joins establish supported runtime/save behavior; the pure codecs do not cryptographically authenticate arbitrary modified historical whole saves or police parallel custodians. No authored A3-L3 acceptance, production art, portrait input, human playtest, campaign completion, sustained performance or mobile result follows from this dependency fixture.

The separately frozen [restore-input controls](../../tests/authored_echo_restore_input_smoke.gd) pass65/0 clean: initial real ready-generation-one packet only, fresh native hook cycle/Object/overbudget/NaN refusal and same-recipient recovery, genuinely freed Hero refusal, and nested public commit/tracking attempts during the actual Scheduler registration getter. These prove the later shallow-envelope/input-validity/managed-gate repairs; the earlier557 source is retained exactly and receives no retrospective execution credit for those repairs. The test subclass intentionally has no production codec2 physical-restore authority.

Directly affected captured475/0, API1 authored312/0 and ordinary snapshot35/0 compatibility checks closed cleanly; pure terminal/journal233/0 remains a separate structural scope. [All six original source/log/closure scopes](evidence/shared33-authored-echo-lifecycle/index.json), indexSHA `2675983cb30c96c30599ba90eb4901274cc6dbc05ad231fa5ee43714a7321743`, preserve469 original sources and496 indexed artifacts. New named targets and generated UID import receive no prior native execution credit. Shared32 measured runtime cost remains open.

Queued named targets added after those original runs: `python3 scripts/dev/dev.py test authored_echo_lifecycle`, `authored_echo_lifecycle_codec` and `authored_echo_restore_input`. Their original runs used the canonical engine wrapper directly; the later target registration is not retroactive execution evidence.

[Separate generated-metadata import and custody](evidence/shared33-resource-metadata/index.json) retains original UID bytes and the full later import log, with no prior gameplay credit.
