# Bounded storage recovery plan

Read-only audit at 2026-10-14T03:27:51.655785+00:00. Only this report was written. No worker, engine, archive, lock or Git mutation was performed.

## Immediate candidate

Clone the four exact immutable PNG groups below into the listed CLOSED-job bank members, retaining every original path, byte and metadata value. This is an evidence-storage change, not deletion of failed/successful history. Root must confirm owner custody before acting on act checkouts; closure receipts do not prove absence of a later reader.

| Scope | Banks | Files | Logical bytes | Sum st_blocks × 512 | Modes |
|---|---:|---:|---:|---:|---|
| act1 | 34 | 136 | 228,108,312 | 228,253,696 | 0o644 |
| act3 | 60 | 240 | 402,544,080 | 402,800,640 | 0o644 |
| root-profile | 1 | 4 | 6,709,068 | 6,713,344 | 0o644 |
| root-pair | 1 | 4 | 6,709,068 | 6,713,344 | 0o644 |

**Allocation qualification:** these sums are observed per-file allocated-block counts, not exclusive physical extents or guaranteed reclaim. APFS clones/snapshots may already share or retain blocks; only a small executed pilot and volume free-space observation can establish useful recovery, and concurrent activity limits causal attribution. All checked targets are regular non-symlink files, nlink=1, distinct from the retained source inode and on the same device. Exact current byte hashes were verified; execution must revalidate inode/size/mtime/hash and capture target owner/xattrs/mode before replacement.

## Retained counterpart and exact member suffixes

Append each `assets/acts/act3/<name>` suffix to the source-bank path in the table below. Every listed bank has all four unless its member column says otherwise. Sources remain untouched.

- **1** `assets/acts/act3/forest-bark-albedo-v1.png` — 3,050,390 bytes; SHA `3c775c520421ebb696448c93ab76a4e7c5ad96e2e2edefaaf4d613c1b0d9a8e5`; retained source `/Users/howardchen/Documents/ChatGPT/video game idea/assets/acts/act3/evidence/A3-L3-focused-desktop/arrival/01-new-script-import/sources/assets/acts/act3/forest-bark-albedo-v1.png`.
- **2** `assets/acts/act3/dreamsinter-observer.png` — 1,481,980 bytes; SHA `27e62f87cab2d937f49c5afe94585caf8ba794d09694c5d03ca0fe9c3a7d289d`; retained source `/Users/howardchen/Documents/ChatGPT/video game idea/assets/acts/act3/evidence/A3-L3-focused-desktop/arrival/01-new-script-import/sources/assets/acts/act3/dreamsinter-observer.png`.
- **3** `assets/acts/act3/mirror-shore-witnesses-v1.png` — 1,115,858 bytes; SHA `eecd39d9efe3c7039023887813be460fe3f7ab07caccc69627c96f431f4743f5`; retained source `/Users/howardchen/Documents/ChatGPT/video game idea/assets/acts/act3/evidence/A3-L3-echo-rule/10-arched-pose-two-kit-native-pass/sources/assets/acts/act3/mirror-shore-witnesses-v1.png`.
- **4** `assets/acts/act3/compassion-companions.png` — 1,060,840 bytes; SHA `c2ae1c3c24b12a2c31baec14aed2733eba976c8d006dd86a5e4ffdb7068987bb`; retained source `/Users/howardchen/Documents/ChatGPT/video game idea/assets/acts/act3/evidence/A3-L3-echo-resonance-room/01-qualified-import/sources/assets/acts/act3/compassion-companions.png`.

## Closed banks and receipts

Paths are absolute. Act 1 receipt is the bank path with trailing `-source` replaced by `.json`; its manifest is `<bank>/manifest.json`. Act 3 receipt is `<bank-parent>/result.json`; its manifest is `<bank-parent>/source-freeze.json`. Their reported source-change lists are empty. Original nonzero exits stay nonzero. Root-specific receipts are listed separately.

