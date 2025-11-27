extends RayCast3D
@onready var prompt = $Label
var Collider

func _process(delta: float) -> void:
	prompt.text = ""
	if is_colliding():
		var collider = get_collider()
		#print(collider.name)

		# Ищем Interactable: сначала сам collider, потом по иерархии вверх
		var interactable = _find_interactable(collider)

		if interactable:
			#print("coliding with interactable:", interactable.name)
			prompt.text = interactable.prompt_message
			Collider = interactable
		else:
			Collider = null
	else:
		Collider = null

# Рекурсивно ищет Interactable вверх по иерархии
func _find_interactable(node: Node) -> Interactable:
	if node == null:
		return null

	# Проверяем текущий узел
	if node is Interactable:
		return node

	# Проверяем родителя
	return _find_interactable(node.get_parent())
			
func use():
	if Collider != null:
		Collider.call("use")
		if Collider.is_in_group("DynamicObject"):
			print_rich("[color=green][b]Dynamic[/b][/color]")
		#Collider
		pass
