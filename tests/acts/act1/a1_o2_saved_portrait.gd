extends "res://tests/acts/act1/a1_o2_campaign.gd"
## SOURCE ONLY until Root supplies a genuine passing campaign report, reviews,
## promotes, imports and runs this fixture. No invented packet/producer hash.
## Two genuine paused Attempts through public production Title/active-side load.
## No fight replay, Hero/camera reposition, native world step or focus forcing.
## Only the menu overlay is temporarily hidden for the actual rendered PNG.

const PortraitSize := Vector2i(540, 1170)
const WholeMs: int = 120000
const PINS_API: String = "act1-o2-portrait-source-pins-1"
const RequiredPinPaths: Array[String] = [
	"project.godot", "scenes/main.tscn", "scenes/acts/act1/a1_l3.tscn", "scenes/acts/act1/a1_o2.tscn",
	"scripts/campaign/shell.gd", "scripts/campaign/level.gd", "scripts/campaign/attempts.gd", "scripts/campaign/save_store.gd", "scripts/campaign/exact_json.gd", "scripts/campaign/registry.gd",
	"scripts/game.gd", "scripts/player.gd", "scripts/hud.gd", "scripts/ui/campaign_menu.gd", "scripts/presentation/camera_framing.gd",
	"scripts/acts/act1/spore_bloom.gd", "scripts/acts/act1/spore_bloom_layout.gd", "scripts/acts/act1/spore_bloom_codec.gd", "scripts/acts/act1/mushroom_caverns.gd",
	"scripts/acts/act1/mushroom_selenite.gd", "scripts/acts/act1/mushroom_selenite_art.gd", "scripts/acts/act1/mushroom_cluster_art.gd", "scripts/acts/act1/mushroom_grotto_art.gd",
	"scripts/environment/spore_field.gd", "scripts/environment/spore_cluster.gd", "scripts/environment/spore_repulsion.gd", "scripts/environment/scheduler_spore_source_protocol.gd",
	"scripts/combat/repulsion_route.gd", "scripts/combat/threat_scheduler.gd", "tests/acts/act1/a1_o2_campaign.gd", "data/campaign/registry.json", "data/design/player_equipment.json",
]

class FocusObserver extends Node:
	var receive: Callable
	func _notification(what: int) -> void:
		if not receive.is_valid(): return
		if what == NOTIFICATION_APPLICATION_FOCUS_IN: receive.call("application-focus-in")
		elif what == NOTIFICATION_APPLICATION_FOCUS_OUT: receive.call("application-focus-out")
		elif what == NOTIFICATION_APPLICATION_PAUSED: receive.call("application-paused")
		elif what == NOTIFICATION_APPLICATION_RESUMED: receive.call("application-resumed")

var options: Dictionary = {
	"source-report": "", "source-report-sha256": "", "source-recorder": "", "source-recorder-sha256": "", "source-pins": "", "source-pins-sha256": "",
	"entrance-label": "actual pristine optional entrance", "partial-label": "actual first near-field partial Save",
}
var producer: Dictionary = {}
var producer_receipt: Dictionary = {}
var selected: Array[Dictionary] = []
var selected_indices: Array[int] = []
var source_pins: Dictionary = {}
var source_bank: String = ""
var source_bank_sha: String = ""
var focus_observer: Node
var focus_rows: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var capture_dir: String
var hidden_menu: CinderCampaignMenu
var menu_visible_before: bool


func _run() -> void:
	root.size = PortraitSize
	test_root = "user://test-act1-o2-saved-portrait-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	report_path = "res://.cinder/a1-o2-saved-portrait-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	registry_bytes = FileAccess.get_file_as_bytes(Registry.DATA_PATH)
	if not _expect(DisplayServer.get_name() != "headless", "actual graphical renderer required"): await _finish(); return
	if not _read_options(): await _finish(); return
	var observer := FocusObserver.new(); observer.process_mode = Node.PROCESS_MODE_ALWAYS
	observer.receive = Callable(self, "_record_focus"); focus_observer = observer; root.add_child(observer)
	root.focus_entered.connect(_record_focus.bind("window-focus-entered")); root.focus_exited.connect(_record_focus.bind("window-focus-exited"))
	_record_focus("passive-startup-observation")
	if not _provenance(): await _finish(); return
	var document: Variant = JSON.parse_string(registry_bytes.get_string_from_utf8())
	if not _expect(document is Dictionary and document.get("levels") is Array, "canonical registry readable"): await _finish(); return
	raw = document.duplicate(true)
	var changed: int = 0
	for row: Dictionary in raw.levels:
		if row.id == Bloom.LEVEL_ID:
			setups.append({"kind": "TEST O2 in-memory accepted scene metadata only", "before": row.duplicate(true)})
			row.scene_path = O2_PATH; row.readiness = "accepted"; row.accepted_commit = "f".repeat(40); row.api_revision = Registry.API_REVISION
			changed += 1
	var registry := Registry.new(raw)
	if not _expect(changed == 1 and registry.last_error.is_empty() and registry.scene_error(Bloom.LEVEL_ID).is_empty(), "isolated O2 row validates without changing canonical bytes"): await _finish(); return
	capture_dir = "res://.cinder/captures/o2-saved-portrait-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir)) == OK, "unique portrait directory writable"): await _finish(); return
	for view: int in range(selected.size()):
		var row: Dictionary = selected[view]
		if not await _restore_view(row, registry) or not await _capture_view(row, view): await _finish(); return
		if not await _retire(): await _finish(); return
	await _finish()


