extends Node
## SearchService: Everything (voidtools) when available, else our own index.
## Demo: es.exe CLI on a worker thread. Alpha: native Everything3 SDK client
## (named pipe "\\.\PIPE\Everything IPC", then the "1.5a" instance).
## See TECH_ARCHITECTURE.md §11. The pure logic (argument safety, output
## parsing, folder-boundary filter) lives in core/everything_cli.gd.
##
## Rules this service keeps:
##  * Results stay inside the user's chosen folders unless they turn on
##    Settings search/everything_whole_pc (off by default).
##  * If es.exe is missing, fails, or Everything isn't running, we quietly fall
##    back to the built-in search. Error text is never shown as a result.

signal results_ready(query: String, results: Array)

var es_path := ""   # path to es.exe if found
## Which backend answered the last search: "everything" or "built-in".
var backend := "built-in"
## Why Everything wasn't used on the last search ("" if it was, or wasn't tried).
var last_error := ""


func _ready() -> void:
	es_path = _detect_es()


## Windows only. Program Files first, then PATH (see EverythingCli.candidate_paths).
func _detect_es() -> String:
	if OS.get_name() != "Windows":
		return ""
	var program_dirs: Array = [OS.get_environment("ProgramFiles"), OS.get_environment("ProgramFiles(x86)")]
	for candidate in EverythingCli.candidate_paths(OS.get_environment("PATH"), program_dirs):
		if FileAccess.file_exists(candidate):
			return candidate
	return ""


func search(query: String, max_results := 200) -> void:
	if query.strip_edges() == "":
		results_ready.emit(query, [])
		return
	var roots: Array = []
	for loc in AppState.locations:
		roots.append(String(loc.get("path", "")))
	var hidden: bool = Settings.get_value("general", "show_hidden", false)
	var whole_pc: bool = Settings.get_value("search", "everything_whole_pc", false)
	var instance := String(Settings.get_value("search", "everything_instance", ""))
	WorkerThreadPool.add_task(_search_job.bind(query, max_results, roots, hidden, es_path, whole_pc, instance), true, "search")


# Runs on a worker thread: everything it needs is passed in, nothing global is touched.
func _search_job(query: String, max_results: int, roots: Array, hidden: bool, es: String, whole_pc: bool, instance: String) -> void:
	var results: Array = []
	var used := "built-in"
	var err := ""
	if es != "":
		var output: Array = []
		var args := EverythingCli.build_args(query, EverythingCli.fetch_count(max_results, not whole_pc), instance)
		var code := OS.execute(es, args, output, true)
		var parsed := EverythingCli.parse_output(output, code)
		if parsed["ok"]:
			var paths: Array = parsed["paths"]
			if not whole_pc:
				paths = EverythingCli.filter_to_roots(paths, roots)
			for p in paths:
				if results.size() >= max_results:
					break
				results.append({"name": String(p).get_file(), "path": p, "kind": "folder" if DirAccess.dir_exists_absolute(p) else FileClassifier.kind_for_ext(String(p).get_extension())})
			used = "everything"
		else:
			err = String(parsed["error"])
	if used == "built-in":
		# Built-in: walk the chosen locations only (TODO(index): use index.sqlite).
		var ns := NameSearch.new()
		ns.max_results = max_results
		ns.include_hidden = hidden
		results = ns.search(roots, query)
	# TODO(guests): filter results to shared rooms when in a shared session.
	call_deferred("_finish", query, results, used, err)


# Back on the main thread: publish which backend answered, then the results.
func _finish(query: String, results: Array, used: String, err: String) -> void:
	backend = used
	last_error = err
	results_ready.emit(query, results)
