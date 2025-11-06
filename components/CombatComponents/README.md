# Система ближнего боя для Godot 4.5

## Обзор компонентов

Эта система состоит из 4 основных компонентов:

### 1. **HitboxComponent** - Обнаружение попаданий
- Активная область атаки
- Обнаруживает столкновения с хёртбоксами
- Предотвращает множественные попадания по одной цели
- Слой коллизии: 2, Маска: 4

### 2. **HurtboxComponent** - Получение урона
- Пассивная область получения урона
- Интегрируется с HealthComponent
- Поддерживает множители урона
- Слой коллизии: 4, Маска: 2

### 3. **MeleeWeaponComponent** - Управление оружием
- Два типа атак: лёгкая и тяжёлая
- Настраиваемые параметры урона, отброса и времени
- Система кулдаунов
- Управляет активацией/деактивацией хитбокса

### 4. **CombatComponent** - Управление боем
- Обработка ввода атак
- Система комбо
- Ограничения атак (в воздухе, остановка движения)
- Интеграция с CharacterBody3D

## Быстрый старт

### Настройка игрока

1. Откройте сцену player.tscn
2. Добавьте следующие узлы к игроку:

```
Player (CharacterBody3D)
├── health_component (HealthComponent) - уже есть
├── CombatComponent (Node)
├── MeleeWeaponComponent (Node3D)
│   └── HitboxComponent (Area3D)
├── HurtboxComponent (Area3D)
└── Pivot (Node3D)
    └── Camera3D
```

3. **Настройка MeleeWeaponComponent:**
   - Разместите под Pivot/Camera3D или создайте отдельный узел для оружия
   - Хитбокс должен быть впереди игрока (примерно на расстоянии вытянутой руки)
   - В инспекторе укажите ссылку на HitboxComponent

4. **Настройка CombatComponent:**
   - В инспекторе укажите ссылку на MeleeWeaponComponent
   - Укажите ссылку на CharacterBody3D (игрока)
   - Настройте параметры комбо и ограничения

5. **Настройка HurtboxComponent:**
   - Разместите на уровне игрока
   - В инспекторе укажите ссылку на health_component
   - Настройте форму коллизии (CapsuleShape3D по размеру игрока)

6. **Замените скрипт игрока:**
   - Используйте `player_combat_example.gd` как основу
   - Или добавьте код обработки атак в ваш существующий player.gd

### Настройка врага

1. Создайте новую сцену для врага:

```
Enemy (CharacterBody3D)
├── health_component (HealthComponent)
├── HurtboxComponent (Area3D)
│   └── CollisionShape3D
└── MeshInstance3D (визуальная модель)
```

2. **Настройка HurtboxComponent:**
   - В инспекторе укажите ссылку на health_component
   - Настройте форму коллизии
   - Убедитесь, что слой = 4, маска = 2

3. Подключите сигналы для реакции на урон

## Использование в коде

### Выполнение атаки

```gdscript
# Лёгкая атака
if combat_component:
    combat_component.handle_attack_input(MeleeWeaponComponent.AttackType.LIGHT)

# Тяжёлая атака
if combat_component:
    combat_component.handle_attack_input(MeleeWeaponComponent.AttackType.HEAVY)
```

### Подключение к сигналам

```gdscript
func _ready():
    # Сигналы боевой системы
    combat_component.attack_performed.connect(_on_attack_performed)
    combat_component.combo_started.connect(_on_combo_started)
    combat_component.combo_reset.connect(_on_combo_reset)

    # Сигналы оружия
    weapon.hit_landed.connect(_on_hit_landed)

    # Сигналы хёртбокса
    hurtbox.hit_received.connect(_on_hit_received)

func _on_attack_performed(attack_type):
    # Запустить анимацию атаки
    pass

func _on_combo_started(combo_index):
    # Изменить анимацию в зависимости от номера комбо
    pass

func _on_hit_landed(target):
    # Эффекты попадания, звуки
    pass

func _on_hit_received(damage, knockback, attacker_pos):
    # Реакция на получение урона
    pass
```

## Параметры компонентов

### MeleeWeaponComponent

