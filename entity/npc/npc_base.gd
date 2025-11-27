# npc_base.gd
extends Interactable
class_name NPCBase

# Компонент диалога
@onready var dialog_component: NPCDialogComponent = $NPCDialogComponent

# Параметры NPC
@export var npc_display_name: String = "NPC"
@export var starting_dialog_id: String = "merchant_greeting"

func _ready():
	# Настроить prompt_message
	prompt_message = "Поговорить с " + npc_display_name

	# Настроить компонент диалога, если он есть
	if dialog_component:
		dialog_component.npc_name = npc_display_name
		dialog_component.starting_dialog_id = starting_dialog_id

# Переопределяем use() из Interactable
func use():
	if dialog_component:
		# Найти игрока
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			dialog_component.on_player_interact(player)
	else:
		push_error("NPCDialogComponent not found on " + npc_display_name)
