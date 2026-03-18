shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 5.0) = 1.0;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.8;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);
	vec2 uv = UV;
	uv -= 0.5;
	float d = length(uv);
	float vignette = smoothstep(0.4, 0.75, d * vignette_intensity);
	
	COLOR = mix(color, vignette_color, vignette * vignette_opacity);
}
