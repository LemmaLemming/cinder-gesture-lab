extends RefCounted
## Owned O3 topology and copied native transport checks only. The real host
## must still validate actor/Player/Scheduler bindings, physical response paths,
## native construction custody, progress, contact overlap and current optics.
## This helper neither constructs actors nor authorizes a whole Save.

const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const NativeCodec = preload("res://scripts/acts/act1/mushroom_selenite_codec.gd")
const Arrangement = preload("res://scripts/combat/encounter_arrangement.gd")
const Layout = preload("res://scripts/acts/act1/royal_rehearsal_layout.gd")
const API_REVISION: String = "act1-rehearsal-aggregate-1"
const SCHEMA_VERSION: int = 1
const WORLD_REVISION: int = 1
const LOCAL_KEYS: Array[String] = ["api_revision", "schema_version", "world_revision", "exercise_index", "stage", "completed_exercises", "checkpoint_published", "bell_armed", "recipes", "admission_cursor", "admission_gate", "actors", "scheduler", "framing"]
const GATE_KEYS: Array[String] = ["source_id", "reservation_id", "cycle", "encounter_id", "profile_id", "release_phase", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]
const SCHEDULER_KEYS: Array[String] = ["api_revision", "schema_version", "encounter_id", "profile", "world_revision", "clock_s", "serial", "collision", "reservations", "cooldowns"]
const RESERVATION_KEYS: Array[String] = ["id", "source_id", "source_position", "opening_position", "floors", "geometry", "start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id", "world_revision"]
const FRAME_KEYS: Array[String] = ["reservation_id", "landing", "attack_position", "proof"]
const PROOF_KEYS: Array[String] = ["accepted", "path", "landing", "attack_position", "primary_time_s", "response_complete_s", "uses_blast", "uses_invulnerability", "proof_scope"]
const SEGMENT_KEYS: Array[String] = ["from", "to", "start_s", "end_s"]


static func envelope_error(value: Variant) -> String:
	var error: String = Codec.value_error(value)
	if not error.is_empty(): return error
	if not value is Dictionary: return "Rehearsal aggregate must be a closed Dictionary"
	var saved: Dictionary = value
	error = Codec.keys_error(saved, LOCAL_KEYS)
	if not error.is_empty(): return error
	if saved.api_revision != API_REVISION or not saved.schema_version is int or saved.schema_version != SCHEMA_VERSION or not saved.world_revision is int or saved.world_revision != WORLD_REVISION: return "Unsupported exact rehearsal aggregate revision"
	if not saved.exercise_index is int or saved.exercise_index not in [0, 1, 2] or not saved.stage is String or saved.stage not in ["awaiting_bell", "active", "complete"] or not saved.completed_exercises is Array or not saved.checkpoint_published is bool or not saved.bell_armed is bool or not saved.admission_cursor is int or saved.admission_cursor not in [0, 1]: return "Closed exercise, completed prefix, bell and admission metadata required"
	for key: String in ["recipes", "admission_gate", "actors", "scheduler", "framing"]:
		if not saved[key] is Dictionary: return "Dictionary required: " + key
	error = Codec.keys_error(saved.actors, Layout.SOURCE_IDS)
	if not error.is_empty(): return "Exact finite six-guard cast required: " + error
	for id: String in Layout.SOURCE_IDS:
		error = _actor_shape_error(saved.actors[id], id)
		if not error.is_empty(): return error
	error = _scheduler_shape_error(saved.scheduler)
	if not error.is_empty(): return error
	return _framing_error(saved)


## Pure authored checks follow the unchanged native copied-packet shape checks.
## Physical custody and ordinary response validity still belong to the host.
static func metadata_error(saved: Dictionary) -> String:
	var error: String = envelope_error(saved)
	if error.is_empty(): error = _prefix_error(saved)
	if error.is_empty(): error = _epoch_error(saved)
	if error.is_empty(): error = _admission_gate_error(saved)
	return error