| Scope | Exact source-bank path | Closed at | Exit | Members |
|---|---|---|---:|---|
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-art-direct-parse01-source` | 2026-10-13T07:19:51.806572+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-art-fixture-import03-source` | 2026-10-13T07:16:44.598002+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-art-native01-source` | 2026-10-13T07:17:55.184665+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-art-native02-source` | 2026-10-13T07:21:11.453095+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-art-portrait01-source` | 2026-10-13T07:23:22.554503+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-art-portrait02-nose-relief-source` | 2026-10-13T07:26:48.269483+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-body-art-import02-source` | 2026-10-13T07:10:39.275805+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-body-native01-source` | 2026-10-13T07:12:08.861112+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-body-native02-verbose-source` | 2026-10-13T07:14:22.550274+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-body-native03-character56-source` | 2026-10-13T09:45:31.089634+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-capsule-import04-source` | 2026-10-13T07:42:18.803091+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-capsule-native01-source` | 2026-10-13T07:43:50.897710+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-component-import01-source` | 2026-10-13T07:02:35.487352+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-encounter-native01-source` | 2026-10-14T02:14:59.772765+00:00 | 1 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-encounter-native02-first-primary-source` | 2026-10-14T02:58:28.868594+00:00 | 254 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-encounter-native03-first-primary-source` | 2026-10-14T03:01:21.564865+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-encounter-native04-full-source` | 2026-10-14T03:10:54.907982+00:00 | 1 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-nose-native01-source` | 2026-10-13T07:03:10.073790+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-parent-import05-source` | 2026-10-13T09:17:45.023520+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-parent-native01-source` | 2026-10-13T09:19:44.587244+00:00 | 1 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-parent-native02-source` | 2026-10-13T09:28:11.247264+00:00 | 1 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-parent-native03-source` | 2026-10-13T09:29:50.068843+00:00 | 1 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-parent-native04-source` | 2026-10-13T09:32:38.370723+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-parent-native05-verbose-source` | 2026-10-13T09:35:06.780444+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-parent-native06-fresh-source` | 2026-10-13T09:54:36.595730+00:00 | 1 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-parent-native07-fresh-pause-source` | 2026-10-13T09:56:15.120791+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-portrait-production01-source` | 2026-10-14T02:23:21.059363+00:00 | 1 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-portrait-production02-source` | 2026-10-14T02:46:07.139821+00:00 | 1 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-production-import07-source` | 2026-10-14T02:11:35.276021+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-shell-import06-source` | 2026-10-14T01:18:47.000885+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-shell-native01-source` | 2026-10-14T01:20:16.701451+00:00 | 0 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-shell-native02-blink-source` | 2026-10-14T01:23:01.223088+00:00 | 1 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-shell-native03-capsule-source` | 2026-10-14T01:26:26.985025+00:00 | 1 | 1,2,3,4 |
| act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea/.cinder/a1-l5-shell-native04-approach-source` | 2026-10-14T01:36:57.877855+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-c50-fresh-floor-registration-native/sources` | 2026-10-13T09:53:46.224106+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-c50-public-shared57-portraits-native/sources` | 2026-10-14T02:48:26.540609+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-codec-grow-corrected-one-native/sources` | 2026-10-13T06:22:32.992085+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-codec-grow-corrected-two-native/sources` | 2026-10-13T06:27:27.407404+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-codec-v3-import-native/sources` | 2026-10-13T06:02:05.908387+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-codec-v3-one-first-native/sources` | 2026-10-13T06:15:21.492237+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-equipment-and-context-resource-import-native/sources` | 2026-10-13T09:11:09.171179+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-equipment-fast-native/sources` | 2026-10-13T09:17:41.964746+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-equipment-heavy-disk-recovered-native/sources` | 2026-10-13T09:45:01.276503+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-equipment-long-native/sources` | 2026-10-13T09:20:02.432581+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-equipment-wall-custody-native/sources` | 2026-10-13T09:45:05.414173+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-equipment-wall-heavy-native/sources` | 2026-10-13T09:28:12.555738+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-floor-diagnostic-resource-import-native/sources` | 2026-10-13T09:55:41.785746+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-full-parent-first-import-native/sources` | 2026-10-13T07:27:07.599843+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-max2-accounting-corrected-native/sources` | 2026-10-13T05:19:59.571526+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-max2-default-one-regression-native/sources` | 2026-10-13T05:28:53.730370+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-max2-first-native/sources` | 2026-10-13T05:13:48.303786+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-max2-import-native/sources` | 2026-10-13T05:10:36.591342+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-max2-rearmed-route-native/sources` | 2026-10-13T13:25:51.349280+08:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-coda-checkpoint-order-native/sources` | 2026-10-13T08:26:28.249029+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-coda-entry-native/sources` | 2026-10-13T08:25:00.575442+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-complete-world-root-corrected-native/sources` | 2026-10-13T07:46:33.454758+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-declared-phase1-construction-corrected-native/sources` | 2026-10-13T08:11:03.269364+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-declared-phase1-first-native/sources` | 2026-10-13T08:06:56.274177+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-entry-operands-native/sources` | 2026-10-13T07:38:42.587724+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-initial-disposal-corrected-native/sources` | 2026-10-13T08:02:53.549433+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-initial-first-native/sources` | 2026-10-13T07:29:59.164470+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-initial-view-observed-native/sources` | 2026-10-13T07:53:42.910833+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-phase1-identity-corrected-native/sources` | 2026-10-13T08:24:14.543100+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-phase2-entry-native/sources` | 2026-10-13T08:24:37.602448+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-portrait-authored-view-native/sources` | 2026-10-13T09:09:21.187031+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-portrait-first-native/sources` | 2026-10-13T09:00:29.362201+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-portrait-resource-import-native/sources` | 2026-10-13T08:55:44.595879+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-portrait-resume-label-native/sources` | 2026-10-13T09:01:19.566263+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-preview-difficulty-corrected-native/sources` | 2026-10-13T07:35:19.676248+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-real-phases-coda-view-native/sources` | 2026-10-13T08:34:24.840424+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-real-phases-exit-approach-native/sources` | 2026-10-13T08:37:52.770550+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-real-phases-first-native/sources` | 2026-10-13T08:26:58.586932+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-real-phases-harness-corrected-native/sources` | 2026-10-13T08:30:52.449623+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-regular-fresh-cycle-native/sources` | 2026-10-13T09:06:12.344926+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-regular-live-framing-native/sources` | 2026-10-14T01:35:31.833356+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-regular-native-lease-native/sources` | 2026-10-13T08:56:23.838680+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-regular-nested-context-native/sources` | 2026-10-13T09:17:24.737676+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-regular-paused-registration-native/sources` | 2026-10-14T01:18:43.843049+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-regular-pending-framing-native/sources` | 2026-10-14T02:10:36.065445+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-regular-priority-native/sources` | 2026-10-13T08:52:18.964617+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-regular-retained-commit-native/sources` | 2026-10-13T08:54:22.812237+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-parent-regular-scenery-stage-native/sources` | 2026-10-13T09:27:13.574036+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-rule-await-corrected-v2-native/sources` | 2026-10-12T08:11:46.375368+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-rule-completion-observed-v2-native/sources` | 2026-10-12T08:27:45.761510+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-rule-first-native/sources` | 2026-10-12T08:08:25.649974+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-rule-focus-resume-portrait-native/sources` | 2026-10-13T01:20:35.250506+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-rule-landing-diagnostic-native/sources` | 2026-10-12T08:16:21.686778+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-rule-natural-completion-portrait-native/sources` | 2026-10-12T09:22:14.323725+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-rule-portrait-import-native/sources` | 2026-10-12T09:01:40.212773+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-rule-portrait-post-actor-diagnostic-native/sources` | 2026-10-12T09:51:56.491192+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-rule-portrait-size-exit-corrected-native/sources` | 2026-10-12T09:30:46.824859+00:00 | 1 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-rule-public-clock-join-native/sources` | 2026-10-12T08:44:31.230618+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-shared56-resource-import-native/sources` | 2026-10-13T08:44:49.778712+00:00 | 0 | 1,2,3,4 |
| act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/.cinder/crystalman-stalker-flat-context-native/sources` | 2026-10-13T09:12:22.826162+00:00 | 0 | 1,2,3,4 |
| root-pair | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/collision-traversal-measure/inputs` | 2026-10-13T09:28:00.046776+00:00 | 0 | 1,2,3,4 |
| root-profile | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/collision-signature-profile/jobs/collision-signature-profile2/source` | 2026-10-13T08:53:56.452700+00:00 | 0 | 1,2,3,4 |

