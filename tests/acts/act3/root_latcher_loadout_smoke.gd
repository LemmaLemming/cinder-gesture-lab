extends SceneTree
## Actual isolated native-crescent admission coverage for108 carried static kits.
## Public paused lab equipment is carried into a fresh real Root room. Each case
## observes a pure preview and one real zero-ammo warning, then releases it.
## No executed escape/primary, encounter clear, sun-state or human-play claim.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const EquipmentScript: GDScript = preload("res://scripts/equipment.gd")
const RootScript: GDScript = preload("res://scripts/acts/act3/root_latcher.gd")
const MechanismScript: GDScript = preload("res://scripts/combat/lane_mechanism.gd")
const Geometry: GDScript = preload("res://scripts/combat/threat_geometry.gd")
const RoomPath: String = "res://scenes/acts/act3/a3_l2_root_room.tscn"
const Slots: Array[String] = ["jacket", "pants", "shoes", "weapon"]
const ExpectedIDs: Dictionary = {
	"jacket": ["CLOTH-J0", "CLOTH-J1", "CLOTH-J2"],
	"pants": ["CLOTH-P0", "CLOTH-P1", "CLOTH-P2"],
	"shoes": ["CLOTH-S0", "CLOTH-S1", "CLOTH-S2"],
	"weapon": ["WEAPON-01", "WEAPON-02", "WEAPON-03", "WEAPON-04"],
}
const ExpectedKits: int = 108
const WarningWaitS: float = 4.0

class PostActorBarrier:
	extends Node
	signal completed
	var waiting: bool = false
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		process_physics_priority = 1000
	func wait_next() -> void:
		waiting = true
		await completed
		waiting = false
	func _physics_process(_delta: float) -> void:
		if waiting:
			completed.emit()
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PAUSED and waiting:
			_wake.call_deferred()
	func _wake() -> void:
		if waiting:
			completed.emit()

var _checks: int = 0
var _failures: int = 0
var _attempted: int = 0
var _witnessed: int = 0
var _previewed: int = 0
var _expected: int = ExpectedKits


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var selector: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if not selector.is_empty() or (argument != "--baseline-only" and not argument.begins_with("--kit=")):
			_expect(false, "one supported focused selector", argument)
			await _finish()
			return
		selector = argument
	var catalogue: CinderEquipment = EquipmentScript.new() as CinderEquipment
	var kits: Array[Dictionary] = _canonical_kits(catalogue)
	if kits.is_empty():
		await _finish()
		return
	var selected: Array[Dictionary] = kits
	if not selector.is_empty():
		var choice: Dictionary = EquipmentScript.STARTER.duplicate(true)
		if selector.begins_with("--kit="):
			var ids: PackedStringArray = selector.trim_prefix("--kit=").split(",", false)
			if ids.size() != Slots.size():
				_expect(false, "focused kit specifies jacket,pants,shoes,weapon canonical IDs", selector)
				await _finish()
				return
			for index: int in range(Slots.size()):
				choice[Slots[index]] = String(ids[index])
		if not kits.has(choice):
			_expect(false, "focused kit belongs to the enumerated108 legal resolutions", _kit_label(choice))
			await _finish()
			return
		selected = [choice]
		_expected = 1
	print("COVERAGE: %d selected actual native crescent admissions; catalogue13 static IDs/108 legal kits; zero-ammo setup; %.1fs first-warning simulation/wall bound. No clears or two-sun coverage." % [_expected, WarningWaitS])
	for kit: Dictionary in selected:
		if not await _case(kit):
			break
	if _failures == 0:
		_expect(_attempted == _expected and _previewed == _expected and _witnessed == _expected, "every selected kit receives a pure native preview and real zero-ammo Root lease", "attempted=%d previewed=%d witnessed=%d expected=%d" % [_attempted, _previewed, _witnessed, _expected])
	else:
		print("STOPPED after first failed kit; later cases unattempted: attempted=%d witnessed=%d intended=%d" % [_attempted, _witnessed, _expected])
	await _finish()


