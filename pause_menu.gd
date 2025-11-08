extends Control
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	$AnimationPlayer.process_mode = Node.PROCESS_MODE_ALWAYS
	$AnimationPlayer.play("RESET")
	hide()

func pause():
	show() # показываем меню
	$AnimationPlayer.play("blur_menu") # проигрываем появление
	get_tree().paused = true # ставим игру на паузу

func resume():
	get_tree().paused = false # снимаем паузу
	$AnimationPlayer.play_backwards("blur_menu") # проигрываем исчезновение
	hide() # прячем меню (или дождись конца анимации, если хочешь красиво)
	
	$AnimationPlayer.play_backwards("blur_menu")
func escape():
	if Input.is_action_just_pressed("esc") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("esc") and get_tree().paused:
		resume()


func _on_resume_button_pressed() -> void:
	resume()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
func _input(event):
	if event.is_action_pressed("esc"):
		if get_tree().paused:
			resume()
		else:
			pause()
