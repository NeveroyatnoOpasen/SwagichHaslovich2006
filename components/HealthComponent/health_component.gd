# Компонент здоровья
extends Node
class_name HealthComponent

# Объявляем сигнал
signal health_changed(current_health: float, max_health: float, damaged: bool)
signal health_depleted()


@export var max_health: float = 100.0
var health: float 

func _ready() -> void:
	health = max_health

# Метод приема урона
func apply_damage(damage: float) -> void: 
	health -= damage
	# Испускаем сигнал при изменении здоровья
	health_changed.emit(health, max_health, 1)
	
	if health <= 0: 
		# Испускаем сигнал при смерти
		health_depleted.emit()
		get_parent().queue_free()

# Метод для лечения (опционально)
func heal(amount: float) -> void:
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health, 0)