func _canonical_kits(catalogue: CinderEquipment) -> Array[Dictionary]:
	var choices: Dictionary = {}
	var seen_ids: Dictionary = {}
	for slot: String in Slots:
		var items: Array[Dictionary] = catalogue.available_items(slot)
		if items.size() != (ExpectedIDs[slot] as Array).size():
			_expect(false, "actual static catalogue has the required slot choices", slot)
			return []
		choices[slot] = items
		for item: Dictionary in items:
			var id: String = String(item.get("id", ""))
			if not (ExpectedIDs[slot] as Array).has(id) or item.get("slot") != slot or item.get("perk_id") != null or not catalogue.is_implemented(id) or seen_ids.has(id):
				_expect(false, "available_items preserves canonical implemented IDs/types without perks", id)
				return []
			seen_ids[id] = true
	if not _expect(seen_ids.size() == 13, "public catalogue enumerates exactly13 canonical static IDs"):
		return []
	var kits: Array[Dictionary] = []
	var seen_kits: Dictionary = {}
	for jacket: Dictionary in choices.jacket:
		for pants: Dictionary in choices.pants:
			for shoes: Dictionary in choices.shoes:
				for weapon: Dictionary in choices.weapon:
					var kit: Dictionary = {"jacket": jacket.id, "pants": pants.id, "shoes": shoes.id, "weapon": weapon.id}
					var label: String = _kit_label(kit)
					if seen_kits.has(label) or not catalogue.restore(kit) or not catalogue.acceptance_errors().is_empty():
						_expect(false, "each enumerated kit has a unique public legal resolution", label)
						return []
					seen_kits[label] = true
					kits.append(kit)
	if not _expect(kits.size() == ExpectedKits, "3×3×3×4 public resolutions yield exactly108 unique kits"):
		return []
	return kits


func _case(kit: Dictionary) -> bool:
	_attempted += 1
	paused = false
	var game: Node = MainScene.instantiate()
	var context: Dictionary = {"game": game, "kit": kit, "events": {"blast": 0, "actions": 0, "hits": 0, "deaths": 0}, "weak": {"game": weakref(game)}, "previewed": false}
	root.add_child(game)
	var reason: String = _prepare(context, kit)
	if reason.is_empty():
		await process_frame
		await process_frame
		reason = _paused_setup_error(context)
	if reason.is_empty():
		game.call("resume_lab")
		if paused:
			reason = "Public room resume remained paused"
		else:
			reason = await _first_warning(context)
	var diagnostic: String = _diagnostic(context) if not reason.is_empty() else ""
	var cleanup_error: String = await _dispose(context)
	if not cleanup_error.is_empty():
		reason += ("; " if not reason.is_empty() else "") + cleanup_error
	if reason.is_empty():
		_witnessed += 1
	_expect(reason.is_empty(), "case%03d/%d %s: actual preview, zero-ammo warning witness and cleanup" % [_attempted, _expected, _kit_label(kit)], reason + ("; " + diagnostic if not diagnostic.is_empty() else ""))
	return reason.is_empty()