func _read_options() -> bool:
	var seen: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		var separator: int = argument.find("=")
		if not argument.begins_with("--") or separator <= 2: return _expect(false, "portrait requires explicit named source paths/hashes/labels, no preview arguments")
		var key: String = argument.substr(2, separator - 2)
		if not options.has(key) or seen.has(key): return _expect(false, "unknown or duplicate portrait option: " + key)
		options[key] = argument.substr(separator + 1); seen[key] = true
	for key: String in ["source-report", "source-recorder", "source-pins", "entrance-label", "partial-label"]:
		if String(options[key]).is_empty(): return _expect(false, "required actual portrait source option missing: " + key)
	for key: String in ["source-report-sha256", "source-recorder-sha256", "source-pins-sha256"]:
		if not _sha(String(options[key])): return _expect(false, "required literal expected source SHA256 missing: " + key)
	return _expect(options["entrance-label"] != options["partial-label"], "two distinct uniquely labeled genuine campaign receipts required")


func _sha(value: String) -> bool:
	if value.length() != 64: return false
	for character: String in value:
		if character not in "0123456789abcdef": return false
	return true


func _provenance() -> bool:
	if not _expect(FileAccess.get_sha256(options["source-report"]) == options["source-report-sha256"] and FileAccess.get_sha256(options["source-recorder"]) == options["source-recorder-sha256"] and FileAccess.get_sha256(options["source-pins"]) == options["source-pins-sha256"], "actual source report/closed recorder/bounded runtime pin bytes match explicit expected hashes"): return false
	var report: Variant = JSON.parse_string(FileAccess.get_file_as_string(options["source-report"]))
	var receipt: Variant = JSON.parse_string(FileAccess.get_file_as_string(options["source-recorder"]))
	var pins: Variant = JSON.parse_string(FileAccess.get_file_as_string(options["source-pins"]))
	if not _expect(report is Dictionary and report.get("checks", 0) > 0 and report.get("failures", -1) == 0 and report.get("first_failure") is Dictionary and report.first_failure.is_empty() and report.get("receipts") is Array, "literal successful actual campaign report required; no planned/generated placeholder"): return false
	if not _expect(receipt is Dictionary and receipt.get("exit_code", -1) == 0 and receipt.get("native_checks") == report.checks and receipt.get("native_failures", -1) == 0 and receipt.get("raw_error_warning_lines") == [] and receipt.get("post_run_frozen_member_changes") == [] and receipt.get("prior_uid_changes") == [] and receipt.get("current_uids_unique", false) and receipt.get("native_report_sha256") == options["source-report-sha256"] and receipt.get("explicit_footer") is Array and receipt.explicit_footer.size() == 1 and receipt.explicit_footer[0] is String and receipt.explicit_footer[0].begins_with("A1-O2 CAMPAIGN:"), "passing closed queued campaign recorder joins the actual native report without warnings/source/UID drift"): return false
	if not _expect(receipt.get("native_report") is String and ProjectSettings.globalize_path(options["source-report"]) == receipt.native_report and receipt.get("source_archive") is String and _sha(String(receipt.get("source_manifest_sha256", ""))), "exact recorder source report path and retained source archive required"): return false
	producer = report; producer_receipt = receipt
	source_bank = receipt.source_archive; source_bank_sha = receipt.source_manifest_sha256
	if not _expect(FileAccess.get_sha256(source_bank.path_join("manifest.json")) == source_bank_sha, "actual frozen producer manifest bytes match closed recorder"): return false
	var bank: Variant = JSON.parse_string(FileAccess.get_file_as_string(source_bank.path_join("manifest.json")))
	if not _expect(bank is Dictionary and bank.get("api_revision") == receipt.get("api_revision") and bank.get("files") is Array and pins is Dictionary and pins.get("api_revision") == PINS_API and pins.get("source_manifest_sha256") == source_bank_sha and pins.get("paths") is Dictionary and not pins.paths.is_empty(), "selected runtime pins belong to the real passing producer source manifest"): return false
	source_pins = pins.paths.duplicate(true)
	var members: Dictionary = {}
	for row: Dictionary in bank.files: members[row.path] = row.sha256
	for path: String in RequiredPinPaths:
		if not source_pins.has(path): return _expect(false, "required actual runtime input absent from bounded source pins: " + path)
	for path: String in source_pins:
		if path.is_absolute_path() or ".." in path.split("/") or not _sha(String(source_pins[path])) or members.get(path, "") != source_pins[path]: return _expect(false, "runtime pin is not an authentic bounded producer member: " + path)
	if not _source_guard(): return false
	for label: String in [options["entrance-label"], options["partial-label"]]:
		var matches: Array[int] = []
		for index: int in range(producer.receipts.size()):
			var row: Variant = producer.receipts[index]
			if row is Dictionary and row.get("label") == label: matches.append(index)
		if not _expect(matches.size() == 1, "source report contains exactly one genuine selected receipt: " + label): return false
		var row: Dictionary = producer.receipts[matches[0]]
		if not _expect(row.get("exact_snapshot") is String and row.get("exact_attempts") is String and row.get("saved_envelope_json") is String, "selected receipt retains original whole snapshot/Attempt and save envelope: " + label): return false
		selected.append(row); selected_indices.append(matches[0])
	return true


