# Project Snow Crash: World blockouts

*Drafted 11 Oct 2026. Greybox specs for the four stock worlds in WORLDS.md: the sizes, the modular kit pieces, and the lighting for each. These are starting numbers for a level artist (or for Bit). Nothing here is final art. Three are greyboxed in Godot: the Museum Quad (`world_museum.gd`, screenshots 30–34), the Island (`world_island.gd`, 50–55) and the Metaverse City Street (`world_city.gd`, 60–65), all in `godot_skeleton/world/`. The "as built" notes say where the greybox differs from the spec. The House / Mansion is spec only.*

All sizes are in metres. Godot is Y-up, and −Z is "forward" from the spawn point.

---

## 0. Shared rules (every world)

### 0.1 Human scale (VR comfort first)

| Thing | Size | Why |
|---|---|---|
| Eye height (flat mode) | 1.65 | Average standing eye height; VR uses the real headset height |
| Walk / run speed (flat) | 3.0 / 6.0 m/s | Already set in `flat_controller.gd`; VR uses comfort settings |
| Interaction reach (pointer) | 7.0 | Long enough to click a door across a small room |
| Standard door | 1.1 × 2.2 | Already used by `door.gd`; wider than a real door to make it easy in VR |
| Doorway clearance (frame) | 1.4 × 2.5 | Leaves room for the frame and a label above |
| Ceiling, standard room | 4.5 | Feels airy in VR; a 2.4 m ceiling feels cramped in a headset |
| Corridor width | ≥ 3.0 | Two people side by side; no wall brushing |
| Step height (visual) | 0.15 to 0.30 | Always with an **invisible ramp** collider underneath (the flat controller can't climb steps, and VR players shouldn't "bump" up them) |
| Railings | 1.0 high | Wherever a drop is over 0.5 m |
| Canvas (picture) max | 1.7 × 1.25 | `canvas.gd`; hung with its centre at 1.6 |
| Cinema screen | 7.2 × 4.05 (16:9) | `cinema.gd`; bottom edge 1.0 above the floor |
| Seat pitch | 1.2 × 1.1 | 3 rows × 4 seats in the demo cinema |

### 0.2 Grid and snapping

- The kit snaps to a **0.5 m grid**. Wall modules are **4 m wide**, so 4 = 8 grid units.
- Rooms are built from a **4 m bay**: the standard room is 16 × 14, i.e. 4 × 3.5 bays.
- Every module has its pivot at the floor, at the centre of the wall face. That way a module dropped on the grid lines up without nudging.
- Sockets are empty nodes named `Socket_Door_*`, `Socket_Canvas_*`, `Socket_Loot_*` and so on, as in the World SDK (WORLDS.md §6). The skeleton keeps them as arrays in `room_builder.gd` for now: `CANVAS_SOCKETS`, `DOOR_SOCKETS`, `DOOR_SOCKETS_AHEAD` and `BACK_DOOR`.

### 0.3 Standard room shell (all worlds re-skin this)

- **Interior** 16 (W) × 14 (D) × 4.5 (H). Spawn at (0, 0, 4.6), facing −Z. The back door is directly behind you at (0, 0, 6.9).
- **12 canvas sockets:** 6 on the back wall, then 3 on each side wall.
- **Door sockets:** on the side and front walls when the room has pictures. When it has no pictures, 5 go on the far wall, straight ahead.
- **Loot grid:** 4 per row, 1.8 m apart, on the floor between the spawn point and the far wall.
- Each room sits in its own **pocket** 1000 m from the others (impossible space), so the outside never has to "contain" it.

### 0.4 Shared modular kit (every world needs a version)

