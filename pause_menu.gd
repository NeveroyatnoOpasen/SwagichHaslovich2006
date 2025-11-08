extends Control

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur_menu")
func pause():
	get_tree().paused = true
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
func _process(delta):
	escape()
