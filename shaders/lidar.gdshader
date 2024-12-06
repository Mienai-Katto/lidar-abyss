shader_type spatial;
render_mode unshaded, depth_draw_opaque;

uniform float point_size = 0.01;
uniform vec3 player_position = vec3(0.0, 0.0, 0.0);
uniform float max_fade_distance = 10.0;
uniform float fade_power = 0.1;

void vertex() {
    float distance = length(VERTEX - player_position);
    
    float normalized_distance = distance / max_fade_distance;
    
    float fade = 1.0 - pow(normalized_distance, fade_power);
    
    fade = clamp(fade, 0.0, 1.0);
    
    COLOR.a *= fade;
    
    POINT_SIZE = point_size;
}

void fragment() {
    ALBEDO = COLOR.rgb;
    ALPHA = COLOR.a;

    // Calculate distance from the point to the player
    float distance_to_player = distance(world_pos, player_position);

    // Calculate glow intensity based on distance
    float glow_intensity = clamp(1.0 - (distance_to_player / max_distance), 0.0, 1.0);

    // Apply emission for glow effect
    EMISSION = COLOR.rgb * glow_intensity;
}
