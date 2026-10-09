extends "res://tests/acts/act2/a2_l4_live_level_smoke.gd"
## TMP TEST ONLY brief actual production views; requires final promoted L5
## codec/scene and presented parent. No full route/earned boss defeat/art pass.
## Scope1: genuine initial L5 packet -> actual Shell GUI Continue -> entry.
## Scope2: actual Shell on unentered production-geometry TEST level, controller dashes, persistent
## presented parent at authored joint/Foot offsets, genuine Ray/Foot lock views.
## Scope3: the same production kit's permanently inert coda after public dashes from a separate authored supported coda spawn.
## Coda is direct scenery construction, not an earned host stage/survivor pose.
## No live HP/phase/clock/transform/camera/lease writes or fabricated proof.
## Synthetic prior completion metadata through L4 is setup only. One Starter
## kit/Standard profile. Controller requests do not claim gesture recognition.
const ArtJson: Script = preload("res://scripts/campaign/exact_json.gd")
const ArtKit: Script = preload("res://scripts/acts/act2/dead_london_kit.gd")
const ProductionHost: Script = preload("res://scripts/acts/act2/dead_london.gd")
const ArtParent: Script = preload("res://scripts/acts/act2/dead_london_sentry_presented_encounter.gd")
const ArtBait: Script = preload("res://scripts/acts/act2/dead_london_bait.gd")
const ArtScheduler: Script = preload("res://scripts/combat/threat_scheduler.gd")
const ArtGeometry: Script = preload("res://scripts/combat/threat_geometry.gd")
const ART_SCENE: String = "res://scenes/acts/act2/dead_london.tscn"
const ART_COMPONENT: String = "res://tests/acts/act2/fixtures/a2_l5_production_art_component.tscn"
const ART_CODA_COMPONENT: String = "res://tests/acts/act2/fixtures/a2_l5_production_coda_component.tscn"
const ART_ROOT: String = "user://test-a2-l5-production-portraits/"
const ART_CAPTURE: String = "res://captures/act2/a2-l5-production-brief/"
const ART_PREFIX: Array[String] = ["A1-L1", "A1-L2", "A1-L3", "A1-L4", "A1-L5", "A2-L1", "A2-L2", "A2-L3", "A2-L4"]
const ART_LABELS: Array[String] = ["production-entry", "direct-sentry-ray-lock", "direct-near-foot-lock", "direct-inert-coda"]
const JOINT_AT: Vector3 = Vector3(0, 0, -28.4)
const FOOT_AT: Vector3 = Vector3(0.65, 0, -29.35)
const MAX_ART_TICKS: int = 720
var _art_parent: Node3D
var _art_scheduler: CinderThreatScheduler
var _art_bait: RefCounted
var _art_action_observer: Callable
var _art_records: Array[Dictionary] = []
var _art_frames: Array[Dictionary] = []
var _art_kit: Dictionary = {}
var _art_parent_errors: Array[String] = []
var _art_foot_view: Dictionary = {} # Actual accepted preview, ephemeral view only.

func _run() -> void:
	root.size = Vector2i(540, 1170)
	_loadout = LOADOUTS.standard.duplicate(true)
	_loadout_name = "standard"
	_profile_id = "standard"
	_native_probe = NativeTickProbe.new()
	root.add_child(_native_probe)
	_canonical = FileAccess.get_file_as_string(Registry.DATA_PATH)
	_art_clean_user()
	if not _expect(DisplayServer.get_name() != "headless", "brief portrait fixture needs real graphical pixels"):
		quit(1); return
	if not _expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ART_CAPTURE)) == OK, "separate ignored brief production capture directory"):
		quit(1); return
	print("L5 brief scope: actual initial production Shell entry, independently constructed native presented Sentry/Foot locks, direct permanently inert kit coda. Synthetic prior prefix only; no earned boss/host coda, full route, balance or art acceptance.")
	var complete: bool = await _art_entry()
	await _art_release_shell()
	if complete: complete = await _art_components()
	_art_cleanup_components()
	await _art_release_shell()
	_expect(_art_frames.size() == ART_LABELS.size(), "exact four selected brief views, no partial gallery accepted")
	var labels: Array[String] = []
	for frame: Dictionary in _art_frames: labels.append(frame.label)
	_expect(labels == ART_LABELS, "actual rendered labels preserve exact scoped order")
	_expect(FileAccess.get_file_as_string(Registry.DATA_PATH) == _canonical, "isolated registry setup preserves canonical bytes")
	var output: Dictionary = {"scope": "brief production rendering only; native readability needs pixel review", "scope_complete": complete, "labels": labels, "frames": _art_frames, "source_files": _art_sources(), "claims": {"full_route": false, "earned_boss_defeat": false, "earned_host_coda": false, "gesture_recognition": false, "component_aggregate_save": false, "balance": false, "art_accepted": false}}
	var text: String = ArtJson.stringify(output)
	_expect(not text.is_empty(), "closed actual view metadata has exact nonempty JSON")
	if not text.is_empty():
		var file: FileAccess = FileAccess.open(ART_CAPTURE + "metadata.exact.json", FileAccess.WRITE)
		_expect(file != null, "open brief native metadata output")
		if file != null: file.store_string(text); file.close()
	if is_instance_valid(_native_probe): _native_probe.free()
	paused = false
	_expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("required_cues").is_empty(), "explicit whole fixture cleanup leaves no actual source/cue bindings")
	_art_clean_user()
	print("L5 brief production portrait smoke: %d checks, %d failures; scope_complete=%s; entry + native component locks + direct inert scenery only" % [_checks, _failures, str(complete)])
	quit(0 if _failures == 0 and complete else 1)

