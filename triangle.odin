package main

import "core:c"

get_triangle_VAO :: proc() -> c.uint{
	vertices := [?]f32 {
		// pos			// color
		0.5, -0.5, 0.0, 1.0, 0.0, 0.0,
		-0.5, -0.5, 0.0, 0.0, 1.0, 0.0,
		0.0, 0.5, 0.0,  0.0, 0.0, 1.0,
	}

	VAO, hasError := create_VAO(vertices[:], nil)
	if hasError {
		panic("Error creating two triangles VAO")
	}

	return VAO
}
