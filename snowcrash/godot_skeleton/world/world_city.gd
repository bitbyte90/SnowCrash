extends Node3D
## The Metaverse City GREYBOX (WORLDS.md §1, WORLD_BLOCKOUTS.md §1). An homage
## to the book's Street, in our own words and shapes: a night boulevard, a Port
## where you jack in, and one tower per chosen folder, alternating sides
## (C: first on your left as you step out of the Port).
## Primitive meshes only; sizes follow the blockout spec.

const KitScript := preload("res://world/kit.gd")
const DoorScript := preload("res://world/door.gd")

const ROAD := Color(0.07, 0.07, 0.09)
const PAVEMENT := Color(0.22, 0.22, 0.26)
const KERB := Color(0.35, 0.35, 0.4)
const TOWER := Color(0.12, 0.13, 0.17)
const NEON := [Color(1.0, 0.2, 0.7), Color(0.2, 0.9, 1.0), Color(1.0, 0.75, 0.2), Color(0.5, 1.0, 0.4), Color(0.7, 0.4, 1.0), Color(1.0, 0.35, 0.25)]
const STREET_HALF := 10.0        # road is 20 m wide
const PAVE := 10.0               # pavements 10 m each side
const PLOT_SPACING := 45.0
const LENGTH := 700.0            # visible street length (tiles recycle in the full version)

## Interiors: slick white-cube galleries with dark floors and neon trim.
const ROOM_THEME := {
	"wall": Color(0.9, 0.9, 0.93), "floor": Color(0.16, 0.16, 0.19), "ceiling": Color(0.96, 0.96, 0.98),
	"frame": Color(0.06, 0.06, 0.07), "door": Color(0.12, 0.12, 0.15), "door_frame": Color(0.25, 0.8, 0.95),
	"light": Color(0.92, 0.96, 1.0),
}

var manager: Node
var _fronts: Dictionary = {}


func build(locations: Array) -> void:
	_environment()
	var mid_z := -LENGTH / 2.0 + 100.0
	# Road, pavements, kerbs, lane dashes.
	add_child(KitScript.box(Vector3(2 * STREET_HALF, 0.2, LENGTH), Vector3(0, -0.1, mid_z), ROAD))
	for side: float in [-1.0, 1.0]:
		add_child(KitScript.box(Vector3(PAVE + 30, 0.2, LENGTH), Vector3(side * (STREET_HALF + (PAVE + 30) / 2.0), 0.0, mid_z), PAVEMENT))
		add_child(KitScript.box(Vector3(0.3, 0.25, LENGTH), Vector3(side * STREET_HALF, 0.0, mid_z), KERB, false))
		# Keep walkers on the Street.
		add_child(KitScript.barrier(Vector3(1, 6, LENGTH), Vector3(side * 75.0, 3, mid_z)))
	add_child(KitScript.barrier(Vector3(160, 6, 1), Vector3(0, 3, 100.0)))
	add_child(KitScript.barrier(Vector3(160, 6, 1), Vector3(0, 3, -LENGTH + 100.0)))
	for k in int(LENGTH / 8.0):
		add_child(KitScript.glow_box(Vector3(0.2, 0.02, 3.0), Vector3(0, 0.01, 96.0 - k * 8.0), Color(0.9, 0.9, 0.6), 0.8))
	# Monorail: beam at 14 m over the centre line, pillars every 50 m.
	add_child(KitScript.box(Vector3(2, 1.2, LENGTH), Vector3(0, 14.6, mid_z), Color(0.3, 0.32, 0.38), false))
	add_child(KitScript.glow_box(Vector3(0.1, 0.1, LENGTH), Vector3(0.95, 14.0, mid_z), Color(0.2, 0.9, 1.0), 1.5))
	for k in int(LENGTH / 50.0):
		add_child(KitScript.cylinder(0.6, 14.0, Vector3(0, 7.0, 90.0 - k * 50.0), Color(0.28, 0.3, 0.35)))
	# Street lamps every 25 m on both kerbs (glowing heads; only a few real lights).
	for k in int(LENGTH / 25.0):
		for side: float in [-1.0, 1.0]:
			var z := 92.0 - k * 25.0
			add_child(KitScript.cylinder(0.08, 6.0, Vector3(side * 11.0, 3.0, z), Color(0.25, 0.25, 0.3), false))
			add_child(KitScript.glow_box(Vector3(1.2, 0.15, 0.4), Vector3(side * 10.5, 6.0, z), Color(0.9, 0.95, 1.0), 3.0))
			if k < 6:
				add_child(KitScript.omni(Vector3(side * 10.5, 5.5, z), 0.9, 14.0, Color(0.85, 0.9, 1.0)))

	_port()

	var locs := locations if not locations.is_empty() else [{"label": "C:", "path": ""}, {"label": "D:", "path": ""}]
	for i in locs.size():
		_tower(locs[i], i)
	_background(locs.size())


