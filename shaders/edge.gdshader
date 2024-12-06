shader_type spatial;
render_mode unshaded;

uniform float wave_speed = 2.0;
uniform float wave_scale = 5.0;
uniform vec4 wave_color = vec4(0.1, 0.1, 0.1, 0.1);

void fragment() {
    // Create wave pattern based on time and UV
    float time = TIME * wave_speed;
    vec2 centered_uv = UV - 0.5;
    
    // Circular wave calculation
    float dist = length(centered_uv);
    float wave = abs(sin(dist * wave_scale - time));
    
    // Create ripple effect with falloff
    float ripple = 1.0 - smoothstep(0.0, 0.5, wave);
    
    ALBEDO = wave_color.rgb;
    ALPHA = ripple * wave_color.a;
}