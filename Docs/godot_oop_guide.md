# Object-Oriented Programming in Godot / ООП в Godot

## Полное руководство по ООП в GDScript

### 📚 Содержание
1. [Основы классов](#основы-классов)
2. [Наследование](#наследование)
3. [Resource vs Node](#resource-vs-node)
4. [Виртуальные методы](#виртуальные-методы)
5. [Композиция vs Наследование](#композиция-vs-наследование)
6. [Практические примеры](#практические-примеры)

---

## Основы классов

### Создание класса

В Godot есть два способа создать класс:

#### 1. Неявный класс (любой .gd файл)
```gdscript
# my_script.gd
extends Node

var health: int = 100

func take_damage(amount: int):
	health -= amount
```

#### 2. Явный класс с `class_name`
```gdscript
# player_data.gd
extends Resource
class_name PlayerData  # Теперь можно использовать везде как тип

var player_name: String = ""
var level: int = 1
```

**Разница:**
- Без `class_name` - класс доступен только через `preload()` или `load()`
- С `class_name` - класс доступен глобально по имени, виден в редакторе

---

## Наследование

### Базовый синтаксис

```gdscript
# Родительский класс
extends Resource
class_name Item

var item_name: String = "Item"
var weight: float = 1.0

func use():
	print("Using: ", item_name)

# Дочерний класс
extends Item
class_name Weapon

var damage: float = 10.0

# Переопределяем метод родителя
func use():
	super.use()  # Вызываем родительский метод
	print("Damage: ", damage)
```

### Ключевое слово `super`

`super` - ссылка на родительский класс:

```gdscript
extends Item
class_name Potion

func use():
	# Вызываем родительскую версию метода
	super.use()

	# Добавляем свою логику
	print("Healing player...")
```

**Важно:** В Godot 4.x используется `super`, в Godot 3.x было `.метод()`

---

## Resource vs Node

### Когда использовать Resource

**Resource** - это данные, которые можно сохранять в файлы (.tres, .res):

```gdscript
extends Resource
class_name InventoryItem

@export var item_name: String = ""
@export var icon: Texture2D
@export var value: int = 0
```

**Преимущества Resource:**
- ✅ Можно сохранять на диск
- ✅ Легковесные (нет overhead от Node)
- ✅ Можно создавать через Inspector как ресурсы
- ✅ Ideal для данных (предметы, настройки, статы)

**Пример создания:**
```gdscript
# В коде:
var sword = WeaponItem.new()
sword.item_name = "Iron Sword"
sword.damage = 25.0

# Или через Inspector:
# 1. Create New → Resource → WeaponItem
# 2. Настройте параметры
# 3. Сохраните как .tres файл
```

### Когда использовать Node

**Node** - это объекты в сцене, у которых есть lifecycle (_ready, _process):

```gdscript
extends Node
class_name HealthComponent

signal health_changed(current, max)

var health: float = 100.0

func _ready():
	print("HealthComponent ready!")

func take_damage(amount: float):
	health -= amount
	health_changed.emit(health, 100.0)
```

**Используй Node когда:**
- ✅ Нужен lifecycle (_ready, _process, _input)
- ✅ Нужна иерархия (parent/child)
- ✅ Нужны сигналы
- ✅ Это компонент игрового объекта

---

## Иерархия классов в проекте

### Наша система инвентаря

```
Resource (встроенный класс Godot)
	↓
InventoryItem (базовый класс)
	├─→ WeaponItem (оружие)
	├─→ ConsumableItem (расходники)
	├─→ QuestItem (квестовые предметы)
	└─→ MaterialItem (материалы)
```

**Визуализация:**

```gdscript
# Базовый класс
class InventoryItem extends Resource:
	var item_name: String
	var weight: float

	func use(user):
		# Базовая реализация
		pass

# Специализированный класс
class WeaponItem extends InventoryItem:
	var damage: float

	# Переопределяем use()
	func use(user):
		user.equip_weapon(self)
```

---

## Виртуальные методы

В Godot нет явного ключевого слова `virtual`, но концепция есть:

### Паттерн виртуальных методов

```gdscript
# Базовый класс
extends Resource
class_name Animal

func make_sound():
	push_warning("Animal.make_sound() not implemented")

# Наследники
extends Animal
class_name Dog

func make_sound():
	print("Woof!")

extends Animal
class_name Cat

func make_sound():
	print("Meow!")
```

### Использование

```gdscript
var animals: Array[Animal] = [
	Dog.new(),
	Cat.new()
]

for animal in animals:
	animal.make_sound()  # Полиморфизм!
```

---

## Встроенные виртуальные методы Godot

Godot предоставляет множество встроенных виртуальных методов:

### Для Node:
```gdscript
func _ready():  # Вызывается при добавлении в сцену
	pass

func _process(delta: float):  # Каждый кадр
	pass

func _physics_process(delta: float):  # Каждый физический кадр
	pass

func _input(event: InputEvent):  # При вводе
	pass

func _enter_tree():  # При входе в дерево сцены
	pass

func _exit_tree():  # При выходе из дерева
	pass
```

### Для Resource:
```gdscript
func _init():  # Конструктор
	pass
```

---

## Композиция vs Наследование

### Наследование (IS-A relationship)

"Меч **является** оружием"

```gdscript
extends WeaponItem
class_name Sword

var blade_length: float = 1.0
```

**Используй когда:**
- Чёткая иерархия типов
- Общая функциональность
- Полиморфизм нужен

### Композиция (HAS-A relationship)

"Игрок **имеет** компонент здоровья"

```gdscript
extends CharacterBody3D
class_name Player

@onready var health_component: HealthComponent = $HealthComponent
@onready var combat_component: CombatComponent = $CombatComponent
```

**Используй когда:**
- Модульная функциональность
- Переиспользуемые компоненты
- Гибкость важнее иерархии

### Наш проект использует оба подхода:

**Наследование для данных:**
```
InventoryItem → WeaponItem → Sword
```

**Композиция для геймплея:**
```
Player:
  - HealthComponent
  - CombatComponent
  - InventoryComponent
```

---

## Практические примеры

### Пример 1: Создание предмета в коде

```gdscript
# Создаём меч программно
var iron_sword = WeaponItem.new()
iron_sword.item_id = "iron_sword"
iron_sword.item_name = "Iron Sword"
iron_sword.description = "A sturdy iron blade"
iron_sword.value = 100
iron_sword.light_damage = 25.0
iron_sword.heavy_damage = 50.0

# Используем
iron_sword.use(player)  # Экипирует оружие
```

### Пример 2: Создание предмета как ресурс

**1. В Godot Editor:**
- Create New → Resource → WeaponItem
- Заполните параметры в Inspector
- Save As → `res://items/weapons/iron_sword.tres`

**2. Загрузка в коде:**
```gdscript
# Загружаем готовый ресурс
var sword = load("res://items/weapons/iron_sword.tres") as WeaponItem

# Или preload для компиляции
const IRON_SWORD = preload("res://items/weapons/iron_sword.tres")
```

### Пример 3: Полиморфизм

```gdscript
# Инвентарь хранит базовый тип
var inventory: Array[InventoryItem] = []

# Добавляем разные типы
inventory.append(WeaponItem.new())
inventory.append(ConsumableItem.new())
inventory.append(QuestItem.new())

# Используем полиморфно
for item in inventory:
	# use() вызовет правильную версию для каждого типа!
	if item.can_use():
		item.use(player)
```

### Пример 4: Проверка типа

```gdscript
func handle_item(item: InventoryItem):
	if item is WeaponItem:
		print("This is a weapon with damage: ", item.damage)
	elif item is ConsumableItem:
		print("This consumable heals: ", item.heal_amount)
	elif item is QuestItem:
		print("Quest item for: ", item.quest_id)
```

---

## Паттерны проектирования в Godot

### 1. Factory Pattern (Фабрика)

```gdscript
class_name ItemFactory

static func create_item(item_id: String) -> InventoryItem:
	match item_id:
		"iron_sword":
			var sword = WeaponItem.new()
			sword.item_name = "Iron Sword"
			sword.light_damage = 25.0
			return sword

		"health_potion":
			var potion = ConsumableItem.new()
			potion.item_name = "Health Potion"
			potion.heal_amount = 50.0
			return potion

		_:
			push_error("Unknown item: " + item_id)
			return null
```

### 2. Component Pattern (используется в проекте)

```gdscript
# Player не наследует функциональность, а композирует компоненты
extends CharacterBody3D
class_name Player

@onready var health := $HealthComponent
@onready var combat := $CombatComponent
@onready var inventory := $InventoryComponent

func _ready():
	# Компоненты независимы и переиспользуемы
	health.health_depleted.connect(_on_death)
	combat.attack_performed.connect(_on_attack)
```

### 3. Observer Pattern (через сигналы)

```gdscript
# Компонент испускает сигнал
class_name HealthComponent extends Node

signal health_changed(current, max)
signal health_depleted

func take_damage(amount: float):
	health -= amount
	health_changed.emit(health, max_health)

	if health <= 0:
		health_depleted.emit()

# Наблюдатель подписывается
func _ready():
	health_component.health_changed.connect(_update_health_bar)
	health_component.health_depleted.connect(_on_death)
```

---

## Инкапсуляция в GDScript

### Приватные переменные (соглашение)

GDScript не имеет настоящих приватных переменных, но есть соглашение:

```gdscript
class_name Item

# Публичная (любой может использовать)
var item_name: String = ""

# "Приватная" (префикс _)
var _internal_id: int = 0

# Используй getter/setter для контроля доступа
var _health: float = 100.0

var health: float:
	get:
		return _health
	set(value):
		_health = clamp(value, 0, max_health)
		health_changed.emit(_health)
```

### @export для Inspector

```gdscript
# Базовый export
@export var speed: float = 5.0

# С диапазоном
@export_range(0, 100) var health: int = 100

# С подсказкой типа
@export var weapon: WeaponItem

# Группировка в Inspector
@export_group("Combat")
@export var attack_damage: float = 10.0
@export var attack_speed: float = 1.0

@export_group("Movement")
@export var walk_speed: float = 5.0
@export var run_speed: float = 10.0
```

---

## Абстрактные классы (паттерн)

GDScript не имеет формальных абстрактных классов, но можно имитировать:

```gdscript
# "Абстрактный" класс
extends Resource
class_name AbstractEnemy

func attack():
	assert(false, "attack() must be implemented in child class")

func take_damage(amount: float):
	assert(false, "take_damage() must be implemented")

# Конкретная реализация
extends AbstractEnemy
class_name Goblin

func attack():
	print("Goblin attacks!")

func take_damage(amount: float):
	print("Goblin takes ", amount, " damage")
```

---

## Статические методы и переменные

```gdscript
class_name MathUtils

# Статические константы
const PI = 3.14159
const MAX_LEVEL = 100

# Статический метод
static func lerp_smooth(from: float, to: float, weight: float) -> float:
	return from + (to - from) * weight

# Использование
var result = MathUtils.lerp_smooth(0, 100, 0.5)
print(MathUtils.MAX_LEVEL)
```

---

## Duck Typing vs Строгая типизация

### Duck Typing (если выглядит как утка...)

```gdscript
func heal(target):  # Любой объект с методом heal()
	if target.has_method("heal"):
		target.heal(50)
```

### Строгая типизация (рекомендуется)

```gdscript
func heal(target: CharacterBody3D):
	var health = target.get_node_or_null("HealthComponent")
	if health:
		health.heal(50)
```

**В нашем проекте используем строгую типизацию где возможно!**

---

## Лучшие практики

### ✅ DO (Делай так)

```gdscript
# 1. Используй class_name для переиспользуемых классов
extends Resource
class_name InventoryItem

# 2. Строгая типизация
var items: Array[InventoryItem] = []

# 3. Виртуальные методы с предупреждениями
func use(user: Node) -> bool:
	push_warning("Override use() in child class")
	return false

# 4. Вызывай super где нужно
func get_tooltip() -> String:
	var tooltip = super.get_tooltip()
	tooltip += "Additional info"
	return tooltip

# 5. Документация с ##
## Базовый класс для всех предметов инвентаря
class_name Item
```

### ❌ DON'T (Не делай так)

```gdscript
# 1. Не злоупотребляй наследованием
extends Player
class_name Warrior extends Mage extends Thief  # Плохо!

# 2. Не создавай глубокие иерархии
Item → Weapon → MeleeWeapon → Sword → LongSword → ... # Слишком глубоко!

# 3. Не дублируй код - используй композицию
extends Node
var health = 100  # Плохо
func take_damage(): ...

# Лучше:
@onready var health_component = $HealthComponent
```

---

## Диаграмма нашей системы инвентаря

```
Resource (Godot built-in)
    ↓
InventoryItem
│   ├─ item_id: String
│   ├─ item_name: String
│   ├─ weight: float
│   └─ use(user) -> bool  [VIRTUAL]
    ↓
    ├──→ WeaponItem
    │     ├─ damage: float
    │     ├─ apply_to_weapon_component()
    │     └─ use() → equip weapon
    │
    ├──→ ConsumableItem
    │     ├─ heal_amount: float
    │     ├─ buff_duration: float
    │     └─ use() → heal player
    │
    ├──→ QuestItem
    │     ├─ quest_id: String
    │     ├─ is_key_item: bool
    │     └─ use() → trigger quest event
    │
    └──→ MaterialItem
          ├─ rarity: int
          ├─ category: Enum
          └─ use() → cannot use (crafting only)
```

---

## Итоговый чеклист ООП

- [x] **Наследование** - `extends` для IS-A отношений
- [x] **Инкапсуляция** - `_private` соглашение, getters/setters
- [x] **Полиморфизм** - виртуальные методы, `super`
- [x] **Абстракция** - базовые классы с assert
- [x] **Композиция** - компоненты вместо глубокого наследования
- [x] **Resource** - для данных (items, configs)
- [x] **Node** - для логики (components, controllers)
- [x] **class_name** - для глобального доступа
- [x] **Сигналы** - для Observer pattern
- [x] **Строгая типизация** - для безопасности

---

## Дополнительные ресурсы

- [Godot GDScript Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)
- [OOP Concepts](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#inheritance)
- Наш проект: примеры в `components/` и `entity/`
