extends Node
## Scripted screenshot tour: drives the real demo (no fakes) and saves PNGs.
##   godot --path . --rendering-method gl_compatibility -- --flat \
##     --root=/tmp/snowcrash_fixture/Webrips --root=/tmp/snowcrash_fixture/Films \
##     --tour=/path/to/screenshots
## Use the museum set with: --world=museum --tour-set=museum
## Works under Xvfb (software OpenGL), so it can run on a headless box.

var main: Node
var out_dir := ""
var tour_set := "demo"
var shots: Array[String] = []


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	await _wait(1.0)
	match tour_set:
		"museum":
			await _museum_tour()
		"island":
			await _island_tour()
		"city":
			await _city_tour()
		"wrist":
			await _wrist_tour()
		"vr":
			await _vr_tour()
		_:
			await _demo_tour()
	print("TOUR DONE: %d screenshots in %s" % [shots.size(), out_dir])
	get_tree().quit()


# --- helpers ------------------------------------------------------------------

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := out_dir.path_join(name + ".png")
	img.save_png(path)
	shots.append(path)
	print("  shot: ", path)


func _flat() -> CharacterBody3D:
	return main.rig.flat


## Go to a folder and wait until we've arrived and things have loaded.
func _go(path: String, settle := 2.5) -> void:
	var done := [false]
	main.rooms.arrived.connect(func(_p, _y, _t): done[0] = true, CONNECT_ONE_SHOT)
	main.rooms.go_folder(path)
	var t := 0.0
	while not done[0] and t < 10.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	await _wait(settle)


func _go_lobby(settle := 2.0) -> void:
	main.rooms.go_lobby()
	await _wait(settle)


func _room() -> Node3D:
	return main.rooms.current_room()


## Place the camera at a room-local position and look at a room-local point.
func _place(local_pos: Vector3, local_look: Vector3) -> void:
	var r := _room()
	var origin: Vector3 = r.global_position if r else Vector3.ZERO
	_flat().global_position = origin + local_pos
	_flat().velocity = Vector3.ZERO
	await get_tree().physics_frame
	_flat().look_at_point(origin + local_look)
	await get_tree().process_frame


func _find(pred: Callable) -> Array:
	var r := _room()
	return [] if r == null else r.find_children("*", "", true, false).filter(pred)


func _canvases() -> Array:
	return _find(func(n): return n.has_method("next_image"))


func _seat_bodies() -> Array:
	return _find(func(n): return n is StaticBody3D and n.has_meta("sc_item") and (n.get_meta("sc_item") as Dictionary).get("kind", "") == "seat")


# --- the demo tour ------------------------------------------------------------

