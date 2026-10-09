class_name Act1MushroomSeleniteApproach
extends RefCounted
## Stateless, opt-in C31 horizontal movement PROPOSAL, not motion authority.
## Actor/codec API2 explicitly retains immutable opt-in configuration and
## approach-driving state; this helper still grants no live motion permission.
##
## Caller supplies ONLY horizontal velocity owned by its approach controller.
## This API cannot distinguish that velocity from injury, repulsion or a native
## attack. Never call it for those motions, a retained attack/pending delivery,
## hurt settling, dormant/dead actors or a held environmental episode.
## Disabled configuration brakes supplied authored approach motion only.
##
## Caller owns actual ground/gravity, native move_and_slide(), spacing, full
## camera/body/art visibility, world membership, collision and attack admission.
## next_position/braking_position assume free horizontal motion and no added
## drive. They are bounds to inspect, NOT a reachable landing or safety proof.
## Vertical velocity is preserved; future gravity/floor motion is not forecast.
## Braking bounds assume the supplied step cadence; changed/delayed steps need
## a fresh actual guard. A moved nearby target cannot undo existing momentum.
##
## Valid outputs own no nodes, target, clocks, callbacks, leases or mutable state.
## "driving" means proposed nonzero horizontal approach-owned motion, including
## finite braking. "stopped" means the whole proposed velocity is exactly zero;
## neither flag certifies actual floor contact or permission to start an attack.
## Invalid inputs return accepted=false with an error and no motion proposal.

const PROVISIONAL_TUNING: Dictionary = {
	"enabled": false,
	"speed": 1.2,
	"acceleration": 3.0,
	"turn_rate": 3.0,
	"braking": 5.0,
	"stop_distance": 3.0,
}
const TUNING_KEYS: Array[String] = ["enabled", "speed", "acceleration", "turn_rate", "braking", "stop_distance"]
const MIN_DELTA_S: float = 0.000001
const MAX_DELTA_S: float = 0.25
const MAX_POSITION_COMPONENT: float = 10000.0
const MAX_VELOCITY_COMPONENT: float = 64.0
const UNIT_TOLERANCE: float = 0.00001
const MISALIGNMENT_RADIANS: float = PI / 6.0


func configuration_error(tuning: Dictionary) -> String:
	if tuning.size() != TUNING_KEYS.size():
		return "Complete six-key provisional C31 approach configuration required"
	for key: Variant in tuning.keys():
		if typeof(key) != TYPE_STRING or String(key) not in TUNING_KEYS:
			return "Approach configuration requires exact String keys without additions"
	if typeof(tuning["enabled"]) != TYPE_BOOL:
		return "Approach enabled requires a literal boolean"
	for key: String in TUNING_KEYS:
		if key == "enabled": continue
		var value: Variant = tuning[key]
		if typeof(value) != TYPE_FLOAT or not is_finite(value) or value <= 0.0 or value != PROVISIONAL_TUNING[key]:
			return "Approach " + key + " requires its exact positive provisional float"
	return ""


