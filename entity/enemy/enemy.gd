# Простой враг с боевой системой
extends CharacterBody3D

# AI States
enum State {
	IDLE,      # Стоит на месте, осматривается
	PATROL,    # Патрулирование между точками
	ALERT,     # Заметил что-то подозрительное
	CHASE,     # Преследует враждебную цель
	ATTACK,    # Атакует враждебную цель
	RETREAT    # Отступает (низкое HP)
}

# Node references
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var health_component: HealthComponent = $health_component
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var melee_weapon: MeleeWeaponComponent = $MeleeWeaponComponent
@onready var vision_ray: RayCast3D = $VisionRay
@onready var detection_area: Area3D = $DetectionArea
@onready var team_component: TeamComponent = $TeamComponent

# Health parameters
@export_group("Health")
@export var max_health: float = 100.0

# Team parameters
@export_group("Team")
@export var team: TeamComponent.Team = TeamComponent.Team.MOBS

# Movement parameters
@export_group("Movement")
@export var idle_speed: float = 0.0
@export var patrol_speed: float = 2.0
@export var chase_speed: float = 5.0
@export var attack_speed: float = 1.0

# AI parameters
@export_group("AI Behavior")
@export var vision_range: float = 15.0        # Дальность зрения
@export var vision_angle: float = 90.0        # Угол обзора (градусы)
@export var detection_radius: float = 20.0    # Радиус обнаружения
@export var attack_range: float = 2.5         # Дистанция атаки
@export var min_attack_range: float = 1.5     # Минимальная дистанция
@export var retreat_health_percent: float = 0.25  # HP для отступления
@export var lose_sight_time: float = 5.0      # Время до потери цели
@export var attack_cooldown: float = 2.0      # Кулдаун между атаками

# Performance settings
@export_group("Performance")
@export var vision_check_interval: float = 0.1      # Интервал проверки зрения (сек)
@export var navigation_update_interval: float = 0.2 # Интервал обновления пути (сек)
@export var target_search_interval: float = 0.5     # Интервал поиска новой цели (сек)
@export var enable_debug_prints: bool = false       # Включить debug сообщения

# Patrol parameters
@export_group("Patrol")
@export var patrol_points: Array[Vector3] = []  # Точки патрулирования
@export var patrol_wait_time: float = 2.0       # Время ожидания на точке

# Weapon parameters (Light Attack)
@export_group("Weapon - Light Attack")
@export var light_damage: float = 15.0
@export var light_knockback: float = 3.0
@export var light_attack_duration: float = 0.3
@export var light_active_start: float = 0.1
@export var light_active_end: float = 0.25
@export var light_cooldown: float = 0.4

# Weapon parameters (Heavy Attack)
@export_group("Weapon - Heavy Attack")
@export var heavy_damage: float = 35.0
@export var heavy_knockback: float = 8.0
@export var heavy_attack_duration: float = 0.6
@export var heavy_active_start: float = 0.2
@export var heavy_active_end: float = 0.5
@export var heavy_cooldown: float = 1.0

# Internal state
var current_state: State = State.IDLE
var current_target: CharacterBody3D = null  # Текущая цель (враг)
var target_position: Vector3
var last_known_target_pos: Vector3
var can_see_target: bool = false
var time_since_seen_target: float = 0.0
var attack_timer: float = 0.0
var patrol_index: int = 0
var patrol_wait_timer: float = 0.0
var idle_rotation_timer: float = 0.0
var potential_targets: Array[CharacterBody3D] = []  # Потенциальные враги в зоне обнаружения

