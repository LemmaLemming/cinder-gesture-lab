extends "res://scripts/game.gd"
## INERT TEST TEXT. Canonical Game view/HUD/camera/Player/input are inherited.
const TestFocusHouse = preload("res://tests/acts/act2/fixtures/a2_l3_difficulty_focus_house.gd")
func get_difficulty_preference() -> String: return "challenge"
func _create_level_instance() -> CinderLevel:
	var level: CinderLevel = TestFocusHouse.new()
	level.name = "DeclaredTESTBossComponent"
	level.level_id = "A2-L3"
	level.local_snapshot_version = 1
	level.objective_text = "TEST FOCUSED B02 / NO EARNED PREFIX"
	var spawn := Marker3D.new()
	spawn.name = "PlayerSpawn"
	spawn.position = Vector3(0.0, 0.1, 2.2) # Original marker; Host supplies declared XZ and derived supported Y once.
	level.add_child(spawn)
	return level
