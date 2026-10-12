shader_type spatial;
render_mode unshaded;

varying vec3 world_vertex;

float mineral_hash(vec2 cell) {
	return fract(sin(dot(cell, vec2(37.17, 73.03))) * 4375.71);
}

void vertex() {
	world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Static broad mineral plates. No TIME, alpha, vertex displacement,
	// emission, directional tell, ring fill or reserved interaction pulse.
	vec2 pixel = floor(world_vertex.xz * 24.0) / 24.0;
	vec2 point = pixel * 0.68;
	vec2 cell = floor(point);
	float nearest = 8.0;
	float second = 8.0;
	float tone = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 candidate = cell + vec2(float(x), float(y));
			vec2 site = candidate + vec2(0.2) + vec2(mineral_hash(candidate), mineral_hash(candidate + vec2(17.0, 9.0))) * 0.6;
			vec2 offset = site - point;
			float distance_squared = dot(offset, offset);
			if (distance_squared < nearest) {
				second = nearest;
				nearest = distance_squared;
				tone = mineral_hash(candidate + vec2(4.0, 31.0));
			} else if (distance_squared < second) {
				second = distance_squared;
			}
		}
	}
	float seam = 1.0 - smoothstep(0.02, 0.09, second - nearest);
	float quiet_grain = mineral_hash(floor(world_vertex.xz * 24.0));
	vec3 mineral = vec3(0.175, 0.150, 0.215) + vec3((tone - 0.5) * 0.022);
	ALBEDO = mineral - vec3(seam * 0.026) + vec3((quiet_grain - 0.5) * 0.005);
}