func _art_entry() -> bool:
	if not await _art_open(ART_SCENE, "entry/"): return false
	var level: CinderLevel = _game.active_level
	var initial: Dictionary = _game.capture_campaign_snapshot()
	if not _expect(not initial.is_empty() and level.snapshot_error_with_player(initial.level, initial.player).is_empty(), "actual completed production codec validates the genuine initial full packet"): return false
	if not _expect(level.scene_file_path == ART_SCENE and not level.is_completed() and _game.player.get_world_action_records().is_empty(), "entry is actual authored scene with no fabricated live progression/actions"): return false
	_game.resume_campaign()
	await _art_settle(12)
	var required: Array = level.camera_framing_points()
	if required.is_empty(): required = _game.player_camera_framing_points()
	return await _art_capture("production-entry", "actual initial production L5 through public Shell Continue", required, {"actual_level_state": _art_encode(level.call("encounter_state")), "live_actions": [], "earned_host_coda": false})

func _art_open(scene: String, suffix: String) -> bool:
	var raw: Dictionary = JSON.parse_string(_canonical)
	for info: Dictionary in raw.levels:
		if info.id == "A2-L5":
			info.scene_path = scene; info.readiness = "accepted"
			info.accepted_commit = "b".repeat(40); info.api_revision = Registry.API_REVISION
	var registry: CinderCampaignRegistry = Registry.new(raw)
	if not _expect(registry.last_error.is_empty() and registry.scene_error("A2-L5").is_empty(), "isolated TEST scene is a canonical native L5 constructor: " + registry.last_error): return false
	var preview: Node = MainScene.instantiate()
	preview.set_script(ProfileSeedGame)
	preview.set("test_profile_id", "standard")
	preview.set("level_scene_path", scene)
	root.add_child(preview)
	preview.call("resume_lab")
	for _tick: int in range(8): await _native_probe.tick_finished
	paused = true
	var hero: CinderPlayer = preview.get("player")
	var level: CinderLevel = preview.get("active_level")
	var camera: Camera3D = preview.get("camera")
	var anchor: Vector2 = preview.call("get_aim_anchor_normalized")
	var player: Dictionary = hero.snapshot_state()
	var local: Dictionary = level.snapshot_state()
	var packet: Dictionary = {"schema_version": 1, "level_id": "A2-L5", "scene_path": scene, "paused": true, "equipment_ids": hero.equipment.snapshot(), "player": player, "level": local, "shell": {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Vector3(0, 18, 13)), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}}
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var seed: Dictionary = model.state()
	seed.completed_main = ART_PREFIX.duplicate()
	seed.story = {"kind": "story", "level_id": "A2-L5", "snapshot": packet.duplicate(true), "checkpoint": packet.duplicate(true)}
	var store: CinderSaveStore = Store.new(ART_ROOT + suffix + "campaign.json")
	store.payload_validator = model.saved_payload_error
	var error: String = model.state_error(seed)
	var valid: bool = not player.is_empty() and not local.is_empty() and hero.equipment.snapshot() == _loadout and error.is_empty() and store.write_payload(seed)
	_expect(valid, "genuine initial full native packet and explicitly synthetic prior prefix persist through public Store: " + error + " / " + store.last_error)
	level.exit_level(); preview.free()
	if not valid: return false
	_game = Shell.new() as CinderCampaignShell
	if not _expect(_game.configure_runtime(raw, ART_ROOT + suffix + "campaign.json", ART_ROOT + suffix + "settings.json", ART_ROOT + suffix + "preferences.json"), "actual Shell uses isolated view save paths"): return false
	root.add_child(_game)
	await _art_settle(8)
	if not _expect(paused and _game.campaign_error.is_empty() and _game.menu.page_name() == "title", "actual Shell validates complete initial story at Title"): return false
	if not await _art_click("ContinueStoryButton"): return false
	return _expect(paused and _game.campaign_error.is_empty() and _game.active_level.scene_file_path == scene and _game.player.presentation_id == "act2_survivor", "actual GUI Continue quietly installs correct production/test recipient and shared Act2 Hero")