Root profile receipt: `.cinder/collision-signature-profile/jobs/collision-signature-profile2/result.json` (native 25/0, original host wrapper scope false retained; source_archive_current_exact_at_closure=true). Root pair receipts: `.cinder/collision-traversal-measure/jobs/{baseline-window,candidate-window}/result.json`, with actual pair in `comparison.json` (24/0 each; candidate withdrawn). These are immutable old jobs, not the latest codec experiment.

## Prior proven method and bounded execution

First read `.cinder/storage-recovery/independent-final-review.json` and `clone_verified_archives.py`. The earlier batch independently verified 965 targets and eight retained counterparts; observed volume free space rose 1,698,959,360 bytes. The executor creates an independent `/bin/cp -c -p` sibling clone, restores target owner/mode/mtime/xattrs, verifies exact bytes and nlink=1, rechecks target identity, then uses atomic `os.replace`. It never hardlinks live evidence. Do not execute that old script unchanged: it is pinned to an old HEAD and old manifest; Root needs a new narrow approved row set. Preserve originals and receipts even for failed/canceled jobs.

Start with Root’s two banks (eight members) to measure whether cloning still frees space. Then coordinate one act-owned closed batch at a time, without touching current active/frozen inputs or asking workers to perform overlapping cleanup. Stop if the pilot shows no useful reclaim or custody changes. Keep new receipts compact rather than copying source graphs.

