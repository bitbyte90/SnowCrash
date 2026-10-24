# Project Snow Crash: Room Types and File Representations

*Drafted 11 Oct 2026. Every file type → what it looks like in the world → how you interact with it → what the bag offers.*

## How to read this

- **Free mode** = read-only (decided Q5). Bag options marked ✍ only appear when **write mode** is unlocked, and are greyed out with a small lock in free mode (so people know they exist, without nagging).
- **Every** bag includes the "always" options at the bottom of this page.
- Looks are described for the bare default world; theme packs re-skin them (a crate in the mansion becomes a steamer trunk, a loot drop on the island becomes a washed-up bottle, and so on).

## The bag in one paragraph

Pick something up (grip in VR, right-click in flat mode) and **the bag** opens beside your other hand: a radial menu of the options for that file. It's the Windows right-click menu, made physical. Picking up never opens or launches anything by itself (Q14). The bag also holds things you **grabbed** from search (a held reference, like copy to clipboard), shown as small tokens round its rim.

---

## 1. Room templates (whole-folder looks)

| Template | Used when | Feels like | Key furniture |
|---|---|---|---|
| **Gallery** | Mostly images | A calm gallery or museum room | 8–24 canvases, a bench, a contact-sheet lectern, slideshow switch |
| **Cinema** | Long videos or mostly videos | A small private cinema | Seats, big screen, thumbnail wall/menu, lights that dim |
| **Living room** | Videos, if the user prefers TV mode (Q3 preference) | A sofa and a TV | Sofa, TV, a coffee-table remote |
| **Shop / arcade** | A game library or emulator folders | A cosy game shop | Shelf bays per platform, a counter with a "featured" stand |
| **Music room** | Mostly audio | A record shop / listening room | Record crates, a turntable/jukebox, speakers |
| **Study** | Mostly documents | A library study | Desk, bookshelf, filing cabinets |
| **Storeroom** | Mostly unknown files/archives | A tidy warehouse corner | Crates, chests, loot drops |
| **Mixed room** | Nothing dominates | An open-plan room with zones | Wall art, TV corner, table, a small shelf |
| **Hallway** (virtual) | More subfolders than door sockets | A corridor of labelled doors | Up to 12 doors, A–Z signage |
| **Lobby / front door** | Every drive | The entrance of a building | Drive label, free space, a directory board of top folders |

The user can force any template per folder ("Make this a cinema").

---

## 2. Images

**Types:** `.jpg .jpeg .png .webp .bmp .tga .svg` (decoded by Godot); `.gif` (first frame in v1, animated later); `.heic .avif .tif .tiff .psd .raw/.cr2/.nef/.arw .jxl .ico` (via Windows shell thumbnails if codecs are installed, else a Polaroid).

**In the world:**
- A framed **canvas** on the wall. Frame style comes from the theme.
- **Big folders** (Q1): one room with N canvases; canvas *i* cycles through images *i, i+N, i+2N…* (500 photos / 12 canvases ≈ 42 per canvas). Each canvas has a tiny counter ("17 / 42").
- **Slideshow** (Q2): one switch per room plus a global default: 1, 2, 3, 4, 5 seconds or off/manual. Canvases are staggered so they don't all flip at once (nicer, and spreads the texture uploads).
- **Contact-sheet lectern:** a flat grid of every image in the folder; tap one to send it to the nearest canvas or hold it.
- **Polaroid** (Q28): an image type we recognise but can't display appears as a Polaroid photo with the file name written underneath, on a pinboard or a table. If Windows can give us a thumbnail, the Polaroid shows it.
- Detail by distance: far = 512 px; when you stop and look, or hold it, it sharpens to full resolution.

**Interactions:** look; point to pause that canvas; swipe/stick to step through its images; grab to hold it up close (with pinch/stick zoom); throw it back and it returns to its frame.

**The bag (image):**
- View full size (a big floating viewer, with zoom)
- Next / previous in this canvas
- Start/stop slideshow here
- Set as this room's door thumbnail (Q31)
- Open in Windows (default photo app)
- Show in folder
- Copy path
- Properties (size, dimensions, date, camera info if present)
- Add to favourites
- ✍ Rename · Move to… · Copy to… · Delete (Recycle Bin) · Rotate (saves to file)

---

## 3. Video

