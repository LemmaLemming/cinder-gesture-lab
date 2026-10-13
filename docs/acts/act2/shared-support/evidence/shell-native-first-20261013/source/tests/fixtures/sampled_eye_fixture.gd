extends CharacterBody3D
## Shared56 native sampled-circle focused fixture.
## The fixture IS the genuine scripted eye HP receiver / Scheduler owner.
## No helper body, fake source getter, surrogate primary target or UID is used.

signal damaged(result: Dictionary)
signal died

const Player = preload("res://scripts/player.gd")
const Scheduler = preload("res://scripts/combat/threat_scheduler.gd")
const Consumer = preload("res://scripts/combat/native_sampled_circle.gd")
const Codec = preload("res://scripts/campaign/snapshot_codec.gd")
const Geometry = preload("res://scripts/combat/threat_geometry.gd")
const RAW_ROLE: Dictionary = {"raw_damage": 4.0, "windup_s": 2.2, "lock_s": 1.1, "active_s": 0.2, "recovery_s": 1.6, "attack_interval_s": 1.8, "max_hp": 14.0, "move_speed": 0.0}
const TIMING_FLOORS: Dictionary = {"windup_s": 2.2, "lock_s": 1.1, "recovery_s": 1.6}
const DEFINITION: Dictionary = {"radius": 0.8, "raw_role": RAW_ROLE, "timing_floors": TIMING_FLOORS}
const SOURCE_POSITION: Vector3 = Vector3(2.7, 0.0, 1.0)

var hp: float = 14.0
var dead: bool = false
var last_snapshot_error: String = ""
var _hero_ref: WeakRef
var _scheduler_ref: WeakRef
var _consumer_ref: WeakRef
var _damage_busy: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 2
	collision_mask = 1
	var collision := CollisionShape3D.new()
	collision.name = "BodyCollision"
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 1.0, 0.8)
	collision.shape = box
	collision.position = Vector3(0.0, 0.5, 0.0)
	add_child(collision)
	add_to_group("enemies")
	var consumer := Consumer.new()
	consumer.name = "Blink"
	add_child(consumer)
	_consumer_ref = weakref(consumer)


func get_sampled_circle_binding() -> Dictionary:
	## Pure actual receiver binding: immutable recipe/incarnation, true HP/death,
	## fixed real body opening, and the retained exact shared Hero itself.
	var value: Variant = _hero_ref.get_ref() if _hero_ref != null else null
	return {"api_revision": "sampled-circle-source-1", "source_id": "moon-eye", "source_epoch": "moon-eye-fixture-epoch-1", "generation": 1, "definition": DEFINITION.duplicate(true), "alive": hp > 0.0 and not dead, "opening_position": global_position, "hero_id": "hero", "hero": value if is_instance_valid(value) and value is CinderPlayer else null}


func parent_presentation_guard(source_id: String, consumer_state: Dictionary) -> bool:
	var consumer: CinderNativeSampledCircle = consumer_node()
	return source_id == "moon-eye" and consumer_state.get("source_id") == source_id and hp > 0.0 and not dead and is_inside_tree() and not is_queued_for_deletion() and is_visible_in_tree() and is_instance_valid(consumer) and consumer.get_parent() == self and consumer.is_visible_in_tree()


func take_damage(amount: float, _impulse: Vector3) -> Dictionary:
	## Declared anchored-eye policy: primary damage changes true HP/death only;
	## its incoming impact impulse never moves this fixed receiver or its opening.
	## No gravity/knockback/dummy body resets are used to fake stationarity.
	var consumer: CinderNativeSampledCircle = consumer_node()
	if _damage_busy or dead or hp <= 0.0 or not is_instance_valid(consumer) or consumer.state().phase != "recovery" or not Geometry.finite_number(amount) or amount <= 0.0:
		return {"accepted": false, "hp_damage": 0.0}
	_damage_busy = true
	var before: float = hp
	hp = maxf(hp - amount, 0.0)
	dead = hp == 0.0
	var result := {"accepted": true, "hp_damage": before - hp, "target_alive_before_hit": true}
	if dead:
		# The genuine receiver retires its own lease before notifying observers.
		var scheduler: CinderThreatScheduler = scheduler_node()
		if is_instance_valid(scheduler): scheduler.cancel_owner(self, "source_defeated")
		remove_from_group("enemies")
		died.emit()
	damaged.emit(result.duplicate(true))
	_damage_busy = false
	return result


func consumer_node() -> CinderNativeSampledCircle:
	var value: Variant = _consumer_ref.get_ref() if _consumer_ref != null else null
	return value if is_instance_valid(value) and value is CinderNativeSampledCircle else null


