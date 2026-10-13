# Collision signature stage measurements

On 13 October 2026, a focused native Crossed profile closed **25 checks, zero failures, clean diagnostics**. Its host verifier then failed because it treated the deliberately tagged native Dictionary as plain JSON. The original unsuccessful wrapper result remains intact. A separate host-only review correctly decoded the retained files and verified their byte/hash joins, nineteen actor packets/native observations, eight Protocol references, clocks and poses. No engine rerun was needed for that correction.

The measured interval contains eight actual physics frames, one process frame and 0.133333 Player/Scheduler seconds. It takes 6,092,211 microseconds with instrumentation enabled. Each of the 2,944 collision-signature queries visits 846 scene nodes and records ten colliders and ten shapes.

| Sequential collision stage | Measured microseconds |
| --- | ---: |
| Tree traversal and filtering | 1,297,049 |
| Collider and shape extraction | 194,015 |
| Sorting | 23,210 |
| Snapshot codec validation | 1,029,613 |

The enclosing signature measurement is 2,969,818 microseconds. The difference includes instrumentation and other enclosing work; other Protocol method timings overlap and must not be added to these stage totals. This is an instrumented workload, not production FPS or proof of a speedup.

Both temporary runtime instruments were restored to the exact published originals after closure. The subsequent two-line candidate skipped world lookups for node types that cannot contribute collision, after enumerating their children. It retained the complete SceneTree walk and every relevant collider/world check. The actual focused semantic differential closed **44 checks, zero failures**, comparing the exact original and candidate on the same native worlds. This establishes the fixture's signature/error equivalence, not general gameplay or performance success.

The subsequent uninstrumented pair also closed cleanly: **baseline 24/0 at 5,619,508 microseconds; candidate 24/0 at 7,150,250 microseconds**. Each measured window advanced eight native physics frames, one process frame and 8/60 Player/Scheduler seconds. The actual complete nineteen-actor/Player/Scheduler packet files are byte-identical. The candidate took **27.2398% longer in this single pair**; this does not establish a repeatable or causal timing effect. No performance benefit was demonstrated, so the candidate was withdrawn and the exact published original Route (`2bdfd3ea…`) restored. No production change was adopted from this experiment.

The [pair archive and hash index](evidence/collision-traversal-pair/index.json) preserve the original parse/window results, logs, manifests, actual witness files, narrow fixtures and **44/0** differential evidence. Its [independent host review](evidence/collision-traversal-pair/host-review.json) joins their hashes, tagged native observations, clocks, poses and frozen inputs without another engine run. The complete 787-input measurement bank and 483-input differential bank remain local dependencies; the [archive scope](evidence/collision-traversal-pair/README.md) explicitly identifies them instead of copying them. The pair adds no sustained-FPS, optical Pause/save, full-route or campaign acceptance claim. Act 2 independently reviews an existing proposal to remove redundant placement-query calls; Act 1 retains ownership of those call sites.

The [original artifacts and scope index](evidence/collision-signature-stages/index.json) retain the failed first setup run, successful sink checks, native outputs, actual Exact witness files, original host failure and independent supplemental review. The first setup run stopped at a stale test assumption that accepted A1-L4 was unavailable; the corrected private fixture preserves every current non-L3 registry entry. The original checkpoint and timing assertions are unchanged. The supplemental review also retains its first failed host assertion: a restored dormant actor's logical grounded value differs from its disabled body's native `is_on_floor` value. Those distinct fields were preserved.

The actual optical Pause/save refusal and encounter-context diagnostic remain reported. This profile does not resolve them, claim arbitrary Script-state completeness, or change the campaign's 16/24 accepted levels. See the separate [entrance geometry diagnosis](CROSSED_ENTRY_GEOMETRY.md).