func _art_components() -> bool:
	if not await _art_open(ART_COMPONENT, "component/"): return false
	_game.resume_campaign()
	# Nested actual production scene is native geometry/scenery construction
	# only, never entered or given invented host stage/Player/parent state.
	var geometry: CinderLevel = _game.active_level.get_node("ActualProductionGeometry")
	var scenery: Node3D = geometry.get_node("DeadLondonScenery")
	_art_kit = {"root": scenery, "survivor": scenery.get_node("QuietSurvivor"), "corpse_piles": [scenery.get_node("DeadRoundMartian_0"), scenery.get_node("DeadRoundMartian_1")], "inert_machines": [scenery.get_node("InertThreeLegMachine_0"), scenery.get_node("InertThreeLegMachine_1")]}
	await _art_settle(12)
	if not _expect(geometry.get_script() == ProductionHost and geometry.hero == null and geometry.effects == null and geometry.shared_shell == null and ProductionHost.APRON_HERO_BOUNDS.has_point(ArtGeometry.planar(_game.player.global_position)) and _game.player.hp == _game.player.max_hp, "component has actual production geometry and an authored supported local spawn; no host stage or live transform seed"): return false
	_art_bait = ArtBait.new()
	if not _expect(bool(_art_bait.call("bind", _game.player)) and bool(_art_bait.call("begin_boundary", "sentry-entry")), "native bait starts only at actual supported local floor"): return false
	_art_action_observer = func(record: Dictionary) -> void:
		_art_records.append(record.duplicate(true))
		_expect(bool(_art_bait.call("observe_record", record)), "actual contiguous completed controller receipt reaches bait")
	_game.player.world_action_executed.connect(_art_action_observer)
	# Retain both actual collision-shortened receipts, then approach the real
	# low brace again. The latest completed landing is the genuine ray bait.
	if not await _art_dash(Vector3.FORWARD) or not await _art_dash(Vector3.BACK) or not await _art_dash(Vector3.FORWARD): return false
	# Ordinary rendered follow frames precede construction of the encounter;
	# neither an attack clock nor camera/hero/source state is advanced by hand.
	await _art_settle(12)
	var floors: Dictionary = geometry.call("floor_bindings")
	if not _expect(floors.size() == ProductionHost.FLOORS.size() and floors.has("sentry-apron") and ProductionHost.APRON_HERO_BOUNDS.has_point(ArtGeometry.planar(_game.player.global_position)), "actual production native floor map and completed collision-shortened bait stay within authored apron"): return false
	_art_scheduler = ArtScheduler.new()
	_art_scheduler.name = "OneActualProductionViewScheduler"
	_game.world.add_child(_art_scheduler)
	if not _expect(_art_scheduler.begin_encounter("standard", "TEST:A2-L5:production-view", 1), "one real Standard source epoch begins without clock seed"): return false
	var dirs: Array[Vector3] = []
	for index: int in range(16): dirs.append(Vector3(sin(TAU * float(index) / 16.0), 0, cos(TAU * float(index) / 16.0)).normalized())
	var context: Dictionary = {"encounter_id": "TEST:A2-L5:production-view", "world_revision": 1, "recognition_s": 0.30, "attack_input_margin_s": 0.03, "escape_directions": dirs.duplicate(), "return_directions": dirs.duplicate(), "floor_regions": floors.values()}
	_art_parent = ArtParent.new() as Node3D
	_art_parent.name = "ActualPresentedSentryComponent"
	_game.world.add_child(_art_parent)
	_art_parent.connect("runtime_failed", func(reason: String) -> void: _art_parent_errors.append(reason))
	if not _expect(bool(_art_parent.call("configure", _game.player, _game.fx, _art_scheduler, _art_bait, _game.world, floors, context, JOINT_AT, FOOT_AT, Callable(self, "_art_guard"))), "actual production factory attaches one independently moving native Foot at(.65,0,-.95)"): return false
	var bindings: Dictionary = {"world_root": _game.world, "owners": _art_parent.call("owners"), "floors": floors}
	if not _expect(bool(_art_parent.call("bind_transport_scope", bindings)) and bool(_art_parent.call("start")), "persistent native production parent binds whole component scope and starts publicly"): return false
	var ray: Node3D = _art_parent.call("get_ray")
	if not await _art_until_phase(ray, "lock"): return false
	var current: Dictionary = ray.call("state")
	if not _expect(current.armed and current.proof_available and current.proof.accepted and current.bait_sample.dash_sequence > 0, "actual lock contains genuine latest completed bait and public response proof"): return false
	if not _expect(_art_primary_proof(current.proof), "actual production apron admits complete capsule-safe ordinary-primary escape/return at canonical no-ammo stats"): return false
	if not await _art_capture("direct-sentry-ray-lock", "actual presented component lock; no earned boss route", _art_component_points(), {"ray": _art_encode(current), "parent_stage": _art_parent.call("state").stage, "actual_bait": _art_bait.call("state")}): return false
	var escape: Dictionary = {}
	for segment: Dictionary in current.proof.path:
		if segment.kind == "escape_dash": escape = segment.duplicate(true); break
	if not _expect(not escape.is_empty() and ArtGeometry.finite_vector(escape.get("from")) and ArtGeometry.finite_vector(escape.get("to")), "actual immutable proof supplies the measured controller escape, never a fictional landing"): return false
	for _tick: int in range(MAX_ART_TICKS):
		if _art_scheduler.get_clock() >= float(escape.start_s): break
		await _art_step()
	if not await _art_dash((escape.to - escape.from).normalized()): return false
	var foot: CinderLaneMechanism = _art_parent.call("get_foot")
	if not await _art_until_phase(foot, "lock"): return false
	if not _expect(_art_parent_errors.is_empty() and _game.player.hp > 0.0, "real first Ray recovery leads to real Foot lock without seeded exposure/HP/phase"): return false
	var foot_proof: Dictionary = {}
	for row: Dictionary in _art_parent.call("state").accepted_cycles:
		if row.kind == "foot" and row.cycle == foot.state().cycle: foot_proof = row.proof.duplicate(true)
	if not _expect(_art_primary_proof(foot_proof), "actual production near-foot preview/start retains real ordinary-primary escape/return opening"): return false
	if not await _art_capture("direct-near-foot-lock", "actual independent near Foot lock following real Ray exposure; no first-pool defeat", _art_component_points(), {"foot": _art_encode(foot.state()), "parent_stage": _art_parent.call("state").stage, "joint": _art_parent.call("get_joint_cue").state()}): return false
	_art_cleanup_components()
	await _art_release_shell()
	# Independent actual construction at the authored redoubt contact side;
	# no opening of production gates or earned-host progression is claimed.
	if not await _art_open(ART_CODA_COMPONENT, "coda/"): return false
	_game.resume_campaign()
	var coda_geometry: CinderLevel = _game.active_level.get_node("ActualProductionGeometry")
	var coda_scenery: Node3D = coda_geometry.get_node("DeadLondonScenery")
	_art_kit = {"root": coda_scenery, "survivor": coda_scenery.get_node("QuietSurvivor"), "corpse_piles": [coda_scenery.get_node("DeadRoundMartian_0"), coda_scenery.get_node("DeadRoundMartian_1")], "inert_machines": [coda_scenery.get_node("InertThreeLegMachine_0"), coda_scenery.get_node("InertThreeLegMachine_1")]}
	await _art_settle(12)
	if not await _art_dash(Vector3.FORWARD) or not await _art_dash(Vector3.LEFT): return false
	await _art_settle(12)
	if not _expect(_game.player.global_position.z <= -36.0 and not _game.active_level.is_completed(), "ordinary controller dashes reach directly constructed inert scenery, not a forged host coda stage"): return false
	var coda_points: Array[Vector3] = []
	coda_points.assign(_game.player_camera_framing_points())
	coda_points.append_array(_art_mesh_bounds(_art_kit.corpse_piles[0]))
	return await _art_capture("direct-inert-coda", "one actual rounded Martian corpse and permanently inert kit context; no earned stage/survivor projection", coda_points, {"host_stage_credit": false, "selected_full_coda_prop": str(_art_kit.corpse_piles[0].get_path()), "kit_art_revision": _art_kit.root.get_meta("art_revision"), "corpse_piles": _art_node_evidence(_art_kit.corpse_piles), "inert_machines": _art_node_evidence(_art_kit.inert_machines), "survivor_visible": _art_kit.survivor.visible})

