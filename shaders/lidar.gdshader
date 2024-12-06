shader_type spatial;
render_mode unshaded, vertex_lighting, depth_draw_opaque;

uniform float point_size = 0.01;

void vertex() {
    POINT_SIZE = point_size;
}

void fragment() {
    ALBEDO = COLOR.rgb;
    ALPHA = COLOR.a;
}