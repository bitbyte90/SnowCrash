extends Node3D
## Cinema room furniture + the sit-then-play flow (Q3) + resume (Q32).
##  1. Pick a video on the thumbnail wall (or just sit: the first video is chosen).
##  2. Sit (E on a seat). The screen shows "Loading…" while the video opens.
##  3. Only then does the Play button appear (Resume / Start over if we have a resume point).
##  4. Space (flat) / B (VR) stands you up: playback pauses and the position is saved.
## Playback: .ogv plays for real with Godot's built-in Theora player. Other
## formats need an FFmpeg plugin (TECH §8); without one we show a clearly
## labelled preview stub (poster frame + running clock) and suggest Open in Windows.

signal message(text: String)

const KitScript := preload("res://world/kit.gd")
const SCREEN := Vector2(7.2, 4.05)
const LOAD_SECONDS := 1.2
const TILES_PER_PAGE := 12

var videos: Array = []
var room_size := Vector3(16, 4.5, 14)
var selected: Dictionary = {}
var state := "idle"            # idle | loading | ready | playing | paused
var position_s := 0.0
var page := 0

var _screen_mat: StandardMaterial3D
var _screen: MeshInstance3D
var _screen_label: Label3D
var _progress: MeshInstance3D
var _buttons: Node3D
var _tiles_root: Node3D
var _seat_used: Node3D
var _viewport: SubViewport
var _player: VideoStreamPlayer
var _poster: Texture2D
var _using_stub := false


func setup(video_files: Array, size: Vector3) -> void:
	videos = video_files
	room_size = size


func _ready() -> void:
	var back_z := -room_size.z / 2 + 0.15
	# Screen + frame.
	add_child(KitScript.box(Vector3(SCREEN.x + 0.3, SCREEN.y + 0.3, 0.08), Vector3(0, 2.55, back_z - 0.02), Color(0.05, 0.05, 0.06), false))
	_screen = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = SCREEN
	_screen_mat = StandardMaterial3D.new()
	_screen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_screen_mat.albedo_color = Color(0.08, 0.08, 0.1)
	qm.material = _screen_mat
	_screen.mesh = qm
	_screen.position = Vector3(0, 2.55, back_z + 0.03)
	add_child(_screen)
	_screen_label = KitScript.label("Pick a film on the wall, then take a seat", Vector3(0, 2.55, back_z + 0.06), 0.008)
	add_child(_screen_label)
	_progress = MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(1, 0.06, 0.02)
	pm.material = KitScript.mat(Color(0.9, 0.2, 0.2), true)
	_progress.mesh = pm
	_progress.visible = false
	add_child(_progress)

	# Seats: 3 rows x 4, facing the screen.
	for row in 3:
		for col in 4:
			var x := -2.4 + col * 1.6
			var z := 0.4 + row * 1.7
			var seat := KitScript.box(Vector3(0.7, 0.45, 0.65), Vector3(x, 0.225, z), Color(0.55, 0.08, 0.1)) as StaticBody3D
			seat.add_child(KitScript.box(Vector3(0.7, 0.7, 0.12), Vector3(0, 0.55, 0.3), Color(0.5, 0.07, 0.09), false))
			KitScript.make_interactive(seat, {"kind": "seat"}, "Seat (E: sit down)", sit.bind(seat))
			add_child(seat)

	_tiles_root = Node3D.new()
	add_child(_tiles_root)
	_build_tiles()

	_buttons = Node3D.new()
	add_child(_buttons)

	_viewport = SubViewport.new()
	_viewport.size = Vector2i(640, 360)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	_player = VideoStreamPlayer.new()
	_player.expand = true
	_player.size = Vector2(640, 360)
	_player.finished.connect(_on_finished)
	_viewport.add_child(_player)

	ThumbnailCache.thumbnail_ready.connect(_on_thumb)
	var rig := get_tree().get_first_node_in_group("sc_player_rig")
	if rig and rig.has_signal("stood_up"):
		rig.stood_up.connect(_on_stood_up)


# --- thumbnail wall -----------------------------------------------------------

