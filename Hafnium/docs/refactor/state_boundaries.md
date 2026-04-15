# State Boundaries

This note documents the intended split introduced by `RunContext`.

## Profile-Persistent State

This state survives across runs and belongs in future profile save modules, not in
`RunContext`.

- unlocked classes, weapons, relics, and rooms
- meta progression currency
- completed achievements and codex entries
- settings and preferences

## Run-Ephemeral State

This state belongs to `RunContext` and should be discarded when a run ends.

- active players for the current run
- the current floor seed and room graph
- the instantiated room root and run-scoped directors
- combat, encounter, and loot events emitted during a run
- transient health, mana, bomb, and currency values for the active run

## Resumable Run Snapshot State

This state can be serialized later if mid-run resume is added. It still belongs to the
run layer, not the profile layer.

- the floor seed and current room id
- player loadout, resources, and currency for the current run
- active room clear state and encounter progress
- room graph traversal progress

## Guideline

If a system only matters while the current run is alive, it should hang off
`RunContext`. If it changes what future runs can access, it belongs in profile or
meta-progression storage.
