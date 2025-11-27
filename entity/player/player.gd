extends CharacterBody3D

# Movement parameters
@export_group("Movement")
@export var speed := 6.0
@export var jump_velocity := 5.0

# Camera parameters
@export_group("Camera")
@export var mouse_sensitivity := 0.003
@export var max_pitch_deg := 85.0
@export var tilt_amount := 0.1  # Сила наклона камеры
@export var tilt_speed := 5.0   # Скорость возврата камеры в исходное положение

# Health parameters
@export_group("Health")
@export var max_health: float = 100.0

# Team parameters
@export_group("Team")
@export var team: TeamComponent.Team = TeamComponent.Team.REGULAR

# Combat parameters
@export_group("Combat")
@export var enable_combo: bool = true
@export var max_combo_count: int = 3
@export var combo_window: float = 0.5
@export var allow_air_attack: bool = false
@export var stop_movement_on_attack: bool = true

# Weapon parameters (Light Attack)
@export_group("Weapon - Light Attack")
@export var light_damage: float = 20.0
@export var light_knockback: float = 5.0
@export var light_attack_duration: float = 0.3
@export var light_active_start: float = 0.1
@export var light_active_end: float = 0.25
@export var light_cooldown: float = 0.3

# Weapon parameters (Heavy Attack)
@export_group("Weapon - Heavy Attack")
@export var heavy_damage: float = 50.0
@export var heavy_knockback: float = 10.0
@export var heavy_attack_duration: float = 0.6
@export var heavy_active_start: float = 0.2
@export var heavy_active_end: float = 0.5
@export var heavy_cooldown: float = 0.8

@onready var pivot: Node3D = $Pivot
@onready var camera: Camera3D = $Pivot/Camera3D  # Предполагаем, что камера - дочерний объект Pivot
@onready var weapon_holder: Node3D = $Pivot/Camera3D/WeaponHolder  # Сюда спавнятся модели оружия
@onready var combat_component: CombatComponent = $CombatComponent
@onready var health_component: HealthComponent = $health_component
@onready var team_component: TeamComponent = $TeamComponent
@onready var inventory: InventoryComponent = $InventoryComponent
@onready var melee_weapon: MeleeWeaponComponent = $MeleeWeaponComponent

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var yaw := 0.0   # поворот корпуса по Y
var pitch := 0.0 # наклон головы/камеры по X
var target_tilt := 0.0  # Целевой наклон камеры
var current_tilt := 0.0  # Текущий наклон камеры

var mouse_input := Vector2.ZERO
var movement_enabled := true  # Для блокировки управления во время диалогов
var is_dead := false  # Флаг смерти игрока

# Система экипировки
var equipped_item: InventoryItem = null  # Текущий экипированный предмет

func _ready() -> void:
	# Синхронизируем экспортные переменные с компонентами
	_sync_component_values()

	# Захватываем курсор и скрываем его
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Подключаем сигналы боевой системы если компонент присуттсвует
	if combat_component:
		combat_component.attack_performed.connect(_on_attack_performed)
		combat_component.combo_started.connect(_on_combo_started)
		combat_component.combo_reset.connect(_on_combo_reset)

	# Подключаем сигналы здоровья
	if health_component:
		health_component.health_depleted.connect(_on_health_depleted)

	# Тестовое добавление предметов (для разработки)
	if inventory:
		_add_test_items()

