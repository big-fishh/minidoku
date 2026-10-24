shader_type canvas_item;

// Control the size of the inner cutout hole (0.0 to 1.0)
uniform float hole_size : hint_range(0.0, 1.0) = 0.5; 

void fragment() {
    // Get UV coordinates centered around (0,0) instead of top-left
    vec2 centered_uv = abs(UV - 0.5);
    
    // Check if the pixel falls inside the cutout square area
    if (centered_uv.x < hole_size * 0.5 && centered_uv.y < hole_size * 0.5) {
        discard; // This cuts out the pixel, making it completely transparent
    }
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
