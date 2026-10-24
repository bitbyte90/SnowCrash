extends Node3D
## VR controller for Quest 2 over Link / Air Link (PC VR through OpenXR).
## UNTESTED IN A HEADSET. Written against Godot 4.7's OpenXR API and the
## default OpenXR action map (openxr_action_map.tres). See ../VR_SETUP.md.
##
## Controls (UX_CONTROLS.md §2):
##   Left stick ........ smooth walk (if locomotion is "smooth" or "both")
##   Right stick ← → .... snap turn (30° default) or smooth turn
##   Right stick ↑ ...... hold to aim the teleport arc, release to jump
##   Right trigger ...... use / click (doors, seats, canvases, menu buttons)
##   Right grip ......... the bag (same as Q on the keyboard)
##   B .................. close / back (same as Esc)
##   A .................. stand up from a seat
##   Y (left) ........... wrist menu        X (left) ..... teleport menu
## Game code never talks to this directly; buttons become the same input
## actions the keyboard uses (sc_interact, sc_bag…), and the pointer is
## exposed through get_pointed().

signal stood_up

const REACH := 7.0
const ARC_SPEED := 8.0
const ARC_STEPS := 60
const ARC_DT := 0.03
const DEADZONE := 0.2

var origin: XROrigin3D
var camera: XRCamera3D
var left: XRController3D
var right: XRController3D
var body: CharacterBody3D
var ray: RayCast3D
var seated := false
var input_enabled := true
var wrist_host: Node3D            # the left-wrist mount for the wrist menu panel
var fake := false                 # --fake-vr: no headset, made-up poses (screenshots/tests)

var _laser: MeshInstance3D
var _arc: MeshInstance3D
var _arc_mesh: ImmediateMesh
var _target: MeshInstance3D
var _aiming := false
var _arc_hit := Vector3.ZERO
var _arc_ok := false
var _snap_ready := true
var _stand_xform := Transform3D.IDENTITY
var _panel: Node3D = null         # VrPanel the laser is on


func _ready() -> void:
	origin = XROrigin3D.new()
	add_child(origin)
	camera = XRCamera3D.new()
	camera.near = 0.05
	origin.add_child(camera)
	left = _make_hand("left_hand", Color(0.3, 0.6, 1.0))
	right = _make_hand("right_hand", Color(1.0, 0.6, 0.3))
	right.pose = &"aim"   # the laser follows where the controller points
	left.button_pressed.connect(_on_left_pressed)
	right.button_pressed.connect(_on_right_pressed)

	# Body that collides with walls when walking with the stick.
	body = CharacterBody3D.new()
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.25
	cap.height = 1.6
	col.shape = cap
	col.position.y = 0.8
	body.add_child(col)
	body.floor_snap_length = 0.3
	add_child(body)

	ray = RayCast3D.new()
	ray.target_position = Vector3(0, 0, -REACH)
	ray.add_exception(body)
	right.add_child(ray)
	_laser = MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.004, 0.004, 1.0)
	lm.material = _unshaded(Color(0.6, 0.9, 1.0, 0.7))
	_laser.mesh = lm
	right.add_child(_laser)

	_arc_mesh = ImmediateMesh.new()
	_arc = MeshInstance3D.new()
	_arc.mesh = _arc_mesh
	_arc.top_level = true
	add_child(_arc)
	_target = MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.35
	tm.bottom_radius = 0.35
	tm.height = 0.02
	tm.material = _unshaded(Color(0.3, 1.0, 0.5, 0.6))
	_target.mesh = tm
	_target.top_level = true
	_target.visible = false
	add_child(_target)

	wrist_host = Node3D.new()
	wrist_host.name = "WristHost"
	# On the back of the left wrist, tilted towards your eyes. TUNE IN HEADSET.
	wrist_host.position = Vector3(0.0, 0.05, 0.13)
	wrist_host.rotation_degrees = Vector3(-55, 0, 0)
	left.add_child(wrist_host)
	if fake:
		_fake_poses()


## Without a headset nothing is tracked, so stand a pretend person in the rig.
func _fake_poses() -> void:
	camera.position = Vector3(0, 1.65, 0)
	camera.current = true
	for c in [left, right]:
		c.show_when_tracked = false
		c.visible = true
	left.position = Vector3(-0.12, 1.32, -0.34)
	left.rotation_degrees = Vector3(55, 0, 0)
	right.position = Vector3(0.24, 1.3, -0.3)


