# Простой враг с боевой системой
extends CharacterBody3D

# AI States
enum State {
	IDLE,      # Стоит на месте, осматривается
	PATROL,    # Патрулирование между точками
	ALERT,     # Заметил что-то подозрительное
	CHASE,     # Преследует игрока
	ATTACK,    # Атакует игрока
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

# Patrol parameters
@export_group("Patrol")
@export var patrol_points: Array[Vector3] = []  # Точки патрулирования
@export var patrol_wait_time: float = 2.0       # Время ожидания на точке

# Internal state
var current_state: State = State.IDLE
var player: CharacterBody3D = null
var target_position: Vector3
var last_known_player_pos: Vector3
var can_see_player: bool = false
var time_since_seen_player: float = 0.0
var attack_timer: float = 0.0
var patrol_index: int = 0
var patrol_wait_timer: float = 0.0
var idle_rotation_timer: float = 0.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var hit_flash_time: float = 0.0
var current_speed: float = 0.0 
func _ready() -> void:
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

	# Найти игрока в сцене (отложенно, чтобы игрок успел заспавниться)
	call_deferred("_find_player")

func _find_player() -> void:
	# Найти игрока в сцене (но не преследовать сразу)
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
		print("Enemy found player: ", player.name)
	else:
		print("Enemy: No player found in scene yet")
		# Попробуем снова через секунду
		await get_tree().create_timer(1.0).timeout
		_find_player()

# ============================================================================
# STATE MACHINE
# ============================================================================

func change_state(new_state: State) -> void:
	if current_state == new_state:
		return

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
	if health_component and health_component.health < health_component.max_health * retreat_health_percent:
		if current_state != State.RETREAT:
			change_state(State.RETREAT)

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

	# Если увидел игрока - переходим в chase
	if can_see_player:
		change_state(State.CHASE)
	elif patrol_points.size() > 0 and idle_rotation_timer > 3.0:
		change_state(State.PATROL)

func _state_patrol(delta: float) -> void:
	if patrol_points.size() == 0:
		change_state(State.IDLE)
		return

	# Если увидел игрока - chase
	if can_see_player:
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
	# Идет к последней известной позиции игрока
	if can_see_player:
		change_state(State.CHASE)
		return

	time_since_seen_player += delta

	if global_position.distance_to(last_known_player_pos) < 2.0:
		# Достигли последней точки - осматриваемся
		rotation.y += delta * 2.0
		if time_since_seen_player > lose_sight_time:
			change_state(State.IDLE)
	else:
		move_towards_target(last_known_player_pos)

func _state_chase(delta: float) -> void:
	if not player:
		change_state(State.IDLE)
		return

	if not can_see_player:
		time_since_seen_player += delta
		if time_since_seen_player > lose_sight_time:
			change_state(State.ALERT)
			return
	else:
		time_since_seen_player = 0.0
		last_known_player_pos = player.global_position

	var distance = global_position.distance_to(player.global_position)

	# Если близко - атакуем
	if distance <= attack_range:
		change_state(State.ATTACK)
	else:
		move_towards_target(player.global_position)

func _state_attack(delta: float) -> void:
	if not player:
		change_state(State.IDLE)
		return

	attack_timer -= delta

	var distance = global_position.distance_to(player.global_position)

	# Если игрок убежал далеко
	if distance > attack_range * 1.5:
		change_state(State.CHASE)
		return

	# Поворачиваемся к игроку
	look_at_target(player.global_position)

	# Управление дистанцией
	if distance < min_attack_range:
		# Слишком близко - отходим
		move_away_from_target(player.global_position, delta)
	elif distance > attack_range:
		# Слишком далеко - подходим
		move_towards_target(player.global_position)
	else:
		# Оптимальная дистанция - атакуем
		if attack_timer <= 0 and melee_weapon and melee_weapon.can_attack():
			perform_attack()
			attack_timer = attack_cooldown

func _state_retreat(delta: float) -> void:
	if not player:
		change_state(State.IDLE)
		return

	# Убегаем от игрока
	move_away_from_target(player.global_position, delta)

	# Если здоровье восстановилось
	if health_component and health_component.health > health_component.max_health * (retreat_health_percent + 0.1):
		change_state(State.CHASE)
func _process(delta: float) -> void:
	# Обновляем AI
	update_state(delta)

	# Проверяем видимость игрока
	check_player_vision()

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

	nav.target_position = target
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

func check_player_vision() -> void:
	if not player or not vision_ray:
		can_see_player = false
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	# Проверка дистанции
	if distance_to_player > vision_range:
		can_see_player = false
		return

	# Проверка угла обзора
	var direction_to_player = (player.global_position - global_position).normalized()
	var forward = -global_transform.basis.z
	var angle = rad_to_deg(forward.angle_to(direction_to_player))

	if angle > vision_angle / 2.0:
		can_see_player = false
		return

	# Проверка line of sight
	vision_ray.look_at(player.global_position, Vector3.UP)
	vision_ray.force_raycast_update()

	if vision_ray.is_colliding():
		var collider = vision_ray.get_collider()
		if collider == player:
			can_see_player = true
		else:
			can_see_player = false
	else:
		can_see_player = false

func _on_detection_area_entered(body: Node3D) -> void:
	if body == player and current_state == State.IDLE:
		# Услышал игрока поблизости - становимся настороже
		change_state(State.ALERT)
		last_known_player_pos = player.global_position

func _on_detection_area_exited(body: Node3D) -> void:
	pass  # Можно добавить логику при выходе из зоны

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
	print("Enemy attacking!")

# ============================================================================
# EVENT HANDLERS
# ============================================================================

func _on_health_changed(current_health: float, max_health: float, damaged: bool) -> void:
	print("Здоровье врага: ", current_health, "/", max_health)

	if damaged:
		_play_hit_effect()

		# Если получили урон и были в IDLE/PATROL - становимся агрессивными
		if current_state == State.IDLE or current_state == State.PATROL:
			if player:
				change_state(State.CHASE)

func _on_health_depleted() -> void:
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
