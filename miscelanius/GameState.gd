extends Node

# Global game state singleton to store player selections and game data

# Available character types
enum CharacterType {
	WARRIOR,
	ROGUE,
	MAGE
}

# Currently selected character (default to WARRIOR)
var selected_character: CharacterType = CharacterType.WARRIOR

# Spawn position for player in world
var spawn_position: Vector3 = Vector3(0.82, 1.23, 3.83)

# Character definitions with their properties
var character_data = {
	CharacterType.WARRIOR: {
		"name": "Warrior",
		"description": "Strong melee fighter with high health",
		"max_health": 150,
		"speed": 5.0,
		"color": Color(0.8, 0.2, 0.2),  # Red
		"abilities": {
			"ability_1": "res://components/AbilitySystem/Abilities/dash_ability.gd",
			"ability_2": null  # No secondary ability for warrior
		}
	},
	CharacterType.ROGUE: {
		"name": "Rogue",
		"description": "Fast and agile with moderate health",
		"max_health": 100,
		"speed": 7.0,
		"color": Color(0.2, 0.8, 0.2),  # Green
		"abilities": {
			"ability_1": "res://components/AbilitySystem/Abilities/dash_ability.gd",
			"ability_2": null  # Could add a backstab ability here
		}
	},
	CharacterType.MAGE: {
		"name": "Mage",
		"description": "Magical character with low health",
		"max_health": 80,
		"speed": 4.5,
		"color": Color(0.2, 0.2, 0.8),  # Blue
		"abilities": {
			"ability_1": null,  # No dash for mage
			"ability_2": "res://components/AbilitySystem/Abilities/fireball_ability.gd"
		}
	}
}

func get_character_data(character_type: CharacterType) -> Dictionary:
	return character_data.get(character_type, character_data[CharacterType.WARRIOR])

func set_selected_character(character_type: CharacterType) -> void:
	selected_character = character_type
	print("Selected character: ", character_data[character_type]["name"])
