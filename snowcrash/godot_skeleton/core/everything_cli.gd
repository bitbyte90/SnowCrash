class_name EverythingCli
extends RefCounted
## Pure helpers for talking to Everything (voidtools) through es.exe.
## No file, process or Settings access in here, so every function can be unit
## tested headless on any OS (see tests/run_core_tests.gd, test_everything_cli).
## SearchService does the actual OS.execute and uses these to stay safe:
##   * the query can never be read by es.exe as a command-line switch,
##   * error text from es.exe is never shown as if it were a search result,
##   * results stay inside the folders the user chose (privacy boundary),
##   * es.exe is looked for in the real Program Files folders, then PATH.

const MAX_FETCH := 2000   # hard cap on how many rows we ask es.exe for


## Make a user query safe to pass as ONE argv element to es.exe.
## es.exe treats an argument that starts with "-" (or "/") as a switch, e.g.
## "-export-txt" or "-instance". We drop those leading characters and any
## double quotes (quotes can break Windows command-line quoting). Everything's
## own search syntax (spaces, *, !, |, ext:) is left alone.
static func sanitize_query(query: String) -> String:
	var q := query.replace("\"", "").strip_edges()
	while q != "" and (q[0] == "-" or q[0] == "/" or q[0] == " "):
		q = q.substr(1)
	return q


## argv for es.exe. `fetch` is how many rows to ask for (clamped 1..MAX_FETCH).
## `instance` is "" (default) or e.g. "1.5a" for the Everything 1.5 alpha.
static func build_args(query: String, fetch: int, instance := "") -> PackedStringArray:
	var args := PackedStringArray(["-n", str(clampi(fetch, 1, MAX_FETCH))])
	if instance != "":
		args.append_array(PackedStringArray(["-instance", instance]))
	args.append(sanitize_query(query))
	return args


## How many rows to request so that, after dropping results outside the chosen
## folders, we can still fill `want` results. Whole-PC mode needs no extra.
static func fetch_count(want: int, scoped: bool) -> int:
	return clampi(want * (5 if scoped else 1), 1, MAX_FETCH)


## Turn the raw OS.execute output into paths, or an error.
## Returns {"ok": bool, "error": String, "paths": Array[String]}.
## es.exe reports problems as plain text ("Error 8: Everything IPC not found...")
## and the demo asked OS.execute to merge stderr into the output, so a failed
## run used to look like a result with a bogus path.
static func parse_output(output: Array, exit_code: int) -> Dictionary:
	var text := ""
	for chunk in output:
		text += String(chunk)
	var lines: Array = []
	for raw in text.split("\n", false):
		var line := String(raw).strip_edges()
		if line != "":
			lines.append(line)
	if exit_code != 0:
		var why: String = lines[0] if not lines.is_empty() else "es.exe exited with code %d" % exit_code
		return {"ok": false, "error": why, "paths": []}
	if not lines.is_empty() and _looks_like_error(lines[0]):
		return {"ok": false, "error": lines[0], "paths": []}
	var paths: Array = []
	for line in lines:
		paths.append(normalise_path(line))
	return {"ok": true, "error": "", "paths": paths}


static func _looks_like_error(line: String) -> bool:
	# es.exe prints "Error <number>: <message>". A real result is a path, which
	# can't start with the word Error followed by a digit and a colon.
	var re := RegEx.new()
	re.compile("^Error\\s+\\d+\\s*:")
	return re.search(line) != null


## Forward slashes, no trailing slash (except a bare drive root like "C:/").
static func normalise_path(p: String) -> String:
	var s := p.strip_edges().replace("\\", "/")
	while s.length() > 1 and s.ends_with("/") and not (s.length() == 3 and s[1] == ":"):
		s = s.substr(0, s.length() - 1)
	return s


## True when `path` is one of the chosen folders or inside one. Case-insensitive
## (Windows paths) and boundary-safe: "C:/Pics" does NOT contain "C:/PicsEvil".
## An empty roots list means "nothing chosen yet", so nothing is allowed.
static func is_under_roots(path: String, roots: Array) -> bool:
	var p := normalise_path(path).to_lower()
	for r in roots:
		var root := normalise_path(String(r)).to_lower()
		if root == "":
			continue
		if p == root:
			return true
		var prefix := root if root.ends_with("/") else root + "/"
		if p.begins_with(prefix):
			return true
	return false


static func filter_to_roots(paths: Array, roots: Array) -> Array:
	var out: Array = []
	for p in paths:
		if is_under_roots(String(p), roots):
			out.append(p)
	return out


## Where to look for es.exe, most trusted first: the real Program Files folders
## (so a planted es.exe earlier on PATH can't win), then each PATH folder.
## `program_dirs` = values of %ProgramFiles% and %ProgramFiles(x86)%.
static func candidate_paths(env_path: String, program_dirs: Array) -> Array:
	var out: Array = []
	for pf in program_dirs:
		var base := normalise_path(String(pf))
		if base == "":
			continue
		for folder in ["Everything", "Everything 1.5a"]:
			_add_unique(out, base + "/" + folder + "/es.exe")
	for d in env_path.split(";", false):
		var dir := normalise_path(String(d).replace("\"", ""))
		if dir != "":
			_add_unique(out, dir + "/es.exe")
	return out


static func _add_unique(list: Array, item: String) -> void:
	if not list.has(item):
		list.append(item)
