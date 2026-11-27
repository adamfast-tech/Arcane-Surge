// Ambiance des menus (Havre-Aube, salles) : rayons de lumière lents et brume qui dérive, en mode additif.
// Discret : la lisibilité des panneaux passe avant l'effet.
shader_type canvas_item;
render_mode blend_add;

uniform vec4 glow : source_color = vec4(0.31, 0.89, 0.82, 1.0);
uniform vec4 glow2 : source_color = vec4(0.95, 0.77, 0.42, 1.0);
uniform float rays = 0.5;
uniform float fog = 0.3;
uniform vec2 aspect = vec2(1.0, 2.0);
uniform vec2 source = vec2(0.22, -0.12);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	vec2 d = (uv - source) * aspect;
	float r = length(d);
	vec3 c = vec3(0.0);
	// Rayons : faisceaux qui partent d'une source hors champ, en haut, et ondulent lentement.
	// Ils éclairent l'illustration (moitié haute) et s'éteignent avant les panneaux : ailleurs, leur terme vaut
	// exactement zéro, on ne le calcule donc pas (même image, moins de calcul).
	float top = smoothstep(0.72, 0.18, uv.y);
	if (top > 0.0 && rays > 0.0) {
		float ang = atan(d.x, d.y);
		float b1 = 0.5 + 0.5 * sin(ang * 17.0 + TIME * 0.13);
		float b2 = 0.5 + 0.5 * sin(ang * 6.0 - TIME * 0.07 + 1.3);
		float band = pow(b1 * b2, 2.2);
		float fall = smoothstep(2.0, 0.1, r);
		c = glow2.rgb * band * fall * top * rays * 0.75;
	}
	// Brume : nappes qui dérivent, au pied de l'illustration. Hors de sa bande, son terme vaut zéro.
	float mid = smoothstep(0.15, 0.45, uv.y) * smoothstep(0.85, 0.5, uv.y);
	if (mid > 0.0 && fog > 0.0) {
		float f = fbm(vec2(uv.x * 2.4 + TIME * 0.03, uv.y * 3.5 - TIME * 0.015));
		c += glow.rgb * smoothstep(0.42, 0.85, f) * mid * fog * 0.55;
	}
	// Halo autour de la source.
	c += glow2.rgb * smoothstep(1.0, 0.0, r) * rays * 0.12;
	COLOR = vec4(c, 1.0);
}