func _prepare(context: Dictionary, kit: Dictionary) -> String:
	var game: Node = context.game
	var lab_hero: CinderPlayer = game.get("player") as CinderPlayer
	var old_level: CinderLevel = game.get("active_level") as CinderLevel
	if lab_hero == null or old_level == null or not game.call("is_lab_level") or not get_nodes_in_group("enemies").is_empty():
		return "Default MainScene must create the actual enemy-free lab"
	context.weak["old_hero"] = weakref(lab_hero)
	context.weak["old_level"] = weakref(old_level)
	game.call("open_bench")
	if not paused:
		return "Public lab bench did not pause the safe equipment boundary"
	for slot: String in Slots:
		if not lab_hero.equip_item(String(kit[slot])):
			return "Public equip_item rejected " + String(kit[slot])
	if not _same(lab_hero.equipment.snapshot(), kit) or not game.call("load_level_scene", RoomPath):
		return "Public equipped room transition failed: " + String(game.get("level_load_error"))
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	var level: CinderLevel = game.get("active_level") as CinderLevel
	if hero == null or level == null or hero == lab_hero or level.scene_file_path != RoomPath or level.level_id != "A3-L2" or not level.contract_error().is_empty():
		return "Transition did not create the actual Root room/new shared Hero"
	game.call("open_bench")
	if not paused:
		return "New room must pause before any await or encounter tick"
	hero.shells = 0 # Authorized TEST ONLY condition on the fresh room Hero.
	var source: CinderAct3RootLatcher = level.get("root_latcher") as CinderAct3RootLatcher
	var scheduler: CinderThreatScheduler = level.get("threat_scheduler") as CinderThreatScheduler
	if source == null or scheduler == null or source.get_script() != RootScript or not String(level.get("last_configuration_error")).is_empty():
		return "Current living native Root and scheduler bindings required"
	var mechanism: CinderLaneMechanism = source.get_mechanism()
	var cue: CinderThreatCue = mechanism.get_cue() if mechanism != null else null
	var barrier := PostActorBarrier.new()
	game.add_child(barrier)
	context.merge({"hero": hero, "level": level, "source": source, "scheduler": scheduler, "mechanism": mechanism, "cue": cue, "barrier": barrier, "hp_before": hero.hp, "source_hp_before": source.hp}, true)
	for entry: Dictionary in [{"id": "world", "node": game.get("world")}, {"id": "hero", "node": hero}, {"id": "level", "node": level}, {"id": "source", "node": source}, {"id": "scheduler", "node": scheduler}, {"id": "mechanism", "node": mechanism}, {"id": "cue", "node": cue}, {"id": "barrier", "node": barrier}]:
		if not is_instance_valid(entry.node):
			return "Actual setup lost " + String(entry.id)
		context.weak[String(entry.id)] = weakref(entry.node)
	hero.fired.connect(func(kind: String) -> void:
		if kind == "blast":
			context.events.blast += 1
	)
	hero.world_action_executed.connect(func(_record: Dictionary) -> void: context.events.actions += 1)
	hero.died.connect(func() -> void: context.events.deaths += 1)
	source.died.connect(func(_where: Vector3) -> void: context.events.deaths += 1)
	mechanism.hit_resolved.connect(func(_id: String, _cycle: int, _result: Dictionary) -> void: context.events.hits += 1)
	if hero.presentation_id != "act3_traveller" or not _same(hero.equipment.snapshot(), kit) or not _same(hero.stats, hero.equipment.resolved_stats()):
		return "Fresh actual Hero did not carry the exact canonical kit/stats"
	if not (hero.process_physics_priority < source.process_physics_priority and scheduler.process_physics_priority < source.process_physics_priority and source.process_physics_priority < mechanism.process_physics_priority and mechanism.process_physics_priority < level.process_physics_priority and level.process_physics_priority < barrier.process_physics_priority):
		return "Pausable post-actor barrier must follow the actual Hero/scheduler/Root/mechanism/level"
	return ""


func _paused_setup_error(context: Dictionary) -> String:
	var hero: CinderPlayer = context.hero
	var source: CinderAct3RootLatcher = context.source
	var scheduler: CinderThreatScheduler = context.scheduler
	var state: Dictionary = source.state()
	if not paused or scheduler.get_clock() != 0.0 or hero.get_world_action_clock() != 0.0 or state.clock_s != 0.0 or state.mechanism.status != "idle" or state.mechanism.cycle != 0 or not state.framing.is_empty() or not scheduler.reservations().is_empty():
		return "Paused carryover setup advanced an actor/cycle/lease before admission"
	if context.weak.old_hero.get_ref() != null or context.weak.old_level.get_ref() != null:
		return "Paused setup retained old lab actors"
	var enemies: Array[Node] = get_nodes_in_group("enemies")
	if enemies.size() != 1 or enemies[0] != source or not get_nodes_in_group("practice_targets").is_empty() or not get_nodes_in_group("lab_weapons").is_empty():
		return "Actual room must contain only its living Root target, without lab proxies"
	return "" if hero.shells == 0 and hero.hp == context.hp_before and source.hp == context.source_hp_before else "Paused setup changed actual fixture resources"


