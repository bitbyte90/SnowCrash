extends RefCounted
## Tiny "modular kit" of greybox helpers shared by rooms and worlds.
## Everything is primitive meshes for now; a theme pack swaps these for real
## art later (WORLDS.md §6, WORLD_BLOCKOUTS.md).

static var _mats: Dictionary = {}


static func mat(colour: Color, unshaded := false, emission := 0.0) -> StandardMaterial3D:
	var key := "%s|%s|%s" % [colour.to_html(), unshaded, emission]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = colour
		m.emission_energy_multiplier = emission
	_mats[key] = m
	return m


## A box with collision (StaticBody3D) or without (just a mesh).
static func box(size: Vector3, pos: Vector3, colour: Color, collide := true) -> Node3D:
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = mat(colour)
	mesh.mesh = bm
	if not collide:
		mesh.position = pos
		return mesh
	var body := StaticBody3D.new()
	body.position = pos
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body


static func cylinder(radius: float, height: float, pos: Vector3, colour: Color, collide := true) -> Node3D:
	var mesh := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 16
	cm.material = mat(colour)
	mesh.mesh = cm
	if not collide:
		mesh.position = pos
		return mesh
	var body := StaticBody3D.new()
	body.position = pos
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	col.shape = shape
	body.add_child(col)
	return body


static func sphere(radius: float, pos: Vector3, colour: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 12
	sm.rings = 6
	sm.material = mat(colour)
	mesh.mesh = sm
	mesh.position = pos
	return mesh


## Triangular prism (e.g. a museum pediment), pointing up.
static func prism(size: Vector3, pos: Vector3, colour: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = size
	pm.material = mat(colour)
	mesh.mesh = pm
	mesh.position = pos
	return mesh


static func label(text: String, pos: Vector3, pixel := 0.006, colour := Color.WHITE, outline := 8) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.pixel_size = pixel
	l.modulate = colour
	l.outline_size = outline
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.font_size = 48
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.double_sided = false
	return l


static func omni(pos: Vector3, energy := 1.0, rng := 12.0, colour := Color(1, 0.96, 0.9)) -> OmniLight3D:
	var o := OmniLight3D.new()
	o.position = pos
	o.light_energy = energy
	o.omni_range = rng
	o.light_color = colour
	return o


## Mark a collision object as interactive. `item` feeds the bag; `on_use` runs on E/click.
static func make_interactive(body: CollisionObject3D, item: Dictionary, hover: String, on_use: Callable = Callable()) -> void:
	body.set_meta("sc_item", item)
	body.set_meta("sc_hover", hover)
	if on_use.is_valid():
		body.set_meta("sc_interact", on_use)


## Cone / frustum (hills, roofs, lamp shades). Collision is a convex hull.
static func cone(bottom_r: float, top_r: float, height: float, pos: Vector3, colour: Color, collide := true, segments := 16) -> Node3D:
	var mesh := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bottom_r
	cm.height = height
	cm.radial_segments = segments
	cm.material = mat(colour)
	mesh.mesh = cm
	if not collide:
		mesh.position = pos
		return mesh
	var body := StaticBody3D.new()
	body.position = pos
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	col.shape = cm.create_convex_shape()
	body.add_child(col)
	return body


## A glowing box (neon, windows, lamps). No collision.
static func glow_box(size: Vector3, pos: Vector3, colour: Color, energy := 2.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = mat(colour, false, energy)
	mesh.mesh = bm
	mesh.position = pos
	return mesh


## An invisible wall (keeps walkers on the island / the Street).
static func barrier(size: Vector3, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body


## A walkable invisible ramp from `from` to `to` (both at floor height), `width` wide.
static func ramp(from: Vector3, to: Vector3, width: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	var d := to - from
	var length := d.length()
	body.transform = Transform3D(Basis.looking_at(d, Vector3.UP), (from + to) / 2.0)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, 0.1, length)
	col.shape = shape
	col.position.y = -0.05
	body.add_child(col)
	return body
