# Примеры наследования в Godot / Inheritance Examples

## 🎯 Основные правила

### ❌ ТАК НЕЛЬЗЯ (не работает в GDScript):

```gdscript
extends InventoryItem

# ❌ ОШИБКА: Нельзя объявлять переменные так на верхнем уровне
item_id: String = "my_item"
item_name: String = "My Item"
```

### ✅ ТАК ПРАВИЛЬНО:

```gdscript
extends InventoryItem
class_name MyItem  # Опционально, но рекомендуется

# Конструктор
func _init():
	# Вызываем родительский конструктор
	super._init()

	# ЗДЕСЬ устанавливаем переменные
	item_id = "my_item"
	item_name = "My Item"
```

---

## 📝 Шаблон 1: Простое наследование

```gdscript
extends ConsumableItem
class_name HealthPotion

func _init():
	super._init()  # Всегда вызывай родительский _init()!

	# Устанавливай все свойства здесь
	item_id = "health_potion"
	item_name = "Health Potion"
	description = "Restores 50 HP"

	# Свойства расходника
	consumable_type = ConsumableType.HEALTH_POTION
	heal_amount = 50.0

	# Характеристики
	value = 25
	is_stackable = true
	max_stack = 99
```

---

## 📝 Шаблон 2: Переопределение методов

```gdscript
extends WeaponItem
class_name MagicSword

func _init():
	super._init()

	item_id = "magic_sword"
	item_name = "Magic Sword"
	light_damage = 30.0
	heavy_damage = 60.0

# Переопределяем use() с дополнительной логикой
func use(user: Node) -> bool:
	# Сначала вызываем родительскую версию
	var result = super.use(user)

	if result:
		# Добавляем свою логику
		print("⚡ The sword crackles with magic!")
		# Можно добавить визуальные эффекты, звуки и т.д.

	return result

# Переопределяем tooltip
func get_tooltip() -> String:
	var tooltip = super.get_tooltip()  # Берём родительский tooltip
	tooltip += "\n[color=cyan]✨ Magical Weapon[/color]"
	return tooltip
```

---

## 📝 Шаблон 3: Добавление новых свойств

```gdscript
extends ConsumableItem
class_name PoisonPotion

# Новое свойство, которого нет в родителе
var damage_over_time: float = 10.0
var poison_duration: float = 5.0

func _init():
	super._init()

	item_id = "poison_potion"
	item_name = "Poison Potion"
	consumable_type = ConsumableType.POISON

	# Устанавливаем наши новые свойства
	damage_over_time = 10.0
	poison_duration = 5.0

func use(user: Node) -> bool:
	print("Applied poison: %d damage over %d seconds" % [damage_over_time, poison_duration])

	# Здесь можно добавить логику яда
	# Например, создать Timer и применять урон каждую секунду

	return true
```

---

## 📝 Шаблон 4: Статические свойства (константы)

```gdscript
extends WeaponItem
class_name Excalibur

# Константы можно объявлять на верхнем уровне
const LEGENDARY_DAMAGE_BONUS: float = 50.0
const WEAPON_ID: String = "excalibur"

func _init():
	super._init()

	item_id = WEAPON_ID
	item_name = "Excalibur"
	description = "The legendary sword of King Arthur"

	light_damage = 50.0 + LEGENDARY_DAMAGE_BONUS
	heavy_damage = 100.0 + LEGENDARY_DAMAGE_BONUS
	value = 9999

	is_stackable = false  # Легендарное оружие не складывается
```

---

## 🔍 Проверка типов

```gdscript
# Проверить, является ли объект определённым типом
var item = Cigarettes.new()

if item is ConsumableItem:
	print("This is consumable!")

if item is InventoryItem:
	print("This is an inventory item!")  # Тоже true!

if item is WeaponItem:
	print("This is weapon!")  # False

# Приведение типа (casting)
var consumable = item as ConsumableItem
if consumable:
	print("Heal amount: ", consumable.heal_amount)
```

---

## 🎓 Продвинутые примеры

### Пример: Зелье с cooldown

```gdscript
extends ConsumableItem
class_name CooldownPotion

var cooldown_time: float = 30.0
var last_use_time: float = -999.0

func _init():
	super._init()

	item_id = "cooldown_potion"
	item_name = "Cooldown Potion"
	heal_amount = 100.0

func can_use() -> bool:
	# Проверяем родительское условие
	if not super.can_use():
		return false

	# Добавляем свою проверку
	var current_time = Time.get_ticks_msec() / 1000.0
	return (current_time - last_use_time) >= cooldown_time

func use(user: Node) -> bool:
	if not can_use():
		print("Potion on cooldown!")
		return false

	var result = super.use(user)

	if result:
		last_use_time = Time.get_ticks_msec() / 1000.0
		print("Potion used! Cooldown: %ds" % cooldown_time)

	return result
```

