extends CinderLevel
## Test fixture only; this is not an act encounter or campaign asset.

const EnemyScript = preload("res://scripts/enemy.gd")

var enter_count: int = 0
var exit_count: int = 0
var observed_actions: int = 0


func _on_enter_level() -> void:
	enter_count += 1
	hero.fired.connect(_observe_action)
	var runtime_prop := Node3D.new()
	runtime_prop.name = "RuntimeProp"
	add_child(runtime_prop)
	var enemy := EnemyScript.new() as AshEnemy
	enemy.name = "LevelEnemy"
	enemy.configure(hero, effects)
	add_child(enemy)
	enemy.global_position = spawn_position() + Vector3(4.0, 0.0, 0.0)
	enemy.set_physics_process(false)


func _on_exit_level() -> void:
	exit_count += 1
	if is_instance_valid(hero) and hero.fired.is_connected(_observe_action):
		hero.fired.disconnect(_observe_action)


func _observe_action(_kind: String) -> void:
	observed_actions += 1
