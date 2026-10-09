# Side attempts return to Journey

The shared Shell returns to Journey after finishing or abandoning an optional/replay attempt. It first prepares and installs the complete protected story, including equipment, resources, encounter state and aim. Explicit Continue Story from a side attempt uses the same restoration transaction and then offers paused Resume; a completed terminal story remains on Journey. Menu input remains consumed before combat.

`_leave_side(continue_story = false)` defaults to Journey. Only the explicit Continue operation passes `true`. Save failure, candidate validation, disposal, installation and reward transactions are unchanged. This implements the saved [UI flow](../UI_DESIGN_PLAN.md) without adding equipment rewards or changing accepted levels.

## Focused verification

Both actual jobs used `python3 scripts/dev/dev.py test campaign_shell` through the canonical Godot queue, on Godot 4.7.2 ed1daf0bf. Each retained 87 original prequeue source/resource files with matching archive/current hashes at closure. These are explicitly isolated live Shell fixtures, not act playthroughs or actual operating-system focus tests.

- First run: 55 checks, one failure. The new abandonment assertion incorrectly reused an earlier protected snapshot after the fixture had performed a real swipe. The later side-start correctly persisted that newer story through the existing production transaction. Original failure and inputs are retained.
- Corrected fixture: capture the actual later pre-side aggregate, verify whole-unit equality at side entry and after abandonment, retaining the swipe observation and every invariant field. Shell code did not change during the repair.
- Second run: **55 checks, zero failures**, exit 0, no Script/Parse/ERROR/WARNING diagnostics. It covers finished replay/optional return and abandonment to Journey, explicit paused Continue, menu tap consumption, whole protected story restoration, existing saves/retry/error flows and the terminal ending.

No new act scene, full route, defeat-all behavior, new artwork or mobile performance claim follows. Prior evidence for unchanged Journey rendering remains applicable. See [focused acceptance](LEVEL_ACCEPTANCE.md).

The exact original packets are retained in `.cinder/side-return-journey1-source/manifest.json`, `.cinder/side-return-journey1-wrapper.log`, `.cinder/side-return-journey1-result.json` and the corresponding `side-return-journey2` files. [Portable exact originals](evidence/side-return-journey/index.json) retain both runs, including the original failed fixture. The187-file packet index is30103d2b836266d3b4aa12ad126c386c342e86be6cdb0df0a05e035afcb28945; it contains174 frozen input rows and both original raw/result/runner/manifest packets.
