extends SceneTree
## Headless smoke tests for core/ (no VR needed):
##   godot --headless --path . --script res://tests/run_core_tests.gd
## TODO: move to GUT or gdUnit4 once the project grows.

var failures := 0


func _init() -> void:
	test_classifier()
	test_canvas_distribution()
	test_generator_gallery_and_overflow()
	test_generator_cinema()
	test_route()
	test_scanner_on_temp_tree()
	test_round2_generator()
	test_name_search()
	test_everything_cli()
	print("\n%s (%d failure(s))" % ["ALL PASSED" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		failures += 1
		print("  FAIL ", what)


func fake_folder(path: String, images: int, videos: int, folders: int, other: int = 0) -> Dictionary:
	var files: Array = []
	for i in images:
		files.append({"name": "img%03d.jpg" % i, "path": path + "/img%03d.jpg" % i, "ext": "jpg", "kind": "image"})
	for i in videos:
		files.append({"name": "vid%02d.mp4" % i, "path": path + "/vid%02d.mp4" % i, "ext": "mp4", "kind": "video"})
	for i in other:
		files.append({"name": "doc%02d.xyz" % i, "path": path + "/doc%02d.xyz" % i, "ext": "xyz", "kind": "unknown"})
	var subs: Array = []
	for i in folders:
		subs.append({"name": "Folder %02d" % i, "path": path + "/Folder %02d" % i})
	return {"path": path, "name": path.get_file(), "ok": true, "error": "", "files": files, "folders": subs}


func test_classifier() -> void:
	print("classifier")
	check(FileClassifier.kind_for_ext("JPG") == "image", "JPG is an image")
	check(FileClassifier.kind_for_ext("heic") == "image_other", "HEIC is a Polaroid-type image")
	check(FileClassifier.kind_for_ext("mkv") == "video", "MKV is a video")
	check(FileClassifier.kind_for_ext("weird") == "unknown", "unknown stays unknown")


func test_canvas_distribution() -> void:
	print("canvas distribution (Q1)")
	var imgs: Array = []
	for i in 500:
		imgs.append({"path": "p%d" % i})
	var canv := RoomGenerator.distribute_to_canvases(imgs, 12)
	check(canv.size() == 12, "500 images -> 12 canvases")
	var total := 0
	var smallest := 9999
	var largest := 0
	for c in canv:
		total += c["images"].size()
		smallest = mini(smallest, c["images"].size())
		largest = maxi(largest, c["images"].size())
	check(total == 500, "every image appears exactly once")
	check(largest - smallest <= 1, "shares are fair (41-42 each)")
	check(canv[1]["images"][0] == "p1" and canv[1]["images"][1] == "p13", "canvas i cycles i, i+N, ...")


func test_generator_gallery_and_overflow() -> void:
	print("room generator: gallery + door overflow")
	var gen := RoomGenerator.new()
	var spec := gen.generate(fake_folder("D:/Webrips/SiteA/Images", 500, 0, 30), "D:/Webrips/SiteA")
	check(spec.template == RoomSpec.TEMPLATE_GALLERY, "mostly images -> gallery")
	check(spec.canvases.size() == 12, "capped at 12 canvases (normal density)")
	var child_doors := spec.doors.filter(func(d): return d["kind"] == "child")
	var hall_doors := spec.doors.filter(func(d): return d["kind"] == "hallway")
	var back_doors := spec.doors.filter(func(d): return d["kind"] == "parent")
	check(child_doors.size() == 7 and hall_doors.size() == 1, "8 sockets: 7 doors + 1 hallway door")
	check(back_doors.size() == 1, "back door to the parent exists")
	check(spec.overflow_rooms.size() == 1, "one hallway room generated")
	var hall: RoomSpec = spec.overflow_rooms[0]
	var hall_children := hall.doors.filter(func(d): return d["kind"] == "child").size()
	check(hall_children == 11 and hall.overflow_rooms.size() == 1, "hallway holds 11 + a deeper hallway for the rest")
	print("    ", spec.describe())
	print("    ", hall.describe())


func test_generator_cinema() -> void:
	print("room generator: cinema + grouping")
	var gen := RoomGenerator.new()
	var spec := gen.generate(fake_folder("D:/Webrips/SiteA/Videos", 2, 40, 0, 30), "")
	check(spec.template == RoomSpec.TEMPLATE_MIXED, "40 videos + 30 unknown + 2 images is mixed (56% video)")
	var spec2 := gen.generate(fake_folder("D:/Films", 0, 12, 2), "D:/")
	check(spec2.template == RoomSpec.TEMPLATE_CINEMA, "mostly videos -> cinema")
	check(spec2.videos.size() == 12, "all videos on the thumbnail wall")
	var grouped := spec.objects.filter(func(o): return o["grouped"]).size()
	check(grouped >= 1, "30 unknown files grouped into a crate")
	var locked := gen.generate({"path": "C:/Locked", "ok": false, "error": "Permission denied"})
	check(locked.error != "", "unreadable folder -> locked room, no crash")


func test_route() -> void:
	print("route planner (Q22)")
	var r := RoutePlanner.tree_route("D:/Webrips/SiteA/Images/2019", "D:/Webrips/SiteB/Videos")
	check(r[0] == "D:/Webrips/SiteA/Images/2019" and r[-1] == "D:/Webrips/SiteB/Videos", "route starts and ends right")
	check(r.has("D:/Webrips"), "route passes through the common ancestor")
	print("    ", " -> ".join(r))
	var r2 := RoutePlanner.tree_route("C:/Users", "D:/Films")
	check(r2.has("This PC"), "different drives route via the world")
	var rp := RoutePlanner.new()
	var hidden: Array[int] = [5]
	var sc := rp.pick_shortcut(r, 0, hidden)
	check(not sc.is_empty() and sc["socket"] == 5, "a hidden socket can become a shortcut door")
	rp.shorten = RoutePlanner.Shorten.OFF
	check(rp.pick_shortcut(r, 0, hidden).is_empty(), "shortening off -> no shortcuts")


func test_scanner_on_temp_tree() -> void:
	print("file scanner (read-only) on a temp tree")
	var root := OS.get_cache_dir().path_join("snowcrash_test_tree")
	DirAccess.make_dir_recursive_absolute(root.path_join("Sub A"))
	DirAccess.make_dir_recursive_absolute(root.path_join("sub b"))
	for n in ["a.jpg", "b.MP4", "c.zip", "日本語.png"]:
		var f := FileAccess.open(root.path_join(n), FileAccess.WRITE)  # test fixture only
		f.store_string("x")
		f.close()
	var data: Dictionary = FileScanner.new().scan_folder(root)
	check(data["ok"], "scan ok")
	check(data["folders"].size() == 2, "2 subfolders")
	check(data["files"].size() == 4, "4 files incl. a Japanese name")
	var kinds := {}
	for f in data["files"]:
		kinds[f["kind"]] = true
	check(kinds.has("image") and kinds.has("video") and kinds.has("archive"), "kinds classified")
	var missing: Dictionary = FileScanner.new().scan_folder(root.path_join("nope"))
	check(not missing["ok"] and missing["error"] != "", "missing folder reports an error")


func test_round2_generator() -> void:
	print("round 2: ids, overrides, demo formats")
	check(RoomGenerator.id_for("D:\\Films") == RoomGenerator.id_for("d:/films/"), "room id ignores slashes, case and trailing /")
	check(RoomGenerator.id_for("D:/Films") != RoomGenerator.id_for("D:/Films2"), "different folders get different ids")
	var gen := RoomGenerator.new()
	var folder := fake_folder("D:/Webrips/SiteA/Images", 40, 1, 0)
	check(gen.generate(folder, "").template == RoomSpec.TEMPLATE_GALLERY, "picture folder defaults to a gallery")
	check(gen.generate(folder, "", RoomSpec.TEMPLATE_CINEMA).template == RoomSpec.TEMPLATE_CINEMA, "'make this a cinema' override wins")
	check(FileClassifier.kind_for_ext("ogv") == "video", ".ogv is a video (plays for real in the demo)")
	var big := gen.generate(fake_folder("D:/Old Forum/Threads", 0, 0, 30), "D:/Old Forum")
	var hall_door: Array = big.doors.filter(func(d): return d["kind"] == "hallway")
	check(hall_door.size() == 1 and String(hall_door[0].get("label", "")).contains("Folder"), "hallway door says which folders are inside")
	var empty := gen.generate(fake_folder("D:/Empty", 0, 0, 0), "D:/")
	check(empty.canvases.is_empty() and empty.doors.size() == 1, "empty folder -> just a back door, no crash")


func test_name_search() -> void:
	print("round 3: built-in name search (read-only, chosen places only)")
	var root := OS.get_cache_dir().path_join("snowcrash_search_tree")
	for d in ["Photos/2019 Night", "Photos/Beach", "Films", "node_modules/night"]:
		DirAccess.make_dir_recursive_absolute(root.path_join(d))
	for f in ["Photos/2019 Night/night_sky_01.jpg", "Photos/Beach/sunset.png", "Films/Night Drive.ogv", "node_modules/night/x.js"]:
		var fa := FileAccess.open(root.path_join(f), FileAccess.WRITE)  # test fixture only
		fa.store_string("x")
		fa.close()
	var ns := NameSearch.new()
	var r: Array = ns.search([root], "night")
	var names: Array = r.map(func(x): return x["name"])
	check(names.has("2019 Night") and names.has("night_sky_01.jpg") and names.has("Night Drive.ogv"), "finds folders and files, case-insensitive")
	check(not names.has("x.js") and not names.has("night") , "skips node_modules and friends")
	check(ns.search([root], "night drive")[0]["name"] == "Night Drive.ogv", "every word must match")
	check(ns.search([root], "zzz").is_empty(), "no match -> empty, no crash")
	ns.max_results = 1
	check(ns.search([root], "n").size() == 1, "result cap is respected")
	var kinds: Array = ns.search([root.path_join("Films")], "drive").map(func(x): return x["kind"])
	check(kinds == ["video"], "results carry a kind for icons")


func test_everything_cli() -> void:
	print("round 4: Everything (es.exe) helpers: safe args, parsing, folder boundary")
	# --- query hardening: a query can never become an es.exe switch ---
	check(EverythingCli.sanitize_query("-export-txt") == "export-txt", "leading '-' stripped (no switch injection)")
	check(EverythingCli.sanitize_query("  /instance 1.5a") == "instance 1.5a", "leading '/' and spaces stripped")
	check(EverythingCli.sanitize_query("night \"drive\"") == "night drive", "double quotes removed")
	check(EverythingCli.sanitize_query("ext:jpg !thumbs night-sky") == "ext:jpg !thumbs night-sky", "Everything syntax and inner '-' kept")
	var a := EverythingCli.build_args("-bad", 50)
	check(a == PackedStringArray(["-n", "50", "bad"]), "args: -n <count> then the query last")
	check(EverythingCli.build_args("x", 50, "1.5a") == PackedStringArray(["-n", "50", "-instance", "1.5a", "x"]), "args: 1.5a instance")
	check(EverythingCli.build_args("x", 999999)[1] == "2000", "fetch count is capped")
	check(EverythingCli.fetch_count(200, true) == 1000 and EverythingCli.fetch_count(200, false) == 200, "scoped search over-fetches 5x, whole-PC does not")
	# --- output parsing: errors are never results ---
	var ok := EverythingCli.parse_output(["C:\\Pics\\a.jpg\r\nD:\\Films\\b.ogv\r\n"], 0)
	check(ok["ok"] and ok["paths"] == ["C:/Pics/a.jpg", "D:/Films/b.ogv"], "CRLF output -> forward-slash paths")
	var e1 := EverythingCli.parse_output(["Error 8: Everything IPC not found. Please make sure Everything is running.\n"], 0)
	check(not e1["ok"] and e1["paths"].is_empty(), "'Error 8' text with exit 0 is an error, not a result")
	var e2 := EverythingCli.parse_output(["boom"], 8)
	check(not e2["ok"] and e2["error"] == "boom", "non-zero exit is an error and keeps the message")
	check(not EverythingCli.parse_output([], 1)["ok"], "non-zero exit with no output is still an error")
	var none := EverythingCli.parse_output([""], 0)
	check(none["ok"] and none["paths"].is_empty(), "no matches -> ok and empty (no fallback needed)")
	check(EverythingCli.parse_output(["C:\\Error 8 notes.txt"], 0)["ok"], "a real path containing the word Error is not an error")
	# --- folder boundary (privacy) ---
	var roots := ["C:\\Users\\bit\\Pics", "D:/Films/"]
	check(EverythingCli.is_under_roots("C:/Users/bit/Pics/a.jpg", roots), "file inside a chosen folder is allowed")
	check(EverythingCli.is_under_roots("c:\\users\\BIT\\pics", roots), "the chosen folder itself, any case/slashes, is allowed")
	check(EverythingCli.is_under_roots("D:/Films/Sub/x.mkv", roots), "trailing slash on a root is fine")
	check(not EverythingCli.is_under_roots("C:/Users/bit/PicsEvil/a.jpg", roots), "sibling with the same prefix is NOT allowed")
	check(not EverythingCli.is_under_roots("C:/Windows/system32/x.dll", roots), "outside the chosen folders is NOT allowed")
	check(not EverythingCli.is_under_roots("C:/anything", []), "no chosen folders -> nothing allowed")
	check(not EverythingCli.is_under_roots("C:/anything", [""]), "blank root never matches")
	check(EverythingCli.filter_to_roots(["D:/Films/a", "E:/Secret/b", "D:/Films"], roots) == ["D:/Films/a", "D:/Films"], "filter keeps only allowed paths, in order")
	check(EverythingCli.is_under_roots("C:/x", ["C:/"]), "a whole-drive root allows the drive")
	# --- finding es.exe ---
	var c := EverythingCli.candidate_paths("C:\\Tools;;\"D:\\bin\"", ["C:\\Program Files", "", "C:\\Program Files (x86)"])
	check(c[0] == "C:/Program Files/Everything/es.exe" and c[1] == "C:/Program Files/Everything 1.5a/es.exe", "Program Files checked first")
	check(c.find("C:/Tools/es.exe") > c.find("C:/Program Files (x86)/Everything 1.5a/es.exe"), "PATH folders come after Program Files")
	check(c.has("D:/bin/es.exe") and not c.has("/es.exe"), "quoted PATH entry handled, empty entries skipped")
	check(EverythingCli.candidate_paths("", []).is_empty(), "nothing set -> no candidates, no crash")
