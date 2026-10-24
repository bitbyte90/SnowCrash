extends Node3D
## A canvas on the wall. In big folders each canvas cycles through its share
## of the images (Q1), on a slideshow of 1-5 s or manual (Q2).
## Loads a 512 px thumbnail; the bag's "View" shows full resolution.
## Local +Z faces into the room.

const KitScript := preload("res://world/kit.gd")
const MAX_SIZE := Vector2(1.7, 1.25)

var images: Array = []
var index := 0
var interval := 0          # seconds; 0 = manual
var frame_colour := Color(0.12, 0.1, 0.08)
var _quad: MeshInstance3D
var _frame: MeshInstance3D
var _mat: StandardMaterial3D
var _timer: Timer
var _counter: Label3D
var _body: StaticBody3D
var _shape: BoxShape3D


func setup(image_paths: Array, slideshow_seconds: int, frame_col: Color = Color(0.12, 0.1, 0.08)) -> void:
	images = image_paths
	interval = slideshow_seconds
	frame_colour = frame_col


func _ready() -> void:
	_frame = MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.material = KitScript.mat(frame_colour)
	_frame.mesh = fm
	_frame.position.z = -0.03
	add_child(_frame)

	_quad = MeshInstance3D.new()
	var qm := QuadMesh.new()
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.albedo_color = Color(0.55, 0.55, 0.58)  # placeholder until the thumbnail arrives
	qm.material = _mat
	_quad.mesh = qm
	_quad.position.z = 0.012
	add_child(_quad)

	_counter = KitScript.label("", Vector3(0, 0, 0.02), 0.0022, Color(0.15, 0.15, 0.15), 0)
	add_child(_counter)

	_body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	_shape = BoxShape3D.new()
	col.shape = _shape
	_body.add_child(col)
	add_child(_body)
	_set_size(Vector2(1.6, 1.2))

	_timer = Timer.new()
	_timer.timeout.connect(next_image)
	add_child(_timer)
	set_slideshow(interval)
	ThumbnailCache.thumbnail_ready.connect(_on_thumb)
	ThumbnailCache.thumbnail_failed.connect(_on_failed)
	_show_current()


func current_path() -> String:
	return "" if images.is_empty() else String(images[index])


func set_slideshow(seconds: int) -> void:
	interval = clampi(seconds, 0, 5)
	if _timer == null:
		return
	_timer.stop()
	if interval > 0 and images.size() > 1:
		# Stagger so canvases don't all flip at once (spreads texture uploads too).
		_timer.wait_time = interval + randf() * 0.6
		_timer.start()


func next_image() -> void:
	if images.size() < 2:
		return
	index = (index + 1) % images.size()
	_show_current()


func previous_image() -> void:
	if images.size() < 2:
		return
	index = (index - 1 + images.size()) % images.size()
	_show_current()


## Called by RoomCache when the player leaves (rooms reset, Q32).
func reset_room() -> void:
	index = 0
	set_slideshow(int(Settings.get_value("rooms", "slideshow_seconds", 0)))
	_show_current()


func _show_current() -> void:
	if images.is_empty():
		return
	var p := current_path()
	_counter.text = "%d / %d" % [index + 1, images.size()] if images.size() > 1 else ""
	var item := {"kind": "image", "path": p, "name": p.get_file()}
	KitScript.make_interactive(_body, item, "Picture: %s  (E: next · Q: bag)" % p.get_file(), next_image)
	ThumbnailCache.request(p, 512)
	# Prefetch the next one so the slideshow flips instantly.
	if images.size() > 1:
		ThumbnailCache.request(String(images[(index + 1) % images.size()]), 512)


func _on_thumb(path: String, tier: int, tex: Texture2D) -> void:
	if tier != 512 or path != current_path():
		return
	_mat.albedo_color = Color.WHITE
	_mat.albedo_texture = tex
	var aspect := float(tex.get_width()) / maxf(1.0, float(tex.get_height()))
	var s := Vector2(MAX_SIZE.y * aspect, MAX_SIZE.y)
	if s.x > MAX_SIZE.x:
		s = Vector2(MAX_SIZE.x, MAX_SIZE.x / aspect)
	_set_size(s)


func _on_failed(path: String, _tier: int) -> void:
	if path == current_path():
		_mat.albedo_texture = null
		_mat.albedo_color = Color(0.95, 0.95, 0.92)  # TODO(polaroid): proper Polaroid look
		_counter.text = path.get_file()


func _set_size(s: Vector2) -> void:
	(_quad.mesh as QuadMesh).size = s
	(_frame.mesh as BoxMesh).size = Vector3(s.x + 0.12, s.y + 0.12, 0.05)
	_shape.size = Vector3(s.x + 0.12, s.y + 0.12, 0.1)
	_counter.position = Vector3(s.x / 2 - 0.12, -s.y / 2 - 0.12, 0.02)
