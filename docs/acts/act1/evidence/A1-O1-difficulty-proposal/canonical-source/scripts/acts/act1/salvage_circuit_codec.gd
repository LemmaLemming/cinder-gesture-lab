extends RefCounted
## Pure A1-O1 local metadata envelope. This does not authorize Save, contacts,
## native attacks or restoration. The actual parent validates whole Player,
## C30/Lane/Scheduler packets, immutable resources, current presentation and
## native stopped openings before its sole quiet commit.
## Preserve complete ordinary and conditional pending native packets. Collected
## IDs retain actual contact order; their order is deliberately not a recipe.

const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Exact = preload("res://scripts/campaign/exact_json.gd")
const API_REVISION: String = "act1-salvage-circuit-1"
const SCHEMA_VERSION: int = 1
const WORLD_REVISION: int = 1
const LEVEL_ID: String = "A1-O1"
const CIRCUIT_ID: String = "salvage-circuit-rusher"
const FINAL_ID: String = "salvage-final-rusher"
const IMPACT_ID: String = "salvage-circuit-impact"
const CIRCUIT_ENCOUNTER_ID: String = "salvage-circuit-encounter"
const FINAL_ENCOUNTER_ID: String = "salvage-final-encounter"
const CHECKPOINT_ID: String = "salvage-parts-ready"
const COMPLETION_ID: String = "salvage-circuit-clear"
const EXIT_ID: String = "repaired-hatch"
const COMPOUND_REFUSAL: String = "compound_response_outside_rusher_recovery"
const PART_IDS: Array[String] = ["nose-cap", "rivet-band", "hatch-disc"]
const SOURCE_IDS: Array[String] = [CIRCUIT_ID, FINAL_ID]
const RESERVATION_SOURCE_IDS: Array[String] = [CIRCUIT_ID, FINAL_ID, IMPACT_ID]
const STAGES: Array[String] = ["circuit", "final", "hatch", "departed"]
const LOCAL_KEYS: Array[String] = ["api_revision", "schema_version", "world_revision", "stage", "collected_ids", "checkpoint_published", "final_started", "final_defeated", "sources", "impact", "impact_host", "scheduler", "framing"]
const ACTOR_KEYS: Array[String] = ["api_revision", "schema_version", "source_id", "configuration", "hp", "dead", "dormant", "motion", "hurt_left_s", "role_encounter_id", "profile_id", "resolved_role", "reservation_id", "cycle", "sample", "hit_ids", "last_cancel_reason"]
const IMPACT_KEYS: Array[String] = ["api_revision", "schema_version", "mechanism_id", "configuration", "status", "phase", "cycle", "clock_s", "resolved_role", "exchange_encounter_id", "exchange", "hero_samples", "hit_ids", "last_cancel_reason"]
const SCHEDULER_KEYS: Array[String] = ["api_revision", "schema_version", "encounter_id", "profile", "world_revision", "clock_s", "serial", "collision", "reservations", "cooldowns"]
const IMPACT_HOST_KEYS: Array[String] = ["host_id", "host_cycle", "host_reservation_id", "host_start_s", "host_active_until_s", "host_recovery_until_s", "opening_position", "primary_time_s", "response_complete_s", "supported"]
const PROGRESS_KEYS: Array[String] = ["completed", "completion_id", "contact_exit_id", "checkpoint_id", "checkpoint_kind", "checkpoint_ids"]
const FRAME_KEYS: Array[String] = ["reservation_id", "proof"]
const PROOF_KEYS: Array[String] = ["accepted", "path", "landing", "attack_position", "primary_time_s", "response_complete_s", "uses_blast", "uses_invulnerability", "proof_scope"]
const PATH_KEYS: Array[String] = ["from", "to", "start_s", "end_s", "kind"]


