class_name FileScanner
extends RefCounted
## One-level, read-only folder scan. Safe to call from a worker thread
## (no scene tree access). Returns plain Dictionaries so results can cross
## threads and be cached/serialised easily. See TECH_ARCHITECTURE.md §4.2.
##
## Result shape:
## {
##   "path": String, "name": String, "ok": bool, "error": String,
##   "files":   [{ "name", "path", "ext", "kind", "size", "mtime" }],
##   "folders": [{ "name", "path" }],
## }

const SKIP_NAMES := ["$recycle.bin", "system volume information", "node_modules", ".git"]

var include_hidden := false
## Reading sizes means opening each file; off by default for speed.
## TODO(native): get sizes cheaply from FindFirstFileExW via the GDExtension.
var want_sizes := false
## Safety valve for absurd folders; the room generator caps far lower anyway.
var max_entries := 20000


func scan_folder(path: String) -> Dictionary:
	var result := {
		"path": path, "name": _display_name(path), "ok": false, "error": "",
		"files": [], "folders": [],
	}
	var dir := DirAccess.open(path)
	if dir == null:
		# Locked door with a reason, never a crash (TECH §4.2).
		result["error"] = error_string(DirAccess.get_open_error())
		return result
	dir.include_hidden = include_hidden
	dir.include_navigational = false
	if dir.list_dir_begin() != OK:
		result["error"] = "could not list folder"
		return result

	var count := 0
	var entry := dir.get_next()
	while entry != "":
		count += 1
		if count > max_entries:
			result["error"] = "truncated at %d entries" % max_entries
			break
		var full := path.path_join(entry)
		if dir.current_is_dir():
			if not (entry.to_lower() in SKIP_NAMES):
				result["folders"].append({"name": entry, "path": full})
		else:
			var ext := entry.get_extension().to_lower()
			var info := {
				"name": entry,
				"path": full,
				"ext": ext,
				"kind": FileClassifier.kind_for_ext(ext),
				"size": _size_of(full) if want_sizes else -1,
				"mtime": FileAccess.get_modified_time(full),
			}
			result["files"].append(info)
		entry = dir.get_next()
	dir.list_dir_end()

	result["folders"].sort_custom(func(a, b): return a["name"].naturalnocasecmp_to(b["name"]) < 0)
	result["files"].sort_custom(func(a, b): return a["name"].naturalnocasecmp_to(b["name"]) < 0)
	result["ok"] = true
	return result


static func _size_of(full: String) -> int:
	var f := FileAccess.open(full, FileAccess.READ)  # READ only: never WRITE
	if f == null:
		return -1
	var n := f.get_length()
	f.close()
	return n


static func _display_name(path: String) -> String:
	var trimmed := path.trim_suffix("/").trim_suffix("\\")
	var name := trimmed.get_file()
	return name if name != "" else trimmed  # drive roots like "C:"
