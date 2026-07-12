package main

import "core:c"

get_rectangle_VAO :: proc() -> c.uint {
	vertices := [?]f32 {
		// top right
		0.5, 0.5, 0.0,
		// bottom right
		0.5, -0.5, 0.0,
		// bottom left
		-0.5, -0.5, 0.0,
		// top left
		-0.5, 0.5, 0.0,
	}

	indices := [?]c.uint {
		// first triangle
		0, 1, 3,
		// second triangle
		1, 2, 3,
	}

	VAO, hasError := create_VAO(vertices[:], indices[:])
	if hasError {
		panic("Error creating rectangle VAO")
	}

	return VAO
}
