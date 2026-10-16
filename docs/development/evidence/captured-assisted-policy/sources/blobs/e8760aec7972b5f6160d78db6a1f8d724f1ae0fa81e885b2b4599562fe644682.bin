extends RefCounted
## SOURCE-ONLY concrete closed phase receipt policy; no gameplay controller.
## Root may inline these constants in the authored parent rather than import it.
## Native actor/source/whole-unit/optical validation remains the parent's job.

const STAGES: Array[String] = ["offered-world", "plain-threshold", "capture-one", "capture-two", "beyond-image"]
const CHECKPOINTS: Array[String] = ["crystalman-offered-entry", "crystalman-plain-entry", "crystalman-phase1-entry", "crystalman-phase2-entry", "crystalman-bare-platform"]
const KINDS: Array[String] = ["encounter", "encounter", "boss_phase", "boss_phase", "encounter"]
const REGULAR_IDS: Array[String] = ["l5-offered-echo", "l5-plain-stalker", "l5-plain-echo"]
const COMPLETE_ID: String = "crystalman-local-tethers-released"
const CONTACT_ID: String = "crystalman-local-escape"


static func checkpoint_for_stage(stage: String) -> Dictionary:
	var index: int = STAGES.find(stage)
	return {} if index < 0 else {"id": CHECKPOINTS[index], "kind": KINDS[index]}


static func phase_metadata_error(receipt: Dictionary, capacity: int) -> String:
	# Validate authored closed history structure; these hashes do not prove an
	# untrusted save was earned. Real live production creates the receipt only
	# after the native Gate/Scheduler/Playback and ordinary tether checks pass.
	const KEYS: Array[String] = ["accepted", "reason", "phase_id", "capacity", "generation", "sequence_id", "completed_at_actor_s", "completed_at_unit_s", "retirement_slot_ids", "retirement_sha256", "sequence_sha256", "projection_sha256", "delivered_attack_count", "tether_hits", "disposition"]
	if capacity not in [1, 2] or receipt.size() != KEYS.size(): return "Closed one/two-slot phase receipt required"
	for key: String in KEYS:
		if not receipt.has(key): return "Missing closed phase receipt field: " + key
	if not receipt.accepted is bool or not receipt.capacity is int or not receipt.tether_hits is int or receipt.accepted != true or receipt.reason != "" or receipt.capacity != capacity or receipt.phase_id != ("capture-one" if capacity == 1 else "capture-two") or receipt.disposition != "whole_unit_disposal" or receipt.tether_hits != 1:
		return "Original spent phase identity/result required"
	if not receipt.generation is int or receipt.generation < 1 or not receipt.sequence_id is String or receipt.sequence_id != "crystalman-rule/sequence-" + str(receipt.generation):
		return "Actual finite generation/sequence identity required"
	for key: String in ["completed_at_actor_s", "completed_at_unit_s"]:
		if not receipt[key] is float or not is_finite(receipt[key]) or receipt[key] < 0.0 or receipt[key] > 1000000.0: return "Original independent native clock required: " + key
	if not receipt.retirement_slot_ids is Array or receipt.retirement_slot_ids.size() != capacity: return "Exactly the consumed finite FIFO slots required"
	var previous: int = 0
	for id: Variant in receipt.retirement_slot_ids:
		if not id is int or id <= previous: return "Monotonic distinct once-only FIFO retirement required"
		previous = id
	if not receipt.delivered_attack_count is int or receipt.delivered_attack_count < capacity or receipt.delivered_attack_count > capacity * 2:
		return "Each slot contains one primary and at most one actually executed optional blast"
	for key: String in ["retirement_sha256", "sequence_sha256", "projection_sha256"]:
		if not receipt[key] is String or receipt[key].length() != 64: return "Exact native source digest required"
		for c: String in receipt[key]:
			if not "0123456789abcdef".contains(c): return "Source digest must be lowercase SHA256"
	return ""