func _build_tiles() -> void:
	for c in _tiles_root.get_children():
		c.queue_free()
	var wall_x := -room_size.x / 2 + 0.14
	var start := page * TILES_PER_PAGE
	var shown := videos.slice(start, start + TILES_PER_PAGE)
	add_child_label_once()
	for i in shown.size():
		var v: Dictionary = shown[i]
		var colm := i % 4
		var row := i / 4
		var tile := Node3D.new()
		tile.position = Vector3(wall_x, 2.75 - row * 0.95, -5.4 + colm * 1.45)
		tile.rotation_degrees.y = 90
		var body := KitScript.box(Vector3(1.25, 0.72, 0.04), Vector3.ZERO, Color(0.15, 0.15, 0.18)) as StaticBody3D
		tile.add_child(body)
		var quad := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(1.2, 0.675)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(0.25, 0.25, 0.3)
		q.material = m
		quad.mesh = q
		quad.position.z = 0.025
		quad.set_meta("video_path", v["path"])
		tile.add_child(quad)
		var resume := Settings.get_resume(v["path"])
		var caption := String(v["name"]).get_basename()
		if resume > 1.0:
			caption += "  ⏸ %s" % _fmt(resume)
		var l := KitScript.label(caption, Vector3(0, -0.45, 0.03), 0.0026)
		l.width = 440
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tile.add_child(l)
		KitScript.make_interactive(body, {"kind": "video", "path": v["path"], "name": v["name"]},
			"Film: %s (E: choose · Q: bag)" % v["name"], select.bind(v))
		_tiles_root.add_child(tile)
		ThumbnailCache.request(v["path"], 128)
	if videos.size() > TILES_PER_PAGE:
		var pages := ceili(videos.size() / float(TILES_PER_PAGE))
		var nxt := KitScript.box(Vector3(0.5, 0.3, 0.04), Vector3(wall_x, 0.55, 0.6), Color(0.3, 0.3, 0.35)) as StaticBody3D
		nxt.rotation_degrees.y = 90
		nxt.add_child(KitScript.label("Page %d/%d ▸" % [page + 1, pages], Vector3(0, 0, 0.03), 0.003))
		KitScript.make_interactive(nxt, {}, "Next page of films", next_page)
		_tiles_root.add_child(nxt)


func add_child_label_once() -> void:
	if has_node("WallTitle"):
		return
	var l := KitScript.label("FILMS IN THIS FOLDER (%d)" % videos.size(), Vector3(-room_size.x / 2 + 0.16, 3.6, -3.2), 0.005)
	l.name = "WallTitle"
	l.rotation_degrees.y = 90
	add_child(l)


func next_page() -> void:
	page = (page + 1) % maxi(1, ceili(videos.size() / float(TILES_PER_PAGE)))
	_build_tiles()


# --- the flow -----------------------------------------------------------------

func select(video: Dictionary) -> void:
	if state == "playing":
		_pause_and_save()
	selected = video
	_poster = null
	_screen_mat.albedo_texture = null
	_screen_mat.albedo_color = Color(0.08, 0.08, 0.1)
	_screen_label.text = "%s\nTake a seat to play" % String(video["name"]).get_basename()
	ThumbnailCache.request(video["path"], 512)
	message.emit("Chosen: %s. Now take a seat." % video["name"])


func sit(seat: Node3D) -> void:
	if videos.is_empty():
		message.emit("No films in this folder.")
		return
	if selected.is_empty():
		select(videos[0])
	_seat_used = seat
	var rig := get_tree().get_first_node_in_group("sc_player_rig")
	if rig:
		rig.sit_at(seat.global_position + Vector3(0, 0.95, 0.1), _screen.global_position)
	state = "loading"
	_screen_label.text = "Loading %s…" % String(selected["name"]).get_basename()
	_prepare_stream()
	await get_tree().create_timer(LOAD_SECONDS).timeout
	if state == "loading":
		state = "ready"
		_show_buttons()


func _prepare_stream() -> void:
	var path: String = selected["path"]
	_using_stub = true
	if path.get_extension().to_lower() == "ogv":
		var stream := VideoStreamTheora.new()
		stream.file = path
		_player.stream = stream
		_using_stub = false
	elif ClassDB.class_exists("VideoPlayback"):
		# TODO(gozen): GDE GoZen adds a VideoPlayback node; instantiate it here,
		# open `path`, and route its texture to the screen. Until wired up we stub.
		pass


## Buttons are freed (not just hidden) so the pointer can't hit invisible ones.
func _clear_buttons() -> void:
	for c in _buttons.get_children():
		c.queue_free()


func _show_buttons() -> void:
	_clear_buttons()
	var resume := Settings.get_resume(selected["path"])
	var base := _seat_used.position + Vector3(0, 1.0, -0.9)
	var play_text := "▶  Resume from %s" % _fmt(resume) if resume > 1.0 else "▶  Play"
	_buttons.add_child(_button(play_text, base + Vector3(-0.56 if resume > 1.0 else 0.0, 0, 0), play.bind(resume)))
	if resume > 1.0:
		_buttons.add_child(_button("⟲  Start over", base + Vector3(0.56, 0, 0), play.bind(0.0)))
	_buttons.visible = true
	_screen_label.text = "%s\nReady" % String(selected["name"]).get_basename()
	message.emit("Ready. Look at Play and press E.")


