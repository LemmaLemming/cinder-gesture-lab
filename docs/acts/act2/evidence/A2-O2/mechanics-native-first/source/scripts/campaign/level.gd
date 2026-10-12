class_name CinderLevel
extends Node3D
## A level owns its floor, scenery, encounter nodes and instance-local state.
## The game shell owns the single player, camera, input, HUD and shared effects.
## Spawn marks the player's feet, ordinarily 0.1 units above the floor surface.
## Progression signals are requests: the shell owns transitions and durable saves.
## Local snapshots never contain player resources or imply checkpoint healing.

signal completion_requested(level_id: String, completion_id: String)
signal contact_exit_requested(level_id: String, exit_id: String)
signal checkpoint_requested(level_id: String, checkpoint_id: String, boundary_kind: String)

const API_REVISION: String = "campaign-level-1"
const RESTORE_CANDIDATE_API_REVISION: String = "level-restore-candidate-1"
const RESTORE_PRESENTATION_API_REVISION: String = "level-restore-presentation-1"
const PRESENTATION_HUD_SCRIPT = preload("res://scripts/hud.gd")
const SNAPSHOT_SCHEMA_VERSION: int = 1
const CHECKPOINT_KINDS: Array[String] = ["encounter", "boss_phase"]

@export var spawn_path: NodePath = NodePath("PlayerSpawn")
@export var objective_text: String = "LEVEL PREVIEW"
## Empty identity preserves anonymous lab/fixture previews. Campaign registration
## requires a canonical nonempty identity; a level cannot change it after entry.
@export var level_id: String = ""
@export_range(1, 2147483647, 1) var local_snapshot_version: int = 1

var hero: CinderPlayer
var effects: PixelEffects
## Optional shared shell exposes documented public input/campaign services.
## Standalone contract fixtures may omit it. Levels never read private timers.
var shared_shell: Node
## Optional pure actual-world corner provider; shared shell owns the camera.
var last_camera_framing_error: String = ""
var last_snapshot_error: String = ""
var _entered: bool = false
var _lifecycle_busy: bool = false
var _restoring: bool = false
var _snapshotting: bool = false
var _validating: bool = false
var _presentation_validating: bool = false
var _dispatching: bool = false
var _restore_candidate: bool = false
var _restore_candidate_ready: bool = false
var _active_level_id: String = ""
var _active_scene_path: String = ""
var _active_local_version: int = 1
var _completed: bool = false
var _completion_id: String = ""
var _contact_exit_id: String = ""
var _checkpoint_id: String = ""
var _checkpoint_kind: String = ""
var _checkpoint_ids: Dictionary = {}


## Supply forecast source/art/whole-footprint/landing/opening corners before
## admission and retain them through recovery. Empty preserves normal follow.
## The shell adds actual player bounds; fit alone does not authorize damage.
func camera_framing_points() -> Array:
	last_camera_framing_error = ""
	var points: Variant = _camera_framing_points()
	if not points is Array or points.size() > 224:
		last_camera_framing_error = "Camera framing requires at most 224 actual world corners"
		return []
	for point: Variant in points:
		if not point is Vector3 or not point.is_finite() or maxf(absf(point.x), maxf(absf(point.y), absf(point.z))) > 1024.0:
			last_camera_framing_error = "Camera framing corners must be finite bounded world positions"
			return []
	return points.duplicate()


func _camera_framing_points() -> Array:
	return []


func contract_error() -> String:
	if not get_node_or_null(spawn_path) is Marker3D:
		return "Level requires a Marker3D at spawn_path: " + String(spawn_path)
	if not level_id.is_empty():
		var canonical_id := RegEx.new()
		canonical_id.compile("^A[1-3]-(L[1-5]|O[1-3])$")
		var matched: RegExMatch = canonical_id.search(level_id)
		if matched == null or matched.get_string() != level_id:
			return "Level identity must be a canonical main/optional ID: " + level_id
	if local_snapshot_version < 1:
		return "Local snapshot version must be positive"
	return ""


func spawn_position() -> Vector3:
	return (get_node(spawn_path) as Marker3D).global_position


func enter_level(player: CinderPlayer, shared_effects: PixelEffects, shell: Node = null) -> void:
	if _entered or _lifecycle_busy or _state_hook_busy() or not is_instance_valid(player) or not is_instance_valid(shared_effects):
		return
	if not contract_error().is_empty():
		return
	_lifecycle_busy = true
	hero = player
	effects = shared_effects
	shared_shell = shell
	_active_level_id = level_id
	_active_scene_path = scene_file_path
	_active_local_version = local_snapshot_version
	_entered = true
	_on_enter_level()
	_lifecycle_busy = false