func _art_primary_proof(proof: Dictionary) -> bool:
	if proof.get("accepted") != true or proof.get("uses_blast") != false or proof.get("uses_invulnerability") != false or not proof.get("path") is Array or proof.path.is_empty() or not ArtGeometry.finite_vector(proof.get("landing")) or not ArtGeometry.finite_vector(proof.get("attack_position")): return false
	if not ProductionHost.APRON_HERO_BOUNDS.has_point(ArtGeometry.planar(proof.landing)) or not ProductionHost.APRON_HERO_BOUNDS.has_point(ArtGeometry.planar(proof.attack_position)): return false
	var escape: bool = false
	var primary: bool = false
	var stats: Dictionary = _game.player.get_threat_response_state().stats
	for segment: Dictionary in proof.path:
		if segment.kind == "escape_dash": escape = true
		if segment.kind == "ordinary_primary":
			primary = segment.from == segment.to and segment.start_s == proof.primary_time_s and segment.end_s == proof.response_complete_s and proof.response_complete_s == proof.primary_time_s + float(stats.primary_cooldown)
	return escape and primary and ArtGeometry.planar(proof.attack_position - JOINT_AT).length() <= float(stats.primary_range) + .00001

func _art_component_points(proposed: Dictionary = {}) -> Array[Vector3]:
	var points: Array[Vector3] = []
	if not is_instance_valid(_art_parent) or not is_instance_valid(_game): return points
	var actor: Variant = _art_parent.call("get_actor")
	if not is_instance_valid(actor) or not actor.is_inside_tree() or actor.is_queued_for_deletion(): return []
	var rig: Node3D = actor.call("get_cosmetic_rig")
	var foot: CinderLaneMechanism = _art_parent.call("get_foot")
	var visual: Node3D = foot.get_node_or_null("InheritedGreyboxGiantFoot")
	for node: Variant in [actor, rig, foot, visual, _art_parent.call("get_joint_cue")]:
		if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion() or not node.is_visible_in_tree(): return []
	for node: Node3D in rig.call("required_source_nodes"): points.append_array(_art_mesh_bounds(node))
	points.append_array(_art_mesh_bounds(visual))
	points.append_array(_game.player_camera_framing_points())
	for current: Dictionary in [(_art_parent.call("get_ray") as Node3D).call("state"), foot.state(), proposed.get("ray", {})]:
		var shape: Dictionary = current.get("geometry", current.get("exchange", {}).get("geometry", {}))
		if not shape.is_empty():
			if not ArtGeometry.error(shape).is_empty(): return []
			var centers: Array[Vector3] = []
			if shape.kind == "lane": centers.assign([shape["from"], shape["to"]])
			elif shape.kind == "circle": centers.append(shape.origin)
			else: return []
			for center: Vector3 in centers:
				for x: float in [-float(shape.radius), float(shape.radius)]:
					for z: float in [-float(shape.radius), float(shape.radius)]: points.append(center + Vector3(x, 0.03, z))
		var witness: Dictionary = current.get("proof", {}) if current.get("proof_available", false) else current.get("presentation_witness", {})
		for key: String in ["landing", "attack_position"]:
			if witness.has(key):
				if not ArtGeometry.finite_vector(witness[key]): return []
				for point: Vector3 in _game.player_camera_framing_points(): points.append(point + witness[key] - _game.player.global_position)
	var preview: Dictionary = proposed.get("foot_preview", {})
	if not preview.is_empty():
		if preview.get("accepted") != true or not preview.get("proof") is Dictionary or not preview.get("candidate") is Dictionary: return []
		var shape: Dictionary = preview.candidate.geometry
		if not ArtGeometry.error(shape).is_empty() or shape.kind != "circle": return []
		for x: float in [-float(shape.radius), float(shape.radius)]:
			for z: float in [-float(shape.radius), float(shape.radius)]: points.append(shape.origin + Vector3(x, 0.03, z))
		for key: String in ["landing", "attack_position"]:
			if not ArtGeometry.finite_vector(preview.proof.get(key)): return []
			for point: Vector3 in _game.player_camera_framing_points(): points.append(point + preview.proof[key] - _game.player.global_position)
	var foot_state: Dictionary = foot.state()
	if foot_state.status == "running":
		var found: bool = false
		for row: Dictionary in _art_parent.call("state").accepted_cycles:
			if row.kind != "foot" or row.cycle != foot_state.cycle: continue
			if row.admitted_exchange.id != foot_state.reservation_id or row.admitted_exchange.geometry != foot_state.geometry or row.proof.get("accepted") != true: return []
			found = true
			for key: String in ["landing", "attack_position"]:
				if not ArtGeometry.finite_vector(row.proof.get(key)): return []
				for point: Vector3 in _game.player_camera_framing_points(): points.append(point + row.proof[key] - _game.player.global_position)
			break
		# Foot.start publishes before parent appends its accepted-cycle diagnostic.
		# Retain only the actual earlier preview matched to this immutable cycle.
		if not found:
			if _art_foot_view.get("owner") != foot or _art_foot_view.get("cycle") != foot_state.cycle or _art_foot_view.get("geometry") != foot_state.geometry or _art_foot_view.get("source_position") != foot.global_position or _art_foot_view.get("opening_position") != actor.global_position: return []
			for key: String in ["landing", "attack_position"]:
				if not ArtGeometry.finite_vector(_art_foot_view.get(key)): return []
				for point: Vector3 in _game.player_camera_framing_points(): points.append(point + _art_foot_view[key] - _game.player.global_position)
	for cue: Node3D in [(_art_parent.call("get_ray") as Node3D).call("get_cue"), foot.get_cue(), _art_parent.call("get_joint_cue")]:
		if not is_instance_valid(cue) or not cue.is_inside_tree() or cue.is_queued_for_deletion() or not cue.is_visible_in_tree(): return []
		points.append_array(_art_mesh_bounds(cue))
	return points

