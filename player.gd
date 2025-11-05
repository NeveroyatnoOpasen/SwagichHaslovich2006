extends CharacterBody3D

@export var speed := 6.0
@export var jump_velocity := 5.0
@export var mouse_sensitivity := 0.003
@export var max_pitch_deg := 85.0
@export var tilt_amount := 0.1  # Сила наклона камеры
@export var tilt_speed := 5.0   # Скорость возврата камеры в исходное положение

@onready var pivot: Node3D = $Pivot
@onready var camera: Camera3D = $Pivot/Camera3D  # Предполагаем, что камера - дочерний объект Pivot

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var yaw := 0.0   # поворот корпуса по Y
var pitch := 0.0 # наклон головы/камеры по X
var target_tilt := 0.0  # Целевой наклон камеры
var current_tilt := 0.0  # Текущий наклон камеры

var mouse_input := Vector2.ZERO

func _ready() -> void:
	# Захватываем курсор и скрываем его
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Накопление ввода мыши
		mouse_input = event.relative
	
	# Esc — отпустить/захватить мышь (удобно в редакторе)
	if event.is_action_pressed("ui_cancel"):
		var captured := Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if captured else Input.MOUSE_MODE_CAPTURED)
	
	if event.is_action_pressed("use"):
		$Pivot/InteractRay.use()
		print("use colider")

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
	
	# читаем ввод с клавиатуры (вынесено)
	var move_dir: Vector3 = get_move_input()
	
	# Вычисляем наклон камеры на основе движения
	calculate_tilt(move_dir)
	
	# Применяем плавный наклон камеры
	apply_camera_tilt(delta)

	# движение по XZ
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
