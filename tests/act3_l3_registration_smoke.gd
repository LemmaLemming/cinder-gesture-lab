extends "res://tests/acts/act3/mirror_sea_production_replay_smoke.gd"
## PRIVATE SOURCE-ONLY successor for the existing Root registration fixture.
## Default/--entry-retry-only cover canonical source-free entry, whole disk,
## public entrance Retry and cleanup. No replay, combat or owner-suite repeat.
## Inherited warning _open creates an actual Main Standard clock0 pair; only
## prefix12 and explicit outer Shell metadata are disclosed TEST scaffolding.

const ACCEPTED_COMMIT: String = "55256309a1dfdbd2506cf56a6b09b7b026193541"
const SHORT_ARRANGEMENT_PATH: String = "res://data/campaign/act3/a3_l3_difficulty.json"
const SHORT_STANDARD_RECIPE: String = "A3-L3/standard-canonical@v1"
const SHORT_REPORT_ENV: String = "CINDER_A3_L3_REGISTRATION_REPORT"
const SHORT_LOCAL_KEYS: Array[String] = ["api_revision", "schema_version", "world", "scheduler", "sources", "route", "ring", "view", "arrangement"]
const SHORT_DESCRIPTOR_KEYS: Array[String] = ["schema_version", "profile", "recipe_id", "order"]
const SHORT_UNITS: Array[String] = ["l3-threshold-stalker", "l3-first-echo", "l3-useful-west-echo", "l3-useful-east-echo", "l3-resonant-echo", "l3-resonant-pulse", "l3-priority-echo", "l3-priority-stalker"]
var _checked_empty_journey: bool = false
var _short_rows: Array[Dictionary] = []
var _short_first_failure: Dictionary = {}
var _short_receipts: Array[Dictionary] = []
var _short_source_before: Dictionary = {}
var _short_report_path: String = ""
var _short_finishing: bool = false
var _short_body_complete: bool = false


func _initialize() -> void:
	_short_report_path = OS.get_environment(SHORT_REPORT_ENV)
	_short_source_before = _short_sources()
	_run.call_deferred()


func _run() -> void:
	create_timer(120.0, true).timeout.connect(func() -> void:
		if not _short_finishing:
			_expect(false, "bounded120-second source-free registration watchdog")
			_finish.call_deferred())
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var reason: String = "" if arguments.is_empty() or (arguments.size() == 1 and arguments[0] == "--entry-retry-only") else "unsupported short selector: " + str(arguments)
	if reason.is_empty() and (_short_report_path.is_empty() or not _short_report_path.is_absolute_path()): reason = "explicit absolute " + SHORT_REPORT_ENV + " destination required"
	if not _expect(reason.is_empty(), "closed short-entry/Retry selector and explicit owned report destination", reason):
		await _finish(); return
	reason = await _open()
	if _short_finishing: return
	if not _expect(reason.is_empty(), "actual canonical entry installs genuine Main Standard source-free packet through public Shell Continue/Pause", reason):
		await _finish(); return
	reason = _arrival_pair()
	if not _expect(reason.is_empty(), "current closed9 native arrival validates without historical API1 substitution", reason):
		await _finish(); return
	var initial: Dictionary = _shell.capture_campaign_snapshot()
	var session: Dictionary = _shell.attempts.state()
	var disk: Dictionary = _short_disk()
	if not _expect(not initial.is_empty() and session.side_attempt == null and session.completed_main.size() == 12 and session.completed_main[11] == "A3-L2" and _exact(session.story, {"kind": "story", "level_id": "A3-L3", "snapshot": initial, "checkpoint": initial}) and _events.is_empty() and _actions.is_empty(), "complete actual initial Story/snapshot/checkpoint and disclosed prefix12 contain no earned L3 events or actions"):
		await _finish(); return
	reason = _disk_error(session)
	if not _expect(reason.is_empty() and disk.reader_error.is_empty() and not disk.loaded_backup and int(disk.generation) >= 1, "independent native Store reread/checksum/full exact initial session joins public paused Save", reason):
		await _finish(); return
	var ids: Dictionary = _short_native_ids()
	if not _expect(_short_ids_valid(ids), "nine actual source-free native identities are valid unique nonzero signed integers"):
		await _finish(); return
	reason = _short_record("actual canonical initial paused Save", initial, session, disk, ids)
	if not _expect(reason.is_empty(), "retain complete initial Exact session/snapshot/checkpoint, raw Store and decimal native identities", reason):
		await _finish(); return
	reason = await _short_retry(initial, session, disk, ids)
	if _short_finishing: return
	if not _expect(reason.is_empty(), "public entrance Retry retains complete initial Story/disk and quietly replaces native recipients", reason):
		await _finish(); return
	_short_body_complete = true
	await _finish()


