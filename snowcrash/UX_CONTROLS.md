# Project Snow Crash: UX and Controls

*Drafted 11 Oct 2026. Based on Q36 (wrist menu on one arm, the bag on the other hand) and Q37 (flat-screen WASD). Quest 2 Touch controllers are the reference; other OpenXR controllers map through Godot's action map.*

## 1. Principles
1. **One wrist for "where/what", one hand for "this thing".** Left wrist = main menu (search, teleport, settings, notifications). Right hand = the bag. Swappable for left-handers.
2. **Nothing important hides behind a gesture only.** Every gesture has a button, and every button has a menu entry.
3. **Point, then act.** Highlight on hover, act on trigger. No accidental actions from just looking.
4. **Comfort is a first-class setting**, offered in the first-run wizard, not buried.
5. **Flat mode is a real program**, not a debug camera (Q37): testers will help polish it.

---

## 2. VR controls (default: right-handed)

### 2.1 Quest 2 Touch mapping

| Input | Left controller (wrist hand) | Right controller (bag hand) |
|---|---|---|
| Thumbstick | Move (smooth locomotion, or off in teleport-only mode) | Left/right = snap or smooth turn · Up (hold) = teleport arc · Down = step back |
| Thumbstick click | Toggle walk/run | Recentre view |
| Trigger | Point and select on the wrist menu / UI | Point and select / interact (press buttons, sit, open doors) |
| Grip | Grab (two-handed inspect) | **Grab: picks up the object and opens the bag** |
| X | Quick **teleport menu** | |
| Y | **Wrist menu** open/close (also: turn your wrist to look at it) | |
| A | | Bag on what you're pointing at, *without* picking it up (handy for doors and far canvases) |
| B | | Back / close / put back |
| Menu (≡) | Pause + settings | (Meta button reserved by the system) |

Hand tracking (later, optional): pinch = trigger, fist = grip, palm-up look = wrist menu.

### 2.2 Swap hands
Settings → Controls → "Wrist menu on: Left / Right". Everything above mirrors.

### 2.3 Locomotion options
- **Smooth** (default for experienced users), with speed slider.
- **Teleport** arc (default for new users, suggested in the wizard).
- **Both** (stick moves, push up for teleport).
- **Treadmill** mode: treats treadmill input (as a gamepad/keyboard device, which most VR treadmills emulate) as forward walking; disables path-shortening surprises near you; long guided walks welcome.
- **Seated** mode: raises your viewpoint to standing height, everything reachable from a chair.
- Room-scale: walk physically; the world doesn't care.

---

## 3. The wrist menu (left wrist by default)

> **In the demo (round 3):** `ui/wrist_menu.gd` has four tabs: Search, Teleport, Settings (slideshow, rooms kept in memory, volume, mute, change my folders) and Alerts. Its header has the clock, where-am-I and "Up a room". On a flat screen it opens with Tab (`/` jumps to Search, N to Alerts). In VR it opens with Y and floats over the left hand; it is untested in a headset (VR_SETUP.md). The demo's Quest 2 button mapping is in VR_SETUP.md and follows §2.1, except that right stick down (step back) isn't done yet.

Turn your left wrist toward your face (or press Y) and a small panel opens above your watch spot. Operated with the right hand's pointer/finger.

```
┌──────────────────────────────────────┐
│  12:41   D:\Webrips\SiteA\Images  🔔3 │   ← clock, where you are, notification badge
├──────────┬──────────┬────────┬───────┤
│ 🔍 Search│ 🧭 Teleport│ 🔔 Alerts│ ⚙ Settings│ ← four big tabs
├──────────┴──────────┴────────┴───────┤
│  ⭐ Favourites   🏠 Spawn   ⬆ Up a room │ ← quick actions
│  ▶ Now playing: (mini player)          │
│  🎞 Slideshow: 3s  [Off 1 2 3 4 5]     │ ← room controls (context)
└──────────────────────────────────────┘
```

- **Search:** text field (virtual keyboard), filter chips (Pictures, Videos, Games, Docs, This room, This drive), results list (see §6).
- **Teleport:** drives → folders tree, favourites, recent rooms (§5).
- **Alerts:** notifications list: View / Go there / Ignore; do-not-disturb.
- **Settings:** the tree in §8.
- **Context strip:** changes by room: slideshow interval in galleries, lights and screen size in cinemas, sort order on shelves.
- **Guided walk** banner when active: "Walking to *holiday.jpg*: 3 rooms · Stop".
- Panel can be **pinned** in the air (grab its edge) for longer sessions, e.g. reading search results.

---

## 4. The bag (right hand by default)

