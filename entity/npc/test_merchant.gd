# test_merchant.gd
# Пример реализации торговца для тестирования диалоговой системы
extends NPCBase

func _ready():
	npc_display_name = "Торговец"
	starting_dialog_id = "merchant_greeting"
	super._ready()

	# Регистрируем обработчики событий
	DialogManager.register_event("open_shop", _on_open_shop)
	DialogManager.register_event("start_quest", _on_start_quest)

func _on_open_shop(params: Dictionary = {}):
	print("[Торговец] Открываю магазин...")
	# Здесь будет логика открытия магазина

func _on_start_quest(params: Dictionary = {}):
	var quest_id = params.get("quest_id", "unknown")
	print("[Торговец] Начинаю квест: ", quest_id)
	# Здесь будет логика квестов
