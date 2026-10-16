# Crystalman captured Assisted policy audit

Captured Crystalman currently omits both Assisted raw-damage reduction and outer windup/recovery scaling. Enemy-authored Echoes already resolve those multipliers upstream. A blanket Playback multiplier would double-scale their damage. This is a source-only finding, not a new native run.

## Actual path

1. `player.gd:507–525` records producer equipment-resolved primary/blast damage and original equipment/stats. Its validator at942–952 requires those same damage, geometry and timing values. There is no difficulty conversion in this calculation.
2. `replay_capture_gate.gd:98–128` reads actual bound Player history; `action_capture.gd:38–75` encodes and duplicates those records. Gate138–159 constructs Sequence from the actual complete capture; Gate409–420 independently regenerates its exact original contents.
3. `replay_sequence.gd:125–151` copies original records into their FIFO timeline with original relative action durations and routes. Crystalman supplies its fixed outer recipe at353–355, then configures actual Playback at384–388.
4. `threat_scheduler.gd:345–377` validates/proves the captured plan, copies it into one exclusive lease and tags its actual profile. It does not resolve damage. Its423–432 deadlines are direct plan-derived sums, including after real lock408–418. `replay_witness.gd:37–65` preserves captured/authored provenance; no damage multiplier is introduced by the witness or projection.
5. `replay_cursor.gd:78–90` copies original due events. Playback346–358 reconstructs the same original plan event, then310–331 commits the attempt before callbacks and passes **record.damage** directly to Hero. `player.gd:396–403` checks death/invulnerability and uses `equipment.gd:125–126`: damage/recipient-current-armour. Thus current captured contact is D/A, including Assisted; it is not0.70D/A.

In contrast, `authored_enemy_sequence.gd:530–555` calls `Difficulty.resolve_role(raw_role, profile)` and places **resolved.damage** in the enemy action; authored warning is resolved windup minus lock and recovery is resolved recovery. Difficulty84–94 applies0.70 and1.35 once from immutable raw values. Authored validator138–157 independently reproduces and binds that definition/profile/programme. Playback116–129 uses that distinct validated programme, `_authored()`950–951 checks its actual API, and managed cycle tracking1386–1405 requires the same authored configuration. Shared delivery326 therefore correctly applies no second scale. The two functions called `_authored` have different roles: Crystalman constructs outer timing; Playback recognizes validated enemy-authored provenance.

## Outer budgets and profile lifetime

Crystalman353–355 and codec287–288 require recognition0.25, warning1.3, locked lead1.5, two-slot gap1.0 and final recovery3.5 for every profile. Sequence151 and Scheduler423–432 use them unchanged. Assisted currently has outer total windup2.8 and recovery3.5. The exclusive lease (`threat_scheduler.gd:435–443`, witness37–53) already allows only one compound replay, including recovery, with sequential slots; that is consistent with Assisted cap1 and does not need another concurrency change.

Fresh phase266–276 reads Shell preference once. Scheduler92–108 refuses a second begin while live. Restore829–843 constructs from **saved** profile; codec52–64 requires the exact canonical full Scheduler profile, and Playback591 joins the exchange to it. Shell883–898 stores a changed preference separately for the next fresh boundary. Do not introduce live retuning at join, rearm or dispatch.

## Smallest compatible option

Add an explicit **fresh captured-phase policy revision**, retained from gen0, and one opt-in **captured Playback policy/API branch**. This requires shared Playback kernel support: current configure has no policy parameter, native Crystalman guard requires the exact shared Playback script, and current strict codecs reject any added field or changed recipe. A parent-only multiplier or changed `_authored` is insufficient.

For new phases only, bind policy to the canonical frozen Scheduler profile. Preserve the original action records and Sequence bytes; at actual damage dispatch pass D*0.70 to Hero only for the explicit new captured Assisted policy. Recipient armour remains the existing later division. Standard/Challenge remain factor1; enemy-authored Echo never takes this extra branch. Preserve existing pending present/damage/notify commitment and once-only callbacks.

For outer timing, resolve **total** reference windup `(1.3+1.5)*1.35`, retain lock1.5 and derive warning as total minus lock. Nominal Assisted becomes total3.78/warning2.28/lock1.5, recovery4.725. Keep recognition0.25, gap1.0, capacities1then2 and all recorded route/geometry/order/durations/relative spacings. These are proposed decimal arithmetic values, not measured native scalars. Use identical deterministic expressions in writer and validator, with normal native proof/framing validation. Multiplying warning1.3 alone would produce total3.255 and underapply the documented1.35 total-windup policy.

**Legacy includes unjoined saves.** Old captured API2/schema2 settling or recording packets have no Playback yet but must still finish with their original full-damage/fixed-budget policy. Dispatching only existing Playback snapshots by version misses this case. Old API2 must construct legacy policy before any later join, even for saved Assisted. Old active and pending-damage packets likewise retain original delivery; pending-notify never redelivers. Preserve exact old configuration/BASE_SHA marker, closed old Playback schema1/2/3 branches and literal original saved wires. New policy needs an explicit closed new captured child identity/policy branch and strict profile/policy joins; no inference from missing keys, current preference or source-file hashes.

The whole parent local1 already delegates to the entitled actual CapturePhase (`crystalman_parent_codec.gd:52–62`) and recaptures the exact whole pair after quiet Hero-first restore119–127. A compatible nested API dispatcher can preserve that parent envelope and existing opaque spent-phase receipts; do not rewrite completed historical receipts or their original hashes. Shared kernel/codec implementation and native validation remain necessary.

## Existing tests and proposed focused checks

Named captured Playback test installs Standard at937 and asserts original full damage100,158,400. Crystalman two-slot257 asserts exact once-only events with no Hero contact; this does not test Assisted damage. The named authored Playback test uses Standard313. Scheduler profile29–47 verifies0.70/1.35 and noncompounding pure resolution; it does not exercise captured contact. No scoped test was executed during this audit.

A small new fixture should cover fresh Assisted actual primary/blast contact with non1 recipient armour; Standard/Challenge controls; enemy-authored Assisted contact proving one0.70; both capacities' deterministic outer timing and unchanged original action wires; literal old Assisted gen0/recording plus pending-damage exact fresh restore/recapture and later full-damage delivery; new Save/disk Continue/opposite preference/Retry/cleanup; atomic refusal of malformed policy/API/profile/type/sequence and old/new downgrade. Reuse unchanged safety and original failed evidence. No full route, all enemies, exit, export or human balance gate.

All exact named-source pins and line anchors are in AUDIT.json and named-pins-before/after.json. No production, worker, engine, Git, registry, acceptance or ledger changes were made. This policy audit does not block the independent A3-O3 owner/frozen work.
