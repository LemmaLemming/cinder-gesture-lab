extends "res://tests/acts/act1/a1_o1_campaign.gd"
## Three genuine49 paused units; actual fresh production Shell active-side load.
## Public menu signal/passive focus only; no GUI/input, fight or route credit.
## No packet/body/HP/phase/cue/camera/clock rewrite. Only menu hidden for PNG.

const ProducerPath: String = "res://.cinder/a1-o1-campaign-79846-772192.json"
const ProducerSha: String = "407b5120f0dd4c395945df284c26f199d0f1891b66c294d8bce44af6682b6f96"
const ReceiptPath: String = "res://.cinder/a1-o1-campaign02.json"
const ReceiptSha: String = "faeee9197799faf91645189b284175b4379f5affdaa3cef6f9ac4cedc691647a"
const BankPath: String = "res://.cinder/a1-o1-campaign02-source"
const BankSha: String = "7fd8533aeec136f69011662a32b69ae70522954f35f9094f101ea76e5400b4cd"
const PinsPath: String = "res://tests/acts/act1/fixtures/a1_o1_saved_portrait_sources.json"
const PinsSha: String = "95832bd61cdf43a88ce08a2e0f7728be24e407d949c0f8b050b19b69a8238111"
const PortraitSize := Vector2i(540, 1170)
const WholeMs: int = 45000
const PacketIndices: Array[int] = [0, 1, 9]
const PacketLabels: Array[String] = ["actual optional entrance", "actual partial contact live C30-impact Save", "actual repaired hatch before contact"]
const PacketHashes: Array[String] = ["39c5b91d4dea8bc3af524bea6948e100996f3eef2cd8de70390990a0331f2fa0", "48fca10398d09ba354ff2aa49d617f6913a48968a39093958dc3d2ee3f1142ab", "bae767afcb553640168bfbc253fc5d248280ff1545870a4e660749aafc16e646"]

class FocusObserver extends Node:
	var receive: Callable
	func _notification(what: int) -> void:
		if not receive.is_valid(): return
		if what == NOTIFICATION_APPLICATION_FOCUS_IN: receive.call("application-focus-in")
		elif what == NOTIFICATION_APPLICATION_FOCUS_OUT: receive.call("application-focus-out")
		elif what == NOTIFICATION_APPLICATION_PAUSED: receive.call("application-paused")
		elif what == NOTIFICATION_APPLICATION_RESUMED: receive.call("application-resumed")

var producer: Dictionary = {}
var source_pins: Dictionary = {}
var focus_observer: Node
var focus_rows: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var capture_dir: String
var hidden_menu: CinderCampaignMenu
var menu_visible_before: bool


func _run() -> void:
	root.size = PortraitSize
	test_root = "user://test-act1-o1-saved-portrait-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	report_path = "res://.cinder/a1-o1-saved-portrait-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	registry_bytes = FileAccess.get_file_as_bytes(Registry.DATA_PATH)
	if not _expect(DisplayServer.get_name() != "headless", "actual graphical renderer required"): await _finish(); return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--level-scene") or argument in ["--capture", "--capture-polish"]:
			_expect(false, "production paused Shell path required"); await _finish(); return
	var observer := FocusObserver.new(); observer.process_mode = Node.PROCESS_MODE_ALWAYS
	observer.receive = Callable(self, "_record_focus"); focus_observer = observer; root.add_child(observer)
	root.focus_entered.connect(_record_focus.bind("window-focus-entered")); root.focus_exited.connect(_record_focus.bind("window-focus-exited"))
	_record_focus("passive-startup-observation")
	if not _provenance(): await _finish(); return
	var document: Variant = JSON.parse_string(registry_bytes.get_string_from_utf8())
	if not _expect(document is Dictionary and document.get("levels") is Array, "canonical registry readable"): await _finish(); return
	raw = document.duplicate(true)
	for row: Dictionary in raw.levels:
		if row.id == Layout.LEVEL_ID:
			setups.append({"kind": "TEST O1 in-memory accepted scene metadata", "before": row.duplicate(true)})
			row.scene_path = O1_PATH; row.readiness = "accepted"; row.accepted_commit = "f".repeat(40); row.api_revision = Registry.API_REVISION
	var registry := Registry.new(raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error(Layout.LEVEL_ID).is_empty(), "isolated O1 row validates"): await _finish(); return
	protected_story = _packet(producer.receipts[0].protected_story)
	if protected_story.is_empty(): await _finish(); return
	capture_dir = "res://.cinder/captures/o1-saved-portrait-%d" % Time.get_ticks_usec()
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir)) == OK, "unique portrait directory writable"): await _finish(); return
	for view: int in range(PacketIndices.size()):
		var row: Dictionary = producer.receipts[PacketIndices[view]]
		var checkpoint_wire: String = producer.receipts[0].exact_snapshot if view == 0 else (row.exact_checkpoint if view == 1 else producer.receipts[3].exact_snapshot)
		if not await _restore_view(row, checkpoint_wire, registry) or not await _capture_view(row, view): await _finish(); return
		if not await _retire(): await _finish(); return
	await _finish()


