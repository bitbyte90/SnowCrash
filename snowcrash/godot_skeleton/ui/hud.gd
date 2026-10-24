extends Control
## Flat-screen HUD: crosshair, "what am I pointing at", where-am-I, toasts,
## the info panel (bag → Info), a full-size image viewer (bag → View) and the
## fade used for teleports/room changes (comfort: UX_CONTROLS.md §10).
## In VR most of this moves onto the wrist panel.

var _crosshair: Label
var _hover: Label
var _where: Label
var _prompt: Label
var _toasts: VBoxContainer
var _info: PanelContainer
var _info_text: RichTextLabel
var _viewer: Control
var _viewer_tex: TextureRect
var _viewer_caption: Label
var _viewer_path := ""
var _fade: ColorRect
var _keys: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_crosshair = _label("+", 26)
	add_child(_crosshair)

	_hover = _label("", 18)
	_hover.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hover.custom_minimum_size = Vector2(900, 0)
	add_child(_hover)

	_where = _label("", 18)
	_where.position = Vector2(16, 12)
	add_child(_where)

	_keys = _label("WASD move · Shift run · E use · Q / right-click bag · T teleport · Tab wrist menu · / search · I info · 0-5 slideshow · Space stand · Esc mouse", 14)
	_keys.modulate = Color(1, 1, 1, 0.65)
	add_child(_keys)

	_prompt = _label("", 22)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.custom_minimum_size = Vector2(900, 0)
	add_child(_prompt)

	_toasts = VBoxContainer.new()
	_toasts.custom_minimum_size = Vector2(600, 0)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toasts)

	_info = PanelContainer.new()
	_info.custom_minimum_size = Vector2(540, 380)
	_info.visible = false
	_info_text = RichTextLabel.new()
	_info_text.bbcode_enabled = true
	_info_text.fit_content = true
	_info_text.add_theme_font_size_override("normal_font_size", 17)
	_info_text.add_theme_font_size_override("bold_font_size", 20)
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 14)
	m.add_child(_info_text)
	_info.add_child(m)
	add_child(_info)

	_viewer = ColorRect.new()
	(_viewer as ColorRect).color = Color(0, 0, 0, 0.88)
	_viewer.visible = false
	_viewer_tex = TextureRect.new()
	_viewer_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_viewer_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_viewer.add_child(_viewer_tex)
	_viewer_caption = _label("", 18)
	_viewer_caption.custom_minimum_size = Vector2(800, 0)
	_viewer_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_viewer.add_child(_viewer_caption)
	add_child(_viewer)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

	ThumbnailCache.thumbnail_ready.connect(_on_thumb)
	get_viewport().size_changed.connect(_layout)
	_layout()


## Explicit layout from the viewport size (robust under a CanvasLayer).
func _layout() -> void:
	var vs := get_viewport_rect().size
	_crosshair.position = vs / 2.0 - Vector2(8, 18)
	_hover.position = Vector2(vs.x / 2.0 - 450, vs.y / 2.0 + 22)
	_where.position = Vector2(16, 12)
	_keys.position = Vector2(16, vs.y - 30)
	_prompt.position = Vector2(vs.x / 2.0 - 450, vs.y - 110)
	_toasts.position = Vector2(vs.x - 620, 44)
	_info.position = Vector2(vs.x - 570, vs.y / 2.0 - 220)
	_viewer.position = Vector2.ZERO
	_viewer.size = vs
	_viewer_tex.position = Vector2(0, 40)
	_viewer_tex.size = vs - Vector2(0, 110)
	_viewer_caption.position = Vector2(vs.x / 2.0 - 400, vs.y - 50)
	_fade.position = Vector2.ZERO
	_fade.size = vs


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func set_hover(text: String) -> void:
	_hover.text = text


func set_where(text: String) -> void:
	_where.text = "📍 " + text


func set_prompt(text: String) -> void:
	_prompt.text = text


func toast(text: String, seconds := 4.0) -> void:
	var l := _label(text, 17)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(600, 0)
	_toasts.add_child(l)
	if _toasts.get_child_count() > 5:
		_toasts.get_child(0).queue_free()
	var tw := create_tween()
	tw.tween_interval(seconds)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)


func show_info(bbcode: String) -> void:
	_info_text.text = bbcode
	_info.visible = true


func hide_overlays() -> bool:
	var was := _info.visible or _viewer.visible
	_info.visible = false
	_viewer.visible = false
	return was


func is_info_open() -> bool:
	return _info.visible


## VR: no crosshair (the laser does that job) and controller hints instead of keys.
func set_vr_mode(on: bool) -> void:
	_crosshair.visible = not on
	_keys.text = "Trigger use · Grip bag · Right stick: turn / push up to teleport · Y wrist menu · X teleport menu · A stand up · B close" if on else _keys.text


func is_viewer_open() -> bool:
	return _viewer.visible


func show_image(path: String) -> void:
	_viewer_path = path
	_viewer_tex.texture = null
	_viewer_caption.text = "%s   (loading full size…)   Esc to close" % path.get_file()
	_viewer.visible = true
	ThumbnailCache.request(path, ThumbnailCache.FULL)


func _on_thumb(path: String, tier: int, tex: Texture2D) -> void:
	if tier == ThumbnailCache.FULL and path == _viewer_path and _viewer.visible:
		_viewer_tex.texture = tex
		_viewer_caption.text = "%s   %d × %d (shown)   Esc to close" % [path.get_file(), tex.get_width(), tex.get_height()]


## Fade to black, run `mid` (the teleport), fade back in. 0.3 s total (comfort).
func fade_through(mid: Callable) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.12)
	tw.tween_callback(mid)
	tw.tween_interval(0.06)
	tw.tween_property(_fade, "color:a", 0.0, 0.18)