# Синхронизация экспортных переменных с компонентами
func _sync_component_values() -> void:
	# Health Component
	if health_component:
		health_component.max_health = max_health

	# Team Component
	if team_component:
		team_component.team = team

	# Combat Component
	if combat_component:
		combat_component.enable_combo = enable_combo
		combat_component.max_combo_count = max_combo_count
		combat_component.combo_window = combo_window
		combat_component.allow_air_attack = allow_air_attack
		combat_component.stop_movement_on_attack = stop_movement_on_attack

	# Melee Weapon Component
	if melee_weapon:
		# Light attack
		melee_weapon.light_damage = light_damage
		melee_weapon.light_knockback = light_knockback
		melee_weapon.light_attack_duration = light_attack_duration
		melee_weapon.light_active_start = light_active_start
		melee_weapon.light_active_end = light_active_end
		melee_weapon.light_cooldown = light_cooldown

		# Heavy attack
		melee_weapon.heavy_damage = heavy_damage
		melee_weapon.heavy_knockback = heavy_knockback
		melee_weapon.heavy_attack_duration = heavy_attack_duration
		melee_weapon.heavy_active_start = heavy_active_start
		melee_weapon.heavy_active_end = heavy_active_end
		melee_weapon.heavy_cooldown = heavy_cooldown

func _input(event) -> void:
	# Мышь обрабатываем всегда для камеры
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Накопление ввода мыши
		mouse_input = event.relative

	# ESC обрабатывается pause_menu, не трогаем здесь
	# (pause_menu.gd управляет паузой и курсором)

	# Блокируем остальной ввод, если управление отключено (диалог, смерть)
	if not movement_enabled:
		return

	if event.is_action_pressed("use"):
		$Pivot/InteractRay.use()
		print("use colider")

	# Обработка ввода атаки
	if event.is_action_pressed("attack"):
		if combat_component:
			combat_component.handle_attack_input(MeleeWeaponComponent.AttackType.LIGHT)

	if event.is_action_pressed("heavy_attack"):
		if combat_component:
			combat_component.handle_attack_input(MeleeWeaponComponent.AttackType.HEAVY)

	# Hotbar система (клавиши 1-9)
	if event.is_action_pressed("ui_1"):
		equip_from_slot(0)
	elif event.is_action_pressed("ui_2"):
		equip_from_slot(1)
	elif event.is_action_pressed("ui_3"):
		equip_from_slot(2)
	elif event.is_action_pressed("ui_4"):
		equip_from_slot(3)
	elif event.is_action_pressed("ui_5"):
		equip_from_slot(4)
	elif event.is_action_pressed("ui_6"):
		equip_from_slot(5)
	elif event.is_action_pressed("ui_7"):
		equip_from_slot(6)
	elif event.is_action_pressed("ui_8"):
		equip_from_slot(7)
	elif event.is_action_pressed("ui_9"):
		equip_from_slot(8)

	# Использовать расходник из текущего слота
	if event.is_action_pressed("ui_accept"):  # Enter
		use_current_item()

func _physics_process(delta: float) -> void:
	# ОБРАБОТКА ВВОДА МЫШИ В _physics_process ДЛЯ СИНХРОНИЗАЦИИ
	if mouse_input != Vector2.ZERO:
		# Горизонт — поворот тела
		yaw -= mouse_input.x * mouse_sensitivity
		rotation.y = yaw

		# Вертикаль — поворот Pivot
		pitch -= mouse_input.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-max_pitch_deg), deg_to_rad(max_pitch_deg))
		pivot.rotation.x = pitch

		# Сбрасываем ввод мыши
		mouse_input = Vector2.ZERO

	apply_gravity(delta)

	# Если управление заблокировано, не обрабатываем движение
	if not movement_enabled:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		move_and_slide()
		return

	# читаем ввод с клавиатуры (вынесено)
	var move_dir: Vector3 = get_move_input()
	
	# Вычисляем наклон камеры на основе движения
	calculate_tilt(move_dir)

	# Применяем плавный наклон камеры
	apply_camera_tilt(delta)

	# Проверяем, можем ли двигаться (боевая система может блокировать движение)
	var can_move := true
	if combat_component and combat_component.is_attacking():
		if combat_component.stop_movement_on_attack:
			can_move = false

	# движение по XZ
	if can_move:
		if move_dir != Vector3.ZERO:
			velocity.x = move_dir.x * speed
			velocity.z = move_dir.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)

	# прыжок
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	move_and_slide()