func _provenance() -> bool:
	if not _expect(FileAccess.get_sha256(ProducerPath) == ProducerSha and FileAccess.get_sha256(ReceiptPath) == ReceiptSha and FileAccess.get_sha256(BankPath + "/manifest.json") == BankSha and FileAccess.get_sha256(PinsPath) == PinsSha, "original passing producer/closed recorder/source bank and bounded pins unchanged"): return false
	var receipt: Variant = JSON.parse_string(FileAccess.get_file_as_string(ReceiptPath))
	var bank: Variant = JSON.parse_string(FileAccess.get_file_as_string(BankPath + "/manifest.json"))
	var pins: Variant = JSON.parse_string(FileAccess.get_file_as_string(PinsPath))
	var report: Variant = JSON.parse_string(FileAccess.get_file_as_string(ProducerPath))
	if not _expect(receipt is Dictionary and receipt.exit_code == 0 and receipt.native_checks == 49 and receipt.native_failures == 0 and receipt.raw_error_warning_lines.is_empty() and receipt.post_run_frozen_member_changes.is_empty() and receipt.prior_uid_changes.is_empty() and receipt.current_active_uids == 525 and receipt.current_uids_unique and receipt.native_report_sha256 == ProducerSha and receipt.source_manifest_sha256 == BankSha, "actual49/0 clean producer custody required"): return false
	if not _expect(bank is Dictionary and bank.api_revision == "campaign-shared-59" and bank.files is Array and bank.files.size() == 915 and pins is Dictionary and pins.api_revision == "act1-o1-portrait-source-pins-1" and pins.source_manifest_sha256 == BankSha and pins.paths is Dictionary and not pins.paths.is_empty(), "bounded relevant runtime pins belong to exact frozen producer bank"): return false
	source_pins = pins.paths.duplicate(true)
	var members: Dictionary = {}
	for row: Dictionary in bank.files: members[row.path] = row.sha256
	for path: String in source_pins:
		if members.get(path, "") != source_pins[path]: return _expect(false, "runtime pin is not an authentic producer member: " + path)
	if not _source_guard(): return false
	if not _expect(report is Dictionary and report.checks == 49 and report.failures == 0 and report.first_failure.is_empty() and report.receipts is Array and report.receipts.size() == 11, "literal passing producer receipts required"): return false
	producer = report
	for view: int in range(PacketIndices.size()):
		var row: Dictionary = producer.receipts[PacketIndices[view]]
		if not _expect(row.label == PacketLabels[view] and row.exact_snapshot.sha256_text() == PacketHashes[view], "selected exact genuine view/packet identity"): return false
	return _expect(producer.receipts[1].exact_checkpoint == producer.receipts[0].exact_snapshot and producer.receipts[3].label == "actual pre-final checkpoint", "genuine entrance/earlier checkpoint wires remain original")


func _source_guard() -> bool:
	if not _expect(FileAccess.get_sha256(ProducerPath) == ProducerSha and FileAccess.get_sha256(ReceiptPath) == ReceiptSha and FileAccess.get_sha256(BankPath + "/manifest.json") == BankSha, "producer/report/source manifest bytes preserved"): return false
	for path: String in source_pins:
		if FileAccess.get_sha256("res://" + path) != source_pins[path] or FileAccess.get_sha256(BankPath + "/" + path) != source_pins[path]: return _expect(false, "actual used runtime or retained producer source changed: " + path)
	return _expect(true, "bounded relevant current runtime/retained producer pins all match")


func _packet(wire: String) -> Dictionary:
	var parsed: Dictionary = Exact.parse(wire)
	if not _expect(parsed.get("accepted", false) and parsed.get("value") is Dictionary and Exact.stringify(parsed.value) == wire, "genuine typed whole packet round-trips unchanged"): return {}
	return parsed.value


