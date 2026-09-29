// ขอบดำหนาเท่ากันบนจอ (หน่วยพิกเซล) ไม่ว่าจะซูมใกล้/ไกล — ให้ชิ้นส่วน 3D ดูเป็นลายเส้นเหมือนฉาก 2D ของเกม
// ใช้เป็น next_pass ของวัสดุชิ้นส่วน (PartBody3D ใส่ให้เอง)
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

uniform vec4 outline_color : source_color = vec4(0.2, 0.11, 0.07, 1.0);
uniform float width_px = 2.5;
uniform float depth_bias = 0.00001; // ≈ 0.04 หน่วย (กล้อง far 4000)

void vertex() {
	// ดันจุดออกจากจุดกึ่งกลางของชิ้น (บนจอ) — ได้ขอบรอบรูปทรงครบทุกด้าน แม้กล่องมุมคม
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec4 center = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0));
	vec2 dir = clip.xy / clip.w - center.xy / center.w;
	if (length(dir) > 0.00001) {
		dir = normalize(dir);
	}
	clip.xy += dir * width_px * 2.0 / VIEWPORT_SIZE * clip.w;
	// ดันขอบไปข้างหลังนิดนึง กันขอบทะลุผิวชิ้นบาง ๆ (แผ่นรอง ESD) [30 ก.ย.] — Godot 4.3+ ใช้ reverse-Z (ค่าน้อย = ไกล)
	clip.z -= depth_bias * clip.w;
	POSITION = clip;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
