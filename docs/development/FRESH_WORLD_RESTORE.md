# Fresh-world restore readiness

Shared57 adds `level-restore-registration-1` to Shell and Level. Opted-in levels prepare their actual isolated world and native floor while paused before entering synchronous restore. Default-false levels retain the previous constructor behavior. Save formats, Player/Level snapshot schemas, Store/Attempts callbacks and native collision guards remain unchanged.

## Confirmed problem

Act 3's original priority check failed 804/1 when a newly constructed isolated World3D rejected a saved native lunge's floor. Diagnostic `4b859caa-7a2d-4877-8bef-bef8344aeeaa` confirmed empty endpoint rays immediately after construction, followed by hits on the exact bound floor RID after one ordinary paused process frame. A distinct fresh candidate waited that frame before its sole restore entry and was accepted. Geometry and recorded actor state stayed unchanged.

The independent diagnostic review verified 598 frozen inputs, 497 original UIDs and unchanged sample `85362582`. That observation did not prove public Shell transport, complete live Scheduler clocks, optical acceptance or a level pass. Its full source bank remains in Act 3's local evidence; original failed and later corrected native results keep their individual scope.

## Additive contract

`CinderLevel.restore_candidate_physics_registration_required() -> bool` defaults to `false`. An override must be pure and callable off-tree. Opted-in levels must provide immutable native query floors by `_ready`; floors first introduced or changed inside `enter_restore_candidate` are refused. Shell creates the actual raw candidate, waits one process frame while gameplay remains paused, and permits one synchronous restore entry. The Level lifecycle check `restore_candidate_registration_error(player, effects, shell, constructed)` verifies that candidate. Waiting is preparation, not proof of a valid ray: the level's actual floor/RID and complete mechanical validators remain mandatory.

Only opted levels change constructor lifetime. One paused operation may retain an uncommitted validation constructor keyed by the exact complete lossless saved packet. Every callback repeats full Player, local-with-saved-Player and Shell validation; successful results are never cached. Original native nodes, World3D, Scripts, bindings and pristine state remain required. Installation uses a separate fresh candidate removed from all validation pools before quiet Player → Level commit. Rejected, committed and installed candidates cannot be recycled; an unprepared packet fails closed.

Startup and operation latches cover callbacks and the paused frame. Retry, Leave Replay and Quit cancel the current preparation generation and queue the replacement operation. Startup retires its cancellation flag before dispatching later operations, so a legitimate later Retry failure remains visible. Donor, disk, epoch and raw-candidate state must remain stable across preparation. Ordinary Begin, Exit, Side and Restart retain their original candidate and captured packet; the wait does not recapture, heal or substitute either.

Candidate-specific errors poison only their exact row. An unused bad backup or recoverably bad side cannot veto a valid primary. The existing synchronous Store/Attempts validation still decides primary/backup recovery, side recovery and writes. A test adapter must inspect the actual row error; whole-scope preparation may correctly return true after rejecting one row. Private Shell helpers are not an additional public level API.

Discovery is bounded to 16 exact packets / 32 MiB and floor traversal to 4,096 nodes. Shell checks the frame's elapsed time against two seconds after resumption. That check is not an independent timer if frames stop entirely; bounded queued engine jobs provide an external deadline.

## Focused evidence

The durable evidence archive preserves original manifests, logs, closure results, exact tested changed sources and independent reviews. The [latest index](evidence/fresh-world-restore/LATEST.json) joins all nine closed focused jobs and the clean import. The initial index remains immutable; subsequent results are appended in a supplement. Full frozen banks remain local, with unchanged source references checked against the indexed Git base.

| Check | Actual result | Scope |
| --- | --- | --- |
| Core registration | 96/0, clean | Actual tiny native floor/rays, exact-packet construction, repeated fresh validation, separate installation, public flows, fallback, cancellation and cleanup |
| Startup cancellation | 21/0, clean | Pending-startup Retry failure stays visible, disk remains unchanged, fresh Shell recovery works |
| Legacy restore | 71/0, clean | Default-false constructor and rejection compatibility |
| Campaign Shell, corrected private setup | 55/0, clean | Existing synthetic public Shell behaviors |
| Campaign persistence, corrected private setup | 45/0, clean | Model/store progress, equipment, checkpoints, replay, backup and atomic rejection |
| Necessary import | 0, clean | All 472 prior UIDs preserved; three genuine additions, 475 unique UIDs |

The first legacy parse returned zero with two user-log permission errors and remains nonclean. Its later core parse is clean. Original Shell 55/1 and persistence 45/4 results remain failures: both private fixtures had assumed A1-L3 was unavailable after the production level had been accepted. Each correction only marks that synthetic row unavailable and preserves all assertions. Persistence's first unintended successful transition changed state and disk, causing the three later comparisons against the prior state to fail. Production registry, Store and Attempts were unchanged.

The exact tested core sources originally retained inert-draft comments. Publication removes only those comments; the archived receipt verifies all behavior lines unchanged. No native rerun is claimed for that comment cleanup or the two CLI aliases.

Focused commands use the canonical queue:

```sh
python3 scripts/dev/dev.py test restore_candidate_physics
python3 scripts/dev/dev.py test restore_candidate_physics_startup_retry
```

## Worker adoption and remaining scope

Workers preserve-adopt the published commit after their frozen jobs close and acknowledge the actual merge. Enable the opt-in only where fresh-world native queries require it, with floors already ready and synchronous restore validation intact. Run only directly affected loading, Continue, Retry and cleanup checks plus brief visual inspection. Existing accepted levels retain acceptance; no global migration, full route, defeat-all or earned-exit gate follows.

Act2's source-only handoff `bc8a799d` supplies a focused actual native-lunge Shell fixture and test plan in its existing support paths. Independent review verifies all 64 committed owned-document paths and 63 indexed artifacts. Its test-only bridge still needs mapping to the published runtime before parser/import/native execution. Use the observing Shell subclass explicitly, and preserve the real row-refusal result and original candidate WeakRefs in raw-preparation rejection checks. Integration remains the first help contact and owns shared code.

Act3 owns its opt-in and public saved-lunge flow checks; its independent paused fixture correction alone does not supply those results. Core evidence does not establish the complete C50 lunge, an authored level's optical gate, Act2's native-lunge suite, same-Shell recovery after canceled startup, sustained performance or full playthrough. Campaign acceptance remains **16/24**.
