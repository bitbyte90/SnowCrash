class_name FileClassifier
extends RefCounted
## Maps file extensions to "kinds" (ROOM_TYPES.md). Pure data, no I/O.

const KINDS := {
	"image": ["jpg", "jpeg", "png", "webp", "bmp", "tga", "svg", "gif"],
	# Known image types Godot can't decode itself -> Windows thumbnail or Polaroid (Q28)
	"image_other": ["heic", "heif", "avif", "tif", "tiff", "psd", "raw", "cr2", "cr3", "nef", "arw", "dng", "jxl", "ico"],
	"video": ["mp4", "m4v", "mkv", "webm", "mov", "avi", "wmv", "flv", "ts", "mpg", "mpeg", "ogv"],
	"audio": ["mp3", "flac", "ogg", "opus", "wav", "m4a", "aac", "wma"],
	"playlist": ["m3u", "m3u8", "pls"],
	"app": ["exe", "lnk"],
	"script": ["bat", "cmd", "ps1", "vbs", "js", "wsf", "hta", "reg", "msi", "scr", "py", "sh"],
	"document": ["pdf", "txt", "md", "rtf", "doc", "docx", "odt", "xls", "xlsx", "ods", "csv", "ppt", "pptx", "epub", "html", "htm"],
	"archive": ["zip", "7z", "rar", "tar", "gz", "cab"],
	"disc_image": ["iso", "bin", "cue", "chd", "cso", "xiso"],
	"model": ["glb", "gltf", "obj", "fbx", "blend", "stl", "3mf"],
	"subtitle": ["srt", "vtt", "ass", "ssa"],
}

## Loot-drop colours by kind (ROOM_TYPES.md §10). Always paired with an icon.
const LOOT_COLOURS := {
	"document": Color(0.30, 0.55, 1.0),
	"archive": Color(0.30, 0.85, 0.40),
	"script": Color(1.0, 0.60, 0.20),
	"app": Color(0.95, 0.25, 0.25),
	"subtitle": Color(1.0, 0.90, 0.30),
	"disc_image": Color(0.95, 0.95, 0.95),
	"unknown": Color(0.60, 0.60, 0.60),
}

static var _lookup: Dictionary = {}


static func _build() -> void:
	for kind in KINDS:
		for ext in KINDS[kind]:
			_lookup[ext] = kind


static func kind_for_ext(ext: String) -> String:
	if _lookup.is_empty():
		_build()
	return _lookup.get(ext.to_lower(), "unknown")


static func kind_for_path(path: String) -> String:
	return kind_for_ext(path.get_extension())


static func loot_colour(kind: String) -> Color:
	return LOOT_COLOURS.get(kind, LOOT_COLOURS["unknown"])