## Fresh paused construction precedes PURE saved-state validation. This builds
## only immutable native bindings; ordinary quiet restore applies saved state.
func enter_restore_candidate(player: CinderPlayer, shared_effects: PixelEffects, shell: Node, snapshot: Dictionary, saved_player: Dictionary) -> bool:
	last_snapshot_error = ""
	if not is_inside_tree() or not get_tree().paused or _entered or _lifecycle_busy or _state_hook_busy() or not is_instance_valid(player) or not is_instance_valid(shared_effects):
		last_snapshot_error = "Restore construction requires a fresh paused nonplayable level"
		return false
	last_snapshot_error = contract_error()
	if not last_snapshot_error.is_empty(): return false
	_lifecycle_busy = true
	hero = player
	effects = shared_effects
	shared_shell = shell
	_active_level_id = level_id
	_active_scene_path = scene_file_path
	_active_local_version = local_snapshot_version
	_entered = true
	_restore_candidate = true
	_restore_candidate_ready = false
	last_snapshot_error = _snapshot_envelope_error(snapshot)
	if last_snapshot_error.is_empty(): last_snapshot_error = player.snapshot_error(saved_player)
	if last_snapshot_error.is_empty():
		last_snapshot_error = _on_enter_restore_candidate((snapshot.local as Dictionary).duplicate(true), saved_player.duplicate(true))
	_lifecycle_busy = false
	# Keep failed partial construction entered for ordinary exit cleanup. The
	# Shell discards it; it cannot become playable or request progression.
	return last_snapshot_error.is_empty()


## An optional PURE optical gate after the whole Player -> local quiet commit.
## The Shell supplies the saved-position native candidate camera and an actual
## canonical HUD laid out at the main viewport's pixel size. This is not a
## saved-state prevalidator or a future-fit acceptance stamp. Legacy levels
## retain an empty hook; opted levels must keep their live capture guard too.
func restore_candidate_presentation_error(framing_camera: Camera3D, framing_hud: GameHUD) -> String:
	if not is_inside_tree() or not get_tree().paused or not _restore_candidate or not _restore_candidate_ready or not _can_access_state() or _dispatching:
		return "Presentation validation requires a fully restored paused nonplayable candidate"
	var error: String = _restore_candidate_presentation_binding_error(framing_camera, framing_hud)
	if not error.is_empty(): return error
	var bound_hero: CinderPlayer = hero
	var bound_effects: PixelEffects = effects
	var bound_shell: Node = shared_shell
	_presentation_validating = true
	error = _restore_candidate_presentation_error(framing_camera, framing_hud)
	if error.is_empty():
		if not is_inside_tree() or is_queued_for_deletion() or not get_tree().paused or not _entered or not _restore_candidate or not _restore_candidate_ready or hero != bound_hero or effects != bound_effects or shared_shell != bound_shell or level_id != _active_level_id or scene_file_path != _active_scene_path or local_snapshot_version != _active_local_version:
			error = "Presentation hook changed the paused candidate lifecycle or bindings"
		else:
			error = _restore_candidate_presentation_binding_error(framing_camera, framing_hud)
	_presentation_validating = false
	return error


func _restore_candidate_presentation_binding_error(framing_camera: Camera3D, framing_hud: GameHUD) -> String:
	if not is_instance_valid(hero) or not is_instance_valid(effects) or not is_instance_valid(shared_shell) or not is_instance_valid(framing_camera) or not is_instance_valid(framing_hud):
		return "Presentation validation requires actual candidate actor, camera, HUD and Shell"
	for node: Node in [hero, effects, shared_shell, framing_camera, framing_hud]:
		if not node.is_inside_tree() or not node.is_node_ready() or node.is_queued_for_deletion() or node.get_tree() != get_tree():
			return "Presentation validation requires ready retained native bindings"
	if framing_camera.get_script() != null or framing_hud.get_script() != PRESENTATION_HUD_SCRIPT or framing_hud.custom_viewport != null:
		return "Presentation validation requires the native camera and canonical actual HUD"
	if framing_camera.get_viewport() != get_viewport() or hero.get_viewport() != get_viewport() or framing_camera.get_world_3d() != get_world_3d() or hero.get_world_3d() != get_world_3d() or get_viewport().get_camera_3d() != framing_camera:
		return "Presentation camera and actor must belong to this candidate's current viewport/world"
	return ""