func _art_guard(proposed: Dictionary) -> bool:
	var points: Array[Vector3] = _art_component_points(proposed)
	if points.is_empty() or not _game.camera_framing_error(points).is_empty(): return false
	# Same public current projection after translating the complete required
	# union into the shared ordinary settled-follow relative frame. No camera
	# repair, private projection copy or gameplay authority from future fit.
	var delta: Vector3 = _game.player.global_position + Vector3.UP * .75 + Vector3(0, 18, 13) - _game.camera.global_position
	var shifted: Array[Vector3] = []
	for point: Vector3 in points: shifted.append(point - delta)
	if not _game.camera_framing_error(shifted).is_empty(): return false
	var preview: Dictionary = proposed.get("foot_preview", {})
	if not preview.is_empty():
		var foot: CinderLaneMechanism = _art_parent.call("get_foot")
		_art_foot_view = {"owner": foot, "cycle": int(foot.state().cycle) + 1, "geometry": preview.candidate.geometry.duplicate(true), "source_position": preview.candidate.source_position, "opening_position": preview.candidate.opening_position, "landing": preview.proof.landing, "attack_position": preview.proof.attack_position}
	return true

func _art_capture(label: String, scope: String, required: Array, details: Dictionary) -> bool:
	if not _expect(not paused and is_instance_valid(_game) and _game.player.hp > 0.0 and _game.camera.size == Vector2(7.2, 0).x and _game.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "actual shared living Hero/follow/camera before view: " + label): return false
	if not _expect(not required.is_empty() and _game.camera_framing_error(required).is_empty(), "current native required source/footprint/Hero/accepted witness union fits before draw: " + label): return false
	await RenderingServer.frame_post_draw
	if label.begins_with("direct-sentry") and (_art_parent.call("get_ray") as Node3D).call("state").phase != "lock": return _expect(false, "postdraw retains actual Ray lock, never mislabeled image")
	if label.begins_with("direct-near") and (_art_parent.call("get_foot") as CinderLaneMechanism).state().phase != "lock": return _expect(false, "postdraw retains actual Foot lock, never mislabeled image")
	if label in ["direct-sentry-ray-lock", "direct-near-foot-lock"]: required = _art_component_points()
	if not _expect(not paused and not required.is_empty() and _game.camera_framing_error(required).is_empty(), "postdraw current required native union remains contained: " + label): return false
	var image: Image = root.get_texture().get_image()
	var path: String = ART_CAPTURE + label + ".png"
	if not _expect(image != null and image.get_size() == Vector2i(540, 1170) and image.save_png(path) == OK, "save actual graphical 540x1170 pixels: " + label): return false
	var safe: Rect2 = _game.hud.combat_safe_rect()
	_art_frames.append({"label": label, "scope": scope, "image_path": path, "image_sha256": FileAccess.get_sha256(path), "details_before_draw": details, "actual_component_after_draw": _art_encode(_art_parent.call("state")) if is_instance_valid(_art_parent) else {}, "required_native_points": _art_encode(required), "required_camera_error": _game.camera_framing_error(required), "hero": {"position": Codec.vector3(_game.player.global_position), "hp": _game.player.hp, "equipment_ids": _game.player.equipment.snapshot(), "presentation_id": _game.player.presentation_id}, "camera": {"position": Codec.vector3(_game.camera.global_position), "basis": _art_encode(_game.camera.global_basis), "size": _game.camera.size}, "hud_safe_rect": {"position": [safe.position.x, safe.position.y], "size": [safe.size.x, safe.size.y]}, "native_component_clock": _art_scheduler.get_clock() if is_instance_valid(_art_scheduler) else null, "world_actions": _art_encode(_game.player.get_world_action_records()), "pixel_readability_accepted": false})
	return true

