# Ability System - Quick Start Guide

## What You Have Now

✅ **Base Ability System** - Fully functional and integrated with your player
✅ **Two Example Abilities** - Dash (Shift) and Fireball (R)
✅ **Character-Specific Abilities** - Different characters get different abilities
✅ **Runtime Ability Swapping** - Perfect for roguelike item pickups

## Current Setup

### Key Bindings
- **Shift** - Ability 1 (Dash for Warrior/Rogue, nothing for Mage)
- **R** - Ability 2 (Fireball for Mage, nothing for Warrior/Rogue)
- **Q** - Ability 3 (Empty)
- **F** - Ability 4 (Empty)

### Character Abilities
- **Warrior**: Dash ability
- **Rogue**: Dash ability (faster with higher speed stat)
- **Mage**: Fireball ability

## Test It Now!

1. Run the game (F5)
2. Select a character
3. Try the abilities:
   - **Warrior/Rogue**: Press **Shift** while moving to dash
   - **Mage**: Press **R** to shoot a fireball

## Creating Your First Custom Ability

1. Create a new script in `components/AbilitySystem/Abilities/`

```gdscript
extends BaseAbility
class_name HealAbility

func _ready() -> void:
	super._ready()
	ability_name = "Heal"
	description = "Restore health"
	cooldown = 10.0

func activate(owner: CharacterBody3D) -> bool:
	if not super.activate(owner):
		return false

	# Heal the player
	if owner.has_node("health_component"):
		owner.get_node("health_component").heal(50.0)
		print("HEALED!")

	return true
```

2. **Option A**: Add to player manually
   - Open `entity/player/player.tscn`
   - Add as child of `AbilityComponent`
   - Set in Inspector: `ability_3` = your new ability node

3. **Option B**: Add to character in GameState
   ```gdscript
   # In GameState.gd
   CharacterType.MAGE: {
	   "abilities": {
		   "ability_1": null,
		   "ability_2": "res://components/AbilitySystem/Abilities/fireball_ability.gd",
		   "ability_3": "res://components/AbilitySystem/Abilities/heal_ability.gd"
	   }
   }
   ```

## Common Use Cases

### Add Ability at Runtime (Item Pickup)
```gdscript
# In your pickup/item script
func pickup_ability_item():
	var player = get_tree().get_first_node_in_group("Player")
	var abilities = player.get_node("AbilityComponent")

	var new_ability = load("res://components/AbilitySystem/Abilities/heal_ability.gd").new()
	abilities.set_ability("ability_3", new_ability)
```

### Check if Ability is Ready
```gdscript
@onready var abilities = $AbilityComponent

func _process(delta):
	if abilities.is_ability_ready("ability_1"):
		$UI/Ability1Icon.modulate = Color.WHITE
	else:
		$UI/Ability1Icon.modulate = Color.GRAY
```

### Display Cooldown
```gdscript
func _process(delta):
	var cooldown = abilities.get_ability_cooldown("ability_1")
	$UI/CooldownLabel.text = str(ceil(cooldown)) + "s"
```

## Ability Ideas for Your Roguelike

### Movement Abilities
- **Teleport** - Instant short-range teleport
- **Sprint** - Temporary speed boost
- **Wall Jump** - Double jump ability
- **Grappling Hook** - Pull to target location

### Combat Abilities
- **Shield Bash** - Dash that stuns enemies
- **Whirlwind** - Spin attack hitting all nearby enemies
- **Backstab** - Extra damage from behind
- **War Cry** - Buff nearby allies

### Mage Abilities
- **Ice Nova** - Freeze enemies around you
- **Lightning Chain** - Damage that jumps between enemies
- **Meteor** - Area damage after delay
- **Blink** - Short teleport

### Utility Abilities
- **Heal** - Restore health
- **Invisibility** - Temporary stealth
- **Time Slow** - Slow down enemies
- **Summon** - Spawn friendly units

## Roguelike Features You Can Add

### 1. Ability Modifiers (Item Effects)
```gdscript
# Pickup that reduces all cooldowns by 30%
func apply_cooldown_reduction():
	for slot in ["ability_1", "ability_2", "ability_3", "ability_4"]:
		var ability = abilities.get_ability(slot)
		if ability:
			ability.cooldown *= 0.7
```

### 2. Synergy System
```gdscript
# Check for ability combinations
func check_synergy():
	var has_dash = abilities.get_ability("ability_1") is DashAbility
	var has_fireball = abilities.get_ability("ability_2") is FireballAbility

	if has_dash and has_fireball:
		# Grant "Fire Dash" synergy bonus
		abilities.get_ability("ability_1").dash_speed *= 1.5
```

### 3. Random Ability Rewards
```gdscript
func on_enemy_defeated():
	if randf() < 0.1:  # 10% chance
		var random_abilities = [HealAbility, ShieldAbility, BlinkAbility]
		var random_ability = random_abilities[randi() % random_abilities.size()].new()
		abilities.set_ability("ability_4", random_ability)
```

## File Structure
```
components/AbilitySystem/
├── README.md              # Full documentation
├── QUICKSTART.md          # This file
├── base_ability.gd        # Base class - don't modify
├── ability_component.gd   # Manager - don't modify
└── Abilities/
	├── dash_ability.gd    # Example ability
	├── fireball_ability.gd # Example ability
	└── YOUR_ABILITY.gd    # Create new abilities here
```

## Next Steps

1. ✅ Test the current abilities (Shift for dash, R for fireball)
2. 🎯 Create 2-3 custom abilities for your game
3. 🎨 Add UI to show ability icons and cooldowns
4. 🎮 Add more character-specific abilities
5. 🎲 Implement random ability drops
6. ⚡ Add visual/sound effects to abilities

## Need Help?

- Full docs: `components/AbilitySystem/README.md`
- Example abilities: `components/AbilitySystem/Abilities/`
- Character setup: `miscelanius/GameState.gd`
- Ability spawning: `levels/World.gd`

Happy ability crafting! ⚔️🔥
