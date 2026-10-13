extends SceneTree
## Actual room witness coverage: 108 implemented static kits in EACH sun.
## Default 216 native configured-sun reservations, never actual kit clears.
## Gear is equipped at the public paused lab boundary, then carried by the
## public shell into the physical Stalker room before its first physics tick.
## This probe performs no dash/slash and establishes no clears or human fairness.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const EquipmentScript: GDScript = preload("res://scripts/equipment.gd")
const SourceScript: GDScript = preload("res://scripts/acts/act3/sunbound_stalker.gd")
const Motion: GDScript = preload("res://scripts/combat/lunge_motion.gd")
const Geometry: GDScript = preload("res://scripts/combat/threat_geometry.gd")
const Codec: GDScript = preload("res://scripts/campaign/snapshot_codec.gd")
const RoomPath: String = "res://scenes/acts/act3/a3_l1_stalker_room.tscn"
const ExpectedKits: int = 108
const ExpectedWitnesses: int = 216
const WarningWaitS: float = 4.0
const Slots: Array[String] = ["jacket", "pants", "shoes", "weapon"]
const SlotCounts: Array[int] = [3, 3, 3, 4]

var _checks: int = 0
var _failures: int = 0
var _attempted: int = 0
var _witnessed: int = 0
var _case_failures: int = 0
var _expected_cases: int = ExpectedWitnesses
var _expected_by_sun: Array[int] = [ExpectedKits, ExpectedKits]
var _attempted_by_sun: Array[int] = [0, 0]
var _witnessed_by_sun: Array[int] = [0, 0]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var selector: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument not in ["--sun0-only", "--sun1-only", "--baseline-sun0-only"] or not selector.is_empty():
			_expect(false, "one supported focused selector", argument)
			_finish()
			return
		selector = argument
	var catalogue: CinderEquipment = EquipmentScript.new() as CinderEquipment
	var choices: Dictionary = {}
	var catalogue_error: String = ""
	var unique_ids: Dictionary = {}
	for index: int in range(Slots.size()):
		var slot: String = Slots[index]
		var items: Array[Dictionary] = catalogue.available_items(slot)
		choices[slot] = items
		if items.size() != SlotCounts[index]:
			catalogue_error = "expected %d implemented %s choices, got %d" % [SlotCounts[index], slot, items.size()]
			break
		for item: Dictionary in items:
			var id: String = String(item.get("id", ""))
			if id.is_empty() or item.get("slot") != slot or item.get("perk_id") != null or not catalogue.is_implemented(id) or unique_ids.has(id):
				catalogue_error = "available_items returned an invalid or duplicate implemented ID: " + id
				break
			unique_ids[id] = true
		if not catalogue_error.is_empty():
			break
	_expect(catalogue_error.is_empty() and unique_ids.size() == 13, "actual catalogue enumerates 3 × 3 × 3 × 4 choices / 13 static IDs", catalogue_error)
	if not catalogue_error.is_empty() or unique_ids.size() != 13:
		_finish()
		return

	var kits: Array[Dictionary] = []
	for jacket: Dictionary in choices["jacket"]:
		for pants: Dictionary in choices["pants"]:
			for shoes: Dictionary in choices["shoes"]:
				for weapon: Dictionary in choices["weapon"]:
					kits.append({"jacket": jacket["id"], "pants": pants["id"], "shoes": shoes["id"], "weapon": weapon["id"]})
	_expect(kits.size() == ExpectedKits, "Cartesian enumeration contains exactly 108 actual static kits")
	if kits.size() != ExpectedKits:
		_finish()
		return

	var unique_kits: Dictionary = {}
	for kit: Dictionary in kits:
		var key: String = _kit_label(kit)
		if unique_kits.has(key) or not catalogue.restore(kit) or not catalogue.acceptance_errors().is_empty():
			_expect(false, "108-kit enumeration contains unique public legal resolutions", key)
			_finish()
			return
		unique_kits[key] = true
	catalogue.reset_starter()
	var baseline: Dictionary = catalogue.snapshot()
	if not unique_kits.has(_kit_label(baseline)):
		_expect(false, "public starter baseline belongs to the 108 actual kits")
		_finish()
		return
	var suns: Array[int] = [0, 1]
	var selected_kits: Array[Dictionary] = kits
	if selector == "--sun0-only":
		suns = [0]
		_expected_by_sun = [ExpectedKits, 0]
	elif selector == "--sun1-only":
		suns = [1]
		_expected_by_sun = [0, ExpectedKits]
	elif selector == "--baseline-sun0-only":
		suns = [0]
		selected_kits = [baseline]
		_expected_by_sun = [1, 0]
	_expected_cases = _expected_by_sun[0] + _expected_by_sun[1]
	print("COVERAGE: %d selected native sun-kit witnesses; unique catalogue kits=%d; expected Sun0=%d Sun1=%d; first-warning budget=%.1f simulation/wall seconds" % [_expected_cases, kits.size(), _expected_by_sun[0], _expected_by_sun[1], WarningWaitS])
	var stopped: bool = false
	for sun: int in suns:
		for kit: Dictionary in selected_kits:
			if not await _case(kit, sun):
				# Every failed case stops coverage, even when cleanup succeeded.
				# A later witness cannot erase the first unsupported admission.
				stopped = true
				break
		if stopped:
			break
	if _case_failures == 0:
		_expect(_attempted == _expected_cases and _witnessed == _expected_cases and _attempted_by_sun == _expected_by_sun and _witnessed_by_sun == _expected_by_sun, "every selected actual sun-kit reservation has its accepted ordinary-primary witness", "attempted=%d witnessed=%d Sun0=%d Sun1=%d expected=%s" % [_attempted, _witnessed, _witnessed_by_sun[0], _witnessed_by_sun[1], _expected_by_sun])
	else:
		print("STOPPED at first failed sun-kit case: attempted=%d witnessed=%d intended=%d; later cases unattempted" % [_attempted, _witnessed, _expected_cases])
	_finish()