static func envelope_error(value: Variant) -> String:
	if Exact.stringify(value).is_empty(): return "O1 requires complete exact finite typed transport"
	if not value is Dictionary: return "O1 local state must be a closed Dictionary"
	var saved: Dictionary = value
	var error: String = Codec.keys_error(saved, LOCAL_KEYS)
	if not error.is_empty(): return error
	if not saved.api_revision is String or saved.api_revision != API_REVISION or not saved.schema_version is int or saved.schema_version != SCHEMA_VERSION or not saved.world_revision is int or saved.world_revision != WORLD_REVISION:
		return "Unsupported exact O1 local metadata revision"
	if not saved.stage is String or saved.stage not in STAGES or not saved.collected_ids is Array or saved.collected_ids.size() > PART_IDS.size():
		return "Closed O1 stage and finite original contact-order list required"
	var seen: Dictionary = {}
	for id: Variant in saved.collected_ids:
		if not id is String or id not in PART_IDS or seen.has(id): return "Collected parts must be unique actual stable IDs in their original contact order"
		seen[id] = true
	for key: String in ["checkpoint_published", "final_started", "final_defeated"]:
		if not saved[key] is bool: return "Actual O1 progression flags must remain booleans: " + key
	for key: String in ["sources", "impact", "impact_host", "scheduler", "framing"]:
		if not saved[key] is Dictionary: return "Complete native dictionary required: " + key
	if not Codec.keys_error(saved.sources, SOURCE_IDS).is_empty(): return "Exactly both retained O1 C30 sources required"
	for id: String in SOURCE_IDS:
		error = _actor_envelope_error(saved.sources[id], id)
		if not error.is_empty(): return error
	error = _impact_envelope_error(saved.impact)
	if not error.is_empty(): return error
	error = _scheduler_envelope_error(saved.scheduler)
	if not error.is_empty(): return error
	error = _impact_host_error(saved)
	return _framing_error(saved) if error.is_empty() else error


## Metadata coherence only. The actual parent rejects callbacks/publication
## windows before capture; this codec accepts only their settled authored state.
static func metadata_error(saved: Dictionary) -> String:
	var error: String = envelope_error(saved)
	if not error.is_empty(): return error
	var final_source: Dictionary = saved.sources[FINAL_ID]
	if saved.final_defeated != final_source.dead: return "Final defeat flag must mirror the complete native C30 death state"
	if saved.final_started == final_source.dormant: return "Final source is pristine dormant until its real final epoch activates it"
	if saved.scheduler.encounter_id != (FINAL_ENCOUNTER_ID if saved.final_started else CIRCUIT_ENCOUNTER_ID):
		return "Scheduler retains the actual circuit epoch until the genuine final epoch begins"
	if saved.stage == "circuit":
		if saved.collected_ids.size() >= PART_IDS.size() or saved.checkpoint_published or saved.final_started or saved.final_defeated:
			return "Circuit capture precedes the deferred three-part checkpoint and final activation"
	else:
		if saved.collected_ids.size() != PART_IDS.size() or not saved.checkpoint_published:
			return "Final approach and repaired hatch retain all three real contacts and their checkpoint"
		if saved.stage == "final":
			if saved.final_defeated: return "Native final defeat must already settle into hatch before capture"
		elif not saved.final_started or not saved.final_defeated:
			return "Hatch and departure require the actually activated and genuinely defeated final source"
	if not saved.final_started and saved.final_defeated: return "Unactivated final source cannot carry defeat"
	return ""


