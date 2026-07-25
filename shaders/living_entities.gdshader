shader_type canvas_item;

uniform vec4 albedo : source_color = vec4(1,1,1,1);
uniform float color_ratio : hint_range(0.0, 1.0, 0.1);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	COLOR = mix(albedo * COLOR, vec4(albedo.rgb, COLOR.a), color_ratio);
	
}
