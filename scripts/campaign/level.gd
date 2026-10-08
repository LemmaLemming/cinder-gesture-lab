class_name CinderLevel
extends Node3D
## A level owns its floor, scenery, encounter nodes and instance-local state.
## The game shell owns the single player, camera, input, HUD and shared effects.
## Spawn marks the player's feet, ordinarily 0.1 units above the floor surface.

@export var spawn_path: NodePath = NodePath("PlayerSpawn")
@export var objective_text: String = "LEVEL PREVIEW"

var hero: CinderPlayer
var effects: PixelEffects
var _entered: bool = false


func contract_error() -> String:
	if not get_node_or_null(spawn_path) is Marker3D:
		return "Level requires a Marker3D at spawn_path: " + String(spawn_path)
	return ""


func spawn_position() -> Vector3:
	return (get_node(spawn_path) as Marker3D).global_position


func enter_level(player: CinderPlayer, shared_effects: PixelEffects) -> void:
	if _entered:
		return
	hero = player
	effects = shared_effects
	_entered = true
	_on_enter_level()


func exit_level() -> void:
	if not _entered:
		return
	_on_exit_level()
	_entered = false
	hero = null
	effects = null


func _on_enter_level() -> void:
	# Configure encounter nodes here, after the shared player is available.
	pass


func _on_exit_level() -> void:
	# Disconnect signals to shared nodes; keep runtime nodes beneath this root.
	pass


func _exit_tree() -> void:
	exit_level()