### 4.1 How it opens
- **Grip** on an object: you hold it, and the bag fans out as a **radial menu** around your right hand (or beside the held object).
- **A** while pointing: the bag opens for the thing you're pointing at, without picking it up.
- Flat mode: **right-click**.

### 4.2 Radial layout (8 slices max, then "More…")

```
                 [ Open / Play ]
      [ Info ]                   [ Show in folder ]
  [ Favourite ]     (object)        [ Copy path ]
      [ More… ]                  [ Keep in bag ]
                 [ Put back ]
```

- **Top** is always the primary action (View / Play / Read / Peek inside / Enter).
- **Bottom** is always Put back / close.
- Selection: tilt the right thumbstick toward a slice and release, or point and trigger. Slices are big (comfortable at arm's length) and labelled with icon + text.
- **More…** opens a list panel with the full options for that type (ROOM_TYPES.md).
- ✍ **write options** appear greyed with a lock in free mode; selecting one shows a gentle "Write mode is a supporter feature" card *once*, then never nags again unless asked.
- The bag's rim shows **tokens** for things you're carrying (grabbed from search or kept). Tap a token to open its bag.

### 4.3 Feel
- Soft haptic tick when moving between slices, a fuller pulse on select.
- The bag is a slightly worn leather satchel in the Metaverse/mansion themes, a canvas tote on the island, a clean glass ring in the bare world (cosmetic only).

---

## 5. Teleport flow (Q4)

1. Press **X** (or wrist → Teleport).
2. A panel shows **drives** as big tiles (with world icon: building/island/hall) plus **Favourites** and **Recent**.
3. **Pick a drive** → you land at its front door.
   **Or drill in**: tap the arrow on a drive tile to browse its folders like a tree (breadcrumbs at top, folders as tiles with thumbnails). Pick a folder → land inside that room, facing its main wall/screen.
4. Brief fade (0.3 s, comfort) and you're there. The previous location is pushed onto a **Back** stack (wrist → Back).
5. Teleport targets respect guest visibility in shared sessions.

Physical teleport points in worlds (the Port's directory, the museum map plinth, the mansion guestbook) open the same panel.

---

## 6. Search flow (Q22)

1. Wrist → **Search** (or flat: `/` or Ctrl+F).
2. Type with the virtual keyboard (laser or poke typing). Voice input later.
3. Results appear live (Everything where installed; otherwise our index), each with thumbnail, name, path and type colour.
4. Choose an action per result:
   - **Teleport**: jump there; the item glows.
   - **Grab**: it drops into the bag as a token. Nothing else happens (Q22b).
   - **Walk there**: a soft floor ribbon and wrist arrow guide you; with **path shortening** (default on, setting "Shorten guided walks: Off / A bit / A lot") the world quietly reshapes out of sight to cut the walk. You never see it change.
5. Stop the walk any time from the wrist banner.

---

## 7. Cinema and gallery interactions
- **Gallery:** point at a canvas: trigger = pause/resume that canvas; right stick left/right = previous/next (while pointing); grip = hold it close; wrist strip = slideshow interval (1–5 s / off).
- **Cinema:** point at a seat → trigger to **sit** (smooth fade, you're seated, view aligned to screen). The **Play** button appears once the video has buffered (Q3). Controls on a floating remote (grab it) or the wrist strip. **Stand up**: B or push the stick back. Leaving saves your place.

---

## 8. Settings menu tree (Q19: "full normal program settings")

```
Settings
├── General
│   ├── Language
│   ├── World (Bare · Metaverse City · Museum Quad · Island · Mansion · Installed packs…)
│   ├── Start in: last location / spawn / favourites
│   ├── Unknown files appear as: Themed objects / Loot drops / Mix
│   ├── Videos open in: Cinema / Living-room TV / Ask
│   ├── Show hidden & system files (off)
│   ├── Skipped folders… (list)
│   └── Run setup wizard again
├── Comfort
│   ├── Locomotion: Smooth / Teleport / Both
│   ├── Move speed
│   ├── Turning: Snap / Smooth · Snap angle (15/30/45/90°) · Smooth turn speed
│   ├── Vignette when moving: Off / Low / Medium / High
│   ├── Fade on teleport and room changes (on)
│   ├── Seated mode · Height adjust · Recentre
│   ├── Treadmill mode
│   ├── Shorten guided walks: Off / A bit / A lot
│   └── Reduce motion (no cycling animations, no swaying props)
├── Controls
│   ├── Wrist menu on: Left / Right
│   ├── Open wrist menu by: Button / Look at wrist / Both
│   ├── Bag: Radial / List
│   ├── Haptics strength
│   ├── Flat-screen key bindings… · Mouse sensitivity · Invert Y
│   └── Gamepad bindings…
├── Rooms & Media
│   ├── Room density: Cosy / Normal / Roomy (items per room)
│   ├── Slideshow default: Off / 1 / 2 / 3 / 4 / 5 s
│   ├── Sit before playing (on)
│   ├── Resume films (on)
│   ├── Subtitles default
│   ├── Default sort (name / date / size / type)
│   └── Auto-group big folders by year (off)
├── Audio
│   ├── Master · Ambient · Interface · Media · Notifications (sliders + mute)
│   ├── Mute ambient in cinemas
│   └── Output: headset / desktop default
├── Display & Performance
│   ├── Quality preset: Low / Normal / High / Custom
│   ├── Rooms kept cached (Q33): 1–8
│   ├── Texture memory budget
│   ├── Canvas resolution: 512 / 1024 / 2048
│   ├── Door previews: Off / Label + thumbnail / Live (one door)
│   ├── Render scale · Refresh rate (72/80/90/120)
│   ├── Foveated rendering (if supported)
│   └── Thumbnail cache size · Clear cache
├── Notifications
│   ├── Watch for new files in: (list of folders/drives)
│   ├── Do not disturb · Mute during films
│   └── Style: Wrist panel / Floating toast
├── Search
│   ├── Search engine: Everything (detected / not found) / Built-in index
│   ├── Everything instance (default / 1.5a)
│   └── Max results
├── Launchers & Games
│   ├── Import from: Playnite · GOG Galaxy · Steam · Epic (on/off each, last imported, Re-import)
│   ├── Emulators: platform → command line
│   ├── Online box art (off; needs consent)
│   ├── Confirm before launching (on) · Allow script files (off)
│   └── Release VR while a launched app runs
├── Privacy & Sharing
│   ├── Guests see: nothing until I share (locked default in v1)
│   ├── Shared rooms list (revoke)
│   ├── Hide list (objects/folders hidden from the world)
│   └── Telemetry / crash reports (off; opt-in)
├── Write mode (✍)
│   ├── Status: Locked / Unlocked
│   ├── Unlock (supporter key)
│   ├── Confirm style: hold to confirm / two-step
│   └── Undo history
├── Accessibility (see §10)
└── About (version, licences, credits, GitHub, report a problem)
```

---

## 9. Flat-screen controls (Q37)

| Action | Keyboard & mouse | Gamepad |
|---|---|---|
| Move | W A S D | Left stick |
| Look | Mouse | Right stick |
| Run | Shift (hold) / toggle in settings | Left stick click |
| Interact / select | Left click or **E** | A |
| **The bag** | **Right click** (or Q) | X |
| **Wrist menu** | **Tab** | Back/View |
| Teleport menu | **T** | Y |
| Search | **/** or Ctrl+F | Y (hold) |
| Notifications | **N** | |
| Back (previous location) | Backspace / Mouse 4 | B |
| Up one room (parent) | Alt + ↑ (like Explorer) | |
| Sit / stand | Space (near a seat) | A |
| Next / previous image | Scroll wheel (while looking at a canvas) | D-pad |
| Slideshow interval | 0 (off), 1–5 | |
| Crouch / fly (accessibility) | C / F (fly toggle) | |
| Pause / settings | Esc | Start/Menu |

Flat UI: the wrist menu becomes a docked side panel; the bag becomes a radial pie at the mouse cursor (with keyboard numbers 1–8); a centre-dot crosshair with a hover outline shows what you'll interact with. Optional "Explorer mode" overlay: a classic address bar at the top that shows (and accepts typed) paths.

---

## 10. Comfort and accessibility

**Comfort**
- Snap turn default 30°; smooth turn optional.
- Tunnel vignette while moving (default Low for new users).
- Fades for teleports, room swaps and sitting.
- No forced camera motion, ever. Path shortening never moves *you*, only unseen geometry.
- Stable horizon; no head bob.
- Break reminder (optional, after 45/60/90 minutes).

**Accessibility**
- **Text size** (S/M/L/XL) for labels, menus, search results; door labels readable from 3 m at M.
- **High-contrast** UI theme; colour-blind loot palettes (deuteranopia, protanopia, tritanopia) and **shape icons on every colour code**.
- **One-handed mode**: wrist menu and bag both on the same hand, with a toggle button to switch between them.
- **Seated / wheelchair**: seated mode, height offset, reach-assist (pull objects to you with the pointer; no need to bend to low shelves).
- **Reduced motion**: canvases cross-fade instead of slide; loot drops stop spinning.
- **Subtitles/captions** for tutorial voice and any UI sounds that carry meaning.
- **Screen reader-ish narration** (later): read out labels on hover via Windows TTS.
- **Remappable everything**, including flat-screen keys and VR buttons.
- **Low vision**: zoom on held objects, magnifier tool on the wrist.
- **Treadmill / no-arms players**: gamepad-only play supported fully.