### Пример: Оружие с прочностью

```gdscript
extends WeaponItem
class_name DurableWeapon

var durability: float = 100.0
var max_durability: float = 100.0
var durability_loss_per_hit: float = 1.0

func _init():
	super._init()

	item_id = "iron_sword"
	item_name = "Iron Sword"
	light_damage = 25.0

	durability = 100.0
	max_durability = 100.0

func apply_to_weapon_component(weapon_component: MeleeWeaponComponent):
	# Вызываем родительский метод
	super.apply_to_weapon_component(weapon_component)

	# Подключаемся к сигналу попадания
	if not weapon_component.hit_landed.is_connected(_on_hit_landed):
		weapon_component.hit_landed.connect(_on_hit_landed)

func _on_hit_landed(_target):
	# Уменьшаем прочность при каждом ударе
	durability -= durability_loss_per_hit

	if durability <= 0:
		print("⚠ %s broke!" % item_name)
		# Можно удалить оружие из инвентаря
	elif durability < max_durability * 0.25:
		print("⚠ %s is almost broken!" % item_name)

func get_tooltip() -> String:
	var tooltip = super.get_tooltip()
	tooltip += "\nDurability: %.0f/%.0f" % [durability, max_durability]
	return tooltip
```

---

## �� Частые ошибки

### Ошибка 1: Забыл вызвать super._init()

```gdscript
extends ConsumableItem

func _init():
	# ❌ ОШИБКА: Забыл super._init()!
	item_id = "my_item"
	# Родительские значения не установлены!
	# is_stackable, max_stack, item_type будут неправильными
```

**Правильно:**
```gdscript
func _init():
	super._init()  # ✅ Всегда первая строка!
	item_id = "my_item"
```

### Ошибка 2: Объявление переменных не в _init()

```gdscript
extends InventoryItem

# ❌ ОШИБКА: Так не работает в GDScript для наследования
item_id = "test"
```

**Правильно:**
```gdscript
extends InventoryItem

func _init():
	super._init()
	item_id = "test"  # ✅
```

### Ошибка 3: Неправильное переопределение use()

```gdscript
extends ConsumableItem

func use(user: Node) -> bool:
	# ❌ Забыли вызвать super.use()!
	print("Using item")
	return true
	# Родительская логика (лечение) не выполнится!
```

**Правильно:**
```gdscript
func use(user: Node) -> bool:
	var result = super.use(user)  # ✅ Сначала родитель

	if result:
		print("Using item")  # Потом своя логика

	return result
```

---

## 📚 Когда наследоваться от какого класса

```
InventoryItem (базовый)
    ↓
    ├─→ WeaponItem - для оружия
    │
    ├─→ ConsumableItem - для:
    │       ✅ Зелья
    │       ✅ Еда
    │       ✅ Баффы
    │       ✅ Сигареты, наркотики
    │       ✅ Scroll'ы с эффектами
    │
    ├─→ QuestItem - для:
    │       ✅ Ключи
    │       ✅ Документы
    │       ✅ Квестовые артефакты
    │
    └─→ MaterialItem - для:
            ✅ Руда
            ✅ Дерево
            ✅ Компоненты
```

---

## 💡 Лучшие практики

### 1. Всегда вызывай super._init()

```gdscript
func _init():
	super._init()  # 👍 Первая строка!
```

### 2. Используй class_name для переиспользования

```gdscript
extends ConsumableItem
class_name HealthPotion  # 👍 Теперь можно везде использовать

# Где-то в коде:
var potion = HealthPotion.new()
```

### 3. Переопределяй get_tooltip() для info

```gdscript
func get_tooltip() -> String:
	var tooltip = super.get_tooltip()  # Базовая инфа
	tooltip += "\nSpecial: +10% damage"  # Своя инфа
	return tooltip
```

### 4. Документируй класс

```gdscript
extends ConsumableItem
class_name ManaPotion

## Зелье маны - восстанавливает магическую энергию
## Используется кастерами для восстановления MP

func _init():
	super._init()
	# ...
```

---

## 🎮 Как использовать созданные классы

```gdscript
# Создать программно
var cigs = Cigarettes.new()
cigs.use(player)

# Или создать как ресурс в редакторе
# 1. Create New → Resource → Cigarettes
# 2. Save as cigarettes.tres
# 3. Load:
var cigs = load("res://items/cigarettes.tres") as Cigarettes
```

---

Теперь ты знаешь как правильно наследоваться! 🎓