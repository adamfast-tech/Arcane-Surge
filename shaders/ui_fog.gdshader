// Carte (ambiance enrichie) : brume qui dérive sur les niveaux encore verrouillés.
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.62, 0.7, 0.78, 1.0);
uniform float strength = 0.55;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 p = UV * vec2(5.0, 2.0);
	float n = noise(p + vec2(TIME * 0.18, TIME * 0.05)) * 0.6 + noise(p * 2.1 - vec2(TIME * 0.11, 0.0)) * 0.4;
	float edge = smoothstep(0.0, 0.15, UV.x) * smoothstep(1.0, 0.85, UV.x);
	COLOR = vec4(tint.rgb, smoothstep(0.25, 0.85, n) * strength * (0.55 + 0.45 * edge));
}
