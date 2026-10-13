# Max2 event-accounting failure — read-only diagnosis

**Concrete cause:** the frozen test imposes raw `dispatch_clock_s >= scheduled`, but shared Cursor delivery and its public saved-prefix validator use the existing derived-deadline precision contract. Both actual dispatch receipts are a few floating-point rounding bits before their exact scheduled values. This makes the test's exact_events conjunction false without demonstrating a shared replay/contact/FIFO fault.

Original job `.cinder/crystalman-max2-first-native/result.json` closed with exit1, 538 frozen inputs and no original source changes. Footer at native.log:145721 reports **46 checks / 1 failure / 580 actual post-actor ticks**. The sole FAIL is at :145714; backtrace names frozen `crystalman_two_slot_rule_room_smoke.gd:233`.

| Original receipt | Slot1 | Slot2 |
| --- | --- | --- |
| Event ID | crystalman-rule/sequence-1/slot-1/primary | crystalman-rule/sequence-1/slot-2/primary |
| Record sequence | 2 (:14868) | 4 (:29689) |
| Slot ID | 1 (:14870) | 2 (:29691) |
| Exact scheduled_at_s | 4.383333333333328 (:14878) | 5.866666666666662 (:29699) |
| Actual dispatch_clock_s | 4.383333333333323 (:14875) | 5.866666666666651 (:29696) |
| Dispatch minus schedule | -5.329070518200751e-15 | -1.0658141036401503e-14 |
| contact / damage_attempted | false / false (:14873–14874) | false / false (:29694–29695) |

The two saved `READONLY EXACT TWO-SLOT EVENT` blocks start at :14771 and :29592. Event/opportunity scheduled values agree exactly (:14869/:14878 and :29690/:29699). Actual IDs, primary kind, record sequence and slot numbers agree with the two expected original FIFO events. No opportunity schema field is missing or renamed.

Frozen test source is preserved byte-exact in sealed V2 `tests/crystalman_two_slot_rule_room_smoke.gd` SHA256 `c066fc3701006b3e173cc0a6b6b4b71a5fd67fe4c08144a1f084f45c1f7de5fc`. Its :232 conjunction contains the raw `float(opportunity.dispatch_clock_s) >= scheduled` that both logged receipts fail. Shared `scripts/combat/replay_cursor.gd:80` computes exact original scheduled = timeline_origin + event.at_s; :81 dispatches using `_at_or_after`. At :299 that comparator is `clock >= deadline - TIME_EPSILON_S`. Public `Cursor.snapshot_error` at :110 uses the same comparator for the saved exact prefix at :163. The existing precision constant is inherited from Sequence (`scripts/combat/replay_sequence.gd:12`, 1e-9); no new tolerance or shared runtime retune is needed. Immutable scheduled values, actual clocks, epoch, generation, sequence and event identities remain exact.

The completed native aggregate already passed at log:145710, including original full prefix, exact opportunity equality, empty lease, quiet cues, HP/kit and retained profile. Paused completed equality and consumed GUI Resume passed at :145711–145713. The raw final lower-bound comparison is the concrete incompatible operand. The later 30-tick once-only assertion and the invalid-second-slot/rearm case occur after this failing return and were **not reached**; do not credit them to this result.

## Assessment of Root's proposed correction

Use a fresh public `Cursor.snapshot_error` on the **actual completed transport cursor**, captured as `terminal.cursor` from the strict paused leaf aggregate, with its matching `schedule.clock_s`, original encoded sequence, source_epoch and generation. Do not pass `Playback.state().cursor`: that public presentation/state dictionary omits the full transport schema/sequence keys required by the validator.

Then join each emitted event and opportunity **exactly** to that validated cursor.executed_events prefix (event_id, scheduled_at_s, dispatch_clock_s), while retaining original scheduled arithmetic, FIFO slot/record sequence/kind identity and the unchanged original late-dispatch bound. This enforces the existing native contract rather than adding a custom numeric comparator.

A defensive COPY whose prefix dispatch is set to exact scheduled minus **2 × the existing Cursor.TIME_EPSILON_S** should reject through the same public validator. Never install the altered copy, advance a clock, change the original schedule/proof or substitute a new lease. This negative case checks the existing lower-bound contract without accepting real early execution beyond its declared precision.

Root separately confirmed the recursion diagnostic comes from printing full public response.actor at frozen test:220. Erasing actor from the returned defensive diagnostic copy and recording the real instance ID follows the existing portrait pattern and keeps the remaining motion/clocks/kit operands. This source/report does not rewrite the original 252,624,484-byte log or treat its 256 recursion diagnostics as clean evidence.

No owned edits, engine/rerun, UID generation, allocation or new user thread were performed. Originals and sealed drafts remain intact. Corrected native behavior remains unexecuted at this review.
