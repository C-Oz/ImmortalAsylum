shader_type canvas_item;

// Allows reading the pixels behind the barrier
// Using filter_linear can sometimes help with initialization issues
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

uniform float glitch_intensity : hint_range(0.0, 0.05) = 0.01;
uniform float static_amount : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_count : hint_range(0.0, 1000.0) = 200.0;
uniform float speed : hint_range(0.0, 10.0) = 2.0;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	// Use SCREEN_UV to get the position on the screen
	vec2 uv = SCREEN_UV;
	
	// Apply horizontal jitter
	float time_step = floor(TIME * speed * 10.0);
	float glitch_row = floor(uv.y * 50.0);
	if (random(vec2(time_step, glitch_row)) > 0.8) {
		uv.x += (random(vec2(time_step, glitch_row + 1.0)) - 0.5) * glitch_intensity;
	}
	
	// Sample the screen
	vec4 color = texture(screen_texture, uv);
	
	// Static Noise
	float noise = random(uv + TIME);
	color.rgb = mix(color.rgb, vec3(noise), static_amount);
	
	// Scanlines
	float scanline = sin(uv.y * scanline_count) * 0.04;
	color.rgb -= scanline;
	
	// Force some alpha transparency so it doesn't look like a solid wall
	// We mix the screen color with a tiny bit of "ghostly" blue
	color.rgb *= vec3(0.9, 0.95, 1.1);
	
	COLOR = vec4(color.rgb, 1.0);
}