## Pure hook: inspect actual restored sources/cues/Player bounds with the
## explicit context camera APIs. Do not mutate, emit, yield, request admission,
## move the camera or replace a failed check with an accepted plan. No hook is
## run on the installed donor. Mechanical saved-unit proof remains mandatory.
func _restore_candidate_presentation_error(_framing_camera: Camera3D, _framing_hud: GameHUD) -> String:
	return ""


func finish_restore_candidate() -> bool:
	if not _restore_candidate: return true
	if not is_inside_tree() or not get_tree().paused or not _can_access_state() or not _restore_candidate_ready:
		return false
	_restore_candidate = false
	_restore_candidate_ready = false
	return true


func is_restore_candidate() -> bool:
	return _restore_candidate and is_inside_tree() and get_tree().paused


## Opt in when an earlier checkpoint's installed native topology can differ
## from the active donor. The Shell then validates against fresh construction.
func restore_candidate_construction_required() -> bool:
	return false


func exit_level() -> void:
	if not _entered or _lifecycle_busy or _state_hook_busy():
		return
	_lifecycle_busy = true
	# Disarm callbacks before cleanup, while retaining references for disconnects.
	_entered = false
	_on_exit_level()
	hero = null
	effects = null
	shared_shell = null
	_restore_candidate = false
	_restore_candidate_ready = false
	_lifecycle_busy = false


func is_completed() -> bool:
	return _completed


func current_checkpoint() -> Dictionary:
	return {"id": _checkpoint_id, "kind": _checkpoint_kind}


func request_completion(completion_id: String = "complete") -> bool:
	if not _can_request_event() or _completed or not _valid_event_id(completion_id):
		return false
	_completed = true
	_completion_id = completion_id
	_dispatching = true
	completion_requested.emit(_active_level_id, completion_id)
	_dispatching = false
	return true


func request_contact_exit(exit_id: String, body: Node3D) -> bool:
	# Contact is distinct from an attack. Only the live shared actor may cross an
	# authored, completed level's exit; scenery/other actors cannot trigger it.
	if not _can_request_event() or body != hero or not _completed or not _contact_exit_id.is_empty() or not _valid_event_id(exit_id):
		return false
	_contact_exit_id = exit_id
	_dispatching = true
	contact_exit_requested.emit(_active_level_id, exit_id)
	_dispatching = false
	return true


func request_checkpoint(checkpoint_id: String, boundary_kind: String = "encounter") -> bool:
	if not _can_request_event() or _completed or not _valid_event_id(checkpoint_id) or not CHECKPOINT_KINDS.has(boundary_kind) or _checkpoint_ids.has(checkpoint_id):
		return false
	_checkpoint_ids[checkpoint_id] = boundary_kind
	_checkpoint_id = checkpoint_id
	_checkpoint_kind = boundary_kind
	_dispatching = true
	checkpoint_requested.emit(_active_level_id, checkpoint_id, boundary_kind)
	_dispatching = false
	return true


## Explicit native capture context for FRESH ordinary Shell entry only.
## Default preserves every existing writer. An opted owner overrides this
## virtual method and factors its normal snapshot_state writer so both paths
## retain complete live mechanical/optical guards; supplied HUD is actual,
## not an accepted stamp. Hooks must not mutate, emit, yield or reenter Shell.
func snapshot_state_for_presentation(_framing_camera: Camera3D, _framing_hud: GameHUD) -> Dictionary:
	return snapshot_state()


func snapshot_state() -> Dictionary:
	last_snapshot_error = ""
	if not _can_access_state():
		last_snapshot_error = "Local state is available only after entry, outside lifecycle/state hooks"
		return {}
	_snapshotting = true
	var local_state: Dictionary = _capture_local_state()
	var error: String = _value_error(local_state)
	if error.is_empty():
		error = _local_snapshot_error(local_state.duplicate(true))
	var snapshot: Dictionary = {}
	if error.is_empty():
		snapshot = {
			"api_revision": API_REVISION,
			"schema_version": SNAPSHOT_SCHEMA_VERSION,
			"level_id": _active_level_id,
			"scene_path": _active_scene_path,
			"local_snapshot_version": _active_local_version,
			"progress": {
				"completed": _completed, "completion_id": _completion_id,
				"contact_exit_id": _contact_exit_id,
				"checkpoint_id": _checkpoint_id, "checkpoint_kind": _checkpoint_kind,
				"checkpoint_ids": _checkpoint_ids.duplicate(true),
			},
			"local": local_state.duplicate(true),
		}
	_snapshotting = false
	last_snapshot_error = error
	return snapshot