func plan(position: Vector3, velocity: Vector3, facing: Vector3, target: Vector3, delta: float, tuning: Dictionary) -> Dictionary:
	var error: String = configuration_error(tuning)
	if not error.is_empty(): return _rejected(error, "invalid_configuration")
	if not is_finite(delta) or delta < MIN_DELTA_S or delta > MAX_DELTA_S:
		return _rejected("Approach delta must be finite within [0.000001, 0.25] seconds", "invalid_delta")
	if not _bounded_vector(position, MAX_POSITION_COMPONENT) or not _bounded_vector(target, MAX_POSITION_COMPONENT):
		return _rejected("Finite bounded actual position and target required", "invalid_position")
	if not _bounded_vector(velocity, MAX_VELOCITY_COMPONENT):
		return _rejected("Finite bounded approach-owned velocity required", "invalid_velocity")
	if not facing.is_finite() or facing.y != 0.0 or absf(facing.length_squared() - 1.0) > UNIT_TOLERANCE:
		return _rejected("Finite normalized nonzero planar facing required", "invalid_facing")

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var proposed_facing: Vector3 = facing
	var reason: String = "disabled_braking"
	var desired_speed: float = 0.0
	var advancing: bool = false
	var braking: float = tuning["braking"]

	if tuning["enabled"]:
		var offset := Vector3(target.x - position.x, 0.0, target.z - position.z)
		var distance: float = offset.length()
		var remaining: float = maxf(0.0, distance - float(tuning["stop_distance"]))
		reason = "inside_stop_distance"
		if distance > 0.0:
			var direction: Vector3 = offset / distance
			var current_facing: Vector3 = facing.normalized()
			var angle: float = atan2(current_facing.cross(direction).y, current_facing.dot(direction))
			# Select one deterministic turn at the exactly opposite heading.
			if current_facing.cross(direction).y == 0.0 and current_facing.dot(direction) < 0.0:
				angle = PI
			var turn: float = clampf(angle, -float(tuning["turn_rate"]) * delta, float(tuning["turn_rate"]) * delta)
			proposed_facing = current_facing.rotated(Vector3.UP, turn).normalized()
			var remaining_angle: float = maxf(0.0, absf(angle) - absf(turn))
			if remaining > 0.0 and remaining_angle <= MISALIGNMENT_RADIANS:
				# Desired speed leaves room for one discrete step plus a finite
				# braking path. Existing speed is NEVER snapped down to this cap:
				# a changed nearby target may require several braking steps.
				var step_braking: float = braking * delta
				var stopping_cap: float = maxf(0.0, sqrt(step_braking * step_braking + 2.0 * braking * remaining) - step_braking)
				desired_speed = minf(float(tuning["speed"]), stopping_cap)
				advancing = desired_speed > 0.0
				reason = "approaching" if stopping_cap >= float(tuning["speed"]) else "stopping_distance_limited"
			elif remaining > 0.0:
				reason = "turning_braking"

	if advancing:
		var desired: Vector3 = proposed_facing * desired_speed
		var rate: float = braking if horizontal.length() > desired_speed else float(tuning["acceleration"])
		horizontal = horizontal.move_toward(desired, rate * delta)
	else:
		horizontal = horizontal.move_toward(Vector3.ZERO, braking * delta)

	# Only authored horizontal motion changes. No ground, gravity, collision,
	# impulse or committed attack velocity is silently applied by this helper.
	var proposed_velocity := Vector3(horizontal.x, velocity.y, horizontal.z)
	var next_position: Vector3 = position + proposed_velocity * delta
	var braking_position: Vector3 = next_position
	var speed: float = horizontal.length()
	if speed > 0.0:
		# Include one further response-step allowance before continuous braking.
		# This is conservative for a caller that then brakes by at least this
		# amount each step; collisions/vertical motion remain caller obligations.
		var braking_distance: float = speed * speed / (2.0 * braking) + speed * delta
		braking_position += horizontal / speed * braking_distance
	if not _bounded_vector(proposed_velocity, MAX_VELOCITY_COMPONENT) or not _bounded_vector(next_position, MAX_POSITION_COMPONENT) or not _bounded_vector(braking_position, MAX_POSITION_COMPONENT) or not proposed_facing.is_finite():
		return _rejected("Proposed motion or braking bound exceeds the finite domain", "invalid_proposal")
	return {
		"accepted": true,
		"error": "",
		"reason": reason,
		"velocity": proposed_velocity,
		"facing": proposed_facing,
		"driving": horizontal != Vector3.ZERO,
		"stopped": proposed_velocity == Vector3.ZERO,
		"next_position": next_position,
		"braking_position": braking_position,
	}


func _bounded_vector(value: Vector3, limit: float) -> bool:
	return value.is_finite() and absf(value.x) <= limit and absf(value.y) <= limit and absf(value.z) <= limit


func _rejected(error: String, reason: String) -> Dictionary:
	return {"accepted": false, "error": error, "reason": reason}
