# Inventory System / Система инвентаря

## Обзор системы

Гибкая, расширяемая система инвентаря на основе ресурсов (Resource) с использованием ООП и полиморфизма.

---

## 📁 Структура файлов

```
InventorySystem/
├── inventory_item.gd        # Базовый класс (Resource)
├── weapon_item.gd           # Оружие
├── consumable_item.gd       # Расходники (зелья, еда)
├── quest_item.gd            # Квестовые предметы
├── material_item.gd         # Материалы для крафта
└── README.md                # Эта документация
```

---

## 🏗️ Иерархия классов

```
Resource (Godot)
    ↓
InventoryItem (базовый класс)
    ├─→ WeaponItem       - Оружие ближнего боя
    ├─→ ConsumableItem   - Зелья, еда, баффы
    ├─→ QuestItem        - Квестовые предметы, ключи
    └─→ MaterialItem     - Материалы для крафта
```

---

## 🎯 Базовый класс: InventoryItem

### Свойства

```gdscript
# Основная информация
item_id: String          # Уникальный ID
item_name: String        # Отображаемое имя
description: String      # Описание
icon: Texture2D          # Иконка для UI

# Характеристики
item_type: ItemType      # Тип предмета (enum)
is_stackable: bool       # Можно ли складывать в стопки
max_stack: int           # Макс. размер стопки
weight: float            # Вес
value: int               # Стоимость в золоте
```

### Методы

```gdscript
use(user: Node) -> bool          # Использовать предмет
can_use() -> bool                # Можно ли использовать
get_tooltip() -> String          # Получить tooltip для UI
```

### Пример использования

```gdscript
# Создание предмета
var item = InventoryItem.new()
item.item_id = "generic_item"
item.item_name = "Generic Item"
item.value = 10

# Использование
if item.can_use():
    item.use(player)
```

---

## ⚔️ WeaponItem - Оружие

### Дополнительные свойства

```gdscript
# Light Attack
light_damage: float = 20.0
light_knockback: float = 5.0
light_attack_duration: float = 0.3
light_active_start: float = 0.1
light_active_end: float = 0.25
light_cooldown: float = 0.3

# Heavy Attack
heavy_damage: float = 50.0
heavy_knockback: float = 10.0
heavy_attack_duration: float = 0.6
heavy_active_start: float = 0.2
heavy_active_end: float = 0.5
heavy_cooldown: float = 0.8

# Визуал
weapon_mesh: Mesh               # 3D модель
weapon_scene: PackedScene       # Готовая сцена оружия
```

### Специальные методы

```gdscript
apply_to_weapon_component(weapon_component: MeleeWeaponComponent)
# Применяет параметры оружия к компоненту
```

### Пример создания меча

```gdscript
var iron_sword = WeaponItem.new()
iron_sword.item_id = "iron_sword"
iron_sword.item_name = "Iron Sword"
iron_sword.description = "A sturdy iron blade"
iron_sword.value = 100
iron_sword.weight = 5.0

# Параметры атаки
iron_sword.light_damage = 25.0
iron_sword.heavy_damage = 55.0
iron_sword.light_cooldown = 0.4
iron_sword.heavy_cooldown = 1.0

# Использование (экипировка)
iron_sword.use(player)  # Вызовет player.equip_weapon(iron_sword)
```

### Создание как ресурс

**В Godot Editor:**
1. Create New → Resource → WeaponItem
2. Настройте параметры в Inspector
3. Save As → `res://items/weapons/iron_sword.tres`

**Загрузка:**
```gdscript
var sword = load("res://items/weapons/iron_sword.tres") as WeaponItem
```

---

## 🧪 ConsumableItem - Расходники

### Типы расходников

```gdscript
enum ConsumableType {
    HEALTH_POTION,   # Восстанавливает здоровье
    STAMINA_POTION,  # Восстанавливает выносливость
    BUFF,            # Временный бафф
    FOOD,            # Еда
    POISON           # Яд
}
```

### Свойства

```gdscript
consumable_type: ConsumableType = HEALTH_POTION
heal_amount: float = 50.0       # HP восстановления
stamina_amount: float = 0.0     # Stamina восстановления
buff_duration: float = 0.0      # Длительность баффа
buff_effect: String = ""        # Название эффекта
use_animation: String = "drink" # Анимация использования
use_sound: AudioStream          # Звук использования
```

### Пример зелья здоровья

```gdscript
var health_potion = ConsumableItem.new()
health_potion.item_id = "health_potion_small"
health_potion.item_name = "Small Health Potion"
health_potion.description = "Restores 50 HP"
health_potion.value = 25
health_potion.is_stackable = true
health_potion.max_stack = 99

health_potion.consumable_type = ConsumableItem.ConsumableType.HEALTH_POTION
health_potion.heal_amount = 50.0

# Использование
health_potion.use(player)  # Восстановит 50 HP игроку
```

