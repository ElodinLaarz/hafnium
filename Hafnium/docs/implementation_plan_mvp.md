# Hafnium — GDD MVP implementation plan

**Purpose:** Single source of truth for shipping the roguelike MVP (hub → two paths → Grave-Warden) in **small, reviewable PRs**.  
**Companion docs:** High-level vision and tables live in `roguelike-game-design.jsx` (Downloads). This file is the **engineering roadmap** merged with the **repo baseline** assessment.

**Target:** Spawn → hub → clear **2 of 3** paths → defeat Grave-Warden → run results.  
**Rough timeline:** ~15 weeks across 6 phases (order: **A** before **B** and **C**; **C** before **D**; **B** + **D** before **E**; **F** last).

---

## Repo baseline (where we start)

Already in tree (see also `docs/refactor/state_boundaries.md`):

- **Autoloads + data:** `Common`, `MultiplayerManager`, `ContentRegistry`; run-scoped `RunContext` with health/resource/currency/room/combat signals.
- **Combat loop:** `CombatDirector`, `CharacterData` + `attack_projectile_id`, projectiles, bombs on `secondary_attack`, crits, hit stop / screen shake / floating damage numbers.
- **Rooms today:** `room_graph_generator.gd` is a **linear** 3-node chain (entrance → combat → boss), not hub-and-spoke. `infinite_room.gd` is procedural wave/room advance without Hades-style door picks.
- **Enemies:** One registered enemy (`slime_basic`); `damage.gd` has `BASIC` + `FIRE` only.
- **Multiplayer:** ENet scaffold exists; not 3-player local input or shared-screen policy per GDD.

Everything in phases **A–F** below closes the gap between this baseline and the GDD MVP.

---

## Dependency flow

```text
A (class + elements + weapons) → B (hub graph) ─┐
                    A → C (enemies + synergies) ─┼→ E (rewards, shop, run-end) → F (3P + polish)
                              C → D (boss) ─────┘
```

Interpretation:

- **B** and **C** can proceed in parallel once **A** lands (elements + skills feed dungeon and enemies).
- **D** needs **C** (boss reuses enemy mechanics).
- **E** needs **B** (reward rooms, hub NPCs), **A** (weapons), and a defeated boss hook from **D**.
- **F** assumes gameplay **A–E** are feature-complete enough to tune and ship.

---

## Effort key

| Tag | Meaning      | Rough size   |
|-----|--------------|--------------|
| **S** | Small        | &lt; 1 day   |
| **M** | Medium       | 1–3 days     |
| **L** | Large        | 3–5 days     |
| **XL** | Extra-large | 1–2 weeks    |

Use effort tags to slice PRs: prefer **one gate-relevant vertical** or **one subsystem** per PR (e.g. “DamageType + projectile tags only”, then “Barbarian passive only”).

---

## Phase A — Class identity & element foundation

**Duration:** ~2 weeks  
**Subtitle:** Make the three classes feel different before building anything around them.

**Playable gate (Gate A):** Each class plays distinctly in a single test room. Elemental tags fire on every hit. Weapon swap changes your moveset.

**Why this order:** Synergies, enemy weaknesses, and reward value all depend on elements and class passives. Extends existing `PlayerCharacter`, `CombatDirector`, and `CharacterData` rather than replacing them.

**Builds on:** `damage.gd`, `class_handler.gd`, `combat_director.gd`, `CharacterData` (`attack_projectile_id`).

