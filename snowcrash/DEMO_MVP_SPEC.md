# Project Snow Crash: Demo / MVP Spec

*Drafted 11 Oct 2026. The demo stays **super basic** (Bit, decided): one building, a few rooms, pictures on walls, one cinema. The install folder is the world (Q10), a manual setup wizard picks the rooms, and it points at real files, read-only, never copying (Q11). Bit's own first test: her **webrips** folder (Q29).*

> **Status, 11 Oct 2026 (round 2):** a flat-screen (WASD) version of this demo now runs in `godot_skeleton/` and covers the building, gallery rooms, cycling canvases, labelled and thumbnailed doors, overflow hallways, the cinema sit-then-play flow (real playback for .ogv only, a labelled stub for other formats), the teleport menu and the read-only bag. Screenshots: `screenshots/index.md`. Round 3 added the wrist menu (Search, Teleport, Settings, Alerts), the OpenXR rig for Quest 2 via Link (written but **untested** in a headset, see `VR_SETUP.md`), Island and City Street greyboxes, and a Windows build: `builds/windows/SnowCrash-demo-0.3.0-windows-x64.zip`, tested only under Wine so far. Not yet done: testing in a real headset, testing on real Windows, and a video plugin.

## 1. The goal in one sentence

> Prove that walking through your own pictures and videos in VR feels good and quick, on Bit's Quest 2 via Link, with her webrips folder.

## 2. In scope

| # | Feature | Notes |
|---|---|---|
| 1 | **Bare world** with **one building** | The building is themeable later; the demo ships one simple look (suggest: a small gallery pavilion). Stands in the bare default world |
| 2 | **Tutorial** | 5 short stops (signs + optional voice/captions): moving, the wrist menu, the bag, teleport, "in the full app every drive is a building and you choose your world" |
| 3 | **Manual setup wizard** (flat window before VR starts, and re-runnable from the wrist) | "Where do you keep your pictures? Videos? Games? Anything else?" One folder picker per type, plus "add another folder". Each pick becomes a room (door) off the building's lobby |
| 4 | **Folder → room** with **subfolders → labelled doors** | Folder name + auto thumbnail on each door. Impossible space via vestibule swap |
| 5 | **Gallery room** | 12 canvases cycling (Q1), slideshow off/1–5 s (Q2), grab a picture to see it close |
| 6 | **Cinema room** | Thumbnail wall of the folder's videos; pick one, sit, Play appears after buffering (Q3); pause, scrub, volume; resume position saved (Q32) |
| 7 | **The bag (basic)** | Radial menu on grab: View/Play · Show in folder · Open in Windows · Copy path · Put back |
| 8 | **Teleport menu (basic)** | Lists the wizard rooms + lobby; tap to go |
| 9 | **Unknown files** | Grey loot drop with the bag's "Open in Windows" (so nothing is invisible) |
| 10 | **Room reset + cache** | Rooms reset when you leave; cached rooms setting 1–3 |
| 11 | **VR + flat mode** | Quest 2 via Link (OpenXR) and WASD/mouse. Snap turn, teleport + smooth, vignette |
| 12 | **Basic settings** | Volume sliders, comfort, slideshow default, cache size, wrist hand |
| 13 | **Read-only guarantee** | No file writes outside the app's own data folders (`%APPDATA%\SnowCrash`, `%LOCALAPPDATA%\SnowCrash`) (tested) |

## 3. Out of scope for the demo (on purpose)

Multiple buildings/drives as buildings · stock worlds · search/Everything · guided walk + path shortening · game shelves + launcher importers · app launching (except "Open in Windows") · music rooms · documents/archives previews · notifications/file watcher · write mode · guests/workspaces · avatars · theme packs · Windows Libraries import (secondary option, later) · Steam.