## The Port: a terminal booth on the left pavement with a glowing floor ring.
func _port() -> void:
	var p := Node3D.new()
	p.position = Vector3(-15, 0, 2)
	add_child(p)
	var frame := Color(0.2, 0.22, 0.28)
	p.add_child(KitScript.box(Vector3(6, 4, 0.3), Vector3(0, 2, 3), frame))          # back wall (behind you)
	p.add_child(KitScript.box(Vector3(0.3, 4, 6), Vector3(-3, 2, 0), frame))         # left wall
	p.add_child(KitScript.box(Vector3(0.3, 4, 6), Vector3(3, 2, 0), frame))          # right wall
	p.add_child(KitScript.box(Vector3(6.3, 0.3, 6.3), Vector3(0, 4.1, 0), frame))    # roof
	p.add_child(KitScript.glow_box(Vector3(6.4, 0.25, 0.1), Vector3(0, 4.0, -3.15), NEON[1], 3.0))
	p.add_child(KitScript.label("PORT 0", Vector3(0, 4.6, -3.1), 0.012, NEON[1]))
	var ring := KitScript.cylinder(1.5, 0.04, Vector3(0, 0.12, 0.5), NEON[1], false) as MeshInstance3D
	ring.material_override = KitScript.mat(NEON[1], false, 2.5)
	p.add_child(ring)
	p.add_child(KitScript.omni(Vector3(0, 3.2, 0), 1.2, 9.0, Color(0.6, 0.9, 1.0)))
	# Directory screen just outside: a physical teleport menu.
	var screen := KitScript.box(Vector3(3, 2, 0.15), Vector3(4.6, 1.6, -4.0), Color(0.05, 0.08, 0.12)) as StaticBody3D
	screen.rotation_degrees.y = -35
	p.add_child(screen)
	var face := KitScript.glow_box(Vector3(2.8, 1.8, 0.02), Vector3(0, 0, 0.09), Color(0.05, 0.25, 0.35), 1.2)
	screen.add_child(face)
	var txt := KitScript.label("DIRECTORY\nYour places on the Street\n\nPress E (or T) to teleport", Vector3(0, 0, 0.11), 0.0036, Color(0.7, 0.95, 1.0))
	screen.add_child(txt)
	KitScript.make_interactive(screen, {}, "Directory: teleport", _open_directory)


func _open_directory() -> void:
	get_tree().call_group("sc_main", "_open_teleport")


## One tower per chosen folder. Even = left side, odd = right side.
func _tower(loc: Dictionary, i: int) -> void:
	var side := -1.0 if i % 2 == 0 else 1.0
	var z := _plot_z(i)
	var label_text := String(loc.get("label", "Drive"))
	var h := 26.0 + float(absi(hash(String(loc.get("path", label_text)))) % 34)   # 26-60 m (real app: log of drive size)
	var w := 26.0 + float(absi(hash(label_text)) % 3) * 4.0
	var neon: Color = NEON[i % NEON.size()]
	var t := Node3D.new()
	t.position = Vector3(side * (STREET_HALF + PAVE), 0, z)   # front face on the setback line
	t.rotation_degrees.y = -90.0 * side                    # local +Z faces the street
	add_child(t)
	t.add_child(KitScript.box(Vector3(w, h, w), Vector3(0, h / 2.0, -w / 2.0 - 10.0), TOWER))
	# Lobby box reaching out to the pavement, with the portal door.
	t.add_child(KitScript.box(Vector3(14, 6, 10), Vector3(0, 3, -5.0), TOWER.lightened(0.08)))
	t.add_child(KitScript.glow_box(Vector3(14.2, 0.2, 0.2), Vector3(0, 6.0, 0.05), neon, 3.0))
	# Window bands up the tower face.
	var rows := int((h - 8.0) / 3.5)
	for r in rows:
		var lit := (hash(label_text + str(r)) % 3) != 0
		if lit:
			t.add_child(KitScript.glow_box(Vector3(w - 4.0, 0.9, 0.1), Vector3(0, 8.0 + r * 3.5, -9.94), Color(0.6, 0.75, 0.9), 0.6))
	# Neon name sign 12 x 3 m, standing on the front edge of the lobby roof.
	t.add_child(KitScript.box(Vector3(12.4, 3.4, 0.3), Vector3(0, 8.2, -0.5), Color(0.04, 0.04, 0.05), false))
	t.add_child(KitScript.glow_box(Vector3(12.4, 0.12, 0.1), Vector3(0, 9.95, -0.3), neon, 4.0))
	t.add_child(KitScript.glow_box(Vector3(12.4, 0.12, 0.1), Vector3(0, 6.45, -0.3), neon, 4.0))
	var name_label := KitScript.label(label_text.to_upper(), Vector3(0, 8.2, -0.3), 0.02, neon.lightened(0.4), 4)
	t.add_child(name_label)
	t.add_child(KitScript.omni(Vector3(0, 8.2, 3.0), 2.0, 16.0, neon))
	# Rooftop crown.
	t.add_child(KitScript.glow_box(Vector3(w * 0.5, 1.0, w * 0.5), Vector3(0, h + 0.5, -w / 2.0 - 10.0), neon.darkened(0.3), 1.0))
	# Portal door.
	var door: Node3D = DoorScript.new()
	door.setup({"socket": 0, "label": label_text, "target_path": loc.get("path", ""), "target_id": "", "kind": "child", "thumb": ""}, ROOM_THEME)
	door.position = Vector3(0, 0, 0.02)
	door.scale = Vector3(1.6, 1.6, 1.6)
	if String(loc.get("path", "")) != "":
		door.door_used.connect(manager.use_door)
		manager.register_door(door, loc["path"])
	t.add_child(door)
	_fronts[loc.get("path", "")] = [t.transform * Vector3(0, 0, 7.0), -90.0 * side]


