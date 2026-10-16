extends "res://tests/acts/act1/a1_l5_encounter_transition.gd"
## Separate private producer/transport integration; unparsed/unexecuted. Original drafts untouched.
## Same real parent, eight ordinary primaries and native CP2/CP3. TEST prefix,
## public Rusher injury and supported Hero placement are explicitly disclosed.
## No source HP/phase/clock/lease/profile/forecast/history assignment.

const LEGACY_HOST_SHA: String = "9056b2111d3e709fca592a38ac58ad1a181a0b1825128493fde7a180c71b9144"
const LEGACY_CODEC_SHA: String = "2fafe8b39f64f791804b3546898c6d54f7063985dc0a65222c6ab69313fcc1df"
const LEGACY_HOST_PATH: String = "res://scripts/acts/act1/living_moon.gd"
const LEGACY_CODEC_PATH: String = "res://scripts/acts/act1/living_moon_codec.gd"
const FRESH_HOST_SHA: String = "89dc49fe6e37c05679d1f4592c9873f01f1c4ea92720d2ec0209624985be7e7f"
const FRESH_CODEC_SHA: String = "25bca033d4ce0e1f04abdeb08fb1645887e72246bb978ee7d1d5ae46a4ba73b9"
const RECIPE_PATH: String = "res://data/campaign/act1/a1_l5_difficulty_arrangements.json"
const RECIPE_SHA: String = "06b65a15b5f56791291d2614346b0973be0d09f91c2466dad8f0ecf20f4463c9"

class BeforeParentProbe extends Node:
	signal before_parent
	func _init() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 199
	func _physics_process(_delta: float) -> void:
		before_parent.emit()

var difficulty_case: String = ""
var transport_request: Dictionary = {}
var producer_profile: String = "challenge"
var selector_test_roots: Array[String] = []
var selector_parent_root: String = ""
var difficulty_complete: bool = false
var assertion_rows: Array[Dictionary] = []
var branches: Dictionary = {}
var branch_order: Array[String] = []
var source_pre: Dictionary = {}
var source_post: Dictionary = {}
var artifact_root: String = ""
var before_parent_probe: BeforeParentProbe
var selection_rows: Array[Dictionary] = []
var selection_observation_count: int = 0
var latest_preselection: Dictionary = {}
var first_final_admission: Dictionary = {}
var checkpoint_pause_requests: Array[Dictionary] = []


func _initialize() -> void:
	super._initialize()
	test_root = "user://test-act1-l5-difficulty-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	artifact_root = "res://.cinder/a1-l5-difficulty-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]


func _run() -> void:
	root.size = Vector2i(540, 1170)
	registry_bytes = FileAccess.get_file_as_bytes(Registry.DATA_PATH)
	if not _parse_difficulty_arguments(): await _finish(); return
	source_pre = _source_pins()
	if difficulty_case == "legacy-producer":
		# Preserve the original old-writer gate; this case cannot run on new code.
		if not _expect(source_pre[LEGACY_HOST_PATH] == LEGACY_HOST_SHA and source_pre[LEGACY_CODEC_PATH] == LEGACY_CODEC_SHA, "genuine old host9056/codec2fafe must remain installed before legacy production"):
			await _finish(); return
	else:
		if not _expect(source_pre[LEGACY_HOST_PATH] == FRESH_HOST_SHA and source_pre[LEGACY_CODEC_PATH] == FRESH_CODEC_SHA and source_pre[RECIPE_PATH] == RECIPE_SHA, "fresh cases require the exact separately promoted host89dc/codec25bc/recipe06b65"):
			await _finish(); return
	var parsed: Variant = JSON.parse_string(registry_bytes.get_string_from_utf8())
	if not _expect(parsed is Dictionary and parsed.get("levels") is Array, "actual registry supplies isolated TEST L5 metadata"):
		await _finish(); return
	raw = parsed.duplicate(true)
	for entry: Dictionary in raw.levels:
		if entry.id == Layout.LEVEL_ID:
			setups.append({"kind": "TEST in-memory L5 override", "canonical_readiness_before": entry.readiness, "canonical_scene_before": entry.scene_path, "canonical_commit_before": entry.accepted_commit})
			entry.scene_path = ScenePath; entry.readiness = "accepted"; entry.accepted_commit = "f".repeat(40); entry.api_revision = Registry.API_REVISION
	var registry := Registry.new(raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error(Layout.LEVEL_ID).is_empty(), "only owned L5 receives isolated TEST registration; no canonical metadata changes"):
		await _finish(); return
	if difficulty_case in ["held-legacy", "held-new"]:
		difficulty_complete = await _run_held_response_case(transport_request.source_report, transport_request.source_sha256, "legacy" if difficulty_case == "held-legacy" else "new", transport_request.get("baseline_report", ""), transport_request.get("baseline_sha256", ""))
		await _finish(); return
	if difficulty_case in ["transport", "metadata"]:
		if difficulty_case == "transport":
			difficulty_complete = await _run_transport_case(transport_request.source_report, transport_request.source_sha256, transport_request.branch, transport_request.future_profile)
		else:
			difficulty_complete = await _run_metadata_case(transport_request.source_report, transport_request.source_sha256, transport_request.branch, transport_request.future_profile)
		await _finish(); return
	probe = NativeTickProbe.new(); probe.process_physics_priority = 3000; root.add_child(probe)
	if difficulty_case == "selectors":
		await _run_selectors(registry)
		await _finish(); return
	before_parent_probe = BeforeParentProbe.new(); root.add_child(before_parent_probe)
	before_parent_probe.before_parent.connect(_observe_before_parent)
	probe.tick_finished.connect(_observe_after_parent)
	if not await _seed_actual_pristine_story(registry): await _finish(); return
	game = _new_shell()
	if game == null or not await _settle() or not await _click(game, "ContinueStoryButton") or not _bindings(game): await _finish(); return
	moon = game.active_level
	var eye: CharacterBody3D = moon.get("eye") as CharacterBody3D
	eye_ref = weakref(eye)
	var collision: CollisionShape3D = eye.call("get_collision")
	eye_collision_ref = weakref(collision); eye_shape_ref = weakref(collision.shape)
	eye.connect("phase_changed", _phase_observer)
	eye.connect("defeated", _defeat_observer)
	moon.checkpoint_requested.connect(_checkpoint_archive_pause)
	var initial: Dictionary = game.capture_campaign_snapshot()
	if not _producer_unit(initial) or not _expect(initial.level.local.stage == "return" and initial.level.local.eye.hp == 240.0 and initial.level.local.scheduler.clock_s == 0.0 and initial.level.local.blink.cycle == 0 and initial.level.progress.checkpoint_ids.is_empty() and game.attempts.state().completed_main == Prefix, "actual Challenge-born pristine Story contains no fabricated Moon progress"):
		await _finish(); return
	if not _expect(game.player.equipment.snapshot() == Equipment.STARTER and float(game.player.equipment.resolved_stats().primary_damage) == 20.0, "unchanged neutral kit has actual ordinary20 damage") or not _archive_branch("entry", "", 240.0, 0): await _finish(); return
	if not await _enter_actual_boss(): await _finish(); return
	hp_boundaries.append(240.0)
	if not await _drive_to_hp(160.0, "blink") or not await _phase_checkpoint("moon-phase-2", "sneeze", 160.0): await _finish(); return
	if not _expect(branch_order == ["entry", "cp2"] and primary_receipts.size() == 4, "complete CP2 branch is archived after fourth primary before any CP3 work"):
		await _finish(); return
	if not await _click(game, "ResumeButton"): await _finish(); return
	if not await _drive_to_hp(80.0, "sneeze") or not await _phase_checkpoint("moon-phase-3", "final", 80.0): await _finish(); return
	if not _expect(branch_order == ["entry", "cp2", "cp3"] and primary_receipts.size() == 8 and moon.get("sneeze_demonstrated") == true and first_final_admission.is_empty(), "complete CP3 follows eight real hits and genuine Sneeze demonstration before first final admission"):
		await _finish(); return
	if not await _click(game, "ResumeButton"): await _finish(); return
	if not await _wait(func() -> bool: return not first_final_admission.is_empty(), "first actual " + difficulty_case + " final admission", 12.0, true) or not await _pause(): await _finish(); return
	var final_unit: Dictionary = game.capture_campaign_snapshot()
	if not _producer_unit(final_unit): await _finish(); return
	var leases: Array = final_unit.level.local.scheduler.reservations
	var fresh_writer: bool = difficulty_case == "fresh-producer"
	var first_id: String = Layout.NOSE_ID if fresh_writer else Layout.EYE_ID
	var first_packet: Dictionary = final_unit.level.local.nose if fresh_writer else final_unit.level.local.blink
	var follower_packet: Dictionary = final_unit.level.local.blink if fresh_writer else final_unit.level.local.nose
	var follower_attack: String = "blink" if fresh_writer else "sneeze"
	if not _expect(first_final_admission.source_ids == [first_id] and leases.size() == 1 and leases[0].source_id == first_id and first_packet.status == "running" and first_packet.phase in ["warning", "lock"] and follower_packet.status != "running" and final_unit.level.local.next_attack == follower_attack, "actual " + difficulty_case + " first final source follows retained policy before its follower"):
		await _finish(); return
	if not _expect(not first_final_admission.preselection.is_empty() and first_final_admission.preselection.clock_s == first_final_admission.clock_s and first_final_admission.preselection.pure, "same native tick records pure preselection without fixture forecast injection; existing parent forecast is reported literally"):
		await _finish(); return
	if not _archive_branch("first-final-sneeze" if fresh_writer else "first-final-blink", "moon-phase-3", 80.0, 8): await _finish(); return
	if not _expect(hp_boundaries == [240.0, 160.0, 80.0] and phase_observers.size() == 2 and phase_observers[0].phase == 2 and phase_observers[1].phase == 3 and primary_receipts.size() == 8 and terminal_observers.is_empty(), "producer stops after original eight primaries/two checkpoints/first final Save; no defeat or exit claim"):
		await _finish(); return
	difficulty_complete = true
	await _finish()


func _parse_difficulty_arguments() -> bool:
	var values: Dictionary = {}
	var allowed: Array[String] = ["--case", "--source-report", "--source-sha256", "--branch", "--future-profile", "--baseline-report", "--baseline-sha256"]
	for argument: String in OS.get_cmdline_user_args():
		var separator: int = argument.find("=")
		var key: String = argument.left(separator) if separator >= 0 else argument
		if not _expect(separator >= 0 and key in allowed and not values.has(key) and not argument.substr(separator + 1).is_empty(), "one explicit known nonempty difficulty selector: " + argument): return false
		values[key] = argument.substr(separator + 1)
	difficulty_case = String(values.get("--case", ""))
	if not _expect(difficulty_case in ["legacy-producer", "fresh-producer", "selectors", "transport", "metadata", "held-legacy", "held-new"], "explicit scoped difficulty case required"): return false
	if difficulty_case in ["legacy-producer", "fresh-producer", "selectors"]:
		return _expect(values.size() == 1, "producer/entry selectors accept no donor or inherited alternate arguments")
	var required: Array[String] = ["--case", "--source-report", "--source-sha256", "--branch", "--future-profile"]
	if difficulty_case == "held-new": required.append_array(["--baseline-report", "--baseline-sha256"])
	if not _expect(values.size() == required.size(), "selected case requires exactly its report/SHA/branch/profile and any genuine baseline selectors"): return false
	for key: String in required:
		if not _expect(values.has(key), "required case selector: " + key): return false
	transport_request = {"source_report": values["--source-report"], "source_sha256": values["--source-sha256"], "branch": values["--branch"], "future_profile": values["--future-profile"]}
	if difficulty_case in ["held-legacy", "held-new"]:
		if not _expect(transport_request.branch == "cp3" and transport_request.future_profile == "standard", "held-response always clones actual CP3 with public future Standard while retaining saved native Challenge"): return false
	if difficulty_case == "held-new":
		transport_request["baseline_report"] = values["--baseline-report"]
		transport_request["baseline_sha256"] = values["--baseline-sha256"]
		if not _expect(String(transport_request.baseline_sha256).length() == 64, "complete actual old held-response baseline SHA is required"): return false
	return _expect(String(transport_request.source_sha256).length() == 64 and transport_request.branch in ["cp2", "cp3", "first-final-blink", "first-final-sneeze"] and transport_request.future_profile in ["standard", "assisted", "challenge"], "input selector shape is exact; original report and branch bytes verified before use")


