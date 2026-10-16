# Private composition adapter

This is source-only preparation. Do not install while any actual native inputs are frozen. No parser, import, native component, portrait draw or result serialization was executed by this preparation.

The current read-only target is `/Users/howardchen/.codex/worktrees/campaign-act3/video game idea/tests/acts/act3/mirror_sea_arrangement_smoke.gd`, observed SHA `fb465a8d0933a5983e200f12c66814ebd3ee1f176312b1f94b71748ed0d4f98e`. Its finalizer already uses typed `actions = []` followed by `assign` when Hero is valid, and invokes inherited `_dispose_host(false)` only when `_game` is valid. Preserve these current fixes verbatim. The composition helper changes only the four target-file anchors below, two composition-only component entry guards, and appends the frozen fragments and adapter.

`python3 /private/tmp/a3_l3_component_draft/compose_adapter.py` rereads that actual target and writes only `/private/tmp/a3_l3_component_draft/composed-smoke.PRIVATE.gd` plus its private source receipt. It refuses changed anchors, wrong frozen fragments, duplicate functions or a missing full OLD manifest pin. It does not install the result. Root controls installation after the current native job closes.

1. Immediately after `_run` obtains `selected`, before `--pure`, legacy/current transport or old producer dispatch, insert:

```gdscript
	if selected == PackedStringArray(["--east-component"]) or selected == PackedStringArray(["--east-component-portrait"]):
		await _eca_run(String(selected[0]))
		return
```

2. Keep the target's single `_tick`. Add the one component branch **after** its existing retiring guard, before the producer observer count. Do not append the duplicate `_tick` from the component fragment.

```gdscript
func _tick() -> String:
	if _p3_done: return "original producer is retiring"
	if _ec_running: return await _ec_tick()
	_p3_driver_observations += 1
	if _p3_driver_observations > 6000: return "original first-two-entry producer exceeded6000 observer calls"
	var error: String = await super._tick()
	if is_instance_valid(_scheduler): _p3_last_clock = _scheduler.get_clock()
	return error
```

3. In `_p3_finish`, immediately after the existing `_p3_done = true`, before reading any common Hero/Scheduler handles, insert:

```gdscript
	if _ec_running or _ec_disposing or not _ec_native_handles.is_empty() or not _ec_scene_handles.is_empty():
		var component_cleanup: String = await _ec_dispose_all()
		_expect(component_cleanup.is_empty(), "declared component native handles/scenes retire before common finish", component_cleanup)
```

Retain the entire current finalizer below it, including its fixed typed actions assignment and valid-game disposer guard. The component cleanup is reentrant and wakes a pending barrier without awarding a tick. The adapter does not resume a run once the watchdog sets `_p3_done`.

4. Use a component-specific footer when `_eca_selector` is nonempty. Keep the original footer otherwise, and retain the final existing `quit(0 if _failures == 0 and _p3_complete else 1)` in both cases. The exact conditional footer is in the private composed view/helper. It reports the actual result folder and component scope; it does not claim early MAIN transport for a component selector.

Append frozen `component-fragment.gd` excluding its duplicate `_tick` and adding exactly the following composition-only entry guard as the **first executable line in both** `_ec_case` and `_ec_spawn`, before any native construction or handle mutation:

```gdscript
	if _p3_done: return {"error": "Component finalizer owns shutdown; no new native construction"}
```

The frozen `component-fragment.gd` file stays byte-exact at SHA `8170bbd359734bd5027b92146881cf41887cf34a8691d136639ee1552b179ea8`; these two lines exist only in the composed derivative. `_ec_case` blocks the next case/combined continuation after awaited disposal, while `_ec_spawn` also blocks the later recipient in `_ec_transport` after its awaited wrong-recipient disposal. The latter cannot be covered solely by an `_ec_case` entry guard. Both checks occur before construction, not after it; no native clocks, physics, schema or view guards change.

Append frozen `portrait-fragment.gd`, then `composition-adapter.gd`. The component class file remains separately at its intended resource path `tests/acts/act3/fixtures/a3_l3_arrangement/east_component.gd` after Root installation/import. Never add `extends` to these appendable fragments. The helper verifies all named functions remain unique.

The adapter calls the existing `_p3t_verify_original()` before component construction. The unchanged literal old manifest SHA is `d8658ace41b461ba2cab78a4016306465774b9b795e6932647301f06b30ddb5f`; all original file/source-pin checks remain the actual authority. No rewriting, renaming or fresh-production inference is added.

Every returned nonempty actual component result is written under a unique `captures/act3/mirror-sea-arrangement/result-component-PID-TIME` or `result-portrait-PID-TIME` folder. `result.var.bin` is the full unmodified `var_to_bytes(result)`; `result.var.txt` is its full `var_to_str(result)` plus one newline. Exact writes and readbacks are checked. `summary.json` uses ExactJSON and includes the literal errors/outcome/refinement/refusal details, requested versus actual case labels, actual known kit/HP/ticks, actual primary origin and dash landings converted from Vector3 to arrays, and actual portrait path/hash. Missing failure-case observations remain null or explicitly unrecorded. Portrait kit/HP/ticks come from the actual callback, since the frozen fragment's portrait case does not include them. No placeholder HP, path or successful draw is invented.

`_p3_complete` requires a nonempty returned result, its actual empty error, no refinement flag or `no_useful_difference` outcome, successful result archival, and (for the portrait selector) the frozen full draw/custody return plus actual PNG existence/hash. A normal refusal/failure remains literal and fails. `no_useful_difference` is archived unchanged, prints refinement, leaves completion false and exits nonzero without an invented assertion that the responses differ. `completion_eligible_before_final_cleanup` in the summary is provisional; only the original runner closure and common cleanup determine the final outcome. No parent route/save, earned east arrival, full-route, human balance or acceptance credit is implied.
