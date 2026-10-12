class_name Act1SeleniteCourtLayout
extends RefCounted
## A1-L4 whole-level authored layout. Runtime readiness lives in level notes.
## ACT1_CONCEPT.md:185-207 owns the five beats/three open courts, same
## formation pair and one finite King helper pair. G19/G15/G21/F10 inform
## quiet theatre scenery; no concept pixels or combat diagrams are authority.
## This detached table creates no actors, clock, Cue, contact or progression.

const LEVEL_ID: String = "A1-L4"
const LAYOUT_REVISION: int = 2
const FLOOR_SIZE: Vector3 = Vector3(14, 1, 44)
const FLOOR_CENTRE: Vector3 = Vector3(0, -0.5, -17)
const FLOOR_RECT: Rect2 = Rect2(-7, -39, 14, 44)
const SAFE_RECT: Rect2 = Rect2(-6.5, -38.5, 13, 43)
const SPAWN_POSITION: Vector3 = Vector3(0, 0.1, 0)
const FLOOR_TILE_PERIOD: float = 1.536
const FLOOR_SKIN_POSITION: Vector3 = Vector3(0, 0.002, -17)

# Physical spaces remain continuous; these are layout bands, not walls or
# alternate floors. Royal approach and both King phases share the third court.
const COURT_IDS: Array[String] = ["entrance", "formation", "royal"]
const COURT_Z_RANGES: Array[Vector2] = [Vector2(-6, 5), Vector2(-14, -6), Vector2(-39, -14)]
const ROOM_IDS: Array[String] = ["curtain", "formation", "approach", "king1", "king2"]
const ROOM_COURT_INDICES: Array[int] = [0, 1, 2, 2, 2]
const ROOM_CENTRES: Array[Vector3] = [Vector3(0, 0, -2), Vector3(0, 0, -10), Vector3(0, 0, -18), Vector3(-1.25, 0, -29), Vector3(-1.25, 0, -29)]
# Nominal supported admission bands only; the parent additionally requires
# native support/framing, completed-prefix predicates and actual contact.
# These rectangles never clamp Hero movement or grant a checkpoint.
const ROOM_ADMISSION_RANGES: Array[Rect2] = [
	Rect2(-6.5, -5.5, 13, 10), Rect2(-6.5, -13.5, 13, 8),
	Rect2(-6.5, -25, 13, 11.5), Rect2(-6.5, -38.5, 13, 13.5),
	Rect2(-6.5, -38.5, 13, 13.5),
]
const ROOM_APPROACH_ENDPOINTS: Array[Vector3] = [
	Vector3(0, 0, 0), Vector3(0, 0, -7), Vector3(0, 0, -15),
	Vector3(0, 0, -26), Vector3(0, 0, -26),
]

# Birth map: each of eight actual identities is allocated once. King2 does
# not create a second King. The same two formation IDs change arrangement.
const ROOM_SOURCE_IDS: Array = [
	["court-curtain-guard"],
	["court-formation-west", "court-formation-east"],
	["court-approach-west", "court-approach-east"],
	["court-king"],
	["court-helper-west", "court-helper-east"],
]
const ROOM_PRESENT_SOURCE_IDS: Array = [
	["court-curtain-guard"],
	["court-formation-west", "court-formation-east"],
	["court-approach-west", "court-approach-east"],
	["court-king"],
	["court-king", "court-helper-west", "court-helper-east"],
]
const SOURCES: Dictionary = {
	"court-curtain-guard": {"room": 0, "role": "C32", "position": Vector3(0, 0, -2)},
	"court-formation-west": {"room": 1, "role": "C32", "position": Vector3(-1.2, 0, -10)},
	"court-formation-east": {"room": 1, "role": "C32", "position": Vector3(1.2, 0, -10)},
	"court-approach-west": {"room": 2, "role": "C32", "position": Vector3(-1.2, 0, -18)},
	"court-approach-east": {"room": 2, "role": "C32", "position": Vector3(1.2, 0, -18)},
	"court-king": {"room": 3, "role": "B01", "position": Vector3(-1.25, 0.005, -29)},
	"court-helper-west": {"room": 4, "role": "C32", "position": Vector3(-2, 0, -31)},
	"court-helper-east": {"room": 4, "role": "C32", "position": Vector3(2, 0, -31)},
}

# Facing proposals for the same retained pair, not native lane proofs or
# timing assignments. The parent owns supported reposition/admission.
const FORMATION_ARRANGEMENTS: Array = [
	{"id": "parallel", "source_ids": ["court-formation-west", "court-formation-east"], "facings": [Vector3(0, 0, 1), Vector3(0, 0, 1)]},
	{"id": "inward", "source_ids": ["court-formation-west", "court-formation-east"], "facings": [Vector3(1, 0, 0), Vector3(-1, 0, 0)]},
]
const ROUND_EL_ID: String = "court-roundel"
const ROUND_EL_POSITION: Vector3 = Vector3(0, 0, -20)
const ROUND_EL_RADIUS: float = 1.2
const ROUND_EL_QUIET_CYCLES: int = 1
const ROUND_EL_GUARD_SOURCE_IDS: Array[String] = ["court-approach-west", "court-approach-east"]