func _restore_view(row: Dictionary, checkpoint_wire: String, registry: CinderCampaignRegistry) -> bool:
	var saved: Dictionary = _packet(row.exact_snapshot); var checkpoint: Dictionary = _packet(checkpoint_wire)
	if saved.is_empty() or checkpoint.is_empty(): return false
	if not _expect(saved.paused and saved.level_id == Layout.LEVEL_ID and not saved.level.progress.completed, "genuine paused pre-completion side unit"): return false
	var model := Attempts.new(registry); var payload: Dictionary = model.state()
	payload.completed_main = PREFIX.duplicate(); payload.story = protected_story.duplicate(true)
	payload.side_attempt = {"kind": "optional", "level_id": Layout.LEVEL_ID, "snapshot": saved.duplicate(true), "checkpoint": checkpoint.duplicate(true)}
	setups.append({"kind": "TEST transport envelope: disclosed completed[L1,L2] prefix + original protected Story and optional snapshot/checkpoint", "receipt_label": row.label, "packet_fields_changed": false})
	var store := Store.new(test_root + "campaign.json"); store.payload_validator = model.saved_payload_error
	if not _expect(model.state_error(payload).is_empty() and store.write_payload(payload), "public Attempts/format2 Store accepts isolated lossless transport envelope"): return false
	if not await _new_shell(): return false # Actual Title invokes current complete saved validators.
	operation = "public paused Resume Side: " + row.label
	game.menu.resume_requested.emit()
	if not await _await_operation(func() -> bool: return _live(Layout.LEVEL_ID) and paused and game.menu.page_name() == "resume", "public Title active-side Continue installs saved unit", 10.0): return false
	var layout_packet: String = Exact.stringify(game.capture_campaign_snapshot()); var layout_camera: String = _camera_wire(); var layout_native: String = _native_wire()
	await process_frame; await process_frame # Normal paused Control layout only.
	if not _expect(is_instance_valid(game) and paused, "actual paused recipient survives normal UI layout settlement"): return false
	var actual: Dictionary = game.capture_campaign_snapshot(); var callbacks: Array[Dictionary] = _recipient_callbacks()
	return _expect(Exact.stringify(actual) == layout_packet and _camera_wire() == layout_camera and _native_wire() == layout_native and _same(actual, saved) and callbacks.is_empty() and _bindings() and _same(game.attempts.state().story, protected_story) and _same(game.attempts.state().side_attempt.checkpoint, checkpoint) and _durable() and game.active_level.snapshot_error_with_player(actual.level, actual.player).is_empty(), "fresh exact installed recipient restores whole packet/native body/clock/cues with zero recipient callbacks")


