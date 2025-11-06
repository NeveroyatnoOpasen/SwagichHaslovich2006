extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_health_component_health_changed(current_health: float, max_health: float, damaged: bool) -> void:
		if damaged:
			$OverlayWirhEffects.texture = load("res://miscelanius/blood.png")
			$AnimationPlayer.play("blood")
		else:
			$OverlayWirhEffects.texture = load("res://miscelanius/Heal.jpg")
			$AnimationPlayer.play("blood")
			
	
