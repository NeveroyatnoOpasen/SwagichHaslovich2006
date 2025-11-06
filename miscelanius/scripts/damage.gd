extends "res://damage_area.gd"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func _on_body_entered(body: Node3D) -> void:
	# Ищем компонент здоровья у вошедшего тела
	var health_component = body.get_node_or_null("health_component")
	print("Smth here")
	if health_component:
		health_component.heal(damage_amount)
		print("Niggas")
