extends Node3D
## A door = a subfolder (Q30) with a label + thumbnail outside (Q31).
## Detail by distance: name always; thumbnail + counts ("214 images · 3 folders")
## once a neighbour scan has looked inside. Walking into the doorway, or
## pressing E on it, asks the RoomManager to take you through.
## Local +Z faces into the room.

signal door_used(door_data: Dictionary)

const KitScript := preload("res://world/kit.gd")
const WIDTH := 1.1
const HEIGHT := 2.2

var data: Dictionary = {}
var theme: Dictionary = {}
var _thumb_mat: StandardMaterial3D
var _thumb_quad: MeshInstance3D
var _info: Label3D
var _thumb_src := ""
var _pending_info: Dictionary = {}


func setup(door_data: Dictionary, room_theme: Dictionary = {}) -> void:
	data = door_data
	theme = room_theme


func _ready() -> void:
	var kind: String = data.get("kind", "child")
	var colour: Color = theme.get("door", Color(0.45, 0.32, 0.22))
	if kind == "hallway":
		colour = Color(0.30, 0.42, 0.60)
	elif kind in ["parent", "lobby", "outside"]:
		colour = Color(0.35, 0.35, 0.38)
	var frame_col: Color = theme.get("door_frame", Color(0.92, 0.9, 0.85))
	# Frame + panel. The panel is the interactive body.
	add_child(KitScript.box(Vector3(0.12, HEIGHT + 0.12, 0.16), Vector3(-WIDTH / 2 - 0.06, HEIGHT / 2, 0), frame_col, false))
	add_child(KitScript.box(Vector3(0.12, HEIGHT + 0.12, 0.16), Vector3(WIDTH / 2 + 0.06, HEIGHT / 2, 0), frame_col, false))
	add_child(KitScript.box(Vector3(WIDTH + 0.24, 0.12, 0.16), Vector3(0, HEIGHT + 0.06, 0), frame_col, false))
	var panel := KitScript.box(Vector3(WIDTH, HEIGHT, 0.06), Vector3(0, HEIGHT / 2, 0.02), colour) as StaticBody3D
	add_child(panel)
	add_child(KitScript.box(Vector3(0.06, 0.06, 0.08), Vector3(WIDTH / 2 - 0.15, 1.05, 0.08), Color(0.85, 0.75, 0.3), false))

	var title := String(data.get("label", "?"))
	if kind == "hallway":
		title = "▸ " + title
	elif kind in ["parent", "lobby", "outside"]:
		title = "◂ " + title
	var name_label := KitScript.label(title, Vector3(0, HEIGHT + 0.36, 0.1), 0.006)
	name_label.width = 420
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(name_label)

	# Thumbnail plaque on the door panel (filled in when the folder is scanned).
	_thumb_quad = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.8, 0.6)
	_thumb_mat = StandardMaterial3D.new()
	_thumb_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_thumb_mat.albedo_color = colour.lightened(0.25)
	qm.material = _thumb_mat
	_thumb_quad.mesh = qm
	_thumb_quad.position = Vector3(0, 1.55, 0.06)
	_thumb_quad.visible = false
	add_child(_thumb_quad)

	_info = KitScript.label("", Vector3(0, 0.95, 0.07), 0.0034, Color(1, 1, 0.9))
	_info.width = 300
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_info)

	var hover := "Door: %s" % data.get("label", "")
	var item := {"kind": "folder", "path": data.get("target_path", ""), "name": data.get("label", ""), "door": data}
	KitScript.make_interactive(panel, item, hover, _use)

	# Walk-through threshold just in front of the door.
	var area := Area3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(WIDTH * 0.8, 2.0, 0.5)
	col.shape = shape
	col.position = Vector3(0, 1.0, 0.3)
	area.add_child(col)
	area.body_entered.connect(_on_body_entered)
	add_child(area)
	ThumbnailCache.thumbnail_ready.connect(_on_thumb)
	if not _pending_info.is_empty():
		apply_folder_info(_pending_info)


## Called by RoomManager when a scan of the target folder arrives.
func apply_folder_info(folder: Dictionary) -> void:
	if not is_node_ready():
		_pending_info = folder   # registered before entering the tree; apply in _ready
		return
	if not folder.get("ok", false):
		_info.text = "🔒 " + String(folder.get("error", "locked"))
		return
	var counts := {}
	var first_image := ""
	var first_video := ""
	for f in folder.get("files", []):
		var k: String = f["kind"]
		counts[k] = counts.get(k, 0) + 1
		if k == "image" and first_image == "" and ThumbnailCache.can_thumbnail(f["path"]):
			first_image = f["path"]
		elif k == "video" and first_video == "":
			first_video = f["path"]
	var parts: Array[String] = []
	if counts.get("image", 0) > 0:
		parts.append("%d images" % counts["image"])
	if counts.get("video", 0) > 0:
		parts.append("%d videos" % counts["video"])
	var sub: int = folder.get("folders", []).size()
	if sub > 0:
		parts.append("%d folders" % sub)
	var others := 0
	for k in counts:
		if not (k in ["image", "video"]):
			others += counts[k]
	if others > 0:
		parts.append("%d other" % others)
	_info.text = " · ".join(parts) if not parts.is_empty() else "empty"
	# TODO(Q31): a user-chosen thumbnail from the index wins over this guess.
	_thumb_src = first_image if first_image != "" else first_video
	if _thumb_src != "":
		ThumbnailCache.request(_thumb_src, 128)


func _on_thumb(path: String, tier: int, tex: Texture2D) -> void:
	if path != _thumb_src or tier != 128:
		return
	_thumb_mat.albedo_color = Color.WHITE
	_thumb_mat.albedo_texture = tex
	var aspect := float(tex.get_width()) / maxf(1.0, float(tex.get_height()))
	(_thumb_quad.mesh as QuadMesh).size = Vector2(minf(0.9, 0.6 * aspect), 0.6) if aspect >= 1.0 else Vector2(0.6 * aspect, 0.6)
	_thumb_quad.visible = true


func _use() -> void:
	door_used.emit(data)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		door_used.emit(data)
