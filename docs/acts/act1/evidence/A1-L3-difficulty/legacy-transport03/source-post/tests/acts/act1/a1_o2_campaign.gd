extends SceneTree
## SOURCE ONLY until Root reviews, promotes, imports and runs this fixture.
## Production Shell; one O2-only in-memory TEST registry row and isolated stores.
## TEST completed [L1,L2,L3] unlock prefix and actual-floor Hero placement earn
## no route, recognition or OS GUI-input credit. The actual RetryButton public
## pressed signal is exercised; no private Shell/level save/restore entry is used.
## Whole snapshots come only from normal paused Shell capture. Native clocks,
## actor HP/phases, field supply, consumer records and proofs are never assigned.

const Shell = preload("res://scripts/campaign/shell.gd")
const Registry = preload("res://scripts/campaign/registry.gd")
const Attempts = preload("res://scripts/campaign/attempts.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Equipment = preload("res://scripts/equipment.gd")
const MainScene = preload("res://scenes/main.tscn")
const Bloom = preload("res://scripts/acts/act1/spore_bloom_layout.gd")
const BloomCodec = preload("res://scripts/acts/act1/spore_bloom_codec.gd")
const BloomScript = preload("res://scripts/acts/act1/spore_bloom.gd")
const Actor = preload("res://scripts/acts/act1/mushroom_selenite.gd")
const Field = preload("res://scripts/environment/spore_field.gd")
const Repulsion = preload("res://scripts/environment/spore_repulsion.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Threat = preload("res://scripts/cues/threat_cue.gd")
const Interaction = preload("res://scripts/cues/interaction_cue.gd")
const O2_PATH: String = "res://scenes/acts/act1/a1_o2.tscn"
const STORY_PATH: String = "res://scenes/acts/act1/a1_l3.tscn"
const PREFIX: Array[String] = ["A1-L1", "A1-L2", "A1-L3"]
const REWARD_ID: String = "A1-O2-completion-stamp"
const WATCHDOG_MS: int = 120000
const TEST_POSITION: Vector3 = Vector3(0, 0.005, 1.95)

var game: CinderCampaignShell
var preview: Node
var raw: Dictionary = {}
var registry_bytes: PackedByteArray
var test_root: String
var report_path: String
var checks: int = 0
var failures: int = 0
var first_failure: Dictionary = {}
var started_ms: int = 0
var finishing: bool = false
var operation: String = "source setup"
var observations: Array[Dictionary] = []
var operation_wait_overruns: Array[Dictionary] = []
var receipts: Array[Dictionary] = []
var setups: Array[Dictionary] = []
var protected_story: Dictionary = {}
var unlocked_before: Array = []
var entrance: Dictionary = {}
var initial_hp: float
var source_hp: Dictionary = {}
var old_fps: int
var old_audio: AudioBusLayout


func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	test_root = "user://test-act1-o2-campaign-%d-%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	report_path = "res://.cinder/a1-o2-campaign-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	old_fps = Engine.max_fps
	old_audio = AudioServer.generate_bus_layout()
	process_frame.connect(_watchdog)
	node_added.connect(_observe_added)
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(540, 1170)
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--level-scene") or argument in ["--capture", "--capture-polish"]:
			_expect(false, "campaign fixture requires production Shell rather than preview arguments"); await _finish(); return
	registry_bytes = FileAccess.get_file_as_bytes(Registry.DATA_PATH)
	var parsed: Variant = JSON.parse_string(registry_bytes.get_string_from_utf8())
	if not _expect(parsed is Dictionary and parsed.get("levels") is Array, "canonical registry supplies the isolated TEST clone"):
		await _finish(); return
	raw = parsed.duplicate(true)
	var changed: int = 0
	for row: Dictionary in raw.levels:
		if row.id == Bloom.LEVEL_ID:
			setups.append({"kind": "TEST in-memory O2 row only", "before": row.duplicate(true), "scene_path": O2_PATH, "accepted_commit": "f".repeat(40)})
			row.scene_path = O2_PATH; row.readiness = "accepted"; row.accepted_commit = "f".repeat(40); row.api_revision = Registry.API_REVISION
			changed += 1
	var registry: CinderCampaignRegistry = Registry.new(raw)
	if not _expect(changed == 1 and registry.last_error.is_empty() and registry.scene_error(Bloom.LEVEL_ID).is_empty() and registry.scene_error("A1-L3").is_empty(), "only O2 readiness is TEST enabled; native accepted L3 Story stays unchanged"):
		await _finish(); return
	var entry: Dictionary = registry.entry(Bloom.LEVEL_ID)
	if not _expect(entry.parent_level_id == "A1-L3" and not registry.is_unlocked(Bloom.LEVEL_ID, ["A1-L1", "A1-L2"]) and registry.is_unlocked(Bloom.LEVEL_ID, PREFIX) and entry.reward_id == REWARD_ID and entry.reward_policy == "once_only_completion_stamp_no_stat_growth", "canonical L3 parent unlock and existing once-only stamp policy govern O2"):
		await _finish(); return
	if not await _seed_story(registry) or not await _new_shell(): await _finish(); return
	operation = "public Continue Story"
	game.menu.continue_story_requested.emit()
	if not await _await_operation(func() -> bool: return _live("A1-L3") and paused and game.menu.page_name() == "resume", "public Continue installs actual protected L3 Story", 12.0):
		await _finish(); return
	protected_story = game.attempts.state().story.duplicate(true)
	unlocked_before = game.attempts.state().unlocked_equipment.duplicate()
	if not _expect(_same(game.capture_campaign_snapshot(), protected_story.snapshot) and game.attempts.state().completed_main == PREFIX and _durable(), "actual pristine whole L3 unit is protected under the disclosed TEST unlock prefix"):
		await _finish(); return
	operation = "public Optional entry"
	game.menu.optional_requested.emit(Bloom.LEVEL_ID)
	if not await _await_operation(func() -> bool: return _live(Bloom.LEVEL_ID) and paused and game.menu.page_name() == "resume" and game.attempts.active_kind() == "optional", "public Optional installs O2 as an independent side attempt", 12.0):
		await _finish(); return
	entrance = game.capture_campaign_snapshot()
	if not _expect(_pristine(entrance) and _same(game.attempts.state().side_attempt.checkpoint, entrance) and _same(game.attempts.state().story, protected_story) and _bindings() and _durable(), "actual whole pristine O2 entrance is its earlier checkpoint and protects complete Story"):
		await _finish(); return
	initial_hp = game.player.hp
	for id: String in Bloom.SOURCE_IDS: source_hp[id] = _source(id).hp
	receipts.append({"label": "actual pristine optional entrance", "exact_snapshot": Exact.stringify(entrance), "exact_protected_story": Exact.stringify(protected_story), "exact_attempts": Exact.stringify(game.attempts.state()), "saved_envelope_json": FileAccess.get_file_as_string(test_root + "campaign.json"), "native_identities": _ids(), "native_bindings": _encode(_native_bindings_readback())})
	# Save from the supported public paused operation; do not privately call the
	# Store or level restore once the real optional attempt exists.
	if not await _pause("pristine entrance Save"): await _finish(); return
	var saved_entrance: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_same(saved_entrance, entrance), "public pristine Save preserves the exact original entrance unit"):
		await _finish(); return
	if not await _reopen_side(saved_entrance, "pristine entrance"): await _finish(); return
	game.player.global_position = TEST_POSITION; game.player.velocity = Vector3.ZERO
	setups.append({"kind": "TEST same-floor Hero placement/zero velocity, no earned route", "position": _encode(TEST_POSITION)})
	if not await _resume("actual first approach") or not await _wait_live(func() -> bool: return game.active_level.call("bloom_state").room_stage == "active", "genuine settled first approach", 15.0):
		await _finish(); return
	if not _expect(_field() != null and _consumer() != null and _field().state().generation == 0 and _field().state().remaining_clusters == 2 and _bindings(), "actual first epoch binds original near Field and first native coordinator with both supplies"):
		await _finish(); return
	if not await _wait_live(_native_entry, "genuine native C31 lunge enters the actual near domain", 16.0): await _finish(); return
	if not _release_primary(): await _finish(); return
	# Observe actual route elapsed time after release; no phase, position, record,
	# clock or witness is seeded. Pause is requested outside native callbacks.
	if not await _wait_live(_live_reaction, "actual active Field and native partial outward retreat", 3.0): await _finish(); return
	if not await _pause("real partial active-field Save"): await _finish(); return
	var partial: Dictionary = game.capture_campaign_snapshot()
	if not _expect(_partial(partial) and _same(game.attempts.state().side_attempt.checkpoint, entrance) and _same(game.attempts.state().story, protected_story) and _durable(), "public Save retains the whole real partial Field/source/consumer/Scheduler/proof unit with original HP and earlier checkpoint"):
		await _finish(); return
	receipts.append({"label": "actual first near-field partial Save", "exact_snapshot": Exact.stringify(partial), "exact_earlier_checkpoint": Exact.stringify(entrance), "exact_attempts": Exact.stringify(game.attempts.state()), "saved_envelope_json": FileAccess.get_file_as_string(test_root + "campaign.json"), "native_bindings": _encode(_native_bindings_readback()), "native_state": _encode(_native_readback())})
	if not await _reopen_side(partial, "actual partial native near-field unit"): await _finish(); return
	if not _expect(_partial(game.capture_campaign_snapshot()) and _healthy(), "fresh recipient retains original HP, native clock/deadline/spent supply and complete partial route without replay"):
		await _finish(); return
	# Actual production pause page owns this real Button and callback. Activating
	# its public pressed signal covers the GUI-to-Shell wiring, not an OS click.
	if not await _pause("expose actual RetryButton from paused Continue") or not await _retry_entrance(): await _finish(); return
	var optional_refs: Array[WeakRef] = _refs(game.world)
	operation = "public uncompleted Optional Leave"
	game.menu.leave_side_requested.emit()
	if not await _await_operation(func() -> bool: return _live("A1-L3") and paused and game.attempts.active_kind() == "story" and game.menu.page_name() == "journey", "public Leave restores the protected Story", 12.0):
		await _finish(); return
	_expect(_freed(optional_refs) and _same(game.attempts.state().story, protected_story) and _same(game.capture_campaign_snapshot(), protected_story.snapshot) and game.attempts.state().completed_main == PREFIX and game.attempts.state().completed_optional.is_empty() and game.attempts.state().reward_ids.is_empty() and game.attempts.state().unlocked_equipment == unlocked_before and _durable(), "normal uncompleted Leave frees O2 and preserves exact Story without completion, reward or equipment growth")
	await _finish()


func _pristine(unit: Dictionary) -> bool:
	if not _closed(unit): return false
	var local: Dictionary = unit.level.local
	if not BloomCodec.metadata_error(local).is_empty() or local.beat_index != 0 or local.room_stage != "approach" or not local.completed_beats.is_empty() or local.checkpoint_published or local.scheduler.clock_s != 0.0 or not local.scheduler.reservations.is_empty() or not local.installed_consumers.is_empty() or not unit.level.progress.checkpoint_ids.is_empty() or unit.level.progress.completed: return false
	if Codec.read_vector3(unit.player.motion.position) != Bloom.SPAWN: return false
	for id: String in Bloom.SOURCE_IDS:
		var actor: Dictionary = local.sources[id]
		if not actor.dormant or actor.dead or actor.hp != (24.0 if id == "bloom-final-guard" else 16.0): return false
	for id: String in Bloom.FIELD_IDS:
		if local.fields[id] != null: return false
	for id: String in Bloom.CONSUMER_IDS:
		if local.consumers[id] != null: return false
	return true


func _partial(unit: Dictionary) -> bool:
	if not _closed(unit) or not _healthy(): return false
	var local: Dictionary = unit.level.local
	if not BloomCodec.metadata_error(local).is_empty() or local.beat_index != 0 or local.room_stage != "active" or local.activated_source_ids != Bloom.group_ids(0) or local.installed_consumers != [Bloom.consumer_id(0)] or local.checkpoint_published or local.scheduler.encounter_id != Bloom.epoch_id(0) or unit.level.progress.completed or not unit.level.progress.checkpoint_ids.is_empty(): return false
	var field: Dictionary = local.fields["bloom-near"]
	var consumer: Dictionary = local.consumers[Bloom.consumer_id(0)]
	if field.schema_version != 1 or field.phase not in ["active", "thinning"] or field.generation != 1 or field.spent_ids != ["cluster-right"] or field.deadline_s != field.activation_s + Bloom.FIELD_DURATION_S or not field.clock_s > field.activation_s or not field.clock_s < field.deadline_s or local.fields["bloom-far"] != null or consumer.schema_version != 2 or consumer.records.is_empty() or not consumer.failures.is_empty(): return false
	var partial_route: bool = false
	for record: Dictionary in consumer.records.values():
		if record.get("phase", "") != "retreat": continue
		# Serialized Consumer records retain the whole original Route1 envelope;
		# live consumer.source_state() below deliberately exposes flat state.
		var transport: Variant = record.get("route")
		if not transport is Dictionary or transport.get("api_revision") != "repulsion-route-1" or not transport.get("schema_version") is int or transport.schema_version != 1 or not transport.get("route") is Dictionary: continue
		var saved_route: Dictionary = transport.route
		if saved_route.get("elapsed_s") is float and saved_route.elapsed_s > 0.0: partial_route = true
	if not partial_route or local.consumers[Bloom.consumer_id(1)] != null or local.consumers[Bloom.consumer_id(2)] != null: return false
	for id: String in Bloom.SOURCE_IDS:
		var actor: Dictionary = local.sources[id]
		if actor.hp != source_hp[id] or actor.dead or actor.dormant != (id not in Bloom.group_ids(0)) or actor.schema_version not in ([3, 4] if id in Bloom.group_ids(0) else [1]): return false
	return _same(_field().snapshot_state(), field) and _same(game.player.snapshot_state(), unit.player) and _bindings()


func _release_primary() -> bool:
	var cluster := _field().get_node_or_null("cluster-right") as Node3D
	var aim: Vector3 = _aim(cluster)
	if not _expect(_primary_ready() and cluster != null and aim != Vector3.ZERO and cluster.is_in_group("environment_attack_targets"), "real ready primary has ordinary reach/cone/LOS to only the chosen original cluster"): return false
	var before: Dictionary = _field().state(); var sequence: int = _last_sequence(); var shells_before: int = game.player.shells
	var result: int = game.player.slash(aim)
	var actions: Array[Dictionary] = game.player.get_world_action_records(sequence)
	var after: Dictionary = _field().state()
	receipts.append({"label": "real public ordinary near-field release", "actual_hero_position": _encode(game.player.global_position), "actual_anchor_position": _encode(cluster.global_position), "supplied_aim": _encode(aim), "actions": _encode(actions), "field_before": before, "field_after": after})
	return _expect(result == 0 and actions.size() == 1 and actions[0].kind == "primary" and actions[0].origin == "player_direct" and actions[0].hits == 0 and actions[0].direction == Vector3(aim.x, 0, aim.z).normalized() and game.player.shells == shells_before and after.generation == 1 and after.spent_ids == ["cluster-right"] and after.phase == "releasing" and after.deadline_s == after.activation_s + Bloom.FIELD_DURATION_S and _healthy(), "one actual public ordinary primary consumes exactly one original harmless finite anchor without enemy hit or ammo cost")


func _native_entry() -> bool:
	if not _primary_ready() or _field() == null: return false
	for id: String in Bloom.group_ids(0):
		var actor: Act1MushroomSelenite = _source(id)
		var response: Dictionary = actor.get_spore_response_state()
		if actor.pure_presentation_state().phase == "active" and response.grounded and _distance(actor.global_position, _field().global_position) <= Bloom.FIELD_RADIUS + float(response.support_radius): return true
	return false


func _live_reaction() -> bool:
	if _field() == null or _consumer() == null or _field().state().phase != "active": return false
	for id: String in Bloom.group_ids(0):
		var response: Dictionary = _source(id).get_spore_response_state()
		var record: Dictionary = _consumer().source_state(id)
		if response.phase == "retreat" and response.velocity != Vector3.ZERO and not record.get("route", {}).is_empty() and record.route.elapsed_s > 0.0: return true
	return false


func _aim(cluster: Node3D) -> Vector3:
	if cluster == null: return Vector3.ZERO
	for index: int in range(360):
		var direction := Vector3(cos(TAU * index / 360.0), 0, sin(TAU * index / 360.0)).normalized()
		if not _reaches(cluster, direction): continue
		var clear: bool = true
		for id: String in Bloom.SOURCE_IDS:
			var actor: Act1MushroomSelenite = _source(id)
			if not actor.dormant and not actor.dead and _reaches(actor, direction): clear = false
		for id: String in Bloom.CLUSTER_IDS:
			var other := _field().get_node(id) as Node3D
			if other != cluster and _reaches(other, direction): clear = false
		if clear: return direction
	return Vector3.ZERO


func _reaches(target: Node3D, direction: Vector3) -> bool:
	var offset: Vector3 = target.global_position - game.player.global_position
	if absf(offset.y) > CinderPlayer.ATTACK_MAX_VERTICAL_DISTANCE: return false
	offset.y = 0.0
	var stats: Dictionary = game.player.equipment.resolved_stats()
	if offset.length() > float(stats.primary_range) or (offset.length() > CinderPlayer.ATTACK_ORIGIN_DISK_RADIUS and offset.normalized().dot(direction) < float(stats.primary_cone_min_dot)): return false
	var query := PhysicsRayQueryParameters3D.create(game.player.global_position + Vector3.UP * CinderPlayer.ATTACK_LOS_HEIGHT, target.global_position + Vector3.UP * CinderPlayer.ATTACK_LOS_HEIGHT, CinderPlayer.ATTACK_SCENERY_MASK)
	return game.player.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _primary_ready() -> bool:
	if paused or not _live(Bloom.LEVEL_ID) or game.player.dead: return false
	var state: Dictionary = game.player.get_threat_response_state()
	return state.stable and float(state.commitment_remaining_s) == 0.0 and float(state.primary_cooldown_left_s) == 0.0


func _distance(left: Vector3, right: Vector3) -> float:
	return Vector2(left.x - right.x, left.z - right.z).length()


func _healthy() -> bool:
	if not _live(Bloom.LEVEL_ID) or game.player.hp != initial_hp: return false
	for id: String in Bloom.SOURCE_IDS:
		if _source(id).hp != source_hp[id]: return false
	return true


func _source(id: String) -> Act1MushroomSelenite:
	return (game.active_level.get("sources") as Dictionary).get(id) as Act1MushroomSelenite


func _field() -> CinderSporeField:
	if not _live(Bloom.LEVEL_ID): return null
	return (game.active_level.get("_fields") as Dictionary).get("bloom-near") as CinderSporeField


func _consumer() -> CinderSporeRepulsion:
	if not _live(Bloom.LEVEL_ID): return null
	return (game.active_level.get("_consumers") as Dictionary).get(Bloom.consumer_id(0)) as CinderSporeRepulsion


func _scheduler() -> CinderThreatScheduler:
	return game.active_level.get("scheduler") as CinderThreatScheduler


func _bindings() -> bool:
	if not _live(Bloom.LEVEL_ID) or game.active_level.hero != game.player or game.active_level.shared_shell != game or _count_players(game.world) != 1: return false
	var bindings: Dictionary = game.active_level.call("scheduler_bindings")
	if bindings.world_root != game.world or game.player.get_world_3d() != game.active_level.get_world_3d(): return false
	for id: String in Bloom.SOURCE_IDS:
		var actor: Act1MushroomSelenite = _source(id)
		var native: Dictionary = actor.get_spore_native_bindings()
		if actor.get_parent() != game.active_level or actor.get_world_3d() != game.player.get_world_3d() or native.scheduler != _scheduler() or native.player != game.player: return false
	var fields: Dictionary = game.active_level.get("_fields")
	var consumers: Dictionary = game.active_level.get("_consumers")
	var protocols: Dictionary = game.active_level.get("_protocols")
	for id: String in fields:
		var field: CinderSporeField = fields[id]
		if field.get_parent() != game.active_level or field.get_world_3d() != game.player.get_world_3d() or not field.binding_error().is_empty(): return false
	for id: String in consumers:
		var consumer: CinderSporeRepulsion = consumers[id]
		if consumer.get_parent() != game.active_level or consumer.get_world_3d() != game.player.get_world_3d() or consumer.consumer_id() != id or not consumer.placement_accepted(): return false
		for source_id: String in protocols[id]:
			if not protocols[id][source_id].matches_source(_source(source_id), source_id) or not consumer.source_binding_matches(_source(source_id), source_id): return false
	return true


func _ids() -> Dictionary:
	if not _live(Bloom.LEVEL_ID): return {}
	var value: Dictionary = {"world": str(game.world.get_instance_id()), "native_world": str(game.world.get_world_3d().get_instance_id()), "player": str(game.player.get_instance_id()), "level": str(game.active_level.get_instance_id()), "scheduler": str(_scheduler().get_instance_id())}
	for id: String in Bloom.SOURCE_IDS:
		value[id] = str(_source(id).get_instance_id()); value[id + "/cue"] = str(_source(id).get_cue().get_instance_id())
	for id: String in (game.active_level.get("_fields") as Dictionary): value["field/" + id] = str((game.active_level.get("_fields") as Dictionary)[id].get_instance_id())
	for id: String in (game.active_level.get("_consumers") as Dictionary): value["consumer/" + id] = str((game.active_level.get("_consumers") as Dictionary)[id].get_instance_id())
	for id: String in (game.active_level.get("_protocols") as Dictionary):
		for source_id: String in (game.active_level.get("_protocols") as Dictionary)[id]: value["protocol/" + source_id] = str((game.active_level.get("_protocols") as Dictionary)[id][source_id].get_instance_id())
	return value


func _all_new(before: Dictionary, after: Dictionary) -> bool:
	if before.is_empty() or after.is_empty(): return false
	for key: String in ["world", "native_world", "player", "level", "scheduler"]:
		if not before.has(key) or not after.has(key) or before[key] == after[key]: return false
	for key: String in after:
		if before.has(key) and before[key] == after[key]: return false
	return true


func _retry_entrance() -> bool:
	var button := game.menu.find_child("RetryButton", true, false) as Button
	if not _expect(button != null and button.is_visible_in_tree() and not button.disabled and game.menu.page_name() == "pause", "actual production pause page exposes its enabled Retry Checkpoint button"): return false
	var before: Dictionary = _ids()
	var refs: Array[WeakRef] = _refs(game.world)
	operation = "actual pause RetryButton public pressed signal"
	button.pressed.emit()
	if not await _await_operation(func() -> bool: return _live(Bloom.LEVEL_ID) and paused and game.menu.page_name() == "resume" and _ids() != before, "actual RetryButton callback installs the earlier original entrance checkpoint", 12.0): return false
	var restored: Dictionary = game.capture_campaign_snapshot()
	var callbacks: Array[Dictionary] = _recipient_callbacks()
	if not _expect(_pristine(restored) and _same(restored, entrance) and _all_new(before, _ids()) and _freed(refs) and callbacks.is_empty() and _bindings() and _same(game.attempts.state().side_attempt.checkpoint, entrance) and _same(game.attempts.state().story, protected_story) and _durable(), "actual menu Retry quietly restores the exact earlier pristine whole entrance and frees the live-field donor with zero installed-recipient callbacks"): return false
	receipts.append({"label": "actual RetryButton restores earlier entrance", "exact_snapshot": Exact.stringify(restored), "exact_attempts": Exact.stringify(game.attempts.state()), "saved_envelope_json": FileAccess.get_file_as_string(test_root + "campaign.json"), "before_identities": before, "new_identities": _ids(), "new_installed_recipient_callbacks": callbacks, "scope": "actual production Button public pressed signal; no OS click credit"})
	return true


func _native_bindings_readback() -> Dictionary:
	var value: Dictionary = {"identities": _ids(), "sources": {}, "protocols": {}}
	for id: String in Bloom.SOURCE_IDS:
		value.sources[id] = _source(id).get_spore_native_bindings()
	var protocols: Dictionary = game.active_level.get("_protocols")
	for consumer_id: String in protocols:
		value.protocols[consumer_id] = {}
		for id: String in protocols[consumer_id]: value.protocols[consumer_id][id] = protocols[consumer_id][id].binding_state()
	return value


func _native_readback() -> Dictionary:
	var value: Dictionary = {"host": game.active_level.call("bloom_state"), "player": game.player.get_threat_response_state(), "player_hp": game.player.hp, "field": _field().state() if _field() != null else {}, "scheduler_clock": _scheduler().get_clock(), "sources": {}}
	for id: String in Bloom.SOURCE_IDS:
		value.sources[id] = {"presentation": _source(id).pure_presentation_state(), "repulsion": _source(id).get_spore_response_state(), "consumer": _consumer().source_state(id) if _consumer() != null and id in Bloom.group_ids(0) else {}}
	return value


func _seed_story(registry: CinderCampaignRegistry) -> bool:
	operation = "accepted L3 native Main story seed"
	paused = true
	preview = MainScene.instantiate(); preview.set("level_scene_path", STORY_PATH); root.add_child(preview)
	# Main.reset_lab releases pause during synchronous construction. Re-pause
	# immediately before any frame; keep exact native spawn/clock assertions.
	paused = true
	await process_frame; await process_frame
	var hero: CinderPlayer = preview.get("player") as CinderPlayer
	var level: CinderLevel = preview.get("active_level") as CinderLevel
	if not _expect(hero != null and level != null and level.level_id == "A1-L3" and level.scene_file_path == STORY_PATH and level.contract_error().is_empty(), "unchanged accepted native L3 Main constructs the actual pristine protected unit"): return false
	var anchor: Vector2 = preview.call("get_aim_anchor_normalized")
	var camera: Camera3D = preview.get("camera") as Camera3D
	var snapshot: Dictionary = {"schema_version": 1, "level_id": "A1-L3", "scene_path": STORY_PATH, "paused": true, "equipment_ids": hero.equipment.snapshot(), "player": hero.snapshot_state(), "level": level.snapshot_state(), "shell": {"api_revision": Shell.SHELL_API, "anchor_normalized": [anchor.x, anchor.y], "input_sequence": 0, "last_input_observation": {}, "camera_focus": Codec.vector3(camera.global_position - Vector3(0, 18, 13)), "shake_left_s": 0.0, "difficulty_at_entry": "standard"}}
	var model: CinderCampaignAttempts = Attempts.new(registry)
	var payload: Dictionary = model.state()
	payload.completed_main = PREFIX.duplicate()
	payload.story = {"kind": "story", "level_id": "A1-L3", "snapshot": snapshot.duplicate(true), "checkpoint": snapshot.duplicate(true)}
	var store: CinderSaveStore = Store.new(test_root + "campaign.json")
	store.payload_validator = model.saved_payload_error
	var pristine: bool = _closed(snapshot) and paused and hero.global_position == level.spawn_position() and snapshot.level.local.beat_index == 0 and snapshot.level.local.scheduler.clock_s == 0.0 and snapshot.level.progress.checkpoint_ids.is_empty() and not snapshot.level.progress.completed
	var accepted: bool = pristine and model.state_error(payload).is_empty() and store.write_payload(payload)
	setups.append({"kind": "TEST completed-main prefix, not earned route", "completed_main": PREFIX.duplicate(), "actual_story_scene": STORY_PATH, "local_progress_completed": snapshot.level.get("progress", {}).get("completed", false)})
	var note: String = model.state_error(payload) + store.last_error
	var refs: Array[WeakRef] = _refs(preview)
	level.exit_level(); preview.free(); preview = null
	return _expect(accepted and _freed(refs), "public validated Attempts/Store persists disclosed three-main TEST prefix plus actual pristine full L3 unit; normal Main disposal: " + note)


func _new_shell() -> bool:
	operation = "fresh actual disk Title"
	game = Shell.new() as CinderCampaignShell
	if not _expect(game.configure_runtime(raw, test_root + "campaign.json", test_root + "settings.json", test_root + "preferences.json"), "supported production Shell.configure_runtime uses only unique isolated stores"): return false
	root.add_child(game)
	if not await _await_operation(func() -> bool: return paused and game.player == null and game.active_level == null and game.menu.page_name() == "title" and not game.attempts.active_snapshot().is_empty(), "actual disk startup loads the saved model at Title without installed world", 8.0): return false
	return _expect(game.campaign_error.is_empty() and game.settings.storage_path() == test_root + "settings.json", "fresh Title validates the saved whole session using isolated settings")


func _reopen_side(saved: Dictionary, label: String) -> bool:
	var before: Dictionary = _ids()
	var disk: String = FileAccess.get_file_as_string(test_root + "campaign.json")
	var backup: String = FileAccess.get_file_as_string(test_root + "campaign.json.bak")
	var refs: Array[WeakRef] = _refs(game)
	operation = "normal donor Shell disposal: " + label
	# Public level cleanup while every native child still has its actual tree.
	game.active_level.exit_level()
	game.free(); game = null
	await process_frame
	if not _expect(_freed(refs), "normal closed donor Shell frees its native descendants before independent disk recipient: " + label): return false
	if not await _new_shell(): return false
	operation = "Title public active-side Continue: " + label
	# Title Resume Side loads the saved active side. Continue Story would leave it.
	game.menu.resume_requested.emit()
	if not await _await_operation(func() -> bool: return _live(Bloom.LEVEL_ID) and paused and game.menu.page_name() == "resume", "public active-side Continue installs saved O2", 8.0): return false
	var captured: Dictionary = game.capture_campaign_snapshot()
	var callbacks: Array[Dictionary] = _recipient_callbacks()
	if not _expect(_same(captured, saved) and _all_new(before, _ids()) and callbacks.is_empty() and _bindings() and _same(game.attempts.state().story, protected_story) and FileAccess.get_file_as_string(test_root + "campaign.json") == disk and FileAccess.get_file_as_string(test_root + "campaign.json.bak") == backup and _durable(), "fresh disk active Continue restores an exact distinct installed native recipient with zero recipient callbacks and unchanged saved/protected unit: " + label): return false
	receipts.append({"label": "fresh public active-side disk Continue", "case": label, "exact_snapshot": Exact.stringify(captured), "exact_attempts": Exact.stringify(game.attempts.state()), "saved_envelope_json": FileAccess.get_file_as_string(test_root + "campaign.json"), "new_installed_recipient_callbacks": callbacks, "new_identities": _ids()})
	return true


func _pause(label: String) -> bool:
	operation = "public Pause: " + label
	var generation_before: int = _save_generation()
	game.request_pause()
	if not await _await_operation(func() -> bool: return paused and game.menu.page_name() == "pause" and _save_generation() > generation_before, "deferred public Pause commits a new whole-unit Save generation", 8.0): return false
	return _expect(game.campaign_error.is_empty() and _durable(), "normal public Pause persists actual native unit: " + label)


func _resume(label: String) -> bool:
	operation = "public Resume: " + label
	game.menu.resume_requested.emit()
	return _expect(not paused and _live(Bloom.LEVEL_ID) and not game.player.dead, "public Resume releases actual healthy optional simulation: " + label)


func _last_sequence() -> int:
	var actions: Array[Dictionary] = game.player.get_world_action_records()
	return 0 if actions.is_empty() else int(actions.back().sequence)


func _live(id: String) -> bool:
	return is_instance_valid(game) and is_instance_valid(game.active_level) and is_instance_valid(game.player) and game.active_level.level_id == id and game.campaign_error.is_empty()


func _durable() -> bool:
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(test_root + "campaign.json"))
	if not envelope is Dictionary or envelope.get("format_version") != 2: return false
	var parsed: Dictionary = Exact.parse(String(envelope.get("payload_json", "")))
	return parsed.get("accepted", false) and _same(parsed.value, game.attempts.state())


