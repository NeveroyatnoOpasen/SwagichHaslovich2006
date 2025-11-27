# weapon_item.gd
# Ресурс для оружия ближнего боя
extends InventoryItem
class_name WeaponItem

## Параметры легкой атаки
@export_group("Light Attack")
@export var light_damage: float = 20.0
@export var light_knockback: float = 5.0
@export var light_attack_duration: float = 0.3
@export var light_active_start: float = 0.1
@export var light_active_end: float = 0.25
@export var light_cooldown: float = 0.3

## Параметры тяжелой атаки
@export_group("Heavy Attack")
@export var heavy_damage: float = 50.0
@export var heavy_knockback: float = 10.0
@export var heavy_attack_duration: float = 0.6
@export var heavy_active_start: float = 0.2
@export var heavy_active_end: float = 0.5
@export var heavy_cooldown: float = 0.8

## Визуальное представление
@export_group("Visual")
@export var weapon_mesh: Mesh  # 3D модель оружия
@export var weapon_scene: PackedScene  # Готовая сцена оружия (альтернатива mesh)

## Конструктор - устанавливает тип автоматически
func _init():
	item_type = ItemType.WEAPON
	is_stackable = false
	max_stack = 1
	weight = 5.0

## Оружие можно экипировать
func is_equippable() -> bool:
	return true

## Экипировать оружие на персонажа
func equip(user: Node) -> void:
	# Находим WeaponHolder в структуре игрока
	var weapon_holder = user.get_node_or_null("Pivot/Camera3D/WeaponHolder")
	if not weapon_holder:
		push_error("Player doesn't have WeaponHolder at Pivot/Camera3D/WeaponHolder")
		return

	# Удаляем старое оружие (если есть)
	for child in weapon_holder.get_children():
		child.queue_free()

	# Создаём новую 3D модель оружия
	if weapon_scene:
		var model = weapon_scene.instantiate()
		weapon_holder.add_child(model)
		print("Equipped weapon model: %s" % item_name)
	elif weapon_mesh:
		# Альтернатива: создаём MeshInstance3D из Mesh
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = weapon_mesh
		weapon_holder.add_child(mesh_instance)
		print("Equipped weapon mesh: %s" % item_name)
	else:
		push_warning("Weapon %s has no scene or mesh" % item_name)

	# Применяем параметры к MeleeWeaponComponent
	var melee_weapon = user.get_node_or_null("MeleeWeaponComponent")
	if melee_weapon:
		apply_to_weapon_component(melee_weapon)
	else:
		push_warning("Player doesn't have MeleeWeaponComponent")

## Снять оружие с персонажа
func unequip(user: Node) -> void:
	var weapon_holder = user.get_node_or_null("Pivot/Camera3D/WeaponHolder")
	if weapon_holder:
		for child in weapon_holder.get_children():
			child.queue_free()
		print("Unequipped weapon: %s" % item_name)

## Переопределяем use() - для обратной совместимости
func use(user: Node) -> bool:
	equip(user)
	return true

## Применить параметры этого оружия к MeleeWeaponComponent
func apply_to_weapon_component(weapon_component: MeleeWeaponComponent):
	if not weapon_component:
		push_error("WeaponComponent is null")
		return

	# Light Attack
	weapon_component.light_damage = light_damage
	weapon_component.light_knockback = light_knockback
	weapon_component.light_attack_duration = light_attack_duration
	weapon_component.light_active_start = light_active_start
	weapon_component.light_active_end = light_active_end
	weapon_component.light_cooldown = light_cooldown

	# Heavy Attack
	weapon_component.heavy_damage = heavy_damage
	weapon_component.heavy_knockback = heavy_knockback
	weapon_component.heavy_attack_duration = heavy_attack_duration
	weapon_component.heavy_active_start = heavy_active_start
	weapon_component.heavy_active_end = heavy_active_end
	weapon_component.heavy_cooldown = heavy_cooldown

## Получить tooltip с информацией об оружии
func get_tooltip() -> String:
	var tooltip = super.get_tooltip()  # Вызываем родительский метод
	tooltip += "\n[color=yellow]WEAPON STATS[/color]\n"
	tooltip += "Light Damage: %.1f\n" % light_damage
	tooltip += "Heavy Damage: %.1f\n" % heavy_damage
	tooltip += "Light Cooldown: %.2fs\n" % light_cooldown
	tooltip += "Heavy Cooldown: %.2fs\n" % heavy_cooldown
	return tooltip
