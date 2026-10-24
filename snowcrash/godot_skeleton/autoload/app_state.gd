extends Node
## AppState: global "where am I / what mode am I in" state, plus input actions.

signal room_changed(path: String)
signal mode_changed(is_vr: bool)

var is_vr := false
var current_room_path := ""
var back_stack: Array[String] = []
## The demo's locations (wizard picks or --root= arguments):
## Array of {"label": String, "path": String, "kind": String}
var locations: Array = []


func set_vr(enabled: bool) -> void:
	is_vr = enabled
	mode_changed.emit(enabled)


func enter_room(path: String) -> void:
	if current_room_path != "":
		back_stack.push_back(current_room_path)
		if back_stack.size() > 50:
			back_stack.pop_front()
	current_room_path = path
	room_changed.emit(path)


func is_write_mode() -> bool:
	## Free mode is read-only (Q5). Every write path must check this AND ask the user.
	return bool(Settings.get_value("write_mode", "unlocked", false))


## Flat-screen bindings (UX_CONTROLS.md §9). Registered in code so the
## project.godot stays readable. VR actions come from the OpenXR action map.
func register_input_actions() -> void:
	_add_key("sc_forward", KEY_W)
	_add_key("sc_back", KEY_S)
	_add_key("sc_left", KEY_A)
	_add_key("sc_right", KEY_D)
	_add_key("sc_run", KEY_SHIFT)
	_add_key("sc_interact", KEY_E)
	_add_key("sc_wrist_menu", KEY_TAB)
	_add_key("sc_teleport_menu", KEY_T)
	_add_key("sc_search", KEY_SLASH)
	_add_key("sc_notifications", KEY_N)
	_add_key("sc_sit", KEY_SPACE)
	_add_key("sc_pause", KEY_ESCAPE)
	_add_key("sc_bag", KEY_Q)
	_add_mouse("sc_bag", MOUSE_BUTTON_RIGHT)
	_add_mouse("sc_interact", MOUSE_BUTTON_LEFT)
	_add_key("sc_info", KEY_I)
	_add_key("sc_close", KEY_ESCAPE)


func _ensure(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)


func _add_key(action: String, keycode: Key) -> void:
	_ensure(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)


func _add_mouse(action: String, button: MouseButton) -> void:
	_ensure(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
