// 3500K warm light, matching the old `gammastep -O 3500` look.
#version 300 es

precision mediump float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    pixColor.r *= 1.00;
    pixColor.g *= 0.76;
    pixColor.b *= 0.55;
    fragColor = pixColor;
}
