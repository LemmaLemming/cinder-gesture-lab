extends "res://scripts/game.gd"
## TEST ONLY initial profile provider for the actual authored level's documented
## public getter. Shared controller, physics, cues and entry logic are inherited.
var test_profile_id: String = "standard"


func get_difficulty_preference() -> String:
	return test_profile_id