func calculate_tilt(move_dir: Vector3) -> void:
	# Определяем направление движения относительно взгляда игрока
	var local_move = transform.basis.inverse() * move_dir
	
	# Наклон в сторону движения (влево/вправо)
	if move_dir.length() > 0:
		target_tilt = -local_move.x * tilt_amount
	else:
		target_tilt = 0.0

func apply_camera_tilt(delta: float) -> void:
	# Плавно интерполируем текущий наклон к целевому
	current_tilt = lerp(current_tilt, target_tilt, tilt_speed * delta)
	
	# Применяем наклон по оси Z к камере или pivot
	if camera:
		camera.rotation.z = current_tilt
	else:
		pivot.rotation.z = current_tilt

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func get_move_input() -> Vector3:
	# WASD → вектор на плоскости (x,z)
	var input_2d := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	if input_2d.length() > 1.0:
		input_2d = input_2d.normalized()

	# переводим вектор из локальных осей игрока в мировой (без pitch)
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

func _on_health_depleted() -> void:
	print("Игрок умер")
	is_dead = true
	movement_enabled = false

	# Освобождаем курсор при смерти
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Здесь можно добавить экран смерти, перезагрузку уровня и т.д.

# Методы для управления движением (используются диалоговой системой)
func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled
	if not enabled:
		# Останавливаем горизонтальное движение
		velocity.x = 0
		velocity.z = 0

# === СИСТЕМА ЭКИПИРОВКИ ===

## Экипировать предмет из слота
func equip_from_slot(slot_index: int) -> void:
	if not inventory:
		return

	var item = inventory.get_item_at(slot_index)

	# Если слот пустой - снимаем текущий предмет
	if item == null:
		unequip_current()
		inventory.swap_to(slot_index)
		print("Switched to empty slot %d" % slot_index)
		return

	# Если предмет не экипируется - просто переключаем слот
	if not item.is_equippable():
		inventory.swap_to(slot_index)
		print("Switched to slot %d: %s (not equippable)" % [slot_index, item.item_name])
		return

	# Экипируем предмет
	unequip_current()
	item.equip(self)
	equipped_item = item
	inventory.swap_to(slot_index)
	print("Equipped from slot %d: %s" % [slot_index, item.item_name])

## Снять текущий экипированный предмет
func unequip_current() -> void:
	if equipped_item:
		equipped_item.unequip(self)
		equipped_item = null
		print("Unequipped item")

## Использовать предмет из текущего слота (для расходников)
func use_current_item() -> void:
	if not inventory:
		return

	var item = inventory.get_current_item()
	if not item:
		print("No item in current slot")
		return

	# Только расходники можно использовать таким образом
	if item is ConsumableItem:
		if item.use(self):
			print("Used consumable: %s" % item.item_name)
			# Удаляем расходник после использования
			inventory.delete_item(inventory.current_slot)
			# Если это был экипированный предмет - снимаем
			if equipped_item == item:
				equipped_item = null
	elif item is WeaponItem:
		print("Press 1-9 to equip weapons. Use Enter for consumables only.")
	else:
		print("Cannot use %s" % item.item_name)

## Тестовое добавление предметов (для разработки)
func _add_test_items() -> void:
	# Добавляем тестовый меч
	var sword = WeaponItem.new()
	sword.item_id = "test_sword"
	sword.item_name = "Test Iron Sword"
	sword.light_damage = 30.0
	sword.heavy_damage = 60.0
	sword.light_cooldown = 0.4
	sword.heavy_cooldown = 1.0
	# weapon_scene можно установить позже, когда будет модель
	inventory.add_item(sword)

	# Добавляем сигареты
	var cigs = Cigarettes.new()
	inventory.add_item(cigs)

	# Добавляем ещё одно оружие
	var club = WeaponItem.new()
	club.item_id = "wooden_club"
	club.item_name = "Wooden Club"
	club.light_damage = 15.0
	club.heavy_damage = 35.0
	inventory.add_item(club)

	# Выводим отладочную информацию
	inventory.debug_info()

	# Автоматически экипируем первый предмет
	print("\nAuto-equipping first item...")
	equip_from_slot(0)