func _capture_view(row: Dictionary, view: int) -> bool:
	if not _source_guard(): return false
	var points: Array = game.active_level.camera_framing_points()
	if not _expect(paused and not points.is_empty() and game.active_level.last_camera_framing_error.is_empty() and game.camera_framing_error(points).is_empty(), "actual saved Camera/HUD contains complete native required union"): return false
	var before: String = Exact.stringify(game.capture_campaign_snapshot()); var native: String = _native_wire()
	var camera: String = _camera_wire(); var input: String = Exact.stringify(_portable(game.get_input_observation_state())); var ui: String = _ui_wire()
	setups.append({"kind": "pre-PNG exact signature diagnostic", "packet_matches": before == row.exact_snapshot, "actual_packet": before if before != row.exact_snapshot else "exact original", "original_packet_sha256": row.exact_snapshot.sha256_text(), "actual_packet_sha256": before.sha256_text(), "native_wire_bytes": native.length(), "camera_wire_bytes": camera.length(), "input_wire_bytes": input.length(), "ui_wire_bytes": ui.length()})
	if not _expect(before == row.exact_snapshot and not native.is_empty() and not camera.is_empty() and not input.is_empty() and not ui.is_empty(), "full exact packet/native/camera/input/UI before PNG"): return false
	hidden_menu = game.menu; menu_visible_before = hidden_menu.visible; hidden_menu.visible = false
	await RenderingServer.frame_post_draw
	var valid: bool = _expect(is_instance_valid(game) and paused, "actual paused recipient survives the render await")
	if valid: valid = _expect(Exact.stringify(game.capture_campaign_snapshot()) == before and _native_wire() == native and _camera_wire() == camera and Exact.stringify(_portable(game.get_input_observation_state())) == input, "only menu hiding preserves full native/clock/cues/camera/input")
	var picture: Image = root.get_texture().get_image() if valid else null
	var path: String = capture_dir.path_join("%02d-%s.png" % [view + 1, ["entrance", "live-circuit-impact", "repaired-hatch"][view]])
	var png_ok: bool = picture != null and picture.get_size() == PortraitSize and picture.save_png(path) == OK
	if png_ok:
		var decoded: Image = Image.load_from_file(path); png_ok = decoded != null and not decoded.is_empty() and decoded.get_size() == PortraitSize
	_restore_menu()
	if not valid: return false
	if not _expect(png_ok and _ui_wire() == ui and Exact.stringify(game.capture_campaign_snapshot()) == before and _native_wire() == native and _camera_wire() == camera and Exact.stringify(_portable(game.get_input_observation_state())) == input and _recipient_callbacks().is_empty() and _source_guard(), "actual540x1170 PNG restores full exact native/camera/input/UI and producer bytes"): return false
	shots.append({"label": row.label, "path": ProjectSettings.globalize_path(path), "source_receipt_index": PacketIndices[view], "source_packet_sha256": PacketHashes[view], "paused": true, "only_menu_temporarily_hidden": true, "whole_before_after_exact": before, "native_before_after_exact": native, "camera_before_after_exact": camera, "input_before_after_exact": input, "ui_before_after_exact": ui, "installed_recipient_callbacks": _recipient_callbacks(), "optical_review": "pending personal inspection; native containment does not grant art acceptance"})
	return true


func _native_wire() -> String:
	var rows: Dictionary = {"player": game.player.snapshot_state(), "player_body": _body(game.player), "scheduler_clock": _scheduler().get_clock(), "parts": {}, "scenery": game.active_level.get("scenery").call("presentation_state")}
	for id: String in [Layout.CIRCUIT_SOURCE_ID, Layout.FINAL_SOURCE_ID]:
		var actor: Act1RushSelenite = _source(id)
		rows[id] = {"state": _portable(actor.state()), "body": _body(actor), "cue": _cue(actor.get_cue()), "sprite": _portable({"id": str(actor.get_art().call("sprite").get_instance_id()), "transform": actor.get_art().call("sprite").global_transform, "texture": str(actor.get_art().call("sprite").texture.get_instance_id())})}
	rows[Layout.IMPACT_ID] = {"state": _portable(_impact().state()), "cue": _cue(_impact().get_cue())}
	for id: String in Layout.PART_IDS:
		var part: Node3D = (game.active_level.get("parts") as Dictionary)[id]
		rows.parts[id] = {"state": part.call("presentation_state"), "contact": _portable(part.call("contact_area").global_transform), "cue": _cue(part.call("get_cue"))}
	rows.hatch_cue = _cue(game.active_level.get("hatch_cue")); return Exact.stringify(_portable(rows))


func _body(actor: CharacterBody3D) -> Dictionary:
	var collision := actor.get_node("BodyCollision") as CollisionShape3D
	var shape := collision.shape as CapsuleShape3D
	return {"id": str(actor.get_instance_id()), "transform": _portable(actor.global_transform), "velocity": Codec.vector3(actor.velocity), "visible": actor.visible, "layer": actor.collision_layer, "mask": actor.collision_mask, "collision": str(collision.get_instance_id()), "collision_transform": _portable(collision.global_transform), "disabled": collision.disabled, "shape": str(shape.get_instance_id()), "radius": shape.radius, "height": shape.height}


func _cue(cue: Node3D) -> Dictionary:
	var rows: Array = []
	for node: Node in cue.find_children("*", "MeshInstance3D", true, false):
		var material: Material = node.material_override
		rows.append({"id": str(node.get_instance_id()), "transform": _portable(node.global_transform), "visible": node.visible, "mesh": str(node.mesh.get_instance_id()) if node.mesh != null else "none", "material": str(material.get_instance_id()) if material != null else "none", "color": _portable(material.albedo_color) if material is StandardMaterial3D else []})
	return {"id": str(cue.get_instance_id()), "state": _portable(cue.call("state")), "meshes": rows}


