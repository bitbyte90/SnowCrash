class_name RoomSpec
extends RefCounted
## Data-only description of a room. The generator makes these; a theme pack
## turns them into nodes. Keeping this scene-free makes generation testable.

const TEMPLATE_GALLERY := "gallery"
const TEMPLATE_CINEMA := "cinema"
const TEMPLATE_SHOP := "shop"
const TEMPLATE_MUSIC := "music"
const TEMPLATE_STUDY := "study"
const TEMPLATE_STOREROOM := "storeroom"
const TEMPLATE_MIXED := "mixed"
const TEMPLATE_HALLWAY := "hallway"   # virtual: overflow doors

var id := ""               # stable id (hash of path + virtual suffix)
var path := ""             # real folder path ("" for purely virtual rooms)
var title := ""
var template := TEMPLATE_MIXED
var layout_seed := 0             # deterministic layout per folder
var is_virtual := false

## Each canvas: { "socket": int, "images": Array[String] } (Q1 cycling)
var canvases: Array[Dictionary] = []
## Videos for the thumbnail wall / screens: Array of file dicts
var videos: Array[Dictionary] = []
## Audio, documents etc. placed as objects: { "kind", "files": Array, "grouped": bool }
var objects: Array[Dictionary] = []
## Doors: { "socket": int, "label": String, "target_path": String,
##          "target_id": String, "kind": "child"|"parent"|"hallway", "thumb": String }
var doors: Array[Dictionary] = []
## Ids of virtual rooms this room spawned (hallways)
var overflow_rooms: Array[RoomSpec] = []
var error := ""            # non-empty = locked room


func total_images() -> int:
	var n := 0
	for c in canvases:
		n += c["images"].size()
	return n


func describe() -> String:
	return "%s [%s] canvases=%d images=%d videos=%d objects=%d doors=%d overflow=%d" % [
		title, template, canvases.size(), total_images(), videos.size(),
		objects.size(), doors.size(), overflow_rooms.size()]
