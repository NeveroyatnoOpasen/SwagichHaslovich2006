# Компонент хёртбокса для получения ударов
extends Area3D
class_name HurtboxComponent

# Сигналы
signal hit_received(damage: float, knockback_force: float, attacker_position: Vector3)

# Ссылка на компонент здоровья (необязательная)
@export var health_component: HealthComponent

# Множитель урона (для уязвимых частей тела)
@export var damage_multiplier: float = 1.0

# Включить/выключить получение урона
@export var enabled: bool = true

func _ready() -> void:
	# Устанавливаем слой и маску коллизии
	# Слой 4 - для хёртбоксов
	collision_layer = 4
	# Маска 2 - обнаруживаем хитбоксы
	collision_mask = 2

	# Хёртбокс всегда активен для обнаружения
	monitoring = false  # Не отслеживаем входы, только позволяем обнаруживать себя
	monitorable = true

	# Пытаемся найти HealthComponent, если не назначен
	if health_component == null:
		health_component = get_parent().get_node_or_null("health_component")

# Метод для получения удара
func take_hit(damage: float, knockback_force: float, attacker_position: Vector3) -> void:
	if not enabled:
		return

	# Применяем множитель урона
	var final_damage = damage * damage_multiplier

	# Применяем урон к компоненту здоровья
	if health_component:
		health_component.apply_damage(final_damage)

	# Испускаем сигнал о получении удара
	hit_received.emit(final_damage, knockback_force, attacker_position)

# Включить хёртбокс
func enable() -> void:
	enabled = true
	monitorable = true

# Отключить хёртбокс (например, во время перекатов или неуязвимости)
func disable() -> void:
	enabled = false
	monitorable = false
