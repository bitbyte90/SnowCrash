extends Node3D
## The bare default world (Q16) with the demo's ONE building (Q10) and the
## five tutorial signs (DEMO_MVP_SPEC §2). Faint "ghost" buildings hint that
## in the full app every drive is a building.

const KitScript := preload("res://world/kit.gd")
const DoorScript := preload("res://world/door.gd")

var manager: Node            # RoomManager, set by main before build()
var spawn_pos := Vector3(0, 0, 12)
var spawn_yaw := 0.0

const TUTORIAL := [
	"1 · MOVING\nWASD to walk, mouse to look, Shift to run.\n(VR: left stick walks, right stick turns.)",
	"2 · THE WRIST MENU\nTab opens your main menu.\n(VR: look at your left wrist, or press Y.)",
	"3 · THE BAG\nPoint at something and press Q (or right-click).\nThe bag shows everything you can do with it.",
	"4 · TELEPORT\nPress T to jump anywhere: the lobby,\nor straight into any room.",
	"5 · THE BIG PICTURE\nThis is ONE building. In the full app every drive\non your PC is a building, in a world you choose.",
]


func build(_locations: Array) -> void:
	_environment()
	# Ground + path.
	add_child(KitScript.box(Vector3(240, 0.2, 240), Vector3(0, -0.1, 0), Color(0.24, 0.25, 0.27)))
	add_child(KitScript.box(Vector3(3, 0.02, 14), Vector3(0, 0.01, 2), Color(0.34, 0.35, 0.38), false))
	for i in range(-6, 7):  # faint grid lines for scale
		add_child(KitScript.box(Vector3(0.03, 0.005, 120), Vector3(i * 10, 0.005, 0), Color(0.3, 0.31, 0.33), false))
		add_child(KitScript.box(Vector3(120, 0.005, 0.03), Vector3(0, 0.005, i * 10), Color(0.3, 0.31, 0.33), false))

	# The demo building: a simple pavilion, 18 x 7 x 12 m, front face at z = -4.
	var b := Node3D.new()
	b.name = "DemoBuilding"
	add_child(b)
	b.add_child(KitScript.box(Vector3(18, 7, 12), Vector3(0, 3.5, -10), Color(0.82, 0.83, 0.86)))
	b.add_child(KitScript.box(Vector3(19, 0.5, 13), Vector3(0, 7.25, -10), Color(0.35, 0.37, 0.42), false))   # roof slab
	b.add_child(KitScript.box(Vector3(6, 0.25, 3), Vector3(0, 0.125, -2.6), Color(0.6, 0.6, 0.62), false))   # front step
	b.add_child(KitScript.box(Vector3(8, 0.3, 2.5), Vector3(0, 3.6, -2.8), Color(0.35, 0.37, 0.42), false))  # canopy
	for x in [-3.6, 3.6]:
		b.add_child(KitScript.cylinder(0.12, 3.5, Vector3(x, 1.75, -1.8), Color(0.3, 0.3, 0.32)))
	b.add_child(KitScript.label("SNOW CRASH · DEMO BUILDING", Vector3(0, 5.4, -3.95), 0.012, Color(0.12, 0.14, 0.2), 0))
	b.add_child(KitScript.label("Your chosen folders are the rooms inside", Vector3(0, 4.6, -3.95), 0.006, Color(0.2, 0.22, 0.28), 0))
	var door: Node3D = DoorScript.new()
	door.setup({"socket": 0, "label": "Enter", "target_path": "", "target_id": "lobby", "kind": "lobby", "thumb": ""})
	door.position = Vector3(0, 0.25, -3.95)
	door.door_used.connect(manager.use_door)
	b.add_child(door)
	b.add_child(KitScript.omni(Vector3(0, 3.3, -2.5), 1.2, 8.0))

	# Tutorial signs along the path.
	for i in TUTORIAL.size():
		var side := -1.0 if i % 2 == 0 else 1.0
		var z := 7.0 - i * 2.2
		var post := Node3D.new()
		post.position = Vector3(side * 2.6, 0, z)
		post.rotation_degrees.y = -side * 25.0
		post.add_child(KitScript.box(Vector3(0.08, 1.2, 0.08), Vector3(0, 0.6, -0.02), Color(0.3, 0.3, 0.32), false))
		post.add_child(KitScript.box(Vector3(1.9, 0.95, 0.05), Vector3(0, 1.6, -0.05), Color(0.12, 0.14, 0.2), false))
		post.add_child(KitScript.label(TUTORIAL[i], Vector3(0, 1.6, 0.0), 0.0028))
		add_child(post)

	# Ghost buildings: "in the full app, every drive is a building".
	var ghost := StandardMaterial3D.new()
	ghost.albedo_color = Color(0.6, 0.75, 1.0, 0.18)
	ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var drives := ["D:", "E:", "F:"]
	for i in drives.size():
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(10, 5 + i * 2, 10)
		bm.material = ghost
		m.mesh = bm
		var x := -22.0 + i * 22.0 if i != 1 else 24.0
		var z := -22.0 if i != 1 else -14.0
		m.position = Vector3(x, bm.size.y / 2, z)
		add_child(m)
		add_child(KitScript.label("%s would be a building here" % drives[i], Vector3(x, bm.size.y + 1.0, z + 5), 0.012, Color(0.75, 0.85, 1.0)))


func _environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.17, 0.18, 0.21)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.76, 0.8)
	e.ambient_light_energy = 0.7
	e.fog_enabled = true
	e.fog_light_color = Color(0.17, 0.18, 0.21)
	e.fog_density = 0.012
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 0.9
	add_child(sun)


func get_spawn() -> Array:
	return [spawn_pos, spawn_yaw]


func get_outside_point(_location_path: String) -> Array:
	return [Vector3(0, 0, -0.5), 0.0]   # just outside the front door, facing it