# Performance timers
var vision_check_timer: float = 0.0
var navigation_update_timer: float = 0.0
var target_search_timer: float = 0.0
var cached_navigation_target: Vector3 = Vector3.ZERO

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var hit_flash_time: float = 0.0
var current_speed: float = 0.0 
func _ready() -> void:
	# Синхронизируем экспортные переменные с компонентами
	_sync_component_values()

	# Подключаем сигналы
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.health_depleted.connect(_on_health_depleted)

	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)

	# Настраиваем detection area
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)

	# Настраиваем vision ray
	if vision_ray:
		vision_ray.enabled = true
		vision_ray.target_position = Vector3(0, 0, -vision_range)

	# Инициализация состояния
	if patrol_points.size() > 0:
		change_state(State.PATROL)
	else:
		change_state(State.IDLE)

# Синхронизация экспортных переменных с компонентами
func _sync_component_values() -> void:
	# Health Component
	if health_component:
		health_component.max_health = max_health

	# Team Component
	if team_component:
		team_component.team = team

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

# ============================================================================
# STATE MACHINE
# ============================================================================

func change_state(new_state: State) -> void:
	if current_state == new_state:
		return

	if enable_debug_prints:
		print("Enemy state: ", State.keys()[current_state], " -> ", State.keys()[new_state])
	current_state = new_state

	# State entry logic
	match new_state:
		State.IDLE:
			current_speed = idle_speed
			idle_rotation_timer = 0.0
		State.PATROL:
			current_speed = patrol_speed
			if patrol_points.size() > 0:
				_set_next_patrol_point()
		State.ALERT:
			current_speed = patrol_speed
		State.CHASE:
			current_speed = chase_speed
		State.ATTACK:
			current_speed = attack_speed
		State.RETREAT:
			current_speed = chase_speed

func update_state(delta: float) -> void:
	# Check for retreat condition
	#if health_component and health_component.health < health_component.max_health * retreat_health_percent:
	#	if current_state != State.RETREAT:
	#		change_state(State.RETREAT)

	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.PATROL:
			_state_patrol(delta)
		State.ALERT:
			_state_alert(delta)
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack(delta)
		State.RETREAT:
			_state_retreat(delta)

func _state_idle(delta: float) -> void:
	# Медленно поворачивается на месте
	idle_rotation_timer += delta
	rotation.y += delta * 0.5

	# Если увидел врага - переходим в chase
	if can_see_target and current_target:
		change_state(State.CHASE)
	elif patrol_points.size() > 0 and idle_rotation_timer > 3.0:
		change_state(State.PATROL)

func _state_patrol(delta: float) -> void:
	if patrol_points.size() == 0:
		change_state(State.IDLE)
		return

	# Если увидел врага - chase
	if can_see_target and current_target:
		change_state(State.CHASE)
		return

	# Движение к патрульной точке
	if global_position.distance_to(target_position) < 1.0:
		# Достигли точки - ждем
		patrol_wait_timer += delta
		if patrol_wait_timer >= patrol_wait_time:
			patrol_wait_timer = 0.0
			_set_next_patrol_point()
	else:
		move_towards_target(target_position)

func _state_alert(delta: float) -> void:
	# Идет к последней известной позиции цели
	if can_see_target and current_target:
		change_state(State.CHASE)
		return

	time_since_seen_target += delta

	if global_position.distance_to(last_known_target_pos) < 2.0:
		# Достигли последней точки - осматриваемся
		rotation.y += delta * 2.0
		if time_since_seen_target > lose_sight_time:
			change_state(State.IDLE)
	else:
		move_towards_target(last_known_target_pos)

func _state_chase(delta: float) -> void:
	if not current_target or not is_instance_valid(current_target):
		change_state(State.IDLE)
		current_target = null
		return

	if not can_see_target:
		time_since_seen_target += delta
		if time_since_seen_target > lose_sight_time:
			change_state(State.ALERT)
			return
	else:
		time_since_seen_target = 0.0
		last_known_target_pos = current_target.global_position

	var distance = global_position.distance_to(current_target.global_position)

	# Если близко - атакуем
	if distance <= attack_range:
		change_state(State.ATTACK)
	else:
		move_towards_target(current_target.global_position)

