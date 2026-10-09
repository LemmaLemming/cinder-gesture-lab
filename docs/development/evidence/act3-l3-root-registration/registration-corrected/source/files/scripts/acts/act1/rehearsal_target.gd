class_name Act1RehearsalTarget
extends PracticeTarget
## Shared health/hit clock with Act 1 cloth and the published attack cue.

const VisualScript: GDScript = preload("res://scripts/acts/act1/rehearsal_target_visual.gd")
const CueScript: GDScript = preload("res://scripts/cues/interaction_cue.gd")

var presentation: Act1RehearsalTargetVisual
var interaction_cue: CinderInteractionCue
var _exercise_active: bool = false
var _latest_state: String = "available"
var _latest_fraction: float = 0.0


func build_presentation() -> void:
	if is_instance_valid(presentation):
		return
	presentation = VisualScript.new() as Act1RehearsalTargetVisual
	presentation.build(self)
	interaction_cue = CueScript.new() as CinderInteractionCue
	interaction_cue.name = "RehearsalAttackCue"
	add_child(interaction_cue)


func present_state(visual_state: String, hit_feedback_fraction: float) -> void:
	_latest_state = visual_state
	_latest_fraction = hit_feedback_fraction
	_redraw()


func set_exercise_active(active: bool) -> void:
	_exercise_active = active
	if active:
		add_to_group("practice_targets")
	else:
		remove_from_group("practice_targets")
	_redraw()


func _redraw() -> void:
	if not is_instance_valid(presentation):
		return
	var authored_state: String = "cleared" if _latest_state == "cleared" else ("available" if _exercise_active else "inactive")
	presentation.present_state(authored_state, _latest_fraction)
	if not is_instance_valid(interaction_cue):
		return
	if _latest_state == "cleared":
		interaction_cue.present("spent", "attack")
	elif _exercise_active and hp > 0.0:
		interaction_cue.present("available", "attack")
	else:
		interaction_cue.clear()