func scheduler_node() -> CinderThreatScheduler:
	var value: Variant = _scheduler_ref.get_ref() if _scheduler_ref != null else null
	return value if is_instance_valid(value) and value is CinderThreatScheduler else null


func snapshot_state() -> Dictionary:
	last_snapshot_error = _snapshot_boundary_error()
	if not last_snapshot_error.is_empty(): return {}
	var hook: Dictionary = get_sampled_circle_binding()
	hook.erase("hero")
	hook.opening_position = Codec.vector3(hook.opening_position)
	var collision: CollisionShape3D = get_node("BodyCollision")
	var packet := {"api_revision": "sampled-eye-fixture-snapshot-1", "schema_version": 1, "source_binding": hook, "hp": hp, "dead": dead, "position": Codec.vector3(global_position), "velocity": Codec.vector3(velocity), "collision_disabled": collision.disabled}
	last_snapshot_error = snapshot_error(packet)
	return packet.duplicate(true) if last_snapshot_error.is_empty() else {}


func snapshot_error(packet: Dictionary) -> String:
	var error: String = _snapshot_boundary_error()
	if error.is_empty(): error = Codec.value_error(packet)
	if error.is_empty(): error = Codec.keys_error(packet, ["api_revision", "schema_version", "source_binding", "hp", "dead", "position", "velocity", "collision_disabled"])
	if not error.is_empty(): return error
	if packet.api_revision != "sampled-eye-fixture-snapshot-1" or not packet.schema_version is int or packet.schema_version != 1 or not packet.hp is float or not Codec.in_range(packet.hp, 0.0, 14.0) or not packet.dead is bool or packet.dead != (packet.hp == 0.0) or not packet.collision_disabled is bool or (not packet.dead and packet.collision_disabled) or not Codec.is_vector3(packet.position) or Codec.read_vector3(packet.position) != SOURCE_POSITION or not Codec.is_vector3(packet.velocity) or Codec.read_vector3(packet.velocity) != Vector3.ZERO or not packet.source_binding is Dictionary or not Codec.keys_error(packet.source_binding, Consumer.SOURCE_WIRE_KEYS).is_empty(): return "Exact true physical eye HP/death/pose/body packet required"
	var actual: Dictionary = get_sampled_circle_binding()
	actual.erase("hero")
	actual.opening_position = Codec.vector3(SOURCE_POSITION)
	actual.alive = packet.hp > 0.0 and not packet.dead
	if not Consumer._same_exact(actual, packet.source_binding): return "Saved true eye lifecycle must join its immutable actual source recipe/Hero"
	return ""


func restore_state(packet: Dictionary) -> bool:
	last_snapshot_error = snapshot_error(packet)
	if not last_snapshot_error.is_empty(): return false
	# Trusted physical commit at the whole-parent paused barrier, no observers.
	hp = float(packet.hp)
	dead = packet.dead
	global_position = Codec.read_vector3(packet.position)
	velocity = Codec.read_vector3(packet.velocity)
	(get_node("BodyCollision") as CollisionShape3D).disabled = packet.collision_disabled
	if dead: remove_from_group("enemies")
	elif not is_in_group("enemies"): add_to_group("enemies")
	return true


func _snapshot_boundary_error() -> String:
	if not is_inside_tree() or not is_node_ready() or not get_tree().paused or _damage_busy: return "Physical eye packets require a ready quiet paused barrier"
	var value: Variant = get_node_or_null("BodyCollision")
	if not is_instance_valid(value) or not value is CollisionShape3D or not value.shape is BoxShape3D: return "Actual supported eye BodyCollision required"
	return ""


static func create(tree: SceneTree, bind_source: bool = true) -> Dictionary:
	var world := Node3D.new()
	world.name = "SampledEyeWorld"
	tree.root.add_child(world)
	var floor := StaticBody3D.new()
	floor.name = "Floor"
	floor.collision_layer = 1
	floor.collision_mask = 0
	var support := CollisionShape3D.new()
	support.name = "Support"
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 1.0, 20.0)
	support.shape = box
	floor.add_child(support)
	world.add_child(floor)
	floor.position.y = -0.5
	var hero: CinderPlayer = Player.new()
	hero.name = "Hero"
	world.add_child(hero)
	hero.shells = 0
	var scheduler: CinderThreatScheduler = Scheduler.new()
	scheduler.name = "Scheduler"
	world.add_child(scheduler)
	var eye = load("res://tests/fixtures/sampled_eye_fixture.gd").new()
	eye.name = "Eye"
	eye.position = SOURCE_POSITION
	eye._hero_ref = weakref(hero)
	eye._scheduler_ref = weakref(scheduler)
	world.add_child(eye)
	var consumer: CinderNativeSampledCircle = eye.consumer_node()
	var region := {"collision": support, "safe_rect": Rect2(-10.0, -10.0, 20.0, 20.0)}
	var bound: bool = bind_source and consumer.bind(eye, scheduler, "hero", hero, world, [region])
	var guarded: bool = bound and consumer.set_presentation_guard(eye.parent_presentation_guard)
	return {"root": world, "hero": hero, "eye": eye, "scheduler": scheduler, "consumer": consumer, "region": region, "bound": bound, "guarded": guarded}