## Call after CinderLevel's exact whole-envelope and local/native prevalidation.
## This verifies local/progress agreement without emitting a progression event.
## Completion is the genuine repaired-hatch contact; the deferred exit request
## can leave contact_exit_id empty in the already completed departed packet.
static func progress_error(snapshot: Dictionary) -> String:
	if not snapshot.get("local") is Dictionary or not snapshot.get("progress") is Dictionary:
		return "Whole O1 local and CinderLevel progress dictionaries required"
	var saved: Dictionary = snapshot.local
	var error: String = metadata_error(saved)
	if not error.is_empty(): return error
	var progress: Dictionary = snapshot.progress
	if not Codec.keys_error(progress, PROGRESS_KEYS).is_empty() or not progress.completed is bool or not progress.completion_id is String or not progress.contact_exit_id is String or not progress.checkpoint_id is String or not progress.checkpoint_kind is String or not progress.checkpoint_ids is Dictionary:
		return "Exact closed typed CinderLevel progress required"
	var history: Dictionary = {CHECKPOINT_ID: "encounter"} if saved.checkpoint_published else {}
	if not _same(progress.checkpoint_ids, history) or progress.checkpoint_id != (CHECKPOINT_ID if saved.checkpoint_published else "") or progress.checkpoint_kind != ("encounter" if saved.checkpoint_published else ""):
		return "O1 retains only its genuine pre-final three-part checkpoint"
	var departed: bool = saved.stage == "departed"
	if progress.completed != departed or progress.completion_id != (COMPLETION_ID if departed else ""):
		return "O1 completion requires the settled actual repaired-hatch departure"
	if progress.contact_exit_id not in (["", EXIT_ID] if departed else [""]):
		return "Only departed O1 may retain its original repaired-hatch contact exit"
	return ""


static func _actor_envelope_error(value: Variant, id: String) -> String:
	if not value is Dictionary: return "Complete native C30 packet required: " + id
	var packet: Dictionary = value
	var keys: Array[String] = ACTOR_KEYS.duplicate()
	if packet.get("schema_version") == 3: keys.append("pending_segments")
	if not Codec.keys_error(packet, keys).is_empty() or packet.get("api_revision") != "act1-rush-selenite-1" or not packet.get("schema_version") is int or packet.schema_version not in [2, 3] or not packet.get("source_id") is String or packet.source_id != id:
		return "Exact complete native C30 schema2 or conditional pending schema3 required: " + id
	if not packet.configuration is Dictionary or packet.configuration.get("source_id") != id or not packet.hp is float or not Codec.in_range(packet.hp, 0.0, 1000000000.0) or not packet.dead is bool or packet.dead != (packet.hp == 0.0) or not packet.dormant is bool:
		return "Native C30 identity, finite HP, death and dormancy metadata required: " + id
	for key: String in ["motion", "resolved_role", "sample"]:
		if not packet[key] is Dictionary: return "Whole native C30 dictionary required: " + key
	for key: String in ["role_encounter_id", "profile_id", "reservation_id", "last_cancel_reason"]:
		if not packet[key] is String: return "Original native C30 string metadata required: " + key
	if not packet.hurt_left_s is float or not Codec.in_range(packet.hurt_left_s, 0.0, 1000000000.0) or not packet.cycle is int or not Codec.is_integer(packet.cycle) or not packet.hit_ids is Array:
		return "Complete typed native C30 hurt/cycle/hit history required: " + id
	if packet.schema_version == 3 and (not packet.pending_segments is Array or packet.pending_segments.is_empty()):
		return "Conditional C30 schema3 keeps its complete nonempty pending path"
	return ""


static func _impact_envelope_error(packet: Dictionary) -> String:
	var keys: Array[String] = IMPACT_KEYS.duplicate()
	if packet.get("schema_version") == 2: keys.append("pending_segments")
	if not Codec.keys_error(packet, keys).is_empty() or packet.get("api_revision") != "lane-mechanism-1" or not packet.get("schema_version") is int or packet.schema_version not in [1, 2] or not packet.get("mechanism_id") is String or packet.mechanism_id != IMPACT_ID:
		return "Whole original Lane schema1 or conditional pending schema2 impact required"
	if not packet.configuration is Dictionary or packet.configuration.get("mechanism_id") != IMPACT_ID or not packet.status is String or packet.status not in ["idle", "running", "cancelled", "complete"] or not packet.phase is String or not packet.cycle is int or not Codec.is_integer(packet.cycle) or not packet.clock_s is float or not Codec.in_range(packet.clock_s, 0.0, 1000000000.0):
		return "Actual impact identity, status, cycle and original finite float clock required"
	for key: String in ["resolved_role", "exchange", "hero_samples"]:
		if not packet[key] is Dictionary: return "Complete native impact dictionary required: " + key
	if not packet.hit_ids is Array or not packet.exchange_encounter_id is String or not packet.last_cancel_reason is String:
		return "Whole typed impact exchange and hit history required"
	if packet.schema_version == 2 and (not packet.pending_segments is Dictionary or packet.pending_segments.is_empty()):
		return "Conditional Lane schema2 keeps its complete nonempty pending hero paths"
	return ""


