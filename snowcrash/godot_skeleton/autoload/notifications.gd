extends Node
## Notifications: a small queue shown on the wrist panel (Q34/Q35).
## Each item offers View / Go there / Ignore.

signal notification_added(item: Dictionary)
signal notifications_cleared

const MAX_ITEMS := 50

var items: Array[Dictionary] = []
var do_not_disturb := false


func push(text: String, data: Dictionary = {}) -> void:
	var item := {"text": text, "data": data, "time": Time.get_unix_time_from_system()}
	items.push_front(item)
	if items.size() > MAX_ITEMS:
		items.resize(MAX_ITEMS)
	# TODO(collapse): merge bursts ("12 new files in Downloads").
	if not do_not_disturb:
		notification_added.emit(item)


func clear() -> void:
	items.clear()
	notifications_cleared.emit()