### Интеграция с HealthComponent

```gdscript
# ConsumableItem автоматически находит HealthComponent
func use(user: Node) -> bool:
    var health_component = user.get_node_or_null("health_component")
    if health_component:
        health_component.heal(heal_amount)
        return true
    return false
```

---

## 📜 QuestItem - Квестовые предметы

### Свойства

```gdscript
quest_id: String = ""             # ID связанного квеста
is_key_item: bool = false         # Важный предмет
can_be_dropped: bool = false      # Можно ли выбросить
auto_use_on_pickup: bool = false  # Авто-использование
```

### Пример квестового ключа

```gdscript
var ancient_key = QuestItem.new()
ancient_key.item_id = "ancient_key"
ancient_key.item_name = "Ancient Key"
ancient_key.description = "A mysterious key found in the ruins"
ancient_key.quest_id = "unlock_ancient_door"
ancient_key.is_key_item = true
ancient_key.can_be_dropped = false
ancient_key.value = 0  # Не продаётся

# Использование триггерит квестовое событие
ancient_key.use(player)
```

---

## 🔨 MaterialItem - Материалы

### Категории

```gdscript
enum MaterialCategory {
    ORE,         # Руда
    WOOD,        # Дерево
    FABRIC,      # Ткань
    LEATHER,     # Кожа
    HERB,        # Травы
    COMPONENT    # Компоненты
}
```

### Свойства

```gdscript
category: MaterialCategory = COMPONENT
rarity: int = 1  # 1-5 (Common to Legendary)
```

### Пример железной руды

```gdscript
var iron_ore = MaterialItem.new()
iron_ore.item_id = "iron_ore"
iron_ore.item_name = "Iron Ore"
iron_ore.description = "Raw iron ore, can be smelted"
iron_ore.value = 5
iron_ore.is_stackable = true
iron_ore.max_stack = 999
iron_ore.weight = 0.5

iron_ore.category = MaterialItem.MaterialCategory.ORE
iron_ore.rarity = 1  # Common

# Материалы нельзя использовать напрямую
iron_ore.can_use()  # Returns false
```

---

## 🔄 Полиморфизм в действии

### Универсальная обработка предметов

```gdscript
# Инвентарь хранит базовый тип
var inventory: Array[InventoryItem] = []

# Добавляем разные типы
inventory.append(WeaponItem.new())
inventory.append(ConsumableItem.new())
inventory.append(QuestItem.new())

# Обрабатываем универсально
for item in inventory:
    print(item.get_tooltip())  # Каждый тип вернёт свой tooltip

    if item.can_use():
        item.use(player)  # Вызовет правильную версию use()
```

### Проверка типа

```gdscript
func handle_item_click(item: InventoryItem):
    if item is WeaponItem:
        print("Weapon damage: ", item.damage)
        player.equip_weapon(item)

    elif item is ConsumableItem:
        print("Heals: ", item.heal_amount)
        item.use(player)

    elif item is QuestItem:
        if item.is_key_item:
            print("This is a key item!")

    elif item is MaterialItem:
        print("Material for crafting")
```

---

## 📦 Создание предметов

### Метод 1: Программно

```gdscript
var sword = WeaponItem.new()
sword.item_name = "Excalibur"
sword.light_damage = 100.0
```

### Метод 2: Через ресурсы (.tres)

**Преимущества:**
- ✅ Визуальное редактирование в Inspector
- ✅ Переиспользование
- ✅ Легко балансировать
- ✅ Можно хранить в папках

**Как создать:**
1. В FileSystem: Right Click → Create New → Resource
2. Выберите тип (WeaponItem, ConsumableItem, etc.)
3. Настройте параметры в Inspector
4. Save As → `items/weapons/my_sword.tres`

**Загрузка:**
```gdscript
# Preload (компилируется)
const IRON_SWORD = preload("res://items/weapons/iron_sword.tres")

# Load (динамически)
var sword = load("res://items/weapons/iron_sword.tres") as WeaponItem
```

---

## 🎮 Интеграция с игровыми системами

### Экипировка оружия

```gdscript
# В player.gd
func equip_weapon(weapon: WeaponItem):
    # Применяем параметры к MeleeWeaponComponent
    if melee_weapon_component:
        weapon.apply_to_weapon_component(melee_weapon_component)

    # Меняем модель
    if weapon.weapon_scene:
        # Instantiate weapon model
        pass

    print("Equipped: ", weapon.item_name)
```

