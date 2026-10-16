# Bounded v3 delta review

Reviewed immutable `comparison-v3.gd.txt`, SHA256 `2e8c703052cf01c1fa5e575550a001bd3ac165879ede747b248089c33b518f5e`, against preserved v1 `16647573`. No further concrete issue found in this bounded delta.

All five v1 findings are addressed:

- The watchdog records a fault only. Main waits now unwind on `SceneTree.process_frame`; cleanup does not independently free an awaited probe. This grants no physics progress and leaves a stalled engine to the external wall watchdog.
- Output creation requires an absent leaf under an existing parent, rejects traversal syntax and uses exclusive leaf creation. Only successful creation sets `owns_output_root`; both artifact and report writes require ownership.
- Required external fixture/control SHA selectors bind actual source bytes. The control file must contain exactly the 36 selected dependency/helper keys; Host remains separately pinned. Both arms require identical fixture/control/dependency pre/post hashes. Original baseline diagnostic artifacts are hash-checked.
- Exact diagnostic and native-report writes flush, inspect error, compare literal UTF-8 bytes and SHA, and cannot credit a successful footer after failed verification. Any best-effort failure rewrite remains explicitly unsuccessful.
- Helper and report wording now describe the actual constructor position, including supported Y.

The changed admission-error loop checks every real reported source, including bootstrap and the naturally live bank. Native response/proof/cadence logic is otherwise unchanged by this delta. This stricter refusal rule can legitimately stop a future native case; it is not evidence that the case will pass.

Verified selected control metadata: `comparison-pins.json` SHA256 `f817d6edbd33326a308d4da613101fb4e9bf47af8030103c6bba0163c62165da`; 36 exact keys, all 33 canonical physical inputs and three inert helper byte hashes match. `focus_game-v2.gd.txt` SHA256 `934cab0d867efb8e7275623569f488c6b184a621ce8fa63389d93c9c8608dc75`; House and policy remain unchanged. Supplied manifest SHA256 `d73d0c2a37fba619dde299e07bde63dfd352907549ebc6b36e3f899290d04572` names these same deliverables.

Source-only review: no parser, engine, executable fixture, runtime mutation, native outcome, gameplay novelty or portrait acceptance. The v1 review remains separately preserved in `comparison-review.md`.
