shader_type spatial;
render_mode unshaded, depth_draw_opaque;

uniform float point_size = 5.0;
uniform vec3 player_position;
uniform vec3 camera_position;
uniform float max_distance = 10.0;

varying vec3 world_pos;

void vertex() {
    // Calculate the world position of the vertex
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Calculate distance from the point to the camera
    float distance_to_camera = distance(world_pos, camera_position);

    // Adjust POINT_SIZE inversely proportional to distance
    float adjusted_size = point_size / distance_to_camera;

    // Set a minimum and maximum point size to avoid extremes
    adjusted_size = clamp(adjusted_size, 1.0, 100.0);

    POINT_SIZE = adjusted_size;
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
