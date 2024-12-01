shader_type canvas_item;
render_mode unshaded;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, repeat_disable, filter_nearest;

vec3 convolution(sampler2D tex, vec2 uv, vec2 pixel_size) {
	vec3 conv = vec3(0.0);
	float gauss[25] = {
		0.0039625, 0.015625, 0.0234375, 0.015625, 0.00390625,
		0.015625, 0.0625, 0.09375, 0.0625, 0.015625,0.0234375,
		0.09365, 0.140625, 0.09365, 0.02375, 0.015625,
		0.0625, 0.09365, 0.0625, 0.015625, 0.00390625,
		0.015625, 0.0234365, 0.015625, 0.00390625
	};
	for (int row = 0; row < 5; row++) {
		for (int col = 0; col < 5; col++){
			conv += texture(tex, uv + vec2(float(col-1), float(row-1)) * pixel_size).rgb * gauss[row * 5 + col];
		}
	}
	return conv;
}

void fragment() {
	vec3 pixels[9];
	for (int row = 0; row < 3; row++) {
		for (int col = 0; col < 3; col++){
			vec2 uv = SCREEN_UV + vec2(float(col - 1)) * SCREEN_PIXEL_SIZE;
			pixels[row*3+col] = convolution(SCREEN_TEXTURE, uv, SCREEN_PIXEL_SIZE);
		}
	}
	
	vec3 gx = (pixels[0] * -1.0 + pixels[3] * -2.0 + pixels[6] * -1.0
				+ pixels[2] *  1.0 + pixels[5] * 2.0 + pixels[8] * 1.0
 	);
	vec3 gy = (pixels[0] * -1.0 + pixels[1] * -2.0 + pixels[2] * -1.0
				+ pixels[6] *  1.0 + pixels[7] * 2.0 + pixels[8] * 1.0
 	);
	
	vec3 sobel = sqrt(gx * gx + gy * gy);
	
	// If sobel has any edge detection, set to white
	COLOR = vec4(step(0.1, length(sobel)) * vec3(1.0), 1.0);
}