static func _admission_gate_error(saved: Dictionary) -> String:
	var gate: Dictionary = saved.admission_gate
	if saved.stage != "active": return "" if gate.is_empty() and saved.admission_cursor == 0 else "Retired exercise clears its admission gate and cursor"
	if gate.is_empty():
		if saved.admission_cursor != 0: return "An unstarted offer sequence begins at its recipe's first source"
		for id: String in Layout.group_ids(saved.exercise_index):
			if saved.actors[id].cycle != 0: return "A real current admission cannot discard its original gate"
		return ""
	var error: String = Codec.keys_error(gate, GATE_KEYS)
	if not error.is_empty(): return error
	var recipe: Dictionary = saved.recipes[Layout.EXERCISE_IDS[saved.exercise_index]]
	if not gate.source_id is String or gate.source_id not in recipe.order or not gate.reservation_id is String or not gate.cycle is int or not Codec.is_integer(gate.cycle, 1) or not gate.encounter_id is String or not gate.profile_id is String or not gate.release_phase is String: return "Closed current native admission identity required"
	var actor: Dictionary = saved.actors[gate.source_id]
	if gate.cycle != actor.cycle or gate.encounter_id != saved.scheduler.encounter_id or gate.encounter_id != actor.role_encounter_id or gate.profile_id != recipe.profile or gate.profile_id != actor.profile_id or gate.reservation_id != "threat-%d" % saved.scheduler.serial: return "Gate retains the latest actual Scheduler admission and source cycle/profile"
	var admitted_index: int = recipe.order.find(gate.source_id)
	if saved.admission_cursor != (admitted_index + 1) % 2 or gate.release_phase != Layout.release_phase(saved.exercise_index, recipe, gate.source_id): return "Next offer and retained release policy follow the actual admitted recipe source"
	for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
		if not gate[key] is float or not Codec.in_range(gate[key], 0.0, 1000000000.0): return "Original admission deadlines remain finite native floats"
	var role: Dictionary = actor.resolved_role
	# Match the exact native construction arithmetic; these comparisons do not
	# synthesize, replace or rebase any serialized deadline.
	if gate.start_s > saved.scheduler.clock_s or gate.active_from_s != gate.start_s + float(role.windup_s) or gate.lock_from_s != gate.active_from_s - float(role.lock_s) or gate.active_until_s != gate.active_from_s + float(role.active_s) or gate.recovery_until_s != gate.active_until_s + float(role.recovery_s) or gate.cooldown_until_s != gate.active_from_s + float(role.attack_interval_s): return "Admission gate retains original role-derived native deadlines"
	var owned: Dictionary = {}
	for record: Dictionary in saved.scheduler.reservations:
		if record.source_id == gate.source_id: owned = record
	if not owned.is_empty():
		if owned.id != gate.reservation_id or actor.reservation_id != gate.reservation_id: return "Live latest gate and native lease differ"
		for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s", "profile_id"]:
			if not _same(gate[key], owned[key]): return "Live admission gate differs from its original native lease: " + key
	var cooldown: Dictionary = {}
	for record: Dictionary in saved.scheduler.cooldowns:
		if record.source_id == gate.source_id: cooldown = record
	if not actor.dead:
		if not cooldown.is_empty():
			if not _same(cooldown.ready_s, gate.cooldown_until_s): return "Latest living source retains its original native cooldown deadline"
		elif saved.scheduler.clock_s < gate.cooldown_until_s:
			return "A living latest source cannot lose its unexpired native cooldown"
	return ""