## Oversized metadata and exclusions

Act 3 `.cinder/crystalman-shared57-adoption-before.json` is 93,701,541 logical / 93,704,192 allocated bytes. No byte-identical counterpart was established, so it is **not** an authorized clone candidate. Several older adoption-before files are about 6–13 MB each, also unpaired. Reformatting/compressing/removing them would change recorded evidence and is outside this plan. Avoid generating another whole-checkout census to diagnose this.

Act 2 had no matching recent source/profile/storage top-level bank or >32 MB top-level metadata file in the bounded check; this is not an assertion that its entire checkout contains no duplicate data. This audit did not walk `.godot`, `.git`, whole archives or running job banks.

## Root-only priority supplement (preferred before worker handoff)

The five explicitly named Integration areas contain **23 closed banks** inspected by their existing manifests; **12 large PNG groups / 264 replacement targets** were byte-verified. Target logical bytes: **261,196,012**; summed target allocated blocks: **261,685,248 bytes**. These are allocation estimates, not exclusive/reclaimable bytes. Retain the first closed counterpart listed for each group. This batch is additional to the earlier Root profile/pair banks and does not require changing an act checkout.

Only the twelve largest PNGs from an existing source manifest were considered; no recursive size census was created. Every target is a regular file with nlink=1, matching SHA/length and same device as its retained counterpart. All target modes below are 0644. Root confirms all its native jobs are closed; original failed jobs remain failed.

### Exact groups

