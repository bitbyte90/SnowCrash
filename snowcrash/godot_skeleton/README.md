# Snow Crash: Godot 4 demo skeleton

A playable flat-screen version of the demo in `../DEMO_MVP_SPEC.md`. It's built almost entirely in code, so there are very few `.tscn` files to break, and `TODO(area):` markers show what comes next.

**Status (11 Oct 2026, round 3).** Tested with Godot **4.7.2** on Linux:

- The flat (WASD) demo runs in all four worlds (bare, museum, island, city) with no script errors.
- The 42 core tests pass (`ALL PASSED`).
- Six scripted tours render 55 screenshots (`../screenshots/`), including a simulated-VR tour (`--fake-vr`) whose laser-click and teleport checks pass.
- The **Windows export** (`export_presets.cfg`, official 4.7.2 templates) builds `../builds/windows/`. The real .exe was run under Wine: it fell back from Vulkan/D3D12 to OpenGL and completed the whole demo tour using Windows paths.

**Not tried yet:** a real headset (the OpenXR code is **UNTESTED**, see `../VR_SETUP.md`), real Windows hardware, or the GoZen video plugin.

## What works in the demo

- **Outside:** the bare world, the demo pavilion with an "Enter" door, 5 tutorial signs, and ghost buildings (D:, E:, F:) hinting at the full app.
- **Museum Quad greybox** (`--world=museum`): one stone building per chosen folder, arranged around a landing circle with a map plinth (use it to teleport). Each door goes straight into that folder.
- **Island greybox** (`--world=island`): you spawn on the jetty facing the sea at golden hour, with a "now turn around" sign. Your folders are the hut village, treehouse, lighthouse, cave and two islets over rope bridges. Rooms use the bamboo theme.
- **Metaverse City Street greybox** (`--world=city`): you spawn inside Port 0 (a glowing booth with a Directory screen that opens Teleport). Each folder is a tower on alternating sides of the Street, with a neon name sign, under a monorail at night. Rooms use a white-cube neon theme.
- Measurements for all three are in `../WORLD_BLOCKOUTS.md` ("as built").
- **Lobby:** one door per chosen location, each with a label and a thumbnail.
- **Gallery rooms:** pictures on up to 12 canvases.
  - **Big folders** (e.g. 130 pictures) cycle images across the canvases: canvas *i* shows images *i*, *i+12*, … Number keys 1–5 set a slideshow speed in seconds; 0 is manual.
  - **Doors to subfolders** show a name, a thumbnail and "N images · N folders". A back door is always behind you.
  - **Too many subfolders** overflow into a "More rooms (A – Z)" hallway.