**Types:** `.mp4 .m4v .mkv .webm .mov .avi .wmv .flv .ts .mpg` (via the FFmpeg plugin; anything it can't decode falls back to "Open in default player").

**In the world:**
- **Cinema room** (default for long videos): rows of seats facing a big screen. Next to the entrance, a **thumbnail wall** (or a menu on a lectern) shows every video in the folder as a poster tile with title and length; this was Bit's webrips idea.
- **Sit, then play** (Q3): you sit (point at a seat or press the sit button), the screen shows the poster while the video opens and buffers, then the Play button appears. Setting: "Allow playing without sitting".
- **Living-room TV** (preference): a sofa and a TV, same rules.
- **Short clips** in a mixed room: a small screen on a plinth that plays muted on loop when you look at it (setting), full controls when you hold it.
- **Resume** (Q32): films remember where you stopped. Thumbnail tiles show a progress bar.

**Interactions:** a floating remote (or wrist controls): play/pause, scrub bar with preview thumbnails, ±10 s / ±30 s, volume, audio track, subtitles (sidecar `.srt` first), screen size (cinema / huge / wall), lights (house lights / dim / dark), passthrough off.

**The bag (video):**
- Play here / Play in cinema (takes you to the folder's cinema)
- Resume from 1:12:40 / Start over
- Choose audio track / subtitles
- Open in default player (leaves VR for the desktop)
- Show in folder · Copy path · Properties (length, resolution, codec, size)
- Set as door thumbnail (uses a frame)
- Add to favourites / watch later shelf
- Mark as watched / unwatched (stored in our DB, not the file)
- ✍ Rename · Move · Copy · Delete

---

## 4. Audio and music

**Types:** `.mp3 .flac .ogg .opus .wav .m4a .aac .wma`; playlists `.m3u .m3u8 .pls`; album art from `cover.jpg / folder.jpg` or embedded tags.

**In the world:**
- **Music room:** albums (subfolders) are **record sleeves in crates**; flick through them like a record shop. Pull one out and put it on the **turntable/jukebox** to play.
- Loose tracks in a mixed room: a small radio/speaker object; tap to play.
- A **"take it with you"** option: music keeps playing quietly as you walk elsewhere (a tiny player on the wrist).

**The bag (audio):**
- Play · Queue next · Add to queue
- Play whole folder / shuffle
- Take it with me (background play)
- Open in default player · Show in folder · Copy path · Properties (artist, album, length, bitrate)
- Add to favourites
- ✍ Rename · Move · Copy · Delete · Edit tags (later)

---

## 5. Games

**Sources:** Playnite, GOG Galaxy, Steam, Epic, emulator folders (TECH_ARCHITECTURE.md §10).

**In the world (Q12):**
- A **shop**: game cases on shelves, sortable however you like (platform, A–Z, last played, playtime, genre, recently added). Default: **one shelf per platform** (Bit's example: PSX 15, PS2 35, OG Xbox 12, X360 3, PC 512).
- Case style per platform (PS1 jewel case, PS2 tall case, Xbox green, PC DVD box), box art on the front, spine text readable from a distance.
- **A huge platform** (PC 512) gets its own **shelf wall** with A–Z tabs and a sort sign, or its own side room. Never 512 cases in one glance; you see a bay of ~40 at a time and flick along.
- A **"featured" counter**: recently played, favourites.

**Interactions:** pull a case off the shelf (it never launches, Q14), turn it over to see the back (description, genre, playtime), put it back and it slides home.

**The bag (game):**
- **Play** (via its launcher: Steam/GOG/Epic/Playnite/emulator; confirmation on first launch)
- Info (description, playtime, last played, source)
- Change box art (pick from local images, or online sources if the user opted in)
- Edit title / platform (stored in our DB)
- Open store/launcher page
- Show install folder
- Add to favourites / featured
- Copy path
- ✍ (later) Uninstall via launcher: we'd only ever hand off to the launcher

---

## 6. Applications

**Types:** `.exe` (and `.lnk` shortcuts resolved to their targets); Start Menu apps and wizard-picked favourites.

**In the world:**
- "**Use this**" wall plaques/buttons: the app icon (256 px from the exe) mounted like art, with the name underneath (from the original concept doc).
- Or, in the shop theme, an **app shelf** of icon "cases" (Q12 says likely similar to games).
- Installers and unknown executables in a normal folder show as a **sealed crate with a gear stamp** so nobody launches `setup.exe` by accident.

**The bag (app):**
- Open (confirm first time; warn if downloaded from the internet; warn if it needs admin)
- Show in folder · Copy path · Properties (publisher, version, signed?)
- Pin to wrist favourites
- Choose icon
- *Script files (`.bat .ps1 .vbs` etc.)*: no "Open" in free mode by default (setting to allow). "Show in folder" instead.

---

## 7. Documents

**Types:** `.pdf .txt .md .rtf .doc/.docx .odt .xls/.xlsx .ods .csv .ppt/.pptx .epub .html`.

**In the world:**
- **Study template:** books on shelves (spine = file name) and folders in filing cabinets.
- In mixed rooms: a paper/book on a table.
- Preview: plain text, Markdown and CSV render inside VR as a readable floating page (v1). PDFs: first page via a Windows shell thumbnail in v1; a proper in-VR PDF reader is a later feature (e.g. via a PDF library GDExtension).
- Webrip `.html` files: a "web page" frame showing a shell thumbnail; bag → Open in browser.

**The bag (document):**
- Read here (text/Markdown/CSV now; PDF later)
- Open in Windows (default app)
- Show in folder · Copy path · Properties
- Add to favourites
- ✍ Rename · Move · Copy · Delete

---

## 8. Archives

**Types:** `.zip .7z .rar .tar .gz .iso .cab`.

**In the world:** a **chest** (themed: crate, trunk, treasure chest, cardboard box) with a small label of file count and size. Disc images (`.iso .bin/.cue .chd`) in emulator folders are treated as **games**, not archives.

**Interactions (free mode):** open the lid to **peek inside** (a read-only list of the contents, read from the archive's index; nothing extracted to the user's folders). Images inside can be previewed from a temporary in-memory read **(later; zip first)**.

**The bag (archive):**
- Peek inside
- Open in Windows (7-Zip, WinRAR, Explorer)
- Show in folder · Copy path · Properties
- ✍ Extract here / Extract to… · Move · Copy · Delete

---

## 9. 3D models

**Types:** `.glb .gltf` (Godot can load these at runtime via `GLTFDocument`), `.obj` (runtime loader possible), `.fbx .blend .stl .3mf` (thumbnail via Windows, or a loot drop).

**In the world:** a **plinth/display case** with the model turning slowly on top (glTF loaded at runtime, scaled to fit a 50 cm box). A "model too big" safety: models over a triangle/texture budget show a wireframe box + Polaroid-style render instead.

**The bag (3D model):**
- Inspect (hold it, scale it up to life-size, walk round it)
- Show at real scale
- Open in Windows (Blender, 3D Viewer…)
- Show in folder · Copy path · Properties (tri count, size)
- ✍ Rename · Move · Copy · Delete

---

## 10. Unknown and everything else (Q27, Q28)

**In the world:** either a **themed object** (crate, chest, filing cabinet, depending on the world) or a video-game-style **spinning, glowing loot drop**, colour-coded by kind. User setting picks the default: "Themed objects / Loot drops / Mix (loot drops for recently changed files)".

**Loot drop colour code (default palette, colour-blind safe alternatives in settings, and every drop also has a shape/icon so colour is never the only cue):**

| Colour | Kind | Icon/shape |
|---|---|---|
| Blue | Documents | Page |
| Green | Archives | Box |
| Orange | Code / scripts / config (`.py .js .json .ini .bat`) | Brackets `{ }` |
| Purple | Design/creative files (`.psd .ai .kra .blend .aep`) | Brush |
| Red | Executables / installers | Gear |
| Yellow | Fonts, subtitles, small assets | Letter "A" |
| White | Disk images / data / databases | Disc |
| Grey | Truly unknown | Question mark |

Notes: loot drops are capped like everything else (16 visible objects; extras grouped into a "37 more files" crate per type). Freshly downloaded files (from a notification) can arrive as a drop that "falls" into the room: the fun, gamified moment.

**The bag (unknown):**
- Open in Windows (Q27)
- Open with… (Windows' "Open with" dialog on the desktop)
- Show in folder · Copy path · Properties (type, size, dates)
- Add to favourites
- ✍ Rename · Move · Copy · Delete

---

## 11. Folders (doors)

**In the world (Q30/Q31):** a labelled door; outside it the folder name and a thumbnail (auto-picked: first image, a video frame, a game cover; or user-chosen). Closer up: counts ("214 images · 3 folders"), last modified date. Locked padlock if we can't read it. A small eye icon if it's shared with guests.

**The bag (door/folder)**, opened by pointing at the door and pressing the bag button:
- Enter · Teleport inside
- Change thumbnail · Change room type (gallery/cinema/…)
- Add to favourites / teleport menu
- Share with guests ▸ (only in a session; private by default, Q21)
- Open in Windows Explorer
- Copy path · Properties (size, counts)
- ✍ Rename · Move · New folder · Delete

---

## 12. "Always" bag options (every object)

- **Put back** (return to its spot)
- **Keep in bag** (carry a reference with you; like a clipboard)
- Copy path
- Show in folder
- Properties
- Add to favourites
- Hide this from the world (local hide list; doesn't touch the file)

## 13. Things held in the bag

The bag holds **references, not files**. In free mode you can carry up to ~12 tokens (grabbed from search or picked up) and drop them on the **favourites shelf**, open them, or (✍ write mode) drop them into another room as move/copy, with confirm and undo.
