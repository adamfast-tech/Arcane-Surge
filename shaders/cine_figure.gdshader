shader_type canvas_item;
// Personnages des cinématiques (docs/design/41-cinematiques.md) : éclat (coup, magie), ombre de
// celui qui écoute, couleur passée (tristesse), liseré de lumière sur le contour, teinte de silhouette.

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_col : source_color = vec4(1.0);
uniform float dark : hint_range(0.0, 1.0) = 0.0;
uniform float desat : hint_range(0.0, 1.0) = 0.0;
uniform vec4 rim_col : source_color = vec4(0.0);
uniform float silhouette : hint_range(0.0, 1.0) = 0.0;
uniform vec4 sil_col : source_color = vec4(0.05, 0.03, 0.1, 1.0);
uniform float bottom_fade = 0.22;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float a_r = texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).a;
	float a_u = texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a;
	float edge = c.a * (1.0 - min(a_r, a_u));
	float g = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	c.rgb = mix(c.rgb, vec3(g) * vec3(0.85, 0.9, 1.05), desat);
	c.rgb = mix(c.rgb, sil_col.rgb, silhouette);
	c.rgb += rim_col.rgb * rim_col.a * edge;
	c.rgb *= 1.0 - dark;
	c.rgb = mix(c.rgb, flash_col.rgb, flash);
	// Le bas du buste se fond (il passe derrière le panneau ; sans panneau, pas de bord coupé).
	c.a *= smoothstep(1.0, 1.0 - bottom_fade, UV.y);
	COLOR = c * COLOR;
}
