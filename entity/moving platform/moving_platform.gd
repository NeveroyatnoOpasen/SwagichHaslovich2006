extends Path3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


var direction: float = 1.0
var speed: float = 0.5
var toggle: bool = false 
#над этим я думал блять час, убейте меня
func _process(delta: float) -> void:
	var path = get_node("PathFollow3D")
	if toggle:
		path.progress_ratio += delta * speed * direction
	#	print(path.progress_ratio, direction)
		if path.progress_ratio >= 0.9 and direction != -1:
			toggle = false
			direction = -1
			print("Changing dir")
		elif path.progress_ratio <= 0.1 and direction != 1:
			toggle = false
			direction = 1
			print("Changing dir")
			#reached(path)

func use():
	toggle = !toggle
	pass