func _art_dash(direction: Vector3) -> bool:
	for _tick: int in range(MAX_ART_TICKS):
		var response: Dictionary = _game.player.get_threat_response_state()
		if not _game.player.dead and response.stable and response.motion.grounded and not _game.player.action_in_progress() and float(response.dash_cooldown_left_s) <= 0.0: break
		await _art_step()
	var before: Array[Dictionary] = _game.player.get_world_action_records()
	var sequence: int = int(before.back().sequence) if not before.is_empty() else 0
	if not _expect(_game.player.request_dash(direction), "actual shared controller admits ordinary dash"): return false
	for _tick: int in range(MAX_ART_TICKS):
		await _art_step()
		var records: Array[Dictionary] = _game.player.get_world_action_records()
		if not records.is_empty() and int(records.back().sequence) > sequence:
			return _expect(records.back().kind == "dash" and records.back().landing == _game.player.global_position and not _game.player.action_in_progress(), "genuine completed world-space landing follows native deliberate stop")
	return _expect(false, "bounded native dash completion, no timestamp/motion seed")

func _art_until_phase(consumer: Node3D, phase: String) -> bool:
	for _tick: int in range(MAX_ART_TICKS):
		var current: Dictionary = consumer.call("state")
		if current.status == "running" and current.phase == phase: return true
		if not _art_parent_errors.is_empty() or _game.player.dead or paused: break
		await _art_step()
	return _expect(false, "bounded actual " + phase + " publication: " + str(consumer.call("state")) + " / " + str(_art_parent_errors))