func _source_guard() -> bool:
	if not _expect(FileAccess.get_sha256(options["source-report"]) == options["source-report-sha256"] and FileAccess.get_sha256(options["source-recorder"]) == options["source-recorder-sha256"] and FileAccess.get_sha256(source_bank.path_join("manifest.json")) == source_bank_sha and FileAccess.get_sha256(options["source-pins"]) == options["source-pins-sha256"], "original producer/closed recorder/source manifest/pins bytes remain exact"): return false
	for path: String in source_pins:
		if FileAccess.get_sha256("res://" + path) != source_pins[path] or FileAccess.get_sha256(source_bank.path_join(path)) != source_pins[path]: return _expect(false, "used current runtime or retained producer source bytes changed: " + path)
	return _expect(true, "bounded actual runtime and retained producer source inputs match")


func _selected_view_shape(row: Dictionary, saved: Dictionary) -> bool:
	if not _expect(_closed(saved) and BloomCodec.progress_error(saved.level).is_empty(), "original selected view retains complete O2 metadata/progress"): return false
	if row.label == options["entrance-label"]:
		return _expect(_pristine(saved), "selected entrance is the real pristine dormant zero-clock unit")
	var local: Dictionary = saved.level.local
	var field: Variant = local.fields.get("bloom-near")
	var consumer: Variant = local.consumers.get(Bloom.consumer_id(0))
	return _expect(local.beat_index == 0 and local.room_stage == "active" and field is Dictionary and field.get("schema_version") == 1 and field.get("phase") in ["active", "thinning"] and field.get("generation") == 1 and field.get("spent_ids") == ["cluster-right"] and consumer is Dictionary and consumer.get("schema_version") == 2 and consumer.get("records") is Dictionary and not consumer.records.is_empty(), "selected partial view is the real finite near-field native first-group unit")


func _await_operation(predicate: Callable, label: String, seconds: float) -> bool:
	var began: int = Time.get_ticks_msec()
	var deadline: int = began + int(seconds * 1000.0)
	while not finishing:
		if not _operation_healthy(): return false
		# A synchronous Godot operation may complete between observations after
		# the async wait deadline. Observe its real result before timeout; record
		# any overrun without inventing an 8/12 s bound on synchronous execution.
		if predicate.call() == true:
			await process_frame
			var okay: bool = _operation_healthy() and predicate.call() == true
			if Time.get_ticks_msec() > deadline:
				setups.append({"kind": "completed public operation observed after async wait deadline", "label": label, "requested_wait_seconds": seconds, "observed_wall_ms": Time.get_ticks_msec() - began, "predicate_after_settle": okay, "synchronous_calls_are_not_preempted": true})
			return okay
		if Time.get_ticks_msec() > deadline: return _expect(false, "unfinished public operation exceeded async observation deadline: " + label)
		await process_frame
	return false


