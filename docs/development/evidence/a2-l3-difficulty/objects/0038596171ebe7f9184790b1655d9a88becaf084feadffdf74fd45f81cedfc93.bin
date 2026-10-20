extends RefCounted
## INERT TEST TEXT. Fresh focused component policy, NOT earned HouseSequence.
## No predecessor defeat/contact records, snapshots, restore, HP or cursor setter.
var phase: int = 1
var defeated_ids: Array[String] = []
var crossed_contacts: Array[String] = []
var cleared: bool = false
func current_beat() -> String:
	return "clear" if cleared else ("boss_phase_one" if phase == 1 else "boss_phase_two")
func current_active_ids() -> Array[String]:
	var ids: Array[String] = []
	if not cleared:
		ids.append("handling_machine")
		if phase == 2: ids.append("side_tender")
	for id: String in defeated_ids: ids.erase(id)
	return ids
func current_boss_phase() -> int: return phase
func exit_is_open() -> bool: return cleared
func commit_contact(_id: String) -> bool: return false
func commit_boss_phase_two() -> bool:
	# Actual inherited House validates native HP15/pending transaction first.
	if phase != 1 or cleared: return false
	phase = 2
	return true
func commit_defeat(id: String) -> bool:
	if phase != 2 or not current_active_ids().has(id): return false
	defeated_ids.append(id)
	if id == "handling_machine": cleared = true
	return true
