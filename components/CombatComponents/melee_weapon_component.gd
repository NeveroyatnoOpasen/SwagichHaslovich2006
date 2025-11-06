# Компонент оружия ближнего боя
extends Node3D
class_name MeleeWeaponComponent

# Сигналы
signal attack_started(attack_type: AttackType)
signal attack_ended()
signal hit_landed(target: HurtboxComponent)

# Типы атак
enum AttackType {
	LIGHT,  # Быстрая лёгкая атака
	HEAVY   # Медленная тяжёлая атака
}

# Параметры лёгкой атаки
@export_group("Light Attack")
@export var light_damage: float = 15.0
@export var light_knockback: float = 3.0
@export var light_attack_duration: float = 0.3  # Длительность анимации атаки
@export var light_active_start: float = 0.1     # Когда активируется хитбокс
@export var light_active_end: float = 0.25      # Когда деактивируется хитбокс
@export var light_cooldown: float = 0.4         # Кулдаун между атаками

# Параметры тяжёлой атаки
@export_group("Heavy Attack")
@export var heavy_damage: float = 35.0
@export var heavy_knockback: float = 8.0
@export var heavy_attack_duration: float = 0.6
@export var heavy_active_start: float = 0.2
@export var heavy_active_end: float = 0.5
@export var heavy_cooldown: float = 1.0

# Ссылка на хитбокс
@export var hitbox: HitboxComponent

# Внутренние переменные состояния
var is_attacking: bool = false
var current_attack_type: AttackType
var attack_timer: float = 0.0
var cooldown_timer: float = 0.0

func _ready() -> void:
	# Пытаемся найти хитбокс, если не назначен
	if hitbox == null:
		hitbox = get_node_or_null("HitboxComponent")

	if hitbox:
		# Подключаем сигнал попадания
		hitbox.hit_detected.connect(_on_hit_detected)

func _process(delta: float) -> void:
	# Обработка таймера кулдауна
	if cooldown_timer > 0:
		cooldown_timer -= delta

	# Обработка текущей атаки
	if is_attacking:
		attack_timer += delta
		_update_attack(delta)

# Попытка начать атаку
func try_attack(attack_type: AttackType) -> bool:
	# Проверяем, можем ли мы атаковать
	if is_attacking or cooldown_timer > 0:
		return false

	# Начинаем атаку
	_start_attack(attack_type)
	return true

# Начало атаки
func _start_attack(attack_type: AttackType) -> void:
	is_attacking = true
	current_attack_type = attack_type
	attack_timer = 0.0

	# Устанавливаем параметры хитбокса в зависимости от типа атаки
	if hitbox:
		match attack_type:
			AttackType.LIGHT:
				hitbox.damage = light_damage
				hitbox.knockback_force = light_knockback
			AttackType.HEAVY:
				hitbox.damage = heavy_damage
				hitbox.knockback_force = heavy_knockback

	# Испускаем сигнал начала атаки
	attack_started.emit(attack_type)

# Обновление состояния атаки
func _update_attack(delta: float) -> void:
	var active_start: float
	var active_end: float
	var duration: float

	# Получаем параметры в зависимости от типа атаки
	match current_attack_type:
		AttackType.LIGHT:
			active_start = light_active_start
			active_end = light_active_end
			duration = light_attack_duration
		AttackType.HEAVY:
			active_start = heavy_active_start
			active_end = heavy_active_end
			duration = heavy_attack_duration

	# Активация хитбокса в нужный момент
	if attack_timer >= active_start and attack_timer <= active_end:
		if hitbox and not hitbox.monitoring:
			hitbox.activate()
	else:
		if hitbox and hitbox.monitoring:
			hitbox.deactivate()

	# Завершение атаки
	if attack_timer >= duration:
		_end_attack()

# Завершение атаки
func _end_attack() -> void:
	is_attacking = false

	# Деактивируем хитбокс
	if hitbox:
		hitbox.deactivate()

	# Устанавливаем кулдаун
	match current_attack_type:
		AttackType.LIGHT:
			cooldown_timer = light_cooldown
		AttackType.HEAVY:
			cooldown_timer = heavy_cooldown

	# Испускаем сигнал окончания атаки
	attack_ended.emit()

# Прерывание атаки (например, при получении урона)
func interrupt_attack() -> void:
	if is_attacking:
		if hitbox:
			hitbox.deactivate()
		is_attacking = false
		attack_ended.emit()

# Проверка, можем ли мы атаковать
func can_attack() -> bool:
	return not is_attacking and cooldown_timer <= 0

# Получить прогресс кулдауна (0.0 - 1.0)
func get_cooldown_progress() -> float:
	var max_cooldown: float
	match current_attack_type:
		AttackType.LIGHT:
			max_cooldown = light_cooldown
		AttackType.HEAVY:
			max_cooldown = heavy_cooldown
		_:
			return 1.0

	if max_cooldown <= 0:
		return 1.0

	return 1.0 - (cooldown_timer / max_cooldown)

# Обработчик попадания
func _on_hit_detected(hurtbox: HurtboxComponent) -> void:
	hit_landed.emit(hurtbox)