func _seed_actual_pristine_story(registry: CinderCampaignRegistry) -> bool:
	# Same inherited genuine fresh-candidate setup; set the PUBLIC preference
	# before the real entry begin_encounter, never relabel a Standard packet.
	game = _new_shell()
	if game == null or not await _settle(): return false
	game.menu.difficulty_preference_requested.emit(producer_profile)
	if not _expect(game.get_difficulty_preference() == producer_profile and game.active_level == null and game.player == null, "public Title preference selects " + producer_profile + " before any fresh L5 entry"):
		return false
	setups.append({"kind": "public Title difficulty preference before fresh entry", "profile_id": producer_profile, "interactive_gesture_claim": false})
	candidate = game._prepare(Layout.LEVEL_ID, Equipment.STARTER)
	if not _expect(not candidate.is_empty(), "actual shared Shell constructs the fresh " + producer_profile + " production entrance"): return false
	var pristine: Dictionary = game._capture_fresh_candidate(candidate, game._fresh_shell_state())
	if not _producer_unit(pristine): return false
	var model := Attempts.new(registry)
	var payload: Dictionary = model.state()
	payload.completed_main = Prefix.duplicate()
	payload.story = {"kind": "story", "level_id": Layout.LEVEL_ID, "snapshot": pristine.duplicate(true), "checkpoint": pristine.duplicate(true)}
	var store := Store.new(test_root + "campaign.json")
	store.payload_validator = model.saved_payload_error
	if not _expect(model.state_error(payload).is_empty() and store.write_payload(payload), "public validated Store preserves genuine " + producer_profile + " birth plus disclosed TEST predecessor prefix: " + model.last_error + store.last_error): return false
	setups.append({"kind": "TEST sequential predecessor prefix, not earned playthrough", "completed_main": Prefix.duplicate(), "candidate_scene": ScenePath, "canonical_registry_changed": false})
	operation = "explicit " + producer_profile + " seed candidate disposal"
	game._dispose(candidate); candidate = {}
	var refs: Array[WeakRef] = _refs(game)
	game.free(); game = null
	return _expect(_freed(refs), "fresh " + producer_profile + " seed candidate and Shell dispose normally before actual Title Continue")


func _checkpoint_archive_pause(id: String, checkpoint: String, kind: String) -> void:
	if id != Layout.LEVEL_ID or checkpoint not in ["moon-phase-2", "moon-phase-3"] or kind != "boss_phase": return
	checkpoint_pause_requests.append({"checkpoint_id": checkpoint, "clock_s": _scheduler().get_clock(), "primary_count": primary_receipts.size(), "method": "public request_pause queued after native checkpoint; no world state write"})
	# The Shell connected its native checkpoint listener before this observer.
	# Public Pause follows its checkpoint operation and prevents auto-resume.
	game.request_pause()


func _phase_checkpoint(id: String, expected_stage: String, hp: float) -> bool:
	if not await _wait(func() -> bool: return moon.current_checkpoint().id == id and moon.get("stage") == expected_stage, "actual deferred native boundary " + id, 8.0, true) or not await _pause(): return false
	var saved: Dictionary = game.attempts.state().story.checkpoint
	if not _producer_unit(saved) or not _expect(saved.level.local.eye.hp == hp and saved.level.local.stage == expected_stage and saved.level.progress.checkpoint_id == id and saved.level.progress.checkpoint_kind == "boss_phase" and saved.level.local.pending_phase == 0 and saved.level.local.scheduler.reservations.is_empty() and _durable(game), "native settled phase checkpoint remains complete and durable before further gameplay"):
		return false
	hp_boundaries.append(hp)
	receipts.append({"stage": "actual " + id, "exact_snapshot": Exact.stringify(saved)})
	return _archive_branch("cp2" if id == "moon-phase-2" else "cp3", id, hp, 4 if id == "moon-phase-2" else 8)


func _place_at_actual_low_rim() -> bool:
	# Authorized focused setup: use existing eye approach, not a phase/HP seed.
	var goal: Vector3 = Layout.EYE_APPROACH_POSITION
	goal.y = game.player.global_position.y
	if game.player.global_position.distance_to(goal) <= 0.01: return true
	var supported: Dictionary = Sweep.step(game.player, Transform3D(Basis.IDENTITY, goal), Vector3.ZERO, [moon.call("floor_region")])
	if not _expect(not supported.has("error") and not supported.get("collided", true), "authored eye-approach TEST placement has actual floor/full-capsule support"): return false
	var before: Vector3 = game.player.global_position
	game.player.global_position = goal
	setups.append({"kind": "TEST recovery-only Hero placement at existing EYE_APPROACH; not earned return", "from": Codec.vector3(before), "to": Codec.vector3(goal), "clock_s": _scheduler().get_clock()})
	return true


func _pause() -> bool:
	game.request_pause()
	if not await _settle(): return false
	if not await _wait(func() -> bool: return _shell_idle() and paused and game.menu.is_open() and game.menu.page_name() == "pause", "public Pause and actual asynchronous Store registration settle", 16.0, true): return false
	return _expect(game.campaign_error.is_empty() and _durable(game), "public Pause closes its real durable barrier: " + game.campaign_error)


func _shell_idle() -> bool:
	return is_instance_valid(game) and not game.get("_draining") and not game.get("_drain_queued") and not game.get("_registration_inflight") and not game.get("_pause_request_pending") and game.get("_operations").is_empty() and game.get("_failed_operations").is_empty()


func _producer_unit(saved: Dictionary) -> bool:
	if difficulty_case == "legacy-producer": return _legacy_unit(saved)
	if not _closed(saved): return false
	var attack: String = "sneeze" if producer_profile == "challenge" else "blink"
	var descriptor: Dictionary = {"profile_id": producer_profile, "recipe_id": "A1-L5/final-" + attack + "-leads@v1", "initial_attack": attack}
	return _expect(saved.level.local.size() == 17 and saved.level.local.api_revision == "act1-living-moon-level-2" and saved.level.local.schema_version == 2 and saved.level.local.world_revision == 1 and saved.level.local.has("final_arrangement") and _same(saved.level.local.final_arrangement, descriptor) and saved.level.local.scheduler.profile.id == producer_profile and saved.shell.difficulty_at_entry == producer_profile, "actual new17 closed descriptor and native/Shell entry profile remain exact: " + producer_profile)


