# VR setup: Quest 2 via Link (UNTESTED)

*11 Oct 2026, round 3.* **Nobody has run this in a headset yet.** The code is written against Godot 4.7.2's OpenXR API and checked only with a simulated rig (`--fake-vr`) on a normal screen. Expect sizes, angles and speeds to need tuning, and possibly a bug or two in the first real run.

## Trying it (Bit's PC + Quest 2)

1. Install the **Meta Quest Link** app on the PC, connect the Quest 2 with a Link cable (or Air Link), and turn Link on in the headset.
2. In the Meta Quest Link app go to **Settings → General → OpenXR Runtime** and click **Set Meta Quest Link as active**. (If SteamVR is the active runtime it may also work through SteamVR, but use Link first.)
3. Start Snow Crash in VR:
   - **From the build:** double-click `VR on Quest 2 (UNTESTED).bat` in the unzipped `SnowCrash` folder. It runs `SnowCrash.exe --xr-mode on`. The normal `SnowCrash.exe` never tries VR (the export uses a `flat_build` feature tag that switches OpenXR off).
   - **From the Godot editor:** open `godot_skeleton/`, press Play. OpenXR is enabled in project.godot; don't pass `--flat`.
4. If OpenXR can't start (no headset, Link off, wrong runtime) the app says so in the log and carries on in flat mode, so it never just hangs. `SnowCrash.console.exe --xr-mode on` shows the log in a window. Look for the startup line `Snow Crash 0.3.0-demo · Godot 4.7.2-stable · OpenXR on`.

## VR controls

| Control | Does |
|---|---|
| Left stick | Smooth walk, in the direction you're looking (setting: comfort/locomotion = both, smooth or teleport) |
| Right stick left/right | Snap turn 30° (or smooth turn), turning around your head, not the play-space centre |
| Right stick up (hold) | Teleport arc: green = OK, red = can't land. Release to jump. (While the laser is on a menu, the stick scrolls it instead) |
| Right trigger | Use / click: doors, seats, canvases, and menu buttons (point the laser) |
| Right grip | The bag (same as Q) |
| B | Close / back (Esc) |
| A | Stand up from a seat (Space) |
| Y (left) | Wrist menu (Tab) |
| X (left) | Teleport menu (T) |
| Left menu button | Close (Esc) |

Not done yet: right stick down "step back" (UX_CONTROLS.md §2) and hand tracking.

## How it's built

- **`player/player_rig.gd`** picks the rig. If the OpenXR interface `is_initialized()` (or `--fake-vr` is given) it uses the VR controller, sets `use_xr` on the viewport, turns vsync off, and matches the physics tick rate to the headset refresh rate (90 Hz if unknown). The OpenXR session signals pause the game when you take the headset off (`session_visible`), resume it when it's back (`session_focussed`), and quit when the runtime stops.
- **`player/vr_controller.gd`** builds XROrigin3D → XRCamera3D + left/right XRController3D (the right hand uses the `aim` pose), simple box hands, a capsule CharacterBody3D for collisions, a 7 m laser (RayCast3D), and the teleport arc (ImmediateMesh) plus a landing ring. A landing spot counts only if the surface is flat enough (normal.y > 0.7).
- **Buttons become actions.** Controller buttons are turned into the same input actions the keyboard uses (`sc_interact`, `sc_bag`, `sc_close`…) through `Input.parse_input_event`. So every menu and room works the same in VR without any VR-only code. It uses Godot's default OpenXR action map; there is no custom `openxr_action_map.tres` yet. The names used are `trigger_click`, `grip_click`, `ax_button`, `by_button`, `menu_button` and `primary` (sticks).
- **Menus in VR.** A 2D CanvasLayer can't be seen in a headset, so `ui/vr_panel.gd` draws any 2D UI into a SubViewport shown on a quad, and turns laser hits into mouse moves and clicks.
  - **Wrist panel:** the wrist menu, 760 × 560 px shown 0.32 m wide. It floats 0.14 m above the left controller and turns to face your eyes.
  - **Screen panel:** the rest of the UI (HUD toasts, Teleport, bag, info, setup wizard), 1280 × 720 px shown 2 m wide about 1.5 m in front of you. It follows lazily when you turn your head more than 40° away. It only takes laser clicks while a menu is open, so it doesn't block the room.
- **Placement:** `teleport_to` turns you to face the right way and then moves the origin so your *head* ends up on the target (so room-scale offsets don't put you inside a wall). `sit_at` / `stand_up` handle cinema seats.

## Things to check and tune in the headset (in order)

1. Does it start at all with `--xr-mode on`, and is the floor at the right height?
2. Do the controller buttons do what the table says? (If the action names differ, the fix is an `openxr_action_map.tres`.)
3. Laser: does it come out of the right controller in the right direction, and can you click wrist-menu buttons reliably?
4. Wrist panel size (0.32 m), height above the hand (0.14 m) and angle. Is the text readable?
5. Screen panel distance (1.5 m), size (2 m) and the 40° follow rule.
6. Snap turn 30° and walk speed 2 m/s. Comfort.
7. Teleport arc reach and the landing ring.
8. Framerate in a big gallery room (target 90 fps on Link; RoomCache keeps 1–10 rooms in memory, set in the wrist menu).
9. Taking the headset off and putting it back on pauses and resumes.
10. Cinema: sitting (trigger on a seat), standing (A), and the screen size from the seat.

## Testing without a headset

```
godot --path godot_skeleton -- --fake-vr --root=/tmp/snowcrash_fixture/Webrips
# scripted check + screenshots 70–73:
xvfb-run -a -s "-screen 0 1600x900x24" godot --path godot_skeleton \
  --rendering-driver opengl3 --rendering-method gl_compatibility --xr-mode off --resolution 1600x900 \
  -- --fake-vr --root=/tmp/snowcrash_fixture/Webrips --root=/tmp/snowcrash_fixture/Films --tour-set=vr --tour=/tmp/shots
```

`--fake-vr` builds the whole VR rig and both panels with made-up head and hand poses. The tour fires a real laser click on the wrist menu's Settings tab, and checks that teleporting puts the head on the target. Both print PASS. This proves the panel and teleport code paths run; it doesn't prove anything about real tracking.