func _open() -> String:
	var registry := ProductionRegistry.new()
	var current: Dictionary = registry.entry("A3-L3")
	var previous: Dictionary = registry.entry("A3-L2")
	var future: Dictionary = registry.entry("A3-L4")
	if not _expect(registry.last_error.is_empty() and registry.ids().size() == 24 and current.get("readiness") == "accepted" and current.get("accepted_commit") == ACCEPTED_COMMIT and current.get("scene_path") == LEVEL_PATH and current.get("api_revision") == "campaign-level-1" and current.get("previous_main_id") == "A3-L2" and current.get("next_main_id") == "A3-L4" and previous.get("readiness") == "accepted" and future.get("readiness") == "accepted" and future.get("accepted_commit") == "741fe48ee2db1ad27ba6e9ce2f7c7ab0a41fb6a7" and future.get("scene_path") == "res://scenes/acts/act3/a3_l4_false_paradise.tscn" and future.get("previous_main_id") == "A3-L3" and future.get("next_main_id") == "A3-L5" and registry.scene_error("A3-L3").is_empty(), "actual canonical Mirror Sea registration, accepted L2 prerequisite and existing accepted L4 metadata are exact", registry.last_error):
		return "canonical L3 registration differs"
	# Warning ancestor uses actual Main native writers and the public complete
	# validator/Continue/Pause. Its in-memory proposal registry is not consumed.
	var error: String = await super._open()
	if error.is_empty() and not _expect(_exact(_shell.registry.entry("A3-L3"), current), "actual production Shell consumes the canonical accepted row"):
		error = "production Shell registry differs from canonical source"
	return error


func _new_shell() -> String:
	_shell = ProductionShell.new()
	_game = _shell
	if not _shell.configure_runtime({}, _test_root + "campaign.json", _test_root + "settings.json", _test_root + "preferences.json"):
		return "canonical production Shell configuration refused: " + _shell.campaign_error
	root.add_child(_shell)
	for _i: int in range(4): await process_frame
	if not paused or not _shell.campaign_error.is_empty() or _shell.menu == null or _shell.menu.page_name() != "title":
		return "fresh canonical Shell title/load refused: " + _shell.campaign_error
	if not _checked_empty_journey:
		_checked_empty_journey = true
		var before: Dictionary = _shell.attempts.state()
		_shell.menu.journey_requested.emit()
		for _i: int in range(4): await process_frame
		_shell.menu.select_level("A3-L3")
		var node: Button = _shell.menu.find_child("Node_A3_L3", true, false) as Button
		var action: Button = _shell.menu.find_child("LevelCardAction", true, false) as Button
		var body: Label = _shell.menu.find_child("LevelCardBody", true, false) as Label
		if not _expect(before.completed_main.is_empty() and _shell.active_level == null and _shell.menu.page_name() == "journey" and node != null and node.get_meta("campaign_state", "") == "locked" and action != null and action.disabled and body != null and body.text.contains("A3-L2"), "fresh canonical Journey keeps accepted L3 locked behind actual L2 prerequisite"):
			return "fresh Journey exposed L3 without predecessor progress"
		if not _expect(_exact(before, _shell.attempts.state()) and _shell.active_level == null, "locked Journey inspection invents no Story, progression or native level"):
			return "locked Journey changed fresh campaign state"
		_shell.menu.show_title()
	return ""


func _arrival_pair() -> String:
	# Intentionally replace the historical API1 arrival assertion. Do not run
	# the old malformed matrix, replay or first-court owner acceptance suites.
	return _source_free_packet_error(_shell.capture_campaign_snapshot())