func _demo_tour() -> void:
	var webrips: String = AppState.locations[0]["path"]
	var films: String = AppState.locations[1]["path"] if AppState.locations.size() > 1 else ""
	# 1. Outside: the one building + tutorial signs.
	_flat().set_view(0, 2)
	await _wait(1.0)
	await _shot("01_outside_spawn")
	_flat().global_position = Vector3(0.3, 0, 9.4)
	_flat().look_at_point(Vector3(-2.6, 1.5, 7.0))
	await _wait(0.3)
	await _shot("02_tutorial_sign")
	_flat().global_position = Vector3(0, 0, 0.4)
	_flat().look_at_point(Vector3(0, 2.2, -4))
	await _wait(0.3)
	await _shot("03_building_entrance")

	# 2. Lobby: one door per chosen folder.
	await _go_lobby(2.5)
	await _place(Vector3(0, 0, 4.6), Vector3(0, 1.5, -7))
	await _shot("04_lobby_doors")

	# 3. Webrips: a door per website, each with a thumbnail and counts.
	await _go(webrips, 3.0)
	await _place(Vector3(0, 0, 1.5), Vector3(0, 1.5, -7))
	await _shot("05_webrips_site_doors")

	# 4. A site room: loose files as loot drops, Images/Videos doors.
	await _go(webrips.path_join("Aurora Photos"), 2.5)
	await _place(Vector3(0, 0, 3.6), Vector3(0, 0.7, -3))
	await _shot("06_site_room_loot_drops")

	# 5. Gallery: 18 images on 12 canvases, doors to subfolders.
	await _go(webrips.path_join("Aurora Photos/Images"), 3.0)
	await _place(Vector3(0, 0, 4.6), Vector3(0, 1.6, -7))
	await _shot("07_gallery_room")
	await _place(Vector3(0, 0, -2.0), Vector3(0, 1.3, 7))
	await _shot("08_gallery_subfolder_doors")

	# 6. Big folder: 130 images -> 12 canvases each cycling ~11 images (Q1/Q2).
	await _go(webrips.path_join("Aurora Photos/Images/2019"), 3.0)
	main.rooms.set_slideshow(1)
	await _place(Vector3(-2.5, 0, 3.0), Vector3(-1.0, 1.7, -7))
	await _wait(0.5)
	await _shot("09a_big_folder_cycling")
	await _wait(2.4)
	await _shot("09b_big_folder_cycling_2s_later")
	main.rooms.set_slideshow(0)

	# 7. Point at a canvas, open the bag, then Info and View.
	var cvs := _canvases()
	if cvs.size() > 2:
		var target: Node3D = cvs[2]
		_flat().global_position = target.global_position + Vector3(0, -1.65, 3.2) - Vector3(0, target.global_position.y - 1.75, 0) * 0.0
		_flat().global_position.y = _room().global_position.y
		await get_tree().physics_frame
		_flat().look_at_point(target.global_position)
		await _wait(0.5)
		await _shot("10_pointing_at_canvas")
		main.open_bag_for_pointed()
		await _wait(0.3)
		await _shot("11_bag_radial_menu")
		main.bag.choose("info")
		await _wait(0.3)
		await _shot("12_bag_info_panel")
		main.hud.hide_overlays()
		main.open_bag_for_pointed()
		main.bag.choose("show_path")
		main.open_bag_for_pointed()
		main.bag.choose("open_in_windows")
		await _wait(0.3)
		await _shot("13_show_path_and_open_stub_toasts")
		main.open_bag_for_pointed()
		main.bag.choose("view")
		await _wait(1.5)
		await _shot("14_full_size_view")
		main.hud.hide_overlays()
		main.rig.set_input_enabled(true)

	# 8. Teleport menu.
	main.teleport.open()
	main.teleport.select_label_containing("Webrips")
	await _wait(0.3)
	await _shot("15_teleport_menu")
	main.teleport.show_folder(webrips)
	main.teleport.select_label_containing("Old Forum")
	await _wait(0.3)
	await _shot("16_teleport_menu_drilled_in")
	main.teleport.close()

	# 9. Overflow: 15 subfolders -> 7 doors + a "More rooms" hallway door.
	await _go(webrips.path_join("Old Forum/Threads"), 3.0)
	await _place(Vector3(0, 0, 0.5), Vector3(0, 1.4, -7))
	await _shot("17_overflow_hallway_door")
	var halls: Array = main.rooms.current_spec.doors.filter(func(d): return d["kind"] == "hallway")
	if not halls.is_empty():
		var done := [false]
		main.rooms.arrived.connect(func(_p, _y, _t): done[0] = true, CONNECT_ONE_SHOT)
		main.rooms._door_cooldown = 0.0
		main.rooms.use_door(halls[0])
		await _wait(3.0)
		await _place(Vector3(0, 0, 9.0), Vector3(0, 1.4, -11))
		await _shot("18_hallway_room")

	# 10. Odd names, a Polaroid (HEIC we can't decode) and a grey loot drop.
	var seaside := ""
	for f in FileScanner.new().scan_folder(webrips)["folders"]:
		if String(f["name"]).begins_with("Seaside"):
			seaside = f["path"]
	if seaside != "":
		await _go(seaside, 3.0)
		await _place(Vector3(0, 0, 4.2), Vector3(-2.5, 0.8, -2))
		await _shot("19_polaroid_and_unknown_file")

	# 11. Cinema: thumbnail wall, sit, Play appears, real .ogv playback, resume, stub.
	await _go(webrips.path_join("Aurora Photos/Videos"), 3.0)
	await _place(Vector3(0, 0, 5.8), Vector3(0, 2.0, -7))
	await _shot("20_cinema_room")
	await _place(Vector3(-3.5, 0, -2.0), Vector3(-8, 2.0, -3.2))
	await _shot("21_cinema_thumbnail_wall")
	var cinema: Node = _room().get_node_or_null("Cinema")
	var seats := _seat_bodies()
	if cinema and seats.size() > 5:
		var ogv: Dictionary = {}
		var mp4: Dictionary = {}
		for v in cinema.videos:
			if String(v["path"]).ends_with(".ogv"):
				ogv = v
			elif mp4.is_empty():
				mp4 = v
		cinema.select(ogv)
		await _wait(0.8)
		cinema.sit(seats[5])
		await _wait(0.3)
		await _shot("22_cinema_seated_loading")
		await _wait(1.6)
		await _shot("23_cinema_play_button_appears")
		cinema.play(0.0)
		await _wait(3.0)
		await _shot("24_cinema_playing_ogv")
		main.rig.stand_up()            # saves the resume point
		await _wait(0.5)
		cinema.sit(seats[5])
		await _wait(2.0)
		await _shot("25_cinema_resume_or_start_over")
		main.rig.stand_up()
		if not mp4.is_empty():
			cinema.select(mp4)
			await _wait(1.0)
			cinema.sit(seats[5])
			await _wait(1.8)
			cinema.play(0.0)
			await _wait(1.5)
			await _shot("26_cinema_mp4_preview_stub")
			main.rig.stand_up()
	if films != "":
		await _go(films, 3.0)
		await _place(Vector3(-3.5, 0, -2.0), Vector3(-8, 2.0, -3.2))
		await _shot("27_films_folder_cinema_wall")


