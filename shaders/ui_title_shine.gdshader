// Titres des menus : un reflet doré traverse lentement le texte.
shader_type canvas_item;

uniform float speed = 0.16;
uniform float width = 0.09;
uniform vec4 shine : source_color = vec4(1.0, 0.97, 0.86, 1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float x = SCREEN_UV.x + SCREEN_UV.y * 0.35;
	float t = fract(TIME * speed) * 2.2 - 0.6;
	float band = smoothstep(width, 0.0, abs(x - t));
	// Le reflet ne touche que les lettres, pas leur halo.
	c.rgb = mix(c.rgb, shine.rgb, band * 0.7 * step(0.6, c.a));
	COLOR = c;
}
