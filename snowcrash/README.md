# Project Snow Crash: design pack (11 Oct 2026, rounds 2 and 3 added the same day)

Start with **DESIGN_OVERVIEW.md**, then **DEMO_MVP_SPEC.md**, then answer **OPEN_QUESTIONS.md**.
**To try it on your PC:** unzip `builds/windows/SnowCrash-demo-0.3.0-windows-x64.zip` and read `README_FIRST.txt` inside.

| File | What's in it |
|---|---|
| DESIGN_OVERVIEW.md | Vision, pillars, the core mapping, systems diagram |
| TECH_ARCHITECTURE.md | Godot 4 + OpenXR structure, scanner/index/watcher/thumbnails, room generation, RAM budget, video, safe launching, launcher importers, Everything search |
| ROOM_TYPES.md | Every file type in the world and what the bag offers for it |
| WORLDS.md | Bare default, the four stock worlds, the World SDK (theme packs) |
| WORLD_BLOCKOUTS.md | Greybox specs for the four stock worlds: sizes, modular kit pieces, lighting. Museum Quad, Island and Metaverse City Street are greyboxed in Godot (with "as built" notes); the House / Mansion is spec only |
| UX_CONTROLS.md | VR + flat controls, wrist menu, the bag, teleport/search flows, settings tree, comfort, accessibility |
| VR_SETUP.md | How to try the (untested) Quest 2 via Link mode, the VR controls, how the VR code works, what needs tuning in a headset |
| DEMO_MVP_SPEC.md | The super-basic first demo, acceptance criteria, week-by-week plan |
| PRIVACY_SAFETY.md | Read-only safety, guests, workspace consent/recording, moderation |
| ROADMAP.md | Phases to Steam, licence recommendation, CONTRIBUTING outline |
| OPEN_QUESTIONS.md | 70 numbered questions for Bit, most important first (43–54 added in round 2, 55–70 in round 3) |
| godot_skeleton/ | The Godot 4.7.2 project: playable flat-screen demo (lobby, galleries, cycling canvases, doors, hallways, cinema, bag, teleport), the wrist menu (Search, Teleport, Settings, Alerts), OpenXR wiring for Quest 2 via Link (untested), and the Museum, Island and City greyboxes. 42 core tests pass. See its README for how to run it |
| builds/windows/ | `SnowCrash-demo-0.3.0-windows-x64.zip`: the Windows exe of the flat demo, built with the official Godot 4.7.2 export templates, plus launchers and README_FIRST.txt. The unzipped `SnowCrash/` folder is next to it |
| screenshots/ | 57 renders from the scripted tours (01–27 demo, 30–34 museum, 40–45 wrist menu, 50–55 island, 60–65 city, 70–73 simulated VR, 80–81 the Windows exe under Wine), `_contact_sheet.png` and `index.md` |

The source of truth for decisions remains `../VR_FILE_EXPLORER.md`.
