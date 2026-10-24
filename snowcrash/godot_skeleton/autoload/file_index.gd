extends Node
## FileIndex: owns background scanning, the (future) SQLite index and change
## watching. Everything heavy runs on WorkerThreadPool; results come back to the
## main thread via call_deferred so the VR frame never waits on the disk.
## See TECH_ARCHITECTURE.md §4.

signal folder_scanned(path: String, data: Dictionary)
signal folder_changed(path: String)

const POLL_SECONDS := 4.0   # demo fallback watcher (TECH §4.4)

var _cache: Dictionary = {}          # normalised path -> folder data (Dictionary)
var _generation := 0                 # bumps to cancel stale jobs
var _pending: Dictionary = {}        # normalised path -> true
var _watched: Dictionary = {}        # normalised path -> last seen mtime
var _poll_timer: Timer


func _ready() -> void:
	_poll_timer = Timer.new()
	_poll_timer.wait_time = POLL_SECONDS
	_poll_timer.autostart = true
	_poll_timer.timeout.connect(_poll_watched)
	add_child(_poll_timer)
	# TODO(index): open user://index.sqlite via the godot-sqlite addon and
	# create the tables listed in TECH_ARCHITECTURE.md §4.3.


static func normalise(path: String) -> String:
	return path.replace("\\", "/").simplify_path().to_lower()


func get_cached(path: String) -> Dictionary:
	return _cache.get(normalise(path), {})


## Ask for a one-level scan. Returns immediately; listen to folder_scanned.
func request_scan(path: String, high_priority := true) -> void:
	var key := normalise(path)
	if _pending.has(key):
		return
	_pending[key] = true
	var gen := _generation
	var show_hidden: bool = Settings.get_value("general", "show_hidden", false)
	# TODO(priority): WorkerThreadPool has a high_priority flag; neighbour scans
	# should pass false so the room you are entering always wins.
	WorkerThreadPool.add_task(_scan_job.bind(path, gen, show_hidden), high_priority, "scan " + path)


## Drop all queued results (e.g. the player teleported elsewhere).
func cancel_stale() -> void:
	_generation += 1
	_pending.clear()


func watch(path: String) -> void:
	_watched[normalise(path)] = FileAccess.get_modified_time(path)


func unwatch(path: String) -> void:
	_watched.erase(normalise(path))


# --- worker thread side -------------------------------------------------------

func _scan_job(path: String, gen: int, show_hidden: bool) -> void:
	# Runs on a worker thread: no scene tree access here.
	var scanner := FileScanner.new()
	scanner.include_hidden = show_hidden
	var data := scanner.scan_folder(path)
	call_deferred("_on_scan_done", path, gen, data)


# --- main thread side ---------------------------------------------------------

func _on_scan_done(path: String, gen: int, data: Dictionary) -> void:
	var key := normalise(path)
	_pending.erase(key)
	if gen != _generation:
		return  # stale
	_cache[key] = data
	folder_scanned.emit(path, data)


func _poll_watched() -> void:
	# Demo fallback for change notifications. TODO(native): replace with a
	# ReadDirectoryChangesW GDExtension with ~1.5 s debounce.
	for key in _watched.keys():
		var mtime := FileAccess.get_modified_time(key)
		if mtime != _watched[key]:
			_watched[key] = mtime
			folder_changed.emit(key)
			Notifications.push("Something changed in %s" % key.get_file(), {"path": key})
