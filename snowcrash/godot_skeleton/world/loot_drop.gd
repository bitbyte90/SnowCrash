extends Node3D
## Unknown files (Q27/Q28): a spinning, glowing, colour-coded loot drop, or a
## crate holding a whole group ("37 files"). Known-but-undecodable images are
## Polaroids. Every colour also gets a text/icon so colour is never the only cue.

const KitScript := preload("res://world/kit.gd")
const ICONS := {"document": "📄 DOC", "archive": "📦 ZIP", "script": "{ } CODE", "app": "⚙ APP",
	"subtitle": "A SUB", "disc_image": "◎ DISC", "audio": "♪ AUDIO", "model": "◆ 3D", "unknown": "? FILE"}

var kind := "unknown"
var files: Array = []
var grouped := false
var polaroid := false
var _spinner: Node3D
var _photo_mat: StandardMaterial3D


func setup(obj_kind: String, obj_files: Array, is_grouped: bool) -> void:
	kind = obj_kind
	files = obj_files
	grouped = is_grouped
	polaroid = obj_kind == "polaroid"


func _ready() -> void:
	var name_text := String(files[0]["name"]) if files.size() == 1 else "%d %s files" % [files.size(), kind]
	var item := {"kind": "group" if files.size() > 1 else kind, "path": files[0]["path"], "name": name_text,
		"files": files.map(func(f): return f["path"])}
	if polaroid:
		_build_polaroid(item)
		return
	var colour := FileClassifier.loot_colour(kind)
	var body: StaticBody3D
	if grouped or files.size() > 1:
		# A crate for a group of files.
		body = KitScript.box(Vector3(0.7, 0.5, 0.5), Vector3(0, 0.25, 0), Color(0.55, 0.4, 0.25)) as StaticBody3D
		add_child(body)
		add_child(KitScript.box(Vector3(0.72, 0.08, 0.52), Vector3(0, 0.42, 0), colour, false))
		add_child(KitScript.label("%s ×%d" % [ICONS.get(kind, "?"), files.size()], Vector3(0, 0.78, 0), 0.0035, colour.lightened(0.4)))
	else:
		_spinner = Node3D.new()
		_spinner.position.y = 0.6
		add_child(_spinner)
		var gem := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.28, 0.28, 0.28)
		bm.material = KitScript.mat(colour, false, 1.2)
		gem.mesh = bm
		gem.rotation_degrees = Vector3(35, 0, 45)
		_spinner.add_child(gem)
		add_child(KitScript.cylinder(0.3, 0.04, Vector3(0, 0.02, 0), colour.darkened(0.3), false))
		body = StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.5, 1.0, 0.5)
		col.shape = shape
		col.position.y = 0.5
		body.add_child(col)
		add_child(body)
		add_child(KitScript.label("%s\n%s" % [ICONS.get(kind, "?"), name_text], Vector3(0, 1.05, 0), 0.003, colour.lightened(0.4)))
	KitScript.make_interactive(body, item, "%s (Q: bag)" % name_text)


func _build_polaroid(item: Dictionary) -> void:
	# A white card on a little easel, with the file name written underneath.
	var body := KitScript.box(Vector3(0.5, 0.6, 0.03), Vector3(0, 1.1, 0), Color(0.97, 0.97, 0.95)) as StaticBody3D
	body.rotation_degrees.x = -12
	add_child(body)
	add_child(KitScript.box(Vector3(0.04, 1.0, 0.04), Vector3(0, 0.5, -0.1), Color(0.4, 0.3, 0.2), false))
	var photo := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.42, 0.4)
	_photo_mat = StandardMaterial3D.new()
	_photo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_photo_mat.albedo_color = Color(0.2, 0.2, 0.22)
	qm.material = _photo_mat
	photo.mesh = qm
	photo.position = Vector3(0, 0.05, 0.02)
	body.add_child(photo)
	var caption := KitScript.label(String(files[0]["name"]), Vector3(0, -0.22, 0.02), 0.0022, Color(0.1, 0.1, 0.3), 0)
	body.add_child(caption)
	KitScript.make_interactive(body, item, "Polaroid: %s (no viewer for this type)" % files[0]["name"])
	# TODO(native): Windows shell thumbnail would fill the photo here.


func _process(delta: float) -> void:
	if _spinner:
		_spinner.rotate_y(delta * 1.2)
		_spinner.position.y = 0.6 + sin(Time.get_ticks_msec() / 500.0) * 0.05