const BOSS_CONTACT_POSITION: Vector3 = Vector3(0, 0, -26)
const EXIT_POSITION: Vector3 = Vector3(0, 0, -35)
const CONTACT_BOX_SIZE: Vector3 = Vector3(2.4, 1.6, 1.2)
const CONTACT_BOX_OFFSET: Vector3 = Vector3(0, 0.8, 0)
const THRONE_POSITION: Vector3 = Vector3(-1.25, 0, -30.2)
const KING_INTRO_DISTANCE: float = 0.7
const KING_INTRO_SPEED: float = 1.4
const KING_INTRO_DURATION: float = KING_INTRO_DISTANCE / KING_INTRO_SPEED
const HELPER_ENTRY_DISTANCE: float = 0.7
const HELPER_ENTRY_SPEED: float = 1.4
const HELPER_ENTRY_DURATION: float = HELPER_ENTRY_DISTANCE / HELPER_ENTRY_SPEED
const HELPER_ENTRY_DIRECTION: Vector3 = Vector3(0, 0, 1)
const HELPER_ENTRY_POSITIONS: Array[Vector3] = [Vector3(-2, 0, -31), Vector3(2, 0, -31)]
# Door panels are a quiet scenic backplane behind the genuine entry anchors.
# They never block motion, emit cues or decide whether another helper exists.
const HELPER_DOOR_POSITIONS: Array[Vector3] = [Vector3(-2, 0, -31.5), Vector3(2, 0, -31.5)]

const NODE_PATHS: Dictionary = {
	"spawn": NodePath("PlayerSpawn"), "floor": NodePath("Floor"),
	"floor_collision": NodePath("Floor/CollisionShape3D"),
	"floor_visual": NodePath("Floor/Visual"), "floor_skin": NodePath("QuietSilverFloorSkin"),
	"boss_contact_marker": NodePath("BossContactMarker"),
	"boss_contact_area": NodePath("BossContactArea"),
	"boss_contact_collision": NodePath("BossContactArea/CollisionShape3D"),
	"exit_marker": NodePath("ExitMarker"), "exit_area": NodePath("ExitArea"),
	"exit_collision": NodePath("ExitArea/CollisionShape3D"),
	"roundel_marker": NodePath("RoundelMarker"),
	"helper_entries": [NodePath("HelperEntryWest"), NodePath("HelperEntryEast")],
	"helper_doors": [NodePath("HelperDoorWest"), NodePath("HelperDoorEast")],
	"throne": NodePath("CompactSideThrone"),
}


static func source_specs() -> Dictionary:
	return SOURCES.duplicate(true)


static func room_source_ids(room: int, include_continuing: bool = true) -> Array[String]:
	var result: Array[String] = []
	if room < 0 or room >= ROOM_IDS.size(): return result
	var selected: Array = ROOM_PRESENT_SOURCE_IDS[room] if include_continuing else ROOM_SOURCE_IDS[room]
	for id: String in selected: result.append(id)
	return result


static func immutable_specs() -> Dictionary:
	# Callers receive detached containers. No supplied node aliases or saved
	# actor state is accepted; the strict whole codec belongs to the parent.
	return {
		"revision": LAYOUT_REVISION, "level_id": LEVEL_ID,
		"floor_size": FLOOR_SIZE, "floor_centre": FLOOR_CENTRE,
		"floor_rect": FLOOR_RECT, "safe_rect": SAFE_RECT, "spawn": SPAWN_POSITION,
		"floor_tile_period": FLOOR_TILE_PERIOD, "floor_skin_position": FLOOR_SKIN_POSITION,
		"court_ids": COURT_IDS, "court_z_ranges": COURT_Z_RANGES,
		"room_ids": ROOM_IDS, "room_court_indices": ROOM_COURT_INDICES,
		"room_centres": ROOM_CENTRES, "room_admission_ranges": ROOM_ADMISSION_RANGES,
		"room_approach_endpoints": ROOM_APPROACH_ENDPOINTS,
		"room_source_ids": ROOM_SOURCE_IDS, "room_present_source_ids": ROOM_PRESENT_SOURCE_IDS,
		"sources": SOURCES, "formation_arrangements": FORMATION_ARRANGEMENTS,
		"roundel_id": ROUND_EL_ID, "roundel_position": ROUND_EL_POSITION,
		"roundel_radius": ROUND_EL_RADIUS, "roundel_quiet_cycles": ROUND_EL_QUIET_CYCLES,
		"roundel_guard_source_ids": ROUND_EL_GUARD_SOURCE_IDS,
		"boss_contact": BOSS_CONTACT_POSITION, "exit": EXIT_POSITION,
		"contact_box_size": CONTACT_BOX_SIZE, "contact_box_offset": CONTACT_BOX_OFFSET,
		"throne": THRONE_POSITION, "helper_entry_positions": HELPER_ENTRY_POSITIONS,
		"helper_door_positions": HELPER_DOOR_POSITIONS,
		"helper_entry_direction": HELPER_ENTRY_DIRECTION,
		"helper_entry_distance": HELPER_ENTRY_DISTANCE,
		"helper_entry_speed": HELPER_ENTRY_SPEED, "helper_entry_duration": HELPER_ENTRY_DURATION,
		"node_paths": NODE_PATHS,
	}.duplicate(true)