| Piece | Size | Notes |
|---|---|---|
| `floor_4x4` | 4 × 0.2 × 4 | Tiling floor; the material comes from the theme |
| `wall_4` | 4 × 4.5 × 0.2 | Plain wall |
| `wall_4_door` | 4 × 4.5 × 0.2 | Wall with a centred 1.4 × 2.5 opening and a door socket |
| `wall_4_canvas` | 4 × 4.5 × 0.2 | Wall with a canvas socket at a height of 1.6 |
| `wall_corner_in` / `_out` | 0.2 × 4.5 × 0.2 | Hides seams |
| `ceiling_4x4` | 4 × 0.2 × 4 | Has a light socket in the middle |
| `door_frame` + `door_panel` | 1.4 × 2.5 / 1.1 × 2.2 | Thumbnail quad 0.6 × 0.45 at a height of 1.45; name label above |
| `canvas_frame` | scales to the image | Frame width 0.06; plaque socket below |
| `plaque` | 0.5 × 0.3 | Slideshow / museum label |
| `loot_pedestal` | ⌀ 0.5 × 0.05 | Glow ring for loot drops |
| `crate` | 0.8 cube | Grouped loot |
| `seat_cinema` | 0.7 × 1.0 × 0.8 | Its "sit" point is at a height of 0.45 |
| `tv_corner` | 2 × 2 footprint | TV + sofa ("make this a cinema") |
| `sign_board` | 2.4 × 1.2 on a 1.4 post | Tutorial and info signs |
| `teleport_point` | ⌀ 1.0 | Map plinth / Port / guestbook stand-in |
| `vestibule` | 3 × 3 × 3 | Door alcove where invisible room swaps happen |

### 0.5 Shared lighting rules

- **Interiors:** 4 to 6 soft omni lights at a height of 3.3, energy about 0.9, plus ambient light from the sky. No real-time shadows at Tier 0. One shadowed key light at Tier 1+.
- **Exteriors:** one directional sun plus a procedural sky, and fog for depth. Lightmaps are baked for static outdoor geometry at Tier 1+.
- **Readability beats mood.** Labels and thumbnails must stay readable everywhere, so nothing goes darker than about 20% grey where text sits.
- **Target:** 90 Hz on a Quest 2 over Link at Tier 1, which works out to about 300 draw calls and about 750k visible triangles per eye. Use MultiMesh for trees, seats and columns.

---

## 1. The Metaverse City (Tier 1, Tier 2 for reflections): Street greyboxed in Godot

### 1.1 Layout and dimensions

- **The Street:** a straight boulevard 60 m wide (a 20 m road, 2 × 10 m pavements and 2 × 10 m building setbacks), built in **100 m tiles**. Each tile holds up to 4 drive plots (2 per side).
- **Length:** endless in both directions. Tiles recycle beyond the last drive, and empty tiles get generic "background" towers.
- **Port (spawn):** a 6 × 6 × 4 m terminal booth on the left pavement at the origin, with a ⌀ 3 m floor ring and a 3 × 2 m directory screen (the teleport menu).
- **Drive buildings:** plots 40 × 40 m. Footprint 24 × 24 to 36 × 36 m. Height = 20 + 12·log₂(drive size in TB + 1), clamped to 20–80 m, so a 4 TB drive is about 48 m. The front door is a 3 × 4 m portal at street level. A lit name sign 12 × 3 m sits at 8 m up.
- **Monorail:** a 2 m wide beam at a height of 14 m down the centre line; pillars every 50 m.
- **Interiors:** an elevator lobby 20 × 16 × 6 m (the drive root), then standard rooms.

### 1.2 Kit pieces (on top of the shared kit)

`street_tile_100` (road + pavements + kerbs), `pavement_light` (6 m pole), `port_booth`, `port_ring`, `directory_screen`, `tower_base_A/B/C` (3 lobby styles), `tower_mid_10m` (stackable floor block, 3 window styles), `tower_crown_A/B` (roof tops), `neon_sign_frame` (resizable), `monorail_beam_50`, `monorail_pillar`, `bg_tower_lowpoly` (background filler, 8 variants), `holo_billboard` (animated texture, Tier 2), `elevator_doors` (the room door, re-skinned), `lobby_desk`.

### 1.3 Lighting