func _first_warning(context: Dictionary) -> String:
	var hero: CinderPlayer = context.hero
	var source: CinderAct3RootLatcher = context.source
	var scheduler: CinderThreatScheduler = context.scheduler
	var begin: float = scheduler.get_clock()
	var wall_deadline: int = Time.get_ticks_msec() + int(WarningWaitS * 1000.0)
	for _index: int in range(int(ceilf(WarningWaitS * Engine.physics_ticks_per_second)) + 8):
		await (context.barrier as PostActorBarrier).wait_next()
		if paused:
			return "Actual admission paused unexpectedly before the warning observation"
		if scheduler.get_clock() - begin > WarningWaitS + Geometry.EPSILON or Time.get_ticks_msec() > wall_deadline:
			return "First actual warning exceeded the bounded simulation/wall wait"
		var state: Dictionary = source.state()
		if state.mechanism.status == "running":
			if state.phase != "warning" or state.mechanism.cycle != 1 or not context.previewed:
				return "First actual lease must follow a pure preview and remain its first warning"
			if not (context.game as Node).call("request_pause_deferred"):
				return "Supported complete-tick pause did not queue for the observed warning"
			await process_frame
			await process_frame
			return _witness_error(context)
		if state.dead or state.phase != "clear" or hero.dead:
			return "Unleased source entered an unsupported lifecycle before admission"
		if not context.previewed and hero.is_on_floor() and hero.get_threat_response_state().stable:
			var error: String = _preview_error(context)
			if not error.is_empty():
				return error
	return "No actual warning within the finite fixed-tick bound"


func _preview_error(context: Dictionary) -> String:
	var source: CinderAct3RootLatcher = context.source
	var mechanism: CinderLaneMechanism = context.mechanism
	var response: Dictionary = (context.level as CinderLevel).call("combat_response")
	var supplied: Dictionary = {}
	for key: String in MechanismScript.RESPONSE_KEYS:
		if not response.has(key): return "Public Root response lacks " + key
		supplied[key] = response[key]
	var bearing: Vector3 = (context.hero as CinderPlayer).global_position - source.global_position
	bearing.y = 0.0
	if bearing.length_squared() == 0.0:
		return "Actual stationary Root preview requires a nonzero planar bait bearing"
	bearing = bearing.normalized()
	var before: Dictionary = _public_observation(context)
	var preview: Dictionary = mechanism.preview_start("hero", supplied, null, bearing)
	if not _same(before, _public_observation(context)):
		return "Pure preview changed actual public Hero/source/consumer/cue/scheduler observations"
	if not preview.get("accepted", false) or preview.get("api_revision") != "stationary-preview-1" or not preview.get("candidate") is Dictionary or not preview.get("proof") is Dictionary or not preview.get("guard") is Dictionary or preview.guard.is_empty():
		return "Actual first grounded stationary preview rejected: " + String(preview.get("reason", "invalid native result"))
	var candidate: Dictionary = preview.candidate
	if candidate.has("id") or candidate.source_instance_id != mechanism.get_instance_id() or candidate.start_s != (context.scheduler as CinderThreatScheduler).get_clock():
		return "Pure candidate must name the real child owner/current clock without allocating an ID"
	var error: String = _geometry_error(source, candidate.geometry)
	if error.is_empty(): error = _proof_error(preview.proof, candidate, response)
	if not error.is_empty(): return "Pure native preview: " + error
	context.previewed = true
	context["preview_summary"] = {"clock_s": candidate.start_s, "geometry": candidate.geometry.duplicate(true), "landing": preview.proof.landing, "attack_position": preview.proof.attack_position}
	_previewed += 1
	return ""