static func _scheduler_envelope_error(packet: Dictionary) -> String:
	if not Codec.keys_error(packet, SCHEDULER_KEYS).is_empty() or packet.get("api_revision") != "scheduler-snapshot-1" or not packet.get("schema_version") is int or packet.schema_version != 1:
		return "O1 retains complete ordinary native Scheduler schema1, without replay or sampled-source registration"
	if not packet.encounter_id is String or not packet.profile is Dictionary or not packet.world_revision is int or packet.world_revision != WORLD_REVISION or not packet.clock_s is float or not Codec.in_range(packet.clock_s, 0.0, 1000000000.0) or not packet.serial is int or not Codec.is_integer(packet.serial) or not packet.collision is Dictionary or not packet.reservations is Array or not packet.cooldowns is Array:
		return "Whole exact typed native Scheduler metadata and original float clock required"
	return ""


## Original companion-impact custody survives after its host lease retires.
## The parent separately checks this exact witness against immutable C30 role
## arithmetic, whole native impact exchange and actual current/retained history.
static func _impact_host_error(saved: Dictionary) -> String:
	var host: Dictionary = saved.impact_host
	if saved.impact.cycle == 0:
		return "" if host.is_empty() else "Unused impact cannot invent a host reservation"
	if not Codec.keys_error(host, IMPACT_HOST_KEYS).is_empty() or not host.host_id is String or host.host_id != CIRCUIT_ID or not host.host_cycle is int or not Codec.is_integer(host.host_cycle, 1) or host.host_cycle > saved.sources[CIRCUIT_ID].cycle or not host.host_reservation_id is String or not host.host_reservation_id.begins_with("threat-") or not host.supported is bool or not _native_vector(host.opening_position):
		return "Used impact retains its complete original supported circuit-rusher custody"
	for key: String in ["host_start_s", "host_active_until_s", "host_recovery_until_s", "primary_time_s", "response_complete_s"]:
		if not host[key] is float or not Codec.in_range(host[key], 0.0, 1000000000.0): return "Original finite typed host/ordinary-response deadlines required"
	if host.host_active_until_s <= host.host_start_s or host.host_recovery_until_s <= host.host_active_until_s or host.response_complete_s < host.primary_time_s or (not saved.final_started and host.host_start_s > saved.scheduler.clock_s):
		return "Companion impact retains its original host chronology and ordinary-response order"
	if host.supported:
		if host.primary_time_s < host.host_active_until_s or host.response_complete_s >= host.host_recovery_until_s:
			return "Supported companion impact keeps the full ordinary response inside its original host recovery"
	elif saved.impact.status != "cancelled" or saved.impact.last_cancel_reason != COMPOUND_REFUSAL or not saved.sources[CIRCUIT_ID].reservation_id.is_empty() or saved.sources[CIRCUIT_ID].last_cancel_reason != COMPOUND_REFUSAL:
		return "Failed compound admission retains both genuine cancellations and its original outside-window history"
	# begin_encounter resets the Scheduler clock. A retained circuit-host witness
	# is historical after final_started, never retimed against the new final epoch.
	return ""


