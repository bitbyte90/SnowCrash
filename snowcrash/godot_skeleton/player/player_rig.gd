extends Node3D
## PlayerRig: one rig for VR (OpenXR) and flat-screen. Tries OpenXR first;
## falls back to the WASD controller. Game logic only asks the rig "what are
## you pointing at?" and never cares which mode is active.
## VR is wired (player/vr_controller.gd) but UNTESTED in a headset.
## TODO(xr-tools): Godot XR Tools for hand models, pickup, vignette, keyboard.

signal stood_up

const FlatControllerScript := preload("res://player/flat_controller.gd")
const VrControllerScript := preload("res://player/vr_controller.gd")

var vr: Node3D                 # VrController when in VR
var flat: CharacterBody3D
var force_flat := false
## --fake-vr: build the VR rig and panels WITHOUT a headset (for screenshots and
## smoke tests on a normal screen). Nothing is tracked; poses are made up.
var fake_vr := false
var xr_interface: XRInterface


func _ready() -> void:
	add_to_group("sc_player_rig")
	xr_interface = XRServer.find_interface("OpenXR")
	if fake_vr:
		vr = VrControllerScript.new()
		vr.name = "VR"
		vr.fake = true
		add_child(vr)
		vr.stood_up.connect(func(): stood_up.emit())
		AppState.set_vr(true)
		return
	if not force_flat and xr_interface and xr_interface.is_initialized():
		_setup_vr()
	else:
		if not force_flat and xr_interface == null:
			print("Snow Crash: OpenXR not available, using flat-screen mode.")
		_setup_flat()


func _setup_vr() -> void:
	var vp := get_viewport()
	vp.use_xr = true
	# The headset sets the pace (72/90/120 Hz on Quest 2); the desktop window must not.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var rate := float(xr_interface.get("display_refresh_rate")) if xr_interface.get("display_refresh_rate") != null else 0.0
	Engine.physics_ticks_per_second = int(rate) if rate >= 60.0 else 90
	vr = VrControllerScript.new()
	vr.name = "VR"
	add_child(vr)
	vr.stood_up.connect(func(): stood_up.emit())
	# Pause the world while the Quest menu is open; resume when back.
	if xr_interface.has_signal("session_visible"):
		xr_interface.connect("session_visible", func(): get_tree().paused = true)
		xr_interface.connect("session_focussed", func(): get_tree().paused = false)
		xr_interface.connect("session_stopping", func(): get_tree().quit())
	AppState.set_vr(true)
	print("Snow Crash: VR mode (OpenXR). Untested build: please report what works.")


func _setup_flat() -> void:
	flat = FlatControllerScript.new()
	add_child(flat)
	flat.stood_up.connect(func(): stood_up.emit())
	AppState.set_vr(false)


func teleport_to(pos: Vector3, yaw_deg := 0.0) -> void:
	if flat:
		flat.stand_up(false)
		flat.global_position = pos
		flat.set_view(yaw_deg, 0.0)
		flat.velocity = Vector3.ZERO
	elif vr:
		vr.teleport_to(pos, yaw_deg)


func sit_at(eye_pos: Vector3, look_target: Vector3) -> void:
	if flat:
		flat.sit_at(eye_pos, look_target)
	elif vr:
		vr.sit_at(eye_pos, look_target)


func stand_up() -> void:
	if flat:
		flat.stand_up(true)
	elif vr:
		vr.stand_up(true)


func is_seated() -> bool:
	return (flat != null and flat.seated) or (vr != null and vr.seated)


func get_pointed() -> Object:
	if flat:
		return flat.get_pointed()
	if vr:
		return vr.get_pointed()
	return null


func set_input_enabled(enabled: bool) -> void:
	if flat:
		flat.input_enabled = enabled
	# In VR the menus are panels in the world, so you can keep moving.
