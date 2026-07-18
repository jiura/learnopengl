#version 330 core
layout (location = 0) in vec3 aPos; // attribute position 0
layout (location = 1) in vec3 aColor; // attribute position 1
layout (location = 2) in vec2 aTexCoord; // and so on

out vec3 ourColor; // passing color outrput to be used by fragment shader
out vec3 vertexPos;
out vec2 texCoord;

uniform float x_offset = 0.0;

void main() {
	gl_Position = vec4(aPos.x + x_offset, aPos.y, aPos.z, 1.0);

	ourColor = aColor;
	vertexPos = aPos;
	texCoord = aTexCoord;
}
