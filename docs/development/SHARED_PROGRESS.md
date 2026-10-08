# Cinder shared progress

Integration owner: Codex chat `01a11abb-d174-7c11-9dc7-8343269bf06e`. Updated 8 October 2026. Scope and precedence: [CAMPAIGN_MEMORY](CAMPAIGN_MEMORY.md). Current API: campaign-shared-4 [SHARED_CONTRACT](SHARED_CONTRACT.md).

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
| Reviewed parallel baseline and READY | Complete | Baseline ff34f58; three clean linked act checkouts, canonical roots/common queue/distinct ports verified; READY published in coordination status |
| Level and executed-world-action interfaces | Verified | campaign-level-1 and world-actions-1; 92 level and 119 action checks, compatible with prior preview API |
| Shared foundations | Verified modules | Player snapshots72, save/progression45, settings182, bounded scheduler65; consumer evidence below; tracking/lunge and act acceptance remain pending |
| Campaign/save/scheduler/UI/settings consumers | In progress | Tested live shell/menu/cues/presentation/enemy/input consumers publish as shared3; tracking/lunge/loading-arm adapters remain in progress |
| Act level acceptance | None | All 15 main/9 optional remain authored proposals; no campaign scenes accepted |
| Integrated desktop campaign | Pending | All 24 levels and required shared-system flows must be accessible/tested |

No level commits are accepted yet. `campaign-shared-1` passed queued verification and is published at baseline `ff34f58e1c29f44b17958f59107e19c99cc91d86`. READY is a setup milestone, not campaign completion.

## READY checkout assignments

| Role | Checkout | Branch | Ports |
| --- | --- | --- | --- |
| Act1 | `/Users/howardchen/.codex/worktrees/campaign-act1/video game idea` | `codex/campaign-act1` | 6015/6016/6017 |
| Act2 | `/Users/howardchen/.codex/worktrees/campaign-act2/video game idea` | `codex/campaign-act2` | 6025/6026/6027 |
| Act3 | `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea` | `codex/campaign-act3` | 6035/6036/6037 |

All were verified clean at the exact reviewed baseline. Generated local configuration resolves the canonical root and inherited lock identically, with distinct debugger ports. The user launched all three act chats; integration verified their matching requests, clean assigned branches and exact baseline, and registered sole owners: Act1 `01a11adf-2ec8-7702-96c6-0fa1e240c332`, Act2 `01a11adf-a56f-77d2-a7bc-45fd94702ab1`, Act3 `01a11ae0-0acf-7d00-a987-321a98de5b66`. Immutable RESPONSE acknowledgements remove their registration gate. First import in each new checkout uses the shared queue; imported caches are local and ignored. READY is recorded atomically in the ignored integration status and an immutable recipient-tagged message. Canonical source for live assignments/worker confirmations: `.cinder/agent-chat/cinder-campaign/run.json`.

## Tests and known limits

Verified this run with Godot 4.7.2 through the shared queue: **469 checks, zero failures** (78 mechanics, 50 equipment, 39 Character Lab, 102 visual effects, 81 level contract, 119 world actions). Full log: ignored `.cinder/campaign-baseline-verified.log`. The first run exposed a JSON fixture supply-count normalization error; the corrected fixture preserves integral counts and rejects fractional supplies. Final review also aligned local-payload nesting on capture/restore and rejected newline-suffixed IDs; a targeted 92-check level-contract rerun verifies those boundaries (ignored `.cinder/campaign-baseline-level-final.log`). Other suites were unchanged and not repeated. All 56 Python tests are covered by the initial run and the successful affected 20-test dev-tool rerun after replacing an obsolete fixed suite-count expectation. Canonical ability/equipment validation and numerical equipment design validation passed without ledger changes.

Actual queued graphical fixture capture at 540×1170: ignored `captures/campaign-baseline-fixture.png`, log `.cinder/campaign-baseline-portrait.log`; inspected shared actor, feet placement, fixed portrait camera and HUD, with no runtime errors. It is an anonymous contract fixture on a grey floor, not campaign art or evidence of encounter completion. Play/Edit Finder launchers now join the same wrapper queue; shell syntax and their engine-version invocation passed.

**Latest user test policy:** rerun the changed level's targeted suite plus directly affected shared checks. The initial full baseline verification is complete; repeat a broad suite only for a newly identified cross-system concern. Use `dev.py engine --headless --path . --script <owned-level-test.gd>` for act suites and named `dev.py test` shared suites. `dev.py doctor` verifies paths/slots/version, not gameplay readiness.