func _make_hand(tracker: String, colour: Color) -> XRController3D:
	var c := XRController3D.new()
	c.name = tracker
	c.tracker = StringName(tracker)
	origin.add_child(c)
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.05, 0.04, 0.12)
	bm.material = _unshaded(colour)
	m.mesh = bm
	c.add_child(m)
	return c


static func _unshaded(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _physics_process(delta: float) -> void:
	_update_laser()
	if seated or not input_enabled:
		_end_aim(false)
		return
	_locomotion(delta)
	_turning()
	_teleport_aim()


# --- pointer / laser -------------------------------------------------------------

func _update_laser() -> void:
	ray.force_raycast_update()
	var dist := 3.0
	var hit_panel: Node3D = null
	if ray.is_colliding():
		dist = right.global_position.distance_to(ray.get_collision_point())
		var col := ray.get_collider()
		if col and col.has_meta("sc_panel"):
			hit_panel = col.get_meta("sc_panel")
	_laser.scale = Vector3(1, 1, dist)
	_laser.position = Vector3(0, 0, -dist / 2.0)
	if _panel and _panel != hit_panel:
		_panel.pointer_exit()
	_panel = hit_panel
	if _panel:
		_panel.pointer(ray.get_collision_point(), right.is_button_pressed("trigger_click"))
		_panel.scroll(right.get_vector2("primary").y)


func get_pointed() -> Object:
	if ray.is_colliding() and _panel == null:
		return ray.get_collider()
	return null


func is_pointing_at_panel() -> bool:
	return _panel != null


# --- buttons -> the same actions as the keyboard ------------------------------------

func _on_right_pressed(button: String) -> void:
	match button:
		"trigger_click":
			if _panel == null:
				_action("sc_interact")
		"grip_click":
			_action("sc_bag")
		"by_button":
			_action("sc_close")
		"ax_button":
			_action("sc_sit")   # stands you up when seated


func _on_left_pressed(button: String) -> void:
	match button:
		"by_button":
			_action("sc_wrist_menu")
		"ax_button":
			_action("sc_teleport_menu")
		"menu_button":
			_action("sc_close")


func _action(name: String) -> void:
	for pressed in [true, false]:
		var ev := InputEventAction.new()
		ev.action = name
		ev.pressed = pressed
		Input.parse_input_event(ev)


# --- locomotion ------------------------------------------------------------------

func _settings_locomotion() -> String:
	return String(Settings.get_value("comfort", "locomotion", "both"))


func _locomotion(delta: float) -> void:
	# Keep the body under the headset (room-scale steps move it without collision).
	var cam := camera.global_position
	body.global_position = Vector3(cam.x, body.global_position.y, cam.z)
	var stick := left.get_vector2("primary")
	if _settings_locomotion() == "teleport" or stick.length() < DEADZONE:
		stick = Vector2.ZERO
	var basis_y := Basis(Vector3.UP, camera.global_rotation.y)
	var dir := basis_y * Vector3(stick.x, 0, -stick.y)
	var speed := float(Settings.get_value("comfort", "move_speed", 2.0))
	body.velocity.x = dir.x * speed
	body.velocity.z = dir.z * speed
	body.velocity.y = 0.0 if body.is_on_floor() else body.velocity.y - 9.8 * delta
	var before := body.global_position
	body.move_and_slide()
	var moved := body.global_position - before
	if stick == Vector2.ZERO:
		# Standing still: only follow the floor up/down (no sideways nudges from
		# the physics engine pushing the capsule out of nearby geometry).
		moved.x = 0.0
		moved.z = 0.0
		body.global_position = Vector3(before.x, body.global_position.y, before.z)
	origin.global_position += moved
	if body.global_position.y < -20.0:
		teleport_to(Vector3(0, 0, 0), 0.0)
	# TODO(comfort): vignette while moving (Settings comfort/vignette).


func _turning() -> void:
	var x := right.get_vector2("primary").x
	if _panel != null:
		return
	if String(Settings.get_value("comfort", "turn_mode", "snap")) == "smooth":
		if absf(x) > DEADZONE:
			_rotate_around_head(-x * deg_to_rad(90.0) * get_physics_process_delta_time())
		return
	if _snap_ready and absf(x) > 0.7:
		_rotate_around_head(-signf(x) * deg_to_rad(float(Settings.get_value("comfort", "snap_angle", 30))))
		_snap_ready = false
	elif absf(x) < 0.3:
		_snap_ready = true


func _rotate_around_head(angle: float) -> void:
	var pivot := camera.global_position
	var t := Transform3D(Basis(), pivot) * Transform3D(Basis(Vector3.UP, angle), Vector3.ZERO) * Transform3D(Basis(), -pivot)
	origin.global_transform = t * origin.global_transform


# --- teleport arc -----------------------------------------------------------------

func _teleport_aim() -> void:
	if _settings_locomotion() == "smooth" or _panel != null:
		_end_aim(false)
		return
	var y := right.get_vector2("primary").y
	if y > 0.7:
		_aiming = true
		_draw_arc()
	elif _aiming and y < 0.3:
		_end_aim(true)


func _draw_arc() -> void:
	var space := get_world_3d().direct_space_state
	var p := right.global_position
	var v := -right.global_transform.basis.z * ARC_SPEED
	var pts: Array[Vector3] = [p]
	_arc_ok = false
	for i in ARC_STEPS:
		var nv := v + Vector3.DOWN * 9.8 * ARC_DT
		var np := p + nv * ARC_DT
		var q := PhysicsRayQueryParameters3D.create(p, np)
		q.exclude = [body.get_rid()]
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			pts.append(hit["position"])
			_arc_hit = hit["position"]
			_arc_ok = (hit["normal"] as Vector3).y > 0.7
			break
		pts.append(np)
		p = np
		v = nv
	_arc_mesh.clear_surfaces()
	_arc_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _unshaded(Color(0.3, 1, 0.5) if _arc_ok else Color(1, 0.3, 0.3)))
	for pt in pts:
		_arc_mesh.surface_add_vertex(pt)
	_arc_mesh.surface_end()
	_target.visible = _arc_ok
	_target.global_position = _arc_hit + Vector3(0, 0.01, 0)


