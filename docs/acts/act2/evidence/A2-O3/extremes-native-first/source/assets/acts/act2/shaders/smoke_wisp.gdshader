shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back;

// Quiet local material. No screen/depth texture, TIME, global or random state.
uniform bool masks_ready = false;
uniform float wisp_alpha : hint_range(0.0, 1.0) = 0.0;
uniform vec2 viewport_size_pixels = vec2(1.0);
uniform vec4 hero_rect_pixels = vec4(0.0);
uniform vec4 source_rect_pixels = vec4(0.0);
uniform vec2 rim_points_pixels[64];
uniform float rim_padding_pixels = 1.5;
uniform vec3 mask_camera_origin = vec3(0.0);
uniform vec3 mask_camera_right = vec3(1.0, 0.0, 0.0);
uniform vec3 mask_camera_up = vec3(0.0, 1.0, 0.0);
uniform vec3 mask_camera_back = vec3(0.0, 0.0, 1.0);
uniform vec2 mask_projection_scale = vec2(1.0);
uniform vec2 mask_projection_offset = vec2(0.0);
uniform vec2 mask_clip_planes = vec2(0.05, 100.0);

bool in_rectangle(vec2 p, vec4 r) {
	return p.x >= r.x && p.y >= r.y && p.x <= r.z && p.y <= r.w;
}

float segment_distance(vec2 p, vec2 a, vec2 b) {
	vec2 delta = b - a;
	float along = clamp(dot(p - a, delta) / max(dot(delta, delta), 0.000001), 0.0, 1.0);
	return length(p - (a + delta * along));
}

void fragment() {
	// Fail closed if the rendering camera moved after the parent's last mask
	// call. Fresh derived masks must use its actual current projection/quad.
	if (!masks_ready || wisp_alpha <= 0.0 ||
		length(VIEWPORT_SIZE - viewport_size_pixels) > 0.01 ||
		length(CAMERA_POSITION_WORLD - mask_camera_origin) > 0.0001 ||
		length(INV_VIEW_MATRIX[0].xyz - mask_camera_right) > 0.0001 ||
		length(INV_VIEW_MATRIX[1].xyz - mask_camera_up) > 0.0001 ||
		length(INV_VIEW_MATRIX[2].xyz - mask_camera_back) > 0.0001 ||
		length(vec2(abs(PROJECTION_MATRIX[0][0]), abs(PROJECTION_MATRIX[1][1])) - mask_projection_scale) > 0.0001 ||
		abs(PROJECTION_MATRIX[3][3] - 1.0) > 0.0001 ||
		length(vec2(abs(PROJECTION_MATRIX[3][0]), abs(PROJECTION_MATRIX[3][1])) - mask_projection_offset) > 0.0001) {
		discard;
	}
	// Godot4.7 reverse-Z near is1; CLIP_SPACE_FAR supplies the active renderer's
	// far convention. Inverse projection preserves ordinary depth testing.
	vec4 near_view = INV_PROJECTION_MATRIX * vec4(0.0, 0.0, 1.0, 1.0);
	vec4 far_view = INV_PROJECTION_MATRIX * vec4(0.0, 0.0, CLIP_SPACE_FAR, 1.0);
	if (abs(near_view.w) < 0.000001 || abs(far_view.w) < 0.000001 ||
		abs(abs(near_view.z / near_view.w) - mask_clip_planes.x) > max(0.0001, mask_clip_planes.x * 0.0001) ||
		abs(abs(far_view.z / far_view.w) - mask_clip_planes.y) > max(0.001, mask_clip_planes.y * 0.0001)) {
		discard;
	}
	vec2 pixel = SCREEN_UV * viewport_size_pixels;
	if (in_rectangle(pixel, hero_rect_pixels) || in_rectangle(pixel, source_rect_pixels)) {
		discard;
	}
	for (int index = 0; index < 64; index++) {
		if (segment_distance(pixel, rim_points_pixels[index], rim_points_pixels[(index + 1) % 64]) <= rim_padding_pixels) {
			discard;
		}
	}
	// Fixed sparse stipple leaves orange fill gaps. It is a local UV pattern,
	// not a noise generator or an independently animated smoke clock.
	vec2 cell = floor(UV * vec2(16.0, 12.0));
	if (mod(cell.x + cell.y * 2.0, 7.0) < 1.0) {
		discard;
	}
	ALBEDO = vec3(0.025, 0.028, 0.030);
	ALPHA = wisp_alpha;
}