func _save_generation() -> int:
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(test_root + "campaign.json"))
	return int(envelope.get("generation", 0)) if envelope is Dictionary else 0


func _closed(unit: Dictionary) -> bool:
	return not unit.is_empty() and unit.get("player") is Dictionary and not unit.player.is_empty() and unit.get("level") is Dictionary and not unit.level.is_empty() and not Exact.stringify(unit).is_empty()


func _same(left: Variant, right: Variant) -> bool:
	var wire: String = Exact.stringify(left)
	return not wire.is_empty() and wire == Exact.stringify(right)


func _await_operation(predicate: Callable, label: String, seconds: float) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while not finishing:
		if not _operation_healthy(): return false
		if predicate.call() == true:
			if Time.get_ticks_msec() > deadline:
				operation_wait_overruns.append({"kind": "operation", "label": label, "late_ms": Time.get_ticks_msec() - deadline, "scope": "completed synchronous operation observed after async waiting deadline; no latency/performance pass"})
			# Observe the real completed state before applying an asynchronous wait
			# deadline. Native synchronous validation cannot be interrupted by it.
			await process_frame
			return _operation_healthy() and predicate.call() == true
		if Time.get_ticks_msec() > deadline: break
		await process_frame
	return _expect(false, "bounded actual Shell operation failed: " + label)


