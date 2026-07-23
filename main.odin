// FIXME: Also add texture coords for shapes other than rectangle

package main

import "core:c"
import "core:fmt"
import "core:strings"

import "base:runtime"

import gl "vendor:OpenGL"
import "vendor:glfw"
import stbi "vendor:stb/image"

HasError :: bool

WINDOW_W :: 800
WINDOW_H :: 600

OPENGL_MAJOR :: 3
OPENGL_MINOR :: 3

ViewMode :: enum u8 {
	Triangle,
	TwoTriangles,
	TwoTrianglesSplit,
	Rectangle,
}

_running: b32 = true
_wireframeMode := false
_viewMode := ViewMode(0)

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

	// First arg is for attribute location
	// Position
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	// Color
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)
	// Texture coords
	gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 6 * size_of(f32))
	gl.EnableVertexAttribArray(2)

	if len(indices) > 0 {
		gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO)
		gl.BufferData(
			gl.ELEMENT_ARRAY_BUFFER,
			len(indices) * size_of(indices[0]),
			&raw_data(indices)[0],
			gl.STATIC_DRAW,
		)
	}

	gl.BindVertexArray(0) // VAO should be unbound before unbiding EBO, otherwise the VAO loses the EBO bound to it
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)

	return VAO, false
}

// Works for current shader program, might error out if none is set
get_uniform_location :: proc(shader: c.uint, name: cstring) -> c.int {
	vertexColorLocation := gl.GetUniformLocation(shader, name)
	if vertexColorLocation == -1 do panic(strings.concatenate([]string{"Couldn't find \"", string(name), "\" uniform location"}))
	return vertexColorLocation
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

	// nrAttribs: c.int
	// gl.GetIntegerv(gl.MAX_VERTEX_ATTRIBS, &nrAttribs)
	// fmt.println(nrAttribs)

	// GLFW setup --- END

	setup_callbacks(window)

	// Init --- START

	success: c.int
	infoLog: [512]byte

	// Vertex shader
	vertexShader := gl.CreateShader(gl.VERTEX_SHADER)

	vertexShaderSource: cstring = #load("shaders/vertex_shader.glsl", cstring) or_else ""
	if vertexShaderSource == "" do panic("Couldn't find vertex shader file")
	gl.ShaderSource(vertexShader, 1, &vertexShaderSource, nil)

	gl.CompileShader(vertexShader)
	gl.GetShaderiv(vertexShader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		gl.GetShaderInfoLog(vertexShader, size_of(infoLog), nil, &infoLog[0])
		fmt.println(cstring(&infoLog[0]))
	}

	// Fragment shader
	fragShader := gl.CreateShader(gl.FRAGMENT_SHADER)

	fragShaderSource: cstring = #load("shaders/fragment_shader.glsl", cstring) or_else ""
	if fragShaderSource == "" do panic("Couldn't find fragment shader file")
	gl.ShaderSource(fragShader, 1, &fragShaderSource, nil)

	gl.CompileShader(fragShader)
	gl.GetShaderiv(fragShader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		gl.GetShaderInfoLog(fragShader, size_of(infoLog), nil, &infoLog[0])
		fmt.println(string(infoLog[:]))
		fmt.println(cstring(&infoLog[0]))
	}

	// Link shaders

	shaderProgram := gl.CreateProgram()
	gl.AttachShader(shaderProgram, vertexShader)
	gl.AttachShader(shaderProgram, fragShader)
	gl.LinkProgram(shaderProgram)

	gl.GetProgramiv(shaderProgram, gl.LINK_STATUS, &success)
	if success == 0 {
		gl.GetProgramInfoLog(shaderProgram, size_of(infoLog), nil, &infoLog[0])
		fmt.println(cstring(&infoLog[0]))
	}

	// Vertex data

	triangleVAO := get_triangle_VAO()
	twoTrianglesVAO := get_two_triangles_VAO()
	triangleOneVAO := get_triangle_one_VAO()
	triangleTwoVAO := get_triangle_two_VAO()
	rectVAO := get_rectangle_VAO()

	// Textures

	texture1: c.uint
	gl.GenTextures(1, &texture1)
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, texture1)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.MIRRORED_REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST_MIPMAP_NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

	imgW, imgH, nrChans: c.int
	imgData := stbi.load("assets/container.jpg", &imgW, &imgH, &nrChans, 0)

	if (imgData == nil) do panic("Couldn't load assets/container.jpg data")

	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, imgW, imgH, 0, gl.RGB, gl.UNSIGNED_BYTE, imgData)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	stbi.image_free(imgData)

	texture2: c.uint
	gl.GenTextures(1, &texture2)
	gl.ActiveTexture(gl.TEXTURE1)
	gl.BindTexture(gl.TEXTURE_2D, texture2)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.MIRRORED_REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST_MIPMAP_NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

	stbi.set_flip_vertically_on_load(c.int(true))
	imgData = stbi.load("assets/awesomeface.png", &imgW, &imgH, &nrChans, 0)

	if (imgData == nil) do panic("Couldn't load assets/awsomeface.jpg data")

	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, imgW, imgH, 0, gl.RGBA, gl.UNSIGNED_BYTE, imgData)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	stbi.image_free(imgData)

	// gl.BindTexture(gl.TEXTURE_2D, 0)

	gl.UseProgram(shaderProgram)
	gl.Uniform1i(get_uniform_location(shaderProgram, "texture1"), 0)
	gl.Uniform1i(get_uniform_location(shaderProgram, "texture2"), 1)

	// Init --- END

	// Main loop --- START

	for !glfw.WindowShouldClose(window) && _running {
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		xOffsetUniform := get_uniform_location(shaderProgram, "x_offset")
		gl.Uniform1f(xOffsetUniform, 0.0)

		switch _viewMode {
		case ViewMode.Triangle:
			gl.Uniform1f(xOffsetUniform, 0.5)

			gl.BindVertexArray(triangleVAO)
			gl.DrawArrays(gl.TRIANGLES, 0, 3)

		case ViewMode.TwoTriangles:
			gl.BindVertexArray(twoTrianglesVAO)
			gl.DrawArrays(gl.TRIANGLES, 0, 6)

		case ViewMode.TwoTrianglesSplit:
			gl.BindVertexArray(triangleOneVAO)
			gl.DrawArrays(gl.TRIANGLES, 0, 3)

			gl.BindVertexArray(triangleTwoVAO)
			gl.DrawArrays(gl.TRIANGLES, 0, 3)

		case ViewMode.Rectangle:
			gl.BindVertexArray(rectVAO)
			gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
		}

		glfw.SwapBuffers(window)
		glfw.PollEvents()

		gl.BindVertexArray(0)
	}

	// Main loop --- END
}
