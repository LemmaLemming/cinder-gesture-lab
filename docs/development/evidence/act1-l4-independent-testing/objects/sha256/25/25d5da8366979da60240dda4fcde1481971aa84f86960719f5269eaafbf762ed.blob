extends "res://tests/acts/act2/a2_l3_live_level_smoke.gd"
## TEST ONLY additional actual rendered timestamps/derived cosmetic diagnostics.
## Production scene, camera, phases, clocks and masks are never assigned.
var _smoke_diagnostic_seen: Dictionary = {}

func _read_options() -> bool:
	var valid: bool = super._read_options()
	_capture_root = "res://captures/act2/a2-l3-smoke-live-opening-corrected/"
	return valid

func _capture_labels(state: Dictionary) -> Array[String]:
	var labels: Array[String] = super._capture_labels(state)
	var bank: Dictionary = state.banks.road_bank
	if bank.status == "running" and bank.phase == "active":
		var elapsed: float = float(state.clock_s) - float(bank.exchange.active_from_s)
		for threshold: float in [0.5, 1.5, 2.5]:
			var label: String = "smoke-active-" + str(threshold)
			if elapsed >= threshold and not _captured.has(label): labels.append(label)
	return labels

func _capture_state() -> void:
	await super._capture_state()
	if not _live(): return
	for label: String in _captured:
		if _smoke_diagnostic_seen.has(label): continue
		_smoke_diagnostic_seen[label] = true
		var art: Node = (_game.active_level.get("_cloud_art") as Dictionary).road_bank
		print("Actual smoke cosmetic diagnostic: label=", label, " frame_clock=", _captured[label].clock_s, " native=", art.call("geometry_stats"))
