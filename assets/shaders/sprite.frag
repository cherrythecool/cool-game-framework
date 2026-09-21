#version 330 core

in vec2 textureUV;
out vec4 fragmentColor;

uniform sampler2D sampledTexture;

void main() {
    fragmentColor = texture(sampledTexture, textureUV);
}