func _case(kit: Dictionary, sun: int) -> bool:
	_attempted += 1
	_attempted_by_sun[sun] += 1
	paused = false
	var game: Node = MainScene.instantiate()
	var context: Dictionary = {"game": game, "sun": sun}
	root.add_child(game)
	var reason: String = _prepare(context, kit)
	if reason.is_empty():
		# Retire old lab actors without running any new room physics.
		await process_frame
		await process_frame
		reason = _paused_setup_error(context)
	if reason.is_empty() and sun == 1:
		reason = _configure_sun_one(context)
	if reason.is_empty():
		var game_resume: Node = context["game"]
		game_resume.call("resume_lab")
		if paused:
			reason = "public resume_lab left the actual room paused"
	if reason.is_empty():
		reason = await _first_warning(context, kit)
	var diagnostic: String = _diagnostic(context)
	var cleanup_error: String = await _dispose(context)
	var clean: bool = cleanup_error.is_empty()
	if not clean:
		reason = cleanup_error if reason.is_empty() else reason + "; cleanup: " + cleanup_error
	if reason.is_empty():
		_witnessed += 1
		_witnessed_by_sun[sun] += 1
	else:
		_case_failures += 1
	_expect(reason.is_empty(), "Sun%d case %03d/%d %s: actual reservation witness, held bias and cleanup" % [sun, _attempted, _expected_cases, _kit_label(kit)], reason + ("; " + diagnostic if not reason.is_empty() else ""))
	return clean and reason.is_empty()


