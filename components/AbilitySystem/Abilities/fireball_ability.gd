# Fireball Ability - Shoots a projectile that damages enemies
extends BaseAbility
class_name FireballAbility

@export_group("Fireball Properties")
@export var damage: float = 50.0
@export var projectile_speed: float = 30.0
@export var projectile_lifetime: float = 5.0
@export var explosion_radius: float = 3.0
@export var fireball_scene: PackedScene  # Custom projectile scene (optional)

func _ready() -> void:
	super._ready()
	ability_name = "Fireball"
	description = "Launch a fiery projectile"
	cooldown = 5.0
	can_use_in_air = true

func activate(owner: CharacterBody3D) -> bool:
	if not super.activate(owner):
		return false

	_spawn_fireball()
	return true

func _spawn_fireball() -> void:
	if not owner_entity:
		return

	# Create fireball projectile
	var fireball: Node3D

	if fireball_scene:
		fireball = fireball_scene.instantiate()
	else:
		# Create simple default fireball
		fireball = _create_default_fireball()

	# Get spawn position (from camera/pivot if player)
	var spawn_pos: Vector3
	var direction: Vector3

	if owner_entity.has_node("Pivot/Camera3D"):
		var camera = owner_entity.get_node("Pivot/Camera3D") as Camera3D
		spawn_pos = camera.global_position + camera.global_transform.basis.z * -2.0
		direction = -camera.global_transform.basis.z
	else:
		spawn_pos = owner_entity.global_position + Vector3.UP * 1.5
		direction = -owner_entity.global_transform.basis.z

	fireball.global_position = spawn_pos

	# Add to scene
	owner_entity.get_tree().root.add_child(fireball)

	# Set velocity
	if fireball is RigidBody3D:
		fireball.linear_velocity = direction * projectile_speed
	elif fireball.has_method("set_direction"):
		fireball.set_direction(direction, projectile_speed)

	# Setup projectile script if it's our default
	if fireball.has_method("setup"):
		fireball.setup(damage, projectile_lifetime, explosion_radius, owner_entity)

	print("Fireball launched!")

func _create_default_fireball() -> Node3D:
	# Create a simple RigidBody3D fireball
	var fireball = RigidBody3D.new()
	fireball.gravity_scale = 0.0  # No gravity for fireball

	# Add mesh
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.3
	mesh_instance.mesh = sphere_mesh

	# Make it glow (emissive material)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.3, 0.0)  # Orange
	material.emission_enabled = true
	material.emission = Color(1.0, 0.5, 0.0)
	material.emission_energy_multiplier = 2.0
	mesh_instance.set_surface_override_material(0, material)

	fireball.add_child(mesh_instance)

	# Add collision
	var collision = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.3
	collision.shape = sphere_shape
	fireball.add_child(collision)

	# Add area for hit detection
	var area = Area3D.new()
	area.collision_layer = 2  # Hitbox layer
	area.collision_mask = 4   # Hurtbox layer
	var area_collision = CollisionShape3D.new()
	var area_shape = SphereShape3D.new()
	area_shape.radius = 0.3
	area_collision.shape = area_shape
	area.add_child(area_collision)
	fireball.add_child(area)

	# Add script for projectile behavior, ебать, создали сразу скрипт в скрипте который работает
	var script_text = """
extends RigidBody3D

var damage: float = 50.0
var lifetime: float = 5.0
var explosion_radius: float = 3.0
var owner_entity: Node3D
var hit_targets: Array = []

func setup(dmg: float, life: float, radius: float, owner: Node3D) -> void:
	damage = dmg
	lifetime = life
	explosion_radius = radius
	owner_entity = owner

	# Connect area signals
	if has_node('Area3D'):
		$Area3D.body_entered.connect(_on_body_entered)

	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	_explode()

func _on_body_entered(body: Node3D) -> void:
	# Hit something
	_explode()

func _explode() -> void:
	# Damage nearby enemies
	var space_state = get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = explosion_radius

	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = global_transform
	params.collision_mask = 4  # Hurtbox layer

	var results = space_state.intersect_shape(params)

	for result in results:
		var collider = result.collider
		if collider and collider != owner_entity:
			# Try to find hurtbox component
			var hurtbox = collider as Area3D
			if hurtbox and hurtbox.has_method('take_damage'):
				hurtbox.take_damage(damage, 5.0, global_position)

	# Visual effect (simple flash)
	print('FIREBALL EXPLODED!')

	queue_free()
"""

	var script = GDScript.new()
	script.source_code = script_text
	script.reload()
	fireball.set_script(script)

	return fireball
