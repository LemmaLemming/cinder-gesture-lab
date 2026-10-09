# Withdrawn numeric comparison experiment

The numeric-zero Cue candidate is withdrawn. Production `scripts/cues/threat_cue.gd` is restored exactly to Shared39 SHA256 `c8a7abbbd4c021ec92c45e1e57fc966873110231b781dba00bd1ff3d63f5cc5a`. The candidate and its test remain original evidence only; no new runtime API is published.

The candidate retained the private bind-derived finite reference tree, original comparator and subclass fallback, current event traversal, and every native/callback guard. Strict float types used native exact equality for nonzero values. Numeric zero still encoded the fresh value and compared all64 bits, preserving signed zero and subnormal identity. The matching Godot4.7.2 commit uses [direct native equality](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/core/variant/variant_op.h#L428-L482) and [complete signed64-bit decoding](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/core/variant/variant_call.cpp#L834-L856). No epsilon, current authority cache or native guard bypass was introduced. This relies on the existing private finite-reference trust boundary; it does not support forged nonfinite private byte trees.

Actual targeted correctness closes2499/0, exit0, with133 original input copies and clean full native/wrapper logs. All439 earlier assertion strings and order are retained. The2060 new assertions exercise20 byte-built finite edge values, exact roundtrip/admission, all scalar pairs, each triplet position, typed containers and integer/nonfinite/native-type rejection. This proves the candidate's bounded comparison correctness, separately from timing.

The unchanged authored one-Box native profile closes113/0 twice. Both127-input sets retain the same native engine, exact Scheduler/Player,72 automatic advances plus one separate admission advance,1.2 simulation seconds, phase counts16 warning/23 lock/14 active/19 recovery, two completed dashes, one ordinary20-damage primary and source defeat. All113 assertions match in order; Cue is the sole common runtime difference.

| Actual run | Median advance | p95 | Maximum | Separate Cue probe median |
|---|---:|---:|---:|---:|
| Numeric candidate a4518729 |54.840ms|111.001ms|174.924ms|1.999ms|
| Published Shared39 c8a7abbb |47.812ms|50.657ms|94.899ms|1.647ms|

No measured gain supports adopting the extra helper and branches. A third repeat was unnecessary for this withdrawal decision. These separate bounded runs do not establish sustained FPS, production16-visual cost, a latency threshold, full-level acceptance, portrait readability or mobile performance. Both production cost requests stay OPEN.

[Original evidence](evidence/cue-numeric-comparison-withdrawn/index.json) preserves387 original source/resource copies, all six raw streams, three actual closures, two full profiles and the private draft/selection/withdrawal. Its413 hashed artifacts total7,669,319bytes, plus index. Historical prequeue statuses remain untouched; closure records qualify them. The original freezes are explicit/literal bounded subsets, with no global import-graph claim or later UID backfill. Only the changed comparison and directly affected authored profile were run; no broad or unchanged full-level suites were repeated.

A future experiment may reduce redundant expected-program safety walks in a fresh authored reader. That requires its own full candidate/native validation and cost measurement; no implementation or gain is claimed here.
