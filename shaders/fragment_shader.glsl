#version 330 core
out vec4 FragColor;
in vec3 ourColor;
in vec3 vertexPos;

void main() {
	// FragColor = vec4(ourColor, 1.0);
	FragColor = vec4(vertexPos, 1.0);
}
