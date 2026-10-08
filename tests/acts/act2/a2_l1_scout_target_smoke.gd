extends SceneTree
## Isolated target-opening fixture in the actual shared Horsell shell.
## Manual recovery and fixture positioning do not certify a Ray fight, threat
## scheduler, gesture trace, campaign checkpoint, human balance or full level.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const ActorScript: Script = preload("res://scripts/acts/act2/ray_scout_actor.gd")
const LevelPath: String = "res://scenes/acts/act2/a2_l1.tscn"
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
	_expect(not bool(actor.call("configure", hero, effects, "bad id")) and bool(actor.call("configure", hero, effects, "A2-L1:fixture-scout")), "configuration requires a stable authored ID and valid entered shared references")
	_expect(not bool(actor.call("configure", hero, effects, "A2-L1:replacement")) and actor.get("actor_id") == "A2-L1:fixture-scout", "repeat configuration cannot change identity or reset health")
	_expect(get_nodes_in_group("enemies") == [actor] and not actor.is_in_group("practice_targets"), "one low-housing root is registered once, with no duplicate practice target")
	_expect(not actor.is_processing() and not actor.is_physics_processing() and _near(actor.get("knockback_scale"), 0.0), "stationary adapter has no independent clock or hidden momentum")
	var defeat_ids: Array[String] = []
	var reentrant_results: Array[bool] = []
	actor.connect("defeated", func(id: String) -> void:
		defeat_ids.append(id)
		reentrant_results.append(not bool(actor.call("take_damage", 5.0, Vector3.ZERO)["accepted"]))
		reentrant_results.append(not bool(actor.call("present_phase", "recovery", 0.0, Vector3.FORWARD)))
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
	actor.call("cleanup")
	_expect(not bool(actor.call("is_armed")) and not bool(actor.call("configure", hero, effects, "A2-L1:revived")), "cleanup releases shared references and prevents revival of the retired instance")
	var old_actor: Node3D = actor
	game.call("reset_lab")
	await process_frame
	_expect(not is_instance_valid(old_actor) and get_nodes_in_group("enemies").is_empty(), "shared reset frees the target subtree and leaves the art preview without stale groups")
	game.queue_free()
	paused = false
	await process_frame
	print("Horsell isolated Scout target smoke: %d checks, %d failures; manual opening only" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _near(actual: Variant, expected: float) -> bool:
	return absf(float(actual) - expected) < 0.00001


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)