# --- the museum tour ----------------------------------------------------------

func _museum_tour() -> void:
	_flat().set_view(0, 3)
	await _wait(1.5)
	await _shot("30_museum_spawn_landing_circle")
	# Aerial overview (physics paused so we don't fall).
	_flat().set_physics_process(false)
	_flat().global_position = Vector3(26, 26, 34)
	_flat().look_at_point(Vector3(0, 0, -6))
	await _wait(0.5)
	await _shot("31_museum_quad_overview")
	_flat().set_physics_process(true)
	_flat().global_position = Vector3(0, 0, -16)
	_flat().look_at_point(Vector3(0, 6, -30))
	await _wait(0.6)
	await _shot("32_museum_building_front")
	var first: String = AppState.locations[0]["path"]
	await _go(first, 3.0)
	await _place(Vector3(0, 0, 4.6), Vector3(0, 1.6, -7))
	await _shot("33_museum_themed_gallery_room")
	await _place(Vector3(0, 0, -2.0), Vector3(0, 1.3, 7))
	await _shot("34_museum_room_back_door")



# --- the wrist menu tour (flat) ------------------------------------------------

func _wrist_tour() -> void:
	# Fill the Alerts tab the way the app would (change poller + app messages).
	Notifications.push("3 new files in Aurora Photos/Images", {"path": AppState.locations[0]["path"]})
	Notifications.push("Thumbnails ready for Cat Gallery")
	Notifications.push("Something changed in Films", {"path": AppState.locations[-1]["path"]})
	await _go(AppState.locations[0]["path"], 2.5)
	await _place(Vector3(0, 0, 4.6), Vector3(0, 1.6, -7))
	main.open_wrist(main.wrist.TAB_SEARCH)
	main.wrist.focus_search("night 2019 1")
	main.wrist._do_search()
	var t := 0.0
	while main.wrist._results.item_count == 0 and t < 8.0:
		await _wait(0.2)
		t += 0.2
	await _wait(0.3)
	await _shot("40_wrist_search_results")
	main.wrist.open(main.wrist.TAB_TELEPORT)
	await _wait(0.3)
	await _shot("41_wrist_teleport_tab")
	main.wrist.open(main.wrist.TAB_SETTINGS)
	await _wait(0.3)
	await _shot("42_wrist_settings_tab")
	main.wrist.open(main.wrist.TAB_ALERTS)
	await _wait(0.3)
	await _shot("43_wrist_alerts_tab")
	# Search -> Go there: lands in the room that holds the file.
	main.wrist.open(main.wrist.TAB_SEARCH)
	main.wrist._results.select(0)
	var done := [false]
	main.rooms.arrived.connect(func(_p, _y, _t): done[0] = true, CONNECT_ONE_SHOT)
	main.wrist._go_result()
	t = 0.0
	while not done[0] and t < 10.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	await _wait(2.5)
	await _place(Vector3(0, 0, 4.6), Vector3(0, 1.6, -7))
	await _shot("44_search_go_there_result")
	# Settings really apply: slideshow 2 s from the wrist menu.
	main.wrist.open(main.wrist.TAB_SETTINGS)
	main.wrist._slide.value = 2
	main.wrist.close()
	await _wait(0.3)
	print("  check: slideshow setting -> ", Settings.get_value("rooms", "slideshow_seconds", -1))
	# The first-run setup wizard (what Bit sees the very first time).
	var wiz: Control = main.WizardScript.new()
	main.ui.add_child(wiz)
	await _wait(0.5)
	await _shot("45_first_run_setup_wizard")
	wiz.queue_free()


# --- the island tour -------------------------------------------------------------

