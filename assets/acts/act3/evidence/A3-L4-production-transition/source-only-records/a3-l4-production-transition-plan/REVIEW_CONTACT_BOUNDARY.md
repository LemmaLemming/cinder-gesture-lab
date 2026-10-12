# Bounded independent contact-boundary review

Frozen originals remain exact: driver `0adef9a690b5b81b6aee590ff8aee75258c7a2d372fa55b4055abfbb395836e7`, recipient candidate `ceea10948d2ed26562029a21de1c0b369d77944f9727e6b9cc3eb7ceb12b6c82`, original patch/scenes/NOTES/custody unchanged. Root's current actual baseline is Shared50 (preserving adoption b9e123a8/d4ce48c5); this read-only review does not relabel source-as-read49 pins or native results. No engine/active/shared/Git edits.

## Concrete blocker and separate correction

Original driver `_contact_next` calls actual `request_test_component_contact` immediately after awaiting inherited `_complete_dash`. The inherited dash observes `MixedBarrier.observed.emit` inside `_physics_process` and returns on that call stack. Actual Shell `_enqueue` (`scripts/campaign/shell.gd:179–188`) deliberately does not pause immediately inside `Engine.is_in_physics_frame()`. Consequently its synchronous contact listener `_on_contact` would call paused-only `Hero.snapshot_state()` and require `paused` before the deferred Shell drain, retaining an empty departure actor/false contact support. The actual contact/exit can still be genuine; this is a fixture capture-order bug.

The separate `garden_mixed_production_transition_smoke_v2.gd` inserts the existing actual public `_completed_pause()` after the full ordinary dash and grounded capsule-contact assertion, before WeakRef capture/fixture barrier removal/contact request. It verifies exact actual Hero global transform, Hero/Scheduler clocks, completed action history and native capsule contact across that pause. The original `_on_contact` then reads the actual paused native outgoing actor legally. No dash/deadline/recovery/HP/geometry/IDs/input/resources are changed or loosened. The separate patch shows the only behavioral change. Publish v2 at the original intended test path; its own native run remains unparsed/unexecuted.

## Remaining requested surfaces

Independent child and parent source scans found no additional known blocker in:

- Exact transport: `_wire_exact` is tagged `ExactJson.stringify` equality. Independent Store.read_payload uses the exact format2 payload reader; plain JSON is only canonical registry parsing and the Store's outer text envelope. This fixture does not inject legacy/corrupt-primary/backup failures or claim a new SaveStore corruption suite.
- Native lifecycle: WeakRefs cover the actual installed native SubViewportContainer/viewport/stage/Hero/Core/Echo/helper/cues/Camera/fx and the separate fixture barrier. The barrier is removed and queued, not freed in an executing callback. Normal whole-unit exit retains raw owner cancellation/history semantics and final native group cleanup assertions.
- Replay/story: actual Journey/Start/Leave Side/Back/Continue buttons and public Shell operations are used. The protected story and campaign core stay exact; only the active replay and last_replay_equipment are intentionally new. Fresh recipient mechanics/clocks/history, tagged native packet comparisons and independent disk reads remain strict.
- One-shot progression: genuine final0/phase3/settled helper release/empty raw owners is required; exact canonical A3-L4/false-paradise-disengaged/adage-plain-threshold identities forward once. Premature, duplicate, far-Hero and foreign-body requests remain explicitly rejected.
- Recipient custody: the candidate replaces the same actual owned TEST Script path, preserves default noncampaign rejection, binds the opt-in immutably at ready, and applies quiet available/spent cue presentation only after actual base progress commit. No private shared fields, donor aliases or invented canonical late history.

Native parser/GUI/contact-floor landing/current-camera/actual engine ordering and full result still require Root's qualified run. Canonical late whole-parent history remains untested, as in the original notes; focused representative component evidence does not invent earlier court receipts.
