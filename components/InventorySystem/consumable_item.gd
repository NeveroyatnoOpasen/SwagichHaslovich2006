# consumable_item.gd
# Ресурс для расходных предметов (зелья, еда, баффы)
extends InventoryItem
class_name ConsumableItem

## Типы расходников
enum ConsumableType {
	HEALTH_POTION,   # Восстанавливает здоровье
	STAMINA_POTION,  # Восстанавливает выносливость
	BUFF,            # Временный бафф
	FOOD,            # Еда (здоровье + бафф)
	POISON           # Яд (для врагов или дебафф)
}

## Параметры расходника
@export_group("Consumable Properties")
@export var consumable_type: ConsumableType = ConsumableType.HEALTH_POTION
@export var heal_amount: float = 50.0  # Количество восстанавливаемого HP
@export var stamina_amount: float = 0.0  # Количество восстанавливаемой выносливости
@export var buff_duration: float = 0.0  # Длительность баффа (секунды)
@export var buff_effect: String = ""  # Название эффекта баффа

@export_group("Visual & Audio")
@export var use_animation: String = "drink"  # Анимация использования
@export var use_sound: AudioStream  # Звук использования

## Конструктор
func _init():
	item_type = ItemType.CONSUMABLE
	is_stackable = true
	max_stack = 99
	weight = 0.5

## Переопределяем use() - применяем эффект
func use(user: Node) -> bool:
	# Проверяем, есть ли у пользователя компонент здоровья
	var health_component = user.get_node_or_null("health_component")

	match consumable_type:
		ConsumableType.HEALTH_POTION:
			if health_component and health_component.has_method("heal"):
				health_component.heal(heal_amount)
				print("%s used %s, healed for %d HP" % [user.name, item_name, heal_amount])
				return true
			else:
				push_warning("User has no HealthComponent to heal")
				return false

		ConsumableType.STAMINA_POTION:
			# TODO: Реализовать систему выносливости
			print("%s used %s, restored %d stamina" % [user.name, item_name, stamina_amount])
			return true

		ConsumableType.BUFF:
			# TODO: Реализовать систему баффов
			print("%s used %s, gained buff '%s' for %ds" % [user.name, item_name, buff_effect, buff_duration])
			return true

		ConsumableType.FOOD:
			if health_component and health_component.has_method("heal"):
				health_component.heal(heal_amount)
			print("%s ate %s" % [user.name, item_name])
			return true

		ConsumableType.POISON:
			# Яд обычно не используется игроком на себе
			push_warning("Trying to use poison on self")
			return false

	return false

## Можно ли использовать этот предмет
func can_use() -> bool:
	# Зелья здоровья нельзя использовать при полном HP (опционально)
	# Здесь можно добавить дополнительные проверки
	return true

## Получить tooltip
func get_tooltip() -> String:
	var tooltip = super.get_tooltip()
	tooltip += "\n[color=green]CONSUMABLE[/color]\n"

	match consumable_type:
		ConsumableType.HEALTH_POTION:
			tooltip += "Restores: %d HP\n" % heal_amount
		ConsumableType.STAMINA_POTION:
			tooltip += "Restores: %d Stamina\n" % stamina_amount
		ConsumableType.BUFF:
			tooltip += "Effect: %s\n" % buff_effect
			tooltip += "Duration: %.1fs\n" % buff_duration
		ConsumableType.FOOD:
			tooltip += "Restores: %d HP\n" % heal_amount

	return tooltip