The default launch remains the playable Character Lab until the opening authored level is accepted. A separate tested desktop shell provides readiness-gated Title/Journey/settings/replay and coherent fixture persistence/transitions. No real campaign scenes are accepted; tracking/moving threat adapters, campaign-selected abilities and complete authored campaign content remain unfinished. Preview reset refreshes resources/supplies and must not be described as checkpoint retry. Existing warning meshes do not validate safe paths. The new world-action API provides executed movement and parametric attack records; it does not implement captured-sequence validation or persistence for Act 2/3.

Selected references opened in initial audits include each act's game view, character and environment art. These support distinct act scenery and headwear; they do not establish production readiness. Existing effects and helmeted lab captures remain preserved. No human campaign playtest or mobile/device performance claim is made.

Research inspected official Godot 4.7 APIs and tagged 4.7.2 source, a maintainer forum/PR and a developer 2.5D postmortem. [Research record](../research/SHARED_SYSTEMS_RESEARCH.md) distinguishes observations, proposed adaptations, required validation and the YouTube candidate whose footage was unavailable.

## Shared foundations publication 2

`campaign-shared-2` adds available player-snapshot-1, save/progression/registry models, settings model and threat-scheduler-1/provisional difficulty. All are additive to the act starting baseline. Exact publication commit is announced in the canonical run/mailbox after scoped commit; do not copy canonical uncommitted working files into acts.

| Targeted suite | Result | Ignored evidence |
| --- | --- | --- |
| campaign_persistence | 45, zero failures | `.cinder/campaign-persistence-test.log` |
| settings | 182, zero failures | `.cinder/settings-test.log` |
| player_snapshot | 72, zero failures | `.cinder/player-snapshot-test.log` |
| world_actions (directly affected) | 119, zero failures | `.cinder/world-actions-after-snapshot.log` |
| threat_scheduler | 65, zero failures | `.cinder/threat-scheduler-test.log` |

The save suite uses explicitly marked test-only accepted fixtures and transport placeholders; it proves model/storage isolation and recovery, not live enemy/shell restoration. Actor suite compares actual paused JSON mid-dash/wall/buffered continuation and attack/reload/knockback/death clocks without replaying damage. Settings tests prove atomic failure handling and protected policy, not an integrated menu or measured performance. Scheduler tests include combined preparing/active footprints, capsule sweeps, analytic floor continuity/holes/steps, slow implemented kit and ordinary-primary opening; finite authored candidates/static stationary sources are a bounded supported witness, not campaign fairness or exhaustive equipment playtesting. One test incorrectly expected source cooldown to expire with recovery; it now independently verifies both deadlines. Full baseline suites were not repeated.

### Read and triaged L1 dependencies

- Act1 requests `d23bcc5f-905f-4c6f-8d21-de22f59dafbe` and `630692a0-3b6e-4dad-b13c-698103b0aceb`: sole owner registered; friendly loading-arm finite lane/cue/damage lifecycle, public release-anchor teaching observations, PracticeTarget public state/art hook, roof coherent checkpoint/hatch transition and G07 brimmed-hat expedition presentation pending. No enemies/perks/required blast/pickup introduced for L1.
- Act2 requests `217cf59b-e691-492f-9c0f-ec7137f33dba`, `c281471f-e539-44d5-8e9e-685088f364dd`, `4c41a8d4-7336-4bfa-8648-bd9bed1622d7`: sole owner registered; tracking-warning then immutable locked lane, preparing-slot/reproof semantics, public live response state, shared cues/coherent checkpoints and G18/S01 bare dark hair/period coat/sash presentation pending. Stationary committed prototype does not supply tracking warning.
- Act3 requests `c0b90d7e-0fe7-4389-b4d4-f32ba1a31b1b`, `f5138515-7845-4636-9511-9ce5a4887c40`, `f0f92ef4-2785-49d6-a899-ce07afe45129`: sole owner registered; physical committed Stalker lunge/shortened endpoint adapter, public live response, common cue/coherent reservations and G18 ivory-coat bare dark short-hair presentation pending. A disconnected stationary proxy must not evade source-motion validation.

All owners may progress same-level owned art/layout/notes while these dependencies are implemented. Registration was delayed while integration verified modules; matching launch requests and clean branches were then checked and acknowledged. No duplicate owners/checkouts were created.

## Open shared requests and implementation order