static func _framing_error(saved: Dictionary) -> String:
	var records: Dictionary = {}
	for value: Variant in saved.scheduler.reservations:
		if not value is Dictionary or not value.get("source_id") is String or value.source_id not in RESERVATION_SOURCE_IDS or records.has(value.source_id) or not value.get("id") is String or value.id.is_empty():
			return "Unique actual O1 native reservation owner and lease ID required"
		records[value.source_id] = value
	if not Codec.keys_error(saved.framing, records.keys()).is_empty(): return "Full original response proofs cover exactly the current O1 native reservations"
	for id: String in saved.framing:
		var value: Variant = saved.framing[id]
		var record: Dictionary = records[id]
		if not value is Dictionary or not Codec.keys_error(value, FRAME_KEYS).is_empty() or not value.reservation_id is String or value.reservation_id != record.id or not value.proof is Dictionary:
			return "Each retained frame needs its exact native reservation ID and complete encoded proof"
		var error: String = proof_error(value.proof, record)
		if not error.is_empty(): return id + ": " + error
	return ""


## Pure copied-wire structure only. The actual parent separately proves native
## geometry, full Player shape, supported scenery, ordinary reach and optics.
static func proof_error(proof: Dictionary, record: Dictionary) -> String:
	if not Codec.keys_error(proof, PROOF_KEYS).is_empty() or not proof.accepted is bool or not proof.accepted or not proof.uses_blast is bool or proof.uses_blast or not proof.uses_invulnerability is bool or proof.uses_invulnerability or proof.proof_scope != "static_box_floor_full_dash_stationary_primary" or not proof.path is Array or proof.path.size() not in [4, 6] or not _native_vector(proof.landing) or not _native_vector(proof.attack_position):
		return "Complete original ordinary-primary response proof required"
	for key: String in ["start_s", "active_until_s", "recovery_until_s"]:
		if not record.get(key) is float or not Codec.in_range(record[key], 0.0, 1000000000.0): return "Original native reservation float deadline required"
	if not proof.primary_time_s is float or not proof.response_complete_s is float or not Codec.in_range(proof.primary_time_s, record.active_until_s, record.recovery_until_s) or not Codec.in_range(proof.response_complete_s, proof.primary_time_s, record.recovery_until_s) or proof.response_complete_s >= record.recovery_until_s:
		return "Full ordinary primary and response must fit the original recovery interval"
	var kinds: Array = ["recognition_and_ready", "escape_dash", "recovery_wait", "ordinary_primary"] if proof.path.size() == 4 else ["recognition_and_ready", "escape_dash", "recovery_wait", "positioning_dash", "primary_ready", "ordinary_primary"]
	var previous: Dictionary = {}
	for index: int in range(proof.path.size()):
		var value: Variant = proof.path[index]
		if not value is Dictionary or not Codec.keys_error(value, PATH_KEYS).is_empty() or not _native_vector(value.from) or not _native_vector(value.to) or not value.start_s is float or not value.end_s is float or not Codec.in_range(value.start_s, 0.0, 1000000000.0) or not Codec.in_range(value.end_s, value.start_s, 1000000000.0) or value.kind != kinds[index]:
			return "Complete finite native proof segments and their original order required"
		if value.start_s == value.end_s and not _same(value.from, value.to): return "Zero-time native proof segment cannot hide displacement"
		if index == 0 and not _same(value.start_s, record.start_s): return "Native proof begins at the original admission clock"
		if not previous.is_empty() and (not _same(previous.end_s, value.start_s) or not _same(previous.to, value.from)): return "Native proof retains exact contiguous times and endpoints"
		if value.kind not in ["escape_dash", "positioning_dash"] and not _same(value.from, value.to): return "Waiting and ordinary primary cannot hide travel"
		previous = value
	if not _same(proof.path[1].to, proof.landing) or not _same(previous.from, proof.attack_position) or not _same(previous.to, proof.attack_position) or not _same(previous.start_s, proof.primary_time_s) or not _same(previous.end_s, proof.response_complete_s):
		return "Proof retains its whole original landing, attack position and response timing"
	return ""


static func _native_vector(value: Variant) -> bool:
	return Codec.is_vector3(value) and _same(value, Codec.vector3(Codec.read_vector3(value)))


static func _same(left: Variant, right: Variant) -> bool:
	var text: String = Exact.stringify(left)
	return not text.is_empty() and text == Exact.stringify(right)
