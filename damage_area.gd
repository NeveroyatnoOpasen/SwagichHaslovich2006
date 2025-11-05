# Area3D скрипт для нанесения урона
extends Area3D

@export var damage_amount: float = 50.0
func _on_body_entered(body: Node3D) -> void:
	# Ищем компонент здоровья у вошедшего тела
	var health_component = body.get_node_or_null("health_component")
	print("Smth here")
	if health_component:
		health_component.apply_damage(damage_amount)
		print("Niggas")