func _state_attack(delta: float) -> void:
	if not current_target or not is_instance_valid(current_target):
		change_state(State.IDLE)
		current_target = null
		return

	attack_timer -= delta

	var distance = global_position.distance_to(current_target.global_position)

	# Если цель убежала далеко
	if distance > attack_range * 1.5:
		change_state(State.CHASE)
		return

	# Поворачиваемся к цели
	look_at_target(current_target.global_position)

	# Управление дистанцией
	if distance < min_attack_range:
		# Слишком близко - отходим
		move_away_from_target(current_target.global_position, delta)
	elif distance > attack_range:
		# Слишком далеко - подходим
		move_towards_target(current_target.global_position)
	else:
		# Оптимальная дистанция - атакуем
		if attack_timer <= 0 and melee_weapon and melee_weapon.can_attack():
			perform_attack()
			attack_timer = attack_cooldown

func _state_retreat(delta: float) -> void:
	if not current_target or not is_instance_valid(current_target):
		change_state(State.IDLE)
		current_target = null
		return

	# Убегаем от цели
	move_away_from_target(current_target.global_position, delta)

	# Если здоровье восстановилось
	if health_component and health_component.health > health_component.max_health * (retreat_health_percent + 0.1):
		change_state(State.CHASE)
func _process(delta: float) -> void:
	# Обновляем AI
	update_state(delta)

	# Обновляем таймеры производительности
	if vision_check_timer >= 0:
		vision_check_timer += delta
	if navigation_update_timer > 0:
		navigation_update_timer -= delta
	if target_search_timer > 0:
		target_search_timer -= delta

	# Проверяем видимость враждебных целей (с интервалом для оптимизации)
	if vision_check_timer >= vision_check_interval:
		vision_check_timer = 0.0
		check_target_vision()

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

# ============================================================================
# MOVEMENT FUNCTIONS
# ============================================================================

func move_towards_target(target: Vector3) -> void:
	if not nav:
		return

	# Обновляем путь только если прошло достаточно времени или цель сильно изменилась
	var should_update_path = false
	if navigation_update_timer <= 0.0:
		should_update_path = true
		navigation_update_timer = navigation_update_interval
	elif cached_navigation_target.distance_to(target) > 2.0:  # Цель сместилась больше чем на 2 метра
		should_update_path = true
		navigation_update_timer = navigation_update_interval

	if should_update_path:
		nav.target_position = target
		cached_navigation_target = target

	var next_location = nav.get_next_path_position()
	var direction = (next_location - global_position).normalized()

	# Поворачиваемся к цели
	look_at_target(target)

	# Движемся
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

func move_away_from_target(target: Vector3, delta: float) -> void:
	var direction = (global_position - target).normalized()
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	# Смотрим на цель даже когда отступаем
	look_at_target(target)

func look_at_target(target: Vector3) -> void:
	var target_pos = Vector3(target.x, global_position.y, target.z)
	look_at(target_pos, Vector3.UP)

func _set_next_patrol_point() -> void:
	if patrol_points.size() == 0:
		return

	patrol_index = (patrol_index + 1) % patrol_points.size()
	target_position = patrol_points[patrol_index]

# ============================================================================
# VISION & DETECTION
# ============================================================================

func check_target_vision() -> void:
	if not vision_ray or not team_component:
		can_see_target = false
		return

	# Если у нас нет текущей цели или она мертва, ищем новую (с интервалом)
	if not current_target or not is_instance_valid(current_target):
		if target_search_timer <= 0.0:
			current_target = _find_closest_hostile_target()
			target_search_timer = target_search_interval

	if not current_target:
		can_see_target = false
		return

	var distance_to_target = global_position.distance_to(current_target.global_position)

	# Проверка дистанции
	if distance_to_target > vision_range:
		can_see_target = false
		return

	# Проверка угла обзора
	var direction_to_target = (current_target.global_position - global_position).normalized()
	var forward = -global_transform.basis.z
	var angle = rad_to_deg(forward.angle_to(direction_to_target))

	if angle > vision_angle / 2.0:
		can_see_target = false
		return

	# Проверка line of sight
	vision_ray.look_at(current_target.global_position, Vector3.UP)
	vision_ray.force_raycast_update()

	if vision_ray.is_colliding():
		var collider = vision_ray.get_collider()
		if collider == current_target:
			can_see_target = true
		else:
			can_see_target = false
	else:
		can_see_target = false

