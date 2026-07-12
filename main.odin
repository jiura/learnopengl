package main

import "base:runtime"

import "core:c"
import "core:fmt"

import gl "vendor:OpenGL"
import "vendor:glfw"

HasError :: bool

WINDOW_W :: 800
WINDOW_H :: 600

OPENGL_MAJOR :: 3
OPENGL_MINOR :: 3

ViewMode :: enum u8 {
	TwoTriangles,
	TwoTrianglesSplit,
	Rectangle,
}

_running: b32 = true
_wireframeMode := false
_viewMode := ViewMode.TwoTriangles

next_view_mode :: proc(m: ViewMode) -> ViewMode {
	return ViewMode((u32(m) + 1) % len(ViewMode))
}

create_VAO :: proc(vertices: []f32, indices: []c.uint) -> (c.uint, HasError) {
	if len(vertices) == 0 {
		return 0, true
	}

	VAO, VBO, EBO: c.uint // Vertex Array Object, Vertex Buffer Object, Element Buffer Object

	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(1, &VBO)
	gl.GenBuffers(1, &EBO)

	gl.BindVertexArray(VAO)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertices) * size_of(vertices[0]),
		raw_data(vertices),
		gl.STATIC_DRAW,
	)

	if len(indices) > 0 {
		gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO)
		gl.BufferData(
			gl.ELEMENT_ARRAY_BUFFER,
			len(indices) * size_of(indices[0]),
			&raw_data(indices)[0],
			gl.STATIC_DRAW,
		)
	}

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	// Unbiding for the sake of it
	gl.BindVertexArray(0) // VAO should be unbound before unbiding EBO, otherwise the VAO loses the EBO bound to it
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)

	return VAO, false
}

setup_callbacks :: proc(window: glfw.WindowHandle) {
	framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: c.int) {
		context = runtime.default_context()

		gl.Viewport(0, 0, width, height)
	}
	glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)

	key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
		context = runtime.default_context()

		if action != glfw.PRESS {
			return
		}

		switch key {
		case glfw.KEY_ESCAPE:
			_running = false

		case glfw.KEY_W:
			if !_wireframeMode {
				gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
				_wireframeMode = true
			} else {
				gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
				_wireframeMode = false
			}

		case glfw.KEY_TAB:
			_viewMode = next_view_mode(_viewMode)
		}
	}
	glfw.SetKeyCallback(window, key_callback)
}

main :: proc() {
	// GLFW setup --- START

	if !glfw.Init() {
		fmt.println("Failed to initialize GLFW")
		return
	}
	defer glfw.Terminate()

	glfw.WindowHint(glfw.RESIZABLE, 1)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, OPENGL_MAJOR)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, OPENGL_MINOR)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window := glfw.CreateWindow(WINDOW_W, WINDOW_H, "Learn OpenGL", nil, nil)
	if window == nil {
		fmt.println("Failed to create GLFW window")
		return
	}
	defer glfw.DestroyWindow(window)
	glfw.MakeContextCurrent(window)

	gl.load_up_to(OPENGL_MAJOR, OPENGL_MINOR, glfw.gl_set_proc_address)

	// GLFW setup --- END

	setup_callbacks(window)

	// Init --- START

	success: c.int
	infoLog: [512]byte

	// Vertex shader
	vertexShader := gl.CreateShader(gl.VERTEX_SHADER)

	vertexShaderSource: cstring =
		"#version 330 core\n" +
		"layout (location = 0) in vec3 aPos;\n" +
		"void main() {\n" +
		"	gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0f);\n" +
		"}"
	gl.ShaderSource(vertexShader, 1, &vertexShaderSource, nil)

	gl.CompileShader(vertexShader)
	gl.GetShaderiv(vertexShader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		gl.GetShaderInfoLog(vertexShader, size_of(infoLog), nil, &infoLog[0])
		fmt.println(string(infoLog[:]))
	}

	// Fragment shader
	orangeFragShader := gl.CreateShader(gl.FRAGMENT_SHADER)

	orangeFragShaderSource: cstring =
		"#version 330 core\n" +
		"out vec4 FragColor;\n" +
		"void main() {\n" +
		"	FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);\n" +
		"}"
	gl.ShaderSource(orangeFragShader, 1, &orangeFragShaderSource, nil)

	gl.CompileShader(orangeFragShader)
	gl.GetShaderiv(orangeFragShader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		gl.GetShaderInfoLog(orangeFragShader, size_of(infoLog), nil, &infoLog[0])
		fmt.println(string(infoLog[:]))
	}

	yellowFragShader := gl.CreateShader(gl.FRAGMENT_SHADER)

	yellowFragShaderSource: cstring =
		"#version 330 core\n" +
		"out vec4 FragColor;\n" +
		"void main() {\n" +
		"	FragColor = vec4(1.0f, 1.0f, 0.0f, 1.0f);\n" +
		"}"
	gl.ShaderSource(yellowFragShader, 1, &yellowFragShaderSource, nil)

	gl.CompileShader(yellowFragShader)
	gl.GetShaderiv(orangeFragShader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		gl.GetShaderInfoLog(yellowFragShader, size_of(infoLog), nil, &infoLog[0])
		fmt.println(string(infoLog[:]))
	}

	// Link shaders

	orangeShaderProgram := gl.CreateProgram()
	gl.AttachShader(orangeShaderProgram, vertexShader)
	gl.AttachShader(orangeShaderProgram, orangeFragShader)
	gl.LinkProgram(orangeShaderProgram)

	gl.GetProgramiv(orangeShaderProgram, gl.LINK_STATUS, &success)
	if success == 0 {
		gl.GetProgramInfoLog(orangeShaderProgram, size_of(infoLog), nil, &infoLog[0])
		fmt.println(string(infoLog[:]))
	}

	gl.DeleteShader(vertexShader)
	gl.DeleteShader(orangeFragShader)

	yellowShaderProgram := gl.CreateProgram()
	gl.AttachShader(yellowShaderProgram, vertexShader)
	gl.AttachShader(yellowShaderProgram, yellowFragShader)
	gl.LinkProgram(yellowShaderProgram)

	gl.GetProgramiv(yellowShaderProgram, gl.LINK_STATUS, &success)
	if success == 0 {
		gl.GetProgramInfoLog(yellowShaderProgram, size_of(infoLog), nil, &infoLog[0])
		fmt.println(string(infoLog[:]))
	}

	// Vertex data

	twoTrianglesVAO := get_two_triangles_VAO()
	triangleOneVAO := get_triangle_one_VAO()
	triangleTwoVAO := get_triangle_two_VAO()
	rectVAO := get_rectangle_VAO()

	// Init --- END

	// Main loop --- START

	for !glfw.WindowShouldClose(window) && _running {
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.UseProgram(orangeShaderProgram)

		switch _viewMode {
		case ViewMode.TwoTriangles:
			gl.BindVertexArray(twoTrianglesVAO)
			gl.DrawArrays(gl.TRIANGLES, 0, 6)

		case ViewMode.TwoTrianglesSplit:
			gl.BindVertexArray(triangleOneVAO)
			gl.DrawArrays(gl.TRIANGLES, 0, 3)

			gl.UseProgram(yellowShaderProgram)

			gl.BindVertexArray(triangleTwoVAO)
			gl.DrawArrays(gl.TRIANGLES, 0, 3)

			gl.UseProgram(orangeShaderProgram)
			break

		case ViewMode.Rectangle:
			gl.BindVertexArray(rectVAO)
			gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
		}

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}

	// Main loop --- END
}
