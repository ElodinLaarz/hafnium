# Gemini Context: Hafnium

## Project Overview
Hafnium is a 2D RPG/Action game built with **Godot 4**. It features single-player and multiplayer modes, with a class-based character system and procedural generation elements.

- **Engine:** Godot 4.x (configured for "4.6" and "Forward Plus" rendering).
- **Primary Language:** GDScript.
- **Secondary Language:** Go (used for experimental dungeon generation logic in `Hafnium/scripts/golang/`).
- **Main Entry Point:** `res://scenes/SceneSwitcher.tscn`.

## Architecture & Key Components

### Core Systems
- **Global Autoloads:**
    - `Common` (`res://scripts/common.gd`): Manages gameplay state, player references, and core actions like attacking and placing bombs.
    - `MultiplayerManager` (`res://scripts/mutiplayer/multiplayer_manager.gd`): Handles networking (host/join) using `ENetMultiplayerPeer`.
- **Class System:**
    - `ClassHandler` (`res://scripts/classes/class_handler.gd`): Defines player classes (**Barbarian, Druid, Wizard**) and their unique stats, resources (mana, bombs), and UI/heart-drawing logic.
- **Stats & Health:**
    - `Stats` (`res://scripts/stats/stats_handler.gd`): Handles health, damage, attack speed, and resource management (e.g., `ResourceStatus` class).
    - Class-specific health UI logic is implemented in `ClassHandler` to reflect different health-to-damage ratios (e.g., Barbarians use 1/4 hearts).

### Gameplay Flow
1. **Scene Management:** `SceneSwitcher` handles transitions between the main menu, character selection, and game levels (`level_1.tscn`).
2. **Player Initialization:** Players are instantiated with class-specific sprites and stats via `Common.load_player` and `ClassHandler.create_class`.
3. **Multiplayer:** Uses a client-server model where the host removes the single-player controller and instantiates `multiplayer_player.tscn` for each peer.

### Procedural Generation
- Located in `Hafnium/scripts/test_scripts/world_generation.gd`, utilizing `NoiseTexture2D` for terrain generation.
- A Go-based dungeon generator is present in `Hafnium/scripts/golang/dungeon_generator.go` but is currently experimental/independent.

## Development Conventions

### Directory Structure
- `Hafnium/scenes/`: Godot scenes (.tscn).
- `Hafnium/scripts/`: GDScript logic, organized by feature (multiplayer, singleplayer, stats, classes).
- `Hafnium/sprites/`: 2D art assets, including Aseprite source files.
- `Hafnium/scripts/golang/`: Go source code for generation logic.
- `Hafnium/tests/`: Unit and integration tests using GUT.

### Coding Practices
- **Global Access:** Use the `Common` singleton for cross-scene gameplay logic and player state.
- **Class Logic:** Centralize class-specific behavior and stat initialization in `ClassHandler`.
- **UI:** Theme files are located in `res://scenes/interface/themes/`.
- **Testability & Modularity:**
    - **Health Checks:** `Health.bounds_ok` takes an integer for heart count rather than a Node, allowing for pure logic testing.
    - **Movement Input:** `PlayerMovement` abstracts `Input` calls into overridable methods (`get_raw_input`, `is_action_just_pressed`, etc.) to allow for mocking in tests.
    - **Deterministic Rewards:** `enemy.drop_reward` uses an injectable `RandomNumberGenerator` for seeded, deterministic testing.
    - **Decoupled Setup:** `ClassHandler.get_attack_projectile_path` provides class-specific asset paths without mandatory side effects on the `Common` singleton, enabling isolated testing of class configurations.

## Building and Running
1.  **Requirement:** Godot Engine 4.x.
2.  **Run:** Open the project in Godot and run the default scene (`SceneSwitcher.tscn`).
3.  **Go Logic:** To work on the dungeon generator, navigate to `Hafnium/scripts/golang/` and use standard Go tools (`go build`, `go run`).

## Testing Plan
Hafnium includes a GUT-based unit test suite in `Hafnium/tests/unit`.

Run the automated tests locally from the project root using the Godot CLI against the `Hafnium/` project and the GUT test suite.
Example command:
`godot --path Hafnium/ --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`

CI also runs this automated test suite using `lihop/setup-godot` (which supports graphical UI tests), so prefer keeping local test runs aligned with the CI workflow before submitting changes.

Manual playtesting is still useful for gameplay verification, but it is no longer the only verification method.

## TODOs / Future Work
- [ ] Complete the implementation of Wizard heart drawing logic in `class_handler.gd`.
- [ ] Integrate the Go dungeon generator with the Godot engine (likely via GDExtension or shell execution).
- [ ] Implement melee attacks for classes that require them.
- [ ] Expand the item/reward system (enemy drops flow through `RunContext` / `CombatDirector`).
- [ ] Implement foundational GUT tests (`test_stats.gd`, `test_health.gd`).
