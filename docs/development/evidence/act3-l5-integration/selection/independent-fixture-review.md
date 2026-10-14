# Independent A3-L5 registration source review

Reviewed private draft SHA-256 `6ef46db986be2dc80c179f6b8ea492d6463be36d4ccb6f537fc76b2be3ab0de2` against submitted content `83a6efa2509b5c7f5e408f3ecb4324f53d1e496d`, current Root shared sources and the registered Act3 checkout. No engine, parser, production or worker edits. This is source review, not execution or acceptance.

No blocking schema, inherited-flow, lock or terminal-link defect found. One concrete error-path cleanup defect: draft lines 12–15 call `quit(1)` directly on watchdog expiry, bypassing `_finish_registration()` and inherited `close()`. After line 32, that can leave this run's isolated `user://test-act3-l5-canonical-*` saves/settings behind. Route a returning-loop timeout through the same idempotent cleanup path, retaining the failure, instead of directly quitting. The watchdog cannot recover a blocked synchronous engine call; Root's external bound remains necessary.

The overridden `_initialize` schedules only the overridden `_run`. The derived run calls `pair`, `same`, `_await_seeded_startup`, `expect` and `close`; it never calls the parent's `fresh_candidate`, `negatives`, `campaign_transport`, `coda_contact` or broad `_run`. No inherited full combat, Save/Retry or contact cycle is silently re-executed.

Both production Shells receive `configure_runtime({})` and isolated paths. The accepted row pins exact content, scene and API. Registry validation plus `previous_main_id=A3-L4`, accepted L4, `next_main_id=null`, empty `next_main` and final main-route position are coherent. Empty-session Journey checks the actual generated locked card/body and unchanged session. The explicit first-fourteen prefix is a structurally valid test history, and the protected story/checkpoint carries the unchanged native Player/parent pair from the real canonical preview. Literal initial Shell fields agree with current `Game.reset_lab` defaults; camera focus derives from the actual camera and current offset. Production startup performs the native validation. Exact restored unit, session and SaveStore reread comparisons give a coherent canonical entry check.

GUI scope must remain precise: lines 41/43 invoke the public Journey signal and `select_level`; line 93 emits the public Continue signal. No real mouse/touch events or Button `pressed` observation occur. Existing wording says public operation and does not claim a GUI click. Do not report this as GUI Continue, disabled-button interaction, or scroll/hit testing. No new GUI gate is needed to reuse the owner's separately scoped 99/85 evidence.

The seeded startup wait requires the exact complete public session, avoiding the known pre-load Title shortcut. The fresh entry wait requires the first real Level/Hero and Resume. In current Shared58, startup/load/Continue have no further yield after publishing those exact states, so this initial-load scope does not inherit the stale Resume replacement problem. The current 60-process-frame bounds can produce a genuine bounded fixture failure; they are not elapsed-time guarantees. The normal finish invokes the existing level exit/queue-free cleanup, waits three process frames and checks actual parent/Hero/Shell weak references. It does not independently assert every descendant or successful removal of the isolated directory; keep that cleanup claim limited.

Terminal coverage here is canonical null-successor metadata at initial entry, not earned final contact or a completed campaign state. Owner99/85 remain reused; no repeated final-contact, boss, Save/Retry or full-route gate is introduced.

Named bytes checked against the sealed content and physical worker files:

- `tests/acts/act3/crystalman_parent_transport_smoke.gd`: `3344ec10095f9d760521fa834b8ebdefee78c05950e77212e975605a86485608`
- `scripts/acts/act3/crystalman_level.gd`: `456095c10d1fd0058c8db7ae2ef900efe6a52e40f35e8534b947067ca6fabde1`
- `scenes/acts/act3/a3_l5_crystalman.tscn`: `887b4332fab4a506c0f697171cd4c40d0fe85a7ef35b1b948e4c6b89fee6a790`

Current Root `shell.gd`, `game.gd`, `campaign_menu.gd`, `attempts.gd` and `save_store.gd` also equal their submitted-content versions. Root Shell SHA-256: `f8df3b798544b79d66985f5e468f13ade5485bccc6050b54c9d9d242b3211a0f`.
