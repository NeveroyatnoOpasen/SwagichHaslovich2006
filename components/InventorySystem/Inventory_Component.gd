# Компонент инвентаря - управление предметами игрока
extends Node
class_name InventoryComponent
# == Пизделка == 
# Короче, в мире будет муляж со скриптом pickup который будет вызывать
# add_item в инвентарь игрока. Сам ресурс который лежит в инвентаре
# будет уже создавать модельку оружия и присобачивать его к руке.
# === ХРАНИЛИЩЕ ===
@export var inventory: Array[InventoryItem]  # Слоты инвентаря
var current_slot: int = 0  # Текущий активный слот (для hotbar)

# === ОСНОВНЫЕ МЕТОДЫ ===

## Переключение на слот (для hotbar системы)
func swap_to(index: int) -> void:
	if index < 0 or index >= inventory.size():
		push_warning("Invalid slot index: %d" % index)
		return

	current_slot = index
	var item = get_current_item()
	if item:
		print("Switched to slot %d: %s" % [index, item.item_name])
	else:
		print("Switched to slot %d: [Empty]" % index)

## Добавление предмета в первый свободный слот
func add_item(item: InventoryItem) -> bool:
	if not item:
		push_warning("Trying to add null item")
		return false

	for i in range(inventory.size()):
		if inventory[i] == null:
			inventory[i] = item
			print("Added %s to slot %d" % [item.item_name, i])
			return true

	print("Inventory full! Cannot add %s" % item.item_name)
	return false

## Удаление предмета по индексу слота
func delete_item(index: int) -> void:
	if index < 0 or index >= inventory.size():
		push_warning("Invalid slot index: %d" % index)
		return

	var item = inventory[index]
	if item:
		print("Removed %s from slot %d" % [item.item_name, index])
		inventory[index] = null
	else:
		print("Slot %d is already empty" % index)

## Отладочная информация
func debug_info() -> void:
	print("=== INVENTORY DEBUG ===")
	print("Current slot: %d" % current_slot)
	print("Total slots: %d" % inventory.size())

	var filled_count = 0
	for i in range(inventory.size()):
		if inventory[i] != null:
			filled_count += 1
			print("  [%d] %s" % [i, inventory[i].item_name])

	print("Filled: %d / %d" % [filled_count, inventory.size()])
	print("Empty slots: %d" % (inventory.size() - filled_count))

# === ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ===

## Получить предмет в текущем слоте
func get_current_item() -> InventoryItem:
	if current_slot >= 0 and current_slot < inventory.size():
		return inventory[current_slot]
	return null

## Получить предмет по индексу
func get_item_at(index: int) -> InventoryItem:
	if index >= 0 and index < inventory.size():
		return inventory[index]
	return null

## Проверить, есть ли предмет в слоте
func is_slot_empty(index: int) -> bool:
	if index < 0 or index >= inventory.size():
		return true
	return inventory[index] == null

## Получить первый свободный слот
func get_first_empty_slot() -> int:
	for i in range(inventory.size()):
		if inventory[i] == null:
			return i
	return -1  # Нет свободных

## Swap между двумя слотами
func swap_slots(slot_a: int, slot_b: int) -> void:
	if slot_a < 0 or slot_a >= inventory.size():
		push_warning("Invalid slot A: %d" % slot_a)
		return
	if slot_b < 0 or slot_b >= inventory.size():
		push_warning("Invalid slot B: %d" % slot_b)
		return

	var temp = inventory[slot_a]
	inventory[slot_a] = inventory[slot_b]
	inventory[slot_b] = temp

	print("Swapped slot %d <-> %d" % [slot_a, slot_b])

## Проверить, полон ли инвентарь
func is_full() -> bool:
	return get_first_empty_slot() == -1