- **R1** suffix `assets/acts/act3/forest-bark-albedo-v1.png`; 3,050,390 bytes; SHA `3c775c520421ebb696448c93ab76a4e7c5ad96e2e2edefaaf4d613c1b0d9a8e5`. Retain `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-02/frozen-before/assets/acts/act3/forest-bark-albedo-v1.png`. Targets 22; allocated sum 67,133,440 bytes.
- **R2** suffix `assets/acts/act3/dreamsinter-observer.png`; 1,481,980 bytes; SHA `27e62f87cab2d937f49c5afe94585caf8ba794d09694c5d03ca0fe9c3a7d289d`. Retain `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-02/frozen-before/assets/acts/act3/dreamsinter-observer.png`. Targets 22; allocated sum 32,620,544 bytes.
- **R3** suffix `assets/acts/act3/mirror-shore-witnesses-v1.png`; 1,115,858 bytes; SHA `eecd39d9efe3c7039023887813be460fe3f7ab07caccc69627c96f431f4743f5`. Retain `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-02/frozen-before/assets/acts/act3/mirror-shore-witnesses-v1.png`. Targets 22; allocated sum 24,600,576 bytes.
- **R4** suffix `assets/acts/act3/compassion-companions.png`; 1,060,840 bytes; SHA `c2ae1c3c24b12a2c31baec14aed2733eba976c8d006dd86a5e4ffdb7068987bb`. Retain `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-02/frozen-before/assets/acts/act3/compassion-companions.png`. Targets 22; allocated sum 23,339,008 bytes.
- **R5** suffix `assets/acts/act3/root-latcher-atlas.png`; 898,823 bytes; SHA `05bac37c0e5d03a0238651179e32106bd562ff5999bde36dcb83d3207a0bf810`. Retain `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-02/frozen-before/assets/acts/act3/root-latcher-atlas.png`. Targets 22; allocated sum 19,824,640 bytes.
- **R6** suffix `assets/acts/act3/twin-suns-violet-tree.png`; 672,657 bytes; SHA `5889d94dd035926cdc4c7d575975e4c63af7ddb04f3d308a3f762c1b4a573a38`. Retain `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-02/frozen-before/assets/acts/act3/twin-suns-violet-tree.png`. Targets 22; allocated sum 14,868,480 bytes.
- **R7** suffix `assets/acts/act3/sunbound-stalker-alppain-back.png`; 634,535 bytes; SHA `7c2a8297720f14ffbc7cacbe15f072ef7d2e4f9ea5effa9c64048a9eea79f03f`. Retain `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-02/frozen-before/assets/acts/act3/sunbound-stalker-alppain-back.png`. Targets 22; allocated sum 13,967,360 bytes.
- **R8** suffix `assets/acts/act3/sunbound-stalker-alppain-readable.png`; 627,238 bytes; SHA `1453c08eb9a48f6131391a82a548b45d3e90c4d36e3cdba36dcf8966b539c132`. Retain `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-02/frozen-before/assets/acts/act3/sunbound-stalker-alppain-readable.png`. Targets 22; allocated sum 13,877,248 bytes.
- **R9** suffix `assets/acts/act3/sunbound-stalker-branchspell.png`; 597,048 bytes; SHA `4b26a05de4d86848bb8d1d40d6567097bcc85f9b083d07c2ded110ac5836dcaa`. Retain `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-02/frozen-before/assets/acts/act3/sunbound-stalker-branchspell.png`. Targets 22; allocated sum 13,156,352 bytes.
- **R10** suffix `assets/acts/act3/sunbound-stalker-branchspell-back.png`; 591,566 bytes; SHA `52b11bd57dabbf3980b831291d48f9492cd186550219d257317dc62174ca0fa1`. Retain `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-02/frozen-before/assets/acts/act3/sunbound-stalker-branchspell-back.png`. Targets 22; allocated sum 13,066,240 bytes.
- **R11** suffix `assets/acts/act3/sunbound-stalker-alppain-recovery.png`; 571,145 bytes; SHA `c8214b1bcebe8b34877309f70f16630b028dfec520a811efdc6b27b0943d21d6`. Retain `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-02/frozen-before/assets/acts/act3/sunbound-stalker-alppain-recovery.png`. Targets 22; allocated sum 12,615,680 bytes.
- **R12** suffix `assets/acts/act3/sunbound-stalker-recovery.png`; 570,466 bytes; SHA `8aab2d8763885d4f198b2c346658987145bf585a7b72f31703b32207602c59ac`. Retain `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-02/frozen-before/assets/acts/act3/sunbound-stalker-recovery.png`. Targets 22; allocated sum 12,615,680 bytes.

