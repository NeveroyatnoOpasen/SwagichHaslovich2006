# Пример простого врага с боевой системой
extends CharacterBody3D

@export var health: float = 50.0

@onready var health_component: HealthComponent = $health_component
@onready var hurtbox: HurtboxComponent = $HurtboxComponent

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	# Подключаем сигналы
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.health_depleted.connect(_on_health_depleted)

	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)

func _physics_process(delta: float) -> void:
	# Применяем гравитацию
	if not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()

# Обработчик изменения здоровья
func _on_health_changed(current_health: float, max_health: float, damaged: bool) -> void:
	print("Здоровье врага: ", current_health, "/", max_health)

	if damaged:
		# Можно добавить эффект получения урона
		_play_hit_effect()

# Обработчик смерти
func _on_health_depleted() -> void:
	print("Враг убит")
	# Можно добавить анимацию смерти, дроп предметов и т.д.
	queue_free()

# Обработчик получения удара
func _on_hit_received(damage: float, knockback_force: float, attacker_position: Vector3) -> void:
	# Применяем отброс
	var knockback_dir = (global_position - attacker_position).normalized()
	knockback_dir.y = 0  # Отброс только по горизонтали
	velocity += knockback_dir * knockback_force

	# Поворачиваемся к атакующему
	look_at(attacker_position, Vector3.UP)

# Эффект получения урона (пример)
func _play_hit_effect() -> void:
	# Можно добавить:
	# - Изменение цвета модели
	# - Частицы
	# - Звук
	# - Анимацию реакции
	pass
