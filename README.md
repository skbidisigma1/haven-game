# Z-BEAM

A laser puzzle game with movable mirrors, fixed mirrors, and beam splitters.

Clear every zombie in one shot without hitting a researcher. Each room gives you three shots; after a miss, you can keep your arrangement and adjust it.

## Play

Open `project.godot` in Godot 4.7 or later and run the project. No addons are needed. The Web export preset writes to `build/web/` (install Godot's matching export templates first).

- Drag a mirror to move it. Pieces snap to an 8-pixel grid and cannot overlap walls, people, or other optics.
- Right-click, double-click, or press **R** over a mirror to turn it 45 degrees. **Shift+R** turns it back.
- **Space** fires. **Escape** opens the pause menu. **M** toggles sound.
- Cyan mirrors reflect from either side. Amber brackets mean an optic is bolted down.
- Violet splitters send one beam straight ahead and reflect another.

All ten rooms are available from the room selector. Cleared rooms and best shot counts are saved locally.

## Working on the game

`levels.gd` contains the level layouts and a reference solution for each room. Positions use the 1152 x 648 playfield; keep objects inside the arena (x: 16–1136, y: 104–608). New mechanics belong in `platform.gd` and `laser_gun.gd`, rather than special cases in the level controller.

The original lab, emitter, and zombie pixel art and three music tracks are in `assets/`. Menus, optics, cracks, and researchers are drawn in-game. Godot's `.import` files and script `.uid` files are kept because they hold resource settings and identities; the `.godot` cache and exported builds are ignored.

Run the campaign checks with:

```sh
godot --headless --path . --script tests/campaign_test.gd
```

These load every level, fire its reference solution through the real physics world, and check the retry, completion, and optics rules. Levels 9 and 10 also check the drag paths and rotations needed to reach their solutions. They use a separate save file so they don't alter your progress.
