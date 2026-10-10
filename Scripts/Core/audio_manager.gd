extends Node
## เพลง + เสียงประกอบ (autoload "Audio") · [Claude 10 ต.ค. 2569]
## เพลงเปลี่ยนเองตามสถานการณ์ (crossfade): เมนูหลัก = bgm_menu · ในบ้าน/หน้าบ้าน/ร้าน = bgm_village
##   มินิเกม/ขมOS = bgm_work · จบเดโม = jingle แล้วกลับ bgm_menu
## เสียงประกอบ: ทุกปุ่มในเกม = click (ต่ออัตโนมัติ) · เงินเข้า = coin · ส่งงานผ่าน/ไม่ผ่าน = success/fail · บูตขมOS = boot
## ไฟล์อยู่ Assets/Audio/ (สร้างจาก Assets/Audio/src/gen_audio.py) · บัส Music / SFX (default_bus_layout.tres)
## ปิดเพลงชั่วคราว: Audio.music_enabled = false · เปลี่ยนเพลงเอง: Audio.play_music(&"village")

const MUSIC := {
	&"menu": "res://Assets/Audio/Music/bgm_menu.ogg",
	&"village": "res://Assets/Audio/Music/bgm_village.ogg",
	&"work": "res://Assets/Audio/Music/bgm_work.ogg",
	&"demo_end": "res://Assets/Audio/Music/jingle_demo_end.ogg",
}
const SFX := {
	&"click": "res://Assets/Audio/Sfx/click.wav",
	&"success": "res://Assets/Audio/Sfx/success.wav",
	&"fail": "res://Assets/Audio/Sfx/fail.wav",
	&"coin": "res://Assets/Audio/Sfx/coin.wav",
	&"boot": "res://Assets/Audio/Sfx/boot.wav",
	&"pop": "res://Assets/Audio/Sfx/pop.wav",
}
const FADE := 1.2
const MUSIC_DB := -6.0

var music_enabled := true
var current: StringName = &""
var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _sfx: Array[AudioStreamPlayer] = []
var _streams: Dictionary = { }
var _jingle_until := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = &"Music"
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)
	for i in 6:
		var s := AudioStreamPlayer.new()
		s.bus = &"SFX"
		add_child(s)
		_sfx.append(s)
	get_tree().node_added.connect(_on_node_added)
	_connect_game.call_deferred()


func _connect_game() -> void:
	if has_node(^"/root/GameState"):
		GameState.money_changed.connect(func(_m, d):
			if d > 0:
				sfx(&"coin"))
		GameState.repair_recorded.connect(func(r: Dictionary):
			sfx(&"fail" if int(r.get("grade", 0)) == GameState.Grade.FAIL else &"success"))


## ปุ่มทุกปุ่มที่เกิดในเกม → เสียงคลิก
func _on_node_added(n: Node) -> void:
	if n is BaseButton and not n.has_meta("no_click"):
		(n as BaseButton).pressed.connect(sfx.bind(&"click"))


func _stream(path: String) -> AudioStream:
	if not _streams.has(path):
		var s = load(path) if ResourceLoader.exists(path) else null
		if s is AudioStreamOggVorbis:
			s.loop = not path.contains("jingle")
		_streams[path] = s
	return _streams[path]


func play_music(key: StringName) -> void:
	if key == current or not MUSIC.has(key):
		return
	var st := _stream(MUSIC[key])
	if st == null:
		return
	current = key
	var old := _players[_active]
	_active = 1 - _active
	var nw := _players[_active]
	nw.stream = st
	nw.volume_db = -40.0
	nw.play()
	var tw := create_tween().set_parallel()
	tw.tween_property(nw, "volume_db", MUSIC_DB, FADE)
	tw.tween_property(old, "volume_db", -80.0, FADE)
	tw.chain().tween_callback(old.stop)
	if key == &"demo_end":
		_jingle_until = Time.get_ticks_msec() / 1000.0 + (st.get_length() if st.get_length() > 0 else 6.0)


func stop_music() -> void:
	current = &""
	for p in _players:
		create_tween().tween_property(p, "volume_db", -80.0, FADE)


func sfx(key: StringName, pitch := 1.0) -> void:
	var st := _stream(SFX.get(key, ""))
	if st == null:
		return
	for p in _sfx:
		if not p.playing:
			p.stream = st
			p.pitch_scale = pitch
			p.play()
			return


## เลือกเพลงตามสถานการณ์ตอนนี้
func want_music() -> StringName:
	var menu := get_tree().get_first_node_in_group("main_menu")
	if menu is CanvasItem and menu.visible:
		return &"menu"
	if has_node(^"/root/Global") and Global.in_minigame:
		return &"work"
	if has_node(^"/root/DayLoop") and DayLoop.demo_over and DayLoop._demo_ack:
		if _jingle_until == 0.0:
			return &"demo_end" # เล่นครั้งแรก → play_music ตั้งเวลาจบ
		return &"demo_end" if Time.get_ticks_msec() / 1000.0 < _jingle_until else &"menu"
	_jingle_until = 0.0
	return &"village"


func _process(_delta: float) -> void:
	if not music_enabled:
		return
	play_music(want_music())
