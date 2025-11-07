extends "res://miscelanius/scripts/interactable.gd"
signal _use
func use():
	_use.emit()