| # | Task | Effort | Detail |
|---|------|--------|--------|
| 1 | Expand `DamageType` enum | S | Add `ICE`, `NATURE`, `PHYSICAL` alongside `BASIC` and `FIRE`. Every damage event carries a tag. Touches: `damage.gd`, combat apply path. |
| 2 | Elemental tag on projectiles & skills | S | `CharacterData` / projectile scenes: exported `element: DamageType`. `CombatDirector` sets tag on spawn so weapon → projectile → hit pipeline is tagged. |
| 3 | Battle Hardened (Barbarian passive) | S | Stacking mitigation: each hit subtracts an incrementing counter from incoming damage until a hit is fully absorbed, then the counter resets (repeated equal hits yield e.g. 5→5,4,3,2,1,0,5). `PlayerCharacter` calls `PlayerClass.modify_incoming_damage`, which delegates to `ClassHandler._modify_incoming_damage`. |
| 4 | Blood Mana (Wizard passive) | M | Mana max scales inversely with HP ratio; spell costs vs mana; HUD bar. |
| 5 | Nature's Reaction (Druid passive) | M | On hit: weighted spawn ThornBurst / VineSnare / HealFlower near Druid; entities tagged `NATURE` for synergy. |
| 6 | Weapon → skill slot system | L | `WeaponResource`: `primary_skill` + `secondary_skill` (`SkillResource`: scene, element, cooldown, cost). `PlayerHandler`: LMB/RMB from current weapon. Migrate bomb-as-secondary into Greataxe default secondary. |
| 7 | Three starter `WeaponResource`s | M | Greataxe, Oak Staff, Gnarled Totem — placeholder VFX, correct elements. |
| 8 | Skill cooldown & mana HUD | M | Primary/secondary icons + cooldown sweep; Wizard mana bar. Extend HUD (`draw_health.gd` or new `SkillBar`). |

**Suggested PR slices:** (1–2) damage + tags; (3–5) passives one class per PR or one PR for all three; (6) weapon model; (7–8) content + HUD.

---

## Phase B — Hub & branching dungeon graph

**Duration:** ~2.5 weeks  
**Subtitle:** Replace the linear room chain with hub-and-spoke path selection.

**Playable gate (Gate B):** Player spawns in a hub, sees 3 path doors (difficulty + reward icons), picks a door, traverses rooms, returns to hub. Boss door unlocks after 2 paths cleared.

**Why:** GDD requires central hub, three branches of variable length, Hades-style door picks, and boss gating — not the current linear `entrance → combat → boss` graph.

**Builds on:** `room_graph_generator.gd`, `infinite_room.gd`, `RoomData`, `RunContext` room signals.

| # | Task | Effort | Detail |
|---|------|--------|--------|
| 1 | Hub room scene | M | Hand-authored hub: 3 path doors + locked boss door; difficulty border + end-reward icon per path; NPC anchor points; boss lock UI 0/2 → 2/2. |
| 2 | `HubGraphGenerator` (replace linear generator) | L | `RunGraph`: hub + 3 `PathChain`s; lengths Easy ~3, Medium ~5, Hard ~7; adjacency as dictionaries (no `GraphNode` required). |
| 3 | Path difficulty assignment | S | RNG Easy/Med/Hard across 3 paths (design: no dupes vs weighted repeats). |
| 4 | Door pick flow | L | On room clear: spawn forward doors with reward icons; interact picks branch; others lock. Replaces `infinite_room` auto-advance. |
| 5 | End-of-path → hub | M | Terminal node → “Return to Hub” portal; `RunContext` marks path complete; increment boss progress; unlock boss at 2. |
| 6 | Room template pool | M | 4–6 combat layout variants (PackedScenes + markers). |
| 7 | Hub NPC random spawn | S | Shopkeeper / Healer roll on hub entry (GDD tension curve). |
| 8 | Reward-type seeding | M | Per-node `RewardType` (combat, weapon vault, relic, etc.); weights; end-of-path tier. |

---

## Phase C — Enemy roster & synergy engine

**Duration:** ~3 weeks  
**Subtitle:** Five enemy types that teach the boss, plus cross-class combo detection.

**Playable gate (Gate C):** All 5 enemy types appear with elemental weaknesses. At least 4 GDD synergies work in live combat (e.g. Fire + Vine = Flaming Briars).

**Builds on:** `enemy.gd`, `ContentRegistry`, expanded `damage.gd`, Druid passive entities.

