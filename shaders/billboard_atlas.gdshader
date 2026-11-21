// Sprites d'unités (MultiMesh) : quad face caméra, image tirée de l'atlas.
// INSTANCE_CUSTOM = rectangle UV dans l'atlas, COLOR = teinte (flash, statuts).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D atlas : source_color, filter_nearest;
uniform bool upright = false;
uniform float upright_stretch = 1.0;

varying vec4 v_rect;
varying vec4 v_tint;

void vertex() {
	v_rect = INSTANCE_CUSTOM;
	v_tint = COLOR;
	float w = length(MODEL_MATRIX[0].xyz);
	float h = length(MODEL_MATRIX[1].xyz);
	vec3 right;
	vec3 up;
	vec3 fwd;
	if (upright) {
		right = normalize(vec3(INV_VIEW_MATRIX[0].x, 0.0, INV_VIEW_MATRIX[0].z));
		up = vec3(0.0, upright_stretch, 0.0);
		fwd = normalize(cross(right, vec3(0.0, 1.0, 0.0)));
	} else {
		right = INV_VIEW_MATRIX[0].xyz;
		up = INV_VIEW_MATRIX[1].xyz;
		fwd = INV_VIEW_MATRIX[2].xyz;
	}
	mat4 bb = mat4(vec4(right * w, 0.0), vec4(up * h, 0.0), vec4(fwd, 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * bb;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 c = texture(atlas, v_rect.xy + UV * v_rect.zw);
	if (c.a < 0.5) {
		discard;
	}
	ALBEDO = c.rgb * v_tint.rgb;
}