func _source_free_packet_error(packet: Dictionary) -> String:
	if packet.is_empty() or not paused or not is_instance_valid(_shell) or _shell.active_level != _level or _shell.player != _hero: return "actual paused current production packet unavailable"
	var error: String = _pair_error({"hero": packet.player, "level": packet.level})
	if error.is_empty(): error = _host_bindings_error()
	if error.is_empty(): error = String(_level.call("runtime_error"))
	if not error.is_empty(): return error
	var local: Dictionary = packet.level.local
	var state: Dictionary = _level.call("state")
	if packet.level_id != "A3-L3" or packet.scene_path != LEVEL_PATH or packet.level.local_snapshot_version != 1 or not ProductionValue.keys_error(local, SHORT_LOCAL_KEYS).is_empty() or local.api_revision != "act3-mirror-sea-snapshot-2" or not local.schema_version is int or local.schema_version != 2:
		return "actual new L3 source-free closed9 API2/schema2 identity differs"
	var definition: Variant = JSON.parse_string(FileAccess.get_file_as_string(SHORT_ARRANGEMENT_PATH))
	if not definition is Dictionary or definition.get("unit_ids") != SHORT_UNITS or not local.arrangement is Dictionary or not ProductionValue.keys_error(local.arrangement, SHORT_DESCRIPTOR_KEYS).is_empty() or not local.arrangement.schema_version is int or local.arrangement.schema_version != 1 or local.arrangement.profile != "standard" or local.arrangement.recipe_id != SHORT_STANDARD_RECIPE or not _exact(local.arrangement.order, SHORT_UNITS) or local.world.profile_id != "standard" or local.scheduler.profile.id != "standard":
		return "actual fresh Standard must retain exact finite current canonical recipe and native saved profile"
	var selected: Dictionary = _level.call("mirror_sea_codec_arrangement_state")
	if String(selected.get("error", "Actual installed current arrangement required")) != "" or selected.get("legacy") != false or not _exact(selected.get("descriptor"), local.arrangement): return "actual constructor selection differs from current saved descriptor"
	if _scheduler.get_clock() != 0.0 or _hero.get_world_action_clock() != 0.0 or packet.player.world_actions.clock_s != 0.0 or packet.player.world_actions.sequence != 0 or not packet.player.world_actions.history.is_empty() or not packet.player.world_actions.pending_dash.is_empty() or not _hero.get_world_action_records().is_empty():
		return "focused source-free lifecycle unexpectedly earned clocks/actions"
	if not local.sources.is_empty() or not local.scheduler.reservations.is_empty() or not local.route.entries.is_empty() or not local.route.deaths.is_empty() or not local.route.pending_checkpoint_boundaries.is_empty() or local.ring.stage != "uninstalled" or not local.ring.mechanism.is_empty() or not local.ring.history.is_empty() or not local.ring.between_receipt.is_empty() or local.route.exit_state != "clear" or not local.route.contact.is_empty() or packet.level.progress.completed or not packet.level.progress.completion_id.is_empty() or not packet.level.progress.contact_exit_id.is_empty() or not packet.level.progress.checkpoint_ids.is_empty() or not state.route.entries.is_empty():
		return "disclosed access metadata invented topology, route, pulse, death or completion"
	if not (_level.get("sources") as Dictionary).is_empty() or is_instance_valid(_level.get("mechanism")) or not get_nodes_in_group("enemies").is_empty() or _hero.dead or _hero.hp != _hero_hp or _hero.shells != _shells or not _exact(_kit, _hero.equipment.snapshot()) or not _exact(_stats, _hero.equipment.resolved_stats()):
		return "actual source-free world/resources/equipment differ"
	var cue: Node3D = _level.get("exit_cue") as Node3D
	var cues: Array[Node] = get_nodes_in_group("required_cues")
	if cue == null or cues.size() != 1 or cues[0] != cue or cue.get_parent() != _level or not cue.is_node_ready() or cue.get_script().resource_path != "res://scripts/cues/interaction_cue.gd": return "actual source-free world retains only its configured clear exit cue"
	var cue_state: Dictionary = cue.call("state")
	var marker: MeshInstance3D = cue.get_node_or_null("RequiredInteractionMarker") as MeshInstance3D
	if not _exact(cue_state, {"api_revision": "interaction-cue-1", "state": "clear", "trigger": "attack", "required": true, "visible": false}) or marker == null or marker.visible or marker.mesh != null: return "initial exit cue gained available/contact presentation before local completion"
	return ""


