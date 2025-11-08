# TeamComponent - компонент определения фракции/команды
# Используется для определения союзников и врагов
extends Node
class_name TeamComponent

# Доступные фракции
enum Team {
	CULT,      # Культисты
	REGULAR,   # Регуляры/военные
	MOBS,      # Монстры/мобы
	NEUTRAL    # Нейтральные (не атакуют и не атакуются)
}

# Текущая команда этого юнита
@export var team: Team = Team.MOBS

# Враждебные отношения между фракциями
# true = враждебны друг другу
const HOSTILITY_MATRIX = {
	Team.CULT: {
		Team.CULT: false,
		Team.REGULAR: true,
		Team.MOBS: true,
		Team.NEUTRAL: false
	},
	Team.REGULAR: {
		Team.CULT: true,
		Team.REGULAR: false,
		Team.MOBS: true,
		Team.NEUTRAL: false
	},
	Team.MOBS: {
		Team.CULT: true,
		Team.REGULAR: true,
		Team.MOBS: false,
		Team.NEUTRAL: false
	},
	Team.NEUTRAL: {
		Team.CULT: false,
		Team.REGULAR: false,
		Team.MOBS: false,
		Team.NEUTRAL: false
	}
}

# Проверяет, является ли другой юнит врагом
func is_hostile_to(other: TeamComponent) -> bool:
	if not other:
		return false

	return HOSTILITY_MATRIX[team][other.team]

# Проверяет, является ли другой юнит союзником
func is_friendly_to(other: TeamComponent) -> bool:
	if not other:
		return false

	return team == other.team

# Получить название команды
func get_team_name() -> String:
	return Team.keys()[team]
