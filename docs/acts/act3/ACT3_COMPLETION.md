# Act 3 complete: Tormance, The False World

All five main levels and all three optional levels are implemented, integrated and independently accepted for desktop under [focused-desktop-level-1](../../development/LEVEL_ACCEPTANCE.md). Act 3 is **8/8 accepted**. The [campaign registry](../../../data/campaign/registry.json) now contains **15 main and 9 optional accepted levels**.

The act retains its progression from alien wonder through watched life, deceptive reflection and false comfort to repetition exposed and local escape. Optional levels reuse their parent environments and award only their existing once-only completion stamps, without stat growth.

| Level | Name | Parent / route | Status |
| --- | --- | --- | --- |
| [A3-L1](../../../data/campaign/act3/levels/A3-L1.md) | Twin Suns | Main route | Accepted |
| [A3-L2](../../../data/campaign/act3/levels/A3-L2.md) | Living Forest | Main route | Accepted |
| [A3-L3](../../../data/campaign/act3/levels/A3-L3.md) | Mirror Sea | Main route | Accepted |
| [A3-L4](../../../data/campaign/act3/levels/A3-L4.md) | False Paradise | Main route | Accepted |
| [A3-L5](../../../data/campaign/act3/levels/A3-L5.md) | Crystalman | Main route | Accepted |
| [A3-O1](../../../data/campaign/act3/levels/A3-O1.md) | Pillars Before Their Time | A3-L1 | Accepted |
| [A3-O2](../../../data/campaign/act3/levels/A3-O2.md) | The Quiet Root Circuit | A3-L2 | Accepted |
| [A3-O3](../../../data/campaign/act3/levels/A3-O3.md) | Irontick's Last Reflection | A3-L3 | Accepted |

## Acceptance and evidence

The linked level records preserve their original acceptance messages, source revisions, art references, tests and limitations. Earlier accepted levels were not rerun for this closeout. Specific integration records cover [Mirror Sea](../../development/A3_L3_ACCEPTANCE.md), [False Paradise](../../development/ACT3_L4_ACCEPTANCE.md), [Crystalman](../../development/ACT3_L5_ACCEPTANCE.md), [O1](../../development/ACT3_O1_ACCEPTANCE.md), [O2](../../development/ACT3_O2_ACCEPTANCE.md) and [O3](../../development/ACT3_O3_ACCEPTANCE.md). Twin Suns retains its [registration evidence](../../development/evidence/A3-L1-registration/index.json); Living Forest retains its [original evidence](../../../assets/acts/act3/evidence/A3-L2-crescent-rule/index.json).

O3's independent production registration passed **137/0**, complete and clean, covering canonical optional entry, entrance Retry, Pause Save, independent fresh Title/disk Continue, early Leave to protected Story, quiet callbacks and normal cleanup. The [integration evidence](../../development/evidence/act3-o3-integration/index.json) has SHA256 `27043359160bb52046a3cd46a6e90471025dcc637e096fd6385f4832f9965736`.

The [original O3 handoff](A3_O3_FOCUSED_HANDOFF.md) and [184-file evidence pack](../../../assets/acts/act3/evidence/A3-O3-native/index.json) retain 22 closed runs, including failed and diagnostic runs. Final focused owner scopes are mechanics **3660/0**, held transport **168/0**, CP1 **3735/0**, CP2 **1484/0**, completion/return **1443/0** and initial-warning portrait **90/0**. These original runs retain Shared62 attribution; integration's 137-check run separately exercised Shared64. The original evidence index SHA256 remains `9312c5d0af3dc3d266fcc1d60f4f1cca081745955367792d947c82737fc01824`.

## Final publication and actual adoption

- Canonical O3 acceptance: `14dd408e-bb92-42d8-a458-f87c7e40e3f0`.
- Accepted owner handoff: `b92a56556c8fdce4f32be9c2b379aa73c2f8e243`; content/evidence seal `14f81fbe9348110b851765da46478694581a9e34`.
- Integration publication: `2b7edaa146d542b25f4546819ea5673df83f48da`, Shared64.
- Actual preserving adoption: `c6680ac8829441fb193ba3570c54d3d899f9880e`, with the owner handoff and integration publication as its exact parents.
- Adoption receipt: `.cinder/act3-o3-acceptance-adoption-after.json`, SHA256 `0e5542d41f19a55fc42dd28b4833a967b80fe444bf13399261ad8e7b41ae20d0`; canonical ACK `d28266d9-b9be-4c5b-9d04-88e14791b756`.

The adoption preserved all 18,753 prior owned Git/index rows and 196 named physical sources, hosts, UID files, settings, previews and original packets. All 444 incoming Git/index rows match the publication, including 204 already-identical owned rows; 240 paths actually changed. The five pre-existing untracked Mirror Shore previews remain untouched. This is scoped preservation evidence, not a whole-project physical or UID census. All owned native job handles are closed; no new engine/import run was needed for documentation or adoption.

## Remaining limits

Focused acceptance does not establish a human-earned full campaign or level traversal, all-enemy completion, all-kit balance, 3–5 minute human pacing, moving/lateral/full-board art fidelity or sustained FPS. O3's original initial-warning portrait was inspected; its two extra CP1 capture attempts remain failed and CP1/CP2 pixels remain uninspected. The original failures and diagnostic results remain in the evidence pack, without an inferred focus cause or relaxed shared capture guard.

Separate shared difficulty-policy and captured-Assisted compatibility work remains with integration. A private A3-O2 difficulty proposal was requested after this closeout; it is not a new production change or a condition on these acceptances. The original eight-level objective is complete. Mobile export, signing, device testing and release are outside this desktop milestone. No public push is part of this closeout.
