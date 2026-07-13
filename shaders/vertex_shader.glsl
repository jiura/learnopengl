#version 330 core
layout (location = 0) in vec3 aPos; // int attribute position 0

out vec4 vertexColor; // passing color outrput to be used by fragment shader

void main() {
	gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
	vertexColor = vec4(0.5, 0.0, 0.0, 1.0);
}
