extends SceneTree
## Loads every .gd file to catch parse errors:
##   godot --headless --path . --script res://tests/check_all_scripts.gd

func _init() -> void:
	var bad := 0
	for p in _find("res://"):
		var s: Script = load(p)
		if s == null or not s.can_instantiate():
			print("BROKEN: ", p)
			bad += 1
		else:
			print("ok: ", p)
	print("%d broken" % bad)
	quit(1 if bad > 0 else 0)


func _find(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir_path)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir_path.path_join(f))
	for sub in d.get_directories():
		if not sub.begins_with("."):
			out.append_array(_find(dir_path.path_join(sub)))
	return out
