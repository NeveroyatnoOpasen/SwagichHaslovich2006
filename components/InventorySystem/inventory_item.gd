# inventory_item.gd
# Базовый класс для всех предметов в инвентаре
extends Resource
class_name InventoryItem

## Типы предметов
enum ItemType {
	WEAPON,      # Оружие
	CONSUMABLE,  # Расходники (зелья, еда)
	ARMOR,       # Броня (на будущее)
	QUEST_ITEM,  # Квестовые предметы
	MATERIAL     # Материалы для крафта
}

## Базовые свойства предмета
@export_group("Basic Info")
@export var item_id: String = ""  # Уникальный ID (например, "iron_sword")
@export var item_name: String = "Item"  # Отображаемое имя
@export_multiline var description: String = ""  # Описание предмета
@export var icon: Texture2D  # Иконка для UI

## Характеристики
@export_group("Properties")
@export var item_type: ItemType = ItemType.MATERIAL
@export var is_stackable: bool = false  # Можно ли складывать в стопки
@export var max_stack: int = 1  # Максимальный размер стопки
@export var weight: float = 1.0  # Вес (для системы инвентаря)
@export var value: int = 0  # Стоимость (золото)

## Виртуальный метод для использования предмета
## Переопределяется в наследниках
func use(user: Node) -> bool:
	push_warning("InventoryItem.use() called on base class. Override this in child classes.")
	return false

## Получить информацию о предмете для UI
func get_tooltip() -> String:
	var tooltip = "[b]%s[/b]\n" % item_name
	tooltip += description + "\n"
	tooltip += "Value: %d gold\n" % value
	tooltip += "Weight: %.1f\n" % weight
	return tooltip

## Можно ли использовать этот предмет
func can_use() -> bool:
	return true

## Можно ли экипировать этот предмет
## Переопределяется в наследниках (WeaponItem, ArmorItem)
func is_equippable() -> bool:
	return false

## Экипировать предмет на персонажа
## Переопределяется в наследниках
func equip(user: Node) -> void:
	push_warning("InventoryItem.equip() not implemented for %s" % item_name)

## Снять предмет с персонажа
## Переопределяется в наследниках
func unequip(user: Node) -> void:
	pass
