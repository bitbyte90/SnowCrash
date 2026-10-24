extends Node
## Settings: a thin wrapper over ConfigFile, saved at user://settings.cfg
## (Godot maps user:// to %APPDATA%\SnowCrash on Windows because the project
## sets a custom user dir). See UX_CONTROLS.md §8 for the full settings tree.

signal setting_changed(section: String, key: String, value: Variant)

const PATH := "user://settings.cfg"

## Defaults live here so every setting has exactly one documented default.
const DEFAULTS := {
	"general": {
		"first_run_done": false,
		"world": "bare",
		"unknown_files_as": "loot",      # "themed" | "loot" | "mix"
		"videos_open_in": "cinema",      # "cinema" | "tv" | "ask"
		"show_hidden": false,
	},
	"comfort": {
		"locomotion": "both",            # "smooth" | "teleport" | "both"
		"move_speed": 2.0,
		"turn_mode": "snap",
		"snap_angle": 30,
		"vignette": "low",
		"seated": false,
		"shorten_walks": "a_bit",        # "off" | "a_bit" | "a_lot"
	},
	"controls": {
		"wrist_hand": "left",
		"mouse_sensitivity": 0.15,
	},
	"rooms": {
		"density": "normal",             # "cosy" | "normal" | "roomy"
		"slideshow_seconds": 0,          # 0 = off/manual, else 1..5 (Q2)
		"sit_before_play": true,         # Q3
		"resume_films": true,            # Q32
	},
	"audio": {
		"master": 0.8, "muted": false, "ambient": 0.6, "interface": 0.7, "media": 0.9, "notifications": 0.7,
	},
	"performance": {
		"rooms_cached": 3,               # Q33
		"texture_budget_mb": 1536,
		"canvas_resolution": 1024,
	},
	"demo": {
		"locations": [],                 # Array of {"label": String, "path": String, "kind": String}
	},
	"write_mode": {
		"unlocked": false,               # Q5: free = read-only
	},
}

var _cfg := ConfigFile.new()
var _resume := ConfigFile.new()
const RESUME_PATH := "user://resume.cfg"
## When true (e.g. command-line demo runs) nothing is written to disk.
var ephemeral := false


func _ready() -> void:
	var err := _cfg.load(PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("Settings: could not load %s (error %d); using defaults." % [PATH, err])
	_resume.load(RESUME_PATH)
	apply_audio()
	setting_changed.connect(_on_setting_changed)


func _on_setting_changed(section: String, _key: String, _value: Variant) -> void:
	if section == "audio":
		apply_audio()


## Master volume + mute on the Master bus (per-category buses come later).
func apply_audio() -> void:
	var vol := float(get_value("audio", "master", 0.8))
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(vol, 0.0001)))
	AudioServer.set_bus_mute(0, bool(get_value("audio", "muted", false)) or vol <= 0.001)


func get_value(section: String, key: String, fallback: Variant = null) -> Variant:
	var default_value: Variant = fallback
	if DEFAULTS.has(section) and DEFAULTS[section].has(key):
		default_value = DEFAULTS[section][key]
	return _cfg.get_value(section, key, default_value)


func set_value(section: String, key: String, value: Variant) -> void:
	_cfg.set_value(section, key, value)
	if not ephemeral:
		_cfg.save(PATH)
	setting_changed.emit(section, key, value)


# --- Film resume points (Q32). Keyed by a hash of the path; stored in app data. ---

func get_resume(path: String) -> float:
	return float(_resume.get_value("resume", path.to_lower().sha1_text(), 0.0))


func set_resume(path: String, seconds: float) -> void:
	_resume.set_value("resume", path.to_lower().sha1_text(), seconds)
	if not ephemeral:
		_resume.save(RESUME_PATH)
