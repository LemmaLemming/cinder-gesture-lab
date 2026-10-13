shader_type spatial;
render_mode unshaded;

// Original stationary leaf clusters. Wet is a palette impression, not physics.
// No TIME, displacement, alpha, emission or warning-shaped scenic marks.
uniform float blue_sun : hint_range(0.0, 1.0) = 0.0;
varying vec3 world_point;

float cell_seed(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 ground = floor(world_point.xz * 24.0) / 24.0;
	vec2 leaf_cell = floor(ground * 1.45);
	vec2 local = fract(ground * 1.45) - vec2(0.5);
	float seed = cell_seed(leaf_cell);
	vec2 axis = seed > 0.5 ? vec2(local.y, -local.x) : local;
	float leaf = step(abs(axis.x + axis.y * 0.35) * 1.6 + abs(axis.y), 0.38) * step(0.35, seed);
	float vein = step(abs(axis.x + axis.y * 0.35), 0.025) * leaf;
	float broad = cell_seed(floor(ground * 0.65));
	vec3 mud = mix(vec3(0.145, 0.125, 0.155), vec3(0.172, 0.150, 0.183), broad);
	vec3 fallen = mix(vec3(0.215, 0.165, 0.183), vec3(0.175, 0.205, 0.180), step(0.67, seed));
	vec3 surface = mix(mud, fallen, leaf * 0.62);
	surface += vec3(0.012, 0.013, 0.010) * vein;
	ALBEDO = mix(surface, surface * vec3(0.90, 0.94, 1.10), blue_sun);
	ROUGHNESS = 1.0;
}