func _run_selectors(registry: CinderCampaignRegistry) -> void:
	# Only real pristine entries. No CP3/HP/history packet is fabricated and no
	# attack or final-phase behavior is credited by an entry selector assertion.
	selector_parent_root = test_root
	for profile: String in ["standard", "assisted"]:
		producer_profile = profile
		test_root = selector_parent_root + profile + "/"
		selector_test_roots.append(test_root)
		if not await _seed_actual_pristine_story(registry): return
		game = _new_shell()
		if game == null or not await _settle() or not await _click(game, "ContinueStoryButton") or not _bindings(game): return
		moon = game.active_level
		var saved: Dictionary = game.capture_campaign_snapshot()
		if not _producer_unit(saved): return
		if not _expect(saved.level.local.stage == "return" and saved.level.local.eye.hp == 240.0 and saved.level.local.scheduler.clock_s == 0.0 and saved.level.local.scheduler.reservations.is_empty() and saved.level.local.blink.cycle == 0 and saved.level.local.nose.cycle == 0 and saved.level.progress.checkpoint_ids.is_empty() and saved.level.local.final_arrangement.initial_attack == "blink", "real fresh " + profile + " entry retains Blink selector without executing boss phases"): return
		if not _archive_branch(profile + "-entry", "", 240.0, 0): return
		var refs: Array[WeakRef] = _refs(game)
		game.free(); game = null; moon = null
		if not _expect(_freed(refs) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal " + profile + " pristine recipient retirement before next selector"): return
	test_root = selector_parent_root
	if not _expect(branch_order == ["standard-entry", "assisted-entry"] and primary_receipts.is_empty() and phase_observers.is_empty() and first_final_admission.is_empty(), "selectors cover only two actual entry descriptors; no final-phase/ordinary-response credit"): return
	difficulty_complete = true


func _case_scope() -> String:
	if difficulty_case in ["held-legacy", "held-new"]:
		return "One exact original independently loaded CP3 whole Store/Attempts, actual Challenge native profile with public future Standard, supported literal authored approach, no new TEST relocation. Public full left dash/held landing/full return/ordinary primary with original native leases/proofs/geometry/cue phases/clocks/full action paths, unchanged HP/ammo, no source-hit callbacks or invulnerability reliance and final whole Save retaining original CP3. New case additionally requires actual old useful-response report and live pure strict-temporal/actual-radius/support held-H counterfactual against genuinely sampled Blink. Same old CP3-relative return schedule is tried only when complete hold and return are safe before new Blink active; equivalent two-dash success receives no automatic difficulty credit and returns to Integration. No equal absolute-clock/both-eligibility/nominal proof-timeline, full route, boss defeat, portrait, OS-gesture, all-kit, balance or performance claim. Failed/inconclusive native observations are retained without guard/timing changes."
	if difficulty_case == "transport":
		return "One SHA-pinned complete successful producer report and one entire contemporaneous CP2, CP3 or first-final branch. Literal original Store/settings/preferences/backup bytes are cloned into a unique isolated destination; actual fresh Title Continue, public opposite future preference and paused Save preserve exact native current/checkpoint/full Attempts. Only an independently selected CP2 branch receives public Retry with fresh identities and quiet native restoration. Original report and available original artifacts remain unchanged; unavailable original paths are disclosed. No gameplay Resume, later phase-three order after Retry, further primaries, held-landing/return distinction, portrait, gesture, full route, boss defeat, balance or performance claim. Original producer checks retain their source attribution and are not credited as new checks."
	if difficulty_case == "metadata":
		return "One SHA-pinned complete successful producer report and entire genuine branch, cloned byte-exactly for actual fresh Continue and paused Save. Valid actual candidate stages schema0 before successful paired Player/whole-level quiet commit and current presentation gate installs the saved format/descriptor. Complete synthetic negative copies test exact closed metadata/type/profile refusals through pure live validation and fresh public Level lifecycle, with no native binding or policy installation and normal retirement. Synthetic negatives are refusal inputs, never historical producers. No gameplay Resume, later final-order/Retry progression, held-landing/return distinction, portrait, gesture, full route, boss defeat, balance or performance claim."
	if difficulty_case == "selectors":
		return "Two genuine new17 Standard/Assisted production L5 entries from their public pre-entry preferences, exact native/Shell profile and closed Blink-first descriptor, pristine local/source/clock state, full literal Store/Attempts/current/checkpoint archive and normal cleanup. Disclosed TEST predecessor prefix only; no phase progression, CP3 fabrication, attack, final admission, route/ordinary-response/portrait/balance/performance claim."
	var format_label: String = "old16" if difficulty_case == "legacy-producer" else "new17"
	var leader: String = "Blink" if difficulty_case == "legacy-producer" else "Sneeze"
	return "Actual " + format_label + " Challenge born at real entry, disclosed TEST prefix/public Rusher injury/supported Hero approach placements, eight actual ordinary20-damage primaries and native Sneeze demonstration/CP2/CP3. Separate literal whole current/checkpoint/Attempts/raw original Store branches archived at CP2 BEFORE CP3, then first actual final " + leader + " Save. Pure native preselection diagnostics are observations, not both-eligibility or difficulty-novelty claims. No source HP/phase/clock/lease/profile seed, CP2 transplantation, manufactured history, earned route, final response comparison, boss defeat/hatch/transition, gesture/portrait/all-kit/balance/performance claim. Exact selected runtime source pins remain retained."


func _legacy_unit(saved: Dictionary) -> bool:
	if not _closed(saved): return false
	return _expect(saved.level.local.size() == 16 and saved.level.local.api_revision == "act1-living-moon-level-1" and saved.level.local.schema_version == 1 and not saved.level.local.has("final_arrangement") and saved.level.local.scheduler.profile.id == "challenge" and saved.shell.difficulty_at_entry == "challenge", "literal old16 omission and actual Challenge entry/native profile remain exact")


func _archive_branch(label: String, checkpoint_id: String, hp: float, hit_count: int) -> bool:
	if not _expect(paused and _shell_idle() and not branches.has(label), "archive only one settled paused branch: " + label): return false
	var current: Dictionary = game.capture_campaign_snapshot()
	var attempts: Dictionary = game.attempts.state()
	var checkpoint: Dictionary = attempts.story.checkpoint
	if not _producer_unit(current) or not _producer_unit(checkpoint): return false
	if not _expect(current.level.local.eye.hp == hp and checkpoint.level.local.eye.hp == hp and checkpoint.level.progress.checkpoint_id == checkpoint_id and primary_receipts.size() == hit_count and _same(attempts.story.snapshot, current) and _durable(game), "whole live current/checkpoint/Attempts/raw Store agree before branch archive: " + label): return false
	if difficulty_case != "legacy-producer":
		if not _expect(_same(game.active_level.call("final_arrangement_state"), {"schema_version": 2, "final_arrangement": current.level.local.final_arrangement}), "actual installed writer policy matches complete fresh snapshot: " + label): return false
	var current_wire: String = Exact.stringify(current)
	var checkpoint_wire: String = Exact.stringify(checkpoint)
	var attempts_wire: String = Exact.stringify(attempts)
	var parsed_attempts: Dictionary = Exact.parse(attempts_wire)
	if not _expect(not current_wire.is_empty() and not checkpoint_wire.is_empty() and parsed_attempts.get("accepted") == true and _same(parsed_attempts.value, attempts), "complete typed whole Attempts/current/checkpoint wires round-trip: " + label): return false
	var raw_store: PackedByteArray = FileAccess.get_file_as_bytes(test_root + "campaign.json")
	var envelope: Variant = JSON.parse_string(raw_store.get_string_from_utf8())
	if not _expect(not raw_store.is_empty() and envelope is Dictionary and envelope.get("format_version") == Store.FORMAT_VERSION and envelope.get("payload_json") == attempts_wire and envelope.get("sha256") == attempts_wire.sha256_text(), "literal original format2 raw Store contains this exact whole Attempts: " + label): return false
	var branch_dir: String = artifact_root.path_join(label)
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(branch_dir)) == OK, "separate immutable evidence destination exists: " + label): return false
	var disk_files: Dictionary = {}
	var directory := DirAccess.open(test_root)
	if not _expect(directory != null, "actual isolated Store directory can be read: " + label): return false
	for name: String in directory.get_files():
		var original_path: String = test_root.path_join(name)
		var original_bytes: PackedByteArray = FileAccess.get_file_as_bytes(original_path)
		var copy_path: String = branch_dir.path_join(name)
		var copy := FileAccess.open(copy_path, FileAccess.WRITE)
		if not _expect(copy != null, "literal branch file can be archived: " + label + "/" + name): return false
		copy.store_buffer(original_bytes); copy.flush()
		var write_error: Error = copy.get_error(); copy.close()
		if not _expect(write_error == OK and FileAccess.get_file_as_bytes(copy_path) == original_bytes and FileAccess.get_sha256(copy_path) == FileAccess.get_sha256(original_path), "archived original bytes/hash remain exact: " + label + "/" + name): return false
		disk_files[name] = {"path": copy_path, "bytes": original_bytes.size(), "sha256": FileAccess.get_sha256(original_path), "hex": original_bytes.hex_encode()}
	var row: Dictionary = {"label": label, "current_exact": current_wire, "current_sha256": current_wire.sha256_text(), "checkpoint_exact": checkpoint_wire, "checkpoint_sha256": checkpoint_wire.sha256_text(), "attempts_exact": attempts_wire, "attempts_sha256": attempts_wire.sha256_text(), "raw_store": disk_files["campaign.json"], "all_original_disk_files": disk_files, "generation": envelope.generation, "primary_count": hit_count, "profile_id": current.level.local.scheduler.profile.id, "local_schema": current.level.local.schema_version, "checkpoint_id": checkpoint_id, "clock_s": current.level.local.scheduler.clock_s, "scope": "Complete literal contemporaneous branch. Future CP2 Retry loads this CP2 branch separately; no transplantation into CP3."}
	if not _expect(FileAccess.get_file_as_bytes(test_root + "campaign.json") == raw_store and Exact.stringify(game.capture_campaign_snapshot()) == current_wire and Exact.stringify(game.attempts.state()) == attempts_wire, "read-only archive leaves actual current/Attempts/original disk unchanged: " + label): return false
	row["source_pre"] = source_pre.duplicate(true)
	var branch_json: String = JSON.stringify(row, "\t")
	var branch_path: String = branch_dir.path_join("branch.json")
	var branch_file := FileAccess.open(branch_path, FileAccess.WRITE)
	if not _expect(branch_file != null, "complete branch receipt can be committed before proceeding: " + label): return false
	branch_file.store_string(branch_json); branch_file.flush()
	var branch_error: Error = branch_file.get_error(); branch_file.close()
	if not _expect(branch_error == OK and FileAccess.get_file_as_string(branch_path) == branch_json, "literal full branch receipt is closed on disk before further gameplay: " + label): return false
	branches[label] = row; branch_order.append(label)
	return true


func _selection_boundary() -> Dictionary:
	var response: Dictionary = game.player.get_threat_response_state().duplicate(true)
	response.erase("actor")
	return {"clock_s": _scheduler().get_clock(), "hero_position": game.player.global_position, "hero_response": response, "eye_hp": moon.get("eye").get("hp"), "blink": moon.get("blink").state(), "nose": moon.get("nose").state(), "eye_control": _scheduler().source_control_state(moon.get("eye")), "nose_control": _scheduler().source_control_state(moon.get("nose")), "stage": moon.get("stage"), "next_attack": moon.get("next_attack"), "forecast": moon.get("_forecast"), "pending_start": moon.get("_pending_start"), "frames": moon.get("_frames"), "parent_error": moon.get("last_encounter_error"), "blink_error": moon.get("blink").get("last_error"), "nose_error": moon.get("nose").get("last_error")}


func _preview_record(value: Dictionary) -> Dictionary:
	return {"accepted": value.get("accepted", false), "reason": value.get("reason", ""), "candidate": _encode(value.get("candidate", {})), "proof": _encode(value.get("proof", {}))}


func _observe_before_parent() -> void:
	if finishing or aborted or paused or not _live() or not is_instance_valid(moon) or moon.get("stage") != "final" or not first_final_admission.is_empty() or not _boss_records().is_empty(): return
	var before: String = Exact.stringify(_encode(_selection_boundary()))
	var blink_preview: Dictionary = moon.get("blink").preview_start(moon.call("response_context", true))
	var nose_preview: Dictionary = moon.get("nose").preview_start(moon.call("response_context"))
	var after: String = Exact.stringify(_encode(_selection_boundary()))
	var pure: bool = not before.is_empty() and before == after
	latest_preselection = {"clock_s": _scheduler().get_clock(), "hero_position": Codec.vector3(game.player.global_position), "profile": _scheduler().encounter_profile(), "blink": _preview_record(blink_preview), "nose": _preview_record(nose_preview), "both_eligible": blink_preview.get("accepted", false) and nose_preview.get("accepted", false), "pure": pure, "forecast_empty": moon.get("_forecast").is_empty() and moon.get("_pending_start").is_empty(), "before_exact": before, "after_exact": after}
	selection_observation_count += 1
	selection_rows.append(latest_preselection.duplicate(true))
	if selection_rows.size() > 32: selection_rows.pop_front()
	if not pure:
		_expect(false, "native preview diagnostics must leave complete source/response/parent boundary unchanged")
		aborted = true; _finish.call_deferred()


func _observe_after_parent() -> void:
	if finishing or aborted or paused or not _live() or not is_instance_valid(moon) or moon.get("stage") != "final" or not first_final_admission.is_empty(): return
	var records: Array[Dictionary] = _boss_records()
	if records.is_empty(): return
	var ids: Array[String] = []
	for record: Dictionary in records: ids.append(String(record.source_id))
	first_final_admission = {"clock_s": _scheduler().get_clock(), "source_ids": ids, "records": _encode(records), "preselection": latest_preselection.duplicate(true), "boundary": _encode(_selection_boundary()), "pause_method": "public request_pause after actual parent admission, outside source callbacks"}
	game.request_pause()


func _source_pins() -> Dictionary:
	var result: Dictionary = {}
	for path: String in [LEGACY_HOST_PATH, LEGACY_CODEC_PATH, "res://scripts/acts/act1/living_moon_layout.gd", "res://scripts/acts/act1/living_moon_body.gd", "res://scripts/acts/act1/living_moon_nose.gd", "res://tests/acts/act1/a1_l5_encounter_transition.gd", "res://tests/acts/act1/a1_l5_shell_transport.gd", ScenePath]:
		result[path] = FileAccess.get_sha256(path)
	result[RECIPE_PATH] = FileAccess.get_sha256(RECIPE_PATH) if FileAccess.file_exists(RECIPE_PATH) else "<absent>"
	return result


func _expect(ok: bool, label: String) -> bool:
	assertion_rows.append({"index": checks + 1, "passed": ok, "label": label, "wall_ms": Time.get_ticks_msec() - started_ms})
	return super._expect(ok, label)


