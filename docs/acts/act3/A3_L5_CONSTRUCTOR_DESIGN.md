# Crystalman: proposed closed parent construction

**Source-only design for Root selection, 16 October 2026. Unimplemented and untested.** This settles one proposed wire and dispatch table for the [single west-inset hypothesis](A3_L5_DIFFICULTY_PROPOSAL.md). Authority is RESPONSE `23935683-4b63-492b-bb5d-9bac2838ff91`, ACK `5efc073b-a28b-4168-a5e4-0934a425e565`. [Design evidence](evidence/A3-L5-difficulty-proposal/constructor-design-index.json) pins the literal messages and current sources at `060ca094aab76c73b16f8c602fa82beb55481487`, actual Shared74. Root selects this design before any production implementation. Nothing below is a live schema, executable fixture or producer.

The original wall illustration compares **different X starting anchors**. Same-start west dashes have identical wall clearance until their actual paths diverge. Initial knot range alone establishes no new decision. The [inert comparison text](evidence/A3-L5-difficulty-proposal/comparison-fixture.inert.md) requires complete actual safe/useful responses against the whole held union, zero contacts/hits as well as unchanged HP, then an observed decision difference. Its declared component has no full-prefix, old-held, all-enemy, earned-exit, full-route or all-kit gate. This supersedes those broader future prerequisites in the original proposal; historical proposal/evidence bytes stay exact.

## One proposed wire

Use exact typed keys; reject missing, extra, wrong-type and unknown values. `int` excludes `bool` and `float`. Profiles use the native canonical numeric types and exact scalar bits, not coercion or tolerance. Every unchanged nested branch retains its existing validator.

| Parent branch | API / schema | Exact top-level keys |
| --- | --- | --- |
| Literal legacy | `act3-crystalman-parent-local-1` / int1 | `api_revision:String`, `schema_version:int`, `world:Dictionary`, `route:Dictionary`, `current_unit:Dictionary`, `presentation:Dictionary` — six |
| Proposed new | `act3-crystalman-parent-local-2` / int2 | The same six, plus `approach_policy:Dictionary` — seven |

The proposed `approach_policy` has **exactly four keys**:

| Key | Exact type / value |
| --- | --- |
| `api_revision` | String `act3-crystalman-approach-policy-1` |
| `schema_version` | int1 |
| `profile` | Full canonical eight-key profile Dictionary below |
| `recipe_id` | String from the three allowed profile/recipe pairs below |

`profile` has exactly `id:String`, `name:String`, `raw_damage_multiplier:float`, `windup_multiplier:float`, `recovery_multiplier:float`, `reserved_threat_budget:float`, `commit_stagger_s:float`, `arrangement:String`. It must equal `Difficulty.profile(profile.id)` from the pinned catalogue under the existing exact native comparison; every numeric field is finite and retains its canonical value. An ID alone is insufficient because no Approach Scheduler survives in parent stages2–4. This full profile is construction identity, not proof of earlier play.

| New `profile.id` | Required `recipe_id` | Resolved source rows |
| --- | --- | --- |
| `assisted` | `canonical-approach-1` | Original base rows |
| `standard` | `canonical-approach-1` | Original base rows |
| `challenge` | `challenge-west-inset-1` | Only complete `l5-plain-echo` translates X−2.3 |

No other pairing, user transform, row override or serialized arbitrary geometry is allowed. Resolve the finite map from immutable base JSON: both plain route points X−0.7→−3.0, knot/slash origin/definition translation X−3.0, and matching physical source/cues/native definitions. Preserve Z15.5→17.5, 0→0.30s, +Z slash, source ID/epoch, raw roles and all other rows. Harmless reflection follows its existing offset. No capture tether/profile, wall, floor or shared changes are part of the map.

The old nine-key `world` stays literal: `layout_sha256:String`, `level_id:String`, `world_revision:int`, `floor_id:String`, `floor_signature:Array`, `permanent_box:Array`, `permanent_center:Array`, `blockers:Array`, `source_scripts:Array`. Compare the entire branch with the original native-world recipe: unchanged base layout SHA `26831d7447e217a57ed173090c82d88c3a437368c6abfda930de3e99fbc0d7c6`, A3-L5/revision1, original floor signature/12×1×54m box/centre/blockers/scripts. Retain existing exact nested vector/blocker types. Do not put resolved rows or a policy into `world`.

The old eight-key `route` stays literal: `stage:int`0–4, `entries:Array`, `regular_metadata:Dictionary`, `phase_metadata:Array`, `pending_checkpoint:int`−1…stage, `phase_observed:bool`, `exit_state:String`, `contact:Dictionary`. Existing earned-entry/death/retirement/phase/contact/progress validators remain. `current_unit` keeps exactly `kind:String,state:Dictionary`; `presentation` keeps Scenery’s closed stage validator. Base outer level/Player/session/Story formats are unchanged.

## Constructor dispatch and persistence

First perform pure transport/type/version/profile/recipe checks while paused with the parent’s original floor/walls available. Freeze the selected legacy mode or new policy **before strict expected-world validation and before `add_child(Approach)`**, because Approach `_ready` copies source rows. Pure selection cannot configure a Scheduler, admit/cancel a lease, arm a Gate or rewrite the Hero. Then validate the immutable world and entitled topology; construct only the current child, perform its unchanged native validation/quiet restore, and commit atomically.

