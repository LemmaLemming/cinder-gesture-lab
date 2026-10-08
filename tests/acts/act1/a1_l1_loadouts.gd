extends SceneTree
## Opening-only loadout witnesses. Staged workshop approaches isolate reach;
## this is neither full route traversal nor loading-arm acceptance.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const LevelPath: String = "res://scenes/acts/act1/a1_l1.tscn"
const CLOTHES: Array[Array] = [
	["CLOTH-J1", "CLOTH-P2", "CLOTH-S2"], # slowest travel, longest landing
	["CLOTH-J2", "CLOTH-P0", "CLOTH-S1"], # fastest travel, reduced health
	["CLOTH-J1", "CLOTH-P1", "CLOTH-S0"], # longest primary cooldown
]
const WEAPONS: Array[String] = ["WEAPON-01", "WEAPON-02", "WEAPON-03", "WEAPON-04"]

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game: Node = MainScene.instantiate()
	game.set("level_scene_path", LevelPath)
	root.add_child(game)
	for clothes: Array in CLOTHES:
		for weapon: String in WEAPONS:
			game.call("reset_lab")
			var hero: CinderPlayer = game.get("player") as CinderPlayer
			var level: CinderLevel = game.get("active_level") as CinderLevel
			if hero == null or level == null:
				_expect(false, "shared preview prepares the opening")
				quit(1)
				return
			paused = true
			var equipped: bool = hero.equip_item(weapon)
			for item: String in clothes:
				equipped = hero.equip_item(item) and equipped
			_expect(equipped, "legal static loadout equips at a paused safe boundary: " + str(clothes) + " / " + weapon)
			game.call("resume_lab")
			await create_timer(0.1).timeout
			var marker: Vector3 = level.call("dash_marker_position")
			_expect(hero.request_dash(marker - hero.global_position), "loadout accepts the ordinary first dash")
			await create_timer(0.4).timeout
			_expect(int(level.get("beat_index")) == 1, "real legal dash landing completes the broad marker without exact-angle enforcement")
			hero.shells = 0
			var hall_direction: Vector3 = game.call("screen_to_direction", Vector2(160, 220))
			_expect(hero.slash(hall_direction) == 1 and int(level.get("beat_index")) == 2, "literal down-right primary reaches hall target from this loadout's actual landing without ammo")
			await create_timer(0.5).timeout
			var targets: Dictionary = level.get("targets")
			var workshop: PracticeTarget = targets["workshop"] as PracticeTarget
			var side: float = -1.0 if weapon in ["WEAPON-01", "WEAPON-03"] else 1.0
			# Reach-only fixture staging. Both broad sides remain collision-free.
			hero.global_position = workshop.global_position + Vector3(side, 0.1, 1.05)
			await physics_frame
			hero.shells = 0
			var approach_direction: Vector3 = workshop.global_position - hero.global_position
			approach_direction.y = 0.0
			_expect(hero.slash(approach_direction) == 1 and int(level.get("beat_index")) == 3, "ordinary primary clears the staged workshop side with empty shells")
			_expect(not level.is_completed() and not level.snapshot_state().is_empty(), "extreme opening does not pretend to complete the unpublished arm exchange")
	# The last genuine primary also starts a shared procedural audio voice.
	# Let that voice finish before closing the engine, then release the scene.
	await create_timer(0.5).timeout
	game.queue_free()
	paused = false
	await process_frame
	print("A1-L1 opening loadouts: %d checks, %d failures; 12 static extreme combinations" % [_checks, _failures])
	print("NOT TESTED: full traversal, loading arm, campaign retry or presentation compatibility.")
	quit(0 if _failures == 0 else 1)


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	print("PASS: " if condition else "FAIL: ", description)
	if not condition:
		_failures += 1
