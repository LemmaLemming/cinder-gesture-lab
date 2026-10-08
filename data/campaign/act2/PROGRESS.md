# Act 2 progress

Updated 8 October 2026. See [memory](ACT_MEMORY.md) and [current level](levels/A2-L1.md).

| ID | State | Next requirement |
| --- | --- | --- |
| A2-L1 | Tested floor/lifecycle and isolated target foundation; native portrait reviewed | Published tracking/cues/presentation/live shell, full primary-only/loadout/pause/retry/transition encounter acceptance and exact handoff |
| A2-L2 | Unimplemented | Begin after L1 handoff |
| A2-L3 | Unimplemented | Begin after L2 handoff |
| A2-L4 | Unimplemented | Begin after L3 handoff |
| A2-L5 | Unimplemented | Begin after L4 handoff |
| A2-O1 | Unimplemented | After all main levels; reuse L1 |
| A2-O2 | Unimplemented | After O1; reuse L3 |
| A2-O3 | Unimplemented | After O2; reuse L4 |

No Act2 level is complete or accepted. Registered codex/campaign-act2 adopted tested shared15589bf / campaign-shared-2 by fast-forward. Scenery, broad dry route, low housing and physical three-leg Scout poses are original prototypes. Only preview visuals are in the scene; the tested target adapter is isolated until shared tracking can drive a real exchange.

Evidence in assigned checkout:

- Initial missing-cache import and new-target class-cache import passed, no script/resource errors. Logs `.cinder/a2-l1-first-import.log`, `.cinder/a2-l1-target-class-import.log`.
- Owned `a2_l1_layout_smoke.gd`: selected spawn(-1,.1,2.6), actual dry-floor travel/ordinary flank dash/corner joins, pause, local JSON/invalid/missing-node rejection and reset cleanup;243 checks/0 failures. Log `.cinder/a2-l1-selected-spawn-layout.log`.
- Owned `a2_l1_scout_target_smoke.gd`: manual recovery target only, real Heavy primaries with0shells at1.8unit reach, phase/invalid/paused/dead/death reentrancy and cleanup;33 checks/0 failures. Log `.cinder/a2-l1-scout-target.log`. Spawn change does not invalidate it: the fixture sets its own target/hero positions before any attack, and floor/actor/shared player/gear contracts are unchanged.
- Six native540x1170/270x585 portrait poses inspected plus selected entry fixture. Logs `.cinder/a2-l1-portrait-revision2.log`, `.cinder/a2-l1-selected-entry-portrait.log`; images in ignored `captures/act2/`. Fixtures do not establish gesture play, real warnings/hit geometry, balance or source-art fidelity. Native portrait fixed camera unchanged; selected left spawn reveals cylinder/witnesses and retains player foot separation. Shared helmeted prototype remains until Act2 presentation publishes.
- Required canonical ability/equipment validation passed at revision0/no uses/no claims; numerical equipment screening passed. No new gear/ability placement or reward.
- Owned links/JSON/resource references and whitespace checked. Shared verified foundation evidence reused; no broad suite rerun.

Exact next task: read current mailbox/publication; adopt only the tested next compatible commit, add published tracking preparing/lock proof, live response and capsule cue to the Scout loop; compose owned actor/encounter snapshots with shared shell checkpoint/retry/transition. Complete functional full L1, then finish scenery/animations and actual encounter portrait/primary-only/loadout/paired-threat/pause/retry/reset/exit acceptance. Do not advance to L2 or hand off the preview as complete.