func _finish() -> void:
	if finishing: return
	if difficulty_case in ["held-legacy", "held-new"]: _held_finalize_observations()
	finishing = true; paused = true; _end_watch("normal " + difficulty_case + " cleanup")
	# Unwind any native probe emitter before normal node disposal.
	await process_frame
	if is_instance_valid(game) and not candidate.is_empty(): game._dispose(candidate); candidate = {}
	var refs: Array[WeakRef] = []
	for shell: CinderCampaignShell in [fresh, game]:
		if is_instance_valid(shell): refs.append_array(_refs(shell)); shell.free()
	fresh = null; game = null
	for node: Node in [before_parent_probe, probe]:
		if is_instance_valid(node): refs.append_array(_refs(node)); node.free()
	paused = false
	await create_timer(0.5, true).timeout; await process_frame
	_expect((refs.is_empty() or _freed(refs)) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal difficulty Shell/native-source/cue/probe cleanup releases every created descendant and group")
	_expect(FileAccess.get_file_as_bytes(Registry.DATA_PATH) == registry_bytes, "TEST prefix and registration never modify canonical registry bytes")
	source_post = _source_pins()
	_expect(not source_pre.is_empty() and source_post == source_pre, "selected writer and all named inherited inputs remain byte-identical through the case")
	var removed: bool = true
	var cleanup_roots: Array[String] = selector_test_roots.duplicate()
	if not cleanup_roots.has(test_root): cleanup_roots.append(test_root)
	if not selector_parent_root.is_empty() and not cleanup_roots.has(selector_parent_root): cleanup_roots.append(selector_parent_root)
	for owned_root: String in cleanup_roots:
		var directory := DirAccess.open(owned_root)
		if directory == null: continue
		for name: String in directory.get_files():
			if DirAccess.remove_absolute(ProjectSettings.globalize_path(owned_root.path_join(name))) != OK: removed = false
		if DirAccess.remove_absolute(ProjectSettings.globalize_path(owned_root)) != OK: removed = false
	_expect(removed, "disposable live Stores retire after literal complete branches are independently archived")
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	var report: String = "res://.cinder/a1-l5-difficulty-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	var file := FileAccess.open(report, FileAccess.WRITE)
	if file == null:
		_expect(false, "difficulty native report is writable")
	else:
		var complete: bool = difficulty_complete and failures == 0 and not aborted
		var body: Dictionary = {"case": difficulty_case, "checks": checks, "failures": failures, "success": complete, "complete": complete, "assertions": assertion_rows, "first_failure": first_failure, "branches": branches, "branch_order": branch_order, "artifact_root": artifact_root, "source_pre": source_pre, "source_post": source_post, "setups": setups, "receipts": receipts, "primary_receipts": primary_receipts, "phase_observers": phase_observers, "hp_boundaries": hp_boundaries, "checkpoint_pause_requests": checkpoint_pause_requests, "first_final_admission": first_final_admission, "selection_observation_count": selection_observation_count, "selection_rows_retained_last32": selection_rows, "circle_cycles": circle_cycles, "dash_requests": dash_requests, "drive_diagnostics": drive_diagnostics, "observations": observations, "wall_ms": Time.get_ticks_msec() - started_ms, "scope": _case_scope(), "transport_request": transport_request.duplicate(true)}
		file.store_string(JSON.stringify(body, "\t")); file.flush()
		var report_error: Error = file.get_error(); file.close()
		if report_error != OK: _expect(false, "difficulty report write closes successfully")
	var completed: bool = difficulty_complete and failures == 0 and not aborted
	print("A1-L5 DIFFICULTY: %d checks, %d failures; complete=%s; report=%s" % [checks, failures, "true" if completed else "false", report])
	quit(1 if failures > 0 or not completed else 0)


# PRIVATE SOURCE FRAGMENT; append to the owned difficulty fixture after review.
# No extends/parser/_run/_finish override. Caller supplies canonical TEST raw,
# source_pre, registry_bytes and existing observer setup; each invocation loads
# ONE exact contemporaneous producer branch. This fragment never resumes play.
var transport_input_path: String = ""
var transport_input_sha256: String = ""
var transport_input_branch: Dictionary = {}
var transport_input_unit: Dictionary = {}
var transport_input_checkpoint: Dictionary = {}
var transport_input_attempts: Dictionary = {}
var transport_original_files: Dictionary = {}
var transport_unavailable_original_paths: Array[String] = []


func _transport_hash(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK: return ""
	return context.finish().hex_encode()


func _transport_read_input(path: String, expected_sha256: String, label: String) -> bool:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	var digest: String = _transport_hash(bytes)
	if not _expect(not bytes.is_empty() and expected_sha256.length() == 64 and digest == expected_sha256, "read exact complete producer report with caller-pinned SHA256"): return false
	var value: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not _expect(value is Dictionary and value.get("case") in ["legacy-producer", "fresh-producer"] and value.get("complete") == true and value.get("success") == true and value.get("failures") == 0 and value.get("first_failure") is Dictionary and value.first_failure.is_empty() and value.get("assertions") is Array and value.assertions.size() == int(value.get("checks", -1)), "input is a complete successful original producer report, not an incomplete branch rescue"): return false
	var original_rows_pass: bool = true
	for assertion: Variant in value.assertions:
		original_rows_pass = original_rows_pass and assertion is Dictionary and assertion.get("passed") == true
	if not _expect(original_rows_pass, "every original producer assertion is passing; original count retained without replay credit"): return false
	if not _expect(value.get("source_pre") is Dictionary and not value.source_pre.is_empty() and value.get("source_post") is Dictionary and _same(value.source_pre, value.source_post) and value.get("branches") is Dictionary and value.branches.get(label) is Dictionary, "original producer source custody and selected complete branch are present"): return false
	var row: Dictionary = value.branches[label]
	if not _expect(row.get("label") == label and row.get("raw_store") is Dictionary and row.get("all_original_disk_files") is Dictionary and row.all_original_disk_files.get("campaign.json") is Dictionary and _same(row.raw_store, row.all_original_disk_files["campaign.json"]), "selected original branch retains its original campaign file record"): return false
	for pair: Array in [["current_exact", "current_sha256"], ["checkpoint_exact", "checkpoint_sha256"], ["attempts_exact", "attempts_sha256"]]:
		if not _expect(row.get(pair[0]) is String and not String(row[pair[0]]).is_empty() and row.get(pair[1]) == String(row[pair[0]]).sha256_text(), "complete original typed wire and SHA join: " + String(pair[0])): return false
	var current: Dictionary = Exact.parse(row.current_exact)
	var checkpoint: Dictionary = Exact.parse(row.checkpoint_exact)
	var attempts: Dictionary = Exact.parse(row.attempts_exact)
	if not _expect(current.get("accepted") == true and checkpoint.get("accepted") == true and attempts.get("accepted") == true and current.value is Dictionary and checkpoint.value is Dictionary and attempts.value is Dictionary and Exact.stringify(current.value) == row.current_exact and Exact.stringify(checkpoint.value) == row.checkpoint_exact and Exact.stringify(attempts.value) == row.attempts_exact, "all three original typed wires parse and reencode exactly within unchanged budgets"): return false
	var state: Dictionary = attempts.value
	if not _expect(state.get("story") is Dictionary and state.get("side_attempt") == null and state.story.get("level_id") == Layout.LEVEL_ID and Exact.stringify(state.story.snapshot) == row.current_exact and Exact.stringify(state.story.checkpoint) == row.checkpoint_exact, "original whole Attempts contains these exact current and checkpoint units, with no transplant"): return false
	if not _closed(current.value) or not _closed(checkpoint.value): return false
	var local: Dictionary = current.value.level.local
	var cp_local: Dictionary = checkpoint.value.level.local
	var schema: int = int(local.schema_version)
	if not _expect(schema in [1, 2] and row.get("local_schema") == schema and cp_local.schema_version == schema and local.scheduler.profile.id == row.get("profile_id") and cp_local.scheduler.profile.id == row.profile_id and current.value.shell.difficulty_at_entry == row.profile_id and checkpoint.value.shell.difficulty_at_entry == row.profile_id, "whole branch retains one native entry profile and literal authored format"): return false
	if not _expect((schema == 1 and local.size() == 16 and cp_local.size() == 16 and not local.has("final_arrangement") and not cp_local.has("final_arrangement")) or (schema == 2 and local.size() == 17 and cp_local.size() == 17 and _same(local.final_arrangement, cp_local.final_arrangement)), "old16 omission or new17 exact saved descriptor holds across the actual branch"): return false
	if value["case"] == "legacy-producer":
		if not _expect(schema == 1 and value.source_pre.get(LEGACY_HOST_PATH) == LEGACY_HOST_SHA and value.source_pre.get(LEGACY_CODEC_PATH) == LEGACY_CODEC_SHA, "legacy producer is pinned to the original writer, not a relabeled new packet"): return false
	else:
		if not _expect(schema == 2 and value.source_pre.get(LEGACY_HOST_PATH) == FRESH_HOST_SHA and value.source_pre.get(LEGACY_CODEC_PATH) == FRESH_CODEC_SHA and value.source_pre.get(RECIPE_PATH) == RECIPE_SHA, "fresh producer retains the exact native new writer/codec/recipe source pins"): return false
	var current_sources: Dictionary = _source_pins()
	if not _expect(current_sources.get(RECIPE_PATH) == RECIPE_SHA, "promoted reader uses the exact authorized arrangement definition"): return false
	var historical_recipe_pin: Variant = value.source_pre.get(RECIPE_PATH, "<not-pinned-in-native-report>")
	if value["case"] == "legacy-producer":
		if not _expect(historical_recipe_pin in ["<absent>", "<not-pinned-in-native-report>"], "old native report retains its literal absent or omitted recipe observation without relabeling"): return false
	for path_key: String in value.source_pre:
		if path_key in [LEGACY_HOST_PATH, LEGACY_CODEC_PATH]: continue
		if path_key == RECIPE_PATH and value["case"] == "legacy-producer": continue
		if not _expect(current_sources.get(path_key) == value.source_pre[path_key], "unchanged directly pinned native/layout/scene/base-fixture input: " + path_key): return false
	if label == "cp2":
		if not _expect(row.checkpoint_id == "moon-phase-2" and row.primary_count == 4 and checkpoint.value.level.progress.checkpoint_id == "moon-phase-2" and cp_local.stage == "sneeze" and cp_local.eye.hp == 160.0 and cp_local.scheduler.reservations.is_empty(), "CP2 input is the independent fourth-primary branch with its own native CP2"): return false
	elif label == "cp3":
		if not _expect(row.checkpoint_id == "moon-phase-3" and row.primary_count == 8 and cp_local.stage == "final" and cp_local.eye.hp == 80.0 and cp_local.scheduler.reservations.is_empty(), "CP3 input is its separate eighth-primary branch"): return false
	else:
		if not _expect(label in ["first-final-blink", "first-final-sneeze"] and row.primary_count == 8 and row.checkpoint_id == "moon-phase-3" and local.stage == "final" and local.eye.hp == 80.0 and not local.scheduler.reservations.is_empty() and cp_local.scheduler.reservations.is_empty(), "active final branch retains its contemporaneous CP3 and actual lease"): return false
	transport_input_path = path; transport_input_sha256 = digest
	transport_input_branch = row.duplicate(true)
	transport_input_unit = current.value.duplicate(true)
	transport_input_checkpoint = checkpoint.value.duplicate(true)
	transport_input_attempts = state.duplicate(true)
	for original: Dictionary in row.all_original_disk_files.values():
		var original_path: String = String(original.get("path", ""))
		if not original_path.is_empty() and FileAccess.file_exists(original_path):
			if not _expect(FileAccess.get_sha256(original_path) == original.get("sha256"), "available original branch artifact matches literal report bytes"): return false
			transport_original_files[original_path] = original.sha256
		else:
			transport_unavailable_original_paths.append(original_path)
	receipts.append({"stage": "pinned whole producer input", "source_report": path, "source_sha256": digest, "producer_case": value["case"], "original_checks": int(value.checks), "available_original_files": transport_original_files.duplicate(true), "unavailable_original_paths": transport_unavailable_original_paths.duplicate(), "branch": label, "current_sha256": row.current_sha256, "checkpoint_sha256": row.checkpoint_sha256, "attempts_sha256": row.attempts_sha256, "raw_store_sha256": row.raw_store.sha256, "producer_source_pre": value.source_pre.duplicate(true), "producer_source_post": value.source_post.duplicate(true), "historical_recipe_pin": historical_recipe_pin, "current_recipe_sha256": current_sources[RECIPE_PATH], "recipe_scope": "Omitted old native key is disclosed, not an original absence witness; runner source bank retains any separate file-presence evidence."})
	return true


func _transport_clone_original_files() -> bool:
	if not _expect(not is_instance_valid(game) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_root)) == OK, "unique isolated clone exists before any recipient Shell"): return false
	var existing := DirAccess.open(test_root)
	if not _expect(existing != null and existing.get_files().is_empty() and existing.get_directories().is_empty(), "transport destination is empty; no prior or donor files overwritten"): return false
	for name: String in transport_input_branch.all_original_disk_files:
		var row: Variant = transport_input_branch.all_original_disk_files[name]
		if not _expect(name == name.get_file() and name not in ["", ".", ".."] and row is Dictionary and row.get("hex") is String and row.get("sha256") is String, "original branch file has a confined leaf name and exact bytes"): return false
		var bytes: PackedByteArray = String(row.hex).hex_decode()
		if not _expect(bytes.size() == row.get("bytes") and bytes.hex_encode() == row.hex and _transport_hash(bytes) == row.sha256, "original branch hex/byte count/SHA agree: " + name): return false
		var output := FileAccess.open(test_root.path_join(name), FileAccess.WRITE)
		if not _expect(output != null, "isolated recipient file opens: " + name): return false
		output.store_buffer(bytes); output.flush()
		var error: Error = output.get_error(); output.close()
		if not _expect(error == OK and FileAccess.get_file_as_bytes(test_root.path_join(name)) == bytes and FileAccess.get_sha256(test_root.path_join(name)) == row.sha256, "isolated original file clone is byte-exact: " + name): return false
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(test_root + "campaign.json"))
	if not _expect(envelope is Dictionary and envelope.get("format_version") == Store.FORMAT_VERSION and envelope.get("payload_json") == transport_input_branch.attempts_exact and envelope.get("sha256") == String(transport_input_branch.attempts_exact).sha256_text(), "copied original format2 envelope contains complete exact original Attempts"): return false
	return true


