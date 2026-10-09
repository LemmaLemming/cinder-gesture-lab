# Ignored full-route fixture adaptation for the current whole parent

This is a test-only proposal, with no parser, native, graphical or acceptance result. No actual source or test was changed, no engine/import/commit/status operation was run, and the queued Root production-warning inputs remain untouched. The patch targets `tests/acts/act3/mirror_sea_route_smoke.gd` only after Root releases its relevant freeze.

## Exact inputs and candidate

| Input | SHA-256 |
| --- | --- |
| Original route, 40,320 bytes | `1b7f518edf04941e900a22ab780ecdd0a8eff1244d8fc45d6859fb68b673adb8` |
| Actual frontier inherited by the route | `8424bedbb8001c3e02b55e7cf18ad525527936933dc1556339bdc3b8ce664fed` |
| Actual parent, including pre-consumer due lock | `4af8680418d0b7449f0750315a8672282f652d5d782878f5c4e7206d6a362b72` |
| Actual whole parent codec | `7fdfe2a8f259190ba223197725ab5b2a9ce6533ce580e55ef08ef13d81774ca6` |
| Patch, 15,368 bytes | `0673bfd29ff22caaa6390c9aada38f90fb6da5bf4b340903fa3a8ddf41ab09f8` |
| Proposed applied route, 47,676 bytes, 718 lines | `b083760959dfa223c77f4fe0212f15614758473eed0530152ccc0356d58ead19` |

The patch is `.cinder/mirror-sea-route-codec-adaptation.patch`. It applies exactly to the original route in an independent in-memory unified-hunk check. The actual route remained exact `1b7f518e` after this check. Local shared baseline is published37 `36090c9d83bb762b14310aa22978f1b31469551f`; this adaptation adds no38 dependency.

## Three concrete obsolete assumptions

1. Original `_entry_error` requires every entered boundary to remain pending. Original `_tick` and `_route_final_error` require zero checkpoint signals. Current parent `_dispatch_pending_checkpoint` removes the oldest actual boundary before synchronous `CinderLevel.request_checkpoint`, which records a delivered canonical ID/kind. A delivered prefix and the remaining exact suffix are the supported state.
2. Original `_fixed_record` reads `record.geometry` for every protocol. Actual `Scheduler.request_authored_replay` creates a compound record with an immutable `adapter.sequence`, source/world/target bindings and deadlines; it has no ordinary `geometry` key. Original first Echo observation would therefore access a missing key. Ordinary lunge/circle records keep their exact full geometry checks.
3. Original held-deadline equality spans unarmed admission and actual authored commitment. Published `commit_authored_replay` retains admission ID/start/program but sets `timeline_origin_s = actual_clock - warning_s`, derives armed deadlines and sets lock at that actual due tick. This is one earned transition, followed by exact immutable armed deadlines. The current owned parent commits at priority90 before Playback110; a coherent end-of-tick Cursor must already be armed at the same actual clock.

The route overrides `_run` and does **not** invoke the inherited frontier `_save_refusal`. There is no need to bypass aggregate validation or manufacture a partial saved packet. Its inherited old refusal method remains unused. Header/final text now distinguish native checkpoint/arm observations from unexercised aggregate transport/restore and production durability.

## Scoped correction

The new paused `_open` calls the unchanged real Main setup, requires the supported current parent, checks all six exact canonical checkpoint IDs, and connects a fixture-only checkpoint observer before ordinary resume. Each subsequent observation requires delivery count equal to the earned entries minus pending suffix, exact suffix identity, original callback level/ID/kind/current checkpoint, actual nondecreasing callback clock after the earned entry, and the current latest checkpoint. Selected route completion additionally requires all five or six real entered boundaries delivered. This counts real Level requests; it does not claim SaveStore protection or ProductionShell durability.

The authored held observer requires a real first unarmed admission at the observed native clock, the same public original lease/owner/program/generation, exact parent cached lease and lock flag, and public native Cursor configured/current clocks. The pure `replay_reservation_state` accessor independently enforces the canonical program/deadline/world binding. At one genuine lock it requires unchanged admission identity, original `start_s`, copied lock/origin in the already armed Cursor, actual lock equal to this Scheduler clock, and first available due gap between zero and the existing tick plus `TIME_EPSILON`. Only then does the fixture retain the actual armed deadline set. Every later deadline/adapter remains exact; lock reset, a missing original warning observation, a stale Cursor, late commitment or another immutable change fails. No extra Playback tick, source mutation, fabricated deadline, private field or invented lease is used.

The original `_run`, navigation, swipes/taps, `_walk_proof`, `_ordinary_hit`, `_resonance`, second recovery primary, pulse selection/completion, all source generation observation, real exit contact/re-entry and cleanup methods remain byte-identical. The 240s route/40s group/10s wait budgets, `.005WU` landing tolerance, `1e-6` action-boundary arithmetic tolerance, floor, all six entry coordinates, full roster, fixed mechanism, damage, equipment and actual GUI/input meanings remain unchanged. The patch changes only original `_entry_error`, `_tick`, `_fixed_record`, `_route_final_error` and `_finish`, plus five narrowly observational helpers.

## Canonical authored route and intended native selector

`docs/ACT3_CONCEPT.md` defines five beats: familiar shore threat; one actual Echo and fixed endpoint; two Echo arrangements at permanent shore stones; one bounded independently previewed environmental pulse with an Echo between pulses; final Stalker/Echo priority choice followed by quiet contact. The current layout uses six earned spatial entries because the third beat has west/east courts. It retains two Stalkers, five real36HP Echoes and one mechanism performing exactly two genuine admissions. Filled-circle danger remains the published bounded circular resonance interpretation; no extra boss, water/jump requirement, new equipment/ability or reward is added.

After Root reviews/publishes the exact patch and closes any consuming freeze, the smallest full-route target is:

```sh
python3 scripts/dev/dev.py engine --headless --path . --script res://tests/acts/act3/mirror_sea_route_smoke.gd -- --full-route --stalker-first
```

This must genuinely earn all six entries, seven ordinary native deaths, surviving between-pulses Echo completion, same mechanism/cooldown/opening on pulse2, full HP, no Blast/pickup/resource write, once-only completion/contact and whole-world cleanup. `--full-route --echo-first` is a separate real priority branch; default/`--resonant-death-only` proves the different real same-generation recovery-death interval on the first five entries and must not claim full completion. No selector has been run by this agent or receives execution credit here.

## Remaining scopes and derived draft custody

This adaptation does not capture, decode, restore, construct a fresh receiver, test terminal timestamp rejection, exercise disk/Continue/Retry, next-level transition, empty ammo or legal equipment extremes, render portrait pixels, or establish human gesture/pacing review. Native Level checkpoint requests are not durable campaign checkpoints. All later scopes remain separate actual tests. Current production-warning8c5 is completely unchanged.

Frozen ignored terminal-ring `f99c41d7` copies the original route's held observer in its own `_tick`; it will need a separately reviewed rebase on this proposed observer before it can meaningfully reach its genuine terminal negative. This file was not altered. Frozen portrait/kit drafts remain separately scoped and unchanged. No proposed layout, constructor recipe, checkpoint or saved history is treated as earned gameplay.
