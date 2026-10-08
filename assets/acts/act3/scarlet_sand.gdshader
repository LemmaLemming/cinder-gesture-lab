shader_type spatial;
render_mode unshaded;

uniform vec3 sand_color : source_color = vec3(0.49, 0.09, 0.15);
varying vec3 world_vertex;

void vertex() {
	world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Stationary grain and broad sediment bands: no animated route or cue.
	vec2 cell = floor(world_vertex.xz * 15.0);
	float grain = fract(sin(dot(cell, vec2(31.17, 71.03))) * 4375.71);
	float band = sin(world_vertex.z * 0.31 + sin(world_vertex.x * 0.46) * 1.6);
	float fleck = step(0.93, grain) * 0.055 - step(grain, 0.08) * 0.04;
	ALBEDO = sand_color + vec3(band * 0.022 + fleck);
}