| Parent stage | Entitled current topology | Legacy six-key construction | New seven-key construction |
| --- | --- | --- | --- |
| 0 | `regular`, Approach stage1, offered Echo only | Canonical rows; saved full child Scheduler profile before once-configuration | Saved policy profile and resolved map before child `_ready`; full child profile must exactly equal policy profile |
| 1 | `regular`, Approach stage2, retained offered history plus C50/plain Echo | Same canonical rows, including old Challenge; saved child profile | Same policy/profile join; whole native source definitions, physical knots and staged views must match resolved rows |
| 2 | `capture-one`, slots1 | Canonical Approach identity remains implicit; no new descriptor/profile invented | Retain policy unchanged as past Approach identity; do not recreate the disposed Approach |
| 3 | `capture-two`, slots2 | Same legacy mode | Same retained policy |
| 4 | `none`, empty state | Canonical legacy writer, no native child | Same retained policy, no native child |

At stages0/1 the Approach remains `act3-crystalman-approach-local-1`/schema1, exact eight keys/world5, with the existing full native Scheduler3. For the new branch require `approach_policy.profile == current_unit.state.scheduler.profile` and its ID equal `current_unit.state.world.profile_id`, in addition to every existing native leaf/profile/world join.

At stages2/3 the current capture child independently authenticates its own existing Root `act3-crystalman-captured-phase-2`/schema2 or `act3-crystalman-captured-phase-3`/schema3 policy and full profile before its once-configuration. It need not share the earlier Approach profile. Fresh later capture entry keeps Root’s current preference rule. Never pass Approach policy into CapturePhase/Gate/Playback, infer past Approach profile from a capture child, or edit Root PRIMARY. At stage4 no Scheduler is created merely to validate the stored Approach profile.

For new stages2–4, also join the immutable fixed Echo death positions in existing regular metadata to the selected fixed knots. C50’s death position is actual dynamic history and must **not** be forced to its initial spawn. Existing journal hash/clock/disposal checks remain; this extra fixed-position join does not reconstruct or certify a lost native journal. Literal legacy metadata validation remains unchanged.

Fresh new attempts select the canonical profile once at Approach entry, emit the new branch and retain that same policy through every stage/checkpoint. Every restored legacy attempt remains a six-key canonical writer through all later stages, Continue and original Retry, regardless of a later menu preference; it is never promoted. Each restored new checkpoint selects its own saved policy, never the future preference. Preserve the original checkpoint pair and shared Story/session handling; the parent policy grants no authority to fabricate or convert checkpoint history.

## Negative cases and quiet recapture

| Rejected input or failed persistence invariant | Required observation |
| --- | --- |
| API1 with schema2/policy; API2 with schema1/no policy; unknown API/schema/key/type; Boolean version | No permissive fallback to the other branch |
| Four-key policy missing/extra/unknown fields, ID-only profile, altered scalar/name/arrangement, nonfinite value, wrong recipe/profile pair | Full canonical profile plus one exact finite map required |
| Changed world/base hash/floor/wall; partial Echo movement; canonical source under new Challenge recipe or translated source under legacy | Native definition/body/epoch/whole journal/view binding must agree with selected construction |
| New regular child Scheduler/world profile differs from policy; source IDs/stage/slots/current kind mismatch | Reject mismatched current topology, not repair its saved branches |
| Descriptor disappears after regular disposal, changes during coda/Retry, or follows future preference | Preserve original format and selected attempt identity |
| Invalid capture packet under its own Root API2/3 validator | Reject independently; a different valid capture profile is allowed |

Closed construction is not a provenance signature. Before the changed source exists, a consistently rewritten prefix lacking the changed plain Echo may be structurally indistinguishable; after disposal, existing metadata cannot recover the historical Approach profile or whole journal. Do not claim rejection of every consistent forged history. Genuine archive custody and unchanged saved pairs provide only their recorded scope.

For every later authorized negative test, retain the installed donor’s complete Player/local state, clocks, source identities, leases, hit prefixes, input/optics and session/disk bytes. Dispose a failed quiet candidate normally. No old journal filtering, proof retiming, re-admission, synthetic death or partial fallback. For a valid candidate, once-configure only entitled fresh recipients, restore native state and verify exact whole Player/local recapture including policy/legacy absence, route/progress, phase state and presentation. It stays paused and emits no attack/capture/contact/completion or gameplay input. Only the existing final optical gate can finish the candidate. These are proposed invariants, not executed results.

## Existing packets and next boundary

[Bounded archive inventory](evidence/A3-L5-difficulty-proposal/legacy-packet-inventory.json) records only the already-known genuine four-file Standard C50 archive. It supports its actual parent/regular-warning scope, not old Challenge, captured phases or genuine late MAIN checkpoints. Missing legacy phase coverage remains explicit. No new producer, compulsory old-held/full-prefix traversal or full-route gate is introduced for the declared comparison.

Original proposal/query/source evidence and all native failures stay byte-exact. No catalogue/playstyle change or allocation is made. All eight Act3/all24 original acceptances and16/24 difficulty policies remain; this adds no coverage. **Stop after submitting this exact design and inert fixture text for Root selection.** No live runtime/art/recipe/Codec/schema, executable test, producer, engine, shared/Root PRIMARY or other-act changes; Agent02 stays untouched.
