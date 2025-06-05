shader_type canvas_item;

uniform float radius : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec2 center = vec2(0.5);
    float dist = distance(UV, center);
    float fade = smoothstep(0.0, radius, dist); // 0 in center, 1 at edge
    COLOR.a *= fade;
}
