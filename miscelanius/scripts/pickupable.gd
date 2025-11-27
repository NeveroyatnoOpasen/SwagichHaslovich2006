#extends Node3D
extends Interactable
class_name pickupable
@export var item_resource: WeaponItem
@onready var mesh: MeshInstance3D = $MeshInstance3D

func _init() -> void:
	prompt_message = "weapon"
# добавляем его к мешу оружия на сцене
func _ready():
	prompt_message = "Pick up %s" % item_resource.item_name
	
func use():
	var player = get_tree().get_first_node_in_group("Player")
	if player.inventory_component:
		if player.inventory_component.add_item(item_resource.duplicate()):
			print("Picked up %s" % item_resource.item_name)
			queue_free()
