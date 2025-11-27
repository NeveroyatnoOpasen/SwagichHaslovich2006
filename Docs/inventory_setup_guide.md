# Inventory System Setup Guide

Руководство по настройке системы инвентаря и экипировки в Godot 4.5

---

## 1. Добавление WeaponHolder к Player

### Структура сцены Player (player.tscn)

Открой сцену `entity/player/player.tscn` в Godot Editor и создай следующую структуру:

```
Player (CharacterBody3D) [корень]
├── Pivot (Node3D)
│   └── Camera3D
│       └── WeaponHolder (Node3D) ← ДОБАВЬ ЭТОТ УЗЕЛ
├── CombatComponent (Node)
├── InventoryComponent (Node) ← ДОБАВЬ ЭТОТ УЗЕЛ
├── health_component (HealthComponent)
├── MeleeWeaponComponent (Node3D)
└── ... другие компоненты
```

### Пошаговая инструкция:

#### Шаг 1: Добавить WeaponHolder

1. Открой `entity/player/player.tscn`
2. Выбери узел `Pivot/Camera3D` в дереве сцены
3. Нажми **правой кнопкой мыши** → **Add Child Node**
4. Найди и выбери **Node3D**
5. Назови его **WeaponHolder**
6. Сохрани сцену (Ctrl+S)

**Назначение:** В этот узел будут спавниться 3D модели оружия при экипировке.

#### Шаг 2: Добавить InventoryComponent

1. Выбери корневой узел **Player**
2. Нажми **правой кнопкой мыши** → **Add Child Node**
3. Найди и выбери **Node** (обычный Node, не Node3D)
4. Назови его **InventoryComponent**
5. В Inspector → **Attach Script** → выбери `components/InventorySystem/inventory_component.gd`
6. В Inspector → найди параметр **Inventory** (Array[InventoryItem])
7. Нажми на стрелку справа → **Resize Array** → установи размер **20** (20 слотов)
8. Сохрани сцену (Ctrl+S)

#### Шаг 3: Проверка ссылок в player.gd

Убедись, что в `player.gd` есть следующие строки (уже добавлены):

```gdscript
@onready var weapon_holder: Node3D = $Pivot/Camera3D/WeaponHolder
@onready var inventory: InventoryComponent = $InventoryComponent
```

Если узлы названы по-другому, измени пути соответственно.

---

## 2. Тестирование системы

### Запуск игры:

1. Нажми **F5** для запуска игры
2. В консоли (Output) должны появиться сообщения:

```
=== INVENTORY DEBUG ===
Current slot: 0
Total slots: 20
  [0] Test Iron Sword
  [1] Cigarettes
  [2] Wooden Club
Filled: 3 / 20
Empty slots: 17

Auto-equipping first item...
Equipped weapon model: Test Iron Sword
Equipped from slot 0: Test Iron Sword
```

### Проверка функционала:

**Клавиши 1-9:** Переключение между слотами и экипировка
- Нажми **1** → Экипирует меч из слота 0
- Нажми **2** → Переключится на сигареты (но не экипирует, т.к. расходник)
- Нажми **3** → Экипирует дубинку из слота 2

**Клавиша Enter:** Использовать расходник
- Переключись на слот 2 (нажми **2**)
- Нажми **Enter** → Используешь сигарету, она удалится из инвентаря

**Консольные сообщения:**
- При экипировке: `Equipped weapon: ...`
- При переключении на расходник: `Switched to slot X: Cigarettes (not equippable)`
- При использовании: `Used consumable: Cigarettes`

---

## 3. Создание 3D модели оружия

### Пример: простой меч для тестирования

#### Создать сцену оружия:

1. **Scene → New Scene**
2. Выбери **Node3D** как корневой узел
3. Назови его **IronSwordModel**
4. Добавь дочерний узел **MeshInstance3D**
5. В Inspector у MeshInstance3D:
   - **Mesh** → **New BoxMesh** (временная замена)
   - Transform → Scale → установи `(0.1, 1.0, 0.02)` для формы меча
   - Transform → Position → сдвинь меч вперёд: `(0, 0, -0.5)`
6. Сохрани сцену как `models/weapons/iron_sword.tscn`

#### Создать ресурс WeaponItem:

1. В FileSystem → правой кнопкой мыши → **Create New → Resource**
2. Найди и выбери **WeaponItem**
3. Сохрани как `items/weapons/iron_sword.tres`
4. В Inspector настрой параметры:
   - **Item Name:** "Iron Sword"
   - **Item Id:** "iron_sword"
   - **Description:** "A sturdy iron blade"
   - **Light Damage:** 30.0
   - **Heavy Damage:** 60.0
   - **Weapon Scene:** Load → выбери `models/weapons/iron_sword.tscn`
5. Сохрани ресурс (Ctrl+S)

#### Использовать ресурс в коде:

```gdscript
# В player.gd, метод _add_test_items()
func _add_test_items() -> void:
    # Загружаем ресурс
    var iron_sword = load("res://items/weapons/iron_sword.tres") as WeaponItem
    inventory.add_item(iron_sword)

    # Или создаём программно и загружаем только сцену
    var sword = WeaponItem.new()
    sword.item_name = "Test Sword"
    sword.weapon_scene = load("res://models/weapons/iron_sword.tscn")
    inventory.add_item(sword)
```