func snapshot_error(snapshot: Dictionary) -> String:
	if not _can_access_state():
		return "Restore validation requires an entered level outside lifecycle/state hooks"
	_validating = true
	var error: String = _snapshot_error(snapshot)
	_validating = false
	return error


## Pure aggregate prevalidation after the caller validates the saved shared
## actor. Authored validators may prove local samples against its saved motion
## instead of the fresh/live hero. This does not restore or duplicate actor
## state. Capture and restore still validate against the actual current hero.
func snapshot_error_with_player(snapshot: Dictionary, saved_player: Dictionary) -> String:
	if not _can_access_state():
		return "Aggregate validation requires an entered level outside lifecycle/state hooks"
	_validating = true
	var error: String = _snapshot_envelope_error(snapshot)
	if error.is_empty():
		error = _value_error(saved_player)
	if error.is_empty():
		# Select one local hook only: the legacy live-player hook can correctly
		# reject a fresh candidate before staged-player geometry is considered.
		error = _local_snapshot_error_with_player((snapshot["local"] as Dictionary).duplicate(true), saved_player.duplicate(true))
	_validating = false
	return error


func restore_state(snapshot: Dictionary) -> bool:
	last_snapshot_error = ""
	if not _can_access_state() or _dispatching:
		last_snapshot_error = "Restore requires an entered level outside callbacks/state hooks"
		return false
	_restoring = true
	last_snapshot_error = _snapshot_error(snapshot)
	if not last_snapshot_error.is_empty():
		_restoring = false
		return false
	# Validation precedes all mutation. The level's validator must check every
	# local field and required runtime node. Its restore hook must then commit
	# the validated state without failing; the base cannot roll back arbitrary
	# level-owned node mutations. Neither hook may emit progression events.
	var accepted: Dictionary = snapshot.duplicate(true)
	_restore_local_state((accepted["local"] as Dictionary).duplicate(true))
	var progress: Dictionary = accepted["progress"]
	_completed = progress["completed"]
	_completion_id = progress["completion_id"]
	_contact_exit_id = progress["contact_exit_id"]
	_checkpoint_id = progress["checkpoint_id"]
	_checkpoint_kind = progress["checkpoint_kind"]
	_checkpoint_ids = (progress["checkpoint_ids"] as Dictionary).duplicate(true)
	if _restore_candidate: _restore_candidate_ready = true
	_restoring = false
	last_snapshot_error = ""
	return true


func _snapshot_error(snapshot: Dictionary) -> String:
	var error: String = _snapshot_envelope_error(snapshot)
	if not error.is_empty():
		return error
	return _local_snapshot_error((snapshot["local"] as Dictionary).duplicate(true))


func _snapshot_envelope_error(snapshot: Dictionary) -> String:
	# The envelope is a transport wrapper, not an extra local nesting level.
	# Its payload roots use depth 0, matching capture's local-state validation.
	var error: String = _value_error(snapshot, -1)
	if not error.is_empty():
		return error
	if snapshot.get("api_revision") != API_REVISION or not _version_matches(snapshot.get("schema_version"), SNAPSHOT_SCHEMA_VERSION):
		return "Unsupported level snapshot API/schema version"
	if snapshot.get("level_id") != _active_level_id or snapshot.get("scene_path") != _active_scene_path:
		return "Level snapshot identity does not match this authored level"
	if not _version_matches(snapshot.get("local_snapshot_version"), _active_local_version):
		return "Unsupported local snapshot version"
	if not snapshot.get("progress") is Dictionary or not snapshot.get("local") is Dictionary:
		return "Level snapshot requires progress and local dictionaries"
	var progress: Dictionary = snapshot["progress"]
	if not progress.get("completed") is bool:
		return "Completion state must be boolean"
	for key: String in ["completion_id", "contact_exit_id", "checkpoint_id", "checkpoint_kind"]:
		if not progress.get(key) is String:
			return "Missing or invalid progression field: " + key
	if progress["completed"]:
		if not _valid_event_id(progress["completion_id"]):
			return "Completed snapshots require a completion ID"
	elif not progress["completion_id"].is_empty() or not progress["contact_exit_id"].is_empty():
		return "Incomplete snapshots cannot contain completion/exit IDs"
	if not progress["contact_exit_id"].is_empty() and not _valid_event_id(progress["contact_exit_id"]):
		return "Invalid contact-exit ID"
	if not progress.get("checkpoint_ids") is Dictionary:
		return "Snapshot requires checkpoint request history"
	var checkpoint_ids: Dictionary = progress["checkpoint_ids"]
	for checkpoint: String in checkpoint_ids:
		if not _valid_event_id(checkpoint) or not CHECKPOINT_KINDS.has(checkpoint_ids[checkpoint]):
			return "Invalid checkpoint request history"
	if progress["checkpoint_id"].is_empty():
		if not progress["checkpoint_kind"].is_empty() or not checkpoint_ids.is_empty():
			return "Empty current checkpoint requires empty history"
	elif not checkpoint_ids.has(progress["checkpoint_id"]) or checkpoint_ids[progress["checkpoint_id"]] != progress["checkpoint_kind"]:
		return "Current checkpoint must match its recorded boundary"
	return ""


