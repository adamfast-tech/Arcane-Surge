// Végétation et détails du décor des combats (MultiMesh) : panneau dressé face à la caméra, posé au sol,
// qui ondule au vent (le haut bouge, le pied reste). INSTANCE_CUSTOM = rectangle UV dans l'atlas ;
// COLOR.rgb = teinte, COLOR.a = lueur (champignons, cristaux, fleurs de lune).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D atlas : source_color, filter_nearest;
uniform float sway = 0.06;
uniform float stretch = 1.0;

varying vec4 v_rect;
varying vec4 v_tint;

void vertex() {
	v_rect = INSTANCE_CUSTOM;
	v_tint = COLOR;
	float w = length(MODEL_MATRIX[0].xyz);
	float h = length(MODEL_MATRIX[1].xyz);
	vec3 right = normalize(vec3(INV_VIEW_MATRIX[0].x, 0.0, INV_VIEW_MATRIX[0].z));
	vec3 up = vec3(0.0, stretch, 0.0);
	vec3 fwd = normalize(cross(right, vec3(0.0, 1.0, 0.0)));
	vec3 org = MODEL_MATRIX[3].xyz;
	// Le vent : une onde qui traverse le décor, plus forte en haut de la plante.
	float wave = sin(TIME * 1.7 + org.x * 0.6 + org.z * 0.45) + 0.5 * sin(TIME * 3.1 + org.z * 1.3);
	VERTEX.x += wave * sway * VERTEX.y / max(0.2, w);
	mat4 bb = mat4(vec4(right * w, 0.0), vec4(up * h, 0.0), vec4(fwd, 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * bb;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 c = texture(atlas, v_rect.xy + UV * v_rect.zw);
	if (c.a < 0.5) {
		discard;
	}
	float glow = v_tint.a;
	ALBEDO = c.rgb * v_tint.rgb * (1.0 + glow * (0.35 + 0.2 * sin(TIME * 2.3 + v_rect.x * 40.0)));
}
