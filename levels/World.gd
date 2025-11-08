extends Node3D

# Player scene to instantiate
const PLAYER_SCENE = preload("res://entity/player/player.tscn")

# Spawn marker for player
@onready var spawn_warrior: Marker3D = $Spawn_Warrior
@onready var spawn_rogue: Marker3D = $Spawn_Rogue
@onready var spawn_mage: Marker3D = $Spawn_Mage

func _ready() -> void:
	# Spawn the player based on selected character
	_spawn_player()

func _spawn_player() -> void:
	var player = PLAYER_SCENE.instantiate()
	var character_data = GameState.get_character_data(GameState.selected_character)

	# Выбор позиции спавна по классу
	match GameState.selected_character:
		GameState.CharacterType.WARRIOR:
			player.global_position = spawn_warrior.global_position
		GameState.CharacterType.ROGUE:
			player.global_position = spawn_rogue.global_position
		GameState.CharacterType.MAGE:
			player.global_position = spawn_mage.global_position
		_:
			player.global_position = Vector3.ZERO

	# --- Применяем параметры персонажа ---
	if player.has_node("health_component"):
		var health_component = player.get_node("health_component")
		health_component.max_health = character_data["max_health"]

	if "SPEED" in player:
		player.SPEED = character_data["speed"]

	_apply_character_abilities(player, character_data)
	add_child(player)

	print("Player spawned as ", character_data["name"])

func _apply_character_abilities(player: Node, character_data: Dictionary) -> void:
	# Get ability component
	if not player.has_node("AbilityComponent"):
		return

	var ability_component = player.get_node("AbilityComponent")
	var abilities_config = character_data.get("abilities", {})

	# Apply each ability from character data
	for slot in abilities_config.keys():
		var ability_path = abilities_config[slot]

		if ability_path and ability_path is String:
			# Load the ability script
			var ability_script = load(ability_path)

			if ability_script:
				# Create new instance
				var ability_instance = ability_script.new()

				# Remove default ability in this slot if exists
				var current_ability = ability_component.get_ability(slot)
				if current_ability:
					ability_component.remove_ability(slot)

				# Set the new ability
				ability_component.set_ability(slot, ability_instance)
				print("Equipped ", ability_instance.ability_name, " to ", slot)
		elif not ability_path:
			# Remove ability from this slot (character doesn't have it)
			ability_component.remove_ability(slot)
			print("Removed ability from ", slot)