func _end_aim(jump: bool) -> void:
	if not _aiming:
		return
	_aiming = false
	_arc_mesh.clear_surfaces()
	_target.visible = false
	if jump and _arc_ok:
		_place_head_over(_arc_hit)
	# TODO(comfort): quick fade to black around the jump.


# --- placement ---------------------------------------------------------------------

## Move the play space so your head ends up above `pos` (y = floor height).
func _place_head_over(pos: Vector3) -> void:
	var cam := camera.global_position
	var o := origin.global_position
	origin.global_position = Vector3(o.x + pos.x - cam.x, pos.y, o.z + pos.z - cam.z)
	body.global_position = Vector3(pos.x, pos.y, pos.z)
	body.velocity = Vector3.ZERO


func teleport_to(pos: Vector3, yaw_deg := 0.0) -> void:
	if seated:
		seated = false
	# Turn the play space so the headset faces yaw_deg, then put the head over pos.
	var head_yaw := camera.global_rotation.y
	_rotate_around_head(deg_to_rad(yaw_deg) - head_yaw)
	_place_head_over(pos)


func sit_at(eye_pos: Vector3, look_target: Vector3) -> void:
	_stand_xform = origin.global_transform
	var d := look_target - eye_pos
	teleport_to(Vector3(eye_pos.x, eye_pos.y - 1.15, eye_pos.z), rad_to_deg(atan2(-d.x, -d.z)))
	seated = true
	# TODO(vr): "recentre" prompt so the real head lines up with the seat.


func stand_up(emit := true) -> void:
	if not seated:
		return
	seated = false
	origin.global_transform = _stand_xform
	if emit:
		stood_up.emit()


## Recentre a panel ~1.3 m in front of the head (used for the screen panel).
func place_in_front(node: Node3D, distance := 1.3, drop := 0.15) -> void:
	var yaw := camera.global_rotation.y
	var fwd := Basis(Vector3.UP, yaw) * Vector3(0, 0, -distance)
	node.global_position = camera.global_position + fwd + Vector3(0, -drop, 0)
	node.global_rotation = Vector3(0, yaw, 0)
