#version 330 core
layout (location = 0) in vec2 pos;
layout (location = 1) in vec2 uv;

uniform mat4 trans;
uniform mat4 scr_trans;

out vec2 UV;

void main() {
    gl_Position = scr_trans * trans * vec4(pos.x, pos.y, 0.0, 1.0);
    UV = uv;
}