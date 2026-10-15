# A3-O1 preserving adoption preparation

This is source-only preparation for Root, the existing sole Act1 owner. No merge, actual adoption receipt, ACK, mailbox/registration change, import or engine job has occurred. The checker has only read-only Git commands and writes its reports exclusively under `/private/tmp`; it cannot perform the adoption itself.

The designated publication is `de750e7eec4a70114637834ffe02a25952e40c1e`, based on already adopted `55c9994c7dd1da2ed69e6b0ce5a286b75fd5866d`. The common ancestor with the initial Act1 head `8b3f05e3c66ed2f94d04e00e425d6a533dcb958a` is exactly that baseline. The authoritative worker/checkout/branch/six owned paths are read from canonical `run.json`; the checker never changes them.

The initial capture is `preflight-at-8b3f05e3.json`, 200,726 bytes, SHA256 `493129a7b58d09414831b043513f910fe94cf63e2b1b9d50d0319c1e35d05145`. It is explicitly **not an adoption** and does not assert terminal job closure. If Root commits further case evidence or content, Root must make a fresh capture of that actual final head after all three terminal cases/jobs close. Do not apply the old capture to a different first merge parent.

The publication envelope was checked against all 418 incoming Git blobs and modes, totaling 10,180,676 bytes. No incoming path overlaps an Act1 owned path. The shared functional delta is only the A3-O1 registry row and one dev CLI alias. The GameSettings change is two comment lines with executable text unchanged. `exact_json.gd` is unchanged. Other registry rows and route metadata are equal. The designated A3-O1 scene/pin/API are retained exactly.

The capture records all six owned Git tree objects, 32 named physical critical files, and the three existing local settings (`project.godot`, `.cinder/local.json`, and present/absent `override.cfg`). The named files include O2 host/layout/codec/scene, campaign/terminal/portrait fixtures and their native UIDs/pin JSON, plus the small mechanics/groups fixtures and UIDs; the previous thirteen O1 critical files; and unchanged Exact JSON. It hashes only these named physical files and the 418 incoming target paths. No whole physical owned tree or historical evidence bank is recaptured.

Six new active UID sidecars come from the exact publication diff. Their six archive mirrors under `docs/development/evidence/act3-o1-integration/publication/archive/` are checked for exact matching bytes but excluded from active uniqueness. The checker verifies only the known 535 UID members named by the current completion01 source manifest, SHA256 `69be83e9c3c9169879c8c22ce15a1174d8cb06988fd02cbcbfb46eb036fbe391`; those source-bank bytes/modes/hashes are retained originals. The new six values are mutually unique and disjoint from that known set. Derived 541 is an expected union size, not a new physical all-files UID census. No UID or `.godot` resource is generated.

After Root establishes all three terminal cases/jobs are closed, Root should commit/review any tracked changes, read the current final head, and run a fresh capture with an unused private report path:

```text
python3 -B /private/tmp/cinder-act1-a3-o1-adoption-prep/check_adoption.py capture --expected-head <exact-final-premerge-head> --output /private/tmp/cinder-act1-a3-o1-adoption-prep/final-premerge.json
```

Capture checks tracked cleanliness without an untracked-file census, original merge-base/ownership, every incoming existing path's exact current baseline bytes/mode, and absence of an incoming new path. Any incoming target with existing untracked content is refused. It copies no source bank and performs no mutation. Root reviews the capture and independently performs the already authorized two-parent merge only at the safe boundary:

```text
git merge --no-ff --no-edit de750e7eec4a70114637834ffe02a25952e40c1e
```

Then Root supplies the fresh capture's printed SHA256 and verifies the actual merge:

```text
python3 -B /private/tmp/cinder-act1-a3-o1-adoption-prep/check_adoption.py verify --capture /private/tmp/cinder-act1-a3-o1-adoption-prep/final-premerge.json --capture-sha256 <exact-fresh-capture-sha256> --all-terminal-cases-closed --output /private/tmp/cinder-act1-a3-o1-adoption-prep/actual-merge-verification.json
```

The post-check requires actual parents `[captured_final_head, designated_publication]`, both ancestry relations, all six unchanged owned tree objects, exact same 32 named physical files and three settings, and exact incoming physical/Git blob bytes/modes for all 418 paths. It requires precisely the publication's twelve added UID paths (six active plus six archive mirrors), with no existing Git UID changed; it rechecks the bounded original known set. The job-closure flag is recorded as Root's explicit assertion, not an automated queue audit. Only after that real merge/verification may Root write the actual owned adoption receipt and canonical ACK. This checker does neither.

Original O2 results remain attributed to their original source revisions, failures, timers, settings and scope. The registry metadata intentionally changes on adoption: historical portrait pin JSONs remain exact and must not be rewritten to make their original strict source guards accept a new registry. Reuse the already adequate evidence for unchanged runtime behavior; any future actual rerun needs its own truthful source join. This preparation provides no new gameplay, import, visual, full-route or performance acceptance.

The earlier `/private/tmp/cinder-act1-adopt-o1-registration.py` and `cinder-act1-adopt-shared60.py` were read for their envelope, ancestry and preservation structure; neither was executed or modified. There is no broad physical UID/evidence census, new source copy, archive, or large diagnostic. At initial capture, the complete report was approximately196KiB and the script17KiB.
