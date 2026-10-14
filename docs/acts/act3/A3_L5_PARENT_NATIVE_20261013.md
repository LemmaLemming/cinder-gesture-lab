# Crystalman full-parent focused native results — 13 October 2026

Status: unfinished. Latest real-phase run: 770 checks/0 failures, 675 native ticks, clean exit0; all own handles closed. Act3 4/8 accepted; Shared55 actually adopted at merge `2c69525c28f61973a8271c5a1ff26c39f94904a5`. These results cover the new full parent, with explicitly declared predecessor history in later-stage fixtures. They do not establish a completed route or art acceptance.

## Initial parent

Crystalman full-parent focused source candidate: stage0 23 checks/0 failures. Later selectors declare prior history; no route-clear/art acceptance.

Command: `python3 scripts/dev/dev.py engine --headless --path . --script res://tests/acts/act3/crystalman_parent_transport_smoke.gd`. Exit 0; 0 diagnostic lines; 590 frozen inputs, changes []. Raw SHA `614abff7de1cfd62bee4e2c6c0c3e92e48ecf340e7918d248f3838fcb970134b`; original evidence directory `.cinder/crystalman-parent-initial-disposal-corrected-native`.

## Phase1 entry

Crystalman full-parent focused source candidate: stage2 22 checks/0 failures. Later selectors declare prior history; no route-clear/art acceptance.

Command: `python3 scripts/dev/dev.py engine --headless --path . --script res://tests/acts/act3/crystalman_parent_transport_smoke.gd -- --declared-phase1`. Exit 0; 0 diagnostic lines; 590 frozen inputs, changes []. Raw SHA `ac36cad86cfc17bc94eb09c27eb5dce0c3f7c0d9b3f1397665f7e1859f71fe7c`; original evidence directory `.cinder/crystalman-parent-phase1-identity-corrected-native`.

## Phase2 entry

Crystalman full-parent focused source candidate: stage3 22 checks/0 failures. Later selectors declare prior history; no route-clear/art acceptance.

Command: `python3 scripts/dev/dev.py engine --headless --path . --script res://tests/acts/act3/crystalman_parent_transport_smoke.gd -- --declared-phase2`. Exit 0; 0 diagnostic lines; 590 frozen inputs, changes []. Raw SHA `6e4c7c339ae733840bc13d54dd4a428a7e857a3db8ecd5d0a35db9aab5068e6a`; original evidence directory `.cinder/crystalman-parent-phase2-entry-native`.

## Coda original

Crystalman full-parent focused source candidate: stage4 23 checks/1 failures. Later selectors declare prior history; no route-clear/art acceptance.

Command: `python3 scripts/dev/dev.py engine --headless --path . --script res://tests/acts/act3/crystalman_parent_transport_smoke.gd -- --declared-coda`. Exit 1; 1 diagnostic lines; 590 frozen inputs, changes []. Raw SHA `3e336f79a0e80b9e502ac00dd31d4dfd9f377a8556920abea7a6d687e4912586`; original evidence directory `.cinder/crystalman-parent-coda-entry-native`.

## Coda corrected

Crystalman full-parent focused source candidate: stage4 23 checks/0 failures. Later selectors declare prior history; no route-clear/art acceptance.

Command: `python3 scripts/dev/dev.py engine --headless --path . --script res://tests/acts/act3/crystalman_parent_transport_smoke.gd -- --declared-coda`. Exit 0; 0 diagnostic lines; 590 frozen inputs, changes []. Raw SHA `504cd3d2d5c5ea29941d2f4ce9018cca90119e6ad9441d7e423b41858775bfe0`; original evidence directory `.cinder/crystalman-parent-coda-checkpoint-order-native`.

## Real phases original harness

Crystalman full-parent phase candidate: 59 checks/1 failures/45 native ticks. Three earlier regular deaths were DECLARED TEST setup; no full-route/art acceptance.

Command: `python3 scripts/dev/dev.py engine --headless --path . --script res://tests/acts/act3/crystalman_parent_phase_smoke.gd`. Exit 1; 19 diagnostic lines; 590 frozen inputs, changes []. Raw SHA `2d10dd19143a0a7de1c027b98433209a71e5a4d770c7ac01123b58b79f5e2278`; original evidence directory `.cinder/crystalman-parent-real-phases-first-native`.

## Real phases corrected harness

Crystalman full-parent phase candidate: 741 checks/1 failures/657 native ticks. Three earlier regular deaths were DECLARED TEST setup; no full-route/art acceptance.

Command: `python3 scripts/dev/dev.py engine --headless --path . --script res://tests/acts/act3/crystalman_parent_phase_smoke.gd`. Exit 1; 1 diagnostic lines; 590 frozen inputs, changes []. Raw SHA `4318a3f67b39c736ebf7453124017b82da1c6ab34fe1b6f50bdc5104a7b540a7`; original evidence directory `.cinder/crystalman-parent-real-phases-harness-corrected-native`.

## Diagnosis and scope

The three declared TEST scenes lacked exported `level_id`, so Registry pre-tree validation refused them. Their explicit A3-L5 identity now matches production. The pure validator error is retained directly, before attempting restoration. Actual Player, current native unit, parent metadata, camera/HUD and JSON are transported through an independent quiet recipient and real Shell Continue/Retry/SaveStore.

The original coda queued its checkpoint and completion in the same physics tick. Checkpoint serialization then saw completed local progress before the campaign completion operation. The owned parent now returns after a successful checkpoint request; the existing Shell persists it before the next normal tick may publish completion. Corrected coda verifies once-only grounded contact and durable final progress. Shared save code is unchanged.

The first real-phase run has genuine parse and cleanup errors and is not clean despite success-looking assertions. The framing helper now defines its exact-JSON comparator. Resume-state observation uses a synchronous paused snapshot boundary without advancing a frame, then restores the resumed state. Parent cleanup retains WeakRefs before freeing child objects and clears stale typed references before inherited cleanup.

The corrected real-phase run reaches both ordinary tether releases and immediate successor disposal, but fails the final optical save because the newly revealed shore marker is outside the current camera view. A focused correction observes ordinary camera follow and explicitly requires a valid original fixed-camera plan before the coda snapshot. It preserves original response deadlines. The coda-view diagnostic CLOSED at 741 checks/1 failure, with no script errors: the required framing exceeds the permitted planar focus shift (raw SHA `06dbdba3dd4f9228bcde83b55ad05ac626e6f9ec4fa53337d8a7c3e92f1572f3`). This is an actual far-exit framing fault, not camera latency. The owned parent now requires the contact marker in framing only inside a four-metre approach; its world position/state and all combat bounds remain unchanged. Focused rerun8427 CLOSED clean at **770 checks/0 failures, 675 ticks**, raw SHA `b964a32728f0035c6a913ea985bb5950b7ad8a7cb9f9d05b8cac4960d0f97a5f`. All590 frozen inputs and491 UID bytes remained exact. Both genuine phase releases, successor saves and original Player recovery deadlines pass. Both observed recording routes advanced directly to warning, so framing-state transport remains unverified.

Remaining: regular priority/journal check, representative actual portrait art inspection, relevant equipment extremes, portable evidence and independent Integration acceptance. Full-playthrough behavior is untested and is not an acceptance gate.
