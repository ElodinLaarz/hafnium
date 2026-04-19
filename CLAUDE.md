# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hafnium is a 2D top-down action game built in Godot 4.6. The project lives in the `Hafnium/` subdirectory. The game supports single-player and local multiplayer (ENet), with three playable classes: Barbarian, Druid, and Wizard.

## Running the Game

Open the project in the Godot editor and run, or use the CLI:

```bash
# Run from the project root
godot --path Hafnium/

# Validate a GDScript file without running
godot --path Hafnium/ --check-only --script scripts/common.gd
```

## One-time Setup

After cloning, run these once:

```bash
# Point git to the committed hooks directory
git config core.hooksPath .githooks

# Install the GDScript formatter and linter (Python 3)
pip install gdtoolkit
```

The pre-commit hook (`./githooks/pre-commit`) will auto-format any staged `.gd` files with `gdformat`, re-stage them, run `gdlint`, run optional Python type-hint checks, then **`Hafnium/presubmit_godot_compile.sh`** when `godot` is on `PATH` (or `GODOT_BIN` is set), then run the GUT unit test suite when GUT is present. Use `SKIP_GODOT_PRESUBMIT=1 git commit …` only if you must bypass the Godot step (not recommended).

## GDScript validation (matches project warnings as errors)

`Hafnium/project.godot` configures `[debug] gdscript/warnings/` — notably `untyped_declaration=2` and `inferred_declaration=2` (level **2** = treated as **errors**). That is what the editor and debug adapter enforce; `gdlint` alone does not fully duplicate it.

Before pushing or between edit cycles when changing GDScript, run:

```bash
bash Hafnium/presubmit_godot_compile.sh
```

Windows (PowerShell):

```powershell
.\Hafnium\presubmit_godot_compile.ps1
```

Requires Godot 4.x on `PATH`, or set `GODOT_BIN` to the executable. CI runs this after resource import via `.github/workflows/tests.yml`.

Single-file `--check-only` may mis-resolve autoloads in isolation; prefer the presubmit scripts for parity with running the project.

## Running Tests

The project uses [GUT](https://github.com/bitwes/Gut) (Godot Unit Test). GUT is not committed; the CI workflow installs it from GitHub. To run tests locally, install GUT first:

```bash
cd Hafnium
git clone --depth 1 https://github.com/bitwes/Gut.git _gut_tmp
mkdir -p addons && mv _gut_tmp/addons/gut addons/ && rm -rf _gut_tmp
```

Then run tests using the provided scripts from inside `Hafnium/`:

```bash
# Linux/macOS
./run_tests.sh

# Windows (PowerShell)
./run_tests.ps1
```

Or directly:

```bash
godot --path Hafnium/ --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

Tests live in `Hafnium/tests/unit/`. CI runs them automatically on every push and PR via `.github/workflows/tests.yml`. Manual playtesting is used for gameplay verification only.

## Architecture

### Autoloads (Global Singletons)

Two autoloads are registered in `project.godot`:

- **`Common`** (`scripts/common.gd`) — Shared game state: holds references to the active `player_character`, `player_class`, and `player_heart_containers`. `attack()` and `place_bomb()` require `run_context` and delegate to `RunContext` → `CombatDirector`. Most cross-system communication flows through `Common`.
- **`MultiplayerManager`** (`scripts/mutiplayer/multiplayer_manager.gd`) — Manages ENet sessions. Host binds to `127.0.0.1:8080`; clients connect to the same. Multiplayer is currently localhost-only.

### Entry Point & Scene Flow

`SceneSwitcher.tscn` is the main scene. It listens for the `Common.start_game_type` signal (emitted by the main menu) and delegates to `scene_switcher.gd`, which loads `level_1.tscn`, instantiates `player_character.tscn`, attaches the class-appropriate sprite, and wires up the UI.

### Player System

- `scenes/player_character.tscn` + `scripts/singleplayer/player_handler.gd` — Core player node (`PlayerCharacter extends CharacterBody2D`). Delegates movement to `PlayerMovement`, aiming to `PlayerAim`.
- `scripts/classes/class_handler.gd` — Defines `ClassHandler` and the inner `PlayerClass` class. `ClassHandler.hdl()` configures HP, resources, heart drawing logic, and attack logic for each class. Attack projectiles come from `CharacterData` (`attack_projectile_id` / `attack_projectile_scene`) on `PlayerClass.definition`.
- `scripts/stats/stats_handler.gd` — `Stats` class holds health, damage, attack speed, projectile speed, attack cooldown, and a `resources` dictionary (bombs, mana). Shared by both players and enemies.
- `scripts/singleplayer/player_configuration.gd` — `PlayerConfigurationManager` maps string names (`"wizard"`, `"druid"`, `"barbarian"`) to `PlayerConfiguration` objects with starting stats.

### Enemy System

- `scripts/enemy.gd` — Base `enemy` class (`CharacterBody2D`). Uses `EnemyMovement` for pathfinding/chasing. Has a `reward` dictionary for loot drops (keys are cumulative probabilities 0–100).
- `scripts/enemy_spawner.gd` / `scenes/npcs/enemy_spawner.tscn` — Spawns enemies into the scene.
- `scripts/slime.gd` / `scenes/npcs/slime.tscn` — Concrete enemy implementation.

### Combat Flow

1. Player input → `Common.attack()` or `Common.place_bomb()` → `RunContext.perform_primary_attack` / `place_primary_bomb` → `CombatDirector` (requires `Common.run_context` to be set during a run).
2. `CombatDirector.fire_attack()` consumes the attack via `player_class.attack()`, resolves the projectile from `CharacterData` / `ContentRegistry`, instantiates it with velocity/damage/TTL from `Stats`, and parents it under the run’s world entity root.
3. Projectile collision → `RunContext.resolve_projectile_hit` → `CombatDirector.resolve_projectile_hit` → `BaseCharacter.receive_damage`; on kill, deferred cleanup and `RunContext.handle_enemy_defeated` for loot.

**Important:** All `queue_free` and `add_child` calls that happen inside physics callbacks must use `call_deferred` / `call_deferred("add_child", ...)` to avoid modifying the scene tree during physics processing.

### UI / Interface

- `scenes/interface/interface.tscn` + `scripts/interface/update_interface.gd` — HUD added to `UI` CanvasLayer at game start.
- `scenes/interface/lifebar/` — Heart containers per class; `ClassHandler` provides per-class heart drawing logic as a `Callable` stored on `PlayerClass.heart_drawing_logic`.
- `scenes/interface/counters/` — Individual counters for bombs, health, rubies.

### Multiplayer

- `scenes/multiplayer_player.tscn` — Player scene used when in multiplayer mode.
- `scripts/mutiplayer/multiplayer_controller.gd`, `multiplayer_aim.gd`, `multiplayer_input.gd` — Multiplayer equivalents of the singleplayer movement/aim scripts.
- The single-player `Player` node is removed when entering multiplayer; players are added under a `Players` node in `MainScene`.

## Key Conventions

- **Identify-by-method pattern**: Scripts use empty `is_player()` / `is_enemy()` methods as type tags; callers check `has_method("is_enemy")` before acting.
- **Stats are shared**: Both `PlayerClass` and `enemy` hold a `Stats` instance. Player `health_to_damage_multiplier` defaults to 2 (1 damage = ½ heart), except Barbarian (4, quarter hearts).
- **Viewport**: 640×360, `canvas_items` stretch mode, pixel-perfect (`default_texture_filter=0`).
- **Input actions**: `up/down/left/right` for movement, `attack` (left click), `secondary_attack` (right click), `zoomin`/`zoomout` (scroll wheel).