func _wait_live(predicate: Callable, label: String, seconds: float, allow_authored_pause: bool = false) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while not finishing:
		if not _operation_healthy(): return false
		if predicate.call() == true:
			if Time.get_ticks_msec() > deadline:
				operation_wait_overruns.append({"kind": "live", "label": label, "late_ms": Time.get_ticks_msec() - deadline, "scope": "completed native observation after async waiting deadline; no latency/performance pass"})
			return true
		if not is_instance_valid(game.player) or game.player.dead: return _expect(false, "actual living shared Player lost: " + label)
		if paused and not allow_authored_pause: return _expect(false, "actual native pause interrupted live observation; no forced Resume/focus: " + label)
		if Time.get_ticks_msec() > deadline: break
		await process_frame
	return _expect(false, "bounded actual native observation failed: " + label)


func _operation_healthy() -> bool:
	if finishing: return false
	if not is_instance_valid(game): return _expect(false, "actual Shell disappeared during operation")
	if not game.campaign_error.is_empty(): return _expect(false, "first actual Shell error during " + operation + ": " + game.campaign_error)
	if is_instance_valid(game.active_level) and not game.active_level.contract_error().is_empty(): return _expect(false, "first actual native level contract error: " + game.active_level.contract_error())
	return true


func _record(kind: String, ref: WeakRef, value: Dictionary) -> void:
	var node: Node = ref.get_ref() as Node
	if node == null: return
	var level: CinderLevel = node as CinderLevel
	var ancestor: Node = node.get_parent()
	while level == null and ancestor != null:
		if ancestor is CinderLevel: level = ancestor
		ancestor = ancestor.get_parent()
	observations.append({"operation": operation, "kind": kind, "emitter_id": str(node.get_instance_id()), "level_instance_id": str(level.get_instance_id()) if level != null else "", "level_id": level.level_id if level != null else "", "inside_tree": node.is_inside_tree(), "value": _encode(value)})