| # | Task | Effort | Detail |
|---|------|--------|--------|
| 1 | Weakness / resistance | M | Enemy resource: `weaknesses` / `resistances`; ×1.5 / ×0.5 damage; VFX on hit. |
| 2 | Hollow Sentinel + Soul Anchor | M | Invuln until tombstone destroyed. |
| 3 | Bone Swarm spawner | M | Stationary spawner; kill spawner to stop minions. |
| 4 | Grave Shambler | M | Slow, wide telegraphed chain sweep. |
| 5 | Spectral Acolyte | M | Heals allies; priority target. |
| 6 | Elemental slime variants | M | Fire / Ice / Nature trails or zones. |
| 7 | Synergy detection engine | L | Zones with element tags; overlap / hit resolves `SynergyTable` → combo effects. |
| 8 | Six MVP synergy effects | L | GDD combos as small scenes + gameplay. |
| 9 | Spawn tables by difficulty | M | Easy vs Hard weighting for enemy mix. |
| 10 | Knockback | M | Impulse from weapon/skill; players + enemies. |

---

## Phase D — Grave-Warden boss fight

**Duration:** ~2 weeks  
**Subtitle:** Three-phase final exam.

**Playable gate (Gate D):** Chain Assault → Shield Phase → Desperation playable; boss death triggers run-end hook.

**Builds on:** Phase C enemies/mechanics, room templates from B, knockback.

| # | Task | Effort | Detail |
|---|------|--------|--------|
| 1 | Boss arena scene | M | Large template; tombstone markers; hazard markers; central platform. |
| 2 | `GraveWarden` + state machine | L | Extends `enemy.gd`; phases by HP thresholds; boss knockback immune. |
| 3 | Phase 1 — Chain Assault | M | Reuse Shambler telegraph; periodic skeleton waves. |
| 4 | Phase 2 — Shield Phase | M | Invuln + multiple Soul Anchors. |
| 5 | Phase 3 — Desperation | L | Healing totems + arena hazards + intensity ramp. |
| 6 | Phase transition beats | S | Short zoom / slow-mo / freeze AI (reuse hit-stop). |
| 7 | Boss defeated → signal | S | `boss_defeated` on `RunContext`; placeholder victory until E. |

---

## Phase E — Rewards, shop & meta layer

**Duration:** ~2.5 weeks  
**Subtitle:** Loot, currency, NPCs, run-end loop.

**Playable gate (Gate E):** Full MVP run: hub → paths → gold + weapons → shop → boss → results screen (“one more run” loop).

**Builds on:** `RunContext` currency, weapon system from A, hub anchors from B, `RewardType` from B.

| # | Task | Effort | Detail |
|---|------|--------|--------|
| 1 | Reward room framework | M | Base reward room; pedestals; claim flow; exit doors. |
| 2 | Weapon Vault room | L | Per-player choices; comparison UI; swap weapon/skills. |
| 3 | Relic room — augments | L | `AugmentResource` modifiers on `SkillResource`. |
| 4 | Blessing Font | M | Run-long passive buffs. |
| 5 | Synergy charms | M | Run-scoped inventory; `SynergySystem` checks charms. |
| 6 | Gold drops | S | Enemy death → pickup; HUD wired to `RunContext`. |
| 7 | Shopkeeper NPC | M | Hub shop UI; scaling prices; deduct currency. |
| 8 | Healer NPC | S | One-shot team heal per appearance; gold cost. |
| 9 | Run-end screen | M | Stats, synergies, time; Play Again / Quit. |
| 10 | Main menu + run init | M | Start run → seed `RunContext` + graph + load hub. |

---

## Phase F — Multiplayer, polish & balance

**Duration:** ~3 weeks  
**Subtitle:** 3 players, presentation, numbers.

**Playable gate (Gate F):** Three players can complete a full run (local shared-screen or online per scope); art/audio/balance match GDD targets; MVP shippable.

**Builds on:** `multiplayer_manager.gd`, systems A–E.

