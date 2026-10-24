extends Node
## ThumbnailCache: makes and stores small WebP thumbnails OUTSIDE the user's
## folders (read-only rule). Disk: %LOCALAPPDATA%\SnowCrash\thumbs on Windows,
## user://thumbs elsewhere. See TECH_ARCHITECTURE.md §4.5.
##
## Tiers: 128 (doors, video tiles), 512 (canvases), FULL (2048, held/viewed;
## never written to disk). Videos use ffmpeg (if found) to grab a frame.

signal thumbnail_ready(path: String, tier: int, texture: Texture2D)
signal thumbnail_failed(path: String, tier: int)

const FULL := 2048
const GODOT_IMAGE_EXTS := ["png", "jpg", "jpeg", "webp", "bmp", "tga", "svg"]
const VIDEO_EXTS := ["mp4", "m4v", "mkv", "webm", "mov", "avi", "wmv", "flv", "ts", "mpg", "mpeg", "ogv"]
const MAX_UPLOADS_PER_FRAME := 3

var cache_dir := ""
var ffmpeg_path := ""
var _upload_queue: Array = []        # [{path, tier, image}]
var _mutex := Mutex.new()
var _memory: Dictionary = {}         # "path|tier" -> Texture2D (small LRU-ish memory cache)
var _in_flight: Dictionary = {}      # "path|tier" -> true


func _ready() -> void:
	var local := OS.get_environment("LOCALAPPDATA")
	cache_dir = (local.path_join("SnowCrash/thumbs")) if local != "" else "user://thumbs"
	DirAccess.make_dir_recursive_absolute(cache_dir)
	ffmpeg_path = _find_ffmpeg()


func _find_ffmpeg() -> String:
	# Bundled next to the app first (planned for Windows builds), then PATH.
	var beside := OS.get_executable_path().get_base_dir().path_join("ffmpeg.exe" if OS.get_name() == "Windows" else "ffmpeg")
	if FileAccess.file_exists(beside):
		return beside
	for p in ["/usr/bin/ffmpeg", "/usr/local/bin/ffmpeg", "C:/ffmpeg/bin/ffmpeg.exe"]:
		if FileAccess.file_exists(p):
			return p
	if OS.get_name() == "Windows":
		var out: Array = []
		if OS.execute("where", ["ffmpeg"], out) == 0 and not out.is_empty():
			return String(out[0]).split("\n")[0].strip_edges()
	return ""


static func key_for(path: String, size: int, mtime: int, tier: int) -> String:
	return ("%s|%d|%d|%d" % [path.to_lower(), size, mtime, tier]).sha1_text()


func cache_path_for(key: String) -> String:
	return cache_dir.path_join(key.substr(0, 2)).path_join(key + ".webp")


static func can_thumbnail(path: String) -> bool:
	var ext := path.get_extension().to_lower()
	return ext in GODOT_IMAGE_EXTS or ext in VIDEO_EXTS


## Request a thumbnail; the result arrives via thumbnail_ready (or thumbnail_failed).
func request(path: String, tier: int = 512, size: int = 0, mtime: int = -1) -> void:
	var mem_key := "%s|%d" % [path, tier]
	if _memory.has(mem_key):
		# Emit next frame so callers can connect/await consistently.
		call_deferred("emit_signal", "thumbnail_ready", path, tier, _memory[mem_key])
		return
	if _in_flight.has(mem_key):
		return
	_in_flight[mem_key] = true
	if mtime < 0:
		mtime = FileAccess.get_modified_time(path)
	var ext := path.get_extension().to_lower()
	if ext in VIDEO_EXTS and ffmpeg_path == "":
		_fail.call_deferred(path, tier)
		return
	WorkerThreadPool.add_task(_make_job.bind(path, tier, size, mtime, ffmpeg_path), false, "thumb " + path)


# --- worker thread ------------------------------------------------------------

func _make_job(path: String, tier: int, size: int, mtime: int, ffmpeg: String) -> void:
	var key := key_for(path, size, mtime, tier)
	var cached := cache_path_for(key)
	var img := Image.new()
	if tier < FULL and FileAccess.file_exists(cached) and img.load(cached) == OK:
		_queue_upload(path, tier, img)
		return
	var ext := path.get_extension().to_lower()
	var ok := false
	if ext in GODOT_IMAGE_EXTS:
		ok = img.load(path) == OK
	elif ext in VIDEO_EXTS and ffmpeg != "":
		var tmp := cache_dir.path_join("tmp_%s.png" % key)
		var abs_tmp := ProjectSettings.globalize_path(tmp)
		# Seek a couple of seconds in to skip black intro frames. (-ss before -i = fast seek)
		var args := ["-y", "-loglevel", "error", "-ss", "2", "-i", path, "-frames:v", "1", "-vf", "scale=640:-2", abs_tmp]
		OS.execute(ffmpeg, args)
		if not FileAccess.file_exists(abs_tmp):
			args[5] = "0"  # very short clip: try the first frame
			OS.execute(ffmpeg, args)
		ok = FileAccess.file_exists(abs_tmp) and img.load(abs_tmp) == OK
		DirAccess.remove_absolute(abs_tmp)
	# TODO(native): Windows shell thumbnails (IShellItemImageFactory) for PDF,
	# PSD, HEIC, RAW... until then those fail -> Polaroid / loot drop.
	if not ok or img.is_empty():
		_fail.call_deferred(path, tier)
		return
	_fit(img, tier)
	if tier < FULL:
		DirAccess.make_dir_recursive_absolute(cached.get_base_dir())
		img.save_webp(cached, true, 0.8)
	_queue_upload(path, tier, img)


static func _fit(img: Image, tier: int) -> void:
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	var longest := maxi(w, h)
	if longest > tier:
		var s := float(tier) / float(longest)
		img.resize(maxi(1, int(w * s)), maxi(1, int(h * s)), Image.INTERPOLATE_LANCZOS)
	img.generate_mipmaps()


func _queue_upload(path: String, tier: int, img: Image) -> void:
	_mutex.lock()
	_upload_queue.push_back({"path": path, "tier": tier, "image": img})
	_mutex.unlock()


# --- main thread --------------------------------------------------------------

func _fail(path: String, tier: int) -> void:
	_in_flight.erase("%s|%d" % [path, tier])
	thumbnail_failed.emit(path, tier)


func _process(_delta: float) -> void:
	# Upload throttle: GPU uploads happen on the main thread, a few per frame,
	# so walking into a big gallery never causes a hitch (TECH §6.3).
	var uploads := 0
	while uploads < MAX_UPLOADS_PER_FRAME:
		_mutex.lock()
		var job: Variant = _upload_queue.pop_front() if not _upload_queue.is_empty() else null
		_mutex.unlock()
		if job == null:
			break
		var tex := ImageTexture.create_from_image(job["image"])
		var mem_key := "%s|%d" % [job["path"], job["tier"]]
		_in_flight.erase(mem_key)
		if job["tier"] < FULL:
			_memory[mem_key] = tex
			if _memory.size() > 400:  # TODO(budget): real VRAM accounting (TECH §6.2)
				_memory.erase(_memory.keys()[0])
		thumbnail_ready.emit(job["path"], job["tier"], tex)
		uploads += 1
