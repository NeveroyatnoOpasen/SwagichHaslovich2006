# Ability System Documentation

A flexible, component-based ability system designed for roguelike games with dynamic character builds.

## Overview

The ability system consists of three main parts:

1. **BaseAbility** - Base class for all abilities
2. **AbilityComponent** - Component that manages abilities on a character
3. **Individual Abilities** - Custom abilities extending BaseAbility (e.g., DashAbility, FireballAbility)

## Architecture

```
CharacterBody3D (Player/Enemy)
└── AbilityComponent
	├── DashAbility (ability_1)
	├── FireballAbility (ability_2)
	├── CustomAbility (ability_3)
	└── UltimateAbility (ability_4)
```

## Key Bindings (Default)

- **Ability 1**: `Shift` - Dash
- **Ability 2**: `R` - Fireball
- **Ability 3**: `Q` - (Empty slot)
- **Ability 4**: `F` - (Empty slot)

You can change these in Project Settings → Input Map.

## Creating Custom Abilities

### Step 1: Create a New Ability Script

Extend `BaseAbility` and override the `activate()` method:

```gdscript
extends BaseAbility
class_name MyCustomAbility

func _ready() -> void:
	super._ready()
	ability_name = "My Ability"
	description = "Does something cool"
	cooldown = 5.0  # 5 second cooldown
	can_use_in_air = true
	stops_movement = false

func activate(owner: CharacterBody3D) -> bool:
	# Check if ability can be used
	if not super.activate(owner):
		return false

	# Your ability logic here
	print("Ability activated!")

	# Example: Heal the player
	if owner.has_node("health_component"):
		var health = owner.get_node("health_component")
		health.heal(25.0)

	return true
```

### Step 2: Add Ability to Player

**Option A: In the Godot Editor (Recommended for designers)**

1. Open `entity/player/player.tscn`
2. Select the `AbilityComponent` node
3. In the Inspector, expand "Ability Slots"
4. Assign your ability script to `ability_1`, `ability_2`, etc.

**Option B: Add at Runtime (Roguelike item pickups)**

```gdscript
# In player.gd or item pickup script
func equip_new_ability(ability_script: GDScript, slot: String) -> void:
	var ability_component = $AbilityComponent

	# Create new ability instance
	var new_ability = ability_script.new()

	# Equip it
	ability_component.set_ability(slot, new_ability)
	print("Equipped new ability in slot: ", slot)
```

## BaseAbility Properties

### Exported Properties (Set in Inspector)

```gdscript
@export var ability_name: String = "Base Ability"
@export_multiline var description: String = "Ability description"
@export var icon: Texture2D  # For UI display

@export var cooldown: float = 1.0
@export var cost: float = 0.0  # Mana/Energy cost (not implemented yet)
@export var can_use_in_air: bool = true
@export var stops_movement: bool = false
```

### Signals

```gdscript
signal ability_used(ability_name: String)
signal ability_cooldown_started(ability_name: String, cooldown: float)
signal ability_ready(ability_name: String)
```

### Methods

- `activate(owner: CharacterBody3D) -> bool` - **Override this** to implement ability logic
- `can_use() -> bool` - Override to add custom conditions
- `get_cooldown_remaining() -> float` - Get remaining cooldown
- `get_cooldown_percent() -> float` - Get cooldown as percentage (0.0-1.0)
- `reset_cooldown()` - Instantly reset cooldown
- `reduce_cooldown(amount: float)` - Reduce cooldown by amount

## AbilityComponent API

### Using Abilities from Code

```gdscript
# Get reference to ability component
@onready var abilities: AbilityComponent = $AbilityComponent

# Use an ability programmatically
abilities.use_ability("ability_1")

# Check if ability is ready
if abilities.is_ability_ready("ability_1"):
	abilities.use_ability("ability_1")

# Get cooldown info
var cooldown = abilities.get_ability_cooldown("ability_1")
print("Cooldown remaining: ", cooldown)

# Swap abilities at runtime (roguelike!)
var new_ability = DashAbility.new()
abilities.set_ability("ability_1", new_ability)

# Remove ability
abilities.remove_ability("ability_1")

# Reset all cooldowns (powerup effect!)
abilities.reset_all_cooldowns()
```

### Signals

```gdscript
signal ability_activated(ability_name: String)
signal ability_failed(ability_name: String, reason: String)
```

## Example Abilities

### DashAbility

Quickly dash in movement direction.

**Properties:**
- `dash_speed: float = 20.0` - Speed of dash
- `dash_duration: float = 0.2` - How long dash lasts
- `dash_direction_mode` - MOVEMENT (input direction), FORWARD (camera forward), or BACKWARD

**Usage:**
```gdscript
var dash = DashAbility.new()
dash.dash_speed = 25.0
dash.cooldown = 2.0
abilities.set_ability("ability_1", dash)
```

### FireballAbility

Launches a damaging projectile.

**Properties:**
- `damage: float = 50.0` - Damage dealt
- `projectile_speed: float = 30.0` - Projectile velocity
- `projectile_lifetime: float = 5.0` - Seconds before auto-destroy
- `explosion_radius: float = 3.0` - AoE damage radius
- `fireball_scene: PackedScene` - Custom projectile (optional)