func _short_retry(initial: Dictionary, expected_session: Dictionary, before_disk: Dictionary, before_ids: Dictionary) -> String:
	var button: Button = _shell.menu.find_child("RetryButton", true, false) as Button
	if not _expect(paused and _shell.menu.page_name() == "pause" and button != null and button.is_visible_in_tree() and not button.disabled, "actual paused menu exposes public entrance Retry"):
		return "actual Retry button unavailable"
	var refs: Array[WeakRef] = []
	var seen: Dictionary = {}
	_collect_native_refs(_shell.world.get_parent().get_parent(), refs, seen)
	_collect_native_refs(_barrier, refs, seen)
	var events: Dictionary = _events.duplicate(true)
	var actions: Array[Dictionary] = _actions.duplicate(true)
	var shell_id: int = _shell.get_instance_id()
	var hud_id: int = _shell.hud.get_instance_id()
	_protected_checkpoint = initial.duplicate(true)
	_prepare_fixture_rebind()
	button.pressed.emit() # Real menu handler emits public retry_requested.
	var error: String = await _settle_shell("resume")
	if _short_finishing: return "registration finalizer owns shutdown"
	_watch_restore = false
	if not error.is_empty(): return error
	if not _quiet_events.is_empty() or not _exact(events, _events) or not _exact(actions, _actions): return "public Retry emitted gameplay events/actions during quiet reconstruction"
	error = _bind_runtime()
	if not error.is_empty(): return error
	var after: Dictionary = _shell.capture_campaign_snapshot()
	error = _source_free_packet_error(after)
	if not error.is_empty(): return error
	if not _expect(_shell.get_instance_id() == shell_id and _shell.hud.get_instance_id() == hud_id and _exact(after, initial) and _exact(_shell.attempts.state(), expected_session) and _exact(_shell.attempts.state().story.checkpoint, initial) and _level.current_checkpoint().id.is_empty(), "entrance Retry keeps Shell/HUD, complete whole Story/current/checkpoint/session and empty authored checkpoint ID"):
		return "public Retry changed protected source-free state"
	var ids: Dictionary = _short_native_ids()
	var distinct: bool = _short_ids_valid(ids) and ids.keys() == before_ids.keys()
	for key: String in before_ids: distinct = distinct and ids.get(key) != before_ids[key]
	if not _expect(distinct, "Retry creates all nine valid nonzero distinct native World3D/viewport/container/Hero/Level/Scheduler/camera/effects recipients"):
		return "public Retry reused a native recipient"
	error = await _donor_freed_error(refs, after)
	if not _expect(error.is_empty(), "actual prior container and full native donor subtree/barrier retire normally", error): return error
	error = _disk_error(expected_session)
	var disk: Dictionary = _short_disk()
	if not _expect(error.is_empty() and disk.reader_error.is_empty() and not disk.loaded_backup and int(disk.generation) == int(before_disk.generation) + 1, "public Retry publishes one format2 generation with exact full initial payload", error): return "public Retry full disk/generation differs: " + error
	return _short_record("actual public entrance Retry exact original unit", after, _shell.attempts.state(), disk, ids)


func _short_native_ids() -> Dictionary:
	if not is_instance_valid(_shell) or not is_instance_valid(_hero) or not is_instance_valid(_level) or not is_instance_valid(_scheduler): return {}
	return {"world": _shell.world.get_instance_id(), "world3d": _shell.world.get_world_3d().get_instance_id(), "viewport": _shell.world.get_parent().get_instance_id(), "container": _shell.world.get_parent().get_parent().get_instance_id(), "hero": _hero.get_instance_id(), "level": _level.get_instance_id(), "scheduler": _scheduler.get_instance_id(), "camera": _shell.camera.get_instance_id(), "effects": _shell.fx.get_instance_id()}


func _short_ids_valid(ids: Dictionary) -> bool:
	if ids.size() != 9: return false
	var unique: Dictionary = {}
	for value: Variant in ids.values():
		if not value is int or value == 0 or not is_instance_id_valid(value) or unique.has(value): return false
		unique[value] = true
	return true


func _short_disk() -> Dictionary:
	var reader: CinderSaveStore = ProductionStore.new(_test_root + "campaign.json")
	reader.read_payload()
	var result: Dictionary = {"generation": reader.generation, "reader_error": reader.last_error, "loaded_backup": reader.loaded_backup}
	for name: String in ["campaign.json", "campaign.json.bak"]:
		var path: String = _test_root + name
		result[name] = {"raw": FileAccess.get_file_as_string(path), "sha256": FileAccess.get_sha256(path), "bytes": FileAccess.get_file_as_bytes(path).size()} if FileAccess.file_exists(path) else null
	return result


func _short_record(stage: String, packet: Dictionary, session: Dictionary, disk: Dictionary, ids: Dictionary) -> String:
	var snapshot_wire: String = ExactJson.stringify(packet)
	var session_wire: String = ExactJson.stringify(session)
	var checkpoint_wire: String = ExactJson.stringify(session.story.checkpoint)
	if snapshot_wire.is_empty() or session_wire.is_empty() or checkpoint_wire.is_empty() or not _short_ids_valid(ids): return "complete exact report receipt unavailable"
	var decimal_ids: Dictionary = {}
	for key: String in ids: decimal_ids[key] = str(ids[key])
	_short_receipts.append({"stage": stage, "exact_snapshot": snapshot_wire, "exact_session": session_wire, "exact_checkpoint": checkpoint_wire, "campaign_disk": disk.duplicate(true), "actual_native_ids_decimal": decimal_ids, "scope": "Genuine native source-free Standard entry; TEST prefix12/initial outer metadata only. No replay/combat/earned route/independent second-Shell disk Continue."})
	return ""


