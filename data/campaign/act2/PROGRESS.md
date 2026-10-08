# Act 2 progress

Updated 9 October 2026. **One of eight Act2 levels is canonically accepted. L2 is implemented in validation; no L2 acceptance or HANDOFF yet.** [Memory](ACT_MEMORY.md), [current L2 design](levels/A2-L2.md), [portable L2 evidence](../../../docs/acts/act2/evidence/A2-L2/README.md) and [preserved progress history](PROGRESS_HISTORY.md) separate current status from earlier failures/pending statements.

Consumed `campaign-shared-21`: publication `811f69fe542f85bc58a26fded567b89e584b51e8`, merge `5a3c4b7e80b90e340266ceac021d91432962fd7e`, ACK `d07d7584-baa0-4d6c-8a4c-775b4971969c`. Earlier L2 tests retain shared19 publication `868b2bff523e538ee093ff6ec58c09c5f2099072`/merge `3fe640ee62b35b6e0fb53c011386b3ad82983a1b`/ACK `c6999a14`. Shared22 is available; replay-only assessment found unchanged L2 dependencies/no new rerun, with consumption pending record freeze. Shared REQUESTdcc047b7 is resolved; owned Scout patches are separately attributed below.

| Level | Current state | Next requirement |
| --- | --- | --- |
| A2-L1 Horsell Common | Original candidate/first b3fb patch adopted; current 40/42 original files match | Supplemental 186/0 + affected 285/0 clean, adopted8c37b1e0/RESPONSEd810feca |
| A2-L2 Weybridge and Shepperton | Native 371/Standard 338 complete at b3fb; no final acceptance | Cargo/Assisted → freeze/HANDOFF |
| A2-L3 Black Smoke and the Ruined House | Production unstarted | L2 handoff/acceptance |
| A2-L4 Red Weed and the London Approaches | Production unstarted | L3 handoff |
| A2-L5 Dead London and Regent's Park | Production unstarted | L4 handoff |
| A2-O1 Cylinder Perimeter | Production unstarted | Main levels complete; reuse L1 kit |
| A2-O2 Clear Air Circuit | Production unstarted | O1 handoff; reuse L3 kit |
| A2-O3 Bleached Canal | Production unstarted | O2 handoff; reuse L4 kit |

## Accepted L1 provenance

Original ACCEPTED response `73244c16-dcb2-4351-a354-b13bf11a81c0` covers candidate `a96edfaddd22e206438e616a8b4080e5c5cdce7a`, runtime `16f2532518edd8d76aa41ec40f1d10edad607559`, registration `d629072f2ca2086878981ef3e19543d9a68ece41`. Current 40/42 runtime hashes match; only common Scout actor/exchange are superseded, with [old/new hashes](../../../docs/acts/act2/evidence/scout-callback-custody/index.json). [Original L1 evidence](../../../docs/acts/act2/evidence/A2-L1/README.md) retains shared13 stationary285/material40/native304/default269/Challenge269 and earlier scopes; integration132/0 headless/142/0 native is separate. Real A1-L5 prerequisite remains; synthetic prefixes do not complete Act1.

## Tested common Scout callback patch

First b3fb6854 patch is adopted 7c2fac/RESPONSE9bd47362; original 155/16 → corrected 155/0 and affected 285/0 retain scope. Supplemental required-query guard original 186/7 → corrected 186/0 and affected tracking 285/0 clean, commit `6c91833fa7f0762467348bb85c4eaae2bd0384fa`, RESPONSEc1157256 sent; canonically adopted at `8c37b1e0a514fe63fc2525c648e658d5c67334ac`/RESPONSE `d810feca-0060-428d-bcbc-28c4ab404470`. [Commands/logs/hashes](../../../docs/acts/act2/evidence/scout-callback-custody/README.md). No current full L1 route/art or final candidate/hash claim.

## Current L2 scoped evidence

These owner-run accepted logs reported clean exit0 without script/resource/exit failures. Original-art route passes retain gameplay/cue/dry-floor scope, not revised anatomy acceptance. TEST ONLY preceding prefix/unlock/profile and injected L3 destination seeds support actual shared L2 actions; no earlier/future-level gameplay or canonical acceptance is inferred. [Full inventory, exact recorded commands and historical failures](../../../docs/acts/act2/evidence/A2-L2/checks/summary.json).

| Shared21/b3fb check | Result | Established scope |
| --- | --- | --- |
| Current full native Standard/Heavy | 371/0;16 frames | Six real primary defeats/four feet/four contacts/once-clear/separate exit/cleanup and current art; before supplemental guard correction |
| Standard weapon full route | 338/0 | Actual WEAPON-01 six defeats/four feet/four contacts/clear/contact exit/cleanup; before supplemental guard correction |