func _restore_view(row: Dictionary, registry: CinderCampaignRegistry) -> bool:
	var saved: Dictionary = _packet(row.exact_snapshot)
	var payload: Dictionary = _packet(row.exact_attempts)
	if saved.is_empty() or payload.is_empty() or not _selected_view_shape(row, saved): return false
	var side: Variant = payload.get("side_attempt")
	var source_envelope: Variant = JSON.parse_string(row.saved_envelope_json)
	if not _expect(saved.paused and saved.level_id == Bloom.LEVEL_ID and not saved.level.progress.completed and payload.get("completed_main") == PREFIX and payload.get("story") is Dictionary and side is Dictionary and side.get("kind") == "optional" and side.get("level_id") == Bloom.LEVEL_ID and _same(side.get("snapshot"), saved) and side.get("checkpoint") is Dictionary and Exact.stringify(side.checkpoint) == selected[0].exact_snapshot and source_envelope is Dictionary and source_envelope.get("format_version") == 2 and source_envelope.get("payload_json") == row.exact_attempts, "selected original whole Attempt/save envelope carries this exact paused O2 snapshot and genuine checkpoint"): return false
	if protected_story.is_empty(): protected_story = payload.story.duplicate(true)
	if not _expect(_same(payload.story, protected_story), "both genuine views preserve the same original full Story"): return false
	var model := Attempts.new(registry)
	var store := Store.new(test_root + "campaign.json"); store.payload_validator = model.saved_payload_error
	if not _expect(model.state_error(payload).is_empty() and store.write_payload(payload) and Exact.stringify(payload) == row.exact_attempts, "public validated Attempts/format2 Store accepts the complete original unmodified Attempt"): return false
	setups.append({"kind": "original genuine whole Attempt transported through public isolated Store", "receipt_label": row.label, "source_attempt_sha256": row.exact_attempts.sha256_text(), "source_snapshot_sha256": row.exact_snapshot.sha256_text(), "packet_fields_changed": false, "storage_envelope_generation_is_new": true})
	if not await _new_shell(): return false
	operation = "public paused Title Resume Side: " + row.label
	game.menu.resume_requested.emit()
	if not await _await_operation(func() -> bool: return _live(Bloom.LEVEL_ID) and paused and game.menu.page_name() == "resume", "public Title active-side Continue installs genuine saved unit", 12.0): return false
	var layout_packet: String = Exact.stringify(game.capture_campaign_snapshot()); var layout_camera: String = _camera_wire(); var layout_native: String = _native_wire()
	await process_frame; await process_frame # Two actual paused UI layout frames.
	if not _expect(is_instance_valid(game) and paused, "actual paused installed recipient survives two UI settle frames"): return false
	var actual: Dictionary = game.capture_campaign_snapshot(); var callbacks: Array[Dictionary] = _recipient_callbacks()
	return _expect(Exact.stringify(actual) == layout_packet and _camera_wire() == layout_camera and _native_wire() == layout_native and _same(actual, saved) and Exact.stringify(game.attempts.state()) == row.exact_attempts and callbacks.is_empty() and _bindings() and _same(game.attempts.state().story, protected_story) and _same(game.attempts.state().side_attempt.checkpoint, side.checkpoint) and _durable() and game.active_level.snapshot_error_with_player(actual.level, actual.player).is_empty(), "fresh exact recipient quietly installs whole original Attempt/body/clock/cues and survives paused UI settlement")