func _transport_wait_idle(label: String) -> bool:
	var until: int = Time.get_ticks_msec() + 20000
	while not finishing and not aborted and Time.get_ticks_msec() <= until:
		if _shell_idle(): return true
		await process_frame
	return _expect(false, "bounded actual Shell operation settlement: " + label)


func _transport_policy_matches(shell: CinderCampaignShell, saved: Dictionary) -> bool:
	if not shell.active_level.has_method("final_arrangement_state"): return _expect(false, "transport requires the promoted dual reader's readonly installed-policy observation")
	var expected: Dictionary = {"schema_version": saved.level.local.schema_version, "final_arrangement": saved.level.local.final_arrangement.duplicate(true) if saved.level.local.schema_version == 2 else {}}
	return _expect(_same(shell.active_level.call("final_arrangement_state"), expected), "installed policy exactly matches literal saved format/descriptor")


func _transport_open_original(future_preference: String) -> bool:
	if not _transport_clone_original_files(): return false
	_begin_watch("fresh clone Title and validation recipients", null, null, true)
	game = _new_shell()
	if game == null or not await _settle() or not await _transport_wait_idle("fresh Title"): return false
	if not _expect(paused and game.player == null and game.active_level == null and game.menu.page_name() == "title" and game.campaign_error.is_empty() and Exact.stringify(game.attempts.state()) == transport_input_branch.attempts_exact and FileAccess.get_sha256(test_root + "campaign.json") == transport_input_branch.raw_store.sha256 and events.is_empty(), "fresh Title loads exact whole original branch without native callbacks or campaign-file rewriting"): return false
	if not _expect(future_preference in ["assisted", "standard", "challenge"] and future_preference != transport_input_branch.profile_id, "future preference intentionally differs from saved native entry profile"): return false
	game.menu.difficulty_preference_requested.emit(future_preference)
	if not await _settle() or not _expect(game.get_difficulty_preference() == future_preference and Exact.stringify(game.attempts.state()) == transport_input_branch.attempts_exact and FileAccess.get_sha256(test_root + "campaign.json") == transport_input_branch.raw_store.sha256, "public future preference changes only isolated preferences, never this saved attempt"): return false
	if not await _click(game, "ContinueStoryButton") or not await _transport_wait_idle("fresh Continue") or not _bindings(game): return false
	moon = game.active_level
	if not _expect(paused and Exact.stringify(game.capture_campaign_snapshot()) == transport_input_branch.current_exact and Exact.stringify(game.attempts.state()) == transport_input_branch.attempts_exact and FileAccess.get_sha256(test_root + "campaign.json") == transport_input_branch.raw_store.sha256 and events.is_empty(), "independent actual disk Continue quietly retains complete original current/checkpoint/Attempts/native clocks/samples/leases"): return false
	if not _transport_policy_matches(game, transport_input_unit): return false
	receipts.append({"stage": "whole original branch fresh Continue", "branch": transport_input_branch.label, "future_preference": future_preference, "exact_current": Exact.stringify(game.capture_campaign_snapshot()), "exact_attempts": Exact.stringify(game.attempts.state()), "recipient_ids": _ids(game.active_level, game.player), "quiet_callbacks": events.duplicate(true)})
	if not await _pause(): return false
	if not _expect(Exact.stringify(game.capture_campaign_snapshot()) == transport_input_branch.current_exact and Exact.stringify(game.attempts.state()) == transport_input_branch.attempts_exact and _durable(game) and events.is_empty(), "public paused Save keeps exact whole native unit and full original Attempts; only isolated Store generation may advance"): return false
	_end_watch("after actual paused Save")
	return true


func _run_transport_case(path: String, sha256: String, label: String, future_preference: String) -> bool:
	if not _transport_read_input(path, sha256, label) or not await _transport_open_original(future_preference): return false
	if label == "cp2":
		var prior_ids: Dictionary = _ids(game.active_level, game.player)
		var prior_refs: Array[WeakRef] = _refs(game.world)
		_begin_watch("actual original CP2 public Retry recipients", null, null, true)
		if not await _click(game, "RetryButton") or not await _transport_wait_idle("CP2 Retry") or not _bindings(game): return false
		moon = game.active_level
		var after: Dictionary = game.attempts.state()
		var expected: Dictionary = transport_input_attempts.duplicate(true)
		# Expected model comparison only. Never submitted or written as history.
		expected["story"]["snapshot"] = transport_input_checkpoint.duplicate(true)
		if not _expect(paused and game.menu.page_name() == "resume" and Exact.stringify(game.capture_campaign_snapshot()) == transport_input_branch.checkpoint_exact and Exact.stringify(after.story.checkpoint) == transport_input_branch.checkpoint_exact and _same(after, expected) and _ids(game.active_level, game.player) != prior_ids and _freed(prior_refs) and _durable(game) and events.is_empty() and game.get_difficulty_preference() == future_preference, "public Retry of independently loaded CP2 restores exactly its native CP2 with fresh identities, zero recipient callbacks and normal predecessor retirement"): return false
		if not _transport_policy_matches(game, transport_input_checkpoint): return false
		receipts.append({"stage": "genuine CP2 branch public Retry", "source_report": path, "source_sha256": sha256, "exact_checkpoint": transport_input_branch.checkpoint_exact, "exact_after_attempts": Exact.stringify(after), "before_ids": prior_ids, "after_ids": _ids(game.active_level, game.player), "quiet_callbacks": events.duplicate(true), "scope": "Original independently archived CP2 session; no CP3 checkpoint transplantation and no gameplay Resume."})
		_end_watch("normal CP2 retry scope complete")
	return _transport_input_unchanged()


func _transport_input_unchanged() -> bool:
	for path: String in transport_original_files:
		if not _expect(FileAccess.get_sha256(path) == transport_original_files[path], "available original branch artifact remains byte-exact: " + path): return false
	return _expect(FileAccess.get_sha256(transport_input_path) == transport_input_sha256 and String(transport_input_branch.current_exact).sha256_text() == transport_input_branch.current_sha256 and String(transport_input_branch.checkpoint_exact).sha256_text() == transport_input_branch.checkpoint_sha256 and String(transport_input_branch.attempts_exact).sha256_text() == transport_input_branch.attempts_sha256, "complete original input report and literal branch witnesses remain unchanged")


func _run_metadata_case(path: String, sha256: String, label: String, future_preference: String) -> bool:
	if not _transport_read_input(path, sha256, label) or not await _transport_open_original(future_preference): return false
	var saved: Dictionary = transport_input_unit
	var donor: Dictionary = _donor()
	var installed: Dictionary = game.active_level.call("final_arrangement_state")
	candidate = game._prepare(Layout.LEVEL_ID, saved.equipment_ids, {}, saved)
	if not _expect(not candidate.is_empty(), "real valid fresh recipient construction stages metadata using the dual reader"): return false
	var recipient: CinderLevel = candidate.level
	var uncommitted: Dictionary = {"schema_version": 0, "final_arrangement": {}}
	var staged: Dictionary = recipient.get("_staged_restore_policy").duplicate(true)
	if not _expect(_same(recipient.call("final_arrangement_state"), uncommitted) and not staged.is_empty(), "valid fresh construction stages intent but installs no authoritative format or recipe"): return false
	var before: String = _physical(recipient, candidate.player)
	_begin_watch("pure valid staged recipient validation", recipient, candidate.player)
	if not _expect(not before.is_empty() and recipient.snapshot_error_with_player(saved.level, saved.player).is_empty() and _physical(recipient, candidate.player) == before and _same(recipient.call("final_arrangement_state"), uncommitted) and _same(recipient.get("_staged_restore_policy"), staged) and _same(game.active_level.call("final_arrangement_state"), installed) and _donor() == donor and events.is_empty(), "complete successful paired prevalidation changes no candidate or installed policy"): return false
	if not _expect(candidate.player.restore_state(saved.player) and recipient.restore_state(saved.level), "original quiet Player then whole native recipient commit succeeds"): return false
	var optical: String = game._candidate_presentation_error(candidate, saved.shell)
	var expected_policy: Dictionary = {"schema_version": saved.level.local.schema_version, "final_arrangement": saved.level.local.final_arrangement.duplicate(true) if saved.level.local.schema_version == 2 else {}}
	if not _expect(optical.is_empty() and _same(recipient.call("final_arrangement_state"), expected_policy) and recipient.get("_staged_restore_policy").is_empty() and _same(recipient.call("_capture_local_state"), saved.level.local) and events.is_empty() and _donor() == donor, "only successful full quiet commit installs exact saved policy and original native unit"): return false
	_end_watch("normal valid candidate disposal")
	var refs: Array[WeakRef] = _refs(candidate.container)
	game._dispose(candidate); candidate = {}
	if not _expect(_freed(refs) and _donor() == donor, "valid candidate disposes normally without donor/whole Store changes"): return false
	if not _metadata_late_native_refusal(saved, donor, installed): return false
	var rows: Array[Dictionary] = []
	var bad: Dictionary
	# Complete typed negative copies only; bracket String keys deliberately avoid
	# creating StringName keys that would fail before the intended metadata gate.
	bad = saved.duplicate(true); bad["level"]["local"]["extra"] = true; rows.append({"label": "closed local rejects extra field", "unit": bad, "error": "Snapshot has missing or unsupported fields"})
	bad = saved.duplicate(true); bad["level"]["local"].erase("world_revision"); rows.append({"label": "missing required local field", "unit": bad, "error": "Snapshot has missing or unsupported fields"})
	bad = saved.duplicate(true); bad["level"]["local"]["schema_version"] = float(saved.level.local.schema_version); rows.append({"label": "authored schema requires exact integer", "unit": bad, "error": "Unsupported exact L5 metadata revision"})
	bad = saved.duplicate(true); bad["level"]["local"]["api_revision"] = 1; rows.append({"label": "authored API requires exact string", "unit": bad, "error": "Unsupported exact L5 metadata revision"})
	if saved.level.local.schema_version == 2:
		bad = saved.duplicate(true); bad["level"]["local"].erase("final_arrangement"); rows.append({"label": "missing required v2 field", "unit": bad, "error": "Snapshot has missing or unsupported fields"})
		bad = saved.duplicate(true); bad["level"]["local"]["api_revision"] = "act1-living-moon-level-1"; rows.append({"label": "mixed v1 API with v2 schema", "unit": bad, "error": "Unsupported exact L5 metadata revision"})
		bad = saved.duplicate(true); bad["level"]["local"]["final_arrangement"] = MoonCodec.fresh_final_arrangement(future_preference); rows.append({"label": "canonical descriptor from wrong native profile", "unit": bad, "error": "Final arrangement differs from the saved native entry profile"})
		bad = saved.duplicate(true); bad["level"]["local"]["final_arrangement"]["initial_attack"] = 1; rows.append({"label": "descriptor exact type", "unit": bad, "error": "Final arrangement descriptor retains exact strings"})
		bad = saved.duplicate(true); bad["level"]["local"]["final_arrangement"]["extra"] = true; rows.append({"label": "descriptor closed keys", "unit": bad, "error": "Closed final arrangement descriptor required"})
		bad = saved.duplicate(true); bad["level"]["local"]["schema_version"] = 1; rows.append({"label": "mixed v2 API with v1 schema", "unit": bad, "error": "Unsupported exact L5 metadata revision"})
		bad = saved.duplicate(true); bad["level"]["local"]["final_arrangement"] = false; rows.append({"label": "descriptor requires dictionary", "unit": bad, "error": "Closed final arrangement descriptor required"})
		bad = saved.duplicate(true); bad["level"]["local"]["final_arrangement"].erase("recipe_id"); rows.append({"label": "descriptor requires every closed field", "unit": bad, "error": "Closed final arrangement descriptor required"})
		bad = saved.duplicate(true); bad["level"]["local"]["final_arrangement"]["profile_id"] = 1; rows.append({"label": "descriptor profile exact string type", "unit": bad, "error": "Final arrangement descriptor retains exact strings"})
		bad = saved.duplicate(true); bad["level"]["local"]["final_arrangement"]["recipe_id"] = 1; rows.append({"label": "descriptor recipe exact string type", "unit": bad, "error": "Final arrangement descriptor retains exact strings"})
		bad = saved.duplicate(true); bad["level"]["local"]["final_arrangement"]["profile_id"] = String("unsupported-profile"); rows.append({"label": "unknown descriptor profile", "unit": bad, "error": "Unknown or inconsistent final arrangement descriptor"})
		bad = saved.duplicate(true); bad["level"]["local"]["final_arrangement"]["recipe_id"] = String("A1-L5/unsupported-recipe@v1"); rows.append({"label": "unknown descriptor recipe", "unit": bad, "error": "Unknown or inconsistent final arrangement descriptor"})
		bad = saved.duplicate(true); bad["level"]["local"]["final_arrangement"]["initial_attack"] = String("unsupported-attack"); rows.append({"label": "unknown descriptor initial attack", "unit": bad, "error": "Unknown or inconsistent final arrangement descriptor"})
	else:
		bad = saved.duplicate(true); bad["level"]["local"]["final_arrangement"] = MoonCodec.fresh_final_arrangement(String(saved.level.local.scheduler.profile.id)); rows.append({"label": "legacy exact16 cannot carry new field", "unit": bad, "error": "Snapshot has missing or unsupported fields"})
		bad = saved.duplicate(true); bad["level"]["local"]["schema_version"] = 2; rows.append({"label": "mixed legacy API and new schema", "unit": bad, "error": "Unsupported exact L5 metadata revision"})
		bad = saved.duplicate(true); bad["level"]["local"]["api_revision"] = String("act1-living-moon-level-2"); rows.append({"label": "mixed new API and legacy schema", "unit": bad, "error": "Unsupported exact L5 metadata revision"})
	for row: Dictionary in rows:
		if not _metadata_refusal(row, donor, installed): return false
	return _transport_input_unchanged()