func _witness_error(context: Dictionary) -> String:
	var hero: CinderPlayer = context.hero
	var level: CinderLevel = context.level
	var source: CinderAct3RootLatcher = context.source
	var scheduler: CinderThreatScheduler = context.scheduler
	var mechanism: CinderLaneMechanism = context.mechanism
	var state: Dictionary = source.state()
	var record: Dictionary = scheduler.reservation_state(String(state.mechanism.reservation_id))
	var bindings: Dictionary = level.call("scheduler_bindings")
	var response: Dictionary = level.call("combat_response")
	if not paused or state.api_revision != "act3-root-latcher-2" or state.phase != "warning" or not hero.is_on_floor() or hero.shells != 0 or hero.hp != context.hp_before or source.hp != context.source_hp_before or state.knot_open or state.dead or hero.dead:
		return "Actual grounded zero-ammo warning changed HP, lifecycle or knot authority"
	if not _same(context.events, {"blast": 0, "actions": 0, "hits": 0, "deaths": 0}) or not hero.get_world_action_records().is_empty():
		return "Admission probe unexpectedly executed an action, blast, contact or defeat"
	if not _same(hero.equipment.snapshot(), context.kit) or not _same(hero.stats, hero.equipment.resolved_stats()) or response.actor != hero or response.equipment_ids != context.kit or not _same(response.stats, hero.stats):
		return "Actual carried canonical IDs/equipment/public response stats diverged"
	for key: String in hero.get_threat_response_state():
		if not response.has(key) or not _same(response[key], hero.get_threat_response_state()[key]):
			return "Authored response changed actual public Hero field: " + key
	if bindings.world_root != (context.game as Node).get("world") or bindings.owners.get(state.source_id) != mechanism or record.is_empty() or record.id != "threat-1" or record.source_instance_id != mechanism.get_instance_id() or not record.armed or record.state != "warning" or scheduler.reservations().size() != 1:
		return "Real first armed lease must belong to the actual mechanism child in the common World"
	var error: String = _geometry_error(source, record.geometry)
	if not error.is_empty(): return error
	var bearing: Vector3 = hero.global_position - source.global_position
	bearing.y = 0.0
	if record.geometry.direction != bearing.normalized() or source.get_selected_geometry() != record.geometry or state.mechanism.geometry != record.geometry:
		return "Actual first lease did not freeze its measured Hero-facing native crescent"
	if record.source_position != source.global_position or record.opening_position != source.global_position or record.world_revision != response.world_revision or record.profile_id != scheduler.encounter_profile().id:
		return "Actual fixed bulb/opening/profile/world custody differs from its lease"
	var body: CollisionShape3D = source.get_node_or_null("BodyCollision") as CollisionShape3D
	if body == null or body.disabled or not body.shape is CapsuleShape3D or source.collision_layer != 2 or source.collision_mask != 1 or not source.is_in_group("enemies") or not source.is_visible_in_tree() or not is_equal_approx((body.shape as CapsuleShape3D).radius, 0.32) or not is_equal_approx((body.shape as CapsuleShape3D).height, 0.64) or not is_equal_approx(body.position.y, 0.32):
		return "Living fixed ordinary-primary target lost its actual low capsule/body authority"
	var cue: Dictionary = (context.cue as CinderThreatCue).state()
	if cue.phase != "warning" or cue.geometry != record.geometry or cue.source_position != source.global_position or not cue.source_visible or not cue.footprint_visible or cue.active_fill_visible:
		return "Required native warning source/footprint differs from the actual committed shape"
	if not state.proof is Dictionary:
		return "Actual Root did not retain its accepted common witness diagnostic"
	error = _proof_error(state.proof, record, response)
	if not error.is_empty(): return error
	if not _same(source.get_selected_response(), {"landing": state.proof.landing, "attack_position": state.proof.attack_position}):
		return "Historical held framing differs from the actual selected witness points"
	if not String(state.framing_error).is_empty() or not String(level.call("framing_guard", true, {})).is_empty():
		return "Actual native source/art/full footprint/selected response failed the current-view guard"
	var points: Array = level.camera_framing_points()
	if points.is_empty() or points.size() > 224 or not String(level.shared_shell.call("camera_framing_error", points)).is_empty():
		return "Actual current portrait union does not contain the required native corners"
	var scheduler_snapshot: Dictionary = scheduler.snapshot_state(bindings)
	var source_snapshot: Dictionary = source.snapshot_state(bindings)
	if scheduler_snapshot.is_empty() or source_snapshot.is_empty() or scheduler_snapshot.serial != 1 or scheduler_snapshot.cooldowns.size() != 1 or scheduler_snapshot.cooldowns[0].source_id != state.source_id or scheduler_snapshot.cooldowns[0].ready_s != record.cooldown_until_s or source_snapshot.schema_version != 2 or source_snapshot.mechanism.schema_version != 1:
		return "Paused actual first lease must retain one native serial/cooldown and source2/common1 custody; " + source.last_snapshot_error + "; " + scheduler.last_snapshot_error
	var checkpoint: Dictionary = level.current_checkpoint()
	if scheduler.get_clock() != hero.get_world_action_clock() or state.clock_s != scheduler.get_clock() or level.is_completed() or not String(checkpoint.id).is_empty() or not String(checkpoint.kind).is_empty():
		return "Admission must preserve exact actual clocks and incomplete room progress"
	return ""


