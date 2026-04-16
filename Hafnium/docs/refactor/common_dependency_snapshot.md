# Common Dependency Snapshot

This snapshot captures the primary `Common` consumers before the extensibility refactor.
It exists to support the staged migration to `RunContext` and to make `Common`
shrinkage observable.

## Active Call Sites

- `scripts/main_menu.gd`
  - Emits `Common.start_game_type` for single-player, load, and multiplayer menu actions.
- `scripts/scene_switcher.gd`
  - Connects to `Common.start_game_type`.
  - Reads `Common.load_player` and `Common.player_class` during run bootstrap.
- `scripts/singleplayer/player_handler.gd`
  - Registers itself into `Common.player_character`.
  - Registers `load_player_data` into `Common.load_player`.
  - Reads `Common.player_heart_containers`.
  - Uses `Common.attack()` and `Common.place_bomb()` (both require `Common.run_context` → `CombatDirector`).
- `scripts/singleplayer/player_aim.gd`
  - Writes `Common.attack_spawn_angle`.
- `scripts/stats/draw_health.gd`
  - Reads `Common.player_class`.
  - Writes `Common.player_heart_containers`.
- `scripts/slime.gd`
  - Calls `Common.run_context.resolve_projectile_hit(...)` (`CombatDirector`).
- `scripts/enemy_spawner.gd`
  - Uses `Common.a_little_offset(...)`.

## Migration Order

The planned cutover order is:

1. Move world-root ownership to `RunContext`.
2. Migrate spawn helpers off `Common`.
3. Migrate projectile resolution to `CombatDirector`.
4. Migrate loot spawning to `LootDirector`.
5. Migrate player registration and UI-facing state to `RunContext`.
6. Reduce `Common` to menu/app-level transition glue only.

## Compatibility Rule

During the migration, new systems should call `RunContext` directly. `Common` should
delegate to the new runtime objects instead of growing new responsibilities.
