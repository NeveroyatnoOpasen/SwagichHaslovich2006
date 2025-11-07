extends "res://miscelanius/scripts/interactable.gd"

var World = get_tree()
var drag = false
var player: Node3D
var raycast: RayCast3D

# Настройки пружинного притяжения
var spring_constant: float = 30.0
var damping_constant: float = 8.0
var max_force: float = 100.0
var dead_zone: float = 0.5

func use():
	drag = !drag  # Переключаем режим drag
	if drag:
		# Находим игрока и RayCast при первом использовании
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			player = players[0]
			raycast = player.get_node("Pivot").get_node("InteractRay")
		
		# Делаем объект более отзывчивым при перетаскивании
		$".".gravity_scale = 0.2  # Уменьшаем гравитацию
		$".".linear_damp = 2.0    # Добавляем демпфирование
	else:
		# Возвращаем оригинальные физические свойства
		$".".gravity_scale = 1.0
		$".".linear_damp = 0.0
		player = null
		raycast = null

func _physics_process(delta: float) -> void:
	if drag and player and raycast and is_instance_valid(player):
		var endpoint = get_raycast_end_point()
		apply_spring_force(endpoint, delta)

# Пружинное притяжение
func apply_spring_force(target_position: Vector3, delta: float):
	var displacement = target_position - global_position
	var distance = displacement.length()
	
	if distance > dead_zone:
		# Пружинная сила (пропорциональна смещению)
		var spring_force = displacement * spring_constant
		# Демпфирование (гасит колебания, пропорционально скорости)
		var damping_force = -$".".linear_velocity * damping_constant
		
		var total_force = spring_force + damping_force
		$".".apply_central_force(total_force.limit_length(max_force))

# Получение конечной точки луча с проверками
func get_raycast_end_point() -> Vector3:
	if raycast and raycast.is_colliding():
		return raycast.get_collision_point()
	elif raycast:
		return raycast.to_global(Vector3(0, 0, -raycast.target_position.length()))
	else:
		return Vector3.ZERO

# Останавливаем перетаскивание если объект уничтожен
func _exit_tree():
	drag = false
