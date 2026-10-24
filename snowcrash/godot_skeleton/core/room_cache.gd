class_name RoomCache
extends RefCounted
## Keeps the last N rooms ready (Q33) and resets rooms when you leave (Q32).
## Stores built room nodes keyed by room id, least-recently-used first out.
## See TECH_ARCHITECTURE.md §6.

var capacity := 3
var _order: Array[String] = []        # LRU order, most recent at the end
var _rooms: Dictionary = {}           # id -> Node3D (built room)


func has_room(id: String) -> bool:
	return _rooms.has(id)


func get_room(id: String) -> Node3D:
	if not _rooms.has(id):
		return null
	_touch(id)
	return _rooms[id]


func put(id: String, room: Node3D) -> void:
	_rooms[id] = room
	_touch(id)
	_evict_if_needed()


## Called when the player leaves a room: reset its state but keep it cached.
func on_room_exited(id: String) -> void:
	var room: Node3D = _rooms.get(id)
	if room == null:
		return
	# Canvases back to the start, slideshows stopped, cinema stopped (it saves
	# its own resume point first, Q32).
	for n in room.find_children("*", "", true, false):
		if n.has_method("reset_room"):
			n.reset_room()
	# NOTE: video resume points are saved by the cinema itself before this (Q32).


## Drop a room immediately (e.g. its template changed, or its folder changed on disk).
func remove(id: String) -> void:
	_order.erase(id)
	var node: Node3D = _rooms.get(id)
	_rooms.erase(id)
	if is_instance_valid(node):
		node.queue_free()


func set_capacity(n: int) -> void:
	capacity = maxi(1, n)
	_evict_if_needed()


func _touch(id: String) -> void:
	_order.erase(id)
	_order.push_back(id)


func _evict_if_needed() -> void:
	while _order.size() > capacity:
		var old: String = _order.pop_front()
		var node: Node3D = _rooms.get(old)
		_rooms.erase(old)
		if is_instance_valid(node):
			node.queue_free()
	# TODO(budget): also evict when the VRAM estimate exceeds the texture budget.
