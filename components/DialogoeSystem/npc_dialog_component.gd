# npc_dialog_component.gd
extends Node
class_name NPCDialogComponent

# Сигналы
signal dialog_interaction_started
signal dialog_interaction_ended

# Параметры NPC
@export var npc_name: String = "NPC"
@export var starting_dialog_id: String = ""
@export var greeting_dialog_id: String = ""

# Состояние
var is_in_dialog: bool = false
var player_in_range: bool = false
var player_reference: Node = null

func _ready():
	# Подключиться к событиям DialogManager
	if DialogManager:
		DialogManager.dialog_ended.connect(_on_dialog_ended)

# Начать диалог с NPC
func start_dialog():
	if is_in_dialog:
		return

	var dialog_id = starting_dialog_id if starting_dialog_id != "" else greeting_dialog_id

	if dialog_id == "":
		push_error("No dialog ID set for NPC: " + npc_name)
		return

	is_in_dialog = true
	dialog_interaction_started.emit()

	# Заблокировать управление игроком
	if player_reference and player_reference.has_method("set_movement_enabled"):
		player_reference.set_movement_enabled(false)

	# Захватить мышь
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Запустить диалог
	DialogManager.start_dialog(dialog_id)

# Завершить диалог
func _on_dialog_ended():
	if not is_in_dialog:
		return

	is_in_dialog = false
	dialog_interaction_ended.emit()

	# Разблокировать управление игроком
	if player_reference and player_reference.has_method("set_movement_enabled"):
		player_reference.set_movement_enabled(true)

	# Вернуть захват мыши
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Обработка взаимодействия с игроком
func on_player_interact(player: Node):
	player_reference = player
	start_dialog()

# Для использования с системой взаимодействия
func get_interaction_prompt() -> String:
	return "Поговорить с " + npc_name