- **Loot drops:** files that aren't pictures appear as coloured gems (docs, archives, code…). Many files of one kind become a crate. Undecodable pictures (HEIC) become Polaroids.
- **Cinema room:** for folders that are mostly video.
  - A thumbnail wall to pick a film, then sit in a seat. You see "Loading…" for 1.2 s, then a Play button.
  - **.ogv plays for real** (Godot's built-in Theora). Every other format shows a clearly labelled preview stub with a running clock.
  - Standing up (Space) pauses and saves a resume point. Next time you get "Resume from 0:03" and "Start over".
- **TV corner:** in mixed rooms with videos it offers "Make this a cinema" (a per-folder override).
- **Bag (Q or right-click):** a radial menu with read-only actions: Info, Open in Windows, Show in Explorer, Show path, View full size, plus 🔒 Rename/Move/Delete (locked: write mode). On Linux the "open" actions are stubs that only show a message.
- **Teleport menu (T):** Outside, Lobby, each location, drill into folders, then "Go there". Fades through black.
- **Wrist menu (Tab; in VR it's on your left wrist, Y button):**
  - Header: clock, where-am-I, "⬆ Up a room".
  - **Search** (`/`): finds files and folders by name. It uses Everything (`es.exe`) if installed, otherwise a built-in read-only walk of your chosen folders (at most 200 results, never writes anything). "Go there" jumps to the folder and highlights the file.
  - **Teleport:** Outside, Lobby, each location, "Browse all folders…".
  - **Settings:** slideshow speed, rooms kept in memory (1–10), volume, mute, and "Change my folders" (re-runs the setup wizard). These are saved.
  - **Alerts** (`N`): notifications with times, Go there, Clear all, Do not disturb, and an unread badge.
- **Launching:** .exe/.lnk/.url ask "Run it?" first. Scripts (.bat, .ps1, .vbs, .reg, .msi…) are always blocked.
- **VR mode (UNTESTED):** XROrigin3D, two controllers with hands, a laser pointer, teleport arc plus snap turn, and smooth walking. Menus are drawn on floating panels you click with the laser. See `../VR_SETUP.md`.
- **HUD:** crosshair, hover text, where-am-I, key help, toasts, info panel, full-size image viewer.
- **Setup wizard:** shown when no locations are saved. It has folder pickers for pictures, videos, games and other.

## Controls (flat)

| Action | Key |
|---|---|
| Walk / run | W A S D / Shift |
| Look | Mouse (Esc releases it) |
| Use (door, canvas, seat, button) | E or left-click |
| Bag | Q or right-click (1–8 choose, Esc closes) |
| Teleport | T |
| Info about the thing you're pointing at | I |
| Wrist menu / Search / Alerts | Tab / `/` / N |
| Slideshow speed | 0–5 (also in wrist menu → Settings) |
| Stand up | Space |
| Close menus | Esc |

VR controls are in `../VR_SETUP.md`.

## Running it

```
# Play, pointing at folders (repeat --root; they're not saved = "ephemeral")
godot --path . -- --flat --root="D:/Webrips" --root="D:/Films"

# Museum Quad instead of the bare world
godot --path . -- --flat --world=museum --root="D:/Pictures" --root="D:/Films"

# Jump straight into a folder
godot --path . -- --flat --root="D:/Webrips" --enter="D:/Webrips/SiteA"

# Island or City Street
godot --path . -- --flat --world=island --root="D:/Pictures" --root="D:/Films"
godot --path . -- --flat --world=city --root="D:/Pictures" --root="D:/Films"

# No --root and nothing saved → the setup wizard opens
godot --path .

# Simulated VR rig on a normal screen (no headset; for tests and screenshots)
godot --path . -- --fake-vr --root="D:/Webrips"
```

- **VR (Quest 2 via Link, UNTESTED):** set Meta Quest Link as the active OpenXR runtime, connect Link, and run without `--flat` from the editor (OpenXR is on in project.godot). The exported Windows exe is flat by default (`openxr/enabled.flat_build=false`); start it with `--xr-mode on` (or "VR on Quest 2 (UNTESTED).bat"). Details: `../VR_SETUP.md`.
- **Test data:** `python3 tools/make_demo_fixture.py` builds `/tmp/snowcrash_fixture` (275 files: webrip-style sites, a 130-picture folder, a 15-subfolder forum, a Japanese/emoji folder name, .ogv/.mp4 films). It needs Pillow and ffmpeg.

## Tests and screenshots

```
godot --headless --path . --import           # once, registers class names
godot --headless --xr-mode off --path . --script res://tests/run_core_tests.gd

# Scripted tours that save PNGs (Linux, no screen needed):
xvfb-run -a -s "-screen 0 1600x900x24" godot --path . \
  --rendering-driver opengl3 --rendering-method gl_compatibility --xr-mode off --resolution 1600x900 \
  -- --flat --root=/tmp/snowcrash_fixture/Webrips --root=/tmp/snowcrash_fixture/Films --tour=/tmp/shots
# other tours (same command, swap the last line's flags):
#   --world=museum --tour-set=museum   (2–6 --root folders)
#   --world=island --tour-set=island
#   --world=city   --tour-set=city
#   --tour-set=wrist                   (wrist menu tabs, search, setup wizard)
#   --fake-vr --tour-set=vr            (simulated VR; prints PASS/FAIL for the laser click and teleport)
```

## Building the Windows exe

You need the **official** Godot 4.7.2 export templates (Editor → Manage Export Templates → Download, or the `.tpz` from the Godot GitHub release, checked against its SHA512).

```
godot --headless --path . --import
godot --headless --path . --export-release "Windows Desktop (flat demo)" ../builds/windows/SnowCrash/SnowCrash.exe
```

The preset embeds the .pck, adds `SnowCrash.console.exe` (it shows the log), sets the version metadata, and uses the `flat_build` feature tag so the exe never tries OpenXR unless you pass `--xr-mode on`. The launchers (`*.bat`), `README_FIRST.txt` and Godot licence files in `../builds/windows/SnowCrash/` are kept by hand. Re-zip the folder afterwards. A second preset, "Linux (smoke test only)", exports to `/tmp/snowcrash_linux_build/` for testing on this box.

Two expected messages, both harmless:

- `ERR_CANT_OPEN … audio_driver_alsa` just means the test box has no sound card.
- `tests/check_all_scripts.gd` reports "identifier not found" for autoloads, because autoloads aren't loaded in `--script` mode.

## Files

| Path | What it does |
|---|---|
| `main.gd` / `main.tscn` | Reads the command-line args, builds the world, player and UI, and handles the bag actions, info and teleports |
| `autoload/settings.gd` | Settings with defaults, the "ephemeral" mode, film resume points (`user://resume.cfg`), volume/mute applied to the Master bus |
| `autoload/app_state.gd` | Locations, mode, key bindings |
| `autoload/file_index.gd` | Background one-level scans, cache, change polling |
| `autoload/thumbnail_cache.gd` | 128/512 px WebP thumbnails in app data, full-size in memory only, ffmpeg video frames, upload throttle |
| `autoload/launcher.gd` | The only place that opens things (stubbed off Windows); blocks scripts, asks before .exe/.lnk/.url |
| `autoload/notifications.gd`, `search_service.gd` | Notification queue; search via Everything (`es.exe`) or the built-in NameSearch |
| `core/*` | Classifier, scanner, RoomSpec, RoomGenerator (templates, cycling canvases, overflow hallways, overrides), RoomCache, RoutePlanner, NameSearch (read-only name search with limits) |
| `world/kit.gd` | Greybox kit helpers (boxes, cones, ramps, glow boxes, invisible barriers, labels, lights, interactive metadata) |
| `world/room_builder.gd` | RoomSpec → 16 × 14 × 4.5 m room with sockets, themes, TV corner, loot grid, hallways |
| `world/room_manager.gd` | Room pockets, doors, back-door tracking, cache, slideshow, "make this a cinema" |
| `world/door.gd`, `canvas.gd`, `loot_drop.gd`, `cinema.gd` | The interactive pieces |
| `world/world_bare.gd`, `world_museum.gd`, `world_island.gd`, `world_city.gd` | The bare world + demo pavilion; the Museum Quad, Island and Metaverse City Street greyboxes |
| `player/player_rig.gd` | Picks OpenXR or flat, sets the refresh rate, handles session pause/quit |
| `player/flat_controller.gd` | WASD + mouse controller, sitting |
| `player/vr_controller.gd` | **UNTESTED** OpenXR rig: XROrigin3D, camera, controllers, laser, teleport arc, snap/smooth turn, smooth walk, button → action mapping |
| `ui/wrist_menu.gd` | The wrist menu (Search, Teleport, Settings, Alerts) |
| `ui/vr_panel.gd` | Shows any 2D UI on a 3D quad in VR and turns laser hits into mouse clicks |
| `ui/*` (others) | HUD, bag radial, teleport menu, setup wizard |
| `export_presets.cfg` | Windows (flat demo) and Linux (smoke test) export presets |
| `tests/run_core_tests.gd` | 42 headless core tests |
| `tests/capture_tour.gd` | Scripted tours (demo, museum, island, city, wrist, vr) that save screenshots |
| `tools/make_demo_fixture.py` | Builds the test folder tree |

## Read-only rule

The app never writes into user folders. It only writes to its own app data (`user://` = `%APPDATA%/SnowCrash` on Windows, `~/.local/share/SnowCrash` on Linux): `user://settings.cfg`, `user://resume.cfg`, Godot's logs, and thumbnails under `%LOCALAPPDATA%/SnowCrash/thumbs` (or `user://thumbs`), including ffmpeg's temporary frame. The tests write only their own temporary tree and the screenshot folder you give them. After a full tour run, the fixture tree had no new files in it.