func _can_access_state() -> bool:
	return _entered and not _lifecycle_busy and not _state_hook_busy() and is_instance_valid(hero) and is_instance_valid(effects) and level_id == _active_level_id and scene_file_path == _active_scene_path and local_snapshot_version == _active_local_version


func _can_request_event() -> bool:
	return _can_access_state() and not _dispatching and not _restore_candidate and not hero.dead


func _state_hook_busy() -> bool:
	return _restoring or _snapshotting or _validating or _presentation_validating


func _valid_event_id(value: String) -> bool:
	if value.is_empty() or value.length() > 128:
		return false
	var identifier := RegEx.new()
	identifier.compile("^[A-Za-z0-9][A-Za-z0-9_:/.-]*$")
	var matched: RegExMatch = identifier.search(value)
	return matched != null and matched.get_string() == value


func _version_matches(value: Variant, expected: int) -> bool:
	# JSON round-trips may represent integral version numbers as floats.
	return (value is int or value is float) and value == expected


func _value_error(value: Variant, depth: int = 0) -> String:
	# JSON-compatible local data is copied by value and cannot retain nodes,
	# resources, callables or other shared references. Bound nesting/cycles.
	if depth > 32:
		return "Snapshot nesting exceeds 32 levels"
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return ""
		TYPE_FLOAT:
			return "" if is_finite(value) else "Snapshot numbers must be finite"
		TYPE_ARRAY:
			for entry: Variant in value:
				var error: String = _value_error(entry, depth + 1)
				if not error.is_empty():
					return error
		TYPE_DICTIONARY:
			for key: Variant in value:
				if not key is String:
					return "Snapshot dictionary keys must be strings"
				var error: String = _value_error(value[key], depth + 1)
				if not error.is_empty():
					return error
		_:
			return "Snapshot contains a non-JSON value"
	return ""


func _capture_local_state() -> Dictionary:
	# Include all relevant instance-owned enemies, supplies, clocks and RNG.
	# Use JSON-compatible values; encode vectors/transforms explicitly as arrays.
	return {}


func _local_snapshot_error(_state: Dictionary) -> String:
	# Override alongside capture/restore. Validate the entire local payload and
	# required nodes without mutating live state; rejection must be atomic.
	return "" if _state.is_empty() else "This level has no declared local snapshot fields"


func _local_snapshot_error_with_player(state: Dictionary, _saved_player: Dictionary) -> String:
	# Backward compatible default for actor-independent local state. Override
	# only when local state must match the already validated saved actor. Both
	# arguments are defensive JSON copies; validate the whole local payload
	# without live mutation, callbacks or retaining a second actor snapshot.
	return _local_snapshot_error(state)


func _restore_local_state(_state: Dictionary) -> void:
	# Commit only validated local state. No healing, player resets or rewards.
	pass


func _on_enter_level() -> void:
	# Configure encounter nodes here, after the shared player is available.
	pass


## Override only when ordinary entry cannot construct saved native bindings.
## First check the closed construction descriptor against authored definitions.
## Build real ready recipients/installed resources, with no activation, signals,
## saved HP/clocks/history or never-entitled future resources. Full pure local
## validation and Player -> level quiet restoration still run afterward.
func _on_enter_restore_candidate(_local: Dictionary, _saved_player: Dictionary) -> String:
	_on_enter_level()
	return ""


func _on_exit_level() -> void:
	# Disconnect signals to shared nodes; keep runtime nodes beneath this root.
	pass


func _exit_tree() -> void:
	exit_level()