(Games are tempting because Bit has a great library, but the importers are a lot of work. They're the first thing after the demo.)

## 4. How the webrips test maps

Bit's webrips folder: each site has images (nested) and videos.

- The wizard picks `Webrips` as the "pictures" location (or "other").
- Lobby → a **Webrips** door → a room whose doors are **each site**.
- In a site room: an **Images** door leads to a **gallery wing** following the folder tree (nested folders = more doors); a **Videos** door leads to a **cinema** with a thumbnail wall.
- In the full app, the optional "each site = a building" (Q29) can be a per-folder "show subfolders as buildings" switch. For the demo, sites are rooms in the one building (keeps "one building" intact). **Open question for Bit.**

## 5. Acceptance criteria

The demo is "done" when all of these pass on Bit's PC + Quest 2 (Link) and in flat mode:

**Setup**
- [ ] A1. First launch shows the wizard; picking 1–4 folders takes under 2 minutes; skipping a type is allowed.
- [ ] A2. The app never writes, renames, moves or deletes anything in picked folders (verified by a test that hashes the folder tree before and after a session, and by a file-access monitor run once with Process Monitor).
- [ ] A3. Settings and caches live only under `%APPDATA%\SnowCrash\` and `%LOCALAPPDATA%\SnowCrash\`; deleting those folders resets the app cleanly.

**World and movement**
- [ ] B1. Starting VR lands you at the building's front door in the bare world; the tutorial can be completed in under 3 minutes and skipped.
- [ ] B2. Smooth move, teleport and snap turn all work; vignette toggles; no frame-rate dips below the headset's refresh rate when walking between rooms (target 72 Hz minimum, 90 preferred) on Bit's PC.
- [ ] B3. Flat mode: WASD + mouse look, right-click bag, Tab wrist menu, T teleport.

**Rooms**
- [ ] C1. Every subfolder of a picked folder is a door with its name and a thumbnail; entering takes under 1 s from touching the door handle for a preloaded room, under 3 s otherwise (with a loading glow on the door, never a frozen frame).
- [ ] C2. A folder with 500 images opens as one gallery with 12 canvases; each cycles through its share; the slideshow interval changes live (off/1–5 s).
- [ ] C3. Grabbing a picture shows it at higher resolution within 1 s; the bag offers View, Show in folder, Open in Windows, Copy path, Put back.
- [ ] C4. A folder of videos shows a thumbnail wall; picking one and sitting shows Play only once it's ready; MP4 (H.264) and MKV play with sound; 1080p plays smoothly.
- [ ] C5. Leaving and re-entering a film offers "Resume from hh:mm:ss".
- [ ] C6. Leaving a room resets it; memory stays flat after walking through 30 rooms (no leak: RAM within ±10% of the start after returning to the lobby).
- [ ] C7. Unreadable folders show as locked doors with a reason; weird file names (emoji, Japanese, very long paths) display and don't crash.
- [ ] C8. Unknown files show as grey loot drops whose bag opens them in Windows.

**Stability**
- [ ] D1. A 30-minute session through the webrips folder with no crash.
- [ ] D2. Pulling the headset off / Link disconnecting doesn't crash; flat mode can continue.

**Bit's gut check**
- [ ] E1. Bit says it feels like walking through her files, and wants to keep using it. ("It could be that simple.")

## 6. Week-by-week build plan (solo dev + AI help)

Assumes roughly **10–15 hours a week** with an AI pair-programmer writing first drafts of scripts, and Bit (or the dev) testing on the Quest each week. Each week ends with something you can put the headset on and try.

| Week | Focus | Done when |
|---|---|---|
| **0** (prep) | Install Godot 4.7.x, Godot XR Tools, Meta Quest Link + OpenXR runtime set to Meta; create GitHub repo; copy in `godot_skeleton/` | An empty scene shows in the headset via Link, hands visible |
| **1** | **Player rig**: XR origin + flat fallback, smooth move, teleport, snap turn, vignette; a test room box | Walk around a grey box in VR and in flat mode |
| **2** | **File scanner** on a worker thread + classifier; print a folder's contents into a debug panel in VR | Point it at webrips, see counts in-headset without hitches |
| **3** | **Room generator v1**: folder → RoomSpec → white-box gallery with canvas sockets and door sockets; doors labelled; vestibule swap between rooms | Walk from room to room through doors through a real folder tree |
| **4** | **Images**: thumbnail cache (Godot image decode → WebP), canvases with cycling, slideshow switch, texture upload throttle, grab-to-inspect | 500-image folder looks good, no stutter |
| **5** | **Room cache + reset**: preload neighbours, LRU, memory checks; locked/odd-name doors | 30-room walk with flat memory |
| **6** | **Video**: install GoZen (or alternative), cinema template, thumbnail wall (ffmpeg frame grabs), sit-then-play, resume points | Bit watches a webrip video in VR with sound |
| **7** | **The bag + teleport menu + wrist menu** (basic versions), Open in Windows / Show in folder via shell | All bag options in §2 work in VR and flat |
| **8** | **Setup wizard** (flat UI), **settings** (comfort, audio, cache, slideshow), loot drops for unknown files | Fresh install → wizard → rooms, without editing any config |
| **9** | **Tutorial**, the one building's look, ambient sound, polish, door thumbnails | A newcomer can get going without help |
| **10** | **Test & fix**: acceptance criteria run-through, performance pass, Windows export build, README, first GitHub pre-release (`v0.1.0-demo`) | All acceptance criteria ticked |

**Buffer:** add 2 weeks for surprises (video plugin and VR performance are the likely ones). Realistic window: **10–12 weeks**.

### Tips for building with AI help
- Keep `core/` scripts scene-free, small and testable; ask the AI for one script at a time with the RoomSpec data shapes pasted in.
- Commit every working step; ask the AI to explain anything it writes in VR-specific code (threads, XR) before you merge it.
- Keep a `DEVLOG.md` of what worked on the Quest each week; it becomes the GitHub release notes.

## 7. Risks for the demo

| Risk | Plan B |
|---|---|
| Video plugin won't build or play MKV well | Use a prebuilt release; fall back to "Open in default player" for unsupported files |
| Hitches entering big folders | Lower canvas resolution, fewer canvases, longer vestibule |
| Link performance on Bit's PC | Mobile renderer, lower render scale, 72 Hz |
| Wizard folder picker inside VR is awkward | The wizard runs as a normal desktop window before entering VR |