func _recipient_callbacks() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var level_id: String = str(game.active_level.get_instance_id())
	var player_id: String = str(game.player.get_instance_id())
	for row: Dictionary in observations:
		if row.level_instance_id == level_id or row.emitter_id == player_id: result.append(row)
	# All validation-candidate/old-donor retirement callbacks remain separately
	# recorded in observations. Only this actual installed recipient gets credit.
	return result


func _count_players(node: Node) -> int:
	var count: int = 1 if node is CinderPlayer else 0
	for child: Node in node.get_children(): count += _count_players(child)
	return count


func _refs(node: Node) -> Array[WeakRef]:
	var result: Array[WeakRef] = [weakref(node)]
	for child: Node in node.get_children(): result.append_array(_refs(child))
	return result


func _freed(refs: Array[WeakRef]) -> bool:
	if refs.is_empty(): return false
	for ref: WeakRef in refs:
		if ref.get_ref() != null: return false
	return true


func _encode(value: Variant) -> Variant:
	if value is Vector3: return Codec.vector3(value)
	if value is Vector2: return [value.x, value.y]
	if value is Color: return [value.r, value.g, value.b, value.a]
	if value is Basis: return {"x": _encode(value.x), "y": _encode(value.y), "z": _encode(value.z)}
	if value is Transform3D: return {"basis": _encode(value.basis), "origin": _encode(value.origin)}
	if value is StringName: return String(value)
	if value is Object: return {"native_class": value.get_class(), "instance_id": str(value.get_instance_id())} if is_instance_valid(value) else null
	if value is int and (value < -9007199254740991 or value > 9007199254740991): return {"native_integer_decimal": str(value)}
	if value is Dictionary:
		var converted: Dictionary = {}
		for key: Variant in value: converted[String(key)] = _encode(value[key])
		return converted
	if value is Array:
		var converted: Array = []
		for child: Variant in value: converted.append(_encode(child))
		return converted
	return value