func _metadata_late_native_refusal(saved: Dictionary, donor: Dictionary, installed: Dictionary) -> bool:
	# This complete copy is a refusal input only. Actual body/HP/phase/source
	# state is untouched. Native eye validation owns its fixed authored position.
	var bad: Dictionary = saved.duplicate(true)
	bad["level"]["local"]["eye"]["position"][0] = float(bad.level.local.eye.position[0]) + 0.125
	var wire: String = Exact.stringify(bad)
	var decoded: Dictionary = Exact.parse(wire)
	if not _expect(not wire.is_empty() and decoded.get("accepted") == true and Exact.stringify(decoded.value) == wire and Store.json_error(bad).is_empty() and MoonCodec.metadata_error(bad.level.local).is_empty(), "complete synthetic fixed-eye-position negative passes exact typed wire and authored metadata"): return false
	candidate = game._prepare(Layout.LEVEL_ID, saved.equipment_ids, {}, saved)
	if not _expect(not candidate.is_empty(), "separate valid restore candidate stages metadata before late native refusal"): return false
	var level: CinderLevel = candidate.level
	var before: String = _physical(level, candidate.player)
	var policy: Dictionary = level.call("final_arrangement_state")
	var staged: Dictionary = level.get("_staged_restore_policy").duplicate(true)
	_begin_watch("paired native refusal after valid metadata staging", level, candidate.player)
	if not _expect(not before.is_empty() and policy.schema_version == 0 and policy.final_arrangement.is_empty() and not staged.is_empty() and level.snapshot_error_with_player(saved.level, saved.player).is_empty() and _physical(level, candidate.player) == before and events.is_empty(), "uncommitted staged candidate accepts the complete genuine baseline without installing policy"): return false
	var reason: String = level.snapshot_error_with_player(bad.level, bad.player)
	if not _expect(reason == "Invalid immutable eye identity/configuration/HP/phase/fixed position" and _physical(level, candidate.player) == before and _same(level.call("final_arrangement_state"), policy) and _same(level.get("_staged_restore_policy"), staged) and _same(game.active_level.call("final_arrangement_state"), installed) and _donor() == donor and events.is_empty(), "actual native fixed-position refusal preserves candidate physical state/staged intent/schema0 and installed donor"): return false
	receipts.append({"stage": "late native refusal after valid metadata staging", "mutation": "synthetic saved eye.position[0] plus0.125 only; never applied", "metadata_error": MoonCodec.metadata_error(bad.level.local), "actual_error": reason, "synthetic_negative_sha256": wire.sha256_text(), "before_policy": policy, "after_policy": level.call("final_arrangement_state"), "staged_before": staged, "staged_after": level.get("_staged_restore_policy").duplicate(true), "native_before_exact": before, "native_after_exact": _physical(level, candidate.player), "quiet_callbacks": events.duplicate(true), "provenance_claim": false})
	_end_watch("normal uncommitted native-refused candidate retirement")
	var refs: Array[WeakRef] = _refs(candidate.container)
	game._dispose(candidate); candidate = {}
	return _expect(_freed(refs) and _same(game.active_level.call("final_arrangement_state"), installed) and _donor() == donor, "late native-refused candidate retires normally without forced commit or donor change")


func _metadata_refusal(row: Dictionary, donor: Dictionary, installed: Dictionary) -> bool:
	var unit: Dictionary = row.unit
	var wire: String = Exact.stringify(unit)
	var decoded: Dictionary = Exact.parse(wire)
	if not _expect(not wire.is_empty() and decoded.get("accepted") == true and Exact.stringify(decoded.value) == wire and Store.json_error(unit).is_empty() and MoonCodec.metadata_error(unit.level.local) == row.error, "synthetic negative remains valid complete typed JSON and reaches intended exact metadata error: " + row.label): return false
	_begin_watch("pure installed-donor metadata refusal", game.active_level, game.player)
	var live_error: String = game.active_level.snapshot_error_with_player(unit.level, unit.player)
	if not _expect(live_error == row.error and _same(game.active_level.call("final_arrangement_state"), installed) and _donor() == donor and events.is_empty(), "live failed prevalidation leaves policy/native unit/full Attempts/disk unchanged: " + row.label): return false
	_begin_watch("raw fresh recipient metadata refusal", null, null, true)
	# Existing Shell raw constructor creates actual native children but deliberately
	# does not enter/bind them. The public Level lifecycle must reject metadata.
	candidate = game._prepare(Layout.LEVEL_ID, unit.equipment_ids, {}, unit, true)
	if not _expect(not candidate.is_empty(), "actual raw recipient exists before metadata rejection: " + row.label): return false
	var level: CinderLevel = candidate.level
	var before: String = _physical(level, candidate.player)
	var policy: Dictionary = level.call("final_arrangement_state")
	var staged: Dictionary = level.get("_staged_restore_policy").duplicate(true)
	if not _expect(_transport_sources_unbound(level), "all actual native recipients are unbound before metadata entry: " + row.label): return false
	var entered: bool = level.enter_restore_candidate(candidate.player, candidate.fx, game, unit.level, unit.player)
	var reason: String = level.last_snapshot_error
	if not _expect(not entered and reason == row.error and not before.is_empty() and _physical(level, candidate.player) == before and _same(level.call("final_arrangement_state"), policy) and policy.schema_version == 0 and policy.final_arrangement.is_empty() and _same(level.get("_staged_restore_policy"), staged) and staged.is_empty() and level.get("_running") == false and level.get("scheduler").encounter_profile().is_empty() and _transport_sources_unbound(level) and events.is_empty() and _donor() == donor, "actual fresh lifecycle refuses intended metadata before binding/processing/policy mutation: " + row.label): return false
	receipts.append({"stage": "actual fresh metadata refusal", "label": row.label, "expected_error": row.error, "actual_error": reason, "synthetic_negative_sha256": wire.sha256_text(), "before_policy": policy, "after_policy": level.call("final_arrangement_state"), "native_before_exact": before, "native_after_exact": _physical(level, candidate.player), "quiet_callbacks": events.duplicate(true), "provenance_claim": false})
	_end_watch("normal refused candidate retirement")
	var refs: Array[WeakRef] = _refs(candidate.container)
	game._dispose(candidate); candidate = {}
	return _expect(_freed(refs) and _same(game.active_level.call("final_arrangement_state"), installed) and _donor() == donor, "refused candidate retires all descendants while original donor remains exact: " + row.label)


func _transport_sources_unbound(level: CinderLevel) -> bool:
	# Passive native reference reads only; base Level.hero is allowed to stage
	# identity during enter_restore_candidate, but no native source may bind it.
	for name: String in ["rusher", "eye"]:
		var actor: Node = level.get(name)
		if actor.get("_scheduler") != null or actor.get("_hero") != null: return false
	for name: String in ["impact", "nose"]:
		var actor: Node = level.get(name)
		if actor.get("_scheduler") != null or not actor.get("_heroes").is_empty(): return false
	var consumer: Node = level.get("blink")
	return consumer.get("_scheduler_ref") == null and consumer.get("_hero_ref") == null and consumer.get("_world_ref") == null and level.get("eye").call("get_native_bindings").is_empty() and level.get("eye").call("get_sampled_circle_binding").is_empty()


# PRIVATE UNPARSED/UNEXECUTED FRAGMENT. Compose with fresh + transport fixture.
# No parser/_run/_finish override. Never seed, move, heal or reset native actors.
const HeldGeometry = preload("res://scripts/combat/threat_geometry.gd")
var held_result: Dictionary = {}
var held_trace: Array[Dictionary] = []
var held_actions: Array[Dictionary] = []
var held_leases: Dictionary = {}
var held_order: Array[String] = []
var held_phases: Dictionary = {}
var held_live: bool = false
var held_fault: String = ""
var held_origin: Vector3
var held_landing: Vector3
var held_cp3_clock: float = 0.0
var held_hp: float = 0.0
var held_shells: int = 0
var held_primary_done: bool = false