## This calls the unchanged native packet codec; its configuration argument is
## still copied data here. Actual ready-time fingerprints are checked by the
## constructor plan, and the host must call each real actor's paired validator.
static func _actor_shape_error(value: Variant, id: String) -> String:
	if not value is Dictionary or not value.get("configuration") is Dictionary: return "Complete native C32 packet required: " + id
	var actor: Dictionary = value
	var error: String = NativeCodec.new().schema_error(actor, actor.configuration)
	if not error.is_empty(): return id + ": " + error
	if actor.source_id != id or actor.role_id != "A1-E3" or actor.configuration.entity_id != "C32" or not actor.configuration.initially_dormant or actor.approach_driving or actor.schema_version not in [1, 2]: return "Rehearsal uses only its six ordinary initially-dormant native C32 guards"
	return ""


static func _scheduler_shape_error(saved: Dictionary) -> String:
	var error: String = Codec.keys_error(saved, SCHEDULER_KEYS)
	if not error.is_empty(): return "Complete ordinary Scheduler packet required: " + error
	if saved.api_revision != "scheduler-snapshot-1" or not saved.schema_version is int or saved.schema_version != 1 or not saved.encounter_id is String or not saved.profile is Dictionary or not saved.world_revision is int or saved.world_revision not in [0, WORLD_REVISION] or not saved.clock_s is float or not Codec.in_range(saved.clock_s, 0.0, 1000000000.0) or not saved.serial is int or not Codec.is_integer(saved.serial) or not saved.collision is Dictionary or not saved.reservations is Array or not saved.cooldowns is Array: return "Exact ordinary native Scheduler envelope required"
	var seen: Dictionary = {}
	for value: Variant in saved.reservations:
		if not value is Dictionary or not value.get("source_id") is String or value.source_id not in Layout.SOURCE_IDS or seen.has(value.source_id): return "One native lease per known rehearsal source required"
		seen[value.source_id] = true
		error = Codec.keys_error(value, RESERVATION_KEYS)
		if not error.is_empty(): return error
		if not value.id is String or value.id.is_empty() or not _native_vector(value.source_position) or not _native_vector(value.opening_position) or not value.floors is Array or value.floors.is_empty() or not value.geometry is Dictionary or not value.profile_id is String or not value.world_revision is int or value.world_revision != WORLD_REVISION: return "Complete native stationary C32 reservation required"
		for key: String in ["start_s", "lock_from_s", "active_from_s", "active_until_s", "recovery_until_s", "cooldown_until_s"]:
			if not value[key] is float or not Codec.in_range(value[key], 0.0, 1000000000.0): return "Original native deadlines remain finite floats"
	seen.clear()
	for value: Variant in saved.cooldowns:
		if not value is Dictionary or not Codec.keys_error(value, ["source_id", "ready_s"]).is_empty() or not value.source_id is String or value.source_id not in Layout.SOURCE_IDS or seen.has(value.source_id) or not value.ready_s is float or not Codec.in_range(value.ready_s, 0.0, 1000000000.0): return "Unique complete native source cooldown required"
		seen[value.source_id] = true
	return ""


static func _pristine_future_error(actor: Dictionary, id: String) -> String:
	# The native schema already checks untouched HP, exchange and motion state.
	# The owned topology additionally fixes pristine unexposed pose and floor cache.
	if not actor.dormant or actor.motion.grounded or not _same(actor.motion.position, Codec.vector3(Layout.SOURCES[id].position)) or not _same(actor.motion.facing, Codec.vector3(Vector3.FORWARD)): return "Future guard must retain its pristine dormant authored pose: " + id
	return ""


static func _native_vector(value: Variant) -> bool:
	return Codec.is_vector3(value) and _same(value, Codec.vector3(Codec.read_vector3(value)))


static func _same(left: Variant, right: Variant) -> bool:
	var text: String = Exact.stringify(left)
	return not text.is_empty() and text == Exact.stringify(right)