func _expect(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		if first_failure.is_empty(): first_failure = {"label": label, "diagnostic": _diagnostic()}
		push_error(label)
	return ok


func _observe_added(node: Node) -> void:
	var ref: WeakRef = weakref(node)
	if node is CinderPlayer:
		node.fired.connect(func(kind: String) -> void: _record("fired", ref, {"kind": kind}))
		node.died.connect(func() -> void: _record("death", ref, {}))
		node.world_action_executed.connect(func(value: Dictionary) -> void: _record("world-action", ref, value))
		node.equipment_changed.connect(func(id: String) -> void: _record("equipment", ref, {"id": id}))
	if node is CinderLevel:
		node.checkpoint_requested.connect(func(id: String, checkpoint: String, kind: String) -> void: _record("checkpoint", ref, {"level_id": id, "id": checkpoint, "boundary": kind}))
		node.completion_requested.connect(func(id: String, complete: String) -> void: _record("completion", ref, {"level_id": id, "id": complete}))
		node.contact_exit_requested.connect(func(id: String, contact: String) -> void: _record("exit", ref, {"level_id": id, "id": contact}))
		if node.get_script() == BloomScript:
			node.connect("native_admission_published", func(id: String, answer: Dictionary) -> void: _record("admission", ref, {"source_id": id, "answer": answer}))
	if node.get_script() in [Actor, Field, Threat, Interaction]:
		node.connect("state_changed", func(value: Dictionary) -> void: _record("source-field-or-cue-state", ref, value))
	if node.get_script() == Actor:
		node.connect("defeated", func(id: String) -> void: _record("defeated", ref, {"source_id": id}))
		node.connect("hit_resolved", func(id: String, cycle: int, result: Dictionary) -> void: _record("hit-resolved", ref, {"hero_id": id, "cycle": cycle, "result": result}))
	if node.get_script() == Field:
		node.connect("activated", func(value: Dictionary) -> void: _record("field-activated", ref, value))
	if node.get_script() == Repulsion:
		node.connect("reaction_started", func(id: String, episode: String) -> void: _record("reaction-started", ref, {"source_id": id, "episode_id": episode}))
		node.connect("placement_rejected", func(id: String, reason: String) -> void: _record("placement-rejected", ref, {"source_id": id, "reason": reason}))
	if node.get_script() == Scheduler:
		node.connect("reservation_invalidated", func(id: String, reason: String) -> void: _record("reservation-invalidated", ref, {"id": id, "reason": reason}))


func _diagnostic() -> Dictionary:
	var value: Dictionary = {"operation": operation, "paused": paused, "elapsed_ms": Time.get_ticks_msec() - started_ms}
	if not is_instance_valid(game): return value
	value["campaign_error"] = game.campaign_error
	if game.menu != null: value["menu"] = game.menu.page_name()
	if game.attempts != null: value["active_kind"] = game.attempts.active_kind()
	if is_instance_valid(game.player): value["hero_position"] = _encode(game.player.global_position); value["hero_hp"] = game.player.hp
	if is_instance_valid(game.active_level):
		value["level_id"] = game.active_level.level_id; value["snapshot_error"] = game.active_level.last_snapshot_error; value["contract_error"] = game.active_level.contract_error()
		if game.active_level.level_id == Bloom.LEVEL_ID:
			value["native_state"] = _encode(_native_readback()); value["capture_error"] = game.active_level.get("_capture_error"); value["encounter_error"] = game.active_level.get("last_encounter_error")
	return value


func _watchdog() -> void:
	if not finishing and Time.get_ticks_msec() - started_ms > WATCHDOG_MS:
		_expect(false, "actual O2 campaign watchdog reached120 seconds")
		_finish.call_deferred()


func _finish() -> void:
	if finishing: return
	finishing = true; paused = true; operation = "normal final cleanup"
	var refs: Array[WeakRef] = []
	if is_instance_valid(preview):
		var level: CinderLevel = preview.get("active_level") as CinderLevel
		if level != null: level.exit_level()
		refs.append_array(_refs(preview)); preview.free(); preview = null
	if is_instance_valid(game):
		if is_instance_valid(game.active_level): game.active_level.exit_level()
		refs.append_array(_refs(game)); game.free(); game = null
	paused = false
	await create_timer(0.5, true).timeout
	await process_frame
	_expect((refs.is_empty() or _freed(refs)) and get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("environment_attack_targets").is_empty() and get_nodes_in_group("required_cues").is_empty(), "normal public level exit and Shell cleanup free all descendants and native source/cluster/cue groups")
	_expect(FileAccess.get_file_as_bytes(Registry.DATA_PATH) == registry_bytes, "isolated TEST O2 override leaves every canonical registry byte unchanged")
	Engine.max_fps = old_fps; AudioServer.set_bus_layout(old_audio)
	var exact_receipts: Array[String] = []
	var exact_observations: Array[String] = []
	var exact_ok: bool = true
	for row: Dictionary in receipts:
		var wire: String = Exact.stringify(_encode(row))
		exact_ok = exact_ok and not wire.is_empty(); exact_receipts.append(wire)
	for row: Dictionary in observations:
		var wire: String = Exact.stringify(_encode(row))
		exact_ok = exact_ok and not wire.is_empty(); exact_observations.append(wire)
	_expect(exact_ok, "each complete observation retains exact original scalar types/bits within native transport bounds")
	var report := FileAccess.open(report_path, FileAccess.WRITE)
	if report == null: _expect(false, "unique actual O2 campaign report is writable")
	else:
		report.store_string(JSON.stringify({"checks": checks, "failures": failures, "first_failure": first_failure, "elapsed_ms": Time.get_ticks_msec() - started_ms, "operation_wait_overruns": operation_wait_overruns, "setups": setups, "receipts": receipts, "observations": observations, "exact_receipts": exact_receipts, "exact_observations": exact_observations, "scope": "Production Shell at540x1170 with O2-only in-memory TEST registry override, isolated stores and disclosed completed[L1,L2,L3] unlock prefix plus actual pristine native L3 protected Story. Public Optional/paused Save/independent disk Title active-side Continue/Resume/Pause/Leave; actual pause RetryButton public pressed signal to earlier original entrance. Real first approach and native C31 lunge, one ordinary primary to original near anchor, real partial native retreat with whole Field1/Actor3-or4/Scheduler1/Consumer2/Route1/proof packets. Fresh distinct installed recipient exactness and zero callbacks scoped only to its real IDs; donor/candidate callbacks retained separately. Normal public exit/Shell teardown and canonical registry byte preservation and isolated settings/runtime restoration. No OS click/recognizer/earned traversal, later groups/pre-final checkpoint/final contact/completion/stamp/replay/all-kit/full-route/portrait/performance/mobile credit."}, "\t")); report.close()
	if node_added.is_connected(_observe_added): node_added.disconnect(_observe_added)
	if process_frame.is_connected(_watchdog): process_frame.disconnect(_watchdog)
	print("A1-O2 CAMPAIGN: %d checks, %d failures; report=%s" % [checks, failures, report_path])
	quit(1 if failures > 0 else 0)
