shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float grain_strength : hint_range(0.0, 0.04) = 0.018;
uniform float vignette_strength : hint_range(0.0, 0.15) = 0.075;
uniform float cool_tint_strength : hint_range(0.0, 0.08) = 0.025;
uniform vec3 night_tint : source_color = vec3(0.94, 0.97, 1.0);

float hash_pixel(vec2 pixel) {
	return fract(sin(dot(pixel, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 scene_rgb = texture(screen_texture, uv).rgb;
	vec2 pixel = floor(uv / SCREEN_PIXEL_SIZE);
	float grain = hash_pixel(pixel) - 0.5;
	float radius = distance(uv, vec2(0.5));
	float vignette = 1.0 - smoothstep(0.30, 0.78, radius) * vignette_strength;
	vec3 color_graded = mix(scene_rgb, scene_rgb * night_tint, cool_tint_strength);
	color_graded *= vignette;
	color_graded += vec3(grain * grain_strength);
	COLOR = vec4(clamp(color_graded, vec3(0.0), vec3(1.0)), 1.0);
}
