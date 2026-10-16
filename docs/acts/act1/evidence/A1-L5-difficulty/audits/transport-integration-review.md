# Private L5 transport integration

Source-only and unexecuted. No owner checkout, engine/import, Git or runtime changes.

- Combined source: `a1_l5_difficulty_transport_draft.gd`, 686 lines, SHA256 `fec85a9f85d94bfe164c389853b44650f61d89ada2ffe46373bfb51864aa10d8`.
- Diff against frozen fresh draft a68ae: `fresh-to-transport.patch`, SHA256 `35714c0ba524bc7d450032b3930f786339952717e0d23d864c2302fb6daa6c48`.
- Original producer eceb9a5b, fresh draft a68ae4705 and transport fragment 1feb3e21 remain unchanged. The fragment has two reviewed function corrections (`_transport_read_input`, `_run_metadata_case`) plus one narrow native-refusal helper; `transport-fragment-corrections.patch` records the exact delta. Existing producer helpers remain byte-for-byte unchanged; only `_run` dispatch, `_case_scope` and `_finish` integration differ, plus the new strict argument parser and request field.

## Exact invocation contract

Producer/entry cases take only `--case=legacy-producer`, `--case=fresh-producer` or `--case=selectors`.

Each transport invocation takes exactly five nonempty selectors, each once:

```text
--case=transport|metadata
--source-report=<actual complete original producer native.json>
--source-sha256=<full SHA256 of those original report bytes>
--branch=cp2|cp3|first-final-blink|first-final-sneeze
--future-profile=standard|assisted|challenge
```

The future profile must differ from the actual saved entry profile. Unknown, duplicate, missing or producer-incompatible arguments are rejected. Omit the runner's optional `--report`: this fixture uses its automatic report path, and the strict parser intentionally rejects that flag. Transport and metadata require exact promoted runtime host89dc/codec25bc/recipe06b65. The old producer path still requires old host9056/codec2fafe. Transport dispatch occurs before native probes or fresh Story construction; no pristine seed or gameplay Resume is called.

The currently sealed original input is `res://.cinder/l5-difficulty/legacy-producer01/native.json`, SHA256 `b0f68e2359f7703e0115f58dbf22bdfa397db6769e305a4ad9711e29993ac380`: actual `legacy-producer`, 168 checks, zero failures, complete true, branches entry/cp2/cp3/first-final-blink. This readback confirms its interface only and supplies no new native test credit. The separately closed fresh producer is `res://.cinder/l5-difficulty/fresh-producer01/native.json`, SHA256 `4375d37e0bfa65571b3a43ff080ae8b7aa7d35ad26baebb50668f87442970b14`, actual172/0 complete. The old native source map omits the recipe key; this is explicitly recorded as not pinned, never relabeled as an original absence witness. A literal old `<absent>` pin is also supported. Only that controlled legacy addition is excluded from ordinary source equality; current and genuine fresh producer recipe must exactly equal06b65, and fresh host/codec must match89dc/25bc. The runner source bank retains separate historical file-presence evidence.

## Scope and review

`transport` clones all archived original files from their exact hex/byte-count/SHA records into an empty unique recipient directory, then performs real fresh Title Continue, public opposite future preference and paused Save. It compares full original current/checkpoint/Attempts plus installed retained policy and quiet callbacks. Only `--branch=cp2` performs public Retry, using that independent whole fourth-primary branch; its expected snapshot replacement is comparison-only. CP3 and first-final branches stay paused and receive no transplanted checkpoint.

`metadata` first exercises a valid real staged candidate and paired Player-to-level quiet commit with current presentation validation. It then submits complete typed malformed copies solely to test exact refusal before native source binding/policy installation, retaining native/donor/disk state and normal cleanup. The matrix has seven legacy and seventeen new-format rows: missing/extra local fields, exact API/schema types and mismatches in both directions, required/closed descriptor fields, all descriptor string types, unknown profile/recipe/initial attack and canonical wrong-profile receipt. Bracket String-key assignments preserve intended typed JSON; no coherent v1 downgrade detection is claimed. A separate candidate additionally stages valid metadata, first accepts the true paired baseline, then rejects a copied saved eye x-position +0.125 through the existing native immutable-position check. Its full physical state, staged intent and installed schema0 remain exact; actual error and zero callbacks are retained, and it is normally disposed without committing the bad packet. These malformed copies are never producer provenance or saved campaign history.

The report keeps all original producer fields/assertion rows/footer and adds `transport_request`; input provenance, original counts, hashes, complete exact wires and actual observations remain in `receipts`. Original assertion counts are not added as newly executed checks. Finish can retire zero descendants after a preconstruction input refusal without inventing a cleanup failure; that original refusal still makes complete/success false. Every created Shell/source/cue/candidate is otherwise disposed normally. Input originals are checked before cleanup; cleanup writes only the unique recipient path.

Checked actual inherited helpers, promoted metadata/policy APIs, raw candidate entry and native unbound reference names. No definite source/API issue found. Native parser, registration, exact quiet callback counts, optical restoration and real Save/Retry behavior remain unexecuted. No future phase-three behavior after CP2 Retry, final held-landing/return distinction, full route, boss defeat, portrait, gesture, balance or performance claim is added. Historical failed/incomplete jobs and their source attribution remain untouched.