1. Receive A1-L1/A2-L1/A3-L1 owned-path work and precise dependencies; all three user-launched sole owners are registered.
2. Publish verified campaign-level-1 completion/contact-exit, encounter/boss-phase checkpoint and local snapshot lifecycle.
3. Compose verified actor/local/attempt/store APIs into paused live save/load/retry/transition/side-return flows; enemy/scheduler snapshots and protected feedback remain in progress.
4. Integrate the verified bounded stationary scheduler and add tracking-warning/moving-source lunge adapters plus coherent reservation snapshots, actual shared cues and public live response state.
5. Apply provisional difficulty profiles at fresh boundaries without compounding values.
6. Build Title/Journey, progression/replay equipment/Continue routes over readiness-gated registry data.
7. Coordinate act presentations, common cues and campaign-selected equipment implementations through canonical claims/reservations.
8. Add persistent cosmetic quality/FPS/audio/reduced motion/credits and measure desktop performance.
9. Accept/integrate one level at a time with exact commit/baseline/API and evidence; revalidate affected shared behavior.

Act workers maintain their own memory/progress/level records. After context recovery, read those plus the three shared records and current mailbox before review. Do not merge private ledger copies or machine settings. Internal acceptance is autonomous; mobile export/release is outside the authorized endpoint.

## Worker contact and shared consumer publication 3

The user confirms integration is the point of contact for all three workers' help/blockers. Registration requests and exact existing identities/assignments were verified; worker_id/confirmation were atomically published, separate from unfinished shared APIs. Each worker has a canonical RESPONSE and explicitly acknowledged shared2 adoption, preserved owned work, and is progressing only its first level. A quiet ten-minute heartbeat plus active-work mailbox checks resolve actionable shared blockers; unchanged state emits no routine alert. No worker status file is overwritten.

Act1 follow-up461764f9 reports stale default target label after direct HP restore. The tested public silent target configure/state/art hook resolves this shared dependency; it is published with an exact commit, rather than copied from uncommitted files. Public hero response and release/tap observer resolve related read-only access requests. Scheduler snapshot, common cues and concept presentations are tested; tracking/moving-source adapters, loading-arm consumer and full authored act composition still require work.

Shared consumer evidence: enemy snapshot81 / PracticeTarget32 / input-response14 / scheduler snapshot35 / menu52 / live shell40 / effects settings60 / cues82 / presentation73 (5,544 poses/11 legal kits), all zero failures. Directly affected mechanics78, level92, scheduler65, effects102, player snapshot72 and persistence45 passed. Logs are ignored .cinder/<suite>-test.log or named after their affected rerun; no broad baseline repeated. Fixtures are explicitly TEST ONLY and not accepted campaign scenes. No human/device playtest, art acceptance or performance measurement follows.

The live shell tests actually restore low HP/zero ammo, enemy phase/clocks/HP, spent supplies/collected IDs, full-precision large RNG strings and separate exact aim/camera; replay/optional attempts protect story and deduplicate stamps. Failed writes preserve the live world and retain pending operations. Completion/local aggregate now commits atomically; a saved latched exit retries after next-scene integration. Staging/revealing the original candidate World3D fixes reparent-induced level exit cleanup. Settings/audio/policy and interrupted paused-session flows are exercised. Full campaign remains incomplete: zero real level acceptances.

Corrections found by targeted checks: enemy test JSON had used shortened float transport near a phase boundary (now matches production full precision); effect test compared a float32 engine property to a double exactly (now approximate comparison); initial shell reparent correctly invoked level exit (now reveal same staged world); typed/unchanged invalid-state test fixtures corrected. Earlier failed checks are retained in the factual work history; current logs reflect repaired targeted runs.

Shared3 portrait evidence: eight actual 540×1170 UI/HUD/fixture renders, including readiness-gated Title, all 24 Journey nodes, settings/credits, actual four-slot replay preview and the three selected concept silhouettes. Root reviewed native gallery and captures. Optional/main buttons now preserve at least eight pixels of separation; completed current nodes (including final main) expose replay, while Title keeps Continue Story. Campaign HUD says RETRY. Act1 request a99371e3's shared preview contrast issue is addressed by a dark objective backplate and dark normal text on the pale primary button. These are shared fixtures, not accepted act art or human campaign playtests.

Exact shared3 publication: `dcc7a3a735b2ef00f7b5e9fd5b74320d8db69b32`. Canonical run and immutable responses announce availability; worker baselines change only on their own adoption acknowledgments.

## Shared stationary consumer publication4

