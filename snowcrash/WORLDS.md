# Project Snow Crash: Worlds

*Drafted 11 Oct 2026. The bare default (Q16), the four vanilla worlds (Q17), spawn points (Q18), and a World SDK so people can make and share their own.*

## Shared rules for every world

- **This PC = the world.** Each world decides what a *drive* looks like (building, island, museum hall, wing) and where it sits.
- **Rooms are rooms.** Inside a drive, folders are rooms generated from room templates (ROOM_TYPES.md). Worlds re-skin the templates (materials, frames, furniture, lighting) but follow the same slot rules, so a room's layout is recognisable across worlds.
- **Impossible space is fine** (Q30). Buildings can be bigger on the inside. The *outside* only needs a front door and a sign.
- **Drive order:** C: first (nearest spawn), then by letter; the user can reorder, rename ("Bit's Archive"), recolour or hide drives. Network drives and USB sticks appear as smaller "visiting" structures that fade in when connected.
- **Spawn:** each world has a named spawn point. Teleporting to a drive lands you at its **front door**; to a folder, straight inside the room (Q4).
- **Sound:** an ambient bed per world, room tone per template, interaction sounds; all on sliders (Q19).
- **Performance tiers:** every world declares a tier. **Tier 0** = anything that runs VR at all (integrated GPU OK in flat mode); **Tier 1** = GTX 1060 / RX 580-class; **Tier 2** = RTX 3060-class. The settings menu warns if you pick a world above your machine's tier.

---

## 0. Bare (the default)

> "Just in case / low power." (Q16)

