extends Control
## THE BAG (Q5, Q14): the right-click menu you get when you pick something up.
## A radial of up to 8 slices: top = primary action, bottom = Put back.
## Number keys 1-8 pick a slice; Esc / Q closes. Write options are shown
## locked in free mode (read-only). See ROOM_TYPES.md and UX_CONTROLS.md §4.
## TODO(vr): render into a SubViewport on a quad at the bag hand; thumbstick
## direction selects a slice, with haptic ticks.

signal option_chosen(action: String, item: Dictionary)
signal closed

const RADIUS := 165.0
const SLICE := Vector2(190, 46)

## [action, label]. First = primary (top slice).
const OPTIONS := {
	"image": [["view", "👁 View full size"], ["info", "ℹ Info"], ["open_in_windows", "🪟 Open in Windows"], ["show_path", "📍 Show path"], ["show_in_folder", "📂 Show in folder"], ["copy_path", "📋 Copy path"]],
	"video": [["play_here", "▶ Choose / play"], ["info", "ℹ Info"], ["open_in_windows", "🪟 Open in default player"], ["show_path", "📍 Show path"], ["show_in_folder", "📂 Show in folder"], ["copy_path", "📋 Copy path"]],
	"folder": [["enter", "🚪 Enter"], ["info", "ℹ Info"], ["open_in_windows", "🪟 Open in Explorer"], ["show_path", "📍 Show path"], ["make_cinema", "🎬 Make this a cinema"], ["copy_path", "📋 Copy path"]],
	"group": [["info", "ℹ What's inside"], ["open_in_windows", "🪟 Open first in Windows"], ["show_path", "📍 Show path"], ["show_in_folder", "📂 Show in folder"], ["copy_path", "📋 Copy path"]],
	"default": [["info", "ℹ Info"], ["open_in_windows", "🪟 Open in Windows"], ["show_path", "📍 Show path"], ["show_in_folder", "📂 Show in folder"], ["copy_path", "📋 Copy path"]],
}
const WRITE_OPTIONS := ["rename", "move", "copy", "delete"]

var item: Dictionary = {}
var _actions: Array = []
var _title: Label


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func options_for(kind: String) -> Array:
	var opts: Array = OPTIONS.get(kind, OPTIONS["default"]).duplicate()
	if not AppState.is_write_mode():
		opts.append(["write_locked", "🔒 Rename / move / delete"])
	opts.append(["put_back", "↩ Put back"])
	return opts


func open_for(target: Dictionary) -> void:
	item = target
	for c in get_children():
		c.queue_free()
	var opts := options_for(String(item.get("kind", "default")))
	_actions = opts.map(func(o): return o[0])
	var centre := get_viewport_rect().size / 2.0
	var ring := Panel.new()
	ring.position = centre - Vector2(RADIUS + 110, RADIUS + 50)
	ring.size = Vector2((RADIUS + 110) * 2, (RADIUS + 50) * 2)
	ring.modulate = Color(1, 1, 1, 0.55)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ring)
	_title = Label.new()
	_title.text = "🎒 " + String(item.get("name", "?"))
	_title.add_theme_font_size_override("font_size", 18)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.custom_minimum_size = Vector2(260, 0)
	_title.position = centre - Vector2(130, 12)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_title)
	var n := opts.size()
	for i in n:
		# Primary at the top, Put back at the bottom, the rest round the sides.
		var angle := -PI / 2.0 + TAU * i / n
		if i == n - 1:
			angle = PI / 2.0
		elif i > 0:
			var side_i := i - 1
			var sides := n - 2
			var half := ceili(sides / 2.0)
			if side_i < half:   # right side, top to bottom
				angle = lerpf(-PI / 2.0 + 0.55, PI / 2.0 - 0.55, (side_i + 0.5) / half)
			else:               # left side, bottom to top
				angle = lerpf(PI / 2.0 + 0.55, 3.0 * PI / 2.0 - 0.55, (side_i - half + 0.5) / maxf(1.0, sides - half))
		var b := Button.new()
		b.text = "%d  %s" % [i + 1, opts[i][1]]
		b.custom_minimum_size = SLICE
		b.size = SLICE
		b.add_theme_font_size_override("font_size", 16)
		b.position = centre + Vector2(cos(angle) * (RADIUS + 50), sin(angle) * RADIUS) - SLICE / 2.0
		if opts[i][0] == "write_locked":
			b.modulate = Color(1, 1, 1, 0.5)
		b.pressed.connect(choose.bind(opts[i][0]))
		add_child(b)
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	if not visible:
		return
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


func choose(action: String) -> void:
	if action == "write_locked":
		# Shown once per session; no nagging (UX_CONTROLS.md §4.2).
		option_chosen.emit("write_locked", item)
		return
	var it := item
	close()
	if action != "put_back":
		option_chosen.emit(action, it)


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed:
		return
	var k: int = (event as InputEventKey).physical_keycode
	if k >= KEY_1 and k <= KEY_8:
		var idx := k - KEY_1
		if idx < _actions.size():
			choose(_actions[idx])
		get_viewport().set_input_as_handled()
	elif k == KEY_ESCAPE or k == KEY_Q:
		close()
		get_viewport().set_input_as_handled()
