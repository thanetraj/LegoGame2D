shader_type canvas_item;

uniform float fear_level : hint_range(0.0, 1.0) = 0.0;
uniform float time_speed = 2.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D noise_texture : repeat_enable, filter_nearest;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Create screen distortion based on noise and fear level
	if (fear_level > 0.1) {
		float noise = texture(noise_texture, uv + vec2(TIME * time_speed * 0.1, TIME * time_speed * 0.2)).r;
		float displacement = (noise - 0.5) * fear_level * 0.05;
		uv.x += displacement;
		
		// Add horizontal scanline glitch
		if (mod(uv.y * 100.0 - TIME * 50.0, 10.0) < 1.0 * fear_level) {
			uv.x += 0.01 * fear_level;
		}
	}
	
	vec4 color = texture(screen_texture, uv);
	
	// Color desaturation and red tint based on fear
	if (fear_level > 0.0) {
		float grayscale = dot(color.rgb, vec3(0.299, 0.587, 0.114));
		vec3 red_tint = vec3(grayscale + 0.2 * fear_level, grayscale * (1.0 - fear_level * 0.5), grayscale * (1.0 - fear_level * 0.5));
		color.rgb = mix(color.rgb, red_tint, fear_level * 0.8);
	}
	
	COLOR = color;
}