func _short_sources() -> Dictionary:
	var result: Dictionary = {}
	for path: String in [get_script().resource_path, "res://tests/acts/act3/mirror_sea_production_replay_smoke.gd", "res://tests/acts/act3/mirror_sea_production_warning_smoke.gd", "res://tests/acts/act3/mirror_sea_frontier_smoke.gd", "res://scenes/main.tscn", "res://scenes/player.tscn", LEVEL_PATH, RUNTIME_PATH, "res://scripts/acts/act3/mirror_sea_codec.gd", SHORT_ARRANGEMENT_PATH, "res://data/campaign/act3/mirror_sea_layout_candidate.json", "res://scripts/campaign/shell.gd", "res://scripts/campaign/level.gd", "res://scripts/campaign/attempts.gd", "res://scripts/campaign/registry.gd", "res://scripts/campaign/save_store.gd", "res://scripts/campaign/exact_json.gd", "res://scripts/campaign/snapshot_codec.gd", "res://scripts/game.gd", "res://scripts/player.gd", "res://scripts/hud.gd", "res://scripts/ui/campaign_menu.gd", "res://scripts/equipment.gd", "res://scripts/settings/game_settings.gd", "res://data/campaign/registry.json", "res://project.godot"]:
		result[path] = FileAccess.get_sha256(path)
	return result


func _expect(ok: bool, label: String, detail: String = "") -> bool:
	_checks += 1
	var row: Dictionary = {"check": _checks, "ok": ok, "label": label, "detail": detail}
	_short_rows.append(row)
	if ok: print("PASS: ", label)
	else:
		_failures += 1
		if _short_first_failure.is_empty(): _short_first_failure = row.duplicate(true)
		push_error("FAIL A3-L3 short registration: " + label + ("; " + detail if not detail.is_empty() else ""))
	return ok


func _finish() -> void:
	if _short_finishing: return
	_short_finishing = true
	await _dispose_host(_short_body_complete and _failures == 0)
	if node_added.is_connected(_watch_new_node): node_added.disconnect(_watch_new_node)
	_expect(_canonical_registry_bytes.is_empty() or FileAccess.get_file_as_string(ProductionRegistry.DATA_PATH) == _canonical_registry_bytes, "canonical registry bytes remain unchanged")
	_cleanup_owned_path(_test_root)
	_expect(_test_root.is_empty() or not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_test_root)), "only unique owned runtime Store directory is removed after normal disposal")
	var after: Dictionary = _short_sources()
	_expect(after == _short_source_before, "explicit named source observations unchanged before/after native scope")
	var complete: bool = _short_body_complete and _failures == 0
	var report: Dictionary = {"schema_version": 1, "kind": "a3-l3-short-registration", "checks": _checks, "failures": _failures, "rows": _short_rows, "first_failure": _short_first_failure, "complete": complete, "success": complete and _failures == 0, "receipts": _short_receipts, "source_before": _short_source_before, "source_after": after, "scope": "Canonical current source-free entry/prerequisite lock, exact initial native/full Story/disk and public entrance Retry/quiet fresh native recipients/cleanup only. Inherited Main genuine Standard writers; disclosed TEST prefix12/initial outer Shell metadata.", "limits": "No legacy/Challenge transport repetition, independent second-Shell disk Continue, replay, combat, earned checkpoint/route/exit, portrait, human balance, performance, mobile or acceptance credit. Historical full replay evidence remains unchanged."}
	if _short_report_path.is_empty() or not _short_report_path.is_absolute_path():
		print("A3-L3 short registration report requires absolute owned destination"); quit(2); return
	DirAccess.make_dir_recursive_absolute(_short_report_path.get_base_dir())
	var file := FileAccess.open(_short_report_path, FileAccess.WRITE)
	if file == null: print("A3-L3 short registration report open failed"); quit(2); return
	file.store_string(JSON.stringify(report, "\t") + "\n"); file.close()
	print(SHORT_REPORT_ENV + " path=" + _short_report_path + " sha256=" + FileAccess.get_sha256(_short_report_path))
	print("A3-L3 short registration: %d checks/%d failures; complete=%s" % [_checks, _failures, str(complete)])
	quit(0 if complete and _failures == 0 else 1)
