# Компонент управления боем
extends Node
class_name CombatComponent

# Сигналы для интеграции с анимациями
signal combo_started(combo_index: int)
signal combo_reset()
signal attack_performed(attack_type: MeleeWeaponComponent.AttackType)

# Ссылки на компоненты
@export var weapon: MeleeWeaponComponent
@export var character_body: CharacterBody3D

# Параметры комбо
@export_group("Combo System")
@export var enable_combo: bool = true
@export var max_combo_count: int = 3        # Максимальное количество ударов в комбо
@export var combo_window: float = 0.5       # Окно времени для продолжения комбо

# Ограничения атаки
@export_group("Attack Restrictions")
@export var allow_air_attack: bool = false  # Разрешить атаку в воздухе
@export var stop_movement_on_attack: bool = true  # Останавливать движение при атаке

# Состояние комбо
var current_combo: int = 0
var combo_timer: float = 0.0
var attack_queued: bool = false
var queued_attack_type: MeleeWeaponComponent.AttackType

func _ready() -> void:
	# Пытаемся найти оружие, если не назначено
	if weapon == null:
		weapon = get_parent().find_child("MeleeWeaponComponent", true, false)

	# Пытаемся найти CharacterBody3D, если не назначен
	if character_body == null:
		character_body = get_parent() as CharacterBody3D

	# Подключаем сигналы оружия
	if weapon:
		weapon.attack_ended.connect(_on_attack_ended)
		weapon.hit_landed.connect(_on_hit_landed)

func _process(delta: float) -> void:
	# Обработка таймера комбо
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			_reset_combo()

	# Обработка очереди атак
	if attack_queued and weapon and not weapon.is_attacking:
		attack_queued = false
		_perform_attack(queued_attack_type)

# Обработка ввода атаки
func handle_attack_input(attack_type: MeleeWeaponComponent.AttackType) -> void:
	# Проверяем ограничения
	if not _can_attack():
		return

	# Если оружие сейчас атакует, ставим атаку в очередь для комбо
	if weapon.is_attacking and enable_combo:
		if current_combo < max_combo_count:
			attack_queued = true
			queued_attack_type = attack_type
		return

	# Выполняем атаку немедленно
	_perform_attack(attack_type)

# Выполнение атаки
func _perform_attack(attack_type: MeleeWeaponComponent.AttackType) -> void:
	if weapon and weapon.try_attack(attack_type):
		# Останавливаем движение, если требуется
		if stop_movement_on_attack and character_body:
			character_body.velocity.x = 0
			character_body.velocity.z = 0

		# Обновляем комбо
		if enable_combo:
			current_combo += 1
			combo_timer = combo_window
			combo_started.emit(current_combo)

		# Испускаем сигнал атаки
		attack_performed.emit(attack_type)

# Проверка возможности атаки
func _can_attack() -> bool:
	# Проверяем наличие оружия
	if not weapon:
		return false

	# Проверяем, можем ли атаковать в воздухе
	if not allow_air_attack and character_body and not character_body.is_on_floor():
		return false

	return true

# Сброс комбо
func _reset_combo() -> void:
	if current_combo > 0:
		current_combo = 0
		combo_reset.emit()

# Обработчик окончания атаки
func _on_attack_ended() -> void:
	# Если нет атаки в очереди, начинаем отсчёт времени для комбо
	if not attack_queued:
		combo_timer = combo_window

# Обработчик попадания
func _on_hit_landed(target: HurtboxComponent) -> void:
	# Можно добавить эффекты попадания, звуки и т.д.
	pass

# Прерывание атаки (например, при получении урона)
func interrupt_attack() -> void:
	if weapon:
		weapon.interrupt_attack()
	attack_queued = false
	_reset_combo()

# Получение текущего комбо
func get_current_combo() -> int:
	return current_combo

# Проверка, атакуем ли мы сейчас
func is_attacking() -> bool:
	return weapon and weapon.is_attacking