---

## 4. Создание Pickup предметов в мире

### Создать скрипт Pickable

**Файл: `miscelanius/scripts/pickable_item.gd`**

```gdscript
extends Interactable
class_name PickableItem

@export var item_resource: InventoryItem  # Ссылка на .tres ресурс
@export var auto_rotate: bool = true
@export var rotation_speed: float = 1.0

func _ready():
    if item_resource:
        prompt_message = "Pick up %s" % item_resource.item_name
    else:
        prompt_message = "Pick up item"

func _process(delta):
    if auto_rotate:
        rotate_y(rotation_speed * delta)

func use():
    var player = get_tree().get_first_node_in_group("Player")
    if not player or not player.inventory:
        return

    # Добавляем КОПИЮ ресурса в инвентарь
    var item_copy = item_resource.duplicate()
    if player.inventory.add_item(item_copy):
        print("Picked up: %s" % item_resource.item_name)
        queue_free()  # Удаляем pickup из мира
    else:
        print("Inventory full!")
```

### Создать сцену Pickup

**Файл: `prefabs/pickups/iron_sword_pickup.tscn`**

```
IronSwordPickup (StaticBody3D) [корень]
├── Script: pickable_item.gd
├── CollisionShape3D (SphereShape3D radius=0.5)
└── MeshInstance3D (BoxMesh для визуала)
```

**Inspector настройки:**
- **Script:** `pickable_item.gd`
- **Item Resource:** Load → `items/weapons/iron_sword.tres`
- **Auto Rotate:** true

Теперь можешь разместить эту сцену в уровне, и игрок сможет подбирать меч через `interact_ray`.

---

## 5. Структура папок проекта

Рекомендуемая организация:

```
project/
├── items/                      # Ресурсы предметов (.tres)
│   ├── weapons/
│   │   ├── iron_sword.tres
│   │   └── wooden_club.tres
│   └── consumables/
│       ├── health_potion.tres
│       └── cigarettes.tres
│
├── models/                     # 3D модели и сцены
│   ├── weapons/
│   │   ├── iron_sword.tscn    # Модель для руки
│   │   └── club.tscn
│   └── pickups/                # Модели для мира (опционально)
│
├── prefabs/                    # Готовые prefab сцены
│   └── pickups/
│       ├── iron_sword_pickup.tscn
│       └── health_potion_pickup.tscn
│
├── components/
│   └── InventorySystem/
│       ├── inventory_component.gd
│       ├── inventory_item.gd
│       ├── weapon_item.gd
│       ├── consumable_item.gd
│       └── ...
│
└── entity/
    └── player/
        ├── player.tscn
        └── player.gd
```

---

## 6. Hotkeys и управление

### Уже работают (встроенные UI actions):

| Клавиша | Действие |
|---------|----------|
| **1-9** | Переключение слотов инвентаря / экипировка |
| **Enter** | Использовать расходник из текущего слота |
| **E** | Подобрать предмет (interact_ray) |
| **ЛКМ** | Лёгкая атака |
| **ПКМ** | Тяжёлая атака |

### Создать кастомные Input Actions (опционально):

Если хочешь добавить свои клавиши вместо `ui_1-9`:

**Project → Project Settings → Input Map:**

1. Создай действие `slot_1` → добавь клавишу **1**
2. Создай действие `slot_2` → добавь клавишу **2**
3. ... и так до `slot_9`
4. Создай действие `use_item` → добавь клавишу **Enter** или **F**

Затем в `player.gd` замени `ui_1` на `slot_1` и т.д.

---

## 7. Отладка и troubleshooting

### Проблема: "Player doesn't have WeaponHolder"

**Решение:**
- Проверь структуру сцены Player
- Убедись, что WeaponHolder находится по пути `Pivot/Camera3D/WeaponHolder`
- Проверь, что узел называется точно **WeaponHolder** (регистр важен)

### Проблема: "Player doesn't have InventoryComponent"

**Решение:**
- Добавь InventoryComponent как дочерний узел Player
- Прикрепи скрипт `inventory_component.gd`
- Установи размер массива `inventory` в Inspector

### Проблема: Оружие не появляется в руке

**Решение:**
- Убедись, что у WeaponItem установлен `weapon_scene` или `weapon_mesh`
- Проверь, что сцена оружия существует по указанному пути
- Посмотри консоль на ошибки загрузки

### Проблема: Инвентарь пустой при запуске

**Решение:**
- Убедись, что `_add_test_items()` вызывается в `_ready()`
- Проверь размер массива inventory в Inspector (должен быть > 0)
- Посмотри консоль на сообщения debug_info()

---

## 8. Следующие шаги

После базовой настройки можешь добавить:

1. **UI инвентаря** - визуальное отображение слотов
2. **Hotbar** - показывает текущие 9 слотов внизу экрана
3. **Pickup системы** - предметы лежат в мире
4. **Система стакания** - складывать одинаковые предметы
5. **Сохранение инвентаря** - save/load система

---

**Версия:** 1.0
**Дата:** 2025-11-28
**Совместимость:** Godot 4.5+