- **Look:** a soft neutral gradient (dark grey to slightly lighter, like a desktop background), an infinite matte floor with a subtle grid that fades with distance. Optional: use the user's **Windows wallpaper** as a far backdrop (read-only; setting).
- **Drives:** clean, simple blocks: frosted-glass cubes with a big drive letter, label and a capacity bar (like Explorer's "This PC" view, made 3D). Arranged in a gentle arc in front of you.
- **Spawn:** the centre of the arc, facing C:.
- **Rooms:** plain white-box rooms with soft ambient occlusion, light wood floor, simple frames. Maximum readability.
- **Lighting/mood:** flat, bright, calm. No shadows needed.
- **Sound:** near silence; a faint room tone. Interaction clicks.
- **Tier:** 0. Target 90 Hz on modest hardware. This is also the world used for testing and the demo fallback.

---

## 1. The Metaverse City (the Snow Crash world)

> Inspired by the book: people jack in at public terminals and walk out onto the Street (Q18). Our version is an *homage*, built from original art and our own wording (see the IP note below).

- **Look:** night-time, neon, a single endless boulevard running in both directions under a black sky; buildings of wildly different styles on either side; a monorail overhead (decorative, later rideable as a fast-travel line).
- **Spawn:** you materialise at a **Port**: a public terminal booth on the Street with a glowing ring on the floor. A directory screen beside the Port lists your drives (a physical teleport menu).
- **Drives:** **buildings along the Street**. C: is the first tower on your left as you exit the Port, then D:, E:… alternating sides. Building size hints at drive size (log scale, so a 4 TB drive isn't a mile high). Each has a lit sign with the drive's name.
- **Folders:** the building's interior: an elevator lobby (the drive's root room) with doors to top-level folders; deeper folders are floors/rooms reached through doors (impossible space). Cinema rooms look like small luxury screening rooms; galleries are slick white-cube galleries; game shops are neon arcades.
- **Lighting/mood:** neon signage, wet-street reflections (screen-space reflections only at Tier 2; baked fake reflections at Tier 1), moody but readable interiors.
- **Sound:** distant city hum, footsteps, occasional monorail whoosh; interiors are quiet.
- **Fun bits (later):** messenger characters delivering notifications (the parked easter egg); the Port's directory taking voice search.
- **Tier:** 1 (2 for reflections and crowds of signage).

---

## 2. The Museum Quad

> Smithsonian-style: several grand buildings around a green, one per drive, spawn in a landing quad out front (Q18).

- **Look:** a sunny grassy quad with paths, trees and benches, ringed by stately museum buildings (stone columns, wide steps, banners).
- **Spawn:** the **landing quad**: a paved circle at the centre of the green with a bronze map plinth (another physical teleport menu) facing C:.
- **Drives:** each museum building is a drive, its banner showing the drive's label ("D: Media Collection"). C: faces you; others ring the quad. More than 6 drives? A second quad through an archway.
- **Folders:** galleries and halls. The drive root is a grand entrance hall with a directory board. Image rooms are classic gallery rooms (benches, rope barriers, museum labels next to each canvas with file name and date); cinema rooms are lecture theatres; game shops are "Interactive exhibits" halls; music rooms are listening booths; documents are reading rooms; unknown files are archive/storage cases.
- **Lighting/mood:** warm daylight outside, gallery spotlights inside; calm, hushed.
- **Sound:** birds and a fountain outside; echoey hush and footsteps inside.
- **Tier:** 1. This is probably the best "showcase" world for the alpha; it fits the original "museum walkaround tour of your file system" idea perfectly.

---

## 3. The Island

> Spawn facing the sea; turn 180° to see your Robinson Crusoe island; each drive is an island home/locale (Q18).

- **Look:** a tropical island at golden hour. A long beach, palms, a little jetty, a volcano-ish hill in the middle; smaller islets nearby linked by rope bridges or a small boat.
- **Spawn:** on the beach **facing out to sea** (a calm opening view). A gentle prompt: "Turn around." Behind you: your island.
- **Drives:** each drive is a **locale**: C: a beach hut village nearest the shore, D: a treehouse in the jungle, E: a lighthouse, F: a cave grotto; more drives become nearby islets reached by bridge (or teleport). The user can choose which locale each drive gets.
- **Folders:** the inside of the hut/treehouse/lighthouse (bigger on the inside). Galleries are bamboo-walled rooms with framed pictures; cinemas are open-air screens on the beach at night (an always-night "cinema cove"); game shops are a beach shack shop; unknown files wash up as **bottles and crates** on the sand (the island version of loot drops).
- **Lighting/mood:** golden hour by default, time-of-day option (follow real time, fixed sunset, fixed night).
- **Sound:** waves, wind in palms, seabirds; lovely for a calm session.
- **Tier:** 1 (water shader + foliage are the cost; Tier 0 version uses flat water and fewer palms).

---

## 4. The House / Mansion

> A landing spot (Q18), and the "almost never-ending mansion that scales to your file system" from the original concept.

- **Look:** a large, cosy country mansion. Starts as a normal house from the outside, but the inside keeps going: grand staircase, long corridors, wings.
- **Spawn:** a **landing spot** in the front hall: a rug with a compass rose, a hallway table with a guestbook (teleport menu) and a coat stand.
- **Drives:** **wings** of the mansion. C: is the east wing, D: the west wing, E: upstairs, F: the cellar… with signposts in the front hall. Big drives get more floors; impossible space keeps corridors short.
- **Folders:** rooms suiting their contents: galleries are picture galleries with portrait frames, cinemas are a home cinema with recliners (or the living room with a TV, the preference from Q3), games are a games room with shelves, music is a lounge with a record player, documents are the library, unknown files are attic trunks.
- **Lighting/mood:** warm lamps, fireplace glow, rain on the windows option.
- **Sound:** clock ticking, fire crackle, creaky floorboards (subtle!), rain.
- **Tier:** 1.

---

## 5. Demo world (install folder world, Q10)

Not a stock world but worth listing: the demo's world is a single **building** (themeable: island, spaceship, zeppelin, village…) standing in the bare world, plus a short **tutorial** (a guide sign/voice that explains: this is one building; in the full app every drive is a building and you can pick a world). Its rooms come from the setup wizard picks. See DEMO_MVP_SPEC.md.

---

## 6. The World SDK (theme packs)

People can make worlds and share them (original concept: "customisable, user-made, shareable/uploadable"). A world is a **theme pack**: a folder (or a `.scworld` zip) that Snow Crash loads at runtime. It contains art and layout rules, **never code that touches files**.

### 6.1 Pack layout

```
my_world.scworld  (zip) / my_world/
├── world.json             # manifest (required)
├── preview.webp           # 1024x576 shown in the world picker
├── LICENSE.txt            # the creator's licence for the assets (required)
├── scenes/
│   ├── exterior.tscn      # or exterior.glb: the outdoor space
│   ├── drive_small.glb    # building/locale for a drive (variants allowed)
│   ├── drive_large.glb
│   ├── spawn.glb          # optional spawn prop (Port, map plinth, rug)
│   └── vestibule.glb      # door alcove used for invisible room swaps
├── rooms/
│   ├── gallery.json       # template overrides: slots, sizes, materials
│   ├── gallery_shell.glb  # walls/floor/ceiling mesh with named sockets
│   ├── cinema.json  cinema_shell.glb
│   ├── shop.json    shop_shell.glb
│   └── ...               # any template not supplied falls back to "bare"
├── props/
│   ├── frame.glb  crate.glb  chest.glb  loot_drop.glb  door.glb  seat.glb
├── materials/  textures/
├── audio/
│   ├── ambient_day.ogg  ambient_night.ogg  room_tone.ogg  door_open.ogg
└── lighting.json          # sky, sun, fog, time of day, environment
```

### 6.2 `world.json` manifest

```json
{
  "format": 1,
  "id": "com.example.cyberpier",
  "name": "Cyber Pier",
  "version": "1.0.0",
  "author": "Example Creator",
  "licence": "CC-BY-4.0",
  "min_app_version": "0.3.0",
  "tier": 1,
  "rating": "everyone",
  "spawn": { "node": "Spawn", "facing_drive": "first" },
  "drive_layout": {
    "type": "path",
    "path_node": "DrivePath",
    "spacing_m": 30,
    "variants": [
      { "max_size_gb": 512, "scene": "scenes/drive_small.glb" },
      { "max_size_gb": 999999, "scene": "scenes/drive_large.glb" }
    ],
    "sign_socket": "Sign",
    "door_socket": "FrontDoor"
  },
  "room_templates": {
    "gallery": "rooms/gallery.json",
    "cinema": "rooms/cinema.json",
    "shop": "rooms/shop.json"
  },
  "unknown_file_style": "loot",
  "props": { "crate": "props/crate.glb", "loot_drop": "props/loot_drop.glb", "door": "props/door.glb" },
  "audio": { "ambient": "audio/ambient_day.ogg", "volume_db": -12 },
  "lighting": "lighting.json"
}
```

`drive_layout.type` options: `path` (along a curve, like the Street), `ring` (around a centre, like the quad), `scatter` (named anchor points, like the island), `wings` (attached to a hub, like the mansion), `arc` (bare).

### 6.3 Room template override (e.g. `rooms/gallery.json`)

```json
{
  "shell": "rooms/gallery_shell.glb",
  "size_m": [12, 4, 9],
  "canvas_sockets": "Canvas_*",
  "door_sockets": "Door_*",
  "seat_sockets": "Seat_*",
  "max_canvases": 12,
  "frame": "props/frame.glb",
  "label_style": "museum_card",
  "light_preset": "gallery_spots"
}
```

Sockets are empty nodes in the glTF named by convention (`Canvas_01`, `Door_01`, `Seat_01`, `Shelf_01`, `Spawn`, `BackDoor`). The generator fills them; the creator never writes logic.

### 6.4 Rules and safety for packs
- **No scripts** in v1 packs: only glTF/scenes without scripts, textures, audio and JSON. The loader strips any script references. (A sandboxed scripting layer could come much later, if ever.)
- **Budgets enforced** per tier (triangles per view, texture memory, audio size). Packs over budget load with a warning.
- **Validator CLI/editor plugin:** `snowcrash-pack validate my_world/` checks the manifest, sockets, budgets, licence file.
- **Sharing:** v1 = share the file (GitHub, itch.io, Discord). Later = a curated in-app gallery (Steam Workshop when on Steam) with moderation: packs are reviewed against the same content rules as the project (PRIVACY_SAFETY.md), and the maintainer (Bit) has final say on what's listed.
- **Licence:** each pack must state its own licence; we recommend CC BY 4.0 or CC0 for assets.
- **Creator kit:** a Godot template project with the bare world's sockets, a Blender naming cheat-sheet, and an example pack.

## 7. IP note on the Metaverse City
Neal Stephenson's book is the inspiration, but the world must use **original art and wording**: no copied text, characters or logos. Generic ideas (a neon street, public terminals) are fine; names like "the Street", "Port" and "Metaverse" are common words but the overall product naming is worth a check before Steam (see OPEN_QUESTIONS.md).
