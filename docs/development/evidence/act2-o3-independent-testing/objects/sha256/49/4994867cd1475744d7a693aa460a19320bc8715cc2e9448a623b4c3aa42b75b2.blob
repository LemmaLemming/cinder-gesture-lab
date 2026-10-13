extends "res://scripts/acts/act1/selenite_court_greybox.gd"
## First authored court presentation over the validated one-guard component.
## Scenery owns no timing, collision, player system or progression authority.

const CourtArtScript = preload("res://scripts/acts/act1/selenite_court_art.gd")

var court_art: Node3D
var _retained_court_art: Node3D
var _court_art_constructed: bool = false
var _court_base_constructor: bool = false


func _ready() -> void:
	_court_base_constructor = true
	super._ready()
	_court_base_constructor = false
	if not _construction_error.is_empty(): return
	court_art = CourtArtScript.build_geometry_art(self, CourtArtScript.entrance_specs())
	if not is_instance_valid(court_art):
		_construction_error = "Authored entrance court scenery could not bind its actual geometry"
		return
	_retained_court_art = court_art
	_court_art_constructed = true
	_construction_error = _scenery_error()


func _scenery_error() -> String:
	var floor_error: String = super._scenery_error()
	if not floor_error.is_empty(): return floor_error
	# The base constructor checks its own original floor before this leaf exists.
	if not _court_art_constructed:
		return "" if _court_base_constructor else "Authored court leaf construction was not completed"
	if not is_instance_valid(court_art) or court_art != _retained_court_art or not court_art.is_inside_tree() or court_art.is_queued_for_deletion() or get_node_or_null("CourtArt") != court_art or court_art.get_parent() != self or court_art.get_script() != CourtArtScript or court_art.transform != Transform3D.IDENTITY or court_art.process_mode != Node.PROCESS_MODE_DISABLED:
		return "Retained authored court presentation root is unavailable or changed"
	return String(court_art.call("binding_error"))