func _button(text: String, pos: Vector3, action: Callable) -> StaticBody3D:
	var b := KitScript.box(Vector3(1.04, 0.22, 0.04), pos, Color(0.12, 0.45, 0.25)) as StaticBody3D
	b.rotation_degrees.x = -20
	b.add_child(KitScript.label(text, Vector3(0, 0, 0.03), 0.0016))
	KitScript.make_interactive(b, {}, text.strip_edges(), action)
	return b


func play(from_s: float) -> void:
	if state != "ready":
		return
	_clear_buttons()
	position_s = from_s
	state = "playing"
	_progress.visible = true
	if not _using_stub:
		_screen_mat.albedo_color = Color.WHITE
		_screen_mat.albedo_texture = _viewport.get_texture()
		_screen_label.text = ""
		_player.play()
		if from_s > 0.0:
			_player.stream_position = from_s  # Theora seeking may be approximate
	else:
		_screen_mat.albedo_color = Color(0.55, 0.55, 0.55) if _poster else Color(0.1, 0.1, 0.12)
		_screen_mat.albedo_texture = _poster
		_screen_label.text = "▶ PREVIEW STUB: no video plugin installed\n%s\nUse the bag → Open in Windows to watch it now" % selected["name"]
		message.emit("Video plugin not installed: showing a preview stub (TECH §8).")


func _process(delta: float) -> void:
	if state != "playing":
		return
	if not _using_stub:
		position_s = _player.stream_position
	else:
		position_s += delta
	var length := _player.get_stream_length() if not _using_stub else 0.0
	var t := fmod(position_s, 60.0) / 60.0 if length <= 0.0 else clampf(position_s / length, 0.0, 1.0)
	var w := maxf(0.01, SCREEN.x * t)
	(_progress.mesh as BoxMesh).size = Vector3(w, 0.06, 0.02)
	_progress.position = _screen.position + Vector3(-SCREEN.x / 2 + w / 2, -SCREEN.y / 2 - 0.1, 0.02)
	if _using_stub:
		_screen_label.text = "▶ PREVIEW STUB: no video plugin installed\n%s   %s\nUse the bag → Open in Windows to watch it now" % [selected["name"], _fmt(position_s)]


func _on_stood_up() -> void:
	if state in ["playing", "ready", "loading"]:
		_pause_and_save()


func _pause_and_save() -> void:
	if state == "playing":
		if not _using_stub:
			_player.paused = true
		Settings.set_resume(selected["path"], position_s)
		_screen_label.text = "Paused at %s\nSit down to resume" % _fmt(position_s)
		_screen_mat.albedo_texture = _poster
		_build_tiles()  # show the resume marker on the tile
	state = "paused" if not selected.is_empty() else "idle"
	_clear_buttons()
	_progress.visible = false


func _on_finished() -> void:
	Settings.set_resume(selected["path"], 0.0)
	state = "idle"
	_progress.visible = false
	_screen_label.text = "The end. Pick another film."


## Rooms reset when you leave (Q32), but the resume point is kept.
func reset_room() -> void:
	if state == "playing":
		_pause_and_save()
	_player.stop()
	_player.stream = null
	selected = {}
	state = "idle"
	_clear_buttons()
	_progress.visible = false
	_screen_mat.albedo_texture = null
	_screen_mat.albedo_color = Color(0.08, 0.08, 0.1)
	_screen_label.text = "Pick a film on the wall, then take a seat"


func _on_thumb(path: String, tier: int, tex: Texture2D) -> void:
	if tier == 128:
		for tile in _tiles_root.get_children():
			for q in tile.get_children():
				if q is MeshInstance3D and q.get_meta("video_path", "") == path:
					var m: StandardMaterial3D = (q.mesh as QuadMesh).material
					m.albedo_color = Color.WHITE
					m.albedo_texture = tex
	elif tier == 512 and not selected.is_empty() and path == selected["path"]:
		_poster = tex
		if state in ["idle", "paused", "loading", "ready"]:
			_screen_mat.albedo_color = Color(0.6, 0.6, 0.6)
			_screen_mat.albedo_texture = tex


static func _fmt(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60] if s >= 3600 else "%d:%02d" % [s / 60, s % 60]
