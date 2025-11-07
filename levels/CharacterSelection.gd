extends Control

# References to UI elements
@onready var warrior_button: Button = $CenterContainer/VBoxContainer/CharacterButtons/WarriorButton
@onready var rogue_button: Button = $CenterContainer/VBoxContainer/CharacterButtons/RogueButton
@onready var mage_button: Button = $CenterContainer/VBoxContainer/CharacterButtons/MageButton
@onready var character_name_label: Label = $CenterContainer/VBoxContainer/CharacterInfo/NameLabel
@onready var character_description_label: Label = $CenterContainer/VBoxContainer/CharacterInfo/DescriptionLabel
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton

# Currently highlighted character
var current_character: GameState.CharacterType = GameState.CharacterType.WARRIOR

func _ready() -> void:
	# Connect button signals
	warrior_button.pressed.connect(_on_warrior_selected)
	rogue_button.pressed.connect(_on_rogue_selected)
	mage_button.pressed.connect(_on_mage_selected)
	start_button.pressed.connect(_on_start_game)

	# Show initial character info
	_update_character_info(GameState.CharacterType.WARRIOR)

func _on_warrior_selected() -> void:
	current_character = GameState.CharacterType.WARRIOR
	_update_character_info(current_character)

func _on_rogue_selected() -> void:
	current_character = GameState.CharacterType.ROGUE
	_update_character_info(current_character)

func _on_mage_selected() -> void:
	current_character = GameState.CharacterType.MAGE
	_update_character_info(current_character)

func _update_character_info(character_type: GameState.CharacterType) -> void:
	var data = GameState.get_character_data(character_type)
	character_name_label.text = data["name"]
	character_description_label.text = data["description"]
	character_description_label.text += "\nHealth: " + str(data["max_health"])
	character_description_label.text += "\nSpeed: " + str(data["speed"])

func _on_start_game() -> void:
	# Save the selected character to GameState
	GameState.set_selected_character(current_character)

	# Load the world scene
	get_tree().change_scene_to_file("res://levels/World.tscn")