**Usage:**
```gdscript
var fireball = FireballAbility.new()
fireball.damage = 100.0
fireball.cooldown = 8.0
abilities.set_ability("ability_2", fireball)
```

## Roguelike Integration Examples

### Example 1: Random Ability on Level Up

```gdscript
func on_level_up():
	var ability_pool = [
		DashAbility,
		FireballAbility,
		HealAbility,
		ShieldAbility
	]

	var random_ability = ability_pool[randi() % ability_pool.size()].new()

	# Let player choose which slot to replace
	abilities.set_ability("ability_3", random_ability)
```

### Example 2: Ability Upgrade System

```gdscript
func upgrade_ability(slot: String):
	var ability = abilities.get_ability(slot)

	if ability is DashAbility:
		ability.dash_speed *= 1.5  # 50% faster
		ability.cooldown *= 0.8     # 20% shorter cooldown
	elif ability is FireballAbility:
		ability.damage *= 2.0       # Double damage!
```

### Example 3: Cooldown Reduction Item

```gdscript
func pickup_cooldown_reduction_item():
	# Reduce all cooldowns by 50%
	for slot in ["ability_1", "ability_2", "ability_3", "ability_4"]:
		var ability = abilities.get_ability(slot)
		if ability:
			ability.cooldown *= 0.5
```

### Example 4: Character-Specific Abilities

```gdscript
# In GameState.gd - extend character data
var character_data = {
	CharacterType.WARRIOR: {
		"abilities": [DashAbility, ShieldBashAbility, WarCryAbility]
	},
	CharacterType.ROGUE: {
		"abilities": [DashAbility, BackstabAbility, SmokeBombAbility]
	},
	CharacterType.MAGE: {
		"abilities": [TeleportAbility, FireballAbility, IceNovaAbility]
	}
}

# In World.gd when spawning player
func _apply_character_abilities(player: CharacterBody3D):
	var char_data = GameState.get_character_data(GameState.selected_character)
	var abilities_list = char_data.get("abilities", [])
	var ability_component = player.get_node("AbilityComponent")

	# Equip character-specific abilities
	for i in range(min(abilities_list.size(), 4)):
		var ability = abilities_list[i].new()
		ability_component.set_ability("ability_" + str(i + 1), ability)
```

## UI Integration Tips

### Displaying Cooldowns

```gdscript
# In UI script
@onready var abilities: AbilityComponent = $"../AbilityComponent"
@onready var ability_1_icon: TextureProgressBar = $Ability1Icon

func _process(delta):
	# Update cooldown display
	var cooldown_percent = abilities.get_ability("ability_1").get_cooldown_percent()
	ability_1_icon.value = (1.0 - cooldown_percent) * 100
```

### Showing Ability Names

```gdscript
func update_ability_tooltip(slot: String):
	var ability = abilities.get_ability(slot)
	if ability:
		$Tooltip/Name.text = ability.ability_name
		$Tooltip/Description.text = ability.description
		$Tooltip/Cooldown.text = "Cooldown: " + str(ability.cooldown) + "s"
```

## Advanced: Custom Ability Types

### Channeled Ability

```gdscript
extends BaseAbility
class_name ChanneledAbility

var is_channeling: bool = false
var channel_time: float = 0.0
@export var max_channel_time: float = 3.0

func activate(owner: CharacterBody3D) -> bool:
	if not super.activate(owner):
		return false

	is_channeling = true
	channel_time = 0.0
	set_process(true)
	return true

func _process(delta: float):
	super._process(delta)

	if is_channeling:
		channel_time += delta

		# Release when key released
		if not Input.is_action_pressed("ability_1"):
			_release()

		# Auto-release at max time
		if channel_time >= max_channel_time:
			_release()

func _release():
	is_channeling = false
	var power = channel_time / max_channel_time
	print("Released with ", power * 100, "% power!")
	# Apply effect based on power
```

## Performance Notes

- Abilities only process when active (cooldown) or being used
- Projectile abilities create temporary nodes - ensure they're cleaned up
- For roguelikes with many ability swaps, use `set_ability()` which properly cleans up old abilities

## Troubleshooting

**Ability doesn't activate:**
- Check `can_use()` conditions (cooldown, in air, etc.)
- Verify input action is bound in Project Settings
- Ensure AbilityComponent is child of CharacterBody3D

**Cooldown not working:**
- Make sure you call `super.activate(owner)` in your custom activate method
- Check that ability's `_process()` is being called

**Runtime ability swap not working:**
- Use `set_ability()`, not direct assignment
- Ensure the ability script has `class_name` defined
- Check that the slot name matches ("ability_1", "ability_2", etc.)

## File Structure

```
components/AbilitySystem/
├── README.md (this file)
├── base_ability.gd (Base class)
├── ability_component.gd (Manager component)
├── ability_component.tscn (Scene)
└── Abilities/
    ├── dash_ability.gd
    ├── fireball_ability.gd
    └── [your custom abilities]
```

## Next Steps

1. Create more abilities for your roguelike!
2. Add UI to display ability icons and cooldowns
3. Implement character-specific ability sets
4. Create ability upgrade/modification system
5. Add visual/sound effects to abilities
6. Consider adding a mana/energy system

Happy coding! 🎮
