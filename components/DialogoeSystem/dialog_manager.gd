extends Node

# Сигналы
signal dialog_started(dialog_id: String)
signal dialog_ended
signal dialog_event(event_name: String, params: Dictionary)

# 2025-11-22
# Data
var dialogs: Dictionary = {}
var current_dialog: Dictionary = {}
var event_handlers: Dictionary = {}

func _ready():
	load_dialogs()

func load_dialogs():
	var file_path = "res://components/DialogoeSystem/dialogs.json"
	if not FileAccess.file_exists(file_path):
		print("File not Found: " + file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: " + file_path)
		return

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()

	if error == OK:
		var data = json.data
		if data.has("dialogs"):
			dialogs = data["dialogs"]
			print("Dialogs loaded successfully: ", dialogs.size(), " dialogs")
		else:
			push_error("Invalid file structure: missing 'dialogs' key")
	else:
		push_error("JSON parse error: " + json.get_error_message())

# Начать диалог
func start_dialog(dialog_id: String) -> Dictionary:
	if not dialogs.has(dialog_id):
		push_error("Dialog not found: " + dialog_id)
		return {}

	current_dialog = dialogs[dialog_id].duplicate(true)
	dialog_started.emit(dialog_id)

	# Выполнить автоматические события
	if current_dialog.has("auto_events"):
		for event in current_dialog["auto_events"]:
			trigger_event(event)

	return current_dialog

# Получить диалог по ID
func get_dialog(dialog_id: String) -> Dictionary:
	return dialogs.get(dialog_id, {})

# Обработать выбор игрока
func process_choice(choice: Dictionary) -> Dictionary:
	# Проверить условие
	if choice.has("condition"):
		if not check_condition(choice["condition"]):
			return {}
	
	# Выполнить событие
	if choice.has("event"):
		var params = choice.get("params", {})
		trigger_event(choice["event"], params)
	
	# Получить следующий диалог
	if choice.has("next") and choice["next"] != null:
		return start_dialog(choice["next"])
	else:
		dialog_ended.emit()
		return {}

# Проверка условий
func check_condition(condition: String) -> bool:
	# Простая система условий
	# Формат: "variable:operator:value"
	# Пример: "reputation:>:10" или "has_item:key"
	
	var parts = condition.split(":")
	
	if parts.size() == 2:  # has_item:key
		var type = parts[0]
		var value = parts[1]
		
		match type:
			"has_item":
				return check_has_item(value)
			"quest_active":
				return check_quest_active(value)
	
	elif parts.size() == 3:  # reputation:>:10
		var variable = parts[0]
		var operator = parts[1]
		var value = parts[2].to_float()
		
		return check_variable_condition(variable, operator, value)
	
	return true

# Заглушки для проверки условий (замени на свою логику)
func check_has_item(item_id: String) -> bool:
	# TODO: Проверка инвентаря
	return true

func check_quest_active(quest_id: String) -> bool:
	# TODO: Проверка квестов
	return true

func check_variable_condition(variable: String, operator: String, value: float) -> bool:
	# TODO: Проверка переменных игрока
	var player_value = get_player_variable(variable)
	
	match operator:
		">":
			return player_value > value
		"<":
			return player_value < value
		">=":
			return player_value >= value
		"<=":
			return player_value <= value
		"==":
			return player_value == value
	
	return true

func get_player_variable(variable: String) -> float:
	# TODO: Получить значение переменной игрока
	# Пример: если variable == "reputation", вернуть player.reputation
	return 0.0

# Система событий
func register_event(event_name: String, handler: Callable):
	event_handlers[event_name] = handler
	print("Registered event handler: ", event_name)

func trigger_event(event_name: String, params: Dictionary = {}):
	print("Triggering event: ", event_name)
	
	if event_handlers.has(event_name):
		event_handlers[event_name].call(params)
	
	dialog_event.emit(event_name, params)
