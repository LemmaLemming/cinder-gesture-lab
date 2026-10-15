extends "res://scripts/game.gd"
## Explicit TEST caller preference, selected before this real Main enters tree.
## Canonical L2 scene, original parent/data, actors and scheduling are untouched.
var legacy_test_profile: String = "standard"

func get_difficulty_preference() -> String:
	return legacy_test_profile
