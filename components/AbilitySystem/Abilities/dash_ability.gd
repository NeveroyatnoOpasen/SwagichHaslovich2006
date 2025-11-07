# Dash Ability - Quick movement burst in current direction
extends BaseAbility
class_name DashAbility

@export_group("Dash Properties")
@export var dash_speed: float = 20.0
@export var dash_duration: float = 0.2
@export var dash_direction_mode: DashDirection = DashDirection.MOVEMENT

enum DashDirection {
	MOVEMENT,  # Dash in movement input direction
	FORWARD,   # Always dash forward (camera direction)
	BACKWARD   # Dash backward
}

var dash_time_remaining: float = 0.0
var dash_velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	super._ready()  # Вызываем событие из родительского класса (уже делает set_process(false))
	ability_name = "Dash"
	description = "Quickly dash in a direction"
	cooldown = 3.0
	can_use_in_air = false
	# set_process(false) не нужен - уже вызван в super._ready()

func activate(owner: CharacterBody3D) -> bool:
	print("=== DASH ACTIVATE CALLED ===")

	if not super.activate(owner):
		print("DASH FAILED: super.activate() returned false (cooldown or other)")
		return false

	# Calculate dash direction
	var dash_dir = _get_dash_direction()

	if dash_dir.length() < 0.1:
		print("DASH: No input direction, using forward")
		# No direction input, dash forward by default
		dash_dir = -owner.global_transform.basis.z

	# Normalize and set velocity
	dash_velocity = dash_dir.normalized() * dash_speed
	dash_time_remaining = dash_duration

	set_process(true)
	print("DASH ACTIVATED! Speed: ", dash_speed, " Direction: ", dash_dir)

	return true

func _process(delta: float) -> void:
	super._process(delta)  # Обрабатываем кулдаун

	if dash_time_remaining > 0.0:
		# Apply dash velocity
		if owner_entity:
			owner_entity.velocity.x = dash_velocity.x
			owner_entity.velocity.z = dash_velocity.z

		dash_time_remaining -= delta

		if dash_time_remaining <= 0.0:
			# Dash finished, но НЕ отключаем _process - кулдаун еще идет!
			# BaseAbility сам отключит _process когда кулдаун закончится
			print("Dash movement finished, cooldown still active")

func _get_dash_direction() -> Vector3:
	var direction = Vector3.ZERO

	match dash_direction_mode:
		DashDirection.MOVEMENT:
			# Get movement input direction
			var input_dir = Vector2.ZERO
			if Input.is_action_pressed("move_forward"):
				input_dir.y -= 1
			if Input.is_action_pressed("move_backward"):
				input_dir.y += 1
			if Input.is_action_pressed("move_left"):
				input_dir.x -= 1
			if Input.is_action_pressed("move_right"):
				input_dir.x += 1

			if input_dir.length() > 0.0:
				# Transform input to world space based on camera
				var forward = -owner_entity.global_transform.basis.z
				var right = owner_entity.global_transform.basis.x
				forward.y = 0
				right.y = 0
				forward = forward.normalized()
				right = right.normalized()

				direction = (forward * -input_dir.y + right * input_dir.x)
			else:
				# No input, use forward
				direction = -owner_entity.global_transform.basis.z

		DashDirection.FORWARD:
			direction = -owner_entity.global_transform.basis.z

		DashDirection.BACKWARD:
			direction = owner_entity.global_transform.basis.z

	direction.y = 0  # Keep horizontal
	return direction
