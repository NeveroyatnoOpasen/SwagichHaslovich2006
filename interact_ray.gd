extends RayCast3D
@onready var prompt = $Label
var Collider
func _process(delta: float) -> void:
	prompt.text = ""
	if is_colliding():
		var collider = get_collider()
		#print(collider.name)
		if collider is Interactable:
			#print("coliding")
			prompt.text = collider.prompt_message
			Collider = collider
			
	else:
			Collider = null
			
func use():
	if Collider != null:
		Collider.call("use")
		if Collider.is_in_group("DynamicObject"):
			print_rich("[color=green][b]Dynamic[/b][/color]")
		#Collider
		pass