func _run_held_response_case(path: String, sha256: String, mode: String, baseline_path: String = "", baseline_sha256: String = "") -> bool:
	if not _expect(mode in ["legacy", "new"], "explicit old or new held-response case"): return false
	if not _transport_read_input(path, sha256, "cp3") or not await _transport_open_original("standard"): return false
	var local: Dictionary = transport_input_unit.level.local
	if not _expect(local.schema_version == (1 if mode == "legacy" else 2) and local.scheduler.profile.id == "challenge" and local.stage == "final" and local.eye.hp == 80.0 and local.scheduler.reservations.is_empty() and local.next_attack == ("blink" if mode == "legacy" else "sneeze"), "actual contemporaneous CP3 retains its original whole-attempt initial leader"): return false
	moon = game.active_level; eye_ref = weakref(moon.get("eye"))
	var eye: CharacterBody3D = eye_ref.get_ref() as CharacterBody3D
	var collision: CollisionShape3D = eye.call("get_collision")
	eye_collision_ref = weakref(collision); eye_shape_ref = weakref(collision.shape)
	held_origin = game.player.global_position; held_cp3_clock = _scheduler().get_clock()
	held_hp = game.player.hp; held_shells = game.player.shells
	var support: Dictionary = Sweep.step(game.player, game.player.global_transform, Vector3.ZERO, [moon.call("floor_region")])
	if not _expect(Vector2(held_origin.x, held_origin.z).distance_to(Vector2(Layout.EYE_APPROACH_POSITION.x, Layout.EYE_APPROACH_POSITION.z)) < 0.001 and game.player.get_threat_response_state().stable and not support.has("error") and not support.get("collided", true) and game.player.equipment.snapshot() == Equipment.STARTER and held_hp == 100.0 and held_shells == 2, "same authored supported CP3 start and neutral resources are restored literally; no new TEST pose or refill"): return false
	var baseline: Dictionary = {}
	if mode == "new":
		baseline = _held_read_baseline(baseline_path, baseline_sha256)
		if baseline.is_empty(): return false
		if not _expect(Codec.read_vector3(baseline.origin).distance_to(held_origin) < 0.001, "new actual CP3 start matches the executed old start within measured submillimetre support tolerance"): return false
	held_result = {"stage": "held-landing response", "mode": mode, "status": "incomplete", "source_report": path, "source_sha256": sha256, "branch": "cp3", "baseline_report": baseline_path, "baseline_sha256": baseline_sha256, "origin": Codec.vector3(held_origin), "cp3_clock_s": held_cp3_clock, "source_order": held_order, "leases": {}, "phases": held_phases, "action_receipts": [], "counterfactual": {}, "stopping_rule": "Order/centre change alone earns no difficulty credit; equivalent two-dash response returns to Integration.", "setup_scope": "Literal genuine CP3 with producer's disclosed TEST predecessor/Rusher/approach history; no new Hero/source placement or native-state write."}
	receipts.append(held_result)
	if not is_instance_valid(probe): probe = NativeTickProbe.new(); probe.process_physics_priority = 3000; root.add_child(probe)
	# Producer admission-pause observers must NOT be connected for this case.
	probe.tick_finished.connect(_held_tick)
	game.player.world_action_executed.connect(_held_world_action)
	_begin_watch("actual held-response live native contacts/cancellations", moon, game.player)
	held_live = true
	if not await _click(game, "ResumeButton"): return _held_stop("Public Resume failed; no forced focus/resume")
	if not await _held_wait(func() -> bool: return held_order.size() >= 1, "first genuine admission"): return false
	var expected_leader: String = Layout.EYE_ID if mode == "legacy" else Layout.NOSE_ID
	if not _expect(held_order[0] == expected_leader, "actual first admitted source matches original saved attempt policy"): return _held_stop("Native initial order differed")
	var leader: Dictionary = held_leases[expected_leader].record
	var proof: Dictionary = held_leases[expected_leader].framing.proof
	if not _expect(proof.path is Array and proof.path.size() >= 2 and proof.path[1].kind == "escape_dash", "retain genuine native recognition/readiness proof without replacing its path"): return false
	var earliest_escape: float = float(proof.path[1].start_s)
	if not await _held_wait(func() -> bool: return _scheduler().get_clock() >= earliest_escape and _held_ready(), "actual recognition and public dash readiness", float(leader.active_from_s)): return false
	if not await _held_dash(Vector3.LEFT, "same initial full left dash"): return false
	held_landing = game.player.global_position
	held_result["landing"] = Codec.vector3(held_landing)
	var hold_start: float = _scheduler().get_clock()
	if not await _held_wait(func() -> bool: return held_order.size() == 2, "native lock follower while genuinely holding left landing", float(leader.active_from_s)): return false
	if not _expect(held_order == ([Layout.EYE_ID, Layout.NOSE_ID] if mode == "legacy" else [Layout.NOSE_ID, Layout.EYE_ID]), "both original native sources admitted in actual policy order; no simultaneous-eligibility claim"): return false
	var blink: Dictionary = held_leases[Layout.EYE_ID].record
	var nose: Dictionary = held_leases[Layout.NOSE_ID].record
	var return_at: float = maxf(float(blink.active_until_s), float(nose.active_until_s))
	var return_policy: String = "hold through both original active intervals"
	if mode == "new":
		if not _expect(Codec.read_vector3(baseline.landing).distance_to(held_landing) < 0.001, "new full dash reaches the same measured old held landing"): return false
		if not _held_counterfactual(blink, baseline): return false
		# Replay the old actual CP3-relative return time where its complete timed
		# path is safe under the real new leases. This can demonstrate equivalence.
		var replay_at: float = held_cp3_clock + float(baseline.return_start_s) - float(baseline.cp3_clock_s)
		var duration: float = float(game.player.equipment.resolved_stats().dash_duration)
		var replay_safe: bool = replay_at >= _scheduler().get_clock() and replay_at + duration < float(blink.active_from_s) and _held_timed_safe(held_landing, held_landing, _scheduler().get_clock(), replay_at) and _held_timed_safe(held_landing, held_origin, replay_at, replay_at + duration)
		held_result["old_return_schedule_replay"] = {"at_s": replay_at, "old_cp3_relative_s": float(baseline.return_start_s) - float(baseline.cp3_clock_s), "complete_timed_path_safe": replay_safe, "analytic_only_until_actual_execution": true}
		if replay_safe:
			return_at = replay_at; return_policy = "same actual old CP3-relative return schedule"
		else:
			return_at = float(nose.active_until_s); return_policy = "earlier return after actual Sneeze active, before sampled Blink active"
		if not _expect(return_at + duration < float(blink.active_from_s), "chosen actual return can finish before unchanged sampled Blink active; otherwise stop without forcing it"): return _held_stop("No bounded supported two-dash return before sampled Blink active")
	if not await _held_wait(func() -> bool: return _scheduler().get_clock() > return_at and _held_ready(), "hold until selected actual return boundary", minf(float(blink.recovery_until_s), float(nose.recovery_until_s))): return false
	if not _expect(game.player.global_position.distance_to(held_landing) < 0.001 and _held_hold_supported(hold_start, _scheduler().get_clock()), "executed stationary supported hold has complete native endpoints and zero contact"): return false
	var return_start: float = _scheduler().get_clock()
	held_result["return_policy"] = return_policy
	held_result["actual_hold"] = {"from": Codec.vector3(held_landing), "to": Codec.vector3(held_landing), "start_s": hold_start, "end_s": return_start, "executed": true}
	if not await _held_dash((held_origin - game.player.global_position).normalized(), "actual full ordinary return; no TEST recovery teleport"): return false
	if not _expect(game.player.global_position.distance_to(held_origin) < 0.01, "actual full return dash reaches measured original useful approach"): return false
	if not await _held_wait(func() -> bool: return _held_ready() and game.player.get_threat_response_state().primary_cooldown_left_s == 0.0 and _genuine_recovery(_boss_records()), "actual stationary low-eye recovery primary readiness", minf(float(blink.recovery_until_s), float(nose.recovery_until_s))): return false
	if not _expect(game.camera_framing_error(moon.camera_framing_points()).is_empty(), "actual current unchanged full source/cue/response framing before ordinary primary"): return _held_stop("Native current optics refused the ordinary response")
	var primary_time: float = _scheduler().get_clock()
	var primary_deadline: float = 0.0
	for record: Dictionary in _boss_records():
		if String(record.state) == "recovery": primary_deadline = maxf(primary_deadline, float(record.recovery_until_s))
	var stats: Dictionary = game.player.equipment.resolved_stats()
	var completion: float = primary_time + maxf(float(stats.primary_cooldown), float(game.player.get_threat_response_state().primary_commitment_s))
	if not _expect(primary_deadline > completion, "actual ordinary primary and unchanged cooldown/commitment fit a genuine retained recovery"): return false
	var before_hp: float = eye.get("hp")
	var hits: int = game.player.slash((eye.global_position - game.player.global_position).normalized())
	held_primary_done = true
	if not _expect(hits == 1 and before_hp == 80.0 and eye.get("hp") == before_hp - float(stats.primary_damage) and held_actions.size() == 3 and held_actions[2].kind == "primary" and held_actions[2].hits == 1 and game.player.get_threat_response_state().primary_cooldown_left_s > 0.0, "one immediate real ordinary primary80-to60 after two full public dashes pays its native cooldown"): return false
	if not await _held_wait(func() -> bool: return _scheduler().get_clock() >= completion and game.player.get_threat_response_state().primary_cooldown_left_s == 0.0, "actual ordinary completion under original recovery", primary_deadline): return false
	# Finish both genuine active windows at the returned safe position. This
	# never rewinds a lease or waits for a fabricated replay of the earlier hold.
	if not await _held_wait(func() -> bool: return _scheduler().get_clock() > maxf(float(blink.active_until_s), float(nose.active_until_s)), "both original active intervals genuinely ended", minf(float(blink.recovery_until_s), float(nose.recovery_until_s))): return false
	for id: String in [Layout.EYE_ID, Layout.NOSE_ID]:
		for phase: String in ["warning", "lock", "active", "recovery"]:
			if not _expect(held_phases.get(id, {}).has(phase), "actual source grammar observed: " + id + "/" + phase): return false
	if not _held_integrity() or not _expect(held_actions.size() == 3 and _eye_registration_intact(), "exact two-dash/one-primary exchange retains original eye collision/native registration"): return false
	held_live = false
	if probe.tick_finished.is_connected(_held_tick): probe.tick_finished.disconnect(_held_tick)
	if not await _pause(): return false
	var saved: Dictionary = game.capture_campaign_snapshot()
	if not _closed(saved) or not _expect(_durable(game) and Exact.stringify(game.attempts.state().story.checkpoint) == transport_input_branch.checkpoint_exact, "actual public final Save retains the original whole CP3 checkpoint"): return false
	var comparison: Dictionary = {"cp3_clock_s": held_cp3_clock, "origin": Codec.vector3(held_origin), "landing": Codec.vector3(held_landing), "hold_start_s": hold_start, "return_start_s": return_start, "primary_time_s": primary_time, "completion_s": completion, "recovery_deadline_s": primary_deadline, "eye_before_hp": before_hp, "eye_after_hp": eye.get("hp"), "hero_hp": game.player.hp, "shells": game.player.shells, "dash_count": 2, "primary_count": 1, "mode": mode, "return_policy": return_policy}
	held_result["comparison_exact"] = Exact.stringify(comparison)
	held_result["trace_exact"] = _held_wire(held_trace)
	held_result["actions_exact"] = _held_wire(held_actions)
	held_result["native_events_exact"] = _held_wire(events)
	held_result["final_snapshot_exact"] = Exact.stringify(saved)
	held_result["final_attempts_exact"] = Exact.stringify(game.attempts.state())
	for key: String in ["comparison_exact", "trace_exact", "actions_exact", "native_events_exact", "final_snapshot_exact", "final_attempts_exact"]:
		if not _expect(_held_wire_valid(String(held_result[key])), "complete nonempty exact held-response witness: " + key): return false
	held_result["status"] = "complete"
	held_result["old_safe_useful_executed"] = mode == "legacy"
	held_result["interpretation"] = "Executed old hold through both active intervals and useful return." if mode == "legacy" else ("Same CP3-relative old return schedule succeeded with two dashes: equivalent option observed; no automatic difficulty credit, return to Integration." if return_policy.begins_with("same actual old") else "Altered earlier return succeeded with two dashes; timing decision observed, complexity unchanged; Integration reviews equivalence.")
	_end_watch("normal held-response cleanup")
	return _transport_input_unchanged()


func _held_wait(predicate: Callable, label: String, native_deadline: float = INF) -> bool:
	var until: int = Time.get_ticks_msec() + 60000
	while not finishing and not aborted and Time.get_ticks_msec() <= until:
		if not _held_integrity(): return false
		if _scheduler().get_clock() >= native_deadline: return _held_stop("Unchanged native deadline reached: " + label)
		if predicate.call(): return true
		if paused: return _held_stop("Normal focus/Shell pause during live " + label + "; no forced Resume")
		await probe.tick_finished
	return _held_stop("Bounded wall observation ended: " + label)


func _held_ready() -> bool:
	var response: Dictionary = game.player.get_threat_response_state()
	return response.stable and response.dash_cooldown_left_s == 0.0 and response.commitment_remaining_s == 0.0 and response.motion.queued_dash == Vector3.ZERO