**Лёгкая атака:**
- `light_damage`: Урон (по умолчанию: 15)
- `light_knockback`: Сила отброса (по умолчанию: 3)
- `light_attack_duration`: Длительность атаки в секундах (по умолчанию: 0.3)
- `light_active_start`: Когда активируется хитбокс (по умолчанию: 0.1)
- `light_active_end`: Когда деактивируется хитбокс (по умолчанию: 0.25)
- `light_cooldown`: Кулдаун между атаками (по умолчанию: 0.4)

**Тяжёлая атака:**
- `heavy_damage`: Урон (по умолчанию: 35)
- `heavy_knockback`: Сила отброса (по умолчанию: 8)
- `heavy_attack_duration`: Длительность атаки (по умолчанию: 0.6)
- `heavy_active_start`: Когда активируется хитбокс (по умолчанию: 0.2)
- `heavy_active_end`: Когда деактивируется хитбокс (по умолчанию: 0.5)
- `heavy_cooldown`: Кулдаун (по умолчанию: 1.0)

### CombatComponent

**Система комбо:**
- `enable_combo`: Включить систему комбо
- `max_combo_count`: Максимальное количество ударов в комбо (по умолчанию: 3)
- `combo_window`: Окно времени для продолжения комбо в секундах (по умолчанию: 0.5)

**Ограничения:**
- `allow_air_attack`: Разрешить атаку в воздухе
- `stop_movement_on_attack`: Останавливать движение при атаке

### HurtboxComponent

- `damage_multiplier`: Множитель урона (для уязвимых зон)
- `enabled`: Включить/выключить получение урона

## Интеграция с анимациями

Для интеграции с AnimationPlayer:

```gdscript
func _on_attack_performed(attack_type):
    if animation_player:
        match attack_type:
            MeleeWeaponComponent.AttackType.LIGHT:
                animation_player.play("light_attack")
            MeleeWeaponComponent.AttackType.HEAVY:
                animation_player.play("heavy_attack")

func _on_combo_started(combo_index):
    # Играть разные анимации в зависимости от номера в комбо
    if animation_player:
        animation_player.play("attack_" + str(combo_index))
```

## Добавленные действия ввода

В `project.godot` добавлены:
- `attack` - Левая кнопка мыши (лёгкая атака)
- `heavy_attack` - Правая кнопка мыши (тяжёлая атака)

## Советы по настройке

1. **Размер и позиция хитбокса:**
   - Располагайте хитбокс впереди игрока/оружия
   - Размер должен соответствовать дальности оружия
   - Для мечей - длинный BoxShape3D
   - Для кулаков - небольшой SphereShape3D

2. **Тайминг активации:**
   - `active_start` - момент, когда удар должен начать наносить урон
   - `active_end` - момент, когда удар перестаёт наносить урон
   - Настраивайте под анимации

3. **Баланс урона:**
   - Лёгкая атака: быстрая, низкий урон
   - Тяжёлая атака: медленная, высокий урон
   - Кулдауны предотвращают спам

4. **Система комбо:**
   - `combo_window` - время, в течение которого игрок может продолжить комбо
   - Слишком короткое окно = сложно
   - Слишком длинное окно = лёгкий спам

## Расширение системы

### Добавление новых типов атак

Измените enum в `melee_weapon_component.gd`:

```gdscript
enum AttackType {
    LIGHT,
    HEAVY,
    SPECIAL,  # Новый тип
}
```

Добавьте параметры для нового типа и обработку в методах.

### Добавление эффектов отброса

В `hurtbox_component.gd`, метод `take_hit`:

```gdscript
func take_hit(damage: float, knockback_force: float, attacker_position: Vector3) -> void:
    # ... существующий код ...

    # Применяем отброс к родителю, если это CharacterBody3D
    var parent_body = get_parent() as CharacterBody3D
    if parent_body:
        var knockback_dir = (parent_body.global_position - attacker_position).normalized()
        parent_body.velocity += knockback_dir * knockback_force
```

### Добавление системы выносливости

Добавьте StaminaComponent и проверяйте выносливость перед атакой в CombatComponent.

## Отладка

Включите видимость коллизий в редакторе:
- Debug → Visible Collision Shapes

Проверьте слои коллизий:
- HitboxComponent: слой 2, маска 4
- HurtboxComponent: слой 4, маска 2

Используйте print() для отладки:
- Когда активируется хитбокс
- Когда происходит попадание
- Состояние комбо