func _geometry_error(source: CinderAct3RootLatcher, shape: Dictionary) -> String:
	if not Geometry.error(shape).is_empty() or shape.get("kind") != "crescent" or shape.origin != source.global_position or shape.inner_radius != 0.55 or shape.outer_radius != 2.0 or shape.min_dot != 0.5:
		return "Actual committed Root geometry must be the canonical hollow .55/2.0/.5 crescent"
	return ""


func _proof_error(proof: Dictionary, record: Dictionary, response: Dictionary) -> String:
	if proof.get("accepted") != true or proof.get("uses_blast") != false or proof.get("uses_invulnerability") != false or not proof.get("path") is Array or proof.path.is_empty() or not Geometry.finite_vector(proof.get("landing")) or not Geometry.finite_vector(proof.get("attack_position")):
		return "Selected public witness must retain an ordinary non-blast/non-immunity path and points"
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not Geometry.finite_number(record.get(key)): return "Missing finite actual deadline: " + key
	if not (record.start_s < record.lock_from_s and record.lock_from_s < record.active_from_s and record.active_from_s < record.active_until_s and record.active_until_s < record.recovery_until_s):
		return "Actual warning/lock/active/recovery deadlines must be ordered"
	if not Geometry.finite_number(proof.get("primary_time_s")) or not Geometry.finite_number(proof.get("response_complete_s")) or proof.primary_time_s <= record.active_until_s or proof.response_complete_s > record.recovery_until_s or proof.response_complete_s != float(proof.primary_time_s) + maxf(float(response.stats.primary_cooldown), float(response.primary_commitment_s)):
		return "Ordinary primary and its actual equipment recovery must fit the held opening deadline"
	var path: Array[Dictionary] = []
	var previous: Dictionary = {}
	var escape: Dictionary = {}
	var primary: Dictionary = {}
	for value: Variant in proof.path:
		if not value is Dictionary or not value.get("kind") is String or not Geometry.finite_vector(value.get("from")) or not Geometry.finite_vector(value.get("to")) or not Geometry.finite_number(value.get("start_s")) or not Geometry.finite_number(value.get("end_s")):
			return "Selected path requires finite native segments/times"
		var segment: Dictionary = value
		if segment.start_s < record.start_s or segment.end_s < segment.start_s or segment.end_s > record.recovery_until_s or (not previous.is_empty() and (segment.start_s != previous.end_s or segment["from"] != previous["to"])):
			return "Selected timed path must remain continuous inside the actual lease"
		if segment.kind in ["escape_dash", "positioning_dash"]:
			if not is_equal_approx(segment.end_s, float(segment.start_s) + float(response.stats.dash_duration)) or absf((segment["to"] as Vector3).distance_to(segment["from"]) - float(response.stats.dash_distance)) > Geometry.EPSILON:
				return "Selected dash must use this actual kit's distance/duration"
		if segment.kind == "escape_dash": escape = segment
		if segment.kind == "positioning_dash" and (escape.is_empty() or segment.start_s < float(escape.start_s) + float(response.stats.dash_cooldown) or segment["from"] != proof.landing or segment["to"] != proof.attack_position):
			return "Real return witness must respect dash cooldown and selected opening/landing"
		if segment.kind == "ordinary_primary": primary = segment
		path.append(segment)
		previous = segment
	if escape.is_empty() or primary.is_empty() or path[0]["from"] != response.motion.position or escape["to"] != proof.landing or primary["from"] != proof.attack_position or primary["to"] != proof.attack_position or primary.start_s != proof.primary_time_s or primary.end_s != proof.response_complete_s:
		return "Selected witness lacks its actual Hero origin, full escape and ordinary primary hold"
	if Geometry.timed_path_hits(record.geometry, path, record.active_from_s, record.active_until_s, CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN):
		return "Selected native capsule path crosses its committed active annular danger"
	if Geometry.planar(proof.attack_position).distance_to(Geometry.planar(record.opening_position)) > float(response.stats.primary_range) - CinderThreatScheduler.SKIN or absf(proof.attack_position.y - record.opening_position.y) > 1.4:
		return "Actual ordinary opening is outside this kit's primary reach"
	var query := PhysicsRayQueryParameters3D.create(proof.attack_position + Vector3.UP * 0.7, record.opening_position + Vector3.UP * 0.7, 1)
	return "Selected low primary opening is blocked by actual scenery" if not (response.actor as CinderPlayer).get_world_3d().direct_space_state.intersect_ray(query).is_empty() else ""