### Использование зелий

```gdscript
# ConsumableItem автоматически найдёт HealthComponent
potion.use(player)

# Или вручную:
func use_consumable(item: ConsumableItem):
    if health_component:
        health_component.heal(item.heal_amount)
```

### Квестовые предметы

```gdscript
# В quest_item.gd
func use(user: Node) -> bool:
    if quest_id != "":
        DialogManager.trigger_event("quest_item_used", {
            "item_id": item_id,
            "quest_id": quest_id
        })
    return true
```

---

## 🧰 Утилиты и вспомогательные классы

### ItemFactory (пример)

```gdscript
class_name ItemFactory

static func create_item(item_id: String) -> InventoryItem:
    match item_id:
        "iron_sword":
            return load("res://items/weapons/iron_sword.tres")
        "health_potion":
            return load("res://items/consumables/health_potion.tres")
        _:
            push_error("Unknown item: " + item_id)
            return null
```

### ItemDatabase (пример)

```gdscript
class_name ItemDatabase

const ITEMS_PATH = "res://items/"

static var _items_cache: Dictionary = {}

static func get_item(item_id: String) -> InventoryItem:
    if _items_cache.has(item_id):
        return _items_cache[item_id]

    var item = load(ITEMS_PATH + item_id + ".tres")
    _items_cache[item_id] = item
    return item
```

---

## 📊 Система инвентаря (будущее расширение)

```gdscript
class_name InventoryComponent extends Node

var items: Array[InventoryItem] = []
var max_weight: float = 100.0

signal item_added(item: InventoryItem)
signal item_removed(item: InventoryItem)

func add_item(item: InventoryItem) -> bool:
    var current_weight = _calculate_total_weight()

    if current_weight + item.weight > max_weight:
        print("Inventory full!")
        return false

    items.append(item)
    item_added.emit(item)
    return true

func remove_item(item: InventoryItem):
    items.erase(item)
    item_removed.emit(item)

func _calculate_total_weight() -> float:
    var total = 0.0
    for item in items:
        total += item.weight
    return total
```

---

## 🎨 UI Integration (пример)

```gdscript
# В UI скрипте
func display_item(item: InventoryItem):
    # Иконка
    item_icon.texture = item.icon

    # Имя
    item_name_label.text = item.item_name

    # Tooltip
    tooltip_label.text = item.get_tooltip()

    # Цвет рамки по типу
    match item.item_type:
        InventoryItem.ItemType.WEAPON:
            border.modulate = Color.RED
        InventoryItem.ItemType.CONSUMABLE:
            border.modulate = Color.GREEN
        InventoryItem.ItemType.QUEST_ITEM:
            border.modulate = Color.PURPLE
```

---

## ⚡ Performance Tips

1. **Используйте preload для часто используемых предметов:**
```gdscript
const COMMON_ITEMS = {
    "health_potion": preload("res://items/consumables/health_potion.tres"),
    "iron_sword": preload("res://items/weapons/iron_sword.tres")
}
```

2. **Кешируйте ресурсы:**
```gdscript
var _item_cache: Dictionary = {}

func get_item(id: String) -> InventoryItem:
    if not _item_cache.has(id):
        _item_cache[id] = load("res://items/" + id + ".tres")
    return _item_cache[id]
```

3. **Используйте дублирование для stackable items:**
```gdscript
var original = load("res://items/arrow.tres") as MaterialItem
var duplicate = original.duplicate()  # Отдельная копия
```

---

## 📝 Checklist для создания нового типа предмета

- [ ] Создать новый класс, наследующий InventoryItem
- [ ] Добавить специфичные для типа свойства
- [ ] Переопределить `use(user)` метод
- [ ] Переопределить `can_use()` если нужно
- [ ] Расширить `get_tooltip()` с доп. информацией
- [ ] Установить `item_type` в `_init()`
- [ ] Настроить `is_stackable` и `max_stack`
- [ ] Добавить документацию

---

## 🚀 Следующие шаги

1. **InventoryComponent** - система хранения предметов
2. **EquipmentManager** - управление экипировкой
3. **Crafting System** - крафтинг из материалов
4. **Loot System** - генерация добычи
5. **Save/Load** - сохранение инвентаря

---

## 📚 Связанная документация

- [Godot OOP Guide](../Docs/godot_oop_guide.md) - Подробное руководство по ООП в Godot
- [Combat System](../CombatComponents/README.md) - Интеграция оружия
- [Dialog System](../DialogoeSystem/README.md) - Покупка предметов у NPC

---

**Последнее обновление:** 2025-11-26
**Версия:** 1.0
**Совместимость:** Godot 4.5+
