extends SceneTree
const Main = preload("res://scenes/main.tscn")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var game: Node = Main.instantiate()
	root.add_child(game)
	await process_frame
	game.resume_lab()
	var hero: CinderPlayer = game.player
	await create_timer(0.3).timeout
	var response: Dictionary = hero.get_threat_response_state()
	_expect(response.stable and response.actor == hero and response.motion.grounded, "actual settled shared actor reports supported stationary response")
	response.stats.primary_range = 999.0
	response.equipment_ids.weapon = "invalid"
	_expect(hero.get_threat_response_state().stats.primary_range != 999.0 and hero.equipment.snapshot().weapon == "WEAPON-01", "public response copies cannot retune equipment or stats")
	var observations: Array[Dictionary] = []
	game.input_observed.connect(func(record: Dictionary) -> void:
		observations.append(record.duplicate(true))
		record.anchor_normalized = Vector2.ZERO)
	var size: Vector2 = root.get_visible_rect().size
	var start: Vector2 = size * Vector2(0.75,0.4)
	var crossing: Vector2 = size * Vector2(0.55,0.38)
	var release: Vector2 = size * Vector2(0.38,0.36)
	game._begin_pointer(1,start)
	game._drag_pointer(1,crossing)
	game._end_pointer(1,release)
	_expect(not hero.get_threat_response_state().stable and hero.get_threat_response_state().motion.dash_left_s > 0.0, "accepted moving dash reports unsupported motion rather than ideal stationary response")
	_expect(observations.size() == 1 and observations[0].kind == "swipe_release" and observations[0].anchor_normalized.is_equal_approx(Vector2(0.38,0.36)), "observer reports exact final release independently of threshold-crossing dash")
	_expect(game.get_aim_anchor_normalized().is_equal_approx(Vector2(0.38,0.36)), "observer mutation cannot recenter authoritative aim")
	await create_timer(0.6).timeout
	hero.shells = 0
	game.handle_tap(size * 0.5)
	_expect(observations.back().accepted and observations.back().kind == "primary_tap" and observations.back().direction.x > 0.0 and observations.back().direction.z > 0.0, "observed immediate zero-ammo primary uses final-release direction")
	_expect(observations.back().world_action_sequence == int(hero.get_world_action_records().back().sequence), "accepted tap observation links the executed action publication sequence")
	response = hero.get_threat_response_state()
	paused = true
	var snapshot: Dictionary = hero.snapshot_state()
	_expect(response.primary_cooldown_left_s == snapshot.clocks.primary_cooldown_s and response.dash_cooldown_left_s == snapshot.clocks.dash_cooldown_s and response.commitment_remaining_s == snapshot.phases.logical_left_s, "public live response exposes actual remaining clocks from the same actor boundary")
	var clock: float = response.action_clock_s
	await process_frame
	await process_frame
	_expect(hero.get_threat_response_state().action_clock_s == clock, "response clock freezes with paused simulation")
	var before: int = observations.size()
	game.handle_tap(size * 0.5)
	_expect(observations.size() == before, "paused menu/resume taps create no observation or attack")
	paused = false
	game.handle_tap(size * 0.5)
	_expect(observations.back().kind == "blast_tap" and not observations.back().accepted, "empty-ammo followup is observed as rejected without inventing an executed blast")
	var copy: Dictionary = game.get_input_observation_state()
	copy.last_observation.kind = "modified"
	_expect(game.get_input_observation_state().last_observation.kind == "blast_tap", "input observer retains defensive bounded last-record state")
	_expect(game.active_level.shared_shell == game, "level receives the supported public shared-shell reference")
	game.active_level.exit_level()
	_expect(game.active_level.shared_shell == null, "level exit clears shared observer reference")
	game.queue_free()
	await process_frame
	print("Input/response smoke: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
func _expect(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + note)