func _prepare(context: Dictionary, kit: Dictionary) -> String:
	var game: Node = context["game"]
	var lab_hero: CinderPlayer = game.get("player") as CinderPlayer
	context["old_hero"] = lab_hero
	context["old_level"] = game.get("active_level")
	if lab_hero == null or not game.call("is_lab_level") or not get_nodes_in_group("enemies").is_empty():
		return "default MainScene must synchronously create the enemy-free lab hero"
	game.call("open_bench")
	if not paused:
		return "public bench did not establish the paused equipment boundary"
	# No await occurs between scene construction, all four public equips and
	# the public room transition. No clothing is swapped in a live encounter.
	for slot: String in Slots:
		if not lab_hero.equip_item(String(kit[slot])):
			return "public equip_item rejected " + String(kit[slot])
	if lab_hero.equipment.snapshot() != kit:
		return "lab equipment snapshot differs from the exact requested kit"
	if not game.call("load_level_scene", RoomPath):
		return "public room selection failed: " + String(game.get("level_load_error"))

	var hero: CinderPlayer = game.get("player") as CinderPlayer
	var level: CinderLevel = game.get("active_level") as CinderLevel
	context["hero"] = hero
	context["level"] = level
	if hero == null or level == null or hero == lab_hero or level.scene_file_path != RoomPath or level.level_id != "A3-L1" or not level.contract_error().is_empty():
		return "public transition did not create the actual A3-L1 Stalker room and new shared hero"
	var source: CharacterBody3D = level.get("stalker") as CharacterBody3D
	var scheduler: CinderThreatScheduler = level.get("threat_scheduler") as CinderThreatScheduler
	context["source"] = source
	context["scheduler"] = scheduler
	if source == null or scheduler == null or not source.has_method("state") or not level.has_method("combat_response") or source.get_script() != SourceScript or not source.is_in_group("enemies"):
		return "actual room source/scheduler/public response bindings are missing"
	if hero.presentation_id != "act3_traveller" or hero.equipment.snapshot() != kit or not Codec.same_values(hero.stats, hero.equipment.resolved_stats()):
		return "actual new room hero did not retain the exact equipped kit and live stats"
	var state: Dictionary = source.call("state")
	if not String(state.get("reservation_id", "")).is_empty() or int(state.get("cycle", -1)) != 0 or not scheduler.reservations().is_empty() or hero.get_world_action_clock() != 0.0:
		return "an encounter tick or old-kit reservation occurred before setup completed"
	# The public transition resets the preview to unpaused. Reestablish its
	# public pause before the zero-ammo fixture and resume below.
	game.call("open_bench")
	if not paused:
		return "public room pause did not establish the fixture boundary"
	# Fixture only: reset_lab creates fresh ammo. Deplete the NEW room hero,
	# rather than assuming the prior lab hero's ammo survives the transition.
	hero.shells = 0
	if hero.shells != 0:
		return "new room hero did not accept the zero-ammo fixture"
	context["hp_before"] = hero.hp
	context["source_hp_before"] = float(state["hp"])
	return ""


func _paused_setup_error(context: Dictionary) -> String:
	for key: String in ["game", "hero", "level", "source", "scheduler"]:
		if not is_instance_valid(context.get(key)):
			return "native paused setup lost actual " + key
	var hero: CinderPlayer = context["hero"]
	var source: CharacterBody3D = context["source"]
	var scheduler: CinderThreatScheduler = context["scheduler"]
	if not paused or hero.get_world_action_clock() != 0.0 or scheduler.get_clock() != 0.0:
		return "deferred paused setup advanced a room/hero physics clock"
	if is_instance_valid(context.get("old_hero")) or is_instance_valid(context.get("old_level")):
		return "native paused setup retained an old lab actor or level"
	var enemies: Array[Node] = get_nodes_in_group("enemies")
	if enemies.size() != 1 or enemies[0] != source or not get_nodes_in_group("practice_targets").is_empty() or not get_nodes_in_group("lab_weapons").is_empty():
		return "native paused setup contains a duplicate source or lab proxy/pickup"
	var state: Dictionary = source.call("state")
	if int(state.get("cycle", -1)) != 0 or not String(state.get("reservation_id", "")).is_empty() or not scheduler.reservations().is_empty() or not state.get("commit") is Dictionary or not (state["commit"] as Dictionary).is_empty() or int(state.get("sun_visual", -1)) != 0 or int(state.get("effective_sun", -1)) != 0 or int((context["level"] as CinderLevel).get("sun_state")) != 0:
		return "native paused setup did not retain the unstarted first-sun source"
	return "" if hero.shells == 0 and hero.hp == float(context["hp_before"]) and float(state["hp"]) == float(context["source_hp_before"]) else "native paused setup changed fixture resources"