func _held_dash(direction: Vector3, label: String) -> bool:
	var origin: Vector3 = game.player.global_position
	var stats: Dictionary = game.player.equipment.resolved_stats()
	var flat: Vector3 = Vector3(direction.x, 0, direction.z).normalized()
	var target: Vector3 = origin + flat * float(stats.dash_distance)
	var now: float = _scheduler().get_clock()
	var support: Dictionary = Sweep.sweep(game.player, game.player.global_transform, target - origin, [moon.call("floor_region")])
	if not _expect(_held_ready() and not support.has("error") and not support.get("collided", true) and _held_timed_safe(origin, target, now, now + float(stats.dash_duration)), "actual full supported timed dash is ready and avoids admitted native shapes: " + label): return _held_stop("Proposed public dash lacks original support/timed safety")
	var count: int = held_actions.size()
	if not _expect(game.player.request_dash(flat), "public Player request_dash accepted only with zero cooldown: " + label): return false
	if not await _held_wait(func() -> bool: return held_actions.size() > count and game.player.get_threat_response_state().stable, "full public dash completes: " + label): return false
	var action: Dictionary = held_actions[count]
	return _expect(held_actions.size() == count + 1 and action.kind == "dash" and action.origin == "player_direct" and action.blocked == false and action.collision_shortened == false and action.movement_damage == false and absf(float(action.distance) - float(stats.dash_distance)) < 0.001 and action.path.size() >= 2, "actual complete native dash retains full endpoints/path/distance and no movement damage: " + label)


func _held_timed_safe(from: Vector3, to: Vector3, start_s: float, end_s: float) -> bool:
	var path: Array[Dictionary] = [{"from": from, "to": to, "start_s": start_s, "end_s": end_s}]
	for id: String in held_leases:
		var record: Dictionary = held_leases[id].record
		if maxf(start_s, float(record.active_from_s)) > minf(end_s, float(record.active_until_s)): continue
		if HeldGeometry.timed_path_hits(record.geometry, path, float(record.active_from_s), float(record.active_until_s), Scheduler.CAPSULE_RADIUS): return false
	return true


func _held_counterfactual(blink: Dictionary, baseline: Dictionary) -> bool:
	var source: Dictionary = moon.get("blink").state()
	var before: Dictionary = _scheduler().sampled_circle_reservation_state(String(blink.id))
	var before_wire: String = _held_wire(before)
	var segment: Dictionary = {"from": held_landing, "to": held_landing, "start_s": float(blink.active_from_s), "end_s": float(blink.active_until_s)}
	var path: Array[Dictionary] = [segment]
	var temporal: bool = maxf(segment.start_s, float(blink.active_from_s)) <= minf(segment.end_s, float(blink.active_until_s))
	var hit: bool = temporal and HeldGeometry.timed_path_hits(blink.geometry, path, float(blink.active_from_s), float(blink.active_until_s), Scheduler.CAPSULE_RADIUS)
	var supported: bool = _scheduler().sampled_circle_contact_supported(String(blink.id), held_landing, held_landing)
	var after: Dictionary = _scheduler().sampled_circle_reservation_state(String(blink.id))
	if not _expect(not paused and source.status == "running" and source.reservation_id == blink.id and blink.geometry.kind == "circle" and not before.is_empty() and _held_wire_valid(before_wire) and before_wire == _held_wire(after) and _held_wire(source.sample) == _held_wire(blink.adapter.sample) and Codec.read_vector3(source.sample.hero_position).distance_to(held_landing) < 0.001 and blink.geometry.origin == Codec.read_vector3(source.sample.ground_position), "actual new native Blink samples the executed held landing without retargeting or custody mutation"): return _held_stop("Actual new Blink did not sample supported held landing")
	held_result["counterfactual"] = {"native_sample_exact": _held_wire(source.sample), "native_lease_exact": _held_wire(before), "old_executed_hold": {"from": baseline.landing, "to": baseline.landing, "start_s": baseline.hold_start_s, "end_s": baseline.return_start_s}, "new_analytic_hold_segment_exact": _held_wire(segment), "strict_temporal_overlap": temporal, "native_radius": Scheduler.CAPSULE_RADIUS, "timed_geometry_hit": hit, "live_current_contact_supported": supported, "executed": false, "scope": "Analytic keep-holding behavior over actual new active interval; not old absolute-clock segment, historical endpoint authority or inflicted contact."}
	return _expect(hit and supported, "new actual sampled lease gives strict timed/supported conflict for holding through its active; no damage intentionally taken")


func _held_hold_supported(from_s: float, to_s: float) -> bool:
	var count: int = 0
	for row: Dictionary in held_trace:
		if float(row.clock_s) < from_s or float(row.clock_s) > to_s: continue
		count += 1
		if not row.stable or not row.grounded or Codec.read_vector3(row.position).distance_to(held_landing) >= 0.001: return false
	return count >= 2


func _held_tick() -> void:
	if not held_live or finishing or aborted or paused or not _live(): return
	var response: Dictionary = game.player.get_threat_response_state()
	if held_trace.size() >= 1800: held_fault = "Bounded native trace capacity reached"; return
	held_trace.append({"clock_s": _scheduler().get_clock(), "player_clock_s": game.player.get_world_action_clock(), "position": Codec.vector3(game.player.global_position), "stable": response.stable, "grounded": response.motion.grounded, "hp": game.player.hp, "shells": game.player.shells, "dash_left_s": response.motion.dash_left_s, "dash_cooldown_s": response.dash_cooldown_left_s, "primary_cooldown_s": response.primary_cooldown_left_s})
	for record: Dictionary in _boss_records():
		var id: String = String(record.source_id)
		var consumer: Node = moon.get("blink") if id == Layout.EYE_ID else moon.get("nose")
		var state: Dictionary = consumer.call("state")
		if not held_leases.has(id):
			var frame: Dictionary = moon.get("_frames").get(id, {})
			if frame.get("reservation_id") != record.id or not frame.get("proof") is Dictionary: held_fault = "Real admission lacks original paired framing proof"; return
			held_order.append(id); held_leases[id] = {"record": record.duplicate(true), "framing": frame.duplicate(true)}; held_phases[id] = {}
			held_result.leases[id] = {"native_record_exact": _held_wire(record), "framing_exact": _held_wire(frame), "state_exact": _held_wire(state), "cue_exact": _held_wire(consumer.call("get_cue").state()), "camera_exact": _held_wire(game.camera.global_transform), "camera_size": game.camera.size, "framing_state_exact": _held_wire(game.get_camera_framing_state()), "hero_position": Codec.vector3(game.player.global_position), "clock_s": _scheduler().get_clock()}
		elif record.id != held_leases[id].record.id: held_fault = "A replacement cycle arrived before this focused exchange completed"; return
		var original: Dictionary = held_leases[id].record.duplicate(true)
		var actual: Dictionary = record.duplicate(true)
		original.erase("state"); original.erase("armed"); actual.erase("state"); actual.erase("armed")
		var original_wire: String = _held_wire(original)
		if original_wire.is_empty() or original_wire != _held_wire(actual): held_fault = "Original native lease/sample/deadline changed"; return
		var phase: String = String(state.phase)
		if not held_phases[id].has(phase): held_phases[id][phase] = {"clock_s": _scheduler().get_clock(), "state_exact": _held_wire(state), "cue_exact": _held_wire(consumer.call("get_cue").state())}


func _held_world_action(action: Dictionary) -> void:
	if not held_live: return
	held_actions.append(action.duplicate(true))
	held_result.action_receipts.append({"scheduler_clock_s": _scheduler().get_clock(), "player_clock_s": game.player.get_world_action_clock(), "actual_action_exact": _held_wire(action)})


func _held_integrity() -> bool:
	if not held_fault.is_empty(): return _held_stop(held_fault)
	if not _live() or game.player.hp != held_hp or game.player.shells != held_shells: return _held_stop("Actual Hero HP/ammo or native live binding changed")
	for row: Dictionary in events:
		if row.kind in ["source-hit", "cancel", "hero-died"]: return _held_stop("Native contact/cancellation observed, including possible dash-invulnerability rejection")
	if not held_primary_done and moon.get("eye").get("hp") != 80.0: return _held_stop("Eye changed before actual ordinary primary")
	return true


func _held_stop(reason: String) -> bool:
	held_live = false
	if is_instance_valid(probe) and probe.tick_finished.is_connected(_held_tick): probe.tick_finished.disconnect(_held_tick)
	if not held_result.is_empty():
		held_result["status"] = "inconclusive_or_refused"
		held_result["reason"] = reason
		held_result["trace_exact"] = _held_wire(held_trace)
		held_result["actions_exact"] = _held_wire(held_actions)
		held_result["native_events_exact"] = _held_wire(events)
		held_result["native_clock_s"] = _scheduler().get_clock() if _live() else -1.0
		held_result["parent_error"] = String(moon.get("last_encounter_error")) if is_instance_valid(moon) else "unavailable"
	return _expect(false, reason + "; preserve result and return to Integration, no guard/timing change")


func _held_read_baseline(path: String, sha256: String) -> Dictionary:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if not _expect(not bytes.is_empty() and _transport_hash(bytes) == sha256 and sha256.length() == 64, "exact complete executed baseline report is SHA-pinned"): return {}
	var value: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not _expect(value is Dictionary and value.get("complete") == true and value.get("success") == true and value.get("failures") == 0 and value.get("receipts") is Array, "old useful-response baseline is a genuinely closed passing case"): return {}
	for row: Variant in value.receipts:
		if not row is Dictionary or row.get("stage") != "held-landing response": continue
		var answer: Dictionary = Exact.parse(String(row.get("comparison_exact", "")))
		if not _expect(row.get("status") == "complete" and row.get("mode") == "legacy" and row.get("old_safe_useful_executed") == true and answer.get("accepted") == true and answer.value is Dictionary and Exact.stringify(answer.value) == row.comparison_exact and answer.value.dash_count == 2 and answer.value.primary_count == 1 and answer.value.eye_after_hp == 60.0 and answer.value.hero_hp == 100.0 and answer.value.shells == 2 and _held_wire_valid(String(row.get("trace_exact", ""))) and _held_wire_valid(String(row.get("actions_exact", ""))), "baseline retains executed old safe/useful two-dash/ordinary response and complete exact trace/actions"): return {}
		return answer.value
	_expect(false, "baseline report has no executed complete old held-response receipt")
	return {}


func _held_wire(value: Variant) -> String:
	return Exact.stringify(_held_encode(value))


func _held_wire_valid(wire: String) -> bool:
	if wire.is_empty(): return false
	var answer: Dictionary = Exact.parse(wire)
	return answer.get("accepted") == true and Exact.stringify(answer.value) == wire


func _held_encode(value: Variant) -> Variant:
	if value is Vector2: return {"native_type": "Vector2", "components": [value.x, value.y]}
	if value is Vector3: return {"native_type": "Vector3", "components": [value.x, value.y, value.z]}
	if value is Color: return {"native_type": "Color", "components": [value.r, value.g, value.b, value.a]}
	if value is Basis: return {"native_type": "Basis", "x": _held_encode(value.x), "y": _held_encode(value.y), "z": _held_encode(value.z)}
	if value is Transform3D: return {"native_type": "Transform3D", "basis": _held_encode(value.basis), "origin": _held_encode(value.origin)}
	if value is Rect2 or value is AABB: return {"native_type": "Rect2" if value is Rect2 else "AABB", "position": _held_encode(value.position), "size": _held_encode(value.size)}
	if value is StringName: return {"native_type": "StringName", "value": String(value)}
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _held_encode(value[key])
		return result
	if value is Array:
		var result: Array = []
		for child: Variant in value: result.append(_held_encode(child))
		return result
	return value


func _held_finalize_observations() -> void:
	# Called synchronously before ordinary fixture cleanup, including watchdog
	# failures. Preserve actual traces even when an earlier assertion returned.
	held_live = false
	if held_result.is_empty(): return
	held_result["trace_exact"] = _held_wire(held_trace)
	held_result["actions_exact"] = _held_wire(held_actions)
	held_result["native_events_exact"] = _held_wire(events)
	held_result["close_clock_s"] = _scheduler().get_clock() if _live() else -1.0
	held_result["close_position"] = Codec.vector3(game.player.global_position) if _live() else []
	if is_instance_valid(probe) and probe.tick_finished.is_connected(_held_tick): probe.tick_finished.disconnect(_held_tick)
