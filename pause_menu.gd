extends Control

var is_in_dialog: bool = false
var player_reference: CharacterBody3D = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	$AnimationPlayer.process_mode = Node.PROCESS_MODE_ALWAYS
	$AnimationPlayer.play("RESET")
	hide()

	# Подключаемся к сигналам диалоговой системы
	if DialogManager:
		DialogManager.dialog_started.connect(_on_dialog_started)
		DialogManager.dialog_ended.connect(_on_dialog_ended)

	# Находим игрока
	_find_player()

func _find_player():
	# Ищем игрока в группе "Player"
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player_reference = players[0]

func _on_dialog_started(_dialog_id: String):
	is_in_dialog = true

func _on_dialog_ended():
	is_in_dialog = false

func pause():
	# Проверяем, можно ли поставить на паузу
	if not _can_pause():
		return

	show()
	$AnimationPlayer.play("blur_menu")
	get_tree().paused = true

	# Освобождаем курсор для меню
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _can_pause() -> bool:
	# Не открываем меню паузы во время диалога
	if is_in_dialog:
		return false

	# Не открываем меню паузы, если игрок мёртв
	if player_reference and player_reference.get("is_dead"):
		if player_reference.is_dead:
			return false

	return true

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur_menu")
	hide()

	# Возвращаем захват курсора только если не в диалоге
	if not is_in_dialog:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_button_pressed() -> void:
	resume()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _input(event):
	if event.is_action_pressed("esc"):
		# Если игрок не найден, пробуем найти снова
		if not player_reference:
			_find_player()

		if get_tree().paused:
			resume()
		else:
			pause()
