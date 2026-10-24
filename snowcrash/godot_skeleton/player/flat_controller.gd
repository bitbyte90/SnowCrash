extends CharacterBody3D
## Flat-screen first-person controller (Q37): WASD, mouse look, Shift run,
## sitting (cinema seats) and a pointer ray for interaction.

signal stood_up

const WALK_SPEED := 3.0
const RUN_SPEED := 6.0
const EYE_HEIGHT := 1.65
const REACH := 7.0

var camera: Camera3D
var ray: RayCast3D
var input_enabled := true
var seated := false
var _pitch := 0.0
var _stand_pos := Vector3.ZERO


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	floor_snap_length = 0.3

	camera = Camera3D.new()
	camera.position.y = EYE_HEIGHT
	camera.fov = 75.0
	camera.near = 0.05
	add_child(camera)
	camera.make_current()

	ray = RayCast3D.new()
	ray.target_position = Vector3(0, 0, -REACH)
	ray.collide_with_areas = false
	ray.add_exception(self)
	camera.add_child(ray)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens: float = Settings.get_value("controls", "mouse_sensitivity", 0.15)
		rotate_y(deg_to_rad(-event.relative.x * sens))
		_pitch = clampf(_pitch - event.relative.y * sens, -85.0, 85.0)
		camera.rotation_degrees.x = _pitch


func _physics_process(delta: float) -> void:
	if seated:
		velocity = Vector3.ZERO
		return
	var input := Vector2.ZERO
	if input_enabled:
		input = Input.get_vector("sc_left", "sc_right", "sc_forward", "sc_back")
	var dir := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	var speed := RUN_SPEED if Input.is_action_pressed("sc_run") else WALK_SPEED
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if global_position.y < -20.0:   # fell out of the world: back to a safe spot
		global_position = _stand_pos if _stand_pos != Vector3.ZERO else Vector3(0, 1, 0)


func set_view(yaw_deg: float, pitch_deg: float) -> void:
	rotation_degrees.y = yaw_deg
	_pitch = pitch_deg
	camera.rotation_degrees.x = pitch_deg


## Point the camera at a world position (used by sitting and the screenshot tour).
func look_at_point(target: Vector3) -> void:
	var eye := camera.global_position
	var d := target - eye
	var yaw := rad_to_deg(atan2(-d.x, -d.z))
	var pitch := rad_to_deg(atan2(d.y, Vector2(d.x, d.z).length()))
	set_view(yaw, pitch)


func sit_at(eye_pos: Vector3, look_target: Vector3) -> void:
	_stand_pos = global_position
	seated = true
	global_position = eye_pos - Vector3(0, EYE_HEIGHT, 0)
	look_at_point(look_target)


func stand_up(emit := true) -> void:
	if not seated:
		return
	seated = false
	global_position = _stand_pos
	if emit:
		stood_up.emit()


func get_pointed() -> Object:
	ray.force_raycast_update()
	return ray.get_collider() if ray.is_colliding() else null
