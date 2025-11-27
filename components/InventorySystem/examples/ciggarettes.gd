extends ConsumableItem
class_name Cigarettes

# Конструктор - здесь устанавливаем все параметры
func _init():
	# Вызываем родительский конструктор
	super._init()

	# Базовая информация
	item_id = "cigarettes"
	item_name = "Cigarettes"
	description = "Make your lungs explode. Restores 5 HP but damages max health."

	# Свойства расходника
	consumable_type = ConsumableType.FOOD  # Или создай новый тип TOBACCO
	heal_amount = 5.0  # Немного лечит
	buff_duration = 10.0  # Эффект на 10 секунд
	buff_effect = "nicotine_buzz"

	# Характеристики предмета
	value = 10
	weight = 0.1
	is_stackable = true
	max_stack = 20

# Переопределяем use() для особого эффекта
func use(user: Node) -> bool:
	# Сначала вызываем родительскую версию (лечит HP)
	var used = super.use(user)

	if used:
		# Добавляем особый эффект - уменьшаем макс. здоровье
		var health_component = user.get_node_or_null("health_component")
		if health_component:
			# Курение вредно - уменьшаем макс HP на 1
			health_component.max_health -= 1.0
			print("*cough cough* Your max health decreased!")

		print("%s smokes a cigarette. Cool, but deadly." % user.name)

	return used
