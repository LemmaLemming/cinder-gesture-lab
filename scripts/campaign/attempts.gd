class_name CinderCampaignAttempts
extends RefCounted
## Pure attempt/progression transactions. The shell captures/restores live actors
## at a paused deferred barrier. This model never heals or resets an encounter.
## Optional/replay attempts keep the entire story snapshot untouched.

const SCHEMA_VERSION: int = 1
const Equipment = preload("res://scripts/equipment.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
var registry: CinderCampaignRegistry
var last_error: String = ""
var last_warning: String = ""
var snapshot_validator: Callable
var _store: CinderSaveStore
var _state: Dictionary

func _init(campaign_registry: CinderCampaignRegistry, save_store: CinderSaveStore = null) -> void:
	registry = campaign_registry
	_store = save_store
	_state = {
		"schema_version": SCHEMA_VERSION, "completed_main": [], "completed_optional": [],
		"reward_ids": [], "story": null, "side_attempt": null,
		"last_replay_equipment": {}, "unlocked_equipment": Equipment.STARTER.values(),
	}
	if _store != null:
		var owner: WeakRef = weakref(self)
		_store.payload_validator = func(candidate: Dictionary) -> String:
			var model: CinderCampaignAttempts = owner.get_ref() as CinderCampaignAttempts
			return "Save validator owner unavailable" if model == null else model.saved_payload_error(candidate)

func state() -> Dictionary:
	return _state.duplicate(true)

func story_snapshot() -> Dictionary:
	return {} if _state["story"] == null else (_state["story"]["snapshot"] as Dictionary).duplicate(true)

func active_snapshot() -> Dictionary:
	var attempt: Variant = _active(_state)
	return {} if attempt == null else (attempt["snapshot"] as Dictionary).duplicate(true)

func active_kind() -> String:
	return "story" if _state["side_attempt"] == null else String(_state["side_attempt"]["kind"])

func begin_story(fresh_snapshot: Dictionary) -> bool:
	if _state["story"] != null or fresh_snapshot.get("level_id") != "A1-L1":
		return _reject("A new story begins once at A1-L1")
	var error: String = _snapshot_error(fresh_snapshot, _state["unlocked_equipment"])
	if not error.is_empty():
		return _reject(error)
	var next: Dictionary = state()
	next["story"] = _attempt("story", fresh_snapshot)
	return _commit(next)

func record_snapshot(snapshot: Dictionary, checkpoint: bool = false) -> bool:
	var active: Variant = _active(_state)
	if active == null or snapshot.get("level_id") != active["level_id"]:
		return _reject("Snapshot does not match the active attempt")
	var error: String = _snapshot_error(snapshot, _state["unlocked_equipment"])
	if not error.is_empty():
		return _reject(error)
	var next: Dictionary = state()
	var destination: Dictionary = _active(next)
	destination["snapshot"] = snapshot.duplicate(true)
	if checkpoint:
		destination["checkpoint"] = snapshot.duplicate(true)
	return _commit(next)

func retry_snapshot() -> Dictionary:
	var active: Variant = _active(_state)
	if active == null:
		_reject("No attempt to retry")
		return {}
	var restored: Dictionary = (active["checkpoint"] as Dictionary).duplicate(true)
	return restored if record_snapshot(restored) else {}

func begin_side(kind: String, level_id: String, fresh_snapshot: Dictionary) -> bool:
	if _state["story"] == null or _state["side_attempt"] != null or not ["optional", "replay"].has(kind):
		return _reject("Side attempts require a protected story and no active side attempt")
	var entry: Dictionary = registry.entry(level_id)
	var completed: bool = _state["completed_main"].has(level_id) or _state["completed_optional"].has(level_id)
	if not registry.is_unlocked(level_id, _state["completed_main"]) or not registry.is_playable(level_id):
		return _reject("Selected side level is locked or awaiting integration")
	if kind == "replay" and not completed:
		return _reject("Replay requires an already completed level")
	if kind == "optional" and (entry.get("kind") != "optional" or completed):
		return _reject("First optional attempt requires an uncompleted optional level")
	if fresh_snapshot.get("level_id") != level_id:
		return _reject("Fresh side snapshot identity differs from selection")
	var error: String = _snapshot_error(fresh_snapshot, _state["unlocked_equipment"])
	if not error.is_empty():
		return _reject(error)
	var next: Dictionary = state()
	next["side_attempt"] = _attempt(kind, fresh_snapshot)
	if kind == "replay":
		next["last_replay_equipment"] = (fresh_snapshot.get("equipment_ids", {}) as Dictionary).duplicate(true)
	return _commit(next)

func complete_active(snapshot: Dictionary = {}) -> bool:
	var active: Variant = _active(_state)
	if active == null:
		return _reject("No active attempt to complete")
	if not snapshot.is_empty():
		if snapshot.get("level_id") != active["level_id"]:
			return _reject("Completion snapshot differs from the active attempt")
		var error: String = _snapshot_error(snapshot, _state["unlocked_equipment"])
		if not error.is_empty():
			return _reject(error)
	var next: Dictionary = state()
	if not snapshot.is_empty():
		_active(next)["snapshot"] = snapshot.duplicate(true)
	var id: String = active["level_id"]
	var entry: Dictionary = registry.entry(id)
	if entry["kind"] == "main":
		# Replaying a main level cannot advance or replace the story route.
		if next["side_attempt"] == null and not next["completed_main"].has(id):
			next["completed_main"].append(id)
	else:
		if not next["completed_optional"].has(id):
			next["completed_optional"].append(id)
		var reward: String = entry["reward_id"]
		if not next["reward_ids"].has(reward):
			next["reward_ids"].append(reward)
	return _commit(next)

func leave_side() -> Dictionary:
	if _state["side_attempt"] == null:
		_reject("No side attempt to leave")
		return {}
	var preserved: Dictionary = story_snapshot()
	var next: Dictionary = state()
	next["side_attempt"] = null
	return preserved if _commit(next) else {}

func next_story_id() -> String:
	for id: String in registry.main_route():
		if not _state["completed_main"].has(id):
			return id
	return ""

func advance_story(fresh_snapshot: Dictionary) -> bool:
	if _state["side_attempt"] != null or _state["story"] == null or not _state["completed_main"].has(_state["story"]["level_id"]):
		return _reject("Story transition requires a completed current story level")
	var target: String = registry.next_main(_state["story"]["level_id"])
	if target.is_empty() or fresh_snapshot.get("level_id") != target or not registry.is_playable(target):
		return _reject("Next story scene is unavailable or differs from the route")
	var error: String = _snapshot_error(fresh_snapshot, _state["unlocked_equipment"])
	if not error.is_empty():
		return _reject(error)
	var next: Dictionary = state()
	next["story"] = _attempt("story", fresh_snapshot)
	return _commit(next)

func grant_equipment(ids: Array) -> bool:
	# Integration calls only for a declared accepted campaign reward. This does
	# not allocate abilities or infer rewards from concept illustrations.
	var next: Dictionary = state()
	var equipment := Equipment.new()
	for id: Variant in ids:
		if not id is String or not equipment.is_implemented(id):
			return _reject("Reward refers to unavailable shared equipment")
		if not next["unlocked_equipment"].has(id):
			next["unlocked_equipment"].append(id)
	return _commit(next)

func restore_session(candidate: Dictionary) -> bool:
	# A malformed side attempt is dropped only after the protected core/story
	# independently validate. Invalid story/progress never changes live memory.
	last_warning = ""
	var accepted: Dictionary = candidate.duplicate(false)
	var side: Variant = accepted.get("side_attempt")
	var remembered: Variant = accepted.get("last_replay_equipment")
	accepted["side_attempt"] = null
	accepted["last_replay_equipment"] = {}
	last_error = state_error(accepted)
	if not last_error.is_empty():
		return false
	if remembered is Dictionary and (remembered.is_empty() or _equipment_error(remembered, accepted["unlocked_equipment"]).is_empty()):
		accepted["last_replay_equipment"] = remembered
	else:
		last_warning = "Invalid remembered replay equipment discarded; story snapshot preserved"
	if side != null:
		accepted["side_attempt"] = side
		var side_error: String = state_error(accepted)
		if not side_error.is_empty():
			accepted["side_attempt"] = null
			last_warning += ("; " if not last_warning.is_empty() else "") + "Interrupted side attempt unavailable; story snapshot preserved: " + side_error
	_state = accepted.duplicate(true)
	last_error = ""
	return true

func load_saved() -> bool:
	if _store == null:
		return _reject("No desktop save store configured")
	var candidate: Dictionary = _store.read_payload()
	if candidate.is_empty():
		return _reject(_store.last_error)
	return restore_session(candidate)

func saved_payload_error(candidate: Dictionary) -> String:
	# Disk fallback/backup retention must use protected-story semantics, rather
	# than considering an arbitrary checksum-valid JSON object a valid save.
	# Side-only corruption is recoverable without rejecting the protected core.
	var core: Dictionary = candidate.duplicate(false)
	core["side_attempt"] = null
	core["last_replay_equipment"] = {}
	return state_error(core)

func state_error(candidate: Dictionary) -> String:
	var error: String = Store.json_error(candidate)
	if not error.is_empty():
		return error
	if candidate.size() != 8 or candidate.get("schema_version") != SCHEMA_VERSION:
		return "Unsupported campaign attempt schema"
	for key: String in ["completed_main", "completed_optional", "reward_ids", "unlocked_equipment"]:
		if not candidate.get(key) is Array or not _unique_strings(candidate[key]):
			return "Invalid campaign list: " + key
	var main: Array = candidate["completed_main"]
	var route: Array[String] = registry.main_route()
	if main.size() > route.size():
		return "Main completion exceeds the authored route"
	for index: int in range(main.size()):
		if main[index] != route[index]:
			return "Main completion must be a sequential prefix"
	var expected_rewards: Array = []
	for id: String in candidate["completed_optional"]:
		var entry: Dictionary = registry.entry(id)
		if entry.get("kind") != "optional" or not registry.is_unlocked(id, main):
			return "Optional completion requires its main parent clear"
		expected_rewards.append(entry["reward_id"])
	if candidate["reward_ids"].size() != expected_rewards.size():
		return "Optional reward stamps must correspond once to completed optional levels"
	for reward: String in candidate["reward_ids"]:
		if not expected_rewards.has(reward):
			return "Unknown optional reward stamp"
	var equipment := Equipment.new()
	for id: String in candidate["unlocked_equipment"]:
		if not equipment.is_implemented(id):
			return "Unavailable equipment cannot be unlocked"
	for id: String in Equipment.STARTER.values():
		if not candidate["unlocked_equipment"].has(id):
			return "Starter equipment cannot be removed"
	if not candidate.get("last_replay_equipment") is Dictionary:
		return "Replay equipment must be a dictionary"
	if not candidate["last_replay_equipment"].is_empty():
		error = _equipment_error(candidate["last_replay_equipment"], candidate["unlocked_equipment"])
		if not error.is_empty():
			return error
	if not candidate.has("story") or not candidate.has("side_attempt"):
		return "Missing protected attempt fields"
	if candidate["story"] == null:
		return "" if main.is_empty() and candidate["completed_optional"].is_empty() and candidate["side_attempt"] == null else "Progress requires a protected story"
	var story: Variant = candidate["story"]
	error = _attempt_error(story, candidate["unlocked_equipment"])
	if not error.is_empty():
		return error
	if story["kind"] != "story" or registry.entry(story["level_id"]).get("kind") != "main":
		return "Story attempt requires a main level"
	var story_index: int = route.find(story["level_id"])
	if story_index != main.size() and story_index != main.size() - 1:
		return "Story attempt differs from sequential progress"
	# A production local completion may never persist ahead of its campaign
	# record. Older checkpoints may reopen the local encounter after a recorded
	# clear; persistent route access is retained. Transport-only fixtures omit
	# progress, while the live shell validates the complete local schema.
	var local_progress: Variant = story["snapshot"]["level"].get("progress")
	if local_progress is Dictionary and local_progress.get("completed") == true and not main.has(story["level_id"]):
		return "Local completion precedes its durable campaign record"
	var side: Variant = candidate["side_attempt"]
	if side == null:
		return ""
	error = _attempt_error(side, candidate["unlocked_equipment"])
	if not error.is_empty():
		return error
	if not registry.is_unlocked(side["level_id"], main):
		return "Side attempt is locked"
	if side["kind"] == "optional":
		if registry.entry(side["level_id"]).get("kind") != "optional":
			return "Optional attempt requires an optional level"
	elif side["kind"] == "replay":
		if not main.has(side["level_id"]) and not candidate["completed_optional"].has(side["level_id"]):
			return "Replay requires prior completion"
	else:
		return "Unsupported side attempt kind"
	return ""

func _attempt(kind: String, snapshot: Dictionary) -> Dictionary:
	return {"kind": kind, "level_id": snapshot.get("level_id", ""), "snapshot": snapshot.duplicate(true), "checkpoint": snapshot.duplicate(true)}

func _attempt_error(attempt: Variant, owned: Array) -> String:
	if not attempt is Dictionary or attempt.size() != 4 or not attempt.get("kind") is String or not attempt.get("level_id") is String:
		return "Malformed attempt record"
	for key: String in ["snapshot", "checkpoint"]:
		if not attempt.get(key) is Dictionary:
			return "Missing coherent attempt snapshot"
		var error: String = _snapshot_error(attempt[key], owned)
		if not error.is_empty():
			return error
		if attempt[key]["level_id"] != attempt["level_id"]:
			return "Attempt snapshot identity differs"
	return ""

func _snapshot_error(snapshot: Dictionary, owned: Array) -> String:
	var json_problem: String = Store.json_error(snapshot)
	if not json_problem.is_empty():
		return json_problem
	if not (snapshot.get("schema_version") is int or snapshot.get("schema_version") is float) or snapshot.get("schema_version") != 1 or not snapshot.get("level_id") is String or not snapshot.get("paused") is bool or snapshot.get("paused") != true:
		return "Snapshots require a paused shared-shell boundary and canonical identity"
	var id: String = snapshot["level_id"]
	var entry: Dictionary = registry.entry(id)
	if not registry.is_playable(id) or snapshot.get("scene_path") != entry.get("scene_path"):
		return "Snapshot refers to an unavailable or different accepted scene"
	for key: String in ["player", "level", "shell", "equipment_ids"]:
		if not snapshot.get(key) is Dictionary:
			return "Missing coherent snapshot component: " + key
	if snapshot["level"].get("level_id") != id or snapshot["level"].get("scene_path") != snapshot["scene_path"]:
		return "Local level snapshot identity differs from shell"
	var error: String = _equipment_error(snapshot["equipment_ids"], owned)
	if error.is_empty() and snapshot_validator.is_valid():
		error = snapshot_validator.call(snapshot.duplicate(true))
	return error

func _equipment_error(loadout: Dictionary, owned: Array) -> String:
	if loadout.size() != 4:
		return "Loadout requires exactly weapon, jacket, pants and shoes"
	var equipment := Equipment.new()
	for slot: String in Equipment.SLOTS:
		if not loadout.get(slot) is String or not owned.has(loadout[slot]):
			return "Loadout uses locked equipment"
	if not equipment.restore(loadout):
		return "Loadout IDs do not match canonical implemented slot types"
	return ""

func _unique_strings(values: Array) -> bool:
	var seen: Dictionary = {}
	for value: Variant in values:
		if not value is String or seen.has(value):
			return false
		seen[value] = true
	return true

func _active(candidate: Dictionary) -> Variant:
	return candidate["story"] if candidate["side_attempt"] == null else candidate["side_attempt"]

func _commit(next: Dictionary) -> bool:
	last_error = state_error(next)
	if not last_error.is_empty():
		return false
	if _store != null and not _store.write_payload(next):
		return _reject(_store.last_error)
	_state = next.duplicate(true)
	last_error = ""
	return true

func _reject(error: String) -> bool:
	last_error = error
	return false