- **Sky:** permanent night, near-black with a faint magenta horizon glow. No sun. A weak cool directional "moonlight" (energy 0.15) for shapes.
- **Neon signs** use emissive materials plus a few baked area lights. Only the nearest ~8 signs get real omni lights (a pool, nearest first).
- **Wet street:** at Tier 2, screen-space reflections. At Tier 1, a baked reflection probe per tile plus a glossy roughness map.
- **Fog:** volumetric at Tier 2, otherwise distance fog from 80 to 300 m in deep blue.
- **Interiors:** cooler, slick gallery lighting (white 5000 K strips). The cinema is near-black with aisle lights.

### 1.4 As built in the greybox (`world_city.gd`, round 3)

- **Axes:** the Street runs along −Z from the Port. Road 20 m wide (x −10 to +10) with kerbs, lane dashes and 10 m pavements, then a 30 m setback strip each side. One 700 m straight piece rather than recycled 100 m tiles. Invisible barriers 75 m out each side and at both ends.
- **Port 0 (spawn):** a 6 × 6 × 4 m booth at (−15, 0, 2) on the left pavement, open towards the Street. It has a ⌀ 3 m glowing floor ring, a "PORT 0" neon strip, and a 3 × 2 m **Directory** screen just outside that opens the Teleport menu (point and press E, or T anywhere). Spawn is at (−15, 0, 2.5) inside the booth, facing down the Street, turned 20° towards the road.
- **Towers:** one per location, alternating left and right. A pair of plots every 45 m (the right-hand one 8 m further on), starting 22 m from the Port. The front face sits on the setback line (x = ±20).
  - Each tower has a 14 × 6 × 10 m lobby box reaching to the pavement, with a neon strip and the door (1.6× scale portal), and a 12.4 × 3.4 m neon name sign on the lobby roof's front edge (centre 8.2 m up).
  - The tower body is 26–34 m square and 26–60 m high, then window bands every 3.5 m and a glowing crown.
  - Height and width come from a hash of the path for now. The spec's log₂(drive size) rule needs drive sizes from the scanner (TODO).
