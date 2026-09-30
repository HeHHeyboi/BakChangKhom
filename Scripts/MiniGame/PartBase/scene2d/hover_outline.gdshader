// เส้นเรืองแสงรอบรูปตอนเมาส์ชี้ (ใช้กับ Item2D) — วาดสีเหลืองนวลรอบขอบรูปที่โปร่งใส
shader_type canvas_item;
uniform vec4 glow_color : source_color = vec4(1.0, 0.86, 0.35, 1.0);
uniform float width_px = 3.0;
uniform float fade = 1.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * width_px;
	float a = 0.0;
	for (int i = 0; i < 12; i++) {
		float t = float(i) * 0.5235988;
		a = max(a, texture(TEXTURE, UV + vec2(cos(t), sin(t)) * px).a);
	}
	vec4 g = vec4(glow_color.rgb, glow_color.a * a);
	vec4 o = mix(g, vec4(c.rgb * 1.08, 1.0), c.a);
	o.a = max(c.a, g.a) * COLOR.a * fade;
	COLOR = o;
}