func _camera_wire() -> String:
	return Exact.stringify(_portable({"transform": game.camera.global_transform, "size": game.camera.size, "near": game.camera.near, "far": game.camera.far, "framing": game.get_camera_framing_state(), "safe_rect": game.hud.combat_safe_rect()}))


func _ui_wire() -> String:
	var rows: Dictionary = {"menu_visible": game.menu.visible, "page": game.menu.page_name(), "hud_visible": game.hud.visible}
	for surface: Node in [game.menu, game.hud]:
		for node: Node in surface.find_children("*", "Control", true, false):
			var value: Dictionary = {"visible": node.visible, "in_tree_visible": node.is_visible_in_tree(), "rect": _portable(node.get_global_rect())}
			if node is Label: value.text = node.text
			if node is Button: value.disabled = node.disabled
			rows[String(node.get_path())] = value
	var wire: String = Exact.stringify(_portable(rows))
	if wire.is_empty(): setups.append({"kind": "UI signature encoding refusal diagnostic", "rows": rows})
	return wire


func _portable(value: Variant) -> Variant:
	if value is Rect2: return {"position": _portable(value.position), "size": _portable(value.size)}
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _portable(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_portable(item))
		return result
	return _encode(value)


func _record_focus(label: String) -> void:
	if focus_rows.size() < 128: focus_rows.append({"label": label, "wall_usec": Time.get_ticks_usec(), "native_focus": DisplayServer.window_is_focused(root.get_window_id()), "paused": paused})


func _restore_menu() -> void:
	if is_instance_valid(hidden_menu): hidden_menu.visible = menu_visible_before
	hidden_menu = null


func _retire() -> bool:
	var refs: Array[WeakRef] = _refs(game); operation = "normal public saved-view exit"
	if is_instance_valid(game.active_level): game.active_level.exit_level()
	game.free(); game = null
	await process_frame
	return _expect(_freed(refs) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "native recipient retires normally before next original packet")


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > WholeMs:
		_expect(false, "actual paused portrait watchdog reached45 seconds"); _finish.call_deferred()


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true; _restore_menu(); await process_frame
	var refs: Array[WeakRef] = []
	if is_instance_valid(game):
		if is_instance_valid(game.active_level): game.active_level.exit_level()
		refs.append_array(_refs(game)); game.free(); game = null
	if is_instance_valid(focus_observer): refs.append(weakref(focus_observer)); focus_observer.free()
	if root.focus_entered.is_connected(_record_focus.bind("window-focus-entered")): root.focus_entered.disconnect(_record_focus.bind("window-focus-entered"))
	if root.focus_exited.is_connected(_record_focus.bind("window-focus-exited")): root.focus_exited.disconnect(_record_focus.bind("window-focus-exited"))
	paused = false; await create_timer(0.5, true).timeout; await process_frame
	_expect((refs.is_empty() or _freed(refs)) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal native/source/cue/focus-observer cleanup")
	_expect(shots.size() == PacketIndices.size(), "all three selected genuine paused views produced actual PNGs")
	_expect(FileAccess.get_file_as_bytes(Registry.DATA_PATH) == registry_bytes, "canonical registry bytes unchanged")
	if not source_pins.is_empty(): _source_guard()
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null: _expect(false, "unique portrait report writable")
	else:
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "first_failure": first_failure, "shots": shots, "focus_events": focus_rows, "source_report_sha256": ProducerSha, "closed_receipt_sha256": ReceiptSha, "source_manifest_sha256": BankSha, "setups": setups, "observations": observations, "elapsed_ms": Time.get_ticks_msec() - started_ms, "scope": "Three genuine49 complete paused packets through public production Shell/Attempts/format2 Store and disclosed TEST prefix/optional transport envelope. Title Resume Side signal; no GUI/input/fight/phase/HP/camera/clock seeds or earned route credit. Passive focus, zero callbacks credited only to exact installed recipients; candidate/retired-donor callbacks separately retained. Only menu CanvasLayer hidden for540x1170 PNG; full exact native/body/clock/cue/camera/input/UI and producer-byte preservation. Personal PNG optical inspection pending; no full-view/playthrough gate."}, "\t")); file.close()
	var directory := DirAccess.open(test_root)
	if directory != null:
		for name: String in directory.get_files(): DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root))
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-O1 SAVED PORTRAIT: %d checks, %d failures; %d shots; report=%s" % [checks, failures, shots.size(), report_path])
	quit(1 if failures > 0 else 0)
