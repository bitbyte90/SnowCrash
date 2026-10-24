extends Node3D
## VrPanel: shows a 2D Control in 3D (a SubViewport on a quad) so menus work in
## the headset. The right-hand laser calls pointer() with the hit point; we turn
## that into mouse events inside the SubViewport, so ordinary Buttons, ItemLists
## and sliders just work. Used for the wrist menu (on the left controller) and
## for the "screen" panel that carries the HUD, bag and teleport menu.
## UNTESTED IN A HEADSET (written against the Godot 4.7 API; see VR_SETUP.md).

var viewport: SubViewport
var quad: MeshInstance3D
var body: StaticBody3D
var size_px := Vector2i(800, 600)
var size_m := Vector2(0.4, 0.3)
var _last_px := Vector2(-1, -1)
var _pressed := false


func setup(content: Node, px: Vector2i, width_m: float) -> void:
	size_px = px
	size_m = Vector2(width_m, width_m * float(px.y) / float(px.x))
	viewport = SubViewport.new()
	viewport.size = px
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.gui_embed_subwindows = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	if content.get_parent():
		content.reparent(viewport, false)
	else:
		viewport.add_child(content)

	quad = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size_m
	quad.mesh = qm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Depth pre-pass: plain ALPHA rendered nothing in the Compatibility renderer.
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	m.albedo_texture = viewport.get_texture()
	m.no_depth_test = false
	m.render_priority = 10
	quad.material_override = m
	add_child(quad)

	body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size_m.x, size_m.y, 0.01)
	col.shape = box
	body.add_child(col)
	body.set_meta("sc_panel", self)
	add_child(body)


## Called every frame the laser is on this panel.
func pointer(global_hit: Vector3, pressed: bool) -> void:
	var local := to_local(global_hit)
	var uv := Vector2(local.x / size_m.x + 0.5, 0.5 - local.y / size_m.y)
	var px := Vector2(clampf(uv.x, 0, 1) * size_px.x, clampf(uv.y, 0, 1) * size_px.y)
	if px.distance_to(_last_px) > 0.5:
		var mm := InputEventMouseMotion.new()
		mm.position = px
		mm.global_position = px
		mm.relative = px - _last_px if _last_px.x >= 0 else Vector2.ZERO
		mm.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		viewport.push_input(mm)
		_last_px = px
	if pressed != _pressed:
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.pressed = pressed
		mb.position = px
		mb.global_position = px
		viewport.push_input(mb)
		_pressed = pressed


## Scroll lists with the thumbstick while pointing at the panel.
func scroll(amount: float) -> void:
	if absf(amount) < 0.5 or _last_px.x < 0:
		return
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_WHEEL_UP if amount > 0 else MOUSE_BUTTON_WHEEL_DOWN
	mb.pressed = true
	mb.position = _last_px
	mb.global_position = _last_px
	viewport.push_input(mb)


func pointer_exit() -> void:
	if _pressed:
		pointer(to_global(Vector3.ZERO), false)
	_last_px = Vector2(-1, -1)


func set_shown(on: bool) -> void:
	visible = on
	body.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	(body.get_child(0) as CollisionShape3D).disabled = not on
