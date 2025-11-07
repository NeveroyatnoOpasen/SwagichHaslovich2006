extends Node3D

# Player scene to instantiate
const PLAYER_SCENE = preload("res://entity/player/player.tscn")

# Spawn marker for player
@onready var player_spawn_point: Marker3D = $PlayerSpawnPoint

func _ready() -> void:
	# Spawn the player based on selected character
	_spawn_player()

func _spawn_player() -> void:
	# Instantiate player from scene
	var player = PLAYER_SCENE.instantiate()

	# Get character data from GameState
	var character_data = GameState.get_character_data(GameState.selected_character)

	# Set player position
	if player_spawn_point:
		player.global_position = player_spawn_point.global_position
	else:
		player.global_position = GameState.spawn_position

	# Apply character-specific properties
	if player.has_node("health_component"):
		var health_component = player.get_node("health_component")
		# Set max_health before the component's _ready() is called
		health_component.max_health = character_data["max_health"]

	# Set player speed
	if "SPEED" in player:
		player.SPEED = character_data["speed"]

	# Apply character-specific abilities
	_apply_character_abilities(player, character_data)

	# Add player to scene
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