func _art_step() -> void:
	await _native_probe.tick_finished
	if is_instance_valid(_art_parent):
		var native_body: Array[Vector3] = []
		native_body.assign(_game.player_camera_framing_points())
		var actor: Node3D = _art_parent.call("get_actor")
		actor.call("get_cosmetic_rig").call("apply_readability", _game.camera, native_body)
		(_art_parent.call("get_foot") as Node3D).get_node("InheritedGreyboxGiantFoot").call("apply_readability", _game.camera, native_body)

func _art_settle(frames: int) -> void:
	for _frame: int in range(frames): await process_frame

func _art_mesh_bounds(node: Node) -> Array[Vector3]:
	var result: Array[Vector3] = []
	if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion(): return result
	if node is MeshInstance3D and node.is_visible_in_tree() and is_instance_valid(node.mesh):
		for index: int in range(8): result.append(node.global_transform * node.mesh.get_aabb().get_endpoint(index))
	for child: Node in node.get_children(): result.append_array(_art_mesh_bounds(child))
	if result.is_empty(): return result
	var bounds := AABB(result[0], Vector3.ZERO)
	for point: Vector3 in result: bounds = bounds.expand(point)
	result.clear()
	for index: int in range(8): result.append(bounds.get_endpoint(index))
	return result

