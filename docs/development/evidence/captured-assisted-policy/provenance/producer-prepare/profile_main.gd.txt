extends "res://scripts/game.gd"
## Explicit TEST profile selected before actual Main enters the tree.
## Production phase/Scheduler/native scripts remain untouched.
var producer_test_profile: String = "standard"
func get_difficulty_preference() -> String:
	return producer_test_profile
