class_name AttackFootprint
extends RefCounted
## Shared reach/dot floor geometry. Cosmetic meshes never resolve damage.

const SEGMENTS: int = 32
const EDGE_WIDTH: float = 0.045
const SOURCE_RADIUS: float = 0.1
const LOS_HEIGHT: float = 0.7


static func cone_mesh(reach: float, cone_min_dot: float, filled: bool = false, world_state: PhysicsDirectSpaceState3D = null, origin: Vector3 = Vector3.ZERO, facing: Vector3 = Vector3.BACK) -> ArrayMesh:
	var vertices: Array[Vector3] = []
	var half_angle: float = acos(clampf(cone_min_dot, -1.0, 1.0))
	var flat_facing := Vector3(facing.x, 0.0, facing.z).normalized()
	if flat_facing.length_squared() < 0.001:
		flat_facing = Vector3.BACK
	var basis := Basis(Vector3.UP, atan2(flat_facing.x, flat_facing.z))
	var outer: Array[Vector3] = []
	var blocked: Array[bool] = []
	for index: int in range(SEGMENTS + 1):
		var angle: float = lerpf(-half_angle, half_angle, float(index) / SEGMENTS)
		var point: Vector3 = radial_point(angle, reach)
		var clipped: Dictionary = _clip_radial(point, world_state, origin, basis)
		outer.append(clipped["point"])
		blocked.append(clipped["blocked"])
	if filled:
		for index: int in range(SEGMENTS):
			if not blocked[index] and not blocked[index + 1]:
				vertices.append_array([Vector3.ZERO, outer[index], outer[index + 1]])
			var start: float = TAU * float(index) / SEGMENTS
			var finish: float = TAU * float(index + 1) / SEGMENTS
			vertices.append_array([Vector3.ZERO, radial_point(start, SOURCE_RADIUS), radial_point(finish, SOURCE_RADIUS)])
	else:
		# Keep blocked sections open. Joining a visible arc to a blocked ray can
		# draw a diagonal behind cover and promise an unavailable hit.
		for index: int in range(SEGMENTS):
			if not blocked[index] and not blocked[index + 1]:
				append_edge(vertices, outer[index], outer[index + 1])
		append_edge(vertices, outer[SEGMENTS], radial_point(half_angle, SOURCE_RADIUS))
		for index: int in range(SEGMENTS):
			var start: float = lerpf(half_angle, TAU - half_angle, float(index) / SEGMENTS)
			var finish: float = lerpf(half_angle, TAU - half_angle, float(index + 1) / SEGMENTS)
			append_edge(vertices, radial_point(start, SOURCE_RADIUS), radial_point(finish, SOURCE_RADIUS))
		append_edge(vertices, radial_point(-half_angle, SOURCE_RADIUS), outer[0])
	return mesh_from_vertices(vertices)


static func ring_mesh(radius: float) -> ArrayMesh:
	var vertices: Array[Vector3] = []
	for index: int in range(SEGMENTS):
		append_edge(vertices, radial_point(TAU * float(index) / SEGMENTS, radius), radial_point(TAU * float(index + 1) / SEGMENTS, radius))
	return mesh_from_vertices(vertices)


static func radial_point(angle: float, radius: float) -> Vector3:
	return Vector3(sin(angle), 0.0, cos(angle)) * radius


static func append_edge(vertices: Array[Vector3], start: Vector3, finish: Vector3) -> void:
	if start.distance_squared_to(finish) < 0.000001:
		return
	var along: Vector3 = (finish - start).normalized()
	var side: Vector3 = Vector3(-along.z, 0.0, along.x) * EDGE_WIDTH * 0.5
	vertices.append_array([start + side, finish + side, finish - side, start + side, finish - side, start - side])


static func mesh_from_vertices(vertices: Array[Vector3]) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if vertices.is_empty():
		return mesh
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _clip_radial(point: Vector3, world_state: PhysicsDirectSpaceState3D, origin: Vector3, basis: Basis) -> Dictionary:
	if world_state == null:
		return {"point": point, "blocked": false}
	var ray_origin: Vector3 = origin + Vector3.UP * LOS_HEIGHT
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + basis * point, 1)
	var hit: Dictionary = world_state.intersect_ray(query)
	if hit.is_empty():
		return {"point": point, "blocked": false}
	var hit_distance: float = ray_origin.distance_to(hit["position"])
	var visible_distance: float = maxf(0.0, hit_distance - EDGE_WIDTH)
	return {"point": point.normalized() * visible_distance, "blocked": true}