- **Monorail:** 2 × 1.2 m beam at 14 m down the centre line with a cyan glow strip; ⌀ 1.2 m pillars every 50 m (on the centre line, so they're in the road; real kit should use a central reservation).
- **Lamps:** 6 m poles every 25 m on both kerbs; only the first few have real omni lights.
- **Background:** seeded filler towers (18–90 m) behind the plots with random neon strips, plus a far skyline of 40–160 m blocks.
- **Lighting:** permanent night, a dark-blue/magenta sky, moonlight energy 0.18, ambient 0.35, deep-blue fog (density 0.006), glow on. No SSR or volumetrics yet (Tier 2 TODO).
- **Rooms:** the white-cube gallery theme with neon trim (`ROOM_THEME`). No elevator lobby yet: the door goes straight into the folder.
- **Not done:** endless tile recycling, the elevator lobby, holo billboards, real tower kit, drive-size heights, and a second Port.

---

## 2. The Museum Quad (Tier 1): greyboxed in Godot

### 2.1 Layout and dimensions (as built in `world_museum.gd`)

- **Ground:** a 160 × 160 lawn.
- **Landing circle (spawn):** at the centre, ⌀ 14 paved with a ⌀ 10 inner stone disc. Spawn at (0, 0, 4.5), facing the first building (C:).
- **Map plinth:** 1.2 × 1.1 × 0.6, 2.2 m in front of the spawn. It's the physical teleport menu ("Press T").
- **Cross paths:** 4 m wide, running from the circle to each axis, 60 m end to end.
- **Buildings:** up to **6** in a ring, front faces at **radius 30** from the centre and 60° apart. More than 6 drives? A second quad through an archway (not built yet).
- **Building:** body **22 (W) × 11 (H) × 16 (D)** on a 24 × 1.2 × 18 podium. Visual steps: 4 treads, 12 wide, 0.3 rise × 0.6 going, with an invisible 12 × 2.6 ramp over them.
- **Portico:** 6 columns (⌀ 1.1, 8 m tall) 1 m in front of the body, with an entablature 19 × 1.2 × 4.4 and a triangular pediment 19 × 2.6.
- **Banners:** two, 1.4 × 4.0, at ±5.2. The name is carved into the entablature.
- **Front door:** the standard door scaled 1.6× (1.76 × 3.52) at the centre of the portico. It leads straight into the drive's root room. The demo has no lobby here, which may change (see question 48).
- **Trees** are scattered in a ring between 12 and 24 m from the centre, avoiding paths. **Benches** (2.0 × 0.5 × 0.6) are placed on a radius of 8.5.
- **Interiors:** the standard room with the museum theme: warm stone walls, dark wood floor, gilt frames.

### 2.2 Planned additions (not in the greybox yet)

- An **entrance hall** per building, 24 × 18 × 9, with a directory board, before the galleries.
- **Rope barriers** (stanchions every 2 m) and **museum labels** (0.25 × 0.15, at a height of 1.4, beside each canvas, showing the file name and date).
- **Benches** in the middle of galleries, 3.0 × 0.45 × 0.6.
- A **fountain** in the landing circle (⌀ 6) instead of the plain disc.
- A **lecture theatre** cinema variant: raked seating, 4 rows, 0.3 rise per row with ramps.

### 2.3 Kit pieces

`lawn_tile_20`, `path_straight_4w`, `path_circle`, `podium_block`, `steps_4tread` (+ ramp collider), `column_doric_8m`, `entablature_19`, `pediment_19`, `banner_1x4` (texture slot for the drive's colour/icon), `museum_door_double`, `tree_round_A/B/C`, `bench_stone`, `bench_wood`, `lamp_post_victorian`, `map_plinth_bronze`, `archway_quad_link`, `stanchion` + `rope_2m`, `museum_label`, `gallery_bench`, `skylight_4x4` (ceiling piece).

### 2.4 Lighting

- **Outside (built):** one directional sun at −50° pitch / −30° yaw, warm white; procedural sky, pale blue. At Tier 1, add soft shadows from the sun only, on buildings and trees.
- **Portico (built):** one warm omni per building (range 10, at 6 m) so the door and name read even with the sun behind.
- **Inside:** warm 3200 K ceiling washes (the shared 4–6 omni rule), plus a **spot per canvas** at Tier 1 (cone 25°, aimed at the canvas centre from 1.5 m out at the ceiling). Skylight modules let in cool fill.
- **Mood:** calm, hushed, high readability. It's the alpha showcase world.

---

## 3. The Island (Tier 1, Tier 0 with flat water): greyboxed in Godot

### 3.1 Layout and dimensions

- **Main island:** roughly 220 × 160, a teardrop shape, with a 40 m high central hill. Playable area inside an invisible boundary at the waterline + 5 m.
- **Beach:** a 25 m deep band of sand on the south side.
- **Spawn:** on the beach, 4 m from the waterline, **facing out to sea** (+Z is the sea, so the island is behind you). A small sign says "Turn around".
- **Jetty:** 3 m wide × 30 m long, at a height of 0.8 above the water, 20 m east of the spawn.
- **Drive locales:** up to 4 on the main island, about 40 m from the spawn and 25–60 m apart, joined by 3 m sand/plank paths with gentle slopes (≤ 8°).
  - C: **beach hut village**: 3 huts, 6 × 6 × 4, the middle one has the door.
  - D: **treehouse**: platform 8 × 8 at a height of 5, reached by a ramp spiral, not a ladder.
  - E: **lighthouse**: ⌀ 6 × 18 tower; the door is at ground level.
  - F: **cave grotto**: a 5 × 4 mouth into the hill.
- **More drives:** islets ⌀ 30–50 m, 40–80 m offshore, linked by **rope bridges** (2 m wide, railings 1.0 high) or a teleport.
- **Cinema cove:** a fixed-night pocket with an open-air screen 10 × 5.6 on the sand and deck chairs. It's a room template variant, so it uses pocket space.
- **Interiors:** the standard shell re-skinned with bamboo walls, a woven floor and driftwood frames. Unknown files wash up as bottles and crates.

### 3.2 Kit pieces

`terrain_island_main` (heightmap mesh, LODs), `islet_A/B/C`, `sand_path_4`, `plank_path_4`, `jetty_10` (stackable), `rope_bridge_10`, `palm_A/B/C` (MultiMesh), `bush_tropical`, `rock_cluster_S/M/L`, `beach_hut`, `treehouse_platform` + `spiral_ramp`, `lighthouse`, `cave_mouth`, `deck_chair`, `outdoor_screen`, `tiki_torch` (light socket), `bottle_loot`, `crate_washed_up`, `bamboo_wall_4`, `woven_floor_4x4`, `driftwood_frame`, `water_plane_1km` (shader at Tier 1, flat at Tier 0).

### 3.3 Lighting

- **Default: golden hour.** Low sun at −12° pitch, warm orange (≈ 3000 K), long soft shadows (Tier 1). Sky gradient from peach to blue. Light distance fog over the sea.
- **Time of day setting:** follow real time / fixed sunset / fixed night. Night uses moonlight (cool, energy 0.2) plus tiki-torch omnis (pooled, nearest 8) and stars.
- **Water:** at Tier 1, a reflection probe at the beach plus a fresnel water shader. At Tier 0, flat, opaque and slightly emissive so it doesn't go black.
- **Interiors:** warm lamp light, no shadows. Bamboo walls let fake "sun stripes" (a projected decal) through.

### 3.4 As built in the greybox (`world_island.gd`, round 3)

- **Axes:** +Z is the sea, the island is towards −Z. An 800 m sea plane at y −0.35. A sand disc of radius 76 m (squashed to 95 % in Z), centred at (0, −0.5, −66), so the beach edge is right by the spawn. A grass disc r 54, and a cone hill (r 30 → 6, 22 m high) with a rock top at (0, 11, −84). That's smaller than the spec's 220 × 160 m teardrop and 40 m hill; it fits the demo better, so make it bigger only if it feels cramped.
- **Boundary:** an invisible ring of 20 m wall pieces at about r 74, with gaps for the jetty and the two bridges.
- **Spawn:** (0, 0, −1), **facing out to sea**. A "Lovely view! Now turn around ↻ Your island is behind you" sign stands just to the right of the spawn.
- **Jetty:** 3 × 30 m planks at 0.65–0.78 m high, 18 m east of the spawn (x = 18, z 3–33), with a ramp up from the sand and posts every 5 m.
- **Locale slots** (in order; each faces the spawn side, and its door has a signpost with the folder name, thumbnail and counts):
  1. **Hut village** at (−24, −24): 3 huts 6 × 3.6 × 6 m with pyramid roofs. The middle one has the door.
  2. **Treehouse** at (26, −30): a 9 m trunk, a 9 × 9 m platform at 5.2 m, a hut on top, a leaf canopy, and a spiral of plank steps. The door is at the foot of the trunk (as a portal); climbing comes later.
  3. **Lighthouse** at (44, −6): ⌀ 6.4 × 18 m, red bands, and a glowing lamp room with a real light.
  4. **Cave grotto** at (0, −58): a dark 7 × 5.5 m mouth in a rock pile at the foot of the hill.
  5. and 6. **Islets** at (±96, −40): ⌀ 40 m sand islets with a hut each, reached by 2 × 26 m rope bridges with rope rails at 1.3 m.
- **More than 6 locations:** the rest don't get a building on the island yet; they're still reachable through Teleport and Search. (The spec's teleport-only extra islets are a TODO.)
- **Dressing:** seeded palms (6-leaf boxes on leaning trunks) round the beach, keeping the spawn view and the slots clear, plus rock clusters.
- **Lighting:** golden hour, with the sun low over the sea (−14° pitch) so the sunset is in the opening view, and a peach-to-blue sky. Ambient 0.55, warm fog (density 0.0035), soft shadows. No time-of-day or tiki torches yet.
- **Rooms:** the bamboo theme (warm walls, woven floor, driftwood frames) via `ROOM_THEME`.
- **Not done:** the cinema cove, bottles washing up as loot, water shader, real paths between locales, and real foliage (MultiMesh).

---

## 4. The House / Mansion (Tier 1)

### 4.1 Layout and dimensions

- **Outside (small on purpose):** a two-storey country house 30 × 12 × 14 (to the ridge) on a 60 × 60 garden plot with a gravel drive. You rarely go outside; the spawn is indoors.
- **Front hall (spawn):** 14 × 12 × 7, double height, with a grand staircase on the back wall (3 m wide, 14 m run, invisible ramp) to a 2.5 m deep gallery landing.
- **Spawn:** on a ⌀ 3 compass-rose rug in the middle, facing the staircase. The guestbook table (the teleport menu) is 1.5 m to the right. A signpost names each wing.
- **Wings = drives:** C: east wing (door right), D: west wing (door left), E: upstairs (the landing), F: cellar (a door under the stairs). Further drives get an "annex" door that leads to a long gallery with more wing doors.
- **Corridors:** 3.2 wide × 3.6 high, in 8 m segments with a door socket on each side every 4 m. Corridors are pocket spaces, so they never need to fit the outside.
- **Rooms:** the standard shell re-skinned. Ceilings drop to 3.6 in "cosy" templates (library, lounge, games room); galleries keep 4.5. The home cinema has 3 rows of recliners on 0.3 risers. A "living room TV" variant reuses the `tv_corner`.

### 4.2 Kit pieces

`house_exterior` (one mesh, LODs), `gravel_drive`, `hedge_4`, `hall_double_height`, `staircase_grand` (+ ramp collider), `landing_rail_4`, `compass_rug`, `guestbook_table`, `wing_signpost`, `corridor_8` (with 4 door sockets), `corridor_corner`, `panelled_wall_4` (wood wainscot to 1.2), `wallpaper_wall_4` (3 patterns), `parquet_4x4`, `ceiling_coffered_4x4`, `fireplace` (light socket), `bookshelf_2m`, `record_player_table`, `recliner`, `sofa_3`, `portrait_frame`, `attic_trunk` (grouped loot), `window_rainy` (an emissive pane with a rain shader option), `grandfather_clock` (an audio socket).

### 4.3 Lighting

- **Inside is the whole world:** warm 2700 K lamps (table lamps, wall sconces), a fireplace glow in the hall (a flickering omni, energy 1.2, range 8), dim cool window light.
- **Rain option:** grey-blue window light plus rain-streak decals on the windows. Thunder flashes are off by default because they can be startling in VR (setting).
- **Corridors:** sconces every 4 m (MultiMesh glow cards; only 2 real omnis per 8 m segment).
- **Outside:** an overcast sky; soft directional light at −35°, no hard shadows.

---

## 5. Build order suggestion

1. **Museum Quad** (greyboxed already): swap boxes for kit meshes, add the entrance hall and labels. Best showcase for the alpha.
2. **Bare** stays the fallback and test world. It's already in the demo.
3. **Mansion**: indoors-only, so it's cheapest to make look good and it reuses the room shell heavily.
4. **Island** (greyboxed): the water and foliage need perf work.
5. **Metaverse City** (Street greyboxed): the most art and the most IP care (WORLDS.md §7).

## 6. Running the greyboxes

```
cd godot_skeleton
godot --path . -- --flat --world=museum --root="D:/Pictures" --root="D:/Films"
```

Each `--root` becomes one building (up to 6). Walk up the steps and through the door to enter that folder. Press T to teleport. Screenshots: `screenshots/30_…` to `34_…`.

The Island and the City Street work the same way:

```
godot --path . -- --flat --world=island --root="D:/Pictures" --root="D:/Films"
godot --path . -- --flat --world=city --root="D:/Pictures" --root="D:/Films"
```

On the Island, up to 6 `--root` folders get a place (huts, treehouse, lighthouse, cave, two islets). On the Street, each folder gets a tower, alternating sides. In the Windows build, use "Choose a world.bat". Screenshots: `screenshots/50_…` to `55_…` (Island) and `60_…` to `65_…` (City).
