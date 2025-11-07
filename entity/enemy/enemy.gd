# Простой враг с боевой системой
extends CharacterBody3D

@onready var health_component: HealthComponent = $health_component
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var hit_flash_time: float = 0.0

func _ready() -> void:
	# Подключаем сигналы
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.health_depleted.connect(_on_health_depleted)

	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)

func _process(delta: float) -> void:
	# Обработка эффекта вспышки при получении урона
	if hit_flash_time > 0:
		hit_flash_time -= delta
		if hit_flash_time <= 0 and mesh_instance:
			# Возвращаем нормальный цвет
			var material = mesh_instance.get_active_material(0) as StandardMaterial3D
			if material:
				material.albedo_color = Color(1, 0, 0)  # Красный цвет врага

func _physics_process(delta: float) -> void:
	# Применяем гравитацию
	if not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()

# Обработчик изменения здоровья
func _on_health_changed(current_health: float, max_health: float, damaged: bool) -> void:
	print("Здоровье врага: ", current_health, "/", max_health)

	if damaged:
		_play_hit_effect()

# Обработчик смерти
func _on_health_depleted() -> void:
	print("Враг убит")
	queue_free()

# Обработчик получения удара
func _on_hit_received(damage: float, knockback_force: float, attacker_position: Vector3) -> void:
	# Применяем отброс
	var knockback_dir = (global_position - attacker_position).normalized()
	knockback_dir.y = 0.2  # Небольшой подъём
	velocity += knockback_dir * knockback_force

# Эффект получения урона
func _play_hit_effect() -> void:
	# Вспышка белым цветом
	if mesh_instance:
		var material = mesh_instance.get_active_material(0) as StandardMaterial3D
		if material:
			material.albedo_color = Color(1, 1, 1)  # Белая вспышка
			hit_flash_time = 0.1  # Длительность вспышки
