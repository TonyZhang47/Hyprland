// Identity. Used when warm light is off (empty shader path can fail to re-enable).
#version 300 es

precision mediump float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

void main() {
    fragColor = texture(tex, v_texcoord);
}
