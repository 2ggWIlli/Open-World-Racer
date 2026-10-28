// Demo-only road surface: asphalt with edge lines and a dashed centre line.
shader_type spatial;

uniform vec3 asphalt_color : source_color = vec3(0.21, 0.21, 0.23);
uniform vec3 paint_color : source_color = vec3(0.95, 0.95, 0.92);
uniform float half_width = 4.5;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float x = abs(world_pos.x - MODEL_MATRIX[3].x);
	float edge = step(half_width - 0.55, x) * step(x, half_width - 0.35);
	float dash = step(x, 0.1) * step(fract(world_pos.z / 9.0), 0.45);
	float paint = max(edge, dash);
	float grain = fract(sin(dot(floor(world_pos.xz * 6.0), vec2(12.9898, 78.233))) * 43758.5453);
	ALBEDO = mix(asphalt_color * (0.94 + grain * 0.1), paint_color, paint);
	ROUGHNESS = mix(0.92, 0.6, paint);
}
