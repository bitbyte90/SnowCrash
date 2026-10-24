# Project Snow Crash: Open Questions for Bit

*11 Oct 2026. Next decisions, most important first. Short answers are fine ("yes", "B", "later").*

1. Name: "Snow Crash" is the title of Neal Stephenson's novel; keep it as a codename only and pick a different public name before GitHub/Steam (to avoid trademark trouble)?
2. Licence: GPL-3.0 (everything stays open, write mode sold as a "thank you" key that people could technically bypass) or MPL-2.0 (lets you keep write mode as a closed add-on)?
3. Contributors: simple DCO sign-off, or a CLA so you keep the right to relicense later?
4. Who builds the demo: you with AI help, a volunteer, or a mix? And roughly how many hours a week?
5. Webrips: in the demo each site is a room in the one building; later, should a "show subfolders as buildings" switch make each site its own building?
6. Video in VR: is it OK to rely on a third-party FFmpeg plugin (GoZen), with "open in your normal player" as the fallback for odd files?
7. Default locomotion for new users: teleport, smooth, or both?
8. Room density: is 12 canvases per gallery the right default, or do you want more/fewer?
9. Door overflow: when a folder has more than 8 subfolders, is an alphabetical "More rooms" hallway OK?
10. Cinema vs TV: should the default be the cinema (sit then play), with the living-room TV as the option?
11. Which stock world comes first after the bare default: Museum Quad (best fit for "museum tour") or the Metaverse City (most Snow Crash)?
12. Write mode pricing: one-off supporter key, pay-what-you-want, or donation-unlocks (e.g. Ko-fi)?
13. Games after the demo: Playnite first (it already gathers Steam/GOG/Epic/emulators), then GOG Galaxy, then Steam/Epic directly; OK?
14. Online box art (SteamGridDB/IGDB): allow as an opt-in, or keep the app 100% offline?
15. Should the app ship or require Everything for search, or just use it when it's already installed?
16. Shared workspaces age limit: 18+ only at first?
17. Recording in workspaces: OK to record for safety by default (with notice) but only use recordings to improve the app if people tick a separate box?
18. Recording retention: 30 days, or something else?
19. Hash-matching provider: are you open to applying to the IWF / PhotoDNA / Thorn Safer (some cost money), and who'd review reports with you?
20. Workspaces: start invite-only with a cap of about 8 people?
21. Workspace networking: are you OK with running a small server (relay/signalling) later, and roughly what budget per month?
22. Unknown files default look: themed objects, loot drops, or a mix (loot drops just for new downloads)?
23. Loot colours: happy with the proposed palette (blue docs, green archives, orange code, purple creative, red programs, yellow fonts/subs, white disc images, grey unknown)?
24. Should freshly downloaded files "drop" into the room as loot (the fun bit), or just appear quietly?
25. Hidden/system files: hidden by default with a setting to show them?
26. App launching from VR: should script files (.bat, .ps1) be blocked by default with a setting to allow them?
27. When you launch a PC game from inside VR, should Snow Crash pause its own VR session automatically?
28. Music: is a music room (record crates + turntable) wanted in the alpha, or later?
29. Documents: is a basic in-VR text/PDF reader important, or is "open in Windows" enough for now?
30. Favourites shelf: one global favourites room, or a shelf in every building?
31. Should rooms ever remember small things (like which image a canvas was on) or always fully reset?
32. Demo building look: gallery pavilion, spaceship, zeppelin, village hall, or something else?
33. Tutorial voice: text signs only, or a narrated voice (AI voice or yours)?
34. Path shortening default: "a bit" or "a lot"?
35. Treadmill: do you have (or plan to get) a specific treadmill we should test with?
36. Hand tracking: worth supporting early on the Quest 2, or controllers only for now?
37. Should the flat-screen mode have an optional classic address bar (type a path, jump there)?
38. Windows Libraries import (Games, Downloads, Captures): add to the wizard in the alpha?
39. Theme packs: share files freely (GitHub/itch/Discord) at first, with an official reviewed gallery later?
40. Telemetry: none at all, or opt-in crash reports only?
41. Where should the community live: GitHub Discussions, a Discord server, or both?
42. Second Life/OpenSim viewer idea: OK to keep parked until after workspaces?

## Added in round 2 (from building the playable demo, 11 Oct 2026)

