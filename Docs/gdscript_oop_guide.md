# ООП в GDScript - Полное руководство

Объектно-ориентированное программирование (ООП) в Godot с GDScript - это мощный инструмент для создания модульной и переиспользуемой архитектуры.

## Содержание
1. [Основы ООП](#основы-ооп)
2. [Наследование (extends)](#наследование-extends)
3. [super - Вызов родительских методов](#super---вызов-родительских-методов)
4. [class_name - Глобальные классы](#class_name---глобальные-классы)
5. [Виртуальные методы](#виртуальные-методы)
6. [Композиция vs Наследование](#композиция-vs-наследование)
7. [Примеры из проекта](#примеры-из-проекта)
8. [Лучшие практики](#лучшие-практики)

---

## Основы ООП

### Три столпа ООП в GDScript:

1. **Инкапсуляция** - Объединение данных и методов в одном классе
2. **Наследование** - Создание новых классов на основе существующих
3. **Полиморфизм** - Один интерфейс для разных реализаций

### Базовая структура класса:

```gdscript
extends Node
class_name MyClass

# Переменные (свойства)
var health: int = 100
@export var max_health: int = 100

# Метод (функция класса)
func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	print("Died!")
	queue_free()
```

---

## Наследование (extends)

Наследование позволяет создавать новые классы на основе существующих, наследуя их свойства и методы.

### Синтаксис:

```gdscript
extends ParentClass
```

### Встроенные типы Godot:

```gdscript
extends Node          # Базовый узел
extends Node3D        # 3D узел с transform
extends CharacterBody3D  # Персонаж с физикой
extends Area3D        # Область обнаружения
extends Control       # UI элемент
```

### Пример из нашего проекта:

```gdscript
# base_ability.gd - базовый класс для всех способностей
extends Node
class_name BaseAbility

var is_on_cooldown: bool = false
var cooldown: float = 1.0

func activate(owner: CharacterBody3D) -> bool:
	if is_on_cooldown:
		return false

	is_on_cooldown = true
	return true
```

```gdscript
# dash_ability.gd - наследуется от BaseAbility
extends BaseAbility
class_name DashAbility

var dash_speed: float = 20.0

func activate(owner: CharacterBody3D) -> bool:
	# DashAbility теперь имеет доступ к:
	# - is_on_cooldown (из BaseAbility)
	# - cooldown (из BaseAbility)
	# - activate() (переопределяем)
	# - dash_speed (собственное свойство)

	if not super.activate(owner):  # Вызываем родительский метод
		return false

	# Своя логика рывка
	owner.velocity = Vector3.FORWARD * dash_speed
	return true
```

### Цепочка наследования:

```
Node (встроенный класс Godot)
  ↓
BaseAbility (наш базовый класс)
  ↓
DashAbility (конкретная реализация)
```

---

## super - Вызов родительских методов

`super` - это ключевое слово для вызова методов родительского класса.

### Зачем нужен super?

Когда вы переопределяете метод в дочернем классе, вы **замещаете** родительский метод. Чтобы выполнить логику родителя И добавить свою, используйте `super`.

### Синтаксис:

```gdscript
super.method_name(arguments)
super()  # Вызов конструктора родителя (для _init)
```

### Примеры:

#### 1. _ready() - Инициализация

```gdscript
# BaseAbility
func _ready() -> void:
	set_process(false)  # Отключаем _process по умолчанию
	print("BaseAbility готов")

# DashAbility
func _ready() -> void:
	super._ready()  # ← Сначала вызываем родительский _ready()
	                # Это выполнит set_process(false)

	# Затем наша инициализация
	ability_name = "Dash"
	cooldown = 3.0
	print("DashAbility готов")

# Вывод:
# "BaseAbility готов"
# "DashAbility готов"
```

#### 2. activate() - Переопределение с расширением

```gdscript
# BaseAbility
func activate(owner: CharacterBody3D) -> bool:
	if is_on_cooldown:
		return false

	is_on_cooldown = true
	ability_used.emit(ability_name)
	return true

# FireballAbility
func activate(owner: CharacterBody3D) -> bool:
	# Сначала проверяем, можно ли использовать способность
	if not super.activate(owner):  # ← Вызываем родительский метод
		return false  # Если кулдаун активен - выходим

	# Родительский метод вернул true - можем использовать
	_spawn_fireball()
	return true
```

#### 3. _process() - Добавление логики

```gdscript
# BaseAbility
func _process(delta: float) -> void:
	# Обработка кулдауна
	if is_on_cooldown:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			is_on_cooldown = false

# DashAbility
func _process(delta: float) -> void:
	super._process(delta)  # ← Обрабатываем кулдаун

	# Добавляем свою логику
	if is_dashing:
		dash_time_remaining -= delta
		if dash_time_remaining <= 0:
			is_dashing = false
```

### Что происходит БЕЗ super?

```gdscript
# ❌ ПЛОХО - без super._ready()
func _ready() -> void:
	# set_process(false) НЕ вызовется!
	# Способность будет обрабатываться каждый кадр - плохо для производительности
	ability_name = "Dash"
	cooldown = 3.0

# ✅ ХОРОШО - с super._ready()
func _ready() -> void:
	super._ready()  # Выполнится set_process(false)
	ability_name = "Dash"
	cooldown = 3.0
```

---

## class_name - Глобальные классы

`class_name` делает класс доступным глобально во всём проекте.

### Синтаксис:

```gdscript
extends Node
class_name MyClassName
```

### Преимущества:

1. **Доступность везде** - не нужно load() или preload()
2. **Типизация** - можно использовать как тип переменной
3. **Автодополнение** - Godot показывает методы и свойства
4. **Проверка типов** - `if ability is DashAbility:`

### Примеры:

```gdscript
# base_ability.gd
extends Node
class_name BaseAbility  # ← Регистрируем глобально

# Теперь можно использовать везде:

# 1. Типизация переменных
var my_ability: BaseAbility

# 2. Проверка типов
if ability is BaseAbility:
	print("Это способность!")

# 3. Создание экземпляров
var dash = DashAbility.new()

# 4. Массивы типизированных объектов
var abilities: Array[BaseAbility] = []
```

### Без class_name пришлось бы:

```gdscript
# ❌ Без class_name
var AbilityScript = load("res://components/AbilitySystem/base_ability.gd")
var ability = AbilityScript.new()

# ✅ С class_name
var ability = BaseAbility.new()
```

---

## Виртуальные методы

В GDScript нет явного ключевого слова `virtual`, но концепция есть - это методы, которые **предназначены для переопределения**.

### Паттерн виртуального метода:

```gdscript
# BaseAbility (родительский класс)
func activate(owner: CharacterBody3D) -> bool:
	# Базовая логика (проверки, кулдаун)
	if is_on_cooldown:
		return false

	is_on_cooldown = true

	# Дочерние классы должны переопределить этот метод
	# и добавить свою логику
	return true
```

### Дочерний класс переопределяет:

```gdscript
# DashAbility (дочерний класс)
func activate(owner: CharacterBody3D) -> bool:
	# Вызываем базовую логику
	if not super.activate(owner):
		return false

	# Наша реализация
	_perform_dash(owner)
	return true
```

### Примеры виртуальных методов в проекте:

1. **BaseAbility.activate()** - каждая способность реализует свою логику активации
2. **HealthComponent** - можно переопределить логику смерти
3. **Interactable.use()** - каждый интерактивный объект реализует свое взаимодействие

---

## Композиция vs Наследование

### Наследование (is-a)

"DashAbility **является** BaseAbility"

```gdscript
extends BaseAbility
class_name DashAbility
```

**Когда использовать:**
- Классы имеют общую природу
- Нужно переопределить поведение
- Есть четкая иерархия

**Пример из проекта:**
```
BaseAbility (базовая способность)
├── DashAbility (рывок)
├── FireballAbility (файрбол)
└── HealAbility (лечение)
```

### Композиция (has-a)

"Player **имеет** HealthComponent"

```gdscript
# player.gd
extends CharacterBody3D

@onready var health_component: HealthComponent = $health_component
@onready var combat_component: CombatComponent = $CombatComponent
@onready var ability_component: AbilityComponent = $AbilityComponent
```

**Когда использовать:**
- Нужно добавить функциональность
- Компоненты могут использоваться независимо
- Гибкость важнее иерархии

**Пример из проекта:**
```
Player (CharacterBody3D)
├── HealthComponent (управление здоровьем)
├── CombatComponent (боевая система)
├── AbilityComponent (способности)
└── InteractRay (взаимодействие)
```

### Сравнение:

| Аспект | Наследование | Композиция |
|--------|-------------|-----------|
| Связь | Жесткая ("is-a") | Гибкая ("has-a") |
| Переиспользование | Труднее | Легче |
| Модификация | Изменяет всех наследников | Изменяет только компонент |
| Пример | DashAbility extends BaseAbility | Player has HealthComponent |

### Правило из практики:

**"Наследуй реализацию, компонуй функциональность"**

```gdscript
# ✅ Наследование - общая реализация
extends BaseAbility
class_name DashAbility

# ✅ Композиция - добавление функциональности
var health_component: HealthComponent
var ability_component: AbilityComponent
```

---

## Примеры из проекта

### 1. Система способностей (Ability System)

**Иерархия наследования:**

```
Node (Godot)
  ↓
BaseAbility
  ↓ ↓ ↓
DashAbility  FireballAbility  HealAbility
```

**Код:**

```gdscript
# base_ability.gd
extends Node
class_name BaseAbility

signal ability_used(ability_name: String)

var is_on_cooldown: bool = false
var cooldown: float = 1.0

func _ready() -> void:
	set_process(false)  # Оптимизация

func activate(owner: CharacterBody3D) -> bool:
	if is_on_cooldown:
		return false

	is_on_cooldown = true
	ability_used.emit(ability_name)
	return true

# ════════════════════════════════════════

# dash_ability.gd
extends BaseAbility
class_name DashAbility

var dash_speed: float = 20.0

func _ready() -> void:
	super._ready()  # ← Вызов родительского _ready()
	ability_name = "Dash"
	cooldown = 3.0

func activate(owner: CharacterBody3D) -> bool:
	if not super.activate(owner):  # ← Проверка кулдауна
		return false

	# Логика рывка
	var direction = owner.get_input_direction()
	owner.velocity = direction * dash_speed
	return true
```

### 2. Компонентная архитектура

**Композиция:**

```gdscript
# player.gd
extends CharacterBody3D

# Компоненты через композицию
@onready var health_component: HealthComponent = $health_component
@onready var abilities: AbilityComponent = $AbilityComponent

func _ready() -> void:
	# Подключаем сигналы компонентов
	health_component.health_depleted.connect(_on_death)
	abilities.ability_activated.connect(_on_ability_used)

func _on_death() -> void:
	print("Игрок умер")

func _on_ability_used(ability_name: String) -> void:
	print("Использована способность: ", ability_name)
```

### 3. Враг (Enemy) - Наследование + Композиция

```gdscript
# enemy.gd
extends CharacterBody3D  # ← Наследование от встроенного класса

# Композиция компонентов
@onready var health_component: HealthComponent = $health_component
@onready var melee_weapon: MeleeWeaponComponent = $MeleeWeaponComponent

enum State { IDLE, PATROL, CHASE, ATTACK }
var current_state: State = State.IDLE

func _ready() -> void:
	health_component.health_depleted.connect(_on_death)

func _on_death() -> void:
	print("Враг убит")
	queue_free()
```

### 4. Интерактивные объекты

**Базовый класс:**

```gdscript
# interactable.gd
extends Node
class_name Interactable

@export var prompt_message: String = "Взаимодействовать"

# Виртуальный метод - должен быть переопределен
func use() -> void:
	push_warning("Метод use() не переопределен!")
```

**Конкретные реализации:**

```gdscript
# door.gd
extends Interactable

var is_open: bool = false

func use() -> void:
	if is_open:
		close_door()
	else:
		open_door()

func open_door() -> void:
	is_open = true
	print("Дверь открыта")

# ════════════════════════════════════════

# button.gd
extends Interactable

signal pressed

func use() -> void:
	pressed.emit()
	print("Кнопка нажата")
```

---

## Лучшие практики

### 1. Всегда вызывайте super в переопределенных методах

```gdscript
# ✅ ПРАВИЛЬНО
func _ready() -> void:
	super._ready()  # Выполняем логику родителя
	# Наша логика

# ❌ НЕПРАВИЛЬНО
func _ready() -> void:
	# Пропущен super._ready() - возможны баги!
	# Наша логика
```

### 2. Используйте class_name для переиспользуемых классов

```gdscript
# ✅ ПРАВИЛЬНО - глобальный класс
extends Node
class_name HealthComponent

# ❌ НЕПРАВИЛЬНО - нужно будет load() каждый раз
extends Node
# без class_name
```

### 3. Предпочитайте композицию для добавления функциональности

```gdscript
# ✅ ПРАВИЛЬНО - композиция
extends CharacterBody3D

@onready var health: HealthComponent = $HealthComponent
@onready var abilities: AbilityComponent = $AbilityComponent

# ❌ НЕПРАВИЛЬНО - множественное наследование невозможно
extends CharacterBody3D, HealthComponent, AbilityComponent
# GDScript не поддерживает множественное наследование!
```

### 4. Делайте базовые классы максимально общими

```gdscript
# ✅ ПРАВИЛЬНО - общий базовый класс
class_name BaseAbility

func activate(owner: CharacterBody3D) -> bool:
	# Общая логика для ВСЕХ способностей
	if is_on_cooldown:
		return false
	return true

# ❌ НЕПРАВИЛЬНО - слишком специфично
class_name BaseAbility

func activate(owner: CharacterBody3D) -> bool:
	# Логика только для рывка - не подходит для файрбола!
	owner.velocity = Vector3.FORWARD * speed
```

### 5. Документируйте виртуальные методы

```gdscript
class_name BaseAbility

# Виртуальный метод - ДОЛЖЕН быть переопределен в дочерних классах
# Вызовите super.activate() перед своей логикой!
func activate(owner: CharacterBody3D) -> bool:
	if is_on_cooldown:
		return false

	is_on_cooldown = true
	return true
```

### 6. Типизируйте переменные

```gdscript
# ✅ ПРАВИЛЬНО - с типизацией
var ability: BaseAbility = DashAbility.new()
var abilities: Array[BaseAbility] = []

# ❌ НЕПРАВИЛЬНО - без типов
var ability = DashAbility.new()
var abilities = []
```

### 7. Используйте @export для настройки в Inspector

```gdscript
class_name DashAbility extends BaseAbility

@export var dash_speed: float = 20.0  # Можно изменить в Inspector
@export var dash_duration: float = 0.2
```

---

## Диаграмма: Полная архитектура проекта

```
НАСЛЕДОВАНИЕ:                    КОМПОЗИЦИЯ:

Node (Godot)                     Player (CharacterBody3D)
  ↓                              ├─ HealthComponent
BaseAbility                      ├─ CombatComponent
  ├─ DashAbility                 ├─ AbilityComponent
  ├─ FireballAbility             │   ├─ DashAbility
  └─ HealAbility                 │   └─ FireballAbility
                                 ├─ HurtboxComponent
Node                             └─ MeleeWeaponComponent
  ↓
Interactable                     Enemy (CharacterBody3D)
  ├─ Door                        ├─ HealthComponent
  └─ Button                      ├─ HurtboxComponent
                                 ├─ MeleeWeaponComponent
Node                             └─ NavigationAgent3D
  ↓
HealthComponent
  (используется через композицию)
```

---

## Шпаргалка

### Ключевые слова:

| Ключевое слово | Использование | Пример |
|---------------|---------------|--------|
| `extends` | Наследование класса | `extends BaseAbility` |
| `class_name` | Регистрация глобального класса | `class_name DashAbility` |
| `super` | Вызов метода родителя | `super._ready()` |
| `@onready` | Инициализация при готовности узла | `@onready var health = $HealthComponent` |
| `@export` | Переменная в Inspector | `@export var speed: float = 5.0` |

### Проверка типов:

```gdscript
# Проверка типа
if ability is DashAbility:
	print("Это рывок!")

# Приведение типа (cast)
var dash = ability as DashAbility
if dash:
	dash.dash_speed = 30.0
```

### Создание экземпляров:

```gdscript
# Новый экземпляр класса
var ability = DashAbility.new()

# Загрузка из файла
var script = load("res://path/to/script.gd")
var instance = script.new()

# Инстанс сцены
var scene = load("res://path/to/scene.tscn")
var instance = scene.instantiate()
```

---

## Заключение

ООП в GDScript - это мощный инструмент для создания чистой и модульной архитектуры:

✅ **Используйте наследование** для общей реализации (BaseAbility → DashAbility)
✅ **Используйте композицию** для добавления функциональности (Player has HealthComponent)
✅ **Всегда вызывайте super** при переопределении методов
✅ **Регистрируйте class_name** для переиспользуемых классов
✅ **Типизируйте переменные** для безопасности и автодополнения

---

## Дополнительные материалы

- [Официальная документация GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)
- Примеры в проекте:
  - `components/AbilitySystem/` - система способностей
  - `components/HealthComponent/` - компонент здоровья
  - `entity/player/player.gd` - композиция компонентов
  - `entity/enemy/enemy.gd` - наследование + композиция

Удачи в разработке! 🚀