All three workers explicitly acknowledged shared3 adoption: Act1 9a4ef563, Act2 faaface0 and Act3 11e1478f; actual assigned checkout ancestry was independently verified. Resulting owned heads are recorded in canonical run, preserving Act2/3 owned commits.

Loading-arm lane-mechanism-1 passed79 targeted checks, including actual dash crossings, armor/empty-ammo baseline response, one opportunity per cycle, required cue geometry drift cancellation, full-precision paused warning/active/recovery/cancellation pairs and exact restored mid-dash path/landing/time. Act1's original request630692a0 is resolved at the shared consumer level; its authored arm art/beat/checkpoint composition remains its responsibility.

Act2 faaface0 clarifies Scout timing: tracking0.45, full locked lead1.10, active0.16 and recovery1.60. The previous0.80 lock was rejected by its conservative response arithmetic. The actual stationary source uses move_speed0; resolver support now retains true zero in every profile and rejects negative speed. Affected scheduler/profile69checks passed; no fakepositive speed is needed. Tracking adapter still must be separately tested/published, and its returned quantized deadlines remain authoritative.

The independent physical lunge helper initially passed planning but failed two actual wall-landings: a coarse full sweep and small physics steps found different numeric contact fractions. The repaired helper keeps the0.005m tolerance and uses bounded matching0.05m virtual/actual sweeps. It also guards real capsule/axis locks/source pose/velocity. Targeted result is13checks/0failures, not yet scheduler integration/act fairness acceptance.

Root remains the point of contact, with mailbox checks and quiet monitoring. Full goal remains active and all24 real levels await individual acceptance. No full-suite rerun after baseline.

Exact shared4 publication: `1ebd6b59265897d6ef49a29461473c52426b8fe6`; immutable canonical responses announce availability. Worker adoption is acknowledged individually.

## Shared consumer publication5

All three workers acknowledged exactshared4: Act1 537484c6, Act2 133f79a1 and Act3 47ef41bc; assigned checkout ancestry was independently verified, preserving all owned work. Root remains their explicit point of contact and checks recipient-tagged mailboxes plus compact thread snapshots regularly. All three active and on L1; no duplicate act owner or premature later-level work.

Tested threat-scheduler-3 tracking preparing/immutable full-lock reproof and actual physical-lunge/body lease additions are ready for adoption. Adapter35/lunge14/snapshot35/scheduler69 checks, zero failures. Lunge source prediction/execution now rejects depenetration/axis locks before real movement and uses matching bounded .05m sweeps; full swept warning/proof corridor remains distinct from actual moving-body damage. Scout consumes actual commit clock+full1.10lock; Stalker proposed3/12=.25 travel fits its .30active window. Act owners still compose actors, local hit dedupe, full encounters and portrait/loadout evidence.

Save/replay corrections passed shell52/menu54/persistence45. Failed completion/transition survives navigation; optional local completion cannot precede its reward stamp; relaunch of a latched side exit restores protected story; restart replay stages fresh selected equipment before atomic commit; Title Continue persists through final authored contact exit/coda. Failed restart preserves old world/HP/ammo/gear. Root inspected three actual540x1170 restart portraits. Public pure world-action codec passed directly affected world119/player72; actor behavior/clock/aim unchanged.

Act1 HUD requestae541bfa resolved by dynamic fitted objective/backplate height, text-change/flash/restore relayout and telemetry below. Actual graphical42checks/0; root reviewed two/three-line/wrapped portraits at540x1170. Text guidance is now fully visible. The separate running-arm aggregate-validation request13ff6828 is acknowledged; helper owns backward-compatible pure saved-player context validation for a separate tested publication. It does not delay these tested adapters/HUD.

Actual graphical desktop benchmark completed19.25s, six valid active scripted cells, Godot4.7.2/M3/OpenGLCompatibility/VSync60Hz. MeanFPS26.81–27.19 at30cap and50.69–51.43 at60cap, large stalls; every window unfocused. Per-cell timings and scope in DESKTOP_PERFORMANCE.md, ignored rawJSON/log retained. No foreground/campaign/thermal/mobile conclusion. Pythondevtools20+6subtests passed. No broad baseline repeated.

Unpublished bounded capture initially failed64/9, then76/4; repair remains targeted and no worker may adopt untested workspace files. Final physical captured replay/whole-sequence fairness remains future campaign-selected work. All24 real levels remain unaccepted. Default launch stays Character Lab; full desktop goal active. Exact shared5 commit is announced through canonical run/immutable responses after scoped publication.
