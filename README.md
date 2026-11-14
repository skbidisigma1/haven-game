# Laser Strategy Puzzle

A strategy puzzle game built in **Godot 4.7+**.

Strategically place and rotate reflective mirror platforms to redirect a laser beam across the room. Neutralize all zombies caught in the trajectory while keeping civilians completely safe!

---

## 🎮 How to Play
1. **Move Platforms**: Click and drag any mirror platform with the **Left Mouse Button**.
2. **Rotate Platforms**:
   - **Double-click** a platform with the Left Mouse Button to rotate 45°.
   - Press **`R`** while hovering over or dragging a platform to rotate 45°.
   - **Right-click** on a platform also rotates 45°.
3. **Launch the Laser**: Click the green **"GO"** button when you are satisfied with your placements.
4. **Tries System**:
   - You have **3 tries** per level attempt.
   - If an attempt fails, click **"Edit Placements"** to tweak your platform positions without starting over, or **"Start Over"** to reset to default.
   - When all zombies are struck with 0 civilian casualties, the **VICTORY** menu appears!

---

## 📂 Project Structure
```
├── project.godot           # Godot project configuration (entry: scenes/main_menu.tscn)
├── main.tscn               # Main gameplay arena and game controller
├── scenes/
│   ├── main_menu.tscn      # Main title menu with Play button
│   ├── level_select.tscn   # Level selection menu (Levels 1 to 10)
│   ├── laser_gun.tscn      # Wall-mounted emitter with gradual beam animation
│   ├── platform.tscn       # Draggable/rotatable reflector platform
│   ├── zombie.tscn         # Target node (solid green -> turns red when struck)
│   ├── humanoid.tscn       # Civilian node (solid blue -> turns red when struck)
│   ├── obstacle_wall.tscn  # Solid barrier blocking laser rays
│   └── ui.tscn             # HUD controls bar, 3-tries counter, Victory & Defeat menus
├── scripts/
│   ├── game_state.gd       # Autoload managing active level index
│   ├── main.gd             # Game manager, level definitions (1-10), and rule evaluation
│   ├── laser_gun.gd        # Multi-bounce physics raycasting & 0.25s beam animation
│   ├── platform.gd         # Mouse drag, clamp bounds, double-click & 'R' key rotation
│   ├── target.gd           # State and color shifts for zombies and civilians
│   ├── ui.gd               # HUD signals, tries display, victory & failure dialogs
│   ├── main_menu.gd        # Main menu transition
│   └── level_select.gd     # Level grid selection logic
└── assets/                 # (Ready for custom art & audio)
    ├── sprites/            # Place your 2D PNG sprites here
    ├── audio/              # Place your sound effect files (.wav) here
    └── music/              # Place your background music tracks (.ogg) here
```

---

## 🎨 Asset Replacement Guide (For Artists & Sound Designers)

The game currently uses solid-colored prototype rectangles so that the core mechanics, raycast physics, and puzzle layouts are 100% playable before any custom art is added.

### 1. Sprites (`assets/sprites/`)

| Asset | Suggested Dimensions | Description |
| :--- | :--- | :--- |
| **`laser_gun.png`** | ~48 × 24 px | Sci-fi laser cannon mounted on the wall, facing right. |
| **`platform.png`** | ~130 × 24 px | Mirror platform with a metallic back and reflective glass front. |
| **`zombie.png`** | ~46 × 46 px | Monster / zombie sprite. |
| **`zombie_hit.png`** | ~46 × 46 px | Burning or electrocuted state when hit by the laser. |
| **`civilian.png`** | ~46 × 46 px | Civilian / scientist / innocent character. |
| **`civilian_hit.png`** | ~46 × 46 px | Panicked or alert frame if struck by the laser. |
| **`wall.png`** | 24 × 200 px (or 9-slice) | Industrial obstacle barrier texture. |
| **`menu_background.png`** | 1152 × 648 px | Background art for the Main Menu and Level Select. |

#### How to Add Sprites in Godot:
1. Place PNG files into `assets/sprites/`.
2. Open the scene (e.g. `scenes/zombie.tscn`).
3. Add a `Sprite2D` node (or replace the `ColorRect`).
4. Drag your texture into the `Texture` property in the Inspector.
5. In `scripts/target.gd`, swap the texture on `set_hit(true/false)`.

---

### 2. Audio & Music (`assets/audio/` and `assets/music/`)

| File | Format | Recommended Sound Style |
| :--- | :--- | :--- |
| **`laser_fire.wav`** | `.wav` | Crisp sci-fi energy blast when pressing "GO". |
| **`laser_bounce.wav`** | `.wav` | Metallic ping or glass chime when the beam bounces. |
| **`zombie_hit.wav`** | `.wav` | Sizzle / zap sound when a zombie is hit. |
| **`civilian_hit.wav`** | `.wav` | Alarm / siren sound when a civilian is caught in the line of fire. |
| **`level_win.wav`** | `.wav` | Short fanfare or chime when clearing a level. |
| **`level_fail.wav`** | `.wav` | Low buzzer or fail chime when an attempt fails. |
| **`bgm_puzzle.ogg`** | `.ogg` (looping) | Atmospheric, synth or ambient puzzle background track. |

#### How to Add Audio in Godot:
1. Place `.wav` sound effects in `assets/audio/` and looping `.ogg` tracks in `assets/music/`.
2. Add an `AudioStreamPlayer` node to the scene (e.g. in `scenes/laser_gun.tscn` or `scenes/main.tscn`).
3. Assign the audio file to the `Stream` property in the Inspector.
4. Trigger in script with `$AudioStreamPlayer.play()`.

---

## ⚙️ Adding or Editing Levels
All 10 levels are defined in `scripts/main.gd` in the `levels` array. Each level is a simple dictionary:
```gdscript
{
    "name": "Level Name",
    "gun_pos": Vector2(32, 160),
    "gun_rot": 0.0,
    "platforms": [ {"pos": Vector2(300, 320), "rot": 0.0} ],
    "zombies": [ Vector2(750, 480) ],
    "humanoids": [ Vector2(500, 160) ],
    "walls": [ {"pos": Vector2(500, 300), "size": Vector2(24, 200)} ]
}
```
To create new levels or tweak obstacle positions, simply edit or append to this array!
