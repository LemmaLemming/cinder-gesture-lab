extends SceneTree
## Isolated target-opening fixture in the actual shared Horsell shell.
## Manual recovery and fixture positioning do not certify a Ray fight, threat
## scheduler, gesture trace, campaign checkpoint, human balance or full level.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const ActorScript: Script = preload("res://scripts/acts/act2/ray_scout_actor.gd")
const VisualScript: Script = preload("res://scripts/acts/act2/ray_scout_visual.gd")
const Codec: GDScript = preload("res://scripts/campaign/snapshot_codec.gd")
const LevelPath: String = "res://scenes/acts/act2/a2_l1.tscn"
const RIG_PATHS: Array[String] = [
	"ScoutRig/ThreeLegChassis",
	"ScoutRig/ThreeLegChassis/RivetedCameraCase",
	"ScoutRig/ThreeLegChassis/TrackingMirrorSwivel",
	"ScoutRig/ThreeLegChassis/TrackingMirrorSwivel/FoldingMirrorHinge",
	"ScoutRig/ThreeLegChassis/FixedLowMirrorHousing",
	"ScoutRig/ThreeLegChassis/FixedLowMirrorHousing/LeftHousingDoor",
	"ScoutRig/ThreeLegChassis/FixedLowMirrorHousing/RightHousingDoor",
]
var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game: Node = MainScene.instantiate()
	game.set("level_scene_path", LevelPath)
	root.add_child(game)
	game.call("resume_lab")
	for frame: int in range(8):
		await physics_frame
	var level: CinderLevel = game.get("active_level") as CinderLevel
	var hero: CinderPlayer = game.get("player") as CinderPlayer
	var effects: PixelEffects = game.get("fx") as PixelEffects
	_expect(level != null and level.level_id == "A2-L1" and level.hero == hero, "fixture retains the actual shared shell and single entered player")
	_expect(hero.equip_item("WEAPON-03") and _near(hero.stats.primary_range, 1.8), "canonical Heavy Edge uses the shortest implemented ordinary-primary reach")
	var actor: Node3D = ActorScript.new() as Node3D
	actor.name = "IsolatedRecoveryTarget"
	actor.position = Vector3(0.0, 0.0, -0.4)
	level.add_child(actor)
	var anchor: Vector3 = actor.global_position
	_expect(not bool(actor.call("take_damage", 3.0, Vector3.ZERO)["accepted"]) and _near(actor.get("hp"), 30.0), "unconfigured target rejects damage without changing health")
	paused = true
	_expect(actor.call("snapshot_state").is_empty() and not bool(actor.call("restore_state", {})), "unconfigured actor cannot capture or restore even at a paused boundary")
	paused = false
	_expect(not bool(actor.call("configure", hero, effects, "bad id")) and bool(actor.call("configure", hero, effects, "A2-L1:fixture-scout")), "configuration requires a stable authored ID and valid entered shared references")
	_expect(not bool(actor.call("configure", hero, effects, "A2-L1:replacement")) and actor.get("actor_id") == "A2-L1:fixture-scout", "repeat configuration cannot change identity or reset health")
	_expect(get_nodes_in_group("enemies") == [actor] and not actor.is_in_group("practice_targets"), "one low-housing root is registered once, with no duplicate practice target")
	_expect(not actor.is_processing() and not actor.is_physics_processing() and _near(actor.get("knockback_scale"), 0.0), "stationary adapter has no independent clock or hidden momentum")
	var defeat_ids: Array[String] = []
	var reentrant_results: Array[bool] = []
	var reentrant_snapshot_results: Array[bool] = []
	actor.connect("defeated", func(id: String) -> void:
		defeat_ids.append(id)
		reentrant_results.append(not bool(actor.call("take_damage", 5.0, Vector3.ZERO)["accepted"]))
		reentrant_results.append(not bool(actor.call("present_phase", "recovery", 0.0, Vector3.FORWARD)))
		var previous_pause: bool = paused
		paused = true
		reentrant_snapshot_results.append(actor.call("snapshot_state").is_empty() and String(actor.get("last_snapshot_error")).contains("transactions"))
		reentrant_snapshot_results.append(not String(actor.call("snapshot_error", {})).is_empty() and not bool(actor.call("restore_state", {})))
		paused = previous_pause
	)
	hero.global_position = Vector3(0.0, 0.1, 1.39)
	hero.velocity = Vector3.ZERO
	for closed_phase: String in ["idle", "warning", "lock", "active"]:
		_expect(bool(actor.call("present_phase", closed_phase, 0.5, Vector3.BACK)), "level controls the %s pose without an actor clock" % closed_phase)
		hero.shells = 0
		var hits: int = hero.slash(Vector3.FORWARD)
		_expect(hits == 0 and _near(actor.get("hp"), 30.0), "real no-ammo primary cannot damage the closed %s housing" % closed_phase)
		await create_timer(float(hero.stats.primary_cooldown) + 0.04).timeout
	_expect(bool(actor.call("present_phase", "recovery", 0.25, Vector3.BACK)), "manual recovery opens the reachable housing for this isolated fixture")
	var unchanged_hp: float = float(actor.get("hp"))
	for invalid_amount: float in [0.0, -1.0, NAN, INF]:
		var result: Dictionary = actor.call("take_damage", invalid_amount, Vector3.ZERO)
		_expect(not result["accepted"] and _near(result["hp_damage"], 0.0) and _near(actor.get("hp"), unchanged_hp), "nonpositive/nonfinite input rejects without partial target mutation")
	_expect(not bool(actor.call("take_damage", 3.0, Vector3(INF, 0.0, 0.0))["accepted"]), "nonfinite impulse rejects even though this anchored target does not travel")
	_expect(not bool(actor.call("present_phase", "unknown", 0.0, Vector3.BACK)) and not bool(actor.call("present_phase", "recovery", NAN, Vector3.BACK)) and not bool(actor.call("present_phase", "recovery", 0.5, Vector3.ZERO)) and actor.get("phase") == "recovery", "invalid external pose data preserves the existing opening")
	paused = true
	var paused_hit: Dictionary = actor.call("take_damage", 3.0, Vector3.ZERO)
	_expect(not paused_hit["accepted"] and _near(actor.get("hp"), unchanged_hp), "paused signal/direct callbacks cannot deal target damage")
	paused = false
	hero.dead = true
	_expect(not bool(actor.call("take_damage", 3.0, Vector3.ZERO)["accepted"]), "dead shared player cannot authorize target damage")
	hero.dead = false

	# Real player geometry, at either side of Heavy Edge's 1.8-unit boundary.
	hero.global_position = Vector3(0.0, 0.1, 1.41)
	hero.shells = 0
	_expect(hero.slash(Vector3.FORWARD) == 0 and _near(actor.get("hp"), 30.0), "shared primary geometry rejects the housing just outside Heavy reach")
	await create_timer(float(hero.stats.primary_cooldown) + 0.04).timeout
	hero.global_position = Vector3(0.0, 0.1, 1.39)
	hero.shells = 0
	_expect(hero.slash(Vector3.FORWARD) == 1 and _near(actor.get("hp"), 6.0), "one immediate no-ammo Heavy primary deals exactly one accepted 24-point hit inside reach")
	_expect(actor.global_position == anchor and defeat_ids.is_empty(), "accepted launch impulse neither moves the anchored housing nor defeats it early")
	await create_timer(float(hero.stats.primary_cooldown) + 0.04).timeout
	hero.shells = 0
	_expect(hero.slash(Vector3.FORWARD) == 1 and _near(actor.get("hp"), 0.0), "second ordinary no-ammo primary accepts only the remaining six HP")
	_expect(actor.global_position == anchor and actor.get("phase") == "defeated" and defeat_ids == ["A2-L1:fixture-scout"] and reentrant_results == [true, true], "lethal state commits a fixed collapsed target and emits one guarded defeat callback")
	_expect(reentrant_snapshot_results == [true, true], "even a paused defeat callback cannot capture or restore inside the actor damage transaction")
	var dead_hit: Dictionary = actor.call("take_damage", 100.0, Vector3.ZERO)
	_expect(not dead_hit["accepted"] and _near(dead_hit["hp_damage"], 0.0) and not dead_hit["target_alive_before_hit"] and defeat_ids.size() == 1, "dead housing accepts no duplicate hit or death event")
	var records: Array[Dictionary] = hero.get_world_action_records()
	var accepted_actions: int = 0
	var primary_only: bool = true
	for record: Dictionary in records:
		primary_only = primary_only and record["kind"] == "primary"
		if int(record.get("hits", 0)) > 0:
			accepted_actions += 1
	_expect(primary_only and accepted_actions == 2, "shared executed actions report two accepted primaries without a blast or duplicate target hit")
	_snapshot_checks(actor, hero, effects, anchor, defeat_ids)
	_fresh_visual_snapshot_checks(level, hero, effects, anchor)
	actor.call("cleanup")
	_expect(not bool(actor.call("is_armed")) and not bool(actor.call("configure", hero, effects, "A2-L1:revived")), "cleanup releases shared references and prevents revival of the retired instance")
	paused = true
	_expect(actor.call("snapshot_state").is_empty() and not String(actor.call("snapshot_error", {})).is_empty() and not bool(actor.call("restore_state", {})), "disarmed actor cannot capture, validate or restore snapshot state")
	_expect(actor.is_in_group("enemies"), "disarmed defeated tombstone retains enemy membership until the owner exits its tree")
	paused = false
	var old_actor: Node3D = actor
	game.call("reset_lab")
	await process_frame
	_expect(not is_instance_valid(old_actor) and get_nodes_in_group("enemies").is_empty(), "shared reset frees the target subtree and leaves the art preview without stale groups")
	game.queue_free()
	paused = false
	await process_frame
	print("Horsell isolated Scout target smoke: %d checks, %d failures; manual opening and actor snapshots only" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _snapshot_checks(actor: Node3D, hero: CinderPlayer, effects: PixelEffects, anchor: Vector3, defeat_ids: Array[String]) -> void:
	_expect(actor.call("snapshot_state").is_empty() and String(actor.get("last_snapshot_error")).contains("paused"), "live unpaused capture rejects even for a defeated configured actor")
	paused = true
	var hero_before: Dictionary = hero.snapshot_state()
	var defeated: Dictionary = _json(actor.call("snapshot_state"))
	var deaths_before: int = defeat_ids.size()
	_expect(not defeated.is_empty() and defeated["hp"] == 0.0 and defeated["phase"] == "defeated" and Codec.read_vector3(defeated["root_position"]) == anchor, "defeated actor remains capturable with finite JSON fields and its authored root")
	_expect(String(actor.call("snapshot_error", defeated)).is_empty() and bool(actor.call("restore_state", defeated)) and bool(actor.call("restore_state", defeated)) and defeat_ids.size() == deaths_before, "defeated JSON restoration is repeatable and silent")
	_expect(actor.is_in_group("enemies") and not actor.is_in_group("practice_targets"), "restored spent tombstone retains one enemies target membership without a reward group")
	paused = false
	_expect(not bool(actor.call("restore_state", defeated)) and not String(actor.call("snapshot_error", defeated)).is_empty(), "unpaused validation and restore reject without reviving the actor")
	paused = true
	var alive: Dictionary = defeated.duplicate(true)
	alive["max_hp"] = 41.25
	alive["hp"] = 7.25
	alive["phase"] = "lock"
	alive["phase_progress"] = 0.625
	alive["direction"] = [0.6, 0.0, 0.8]
	_expect(bool(actor.call("restore_state", _json(alive))) and _near(actor.get("max_hp"), 41.25) and _near(actor.get("hp"), 7.25) and actor.get("phase") == "lock" and actor.get("direction") == Codec.read_vector3(alive["direction"]) and actor.global_position == anchor, "earlier alive state restores HP/maxHP/phase/exact planar direction without reconfiguration")
	var before_configure: Dictionary = actor.call("snapshot_state")
	_expect(not bool(actor.call("configure", hero, effects, "A2-L1:fixture-scout")) and actor.call("snapshot_state") == before_configure, "reconfiguration cannot heal the restored low-HP actor or replace its authored identity")

	for restored_phase: String in ["idle", "warning", "lock", "active", "recovery", "defeated"]:
		var expected: Dictionary = alive.duplicate(true)
		expected["phase"] = restored_phase
		expected["hp"] = 0.0 if restored_phase == "defeated" else 7.25
		var transported: Dictionary = _json(expected)
		_expect(String(actor.call("snapshot_error", transported)).is_empty() and bool(actor.call("restore_state", transported)), "paused JSON restoration accepts coherent " + restored_phase)
		_expect(Codec.same_values(expected, actor.call("snapshot_state")) and defeat_ids.size() == deaths_before, "restored %s tuple captures identically without defeat/damage/clock advancement" % restored_phase)

	_expect(bool(actor.call("restore_state", _json(alive))), "return to the live low-HP checkpoint before invalid transport cases")
	var stable: Dictionary = actor.call("snapshot_state")
	var accepted_input: Dictionary = _json(stable)
	_expect(bool(actor.call("restore_state", accepted_input)), "valid defensive JSON input restores once")
	accepted_input["direction"][0] = 99.0
	accepted_input["root_position"][0] = 99.0
	var view: Dictionary = actor.call("snapshot_state")
	view["direction"][2] = 99.0
	view["root_position"][2] = 99.0
	_expect(actor.call("snapshot_state") == stable and actor.global_position == anchor, "mutating an accepted input or returned nested view cannot alter the actor")

	var invalid_fields: Array[Dictionary] = [
		{"name": "unknown API", "field": "api_revision", "value": "other-actor-1"},
		{"name": "boolean schema", "field": "schema_version", "value": true},
		{"name": "future schema", "field": "schema_version", "value": 3},
		{"name": "different authored ID", "field": "actor_id", "value": "A2-L1:other-scout"},
		{"name": "empty authored ID", "field": "actor_id", "value": ""},
		{"name": "zero maximum HP", "field": "max_hp", "value": 0.0},
		{"name": "nonfinite maximum HP", "field": "max_hp", "value": INF},
		{"name": "boolean maximum HP", "field": "max_hp", "value": true},
		{"name": "negative HP", "field": "hp", "value": -1.0},
		{"name": "HP above maximum", "field": "hp", "value": 42.0},
		{"name": "nonfinite HP", "field": "hp", "value": NAN},
		{"name": "boolean HP", "field": "hp", "value": false},
		{"name": "dead HP with live phase", "field": "hp", "value": 0.0},
		{"name": "live HP with defeated phase", "field": "phase", "value": "defeated"},
		{"name": "unknown phase", "field": "phase", "value": "preparing"},
		{"name": "negative progress", "field": "phase_progress", "value": -0.01},
		{"name": "progress above one", "field": "phase_progress", "value": 1.01},
		{"name": "nonfinite progress", "field": "phase_progress", "value": INF},
		{"name": "boolean progress", "field": "phase_progress", "value": true},
		{"name": "zero direction", "field": "direction", "value": [0.0, 0.0, 0.0]},
		{"name": "unnormalized direction", "field": "direction", "value": [2.0, 0.0, 0.0]},
		{"name": "nonplanar direction", "field": "direction", "value": [0.0, 0.6, 0.8]},
		{"name": "nonfinite direction", "field": "direction", "value": [NAN, 0.0, 1.0]},
		{"name": "short direction tuple", "field": "direction", "value": [0.0, 1.0]},
		{"name": "boolean direction component", "field": "direction", "value": [true, 0.0, 0.0]},
		{"name": "native vector direction", "field": "direction", "value": Vector3.BACK},
		{"name": "changed authored root", "field": "root_position", "value": Codec.vector3(anchor + Vector3(0.01, 0.0, 0.0))},
		{"name": "nonfinite root", "field": "root_position", "value": [0.0, INF, -0.4]},
		{"name": "native vector root", "field": "root_position", "value": anchor},
		{"name": "nonfinite body yaw", "field": "body_yaw", "value": NAN},
		{"name": "infinite body yaw", "field": "body_yaw", "value": INF},
		{"name": "boolean body yaw", "field": "body_yaw", "value": false},
		{"name": "string body yaw", "field": "body_yaw", "value": "0.0"},
		{"name": "tuple body yaw", "field": "body_yaw", "value": [0.0]},
		{"name": "out-of-range body yaw", "field": "body_yaw", "value": TAU},
	]
	for invalid: Dictionary in invalid_fields:
		var malformed: Dictionary = stable.duplicate(true)
		malformed[invalid["field"]] = invalid["value"]
		_expect_snapshot_rejected(actor, malformed, stable, anchor, defeat_ids, deaths_before, invalid["name"])
	var missing: Dictionary = stable.duplicate(true)
	missing.erase("root_position")
	_expect_snapshot_rejected(actor, missing, stable, anchor, defeat_ids, deaths_before, "missing root field")
	var missing_yaw: Dictionary = stable.duplicate(true)
	missing_yaw.erase("body_yaw")
	_expect_snapshot_rejected(actor, missing_yaw, stable, anchor, defeat_ids, deaths_before, "missing cosmetic body yaw")
	var legacy: Dictionary = stable.duplicate(true)
	legacy["api_revision"] = "act2-ray-scout-snapshot-1"
	legacy["schema_version"] = 1
	_expect_snapshot_rejected(actor, legacy, stable, anchor, defeat_ids, deaths_before, "unshipped legacy API/schema")
	var extra: Dictionary = stable.duplicate(true)
	extra["cooldown_s"] = 1.0
	_expect_snapshot_rejected(actor, extra, stable, anchor, defeat_ids, deaths_before, "unsupported parent clock field")

	actor.global_position = anchor + Vector3(0.2, 0.0, 0.1)
	_expect(actor.call("snapshot_state").is_empty() and String(actor.get("last_snapshot_error")).contains("fixed authored"), "capture refuses runtime drift from the stationary housing anchor")
	_expect(String(actor.call("snapshot_error", stable)).is_empty() and bool(actor.call("restore_state", stable)) and actor.global_position == anchor, "valid paused restoration reinstates the fixed authored root")

	hero.dead = true
	_expect(not actor.call("snapshot_state").is_empty() and bool(actor.call("restore_state", stable)) and defeat_ids.size() == deaths_before, "paused aggregate may capture and silently restore live actor state with a dead bound hero")
	paused = false
	_expect(not bool(actor.call("present_phase", "recovery", 0.5, Vector3.BACK)) and not bool(actor.call("take_damage", 2.0, Vector3.ZERO)["accepted"]), "dead shared hero still cannot reopen gameplay or authorize damage after snapshot restoration")
	paused = true
	_expect(bool(actor.call("restore_state", defeated)) and not actor.call("snapshot_state").is_empty() and defeat_ids.size() == deaths_before, "spent actor transport also remains valid and silent with a dead bound hero")
	hero.dead = false
	var live_recovery: Dictionary = stable.duplicate(true)
	live_recovery["phase"] = "recovery"
	_expect(bool(actor.call("restore_state", live_recovery)), "live recovery can rewind a spent actor through explicit paused state restoration")
	paused = false
	var restored_hit: Dictionary = actor.call("take_damage", 100.0, Vector3.ZERO)
	_expect(restored_hit["accepted"] and _near(restored_hit["hp_damage"], 7.25) and defeat_ids.size() == deaths_before + 1, "a rewound alive actor can later defeat once in its restored timeline")
	paused = true
	var spent: Dictionary = _json(actor.call("snapshot_state"))
	_expect(bool(actor.call("restore_state", spent)) and bool(actor.call("restore_state", spent)) and defeat_ids.size() == deaths_before + 1, "repeated defeated restoration does not replay the restored timeline's defeat")
	_expect(Codec.same_values(hero_before, hero.snapshot_state()), "actor transport and direct target lifecycle checks never heal, refill, damage or reward the shared player")
	paused = false


func _expect_snapshot_rejected(actor: Node3D, malformed: Dictionary, before: Dictionary, anchor: Vector3, defeat_ids: Array[String], deaths_before: int, description: String) -> void:
	var rig_before: Dictionary = _rig_transforms(actor)
	_expect(not String(actor.call("snapshot_error", malformed)).is_empty() and not bool(actor.call("restore_state", malformed)), "snapshot rejects " + description)
	_expect(actor.call("snapshot_state") == before and actor.global_position == anchor and defeat_ids.size() == deaths_before and _same_rig_transforms(rig_before, _rig_transforms(actor)), "rejection commits no HP/phase/direction/root/rig/lifecycle change: " + description)


func _fresh_visual_snapshot_checks(level: CinderLevel, hero: CinderPlayer, effects: PixelEffects, anchor: Vector3) -> void:
	paused = true
	var hero_before: Dictionary = hero.snapshot_state()
	var source: Node3D = ActorScript.new() as Node3D
	source.name = "FreshPoseSource"
	level.add_child(source)
	source.global_position = anchor
	_expect(bool(source.call("configure", hero, effects, "A2-L1:pose-roundtrip-scout")), "source configures at the fixed authored root for fresh-rig snapshot checks")
	var events: Array[String] = []
	source.connect("defeated", func(id: String) -> void: events.append("source:" + id))
	var latest_direction: Vector3 = Vector3(-0.6, 0.0, 0.8)
	_expect(bool(source.call("present_phase", "warning", 0.0, Vector3.RIGHT)) and bool(source.call("present_phase", "warning", 0.6, latest_direction)), "warning starts facing right then tracks a different exact direction")
	var chassis: Node3D = source.get_node("ScoutRig/ThreeLegChassis") as Node3D
	var swivel: Node3D = source.get_node("ScoutRig/ThreeLegChassis/TrackingMirrorSwivel") as Node3D
	_expect(_near(chassis.rotation.y, PI * 0.5) and _near(swivel.rotation.y, wrapf(atan2(latest_direction.x, latest_direction.z) - PI * 0.5, -PI, PI)), "actual chassis remains warning-entry planted while actual mirror swivel follows the later direction")
	for saved_phase: String in ["warning", "lock", "active", "recovery", "defeated"]:
		if saved_phase == "defeated":
			var spent: Dictionary = source.call("snapshot_state")
			spent["hp"] = 0.0
			spent["phase"] = "defeated"
			spent["phase_progress"] = 1.0
			_expect(bool(source.call("restore_state", spent)), "source can pose a spent checkpoint without emitting a defeat event")
		else:
			_expect(bool(source.call("present_phase", saved_phase, 0.6, latest_direction)), "source holds its planted heading in " + saved_phase)
		var transported: Dictionary = _json(source.call("snapshot_state"))
		var expected_rig: Dictionary = _rig_transforms(source)
		_expect(_near(transported["body_yaw"], PI * 0.5) and Codec.read_vector3(transported["direction"]).is_equal_approx(latest_direction), "JSON saves distinct planted body yaw and later mirror direction in " + saved_phase)
		var fresh: Node3D = ActorScript.new() as Node3D
		fresh.name = "FreshRestored" + saved_phase.capitalize()
		level.add_child(fresh)
		fresh.global_position = anchor
		_expect(bool(fresh.call("configure", hero, effects, "A2-L1:pose-roundtrip-scout")), "fresh " + saved_phase + " actor configures at the same authored root")
		fresh.connect("defeated", func(id: String) -> void: events.append("restored:" + id))
		_expect(bool(fresh.call("restore_state", transported)) and Codec.same_values(transported, fresh.call("snapshot_state")) and fresh.global_position == anchor, "fresh " + saved_phase + " actor restores exact JSON state silently")
		_expect(_same_rig_transforms(expected_rig, _rig_transforms(fresh)), "fresh " + saved_phase + " restore matches actual chassis, mirror hinge/swivel, housing and door transforms")
		_expect(bool(fresh.call("present_phase", saved_phase, 0.6 if saved_phase != "defeated" else 1.0, latest_direction)) and _same_rig_transforms(expected_rig, _rig_transforms(fresh)), "next held " + saved_phase + " sample preserves the restored warning-entry latch")
		_expect(events.is_empty() and Codec.same_values(hero_before, hero.snapshot_state()), "fresh " + saved_phase + " restoration emits no defeat, reward or shared player change")
		fresh.call("cleanup")
		fresh.free()
	for boundary_yaw: float in [-PI, PI]:
		var boundary_state: Dictionary = source.call("snapshot_state")
		boundary_state["body_yaw"] = boundary_yaw
		var boundary_json: Dictionary = _json(boundary_state)
		var boundary_actor: Node3D = ActorScript.new() as Node3D
		level.add_child(boundary_actor)
		boundary_actor.global_position = anchor
		_expect(bool(boundary_actor.call("configure", hero, effects, "A2-L1:pose-roundtrip-scout")), "fresh actor configures for exact %s PI yaw transport" % ("negative" if boundary_yaw < 0.0 else "positive"))
		boundary_actor.connect("defeated", func(id: String) -> void: events.append("boundary:" + id))
		_expect(String(boundary_actor.call("snapshot_error", boundary_json)).is_empty() and bool(boundary_actor.call("restore_state", boundary_json)) and Codec.same_values(boundary_state, boundary_actor.call("snapshot_state")), "exact %s PI yaw survives full-precision JSON and captures the saved latch" % ("negative" if boundary_yaw < 0.0 else "positive"))
		var boundary_chassis: Node3D = boundary_actor.get_node("ScoutRig/ThreeLegChassis") as Node3D
		_expect(boundary_chassis.rotation.is_equal_approx(Vector3(0.0, boundary_yaw, 0.0)) and boundary_chassis.global_transform.is_finite() and events.is_empty(), "exact %s PI restored chassis has the expected finite physical orientation without events" % ("negative" if boundary_yaw < 0.0 else "positive"))
		boundary_actor.call("cleanup")
		boundary_actor.free()
	var rig_before: Dictionary = _rig_transforms(source)
	var visual: Node3D = source.get_node("ScoutRig") as Node3D
	_expect(not bool(visual.call("restore_pose", "lock", 0.6, latest_direction, NAN)) and not bool(visual.call("restore_pose", "lock", 0.6, latest_direction, INF)) and _same_rig_transforms(rig_before, _rig_transforms(source)), "public visual restore rejects nonfinite yaw without changing actual transforms")
	var pending_visual: Node3D = VisualScript.new() as Node3D
	_expect(bool(pending_visual.call("restore_pose", "recovery", 0.6, latest_direction, PI * 0.5)), "explicit visual restore can retain a planted heading before build")
	source.free()
	# Compare the pre-ready path against a built reference with the same root.
	var reference: Node3D = VisualScript.new() as Node3D
	level.add_child(reference)
	level.add_child(pending_visual)
	reference.global_position = anchor
	pending_visual.global_position = anchor
	_expect(bool(reference.call("restore_pose", "recovery", 0.6, latest_direction, PI * 0.5)), "built visual reference accepts the exact saved cosmetic tuple")
	_expect(_near(pending_visual.call("get_body_yaw"), PI * 0.5) and (pending_visual.get_node("ThreeLegChassis") as Node3D).global_transform.is_equal_approx((reference.get_node("ThreeLegChassis") as Node3D).global_transform) and (pending_visual.get_node("ThreeLegChassis/TrackingMirrorSwivel") as Node3D).global_transform.is_equal_approx((reference.get_node("ThreeLegChassis/TrackingMirrorSwivel") as Node3D).global_transform), "ready applies the retained body latch and mirror direction to the actual fresh rig")
	var first_pose_visual: Node3D = VisualScript.new() as Node3D
	first_pose_visual.call("pose", "lock", 0.6, Vector3.RIGHT)
	level.add_child(first_pose_visual)
	first_pose_visual.global_position = anchor
	_expect(_near(first_pose_visual.call("get_body_yaw"), PI * 0.5) and _near((first_pose_visual.get_node("ThreeLegChassis") as Node3D).rotation.y, PI * 0.5) and _near((first_pose_visual.get_node("ThreeLegChassis/TrackingMirrorSwivel") as Node3D).rotation.y, 0.0), "normal pre-ready first lock pose preserves original chassis-facing initialization and aligned mirror")
	first_pose_visual.free()
	_expect(events.is_empty() and Codec.same_values(hero_before, hero.snapshot_state()), "all fresh visual fixtures leave shared events and player state unchanged")
	reference.free()
	pending_visual.free()
	paused = false


func _rig_transforms(actor: Node3D) -> Dictionary:
	var values: Dictionary = {}
	for path: String in RIG_PATHS:
		var part: Node3D = actor.get_node(path) as Node3D
		values[path] = part.global_transform
	# Rotation checks expose a planted-yaw regression directly, independently
	# of any dictionary returned by the actor/visual snapshot getters.
	values["chassis_rotation"] = (actor.get_node(RIG_PATHS[0]) as Node3D).rotation
	values["swivel_rotation"] = (actor.get_node(RIG_PATHS[2]) as Node3D).rotation
	return values


func _same_rig_transforms(expected: Dictionary, actual: Dictionary) -> bool:
	if expected.size() != actual.size():
		return false
	for key: String in expected:
		if not actual.has(key) or not expected[key].is_equal_approx(actual[key]):
			return false
	return true


func _json(value: Dictionary) -> Dictionary:
	var decoded: Variant = JSON.parse_string(JSON.stringify(value, "", true, true))
	return decoded if decoded is Dictionary else {}


func _near(actual: Variant, expected: float) -> bool:
	return absf(float(actual) - expected) < 0.00001


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)