| # | Task | Effort | Detail |
|---|------|--------|--------|
| 1 | 3-player local input | L | P1 KB+mouse, P2/P3 gamepads; per-device action maps. |
| 2 | Shared-screen camera | M | Frame all players; zoom; off-screen arrows. |
| 3 | Multiplayer reward flow | M | Weapon/relic rules; shared vs per-player gold; door vote or leader (design call). |
| 4 | Character animation pass | L | Per-class move/attack/hit/death. |
| 5 | Enemy + boss animation pass | L | Readable telegraphs. |
| 6 | Environment art pass | L | Hub, dungeon, boss tiles; door frames; pedestals. |
| 7 | Elemental VFX | M | Fire / ice / nature + synergy combos. |
| 8 | Audio pass | L | Music layers + SFX. |
| 9 | Balance pass | M | GDD stat tables, economy, boss HP. |
| 10 | Online multiplayer (stretch) | XL | ENet sync; may slip post-MVP. |

---

## PR checklist (copy into PR description)

- [ ] Which phase (A–F) and task ID does this PR advance?
- [ ] Does it move a **gate** forward or is it pure refactor / prep?
- [ ] Tests updated or added (`tests/unit/`) where logic changed?
- [ ] `gdlint` / project scripts clean for touched `.gd` files?

---

## Changelog

| Date | Change |
|------|--------|
| 2026-04-15 | Initial merge: repo baseline + phases A–F from `implementation-plan.jsx`, aligned with GDD gap analysis. |
| 2026-04-15 | Phase A (tasks 1–2): Expanded `DamageType` (`ICE`, `NATURE`, `PHYSICAL`). `CharacterData.attack_element`, typed `ProjectileData.damage_type`, `Projectile.element`; `Damage.resolve_attack_element`, `Damage.typed`, `Damage.damage_type_label`; `CombatDirector` tags `damage_payload` on attack; class resources Barbarian PHYSICAL, Wizard FIRE, Druid NATURE; `tests/unit/test_damage.gd`. |
| 2026-04-15 | Common / combat pipeline: Removed legacy combat from `Common` (`attack`, `place_bomb`, `projectile_resolve` no longer spawn projectiles or resolve hits without `RunContext`). Slime hitbox requires `Common.run_context.resolve_projectile_hit`. Docs: `CLAUDE.md`, `GEMINI.md`, `docs/refactor/common_dependency_snapshot.md`. |
| 2026-04-15 | RunContext training override: `use_training_damage_type_override`, `training_damage_type_override`, `set_training_damage_type_override()`, signal `training_damage_type_override_changed`. `CombatDirector` applies override when firing; hit feedback uses `get_last_applied_damage_for_feedback()` for correct floating numbers on infinite-HP dummies. |
| 2026-04-15 | Element training room: `scenes/test_scenes/element_training_room.tscn`, `element_training_room.gd`; `ElementTrainingDummy` (per-type multipliers, descriptive profile text); `DamageTypeTrainingPickup` (respawning tokens, element-colored diamonds); `TrainingSlimeDummy` `class_name` + feedback damage; `element_training_dummy.tscn` instances base dummy. Menu: New Game → Element Training (`main_menu.gd`, `main_menu.tscn`). HUD layer + instructional copy; dummy labels top-level, centered under slimes; token visuals and layout iterations. |
| 2026-04-15 | Fix: `ElementTrainingDummy` extends `training_slime_dummy.gd` by path (avoids parse order issues with `class_name` base). |
| 2026-04-15 | Main menu: New Game → level pick → **character class** screen (reuses `character_select.tscn`); `Common.character_select_after_level_pick`; `SceneSwitcher.show_character_select_for_new_game` / `return_from_character_select` (Back returns to level list or main menu). Character select: Back button; slot labels shortened to class names. **Fix:** selected-level runs (`_start_selected_level`) set `player_name` on the level root before `_ready` so DPS / Element training spawn the chosen class, not default wizard. |
| 2026-04-15 | Phase A (task 3 baseline): Added placeholder Barbarian primary melee swing (`weapon:barbarian_swing`) with knockback on `ProjectileData.knockback_force`; Barbarian `CharacterData` references the attack projectile; `CombatDirector` reads knockback from projectile data. Battle Hardened lives behind `PlayerClass.modify_incoming_damage` → `ClassHandler._modify_incoming_damage` (stacking mitigation / reset). `build_attack_logic` rejects unresolved projectile IDs. Tests: `tests/unit/test_barbarian_baseline.gd`, `tests/unit/test_class_handler.gd`. |
