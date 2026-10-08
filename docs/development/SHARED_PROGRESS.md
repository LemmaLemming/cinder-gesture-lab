# Cinder shared progress

Integration owner: Codex chat `01a11abb-d174-7c11-9dc7-8343269bf06e`. Updated 8 October 2026. Scope and precedence: [CAMPAIGN_MEMORY](CAMPAIGN_MEMORY.md). Current API: [SHARED_CONTRACT](SHARED_CONTRACT.md).

## Inventory and ownership

- Initial clean canonical checkout: `codex/gesture-prototype`, `03743796114d1ff8a22f2819ff4ff11c0a0b20d5` (Character Lab and parallel tooling baseline). One checkout at inventory; no act owners/worktrees discovered.
- The user explicitly confirms this chat is unequivocally the newest objective owner and waived the interrupted earlier setup chat. It is archived and was not resumed. Its interruption does not authorize discarding other workers' work.
- Character worker handoff requested from `Create Godot character and starter` (`01a11a5c-d1be-7b61-ad2a-33b0c1766b1a`). Its existing code/art/effects/provenance remain preserved. Acknowledged handoff received: no active workers/edits/owned engine jobs and no outstanding implementation; shared ownership released to integration.
- Read-only process inventory found detached outside-wrapper game preview PID 68609, parent 1; its editor PID 62338 had exited. After the explicit ownership handoff, integration gracefully closed this inherited game preview with SIGTERM and verified its exit. Its UI was unresponsive; no forced kill, active worker/editor termination or lock deletion occurred.
- Initial disk inventory approximately 37–38 GiB free. Godot 4.7.2 official is local; no engine replacement/Node installation. Heavy engine concurrency remains one.
- Canonical equipment creation and ability ledgers are revision 0, no claims/uses. Catalogue contains 12 clothing, four weapons, 14 perks and six temporary powerups; runtime implements nine static clothing and four weapons.

## Milestones and acceptance

| Milestone | State | Evidence / next action |
| --- | --- | --- |
| Objective and current inventory | Complete | Attached objective read; clean Git/worktree/tool/ledger inventory and actual selected art inspection |
| Ownership handoff | Complete | Direct user ownership confirmation and character owner acknowledgement; older external preview release tracked separately |
| Latest decision reconciliation | Complete | Scope existing docs/manifests to concept-derived campaign presentation; retain historical helmet provenance |
| Durable records and role mailbox | Complete | Three shared records; run `cinder-desktop-8316ef76-c930-4cd2-9e6f-13c616dd10e2`; no act writes before READY |
| Reviewed parallel baseline and READY | Checkouts pending | Shared checks and portrait fixture passed; scoped commit and actual linked checkout/root/port/lock verification remain |
| Level and executed-world-action interfaces | Verified | campaign-level-1 and world-actions-1; 92 level and 119 action checks, compatible with prior preview API |
| Campaign/save/scheduler/UI/settings | Pending | Local hooks and action data do not implement those flows |
| Act level acceptance | None | All 15 main/9 optional remain authored proposals; no campaign scenes accepted |
| Integrated desktop campaign | Pending | All 24 levels and required shared-system flows must be accessible/tested |

No level commits are accepted yet. `campaign-shared-1` passed queued verification and awaits scoped baseline publication. READY is a setup milestone, not campaign completion.

## Tests and known limits

Verified this run with Godot 4.7.2 through the shared queue: **469 checks, zero failures** (78 mechanics, 50 equipment, 39 Character Lab, 102 visual effects, 81 level contract, 119 world actions). Full log: ignored `.cinder/campaign-baseline-verified.log`. The first run exposed a JSON fixture supply-count normalization error; the corrected fixture preserves integral counts and rejects fractional supplies. Final review also aligned local-payload nesting on capture/restore and rejected newline-suffixed IDs; a targeted 92-check level-contract rerun verifies those boundaries (ignored `.cinder/campaign-baseline-level-final.log`). Other suites were unchanged and not repeated. All 56 Python tests are covered by the initial run and the successful affected 20-test dev-tool rerun after replacing an obsolete fixed suite-count expectation. Canonical ability/equipment validation and numerical equipment design validation passed without ledger changes.

Actual queued graphical fixture capture at 540×1170: ignored `captures/campaign-baseline-fixture.png`, log `.cinder/campaign-baseline-portrait.log`; inspected shared actor, feet placement, fixed portrait camera and HUD, with no runtime errors. It is an anonymous contract fixture on a grey floor, not campaign art or evidence of encounter completion. Play/Edit Finder launchers now join the same wrapper queue; shell syntax and their engine-version invocation passed.

**Latest user test policy:** rerun the changed level's targeted suite plus directly affected shared checks. The initial full baseline verification is complete; repeat a broad suite only for a newly identified cross-system concern. Use `dev.py engine --headless --path . --script <owned-level-test.gd>` for act suites and named `dev.py test` shared suites. `dev.py doctor` verifies paths/slots/version, not gameplay readiness.

The current game is one Character Lab. No campaign runtime scenes, persistence, Journey, difficulty profiles, full threat scheduler, perks/powerups or selected act presentation variants exist. Preview reset refreshes resources/supplies and must not be described as checkpoint retry. Existing warning meshes do not validate safe paths. The new world-action API provides executed movement and parametric attack records; it does not implement captured-sequence validation or persistence for Act 2/3.

Selected references opened in initial audits include each act's game view, character and environment art. These support distinct act scenery and headwear; they do not establish production readiness. Existing effects and helmeted lab captures remain preserved. No human campaign playtest or mobile/device performance claim is made.

Research inspected official Godot 4.7 APIs and tagged 4.7.2 source, a maintainer forum/PR and a developer 2.5D postmortem. [Research record](../research/SHARED_SYSTEMS_RESEARCH.md) distinguishes observations, proposed adaptations, required validation and the YouTube candidate whose footage was unavailable.

## Open shared requests and implementation order

1. Publish reviewed ownership, references and parallel setup; start workers only after READY.
2. Publish verified campaign-level-1 completion/contact-exit, encounter/boss-phase checkpoint and local snapshot lifecycle.
3. Implement coherent actor/local snapshots and isolated story/optional/replay saves; define checkpoint healing explicitly.
4. Build on verified world-actions-1 completed dash/accepted attack capture; add authoritative preparing/active geometry, reachable paths and scheduler.
5. Apply provisional difficulty profiles at fresh boundaries without compounding values.
6. Build Title/Journey, progression/replay equipment/Continue routes over readiness-gated registry data.
7. Coordinate act presentations, common cues and campaign-selected equipment implementations through canonical claims/reservations.
8. Add persistent cosmetic quality/FPS/audio/reduced motion/credits and measure desktop performance.
9. Accept/integrate one level at a time with exact commit/baseline/API and evidence; revalidate affected shared behavior.

Act workers maintain their own memory/progress/level records. After context recovery, read those plus the three shared records and current mailbox before review. Do not merge private ledger copies or machine settings. Internal acceptance is autonomous; mobile export/release is outside the authorized endpoint.
