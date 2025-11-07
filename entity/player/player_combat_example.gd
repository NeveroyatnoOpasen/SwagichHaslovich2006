# Пример интеграции боевой системы с игроком
# Добавьте этот код в ваш player.gd или используйте как ссылку
extends CharacterBody3D

# Стандартные параметры игрока
@export var speed := 6.0
@export var jump_velocity := 5.0
@export var mouse_sensitivity := 0.003
@export var max_pitch_deg := 85.0

@onready var pivot: Node3D = $Pivot
@onready var camera: Camera3D = $Pivot/Camera3D

# Боевые компоненты
@onready var combat_component: CombatComponent = $CombatComponent
@onready var health_component: HealthComponent = $health_component

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var yaw := 0.0
var pitch := 0.0
var mouse_input := Vector2.ZERO

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Подключаем сигналы боевой системы
	if combat_component:
		combat_component.attack_performed.connect(_on_attack_performed)
		combat_component.combo_started.connect(_on_combo_started)
		combat_component.combo_reset.connect(_on_combo_reset)

	# Подключаем сигналы здоровья
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.health_depleted.connect(_on_health_depleted)

func _input(event) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		mouse_input = event.relative

	if event.is_action_pressed("ui_cancel"):
		var captured := Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if captured else Input.MOUSE_MODE_CAPTURED)

	# Обработка ввода атаки
	if event.is_action_pressed("attack"):
		if combat_component:
			combat_component.handle_attack_input(MeleeWeaponComponent.AttackType.LIGHT)

	if event.is_action_pressed("heavy_attack"):
		if combat_component:
			combat_component.handle_attack_input(MeleeWeaponComponent.AttackType.HEAVY)

	if event.is_action_pressed("use"):
		# Ваш код взаимодействия
		pass

func _physics_process(delta: float) -> void:
	# Обработка ввода мыши
	if mouse_input != Vector2.ZERO:
		yaw -= mouse_input.x * mouse_sensitivity
		rotation.y = yaw

		pitch -= mouse_input.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-max_pitch_deg), deg_to_rad(max_pitch_deg))
		pivot.rotation.x = pitch

		mouse_input = Vector2.ZERO

	apply_gravity(delta)

	# Получаем ввод движения
	var move_dir: Vector3 = get_move_input()

	# Если атакуем и движение запрещено, ограничиваем движение
	var can_move := true
	if combat_component and combat_component.is_attacking():
		if combat_component.stop_movement_on_attack:
			can_move = false

	# Движение
	if can_move:
		if move_dir != Vector3.ZERO:
			velocity.x = move_dir.x * speed
			velocity.z = move_dir.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)

	# Прыжок
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	move_and_slide()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func get_move_input() -> Vector3:
	var input_2d := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	if input_2d.length() > 1.0:
		input_2d = input_2d.normalized()

	var forward := transform.basis.z
	var right := transform.basis.x
	var dir := (right * input_2d.x) + (forward * input_2d.y)
	return dir.normalized()

# Обработчики сигналов боевой системы
func _on_attack_performed(attack_type: MeleeWeaponComponent.AttackType) -> void:
	print("Атака выполнена: ", "Лёгкая" if attack_type == MeleeWeaponComponent.AttackType.LIGHT else "Тяжёлая")
	# Здесь можно запустить анимацию атаки

func _on_combo_started(combo_index: int) -> void:
	print("Комбо: ", combo_index)
	# Здесь можно менять анимации в зависимости от номера комбо

func _on_combo_reset() -> void:
	print("Комбо сброшено")

func _on_health_changed(current_health: float, max_health: float, damaged: bool) -> void:
	print("Здоровье: ", current_health, "/", max_health)
	# Обновление UI здоровья

	# Прерывание атаки при получении урона
	if damaged and combat_component:
		combat_component.interrupt_attack()

func _on_health_depleted() -> void:
	print("Игрок умер")
	# Обработка смерти игрока