func _configure_sun_one(context: Dictionary) -> String:
	# Complete NATIVE actor/local pair at the deferred paused clock-zero
	# boundary. No JSON transport, direct sun field write or source reset.
	var hero: CinderPlayer = context["hero"]
	var level: CinderLevel = context["level"]
	var source: CharacterBody3D = context["source"]
	var scheduler: CinderThreatScheduler = context["scheduler"]
	var pair: Dictionary = {"hero": hero.snapshot_state(), "level": level.snapshot_state()}
	if not paused or hero.get_world_action_clock() != 0.0 or scheduler.get_clock() != 0.0 or pair["hero"].is_empty() or pair["level"].is_empty():
		return "native clock-zero second-sun actor/local capture failed: hero=%s level=%s" % [hero.last_snapshot_error, level.last_snapshot_error]
	var error: String = hero.snapshot_error(pair["hero"])
	if not error.is_empty():
		return "native second-sun paired hero validation failed: " + error
	pair["level"]["local"]["scenery"]["sun_state"] = 1
	error = level.snapshot_error(pair["level"])
	if not error.is_empty() or not level.restore_state(pair["level"]):
		return "native second-sun local validation/restore failed: " + error + "; " + level.last_snapshot_error
	var state: Dictionary = source.call("state")
	if not _exact(hero.snapshot_state(), pair["hero"]) or int(level.get("sun_state")) != 1 or state.get("sun_visual") != 1 or state.get("effective_sun") != 1 or int(state.get("cycle", -1)) != 0 or not (state["commit"] as Dictionary).is_empty() or not scheduler.reservations().is_empty() or scheduler.get_clock() != 0.0:
		return "native second-sun setup changed its paired actor/resources/history or ran encounter physics"
	return ""


func _first_warning(context: Dictionary, kit: Dictionary) -> String:
	var source: CharacterBody3D = context["source"]
	var scheduler: CinderThreatScheduler = context["scheduler"]
	var begin_clock: float = scheduler.get_clock()
	var wall_deadline_ms: int = Time.get_ticks_msec() + int(WarningWaitS * 1000.0)
	var frame_limit: int = maxi(1, int(ceilf(WarningWaitS * float(Engine.physics_ticks_per_second))) + 8)
	for _index: int in range(frame_limit):
		await physics_frame
		await process_frame
		if not is_instance_valid(source) or not is_instance_valid(scheduler):
			return "actual source or scheduler disappeared before its first accepted warning"
		var state: Dictionary = source.call("state")
		var elapsed: float = scheduler.get_clock() - begin_clock
		if elapsed > WarningWaitS + 0.00001 or Time.get_ticks_msec() > wall_deadline_ms:
			return "first accepted warning exceeded the bounded %.1f-second simulation/wall wait" % WarningWaitS
		var reservation_id: String = String(state.get("reservation_id", ""))
		if not reservation_id.is_empty():
			if state.get("phase") != "warning" or int(state.get("cycle", -1)) != 1:
				return "first observed actual reservation was not the first warning"
			var record: Dictionary = scheduler.reservation_state(reservation_id)
			return _witness_error(context, kit, state, record)
		if state.get("phase") not in ["idle", "approach"] or state.get("dead") != false:
			return "unleased source entered an unsupported phase/lifecycle before its first warning"
	return "no accepted actual warning within %.1f seconds / %d bounded physics frames" % [WarningWaitS, frame_limit]


