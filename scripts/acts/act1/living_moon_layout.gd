class_name Act1LivingMoonLayout
extends RefCounted
## A1-L5 compact return and local cheek-side encounter. Detached authored data;
## no actors, clock, samples, movement clamp, checkpoint or private shared API.
## Coordinates and tuning are provisional until actual portrait/native checks.

const LEVEL_ID: String = "A1-L5"
const LAYOUT_REVISION: int = 1
const FLOOR_SIZE: Vector3 = Vector3(14, 1, 26)
const FLOOR_CENTRE: Vector3 = Vector3(0, -0.5, -2)
const FLOOR_RECT: Rect2 = Rect2(-7, -15, 14, 26)
const SAFE_RECT: Rect2 = Rect2(-6.5, -14.5, 13, 25)
const SPAWN_POSITION: Vector3 = Vector3(0, 0.1, 4)
const BOSS_RECT: Rect2 = Rect2(-6.5, -14.5, 13, 8)
const IMPACT_ID: String = "moon-return-impact"
const IMPACT_POSITION: Vector3 = Vector3(-1.4, 0, 1.3)
const IMPACT_RADIUS: float = 0.9
const RUSHER_ID: String = "moon-return-rusher"
const RUSHER_POSITION: Vector3 = Vector3(1.6, 0, -0.4)
const CAPSULE_CHECKPOINT_POSITION: Vector3 = Vector3(0, 0, -4.5)
const BOSS_THRESHOLD_POSITION: Vector3 = Vector3(0, 0, -6.5)
const EYE_ID: String = "moon-eye"
const EYE_POSITION: Vector3 = Vector3(0, 0, -9)
const NOSE_ID: String = "moon-nose"
const NOSE_LOCAL_POSITION: Vector3 = Vector3(2, 0, -1)
const EYE_APPROACH_POSITION: Vector3 = Vector3(0, 0, -7.6)
const HATCH_POSITION: Vector3 = Vector3(-3.4, 0, -11)
const HATCH_CONTACT_SIZE: Vector3 = Vector3(1.8, 1.6, 1.2)
const HATCH_CONTACT_OFFSET: Vector3 = Vector3(0, 0.8, 0)
const BOSS_MAX_HP: float = 240.0
const BOSS_PHASE_THRESHOLDS: Array[float] = [160.0, 80.0]
const SNEEZE_REACH: float = 3.2
const SNEEZE_MIN_DOT: float = 0.65
const SNEEZE_ORIGIN_RADIUS: float = 0.1
const ESCAPE_DURATION_S: float = 0.75

const BEAT_IDS: Array[String] = ["return", "capsule", "blink", "sneeze", "final", "escape"]
const CHECKPOINT_IDS: Array[String] = ["capsule-ready", "moon-phase-2", "moon-phase-3"]


static func immutable_specs() -> Dictionary:
	return {"level_id": LEVEL_ID, "revision": LAYOUT_REVISION,
		"floor_size": FLOOR_SIZE, "floor_centre": FLOOR_CENTRE,
		"floor_rect": FLOOR_RECT, "safe_rect": SAFE_RECT, "spawn": SPAWN_POSITION,
		"boss_rect": BOSS_RECT, "impact_id": IMPACT_ID, "impact_position": IMPACT_POSITION,
		"impact_radius": IMPACT_RADIUS, "rusher_id": RUSHER_ID, "rusher_position": RUSHER_POSITION,
		"capsule_checkpoint": CAPSULE_CHECKPOINT_POSITION, "boss_threshold": BOSS_THRESHOLD_POSITION,
		"eye_id": EYE_ID, "eye_position": EYE_POSITION, "nose_id": NOSE_ID,
		"nose_local_position": NOSE_LOCAL_POSITION, "eye_approach": EYE_APPROACH_POSITION,
		"hatch_position": HATCH_POSITION, "hatch_contact_size": HATCH_CONTACT_SIZE,
		"hatch_contact_offset": HATCH_CONTACT_OFFSET, "boss_max_hp": BOSS_MAX_HP,
		"phase_thresholds": BOSS_PHASE_THRESHOLDS.duplicate(), "sneeze_reach": SNEEZE_REACH,
		"sneeze_min_dot": SNEEZE_MIN_DOT, "sneeze_origin_radius": SNEEZE_ORIGIN_RADIUS,
		"escape_duration_s": ESCAPE_DURATION_S, "beat_ids": BEAT_IDS.duplicate(),
		"checkpoint_ids": CHECKPOINT_IDS.duplicate()}
