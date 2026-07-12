package main

import "core:c"

get_two_triangles_VAO :: proc() -> c.uint{
	vertices := [?]f32 {
		-1.0, 0.0, 0.0,
		-0.5, 1.0, 0.0,
		0.0, 0.0, 0.0,
		0.5, 1.0, 0.0,
		1.0, 0.0, 0.0,
	}

	VAO, hasError := create_VAO(vertices[:], nil)
	if hasError {
		panic("Error creating two triangles VAO")
	}

	return VAO
}
