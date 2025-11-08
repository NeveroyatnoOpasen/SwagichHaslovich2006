# TeamComponent

Компонент для определения фракции/команды юнита. Используется AI для определения союзников и врагов.

## Использование

### Добавление компонента

1. Добавьте `TeamComponent` как дочерний узел к `CharacterBody3D` (игрок, враг, NPC)
2. В инспекторе выберите фракцию из enum `Team`

### Доступные фракции

- **CULT** - Культисты
- **REGULAR** - Регуляры/военные
- **MOBS** - Монстры/мобы
- **NEUTRAL** - Нейтральные (никого не атакуют и не атакуются)

### Матрица враждебности

| Фракция | CULT | REGULAR | MOBS | NEUTRAL |
|---------|------|---------|------|---------|
| CULT    | ❌   | ✅      | ✅   | ❌      |
| REGULAR | ✅   | ❌      | ✅   | ❌      |
| MOBS    | ✅   | ✅      | ❌   | ❌      |
| NEUTRAL | ❌   | ❌      | ❌   | ❌      |

✅ = враждебны друг другу
❌ = не враждебны

### API

```gdscript
# Проверить, является ли другой юнит врагом
func is_hostile_to(other: TeamComponent) -> bool

# Проверить, является ли другой юнит союзником
func is_friendly_to(other: TeamComponent) -> bool

# Получить название команды
func get_team_name() -> String
```

### Пример использования в AI

```gdscript
# Ссылка на компонент
@onready var team_component: TeamComponent = $TeamComponent

# Проверка враждебности цели
func check_if_hostile(target: CharacterBody3D) -> bool:
    if not target.has_node("TeamComponent"):
        return false

    var target_team: TeamComponent = target.get_node("TeamComponent")
    return team_component.is_hostile_to(target_team)
```

## Интеграция с Enemy AI

Враг (`entity/enemy/enemy.gd`) теперь автоматически:
- Обнаруживает все `CharacterBody3D` с `TeamComponent` в зоне обнаружения
- Выбирает ближайшую враждебную цель для атаки
- Игнорирует союзников и нейтральные цели
- Может атаковать игрока, если игрок принадлежит враждебной фракции

## Настройка игрока

Чтобы враги атаковали игрока, добавьте `TeamComponent` к игроку и установите фракцию:
- Если игрок за регуляров: `Team.REGULAR`
- Если игрок за культ: `Team.CULT`
- Если враги должны игнорировать игрока: `Team.NEUTRAL`

## Изменение матрицы враждебности

Матрица враждебности определена в константе `HOSTILITY_MATRIX` в `team_component.gd`. Чтобы изменить отношения между фракциями, отредактируйте эту матрицу.
