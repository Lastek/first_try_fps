shader_type spatial;
uniform float stripe_width : hint_range(0.01, 0.5);
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	    // Compute a repeating pattern based on the UV.x coordinate.
    float stripe = step(0.5, fract(UV.x / stripe_width));
    
    // Set the color based on the stripe pattern.
    ALBEDO = vec3(stripe);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
