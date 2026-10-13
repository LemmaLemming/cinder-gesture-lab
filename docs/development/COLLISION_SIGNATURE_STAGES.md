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

Both temporary runtime instruments were restored to the exact published originals after closure. The next candidate skips world lookups for node types that cannot contribute collision, after enumerating their children. It retains the complete SceneTree walk and every relevant collider/world check. A separate uninstrumented pair and focused correctness checks are required before adopting it. Act 2 independently reviews an existing proposal to remove redundant placement-query calls; Act 1 retains ownership of those call sites.

The [original artifacts and scope index](evidence/collision-signature-stages/index.json) retain the failed first setup run, successful sink checks, native outputs, actual Exact witness files, original host failure and independent supplemental review. The first setup run stopped at a stale test assumption that accepted A1-L4 was unavailable; the corrected private fixture preserves every current non-L3 registry entry. The original checkpoint and timing assertions are unchanged. The supplemental review also retains its first failed host assertion: a restored dormant actor's logical grounded value differs from its disabled body's native `is_on_floor` value. Those distinct fields were preserved.

The actual optical Pause/save refusal and encounter-context diagnostic remain reported. This profile does not resolve them, claim arbitrary Script-state completeness, or change the campaign's 16/24 accepted levels. See the separate [entrance geometry diagnosis](CROSSED_ENTRY_GEOMETRY.md).