func _art_node_evidence(nodes: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node: Node3D in nodes: result.append({"path": str(node.get_path()), "position": Codec.vector3(node.global_position), "visible": node.is_visible_in_tree(), "full_mesh_bounds": _art_encode(_art_mesh_bounds(node)), "scenery_only": node.get_meta("scenery_only", false)})
	return result

func _art_encode(value: Variant) -> Variant:
	if value is Vector3: return Codec.vector3(value)
	if value is Basis: return {"x": Codec.vector3(value.x), "y": Codec.vector3(value.y), "z": Codec.vector3(value.z)}
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[key] = _art_encode(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_art_encode(item))
		return result
	if value is int and abs(value) > 9007199254740991: return {"diagnostic_native_integer_decimal": str(value)}
	return value

func _art_sources() -> Dictionary:
	var result: Dictionary = {}
	for path: String in [ART_SCENE, ART_COMPONENT, ART_CODA_COMPONENT, "res://scripts/acts/act2/dead_london.gd", "res://scripts/acts/act2/dead_london_kit.gd", "res://scripts/acts/act2/dead_london_sentry_presented_actor.gd", "res://scripts/acts/act2/dead_london_sentry_presented_encounter.gd", "res://scripts/acts/act2/dead_london_sentry_visual.gd", "res://scripts/combat/lane_mechanism.gd", "res://scripts/campaign/shell.gd", "res://scripts/game.gd"]: result[path] = FileAccess.get_sha256(path)
	return result

func _art_cleanup_components() -> void:
	if is_instance_valid(_game) and _art_action_observer.is_valid() and _game.player.world_action_executed.is_connected(_art_action_observer): _game.player.world_action_executed.disconnect(_art_action_observer)
	_art_action_observer = Callable()
	_art_foot_view.clear()
	if is_instance_valid(_art_parent): _art_parent.call("cleanup"); _art_parent.free()
	_art_parent = null
	if is_instance_valid(_art_scheduler): _art_scheduler.end_encounter("production_art_fixture_cleanup"); _art_scheduler.free()
	_art_scheduler = null
	if is_instance_valid(_art_bait): _art_bait.call("release")
	_art_bait = null

func _art_release_shell() -> void:
	if not is_instance_valid(_game): return
	var refs: Array[WeakRef] = []
	_art_collect_refs(_game, refs)
	_release_fixture_shell(_game)
	_game = null
	await _art_settle(8)
	for ref: WeakRef in refs: _expect(ref.get_ref() == null, "whole native Shell/World/Hero/HUD/props cleanup")

func _art_collect_refs(node: Node, refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child: Node in node.get_children(): _art_collect_refs(child, refs)

func _art_clean_user() -> void:
	for suffix: String in ["entry/", "component/", "coda/"]:
		for name: String in ["campaign.json", "campaign.json.bak", "settings.json", "settings.json.bak", "preferences.json", "preferences.json.bak"]:
			var path: String = ART_ROOT + suffix + name
			if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _art_click(name: String) -> bool:
	await _art_settle(8)
	var button: Button = _game.menu.find_child(name, true, false) as Button
	if not _expect(is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled, "real enabled GUI control: " + name): return false
	var cursor: Node = button.get_parent()
	while cursor != null:
		if cursor is ScrollContainer: (cursor as ScrollContainer).ensure_control_visible(button)
		cursor = cursor.get_parent()
	await _art_settle(8)
	var at: Vector2 = button.get_global_rect().get_center()
	if not _expect(root.get_visible_rect().has_point(at), "actual GUI center lies in native viewport"): return false
	cursor = button.get_parent()
	while cursor != null:
		if cursor is Control and cursor.clip_contents and not cursor.get_global_rect().has_point(at): return _expect(false, "actual GUI center clears all clipping ancestors")
		cursor = cursor.get_parent()
	var pressed: Array[String] = []
	button.pressed.connect(func() -> void: pressed.append(name))
	var motion := InputEventMouseMotion.new(); motion.position = at; motion.global_position = at
	root.push_input(motion, true)
	var press := InputEventMouseButton.new(); press.button_index = MOUSE_BUTTON_LEFT; press.position = at; press.global_position = at; press.pressed = true
	root.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton; release.pressed = false
	root.push_input(release, true)
	await _art_settle(8)
	return _expect(pressed == [name] and _game.campaign_error.is_empty(), "exact one real GUI press without campaign error: " + name + " / " + _game.campaign_error)
