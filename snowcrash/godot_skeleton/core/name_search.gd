class_name NameSearch
extends RefCounted
## Built-in file-name search for when Everything (es.exe) isn't installed.
## Walks only the user's chosen locations, read-only, breadth-first, with hard
## limits so a huge drive can't freeze anything. Safe on a worker thread.
## Matching: every word of the query must appear in the name (case-insensitive).

var max_results := 200
var max_visited := 50000      # files + folders looked at, in total
var max_depth := 12
var include_hidden := false


func search(roots: Array, query: String) -> Array:
	var words := query.to_lower().split(" ", false)
	var results: Array = []
	if words.is_empty():
		return results
	var queue: Array = []
	for r in roots:
		if String(r) != "":
			queue.append([String(r), 0])
	var visited := 0
	while not queue.is_empty() and results.size() < max_results and visited < max_visited:
		var item: Array = queue.pop_front()
		var dir := DirAccess.open(item[0])
		if dir == null:
			continue
		dir.include_hidden = include_hidden
		dir.include_navigational = false
		dir.list_dir_begin()
		var entry := dir.get_next()
		while entry != "":
			visited += 1
			var full := String(item[0]).path_join(entry)
			var is_dir := dir.current_is_dir()
			if is_dir and entry.to_lower() in FileScanner.SKIP_NAMES:
				entry = dir.get_next()
				continue
			if _matches(entry.to_lower(), words):
				results.append({
					"name": entry, "path": full,
					"kind": "folder" if is_dir else FileClassifier.kind_for_ext(entry.get_extension()),
				})
				if results.size() >= max_results:
					break
			if is_dir and item[1] < max_depth:
				queue.append([full, item[1] + 1])
			entry = dir.get_next()
		dir.list_dir_end()
	return results


static func _matches(name: String, words: PackedStringArray) -> bool:
	for w in words:
		if not name.contains(w):
			return false
	return true
