# material_item.gd
# Материалы для крафта (руда, дерево, ткань и т.д.)
extends InventoryItem
class_name MaterialItem

## Категории материалов
enum MaterialCategory {
	ORE,         # Руда (железо, золото)
	WOOD,        # Дерево
	FABRIC,      # Ткань
	LEATHER,     # Кожа
	HERB,        # Травы
	COMPONENT    # Компоненты (винтики, механизмы)
}

## Параметры материала
@export_group("Material Properties")
@export var category: MaterialCategory = MaterialCategory.COMPONENT
@export var rarity: int = 1  # 1-5 (1 = common, 5 = legendary)

## Конструктор
func _init():
	item_type = ItemType.MATERIAL
	is_stackable = true
	max_stack = 999
	weight = 0.1

## Материалы нельзя использовать напрямую
func use(user: Node) -> bool:
	push_warning("Materials cannot be used directly. Use them in crafting.")
	return false

func can_use() -> bool:
	return false  # Материалы используются только в крафте

## Tooltip
func get_tooltip() -> String:
	var tooltip = super.get_tooltip()
	tooltip += "\n[color=gray]MATERIAL[/color]\n"

	var rarity_text = ["", "Common", "Uncommon", "Rare", "Epic", "Legendary"]
	if rarity >= 1 and rarity <= 5:
		tooltip += "Rarity: %s\n" % rarity_text[rarity]

	var category_names = ["Ore", "Wood", "Fabric", "Leather", "Herb", "Component"]
	tooltip += "Category: %s\n" % category_names[category]

	return tooltip
