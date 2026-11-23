// Vignette des menus : bords assombris, pour recentrer le regard sur le contenu.
shader_type canvas_item;

uniform float strength = 0.55;
uniform vec4 tint : source_color = vec4(0.0, 0.0, 0.02, 1.0);

void fragment() {
	vec2 d = (UV - 0.5) * vec2(1.0, 0.85);
	float v = smoothstep(0.32, 0.82, length(d));
	COLOR = vec4(tint.rgb, v * strength);
}