func _witness_error(context: Dictionary, kit: Dictionary, state: Dictionary, record: Dictionary) -> String:
	for key: String in ["hero", "level", "source", "scheduler"]:
		if not is_instance_valid(context.get(key)):
			return "actual witness binding disappeared: " + key
	var hero: CinderPlayer = context["hero"]
	var level: CinderLevel = context["level"]
	var source: CharacterBody3D = context["source"]
	var scheduler: CinderThreatScheduler = context["scheduler"]
	var response: Dictionary = level.call("combat_response")
	var public_response: Dictionary = hero.get_threat_response_state()
	if response.get("actor") != hero or response.get("equipment_ids") != kit or hero.equipment.snapshot() != kit:
		return "root combat_response is not bound to the actual hero and exact kit"
	for key: String in public_response:
		if not response.has(key) or not Codec.same_values(response[key], public_response[key]):
			return "root combat_response changed the actual public hero field: " + key
	if not Codec.same_values(response.get("stats"), hero.stats) or not Codec.same_values(response.get("stats"), hero.equipment.resolved_stats()) or response.get("stable") != true:
		return "actual stable hero / equipment / root response stats disagree"
	if not hero.get_world_action_records().is_empty():
		return "probe unexpectedly executed a dash or attack"
	if record.is_empty() or record.get("id") != state.get("reservation_id") or record.get("source_instance_id") != source.get_instance_id() or record.get("armed") != true or record.get("state") != "warning":
		return "actual scheduler did not retain the source's armed warning reservation"
	var reservations: Array[Dictionary] = scheduler.reservations()
	if reservations.size() != 1 or reservations[0].get("id") != record["id"] or record.get("world_revision") != response.get("world_revision"):
		return "actual room must own exactly this one reservation in its response world"

	if hero.hp != float(context["hp_before"]) or float(state.get("hp", -1.0)) != float(context["source_hp_before"]) or hero.dead or state.get("dead") != false:
		return "first warning changed actual actor/source HP or lifecycle"
	var body_error: String = _body_error(hero, source, record)
	if not body_error.is_empty():
		return body_error
	var bias_error: String = _bias_error(context, state, record)
	if not bias_error.is_empty():
		return bias_error
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not Geometry.finite_number(record.get(key)):
			return "reservation lacks a finite authoritative deadline: " + key
	if not (float(record.start_s) < float(record.lock_from_s) and scheduler.get_clock() < float(record.lock_from_s) and float(record.lock_from_s) < float(record.active_from_s) and float(record.active_from_s) < float(record.active_until_s) and float(record.active_until_s) < float(record.recovery_until_s)):
		return "actual warning/lock/active/recovery deadlines are not ordered and positive"
	if not state.get("proof") is Dictionary:
		return "actual source did not preserve its accepted request proof"
	return _proof_error(state["proof"], record, response)


func _body_error(hero: CinderPlayer, source: CharacterBody3D, record: Dictionary) -> String:
	var hero_collision: CollisionShape3D = hero.get_node_or_null("BodyCollision") as CollisionShape3D
	if hero_collision == null or hero_collision.disabled or not hero_collision.shape is CapsuleShape3D:
		return "actual hero must retain the enabled shared capsule"
	var hero_capsule: CapsuleShape3D = hero_collision.shape as CapsuleShape3D
	if not is_equal_approx(hero_capsule.radius, 0.32) or not is_equal_approx(hero_capsule.height, 1.45) or not hero_collision.position.is_equal_approx(Vector3(0.0, 0.73, 0.0)):
		return "actual hero capsule or feet convention differs from the shared fixed geometry"
	if not record.get("adapter") is Dictionary or not record.get("geometry") is Dictionary:
		return "actual reservation lacks its physical adapter and committed footprint"
	var adapter: Dictionary = record["adapter"]
	if adapter.get("kind") != "lunge" or not adapter.get("body_collision_path") is String:
		return "actual reservation is not a real-body lunge adapter"
	var description: Dictionary = Motion.source_description(source, adapter["body_collision_path"])
	if description.has("error"):
		return "actual source capsule rejected: " + String(description["error"])
	if not source.is_in_group("enemies") or source.collision_layer != 2 or not Codec.same_values(adapter.get("body_signature"), description["signature"]) or not is_equal_approx(float(description["radius"]), float(SourceScript.TUNING.capsule_radius)) or not is_equal_approx(float(description["height"]), float(SourceScript.TUNING.capsule_height)):
		return "reserved source signature differs from its actual positive capsule geometry"
	for key: String in ["start", "planned_endpoint", "current_position", "current_velocity", "direction"]:
		if not Geometry.finite_vector(adapter.get(key)):
			return "actual lunge lacks a finite physical field: " + key
	for key: String in ["speed", "distance", "duration_s", "damage_radius"]:
		if not Geometry.finite_number(adapter.get(key)) or float(adapter[key]) <= 0.0:
			return "actual lunge lacks a positive physical field: " + key
	if (adapter["start"] as Vector3).distance_to(source.global_position) > 0.00001 or not source.velocity.is_zero_approx() or not (adapter["current_velocity"] as Vector3).is_zero_approx() or adapter.get("finished") != false:
		return "warning source moved or finished before its leased active motion"
	var geometry: Dictionary = record["geometry"]
	if not Geometry.error(geometry).is_empty() or geometry.get("kind") != "lane" or not Codec.same_values(geometry.get("from"), adapter["start"]) or not Codec.same_values(geometry.get("to"), adapter["planned_endpoint"]) or not is_equal_approx(float(geometry.get("radius", -1.0)), float(adapter["damage_radius"])):
		return "fixed committed lane is not the actual lunge source corridor"
	if not Codec.same_values(record.get("opening_position"), adapter["planned_endpoint"]) or float(adapter["damage_radius"]) < float(description["radius"]) or not is_equal_approx(float(adapter["duration_s"]), float(adapter["distance"]) / float(adapter["speed"])):
		return "actual capsule, corridor, endpoint or full travel duration disagree"
	if float(record.get("active_until_s", -1.0)) - float(record.get("active_from_s", 0.0)) + 0.00001 < float(adapter["duration_s"]):
		return "authoritative active interval cannot cover the full physical lunge"
	return ""


