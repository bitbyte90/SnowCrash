class_name RoomGenerator
extends RefCounted
## Folder data (from FileScanner) -> RoomSpec. Deterministic: same folder +
## same settings = same room every visit, even though rooms reset on exit.
## Implements the core rule: every room stays bite-sized (Q9).
## See TECH_ARCHITECTURE.md §5.

## Caps per density setting (TECH §5.3). Themes may lower these further.
const CAPS := {
	"cosy":   {"canvases": 8,  "doors": 6,  "objects": 10, "video_wall": 16, "hallway_doors": 8},
	"normal": {"canvases": 12, "doors": 8,  "objects": 16, "video_wall": 24, "hallway_doors": 12},
	"roomy":  {"canvases": 20, "doors": 10, "objects": 24, "video_wall": 36, "hallway_doors": 16},
}

const DOMINANCE := 0.6   # 60% of files of one kind picks that template

var density := "normal"


func caps() -> Dictionary:
	return CAPS.get(density, CAPS["normal"])


static func id_for(path: String) -> String:
	return path.replace("\\", "/").simplify_path().to_lower().sha1_text().substr(0, 16)


## template_override: a per-folder choice remembered by the user ("Make this a cinema").
func generate(folder: Dictionary, parent_path: String = "", template_override: String = "") -> RoomSpec:
	var spec := RoomSpec.new()
	spec.path = folder.get("path", "")
	spec.title = folder.get("name", spec.path)
	spec.id = id_for(spec.path)
	spec.layout_seed = hash(spec.path.to_lower())
	if not folder.get("ok", false):
		spec.error = folder.get("error", "unreadable")
		spec.template = RoomSpec.TEMPLATE_STOREROOM
		return spec

	var by_kind := _group_by_kind(folder.get("files", []))
	spec.template = template_override if template_override != "" else choose_template(by_kind)
	var c := caps()

	# Images -> N canvases, each cycling through its share (Q1).
	var images: Array = by_kind.get("image", [])
	spec.canvases = distribute_to_canvases(images, c["canvases"])

	# Known-but-undecodable images become Polaroids (Q28), grouped on a pinboard.
	if by_kind.has("image_other"):
		spec.objects.append({"kind": "polaroid", "files": by_kind["image_other"], "grouped": by_kind["image_other"].size() > c["objects"]})

	# Videos -> thumbnail wall. Paging happens in the UI, not with more rooms.
	for v in by_kind.get("video", []):
		spec.videos.append(v)

	# Everything else -> objects, grouped into one crate per kind when over cap.
	var loose_kinds := by_kind.keys().filter(func(k): return not (k in ["image", "image_other", "video"]))
	var loose_total := 0
	for k in loose_kinds:
		loose_total += by_kind[k].size()
	for k in loose_kinds:
		var files: Array = by_kind[k]
		var grouped: bool = loose_total > c["objects"] and files.size() > 1
		spec.objects.append({"kind": k, "files": files, "grouped": grouped})

	_place_doors(spec, folder.get("folders", []), parent_path, c)
	return spec


func choose_template(by_kind: Dictionary) -> String:
	var total := 0
	for k in by_kind:
		total += by_kind[k].size()
	if total == 0:
		return RoomSpec.TEMPLATE_MIXED  # empty rooms are just lobbies of doors
	var share := func(kinds: Array) -> float:
		var n := 0
		for k in kinds:
			n += by_kind.get(k, []).size()
		return float(n) / float(total)
	if share.call(["video"]) >= DOMINANCE:
		return RoomSpec.TEMPLATE_CINEMA
	if share.call(["image", "image_other"]) >= DOMINANCE:
		return RoomSpec.TEMPLATE_GALLERY
	if share.call(["disc_image"]) >= DOMINANCE:
		return RoomSpec.TEMPLATE_SHOP  # emulator folders; launcher libraries come from MetadataService
	if share.call(["audio", "playlist"]) >= DOMINANCE:
		return RoomSpec.TEMPLATE_MUSIC
	if share.call(["document"]) >= DOMINANCE:
		return RoomSpec.TEMPLATE_STUDY
	if share.call(["unknown", "archive", "script"]) >= DOMINANCE:
		return RoomSpec.TEMPLATE_STOREROOM
	# TODO(cinema rule): one long video (>20 min) should also make a cinema;
	# needs durations from the video plugin or metadata.
	return RoomSpec.TEMPLATE_MIXED


