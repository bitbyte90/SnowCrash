extends Node
## SearchService: Everything (voidtools) when available, else our own index.
## Demo: es.exe CLI on a worker thread. Alpha: native Everything3 SDK client
## (named pipe "\\.\PIPE\Everything IPC", then the "1.5a" instance).
## See TECH_ARCHITECTURE.md §11.

signal results_ready(query: String, results: Array)

var es_path := ""   # path to es.exe if found
## Which backend answered the last search: "everything" or "built-in".
var backend := "built-in"


func _ready() -> void:
	# TODO(detect): look in Program Files\Everything and PATH; offer a link if missing.
	for candidate in ["C:/Program Files/Everything/es.exe", "C:/Program Files/Everything 1.5a/es.exe"]:
		if FileAccess.file_exists(candidate):
			es_path = candidate
			break


func search(query: String, max_results := 200) -> void:
	if query.strip_edges() == "":
		results_ready.emit(query, [])
		return
	var roots: Array = []
	for loc in AppState.locations:
		roots.append(String(loc.get("path", "")))
	var hidden: bool = Settings.get_value("general", "show_hidden", false)
	backend = "everything" if es_path != "" else "built-in"
	WorkerThreadPool.add_task(_search_job.bind(query, max_results, roots, hidden), true, "search")


func _search_job(query: String, max_results: int, roots: Array, hidden: bool) -> void:
	var results: Array = []
	if es_path != "":
		var output: Array = []
		OS.execute(es_path, ["-n", str(max_results), query], output, true)
		if not output.is_empty():
			for line in String(output[0]).split("\n", false):
				var p := line.strip_edges().replace("\\", "/")
				results.append({"name": p.get_file(), "path": p, "kind": "folder" if DirAccess.dir_exists_absolute(p) else FileClassifier.kind_for_ext(p.get_extension())})
	else:
		# Built-in: walk the chosen locations only (TODO(index): use index.sqlite).
		var ns := NameSearch.new()
		ns.max_results = max_results
		ns.include_hidden = hidden
		results = ns.search(roots, query)
	# TODO(guests): filter results to shared rooms when in a shared session.
	call_deferred("emit_signal", "results_ready", query, results)