func _capture_view(row: Dictionary, view: int) -> bool:
	if not _source_guard(): return false
	var points: Array = game.active_level.camera_framing_points()
	if not _expect(paused and not points.is_empty() and game.active_level.last_camera_framing_error.is_empty() and game.camera_framing_error(points).is_empty(), "actual saved Camera/HUD contains the complete required native union"): return false
	var before: String = Exact.stringify(game.capture_campaign_snapshot()); var attempt: String = Exact.stringify(game.attempts.state()); var native: String = _native_wire()
	var camera: String = _camera_wire(); var input: String = Exact.stringify(_portable(game.get_input_observation_state())); var ui: String = _ui_wire()
	setups.append({"kind": "pre-PNG exact signature observation", "packet_matches": before == row.exact_snapshot, "source_packet_sha256": row.exact_snapshot.sha256_text(), "actual_packet_sha256": before.sha256_text(), "native_wire_bytes": native.length(), "camera_wire_bytes": camera.length(), "input_wire_bytes": input.length(), "ui_wire_bytes": ui.length()})
	if not _expect(before == row.exact_snapshot and attempt == row.exact_attempts and not native.is_empty() and not camera.is_empty() and not input.is_empty() and not ui.is_empty(), "complete original unit/Attempt/native/camera/input/UI before render"): return false
	hidden_menu = game.menu; menu_visible_before = hidden_menu.visible; hidden_menu.visible = false
	await RenderingServer.frame_post_draw
	var valid: bool = _expect(is_instance_valid(game) and paused, "actual paused recipient survives frame_post_draw")
	if valid: valid = _expect(Exact.stringify(game.capture_campaign_snapshot()) == before and Exact.stringify(game.attempts.state()) == attempt and _native_wire() == native and _camera_wire() == camera and Exact.stringify(_portable(game.get_input_observation_state())) == input, "only menu hiding preserves full original native unit/Attempt/clock/cues/camera/input")
	var picture: Image = root.get_texture().get_image() if valid else null
	var path: String = capture_dir.path_join("%02d-%s.png" % [view + 1, ["entrance", "live-near-field"][view]])
	var png_ok: bool = picture != null and picture.get_size() == PortraitSize and picture.save_png(path) == OK
	if png_ok:
		var decoded: Image = Image.load_from_file(path); png_ok = decoded != null and not decoded.is_empty() and decoded.get_size() == PortraitSize
	_restore_menu()
	if not valid: return false
	if not _expect(png_ok and _ui_wire() == ui and Exact.stringify(game.capture_campaign_snapshot()) == before and Exact.stringify(game.attempts.state()) == attempt and _native_wire() == native and _camera_wire() == camera and Exact.stringify(_portable(game.get_input_observation_state())) == input and _recipient_callbacks().is_empty() and _source_guard(), "actual540x1170 PNG restores full native/camera/input/UI and preserves producer/source bytes"): return false
	shots.append({"label": row.label, "path": ProjectSettings.globalize_path(path), "source_receipt_index": selected_indices[view], "source_packet_sha256": row.exact_snapshot.sha256_text(), "source_attempt_sha256": row.exact_attempts.sha256_text(), "paused": true, "only_menu_temporarily_hidden": true, "whole_before_after_exact": before, "attempt_before_after_exact": attempt, "native_before_after_exact": native, "camera_before_after_exact": camera, "input_before_after_exact": input, "ui_before_after_exact": ui, "native_identities": _ids(), "installed_recipient_callbacks": _recipient_callbacks(), "optical_review": "pending personal inspection; native containment does not grant art acceptance"})
	return true


func _native_wire() -> String:
	var rows: Dictionary = {"player": game.player.snapshot_state(), "player_body": _body(game.player), "scheduler_clock": _scheduler().get_clock(), "sources": {}, "fields": {}, "consumers": {}, "contact_cue": _cue(game.active_level.get("_exit_cue")), "native_bindings": _native_bindings_readback()}
	for id: String in Bloom.SOURCE_IDS:
		var actor: Act1MushroomSelenite = _source(id)
		rows.sources[id] = {"state": actor.pure_presentation_state(), "repulsion": actor.get_spore_response_state(), "body": _body(actor), "cue": _cue(actor.get_cue()), "art_pose": actor.get_art().call("pose_name"), "art_facing": actor.get_art().call("facing_name"), "sprite": _sprite(actor.get_art().call("sprite"))}
	var fields: Dictionary = game.active_level.get("_fields")
	var art: Dictionary = game.active_level.get("_cluster_art")
	for id: String in fields:
		var field: CinderSporeField = fields[id]
		rows.fields[id] = {"id": str(field.get_instance_id()), "transform": field.global_transform, "state": field.state(), "cue_state": field.get_cue_state(), "meshes": _meshes(field), "clusters": {}}
		for cluster_id: String in Bloom.CLUSTER_IDS:
			var cluster := field.get_node(cluster_id) as Node3D
			rows.fields[id].clusters[cluster_id] = {"id": str(cluster.get_instance_id()), "transform": cluster.global_transform, "cue_state": cluster.call("get_cue_state"), "art_state": art[id][cluster_id].call("state_name"), "sprite": _sprite(art[id][cluster_id].call("sprite"))}
	var consumers: Dictionary = game.active_level.get("_consumers")
	for id: String in consumers:
		rows.consumers[id] = {"id": str(consumers[id].get_instance_id()), "sources": {}}
		for source_id: String in Bloom.group_ids(Bloom.CONSUMER_IDS.find(id)): rows.consumers[id].sources[source_id] = consumers[id].source_state(source_id)
	var floor_collision := game.active_level.get_node("Floor/CollisionShape3D") as CollisionShape3D
	rows.floor = {"id": str(floor_collision.get_instance_id()), "transform": floor_collision.global_transform, "disabled": floor_collision.disabled, "shape": str(floor_collision.shape.get_instance_id()), "size": (floor_collision.shape as BoxShape3D).size}
	return Exact.stringify(_portable(rows))


