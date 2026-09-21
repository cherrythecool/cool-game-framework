#version 330 core

layout (location = 0) in vec2 vertexPosition;
layout (location = 1) in vec2 vertexUV;

uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;

out vec2 textureUV;

void main() {
    gl_Position = projectionMatrix * modelMatrix * vec4(vertexPosition.x, vertexPosition.y, 0.0, 1.0);
    textureUV = vertexUV;
}