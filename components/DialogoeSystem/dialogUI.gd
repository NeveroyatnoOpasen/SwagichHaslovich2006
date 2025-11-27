# dialog_ui.gd
extends CanvasLayer

# Ссылки на UI элементы
@onready var dialog_panel = $DialogPanel
@onready var character_name_label = $DialogPanel/MarginContainer/VBoxContainer/CharacterName
@onready var dialog_text_label = $DialogPanel/MarginContainer/VBoxContainer/DialogText
@onready var choices_container = $DialogPanel/MarginContainer/VBoxContainer/ChoicesContainer

# Префаб кнопки выбора
const CHOICE_BUTTON = preload("res://dialogs/choice_button.tscn")  # Создадим позже

var is_active: bool = false
var current_dialog: Dictionary = {}

func _ready():
	hide_dialog()
	DialogManager.dialog_started.connect(_on_dialog_started)
	DialogManager.dialog_ended.connect(_on_dialog_ended)

func show_dialog(dialog_data: Dictionary):
	if dialog_data.is_empty():
		hide_dialog()
		return
	
	current_dialog = dialog_data
	is_active = true
	dialog_panel.show()
	
	# Установить имя персонажа
	if dialog_data.has("character"):
		character_name_label.text = dialog_data["character"]
		character_name_label.show()
	else:
		character_name_label.hide()
	
	# Установить текст диалога
	dialog_text_label.text = dialog_data.get("text", "...")
	
	# Очистить старые выборы
	for child in choices_container.get_children():
		child.queue_free()
	
	# Создать кнопки выбора
	if dialog_data.has("choices"):
		for choice in dialog_data["choices"]:
			create_choice_button(choice)
	else:
		# Если нет выборов, создать кнопку "Продолжить"
		var continue_choice = {"text": "Продолжить", "next": null}
		create_choice_button(continue_choice)

func create_choice_button(choice: Dictionary):
	var button = Button.new()
	button.text = choice.get("text", "???")
	button.custom_minimum_size = Vector2(0, 40)
	
	# Проверить условие
	if choice.has("condition"):
		if not DialogManager.check_condition(choice["condition"]):
			button.disabled = true
			button.text += " [Недоступно]"
	
	button.pressed.connect(_on_choice_pressed.bind(choice))
	choices_container.add_child(button)

func hide_dialog():
	is_active = false
	dialog_panel.hide()

func _on_choice_pressed(choice: Dictionary):
	var next_dialog = DialogManager.process_choice(choice)
	show_dialog(next_dialog)

func _on_dialog_started(dialog_id: String):
	var dialog_data = DialogManager.get_dialog(dialog_id)
	show_dialog(dialog_data)

func _on_dialog_ended():
	hide_dialog()