func _bias_error(context: Dictionary, state: Dictionary, record: Dictionary) -> String:
	var sun: int = int(context["sun"])
	var source: CharacterBody3D = context["source"]
	var hero: CinderPlayer = context["hero"]
	var level: CinderLevel = context["level"]
	if int(level.get("sun_state")) != sun or state.get("sun_visual") != sun or state.get("effective_sun") != sun or not state.get("commit") is Dictionary:
		return "actual scenery/source/effective held sun differs from its native configured case"
	var commit: Dictionary = state["commit"]
	if not Codec.keys_error(commit, SourceScript.COMMIT_KEYS).is_empty() or commit.get("sun_choice") != sun:
		return "actual accepted source lacks the exact held sun-commit schema/choice"
	for key: String in SourceScript.COMMIT_VECTOR_KEYS:
		if not Geometry.finite_vector(commit.get(key)):
			return "actual held commit lacks its finite native vector: " + key
	var adapter: Dictionary = record["adapter"]
	if commit["source_position"] != adapter["start"] or commit["facing"] != adapter["direction"] or state.get("facing") != commit["facing"] or state.get("position") != commit["source_position"] or source.global_position != commit["source_position"] or hero.global_position != commit["hero_position"]:
		return "actual source/body adapter/current bearing differs from its sampled held commit"
	var toward: Vector3 = commit["hero_position"] - commit["source_position"]
	toward.y = 0.0
	var gap: float = toward.length()
	if gap < float(SourceScript.TUNING.brace_min_distance) or gap > float(SourceScript.TUNING.brace_max_distance):
		return "actual accepted source was not braced within 1.80..2.00 world units"
	var held: Vector3 = commit["facing"]
	var degrees: float = float(SourceScript.TUNING.sun_bias_degrees) * (1.0 if sun == 0 else -1.0)
	var expected: Vector3 = toward.normalized().rotated(Vector3.UP, deg_to_rad(degrees)).normalized()
	if absf(held.y) > 0.00001 or absf(held.length() - 1.0) > 0.00001 or held.dot(expected) < float(SourceScript.TUNING.brace_facing_min_dot):
		return "actual physical heading does not match the selected signed 20-degree sun bias"
	var art: Dictionary = source.call("get_art_state")
	if art.get("sun_state") != sun or art.get("phase") != "warning" or art.get("visible") != true:
		return "actual held crest/source art does not present its accepted warning sun"
	print("WITNESS: Sun%d gap=%.9f signed_heading_degrees=%.9f source=%s sampled_hero=%s held_direction=%s actual_adapter_endpoint=%s" % [sun, gap, rad_to_deg(toward.normalized().signed_angle_to(held, Vector3.UP)), commit["source_position"], commit["hero_position"], held, adapter["planned_endpoint"]])
	return ""