### Exact target banks and closure evidence

For each listed group ID, append its suffix above to the listed target bank. A dash means the bank supplies retained counterparts only. No other file in these banks is proposed for replacement.

| Target bank | Group IDs | Closure receipt | Closed timestamp / original exit |
|---|---|---|---|
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-02/frozen-before` | retained only | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-02/closure.json` (SHA `c9d0424ca3c59b1e071bfa0e3fb0d5f2854cf16374c73bbf7ca266b08644d33a`) | 2026-10-13T08:00:56.074134+00:00; exit 1 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-03/frozen-before` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-03/closure.json` (SHA `ba6d7c15c05e4da34172a240ec88f50cec5db2e92bed1e9bf42bb39a26fe7f8b`) | 2026-10-13T08:06:54.356645+00:00; exit 1 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-05-held-restore/frozen-before` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-05-held-restore/closure.json` (SHA `73dfe054217ef5bb2ed15ca5ac3a60fb61d9e1f7e0099c156c57afd7d277feb7`) | 2026-10-13T08:16:52.921766+00:00; exit 0 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-04-held-diagnostic/frozen-before` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-04-held-diagnostic/closure.json` (SHA `b48ccd6cca8e58ad925fca16f788d2d1895398dd21a9a9768b31ca9e0ea2b279`) | 2026-10-13T08:12:27.438753+00:00; exit 1 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-01/frozen-before` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-01/closure.json` (SHA `fc21180d6f863a3961890c551c7d8d09f576a8987acdcf188312660ef780b9a0`) | 2026-10-13T07:56:49.417845+00:00; exit 1 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/import-01/frozen-before` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/import-01/closure.json` (SHA `031428e00ddd87ff667a48294d9531e5a7f535c318f17eea31351cca4b16d0ab`) | 2026-10-13T07:55:19.643590+00:00; exit 0 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-06-full/frozen-before` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/sampled-circle-native/native-06-full/closure.json` (SHA `c0119fb8d8cf2801d3db86c17ac4f0237441c8fd8207012cce8a75b36b392213`) | 2026-10-13T08:23:08.106345+00:00; exit 0 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/configuration-reference-native/controls-first-20261012/source` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/configuration-reference-native/controls-first-20261012/result.json` (SHA `df8e34b14db2b4e2240363a6d6a7955c5167c0d5f0055f28839fa75b9f5b1182`) | 2026-10-12T08:29:41.239232+00:00; exit 0 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/configuration-reference-native/bounded-candidate-first-20261012/source` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/configuration-reference-native/bounded-candidate-first-20261012/result.json` (SHA `b0afbddf3235e3ec2a555bbae99be7ce78a3037c28e145f90f78c2daeac53b41`) | 2026-10-12T08:40:28.166259+00:00; exit 0 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/configuration-reference-native/affected-source-first-20261012/source` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/configuration-reference-native/affected-source-first-20261012/result.json` (SHA `93769f409cdbb585b5c0774fceb4bd8cccc76e2b0b9352b32bbbb82779fa3e04`) | 2026-10-12T08:31:51.288319+00:00; exit 0 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/configuration-reference-native/affected-reference-first-20261012/source` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/configuration-reference-native/affected-reference-first-20261012/result.json` (SHA `2a7dfff2d8b881a061e792d8b2cac461f0fa6bdb2adb1f203e660f45a4978073`) | 2026-10-12T08:33:54.159086+00:00; exit 0 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/configuration-reference-native/bounded-baseline-first-20261012/source` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/configuration-reference-native/bounded-baseline-first-20261012/result.json` (SHA `1c0dac423b1c571fab843f38ac680e4c92df8dac62176eb905ff6de0a6a96a3f`) | 2026-10-12T08:38:34.333773+00:00; exit 0 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-world-floor-review/jobs/campaign-shell-native-01/inputs` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-world-floor-review/jobs/campaign-shell-native-01/result.json` (SHA `10efd2dff70513978313bcb329521ba490c44554c4074cb7f8dfacb8449051bf`) | 2026-10-14T01:42:30.195094+00:00; exit 1 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-world-floor-review/jobs/campaign-persistence-native-02/inputs` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-world-floor-review/jobs/campaign-persistence-native-02/result.json` (SHA `b42fc6f04ecb8e1a86353a19277baa5f3bec5d653165ba9f48e8340a5c001cec`) | 2026-10-14T02:12:28.201506+00:00; exit 0 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-world-floor-review/jobs/restore-legacy-parse-01/inputs` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-world-floor-review/jobs/restore-legacy-parse-01/result.json` (SHA `f654624374c564ff93d2e36ee963fd8f9522fdeb9dbd8ddf6ff4ce275727b536`) | 2026-10-14T01:35:32.310051+00:00; exit 0 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-world-floor-review/jobs/physics-core-native-01/inputs` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-world-floor-review/jobs/physics-core-native-01/result.json` (SHA `f810a60c94c584ca5ea33c74e68dfb547c4f0ba79d8da13a6f77dca6f6fb8ba1`) | 2026-10-14T01:39:04.703552+00:00; exit 0 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-world-floor-review/jobs/campaign-shell-native-02/inputs` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-world-floor-review/jobs/campaign-shell-native-02/result.json` (SHA `0f42d7dd2b60e6208a222b5bfd7351e37655f5510e801feb0fa971e787524328`) | 2026-10-14T02:11:30.402337+00:00; exit 0 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-world-floor-review/jobs/campaign-persistence-native-01/inputs` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-world-floor-review/jobs/campaign-persistence-native-01/result.json` (SHA `ee5f256473a8bd3477d0332f8937f97cf413bbef34fb50a9bfd78c658c881bc7`) | 2026-10-14T02:11:35.935160+00:00; exit 1 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-world-floor-review/jobs/physics-startup-native-01/inputs` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-world-floor-review/jobs/physics-startup-native-01/result.json` (SHA `68df47e8d01b3b4b9df3d56c1fc0ac9fafa2aa32c4c48112e33a9d0d8990f1e5`) | 2026-10-14T01:40:34.881896+00:00; exit 0 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-world-floor-review/jobs/restore-legacy-native-01/inputs` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-world-floor-review/jobs/restore-legacy-native-01/result.json` (SHA `54644b187247e9e325bb5834505ceb0df4e1b9cb8b50c95b6c4449429a28c19d`) | 2026-10-14T01:41:26.310794+00:00; exit 0 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-world-floor-review/jobs/physics-core-parse-01/inputs` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/fresh-world-floor-review/jobs/physics-core-parse-01/result.json` (SHA `7fd790eb9fae97e5761b2a4f56133b7ecf90136e7b765120c0f9996e13e0601c`) | 2026-10-14T01:37:30.012560+00:00; exit 0 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/shared54-root-import/primary-import-first-20261013/frozen-before` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/shared54-root-import/primary-import-first-20261013/closure.json` (SHA `0e4ae9979f097268148650a26c273b628bed643144a50e7d3dbc5fdbf69e98da`) | 2026-10-13T05:20:01.611679+00:00; exit 0 |
| `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/shared55-root-import/primary-import-first-20261013/frozen-before` | R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12 | `/Users/howardchen/Documents/ChatGPT/video game idea/.cinder/shared55-root-import/primary-import-first-20261013/closure.json` (SHA `f5533b755e13318519b6b8a2b48c3aad3800fbce4ad798a015fb9f91e4fc5520`) | 2026-10-13T06:39:02.132153+00:00; exit 0 |

Root-only atomic execution still needs fresh per-target inode/mtime/owner/xattr capture immediately before replacement, using the prior safe COW method. No source/closure manifest or original logs should be rewritten. Existing freezes may hold shared extents already, so run a small one-group pilot first; stop on lack of useful reclaim. Future freeze writers can use verified `cp -c -p` for same-volume copies to avoid recreating independent duplicate extents, provided that writer change preserves immutable byte/metadata custody and is separately reviewed.
