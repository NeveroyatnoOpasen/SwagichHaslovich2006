# Компонент хитбокса для обнаружения попаданий атак
extends Area3D
class_name HitboxComponent

# Сигналы
signal hit_detected(hurtbox: HurtboxComponent)

@export var damage: float = 10.0
@export var knockback_force: float = 5.0

# Хранит список уже пораженных целей в текущей атаке
var hit_targets: Array[HurtboxComponent] = []

func _ready() -> void:
	# Устанавливаем слой и маску коллизии
	# Слой 2 - для хитбоксов
	collision_layer = 2
	# Маска 4 - обнаруживаем хёртбоксы
	collision_mask = 4

	# По умолчанию хитбокс неактивен
	monitoring = false
	monitorable = false

	# Подключаем сигнал обнаружения областей
	area_entered.connect(_on_area_entered)

# Активировать хитбокс для атаки
func activate() -> void:
	hit_targets.clear()
	monitoring = true
	monitorable = true

# Деактивировать хитбокс после атаки
func deactivate() -> void:
	monitoring = false
	monitorable = false
	hit_targets.clear()

# Проверяет, была ли цель уже поражена в этой атаке
func has_hit_target(hurtbox: HurtboxComponent) -> bool:
	return hurtbox in hit_targets

# Обработчик входа в область
func _on_area_entered(area: Area3D) -> void:
	# Проверяем, является ли область хёртбоксом
	if area is HurtboxComponent:
		var hurtbox: HurtboxComponent = area as HurtboxComponent

		# Предотвращаем повторное попадание по той же цели
		if not has_hit_target(hurtbox):
			hit_targets.append(hurtbox)

			# Применяем урон к хёртбоксу
			hurtbox.take_hit(damage, knockback_force, global_position)

			# Испускаем сигнал о попадании
			hit_detected.emit(hurtbox)