func _proof_error(proof: Dictionary, record: Dictionary, response: Dictionary) -> String:
	if proof.get("accepted") != true or proof.get("uses_blast") != false or proof.get("uses_invulnerability") != false:
		return "actual accepted proof credits blast, invulnerability or no accepted response"
	if not proof.get("path") is Array or (proof["path"] as Array).is_empty() or not Geometry.finite_vector(proof.get("landing")) or not Geometry.finite_vector(proof.get("attack_position")):
		return "actual accepted proof lacks its path, landing or ordinary attack position"
	for key: String in ["primary_time_s", "response_complete_s"]:
		if not Geometry.finite_number(proof.get(key)) or float(proof[key]) <= 0.0:
			return "actual proof lacks a positive ordinary-primary time: " + key
	var primary_time: float = float(proof["primary_time_s"])
	var finish: float = float(proof["response_complete_s"])
	var stats: Dictionary = response["stats"]
	if primary_time <= float(record["active_until_s"]) or finish <= primary_time or finish > float(record["recovery_until_s"]) or finish - primary_time + 0.00001 < float(stats["primary_cooldown"]):
		return "positive ordinary-primary window does not fit the actual recovery deadlines and live weapon cadence"
	var path: Array[Dictionary] = []
	var previous: Dictionary = {}
	var escaped: bool = false
	var attacked: bool = false
	for value: Variant in proof["path"]:
		if not value is Dictionary:
			return "actual proof path contains a non-segment value"
		var segment: Dictionary = value
		if not Geometry.finite_vector(segment.get("from")) or not Geometry.finite_vector(segment.get("to")) or not Geometry.finite_number(segment.get("start_s")) or not Geometry.finite_number(segment.get("end_s")):
			return "actual proof path has a missing finite position or time"
		var start_s: float = float(segment["start_s"])
		var end_s: float = float(segment["end_s"])
		if start_s < float(record["start_s"]) - 0.00001 or end_s < start_s or end_s > float(record["recovery_until_s"]):
			return "actual proof path falls outside the committed response timeline"
		if not previous.is_empty() and (not is_equal_approx(start_s, float(previous["end_s"])) or not (segment["from"] as Vector3).is_equal_approx(previous["to"])):
			return "actual accepted proof path is discontinuous"
		if segment.get("kind") == "escape_dash":
			escaped = (segment["to"] as Vector3).is_equal_approx(proof["landing"]) and is_equal_approx(end_s - start_s, float(stats["dash_duration"])) and is_equal_approx((segment["from"] as Vector3).distance_to(segment["to"]), float(stats["dash_distance"]))
		if segment.get("kind") == "ordinary_primary":
			attacked = (segment["from"] as Vector3).is_equal_approx(proof["attack_position"]) and (segment["to"] as Vector3).is_equal_approx(proof["attack_position"]) and is_equal_approx(start_s, primary_time) and is_equal_approx(end_s, finish)
		path.append(segment)
		previous = segment
	if not escaped or not attacked or not (path[0]["from"] as Vector3).is_equal_approx((response["motion"] as Dictionary)["position"]):
		return "actual proof omits the live hero origin, exact equipped dash or ordinary-primary segment"
	if Geometry.timed_path_hits(record["geometry"], path, float(record["active_from_s"]), float(record["active_until_s"]), CinderThreatScheduler.CAPSULE_RADIUS + CinderThreatScheduler.SKIN):
		return "actual accepted witness intersects its committed active corridor"
	return ""


func _dispose(context: Dictionary) -> String:
	var cleanup_error: String = ""
	var game: Node = context["game"]
	var level: Variant = context.get("level")
	var scheduler: Variant = context.get("scheduler")
	if is_instance_valid(game) and is_instance_valid(game.get("player")):
		game.call("open_bench")
	else:
		paused = true
	if is_instance_valid(level):
		level.exit_level()
	if is_instance_valid(scheduler) and not scheduler.reservations().is_empty():
		cleanup_error = "public level exit left a scheduler reservation"
	if is_instance_valid(game):
		if game.get_parent() == root:
			root.remove_child(game)
		game.queue_free()
	paused = false
	for _index: int in range(4):
		await process_frame
		if not is_instance_valid(game):
			break
	for key: String in ["game", "hero", "level", "source", "scheduler", "old_hero", "old_level"]:
		if context.has(key) and is_instance_valid(context[key]):
			return cleanup_error if not cleanup_error.is_empty() else "disposed case retained its actual " + key
	for group: String in ["enemies", "practice_targets", "lab_weapons"]:
		if not get_nodes_in_group(group).is_empty():
			return cleanup_error if not cleanup_error.is_empty() else "disposed case left nodes in group " + group
	return cleanup_error


