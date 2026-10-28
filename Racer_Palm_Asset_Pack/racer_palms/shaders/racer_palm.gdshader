// Racer Palms - stylized low-poly palm shader for Godot 4.
//
// One material for the whole palm (trunk, crown base, coconuts, fronds), so
// every palm is a single mesh surface = one draw call, and it works unchanged
// with MeshInstance3D and MultiMeshInstance3D.
//
// The meshes store their part/wind data in UV (see tools/racer_palms_generate.py):
//   UV.y <  0.325  trunk   (UV.x = height ratio)
//   UV.y <  0.5    crown base / coconuts
//   UV.y >= 0.5    frond   (UV.x = position along frond, UV.y = frond seed)
//
// Wind is purely GPU-side (vertex shader, TIME based). The displacement only
// depends on vertex position and UV, so faces never tear apart, and the shadow
// pass uses the very same animation.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_schlick_ggx;

group_uniforms leaves;
uniform vec3 leaf_color_dark : source_color = vec3(0.20, 0.48, 0.14);
uniform vec3 leaf_color_mid : source_color = vec3(0.36, 0.66, 0.18);
uniform vec3 leaf_color_light : source_color = vec3(0.56, 0.80, 0.24);
uniform vec3 leaf_tip_color : source_color = vec3(0.74, 0.78, 0.32);
uniform vec3 leaf_underside_color : source_color = vec3(0.22, 0.42, 0.15);
uniform float frond_color_variation : hint_range(0.0, 1.0) = 0.85;
uniform float crown_occlusion : hint_range(0.0, 1.0) = 0.45;
uniform float leaf_backlight : hint_range(0.0, 1.0) = 0.35;

group_uniforms trunk;
uniform vec3 trunk_color_dark : source_color = vec3(0.47, 0.33, 0.22);
uniform vec3 trunk_color : source_color = vec3(0.62, 0.46, 0.31);
uniform vec3 trunk_ring_color : source_color = vec3(0.78, 0.66, 0.48);
uniform vec3 sheath_color : source_color = vec3(0.50, 0.42, 0.22);
uniform vec3 coconut_color : source_color = vec3(0.45, 0.43, 0.15);

group_uniforms variation;
// Per-instance colour/brightness shift, derived from the world position.
uniform float instance_variation : hint_range(0.0, 1.0) = 0.5;

group_uniforms wind;
uniform bool wind_enabled = true;
uniform float wind_strength : hint_range(0.0, 3.0) = 1.0;
uniform float wind_speed : hint_range(0.0, 4.0) = 1.0;
uniform vec2 wind_direction = vec2(1.0, 0.3);
uniform float trunk_sway : hint_range(0.0, 1.0) = 0.10;
uniform float frond_sway : hint_range(0.0, 1.5) = 0.32;
uniform float frond_bounce : hint_range(0.0, 1.0) = 0.20;
uniform float leaf_flutter : hint_range(0.0, 0.3) = 0.05;

varying float v_inst;

float racer_palm_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	v_inst = racer_palm_hash(origin.xz * 0.731 + 17.0);

	if (wind_enabled && wind_strength > 0.0) {
		vec2 wd = length(wind_direction) > 0.0001 ? normalize(wind_direction) : vec2(1.0, 0.0);
		// world wind direction -> model space (works for rotated/scaled instances)
		vec3 wdir = normalize(transpose(mat3(MODEL_MATRIX)) * vec3(wd.x, 0.0, wd.y));
		float phase = dot(origin.xz, wd) * 0.06 + v_inst * 6.2831;
		float t = TIME * wind_speed;
		float gust = 0.65 + 0.35 * sin(t * 0.31 + phase * 0.5) * sin(t * 0.17 + phase);

		float is_trunk = step(UV.y, 0.325);
		float h = mix(1.0, UV.x * UV.x, is_trunk);
		vec3 disp = wdir * ((0.6 + 0.4 * sin(t * 0.9 + phase)) * gust * trunk_sway * h);

		if (UV.y >= 0.5) {
			float f = UV.x;
			float f2 = f * f;
			float seed = (UV.y - 0.55) / 0.45;
			float fp = phase + seed * 6.2831;
			disp += wdir * ((0.55 + 0.45 * sin(t * 1.7 + fp)) * gust * frond_sway * f2);
			disp.y += sin(t * 2.1 + fp + f * 1.8) * frond_bounce * f2 * (0.5 + 0.5 * gust);
			disp.y += sin(t * 6.5 + fp * 3.0 + f * 9.0 + dot(VERTEX, vec3(3.1, 1.7, 2.3)))
					* leaf_flutter * f;
		}
		VERTEX += disp * wind_strength;
	}
}

void fragment() {
	float inst = (v_inst - 0.5) * instance_variation;
	vec3 col;
	float rough = 0.85;

	if (UV.y >= 0.5) {
		// ---- fronds
		float f = UV.x;
		float seed = clamp((UV.y - 0.55) / 0.45, 0.0, 1.0);
		float s = fract(seed + inst * 0.8);
		vec3 base = s < 0.5
				? mix(leaf_color_dark, leaf_color_mid, s * 2.0)
				: mix(leaf_color_mid, leaf_color_light, (s - 0.5) * 2.0);
		base = mix(leaf_color_mid, base, frond_color_variation);
		base *= mix(1.0 - crown_occlusion, 1.0, smoothstep(0.0, 0.4, f));
		base = mix(base, leaf_tip_color, smoothstep(0.72, 1.0, f) * 0.45);
		if (!FRONT_FACING) {
			base = mix(base, leaf_underside_color, 0.5);
		}
		col = base;
		BACKLIGHT = col * leaf_backlight;
		rough = 0.72;
	} else if (UV.y >= 0.325) {
		// ---- crown base: fibrous sheath and coconuts
		float k = (UV.y - 0.35) / 0.1;
		col = k < 0.5
				? sheath_color * (0.8 + k * 0.6)
				: coconut_color * (0.8 + (k - 0.5) * 0.6);
	} else {
		// ---- trunk: darker bark bands with sandy ring lips
		float k = UV.y / 0.3;
		col = k < 0.5
				? mix(trunk_color_dark, trunk_color, k * 2.0)
				: mix(trunk_color, trunk_ring_color, 0.2 + 0.5 * clamp((k - 0.55) / 0.45, 0.0, 1.0));
		col *= mix(0.8, 1.05, smoothstep(0.0, 0.5, UV.x));
	}

	ALBEDO = col * (1.0 + inst * 0.25);
	ROUGHNESS = rough;
	SPECULAR = 0.3;
}
