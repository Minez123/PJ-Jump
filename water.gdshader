// Infinite Ocean Shader (Gerstner + PBR water)
// Based on StandardMaterial3D with wave injection

shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(0.0, 0.3, 0.6, 0.8);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size;

uniform float roughness : hint_range(0.0, 1.0) = 0.05;
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01) = 0.9;
uniform float metallic : hint_range(0.0, 1.0, 0.01) = 0.0;

uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0) = 1.0;

uniform float refraction : hint_range(-1.0, 1.0, 0.001) = 0.1;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

// === Gerstner Wave Settings ===
uniform int wave_count : hint_range(1, 8) = 4;
uniform float wave_amplitude = 0.6;
uniform float wave_length = 12.0;
uniform float wave_speed = 1.2;
uniform float steepness = 0.3;


struct WaveResult {
	vec3 disp;
	vec3 normal;
};

WaveResult gerstner_wave(vec2 pos, float angle, float amplitude, float wavelength, float speed, float t) {
	float k = 2.0 * PI / wavelength;
	vec2 d = normalize(vec2(cos(angle), sin(angle)));
	float phase = k * dot(d, pos) - speed * t;

	float cos_p = cos(phase);
	float sin_p = sin(phase);

	vec3 disp;
	disp.x = d.x * amplitude * cos_p;
	disp.z = d.y * amplitude * cos_p;
	disp.y = amplitude * sin_p;

	// Derivatives for normal
	vec3 tangent_x = vec3(
		1.0 - steepness * d.x * d.x * sin_p,
		steepness * d.x * cos_p,
		-steepness * d.x * d.y * sin_p
	);

	vec3 tangent_z = vec3(
		-steepness * d.x * d.y * sin_p,
		steepness * d.y * cos_p,
		1.0 - steepness * d.y * d.y * sin_p
	);

	vec3 normal = normalize(cross(tangent_z, tangent_x));
	return WaveResult(disp, normal);
}

varying vec3 uv1_triplanar_pos;
varying vec3 uv1_power_normal;

void vertex() {
	vec3 displaced = VERTEX;
	vec3 n = NORMAL;

	// Apply Gerstner Waves
	for (int i = 0; i < wave_count; i++) {
		float angle = (PI * 2.0 / float(wave_count)) * float(i);
		WaveResult w = gerstner_wave(VERTEX.xz, angle, wave_amplitude, wave_length, wave_speed, TIME);
		displaced += w.disp;
		n += w.normal;
	}

	VERTEX = displaced;
	NORMAL = normalize(n);

	// Keep triplanar setup
	vec3 normal = MODEL_NORMAL_MATRIX * NORMAL;
	uv1_power_normal = pow(abs(normal), vec3(64.0));
	uv1_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * 0.1;
	uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));
	uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);
}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
	return samp;
}

void fragment() {
	// Base water color
	vec4 albedo_tex = triplanar_texture(texture_albedo, uv1_power_normal, uv1_triplanar_pos);
	ALBEDO = mix(albedo.rgb, albedo_tex.rgb, 0.5);

	// Metallic / Roughness
	float metallic_tex = dot(triplanar_texture(texture_metallic, uv1_power_normal, uv1_triplanar_pos), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(triplanar_texture(texture_roughness, uv1_power_normal, uv1_triplanar_pos), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	// Normal map (optional detail on top of Gerstner normals)
	NORMAL_MAP = triplanar_texture(texture_normal, uv1_power_normal, uv1_triplanar_pos).rgb;
	NORMAL_MAP_DEPTH = normal_scale;

	// Refraction + screen reflection
	vec3 ref_normal = normalize(NORMAL);
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * refraction;

	float ref_amount = 0.4;
	EMISSION += textureLod(screen_texture, ref_ofs, ROUGHNESS * 8.0).rgb * ref_amount * EXPOSURE;

	// Transparency for water
	ALPHA = 0.85;
}