func _diagnostic(context: Dictionary) -> String:
	# Keep possibly freed references as Variants until is_instance_valid;
	# casting a retired Object would itself hide the first failure diagnostic.
	var source: Variant = context.get("source")
	var scheduler: Variant = context.get("scheduler")
	var diagnostic: String = "configured_sun=" + str(context.get("sun", -1))
	if is_instance_valid(source) and source.has_method("state"):
		diagnostic += "; source=" + str(source.call("state"))
		if source is CharacterBody3D:
			diagnostic += "; source_grounded=%s source_safe_margin=%s" % [source.is_on_floor(), source.safe_margin]
			var collision: Variant = source.get_node_or_null("BodyCollision")
			if is_instance_valid(collision) and collision is CollisionShape3D:
				diagnostic += "; actual_source_collision=" + str(_collision_diagnostic(collision))
	var hero: Variant = context.get("hero")
	if is_instance_valid(hero) and hero is CinderPlayer:
		diagnostic += "; actual_hero=" + str({"position": hero.global_position, "velocity": hero.velocity, "grounded": hero.is_on_floor(), "shells": hero.shells, "equipment": hero.equipment.snapshot()})
	var level: Variant = context.get("level")
	if is_instance_valid(level) and level.has_method("scheduler_bindings"):
		var bindings: Dictionary = level.call("scheduler_bindings")
		var floors: Dictionary = bindings.get("floors", {})
		for id: String in floors:
			if not floors[id] is Dictionary:
				continue
			var region: Dictionary = floors[id]
			var collision: Variant = region.get("collision")
			if is_instance_valid(collision) and collision is CollisionShape3D:
				diagnostic += "; actual_floor[%s]=%s safe_rect=%s" % [id, _collision_diagnostic(collision), region.get("safe_rect")]
	if is_instance_valid(scheduler):
		diagnostic += "; scheduler.last_error=" + scheduler.last_error
	return diagnostic


func _collision_diagnostic(collision: CollisionShape3D) -> Dictionary:
	var result: Dictionary = {"path": String(collision.get_path()), "global_transform": collision.global_transform, "disabled": collision.disabled}
	var shape: Shape3D = collision.shape
	if shape != null:
		result["shape_margin"] = shape.margin
	if shape is CapsuleShape3D:
		var capsule: CapsuleShape3D = shape as CapsuleShape3D
		result["capsule_radius"] = capsule.radius
		result["capsule_height"] = capsule.height
		result["capsule_foot_y"] = collision.global_position.y - capsule.height * 0.5
	elif shape is BoxShape3D:
		result["box_size"] = (shape as BoxShape3D).size
	var body: CollisionObject3D = collision.get_parent() as CollisionObject3D
	if body != null:
		result["collision_layer"] = body.collision_layer
		result["collision_mask"] = body.collision_mask
	return result


func _kit_label(kit: Dictionary) -> String:
	var ids: PackedStringArray = []
	for slot: String in Slots:
		ids.append(String(kit[slot]))
	return "/".join(ids)


## Native setup comparisons remain exact. This fixture never transports JSON
## and does not weaken the separately failing true-double persistence contract.
func _exact(a: Variant, b: Variant) -> bool:
	if (a is float or a is int) and (b is float or b is int):
		return float(a) == float(b)
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for key: Variant in a:
			if not b.has(key) or not _exact(a[key], b[key]):
				return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for index: int in range(a.size()):
			if not _exact(a[index], b[index]):
				return false
		return true
	return typeof(a) == typeof(b) and a == b


func _expect(condition: bool, description: String, diagnostic: String = "") -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description + ("; " + diagnostic if not diagnostic.is_empty() else ""))


func _finish() -> void:
	paused = false
	print("Stalker loadout room reservation-witness smoke: %d checks, %d failures; %d/%d native sun-kit cases attempted, %d witnessed, %d case failures; Sun0=%d/%d Sun1=%d/%d. Catalogue=108 unique kits. No encounter clears, native gestures or human-fairness acceptance." % [_checks, _failures, _attempted, _expected_cases, _witnessed, _case_failures, _witnessed_by_sun[0], _expected_by_sun[0], _witnessed_by_sun[1], _expected_by_sun[1]])
	quit(0 if _failures == 0 else 1)