func _find_closest_hostile_target() -> CharacterBody3D:
	if not team_component or potential_targets.is_empty():
		return null

	var closest_target: CharacterBody3D = null
	var closest_distance: float = vision_range * vision_range  # Используем квадрат для оптимизации

	# Проверяем все потенциальные цели в зоне обнаружения
	for target in potential_targets:
		if not is_instance_valid(target) or target == self:
			continue

		# Проверяем наличие TeamComponent у цели (кешируем результат)
		if not target.has_node("TeamComponent"):
			continue

		var target_team: TeamComponent = target.get_node("TeamComponent")

		# Проверяем враждебность
		if team_component.is_hostile_to(target_team):
			# Используем distance_squared_to для оптимизации (избегаем sqrt)
			var distance_sq = global_position.distance_squared_to(target.global_position)
			if distance_sq < closest_distance:
				closest_distance = distance_sq
				closest_target = target

	return closest_target

func _on_detection_area_entered(body: Node3D) -> void:
	# Добавляем в список потенциальных целей
	if body is CharacterBody3D and body != self:
		if body.has_node("TeamComponent"):
			var target_team: TeamComponent = body.get_node("TeamComponent")
			if team_component and team_component.is_hostile_to(target_team):
				if not potential_targets.has(body):
					potential_targets.append(body)
					if enable_debug_prints:
						print("Enemy detected potential hostile: ", body.name)

				# Если были в IDLE - становимся настороже
				if current_state == State.IDLE:
					change_state(State.ALERT)
					last_known_target_pos = body.global_position

func _on_detection_area_exited(body: Node3D) -> void:
	# Убираем из списка потенциальных целей
	if body is CharacterBody3D:
		if potential_targets.has(body):
			potential_targets.erase(body)

# ============================================================================
# COMBAT
# ============================================================================

func perform_attack() -> void:
	if not melee_weapon:
		return

	# Играем анимацию
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("Melee_atack")

	# Выполняем атаку
	melee_weapon.try_attack(MeleeWeaponComponent.AttackType.HEAVY)

	if enable_debug_prints:
		print("Enemy attacking!")

# ============================================================================
# EVENT HANDLERS
# ============================================================================

func _on_health_changed(current_health: float, max_health: float, damaged: bool) -> void:
	if enable_debug_prints:
		print("Здоровье врага: ", current_health, "/", max_health)

	if damaged:
		_play_hit_effect()

		# Если получили урон и были в IDLE/PATROL - становимся агрессивными
		if current_state == State.IDLE or current_state == State.PATROL:
			# Попытаемся найти ближайшую враждебную цель
			current_target = _find_closest_hostile_target()
			if current_target:
				change_state(State.CHASE)

func _on_health_depleted() -> void:
	if enable_debug_prints:
		print("Враг убит")
	queue_free()

func _on_hit_received(damage: float, knockback_force: float, attacker_position: Vector3) -> void:
	# Применяем отброс
	var knockback_dir = (global_position - attacker_position).normalized()
	knockback_dir.y = 0.2  # Небольшой подъём
	velocity += knockback_dir * knockback_force

	# Прерываем атаку при получении урона
	if melee_weapon and current_state == State.ATTACK:
		melee_weapon.interrupt_attack()

func _play_hit_effect() -> void:
	# Вспышка белым цветом
	if mesh_instance:
		var material = mesh_instance.get_active_material(0) as StandardMaterial3D
		if material:
			material.albedo_color = Color(1, 1, 1)  # Белая вспышка
			hit_flash_time = 0.1  # Длительность вспышки
