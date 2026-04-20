class_name GameConstants
extends RefCounted

const INPUT_ACTION_UP: String = "up"
const INPUT_ACTION_DOWN: String = "down"
const INPUT_ACTION_LEFT: String = "left"
const INPUT_ACTION_RIGHT: String = "right"
const INPUT_ACTION_ATTACK: String = "attack"
const INPUT_ACTION_SECONDARY_ATTACK: String = "secondary_attack"
const INPUT_ACTION_TOGGLE_FEEL_TUNING: String = "toggle_feel_tuning"
const INPUT_ACTION_TOGGLE_AUTORUN: String = "toggle_autorun"
const INPUT_ACTION_WALK_MODIFIER: String = "walk_modifier"

const RESOURCE_BOMB: String = "bomb"
const RESOURCE_MANA: String = "mana"

const ATTACK_SPAWN_DISPLACEMENT: float = 15.0
## Upper bound for crit chance after Luck and tuning (primary + secondary attacks).
const CRIT_CHANCE_CAP: float = 0.85
## How many stat options the level-up overlay presents.
const LEVEL_UP_CHOICE_COUNT: int = 3
const PLAYER_TEAM: int = 1
const HOST_PLAYER_ID: int = 1

const LOCAL_SERVER_IP: String = "127.0.0.1"
const DEFAULT_SERVER_PORT: int = 8080

const CLASS_ID_BARBARIAN: String = "class:barbarian"
const CLASS_ID_DRUID: String = "class:druid"
const CLASS_ID_WIZARD: String = "class:wizard"
const HEART_STYLE_BARBARIAN: String = "barbarian"
const HEART_STYLE_DRUID: String = "druid"
const HEART_STYLE_WIZARD: String = "wizard"
const HEART_STYLE_DEFAULT: String = "default"

## Per-class accent colors used by HUD / tooltips. Kept here as the single source
## of truth until we introduce a formal theme resource.
const CLASS_COLOR_BARBARIAN: String = "#dd4444"
const CLASS_COLOR_DRUID: String = "#33bb55"
const CLASS_COLOR_WIZARD: String = "#4499ee"

const ENEMY_ID_SLIME_BASIC: String = "enemy:slime_basic"