static func _plot_z(i: int) -> float:
	return -22.0 - floorf(i / 2.0) * PLOT_SPACING - (8.0 if i % 2 == 1 else 0.0)


## Generic background towers (no doors) so the Street feels endless.
func _background(used: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for side: float in [-1.0, 1.0]:
		for k in 16:
			var z := 80.0 - k * 38.0
			if z > -2.0 and z < 12.0 and side < 0:
				continue   # the Port
			var clash := false
			for i in used:
				if (i % 2 == 0) == (side < 0) and absf(_plot_z(i) - z) < 36.0:
					clash = true   # leave the plots in use clear
			if clash:
				continue
			var h := rng.randf_range(18.0, 90.0)
			var w := rng.randf_range(18.0, 30.0)
			var x := side * (STREET_HALF + PAVE + 6.0 + w / 2.0 + rng.randf_range(0, 8))
			add_child(KitScript.box(Vector3(w, h, w), Vector3(x, h / 2.0, z), TOWER.darkened(rng.randf_range(0.0, 0.4)), false))
			if rng.randf() < 0.6:
				var c: Color = NEON[rng.randi() % NEON.size()]
				add_child(KitScript.glow_box(Vector3(0.3, rng.randf_range(4, 12), 2.0), Vector3(x - side * (w / 2.0 + 0.2), rng.randf_range(8, 20), z), c, 2.5))
		# Far skyline row.
		for k in 22:
			var h2 := rng.randf_range(40.0, 160.0)
			add_child(KitScript.box(Vector3(30, h2, 30), Vector3(side * rng.randf_range(90, 140), h2 / 2.0, 90.0 - k * 30.0), Color(0.06, 0.06, 0.09), false))


func _environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.01, 0.01, 0.03)
	sm.sky_horizon_color = Color(0.22, 0.05, 0.22)
	sm.ground_horizon_color = Color(0.1, 0.03, 0.1)
	sm.ground_bottom_color = Color(0.0, 0.0, 0.0)
	sm.sun_angle_max = 0.0
	sky.sky_material = sm
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.45, 0.5, 0.75)
	e.ambient_light_energy = 0.35
	e.fog_enabled = true
	e.fog_light_color = Color(0.06, 0.05, 0.14)
	e.fog_density = 0.006
	e.glow_enabled = true
	e.glow_intensity = 0.6
	e.glow_bloom = 0.1
	env.environment = e
	add_child(env)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-40, 30, 0)
	moon.light_energy = 0.18
	moon.light_color = Color(0.6, 0.7, 1.0)
	add_child(moon)
	# TODO(tier2): wet-street reflections (SSR), volumetric fog, animated billboards.


func get_spawn() -> Array:
	return [Vector3(-15, 0, 2.5), -20.0]   # in the Port, facing down the Street (-Z), turned a little towards the road


func get_outside_point(location_path: String) -> Array:
	return _fronts.get(location_path, get_spawn())
