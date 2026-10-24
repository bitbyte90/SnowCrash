class_name RoutePlanner
extends RefCounted
## Guided walks and path shortening (Q22). See TECH_ARCHITECTURE.md §5.6.
## The real route is the folder-tree path: up to the common ancestor, then down.
## Shortening re-targets doors the player CAN'T see so later rooms are skipped.

enum Shorten { OFF, A_BIT, A_LOT }

var shorten := Shorten.A_BIT


static func split(path: String) -> PackedStringArray:
	return path.replace("\\", "/").trim_suffix("/").split("/", false)


## Returns the list of folder paths you walk through, from `from` to `to`.
static func tree_route(from: String, to: String) -> Array[String]:
	var a := split(from)
	var b := split(to)
	var common := 0
	while common < a.size() and common < b.size() and a[common].to_lower() == b[common].to_lower():
		common += 1
	var route: Array[String] = []
	# Up from `from` to the common ancestor.
	for i in range(a.size() - 1, common - 1, -1):
		route.append("/".join(a.slice(0, i + 1)))
	if common > 0:
		route.append("/".join(a.slice(0, common)))
	elif a.size() > 0 and b.size() > 0:
		route.append("This PC")  # different drives: go via the world outside
	# Down to `to`.
	for i in range(common, b.size()):
		route.append("/".join(b.slice(0, i + 1)))
	# Remove consecutive duplicates.
	var clean: Array[String] = []
	for r in route:
		if clean.is_empty() or clean[-1] != r:
			clean.append(r)
	return clean


## How many rooms of the remaining route a shortcut door may skip.
func max_skip() -> int:
	match shorten:
		Shorten.OFF:
			return 0
		Shorten.A_BIT:
			return 1
		_:
			return 3


## Decide where a hidden door should lead. `visible_sockets` comes from the
## room's visibility test (frustum + occlusion); doors the player can see, or
## is within 3 m of, are never changed. The back door is never changed.
func pick_shortcut(route: Array[String], current_index: int, free_hidden_sockets: Array[int]) -> Dictionary:
	if max_skip() == 0 or free_hidden_sockets.is_empty():
		return {}
	var target_index := mini(current_index + 1 + max_skip(), route.size() - 1)
	if target_index <= current_index + 1:
		return {}
	return {"socket": free_hidden_sockets[0], "target_path": route[target_index]}
	# TODO(feel): keep walks feeling like a journey; never shortcut the final room.