func _public_observation(context: Dictionary) -> Dictionary:
	return {"hero": (context.hero as CinderPlayer).get_threat_response_state(), "source": (context.source as CinderAct3RootLatcher).state(), "mechanism": (context.mechanism as CinderLaneMechanism).state(), "cue": (context.cue as CinderThreatCue).state(), "clock_s": (context.scheduler as CinderThreatScheduler).get_clock(), "reservations": (context.scheduler as CinderThreatScheduler).reservations(), "events": context.events.duplicate(true), "scheduler_error": (context.scheduler as CinderThreatScheduler).last_error, "mechanism_error": (context.mechanism as CinderLaneMechanism).last_error}


func _dispose(context: Dictionary) -> String:
	var error: String = ""
	var game: Variant = context.get("game")
	if is_instance_valid(game) and is_instance_valid(game.get("player")): game.call("open_bench")
	else: paused = true
	var level: Variant = context.get("level")
	var scheduler: Variant = context.get("scheduler")
	var cue: Variant = context.get("cue")
	if is_instance_valid(level): level.exit_level()
	if is_instance_valid(scheduler) and not scheduler.reservations().is_empty(): error = "Public level exit retained an actual lease"
	if is_instance_valid(cue) and cue.state().phase != "clear": error = "Public exit retained a visible required threat cue"
	if is_instance_valid(game):
		if game.get_parent() == root: root.remove_child(game)
		game.queue_free()
	paused = false
	for _index: int in range(5):
		await process_frame
		if not is_instance_valid(game): break
	for key: String in context.weak:
		if (context.weak[key] as WeakRef).get_ref() != null: return error if not error.is_empty() else "Disposed case retained actual " + key
	for group: String in ["enemies", "practice_targets", "lab_weapons", "required_cues"]:
		if not get_nodes_in_group(group).is_empty(): return error if not error.is_empty() else "Disposed case retained group " + group
	return error


func _diagnostic(context: Dictionary) -> String:
	var result: Dictionary = {"kit": context.kit, "events": context.events, "preview": context.get("preview_summary", {})}
	var hero: Variant = context.get("hero")
	if is_instance_valid(hero): result["hero"] = {"position": hero.global_position, "velocity": hero.velocity, "grounded": hero.is_on_floor(), "hp": hero.hp, "shells": hero.shells, "stats": hero.stats, "equipment": hero.equipment.snapshot()}
	var source: Variant = context.get("source")
	if is_instance_valid(source): result["source"] = source.state()
	var scheduler: Variant = context.get("scheduler")
	if is_instance_valid(scheduler): result["scheduler"] = {"clock_s": scheduler.get_clock(), "last_error": scheduler.last_error, "reservations": scheduler.reservations()}
	var level: Variant = context.get("level")
	if is_instance_valid(level): result["camera_error"] = level.get("last_camera_framing_error")
	return str(result)


func _kit_label(kit: Dictionary) -> String:
	var ids: PackedStringArray = []
	for slot: String in Slots: ids.append(String(kit.get(slot, "")))
	return "/".join(ids)


func _same(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b): return false
	if a is Dictionary:
		if a.size() != b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _same(a[key], b[key]): return false
		return true
	if a is Array:
		if a.size() != b.size(): return false
		for index: int in range(a.size()):
			if not _same(a[index], b[index]): return false
		return true
	return a == b


func _expect(condition: bool, label: String, diagnostic: String = "") -> bool:
	_checks += 1
	if condition: print("PASS: " + label)
	else:
		_failures += 1
		push_error("FAIL: " + label + ("; " + diagnostic if not diagnostic.is_empty() else ""))
	return condition


func _finish() -> void:
	paused = false
	# Finite native audio/node retirement; no warning suppression or live actors.
	await create_timer(0.15, true, false, true).timeout
	print("Root native crescent loadout admissions: %d checks; failures:%d; attempted:%d/%d; pure previews:%d; actual zero-ammo leases:%d. No kit clears, two-sun states, native gestures or human fairness claim." % [_checks, _failures, _attempted, _expected, _previewed, _witnessed])
	quit(0 if _failures == 0 else 1)
