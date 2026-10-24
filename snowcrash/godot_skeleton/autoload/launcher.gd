extends Node
## Launcher: the ONLY place that opens or launches anything (TECH §9).
## Rules: never launch on pick-up; confirm first launch; no scripts in free
## mode; never elevate. Godot's create_process has no working directory, so a
## native ShellExecuteExW helper is planned for games that need one.

signal confirmation_needed(path: String, reason: String)
signal launched(path: String)
## Human-readable feedback for the HUD ("Opened in Windows", "stubbed on Linux"...)
signal message(text: String)

const BLOCKED_SCRIPT_EXTS := [
	"bat", "cmd", "ps1", "psm1", "vbs", "vbe", "js", "jse", "wsf", "wsh", "hta", "reg", "msi", "scr",
	"com", "pif", "cpl", "msc", "jar", "py", "pyw", "inf", "scf", "application", "appref-ms",
]
## Run something else (a program or a shortcut that could point anywhere): ask first.
const ASK_FIRST_EXTS := ["exe", "lnk", "url"]

var _allowed: Dictionary = {}   # path -> true once the user said "always allow"


func open_in_windows(path: String) -> void:
	if path == "":
		return
	var ext := path.get_extension().to_lower()
	if ext in BLOCKED_SCRIPT_EXTS:
		confirmation_needed.emit(path, "Script files aren't run from VR. Use Show in folder instead.")
		return
	if ext in ASK_FIRST_EXTS and not _allowed.has(path):
		var what := "program" if ext == "exe" else "shortcut"
		confirmation_needed.emit(path, "Run this %s? It will open on your desktop, outside Snow Crash." % what)
		return
	# TODO(motw): check the Zone.Identifier stream and warn for downloaded files.
	if OS.get_name() != "Windows":
		# The demo targets Windows; elsewhere we only say what would happen.
		message.emit("[stub on %s] Would open in Windows: %s" % [OS.get_name(), path.get_file()])
		return
	var err := OS.shell_open(path)
	if err == OK:
		launched.emit(path)
		message.emit("Opened on your desktop: %s" % path.get_file())


func confirm_and_open(path: String, always_allow: bool) -> void:
	if path.get_extension().to_lower() in BLOCKED_SCRIPT_EXTS:
		return   # never, even if asked
	if always_allow:
		_allowed[path] = true
	if OS.get_name() != "Windows":
		message.emit("[stub on %s] Would run: %s" % [OS.get_name(), path.get_file()])
		return
	var err := OS.shell_open(path)
	if err == OK:
		launched.emit(path)
		message.emit("Started on your desktop: %s" % path.get_file())


func show_in_folder(path: String) -> void:
	if path == "":
		return
	if OS.get_name() != "Windows":
		message.emit("[stub on %s] Would show in Explorer: %s" % [OS.get_name(), path])
		return
	OS.shell_show_in_file_manager(path, true)


## Games go through their launcher so DRM/overlays/playtime all work.
## e.g. "steam://rungameid/620", "playnite://playnite/start/<guid>".
func launch_uri(uri: String) -> void:
	# TODO(confirm): first-launch confirmation per game.
	OS.shell_open(uri)
