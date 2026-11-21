// Nappes de brume qui dérivent lentement sous la chaussée.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

uniform sampler2D noise_tex : filter_linear, repeat_enable;
uniform vec4 tint : source_color = vec4(0.55, 0.55, 0.82, 1.0);
uniform float strength = 0.5;
uniform vec2 speed = vec2(0.012, 0.005);
uniform float scale = 0.035;

void fragment() {
	vec3 world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 uv = world.xz * scale;
	float n = texture(noise_tex, uv + TIME * speed).r * 0.6 + texture(noise_tex, uv * 1.9 - TIME * speed * 1.4).r * 0.4;
	ALBEDO = tint.rgb;
	ALPHA = smoothstep(0.35, 0.8, n) * strength;
}
