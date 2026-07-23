package main

import "core:c"

get_rectangle_VAO :: proc() -> c.uint {
	vertices := [?]f32 {
		// pos           // color       // texture coords
		0.5, 0.5, 0.0,   1.0, 0.0, 0.0, 2.0, 2.0, // top right
		0.5, -0.5, 0.0,  0.0, 1.0, 0.0, 2.0, 0.0, // bottom right
		-0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, // bottom left
		-0.5, 0.5, 0.0,  1.0, 1.0, 1.0, 0.0, 2.0, // top left
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
