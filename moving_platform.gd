extends Path3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


var direction: float = 1.0
var speed: float = 0.5

func _process(delta: float) -> void:
	var path = get_node("PathFollow3D")
	
	if path.progress_ratio >= 0.9:
		direction = -1.0
	elif path.progress_ratio <= 0.1:
		direction = 1.0
		
	path.progress_ratio += delta * speed * direction
	print(direction)
	# Меняем направление при достижении концов