static func _sha256(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for index: int in range(64):
		if "0123456789abcdef".find(value.substr(index, 1)) < 0: return false
	return true


static func _rejected(error: String) -> Dictionary:
	return {"accepted": false, "error": error}


## Call after the closed envelope check. An active pair may already be dead
## before the next actual parent retirement callback; it is not yet in prefix.
static func _prefix_error(saved: Dictionary) -> String:
	var count: int = saved.completed_exercises.size()
	if count > 3: return "At most the three finite exercises can be completed"
	for index: int in count:
		if saved.completed_exercises[index] != Layout.EXERCISE_IDS[index]: return "Completed exercises retain the exact ordered prefix"
	if saved.stage == "complete":
		if count != 3 or saved.exercise_index != 2: return "Completion requires all three finite exercises"
	elif count != saved.exercise_index: return "Current exercise follows exactly its completed prefix"
	if saved.checkpoint_published != (count >= 2): return "Pre-final checkpoint follows exactly the first two cleared exercises"
	if saved.stage != "awaiting_bell" and saved.bell_armed: return "Only an awaiting exercise can arm the bell"
	if saved.stage == "awaiting_bell" and count == 0 and not saved.bell_armed: return "Fresh first exercise retains its available bell"
	var started: int = _started_count(saved)
	var expected_recipes: Array[String] = []
	for index: int in started: expected_recipes.append(Layout.EXERCISE_IDS[index])
	var error: String = Codec.keys_error(saved.recipes, expected_recipes)
	if not error.is_empty(): return "Recipes retain exactly the started exercise prefix: " + error
	for index: int in started:
		var recipe: Variant = saved.recipes[Layout.EXERCISE_IDS[index]]
		error = Arrangement.new(Layout.arrangement_definition(index)).saved_error(recipe)
		if not error.is_empty(): return "Retained exercise recipe: " + error
	for id: String in Layout.SOURCE_IDS:
		var actor: Dictionary = saved.actors[id]
		var index: int = int(Layout.SOURCES[id].exercise)
		if actor.dormant != (index >= started): return "Native exposure differs from its exact started prefix: " + id
		if index < count and not actor.dead: return "Completed exercise retains both genuinely defeated guards: " + id
		if index >= started:
			error = _pristine_future_error(actor, id)
			if not error.is_empty(): return error
		elif actor.cycle > 0:
			var recipe: Dictionary = saved.recipes[Layout.EXERCISE_IDS[index]]
			if actor.role_encounter_id != Layout.encounter_id(index) or actor.profile_id != recipe.profile: return "Historical native actor retains its original exercise and saved profile: " + id
	return ""


static func _started_count(saved: Dictionary) -> int:
	return 3 if saved.stage == "complete" else saved.exercise_index + (1 if saved.stage == "active" else 0)


static func _epoch_error(saved: Dictionary) -> String:
	var control: Dictionary = saved.scheduler
	var started: int = _started_count(saved)
	if saved.stage == "active":
		var recipe: Dictionary = saved.recipes[Layout.EXERCISE_IDS[saved.exercise_index]]
		if control.encounter_id != Layout.encounter_id(saved.exercise_index) or control.world_revision != WORLD_REVISION or control.profile.get("id") != recipe.profile: return "Active exercise retains its original native epoch and saved recipe profile"
	else:
		if not control.encounter_id.is_empty() or not control.profile.is_empty() or not control.reservations.is_empty() or not control.cooldowns.is_empty(): return "Awaiting or complete exercises retain a retired native epoch"
		if control.world_revision != (0 if started == 0 else WORLD_REVISION): return "Fresh and retired native world revisions remain literal"
		if started == 0 and (control.clock_s != 0.0 or control.serial != 0): return "Unstarted rehearsal cannot invent native clock or admission history"
	var leases: Dictionary = {}
	for record: Dictionary in control.reservations:
		var id: String = record.source_id
		if saved.stage != "active" or int(Layout.SOURCES[id].exercise) != saved.exercise_index or saved.actors[id].dead or saved.actors[id].dormant: return "Only current living exposed guards may retain native leases"
		leases[id] = record.id
	for id: String in Layout.SOURCE_IDS:
		if saved.actors[id].reservation_id != leases.get(id, ""): return "Native actor and Scheduler lease membership differ: " + id
	for record: Dictionary in control.cooldowns:
		var id: String = record.source_id
		if saved.stage != "active" or int(Layout.SOURCES[id].exercise) != saved.exercise_index or saved.actors[id].dead or saved.actors[id].dormant: return "Only current living exposed guards may retain native cooldowns"
	return ""


## The host has already validated the local aggregate and common level envelope.
## Actual saved Hero/exit overlap remains a separate physical host check.
static func progress_error(local: Dictionary, progress: Dictionary) -> String:
	var error: String = Codec.keys_error(progress, ["completed", "completion_id", "contact_exit_id", "checkpoint_id", "checkpoint_kind", "checkpoint_ids"])
	if not error.is_empty(): return error
	var expected: Dictionary = {}
	if local.checkpoint_published: expected[Layout.CHECKPOINT_ID] = "encounter"
	if not _same(progress.checkpoint_ids, expected) or progress.checkpoint_id != (Layout.CHECKPOINT_ID if local.checkpoint_published else "") or progress.checkpoint_kind != ("encounter" if local.checkpoint_published else ""): return "Whole progress retains exactly the genuine pre-final checkpoint"
	if progress.completed != (local.stage == "complete") or progress.completion_id != (Layout.COMPLETION_ID if local.stage == "complete" else ""): return "Whole completion matches all three actually retired exercises"
	if not progress.contact_exit_id.is_empty() and (not progress.completed or progress.contact_exit_id != Layout.EXIT_ID): return "Only the completed rehearsal can retain its exact contact exit"
	return ""


## Trusted inputs are captured from actual ready-time native objects, never
## learned from this submitted packet. Accepted means a constructor plan only.
static func construction_plan(saved: Dictionary, configuration_sha256: Dictionary, source_positions: Dictionary) -> Dictionary:
	var error: String = metadata_error(saved)
	if not error.is_empty(): return _rejected(error)
	error = Codec.value_error(configuration_sha256)
	if error.is_empty(): error = Codec.value_error(source_positions)
	if error.is_empty(): error = Codec.keys_error(configuration_sha256, Layout.SOURCE_IDS)
	if error.is_empty(): error = Codec.keys_error(source_positions, Layout.SOURCE_IDS)
	if not error.is_empty(): return _rejected("Closed actual ready-time native input maps required: " + error)
	for id: String in Layout.SOURCE_IDS:
		if not _sha256(configuration_sha256[id]) or not _native_vector(source_positions[id]) or not _same(source_positions[id], Codec.vector3(Layout.SOURCES[id].position)): return _rejected("Actual immutable configuration fingerprint/authored position required: " + id)
		var text: String = Exact.stringify(saved.actors[id].configuration)
		if text.is_empty() or text.sha256_text() != configuration_sha256[id]: return _rejected("Saved configuration differs from actual ready-time native bytes: " + id)
	var rooms: Array[String] = []
	for index: int in _started_count(saved): rooms.append(Layout.EXERCISE_IDS[index])
	var exposed: Array[String] = []
	var descriptors: Dictionary = {}
	for id: String in Layout.SOURCE_IDS:
		var index: int = int(Layout.SOURCES[id].exercise)
		if index >= rooms.size(): continue
		exposed.append(id)
		descriptors[id] = {"api_revision": "act1-restore-recipient-construction-1", "source_id": id, "room_id": Layout.EXERCISE_IDS[index], "installed_rooms": rooms.duplicate(), "installed_fields": [], "configuration_sha256": configuration_sha256[id], "authored_position": source_positions[id].duplicate()}
	return {"accepted": true, "error": "", "scope": "authored_transport_and_construction_plan_only", "installed_rooms": rooms, "installed_fields": [], "activated_source_ids": exposed, "descriptors": descriptors}


static func _framing_error(saved: Dictionary) -> String:
	var leases: Dictionary = {}
	for record: Dictionary in saved.scheduler.reservations: leases[record.source_id] = record
	var error: String = Codec.keys_error(saved.framing, leases.keys())
	if not error.is_empty(): return "Original witnesses cover exactly all captured live native leases"
	for id: String in saved.framing:
		var value: Variant = saved.framing[id]
		var record: Dictionary = leases[id]
		if not value is Dictionary or not Codec.keys_error(value, FRAME_KEYS).is_empty() or value.reservation_id != record.id or not _native_vector(value.landing) or not _native_vector(value.attack_position) or not value.proof is Dictionary: return "Original four-key response witness and complete proof required"
		var proof: Dictionary = value.proof
		if not Codec.keys_error(proof, PROOF_KEYS).is_empty() or not proof.accepted is bool or proof.accepted != true or not proof.uses_blast is bool or proof.uses_blast != false or not proof.uses_invulnerability is bool or proof.uses_invulnerability != false or proof.proof_scope != "static_box_floor_full_dash_stationary_primary" or not proof.path is Array or proof.path.size() not in [4, 6] or not _same(proof.landing, value.landing) or not _same(proof.attack_position, value.attack_position) or not proof.primary_time_s is float or not proof.response_complete_s is float: return "Full original ordinary-only native proof transport required"
		if not Codec.in_range(proof.primary_time_s, record.active_until_s, record.recovery_until_s) or proof.response_complete_s < proof.primary_time_s or proof.response_complete_s >= record.recovery_until_s: return "Original primary and complete response fit the committed recovery interval"
		var kinds: Array = ["recognition_and_ready", "escape_dash", "recovery_wait", "ordinary_primary"] if proof.path.size() == 4 else ["recognition_and_ready", "escape_dash", "recovery_wait", "positioning_dash", "primary_ready", "ordinary_primary"]
		var previous: Dictionary = {}
		for index: int in range(proof.path.size()):
			var segment: Variant = proof.path[index]
			error = _segment_shape_error(segment, true)
			if not error.is_empty(): return error
			if segment.kind != kinds[index]: return "Original native ordinary path segment order required"
			if index == 0 and not _same(segment.start_s, record.start_s): return "Original accepted response begins at its actual reservation start"
			if not previous.is_empty() and (not _same(previous.end_s, segment.start_s) or not _same(previous.to, segment.from)): return "Original path retains literal contiguous endpoints / times"
			if segment.kind not in ["escape_dash", "positioning_dash"] and not _same(segment.from, segment.to): return "Native wait / ordinary primary cannot hide travel"
			previous = segment
		if not _same(proof.path[1].to, value.landing) or not _same(previous.from, value.attack_position) or not _same(previous.to, value.attack_position) or not _same(previous.start_s, proof.primary_time_s) or not _same(previous.end_s, proof.response_complete_s): return "Full path preserves original landing / primary endpoint and timing"
	# Native proof provenance, physical support/escape, source opening and camera
	# fit are NOT inferred from these copied values; actual parent must prove them.
	return ""


static func _segment_shape_error(value: Variant, has_kind: bool) -> String:
	var keys: Array = SEGMENT_KEYS.duplicate()
	if has_kind: keys.append("kind")
	if not value is Dictionary or not Codec.keys_error(value, keys).is_empty() or not _native_vector(value.from) or not _native_vector(value.to) or not value.start_s is float or not value.end_s is float or not Codec.in_range(value.start_s, 0.0, 1000000000.0) or not Codec.in_range(value.end_s, value.start_s, 1000000000.0): return "Complete literal native finite path segment required"
	if has_kind and not value.kind is String: return "Native path kind must remain a String"
	if value.start_s == value.end_s and not _same(value.from, value.to): return "Zero-time segment cannot contain displacement"
	return ""