static func context(arena: Dictionary, encounter_id: String) -> Dictionary:
	return {"encounter_id": encounter_id, "world_revision": 1, "recognition_s": 0.12, "attack_input_margin_s": 0.02, "escape_directions": [Vector3.RIGHT, Vector3.BACK, Vector3.FORWARD], "return_directions": [Vector3.RIGHT, Vector3.BACK, Vector3.FORWARD], "floor_regions": [arena.region], "world_root": arena.root}


static func bindings(arena: Dictionary) -> Dictionary:
	return {"world_root": arena.root, "owners": {"moon-eye": arena.eye}, "floors": {"main-floor": arena.region}, "actors": {"hero": arena.hero}}


static func capture(arena: Dictionary) -> Dictionary:
	## Caller has settled an actual parent tick and entered the paused barrier.
	var player_packet: Dictionary = arena.hero.snapshot_state()
	var eye_packet: Dictionary = arena.eye.snapshot_state()
	var scheduler_packet: Dictionary = arena.scheduler.snapshot_state(bindings(arena))
	var consumer_packet: Dictionary = arena.consumer.snapshot_state(bindings(arena))
	return {"player": player_packet, "eye": eye_packet, "scheduler": scheduler_packet, "consumer": consumer_packet}


static func aggregate_error(arena: Dictionary, packet: Dictionary) -> String:
	## Validate the complete actual packets before deriving any staged fields.
	var error: String = Codec.keys_error(packet, ["player", "eye", "scheduler", "consumer"])
	if not error.is_empty(): return error
	for key: String in packet:
		if not packet[key] is Dictionary or packet[key].is_empty(): return "Whole-unit packet cannot omit " + key
	error = arena.hero.snapshot_error(packet.player)
	if error.is_empty(): error = arena.eye.snapshot_error(packet.eye)
	if not error.is_empty(): return error
	var staged: Dictionary = bindings(arena)
	staged["hero_positions"] = {"hero": Codec.read_vector3(packet.player.motion.position)}
	staged["hero_action_clocks"] = {"hero": packet.player.world_actions.clock_s}
	staged["owner_positions"] = {"moon-eye": Codec.read_vector3(packet.eye.position)}
	staged["owner_velocities"] = {"moon-eye": Codec.read_vector3(packet.eye.velocity)}
	staged["sampled_owner_bindings"] = {"moon-eye": packet.eye.source_binding.duplicate(true)}
	error = arena.scheduler.snapshot_error(packet.scheduler, staged)
	if error.is_empty(): error = arena.consumer.snapshot_error(packet.consumer, staged, packet.scheduler)
	return error


static func restore_aggregate(arena: Dictionary, packet: Dictionary) -> bool:
	## Fresh whole-unit commit: true Player -> true eye HP/death -> Scheduler
	## -> consumer/Cue/pending paths. No replay/preview/request/phase observers.
	var preflight: String = aggregate_error(arena, packet)
	if not preflight.is_empty():
		print("TRACE sampled restore preflight: ", preflight)
		return false
	if not arena.hero.restore_state(packet.player):
		print("TRACE sampled restore Player: ", arena.hero.last_snapshot_error)
		return false
	if not arena.eye.restore_state(packet.eye):
		print("TRACE sampled restore eye: ", arena.eye.last_snapshot_error)
		return false
	var actual: Dictionary = bindings(arena)
	if not arena.scheduler.restore_state(packet.scheduler, actual):
		print("TRACE sampled restore Scheduler: ", arena.scheduler.last_snapshot_error)
		return false
	var restored: bool = arena.consumer.restore_state(packet.consumer, actual)
	if not restored:
		print("TRACE sampled restore consumer: ", arena.consumer.last_snapshot_error, " phase=", arena.consumer.state().phase, " cue=", arena.consumer.get_cue().last_error, " fault=", arena.consumer.get("_cue_fault"))
	return restored
