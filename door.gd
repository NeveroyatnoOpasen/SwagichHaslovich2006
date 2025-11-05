extends "res://interactable.gd"
#@export var prompt_message = "Interact"
func use():
	print("door")
	if !open:
		$"../AnimationPlayer".play("open")
		open = !open
	else:
		$"../AnimationPlayer".play_backwards("open")
		open = !open
	pass
