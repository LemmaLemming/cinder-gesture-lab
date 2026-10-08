extends Node
## Parent-owned presentation check after authoritative Player/Scheduler updates
## and before the published SmokeBank contact consumer at priority100.
## This node has no clock, damage, phase or lease authority.
const GUARD_PATH: String = "res://scripts/acts/act2/ruined_house_bank_guard.gd"
const PHYSICS_PRIORITY: int = 99
var _callback: Callable = Callable()
var _owned_script: Script
var _configured: bool = false

func configure(callback: Callable) -> bool:
	if is_inside_tree() or _configured or not callback.is_valid() or get_script() == null or get_script().resource_path != GUARD_PATH: return false
	_callback = callback
	_owned_script = get_script()
	_configured = true
	process_physics_priority = PHYSICS_PRIORITY
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_physics_process(true)
	return true

func binding_matches(callback: Callable) -> bool:
	return _configured and is_inside_tree() and not is_queued_for_deletion() and get_script() == _owned_script and _owned_script != null and _owned_script.resource_path == GUARD_PATH and process_physics_priority == PHYSICS_PRIORITY and is_physics_processing() and process_mode == Node.PROCESS_MODE_PAUSABLE and _callback.is_valid() and callback.is_valid() and _callback == callback

func _physics_process(_delta: float) -> void:
	if binding_matches(_callback): _callback.call()
