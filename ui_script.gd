extends Control

@onready var progress_bar: ProgressBar = $HealthBarContainer/ProgressBar
@onready var health_label: Label = $HealthBarContainer/HealthLabel

func _ready() -> void:
	# Инициализация health bar
	if progress_bar:
		progress_bar.show_percentage = false

func _on_health_component_health_changed(current_health: float, max_health: float, damaged: bool) -> void:
	# Обновляем health bar
	if progress_bar:
		progress_bar.max_value = max_health
		progress_bar.value = current_health

		# Меняем цвет в зависимости от здоровья
		var health_percent = current_health / max_health
		if health_percent > 0.6:
			progress_bar.modulate = Color(0.2, 1.0, 0.2)  # Зеленый
		elif health_percent > 0.3:
			progress_bar.modulate = Color(1.0, 0.8, 0.0)  # Желтый
		else:
			progress_bar.modulate = Color(1.0, 0.2, 0.2)  # Красный

	# Обновляем текст здоровья
	if health_label:
		health_label.text = "Health: %d / %d" % [int(current_health), int(max_health)]

	# Эффекты крови/хила
	if damaged:
		if ResourceLoader.exists("res://miscelanius/blood.png"):
			$OverlayWirhEffects.texture = load("res://miscelanius/blood.png")
		$AnimationPlayer.play("blood")
	else:
		if ResourceLoader.exists("res://miscelanius/Heal.jpg"):
			$OverlayWirhEffects.texture = load("res://miscelanius/Heal.jpg")
		$AnimationPlayer.play("blood")
