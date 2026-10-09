# Optional Lane parent presentation guard

The opt-in `CinderLaneMechanism.set_presentation_guard(provider: Callable) -> bool` protects required authored sibling presentation at the actual damage boundary. It addresses Act2 REQUESTaa1c5773: a later Foot active-phase observer hid the living Sentry after an earlier parent check, while the Foot/cue/lease stayed valid. The original closed19/1 representative case dealt4 damage before the next parent tick canceled. Original diagnostics, including two unclassified ObjectDB warning lines, remain owner evidence; earlier182/0 component results retain their separate scope.

## Binding and delivery

Bind exactly once on a ready configured/bound fresh mechanism before its first cycle, including a fresh paused restore recipient. The provider accepts exactly `(mechanism_id: String, current_state: Dictionary)` and returns native `bool`. State is defensive. The provider queries its actual parent Actor, required art, joint, camera and world custody synchronously. It may pause or cancel; it must not yield or manufacture authority.

Delivery retains the original native binding, cue, geometry and lease checks before and after each provider call. After phase/cue/lease observers and before hit consumption, the parent must still authorize. Existing post-hurt and post-hit boundaries use the same wrapper. Any Scheduler invalidation, including a foreign lease observer during the query or recheck, makes the earlier answer stale: one bounded reauthorization is allowed; continuing notification churn cancels before damage.

Invalid, freed, wrong-arity, false or wrong-type providers cancel with `required_parent_presentation_unavailable`. A provider that synchronously cancels keeps its exact owner reason. A pause holds measured pending segments and the original once-hit prefix. Removal releases the Callable capture but retains the required flag. Ordinary consumers without this opt-in retain their existing behavior. An accepted admission may be synchronously canceled by its warning observers; always inspect the current native state rather than treating an admission proof as lasting authority.

## Quiet restoration and owner hookup

The callback is ephemeral and absent from saved configuration/API/schema fields. Capture, validation and quiet restoration never invoke it. The whole parent constructor/codec binds the actual fresh recipient callback before restoring and validates required parent presentation itself. A legacy wire does not prove that a required constructor opted in; no saved callback or flag substitutes for the real binding.

The B05 owner should bind after `_configured = true`, before any cycle, and preserve its existing precise close-first failure path:

```gdscript
if not _foot.set_presentation_guard(_foot_presentation_guard):
    return _construction_failed("Foot parent presentation binding refused")

func _foot_presentation_guard(source_id: String, _current: Dictionary) -> bool:
    if source_id == FOOT_ID and _live() and _presentation_ok():
        return true
    _fail("B05 required native bindings/presentation lost")
    _cancel_owned("b05_actual_source_cue_or_frame_lost")
    return false
```

This is a supported integration pattern, not an edit or acceptance of worker-owned content. The owner must bind it on each actual recipient and rerun only its affected late-publication reproduction and dependent focused restore checks after preserving adoption. Whole-level save/art/registration work remains independent.

## Verification and research

The existing directly affected Lane suite actually closed **243/0**, exit0, on121 exact original inputs (manifest42a1a334903a806cf7e17beee92b13365baaafa1b7c6cb88ad0ca9349083d67f). It verifies unchanged default consumers, callbacks, pause-held paths, paired restore and cleanup. The final `lane_parent_presentation` target actually closed **48/0**, exit0, on122 exact original inputs (manifeste27ef67b9c219d7be7609a5d31f4bf794c85f5026358cb16a27ce795d81152a9). Both passing logs have no Script/Parse/ERROR/WARNING diagnostics. It covers opt-in sibling/callback/foreign-lease/pending/fresh-recipient cases. [Portable exact originals](evidence/lane-parent-presentation/index.json) retain all four jobs. The first48/0 target had a freed lambda-capture ERROR; it remains diagnostic-bearing. The second observer repair attempted to free its own locked callback receiver and was stopped by the canonical wrapper with ScriptError/exit1 and no footer. The final fixture uses a separate native observer holding a WeakRef, disconnecting before freeing the actual unlocked provider. Runtime and assertions remained exact; only observer lifetime changed. The legacy Dev mapping was intentionally extended with the named target after its closure. Three unparsed draft branches were also corrected before first submission to preserve the inherited void assertion signature; no native credit is assigned to that private draft. No A2 whole-parent, whole-level, full-route, portrait, balance or performance credit is implied.

Godot4.7.2 ed1daf0bf is the actual local test engine. The official [Signal API](https://docs.godotengine.org/en/stable/classes/class_signal.html), [Callable API](https://docs.godotengine.org/en/stable/classes/class_callable.html) and [Object API](https://docs.godotengine.org/en/stable/classes/class_object.html) were inspected9October2026 for callback delivery, validity, argument count and deferred connection semantics. They support the API design; they do not prove this engine's exact callback ordering or the original defect. The actual native regressions provide that evidence.

Use `python3 scripts/dev/dev.py test lane_parent_presentation` and, when the implementation changes, the directly affected `lane_mechanism` target through the canonical queue. [Focused desktop acceptance](LEVEL_ACCEPTANCE.md) applies; no route or defeat-all run is required.