| Shared19 check | Result | Established scope |
| --- | --- | --- |
| Standard/Heavy full route | 314/0 | Six ordinary-primary defeats, four HP-free true-circle/no-primary foot opportunities, four stable contacts, full locks, once-clear, separate shelter exit/cleanup |
| Standard/Heavy original native full route | 362/0;16 frames | Actual 540×1170 gameplay/cue/dry-floor views; original Handler anatomy subsequently FAILED source fidelity |
| Challenge/slow Padded+Reach full route | 320/0 | Canonical slower full primary cadence; six defeats/four feet/four contacts/clear/exit/cleanup; original art |
| Actual apron pair/death/public retry | 221/0 | Warning/lock pause, full ExactJson saved-player preflight/quiet restore, eight atomic refusals, real source death and saved resources/gear/input/profile retry/cleanup |
| Genuine pending-path aggregate | 111/0 | Schema2 whole transport/fresh preflight/quiet restore, six atomic refusals, resume once/schema1 drain, no refired hit/cooldown refresh |
| Revised Handler native prefix | 127/0;11 frames | Three real defeats, yard contact, two completed feet; all eleven current source/readability views reviewed |
| Revised Handler pose-only | 65/0 | Actual operator vertices≥ground, unchanged 1.1025m top/.944141m radius; six phases, quiet fresh restore/material isolation |

Pre-b3fb shared21 mixed 260/0 retains unaffected scope: earlier accepted 10HP damage from both sources, fatal active Handler with already-cancelled `tracking_lock_unproved` Scout, exact terminal/vector receipts and running deadlines/cooldown, four foot receipts/full fresh quiet dead restoration. No two-running-sources-at-lethal claim. [Portable completed log](../../../docs/acts/act2/evidence/A2-L2/checks/a2-l2-shared21-mixed-death-closed-receipts.log). Exact owner command:

```sh
python3 scripts/dev/dev.py engine --headless --path . --log-file .cinder/a2-l2-shared21-mixed-death-closed-receipts.log --script tests/acts/act2/a2_l2_mixed_death_smoke.gd -- --loadout=heavy --profile=standard
```

The 111-check retained circle sample is stationary after an actual arrival dash; it does not establish a nonzero moving intersection. Earlier entry22/0 and narrow Handler pair/clean audio retirement26/0 retain their isolated scopes in the inventory. Initial retry 221/0 behavior counts with native fresh-fixture teardown errors remain failed history; the clean retry supersedes only that resource symptom. Prior pending72/1 and102/1 cosmetic-barrier failures are preserved, not erased by111/0.

Current b3fb native 371 has 16 actual 540×1170 frames, all independently reviewed/root seven viewed, with no material combat-source/player/cue/dry-floor or revised Handler defect. Minor strand/beak merge, rear-support hiding and right-foot outline overlap remain. Distant tripod is heavily cropped behind topHUD/canvas; complete three-leg collapse/artillery-cause composition is undemonstrated. Original native 362 retains its anatomy failure; revised prefix 127/eleven frames and pose 65 retain their narrower scopes. [Three portable capture sets/reviews](../../../docs/acts/act2/evidence/A2-L2/README.md). No all-poses acceptance is inferred.

Quick subsequently passed 301/0 cleanly at 6c91833f/shared21; owner final promotion awaits remaining Cargo/Assisted.

## Failed variants and exact next work

Mixed-death282/1 failed an earlier apron swept-hit assertion; scoped-prefix220/1 and retained-response220/1 failed final accepted-hit/admission observation. These original variants remain failed history. Corrected 260/0 retains actual complete/prior-cancel receipts and exact vectors rather than assuming a live Scout lease. Assisted291/1 failed a duplicate clear of an already-dead crossing Scout; corrected Assisted remains pending. Raw logs/[level history](levels/A2-L2_HISTORY.md) preserve failures; root will append the latest logs to portable evidence before final freeze.

Next: remaining slow Cargo+Longstep/Assisted → final runtime/evidence/hash freeze → required validation/L2 HANDOFF. Track supplemental 6c91833f/RESPONSEc1157256 adoption. Native 371/Standard 338 are b3fb/shared21; mixed 260 remains pre-b3fb. Shared22 replay-only assessment found unchanged L2 dependencies/no new rerun; consumption awaits freeze. Current 40/42 original-L1 matching is not final all 42 preservation; no final L2 candidate/acceptance. Six later productions remain unstarted.

L1/L2 introduce no equipment type, perk, temporary powerup, reward or permanent growth. Earlier catalogue validators retain their original scope, without a new validation claim. No human recognition/balance/native-focused play/every possible pose/device performance/mobile export/release or all-eight-level acceptance is claimed. Those limitations add no human decision or mobile gate to the authorized desktop work.

Current scoped update: Cargo/Longstep Standard passes287/0 clean at Weybridge SHA `171680483795c75272d0d7e8b64a85c348d2b4b552acb92a2d3638febe694a2b`. The new derived crossing guard uses the actual accepted combined foot/Scout response with native sources, both current danger footprints and landing/attack bounds. It retains exact original source proof/witness, leases, clocks and saved fields. The broad response-context union attempt was retired; original candidate context is unchanged. The fixture approaches a cropped idle Handler with a real dash. New right-foot pause/fresh-camera restore and affected native capture remain pending; original earlier checks keep their exact scopes. Supplemental common Scout6c was adopted independently at8c37b1e0/RESPONSEd810feca, with no duplicate cherry-pick required.