## Canvas i shows images i, i+N, i+2N... so every canvas gets a fair share
## and neighbouring images (often a sequence) spread round the room.
static func distribute_to_canvases(images: Array, max_canvases: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var n := mini(images.size(), max_canvases)
	for i in n:
		out.append({"socket": i, "images": []})
	for idx in images.size():
		out[idx % n]["images"].append(images[idx]["path"])
	return out


func _place_doors(spec: RoomSpec, folders: Array, parent_path: String, c: Dictionary) -> void:
	var max_doors: int = c["doors"]
	var socket := 0
	# The back door is always behind the spawn point (socket -1 = "behind you").
	if parent_path != "":
		spec.doors.append({"socket": -1, "label": "Back", "target_path": parent_path, "target_id": "", "kind": "parent", "thumb": ""})

	if folders.size() <= max_doors:
		for f in folders:
			spec.doors.append(_door(socket, f))
			socket += 1
		return

	# Overflow: fill all but the last socket, then a hallway door holding the rest
	# (split into further hallways if needed). Hallways are virtual rooms.
	for i in max_doors - 1:
		spec.doors.append(_door(socket, folders[i]))
		socket += 1
	var rest := folders.slice(max_doors - 1)
	var hallway := _make_hallway(spec, rest, c)
	spec.overflow_rooms.append(hallway)
	spec.doors.append({
		"socket": socket, "label": hallway.title, "target_path": "",
		"target_id": hallway.id, "kind": "hallway", "thumb": "",
	})


func _make_hallway(owner: RoomSpec, folders: Array, c: Dictionary) -> RoomSpec:
	var h := RoomSpec.new()
	h.is_virtual = true
	h.template = RoomSpec.TEMPLATE_HALLWAY
	var first_name: String = folders[0]["name"]
	var last_name: String = folders[folders.size() - 1]["name"]
	var first := first_name.left(1).to_upper()
	var last := last_name.left(1).to_upper()
	if first == last:
		# e.g. "Folder 07" .. "Folder 29": show short names instead of "F-F"
		first = first_name.left(12)
		last = last_name.left(12)
	h.title = "More rooms (%s – %s)" % [first, last]
	h.id = (owner.id + "|hall|" + first + last).sha1_text().substr(0, 16)
	h.doors.append({"socket": -1, "label": "Back", "target_path": owner.path, "target_id": owner.id, "kind": "parent", "thumb": ""})
	var cap: int = c["hallway_doors"]
	if folders.size() <= cap:
		for i in folders.size():
			h.doors.append(_door(i, folders[i]))
	else:
		for i in cap - 1:
			h.doors.append(_door(i, folders[i]))
		var deeper := _make_hallway(h, folders.slice(cap - 1), c)
		h.overflow_rooms.append(deeper)
		h.doors.append({"socket": cap - 1, "label": deeper.title, "target_path": "", "target_id": deeper.id, "kind": "hallway", "thumb": ""})
	return h


static func _door(socket: int, folder: Dictionary) -> Dictionary:
	# TODO(thumb): user-chosen thumbnail from the index first (Q31), else the
	# first image / a video frame / a game cover found by a neighbour scan.
	return {"socket": socket, "label": folder["name"], "target_path": folder["path"], "target_id": "", "kind": "child", "thumb": ""}


static func _group_by_kind(files: Array) -> Dictionary:
	var out := {}
	for f in files:
		var k: String = f.get("kind", "unknown")
		if not out.has(k):
			out[k] = []
		out[k].append(f)
	return out