43. Doors: in rooms with pictures the doors sit on the side and front walls, and in rooms without pictures they're straight ahead on the far wall. Do you like that, or should doors always be in the same place so you build muscle memory?
44. Demo video: Godot can only play .ogv (Theora) files by itself. Everything else gets a clearly labelled "preview stub" until a video plugin (GoZen) is wired in. Is that OK for a first demo, or is real .mp4 playback a must-have before anyone sees it?
45. Thumbnails for videos currently use ffmpeg. OK to bundle an LGPL build of ffmpeg with the app, or should we use Windows' own thumbnails on Windows instead?
46. Fonts: names in Japanese, Chinese, Korean or with emoji need a bigger font (e.g. Noto, which adds roughly 20 to 60 MB). Ship it with the app, or download it only when needed?
47. Tutorial signs: are the five sign texts in the demo (moving, wrist menu, bag, teleport, the big picture) the right topics and tone? (The screenshots show them.)
48. Museum Quad: the demo greybox takes you from a building's door straight into the folder's room. Do you want a grand entrance hall first (nicer, but one more step)?
49. Mixed rooms with videos get a small "TV corner" offering "make this a cinema". Is that helpful, or clutter?
50. The bag shows locked actions (rename, move, delete) with a padlock, as a hint of the paid write mode. Show them like that, or hide them completely in the free version?
51. Cinema: you sit, it says "Loading…", then a Play button appears in front of you. Should it just start playing when you sit down instead?
52. Resume points (where you stopped a film) are saved in the app's own data folder, never next to the film. Should they expire after a while (say 90 days), and should there be a "forget all" button?
53. Museum Quad holds 6 buildings per quad, with more drives going through an archway into a second quad. Is 6 right?
54. Looking at the screenshots: anything that feels wrong (colours, room size, how big the labels are, the floor colour)? Gut reactions are fine.

## Added in round 3 (Windows build, wrist menu, VR wiring, Island and City, 11 Oct 2026)

55. Trying the Windows build: when you run `builds/windows/SnowCrash-demo-0.3.0-windows-x64.zip` on your PC, does it start, find your folders, and feel OK on a mouse and keyboard? Screenshots of anything odd help a lot.
56. Windows SmartScreen will say "Windows protected your PC" because the exe isn't code-signed. Is that fine while testing? For a public release, a signing certificate costs roughly £100 to £400 a year. Worth it, and when?
57. The default .exe never tries VR, and a separate "VR on Quest 2 (UNTESTED).bat" turns VR on. Later, should the app detect a headset and ask "Start in VR?" instead?
58. VR comfort defaults in the build: both teleport (right stick up) and smooth walking (left stick), with snap turn of 30° on the right stick. Is that the right default, and is 30° right (45° is the other common choice)? (This follows on from question 7.)
59. The VR wrist menu currently floats a little above your left hand and turns to face you, rather than being stuck flat to the wrist like a watch. Which do you prefer once you've tried it?
60. Typing a search in VR: point at a floating keyboard, use voice (Windows dictation), or both? Right now search uses the computer keyboard even in VR.
61. The other menus (Teleport, the bag, the setup wizard) appear in VR on a big floating "screen" about 1.5 m in front of you, 2 m wide. Is that size and distance comfortable, or should those menus also go on the wrist?
62. The wrist menu's Settings tab has slideshow speed, rooms kept in memory, volume and mute. What else should be one tap away (comfort settings, hidden files, room theme)?
63. Notifications (Alerts tab): today they're "new files arrived", "drive plugged in or removed" and app messages. Which ones do you actually want, and should any of them make a sound?
64. Search uses the free "Everything" tool if it's installed (instant across the whole PC), otherwise a slower built-in search of just your chosen folders. Recommend Everything in the wizard, bundle it (its licence allows that), or keep it out of sight? (This follows on from question 15.)
65. Programs and shortcuts: .exe, .lnk and .url files ask "Run it?" first, and scripts (.bat, .ps1, .vbs and so on) are always blocked. Is that the right line? (This settles question 26 for the demo.)
66. Island world: does the golden-hour look work? Are the slots right (hut village, treehouse, lighthouse, cave, two islets over rope bridges), and what should go in the cave?
67. Metaverse City Street: the name "Metaverse" comes straight from Snow Crash. To avoid trouble with the book's rights and with Meta (Facebook's owner), should the world have its own name in the app, like "The Street" or "Neon Boulevard"?
68. City Street: you arrive at a Port (a numbered booth with a Directory screen), and each location is a tower with a neon name sign. Should the Street be one long straight road (as in the book) or loop back round so it never ends?
69. Should you be able to change your folders (re-run the setup wizard) from inside VR, or only on the flat screen? Right now it works in both.
70. Default world for a brand-new user: bare (fastest), Museum Quad, Island or City Street?