func _sprite(sprite: Sprite3D) -> Dictionary:
	return {"id": str(sprite.get_instance_id()), "transform": sprite.global_transform, "visible": sprite.visible, "texture": str(sprite.texture.get_instance_id()), "frame": sprite.frame, "pixel_size": sprite.pixel_size, "offset": sprite.offset, "modulate": sprite.modulate, "billboard": sprite.billboard}


func _meshes(owner: Node) -> Array:
	var rows: Array = []
	for node: Node in owner.find_children("*", "MeshInstance3D", true, false):
		var material: Material = node.material_override
		var value: Dictionary = {"id": str(node.get_instance_id()), "transform": node.global_transform, "visible": node.visible, "mesh": str(node.mesh.get_instance_id()) if node.mesh != null else "none", "material": str(material.get_instance_id()) if material != null else "none", "color": material.albedo_color if material is StandardMaterial3D else [], "geometry": []}
		if node.mesh != null:
			for surface: int in range(node.mesh.get_surface_count()): value.geometry.append(var_to_bytes(node.mesh.surface_get_arrays(surface)).hex_encode().sha256_text())
		rows.append(value)
	return rows


func _packet(wire: String) -> Dictionary:
	var parsed: Dictionary = Exact.parse(wire)
	if not _expect(parsed.get("accepted", false) and parsed.get("value") is Dictionary and Exact.stringify(parsed.value) == wire, "genuine typed whole packet round-trips unchanged"): return {}
	return parsed.value


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
	if value is AABB: return {"position": _portable(value.position), "size": _portable(value.size)}
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
	return _expect(_freed(refs) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("environment_attack_targets").is_empty() and get_nodes_in_group("required_cues").is_empty(), "native recipient retires normally before next original packet")


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > WholeMs:
		_expect(false, "actual paused O2 portrait watchdog reached120 seconds"); _finish.call_deferred()


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
	_expect((refs.is_empty() or _freed(refs)) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("environment_attack_targets").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal native/source/cluster/cue/focus-observer cleanup")
	_expect(shots.size() == 2, "both selected genuine paused views produced actual PNGs")
	_expect(FileAccess.get_file_as_bytes(Registry.DATA_PATH) == registry_bytes, "canonical registry bytes unchanged")
	if not source_pins.is_empty(): _source_guard()
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null: _expect(false, "unique portrait report writable")
	else:
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "first_failure": first_failure, "shots": shots, "focus_events": focus_rows, "source_options": options, "source_report_sha256": options["source-report-sha256"], "closed_recorder_sha256": options["source-recorder-sha256"], "source_manifest_sha256": source_bank_sha, "setups": setups, "observations": observations, "elapsed_ms": Time.get_ticks_msec() - started_ms, "scope": "Two genuine passing campaign whole Attempts transported unchanged through public production Shell/Attempts/format2 Store. CLI source report/closed recorder/runtime pins and unique receipt labels, actual Title Resume Side signals, two paused UI settle frames, passive focus. No fight replay, Hero/camera reposition, native world stepping, synthetic HP/phase/clock/cue/snapshot or focus forcing. Zero callbacks attributed only to exact installed recipients; candidate/retired-donor observations retained separately. Only menu overlay hidden temporarily for actual540x1170 frame_post_draw PNGs; full exact unit/Attempt/body/HP/clock/cue/camera/input/UI and producer/runtime byte preservation. Personal optical inspection pending; no full-route/all-kit/performance/mobile credit."}, "\t")); file.close()
	var directory := DirAccess.open(test_root)
	if directory != null:
		for name: String in directory.get_files(): DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_root))
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-O2 SAVED PORTRAIT: %d checks, %d failures; %d shots; report=%s" % [checks, failures, shots.size(), report_path])
	quit(1 if failures > 0 else 0)
