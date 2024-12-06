shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float chromatic_aberration_intensity = 0.0005;

void fragment() {
    vec2 screen_uv = UV;
    vec3 aberration_color;

    float adjusted_intensity = pow(chromatic_aberration_intensity, 5); // Reduce impact of high values
	vec2 red_uv = screen_uv + vec2(adjusted_intensity * 0.0025, 0.0);
	vec2 blue_uv = screen_uv - vec2(adjusted_intensity * 0.0025, 0.0);

	red_uv = clamp(red_uv, vec2(0.0), vec2(1.0));
	blue_uv = clamp(blue_uv, vec2(0.0), vec2(1.0));

    // Sample the screen texture
    float red_channel = texture(SCREEN_TEXTURE, red_uv).r;
    float green_channel = texture(SCREEN_TEXTURE, screen_uv).g;
    float blue_channel = texture(SCREEN_TEXTURE, blue_uv).b;

    // Combine the channels
    aberration_color = vec3(red_channel, green_channel, blue_channel);

    // Output the final color
    COLOR = vec4(aberration_color, 1.0);
}