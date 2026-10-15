extends "res://tests/acts/act3/irontick_reflection_optional_shell.gd"
## Host-only recovery after original final-cp2-01 exhausted its 600s host budget.
## Original failed1423/1 remains failed; Optional helpers/pins stay exact.
## Measured CP2 original resume/retry consumed about 463 wall seconds before
## its second Echo driver; the original CP1 job required about eight minutes.
## A finite 1800-second host ceiling covers those native restore/capture costs.
## Inherited EchoDriver still enforces each actual 30-second/1800-tick bound;
## all native deadlines, geometry, HP, archive pins and cleanup stay unchanged.
## No pin compatibility exception or CP1 re-earning/transplant is introduced.
## Runner custody freezes this additional entrypoint plus original inputs.
## Passive phase markers expose wall time and existing model/disk identity only;
## every inherited action, assertion and return value is retained.

func _run() -> void:
	create_timer(1800.0,true,false,true).timeout.connect(func() -> void:
		if not finished:
			_expect(false,"bounded selected final O3 public job")
			_finish())
	root.size=Vector2i(340,736)
	root.content_scale_size=root.size
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	canonical_bytes=FileAccess.get_file_as_string(Registry.DATA_PATH)
	var args: PackedStringArray=OS.get_cmdline_user_args()
	var original: String=""
	if args==PackedStringArray(["--earn-cp1"]): _selector="earn-cp1"
	elif args.size()==1 and args[0].begins_with("--earn-cp2=res://captures/act3/irontick-reflection/"): _selector="earn-cp2"; original=args[0].trim_prefix("--earn-cp2=")
	elif args.size()==1 and args[0].begins_with("--completion-return=res://captures/act3/irontick-reflection/"): _selector="completion-return"; original=args[0].trim_prefix("--completion-return=")
	elif not args.is_empty(): _expect(false,"explicit bounded final O3 selector"); await _finish(); return
	if not _expect(DisplayServer.get_name()=="headless","selected transport jobs require native headless; no portrait credit"): await _finish(); return
	node_added.connect(_watch_node)
	if original.is_empty():
		if not await _fresh_optional(): await _finish(); return
	else:
		if not _load_original_archive(original,"cp1" if _selector=="earn-cp2" else "cp2") or not await _new_shell(expected_session): await _finish(); return
		production.menu.resume_requested.emit()
		if not await _wait_installed("A3-O3","resume",held) or not _installed(held) or not _quiet_selected() or not _disk(expected_session): await _finish(); return
		if not await _retry_original_checkpoint(): await _finish(); return
	print("O3 TEST ONLY prefix13/readiness; actual accepted L3 Story; selector=",_selector,"; original whole packets only, no source/journal/progress transplant")
	if _selector=="held-transport": scope_complete=await _held_transport()
	elif _selector=="earn-cp1": scope_complete=await _earn_checkpoint(0)
	elif _selector=="earn-cp2": scope_complete=await _earn_checkpoint(1)
	else: scope_complete=await _complete_return()
	await _finish()


func _host_phase(label: String) -> void:
	print("O3 HOST PHASE: ", label, "; elapsed_wall_s=", Time.get_ticks_msec() / 1000.0, "; checks=", checks, "; driver_ticks=", _native_ticks)

func _new_shell(expected: Dictionary) -> bool:
	_host_phase("fresh Shell start")
	var ok: bool = await super._new_shell(expected)
	_host_phase("fresh Shell end result=" + str(ok))
	return ok

func _retry_original_checkpoint() -> bool:
	_host_phase("original checkpoint Retry start")
	var ok: bool = await super._retry_original_checkpoint()
	_host_phase("original checkpoint Retry end result=" + str(ok))
	return ok

func _earn_checkpoint(stage: int) -> bool:
	_host_phase("earn checkpoint start stage=" + str(stage))
	var ok: bool = await super._earn_checkpoint(stage)
	_host_phase("earn checkpoint end result=" + str(ok))
	return ok

func _wait_pause() -> bool:
	_host_phase("public Pause settlement start")
	var ok: bool = await super._wait_pause()
	_host_phase("public Pause settlement end result=" + str(ok))
	return ok

func _archive_state(kind: String, entrance: Dictionary, receipt: Dictionary = {}) -> bool:
	_host_phase("whole archive start kind=" + kind)
	var ok: bool = super._archive_state(kind, entrance, receipt)
	_host_phase("whole archive end result=" + str(ok))
	return ok

func _expect(ok: bool, label: String, detail: String = "") -> bool:
	if label == "genuine durable CP follows coherent next-stage activation" or label == "bounded selected final O3 public job":
		_host_phase("checkpoint boundary result=" + str(ok) + " label=" + label)
		if is_instance_valid(production) and production.attempts != null:
			var observed: Dictionary = production.attempts.state()
			var side: Variant = observed.get("side_attempt")
			if side is Dictionary:
				print("O3 HOST MODEL: checkpoint=", side.checkpoint.level.progress.checkpoint_id, "; snapshot=", side.snapshot.level.progress.checkpoint_id)
		var disk: String = isolated + "campaign.json"
		print("O3 HOST DISK: exists=", FileAccess.file_exists(disk), "; sha256=", FileAccess.get_sha256(disk) if FileAccess.file_exists(disk) else "absent", "; hash alone is not payload-validation credit")
	return super._expect(ok, label, detail)