func _island_tour() -> void:
	_flat().set_view(180, 2)
	await _wait(1.5)
	await _shot("50_island_spawn_facing_sea")
	_flat().set_view(0, 4)
	await _wait(0.5)
	await _shot("51_island_turn_around")
	_flat().set_physics_process(false)
	_flat().global_position = Vector3(0, 60, 40)
	_flat().look_at_point(Vector3(0, 0, -50))
	await _wait(0.5)
	await _shot("52_island_overview")
	var p: Array = main.world.get_outside_point(AppState.locations[0]["path"])
	_flat().global_position = p[0] + Vector3(0, 0, 0)
	_flat().set_view(p[1], 6)
	await _wait(0.5)
	await _shot("53_island_hut_village_door")
	if AppState.locations.size() > 2:
		p = main.world.get_outside_point(AppState.locations[2]["path"])
		_flat().global_position = p[0] + (p[0] - Vector3(44, 0, -6)).normalized() * 10.0
		_flat().set_view(p[1], 16)
		await _wait(0.5)
		await _shot("54_island_lighthouse")
	_flat().set_physics_process(true)
	await _go(AppState.locations[0]["path"], 3.0)
	await _place(Vector3(0, 0, 4.6), Vector3(0, 1.6, -7))
	await _shot("55_island_themed_room")


# --- the Metaverse City tour -------------------------------------------------------

func _city_tour() -> void:
	_flat().set_view(-20, 3)
	await _wait(1.5)
	await _shot("60_city_spawn_in_port")
	_flat().set_physics_process(false)
	_flat().global_position = Vector3(-3, 0, -6)
	_flat().look_at_point(Vector3(0, 6, -120))
	await _wait(0.5)
	await _shot("61_city_street_view")
	_flat().global_position = Vector3(40, 55, 40)
	_flat().look_at_point(Vector3(0, 0, -60))
	await _wait(0.5)
	await _shot("62_city_overview")
	var p: Array = main.world.get_outside_point(AppState.locations[0]["path"])
	_flat().global_position = p[0] + Vector3(8, 0, 6)
	_flat().look_at_point(p[0] + Vector3(-8, 5, 0))
	await _wait(0.5)
	await _shot("63_city_tower_front")
	_flat().global_position = Vector3(-14, 0, 0.5)
	_flat().look_at_point(Vector3(-10.4, 1.4, -2.0))
	await _wait(0.5)
	await _shot("64_city_port_directory")
	_flat().set_physics_process(true)
	await _go(AppState.locations[0]["path"], 3.0)
	await _place(Vector3(0, 0, 4.6), Vector3(0, 1.6, -7))
	await _shot("65_city_themed_room")


# --- fake VR (no headset): panels, laser, and a real laser click ------------------

func _vr_tour() -> void:
	var vr: Node3D = main.rig.vr
	await _wait(1.5)
	main.hud.toast("VR preview without a headset: this is the floating screen panel", 30.0)
	await _wait(0.5)
	await _shot("70_fakevr_screen_panel_and_hands")
	# Open the wrist menu and look at the left wrist.
	main.open_wrist(main.wrist.TAB_TELEPORT)
	await _wait(0.4)
	var cam: Camera3D = vr.camera
	cam.look_at(main.wrist_panel.global_position, Vector3.UP)
	await _wait(0.4)
	await _shot("71_fakevr_wrist_menu")
	# Real input path: aim the right controller's laser at the Settings tab and pull the trigger.
	var bar: TabBar = main.wrist._tabs.get_tab_bar()
	var r := bar.get_tab_rect(main.wrist.TAB_SETTINGS)
	var px := bar.get_global_rect().position + r.get_center()
	var panel: Node3D = main.wrist_panel
	var local := Vector3((px.x / panel.size_px.x - 0.5) * panel.size_m.x, (0.5 - px.y / panel.size_px.y) * panel.size_m.y, 0)
	var hit: Vector3 = panel.to_global(local)
	vr.right.look_at(hit, Vector3.UP)
	await get_tree().physics_frame
	await get_tree().physics_frame
	panel.pointer(hit, true)
	await get_tree().process_frame
	panel.pointer(hit, false)
	await _wait(0.4)
	var ok: bool = main.wrist.current_tab() == main.wrist.TAB_SETTINGS
	print("  check: VR laser click on the Settings tab -> ", "PASS" if ok else "FAIL (tab %d)" % main.wrist.current_tab())
	await _shot("72_fakevr_laser_clicked_settings")
	main.wrist.close()
	# Teleport: the rig lands with the head over the target.
	main.rig.teleport_to(Vector3(0, 0, 6), 0.0)
	await _wait(0.3)
	var c := cam.global_position
	print("  check: VR teleport -> head at (%.2f, %.2f) %s" % [c.x, c.z, "PASS" if Vector2(c.x, c.z).distance_to(Vector2(0, 6)) < 0.05 else "FAIL"])
	cam.rotation = Vector3.ZERO
	main._open_teleport()
	await _wait(0.5)
	cam.look_at(main.screen_panel.global_position, Vector3.UP)
	await _wait(0.2)
	await _shot("73_fakevr_teleport_menu_on_screen_panel")
