# quest_item.gd
# Квестовые предметы (ключи, документы, артефакты)
extends InventoryItem
class_name QuestItem

## Параметры квестового предмета
@export_group("Quest Properties")
@export var quest_id: String = ""  # ID связанного квеста
@export var is_key_item: bool = false  # Важный предмет (нельзя выбросить)
@export var can_be_dropped: bool = false  # Можно ли выбросить
@export var auto_use_on_pickup: bool = false  # Автоматически использовать при подборе

## Конструктор
func _init():
	item_type = ItemType.QUEST_ITEM
	is_stackable = false
	max_stack = 1
	weight = 0.1
	value = 0  # Квестовые предметы обычно не продаются

## Переопределяем use() - триггерим квестовое событие
func use(user: Node) -> bool:
	# Здесь можно интегрироваться с системой квестов
	print("Quest item used: %s (quest_id: %s)" % [item_name, quest_id])

	# Можно испустить событие через DialogManager или QuestManager
	if quest_id != "":
		# Пример: DialogManager.trigger_event("quest_item_used", {"item_id": item_id, "quest_id": quest_id})
		pass

	return true

## Квестовые предметы обычно нельзя использовать напрямую
func can_use() -> bool:
	return not is_key_item  # Ключевые предметы используются автоматически

## Tooltip
func get_tooltip() -> String:
	var tooltip = super.get_tooltip()
	tooltip += "\n[color=purple]QUEST ITEM[/color]\n"

	if is_key_item:
		tooltip += "[Important - Cannot be dropped]\n"

	if quest_id != "":
		tooltip += "Related to quest: %s\n" % quest_id

	return tooltip
